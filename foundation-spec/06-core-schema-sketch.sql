-- ============================================================================
--  ILLUSTRATIVE SCHEMA SKETCH — NOT A MIGRATION. DO NOT RUN.
--  Supports ERD in 04-technical-architecture.md §36.
--  Purpose: make the data model concrete enough to critique before Phase 3.
--  Real migrations will be produced per Phase 3, additive-only, in git.
-- ============================================================================

create schema if not exists content;
create schema if not exists learning;
create schema if not exists assess;
create schema if not exists ai;
create schema if not exists admin;
create schema if not exists analytics;

-- ---------------------------------------------------------------- ENUMS ----
create type content.cefr as enum ('pre_a1','a1','a2','b1','b2','c1','c2');
create type content.node_kind as enum ('course','module','unit');
create type content.pub_status as enum
  ('draft','ai_validated','lang_checked','ped_checked','in_review','approved','published','retired','rejected');
create type content.register as enum
  ('formal_high','formal','neutral','informal','colloquial','slang','professional','administrative');
create type content.variety_intent as enum
  ('es_ES_target','contrast_note','recognition_only');
create type content.skill as enum
  ('listening','reading','speaking','interaction','writing','pronunciation','grammar','lexis','sociolinguistic','pragmatic');

-- ================================================================ CONTENT ==

create table content.cefr_levels (
  level              content.cefr primary key,
  ordinal            int not null unique,
  name_th            text not null,
  name_es            text not null,
  can_do_summary_th  text not null,
  thai_support_ratio numeric not null,          -- 1.0 = Thai-heavy … 0.0 = Spanish-only
  outcomes           jsonb not null,            -- per-skill outcomes, grammar inventory, domains
  completion_rules   jsonb not null             -- thresholds per 02 §5.2
);

-- Course > Module > Unit collapsed into one typed tree (see 04 §35 rationale)
create table content.curriculum_nodes (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid references content.curriculum_nodes(id) on delete restrict,
  kind        content.node_kind not null,
  level       content.cefr not null references content.cefr_levels(level),
  slug        text not null unique,
  title_th    text not null,
  title_es    text,
  subtitle_th text,
  sort_order  int not null,
  path        ltree,                            -- materialised, maintained by trigger
  status      content.pub_status not null default 'draft',
  constraint node_parent_kind check (
    (kind = 'course'  and parent_id is null) or
    (kind <> 'course' and parent_id is not null))
);
create index on content.curriculum_nodes using gist (path);

create table content.learning_objectives (
  id            uuid primary key default gen_random_uuid(),
  code          text not null unique,           -- 'A1.U3.O2'
  level         content.cefr not null,
  skill         content.skill not null,
  can_do_th     text not null,                  -- "สั่งกาแฟในร้านได้"
  can_do_es     text,
  is_core       boolean not null default true,  -- core vs extension (02 §5.2)
  mastery_rules jsonb not null
);

create table content.lessons (
  id                uuid primary key default gen_random_uuid(),
  unit_id           uuid not null references content.curriculum_nodes(id),
  slug              text not null unique,
  sort_order        int not null,
  estimated_minutes int not null check (estimated_minutes between 2 and 30),
  current_version   int not null default 1,
  status            content.pub_status not null default 'draft'
);

create table content.lesson_versions (
  id             uuid primary key default gen_random_uuid(),
  lesson_id      uuid not null references content.lessons(id),
  version        int not null,
  title_th       text not null,
  goal_th        text not null,                 -- "เรียนจบแล้วคุณจะสั่งกาแฟได้"
  style_guide_version text not null,            -- which style guide it was reviewed against
  published_at   timestamptz,
  unique (lesson_id, version)
);

create table content.lesson_objectives (
  lesson_version_id uuid references content.lesson_versions(id) on delete cascade,
  objective_id      uuid references content.learning_objectives(id),
  primary key (lesson_version_id, objective_id)
);

