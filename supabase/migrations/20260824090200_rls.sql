-- ============================================================================
-- 20260824090200_rls.sql   (REWRITTEN — v2. Migration was never applied
--                           anywhere, so it is replaced in place rather than
--                           corrected by a follow-up migration.)
--
-- v1 DEFECT: derived measurement tables were granted INSERT/UPDATE to
-- `authenticated`, and the guard trigger fired only BEFORE UPDATE. A learner
-- could therefore INSERT objective_mastery(p_mastery = 1) for an objective they
-- had never attempted, or skill_estimates(theta = 9, se = 0.01) — accepted,
-- because there was no prior row for the trigger to compare against.
--
-- v2 model — four table classes, each with a different grant shape:
--
--   PUBLIC CONTENT   select when published. No client write, ever.
--   OWNED-MUTABLE    the learner genuinely owns it: preferences, bookmarks,
--                    reading position. select/insert/update by owner.
--   DERIVED          server-computed measurement. SELECT ONLY — no insert,
--                    no update, no delete, for any client role. Written
--                    exclusively by SECURITY DEFINER RPCs.
--   APPEND-ONLY      facts. select + insert. No update, no delete.
--
-- Grants are the primary control. The trigger below is defence-in-depth for
-- the day someone re-adds a grant by accident.
--
-- (select auth.uid()) is wrapped so Postgres caches it as an InitPlan rather
-- than re-evaluating per row.
-- ============================================================================

do $$
declare t record;
begin
  for t in
    select schemaname, tablename from pg_tables
    where schemaname in ('content','learning','assess','ai','admin','analytics')
  loop
    execute format('alter table %I.%I enable row level security;', t.schemaname, t.tablename);
    execute format('alter table %I.%I force row level security;', t.schemaname, t.tablename);
  end loop;
end $$;

revoke all on all tables in schema content, learning, assess, ai, admin, analytics
  from anon, authenticated;
revoke all on all sequences in schema learning, assess, ai, admin, analytics
  from anon, authenticated;

grant usage on schema content, learning, assess, ai, analytics to authenticated;
grant usage on schema content to anon;

-- ================================================== defence-in-depth guard ==
-- Fires on INSERT, UPDATE and DELETE. Identity comes from current_user: inside
-- a SECURITY DEFINER function current_user is the function owner, while a
-- direct PostgREST write leaves it as `authenticated`/`anon`. Far more robust
-- than v1's session flag, which stayed switched on if a function raised before
-- resetting it.
create or replace function learning.reject_client_write()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated','anon') then
    raise exception
      '%.% is server-computed; write it through a SECURITY DEFINER RPC',
      tg_table_schema, tg_table_name
      using errcode = '42501';
  end if;
  return coalesce(new, old);
end $$;

