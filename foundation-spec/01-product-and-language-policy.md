# 01 — Product & Language Policy

Covers spec items **1–4**.

---

## 1. Product vision

> A Thai speaker with zero Spanish opens this app and, within four minutes, says a
> real Spanish sentence out loud and understands *why it is built that way*.
> Two years later they sit the DELE B2 in Madrid and pass — and, more importantly,
> they can rent a flat, argue with a landlord, and be funny at a dinner table in Spain.

**The product thesis.** Existing apps optimise for *session completion*. Thai-speaking
learners of Spanish are underserved twice over: almost all Spanish courseware explains
via English or Latin American Spanish, and almost none explains the specific structural
collisions between Thai and Spanish (no grammatical gender, no verb inflection, no
articles, no tense morphology, different syllable timing, no consonant clusters,
no trill). The moat is not the app shell — it is the **Thai-contrastive explanation
corpus + the Spain-Spanish guarantee**.

**What we sell.** Not lessons. *Explained understanding, verified production, and
honest measurement.* Concretely, three defensible assets:

1. **The Deep Explanation Corpus** — every grammar concept authored at four depths in
   Thai, with Thai-contrastive notes and native-Spain examples, human-reviewed.
2. **The Spain-Spanish Guarantee** — an enforced, testable, auditable pipeline
   (`SPAIN_SPANISH_LANGUAGE_GUARD`) that no general-purpose chatbot offers.
3. **The Learner Model** — multidimensional, evidence-based mastery, not XP.

**Non-goals for v1.** Multi-language teaching. Social/leaderboard features. Live human
tutors. Web app. Latin American Spanish. Children's product.

**Success in one sentence.** A learner can point at a screen and say
*"นี่คือสิ่งที่ฉันยังอ่อน และนี่คือสิ่งที่ฉันควรทำต่อ"* — and be right.

---

## 2. Target learner definition

### 2.1 Primary persona — "Ploy", 29, Bangkok → Madrid

Thai native. Office worker, English at B1-ish, has a Spanish partner or a Spain job/study
plan within 18 months. Studies 15–25 min/day on a phone, on the BTS, in Thai.
Has tried Duolingo and quit at the point where Spanish stopped being vocabulary and
started being *conjugation*. **Her actual blocker is not motivation — it is that nobody
ever explained gender, articles, or verb endings in a way that made sense from Thai.**
Needs: DELE B1/B2 eventually, real conversation now, and to not feel stupid.

### 2.2 Secondary persona — "Nan", 41, already in Spain

Lives in Spain (Valencia), married, needs to deal with the *centro de salud*, her
landlord, her child's school, and eventually *nacionalidad*. Speaks survival Spanish
learned by ear, riddled with fossilised errors. Needs: correction without humiliation,
formal/administrative register, listening to fast native speech, DELE A2 for
nationality (paired with CCSE — out of scope, but must be *named* correctly).

### 2.3 Tertiary persona — "Beam", 22, student

Thai university student, Spanish minor or self-study, exam-driven, higher tolerance for
grammar depth and metalanguage, wants C1. Will use Level-4 linguistic explanations.

### 2.4 Anti-persona (explicitly not designed for)

- Learners wanting Latin American Spanish. We say so plainly at onboarding.
- Under-13 users. Age-gate at signup; the product is designed for adults.
- Learners wanting a 60-second-a-day streak toy.

### 2.5 Jobs To Be Done

| # | Job | Success signal |
|---|---|---|
| JTBD-1 | "When I meet a Spanish speaker, help me not freeze." | Completes a 6-turn scenario unaided |
| JTBD-2 | "When grammar confuses me, explain it in Thai until it clicks." | Uses ทำไม? then answers the retry correctly |
| JTBD-3 | "When I speak, tell me honestly if I sound wrong." | Records, retries, measurable pronunciation delta |
| JTBD-4 | "Tell me what to study today so I stop deciding." | Opens app → taps primary action within 10s |
| JTBD-5 | "Show me I'm actually getting better." | Returns to Progress weekly, self-reports accuracy |
| JTBD-6 | "Get me through DELE without lying to me about my odds." | Mock score correlates with real outcome |
| JTBD-7 | "Help me survive a real Spanish situation next Tuesday." | Uses scenario search before a real event |

### 2.6 Thai-learner starting assumptions (drive pedagogy — see `02` §18)

- Thai has **no** grammatical gender, articles, verb conjugation, tense morphology,
  plural marking, or subject-verb agreement. Every one of these is *new machinery*,
  not a variation on something known.