-- Validated block schemas only. NEVER executable UI instructions (03 §32).
create table content.content_blocks (
  id                uuid primary key default gen_random_uuid(),
  lesson_version_id uuid not null references content.lesson_versions(id) on delete cascade,
  sort_order        int not null,
  block_type        text not null,              -- text|heading|explanation|example|comparison|
                                                -- tip|warning|grammar_breakdown|interactive_sentence|
                                                -- image|audio|dialogue|pronunciation_guide|timeline|
                                                -- table|exercise_embed
  payload           jsonb not null,             -- validated against a per-type JSON Schema
  offline_capable   boolean not null default true,
  variety_intent    content.variety_intent not null default 'es_ES_target',
  register          content.register,
  concept_id        uuid,                       -- optional link for the Why engine
  why_l1_th         text                        -- PRE-AUTHORED instant answer (T0 path, 02 §17)
);

-- ---- grammar -------------------------------------------------------------
create table content.grammar_concepts (
  id                uuid primary key default gen_random_uuid(),
  slug              text not null unique,       -- 'noun_gender','ser_vs_estar_states'
  cefr_introduced   content.cefr not null,
  cefr_mastered     content.cefr not null,
  name_th           text not null,
  name_es           text not null,
  answers           jsonb not null,             -- the 16 mandatory questions, keyed
  explain_l1_th     text not null,
  explain_l2_th     text not null,
  explain_l3_th     text not null,
  explain_l4_th     text,                       -- may be AI-generated on demand
  spain_usage_note  text,
  visual_model      text,                       -- agreement_arrows|timeline|pronoun_swap|morphology
  dele_relevance    content.cefr[],
  status            content.pub_status not null default 'draft'
);

create table content.grammar_concept_edges (   -- the DAG
  prerequisite_id uuid references content.grammar_concepts(id),
  concept_id      uuid references content.grammar_concepts(id),
  strength        numeric not null default 1.0,
  primary key (prerequisite_id, concept_id),
  constraint no_self_edge check (prerequisite_id <> concept_id)
);
-- Cycle prevention enforced by a trigger + CMS-side check (03 §32).

create table content.thai_contrast_notes (
  id          uuid primary key default gen_random_uuid(),
  concept_id  uuid references content.grammar_concepts(id),
  target_id   uuid,                             -- or a pronunciation target
  thai_reality_th text not null,
  strategy_th     text not null,
  bridge_example  text
);

create table content.error_taxonomy (
  code        text primary key,                 -- 'GRAM.GEN.ADJ','PRON.RR','LEX.LATAM_DEFAULT'
  parent_code text references content.error_taxonomy(code),
  label_th    text not null,
  concept_id  uuid references content.grammar_concepts(id),
  severity    text not null                     -- communicative impact
);

-- ---- vocabulary ----------------------------------------------------------
create table content.vocabulary_entries (
  id           uuid primary key default gen_random_uuid(),
  lemma        text not null,
  pos          text not null,
  gender       text,                            -- m|f|mf|null
  plural_form  text,
  ipa          text,
  freq_band    int,
  status       content.pub_status not null default 'draft',
  unique (lemma, pos)
);

create table content.vocabulary_senses (
  id              uuid primary key default gen_random_uuid(),
  entry_id        uuid not null references content.vocabulary_entries(id) on delete cascade,
  sense_order     int not null,
  meaning_es      text not null,
  meaning_th      text not null,
  register        content.register not null default 'neutral',
  cefr            content.cefr not null,
  domain          text,
  false_friend    boolean not null default false,
  false_friend_note_th text,
  spain_note      text,                          -- e.g. coger: normal in Spain, taboo in parts of LatAm
  variety_intent  content.variety_intent not null default 'es_ES_target'
);

create table content.collocations (
  id         uuid primary key default gen_random_uuid(),
  sense_id   uuid references content.vocabulary_senses(id) on delete cascade,
  phrase     text not null,                      -- 'hacer una pregunta'
  meaning_th text not null,
  cefr       content.cefr not null,
  register   content.register not null default 'neutral'
);

