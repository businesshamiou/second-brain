---
type: decision
title: "Amendment of DECISION-171209 — the skills library moves to the standard Agent Skills form (six fields, provenance under metadata); replacement by the skills-warehouse package"
description: "Engraves the Owner's arbitration of 2026-08-31: the V1 envelope with flat keys (type, title, created_at, status, metadata-upstream-*) is abandoned because it is outside the Agent Skills specification — the claude.ai uploader refuses it with a hard error, only name, description, license, compatibility, allowed-tools and metadata are admitted. The vault/skills/external/ library is replaced by the output of the skills-warehouse project (package affiliate-pro-skills-full.zip), in standard form; the skills of the current library absent from the package are kept and converted to the same form; duplicates are counted and submitted; nothing is deleted, the old library goes to _trash/ with a fingerprint. The update-or-reject cycle and the verbatim body under fingerprint stay in force."
created_at: "2026-08-31T23:18:41-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-28-171209-skills-adoption-by-v1-envelope-rewrite.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-31-231841-skills-library-standard-form-warehouse.md"
---

# DECISION — STANDARD FORM OF THE SKILLS LIBRARY AND REPLACEMENT BY THE WAREHOUSE PACKAGE

## Date

2026-08-31

## Status

`ARBITRATED`

## Measured fact

Official Claude Code doc ("Extend Claude with skills", read on 2026-08-31): any header field outside the six allowed ones (`name`, `description`, `license`, `compatibility`, `allowed-tools`, `metadata`) causes a hard-error refusal on upload to claude.ai. Our V1 envelope (DECISION-171209 §2: `type`, `title`, `created_at`, `timezone`, `status`, flat keys `metadata-upstream-*`) is therefore outside the specification; the upstream's Claude Code extensions (`argument-hint`, `disable-model-invocation`) are too. Knowledge-note 152952 had established it on 2026-08-27: `metadata` is the standard's only extension point. The flat keys had been chosen to work around a guardian that did not read nested YAML (Mission 083) — code is never a norm (DECISION-193624).

## Decision

**1. Standard form, the only form admitted in `vault/skills/`.** A `SKILL.md` of the library carries at most the six fields of the specification. Any information specific to the Vault (provenance, body fingerprint, upstream version, entry date, extensions of a tool) lives **under `metadata:`**, as string → string pairs. §2 of DECISION-171209 is replaced on this point; its other principles hold: verbatim body proven by SHA-256 fingerprint, adoption by named Owner arbitration (DECISION-210726), update-or-reject cycle.

**2. Source of the library: the `skills-warehouse` project.** Its output (package `affiliate-pro-skills-full.zip`, path given by the Owner on 2026-08-31, outside the workspace) becomes the source of `vault/skills/external/`. The direction of flow is warehouse → Vault, never the reverse. The name of the package is free; it is its content that is measured.

**3. Replacement, not merge.** The current library (30 skills, V1 envelopes) is moved in full to `_trash/` with a fingerprint, never deleted (DECISION-110852). The new library is built from the package.

**4. What the package does not contain is kept and converted.** A skill present in the current library and absent from the package is declared in the report, then reinstalled from the old copy **converted to the standard form** (body intact, header reduced to the six fields, provenance under `metadata:`). Nothing is lost, everything has the same form.

**5. Duplicates.** A name appears once in the library, once in the catalogue, once in the manifest. A duplicate **internal to the package** (same name, two folders or two `SKILL.md`) is a STOP: counted, listed, submitted to the Owner — the Executor does not choose.

**6. Non-conformity of the package.** A `SKILL.md` of the package carrying a field outside the six is not installed as is: it is listed in the report with the offending field. The package is supposed to be standard; if it is not, it is the warehouse that must be fixed, not the Vault that must adapt.

**7. Guardians.** If a guardian refuses a nested `metadata:` block, it is a STOP with verbatim: the guardian will be fixed by a dedicated Mission (reading of the guardian, push, re-pin), never worked around or modified in the installation Mission.

## Reason

Owner arbitration of 2026-08-31: “we are going to install all the skills on both sides; on the Vault side, redo the installation from the new package; remove all the other skills and install the new ones; if a skill does not exist in the package, declare it, save it and adapt it to the same structure, for a standard form” (the Owner's words, translated from French). The choice of the standard form is not aesthetic: it is the only one that passes on all three surfaces (Claude Code, claude.ai, other agents), hence the only one compatible with a Vault distributable to any LLM.

## Impact

- 171209 receives `amended by` (reciprocal, same commit).
- Mission 106: replacement, conversion of the orphans, provenance, manifest, catalogue v2, junctions, check by Claude Code listing.
- Catalogue 151755: replaced by a catalogue v2 (`superseded by`), the old one stays as history.
- Reciprocity / obsolescence guardian: to be checked on nested YAML; any fix = dedicated Mission.
- Upload to claude.ai: becomes possible directly from the library (zip of the folder).

## Important alternatives

- Keep the V1 envelope and produce separate "cleaned" zips for the chat: set aside — two forms of the same skill, guaranteed divergence.
- Merge package and current library skill by skill: set aside by the Owner — replacement, the warehouse is the source.
- Delete the old library: forbidden (110852); `_trash/` with a fingerprint.

## Human gate

- Validation: granted
- Reference: Owner messages of 2026-08-31 cited under Reason.

## Liens

- `amends` — [Decision — Adoption by V1 envelope rewrite](./DECISION-2026-08-28-171209-skills-adoption-by-v1-envelope-rewrite.md)
- `see also` — Decision — The score criterion is removed, adoption is an Owner arbitration by name (workshop history, not distributed)
- `see also` — [Decision — The external skills library enters the Vault](./DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md)
- `see also` — Research — Agent Skills specification and life cycle (workshop history, not distributed)
