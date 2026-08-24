# 04 — Technical Architecture

Covers spec items **35–53**.

---

## 35. Database domain model

**[DECIDED] Six Postgres schemas, not one `public`.** Rationale: RLS policy surfaces stay
comprehensible, grants are coarse-grained and auditable, and "is this row public
curriculum or private learner data?" becomes a *structural* property rather than a
per-table memory test.

| Schema | Contains | Default access posture |
|---|---|---|
| `content` | curriculum, grammar, vocabulary, exercises, audio metadata, exam specs | read-only to authenticated when `status='published'`; write = editor role only |
| `learning` | enrolments, progress, mastery, SRS, preferences, plans, bookmarks | owner-only |
| `assess` | attempts, submissions, speech attempts, assessments, placement | owner-only, insert-once semantics |
| `ai` | requests, responses, cached explanations, conversations, feedback | owner-only for conversations; cache is service-managed |
| `admin` | reviews, versions, publications, audit, exam verification | admin/editor only |
| `analytics` | event stream, aggregates | write-only from client, read = service/admin |

**Normalisation decisions (justified, per the instruction to justify rather than blindly
create the listed tables):**

- **Merged:** `courses` + `modules` + `units` into a single self-referencing
  `content.curriculum_nodes(id, parent_id, node_type, ...)`. Three near-identical tables
  with the same fields and the same queries is a maintenance tax; a typed tree with a
  `node_type` check constraint and a materialised `path` gives the same integrity with
  one set of policies and one set of indexes. Lessons stay separate because their shape
  genuinely differs (versioning, blocks, objectives).
- **Merged:** `grammar_rules` / `grammar_examples` / `grammar_exceptions` into
  `content.grammar_concepts` (structured JSONB for the 16 answers and 4 depths) +
  `content.grammar_examples` (rows, because they need audio, tapping, and reuse).
  Rules and exceptions are *prose fields of a concept*, not independent entities — they
  are never queried alone.
- **Merged:** `streaks` into `learning.learner_stats` — a streak is a derived counter,
  not a domain.
- **Kept separate (against the temptation to merge):**
  `assess.exercise_attempts` vs `assess.speech_attempts` vs `assess.writing_submissions`.
  They have different sizes, different retention rules, different privacy classes
  (audio is biometric-adjacent), and wildly different write volumes.
- **Kept separate:** `vocabulary_entries` / `_senses` / `_examples` (see `02` §10.1).
- **Added (not in the original list, and necessary):**
  `content.content_packs` + `content.pack_manifests` (offline delivery),
  `content.lexicon_policy` (the Spain preference table as data),
  `content.error_taxonomy`, `content.thai_contrast_notes`,
  `ai.explanation_cache`, `admin.exam_spec_verifications`,
  `learning.sync_cursors`, `assess.attempt_idempotency`.

---

## 36. Proposed ERD

Illustrative DDL: `06-core-schema-sketch.sql`. Core relationships:

