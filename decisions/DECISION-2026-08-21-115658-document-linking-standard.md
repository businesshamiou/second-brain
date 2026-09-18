---
type: decision
title: "Adoption of the standard for links between documents"
created_at: "2026-08-21T11:56:58-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
---

# DECISION — Adoption of the standard for links between documents

## Date

2026-08-21

## Status

`ARBITRATED`

Arbitration: Owner/Pilot session of 2026-08-21.

## Decision

Adoption of the [rule of the standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md), which engraves the twelve points of the cited proposal. This Decision keeps the proposal as a source instead of renaming or transforming it.

Choices retained for the points marked `[choix]` in the proposal, taken up as written:

- Name of the summary section: « Liens » (point 2).
- Closed vocabulary of six types: `applique`, `remplace`, `amende`, `source`, `prescrit par`, `voir aussi` (point 4). **Note (2026-08-26, Mission 065)**: this French vocabulary has been anglicized since [DECISION-2026-08-25-131034](./DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md), point 4 (`applies`, `supersedes`, `amends`, `source`, `prescribed by`, `see also`), migration executed by Mission 054; kept here for historical reading, not corrected in place.
- Suffix `(hors Vault)` / (workshop history, not distributed) for a link that leaves the current repository, without producing an edge (point 6).
- Blocking/warning split of the machine check: a missing `## Liens` section and a broken link block; the absence of an internal link only warns (point 9).
- Pilot review for the right type and the in-context link, in addition to the machine check (point 10).
- Retroactivity left out of this Mission: existing documents without links are corrected by a dedicated Mission (024), not on the fly (point 11).

## Reason

The graph of a prose corpus reflects the written links; the model complements, it does not replace. Three independent traditions (personal knowledge management, software architecture decisions, OKF) converge on the same form, measured by Missions 021 and 022.

## Impact

Six existing templates and one report template now carry a pre-filled `## Liens` section. A pre-commit check (`tools/check-links.sh`) applies the rule mechanically. `AGENTS.md` and the installation runbook point to the rule. Existing documents remain unchanged until Mission 024.

## Important alternatives

- Front matter alone: rejected, measured `PARTIEL` by Mission 021.
- « Liens » section alone, without in-context links: rejected, the reader loses the relation where it is stated.
- Let the model infer the links: rejected, measured by Missions 020-C01 and 021.

## Human gate

- Validation: granted
- Reference: agreement in principle from the Owner in session on 2026-08-21, formalized by Mission 023.

## Linked artefacts

- Source Proposal: (workshop history, not distributed)
- Rule adopted: `../rules/RULES-2026-08-21-115658-document-linking-standard.md`

## Liens

- `applies` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `source` — Proposal: links standard (workshop history, not distributed) (hors Vault)
- `see also` — Mission 023 (workshop history, not distributed) (hors Vault)
- `amended by` — [Doctrinal arbitrations of 2026-08-25](./DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md) (point 4, anglicization of the vocabulary)
