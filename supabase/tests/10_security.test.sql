-- ============================================================================
-- 10_security.test.sql — pgTAP authorization suite.
-- Run: psql -f 00_shim_local_only.sql -f <migrations...> -f 01_helpers... -f this
-- Covers the defects raised in review plus the wider RLS matrix.
-- ============================================================================
begin;
create extension if not exists pgtap;
select plan(50);

-- fixtures ------------------------------------------------------------------
select tests.mk_learner('a@test') as a \gset
select tests.mk_learner('b@test') as b \gset

-- =========================================================== 1. DERIVED ====
-- A learner must not be able to CREATE server-computed measurements.
-- v1 allowed exactly this: INSERT was granted and the guard only saw UPDATE.

select tests.claim_as(:'a'::uuid); set role authenticated;

select throws_ok(
  format($$insert into learning.objective_mastery
            (learner_id, objective_id, p_mastery)
          values (%L, '33333333-3333-4333-8333-333333333302', 1.0)$$, :'a'),
  NULL, 'D1.1 learner cannot insert p_mastery = 1');

select throws_ok(
  format($$insert into learning.grammar_mastery (learner_id, concept_id, p_mastery)
          values (%L, '11111111-1111-4111-8111-111111111102', 1.0)$$, :'a'),
  NULL, 'D1.2 learner cannot insert arbitrary grammar mastery');

select throws_ok(
  format($$insert into learning.skill_estimates (learner_id, dimension, theta, se)
          values (%L, 'speaking', 9.0, 0.01)$$, :'a'),
  NULL, 'D1.3 learner cannot insert arbitrary theta / standard error');

select throws_ok(
  format($$update learning.learner_stats set xp = 999999 where learner_id = %L$$, :'a'),
  NULL, 'D1.4 learner cannot update XP');

select throws_ok(
  format($$insert into learning.learner_stats (learner_id, xp) values (%L, 999999)$$, :'a'),
  NULL, 'D1.5 learner cannot insert XP');

select throws_ok(
  format($$insert into learning.learner_error_patterns
            (learner_id, code, occurrence_count, session_count, status)
          values (%L, 'PRON.LL_Y', 99, 99, 'resolved')$$, :'a'),
  NULL, 'D1.6 learner cannot forge error-pattern counts');

select throws_ok(
  format($$insert into learning.review_queue (learner_id, item_type, item_id, state)
          values (%L, 'sense', '88888888-8888-4888-8888-888888888801', 'mastered')$$, :'a'),
  NULL, 'D1.7 learner cannot forge review state');

select throws_ok(
  format($$insert into learning.study_sessions (learner_id, kind) values (%L, 'lesson')$$, :'a'),
  NULL, 'D1.8 learner cannot fabricate a study session directly');

select throws_ok(
  format($$insert into assess.exercise_attempts
            (id, learner_id, exercise_id, raw_answer, is_correct)
          values (gen_random_uuid(), %L,
                  '66666666-6666-4666-8666-666666666601', '{}'::jsonb, true)$$, :'a'),
  NULL, 'D1.9 learner cannot insert an attempt directly (is_correct is server-owned)');

select throws_ok(
  format($$insert into learning.lesson_progress (learner_id, lesson_id, state)
          values (%L, '44444444-4444-4444-8444-444444444403', 'completed')$$, :'a'),
  NULL, 'D1.10 learner cannot self-declare a lesson complete');

-- but the legitimately-owned parts still work
select lives_ok(
  format($$insert into learning.lesson_progress (learner_id, lesson_id, state, last_block_index)
          values (%L, '44444444-4444-4444-8444-444444444403', 'in_progress', 2)$$, :'a'),
  'D1.11 learner CAN record their own reading position');

select lives_ok(
  format($$update learning.learner_preferences set daily_goal_minutes = 30
           where learner_id = %L$$, :'a'),
  'D1.12 learner CAN change their own preferences');

-- ============================================ 2. CROSS-USER RPC (schedule) ==
-- v1: schedule_review(p_learner uuid,...) was granted to authenticated.

select is(
  (select count(*)::int from information_schema.role_routine_grants
   where routine_name = 'schedule_review' and grantee in ('authenticated','anon','public')),
  0, 'D2.1 the uuid-taking scheduler is not callable by any client role');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='learning' and p.proname='schedule_review'),
  0, 'D2.2 the v1 client-callable schedule_review signature no longer exists');

select throws_ok(
  format($$select learning.schedule_review_internal(%L,'sense',
             '88888888-8888-4888-8888-888888888801',4)$$, :'b'),
  '42501', NULL,
  'D2.3 learner A cannot invoke the internal writer against learner B');

-- the safe surface works and is self-scoped
select lives_ok(
  $$select learning.grade_review('sense','88888888-8888-4888-8888-888888888801',3)$$,
  'D2.4 grade_review works for the caller');

select is(
  (select count(*)::int from learning.review_queue where learner_id = :'a'::uuid),
  1, 'D2.5 grade_review wrote to the CALLER queue');