```
content.languages ──< content.language_variants (es-ES, es-419 recognition-only)
content.cefr_levels ──< content.curriculum_nodes (self-ref tree: course>module>unit)
                                 │
                                 └──< content.lessons ──< content.lesson_versions
                                            │                      │
                                            │                      └──< content.content_blocks
                                            └──< content.lesson_objectives >── content.learning_objectives
                                                                                     │
content.grammar_concepts ──< content.grammar_concept_edges (DAG, prerequisites)       │
        │  │                                                                          │
        │  └──< content.grammar_examples ──< content.audio_assets                      │
        └──< content.thai_contrast_notes                                              │
                                                                                      │
content.vocabulary_entries ──< _senses ──< _examples, content.collocations            │
content.pronunciation_targets ──< content.audio_assets                                │
content.exercise_templates ──< content.exercises ──< content.exercise_items ──────────┘
content.exam_providers ──< content.exam_specs ──< content.exam_tasks
content.content_packs ──< content.pack_manifests   (compiled publish artefacts)

auth.users ──1:1── learning.profiles
                        ├──< learning.learner_preferences
                        ├──< learning.enrolments ──< learning.lesson_progress
                        ├──< learning.objective_mastery
                        ├──< learning.vocabulary_mastery ──< learning.review_queue
                        ├──< learning.grammar_mastery
                        ├──< learning.skill_estimates
                        ├──< learning.learner_error_patterns >── content.error_taxonomy
                        ├──< learning.study_plans ──< learning.daily_sessions
                        ├──< learning.bookmarks, learning.learner_stats
                        ├──< assess.exercise_attempts
                        ├──< assess.assessment_attempts (placement, mastery check, mock)
                        ├──< assess.writing_submissions ──< assess.writing_feedback
                        ├──< assess.speech_attempts ──< assess.pronunciation_feedback
                        ├──< ai.conversation_sessions ──< ai.conversation_messages
                        └──< ai.ai_requests (cost/latency/model ledger)

admin.content_reviews, admin.publication_history, admin.audit_logs,
admin.exam_spec_verifications, admin.ai_prompt_versions
ai.explanation_cache (global, keyed by context hash — not learner-scoped)
```

**Indexing notes that matter at scale:**
`learning.review_queue(learner_id, due_at)` partial index `WHERE state <> 'suspended'` —
this is the hottest query in the product. `assess.exercise_attempts(learner_id,
created_at DESC)` and a BRIN on `created_at` for the analytics rollups.
`ai.explanation_cache(context_hash)` unique. Everything learner-scoped leads with
`learner_id` so RLS predicates are index-supported.

---

## 37. RLS model

**Every table has RLS enabled. No exceptions, no "temporarily disable to debug".**

Three policy shapes, applied consistently:

```sql
-- SHAPE A: published public content (content.*)
create policy read_published on content.lessons
  for select to authenticated
  using (status = 'published');
-- writes: no policy for authenticated at all; editors go through
-- SECURITY DEFINER functions in the admin API, never direct table writes.

-- SHAPE B: owner-only learner data (learning.*, assess.*, ai.conversations)
create policy own_rows on learning.lesson_progress
  for select using ((select auth.uid()) = learner_id);
create policy own_insert on learning.lesson_progress
  for insert with check ((select auth.uid()) = learner_id);
create policy own_update on learning.lesson_progress
  for update using ((select auth.uid()) = learner_id)
         with check ((select auth.uid()) = learner_id);
-- NO delete policy: learner deletion happens via the account-deletion RPC only.

-- SHAPE C: append-only assessment integrity (assess.*)
create policy own_read on assess.exercise_attempts
  for select using ((select auth.uid()) = learner_id);
create policy own_append on assess.exercise_attempts
  for insert with check ((select auth.uid()) = learner_id);
-- no update, no delete for anyone but service_role. An attempt is a fact.
```

Notes:
- `(select auth.uid())` rather than bare `auth.uid()` — this lets Postgres cache the
  value as an InitPlan instead of re-evaluating per row. On a 200k-row attempts table
  this is the difference between 8 ms and 900 ms. It is not a style preference.
- **Admin access is role-based via a JWT claim**, checked in a `SECURITY DEFINER`
  helper `admin.is_editor()`, not via a lookup that itself needs RLS (a classic
  recursion footgun).
- **Scores and correctness are never written by the client.** `is_correct`, `p_mastery`,
  `theta`, and `readiness` are computed by RPCs/Edge Functions. If the client could
  write them, the entire measurement layer would be fiction.
- **RLS is tested, not assumed.** A dedicated pgTAP-style suite asserts, for each table:
  learner A cannot read/write learner B's row; anon cannot read unpublished content;
  authenticated cannot write `content.*`. This suite runs in CI on every migration.

---

## 38. Storage model

Buckets, deliberately separated by privacy class:

