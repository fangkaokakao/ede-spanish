-- ============================================================================
-- 20260824090000_foundation_and_content.sql
-- Phase 3 / migration 1 of 5.
-- Schemas, extensions, enums, helper functions, and the CONTENT domain.
-- Additive only. Never edit an applied migration; write a new one.
-- ============================================================================

create extension if not exists "pgcrypto";
create extension if not exists "ltree";

-- ---------------------------------------------------------------- SCHEMAS --
create schema if not exists content;   -- curriculum (published = world-readable)
create schema if not exists learning;  -- learner state (owner only)
create schema if not exists assess;    -- attempts & submissions (append-only)
create schema if not exists ai;        -- AI ledger, cache, conversations
create schema if not exists admin;     -- review, publication, audit
create schema if not exists analytics; -- events

comment on schema content  is 'Curriculum. Readable when published. Written only via admin RPCs.';
comment on schema learning is 'Per-learner state. Owner-only RLS.';
comment on schema assess   is 'Attempts and submissions. Append-only: an attempt is a fact.';
comment on schema ai       is 'AI request ledger and global explanation cache.';
comment on schema admin    is 'Editorial workflow and audit. Admin/editor roles only.';

-- ------------------------------------------------------------------ ENUMS --
create type content.cefr as enum ('pre_a1','a1','a2','b1','b2','c1','c2');

create type content.node_kind as enum ('course','module','unit');

create type content.pub_status as enum (
  'draft','ai_validated','lang_checked','ped_checked',
  'in_review','approved','published','retired','rejected');

create type content.register as enum (
  'formal_high','formal','neutral','informal',
  'colloquial','slang','professional','administrative');

-- The single most important column in the database: it is what lets the
-- Spain guard flag `computadora` in a lesson but allow it in a contrast note.
create type content.variety_intent as enum (
  'es_ES_target',      -- productive target. LatAm defaults here are an ERROR.
  'contrast_note',     -- deliberate comparison. Must carry a label.
  'recognition_only'); -- comprehension only. Excluded from all drills.

create type content.skill as enum (
  'listening','reading','speaking','interaction','writing',
  'pronunciation','grammar','lexis','sociolinguistic','pragmatic');

create type content.evidence_kind as enum (
  'recognition',   -- multiple choice / matching. Capped contribution.
  'production',    -- typed, conjugated, transformed
  'free_written',  -- unprompted use in the learner's own writing
  'free_spoken',   -- unprompted use in conversation
  'delayed');      -- correct on a review >= 14 days later

-- --------------------------------------------------------------- HELPERS --
-- Role check via JWT claim. SECURITY DEFINER + a hardened search_path so it
-- cannot itself be caught by RLS (the classic recursive-policy footgun).
create or replace function admin.jwt_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claims', true)::jsonb ->> 'app_role', ''),
    'learner');
$$;

create or replace function admin.is_editor() returns boolean
language sql stable security definer set search_path = '' as $$
  select admin.jwt_role() in ('editor','admin');
$$;

create or replace function admin.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select admin.jwt_role() = 'admin';
$$;

create or replace function content.touch_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at := now(); return new; end $$;

-- ============================================================== CONTENT ====

create table content.cefr_levels (
  level              content.cefr primary key,
  ordinal            int not null unique,
  name_th            text not null,
  tagline_th         text not null,
  thai_support_ratio numeric not null check (thai_support_ratio between 0 and 1),
  outcomes           jsonb not null default '{}'::jsonb,
  completion_rules   jsonb not null default '{}'::jsonb,
  is_available       boolean not null default false  -- false => shown as "เร็วๆ นี้"
);
comment on column content.cefr_levels.is_available is
  'Levels with no QA-complete curriculum are visible but not enterable. Never label incomplete content complete.';

-- Course > Module > Unit collapsed into one typed tree. Three tables with
-- identical shape and identical queries is a maintenance tax, not normalisation.
create table content.curriculum_nodes (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid references content.curriculum_nodes(id) on delete restrict,
  kind        content.node_kind not null,
  level       content.cefr not null references content.cefr_levels(level),
  slug        text not null unique,
  title_th    text not null,
  title_es    text,
  subtitle_th text,
  icon        text,
  sort_order  int not null default 0,
  path        ltree,
  status      content.pub_status not null default 'draft',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint node_root_shape check (
    (kind = 'course'  and parent_id is null) or
    (kind <> 'course' and parent_id is not null))
);
create index curriculum_nodes_parent_idx on content.curriculum_nodes(parent_id, sort_order);
create index curriculum_nodes_path_idx   on content.curriculum_nodes using gist(path);
create index curriculum_nodes_pub_idx    on content.curriculum_nodes(level, sort_order)
  where status = 'published';
create trigger t_nodes_touch before update on content.curriculum_nodes
  for each row execute function content.touch_updated_at();

