# 05 — MVP, Roadmap, Risks & Decisions

Covers spec items **54–60**.

---

## 54. MVP definition

**The MVP proves the learning loop end-to-end at one level, not the curriculum at seven.**

### In scope

**Content:** Pre-A1 complete (4 units, ~30 lessons) + A1 Units 1–3 (~24 lessons).
~450 vocabulary entries, ~40 grammar concepts fully authored at L1–L3, 10 pronunciation
targets, 6 scenarios (S-01, S-02, S-03, S-04, S-06, S-12), all audio in 2 Spain voices.

**Learner app (31 screens):** onboarding (goal, experience, daily goal, self-reference) ·
account · simple placement routing (Route A full, Route B v1 = receptive adaptive core
only, no speaking/writing task) · Home + daily plan · CEFR journey + course map + unit ·
lesson player with 10 block renderers · exercise renderer with 12 item types ·
answer feedback · Why bottom sheet (L1–L3) · interactive sentence analysis ·
morphology explorer · word sheet · vocabulary detail + SRS review · listening player ·
pronunciation recorder + result · speaking task · scenario roleplay · AI tutor
conversation + debrief · progress dashboard + skill detail + weak areas ·
profile + preferences + downloads + privacy · search · bookmarks.

**Backend:** full schema for the MVP domains, RLS + RLS test suite, content packs,
AI gateway with tiering + cache + Spain guard L1/L2, TTS pipeline, ASR with confidence
handling, honest pronunciation feedback per `04` §42 MVP position.

**CMS (basic):** lesson block composer, grammar concept editor, vocabulary editor,
exercise authoring, audio manager, review queue, publish/rollback, preview-as-learner.

**Spain guard:** L1 + L2 live; L3 human review mandatory for all published content;
the §51 eval suite running in CI.

### Explicitly out of scope for MVP

A2–C2 content · DELE hub and mock exams · writing coach and rubric feedback ·
reading engine beyond simple lesson texts · full adaptive placement with productive tasks ·
achievements/gamification beyond a streak counter · offline (v1.1) · web app ·
subscriptions · phoneme-level pronunciation scoring · multi-language.

### MVP success criteria (measured in beta, `05` §55 Phase 18)

1. ≥ 60% of new users complete lesson 1 within the first session.
2. ≥ 35% return on day 2; ≥ 20% on day 7.
3. ≥ 50% of active learners use the **speaking** feature weekly (the true product test).
4. ≥ 40% of learners tap **ทำไม?** at least once per session, and ≥ 70% of those
   answer the following retry correctly.
5. ≥ 80% delayed-review accuracy at 14 days.
6. Spain-fidelity eval ≥ 95% hard / ≥ 85% overall.
7. AI cost per active learner per month within budget (**D-09**).
8. Zero incidents of unvalidated Spanish reaching a learner.

**"Do not call incomplete superficial content C2."** The app will display Pre-A1/A1 only,
with the higher levels visibly marked *"เร็วๆ นี้"* — not stubbed and enterable.

---

## 55. Development roadmap

Phases as mandated, with realistic sizing for a small team (assumes 1 owner/PM +
1–2 Flutter devs + 1 backend + contracted native Peninsular editor + Thai editor).