reset role;
select is(
  (select count(*)::int from learning.review_queue where learner_id = :'b'::uuid),
  0, 'D2.6 learner B queue was never touched');

-- A cannot read B's review data
select tests.claim_as(:'b'::uuid); set role authenticated;
select lives_ok($$select learning.grade_review('sense',
  '88888888-8888-4888-8888-888888888802',4)$$, 'D2.7 B can grade their own');
reset role;
select tests.claim_as(:'a'::uuid); set role authenticated;
select is((select count(*)::int from learning.review_queue), 1,
  'D2.8 A sees only their own review rows (RLS read isolation)');

-- ============================================== 3. submit_attempt integrity ==
reset role;
select tests.claim_as(:'a'::uuid); set role authenticated;
select learning.start_session('lesson','44444444-4444-4444-8444-444444444403') as sa \gset

-- first submission
select is(
  (assess.submit_attempt('aaaaaaa1-0000-4000-8000-000000000001'::uuid,
     '66666666-6666-4666-8666-666666666601'::uuid,
     '{"value":"Me llamo Somchai"}'::jsonb, :'sa'::uuid) ->> 'is_correct')::boolean,
  true, 'D3.1 frame-based grading accepts a name that is not the seeded one');

select is(
  (select count(*)::int from assess.exercise_attempts where learner_id = :'a'::uuid),
  1, 'D3.2 one attempt row');

-- replay: this is the branch that raised a type error in v1
select lives_ok(
  $$select assess.submit_attempt('aaaaaaa1-0000-4000-8000-000000000001'::uuid,
      '66666666-6666-4666-8666-666666666601'::uuid,
      '{"value":"Me llamo Somchai"}'::jsonb,
      (select id from learning.study_sessions limit 1))$$,
  'D3.3 replay does not raise (v1 selected jsonb into a boolean)');

select is(
  (assess.submit_attempt('aaaaaaa1-0000-4000-8000-000000000001'::uuid,
     '66666666-6666-4666-8666-666666666601'::uuid,
     '{"value":"anything else"}'::jsonb, :'sa'::uuid) ->> 'replayed')::boolean,
  true, 'D3.4 replay returns the stored response, ignoring the new payload');

select is(
  (select count(*)::int from assess.exercise_attempts where learner_id = :'a'::uuid),
  1, 'D3.5 replay created no duplicate attempt');

select is(
  (select evidence_count from learning.objective_mastery
    where learner_id = :'a'::uuid
      and objective_id = '33333333-3333-4333-8333-333333333302'),
  1, 'D3.6 replay created no duplicate mastery evidence');

-- different learner, same key
reset role;
select tests.claim_as(:'b'::uuid); set role authenticated;
select learning.start_session('lesson') as sb \gset
select throws_ok(
  format($$select assess.submit_attempt('aaaaaaa1-0000-4000-8000-000000000001'::uuid,
      '66666666-6666-4666-8666-666666666601'::uuid,
      '{"value":"Me llamo Beto"}'::jsonb, %L)$$, :'sb'),
  '23505', NULL,
  'D3.7 learner B reusing A''s idempotency key is rejected, and learns nothing');

select is(
  (select count(*)::int from assess.exercise_attempts),
  0, 'D3.8 B cannot see A''s attempt through RLS');

-- session must belong to the caller
reset role;
select tests.claim_as(:'a'::uuid); set role authenticated;
select throws_ok(
  format($$select assess.submit_attempt(gen_random_uuid(),
     '66666666-6666-4666-8666-666666666601'::uuid,
     '{"value":"Me llamo X"}'::jsonb, %L)$$, :'sb'),
  '42501', NULL, 'D3.9 A cannot submit into B''s session');

-- ================================== 4. error pattern / session evidence ====
-- Three wrong answers inside ONE session must not create a recurring pattern.
select assess.submit_attempt('aaaaaaa2-0000-4000-8000-000000000001'::uuid,
  '66666666-6666-4666-8666-666666666602'::uuid, '{"value":"¿Cómo se llaman ustedes?"}'::jsonb, :'sa'::uuid);
select assess.submit_attempt('aaaaaaa2-0000-4000-8000-000000000002'::uuid,
  '66666666-6666-4666-8666-666666666602'::uuid, '{"value":"¿Cómo te llamas?"}'::jsonb, :'sa'::uuid);
select assess.submit_attempt('aaaaaaa2-0000-4000-8000-000000000003'::uuid,
  '66666666-6666-4666-8666-666666666602'::uuid, '{"value":"¿Cómo se llama?"}'::jsonb, :'sa'::uuid);

select is(
  (select occurrence_count from learning.learner_error_patterns
    where learner_id = :'a'::uuid and code = 'GRAM.ADDRESS'),
  3, 'D4.1 three occurrences recorded');

select is(
  (select session_count from learning.learner_error_patterns
    where learner_id = :'a'::uuid and code = 'GRAM.ADDRESS'),
  1, 'D4.2 three mistakes in ONE session count as one session');

