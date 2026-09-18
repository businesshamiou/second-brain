---
type: decision
title: "External skills adoption doctrine — adoption by V1 envelope rewrite, update-or-reject cycle, end of the untouchable status"
description: "Engraves the doctrine arbitrated by the Owner: an external skill is adopted by being rewritten into a V1 version of our own — envelope in the Vault format immediately, body kept verbatim with a fingerprint, then an update or reject-and-delete life cycle. Amends DECISION-160213 and lifts Mission 082's modification ban for the envelopes. The E/P arbitration on the guardian becomes moot."
created_at: "2026-08-28T17:12:09-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-28-171209-skills-adoption-by-v1-envelope-rewrite.md"
---

# DECISION — ADOPTION BY V1 ENVELOPE REWRITE

## Date

2026-08-28

## Status

`ARBITRATED`

## Decision

**1. Adoption = rewrite.** An external skill does not enter the Vault as untouchable material: it is adopted by becoming a **V1 version of our own**. The status "external, never modified" engraved by Decisions 151235/160213 and Mission 082 is lifted for the content of `vault/skills/external/`.

**2. The V1 is done in two stages, and only the first is immediate.**
- **Envelope, now, for all 28**: the front matter of each `SKILL.md` is rewritten in the Vault format — `type: skill`, `title`, `description` (one line), real `created_at`, `timezone`, `status: ADOPTED-V1` (provisional value, subject to the `open-vocabularies` arbitration) — **keeping the functional fields** of the Agent Skills format without which the skill stops being discovered and loaded: `name`, the functional `description` (merged with ours: a single line serving both readings), `disable-model-invocation` and `argument-hint` where they exist. Provenance lives in flat `metadata-*` keys (upstream repository, upstream version, licence, **SHA-256 fingerprint of the original body**) — flat form arbitrated on 2026-08-28 after measurement: the nested `metadata:` block, a conforming extension point of the upstream format, is unreadable by the restricted parser of the reciprocity guardian (diagnosis in the report of Mission 083, first run).
- **Body, as we go**: the body stays verbatim on entry, proven by the fingerprint. Its rewrite is done skill by skill, when use justifies it, first those the audits ask to harden (`wizard`, `scroll-film-studio`). No wholesale rewrite of bodies.

**3. Life cycle.** Each adopted skill then lives on: **update** — our version evolves, the gap with upstream is accepted and the maintenance falls to us; or **reject** — the skill is deleted from the Vault, deletion remaining a human gate of the Owner, never a gesture of an Executor alone.

**4. Consequence for the guardians.** The envelopes being in the Vault format, the reciprocity guardian reads the 28 files with no exemption or relaxation: the E/P arbitration raised by the PARTIEL of Mission 082 is **moot**. The guardians keep full powers over `skills/external/`, as everywhere.

**5. `skills/external/` changes meaning**: it is no longer a governance boundary ("material we do not touch") but a **provenance** boundary ("material born elsewhere, adopted here"). The six native V1 skills of `DECISION-232341` §5.1 stay outside this folder.

## Reason

Owner arbitration of 2026-08-28: “in my view we must adopt them by rewriting them to be a V1 version and afterwards either we update or we reject and delete” (the Owner's words, translated from French), given after three rounds — internal/external definition laid down, cost of the fork exposed, envelope/body distinction proposed by the Pilot and integrated. The doctrine also resolves the measured blockage of 082: 18/28 headers unreadable by the guardian stop being so once in the Vault format, without touching the guardian itself.

## Impact

- `DECISION-160213` receives `amended by` (same commit). §6 of 160213 (hooks perimeter arbitration) is resolved without exemption.
- Mission 082's constraint "any hardening or modification of the content of the skills" is lifted **for the envelopes only** in Mission 083; the bodies stay verbatim until their individual rewrite.
- The catalogue documents per skill: ADOPTED-V1 status, body fingerprint, upstream gap (none on entry).
- The audits' hardening recommendations become the queue of body rewrites.

## Important alternatives

- Guardian exemption on `external/` (option E): made moot — it treated the symptom (unreadable headers) while leaving the material untouchable, which the Owner does not want.
- Relax the guardian's parser (option P): rejected — touching a proven mechanism to tolerate a format we decided to make disappear.
- Rewrite the 28 bodies immediately: rejected — days of work on material not yet in use, contrary to the Owner's "as we go".

## Human gate

- Validation: granted
- Reference: exact words of the Owner in the session of 2026-08-28 (doctrine), then « je valide le dépôt de la Décision d'adoption et de la Mission 083 » ["I validate the filing of the adoption Decision and of Mission 083"].

## Linked artefacts

- Amended Decision: `./DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md`.
- Source blockage: `../reports/REPORT-2026-08-28-162300-082-skills-library-into-vault.md` §7 (verbatim of the guardian's refusal).
- Research on `metadata` as an extension point: knowledge-notes of 2026-08-27.
- Execution Mission: `../missions/MISSION-2026-08-28-171305-083-skills-v1-envelope-adoption.md` (filed in the same turn).

## Liens

- `amends` — [Decision — The external skills library enters the Vault](./DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md)
- `see also` — Decision — Adoption of external skills at the score threshold (workshop history, not distributed)
- `see also` — Execution report — Mission 082 (workshop history, not distributed)
- `amended by` — [Decision — Standard form of the skills library and replacement by the warehouse package](./DECISION-2026-08-31-231841-skills-library-standard-form-warehouse.md)
