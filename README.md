# EDE — Español de España

Spanish-from-Spain learning app for Thai speakers.
Flutter (iOS/Android) + Supabase. Curriculum is data, never Dart.

Architecture: see `foundation-spec/` (delivered separately).

---

## Status — honest

| Phase | State |
|---|---|
| 0 Discovery & specification | done (60-point spec) |
| 1 System architecture | done (spec `04`) |
| 2 Flutter foundation | design system, theme, router, DI. **Not executed** |
| 3 Database | **executed and tested locally; NOT applied to any remote project** |
| First vertical slice | **written** — onboarding → Home → course map → lesson → exercise → speaking → completion → progress. **Not executed** |
| PWA (web platform) | `app/web/` scaffold added (index.html, manifest.json). **Not built or run** — see "Web / PWA" below |
| 4–20 | not started |

---

## Web / PWA — honest

The product direction (`CLAUDE.md`) is PWA-first, ahead of native. What exists:

- `app/web/index.html` and `app/web/manifest.json` — the standard Flutter web
  platform files (`flutter build web`/`flutter run -d chrome` need these to
  recognise the project as web-enabled; nothing in `pubspec.yaml` needs to
  change for that).
- Audio already goes through `just_audio` and `record`, both of which ship
  federated web implementations that Flutter wires in automatically once the
  `web/` platform exists — no extra dependency was needed. Playback and
  recording in this codebase are only ever triggered from an explicit button
  tap (`AudioControls`, the mic button in `SpeakingView`), which satisfies
  browsers' user-gesture requirement for audio/microphone access. This is
  unverified in a real browser (see below), just consistent with how the code
  is structured.

