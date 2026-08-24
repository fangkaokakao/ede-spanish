# 02 — Learning Architecture

Covers spec items **5–26**.

---

## 5. CEFR / MCER learning architecture

### 5.1 Structural principle

CEFR levels are **not containers of lessons**. They are *claim thresholds*. A learner is
"A2" when there is evidence they can do the A2 can-do statements — not when they have
opened the A2 folder. Therefore the model is:

```
CEFR_LEVEL ──(defines)──▶ CAN_DO_DESCRIPTOR ──(operationalised as)──▶ LEARNING_OBJECTIVE
                                                          │
LESSON ──(teaches)──▶ LEARNING_OBJECTIVE ◀──(evidences)── EXERCISE / TASK / PRODUCTION
                                                          │
                                             OBJECTIVE_MASTERY (per learner, probabilistic)
                                                          │
                                             LEVEL_COMPLETION (thresholded, multi-skill)
```

Every level definition record specifies, per skill: communicative outcomes, grammar
inventory, vocabulary domains, pronunciation outcomes, sociolinguistic and pragmatic
competence, mediation (B1+), assessment requirements, prerequisites, and mastery
thresholds. These are **data rows**, not code.

### 5.2 Level completion gate (see also §20)

A level is claimed only when **all** hold:
- ≥ 90% of the level's *core* learning objectives at mastery p ≥ 0.85
- ≥ 70% of *extension* objectives at p ≥ 0.70
- No skill dimension below `level_floor` (e.g. Speaking ≥ 60% of level target)
- Level assessment passed in both a receptive and a productive group
- Retention: ≥ 80% correct on delayed review items drawn from ≥ 21 days earlier
- ≥ 1 free-production sample (speaking + writing) rated at level by AI + rubric

Missing one → the app does **not** block the learner. It says
*"คุณเกือบถึง A2 แล้ว — เหลือแค่การพูด"* and routes remediation. Gatekeeping demotivates;
honest reporting does not.

### 5.3 Internal estimate vs. official certification

Three distinct, never-conflated concepts, each with its own UI treatment (§24, `03` §30):

| Concept | Label | Claim strength |
|---|---|---|
| Course progress | "จบ A2 ในแอป" | We taught it, you completed it |
| Internal proficiency estimate | "ประเมินภายใน: A2 (ค่าความเชื่อมั่นปานกลาง)" | Our measurement, with CI |
| DELE / official CEFR | "ประกาศนียบัตร DELE" | **Not ours. Instituto Cervantes only.** |

Certificates issued by the app must literally read *"internal course completion — this is
not an official DELE or CEFR certification."* in Thai and Spanish.

---

## 6. Curriculum map — Pre-A1 to C2

Sizing target below is *indicative* (units × ~6–9 lessons; a lesson = 6–12 min).
Grammar inventories align to the PCIC and must be **[NEEDS VERIFICATION]** cross-checked
against the current *Plan curricular del Instituto Cervantes* inventories at authoring time.

### Pre-A1 — "เสียงและคำแรก" (≈4 units, 30 lessons)
**Outcome:** greet, give name/origin, count 0–20, read Spanish aloud accurately, survive
5 fixed exchanges.
**Grammar:** `ser` (soy/eres/es) as fixed chunks; `me llamo`; `tú/usted` awareness;
noun gender *introduced as a property to notice*, not yet a rule; `el/la`; number.
**Pronunciation (this is the real Pre-A1 payload):** the 5 pure vowels (Thai speakers
must unlearn diphthongised/tonal vowels); `c/z → /θ/`; `j/g+e,i → /x/`; `ñ`;
`r` tap vs `rr` trill (introduced, not mastered); written stress; syllable timing.
**Vocabulary:** ~150 items. Greetings, numbers, countries, classroom.
**Thai-contrastive focus:** "Spanish has no tones — pitch carries emotion, not meaning."

### A1 — "ชีวิตประจำวันเริ่มต้น" (≈10 units, 80 lessons)
**Grammar:** full present indicative regular `-ar/-er/-ir` **including vosotros**;
`ser/estar/hay` first contrast; definite/indefinite/zero article; `al`/`del`;
gender & number agreement of adjectives; possessives; demonstratives; `gustar`-type
(me/te/le + singular/plural); `tener/ir/hacer/poder/querer/venir/decir` irregulars;
`ir a + infinitivo`; `estar + gerundio`; `hay que`/`tener que`; interrogatives;
negation; basic reflexives (`levantarse, ducharse`); `muy/mucho`; time & date.
**Communicative:** introduce self, family, order in a café, buy, ask directions, tell time,
describe routine, make simple plans.
**Vocabulary:** ~800 cumulative. **Scenarios:** S-01…S-12 (§26).