select is(
  (select status from learning.learner_error_patterns
    where learner_id = :'a'::uuid and code = 'GRAM.ADDRESS'),
  'observed', 'D4.3 3 mistakes in 1 session is NOT a recurring pattern');

-- simulate a genuinely separate sitting: close the session and age the clock
reset role;
update learning.study_sessions set ended_at = now(), last_seen_at = now() - interval '2 hours';
update learning.learner_error_patterns
   set last_counted_session_at = now() - interval '2 hours';
select tests.claim_as(:'a'::uuid); set role authenticated;

select learning.start_session('lesson') as sa2 \gset
select isnt(:'sa2'::text, :'sa'::text, 'D4.4 a new sitting yields a new session id');

select assess.submit_attempt('aaaaaaa3-0000-4000-8000-000000000001'::uuid,
  '66666666-6666-4666-8666-666666666602'::uuid, '{"value":"¿Cómo te llamas?"}'::jsonb, :'sa2'::uuid);

select is(
  (select session_count from learning.learner_error_patterns
    where learner_id = :'a'::uuid and code = 'GRAM.ADDRESS'),
  2, 'D4.5 a later, separate session increments session_count');

select is(
  (select status from learning.learner_error_patterns
    where learner_id = :'a'::uuid and code = 'GRAM.ADDRESS'),
  'recurring', 'D4.6 >=3 occurrences across >=2 sessions becomes recurring');

-- a single mistake never becomes a weakness
select is(
  (select count(*)::int from learning.learner_error_patterns
    where learner_id = :'a'::uuid and code = 'GRAM.PERSON' and status <> 'observed'),
  0, 'D4.7 one mistake alone is never a weakness');

-- session-spam cannot inflate the count
select learning.start_session('practice') as sp1 \gset
reset role;
update learning.study_sessions set ended_at = now(), last_seen_at = now() - interval '2 hours'
 where id = :'sa2'::uuid;
select tests.claim_as(:'a'::uuid); set role authenticated;
select learning.start_session('lesson') as sa3 \gset
select assess.submit_attempt('aaaaaaa4-0000-4000-8000-000000000001'::uuid,
  '66666666-6666-4666-8666-666666666602'::uuid, '{"value":"¿Cómo se llama?"}'::jsonb, :'sa3'::uuid);
select is(
  (select session_count from learning.learner_error_patterns
    where learner_id = :'a'::uuid and code = 'GRAM.ADDRESS'),
  2, 'D4.8 immediately opening another session does NOT inflate session_count');

-- ================================================ 5. RLS matrix (anon etc) ==
reset role;
select tests.claim_none(); set role anon;

select is((select count(*)::int from content.lessons), 1,
  'D5.1 anon reads published curriculum');
select throws_ok($$select count(*) from learning.profiles$$, NULL,
  'D5.2 anon cannot read learner profiles');
select throws_ok($$select count(*) from assess.exercise_attempts$$, NULL,
  'D5.3 anon cannot read attempts');
select throws_ok($$select learning.build_daily_plan()$$, NULL,
  'D5.4 anon cannot call learner RPCs');

reset role;
insert into content.lessons (id, unit_id, slug, sort_order, status)
values ('44444444-4444-4444-8444-4444444444ff',
        '22222222-2222-4222-8222-222222222203','draft-lesson',99,'draft');
select tests.claim_as(:'a'::uuid); set role authenticated;
select is((select count(*)::int from content.lessons where slug='draft-lesson'), 0,
  'D5.5 a learner cannot read unpublished curriculum');
reset role; select tests.claim_as(:'a'::uuid, 'editor'); set role authenticated;
select is((select count(*)::int from content.lessons where slug='draft-lesson'), 1,
  'D5.6 an editor CAN read unpublished curriculum');

reset role; select tests.claim_as(:'a'::uuid); set role authenticated;
select throws_ok($$select count(*) from admin.audit_logs$$, NULL,
  'D5.7 a learner cannot read the audit log');
select throws_ok(
  $$insert into admin.audit_logs (action, entity) values ('forge','x')$$, NULL,
  'D5.8 nobody inserts audit rows from a client');
select throws_ok($$select count(*) from analytics.events$$, NULL,
  'D5.9 analytics is write-only to clients');
select throws_ok($$select count(*) from ai.explanation_cache$$, NULL,
  'D5.10 AI cache is service-role only');

-- ============================================ 6. post-audit hardening ======
select tests.claim_as(:'a'::uuid); set role authenticated;
select throws_ok(
  $$select learning.grade_review('sense'::text,'00000000-0000-4000-8000-00000000dead'::uuid,3)$$,
  '23503', NULL, 'D6.1 cannot queue a review item that does not exist');

reset role;
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname in ('learning','assess','ai','admin','content')
      and p.proconfig is null),
  0, 'D6.2 every function in the app schemas has search_path pinned');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname in ('learning','assess','ai','admin')
      and p.prosecdef
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')
      and pg_get_function_arguments(p.oid) ~ '(learner|user)[_a-z]*\s+uuid'),
  0, 'D6.3 no client-callable DEFINER function accepts a learner identity');

reset role;
select * from finish();
rollback;
