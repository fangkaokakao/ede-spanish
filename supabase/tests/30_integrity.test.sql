-- ============================================================================
-- 30_integrity.test.sql — second-round integrity gate.
-- Every assertion here protects an invariant that a real attacker or a buggy
-- client could otherwise violate. No catalog padding.
-- ============================================================================
begin;
create extension if not exists pgtap;
select plan(41);

select tests.mk_learner('x@test') as x \gset
select tests.mk_learner('y@test') as y \gset

\set L  '44444444-4444-4444-8444-444444444403'
\set E1 '66666666-6666-4666-8666-666666666601'
\set E2 '66666666-6666-4666-8666-666666666602'
\set E3 '66666666-6666-4666-8666-666666666603'

-- ============================== 1+2. completion contract & idempotency ======

select tests.claim_as(:'x'::uuid); set role authenticated;
select learning.start_session('lesson', :'L') as sx \gset

-- opening the lesson is not completing it
select is(
  (learning.complete_lesson(:'L'::uuid) ->> 'completed')::boolean,
  false, 'I1 opening a lesson alone cannot complete it');

select is(
  jsonb_array_length(learning.complete_lesson(:'L'::uuid) -> 'missing'),
  3, 'I2 the refusal names every piece of missing evidence');

-- partial evidence still refused
select assess.submit_attempt('bbbbbbb1-0000-4000-8000-000000000001'::uuid,
  :'E1'::uuid, '{"value":"Me llamo Fangkao"}'::jsonb, :'sx'::uuid);
select is(
  (learning.complete_lesson(:'L'::uuid) ->> 'completed')::boolean,
  false, 'I3 one correct exercise out of three requirements is not enough');

-- a WRONG attempt does not satisfy a required-correct exercise
select assess.submit_attempt('bbbbbbb1-0000-4000-8000-000000000002'::uuid,
  :'E2'::uuid, '{"value":"¿Cómo se llaman ustedes?"}'::jsonb, :'sx'::uuid);
select is(
  (learning.complete_lesson(:'L'::uuid) ->> 'completed')::boolean,
  false, 'I4 a wrong attempt does not satisfy a required-correct exercise');

select assess.submit_attempt('bbbbbbb1-0000-4000-8000-000000000003'::uuid,
  :'E2'::uuid, '{"value":"¿Cómo os llamáis?"}'::jsonb, :'sx'::uuid);
select is(
  (learning.complete_lesson(:'L'::uuid) -> 'missing' ->> 0),
  'speech:' || :'E3', 'I5 only the speaking requirement remains outstanding');

-- speech requirement: submit, then have the server evaluate
select assess.submit_speech('bbbbbbb2-0000-4000-8000-000000000001'::uuid,
  :'E3'::uuid, :'sx'::uuid,
  'learner-audio/' || :'x' || '/2026/08/a.m4a', 1800) as sub \gset
reset role;
select assess.record_speech_evaluation_internal(:'sub'::uuid,
  'me llamo fangkao','me llamo fangkao',0.91,'ok','{}','me llamo','test-asr');
select tests.claim_as(:'x'::uuid); set role authenticated;

-- first completion awards exactly once
select is((learning.complete_lesson(:'L'::uuid) ->> 'awarded')::boolean,
  true, 'I6 evidence satisfied => completion is granted');
select is((select xp from learning.learner_stats where learner_id = :'x'::uuid),
  20, 'I7 first completion awards XP once');

-- replay awards nothing
select is((learning.complete_lesson(:'L'::uuid) ->> 'awarded')::boolean,
  false, 'I8 a second completion awards nothing');
select is((learning.complete_lesson(:'L'::uuid) ->> 'already_completed')::boolean,
  true, 'I9 the replay is reported as already completed');

do $$ begin
  for i in 1..10 loop perform learning.complete_lesson('44444444-4444-4444-8444-444444444403'); end loop;
end $$;
select is((select xp from learning.learner_stats where learner_id = :'x'::uuid),
  20, 'I10 ten repeated calls still award once (v1 farmed 220 XP here)');