| Phase | Name | Duration | Exit criterion |
|---|---|---|---|
| 0 | Discovery & specification | **done on approval of this document** | owner approval |
| 1 | System architecture | 1–2 wk | ERD frozen, spikes S-01/S-02 resolved, D-01…D-10 answered |
| 2 | Design system & UX | 3 wk | tokens, component library, 12 key screens specified to the §30 nine-point brief, Thai typography verified on device |
| 3 | Backend foundation | 3 wk | migrations, RLS + passing RLS test suite, storage, seed data, publication model |
| 4 | Flutter foundation | 3 wk | routing, auth, design system, Drift, error handling, l10n, flavours |
| 5 | CMS / content system | 3 wk | an editor can author and publish a lesson without an engineer |
| 6 | Learning engine | 4 wk | course map → lesson → block renderer → exercise → feedback → progress → review |
| 7 | Deep grammar engine | 3 wk | Why (3 depths), sentence analysis, morphology, DAG + gap detection |
| 8 | Vocabulary / SRS | 2 wk | FSRS scheduling, active/passive split, review sessions |
| 9 | Audio / pronunciation / speech | 4 wk | Spain audio pipeline, recorder, ASR + confidence, honest feedback |
| 10 | AI Tutor | 4 wk | gateway, retrieval, guard, tiering, conversation, debrief, cost dashboard |
| 11 | Writing / reading / listening | 3 wk | *(post-MVP for writing rubric)* |
| 12 | Placement & assessments | 2 wk | adaptive core, skill profile, honest reporting |
| 13 | Personalisation | 2 wk | error memory, daily plan, remediation, recommendations |
| 14 | Progress & gamification | 2 wk | skill dashboard, CEFR journey, celebrations |
| 15 | DELE preparation | 4 wk | **starts with spec verification**, then exam data model + practice + mocks |
| 16 | Offline / sync | 3 wk | download, outbox, idempotency, conflict handling, version pinning |
| 17 | Hardening | 3 wk | security, RLS, privacy, perf, a11y, AI eval, drift tests, devices |
| 18 | Beta | 4 wk | 50–150 Thai learners, criteria in §54 |
| 19 | Production release | 2 wk | store assets, privacy disclosures, monitoring, runbooks |
| 20 | Post-launch improvement | ongoing | data-driven curriculum + AI improvement |

**MVP ships after Phase 14 + a reduced Phase 17.** Phases 15 (DELE), 16 (offline) and the
writing engine follow in v1.1/v1.2. Realistic MVP calendar: **~7–9 months**.

---

## 56. Dependencies between phases

```
0 ──▶ 1 ──┬──▶ 2 ──┬──▶ 4 ──┬──▶ 6 ──┬──▶ 7 ──▶ 13
          │        │        │       ├──▶ 8 ──▶ 13
          └──▶ 3 ──┴──▶ 5 ──┘       ├──▶ 12 ──▶ 13 ──▶ 14
                   │                └──▶ 9 ──▶ 10 ──▶ 11
                   └──▶ 9(storage)          │
                                            └──▶ 15 (needs 10 + verified specs)
6,8,12 ──▶ 16 (offline needs stable content + attempt models)
all ──▶ 17 ──▶ 18 ──▶ 19 ──▶ 20
```

**Hard blockers, in order of danger:**
1. **Phase 5 (CMS) blocks all content production.** If content authoring waits for
   engineering, the curriculum never scales. CMS is not a "later" phase.
2. **Phase 3 (schema + RLS) blocks 4, 5, 6.** Get the content model right; a content
   model change after 200 lessons exist is a migration nightmare.
3. **Spike S-01 (TTS) blocks Phase 9**, which blocks 10, which blocks 15.
4. **Native Peninsular reviewer hiring blocks Phase 33 review gate**, which blocks every
   content publish. Start recruiting during Phase 1, not Phase 6.
5. **Phase 15 (DELE) is blocked by external verification**, not by code.

**Parallelisable:** 2 ∥ 3; 5 ∥ 6 (different people); content authoring ∥ 7–14 once the
CMS exists; audio recording ∥ everything after 9.

---

## 57. Major risks