### A2 — "จัดการชีวิตในสเปนได้" (≈12 units, 100 lessons)
**Grammar:** `pretérito perfecto compuesto` (**Spain-priority**) vs `pretérito indefinido`;
`imperfecto` and the pretérito/imperfecto contrast (narrative); direct + indirect object
pronouns, then combination (`se lo`); `imperativo afirmativo` (incl. `hablad`) and
`negativo` (first subjunctive forms, taught as imperative, not labelled subjunctive);
comparatives/superlatives; `por/para` first pass; `futuro simple` and `ir a`;
reflexive/pronominal expansion; `se` impersonal; `estar/ser` deepened; `desde/hace`;
`ya/todavía`; frequency & sequencing connectors.
**Vocabulary:** ~1,800 cumulative. **Scenarios:** S-13…S-30 including *médico*,
*farmacia*, *piso*, *banco*.

### B1 — "แสดงความเห็นและเล่าเรื่อง" (≈14 units, 120 lessons)
**Grammar:** present subjunctive — introduced through *function* (deseo, influencia,
emoción, valoración, duda), not "the difficult mood"; `condicional simple`;
`pluscuamperfecto`; relative clauses (`que, quien, donde, el que`) and the
indicative/subjunctive split in relatives (`busco a alguien que hable...`);
`si` type-1; reported speech (present anchor); `por/para` deepened;
`pronominal se` typology; `estilo indirecto`; discourse connectors; `soler`,
`acabar de`, `volver a`, `ponerse a`, `dejar de`.
**Vocabulary:** ~3,500. **New:** mediation tasks begin; leísmo introduced as
accepted-Spain; regional Spain listening introduced (tagged).

### B2 — "ถกเถียงและใช้ชีวิตจริง" (≈14 units, 130 lessons)
**Grammar:** `imperfecto de subjuntivo`; `si` types 2 & 3; `pluscuamperfecto de
subjuntivo`; `futuro perfecto`/`condicional compuesto`; concessives
(`aunque` + ind./subj.); full passive vs `se` passive vs impersonal; `voz media`;
verbal periphrasis system; nominalisation; advanced connectors; register shifting;
`ojalá`, `como si`, `por si`.
**Vocabulary:** ~6,000. Professional and academic domains enter.

### C1 — "ความละเอียดและงานอาชีพ" (≈12 units, 120 lessons)
**Grammar:** subjunctive in all subordinate types incl. temporal/final/modal;
tense-mood harmony (`consecutio temporum`); information structure, dislocation,
clefting (`fue entonces cuando…`); `lo` + adjective; aspectual nuance; discourse
markers by genre; irony, litotes, hedging; administrative and legal register;
literary past (`pretérito anterior`) for recognition.
**Vocabulary:** ~9,000 + collocation depth over breadth.

### C2 — "ความแม่นยำระดับเจ้าของภาษา" (≈10 units, 100 lessons)
**Focus shifts from new grammar to precision, idiom, pragmatics, and mediation.**
Phraseology, refranes (used, not listed), sociolinguistic variation across Spain,
genre mastery, subtle mood alternations, humour, implicature, editing others' Spanish.

**Total indicative:** ~680 lessons. This is a multi-year content programme —
which is precisely why §54's MVP is a vertical slice, not a curriculum dump.

---

## 7. Skill architecture

Six primary skills + four cross-cutting competences, each independently estimated:

| Dimension | Type | Primary evidence |
|---|---|---|
| Listening | Skill | listening items, dictation, conversation comprehension |
| Reading | Skill | comprehension incl. inference items |
| Speaking (production) | Skill | read-aloud, prompted response, monologue |
| Spoken interaction | Skill | scenario turns, tutor conversation |
| Writing | Skill | rubric-scored submissions |
| Pronunciation | Skill | ASR + assessment attempts, per-phoneme |
| Grammar control | Competence | exercise attempts tagged by concept |
| Lexical range | Competence | SRS state + productive usage in free output |
| Sociolinguistic (register) | Competence | register-selection items, tutor rubric |
| Pragmatic / discourse | Competence | B1+ rubric dimensions |

Each stored as `skill_estimates(learner, dimension, theta, se, updated_at)` — a point
estimate **and** a standard error. The UI never shows a bare number without the
uncertainty being representable (§24).

---

## 8. Deep grammar architecture (`DEEP_GRAMMAR_LANGUAGE_EXPLANATION_ENGINE`)

### 8.1 The concept graph

`grammar_concepts` is a DAG, not a list. Each node:

```
grammar_concept
  id, slug ("noun_gender", "ser_vs_estar_states", "pres_subj_influence")
  cefr_introduced, cefr_mastered
  short_name_th, short_name_es
  answers[16]            -- the 16 mandatory questions, structured
  explanation_levels[4]  -- L1 simple / L2 mechanism / L3 deep / L4 linguistic
  thai_contrast_note
  common_errors[]        -- FK to error_taxonomy
  spain_usage_note
  dele_relevance[]
  prerequisites[]        -- edges
  visual_model_type      -- agreement_arrows | timeline | pronoun_swap | morphology | none
```

**The 16 questions** from the master instruction are stored as discrete fields, not
prose. This matters: it makes them individually retrievable by the AI tutor, individually
reviewable, and individually renderable in the deep grammar page's card stack.

### 8.2 Four explanation levels — authored, not improvised

| Level | Length | Audience | Metalanguage |
|---|---|---|---|
| L1 Simple | ≤ 2 Thai sentences | default for A-levels | none |
| L2 Understand | ≤ 120 Thai words | on ทำไม? tap | minimal, glossed |
| L3 Deep | ≤ 400 words + examples + exceptions | on "อธิบายละเอียด" | full but glossed |
| L4 Linguistic | unbounded | opt-in / C-levels | free |

