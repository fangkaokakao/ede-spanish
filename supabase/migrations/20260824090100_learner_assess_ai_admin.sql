-- ============================================================================
-- 20260824090100_learner_assess_ai_admin.sql
-- Phase 3 / migration 2 of 5. Learner state, attempts, AI ledger, editorial.
-- ============================================================================

-- ============================================================== LEARNING ====

create table learning.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  ui_locale    text not null default 'th',
  created_at   timestamptz not null default now(),
  deleted_at   timestamptz
);

-- Auto-create the profile row on signup, gated on metadata so we never create
-- orphan or duplicate profiles. A duplicate profile silently destroys a
-- learner's entire history, which is unrecoverable and invisible until they complain.
create or replace function learning.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into learning.profiles (id, display_name)
  values (new.id, nullif(new.raw_user_meta_data ->> 'display_name',''))
  on conflict (id) do nothing;

  insert into learning.learner_preferences (learner_id)
  values (new.id)
  on conflict (learner_id) do nothing;

  insert into learning.learner_stats (learner_id)
  values (new.id)
  on conflict (learner_id) do nothing;

  return new;
end $$;

create table learning.learner_preferences (
  learner_id              uuid primary key references learning.profiles(id) on delete cascade,
  goal                    text check (goal in
                            ('live_in_spain','travel','partner','work','study','dele','interest',null)),
  daily_goal_minutes      int not null default 15
                            check (daily_goal_minutes in (5,10,15,20,30,45) or daily_goal_minutes between 1 and 240),
  self_reference          text not null default 'both'
                            check (self_reference in ('masculine','feminine','both')),
  explanation_depth       int not null default 1 check (explanation_depth between 1 and 4),
  thai_support            text not null default 'auto'
                            check (thai_support in ('auto','always','minimal')),
  voice_preference        text not null default 'both'
                            check (voice_preference in ('male','female','both')),
  consent_store_audio     boolean not null default false,
  consent_improve_product boolean not null default false,
  consent_analytics       boolean not null default false,
  audio_retention_days    int not null default 90 check (audio_retention_days in (7,30,90,36500)),
  reduce_motion           boolean not null default false,
  updated_at              timestamptz not null default now()
);
comment on column learning.learner_preferences.self_reference is
  'Affects only sentences that genuinely describe the learner (Estoy cansado/cansada). Never alters the grammatical gender of unrelated nouns. Never inferred.';
comment on column learning.learner_preferences.consent_improve_product is
  'Defaults false. Recording works without it.';

create table learning.learner_stats (
  learner_id        uuid primary key references learning.profiles(id) on delete cascade,
  current_streak    int not null default 0,
  longest_streak    int not null default 0,
  last_active_date  date,
  total_minutes     int not null default 0,
  lessons_completed int not null default 0,
  words_mastered    int not null default 0,
  xp                int not null default 0
);
comment on column learning.learner_stats.xp is
  'Motivational only. Never an input to level estimation.';

-- A server-created study session. Error-pattern "distinct session" evidence is
-- counted from these rows, never from a client-supplied flag.
--
-- A client can still call start_session in a loop, so session identity alone is
-- not enough: record_error_code additionally requires real elapsed time between
-- counted sessions (see the RPC). Session id answers "which sitting", the time
-- gap answers "is this actually a different sitting".
create table learning.study_sessions (
  id          uuid primary key default gen_random_uuid(),
  learner_id  uuid not null references learning.profiles(id) on delete cascade,
  kind        text not null check (kind in
                ('lesson','practice','review','conversation','assessment','placement')),
  lesson_id   uuid references content.lessons(id) on delete set null,
  started_at  timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  ended_at    timestamptz
);
create index study_sessions_open_idx
  on learning.study_sessions(learner_id, kind, started_at desc)
  where ended_at is null;

create table learning.enrolments (
  learner_id  uuid not null references learning.profiles(id) on delete cascade,
  course_id   uuid not null references content.curriculum_nodes(id) on delete restrict,
  entry_level content.cefr not null,
  started_at  timestamptz not null default now(),
  primary key (learner_id, course_id)
);

create table learning.lesson_progress (
  learner_id      uuid not null references learning.profiles(id) on delete cascade,
  lesson_id       uuid not null references content.lessons(id) on delete cascade,
  state           text not null default 'not_started'
                    check (state in ('not_started','in_progress','completed')),
  last_block_index int not null default 0,
  content_version int not null default 1,
  started_at      timestamptz,
  completed_at    timestamptz,
  updated_at      timestamptz not null default now(),
  primary key (learner_id, lesson_id)
);
create index lesson_progress_recent_idx
  on learning.lesson_progress(learner_id, updated_at desc);