| ID | Risk | Sev | Likelihood | Mitigation |
|---|---|---|---|---|
| **R-01** | **Content volume is the real product cost.** ~680 lessons × (author + review + audio) is a multi-year, multi-person programme. Engineering finishes; content doesn't. | Critical | High | Vertical-slice MVP; CMS early; AI-assisted drafting with human review; ship level-by-level; treat content as the primary budget line, not a rounding error |
| **R-02** | **AI cost per learner exceeds revenue.** Unbounded tutor use at T2/T3 can cost more per month than any plausible subscription. | Critical | High | Tiering, pre-authored Why, global cache, hard quotas, cost dashboard from day one, cost per DAU as a tracked metric |
| **R-03** | **Native Peninsular + Thai reviewer capacity.** The QA gate is the throughput ceiling. | High | High | Contract reviewers in Phase 1; batch review UX; approved-pattern fast path; budget for it explicitly |
| **R-04** | **Pronunciation assessment under-delivers**; learners expect Duolingo-style scores and we can only honestly give qualitative feedback. | High | Medium | Spike S-02 early; design the UI to be *qualitatively* excellent so the absence of a score is not felt as a gap; never fake a number |
| **R-05** | **Spain-dialect drift** as providers silently update models. | High | Medium | L2 validator on every output; weekly production drift suite; prompt versions pinned as data; fallback to authored content on guard failure |
| **R-06** | **ASR fails for Thai-accented Spanish**, discouraging exactly the learners we serve. | High | High | Confidence thresholds; `inconclusive` never penalises; typed fallback everywhere; collect audio (with consent) to evaluate vendor accuracy on our actual population |
| **R-07** | **Thai typography defects** (clipped diacritics) undermine perceived quality. | Medium | High | Golden tests; line-height ≥ 1.65; device matrix; a fixed torture-string test |
| **R-08** | Scope creep — the master spec describes a 5-year product. | Critical | High | This roadmap; the MVP boundary; "no" is the default answer until §54 criteria are met |
| **R-09** | Duplicate learner profiles from multi-provider auth destroying history. | High | Medium | Verified-email account linking; explicit tests; never auto-create a profile without gating on signup metadata |
| **R-10** | **DELE spec change** invalidates exam content. | Medium | Certain (eventually) | Versioned exam specs as data; `last_verified_at` alerting; a cron diff job on the Cervantes pages |
| **R-11** | Privacy/regulatory exposure from voice + EU learners. | High | Medium | Granular consent, retention defaults, EU region, real deletion, no-training contractual terms |
| **R-12** | Solo-founder key-person risk; the owner is also running two other businesses. | High | High | Documentation-first culture; no undocumented manual DB changes; migrations in git; runbooks |
| **R-13** | Single-provider dependency (AI, TTS, ASR). | Medium | Medium | Provider abstraction at the gateway; no provider-specific features in the domain layer |

---

## 58. Missing requirements a serious production app still needs

Not in the master instruction, but genuinely required:

1. **Monetisation architecture.** There is no pricing model in the spec. This determines
   AI quota design, offline entitlements, content gating, and store setup. It must be
   decided *before* Phase 6, because "which lessons are free" is a content-model field.
2. **Customer support workflow.** Refunds, account recovery, content error reports.
   A "รายงานข้อผิดพลาดในบทเรียน" button that files into the CMS review queue is
   cheap and enormously valuable for content quality.
3. **Learner feedback loop on content.** Per-lesson thumbs + "อธิบายไม่เข้าใจ" signal,
   routed to the content team. This is how the explanation corpus actually improves.
4. **Terms of Service, Privacy Policy, and a DPA** with each AI/TTS/ASR provider.
5. **Trademark and naming clearance** — "DELE", "Instituto Cervantes", and "Cervantes"
   are protected. The app must never imply affiliation. App Store metadata is
   frequently where this goes wrong ("Official DELE prep" = rejection + legal risk).
6. **Accessibility statement** and a VPAT-style record if institutional sales ever happen.
7. **Content licensing register** — every image, audio, font, and text with its licence.
   Fonts especially (Noto/IBM Plex are OFL; verify anything else).
8. **App Store / Play compliance**: data safety forms (voice = sensitive), account
   deletion *in-app* (an Apple requirement since 2022), age rating, export compliance.
9. **Anti-abuse for the AI tutor** — jailbreak attempts, off-topic use as a free
   general chatbot (a real cost vector), and inappropriate content directed at the tutor.
10. **A curriculum editorial calendar** and a definition of who owns pedagogical
    authority when the editor and the specialist disagree.
11. **Backup and disaster recovery drill** — an actual restore test, not just PITR being
    enabled.
12. **Localisation of the interface beyond Thai** (English UI) — needed sooner than
    expected for App Store review, support, and non-Thai reviewers.
13. **Analytics-to-curriculum feedback pipeline**: which lessons cause drop-off, which
    explanations lead to failed retries. This is the mechanism for §20 (post-launch
    improvement) and needs to be designed, not improvised.

---

## 59. Decisions required before implementation