| Bucket | Public? | Contents | Retention |
|---|---|---|---|
| `content-audio` | public (CDN) | approved curriculum TTS + human recordings | with content version |
| `content-media` | public (CDN) | illustrations, diagrams, images | with content version |
| `content-packs` | public (CDN) | compiled versioned lesson packs (JSON + asset lists) | last N versions |
| `learner-audio` | **private** | learner recordings | default 90 days, configurable, deleted on request |
| `learner-uploads` | **private** | writing attachments (future) | on request |
| `admin-drafts` | **private** | unapproved audio/media in review | until publish/reject |

**Rules.** Learner recordings never enter a public bucket — enforced structurally by the
bucket split, not by a naming convention. Signed URLs, short TTL (≤ 5 min), issued by an
Edge Function that re-checks ownership. Upload MIME and size validated server-side
(`m4a/aac/wav`, ≤ 5 MB, ≤ 60 s). Path convention
`learner-audio/{learner_id}/{yyyy}/{mm}/{attempt_id}.m4a` with an RLS storage policy on
the `{learner_id}` path segment.

---

## 39. Backend architecture

Supabase, with a deliberate split of responsibilities:

- **PostgREST (direct table reads)** — only for the learner's own small, hot data
  (progress, review queue, preferences). Low latency, RLS-protected.
- **Postgres RPCs (`SECURITY DEFINER`)** — for anything with business rules:
  `submit_attempt()`, `update_mastery()`, `schedule_review()`, `complete_lesson()`,
  `start_placement()` / `next_placement_item()`, `claim_level()`. These enforce
  invariants that RLS cannot express (idempotency, score computation, evidence weighting).
- **Edge Functions (Deno)** — for anything needing a secret, an external call, or
  significant CPU: the AI gateway, TTS generation, ASR, pronunciation assessment,
  content publication/pack build, account deletion, exam-spec verification job.
- **Scheduled jobs (pg_cron / Supabase cron)** — nightly SRS parameter optimisation,
  analytics rollups, `last_verified_at` staleness alerts, learner-audio retention sweep,
  nightly Spain-drift sampling of tutor output.

**Never:** privileged keys in Flutter; client-computed scores; client-side content
publication; direct client writes to `content.*` or `admin.*`.

**Content delivery — the key architectural decision.**
Published curriculum is **compiled into immutable versioned content packs** (JSON +
asset manifest) written to `content-packs` on CDN, rather than being read row-by-row from
Postgres at runtime. Consequences: offline works by construction; app launch does not hit
the database for curriculum; caching and delta updates are trivial; a bad publish is
rolled back by pointing the manifest at the previous version; and the database is free to
be normalised for authoring rather than contorted for read performance. The tables remain
the source of truth; the packs are the read model. This is CQRS applied where it actually
pays.

---

## 40. Edge Function / API contracts

Typed boundaries (TypeScript on the server, generated Dart models on the client via
`json_serializable` from a shared JSON Schema).

| Function | Purpose | Auth | Rate limit |
|---|---|---|---|
| `ai-tutor-turn` | conversation turn | user JWT | 60/hr, 600/day |
| `ai-explain` | Why / deep explanation (cache-first) | user JWT | 200/day |
| `ai-write-feedback` | writing evaluation | user JWT | 20/day |
| `ai-speech-assess` | ASR + pronunciation assessment | user JWT | 200/day |
| `tts-dynamic` | TTS for AI-generated speech (cached by hash) | user JWT | 300/day |
| `media-sign` | signed URL for a learner's own audio | user JWT | 100/hr |
| `content-publish` | build + publish a content pack | editor JWT | — |
| `content-validate` | run Spain-QA + schema + pedagogy checks | editor JWT | — |
| `exam-spec-verify` | fetch + diff Instituto Cervantes spec pages, raise review task | cron/admin | — |
| `account-delete` | full erasure orchestration | user JWT + re-auth | 1/day |
| `account-export` | data export bundle | user JWT | 1/day |

