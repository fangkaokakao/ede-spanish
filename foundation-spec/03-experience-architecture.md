# 03 — Experience, Content Operations & QA Architecture

Covers spec items **27–34**.

---

## 27. Product information architecture

```
ROOT
├── Home                  ← default landing; answers "what now?"
│   ├── Today's plan
│   ├── Continue lesson
│   ├── Review due
│   └── Weak-point action
├── Learn                 ← the curriculum spine
│   ├── CEFR journey → Course → Module → Unit → Lesson
│   └── Lesson player (content blocks + exercises)
├── Practice              ← skill-targeted, curriculum-independent
│   ├── Vocabulary review (SRS)
│   ├── Listening
│   ├── Speaking & pronunciation
│   ├── Reading
│   ├── Writing
│   └── Scenarios (roleplay)
├── Tutor                 ← conversation + ask-anything
├── Progress
│   ├── Skill profile
│   ├── CEFR journey
│   ├── Weak areas
│   └── Achievements
└── Profile
    ├── Goals & daily target
    ├── Learner preferences (self-reference, depth, Thai support)
    ├── Downloads & offline
    ├── Notifications
    ├── Privacy & data
    └── Account

CONTEXTUAL (not in main nav):
    Onboarding · Placement · Search · Bookmarks · Word sheet · Why sheet ·
    Deep grammar page · Feedback screens · DELE hub (appears in Practice + Home
    only when the learner's goal includes an exam)
```

**Key IA decisions.**
- 5 tabs, not 6. `Exam` is *not* a permanent tab — most learners are not exam-driven,
  and a permanently visible DELE tab makes the product feel like a cram school.
  It appears as a Practice section and a Home card once the goal is set.
- `Learn` (structured path) and `Practice` (free choice) are separated deliberately:
  the app must be able to answer "just tell me what to do" **and** "I have 6 minutes and
  want to work on listening."
- Search and the Word sheet are *global overlays*, reachable from any Spanish text.

---

## 28. Complete screen inventory

Grouped by flow; each will get the §30 nine-point design brief before implementation.

**Onboarding & entry (11):** Splash · Welcome/value · Goal selection (`อยู่ที่สเปน /
เที่ยว / คู่รักคนสเปน / ทำงาน / สอบ DELE / ความสนใจ`) · Prior experience · Daily goal ·
Self-reference preference (optional, skippable) · Notification permission (deferred,
asked *after* first lesson, not before) · Account create/sign-in · Placement intro ·
Placement test player · Placement result.

**Home & planning (4):** Home · Today's plan detail · Streak/goal sheet ·
Notification preferences.

**Learn (7):** CEFR journey map · Course map · Unit detail · Lesson player ·
Lesson complete/summary · Mastery check · Level assessment.

**Content blocks rendered inside the lesson player (14 renderers, not screens):**
text · heading · explanation · example (tappable) · comparison · tip · warning ·
grammar breakdown · interactive sentence · image · audio · dialogue · pronunciation
guide · timeline · table · exercise embed.

**Grammar & explanation (5):** Why bottom sheet · Deep grammar page (card stack) ·
Interactive sentence analysis · Morphology explorer · Grammar concept index.

**Vocabulary (5):** Word sheet (overlay) · Vocabulary detail · Vocabulary review (SRS) ·
Saved words · Collocation practice.

**Practice & skills (9):** Practice hub · Listening player · Reading player ·
Writing composer · Writing feedback · Pronunciation recorder · Pronunciation result ·
Speaking task · Scenario roleplay.

**Tutor (4):** Tutor home · Conversation (chat) · Conversation debrief · Ask-a-question.

**Exercise & feedback (3):** Exercise renderer (schema-driven, one screen, ~28 item
types) · Answer feedback · Session summary.

**Progress (6):** Progress dashboard · Skill detail · Weak areas · CEFR journey ·
Achievements · Study history.

**DELE (8):** DELE hub · Target selection · Understand-the-exam · Task-type training ·
Section practice · Timed mock (with exam chrome) · Mock result · Readiness report.

**Profile & system (10):** Profile · Preferences · Downloads/offline manager ·
Privacy controls (export, delete) · Account · Subscription (future) · Help ·
Search · Bookmarks · About/legal.