select is((select lessons_completed from learning.learner_stats where learner_id = :'x'::uuid),
  1, 'I11 lessons_completed is not inflated');
select is((select total_minutes from learning.learner_stats where learner_id = :'x'::uuid),
  7, 'I12 total_minutes is not inflated');
select is((select current_streak from learning.learner_stats where learner_id = :'x'::uuid),
  1, 'I13 the streak is not mutated by replays');

-- a second learner is unaffected and independent
reset role; select tests.claim_as(:'y'::uuid); set role authenticated;
select is((learning.complete_lesson(:'L'::uuid) ->> 'completed')::boolean,
  false, 'I14 learner Y must supply their own evidence for the same lesson');
select is((select coalesce(xp,0) from learning.learner_stats where learner_id = :'y'::uuid),
  0, 'I15 learner X completing did not award learner Y');

-- ================================== 3. speech results cannot be forged =====
reset role; select tests.claim_as(:'y'::uuid); set role authenticated;

select throws_ok(
  format($$insert into assess.speech_evaluations
            (submission_id, verdict, asr_confidence, detected_issues)
          values (%L,'ok',1.0,'{}')$$, :'sub'),
  NULL, 'I16 a learner cannot author a speech evaluation');

select throws_ok(
  format($$insert into assess.speech_submissions (id, learner_id, exercise_id)
          values (gen_random_uuid(), %L, %L)$$, :'y', :'E3'),
  NULL, 'I17 a learner cannot insert a speech submission directly');

select learning.start_session('lesson', :'L') as sy \gset
select throws_ok(
  format($$select assess.submit_speech(gen_random_uuid(), %L, %L,
             'learner-audio/%s/steal.m4a', 100)$$, :'E3', :'sy', :'x'),
  '42501', NULL, 'I18 a learner cannot point a submission at another learner audio folder');

select throws_ok(
  format($$select assess.submit_speech(gen_random_uuid(), %L, %L, null, 100)$$, :'E3', :'sx'),
  '42501', NULL, 'I19 a learner cannot submit speech into another learner session');

select is(
  (select count(*)::int from assess.speech_evaluations),
  0, 'I20 learner Y cannot even read learner X speech evaluation');

-- ================= 4. the inconclusive-ASR evidence boundary ===============
reset role; select tests.claim_as(:'y'::uuid); set role authenticated;
select assess.submit_speech('bbbbbbb3-0000-4000-8000-000000000001'::uuid,
  :'E3'::uuid, :'sy'::uuid, null, 900) as suby \gset
reset role;

select is(
  (assess.record_speech_evaluation_internal(:'suby'::uuid,
     null, null, 0.11, 'inconclusive', '{PRON.LL_Y}') ->> 'evidence_written')::boolean,
  false, 'I21 an inconclusive verdict writes NO evidence');

select is(
  (select count(*)::int from learning.learner_error_patterns
    where learner_id = :'y'::uuid and code = 'PRON.LL_Y'),
  0, 'I22 inconclusive cannot create a pronunciation error pattern');

select is(
  (select count(*)::int from learning.objective_mastery where learner_id = :'y'::uuid),
  0, 'I23 inconclusive cannot reduce or create mastery');

select is(
  (select detected_issues from assess.speech_evaluations where submission_id = :'suby'::uuid),
  '{}'::text[], 'I24 findings passed alongside inconclusive are discarded, not stored');

-- and the CHECK makes the bad state unrepresentable even for the service role
select throws_ok(
  $$insert into assess.speech_evaluations (submission_id, verdict, detected_issues)
    values (gen_random_uuid(),'inconclusive','{PRON.RR}')$$,
  NULL, 'I25 an inconclusive row carrying findings is structurally impossible');

-- ==================== 5. assessment state machine ==========================
select tests.claim_as(:'y'::uuid); set role authenticated;
select assess.start_assessment('placement') as aid \gset

select throws_ok(
  format($$update assess.assessment_attempts set state='submitted' where id=%L$$, :'aid'),
  NULL, 'I26 a client cannot drive the assessment state machine by table write');