**Not done, and not faked:**
- **App icons.** `manifest.json` references `icons/Icon-192.png`,
  `Icon-512.png`, and maskable variants, plus `favicon.png` — none of these
  files are committed. This sandbox has no image-generation tool available, so
  rather than invent placeholder art, the paths are left pointing at files a
  human needs to add. `flutter build web` will still succeed without them
  (it doesn't validate manifest asset references); the PWA install prompt and
  home-screen icon will look wrong until real icons land.
- **Offline / service worker behaviour.** Flutter generates the service
  worker at build time; nothing here has been through `flutter build web`
  yet in this environment (see "Not executed" below), so caching/offline
  behaviour is unverified.
- Actual audio assets (`app/assets/audio/` is still empty) and the offline
  content-pack story (`04` §44) are unrelated, separate gaps — not attempted
  here, per the instruction not to fabricate lesson/audio content.

**Not executed:** exactly the same limitation as the rest of `app/` — the
Flutter SDK is not installed in this authoring environment and pub.dev is
unreachable, so `flutter build web` has never actually run against this
scaffold. `flutter-ci.yml` does not build for web yet either (the bot that
authored this change cannot modify files under `.github/workflows/` — add a
`flutter build web` step there by hand to close this gap, the same "red run
is signal, not a setback" policy the rest of that workflow already uses).

**Executed:** all 5 migrations apply cleanly to a fresh PostgreSQL 16 (0 errors),
and `supabase/run_tests.sh` runs **109 pgTAP assertions across 3 suites
(50 + 18 + 41), 109 passing, 0 failing, 0 plan mismatches**. Coverage:
cross-user authorization, derived-state protection, attempt idempotency,
session-based error evidence, lesson-completion idempotency and evidence
contract, speech-result forgery, the inconclusive-ASR evidence boundary, the
assessment state machine, AI tutor-message and debrief forgery, review
self-certification, the RLS matrix, and content integrity.
Re-run it yourself: `./supabase/run_tests.sh`.

**Not executed:** anything Flutter. `flutter pub get`, `flutter analyze` and
`flutter test` have never run — the SDK is not installed and pub.dev,
storage.googleapis.com, dl.google.com and github.com all return 403 from the
authoring environment. **Treat everything under `app/` as unverified**, including
the seven test files: they are written, not passing.

What *was* checked statically, for what little it is worth: bracket balance
across all 36 Dart files, every local import resolving to a real file, every
`EdeType`/`EdeSpace`/`EdeTokens`/component symbol existing, every block type in
the seed having a registered renderer, and every exercise slug referenced by a
block resolving to a published exercise row (the last one found a real bug — the
live adapter looked up `payload->>slug` and the seed never stored one).

### First thing to run

Order matters: `app_database.dart` declares `part 'app_database.g.dart'`, and
that file is **not committed**. Until build_runner generates it, every import of
the database fails and the analyzer output is meaningless.

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # writes app_database.g.dart
flutter analyze
flutter test
```

Expect analyzer findings. Nothing in `app/` has been compiled even once.

---

## Why the database has not been applied

The Supabase org (`aaptooxubcispkjjlsjo`) already holds two projects, both
Japan Hayai. Applying these migrations would either need a **new project**
(blocked on decision D-02: the free-plan project ceiling) or would target an
existing production business database, which must not happen. Learner voice
recordings and freight-forwarding data do not belong in one database.

So: migrations are written and reviewable; applying them is a deliberate,
separate act you authorise.

---

## Run it

### 1. App, in local mode (no backend needed)

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run          # no --dart-define => DataSource.local
```

With no `SUPABASE_URL` defined the app runs entirely against the embedded
content pack and an on-device SQLite file. The whole learner journey works
offline; grading uses the dev mirror in `domain/answer_matcher.dart`.

### 2. Fonts (optional, but do this before judging the typography)

The font block in `pubspec.yaml` is **commented out on purpose**: declaring an
asset path that does not exist makes `flutter run` fail on a clean checkout, and
these families cannot be committed from the authoring environment. The theme
sets `fontFamilyFallback`, so the app runs and Thai renders on the platform
default until you add them.

All three are OFL-licensed. Download and place the `.ttf` files in
`app/assets/fonts/`:

- **Source Serif 4** — Regular, SemiBold → the Spanish target text
- **IBM Plex Sans Thai** — Regular, Medium, SemiBold → Thai explanations
- **IBM Plex Sans** — Regular, Medium, SemiBold → UI and grammar labels

Then uncomment the `fonts:` block in `pubspec.yaml` and re-run
`flutter pub get`. Filenames must match exactly.

The Spanish-serif / Thai-sans hierarchy is a deliberate design decision, so the
app looks noticeably flatter without these.

### 3. Database (only needed for Supabase mode)

```bash
supabase init
supabase start                 # local Postgres
supabase db reset              # applies all 5 migrations in order
```

Then create the storage buckets (private ones matter):

```sql
insert into storage.buckets (id, name, public) values
  ('content-audio','content-audio',true),
  ('content-media','content-media',true),
  ('content-packs','content-packs',true),
  ('learner-audio','learner-audio',false),   -- private. never public.
  ('admin-drafts','admin-drafts',false);
```

### 4. App, in Supabase mode

```bash
cd app
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Only the anon key ever ships in the client. In this mode the server grades every
answer and owns every measurement; the dev mirror is not used.

---

## Design direction

**Azulejo** — the cobalt-and-white glazed tilework of Spain. Chosen against two
obvious alternatives: flag red/yellow is a cliché, and terracotta-on-cream is
the current default look of generated interfaces and would read as templated.

Boldness is spent in one place: `AzulejoTile`, a drawn quatrefoil whose petals
fill with unit progress, used for unit markers and the CEFR journey. Everything
around it stays quiet.

Typography does structural work rather than decorating:

| Role | Face | Why |
|---|---|---|
| Spanish target | Source Serif 4, 21–30sp | The script itself marks "this is the language" |
| Thai meaning | IBM Plex Sans Thai, 14–16sp, **line-height 1.70** | Secondary; 1.70 because Thai stacks a vowel and a tone mark above one consonant and clips at Latin leading |
| Grammar label | IBM Plex Sans, 11.5sp, tracked | Tertiary metadata |

Plex Thai and Plex Sans are one superfamily, so Thai and UI Latin stay
coherent; the serif sits deliberately outside it.

`barro` (warm brown) is the *retry* colour. A wrong answer in a lesson is
normal and must not read as a system failure — true red is reserved for
actual errors.

---

## Invariants that must never be relaxed

These are enforced in SQL, not documentation, because documentation does not
stop a rushed migration:

1. **`content.audio_assets.locale` is CHECK-pinned to `es-ES`.** A Latin
   American voice cannot be stored, not merely discouraged.
2. **Mastery is written only by `learning.record_evidence()`.** Recognition
   evidence is capped at 0.70; mastery additionally requires ≥1 productive and
   ≥1 delayed-retention success. One multiple-choice win can never mean mastery.
3. **Attempts are append-only.** No UPDATE or DELETE policy exists on
   `assess.exercise_attempts` for any client role.
4. **`is_correct` is server-computed.** The client sends an answer, not a verdict.
5. **`speech_attempts.verdict = 'inconclusive'`** contributes no negative
   evidence. A learner is never marked wrong because ASR failed.
6. **An error pattern needs ≥3 occurrences across ≥2 sessions** before it is
   called a pattern — enforced by a CHECK constraint.
7. **`variety_intent`** scopes every Spain-guard rule, so `computadora` is an
   error in a lesson and legitimate in a contrast note. Never a blind blacklist.
8. **DELE specs are versioned rows with a source URL and a verification date.**
   Published groupings differ between levels and the A1/A2 formats were renewed;
   sources disagree. Exam rules never become constants in Dart.
9. **Derived measurement tables are SELECT-only to every client role.**
   `objective_mastery`, `grammar_mastery`, `skill_estimates`, `learner_stats`,
   `learner_error_patterns`, `review_queue`, `study_sessions`,
   `exercise_attempts` have no INSERT/UPDATE/DELETE grant at all, plus a
   BEFORE INSERT OR UPDATE OR DELETE trigger as defence-in-depth.
10. **No client-callable SECURITY DEFINER function accepts a learner identity.**
    Identity comes from `auth.uid()`. Functions that need an explicit learner
    uuid are `*_internal` and revoked from every client role. Asserted by D6.3.
11. **An error pattern needs >=3 occurrences across >=2 sessions**, where a
    session is a server-created `study_sessions` row *and* real elapsed time has
    passed. Looping `start_session` cannot inflate the count.
12. **Lesson completion is idempotent and evidence-gated.** `complete_lesson()`
    locks the progress row, awards only on the transition into `completed`, and
    refuses any lesson whose authored `completion_rules` are empty. Ten calls
    award once; two concurrent calls serialise.
13. **Speech is two tables.** `speech_submissions` holds client facts only and
    is written solely by `submit_speech()` (which validates session, exercise
    and audio-path prefix). `speech_evaluations` holds every derived field and
    has no client grant. A learner cannot author a verdict.
14. **The inconclusive-ASR rule is enforced by control flow**, not semantics:
    `record_speech_evaluation_internal()` returns before any evidence call when
    `verdict='inconclusive'`, and a CHECK makes an inconclusive row carrying
    findings unrepresentable.
15. **Assessments move only through RPCs** (`start` / `submit` / `abandon`, with
    `score_assessment_internal` revoked). No client UPDATE grant, so `kind`,
    `level`, `state`, `result`, `started_at` and `submitted_at` cannot be forged.
16. **A learner may only author their own conversation turn** — `role='learner'`,
    no `error_codes`, no `audio_path`. Tutor turns and debriefs are server-only.
17. **Self-reported review grades drive scheduling, never proficiency.**
    `grade_review()` no longer accepts a productive claim; `productive_p` and
    the `mastered` state require server-graded production evidence.

## Pronunciation standard (sg-0.2)

The course teaches **distincion** (`casa` /ˈkasa/ vs `caza` /ˈkaθa/) and
**yeismo** (⟨ll⟩ and ⟨y⟩ both /ʝ/). The asymmetry is deliberate and documented
in the seed migration: distincion is alive and standard across most of Spain,
while the ⟨ll⟩–⟨y⟩ contrast has merged for the large majority of speakers.
Teaching /ʎ/ would give a Thai learner a production target most of the people
they meet do not use, and would contradict our own reference audio.

IPA is stored as two separate columns — `ipa_phonemic` (/…/, variety-level) and
`ipa_phonetic` ([…], realisation-level) — plus `audio_assets.ipa_realization`
for what a specific recording actually does. One transcription cannot honestly
represent every Spanish speaker.

---

## The vertical slice

One lesson, end to end: welcome → goal → experience → daily goal →
self-reference → Home → course map → Unit 1 → *Me llamo…* → audio controls →
word/morphology sheet → ทำไม? → exercise → correction → retry → speaking →
completion → progress → next recommendation.

**The player is schema-driven.** `features/lesson/block_renderers.dart` is a
`Map<String, BlockBuilder>`; the player walks `lesson.blocks` and looks each
type up. It contains no reference to "Me llamo" or to any specific lesson, so a
second lesson is a data change and a new block type is one widget plus one map
entry. Nine block types render: `example`, `pronunciation_guide`, `vocabulary`,
`comparison`, `dialogue`, `exercise_embed`, `speaking_prompt`, `review`, plus
`explanation`/`text`/`heading`/`tip`/`warning`. Unknown types degrade to a
"update the app to see this" card rather than crashing the lesson.

**ทำไม? resolves cheapest-first.** `why_l1_th` ships inside the lesson: instant,
free, offline, no model. Then approved `grammar_concepts` L2, then L3. The tutor
is last, and when it is the stub it says so on screen.

### Honest about what is not real

| Thing | State |
|---|---|
| Pronunciation scoring | **Not implemented.** The UI records and says evaluation is unavailable. There is no percentage anywhere in the speaking screen, and a test asserts that. |
| AI tutor | `LocalTutorStub`, labelled on screen. It only re-serves approved curriculum text and refuses questions it has no approved answer for. |
| Audio playback | Assets are pre-generated at publish time; the bucket is empty, so the button says so instead of failing silently. |
| Backend | Local in-memory adapters behind the same interfaces. Progress does not survive app restart, and Home says so. |
| Placement test | Not built. Onboarding routes everyone to Pre-A1 and tells "เคยเรียนมาบ้าง" learners that plainly. |

## Next

Everything below the line "written" is **written but never compiled**. The next
step is not more code — it is the first real toolchain run.

### Run Flutter CI (no local Flutter needed)

`.github/workflows/flutter-ci.yml` runs exactly the sequence below on GitHub's
runners, so the slice can be verified without installing anything:

`flutter --version` -> `flutter pub get` -> `dart run build_runner build
--delete-conflicting-outputs` -> `flutter analyze` -> `flutter test`

Codegen is a hard prerequisite: if `app_database.g.dart` is not produced the job
stops there, because the analyzer would otherwise emit hundreds of
consequential errors with no diagnostic value. The run needs **no secrets** —
`DATA_SOURCE` defaults to local, so it exercises the embedded content pack and
an in-memory database.

To trigger it: push the repo to GitHub, then open **Actions -> Flutter CI ->
Run workflow**. Download the `flutter-ci-diagnostics` artifact if it fails.

Flutter is pinned to 3.32.0 stable. `pubspec.yaml` now declares the floor
explicitly as `flutter: ">=3.29.0"` alongside `sdk: ">=3.7.0 <4.0.0"`, because
`theme.dart` uses `CardThemeData` — a Flutter API requirement the Dart
constraint alone cannot express.

### Or verify on a machine with Flutter


```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # writes app_database.g.dart
flutter analyze
flutter test
```

`analyze` and `test` will almost certainly report findings, and that output is
the most valuable thing this project can produce right now. The two files most
likely to be wrong are `lib/data/local/app_database.dart` and
`lib/data/local/content_pack.dart`: both were reconstructed from their call
sites rather than written against a compiler.

If both pass, `flutter run` with no `--dart-define` boots local mode and the
journey is Welcome → goal → "ไม่เคยเรียน" → daily goal → self-reference → Home
→ Pre-A1 map → *Me llamo…* → ทำไม? → exercise → speaking → completion.

### Written, pending that verification

- Drift schema, on-device SQLite, and the sync outbox (`synced` flag +
  `unsyncedAttempts` / `unsyncedSpeech` drain queries)
- Schema-driven block renderer over 9 block types
- ทำไม? bottom sheet, resolving the block's authored `why_l1_th` from the pack
  with no model call, then concept L2/L3, then an explicitly-labelled stub
- Exercise engine with the nine-part feedback contract, retry, and
  frame-based proper-name grading
- Recording flow with no invented pronunciation score
- Server-verified lesson completion and the progress update

### Genuinely not built yet

1. **`content-publish` Edge Function** — the pack compiler. Today the pack is a
   Dart constant; production compiles it from `content.*` to versioned CDN JSON.
   Tables stay the write model, packs the read model.
2. **Admin CMS.** This is the real bottleneck on curriculum scale, not the app.
3. **Audio pipeline** — es-ES TTS at publish time, plus spike S-01 (voice
   quality) and S-02 (whether honest pronunciation assessment is feasible).
4. **Applying the migrations anywhere.** Still blocked on decision D-02: the
   Supabase org is at its project ceiling, and these tables must not share a
   database with the freight business.

Definition of done for the slice: someone who is not a developer authors a
second lesson in the CMS, publishes it, and sees it on a phone — with no app
release and no engineer. Items 1 and 2 above are what stand between here and
that sentence.