Every function: request/response schema-validated, correlation-ID logged, idempotency
key honoured on writes, structured error envelope
`{code, message_th, message_en, retryable, correlation_id}` so the client can render a
human Thai message without string-matching on English errors.

---

## 41. AI gateway architecture

```
Flutter ──JWT──▶ Edge: ai-gateway
                    ├─ 1. authn/authz + per-user quota + abuse check
                    ├─ 2. build context (learner model, retrieval, policy)   ← DB
                    ├─ 3. CACHE LOOKUP (ai.explanation_cache)  ─── hit ──▶ return (¢0)
                    ├─ 4. ROUTE to model tier
                    ├─ 5. call provider (secret held server-side only)
                    ├─ 6. SPAIN GUARD L2 validator on output
                    │        └─ fail → repair prompt (1 retry) → still fail → safe fallback
                    ├─ 7. persist ai_requests (model, tokens, cost, latency, verdict)
                    └─ 8. cache + return
```

**Tiering (cost control is an architecture concern, not an afterthought):**

| Tier | Used for | Model class |
|---|---|---|
| T0 — no model | answer validation, conjugation checks, SRS, navigation, progress, plan generation, pre-authored Why answers | deterministic code |
| T1 — small | hints, short L1/L2 explanations, error classification, simple scenario turns at A-levels | small/fast |
| T2 — mid | free conversation, writing feedback, debriefs, L3 explanations | mid |
| T3 — large | L4 linguistic depth on request, CMS content drafting, LLM-judge QA | large |

**Cost levers, in order of impact:** (1) pre-authored Why answers shipped in packs
(target ≥ 70% of taps at T0); (2) global explanation cache keyed by context hash —
the same 5,000 curriculum sentences produce the same questions across all learners;
(3) tiering; (4) context trimming (send a *summary* of the learner model, never raw
history); (5) hard per-user daily quotas with a graceful Thai message, never a silent
failure.

**Fallbacks.** Provider timeout → cached/authored explanation + "ลองใหม่อีกครั้ง".
Conversation failure mid-scenario → the session is preserved and resumable; the learner's
turn is never lost. Guard failure after repair → serve the authored L1/L2 content and log
for review; **never serve unvalidated Spanish.**

**Observability.** Every request logs model, prompt version, tokens, cost, latency, cache
hit, guard verdict, and a truncated hash of the context — not the learner's raw text,
which is privacy-sensitive (§48).

---

## 42. Speech architecture

**TTS.**
- Curriculum audio: **pre-generated at publish time**, stored in `content-audio`, served
  from CDN, bundled into offline packs. Never synthesised on-device or at runtime.
- Dynamic tutor speech: `tts-dynamic`, cached by `hash(text, voice, speed)` — tutor
  utterances repeat heavily across learners.
- Vendor must offer genuine **es-ES** voices with distinción. **[NEEDS VERIFICATION]**
  and **[SPIKE S-01]**: candidate vendors evaluated on a fixed 40-sentence Spain script,
  blind-rated by a native Peninsular speaker on: distinción, trill quality, prosody,
  slow-speed integrity, and *whether the "Spanish" voice is actually LatAm mislabelled*.

**ASR.**
- Two paths. **On-device** (`speech_to_text` → iOS `SFSpeechRecognizer` / Android
  `SpeechRecognizer`, locale `es-ES`) for free, instant, low-stakes repetition and
  conversation input. **Server** (Whisper-class, `language=es`) for scored attempts,
  noisy input, and anything feeding mastery evidence.
- Store: raw transcript (where consent allows), normalised transcript, confidence,
  detected error codes, and the assessment payload.

**The confidence rule — non-negotiable.** ASR failure must never be scored as a learner
error. Below the confidence threshold the app shows
*"ระบบไม่แน่ใจว่าได้ยินถูกหรือไม่ ลองพูดอีกครั้งในที่เงียบกว่านี้"* and the attempt is
recorded as `inconclusive`, contributing **no** negative evidence to mastery.

