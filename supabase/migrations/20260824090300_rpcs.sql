-- ============================================================================
-- 20260824090300_rpcs.sql   (REWRITTEN — v2, replaced in place; never applied)
--
-- v1 DEFECTS FIXED HERE
--   D-2  schedule_review(p_learner uuid, ...) was SECURITY DEFINER and granted
--        to `authenticated` while taking the learner id from the caller. Any
--        signed-in user could rewrite any other learner's review queue by
--        passing their uuid. Client-callable surface now derives identity from
--        auth.uid() only; the uuid-taking variant is internal and revoked.
--   D-3  submit_attempt's replay branch did `select jsonb_build_object(...)
--        into v_correct` where v_correct is boolean — a runtime type error on
--        every retry — and looked the key up without scoping to the caller.
--   D-4  record_error_code took a client-supplied p_new_session boolean, which
--        submit_attempt never passed, so session_count never exceeded 1 and no
--        error could ever reach 'recurring'. Replaced with a server-owned
--        session entity plus an elapsed-time rule.
--
-- AUTHORIZATION CONVENTION, applied to every function below:
--   * Client-callable functions take NO learner identity parameter.
--   * Functions that need an explicit learner uuid are named `_internal` and
--     are revoked from public/anon/authenticated.
--   * search_path is pinned to '' on every SECURITY DEFINER function.
--   * Execute is revoked from public first, then granted deliberately.
-- ============================================================================

revoke execute on all functions in schema learning, assess, ai, admin from public;

-- ------------------------------------------------------- evidence weights --
create or replace function learning.evidence_weight(kind content.evidence_kind)
returns numeric language sql immutable as $$
  select case kind
    when 'recognition'  then 0.4
    when 'production'   then 1.0
    when 'free_written' then 1.5
    when 'free_spoken'  then 1.5
    when 'delayed'      then 2.0
  end;
$$;

-- =========================================================== SESSIONS ======
-- Server-owned. The client asks for a session; it does not assert one.
--
-- A client could still loop start_session to manufacture "distinct sessions",
-- so session identity alone is not sufficient evidence. Two defences:
--   1. start_session REUSES an open session for the same kind within
--      SESSION_REUSE_WINDOW, so ordinary use produces one row per sitting.
--   2. record_error_code only counts a session as distinct if real time has
--      elapsed since the last counted one (SESSION_GAP). Spamming the RPC
--      cannot compress that.
create or replace function learning.start_session(
  p_kind text,
  p_lesson_id uuid default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_learner uuid := (select auth.uid());
  v_id      uuid;
  c_reuse   constant interval := interval '30 minutes';
begin
  if v_learner is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_kind not in ('lesson','practice','review','conversation','assessment','placement') then
    raise exception 'invalid session kind';
  end if;

  select id into v_id
    from learning.study_sessions
   where learner_id = v_learner and kind = p_kind and ended_at is null
     and last_seen_at > now() - c_reuse
   order by started_at desc limit 1;

  if v_id is not null then
    update learning.study_sessions set last_seen_at = now() where id = v_id;
    return v_id;
  end if;

  -- Close anything stale before opening a new sitting.
  update learning.study_sessions
     set ended_at = last_seen_at
   where learner_id = v_learner and ended_at is null
     and last_seen_at <= now() - c_reuse;

  insert into learning.study_sessions (learner_id, kind, lesson_id)
  values (v_learner, p_kind, p_lesson_id)
  returning id into v_id;
  return v_id;
end $$;

create or replace function learning.end_session(p_session_id uuid)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  update learning.study_sessions
     set ended_at = now()
   where id = p_session_id
     and learner_id = (select auth.uid())   -- ownership, not just existence
     and ended_at is null;
end $$;

-- ==================================================== INTERNAL WRITERS =====
-- These take an explicit learner uuid because they are composed by other
-- definer functions. They are NOT reachable by a client: execute is revoked
-- at the foot of this file.

create or replace function learning.record_evidence_internal(
  p_learner    uuid,
  p_objective  uuid,
  p_kind       content.evidence_kind,
  p_correct    boolean,
  p_concept    uuid default null
) returns numeric
language plpgsql security definer set search_path = '' as $$
declare
  v_w numeric := learning.evidence_weight(p_kind);
  v_p numeric; v_prod int; v_delayed int; v_cap numeric; v_thresh numeric;
begin
  insert into learning.objective_mastery (learner_id, objective_id)
  values (p_learner, p_objective)
  on conflict (learner_id, objective_id) do nothing;

  select p_mastery, productive_evidence_count, delayed_success_count
    into v_p, v_prod, v_delayed
  from learning.objective_mastery
  where learner_id = p_learner and objective_id = p_objective
  for update;

  if p_correct then
    v_p := v_p + (1 - v_p) * least(0.5, 0.18 * v_w);
  else
    v_p := v_p * (1 - least(0.6, 0.30 * v_w));
  end if;

  if p_correct and p_kind in ('production','free_written','free_spoken') then
    v_prod := v_prod + 1;
  end if;
  if p_correct and p_kind = 'delayed' then
    v_delayed := v_delayed + 1;
  end if;

  select coalesce((mastery_rules ->> 'threshold')::numeric, 0.85)
    into v_thresh from content.learning_objectives where id = p_objective;
  v_thresh := coalesce(v_thresh, 0.85);

  -- Recognition-only evidence is capped below the mastery threshold no matter
  -- how many quizzes are passed.
  v_cap := case
    when v_prod >= 1 and v_delayed >= 1 then 1.0
    when v_prod >= 1 then least(0.80, v_thresh - 0.01)
    else 0.70
  end;
  v_p := least(v_p, v_cap);

  update learning.objective_mastery
     set p_mastery                 = v_p,
         evidence_count            = evidence_count + 1,
         productive_evidence_count = v_prod,
         delayed_success_count     = v_delayed,
         last_evidence_at          = now(),
         first_mastered_at         = coalesce(first_mastered_at,
                                       case when v_p >= v_thresh then now() end)
   where learner_id = p_learner and objective_id = p_objective;

  if p_concept is not null then
    insert into learning.grammar_mastery
      (learner_id, concept_id, p_mastery, evidence_count, last_evidence_at)
    values (p_learner, p_concept, v_p, 1, now())
    on conflict (learner_id, concept_id) do update
      set p_mastery        = (learning.grammar_mastery.p_mastery * 0.7) + (v_p * 0.3),
          evidence_count   = learning.grammar_mastery.evidence_count + 1,
          last_evidence_at = now();
  end if;

  return v_p;
end $$;

-- Session-aware. A session counts as distinct only when it is a different
-- session AND enough wall-clock time has passed. Three mistakes inside one
-- sitting is one session's worth of evidence, by construction.
create or replace function learning.record_error_code_internal(
  p_learner uuid, p_code text, p_session_id uuid
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  r learning.learner_error_patterns%rowtype;
  v_distinct boolean;
  c_gap constant interval := interval '20 minutes';
begin
  select * into r from learning.learner_error_patterns
   where learner_id = p_learner and code = p_code for update;

  if not found then
    insert into learning.learner_error_patterns
      (learner_id, code, occurrence_count, weighted_recent_count,
       session_count, last_session_id, last_counted_session_at)
    values (p_learner, p_code, 1, 1, 1, p_session_id, now());
    return;
  end if;

  v_distinct := p_session_id is not null
                and p_session_id is distinct from r.last_session_id
                and (r.last_counted_session_at is null
                     or now() - r.last_counted_session_at >= c_gap);

  update learning.learner_error_patterns set
    occurrence_count      = r.occurrence_count + 1,
    weighted_recent_count = r.weighted_recent_count * 0.9 + 1,
    session_count         = r.session_count + case when v_distinct then 1 else 0 end,
    last_session_id       = coalesce(p_session_id, r.last_session_id),
    last_counted_session_at = case when v_distinct then now()
                                   else r.last_counted_session_at end,
    last_seen             = now(),
    status = case
      when r.status = 'observed'
       and r.occurrence_count + 1 >= 3
       and r.session_count + case when v_distinct then 1 else 0 end >= 2
      then 'recurring'
      else r.status
    end
  where learner_id = p_learner and code = p_code;
end $$;

-- p_verified_production is TRUE only when the caller is a server-graded
-- production path. Self-reported review grades must pass false.
create or replace function learning.schedule_review_internal(
  p_learner uuid, p_item_type text, p_item_id uuid,
  p_grade int, p_verified_production boolean default false
) returns timestamptz
language plpgsql security definer set search_path = '' as $$
declare
  r learning.review_queue%rowtype;
  v_stab numeric; v_diff numeric; v_due timestamptz;
begin
  if p_grade not between 1 and 4 then raise exception 'grade must be 1..4'; end if;

  insert into learning.review_queue (learner_id, item_type, item_id)
  values (p_learner, p_item_type, p_item_id)
  on conflict (learner_id, item_type, item_id) do nothing;

  select * into r from learning.review_queue
   where learner_id = p_learner and item_type = p_item_type and item_id = p_item_id
   for update;

  v_diff := greatest(1, least(10, coalesce(r.difficulty, 5.0) + (3 - p_grade) * 0.5));

  if r.stability is null then
    v_stab := case p_grade when 1 then 0.4 when 2 then 0.9 when 3 then 2.5 else 5.0 end;
  elsif p_grade = 1 then
    v_stab := greatest(0.3, r.stability * 0.35);
  else
    v_stab := r.stability * (1 + (2.6 - v_diff * 0.12) * (0.4 + 0.25 * (p_grade - 2)));
  end if;

  -- Clamp stability. Unbounded exponential growth overflowed the timestamp
  -- after ~40 consecutive easy grades (caught by test I41 aborting with
  -- "timestamp out of range"). A ten-year ceiling is far beyond any real
  -- review horizon and keeps due_at representable.
  v_stab := least(v_stab, 3650);
  v_due  := now() + (greatest(0.02, v_stab) || ' days')::interval;

  update learning.review_queue set
    stability    = v_stab,
    difficulty   = v_diff,
    due_at       = v_due,
    last_review  = now(),
    reps         = r.reps + 1,
    lapses       = r.lapses + case when p_grade = 1 then 1 else 0 end,
    receptive_p  = greatest(0, least(1, r.receptive_p
                     + case when p_grade >= 3 then 0.15 else -0.20 end)),
    productive_p = case when p_verified_production
                     then greatest(0, least(1, r.productive_p
                       + case when p_grade >= 3 then 0.20 else -0.25 end))
                     else r.productive_p end,
    state = case
      when p_grade = 1 then 'lapsed'
      -- 'mastered' additionally requires verified productive evidence, so a
      -- learner cannot tap their way to mastery.
      when v_stab >= 60 and r.productive_p >= 0.7 and p_verified_production
        then 'mastered'
      when r.reps + 1 <= 2 then 'learning'
      else 'review' end
  where learner_id = p_learner and item_type = p_item_type and item_id = p_item_id;

  return v_due;
end $$;

-- ==================================================== CLIENT-CALLABLE ======
-- No learner identity parameter anywhere below this line.

-- v1 took p_productive from the client, so a learner could self-certify
-- productive mastery of a word by tapping "easy". Self-report now only drives
-- SCHEDULING (when to see it again) and receptive confidence. Productive
-- mastery and the 'mastered' state require server-graded production evidence,
-- which arrives through submit_attempt / speech evaluation, never from a tap.
create or replace function learning.grade_review(
  p_item_type text, p_item_id uuid, p_grade int
) returns timestamptz
language plpgsql security definer set search_path = '' as $$
declare v_learner uuid := (select auth.uid()); v_exists boolean;
begin
  if v_learner is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_item_type not in ('sense','collocation','concept','pron_target') then
    raise exception 'invalid item type';
  end if;
  -- The item must be real; otherwise a client could fill its own review queue
  -- with arbitrary uuids and distort its daily plan.
  if p_item_type = 'sense' then
    v_exists := exists (select 1 from content.vocabulary_senses where id = p_item_id);
  elsif p_item_type = 'collocation' then
    v_exists := exists (select 1 from content.collocations where id = p_item_id);
  elsif p_item_type = 'concept' then
    v_exists := exists (select 1 from content.grammar_concepts
                         where id = p_item_id and status = 'published');
  else
    v_exists := exists (select 1 from content.pronunciation_targets where id = p_item_id);
  end if;
  if not v_exists then
    raise exception 'unknown review item' using errcode = '23503';
  end if;
  return learning.schedule_review_internal(
           v_learner, p_item_type, p_item_id, p_grade, false);
end $$;

-- ------------------------------------------------------------ answer check --
-- Two validation modes. `pattern` exists so an exercise can grade the
-- grammatical frame while accepting any proper noun in the slot — see the
-- "Me llamo <your name>" exercise in the seed.
-- Normalisation must be applied SYMMETRICALLY. v2 stripped trailing
-- punctuation from the learner's input but not from the accepted strings, so
-- the correct answer to the vosotros exercise ("¿Cómo os llamáis?") was graded
-- WRONG. Caught by test I5; the earlier suite only ever fed that exercise
-- incorrect answers, so the bug hid behind passing tests.
create or replace function assess.normalise_answer(p_text text, p_accent_insensitive boolean)
returns text
language sql immutable set search_path = '' as $$
  select case when p_accent_insensitive
              then translate(x, 'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN')
              else x end
  from (
    select regexp_replace(
             lower(btrim(regexp_replace(coalesce(p_text, ''), '\s+', ' ', 'g'))),
             '[.!?¡¿]+$', '') as x
  ) t;
$$;

create or replace function assess.check_answer(p_given text, p_rules jsonb)
returns boolean
language plpgsql immutable set search_path = '' as $$
declare
  v_ai      boolean := coalesce((p_rules ->> 'accent_insensitive')::boolean, false);
  v_given   text := assess.normalise_answer(p_given, v_ai);
  v_pattern text := p_rules ->> 'pattern';
  v_accepted text[];
begin
  if v_pattern is not null then
    return v_given ~ v_pattern;
  end if;

  select array_agg(assess.normalise_answer(x, v_ai))
    into v_accepted
    from jsonb_array_elements_text(coalesce(p_rules -> 'accepted', '[]'::jsonb)) x;

  return v_given = any(coalesce(v_accepted, array[]::text[]));
end $$;

-- ---------------------------------------------------------- submit_attempt --
create or replace function assess.submit_attempt(
  p_attempt_id  uuid,
  p_exercise_id uuid,
  p_answer      jsonb,
  p_session_id  uuid,
  p_latency_ms  int default null,
  p_modality    text default 'typed'
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_learner  uuid := (select auth.uid());
  v_prior    jsonb;
  v_owner    uuid;
  v_ex       content.exercises%rowtype;
  v_tpl      content.exercise_templates%rowtype;
  v_correct  boolean;
  v_codes    text[] := '{}';
  v_p        numeric;
  v_expected text;
  v_out      jsonb;
  c          text;
begin
  if v_learner is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- Idempotent replay, scoped by a composite ownership check. A key belonging
  -- to another learner returns the same generic conflict as a malformed key:
  -- the caller learns nothing about who owns it.
  select learner_id, response into v_owner, v_prior
    from assess.attempt_idempotency where idempotency_key = p_attempt_id;

  if v_owner is not null then
    if v_owner <> v_learner then
      raise exception 'attempt id conflict' using errcode = '23505';
    end if;
    -- Same learner, same key: return the identical stored payload and write
    -- nothing. No second attempt row, no second mastery update, no second
    -- error-pattern increment.
    return v_prior || jsonb_build_object('replayed', true);
  end if;

  -- Session must exist, belong to the caller, and still be open.
  if not exists (
    select 1 from learning.study_sessions
     where id = p_session_id and learner_id = v_learner and ended_at is null) then
    raise exception 'no open session for this learner' using errcode = '42501';
  end if;
  update learning.study_sessions set last_seen_at = now() where id = p_session_id;

  select * into v_ex from content.exercises
   where id = p_exercise_id and status = 'published';
  if not found then raise exception 'exercise not found or not published'; end if;
  select * into v_tpl from content.exercise_templates where id = v_ex.template_id;

  v_correct := assess.check_answer(p_answer ->> 'value', v_ex.answer_rules);

  if not v_correct then
    select coalesce(array_agg(x), '{}') into v_codes
      from jsonb_array_elements_text(
             coalesce(v_ex.answer_rules -> 'error_codes', '[]'::jsonb)) x;
  end if;

  insert into assess.exercise_attempts
    (id, learner_id, exercise_id, objective_id, raw_answer, is_correct,
     error_codes, latency_ms, modality, session_id)
  values
    (p_attempt_id, v_learner, p_exercise_id, v_ex.objective_id, p_answer, v_correct,
     v_codes, p_latency_ms, p_modality, p_session_id);

  if v_ex.objective_id is not null then
    v_p := learning.record_evidence_internal(
             v_learner, v_ex.objective_id, v_tpl.evidence_kind, v_correct, v_ex.concept_id);
  end if;

  if not v_correct then
    foreach c in array v_codes loop
      perform learning.record_error_code_internal(v_learner, c, p_session_id);
    end loop;
  end if;

  -- With a `pattern` rule there is no single canonical string, so show the
  -- worked model instead of pretending one accepted answer exists.
  v_expected := coalesce(
    v_ex.answer_rules -> 'accepted' ->> 0,
    v_ex.answer_rules ->> 'model_answer');

  v_out := jsonb_build_object(
    'is_correct',     v_correct,
    'your_answer',    p_answer ->> 'value',
    'correct',        v_expected,
    'what_changed',   v_ex.feedback ->> 'what_changed',
    'why_th',         v_ex.feedback ->> 'why_th',
    'rule_concept',   v_ex.concept_id,
    'contrast',       v_ex.feedback -> 'contrast',
    'error_codes',    to_jsonb(v_codes),
    'p_mastery',      v_p,
    'can_retry',      true,
    'deep_available', v_ex.concept_id is not null,
    'replayed',       false);

  insert into assess.attempt_idempotency (idempotency_key, learner_id, kind, response)
  values (p_attempt_id, v_learner, 'exercise', v_out);

  return v_out;
end $$;

-- --------------------------------------------------------- complete_lesson --
-- v1 DEFECTS:
--   (a) it UPSERTed progress then unconditionally incremented xp,
--       lessons_completed and total_minutes, so calling it N times for the
--       same lesson awarded N times. Repeated or concurrent calls farmed XP.
--   (b) it granted completion to anyone who could name a published lesson id,
--       with no evidence that any learning happened. A trust button.
--
-- v2: the award is guarded by an INSERT ... ON CONFLICT DO NOTHING on the
-- unique (learner_id, lesson_id) progress key. Only the transaction that
-- actually transitions the row to 'completed' awards stats, and the row is
-- locked FOR UPDATE so two concurrent calls serialise: the loser observes
-- 'completed' and awards nothing. Evidence requirements come from the
-- lesson's authored completion_rules.
create or replace function learning.complete_lesson(p_lesson_id uuid)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_learner  uuid := (select auth.uid());
  v_min      int;
  v_rules    jsonb;
  v_state    text;
  v_missing  text[] := '{}';
  v_req      uuid;
  v_awarded  boolean := false;
  v_streak   int;
begin
  if v_learner is null then raise exception 'not authenticated' using errcode = '28000'; end if;

  select l.estimated_minutes, lv.completion_rules
    into v_min, v_rules
  from content.lessons l
  join content.lesson_versions lv
    on lv.lesson_id = l.id and lv.version = l.current_version
  where l.id = p_lesson_id and l.status = 'published';
  if not found then raise exception 'lesson not found or not published'; end if;

  -- An empty contract is a configuration error, not a free pass.
  if v_rules is null or v_rules = '{}'::jsonb then
    raise exception 'lesson % has no completion_rules; refusing to grant completion',
      p_lesson_id using errcode = '23514';
  end if;

  -- Lock the progress row first so concurrent duplicates serialise here.
  insert into learning.lesson_progress (learner_id, lesson_id, state, started_at)
  values (v_learner, p_lesson_id, 'in_progress', now())
  on conflict (learner_id, lesson_id) do nothing;

  select state into v_state from learning.lesson_progress
   where learner_id = v_learner and lesson_id = p_lesson_id
   for update;

  if v_state = 'completed' then
    -- Idempotent: no XP, no counters, no streak mutation, no second award.
    return jsonb_build_object('completed', true, 'awarded', false,
                              'already_completed', true, 'missing', '[]'::jsonb);
  end if;

  -- Evidence check: every required exercise needs a CORRECT attempt.
  for v_req in
    select (x)::uuid from jsonb_array_elements_text(
             coalesce(v_rules -> 'required_correct_exercises', '[]'::jsonb)) x
  loop
    if not exists (select 1 from assess.exercise_attempts
                    where learner_id = v_learner and exercise_id = v_req
                      and is_correct) then
      v_missing := v_missing || ('correct:' || v_req::text);
    end if;
  end loop;

  -- Speech tasks need an EVALUATED submission. An inconclusive recognition
  -- still counts as having done the work: the learner spoke, and blocking
  -- progress on an ASR failure would punish them for our tooling.
  for v_req in
    select (x)::uuid from jsonb_array_elements_text(
             coalesce(v_rules -> 'required_speech_exercises', '[]'::jsonb)) x
  loop
    if not exists (select 1 from assess.speech_submissions sub
                    join assess.speech_evaluations ev on ev.submission_id = sub.id
                   where sub.learner_id = v_learner and sub.exercise_id = v_req) then
      v_missing := v_missing || ('speech:' || v_req::text);
    end if;
  end loop;

  if array_length(v_missing, 1) > 0 then
    return jsonb_build_object('completed', false, 'awarded', false,
                              'already_completed', false,
                              'missing', to_jsonb(v_missing));
  end if;

  update learning.lesson_progress
     set state = 'completed', completed_at = now(), updated_at = now()
   where learner_id = v_learner and lesson_id = p_lesson_id
     and state <> 'completed';
  v_awarded := found;

  if v_awarded then
    insert into learning.learner_stats (learner_id) values (v_learner)
    on conflict (learner_id) do nothing;

    select case
      when last_active_date = current_date then current_streak
      when last_active_date = current_date - 1 then current_streak + 1
      else 1 end
      into v_streak
    from learning.learner_stats where learner_id = v_learner for update;

    update learning.learner_stats set
      lessons_completed = lessons_completed + 1,
      total_minutes     = total_minutes + coalesce(v_min, 0),
      xp                = xp + 20,
      current_streak    = v_streak,
      longest_streak    = greatest(longest_streak, v_streak),
      last_active_date  = current_date
    where learner_id = v_learner;
  end if;

  return jsonb_build_object('completed', true, 'awarded', v_awarded,
                            'already_completed', false, 'missing', '[]'::jsonb);
end $$;

-- ================================================ SPEECH: submit + evaluate =
-- The learner states client facts only. Everything derived is written by the
-- evaluator through the internal function below.
create or replace function assess.submit_speech(
  p_submission_id uuid,
  p_exercise_id   uuid,
  p_session_id    uuid,
  p_audio_path    text default null,
  p_duration_ms   int default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_learner uuid := (select auth.uid());
  v_target  uuid;
begin
  if v_learner is null then raise exception 'not authenticated' using errcode = '28000'; end if;

  if exists (select 1 from assess.speech_submissions
              where id = p_submission_id and learner_id = v_learner) then
    return p_submission_id;                       -- idempotent replay
  end if;
  if exists (select 1 from assess.speech_submissions where id = p_submission_id) then
    raise exception 'submission id conflict' using errcode = '23505';
  end if;

  if not exists (select 1 from learning.study_sessions
                  where id = p_session_id and learner_id = v_learner and ended_at is null) then
    raise exception 'no open session for this learner' using errcode = '42501';
  end if;

  -- Audio must live under the learner's own folder in the private bucket.
  if p_audio_path is not null
     and p_audio_path not like ('learner-audio/' || v_learner::text || '/%') then
    raise exception 'audio path must be inside the caller own folder'
      using errcode = '42501';
  end if;

  select (select id from content.pronunciation_targets
           where slug = e.payload ->> 'pron_target_slug')
    into v_target
  from content.exercises e where e.id = p_exercise_id and e.status = 'published';

  insert into assess.speech_submissions
    (id, learner_id, session_id, exercise_id, pron_target_id, audio_path, client_duration_ms)
  values
    (p_submission_id, v_learner, p_session_id, p_exercise_id, v_target,
     p_audio_path, p_duration_ms);

  return p_submission_id;
end $$;

-- THE EVIDENCE BOUNDARY.
-- Every route from speech to the learner model passes through here, and
-- verdict='inconclusive' returns before any evidence call. The rule is
-- enforced by control flow, not by a comment or a table semantic.
create or replace function assess.record_speech_evaluation_internal(
  p_submission_id  uuid,
  p_transcript_raw text,
  p_transcript_norm text,
  p_confidence     numeric,
  p_verdict        text,
  p_issues         text[] default '{}',
  p_scored_frame   text default null,
  p_model          text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_sub     assess.speech_submissions%rowtype;
  v_obj     uuid;
  v_issues  text[] := coalesce(p_issues, '{}');
  c         text;
  v_wrote   boolean := false;
begin
  select * into v_sub from assess.speech_submissions where id = p_submission_id;
  if not found then raise exception 'unknown submission'; end if;

  if p_verdict = 'inconclusive' then
    v_issues := '{}';        -- belt and braces; a CHECK also enforces this
  end if;

  insert into assess.speech_evaluations
    (submission_id, scored_frame, transcript_raw, transcript_norm,
     asr_confidence, verdict, detected_issues, model)
  values
    (p_submission_id, p_scored_frame, p_transcript_raw, p_transcript_norm,
     p_confidence, p_verdict, v_issues, p_model)
  on conflict (submission_id) do nothing;

  -- ---- the invariant -----------------------------------------------------
  if p_verdict = 'inconclusive' then
    return jsonb_build_object('verdict', p_verdict, 'evidence_written', false,
      'message_th','ระบบไม่แน่ใจว่าได้ยินถูกหรือไม่ ลองพูดอีกครั้งในที่เงียบกว่านี้');
  end if;
  -- ------------------------------------------------------------------------

  select objective_id into v_obj from content.exercises where id = v_sub.exercise_id;

  if v_obj is not null then
    perform learning.record_evidence_internal(
      v_sub.learner_id, v_obj, 'free_spoken', p_verdict = 'ok', null);
    v_wrote := true;
  end if;

  if p_verdict = 'issue' then
    foreach c in array v_issues loop
      perform learning.record_error_code_internal(v_sub.learner_id, c, v_sub.session_id);
    end loop;
    v_wrote := true;
  end if;

  update assess.speech_evaluations
     set evidence_written = v_wrote where submission_id = p_submission_id;

  return jsonb_build_object('verdict', p_verdict, 'evidence_written', v_wrote);
end $$;

-- ============================================= ASSESSMENT STATE MACHINE ====
-- in_progress -> submitted -> scored, plus in_progress -> abandoned.
-- No other transition exists, and none is reachable by a direct table write.
create or replace function assess.start_assessment(p_kind text, p_level content.cefr default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_learner uuid := (select auth.uid()); v_id uuid := gen_random_uuid();
begin
  if v_learner is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_kind not in ('placement','mastery_check','level_assessment','mock_exam') then
    raise exception 'invalid assessment kind';
  end if;
  insert into assess.assessment_attempts (id, learner_id, kind, level, state, started_at)
  values (v_id, v_learner, p_kind, p_level, 'in_progress', now());
  return v_id;
end $$;

create or replace function assess.submit_assessment(p_id uuid, p_responses jsonb default '{}'::jsonb)
returns void
language plpgsql security definer set search_path = '' as $$
declare v_learner uuid := (select auth.uid()); v_state text;
begin
  if v_learner is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  select state into v_state from assess.assessment_attempts
   where id = p_id and learner_id = v_learner for update;
  if not found then raise exception 'assessment not found' using errcode = '42501'; end if;
  if v_state <> 'in_progress' then
    raise exception 'cannot submit an assessment in state %', v_state using errcode = '23514';
  end if;
  -- responses only; result/theta/se remain untouched and unscored
  update assess.assessment_attempts
     set state = 'submitted', submitted_at = now(),
         result = jsonb_build_object('responses', p_responses)
   where id = p_id;
end $$;

create or replace function assess.abandon_assessment(p_id uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare v_learner uuid := (select auth.uid());
begin
  if v_learner is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  update assess.assessment_attempts set state = 'abandoned'
   where id = p_id and learner_id = v_learner and state = 'in_progress';
end $$;

create or replace function assess.score_assessment_internal(
  p_id uuid, p_theta numeric, p_se numeric, p_profile jsonb, p_result jsonb
) returns void
language plpgsql security definer set search_path = '' as $$
declare v_state text;
begin
  select state into v_state from assess.assessment_attempts where id = p_id for update;
  if v_state <> 'submitted' then
    raise exception 'only a submitted assessment can be scored (state=%)', v_state
      using errcode = '23514';
  end if;
  update assess.assessment_attempts
     set state = 'scored', theta = p_theta, se = p_se,
         skill_profile = p_profile, result = p_result
   where id = p_id;
end $$;

-- ====================================================== CONVERSATION =======
create or replace function ai.end_conversation(p_session_id uuid, p_abandoned boolean default false)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  update ai.conversation_sessions
     set state = case when p_abandoned then 'abandoned' else 'ended' end,
         ended_at = now()
   where id = p_session_id
     and learner_id = (select auth.uid())
     and state = 'active';
end $$;

create or replace function ai.append_tutor_message_internal(
  p_session_id uuid, p_content text, p_audio_path text default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  insert into ai.conversation_messages
    (session_id, role, content, audio_path, authored_by)
  values (p_session_id, 'tutor', p_content, p_audio_path, 'server')
  returning id into v_id;
  return v_id;
end $$;

create or replace function ai.write_debrief_internal(p_session_id uuid, p_debrief jsonb)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  update ai.conversation_sessions set debrief = p_debrief where id = p_session_id;
end $$;

-- -------------------------------------------------------------- daily plan --
create or replace function learning.build_daily_plan(p_budget_min int default null)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_learner uuid := (select auth.uid());
  v_budget int; v_due int; v_gap record; v_next record;
  v_items jsonb := '[]'::jsonb; v_left int; v_m int;
begin
  if v_learner is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_budget_min is not null and (p_budget_min < 1 or p_budget_min > 240) then
    raise exception 'budget out of range';
  end if;

  select coalesce(p_budget_min, daily_goal_minutes) into v_budget
    from learning.learner_preferences where learner_id = v_learner;
  v_budget := coalesce(v_budget, 15);
  v_left := v_budget;

  select count(*) into v_due from learning.review_queue
   where learner_id = v_learner and due_at <= now() and state <> 'suspended';
  if v_due > 0 then
    v_m := least(ceil(v_budget * 0.30)::int, greatest(1, ceil(v_due / 8.0)::int));
    v_items := v_items || jsonb_build_object('kind','review','minutes',v_m,
                 'count',v_due,'label_th','ทบทวนคำศัพท์');
    v_left := v_left - v_m;
  end if;

  select gm.concept_id, gc.name_th into v_gap
    from learning.grammar_mastery gm
    join content.grammar_concepts gc on gc.id = gm.concept_id
   where gm.learner_id = v_learner and gm.p_mastery < 0.5 and gm.evidence_count >= 3
   order by gm.p_mastery asc limit 1;
  if found and v_left >= 3 then
    v_m := least(ceil(v_budget * 0.20)::int, v_left);
    v_items := v_items || jsonb_build_object('kind','remediation',
                 'concept_id',v_gap.concept_id,'minutes',v_m,
                 'label_th','ทบทวนไวยากรณ์: ' || v_gap.name_th);
    v_left := v_left - v_m;
  end if;

  select l.id, lv.title_th, l.estimated_minutes into v_next
    from content.lessons l
    join content.lesson_versions lv
      on lv.lesson_id = l.id and lv.version = l.current_version
    left join learning.lesson_progress lp
      on lp.lesson_id = l.id and lp.learner_id = v_learner
   where l.status = 'published' and coalesce(lp.state,'not_started') <> 'completed'
   order by l.sort_order limit 1;
  if found and v_left > 0 then
    v_m := least(v_next.estimated_minutes, v_left);
    v_items := v_items || jsonb_build_object('kind','lesson','lesson_id',v_next.id,
                 'minutes',v_m,'label_th',v_next.title_th);
    v_left := v_left - v_m;
  end if;

  if v_left >= 3 then
    v_items := v_items || jsonb_build_object('kind','skill_practice','minutes',v_left,
      'skill', coalesce((select dimension::text from learning.skill_estimates
                          where learner_id = v_learner
                          order by theta asc, (dimension = 'speaking') desc limit 1),'speaking'),
      'label_th','ฝึกพูด');
  end if;

  insert into learning.study_plans (learner_id, plan_date, budget_min, items)
  values (v_learner, current_date, v_budget, v_items)
  on conflict (learner_id, plan_date) do update
    set items = excluded.items, budget_min = excluded.budget_min;

  return jsonb_build_object('budget_min', v_budget, 'items', v_items);
end $$;

-- -------------------------------------------------------- account deletion --
create or replace function learning.delete_my_account()
returns void
language plpgsql security definer set search_path = '' as $$
declare v_learner uuid := (select auth.uid());
begin
  if v_learner is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  update analytics.events set learner_id = null where learner_id = v_learner;
  delete from auth.users where id = v_learner;
end $$;

-- ========================================================= PRIVILEGES ======
-- Internal writers: unreachable by any client role.
revoke all on function
  learning.record_evidence_internal(uuid,uuid,content.evidence_kind,boolean,uuid),
  learning.record_error_code_internal(uuid,text,uuid),
  learning.schedule_review_internal(uuid,text,uuid,int,boolean),
  assess.record_speech_evaluation_internal(uuid,text,text,numeric,text,text[],text,text),
  assess.score_assessment_internal(uuid,numeric,numeric,jsonb,jsonb),
  ai.append_tutor_message_internal(uuid,text,text),
  ai.write_debrief_internal(uuid,jsonb),
  ai.guard_message_authorship(),
  learning.reject_client_write(),
  learning.guard_lesson_completion()
  from public, anon, authenticated;

-- Role helpers are referenced INSIDE content RLS policies, so client roles must
-- be able to execute them. Caught by test D5.6: without this grant the blanket
-- revoke above silently made ALL curriculum unreadable to every learner.
grant execute on function admin.jwt_role(), admin.is_editor(), admin.is_admin()
  to authenticated, anon;

-- Pin search_path on the remaining trigger/helper functions and keep them off
-- the client surface. Found by the function audit, not by a failing test.
alter function learning.reject_client_write()     set search_path = '';
alter function learning.guard_lesson_completion() set search_path = '';
alter function content.touch_updated_at()         set search_path = '';
alter function learning.evidence_weight(content.evidence_kind) set search_path = '';
revoke all on function content.touch_updated_at(),
                       learning.evidence_weight(content.evidence_kind)
  from public, anon, authenticated;

-- Client-callable surface. Every one of these derives identity from auth.uid().
grant execute on function
  learning.start_session(text,uuid),
  learning.end_session(uuid),
  learning.grade_review(text,uuid,int),
  learning.complete_lesson(uuid),
  assess.submit_speech(uuid,uuid,uuid,text,int),
  assess.start_assessment(text,content.cefr),
  assess.submit_assessment(uuid,jsonb),
  assess.abandon_assessment(uuid),
  ai.end_conversation(uuid,boolean),
  learning.build_daily_plan(int),
  learning.delete_my_account(),
  assess.submit_attempt(uuid,uuid,jsonb,uuid,int,text),
  assess.check_answer(text,jsonb),
  assess.normalise_answer(text,boolean)
  to authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function learning.handle_new_user();