create table learning.objective_mastery (
  learner_id                uuid not null references learning.profiles(id) on delete cascade,
  objective_id              uuid not null references content.learning_objectives(id) on delete cascade,
  p_mastery                 numeric not null default 0 check (p_mastery between 0 and 1),
  evidence_count            int not null default 0,
  productive_evidence_count int not null default 0,
  delayed_success_count     int not null default 0,
  last_evidence_at          timestamptz,
  first_mastered_at         timestamptz,
  primary key (learner_id, objective_id)
);
comment on table learning.objective_mastery is
  'p_mastery is written ONLY by learning.record_evidence(). Recognition evidence is capped at 0.70; mastery additionally requires >=1 productive and >=1 delayed success.';

create table learning.grammar_mastery (
  learner_id       uuid not null references learning.profiles(id) on delete cascade,
  concept_id       uuid not null references content.grammar_concepts(id) on delete cascade,
  p_mastery        numeric not null default 0 check (p_mastery between 0 and 1),
  evidence_count   int not null default 0,
  last_evidence_at timestamptz,
  primary key (learner_id, concept_id)
);

create table learning.review_queue (
  learner_id   uuid not null references learning.profiles(id) on delete cascade,
  item_type    text not null check (item_type in ('sense','collocation','concept','pron_target')),
  item_id      uuid not null,
  state        text not null default 'new'
                 check (state in ('new','learning','review','lapsed','mastered','suspended')),
  stability    numeric,
  difficulty   numeric,
  due_at       timestamptz not null default now(),
  last_review  timestamptz,
  reps         int not null default 0,
  lapses       int not null default 0,
  receptive_p  numeric not null default 0 check (receptive_p between 0 and 1),
  productive_p numeric not null default 0 check (productive_p between 0 and 1),
  primary key (learner_id, item_type, item_id)
);
-- Hottest query in the product. Partial index keeps suspended rows out of it.
create index review_due_idx on learning.review_queue(learner_id, due_at)
  where state <> 'suspended';
comment on column learning.review_queue.stability is 'FSRS stability (days). SM-2 systematically over-schedules; FSRS parameters can be optimised per learner from their own log.';

create table learning.skill_estimates (
  learner_id uuid not null references learning.profiles(id) on delete cascade,
  dimension  content.skill not null,
  theta      numeric not null default 0,
  se         numeric not null default 1.0,
  updated_at timestamptz not null default now(),
  primary key (learner_id, dimension)
);
comment on column learning.skill_estimates.se is
  'Standard error. The UI must never render theta without the uncertainty being representable.';

create table learning.learner_error_patterns (
  learner_id            uuid not null references learning.profiles(id) on delete cascade,
  code                  text not null references content.error_taxonomy(code) on delete cascade,
  occurrence_count      int not null default 0,
  weighted_recent_count numeric not null default 0,
  session_count         int not null default 0,
  last_session_id       uuid references learning.study_sessions(id) on delete set null,
  last_counted_session_at timestamptz,
  status                text not null default 'observed'
                          check (status in ('observed','recurring','targeted','improving','resolved')),
  first_seen            timestamptz not null default now(),
  last_seen             timestamptz not null default now(),
  primary key (learner_id, code),
  -- One mistake never labels a learner.
  constraint pattern_needs_evidence check (
    status = 'observed' or (occurrence_count >= 3 and session_count >= 2))
);

create table learning.study_plans (
  id          uuid primary key default gen_random_uuid(),
  learner_id  uuid not null references learning.profiles(id) on delete cascade,
  plan_date   date not null,
  budget_min  int not null,
  items       jsonb not null default '[]'::jsonb,
  completed   boolean not null default false,
  created_at  timestamptz not null default now(),
  unique (learner_id, plan_date)
);

create table learning.bookmarks (
  learner_id  uuid not null references learning.profiles(id) on delete cascade,
  item_type   text not null check (item_type in ('sense','concept','example','lesson','ai_answer')),
  item_id     uuid not null,
  note        text,
  created_at  timestamptz not null default now(),
  primary key (learner_id, item_type, item_id)
);

create table learning.sync_cursors (
  learner_id     uuid not null references learning.profiles(id) on delete cascade,
  entity         text not null,
  last_synced_at timestamptz not null default 'epoch',
  primary key (learner_id, entity)
);

-- ================================================================ ASSESS ====