L1–L3 are **human-approved authored content**. L4 may be AI-generated *at request time*
from approved L3 + concept data, clearly marked as generated, and cached. Depth shown
by default = f(learner level, learner's explicit depth preference), never L4 automatically.

### 8.3 Prerequisite gap detection

When a learner fails objective `O` twice within a window, walk `O`'s concept
prerequisites and check mastery. If an ancestor is below threshold, the failure is
attributed upward: *"ปัญหาไม่ใช่ที่คำคุณศัพท์ — คือเรื่องเพศของคำนาม"* and a
remediation micro-lesson for the ancestor is inserted into the daily plan.
This is the single highest-value differentiator in the product. It requires the DAG to
be genuinely authored, not auto-derived.

### 8.4 Non-negotiable content rules (validator-enforced)

Hard-fail strings in any authored explanation: *"-o = ผู้ชาย, -a = ผู้หญิง"*,
*"ser = ถาวร, estar = ชั่วคราว"*, *"subjuntivo = ไม่แน่ใจ"*, *"ลำดับคำในภาษาสเปนอิสระ"*.
No invented etymology: an etymology field is optional and requires a `source_ref`.

### 8.5 Morphology explorer

Every inflected form in content is stored with a segmentation:
`hablábamos → [habl:ROOT][ába:IMPF][mos:1PL]`, each segment carrying a level-appropriate
Thai gloss (`-mos` → beginner: "พวกเรา"; advanced: "1st person plural desinence").
Segmentation is generated at publish time by a morphological analyser and
**human-spot-checked**, not computed on device.

---

## 9. Pronunciation architecture

### 9.1 Phoneme inventory & Thai-contrastive difficulty map

Every `pronunciation_target` carries: IPA, orthographic triggers, articulatory
description (tongue/lips/airflow/voicing), Thai contrast, typical Thai-speaker error,
minimal pairs, corrective drill, CEFR introduction point.

Priority order for Thai learners (evidence-driven, revisable):

| Rank | Target | Typical Thai error | Drill |
|---|---|---|---|
| 1 | `/r/` tap vs `/r̄/` trill | both → Thai ร or /l/ | *pero/perro, caro/carro* |
| 2 | Final `/s/`, `/r/`, `/l/`, `/d/` | dropped or glottalised (Thai coda rules) | *hablas, comer, español, ciudad* |
| 3 | Consonant clusters `tr/pr/bl/gr` | vowel epenthesis (*ta-res*) | *tres, problema, blanco* |
| 4 | `/θ/` (distinción) | → /s/ or /t/ | *casa/caza, cocer/coser* |
| 5 | Vowels — 5 pure, no reduction | tone/length carryover, diphthongisation | *mesa, mismo* |
| 6 | Stress + tilde | flat/tonal reading | *hablo/habló, papa/papá* |
| 7 | Approximant `b d g` between vowels | full stops | *abogado, cada* |
| 8 | `/x/` (j, ge/gi) | → /h/ (acceptable-ish) or /kʰ/ | *jamón, gente* |
| 9 | Linking / resyllabification | word-by-word delivery | *los_amigos, el_hombre* |
| 10 | Intonation contours | Thai tonal interference on questions | *¿Vienes? / Vienes.* |

### 9.2 Pronunciation is taught, not merely played

Each target has a teaching unit: articulation diagram (mouth/tongue SVG), a
"what your Thai mouth does vs what Spanish needs" note, slow model, normal model,
minimal-pair discrimination (listening) *before* production, then production.
**Discrimination before production** — a learner who cannot hear `/θ/` cannot produce it,
and scoring their production first is cruel and uninformative.

### 9.3 Audio production standard

- **Pre-generated at publish time**, never at runtime, for all curriculum audio.
  Rationale: cost, determinism, QA, offline, and consistency of voice.
- Minimum 4 Spain voices (2 M / 2 F) for the core; ≥ 8 by B1 so learners do not overfit.
- Variants per item: `normal`, `slow` (~0.75×, **re-synthesised or re-recorded, not
  time-stretched** — time-stretching destroys the trill and the tap), plus word- and
  syllable-level clips for pronunciation targets.
- Human native review of a sample of every generated batch; hard review of all
  minimal-pair and pronunciation-target audio.
- **[NEEDS DECISION D-04]** TTS vendor vs. recorded voice talent for the MVP core.
  Recommendation: TTS for scale + **recorded human voice for Pre-A1/A1 core phrases and
  all pronunciation targets**, because that is where audio quality most affects learning
  and where errors are most damaging.

### 9.4 Scoring honesty

See `04` §42. Scores are always accompanied by a *named issue* ("RR ยังสั่นไม่ชัด"),
never a bare percentage, and never presented as precise when confidence is low.

---

## 10. Vocabulary architecture

### 10.1 Entry model — lemma / sense / usage, three levels

Not one flat table. `vocabulary_entries` (lemma, POS, gender, plural, IPA, frequency band,
audio) → `vocabulary_senses` (Spain meaning, Thai gloss, register, CEFR, domain, notes,
false-friend flag) → `vocabulary_examples` + `collocations` per sense.

Why: `coger` has ~8 senses with radically different registers and one catastrophic
LatAm false-friend risk; `banco` is bench/bank; a single "meaning" column makes the
false-friend and register systems impossible.

### 10.2 Words are never taught alone

The minimum learnable unit is **lemma + sense + one collocation + one context sentence
+ audio**. Collocations are first-class rows (`hacer una pregunta`, `tener hambre`,
`dar un paseo`, `tomar una decisión`, `echar de menos`) and enter the SRS as their own
items, because Thai speakers systematically calque Thai verb+noun pairings.

### 10.3 Active vs passive tracking

Two independent mastery values per sense: `receptive_p` (recognised in reading/listening)
and `productive_p` (produced correctly unprompted in writing/speaking). Productive
evidence only comes from free production or typed-production exercises — never from
multiple choice. The Progress screen shows both, because "I know 2,000 words" is usually
a receptive claim.

---

## 11. Listening architecture

Progression ladder with a `listening_difficulty` vector per asset:
`speech_rate (syl/s) · connectedness · noise · speaker_count · accent_distance ·
lexical_density · redundancy · visual_support`.

Stages: isolated words → phrases → slow learner-directed → clear standard sentences →
short dialogues → natural-speed dialogue → announcements (Renfe/Metro/airport) →
telephone audio → interviews → news-style → professional/multi-speaker → reduced and
elided connected speech (*"pa' que" , "na'", "to'"*).

**Rules:** transcript is *never* auto-revealed before an attempt. Replay is unlimited and
free of penalty. Speed control at 0.75× / 1× (and 1.25× at B2+, because DELE audio feels
fast). Every listening item declares which sub-skill it tests: gist / specific info /
inference / attitude. From B1, tagged regional-Spain audio (andaluz, canario, gallego,
catalán-influenced) appears in comprehension only, clearly labelled.

---

## 12. Speaking architecture

Five task types on an increasing-freedom ladder:

1. **Repeat** (pronunciation target) — model → record → compare.
2. **Read aloud** — text known, tests phonetics + prosody.
3. **Prompted single response** — "สั่งกาแฟ 1 แก้ว" → open production, narrow scope.
4. **Scenario turn** — multi-turn roleplay with an AI interlocutor in role (§26).
5. **Monologue / DELE-style task** — timed, prepared, rubric-scored.

Learner sees a large mic, a prompt, and nothing else during recording. **No live
scoring while speaking** — it destroys fluency. Feedback appears after, in the order:
what worked → one or two priority fixes → retry → continue.

---

## 13. Reading architecture

Text types by level: signs/menus/labels (A1) → messages, schedules, short emails (A2) →
articles, blogs, narratives (B1) → opinion, argumentation, official notices, contracts,
*empadronamiento*/`Seguridad Social` forms (B2) → academic, literary extract, legal,
journalistic register analysis (C1–C2).

Question types must escalate beyond lookup: locate → paraphrase → infer → identify
attitude/intent → identify text purpose/genre → mediate (summarise for a third party in
Thai or Spanish, B1+). Every text is tagged with lexical coverage vs. the learner's known
vocabulary so we can select texts at ~95% known-word coverage (the empirically
comfortable reading threshold).

**Copyright:** all reading texts are original or public-domain. Literary extracts require
a rights check and a `source_ref`. No textbook or exam paper reproduction.

---

## 14. Writing architecture

Task ladder: word → sentence → WhatsApp message → informal email → description →
narrative → opinion → complaint (formal) → application/cover letter → professional email →
argued essay → mediation/report.

**Feedback contract.** The engine returns a structured object, never prose blobs:

```json
{
  "original": "...",
  "annotations": [
    {"span":[12,18], "type":"gender_agreement", "concept":"noun_gender",
     "learner":"La coche", "suggested":"El coche",
     "severity":"error", "explanation_th":"...", "spain_note":null}
  ],
  "corrected_version": "...",
  "natural_alternative": "...",
  "rubric": {"task_completion":4,"coherence":3,"grammar":3,"lexis":3,"register":4},
  "kept_voice": true,
  "confidence": 0.82
}
```

`type` is drawn from the shared **error taxonomy** (§21) so writing errors feed the same
learner error memory as exercise errors. `natural_alternative` is separate from
`corrected_version` so we fix errors without erasing the learner's voice — an explicit
requirement.

---

## 15. Conversation architecture

**Modes:** (a) *Scenario* — fixed role, goal, and success criteria; (b) *Free chat* —
topic-open at the learner's level; (c) *Lesson dialogue* — scripted with slots.

**Level adaptation** is enforced by injecting a level contract into the tutor call:
max sentence length, permitted tense set, permitted lexis band, speech rate for TTS,
and whether Thai scaffolding is permitted mid-turn.

**Correction policy.** During the exchange: intervene only if communication breaks
(the tutor genuinely cannot parse the intent) or the lesson is in *drill mode*. Errors are
silently collected. After the exchange, the debrief returns: what went well → grammar →
vocabulary → pronunciation → fluency → naturalness → Spain-appropriateness →
suggested phrases → next practice. Prioritised by *recurrence × communicative impact*,
capped at 3 items — a wall of 14 corrections after a first conversation ends the habit.

---

## 16. AI Tutor architecture (`AI_SPAIN_SPANISH_TUTOR`) — pedagogical contract

Technical gateway in `04` §41. Pedagogically, the tutor is defined by a **contract
object** assembled server-side per request:

```
tutor_context = {
  learner: {cefr_estimate, skill_profile_summary, weak_concepts[≤5],
            self_reference_pref, depth_pref, thai_support_level},
  situation: {mode, lesson_id, objective_id, current_sentence, target_concept},
  retrieved: {grammar_concept L1-L3, vocabulary senses, spain_usage_notes},
  policy: {spain_guard@vN, correction_policy, register_target, level_contract},
  history: {last_n_turns, collected_errors_this_session}
}
```

**The tutor is not the curriculum database.** For any grammar question, approved
`grammar_concepts` content is retrieved first and the model's job is to *explain the
retrieved knowledge in Thai at the right depth for this learner in this context*. If
retrieval returns nothing relevant and the question is normative, the tutor says it is
not sure and offers to route to the deep grammar page or flag for a human —
it does not invent a rule. This is enforced by prompt + a post-hoc "unsupported
normative claim" check on sampled outputs.

---

## 17. "Why?" (ทำไม?) explanation architecture

The most important interaction in the product. Design constraints: never navigates away
(bottom sheet), answers *this* sentence, answers in ≤ 3 seconds, and is mostly free.

**Resolution order:**

1. **Deterministic path (target ≥ 70% of taps, 0 cost, instant, offline-capable).**
   The content author has pre-linked this token/sentence to a concept and a
   *context-specific* L1 answer. `La casa bonita` → tap `bonita` → the pre-authored
   agreement explanation ships inside the lesson pack.
2. **Cache path.** Key = `hash(concept_id, level, depth, sentence_id, locale,
   self_ref_pref)`. Previously generated answers for the same context are reused
   globally across learners — the same 5,000 sentences generate the same questions.
3. **Generate path.** Only for genuinely novel context (free conversation, learner's own
   writing). Cheap model tier, retrieved concept data, cached on return.

**Escalation UI:** short answer → `ดูตัวอย่างเพิ่ม` · `เปรียบเทียบกับ SER` ·
`ดูแบบละเอียด` · `ถามครู AI`. Each step is a deeper tier, and only the last is
guaranteed to cost a model call.

---

## 18. Thai-speaker pedagogy architecture

A `thai_contrast_notes` table joined to concepts and pronunciation targets. Core entries:

| Spanish feature | Thai reality | Teaching strategy |
|---|---|---|
| Grammatical gender | absent | Teach as an **arbitrary agreement system**, like a classifier system with 2 classes. Use ลักษณนาม (classifiers) as the bridge: Thai speakers already accept arbitrary noun classes. Never "male/female". |
| Articles | absent | Teach *function* (known vs new, specific vs generic) before form; contrast with Thai's zero-marking |
| Verb conjugation | absent | Frame endings as "the verb already tells you who" — an *economy*, not a burden |
| Subject omission | **present in Thai** | Leverage: "คุณทำแบบนี้ในภาษาไทยอยู่แล้ว" |
| Tense morphology | aspect particles (แล้ว/กำลัง/เคย) | Map: กำลัง→estar+gerundio; แล้ว→perfecto/indefinido nuance; เคย→imperfecto habitual / `he + participio` experiential |
| Pretérito vs imperfecto | no morphological equivalent | Teach by *viewpoint* + timeline visuals; never by keyword lists |
| Plural agreement | optional/absent | High-frequency silent error; drill agreement chains |
| Object pronouns | different ordering | Visual transformation animation |
| Subjunctive | no equivalent | Teach via *function*: อยากให้ / หวังว่า / กลัวว่า — Thai marks these with complementisers; anchor there |
| Prepositions | different carving | Never 1:1; teach in collocation |
| Syllable timing / coda | restricted codas, tonal | Explicit phonetics, §9 |

**Do not assume uniformity.** These are *priors*, not labels. Every note is a hypothesis
that the learner's own error data confirms or overrides (§21).

**Translation policy.** Every example may carry three lines: literal gloss (only when
instructive), natural Thai meaning, and — where they diverge — a note on the conceptual
difference. Never a single bare translation implying equivalence.

---

## 19. Placement assessment architecture

**Route A — "ไม่เคยเรียนเลย"** → straight to Pre-A1 Lesson 1. Zero friction. No test.

**Route B — "เคยเรียนมาก่อน"** → adaptive placement, 12–18 min:

- Item bank calibrated with a 1-PL/Rasch difficulty parameter per item, seeded by
  author-assigned CEFR and recalibrated from live data.
- Stages: (1) receptive adaptive core — grammar + vocabulary + short reading, ~20 items,
  ability estimate updated after each; (2) one listening block at the estimated level ±1;
  (3) one short writing task; (4) one 45-second speaking task.
- Stop rule: SE(θ) < 0.35 **or** 25 items **or** 3 consecutive failures below the
  current estimate.
- Output: `estimated_level` + **skill profile** (a learner is rarely flat: typical Thai
  self-taught profile is Reading B1 / Speaking A1) + **confidence** + recommended
  entry unit + list of concepts to backfill.

**Honesty rule:** the result screen says *"นี่คือการประเมินภายในของแอป ไม่ใช่ผลสอบ CEFR
อย่างเป็นทางการ"*. Placement never places a learner above a level where they lack the
prerequisite concepts, even if their θ is high — a high-θ learner with no `vosotros`
gets a targeted backfill queue, not a demotion.

---

## 20. Mastery architecture

**Model:** per learning objective, a Bayesian Knowledge Tracing-style posterior
`p(mastered)` with evidence weighting:

| Evidence type | Weight | Notes |
|---|---|---|
| Multiple choice correct | 0.4 | recognition only; can never alone exceed p=0.7 |
| Typed production correct | 1.0 | |
| Transformation / error-correction | 1.0 | |
| Free writing usage (correct, unprompted) | 1.5 | |
| Speaking usage in conversation | 1.5 | |
| Delayed review (≥ 14 days) correct | 2.0 | retention is the real signal |
| Any of the above incorrect | negative, scaled by recency | |

`p` decays with time-since-last-evidence (concept-specific half-life). **Mastery requires
at least one productive evidence type and one delayed-retention success.** A single
multiple-choice success is capped and can never trigger mastery — an explicit requirement.

`objective_mastery(learner_id, objective_id, p, evidence_count, last_evidence_at,
first_mastered_at, decayed_p)`.

---

## 21. Personalisation architecture

**Error taxonomy** — a hierarchical code system shared by exercises, writing, speech and
tutor debriefs:

```
GRAM.GEN.ART        article gender mismatch
GRAM.GEN.ADJ        adjective agreement
GRAM.NUM.PLURAL     plural agreement
GRAM.SER_ESTAR.*    .state .identity .location .result
GRAM.PAST.PERF_IND  perfecto vs indefinido (Spain-specific!)
GRAM.PAST.IND_IMP   indefinido vs imperfecto
GRAM.SUBJ.SELECT    mood selection
GRAM.PRON.DO_IO     object pronoun choice/placement
GRAM.PREP.POR_PARA
LEX.FALSE_FRIEND
LEX.LATAM_DEFAULT   used LatAm default form
PRON.RR / PRON.THETA / PRON.CODA_S / PRON.CLUSTER / PRON.STRESS
REG.FORMALITY       register mismatch
```

`learner_error_patterns(learner_id, code, count, weighted_recent_count, first_seen,
last_seen, status)`. Status moves `observed → recurring → targeted → improving → resolved`
and requires **≥ 3 occurrences across ≥ 2 sessions** before it is called a pattern —
one mistake never labels a learner.

**Personalisation levers:** review volume, exercise difficulty band, lesson
recommendation, explanation depth default, scenario topic, speaking challenge level,
remediation insertion.

**Guardrail:** personalisation may *reorder and reweight*, never *skip* a core objective.
A learner who is brilliant at vocabulary does not get to skip `vosotros`.

---

## 22. Daily learning architecture

Goal options: 5 / 10 / 15 / 20 / 30 / 45 min, custom. The planner is **deterministic
(no AI cost)** and runs client-side from cached state so the Home screen renders offline
and instantly.

Allocation algorithm (per session, budget `B` minutes):

```
1. Overdue SRS reviews          → min(0.30·B, actual_due)   [never skipped]
2. Prerequisite remediation     → 0.20·B if any gap flagged  [pre-empts new content]
3. New lesson / continue        → remaining, ≥ 0.30·B
4. Weakest-skill practice       → 0.15·B (speaking gets priority if it is the floor)
5. Spaced re-encounter          → fill
```

Rendered as an achievable checklist (`03` §30). If the learner has 5 minutes, they get
reviews and one micro-lesson, not a truncated full lesson.

---

## 23. SRS architecture

**[DECIDED] Use FSRS** (Free Spaced Repetition Scheduler, open algorithm) rather than
SM-2. Rationale: SM-2 is 1987-era and systematically over-schedules; FSRS models
difficulty/stability/retrievability separately, is open-source, has reference
implementations, and its parameters can be *optimised per learner* from their own
review log — which we will have.

States: `new → learning → review(weak|developing|familiar|strong) → mastered`, with
`lapsed` re-entry. Items are not only vocabulary: **grammar concepts, collocations, and
pronunciation targets are all SRS items** with their own type-specific review exercise
generators.

Critical rule: SRS review of a *productive* item must sometimes demand production
(typed or spoken), not recognition — otherwise SRS inflates receptive-only knowledge.
Target ratio ≥ 40% productive reviews from A2.

---

## 24. Progress architecture

The dashboard is a **skill profile with uncertainty**, not a level bar.

Displayed: current course position · internal CEFR estimate *with confidence band* ·
the 10 dimensions of §7 as bars · study time · lessons · review consistency ·
2 strengths · 2 weak areas with a one-tap action · recent measurable improvements
("การออกเสียง RR ดีขึ้น 40% ใน 2 สัปดาห์") · CEFR journey · exam readiness (if DELE mode on).

**Framing rule (product-critical):** achievements are stated as *abilities*, not points.
"ตอนนี้คุณสั่งอาหารในร้านสเปนได้แล้ว" beats "+250 XP" every time. XP may exist; it may
never be the largest text on the screen and never determines level.

---

## 25. DELE architecture

### 25.1 Verified facts (checked 2026-08-24 — **[NEEDS VERIFICATION]** before implementation)

- Six general adult levels: **A1, A2, B1, B2, C1, C2**, plus school exams for ages 11–17
  (A1, A2/B1, and a **new B2/C1 escolar first administered May 2026**).
- Diplomas granted by Instituto Cervantes on behalf of Spain's education ministry;
  **exams designed and corrected by the Universidad de Salamanca**.
- Result is **APTO / NO APTO**. Tests are organised into **two groups**, and a
  candidate must obtain *apto in both groups in the same session*; the commonly cited
  scale is 30/50 per group.
- Four tests per level: comprensión de lectura, comprensión auditiva, expresión e
  interacción escritas, expresión e interacción orales.
- Diplomas are valid indefinitely. 2026 had multiple *convocatorias* (Feb, Apr, May,
  Jul, Sep, Oct, Nov), not all levels at every date.
- **The A1 and A2 formats were renewed** (task counts and durations changed, new rating
  scales). Published structures differ between levels — e.g. A2 (2020 version) groups
  reading+writing vs listening+speaking, while other sources describe B1 grouping
  reading+listening vs writing+speaking.

**This last point is the architectural finding.** Sources disagree; formats change; the
grouping is not uniform across levels. **Exam structure must therefore be
version-controlled data with a `source_reference` and `last_verified_at`, fetched from
`examenes.cervantes.es` guías per level, and never written into Flutter or into prose
lesson text.** Anything else guarantees the app will one day teach a format that no
longer exists.

### 25.2 Data model

```
exam_providers(id, name)                              -- "Instituto Cervantes"
exam_specs(id, provider_id, exam_name, level, specification_version,
           effective_from, effective_to, source_reference_url, last_verified_at,
           verified_by, total_duration, grouping_rules jsonb, scoring_rules jsonb,
           content_version, status)
exam_tasks(id, spec_id, prueba, task_number, task_type, item_count, duration_min,
           input_format, response_format, rating_scale_ref, descriptors jsonb)
exam_practice_items(id, task_id, ... )                -- our ORIGINAL content
```

A `last_verified_at` older than 180 days raises an **admin alert** and shows a soft
"ข้อมูลรูปแบบข้อสอบอาจมีการเปลี่ยนแปลง — ตรวจสอบกับ Instituto Cervantes" banner.

### 25.3 Modes

Understand the exam · Section practice · Task-type training · Skill drills ·
Timed practice · Mini mock · Full mock · Speaking simulation · Writing simulation ·
Strategy · Mistake review · Readiness report.

### 25.4 Readiness reporting — honesty rules

Report per *prueba* and per *group* (because the pass rule is per group). Show
"ตอนนี้คุณอยู่ในช่วงที่มักจะผ่าน / ยังไม่แน่นอน / ยังไม่พร้อม" with an explicit
confidence statement. **Forbidden strings:** "คุณจะสอบผ่านแน่นอน", any guaranteed-pass
claim, any implication of affiliation with Instituto Cervantes.

### 25.5 Content legality

All practice material is **original**, written to match published *task types and
descriptors*. Official papers may be studied to understand format; they are never
reproduced, and no official audio, text, or item is ingested into the content database.

---

## 26. Real-life Spain scenario map

Each scenario scales across levels via the same `scenario_id` with level-specific goals,
permitted language, and success criteria.

| ID | Scenario | First level | Registers exercised |
|---|---|---|---|
| S-01 | Saludos y presentaciones | Pre-A1 | informal/formal |
| S-02 | Pedir en la cafetería | Pre-A1 | neutral |
| S-03 | Números, precios, pagar | A1 | neutral |
| S-04 | Restaurante: menú del día, la cuenta | A1 | neutral/informal |
| S-05 | Supermercado / mercado | A1 | neutral |
| S-06 | Pedir y entender direcciones | A1 | neutral |
| S-07 | Metro / autobús / billetes | A1 | neutral |
| S-08 | Renfe: comprar y cambiar un billete | A2 | neutral/formal |
| S-09 | Taxi / VTC | A1 | neutral |
| S-10 | Aeropuerto y facturación | A2 | formal |
| S-11 | Hotel: reserva, incidencia | A2 | formal |
| S-12 | Conocer gente, quedar con amigos | A1→B2 | informal/colloquial |
| S-13 | Tienda de ropa: tallas, probador | A2 | neutral |
| S-14 | Devolver un producto / reclamar | A2→B1 | neutral→formal |
| S-15 | Farmacia: síntomas, medicamentos | A2 | neutral/formal |
| S-16 | Centro de salud: cita y consulta | A2→B1 | formal |
| S-17 | Urgencias / emergencia (112) | A2 | urgent/formal |
| S-18 | Alquilar piso: visita, contrato, fianza | B1 | formal |
| S-19 | Hablar con el casero / averías | B1 | neutral→assertive |
| S-20 | Banco: abrir cuenta, problemas | B1 | formal |
| S-21 | Empadronamiento / cita previa / administración | B1→B2 | administrative |
| S-22 | Extranjería / NIE / TIE | B2 | administrative |
| S-23 | Comisaría: denuncia, objetos perdidos | B1 | formal |
| S-24 | Universidad: matrícula, tutoría | B1→B2 | academic |
| S-25 | Entrevista de trabajo | B2 | professional |
| S-26 | Oficina: reunión, correo, presentación | B2→C1 | professional |
| S-27 | Atención al cliente / reclamación formal | B2 | formal |
| S-28 | Teléfono (sin apoyo visual) | B1→C1 | all |
| S-29 | Vecinos y comunidad de propietarios | B1 | neutral/assertive |
| S-30 | Cita, ligar, relaciones | B1 | informal/colloquial |
| S-31 | Familia política y celebraciones | B1 | informal |
| S-32 | Debate y opinión con amigos | B2→C1 | informal/argumentative |
| S-33 | Correo formal y solicitud escrita | B1→C1 | formal/administrative |
| S-34 | Autónomo / gestoría / impuestos | C1 | administrative |

Cultural competence lessons attach to scenarios rather than existing as standalone
"culture facts": meal times attach to S-04, *cita previa* culture to S-21,
*dos besos* and personal space to S-01, tipping norms to S-04, regional identity to S-32.
Every cultural claim carries a `source_ref` and avoids stereotyping — written as
*"lo habitual es…"*, never *"los españoles son…"*.
