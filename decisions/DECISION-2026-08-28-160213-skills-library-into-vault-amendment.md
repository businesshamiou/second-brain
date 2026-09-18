---
type: decision
title: "Amendment — the 28 external skills enter the Vault, library vault/skills/external/, the personal scope becomes junctions"
description: "Amends DECISION-151235 §4 on Owner arbitration of 2026-08-28: the canonical library of the 28 adopted external skills lives in vault/skills/external/ and ships with the distributed product; the Claude personal scope becomes junctions to this library; MIT licence and provenance embedded; the distribution manifest must classify these files."
created_at: "2026-08-28T16:02:13-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md"
---

# DECISION — THE EXTERNAL SKILLS LIBRARY ENTERS THE VAULT

## Date

2026-08-28

## Status

`ARBITRATED`

## Decision

**1.** `DECISION-2026-08-28-151235` §4 (« portée personnelle, hors Vault » ["personal scope, outside the Vault"]) is amended: **the canonical library of the 28 adopted skills lives in `vault/skills/external/<nom>/`**. It is part of the Vault and therefore of the distributed product. The lists (28 accepted, 8 refused), the score criterion and the single-source rule (§1, §2, §3, §6 of 151235) stay unchanged.

**2.** The `external/` subfolder is a provenance boundary: it contains only material by third-party authors, never the Vault's own skills (the six V1 skills of `DECISION-232341` §5.1 will live directly in `vault/skills/`).

**3.** The library embeds the **MIT licence** of the source collection (Matt Pocock, `skills-main` 1.2.3) and a provenance note; the licence obligation follows the files to the participants.

**4.** The Claude personal scope (`C:\Users\<utilisateur>\.claude\skills\<nom>`) stops being a copy: each folder of the 28 becomes a **junction** to `vault/skills/external/<nom>/`. A single source; Claude reaches it through its door, any other agent through the Vault's path. No content is lost: the replacement is copy-then-junction, not outright deletion.

**5.** The Vault's **distribution manifest** classifies the files of `skills/external/`; if its current schema has no suitable category, the classification is raised to the Owner, never invented.

**6.** The Vault's hooks apply to this content as to the rest. A hook refusal on this external material means **stop and report**, never a workaround; any need to exclude `skills/external/` from a guardian's perimeter is a separate Owner arbitration.

## Reason

Owner arbitration of 2026-08-28: « on garde les skills centralisés dans le vault dans leur bibliothèque c'est plus simple comme ça » ["we keep the skills centralized in the vault in their library, it's simpler that way"], given after presentation of the three options (library outside the repositories; everything in the Vault; library plus hardened selection) and their costs — including distributing to participants five beta skills and an unhardened `wizard`, the licence to honour, and the maintenance of third-party material in the product. The simplicity of a single source in the versioned repository wins, knowingly. The requirement of the same day — skills within reach of any agent, not only Claude — is met: the Vault is a disk path readable by any agent, the Claude scope is now only an adapter.

## Impact

- `DECISION-151235` receives the reciprocal `amended by` link in the same commit.
- The audit and packaging perimeter of the Vault widens by 94 external files; the hardening recommended by the second audit remains unexecuted and documented in the catalogue.
- The catalogue (`knowledge-notes`) is updated: canonical paths `vault/skills/external/`.
- The product's distribution now includes this material; any upstream update (the author's GitHub repository) is a product maintenance operation, in the Owner's hands.

## Important alternatives

- Library at the root of the workspace + adapters (proposal B): rejected by the Owner — simplicity of a source in the Vault preferred.
- Hardened selection alone in the Vault (B+S): rejected by the Owner after detailed explanation.
- Per-agent copies without a canonical source: rejected — guaranteed divergence, contrary to `DECISION-214607`.

## Human gate

- Validation: granted
- Reference: arbitration in session, Owner, 2026-08-28, after three rounds of options and the requested explanation of B+S.

## Linked artefacts

- Amended Decision: DECISION-2026-08-28-151235-external-skills-adoption-score-threshold (workshop history, not distributed).
- Single-source / adapters doctrine: `../../../vault/decisions/DECISION-2026-08-24-214607-transverse-mechanism-distribution.md`.
- Execution Mission: `../missions/MISSION-2026-08-28-160311-082-skills-library-into-vault.md` (filed in the same turn).

## Liens

- `amends` — Decision — Adoption of external skills at the score threshold (workshop history, not distributed)
- `see also` — [Decision — Distribution of transverse mechanisms](../../../vault/decisions/DECISION-2026-08-24-214607-transverse-mechanism-distribution.md) (hors Vault)
- `amended by` — [Decision — Adoption by V1 envelope rewrite](./DECISION-2026-08-28-171209-skills-adoption-by-v1-envelope-rewrite.md)