-- ---- Spain language policy as DATA, not code (01 §3.3) -------------------
create table content.lexicon_policy (
  id                 uuid primary key default gen_random_uuid(),
  spain_form         text not null,
  alternative_form   text not null,
  alternative_status text not null,              -- 'not_default' | 'wrong_in_spain' | 'false_friend'
  note_th            text,
  first_cefr         content.cefr,
  severity           text not null default 'error',
  policy_version     int not null default 1,
  unique (spain_form, alternative_form, policy_version)
);

-- ---- pronunciation & audio ----------------------------------------------
create table content.pronunciation_targets (
  id                uuid primary key default gen_random_uuid(),
  slug              text not null unique,        -- 'trill_rr','theta','coda_s','cluster_tr'
  ipa               text not null,
  orthography_rules text not null,
  articulation_th   text not null,               -- tongue/lips/airflow/voicing
  thai_contrast_th  text not null,
  typical_error_th  text not null,
  minimal_pairs     jsonb not null,              -- [{a:"pero",b:"perro"}]
  cefr_introduced   content.cefr not null,
  priority          int not null
);

create table content.audio_assets (
  id             uuid primary key default gen_random_uuid(),
  storage_path   text not null unique,
  locale         text not null default 'es-ES' check (locale = 'es-ES'),
  speaker_type   text not null,                  -- 'human' | 'tts'
  voice_id       text not null,
  voice_gender   text not null,                  -- speaker voice ≠ grammatical gender (01/02)
  speed          text not null,                  -- 'normal' | 'slow'
  granularity    text not null,                  -- 'sentence' | 'word' | 'syllable'
  transcript     text not null,
  duration_ms    int,
  content_version int not null,
  approved_by    uuid,
  approved_at    timestamptz
);

-- ---- exercises -----------------------------------------------------------
create table content.exercise_templates (
  id           text primary key,                 -- 'mcq','fill_blank','typed','conjugate',
                                                 -- 'transform','error_correct','order','match',
                                                 -- 'gender_select','dictation','minimal_pair',
                                                 -- 'read_aloud','repeat','register_select', ...
  schema       jsonb not null,                   -- JSON Schema for `payload`
  skill        content.skill not null,
  evidence_weight numeric not null,              -- feeds mastery (02 §20)
  productive   boolean not null
);

create table content.exercises (
  id             uuid primary key default gen_random_uuid(),
  template_id    text not null references content.exercise_templates(id),
  objective_id   uuid references content.learning_objectives(id),
  concept_id     uuid references content.grammar_concepts(id),
  cefr           content.cefr not null,
  difficulty     numeric,                        -- Rasch b, calibrated from live data
  payload        jsonb not null,
  answer_rules   jsonb not null,                 -- accepted variants, accent tolerance, normalisation
  variety_intent content.variety_intent not null default 'es_ES_target',
  status         content.pub_status not null default 'draft'
);

-- ---- exam specs (25 §2) — versioned DATA, never code ---------------------
create table content.exam_providers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique                      -- 'Instituto Cervantes'
);

create table content.exam_specs (
  id                    uuid primary key default gen_random_uuid(),
  provider_id           uuid not null references content.exam_providers(id),
  exam_name             text not null,           -- 'DELE'
  level                 content.cefr not null,
  specification_version text not null,
  effective_from        date not null,
  effective_to          date,
  source_reference_url  text not null,
  last_verified_at      timestamptz not null,
  verified_by           uuid not null,
  total_duration_min    int,
  grouping_rules        jsonb not null,          -- grouping DIFFERS BY LEVEL — see 02 §25.1
  scoring_rules         jsonb not null,
  status                content.pub_status not null default 'draft',
  unique (provider_id, exam_name, level, specification_version)
);

create table content.exam_tasks (
  id            uuid primary key default gen_random_uuid(),
  spec_id       uuid not null references content.exam_specs(id) on delete cascade,
  prueba        text not null,                   -- comprension_lectura | comprension_auditiva |
                                                 -- expresion_escrita | expresion_oral
  task_number   int not null,
  task_type     text not null,
  item_count    int,
  duration_min  int,
  descriptors   jsonb
);