create table content.learning_objectives (
  id            uuid primary key default gen_random_uuid(),
  code          text not null unique,              -- 'PRE_A1.U1.O2'
  level         content.cefr not null references content.cefr_levels(level),
  skill         content.skill not null,
  can_do_th     text not null,                     -- "บอกชื่อตัวเองเป็นภาษาสเปนได้"
  can_do_es     text,
  is_core       boolean not null default true,
  mastery_rules jsonb not null default
    '{"threshold":0.85,"min_productive":1,"min_delayed":1}'::jsonb
);
comment on column content.learning_objectives.is_core is
  'Core objectives gate level completion. Personalisation may reorder them, never skip them.';

create table content.lessons (
  id                uuid primary key default gen_random_uuid(),
  unit_id           uuid not null references content.curriculum_nodes(id) on delete restrict,
  slug              text not null unique,
  sort_order        int not null default 0,
  estimated_minutes int not null default 8 check (estimated_minutes between 2 and 30),
  current_version   int not null default 1,
  status            content.pub_status not null default 'draft',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index lessons_unit_idx on content.lessons(unit_id, sort_order);
create trigger t_lessons_touch before update on content.lessons
  for each row execute function content.touch_updated_at();

create table content.lesson_versions (
  id                  uuid primary key default gen_random_uuid(),
  lesson_id           uuid not null references content.lessons(id) on delete cascade,
  version             int not null,
  title_th            text not null,
  title_es            text,
  goal_th             text not null,        -- "เรียนจบแล้วคุณจะบอกชื่อตัวเองได้"
  -- Server-verified completion contract for THIS lesson. Different lessons
  -- legitimately need different evidence, so the requirement is authored
  -- content, not a constant in Dart or a single global rule.
  --   required_correct_exercises : uuid[]  must have >=1 correct attempt each
  --   required_speech_exercises  : uuid[]  must have an evaluated submission
  --   min_blocks_viewed          : int     optional floor
  -- An empty contract is REJECTED by complete_lesson(): a lesson with no
  -- evidence requirement would be a trust button.
  completion_rules    jsonb not null default '{}'::jsonb,
  style_guide_version text not null default 'sg-0.1',
  published_at        timestamptz,
  created_at          timestamptz not null default now(),
  unique (lesson_id, version)
);

create table content.lesson_objectives (
  lesson_version_id uuid references content.lesson_versions(id) on delete cascade,
  objective_id      uuid references content.learning_objectives(id) on delete restrict,
  primary key (lesson_version_id, objective_id)
);

-- Validated block schemas only. Never executable UI instructions from the CMS.
create table content.content_blocks (
  id                uuid primary key default gen_random_uuid(),
  lesson_version_id uuid not null references content.lesson_versions(id) on delete cascade,
  sort_order        int not null,
  block_type        text not null check (block_type in (
                      'heading','text','explanation','example','comparison','tip','warning',
                      'grammar_breakdown','interactive_sentence','image','audio','dialogue',
                      'pronunciation_guide','timeline','table','exercise_embed',
                      -- added for the vertical slice: a vocabulary card, a
                      -- speaking task and an end-of-lesson recap are distinct
                      -- renderers, not variants of 'text'
                      'vocabulary','speaking_prompt','review')),
  payload           jsonb not null,
  offline_capable   boolean not null default true,
  variety_intent    content.variety_intent not null default 'es_ES_target',
  register          content.register default 'neutral',
  concept_id        uuid,
  why_l1_th         text,   -- pre-authored instant Why answer: 0 cost, offline, <16ms
  unique (lesson_version_id, sort_order)
);
comment on column content.content_blocks.why_l1_th is
  'Ships inside the offline pack. Target: >=70% of Why taps resolve here with no model call.';

-- ---- grammar -------------------------------------------------------------
create table content.grammar_concepts (
  id               uuid primary key default gen_random_uuid(),
  slug             text not null unique,
  cefr_introduced  content.cefr not null,
  cefr_mastered    content.cefr not null,
  name_th          text not null,
  name_es          text not null,
  answers          jsonb not null default '{}'::jsonb,  -- the 16 mandatory questions, keyed
  explain_l1_th    text not null,
  explain_l2_th    text not null,
  explain_l3_th    text,
  explain_l4_th    text,
  spain_usage_note text,
  visual_model     text check (visual_model in
                     ('agreement_arrows','timeline','pronoun_swap','morphology','contrast_pair',null)),
  dele_relevance   content.cefr[] default '{}',
  status           content.pub_status not null default 'draft',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create trigger t_concepts_touch before update on content.grammar_concepts
  for each row execute function content.touch_updated_at();

alter table content.content_blocks
  add constraint content_blocks_concept_fk
  foreign key (concept_id) references content.grammar_concepts(id) on delete set null;

create table content.grammar_concept_edges (
  prerequisite_id uuid not null references content.grammar_concepts(id) on delete cascade,
  concept_id      uuid not null references content.grammar_concepts(id) on delete cascade,
  strength        numeric not null default 1.0 check (strength > 0 and strength <= 1),
  primary key (prerequisite_id, concept_id),
  constraint no_self_edge check (prerequisite_id <> concept_id)
);
comment on table content.grammar_concept_edges is
  'Prerequisite DAG. Enables gap attribution: repeated adjective-agreement failure points at noun gender.';

create table content.thai_contrast_notes (
  id              uuid primary key default gen_random_uuid(),
  concept_id      uuid references content.grammar_concepts(id) on delete cascade,
  thai_reality_th text not null,
  strategy_th     text not null,
  bridge_example  text
);

create table content.error_taxonomy (
  code        text primary key,
  parent_code text references content.error_taxonomy(code),
  label_th    text not null,
  concept_id  uuid references content.grammar_concepts(id) on delete set null,
  severity    text not null default 'medium' check (severity in ('low','medium','high'))
);

-- ---- vocabulary ----------------------------------------------------------
create table content.vocabulary_entries (
  id          uuid primary key default gen_random_uuid(),
  lemma       text not null,
  pos         text not null,
  gender      text check (gender in ('m','f','mf',null)),
  plural_form text,
  -- Two transcriptions, never one. A single "ipa" column forces a lie: the
  -- phonemic form is variety-level, the phonetic form is realisation-level and
  -- differs by position and speaker. See 0005 for the course's chosen model.
  ipa_phonemic text,   -- /..../  broad, matches the taught target variety
  ipa_phonetic text,   -- [....]  narrow, matches the reference audio
  freq_band   int check (freq_band between 1 and 10),
  status      content.pub_status not null default 'draft',
  unique (lemma, pos)
);

create table content.vocabulary_senses (
  id                   uuid primary key default gen_random_uuid(),
  entry_id             uuid not null references content.vocabulary_entries(id) on delete cascade,
  sense_order          int not null default 1,
  meaning_es           text not null,
  meaning_th           text not null,
  register             content.register not null default 'neutral',
  cefr                 content.cefr not null,
  domain               text,
  false_friend         boolean not null default false,
  false_friend_note_th text,
  spain_note           text,
  variety_intent       content.variety_intent not null default 'es_ES_target',
  unique (entry_id, sense_order)
);
comment on column content.vocabulary_senses.spain_note is
  'e.g. coger: everyday and neutral in Spain. Taught normally. Note exists for the LatAm false-friend risk only.';

create table content.vocabulary_examples (
  id         uuid primary key default gen_random_uuid(),
  sense_id   uuid not null references content.vocabulary_senses(id) on delete cascade,
  sentence_es text not null,
  meaning_th  text not null,
  audio_id    uuid
);

create table content.collocations (
  id         uuid primary key default gen_random_uuid(),
  sense_id   uuid references content.vocabulary_senses(id) on delete cascade,
  phrase     text not null,
  meaning_th text not null,
  cefr       content.cefr not null,
  register   content.register not null default 'neutral'
);
comment on table content.collocations is
  'First-class SRS items. Thai speakers systematically calque Thai verb+noun pairings, so hacer una pregunta must be learned as a unit.';

-- ---- the Spain lexical policy, as DATA -----------------------------------
create table content.lexicon_policy (
  id                 uuid primary key default gen_random_uuid(),
  spain_form         text not null,
  alternative_form   text not null,
  alternative_status text not null check (alternative_status in
                       ('not_default','wrong_in_spain','false_friend')),
  note_th            text,
  first_cefr         content.cefr,
  severity           text not null default 'error' check (severity in ('warn','error')),
  policy_version     int not null default 1,
  unique (spain_form, alternative_form, policy_version)
);
comment on table content.lexicon_policy is
  'Read by the L2 validator. Never a blind blacklist: severity is scoped by the item variety_intent.';

-- ---- pronunciation & audio ----------------------------------------------
create table content.pronunciation_targets (
  id                uuid primary key default gen_random_uuid(),
  slug              text not null unique,
  ipa_phonemic      text not null,
  ipa_phonetic      jsonb not null default '[]'::jsonb,  -- [{"context":"tras pausa","ipa":"ɟ͡ʝ"}]
  orthography_rules text not null,
  articulation_th   text not null,
  thai_contrast_th  text not null,
  typical_error_th  text not null,
  minimal_pairs     jsonb not null default '[]'::jsonb,
  variation_note_th text,          -- real variation inside Spain, shown later as recognition
  is_productive_target boolean not null default true,
  cefr_introduced   content.cefr not null,
  priority          int not null
);
comment on column content.pronunciation_targets.is_productive_target is
  'false = recognition only. Lets us teach a single confident production target while still exposing learners to Spain-internal variation later.';

create table content.audio_assets (
  id              uuid primary key default gen_random_uuid(),
  storage_path    text not null unique,
  locale          text not null default 'es-ES' check (locale = 'es-ES'),
  speaker_type    text not null check (speaker_type in ('human','tts')),
  voice_id        text not null,
  voice_gender    text not null check (voice_gender in ('male','female')),
  speed           text not null default 'normal' check (speed in ('normal','slow')),
  granularity     text not null default 'sentence'
                    check (granularity in ('sentence','word','syllable')),
  transcript      text not null,
  duration_ms     int,
  ipa_realization text,        -- what THIS recording actually does, speaker-specific
  content_version int not null default 1,
  approved_by     uuid,
  approved_at     timestamptz
);
comment on column content.audio_assets.locale is
  'CHECK-pinned to es-ES. A LatAm voice cannot be stored, not merely discouraged.';
comment on column content.audio_assets.voice_gender is
  'Speaker voice. Unrelated to grammatical gender: a male voice says "La casa es bonita" too.';

alter table content.vocabulary_examples
  add constraint vocab_example_audio_fk
  foreign key (audio_id) references content.audio_assets(id) on delete set null;

-- ---- exercises -----------------------------------------------------------
create table content.exercise_templates (
  id              text primary key,
  schema          jsonb not null,
  skill           content.skill not null,
  evidence_kind   content.evidence_kind not null,
  productive      boolean not null,
  renderer        text not null
);
comment on table content.exercise_templates is
  'Schema-driven. Adding an exercise must never require a Flutter release.';

create table content.exercises (
  id             uuid primary key default gen_random_uuid(),
  template_id    text not null references content.exercise_templates(id),
  objective_id   uuid references content.learning_objectives(id) on delete set null,
  concept_id     uuid references content.grammar_concepts(id) on delete set null,
  lesson_version_id uuid references content.lesson_versions(id) on delete cascade,
  cefr           content.cefr not null,
  difficulty     numeric,                    -- Rasch b, calibrated from live attempts
  prompt_th      text,
  payload        jsonb not null,
  answer_rules   jsonb not null,             -- accepted variants, accent tolerance
  feedback       jsonb not null default '{}'::jsonb,  -- the 9-part wrong-answer structure
  variety_intent content.variety_intent not null default 'es_ES_target',
  status         content.pub_status not null default 'draft'
);
create index exercises_lesson_idx on content.exercises(lesson_version_id);
create index exercises_objective_idx on content.exercises(objective_id);

-- ---- DELE exam specs: versioned DATA, never code -------------------------
create table content.exam_providers (
  id   uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table content.exam_specs (
  id                    uuid primary key default gen_random_uuid(),
  provider_id           uuid not null references content.exam_providers(id),
  exam_name             text not null,
  level                 content.cefr not null,
  specification_version text not null,
  effective_from        date not null,
  effective_to          date,
  source_reference_url  text not null,
  last_verified_at      timestamptz not null,
  verified_by           uuid,
  total_duration_min    int,
  grouping_rules        jsonb not null default '{}'::jsonb,
  scoring_rules         jsonb not null default '{}'::jsonb,
  status                content.pub_status not null default 'draft',
  unique (provider_id, exam_name, level, specification_version)
);
comment on table content.exam_specs is
  'Published DELE groupings differ between levels and the A1/A2 formats were renewed. Sources disagree. Therefore: data with a source URL and a verification date, never prose in a lesson and never a constant in Dart.';

create table content.exam_tasks (
  id           uuid primary key default gen_random_uuid(),
  spec_id      uuid not null references content.exam_specs(id) on delete cascade,
  prueba       text not null check (prueba in
                 ('comprension_lectura','comprension_auditiva',
                  'expresion_escrita','expresion_oral')),
  task_number  int not null,
  task_type    text not null,
  item_count   int,
  duration_min int,
  descriptors  jsonb default '{}'::jsonb,
  unique (spec_id, prueba, task_number)
);

-- ---- publication artefacts ----------------------------------------------
create table content.content_packs (
  id            uuid primary key default gen_random_uuid(),
  scope_type    text not null check (scope_type in ('unit','level','global')),
  scope_id      uuid,
  version       int not null,
  manifest_path text not null,
  bytes         bigint,
  asset_count   int,
  published_at  timestamptz not null default now(),
  published_by  uuid,
  superseded_by uuid references content.content_packs(id),
  unique (scope_type, scope_id, version)
);
comment on table content.content_packs is
  'Published curriculum is compiled to immutable CDN packs. Tables are the write model; packs are the read model. Offline works by construction and rollback is a pointer change.';