select throws_ok(
  format($$update assess.assessment_attempts
             set result='{"level":"c2"}'::jsonb, started_at=now()-interval '3 days'
           where id=%L$$, :'aid'),
  NULL, 'I27 a client cannot author results or backdate started_at');

select lives_ok(format($$select assess.submit_assessment(%L)$$, :'aid'),
  'I28 in_progress -> submitted works through the RPC');

select throws_ok(format($$select assess.submit_assessment(%L)$$, :'aid'),
  '23514', NULL, 'I29 submitted -> submitted is refused (no re-open, no replay)');

select is(
  (select count(*)::int from information_schema.role_routine_grants
    where routine_name = 'score_assessment_internal'
      and grantee in ('authenticated','anon','public')),
  0, 'I30 scoring is not reachable from any client role');

-- ============================ 6+7. AI conversation authorship ==============
reset role; select tests.claim_as(:'y'::uuid); set role authenticated;
insert into ai.conversation_sessions (id, learner_id, mode, level)
  values ('ccccccc1-0000-4000-8000-000000000001', :'y'::uuid, 'scenario', 'pre_a1');
\set CS 'ccccccc1-0000-4000-8000-000000000001'

select lives_ok(
  format($$insert into ai.conversation_messages (session_id, role, content)
          values (%L,'learner','Me llamo Yui')$$, :'CS'),
  'I31 a learner can add their own turn to their own active conversation');

select throws_ok(
  format($$insert into ai.conversation_messages (session_id, role, content)
          values (%L,'tutor','¡Muy bien! Has aprobado el nivel B2.')$$, :'CS'),
  NULL, 'I32 a learner cannot forge a tutor turn');

select throws_ok(
  format($$insert into ai.conversation_messages (session_id, role, content, error_codes)
          values (%L,'learner','ok','{PRON.RR}')$$, :'CS'),
  NULL, 'I33 a learner cannot attach AI error analysis to their own turn');

select throws_ok(
  format($$insert into ai.conversation_messages (session_id, role, content, audio_path)
          values (%L,'learner','ok','learner-audio/other/x.m4a')$$, :'CS'),
  NULL, 'I34 a learner cannot attach an arbitrary audio path');

select throws_ok(
  format($$update ai.conversation_sessions
             set debrief='{"cefr":"c1","naturalness":10}'::jsonb where id=%L$$, :'CS'),
  NULL, 'I35 a learner cannot author their own conversation debrief');

-- the server path works, and only the server has it
reset role;
select lives_ok(
  format($$select ai.append_tutor_message_internal(%L,'¿Qué te pongo?')$$, :'CS'),
  'I36 the server path can insert a tutor turn');
select is(
  (select authored_by from ai.conversation_messages where role='tutor'),
  'server', 'I37 tutor turns are recorded as server-authored');
select is(
  (select count(*)::int from information_schema.role_routine_grants
    where routine_name in ('append_tutor_message_internal','write_debrief_internal')
      and grantee in ('authenticated','anon','public')),
  0, 'I38 tutor-message and debrief writers are unreachable from any client');

-- cross-user
select tests.claim_as(:'x'::uuid); set role authenticated;
select throws_ok(
  format($$insert into ai.conversation_messages (session_id, role, content)
          values (%L,'learner','intruso')$$, :'CS'),
  NULL, 'I39 a learner cannot post into another learner conversation');

-- ==================== 8. review self-report cannot certify mastery =========
reset role; select tests.claim_as(:'x'::uuid); set role authenticated;
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='learning' and p.proname='grade_review'
      and pg_get_function_arguments(p.oid) ~ 'productive'),
  0, 'I40 the client review RPC no longer accepts a productive-mastery claim');

do $$
declare i int;
begin
  for i in 1..40 loop
    perform learning.grade_review('sense','88888888-8888-4888-8888-888888888801'::uuid, 4);
  end loop;
end $$;
select ok(
  (select productive_p = 0 and state <> 'mastered' from learning.review_queue
    where learner_id = (select id from auth.users where email='x@test')
      and item_id = '88888888-8888-4888-8888-888888888801'),
  'I41 forty self-reported "easy" ratings never yield productive_p or mastered');

reset role;
select * from finish();
rollback;