**Admin CMS (separate web app, 16):** Dashboard · Course tree editor · Unit/Lesson
editor (block composer) · Grammar concept editor (16-question form + 4 depths) ·
Vocabulary editor · Exercise authoring · Audio manager · Scenario editor ·
Exam spec editor · AI prompt & version manager · Content review queue ·
Spain-QA report · Publication manager · Preview-as-learner · Audit log · User admin.

**Total: ~86 learner-facing screens + 16 admin.** This is a large product; the MVP
(`05` §54) implements 31 of them.

---

## 29. Navigation

- **Bottom tab bar, 5 items**, always visible except in: lesson player, exercise,
  recording, timed mock, and onboarding — where it is hidden to protect focus.
- **Lesson player** is a full-screen flow with a progress bar, a close (×) that saves
  state and confirms, and no bottom nav.
- **Why / Word / Hint** always open as **bottom sheets over the current screen**.
  Rule: *explanation never causes navigation*. Losing your place to read an explanation
  is the single most common way learning apps break flow.
- **Timed mock** enters a modal "exam mode" — no tabs, no tutor, no dictionary,
  explicit exit warning. Assessment integrity requires it.
- Back behaviour: Android hardware back mirrors the visible close affordance; mid-exercise
  back = confirm-discard, never silent loss.
- Deep links: `ede://lesson/{id}`, `ede://concept/{slug}`, `ede://review`,
  `ede://scenario/{id}` — required for notifications to be useful.

---

## 30. UX principles

**P1 — Every screen answers five questions:** where am I, what am I learning, what do I
do now, why does it matter, what's next. If a screen cannot answer all five, it is not
finished.

**P2 — One primary action.** Exactly one filled, full-width, brand-coloured button per
screen. Everything else is a text button, icon+label, or secondary outline. A screen with
five equally weighted buttons has no primary action.

**P3 — Teach a little → practise → explain → practise → use.** Never more than ~2
content blocks before an interaction. If a lesson has 5 explanation screens in a row,
it is authored wrong, and the CMS should warn the author.

**P4 — Progressive disclosure by default.** L1 explanation shows; ทำไม? reveals L2;
"อธิบายละเอียด" reveals L3; "มุมมองภาษาศาสตร์" reveals L4. A beginner must never be
shown "non-assertive subordinate clause" unasked.

**P5 — Ability over points.** Achievements are phrased as capabilities.

**P6 — Never punish.** Wrong answers use amber, not red-screen. Copy is
*"ลองอีกครั้ง"* + what changed + why + retry. ASR failure never counts as a learner error.

**P7 — The learner's work is never lost.** Any error state that follows a submission
must say so explicitly (*"คำตอบของคุณยังไม่หาย"*).

**P8 — Mobile one-handed.** Primary actions in the bottom third. Minimum tap target
48×48 dp. Nothing critical within 16 dp of a screen edge.

**P9 — Typography carries hierarchy, colour never carries meaning alone.**

**P10 — Silence is a feature.** No confetti for a correct answer. Celebrations are
reserved for: first conversation, unit complete, 100 words mastered, level milestone,
7/30-day streaks.

### 30.1 Design tokens (initial)

| Token | Value | Rationale |
|---|---|---|
| `color.primary` | deep warm terracotta/ochre family (e.g. `#C2542F`) | Spain-evocative without the flag cliché; distinct from Duolingo green and every blue ed-tech app |
| `color.accent` | muted teal | for progress/info, high contrast against primary |
| `color.success` / `warning` / `error` / `info` | green / amber / rose (not fire-engine red) / blue | error tone deliberately softened |
| `color.surface` | warm off-white `#FAF8F5` / dark `#141210` | warm neutral, not clinical grey |
| `radius` | 16 card / 12 control / 999 pill | |
| `space` | 4-8-12-16-24-32-48 | |
| `elevation` | 0/1/2 only | no heavy shadows |
| `motion` | 150 ms micro / 250 ms sheet / respects `reduceMotion` | |

**Typography — the hardest constraint in this product.**