**Pronunciation assessment — the honest position.**
Real phoneme-level scoring needs either a dedicated pronunciation-assessment API with
es-ES support and per-phoneme output, or a custom forced-alignment pipeline
(MFA/wav2vec-style) with goodness-of-pronunciation scoring. Both are non-trivial.
**[SPIKE S-02]**, timeboxed to 5 days, is required before *any* phoneme-level claim is
made in the UI.

MVP position if the spike does not land: assess only what we can defend —
(a) did the ASR recognise the target word at all, (b) targeted minimal-pair
discrimination (*pero/perro*), (c) syllable/stress placement via alignment, and
(d) self-comparison against the model with A/B playback. This yields honest, useful
feedback ("RR ยังสั่นไม่ชัด" derived from a *pero/perro* confusion) without inventing
an "87%".

---

## 43. Flutter architecture

**[DECIDED] Riverpod (v2+, code-generated) for state; go_router for navigation;
freezed + json_serializable for models; Drift for local persistence; dio for HTTP.**

*Why Riverpod over BLoC:* this app is overwhelmingly **async read-and-cache** (packs,
progress, review queue, AI calls) rather than complex event-driven state machines.
Riverpod gives compile-safe DI, trivially testable providers with overrides, automatic
caching/invalidation (`ref.invalidate` on a mastery update refreshes the plan, the map,
and Home for free), and far less boilerplate. BLoC's event-modelling strength is real but
would be paid for on every one of ~86 screens. **One approach only** — no mixing.

**Layering, feature-first:**

```
lib/
  app/            router, theme, bootstrap, env, DI root
  core/           errors, result types, logging, analytics, connectivity, l10n
  design_system/  tokens, typography (TH+ES), components, learning widgets
  data/           supabase client, api clients, drift db, repositories(impl), dtos
  domain/         entities, repository interfaces, use cases, pure learning logic
  features/
    onboarding/ home/ learn/ lesson/ exercise/ grammar/ vocabulary/
    listening/ speaking/ writing/ reading/ tutor/ progress/ dele/ profile/
      └─ each: presentation/ (screens, widgets, controllers) + application/
```

**Rules.** No feature imports another feature's `presentation`. `domain` has zero Flutter
imports (so the SRS scheduler, mastery maths, and plan generator are pure-Dart unit
testable). All strings in ARB files (`th` primary, `en` fallback) — **zero hardcoded
lesson content in widgets**; lesson content comes from packs.

**Content rendering.** The lesson player is a **schema-driven renderer**: a
`ContentBlock` sealed class → a registry of block widgets. Same for exercises: one
`ExerciseRenderer` with ~28 item-type widgets driven by `exercise_templates`.
Adding a lesson must never require a Flutter release. This is the difference between
680 lessons being possible and impossible.

**Local persistence — [DECIDED] Drift (SQLite).** Why not Isar/Hive: the review queue is
a genuinely relational query (`due items JOIN sense JOIN entry WHERE state<>suspended
ORDER BY due_at`), the sync outbox needs transactional integrity, and Drift gives typed
SQL, real migrations, and testability. Secrets (session tokens) in
`flutter_secure_storage`; nothing sensitive in `SharedPreferences`.

---

## 44. Offline architecture

**Downloadable:** lesson packs (text, blocks, exercises, pre-authored Why answers),
approved audio, vocabulary + SRS data, saved words, the current daily plan.

**Online-only:** AI tutor, writing feedback, server ASR/pronunciation assessment, mock
exam submission scoring, placement (adaptive routing needs the server).
The UI states this *before* the learner taps, never after.

Download granularity = **unit** (a natural, achievable chunk; ~15–40 MB with audio).
Manager shows size, progress, and a per-unit delete. Wi-Fi-only default.

Offline capability is a property of a `ContentBlock` type, declared in the schema —
the renderer disables non-offline blocks with an explanatory placeholder rather than
crashing or silently hiding content.