- Thai **is** tonal and syllable-timed with a fairly restricted syllable coda; Spanish
  stress, consonant clusters (`tr`, `pr`, `bl`), final `-s`/`-r`/`-l`, and the
  tap/trill contrast are the predictable phonetic battlegrounds.
- Thai **does** have aspect particles (แล้ว, กำลัง, เคย) — these are genuine
  bridges to preterite/imperfect/present-progressive, and we should use them.
- Thai speakers routinely drop subjects — **this is an advantage** for Spanish
  pro-drop, and should be taught as "you already do this".

---

## 3. Spain Spanish language policy (`SPAIN_SPANISH_LANGUAGE_GUARD`)

### 3.1 Policy statement

The productive target variety is **contemporary educated standard Peninsular Spanish**,
locale `es-ES`. This is a permanent product constraint, changeable only by explicit
written instruction from the owner. It binds all generated and authored content:
curriculum, AI tutor turns, exercises, examples, audio, corrections, roleplays,
assessments, notifications, and CMS-assisted generation.

### 3.2 The guard is three enforcement layers, not a prompt

A prompt alone is not a guarantee. The guard is implemented as:

| Layer | Mechanism | Runs |
|---|---|---|
| **L1 — Generation** | System prompt fragment `spain_guard@vN` injected into *every* AI call, plus few-shot Spain exemplars | Every AI request |
| **L2 — Deterministic validator** | Rule engine over the output: lexicon, morphology, pronoun paradigms. Tag-aware (see 3.6) | Every AI output + every content publish |
| **L3 — Judged / human review** | LLM rubric judge on sampled output; mandatory human native review before publish | Publish gate + nightly sample of tutor output |

L1 alone ships nothing to a learner. **No AI-generated learning content reaches a
learner without passing L2 and, for published curriculum, L3.**

### 3.3 Lexical policy (non-exhaustive; lives in versioned `lexicon_policy` table)

| Prefer (es-ES) | Not as default | Note |
|---|---|---|
| ordenador | computadora | LatAm form allowed only in tagged recognition notes |
| móvil | celular | |
| coche | carro | `carro` in Spain ≈ cart — teach the false-friend risk |
| zumo | jugo | `jugo` exists in Spain (cooking sense) — validator must not blanket-ban |
| piso | departamento/apartamento | `apartamento` is not wrong in Spain; `piso` is the default |
| conducir | manejar | |
| coger | agarrar/tomar | **Teach `coger` normally.** Flag only if a lesson *avoids* it for LatAm reasons |
| aparcar | estacionar/parquear | |
| patata | papa | |
| ordenar/recoger | acomodar | |
| vale / venga / qué guay / genial / me apetece / quedar / dar una vuelta | — | Register-tagged, level-gated |

Register-gating: `vale`, `genial`, `de acuerdo`, `no pasa nada` from A1.
`venga`, `me apetece`, `quedar`, `dar una vuelta` from A2. `qué guay`, `flipar`,
`currar`, `tío/tía` from B1 and always tagged `colloquial`. No slang before A2.

### 3.4 Grammatical policy

- **`vosotros/vosotras` is a first-class paradigm.** It appears in every conjugation
  table, every drill, every audio set, from the first present-tense lesson. `os`,
  `vuestro/-a/-os/-as`, and the imperative (`hablad, comed, venid, decid, haced, id`)
  are taught, not footnoted.
- `ustedes` is taught as **formal plural**, and the Spain/LatAm distribution difference
  is explained explicitly (in Spain: `ustedes` = formal only; in most of LatAm:
  `ustedes` = all plural). This is a *comprehension* asset, not a hedge.
- **Perfecto compuesto.** Spain's use of `he comido` for today/this-week/recent-relevant
  events (`Hoy he desayunado tarde`) is the default taught for recent past — this is one
  of the largest real Spain-vs-LatAm divergences and is frequently taught wrongly by
  international courseware. Preterite for bounded, detached past.
- **Distinción** (`/s/` vs `/θ/`) is the pronunciation standard — see `02` §9.
- **Leísmo:** exam-safe standard (`lo/la` for DO, `le` for IO) is taught first and is
  the drill target. From B1, *leísmo de persona masculina* (`le vi` for a man) is
  introduced as **accepted in Spain and admitted by the RAE**, tagged `accepted-Spain`.
  Laísmo and loísmo are tagged `non-recommended`, taught for recognition only from B2.
- **No voseo** in production. If it ever appears, it carries the mandatory label
  *"Regional variation outside Spain — recognition only"* and is excluded from drills.

### 3.5 Register taxonomy (every content item carries exactly one)

