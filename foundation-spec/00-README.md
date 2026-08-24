# ESPAÑOL DE ESPAÑA — Foundation Specification (Phase 0 + Phase 1)

**Product working name:** `EDE` (Español de España) — final name TBD (Decision D-01)
**Target learner:** Thai speakers learning Peninsular Spanish
**Document status:** DRAFT v0.1 — awaiting owner approval
**Date:** 2026-08-24
**Author role:** combined PM / architect / curriculum & pedagogy / engineering

---

## What this document set is

This is the deliverable required by `FIRST RESPONSE REQUIRED` in the Master Project Instruction:
the 60-point foundation specification that must exist **before** production code.

No application code has been written. No database has been created.

---

## Findings from project inspection (Execution Protocol, Steps 1–3)

**Step 1 — Inspect existing project.**
Supabase account inspected via MCP. Two projects exist:

| Project | Ref | Region | Status | Relevance |
|---|---|---|---|---|
| fangkaokakao's Project | `owbaacymjxehenribbgu` | ap-northeast-1 | ACTIVE_HEALTHY | Japan Hayai system — **unrelated, do not touch** |
| japanhayai | `vjmrwwhxocnalvreesas` | ap-southeast-1 | INACTIVE | Japan Hayai legacy — **unrelated, do not touch** |

**Step 2 — What already exists for this product.** Nothing. Greenfield.
No Flutter project, no Supabase project, no schema, no content, no design system.

**Step 3 — Immediate consequences.**
- A **new, dedicated Supabase project** is required. Learner voice recordings and
  learning history must never share a database with a freight-forwarding business
  (privacy blast radius, RLS surface, backup/retention policy conflicts).
- The organisation `aaptooxubcispkjjlsjo` already holds 2 projects. On the Free plan
  that is the project ceiling — creating a third requires a paid org plan.
  **This is a blocking commercial decision (D-02).**
- Suggested region: `eu-west-3` (Paris) or `eu-central-1` (Frankfurt) — see §52.
  Rationale: the learner audio/AI providers and Spanish-language TTS voices are
  EU-hosted, and GDPR posture is simpler if the target audience later includes
  learners resident in Spain. Latency for Thailand/Japan users is acceptable
  because the heavy assets are CDN-cached, not database round-trips.

**DELE verification (required by the instruction: "Do not rely on memory").**
Verified against Instituto Cervantes and current 2026 sources — see `05` §25.
Key confirmed points and the one confirmed *inconsistency between sources* that
proves exam specs must be versioned data, not code.

---

## Reading order

| File | Covers spec items | Purpose |
|---|---|---|
| `01-product-and-language-policy.md` | 1–4 | Vision, learner, Spain-Spanish policy, style guide outline |
| `02-learning-architecture.md` | 5–26 | CEFR map, curriculum, grammar/pronunciation/vocab/skills, DELE, scenarios |
| `03-experience-architecture.md` | 27–34 | IA, screens, navigation, UX, accessibility, CMS, content QA |
| `04-technical-architecture.md` | 35–53 | Data model, ERD, RLS, storage, backend, AI gateway, speech, Flutter, offline, security, testing, environments |
| `05-mvp-roadmap-and-decisions.md` | 54–60 | MVP, roadmap, phase dependencies, risks, gaps, decisions, first vertical slice |
| `06-core-schema-sketch.sql` | 36 | Illustrative DDL for the ERD — **not a migration** |

---

## How to read the confidence markers

- **[DECIDED]** — recommended and justified; proceed unless the owner objects.
- **[NEEDS DECISION]** — owner or commercial input required; listed in `05` §59.
- **[NEEDS VERIFICATION]** — must be checked against an external authority before
  implementation (DELE specs, provider capabilities, pricing).
- **[SPIKE]** — technical unknown requiring a timeboxed experiment before commitment.

Nothing in this document set claims to have been tested. Nothing has been built.