---

## 45. Sync architecture

**Outbox pattern.** Every learner-generated event (attempt, progress tick, review grade,
bookmark) is written to a local Drift `outbox` table **first**, with a client-generated
UUID `idempotency_key`, then pushed. The UI reads local state, so it is instant and
correct offline.

- Push: batched, exponential backoff, resumed on connectivity regain and app foreground.
- Server: `submit_attempt(payload, idempotency_key)` upserts against
  `assess.attempt_idempotency` — replays are free. This is what makes "duplicate
  submission" a non-issue rather than a bug class.
- Pull: `learning.sync_cursors(learner_id, entity, last_synced_at)`; delta pulls only.
- **Conflict policy:**
  - Attempts/events → **append-only, no conflict possible** (by design).
  - Derived state (mastery, SRS, θ) → **server is authoritative**; the client recomputes
    optimistically for UI and reconciles on pull. Never merge two mastery values.
  - Preferences → last-write-wins with a client timestamp; trivial and acceptable.
  - Content → version-pinned; a device on pack v11 keeps working until it downloads v12.
    An attempt records the `content_version` it was made against, so analytics never
    compares apples to a rewritten lesson.

---

## 46. Analytics

Event taxonomy (`analytics.events`, typed `name` + `props` JSONB, validated server-side):
`lesson_started/completed/abandoned`, `block_viewed`, `exercise_attempted`,
`why_tapped` (+ depth reached), `hint_used`, `audio_played` (+ speed), `recording_made`,
`asr_low_confidence`, `review_completed`, `plan_completed`, `tutor_turn`,
`scenario_completed`, `assessment_submitted`, `download_started`, `error_shown`,
`paywall_viewed` (future).

**Privacy-first:** no raw learner text, no audio, no transcript in analytics. IDs only.
Learner-level analytics is opt-out; aggregate product analytics is contractual.
**[NEEDS DECISION D-06]** vendor: recommend **PostHog EU** or self-hosted, over
Firebase/GA — because we will hold EU-resident learners' data and want event data in the
same jurisdiction as the database.

**Product metrics** (§ "do not optimise for streaks"): weekly active learners, learning
days/week, *review retention rate*, lesson completion, **speaking participation rate**
(the leading indicator of real progress and the first thing that dies in bad UX),
mastery velocity per objective, placement→activation, exam-mode engagement,
and — critically — **delayed retention at 30 days**, which is the only metric that
distinguishes learning from entertainment.

---

## 47. Security

- Flutter ships only the Supabase URL and the **publishable/anon key**. No
  `service_role`, no AI provider key, no admin secret. Ever.
- All AI/TTS/ASR provider secrets live in Edge Function env vars.
- RLS on every table + the CI RLS test suite (§37).
- Server-side validation of every RPC payload; never trust client-supplied
  correctness, scores, level, or role.
- Rate limits on all AI endpoints, per-user and per-IP, with a distinct quota for
  expensive tiers. Abuse detection on anomalous volume.
- Storage: MIME + magic-byte + size validation, private buckets, short-lived signed URLs,
  path-scoped policies.
- Auth: email OTP/password + Apple + Google (Apple is **mandatory** for iOS review if any
  third-party sign-in exists). Account linking by verified email to prevent duplicate
  learner profiles — a real bug class with expensive consequences here, because a
  duplicate profile silently destroys a learner's history.
- Admin operations write to `admin.audit_logs` (actor, action, target, before/after,
  IP, timestamp). Admin sessions are short and require re-auth for destructive actions.
- Dependency scanning + secret scanning in CI. Certificate pinning **[SPIKE S-03]** —
  evaluate cost/benefit; probably not worth it for v1.
- Mock-exam integrity: server-timed, answers not shipped ahead of submission, exam mode
  restricts in-app help.

---

## 48. Privacy

Data inventory by sensitivity:

| Class | Data | Handling |
|---|---|---|
| **High** | voice recordings, writing submissions, tutor conversations | explicit consent, private buckets, default 90-day retention (configurable by the learner: 7/30/90/forever), excluded from logs and analytics |
| Medium | learning history, error patterns, mastery, placement results | owner-only, exportable, deleted with account |
| Low | preferences, goals | owner-only |
| Excluded by design | precise location, contacts, photos, health, ethnicity, third-party identifiers | **not collected** |

- **Consent is granular and pre-recording**, not buried in a ToS: (1) store my
  recordings, (2) use my recordings to improve the product,
  (3) analytics. (2) defaults **off**. Recording works with (1) alone; assessment works
  transiently even with both off (process-and-discard).
- **Export:** `account-export` produces a JSON + audio bundle within the statutory window.
- **Deletion:** `account-delete` is a real cascade — Postgres rows, storage objects,
  AI conversation history, analytics IDs pseudonymised — executed by an Edge Function
  with an audited job record, not a soft flag. Tested as part of the release checklist.
- **Age gate** at signup; product is 13+/16+ depending on jurisdiction
  **[NEEDS DECISION D-07]** — recommend 16+ to sidestep the strictest child-data regimes,
  given we process voice.
- AI provider terms must permit **no-training-on-customer-data**; verify contractually
  before launch. Learner text sent to a provider is the single largest privacy exposure
  in the product.

---

## 49. Testing strategy

| Layer | Tool | What must pass |
|---|---|---|
| Pure domain logic | Dart unit | SRS scheduling, mastery maths, plan allocation, placement stop rules, morphology segmentation |
| Widget | Flutter widget tests | every content block renderer, every exercise item type, all four content states |
| Golden/visual | golden tests | **Thai diacritic clipping**, Spanish accents, dynamic type 200%, dark mode, RTL-safe layout |
| Integration | integration_test | onboarding→first lesson→first attempt; offline download→airplane mode→complete→sync |
| Database | pgTAP | constraints, triggers, RPC invariants, idempotency |
| **RLS** | pgTAP suite | learner A ≠ learner B; anon ≠ unpublished; authenticated ≠ content writes. **Runs on every migration.** |
| Edge Functions | Deno test | contracts, error envelopes, quota enforcement, guard-failure fallback |
| AI evaluation | eval harness | §50 |
| Spain fidelity | eval harness | §51 |
| Content schema | validator CI | every published pack validates against the block/exercise schemas |
| Audio pipeline | script + human sample | locale, voice, speed variants, transcript match |
| Offline/sync | integration | conflict cases, duplicate submission, version pinning |
| Accessibility | automated + manual | contrast, tap targets, screen reader traversal, transcript availability |
| Devices | manual matrix | iOS 16+ / Android 10+, small phone (SE), large phone, low-end Android |

**Explicit rule from the instruction:** nothing is reported as tested that was not
actually run. Every phase report lists the commands executed and their output.

---

## 50. AI evaluation strategy

Three evaluation loops:

1. **Regression suite (CI, blocking).** ~250 cases across: Spain fidelity (§51),
   level adaptation (does the A1 tutor use only A1 structures?), correction policy
   (does it stay quiet mid-conversation?), hallucination (does it refuse to invent a
   normative rule?), Thai explanation quality, safety, and refusal behaviour.
   Judged by rubric (LLM judge + periodic human calibration), scored 0–3, with a
   pass threshold per category. Runs on every prompt-version or model change.
2. **Golden human review.** 50 cases reviewed by a native Peninsular teacher + a Thai
   reviewer each release. The LLM judge is *calibrated against these*, and a judge whose
   agreement with humans falls below κ ≈ 0.6 is retired.
3. **Production sampling.** Nightly, 1% of tutor turns sampled (with consent), scored by
   the guard + judge, dashboarded. A drift alert triggers a prompt review.