| Role | Font | Notes |
|---|---|---|
| Spanish target text | a humanist sans with complete Latin-Ext + IPA-adjacent coverage (**Inter** or **Source Sans 3**) | 24–32 sp, tightest hierarchy weight; must render `¿ ¡ ñ ü á é í ó ú` perfectly |
| Thai explanation | **Noto Sans Thai** or **IBM Plex Sans Thai** | 16–18 sp, **line-height ≥ 1.65** — Thai upper/lower diacritics (ไม้โท + สระอิ stacks) clip at tight leading; this is the #1 Thai typography bug |
| Grammar labels | same Latin family, small caps / 12 sp, tertiary colour | |
| IPA | a font with real IPA coverage (**Charis SIL** / **Doulos SIL**) | Noto Sans lacks some IPA glyphs; do not assume |

**Never** use a single font family for both scripts and assume it works. Thai and Latin
must be metric-compatible in size *perception*, which usually means Thai renders 1–2 sp
larger than the Latin at the same nominal size. A visual QA test with the string
*"ปั๊ปสั่งไม้โทซ้ำ"* + *"¿Vosotros habláis español?"* on one line is a required check.

Dark mode: all semantic colours re-tuned, not inverted. Illustrations must have dark
variants or transparent-background line art.

---

## 31. Accessibility architecture

- **Screen readers:** every interactive element labelled in the *interface* language
  (Thai). Spanish text spans get `lang="es-ES"` semantics so TalkBack/VoiceOver switch
  voice — reading Spanish with a Thai TTS voice is unusable. Flutter: `Semantics(
  attributedLabel:...)` + locale-aware `TextSpan` with `locale:`.
- **Dynamic type:** support up to 200%. All learning layouts must reflow, never clip.
  Fixed-height cards are banned in lesson content.
- **Contrast:** ≥ 4.5:1 body, ≥ 3:1 large text and non-text indicators, in both themes.
- **Never colour alone:** correct/incorrect always carry an icon + text label.
- **Audio alternatives:** every audio asset has a transcript. Listening exercises can be
  completed with transcript-after-attempt; a *deaf-accessible mode* switches listening
  objectives to reading equivalents and reports the substitution honestly in Progress.
- **Speaking alternatives:** every speaking task has a typed-response fallback for users
  who cannot or will not speak (also needed on the bus). Mastery records which modality
  produced the evidence.
- **Motion:** honour `MediaQuery.disableAnimations`.
- **Tap targets:** ≥ 48×48 dp, ≥ 8 dp apart.
- **Timers:** all timed practice (except deliberate DELE mocks) can be extended or
  disabled.
- **Keyboard:** full traversal implemented from day one for the CMS, and for the app
  where it costs nothing — cheap insurance for the future web build.

---

## 32. CMS architecture

**[DECIDED] The CMS is a separate web application** (React/Next or Flutter Web —
**[NEEDS DECISION D-05]**, recommend React for ecosystem: rich text, diffing, tables),
authenticating against the same Supabase project with an `admin`/`editor`/`reviewer` role.
It is not shipped inside the learner app.

**Capabilities**

- **Course tree editor** — drag-order Course → Module → Unit → Lesson.
- **Lesson block composer** — add/reorder validated content blocks; live mobile preview.
- **Grammar concept editor** — the 16 questions as discrete fields, the 4 explanation
  depths, prerequisites (graph picker with cycle detection), Thai contrast note, common
  errors (taxonomy picker), visual model selection.
- **Vocabulary editor** — lemma → senses → examples → collocations; false-friend flag;
  Spain-preference link.
- **Exercise authoring** — pick template, fill schema, define answer rules
  (incl. accepted-variants and accent-tolerance policy per item).
- **Audio manager** — request TTS generation per item/voice/speed, listen, approve,
  reject with reason, replace with human recording.
- **AI-assisted drafting** — an author can generate a draft lesson/example set. Output
  lands as `draft` and **cannot skip review**. The prompt and model version used are
  recorded on the row.
- **Exam spec editor** — §25.2 fields with mandatory `source_reference_url` and
  `last_verified_at`.
- **Preview as learner** — render as Pre-A1 / A1 / B1 / C1; toggle Thai support level;
  male/female voice; masculine/feminine self-reference; large text; dark mode;
  screen-reader label dump.
- **Publication manager** — build a content pack, diff against the live version, show
  what learners will see change, publish or roll back.

**Hard rule:** the CMS stores *validated block schemas*, never executable UI
instructions, arbitrary HTML, or scripts. A malicious or careless CMS row must not be
able to do anything except render known block types with known fields.

---

## 33. Content QA workflow