`formal_high` · `formal` · `neutral` · `informal` · `colloquial` · `slang` · `professional` · `administrative`

### 3.6 The validator must be tag-aware, not a blacklist

A blacklist is wrong and will corrupt content. `computadora` is *correct* inside a
lesson explicitly comparing varieties. The validator receives the content item's
metadata and applies:

```
if item.variety_intent == "es-ES-target"      → LatAm-default lexeme = ERROR
if item.variety_intent == "contrast-note"     → LatAm lexeme = ALLOWED, must carry label
if item.variety_intent == "recognition-only"  → LatAm lexeme = ALLOWED, excluded from drills
```

Additionally, the validator raises **structural** flags that a wordlist cannot catch:

- `ustedes` used with a plainly informal plural addressee (friends, `tíos`, `chicos`)
  and no `vosotros` anywhere in the item → **flag**
- Any `vos + -ás/-és/-ís` verb form → **hard fail** unless tagged recognition-only
- A present-tense conjugation table with fewer than 6 persons → **hard fail**
  (this is the single most common way `vosotros` silently disappears)
- Recent-past narrative using only preterite where Spain would use `he + participio`
  → **soft flag** for human review

### 3.7 AI Tutor behaviour when the learner uses a non-Spain form

Never correct as "wrong". The mandated pattern:

> ✅ Learner: *"¿Quieren un café?"* (to two friends)
> Tutor: *"Se entiende perfectamente. En España, hablando con dos amigos, lo normal es
> **¿Queréis un café?** — `ustedes` en España suena formal."*

No shaming, no dialect debate, no switching the tutor's own default.

### 3.8 What the guard does **not** do

It does not pretend Spain is monolithic. Andalusian *seseo/ceceo*, Canarian, Galician-,
Basque- and Catalan-influenced accents are real and appear as **tagged listening material
from B1** for comprehension. The *productive* target remains standard Peninsular.
Never marketed as "the only correct Spanish."

---

## 4. Spain Spanish internal style guide — outline

This becomes the source of truth for content QA. It must exist **before** mass content
generation and be authored/approved by a native Peninsular editor. Structure:

**§1 Scope and authority** — target variety; the reference hierarchy for adjudicating
disputes: *Instituto Cervantes Plan Curricular (PCIC)* → *RAE/ASALE NGLE & DPD* →
*DRAE* → *CORPES/CREA frequency* → editor judgement. Never "the LLM said so."

**§2 Variety and register** — the six register labels; level-gating table for
colloquialisms; what is never taught (insults, regional slurs, prescriptively
stigmatised forms as targets).

**§3 Lexical preferences** — the versioned preference table (3.3), each entry with:
Spain form, non-default alternatives, whether the alternative is *wrong in Spain* or
merely *not default*, false-friend risk, first CEFR level, register.

**§4 Grammar decisions** — vosotros policy; perfecto compuesto policy; leísmo tiers;
`se` constructions terminology; how we name tenses in Thai and Spanish
(*pretérito perfecto compuesto* vs *pretérito indefinido* — pick one naming system and
never mix; **[DECIDED]** use PCIC/RAE names, gloss in Thai).

**§5 Pronunciation standard** — distinción; `/x/`; approximant `b/d/g`; syllable timing;
what "standard Peninsular" means for casting voice talent.

**§6 Orthography & typography** — `¿ ¡`; accent rules incl. `solo`/`sólo` and
demonstratives (RAE current guidance: no accent) — pick and enforce; capitalisation
(months, days, nationalities lowercase); `«»` as primary quotation marks with `""`
nested; decimal comma and thousands separator; 24-hour time; date format
`23 de mayo de 2026`; currency `12,50 €` (space, symbol after).

**§7 Thai-side style** — how Spanish terms are transliterated (or deliberately not);
Thai grammar terminology glossary (a fixed, consistent Thai term for *article*,
*gender*, *subjunctive*, etc. — inconsistency here is a top-3 content quality risk);
politeness level of Thai explanations (ครับ/ค่ะ policy — **[NEEDS DECISION D-03]**:
recommend neutral, no gendered particles, to avoid mis-gendering the learner);
sentence length limits for mobile.

**§8 Audio standard** — speaker criteria, permitted regional range, recording spec,
speed variants, naming.

**§9 AI correction policy** — the 3.7 pattern; when to correct vs. collect; forbidden
phrasings.

**§10 Handling of non-Spain forms** — labelling, placement, drill exclusion.

**§11 Change control** — the style guide is versioned; content records which version
it was reviewed against.