**Hallucination-specific test:** ask for rules that don't exist
("¿Por qué los sustantivos que terminan en -aje son femeninos?" — they are masculine).
The tutor must correct the premise, not confabulate a justification.

---

## 51. Spain-dialect evaluation strategy

The suite in `03` §34.2, extended and formalised:

- **Categories:** plural informal address · core lexicon (coche/ordenador/móvil/zumo/
  piso/patata) · `coger` naturalness · perfecto compuesto vs indefinido ·
  pronunciation guidance (distinción) · imperatives (`venid/haced/id`) · possessives
  (`vuestro`) · formal letters and administrative register · roleplay in a Spain setting ·
  colloquial markers (`vale/venga`) · correction of a learner's LatAm form (must follow
  the §3.7 non-shaming pattern) · resistance to a learner *asking* it to switch dialect
  mid-lesson (it should offer a recognition note, not switch its default).
- **Scoring:** meaning + register + Spain-appropriateness rubric, never string equality.
  A response using `zumo de naranja natural` must score full marks even though the
  expected string was `zumo`.
- **Threshold:** ≥ 95% on hard categories (voseo, vosotros, core lexicon),
  ≥ 85% overall. Below → the prompt version cannot be promoted.
- **Drift monitor:** the same suite runs weekly against the *live production
  configuration*, because provider models change underneath us without notice. This is
  the mechanism that keeps the Spain guarantee true six months after launch.

---

## 52. Environments

| Env | Supabase project | Purpose | Data |
|---|---|---|---|
| `local` | supabase CLI (Docker) | dev | seed fixtures |
| `dev` | new project `ede-dev` | integration, CMS testing | synthetic |
| `staging` | new project `ede-staging` | release candidate, beta content rehearsal, exam-mode testing | anonymised |
| `prod` | new project `ede-prod` | live | real |

- **Region:** `eu-west-3`/`eu-central-1` for staging+prod (see `00`). Thailand/Japan
  latency is mitigated by CDN-delivered content packs; only small RPC calls cross the
  distance. **[NEEDS DECISION D-08]** — if measured RPC latency from Bangkok is
  unacceptable in the spike, reconsider `ap-southeast-1` and accept the GDPR complexity.
- **Blocking:** the org currently holds 2 projects; 3 environments require a paid plan
  (**D-02**). Minimum viable compromise: `local` + `dev` + `prod` at first, adding
  `staging` before beta — but **never** ship without a staging environment for a product
  that stores voice data.
- Flutter flavours: `dev`/`staging`/`prod` with separate bundle IDs, icons, and Supabase
  configs, so a tester can hold all three.

---

## 53. Deployment architecture

- **Migrations:** Supabase CLI migrations in git, applied via CI on merge.
  Additive-only in production; destructive changes require an explicit, reviewed,
  two-step expand/contract migration. **No manual dashboard schema edits, ever** —
  they are invisible to git and have already caused pain in prior projects.
- **Edge Functions:** deployed from CI, versioned, with the AI prompt version pinned as
  data (`admin.ai_prompt_versions`) rather than baked into the function.
- **Content:** publication is a *runtime operation by an editor*, decoupled from app
  releases. Publishing writes a new pack version + manifest; rollback repoints the
  manifest. Content and code deploy independently — this is essential when 680 lessons
  are coming.
- **Mobile:** Fastlane, CI-built, TestFlight + Play internal → closed beta → staged
  rollout (10%→50%→100%) with crash-rate gates.
- **Backups:** daily PITR on prod (paid plan requirement), plus a weekly logical dump of
  `content.*` to cold storage — the curriculum is the most expensive asset in the
  company and must survive a catastrophic account event.
- **Monitoring:** Sentry (Flutter + Edge), Supabase logs/metrics, an AI cost & latency
  dashboard, content-load failure rate, ASR failure rate, sync backlog depth.
  Alert thresholds defined before launch, not after the first incident.
- **Incident response:** documented severity levels, on-call (owner), rollback runbooks
  for code, content, and prompt versions independently.