```
draft ──▶ ai_validation ──▶ spain_language_check ──▶ pedagogical_check
   ▲                                                        │
   │                                                        ▼
rejected ◀──────────────── human_review ◀──── factual_grammar_validation
                                 │
                                 ▼
                            approved ──▶ published(vN) ──▶ retired
```

| Gate | Who/what | Blocking? | Output |
|---|---|---|---|
| `ai_validation` | schema validity, required fields, block rules, level-appropriateness heuristics, forbidden-oversimplification strings | **yes** | machine report |
| `spain_language_check` | §34 validator (L2) | **yes** | flags with severity |
| `pedagogical_check` | objective↔exercise coverage, prerequisite satisfaction, teach→practise ratio, register tagging completeness | **yes** | machine report |
| `factual_grammar_validation` | LLM judge against retrieved authoritative reference + citation requirement | warn | judged report |
| `human_review` | native Peninsular reviewer **and** Thai-language reviewer | **yes for all published curriculum** | approve/reject + notes |

**Nothing AI-generated reaches a learner without human approval.** Full audit history:
who, when, which version, which model, which prompt version, which style-guide version.
Rollback is a first-class operation, not a database restore.

Reviewer capacity is the true content bottleneck (`05` §57, R-03) — the workflow must
support batch review and a "same-pattern approved" fast path, or content will never ship.

---

## 34. Spain-Spanish automated QA

### 34.1 The validator's four checks

**C1 — Lexical.** Match against the versioned preference table. Severity depends on the
item's `variety_intent` (see `01` §3.6). `computadora` in an `es-ES-target` item = error;
in a `contrast-note` item = allowed with mandatory label; missing label = error.

**C2 — Morphological/paradigmatic.**
- Any `vos` + voseo verb form → **hard fail** outside recognition-tagged content.
- Conjugation tables with < 6 persons → **hard fail**.
- `ustedes` + informal-plural addressee markers (`chicos`, `tíos`, `amigos`, `vosotros`
  absent, informal register tag) → **flag for review**.
- Missing `os` / `vuestro` where the paradigm demands them → flag.

**C3 — Contextual (LLM judge, rubric-scored 0–3).** "Would an educated speaker in Madrid
say this naturally in this register?" plus "does the recent-past usage match Spain's
`he + participio` norm?" Scores ≤ 1 block publication.

**C4 — Audio.** Spot-check generated audio for seseo where distinción is required, and
for LatAm voice models mistakenly selected. Metadata check: every audio asset must carry
`locale=es-ES` and an approved `voice_id`.

### 34.2 The evaluation dataset (regression suite, runs in CI)

A curated prompt set with *expected properties*, evaluated on meaning and register —
never exact-string matching. Seed set (~120 prompts, ≥ 10 per category):

| Prompt (to the tutor) | Expected property | Fail condition |
|---|---|---|
| "Ask two friends if they want coffee." | uses `¿Queréis…?` | defaults to `¿Quieren…?` |
| "How do I say 'I bought a car'?" | `coche` | `carro` |
| "Order orange juice." | `zumo de naranja` | `jugo` |
| "Explain how to pronounce *cerveza*." | describes `/θ/`, distinción | teaches seseo as standard |
| "Tell your friends to come here." | `venid` | `vengan` |
| "I've eaten already, today." | `Ya he comido` | defaults to `Ya comí` |
| "Roleplay: café in Madrid." | Spain register markers, `vale`/`¿qué te pongo?` | LatAm markers |
| "Write a formal email to a Spanish landlord." | `usted`, Spain formulae (`Le saluda atentamente`) | LatAm formulae |
| "What's a computer?" | `ordenador` | `computadora` |
| "Take the bus." | `coger el autobús` used naturally | avoids `coger` |
| "How do I say 'apartment'?" | `piso` primary | `departamento` |
| "Park the car." | `aparcar` | `estacionar`/`parquear` |

Each run reports a **Spain-fidelity score**. A drop below threshold blocks the AI prompt
version from promotion to production. This suite runs on every prompt change, every
model change, and nightly against production tutor samples.

### 34.3 Anti-requirement

The validator must **not** blindly blacklist. False positives that strip legitimate
contrast notes, cooking senses of `jugo`, or Spain-internal variation would degrade the
product. Every rule carries a `severity` and a `variety_intent` scope, and every
suppression is logged so the rule set can be tuned from real data.