do $$
declare t text;
begin
  foreach t in array array[
    'learning.objective_mastery','learning.grammar_mastery','learning.skill_estimates',
    'learning.learner_stats','learning.learner_error_patterns','learning.review_queue',
    'learning.study_sessions','learning.study_plans',
    'assess.exercise_attempts','assess.attempt_idempotency',
    'assess.speech_evaluations','assess.assessment_attempts']
  loop
    execute format(
      'create trigger t_no_client_write before insert or update or delete on %s
         for each row execute function learning.reject_client_write();', t);
  end loop;
end $$;

-- ======================================================= CLASS: CONTENT ====

do $$
declare t text;
begin
  foreach t in array array[
    'cefr_levels','curriculum_nodes','lessons','lesson_versions','content_blocks',
    'learning_objectives','lesson_objectives','grammar_concepts','grammar_concept_edges',
    'thai_contrast_notes','error_taxonomy','vocabulary_entries','vocabulary_senses',
    'vocabulary_examples','collocations','lexicon_policy','pronunciation_targets',
    'audio_assets','exercise_templates','exercises','exam_providers','exam_specs',
    'exam_tasks','content_packs']
  loop
    execute format('grant select on content.%I to authenticated, anon;', t);
    execute format($p$
      create policy content_read_%1$s on content.%1$I
        for select to authenticated, anon
        using ( admin.is_editor() or coalesce(
                  (to_jsonb(content.%1$I.*) ->> 'status'), 'published') = 'published' );
    $p$, t);
  end loop;
end $$;

-- ================================================== CLASS: OWNED-MUTABLE ==
-- Things the learner legitimately controls. Nothing here feeds measurement.

grant select, update on learning.profiles to authenticated;
create policy own_select on learning.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy own_update on learning.profiles
  for update to authenticated using ((select auth.uid()) = id)
                                with check ((select auth.uid()) = id);

do $$
declare t text;
begin
  foreach t in array array['learner_preferences','bookmarks','sync_cursors','enrolments']
  loop
    execute format('grant select, insert, update on learning.%I to authenticated;', t);
    execute format('create policy own_select on learning.%I for select to authenticated
                      using ((select auth.uid()) = learner_id);', t);
    execute format('create policy own_insert on learning.%I for insert to authenticated
                      with check ((select auth.uid()) = learner_id);', t);
    execute format('create policy own_update on learning.%I for update to authenticated
                      using ((select auth.uid()) = learner_id)
                      with check ((select auth.uid()) = learner_id);', t);
  end loop;
end $$;

grant delete on learning.bookmarks to authenticated;
create policy own_delete on learning.bookmarks
  for delete to authenticated using ((select auth.uid()) = learner_id);

-- Reading position is the learner's own; completion is not. A client may move
-- last_block_index freely but may never declare a lesson complete, because
-- completion awards stats and unlocks progression.
grant select, insert, update on learning.lesson_progress to authenticated;
create policy own_select on learning.lesson_progress
  for select to authenticated using ((select auth.uid()) = learner_id);
create policy own_insert on learning.lesson_progress
  for insert to authenticated
  with check ((select auth.uid()) = learner_id and state <> 'completed');
create policy own_update on learning.lesson_progress
  for update to authenticated
  using ((select auth.uid()) = learner_id)
  with check ((select auth.uid()) = learner_id and state <> 'completed');

create or replace function learning.guard_lesson_completion()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated','anon')
     and new.state = 'completed'
     and coalesce(case when tg_op = 'UPDATE' then old.state end, '') <> 'completed' then
    raise exception 'use learning.complete_lesson()' using errcode = '42501';
  end if;
  return new;
end $$;
create trigger t_guard_completion before insert or update on learning.lesson_progress
  for each row execute function learning.guard_lesson_completion();

-- ======================================================= CLASS: DERIVED ====
-- SELECT ONLY. This is the v1 fix.

do $$
declare t text;
begin
  foreach t in array array[
    'objective_mastery','grammar_mastery','skill_estimates','learner_stats',
    'learner_error_patterns','review_queue','study_sessions','study_plans']
  loop
    execute format('grant select on learning.%I to authenticated;', t);
    execute format('create policy own_select on learning.%I for select to authenticated
                      using ((select auth.uid()) = learner_id);', t);
  end loop;
end $$;

-- =================================================== CLASS: APPEND-ONLY ====

grant select, insert on assess.writing_submissions to authenticated;
create policy own_select on assess.writing_submissions
  for select to authenticated using ((select auth.uid()) = learner_id);
create policy own_append on assess.writing_submissions
  for insert to authenticated with check ((select auth.uid()) = learner_id);

-- Speech submissions go through assess.submit_speech(), which validates the
-- session, the exercise and the audio path prefix. Read-only here.
grant select on assess.speech_submissions to authenticated;
create policy own_select on assess.speech_submissions
  for select to authenticated using ((select auth.uid()) = learner_id);
create trigger t_no_client_write
  before insert or update or delete on assess.speech_submissions
  for each row execute function learning.reject_client_write();

-- Evaluations: the learner may READ their own result and nothing more.
grant select on assess.speech_evaluations to authenticated;
create policy own_select on assess.speech_evaluations
  for select to authenticated using (exists (
    select 1 from assess.speech_submissions s
    where s.id = speech_evaluations.submission_id
      and s.learner_id = (select auth.uid())));

-- Exercise attempts are inserted ONLY by assess.submit_attempt(): the server
-- decides is_correct and the row drives mastery. Read-only to clients.
grant select on assess.exercise_attempts to authenticated;
create policy own_select on assess.exercise_attempts
  for select to authenticated using ((select auth.uid()) = learner_id);

-- v1 granted broad UPDATE while `state = 'in_progress'` and guarded only
-- theta/se/skill_profile. That left kind, level, state, result, started_at and
-- submitted_at client-writable: a learner could manufacture a submitted
-- assessment with an arbitrary result and backdated timestamps. An assessment
-- is a state machine, so it now moves only through explicit RPCs.
grant select on assess.assessment_attempts to authenticated;
create policy own_select on assess.assessment_attempts
  for select to authenticated using ((select auth.uid()) = learner_id);

grant select on assess.writing_feedback to authenticated;
create policy own_select on assess.writing_feedback
  for select to authenticated using (exists (
    select 1 from assess.writing_submissions s
    where s.id = writing_feedback.submission_id
      and s.learner_id = (select auth.uid())));

-- ============================================================== CLASS: AI ==

grant select, insert on ai.conversation_sessions, ai.conversation_messages to authenticated;

create policy own_select on ai.conversation_sessions
  for select to authenticated using ((select auth.uid()) = learner_id);
create policy own_insert on ai.conversation_sessions
  for insert to authenticated with check ((select auth.uid()) = learner_id);
-- No client UPDATE. `debrief` is the AI's evaluation of the learner and must
-- not be self-authored; state changes go through ai.end_conversation().
create trigger t_no_client_update
  before update or delete on ai.conversation_sessions
  for each row execute function learning.reject_client_write();

create policy own_select on ai.conversation_messages
  for select to authenticated using (exists (
    select 1 from ai.conversation_sessions s
    where s.id = conversation_messages.session_id
      and s.learner_id = (select auth.uid())));
-- A learner may only ever author their OWN turn, with no server-derived
-- fields attached. Tutor turns are written by the AI gateway (service_role)
-- through ai.append_tutor_message_internal().
create policy own_insert on ai.conversation_messages
  for insert to authenticated with check (
    role = 'learner'
    and authored_by = 'client'
    and error_codes = '{}'          -- cannot forge AI error analysis
    and audio_path is null          -- audio is attached server-side
    and exists (
      select 1 from ai.conversation_sessions s
      where s.id = conversation_messages.session_id
        and s.learner_id = (select auth.uid())
        and s.state = 'active'));

create or replace function ai.guard_message_authorship()
returns trigger language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated','anon')
     and (new.role <> 'learner' or new.authored_by <> 'client'
          or new.error_codes <> '{}' or new.audio_path is not null) then
    raise exception 'a client may only author its own learner turn'
      using errcode = '42501';
  end if;
  return new;
end $$;
create trigger t_guard_authorship before insert or update on ai.conversation_messages
  for each row execute function ai.guard_message_authorship();

-- ai.explanation_cache, ai.ai_requests: service_role only. No grants issued.

-- =========================================================== CLASS: ADMIN ==

do $$
declare t record;
begin
  for t in select tablename from pg_tables where schemaname = 'admin'
  loop
    execute format('grant select, insert on admin.%I to authenticated;', t.tablename);
    execute format('create policy editor_read on admin.%I for select to authenticated
                      using (admin.is_editor());', t.tablename);
    execute format('create policy editor_write on admin.%I for insert to authenticated
                      with check (admin.is_editor());', t.tablename);
  end loop;
end $$;

drop policy if exists editor_read on admin.audit_logs;
drop policy if exists editor_write on admin.audit_logs;
revoke insert on admin.audit_logs from authenticated;
create policy admin_read_audit on admin.audit_logs
  for select to authenticated using (admin.is_admin());
-- No insert policy: the audit trail is written by definer functions only.

-- ======================================================= CLASS: ANALYTICS ==
-- Write-only. A learner cannot read the event stream back.

grant insert on analytics.events to authenticated;
grant usage on sequence analytics.events_id_seq to authenticated;
create policy own_append on analytics.events
  for insert to authenticated
  with check ((select auth.uid()) = learner_id);

-- ================================================================ STORAGE ==
-- Guarded so the block is a no-op against a bare Postgres in CI.

do $$
begin
  if to_regclass('storage.objects') is null then
    raise notice 'storage.objects absent - skipping storage policies';
    return;
  end if;

  execute $p$
    create policy "learner reads own audio" on storage.objects
      for select to authenticated
      using (bucket_id = 'learner-audio'
             and (storage.foldername(name))[1] = (select auth.uid())::text) $p$;
  execute $p$
    create policy "learner writes own audio" on storage.objects
      for insert to authenticated
      with check (bucket_id = 'learner-audio'
                  and (storage.foldername(name))[1] = (select auth.uid())::text) $p$;
  execute $p$
    create policy "learner deletes own audio" on storage.objects
      for delete to authenticated
      using (bucket_id = 'learner-audio'
             and (storage.foldername(name))[1] = (select auth.uid())::text) $p$;
  execute $p$
    create policy "read published content assets" on storage.objects
      for select to authenticated, anon
      using (bucket_id in ('content-audio','content-media','content-packs')) $p$;
end $$;