| ID | Decision | Why it blocks | Recommendation |
|---|---|---|---|
| **D-01** | Product name + branding | Store setup, design system, domain | — |
| **D-02** | Supabase paid org plan (org already at 2 projects; need 3 envs + PITR) | Blocks Phase 3 entirely | Pro plan; treat as a fixed cost |
| **D-03** | Thai politeness register in UI copy (ครับ/ค่ะ or neutral) | Every string in the product | **Neutral** — avoids mis-gendering the learner |
| **D-04** | TTS vs human voice talent for MVP core audio | Phase 9 budget & timeline | Hybrid: human for Pre-A1/A1 core + all pronunciation targets, TTS for scale |
| **D-05** | CMS stack (React/Next vs Flutter Web) | Phase 5 | React — better rich-text/table/diff ecosystem |
| **D-06** | Analytics vendor | Phase 4 | PostHog EU or self-hosted |
| **D-07** | Minimum age | Signup, privacy, store rating | 16+ given voice processing |
| **D-08** | Primary region (EU vs ap-southeast-1) | Phase 3, latency vs GDPR | EU, pending a measured latency spike from Bangkok |
| **D-09** | Monetisation model + AI budget per learner | AI quota design, content gating, §54 criterion 7 | Subscription with a tiered AI allowance |
| **D-10** | AI provider(s) + confirmation of no-training terms | Phase 10, privacy | — |
| **D-11** | Hiring/contracting the native Peninsular editor and Thai editor | The content QA gate | Start in Phase 1 |
| **D-12** | Whether v1 targets Thai learners only, or also ships an English UI | Scope, store listing | Thai-only UI for MVP; English UI before public launch |

**Spikes to run in Phase 1:** S-01 TTS vendor evaluation (es-ES quality, blind-rated) ·
S-02 pronunciation assessment feasibility (5 days, hard stop) · S-03 Bangkok→EU RPC
latency measurement · S-04 ASR accuracy on Thai-accented Spanish (record 20 real samples).

---

## 60. Recommended first vertical slice

**Do not start with the course map. Start with the single hardest, most differentiating
interaction and prove it end-to-end.**

### The slice: one lesson — *"Presentarse: Me llamo…"* (Pre-A1, Unit 1, Lesson 3)

It must demonstrate, for real, with no placeholders:

1. **Content is data.** The lesson exists only as rows in `content.*`, authored through
   the CMS, compiled into a pack, rendered by the schema-driven player. Changing the
   lesson requires zero Flutter changes.
2. **Teach → practise rhythm.** 2 content blocks → exercise → 2 blocks → exercise.
3. **Spain Spanish, provably.** The lesson contains `¿Cómo os llamáis?` alongside
   `¿Cómo te llamas?`, and the audio is a Spain voice with distinción.
4. **Audio.** Pre-generated, 2 voices, normal + slow, word-level playback on tap.
5. **Interactive sentence analysis.** Tap `Me llamo Ploy` → segments, roles, and the
   agreement/pronoun relationship visualised.
6. **The Why engine.** Tap ทำไม? on `Me llamo` → pre-authored L1 answer instantly
   (T0, zero cost, works offline) → "อธิบายละเอียด" → L2/L3 → "ถามครู AI" → a real
   gateway call with retrieval, guard, and cache.
7. **Exercise + feedback.** One typed-production item. A wrong answer produces the full
   9-part feedback structure (result → your answer → correct → what changed → why →
   rule → contrast example → retry → deep option), not "Wrong."
8. **Speaking.** Record `Me llamo…`, ASR at `es-ES`, confidence handling that visibly
   does the right thing on a deliberately mumbled attempt.
9. **Mastery + review.** The attempt writes evidence, updates `objective_mastery` with
   the correct weighting (multiple choice capped at 0.7), and schedules an FSRS review.
10. **Progress.** The skill profile visibly moves, and Home's next recommendation changes
    as a result.
11. **All four states** on every screen: loading, empty, error, offline.
12. **The full QA pipeline** ran on this lesson: schema → Spain check → pedagogy check →
    human native review → published v1 → and a rollback to v0 was demonstrated.

**Why this slice.** It exercises every architectural seam that is expensive to get wrong
— content-as-data, the pack pipeline, the block renderer, the exercise engine, the AI
gateway with caching and the guard, ASR confidence, the mastery model, the SRS, and the
publish/review workflow. If all twelve points hold for one lesson, scaling to 680 is a
content problem. If any one of them is faked, scaling to 680 is impossible.

**Definition of done for the slice:** a person who is not the developer can author a
*second* lesson in the CMS, publish it, and see it appear correctly on a phone —
without an app release and without an engineer.