-- ---- publication artefacts ----------------------------------------------
create table content.content_packs (
  id              uuid primary key default gen_random_uuid(),
  scope_type      text not null,                 -- 'unit' | 'level' | 'global'
  scope_id        uuid,
  version         int not null,
  manifest_path   text not null,                 -- CDN path in `content-packs`
  bytes           bigint,
  asset_count     int,
  published_at    timestamptz not null default now(),
  published_by    uuid not null,
  superseded_by   uuid references content.content_packs(id),
  unique (scope_type, scope_id, version)
);

-- =============================================================== LEARNING ==

create table learning.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  ui_locale    text not null default 'th',
  created_at   timestamptz not null default now(),
  deleted_at   timestamptz
);

create table learning.learner_preferences (
  learner_id           uuid primary key references learning.profiles(id) on delete cascade,
  goal                 text,                     -- live_in_spain|travel|partner|work|dele|interest
  daily_goal_minutes   int not null default 15,
  self_reference       text not null default 'both',   -- masculine|feminine|both (02/01)
  explanation_depth    int not null default 1 check (explanation_depth between 1 and 4),
  thai_support         text not null default 'auto',
  voice_preference     text not null default 'both',
  consent_store_audio      boolean not null default false,
  consent_improve_product  boolean not null default false,
  consent_analytics        boolean not null default false,
  audio_retention_days int not null default 90
);

create table learning.objective_mastery (
  learner_id        uuid not null references learning.profiles(id) on delete cascade,
  objective_id      uuid not null references content.learning_objectives(id),
  p_mastery         numeric not null default 0 check (p_mastery between 0 and 1),
  evidence_count    int not null default 0,
  productive_evidence_count int not null default 0,
  delayed_success_count     int not null default 0,
  last_evidence_at  timestamptz,
  first_mastered_at timestamptz,
  primary key (learner_id, objective_id)
);
-- INVARIANT (enforced in the update_mastery RPC, 04 §39):
--   mastery requires productive_evidence_count >= 1 AND delayed_success_count >= 1.
--   recognition-only evidence can never push p_mastery above 0.70.

create table learning.review_queue (
  learner_id   uuid not null references learning.profiles(id) on delete cascade,
  item_type    text not null,                    -- 'sense' | 'collocation' | 'concept' | 'pron_target'
  item_id      uuid not null,
  state        text not null default 'new',      -- new|learning|review|lapsed|mastered|suspended
  stability    numeric,                          -- FSRS
  difficulty   numeric,                          -- FSRS
  due_at       timestamptz not null,
  reps         int not null default 0,
  lapses       int not null default 0,
  receptive_p  numeric not null default 0,
  productive_p numeric not null default 0,
  primary key (learner_id, item_type, item_id)
);
create index review_due_idx on learning.review_queue (learner_id, due_at)
  where state <> 'suspended';                    -- hottest query in the product (04 §36)

create table learning.skill_estimates (
  learner_id uuid not null references learning.profiles(id) on delete cascade,
  dimension  content.skill not null,
  theta      numeric not null,
  se         numeric not null,                   -- never show theta without representable uncertainty
  updated_at timestamptz not null default now(),
  primary key (learner_id, dimension)
);

create table learning.learner_error_patterns (
  learner_id            uuid not null references learning.profiles(id) on delete cascade,
  code                  text not null references content.error_taxonomy(code),
  occurrence_count      int not null default 0,
  weighted_recent_count numeric not null default 0,
  session_count         int not null default 0,
  first_seen            timestamptz not null default now(),
  last_seen             timestamptz not null default now(),
  status                text not null default 'observed',
  primary key (learner_id, code)
);
-- INVARIANT: status may only reach 'recurring' when
--   occurrence_count >= 3 AND session_count >= 2  (02 §21 — never label from one mistake)