create table assess.exercise_attempts (
  id              uuid primary key,          -- client-generated => idempotent replay
  learner_id      uuid not null references learning.profiles(id) on delete cascade,
  exercise_id     uuid not null references content.exercises(id) on delete cascade,
  objective_id    uuid references content.learning_objectives(id) on delete set null,
  raw_answer      jsonb not null,
  is_correct      boolean not null,          -- server-computed; the client cannot write this
  error_codes     text[] not null default '{}',
  latency_ms      int,
  content_version int not null default 1,
  session_id      uuid references learning.study_sessions(id) on delete set null,
  modality        text not null default 'typed'
                    check (modality in ('typed','choice','spoken','written')),
  created_at      timestamptz not null default now()
);
create index attempts_learner_time_idx on assess.exercise_attempts(learner_id, created_at desc);
create index attempts_exercise_idx     on assess.exercise_attempts(exercise_id);
comment on table assess.exercise_attempts is
  'Append-only. No UPDATE or DELETE policy for any client role: an attempt is a fact, and mutable attempts make the whole measurement layer fiction.';

-- Split deliberately. v1 had ONE table with client INSERT on the whole row,
-- which let a learner author verdict='ok', asr_confidence=1, detected_issues={}
-- and impersonate the speech evaluator. A learner can now only state client
-- facts; every derived field lives in a table they cannot write.
create table assess.speech_submissions (
  id                 uuid primary key,          -- client-generated, idempotent
  learner_id         uuid not null references learning.profiles(id) on delete cascade,
  session_id         uuid references learning.study_sessions(id) on delete set null,
  exercise_id        uuid references content.exercises(id) on delete set null,
  pron_target_id     uuid references content.pronunciation_targets(id) on delete set null,
  audio_path         text,                      -- private bucket, own folder only
  client_duration_ms int check (client_duration_ms between 0 and 120000),
  created_at         timestamptz not null default now()
);
create index speech_sub_learner_idx on assess.speech_submissions(learner_id, created_at desc);

create table assess.speech_evaluations (
  submission_id   uuid primary key references assess.speech_submissions(id) on delete cascade,
  -- Scored frame only. A learner's own name is content, not a pronunciation
  -- target, and must never generate a phonetic error.
  scored_frame    text,
  transcript_raw  text,
  transcript_norm text,
  asr_confidence  numeric check (asr_confidence between 0 and 1),
  verdict         text not null check (verdict in ('ok','issue','inconclusive')),
  detected_issues text[] not null default '{}',
  evidence_written boolean not null default false,
  model           text,
  created_at      timestamptz not null default now(),
  -- Structural half of the inconclusive rule: an inconclusive evaluation
  -- cannot carry pronunciation findings, so there is nothing for the evidence
  -- boundary to turn into negative evidence even by mistake.
  constraint inconclusive_has_no_findings
    check (verdict <> 'inconclusive' or detected_issues = '{}')
);
comment on table assess.speech_evaluations is
  'Server-owned. No client grant. Written only by assess.record_speech_evaluation_internal().';

create table assess.writing_submissions (
  id          uuid primary key,
  learner_id  uuid not null references learning.profiles(id) on delete cascade,
  task_id     uuid,
  text        text not null,
  word_count  int generated always as (array_length(regexp_split_to_array(trim(text), '\s+'), 1)) stored,
  created_at  timestamptz not null default now()
);

create table assess.writing_feedback (
  submission_id      uuid primary key references assess.writing_submissions(id) on delete cascade,
  annotations        jsonb not null default '[]'::jsonb,
  corrected_version  text,
  natural_alternative text,
  rubric             jsonb not null default '{}'::jsonb,
  confidence         numeric,
  model              text,
  created_at         timestamptz not null default now()
);
comment on column assess.writing_feedback.natural_alternative is
  'Kept separate from corrected_version so errors are fixed without erasing the learner voice.';

create table assess.assessment_attempts (
  id            uuid primary key,
  learner_id    uuid not null references learning.profiles(id) on delete cascade,
  kind          text not null check (kind in ('placement','mastery_check','level_assessment','mock_exam')),
  level         content.cefr,
  state         text not null default 'in_progress'
                  check (state in ('in_progress','submitted','scored','abandoned')),
  theta         numeric,
  se            numeric,
  skill_profile jsonb not null default '{}'::jsonb,
  result        jsonb not null default '{}'::jsonb,
  started_at    timestamptz not null default now(),
  submitted_at  timestamptz
);

create table assess.attempt_idempotency (
  idempotency_key uuid primary key,
  learner_id      uuid not null references learning.profiles(id) on delete cascade,
  kind            text not null,
  response        jsonb not null,   -- the exact payload returned the first time
  created_at      timestamptz not null default now()
);
comment on table assess.attempt_idempotency is
  'Makes offline replay free. Duplicate submission stops being a bug class and becomes a no-op.';

-- ==================================================================== AI ====