-- ================================================================= ASSESS ==

create table assess.exercise_attempts (
  id               uuid primary key,             -- CLIENT-GENERATED (idempotency, 04 §45)
  learner_id       uuid not null references learning.profiles(id) on delete cascade,
  exercise_id      uuid not null references content.exercises(id),
  objective_id     uuid,
  raw_answer       jsonb not null,
  is_correct       boolean not null,             -- SERVER-COMPUTED ONLY (04 §37)
  error_codes      text[],
  latency_ms       int,
  content_version  int not null,                 -- so analytics never compares rewritten lessons
  modality         text not null default 'typed',
  created_at       timestamptz not null default now()
);
create index on assess.exercise_attempts (learner_id, created_at desc);
-- append-only: no UPDATE/DELETE policy for authenticated (04 §37 SHAPE C)

create table assess.speech_attempts (
  id                 uuid primary key,
  learner_id         uuid not null references learning.profiles(id) on delete cascade,
  target_text        text not null,
  pron_target_id     uuid references content.pronunciation_targets(id),
  audio_path         text,                       -- private bucket; null if consent withheld
  transcript_raw     text,
  transcript_norm    text,
  asr_confidence     numeric,
  verdict            text not null,              -- 'ok' | 'issue' | 'inconclusive'
  detected_issues    text[],                     -- error taxonomy PRON.* codes
  created_at         timestamptz not null default now()
);
-- INVARIANT: verdict='inconclusive' contributes NO negative mastery evidence (04 §42)

-- ===================================================================== AI ==

create table ai.explanation_cache (
  context_hash  text primary key,                -- hash(concept,level,depth,sentence,locale,self_ref)
  concept_id    uuid,
  depth         int not null,
  answer_th     text not null,
  model         text not null,
  prompt_version text not null,
  guard_verdict text not null,
  hits          int not null default 0,
  created_at    timestamptz not null default now()
);
-- Global, NOT learner-scoped: the same 5,000 curriculum sentences generate the
-- same questions across all learners. This is the single largest AI cost lever.

create table ai.ai_requests (
  id             uuid primary key default gen_random_uuid(),
  learner_id     uuid references learning.profiles(id) on delete set null,
  feature        text not null,                  -- tutor|explain|write_feedback|speech|tts
  tier           text not null,                  -- t1|t2|t3
  model          text not null,
  prompt_version text not null,
  input_tokens   int, output_tokens int,
  cost_usd       numeric,
  latency_ms     int,
  cache_hit      boolean not null default false,
  guard_verdict  text not null,                  -- pass|repaired|failed_fallback
  created_at     timestamptz not null default now()
);
-- NOTE: raw learner text is NOT stored here (04 §41, §48).

-- ================================================================== ADMIN ==

create table admin.content_reviews (
  id             uuid primary key default gen_random_uuid(),
  entity_type    text not null,
  entity_id      uuid not null,
  gate           text not null,                  -- ai_validation|spain_language|pedagogical|
                                                 -- factual|human_review
  verdict        text not null,                  -- pass|warn|fail
  findings       jsonb,
  reviewer_id    uuid,
  reviewer_role  text,                           -- 'peninsular_editor' | 'thai_editor' | 'system'
  style_guide_version text,
  created_at     timestamptz not null default now()
);

create table admin.exam_spec_verifications (
  id            uuid primary key default gen_random_uuid(),
  spec_id       uuid not null references content.exam_specs(id),
  checked_at    timestamptz not null default now(),
  source_url    text not null,
  diff_detected boolean not null,
  diff_summary  text,
  action_taken  text
);
-- Cron alerts when content.exam_specs.last_verified_at is older than 180 days (02 §25.2)

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

-- ============================================================================
--  RLS: every table above gets `alter table ... enable row level security;`
--  plus the three policy shapes in 04 §37. Omitted here for brevity — but they
--  are NOT optional, and the pgTAP RLS suite (04 §49) must cover every table.
-- ============================================================================