-- Global, NOT learner-scoped: the same curriculum sentences generate the same
-- questions across every learner. This is the single largest AI cost lever.
create table ai.explanation_cache (
  context_hash   text primary key,
  concept_id     uuid references content.grammar_concepts(id) on delete cascade,
  depth          int not null check (depth between 1 and 4),
  answer_th      text not null,
  model          text not null,
  prompt_version text not null,
  guard_verdict  text not null check (guard_verdict in ('pass','repaired')),
  hits           int not null default 0,
  created_at     timestamptz not null default now()
);
comment on table ai.explanation_cache is
  'Only guard-passing answers are cached. Unvalidated Spanish never becomes durable.';

create table ai.conversation_sessions (
  id           uuid primary key default gen_random_uuid(),
  learner_id   uuid not null references learning.profiles(id) on delete cascade,
  scenario_id  text,
  mode         text not null default 'free' check (mode in ('free','scenario','lesson_dialogue')),
  level        content.cefr not null,
  state        text not null default 'active' check (state in ('active','ended','abandoned')),
  debrief      jsonb,
  started_at   timestamptz not null default now(),
  ended_at     timestamptz
);

create table ai.conversation_messages (
  id          uuid primary key default gen_random_uuid(),
  session_id  uuid not null references ai.conversation_sessions(id) on delete cascade,
  role        text not null check (role in ('tutor','learner')),
  content     text not null,
  -- server-derived; a learner must not be able to author AI error analysis
  audio_path  text,
  error_codes text[] not null default '{}',
  authored_by text not null default 'client'
                check (authored_by in ('client','server')),
  created_at  timestamptz not null default now()
);
create index conv_msg_session_idx on ai.conversation_messages(session_id, created_at);

create table ai.ai_requests (
  id             bigserial primary key,
  learner_id     uuid references learning.profiles(id) on delete set null,
  feature        text not null,
  tier           text not null check (tier in ('t1','t2','t3')),
  model          text not null,
  prompt_version text not null,
  input_tokens   int,
  output_tokens  int,
  cost_usd       numeric(10,6),
  latency_ms     int,
  cache_hit      boolean not null default false,
  guard_verdict  text not null check (guard_verdict in ('pass','repaired','failed_fallback')),
  created_at     timestamptz not null default now()
);
create index ai_requests_time_idx on ai.ai_requests using brin(created_at);
comment on table ai.ai_requests is
  'Cost and drift ledger. Deliberately stores no learner text.';

-- ================================================================= ADMIN ====

create table admin.content_reviews (
  id                  uuid primary key default gen_random_uuid(),
  entity_type         text not null,
  entity_id           uuid not null,
  gate                text not null check (gate in
                        ('ai_validation','spain_language','pedagogical','factual','human_review')),
  verdict             text not null check (verdict in ('pass','warn','fail')),
  findings            jsonb not null default '[]'::jsonb,
  reviewer_id         uuid,
  reviewer_role       text check (reviewer_role in ('peninsular_editor','thai_editor','system')),
  style_guide_version text,
  created_at          timestamptz not null default now()
);
create index reviews_entity_idx on admin.content_reviews(entity_type, entity_id, created_at desc);

create table admin.publication_history (
  id            bigserial primary key,
  entity_type   text not null,
  entity_id     uuid not null,
  from_status   content.pub_status,
  to_status     content.pub_status not null,
  pack_id       uuid references content.content_packs(id) on delete set null,
  actor_id      uuid,
  created_at    timestamptz not null default now()
);

create table admin.exam_spec_verifications (
  id            uuid primary key default gen_random_uuid(),
  spec_id       uuid not null references content.exam_specs(id) on delete cascade,
  checked_at    timestamptz not null default now(),
  source_url    text not null,
  diff_detected boolean not null default false,
  diff_summary  text,
  action_taken  text
);

create table admin.ai_prompt_versions (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  version     text not null,
  body        text not null,
  is_active   boolean not null default false,
  eval_score  numeric,
  created_at  timestamptz not null default now(),
  unique (name, version)
);
comment on table admin.ai_prompt_versions is
  'Prompts are versioned data, not code. Promotion is gated on the Spain-fidelity eval score.';

create table admin.audit_logs (
  id         bigserial primary key,
  actor_id   uuid,
  action     text not null,
  entity     text not null,
  entity_id  uuid,
  before     jsonb,
  after      jsonb,
  ip         inet,
  created_at timestamptz not null default now()
);
create index audit_time_idx on admin.audit_logs using brin(created_at);

-- ============================================================= ANALYTICS ====

create table analytics.events (
  id         bigserial primary key,
  learner_id uuid references learning.profiles(id) on delete set null,
  name       text not null,
  props      jsonb not null default '{}'::jsonb,
  client_ts  timestamptz,
  created_at timestamptz not null default now()
);
create index events_name_time_idx on analytics.events(name, created_at desc);
comment on table analytics.events is
  'No raw learner text, transcripts or audio. IDs and counts only.';
