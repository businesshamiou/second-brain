---
type: decision
title: "Placement principle for amendments — an amending Decision lives in the repository of the document it amends"
description: "Engraves the Owner's arbitration M: any Decision carrying an amends or supersedes relation towards a document is filed in that document's repository, never in the sibling repository. Amendment relations thus stay internal to each repository's graph, computable by the guardians, and the amendment chain of the distributed product never contains a dead link. Resolves the cross-repository tension revealed by Mission 085 without touching either the links standard or the guardians."
created_at: "2026-08-28T20:59:04-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
---

# DECISION — THE AMENDMENT LIVES IN THE REPOSITORY OF THE AMENDED DOCUMENT

## Date

2026-08-28

## Status

`ARBITRATED`

## Decision

**1.** Any Decision carrying an `amends` or `supersedes` relation towards a document is filed **in the repository where that document lives**. A Vault rule is amended by a Decision filed in `vault/decisions/`; a project document is amended from the project's repository. No `amends`/`supersedes` relation crosses the boundary between repositories.

**2.** If a Decision had to amend documents of both repositories at once, it is split: one Decision per repository, linked to each other by `see also` (outside the graph, informational).

**3.** This principle is already the de facto practice of the corpus — the delegated push amendments (`DECISION-112528`) and the copy protocol (`DECISION-100016`) live in `vault/decisions/` because they amend texts of the Vault. It becomes an engraved norm here. `DECISION-2026-08-28-203627`, filed in the project repository by a placement error, is moved to `vault/decisions/` in immediate application.

**4.** Product motive, beyond the mechanics: the Vault is distributed alone. A Vault document whose amendment chain points outside the Vault delivers a **dead link** to the participants, in the product itself. This principle guarantees that the amendment chain of any distributed document is whole within what is distributed.

## Reason

Owner's arbitration M, 2026-08-28. Mission 085 revealed, at the first cross-repository `amends` relation in the corpus's history, a structural tension between `RULES-115658` §5 (mandatory reciprocity of typed relations) and §6 (a link outside the repository is not an edge): a cross-repository amendment is at once mandatory and invisible to the computation. The three ways out proposed by the measurement — make cross-repository edges real, relax the guardian, downgrade to `see also` — cost respectively the coupling of the repositories and dead links distributed, one more exemption on a guardian just brought into conformity, or the recreation of blindness to amendments. Placement corrects the cause: the relation no longer has to cross.

## Impact

- `RULES-115658` §5 and §6 stay as they are: the tension disappears because the case that triggered it no longer has the right to exist.
- No guardian modified.
- The reciprocal line placed on `RULES-115658` by Mission 085 (commit `f9887c8`) points to the old address: its correction to `../decisions/` is a gesture of Mission 086.
- This principle is a natural candidate for promotion to a Vault rule during a future consolidation of the links standard; meanwhile, the present Decision is authoritative.

## Human gate

- Validation: granted
- Reference: « je tranche : M » ["I decide: M"], Owner, 2026-08-28.

## Linked artefacts

- Measured tension: (workshop history, not distributed) (hors dépôt).
- Immediate application: `./DECISION-2026-08-28-203627-link-section-requirement-scoped-to-corpus.md` (moved).

## Liens

- `applies` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `see also` — [Decision — Scoping of the links standard to the corpus](./DECISION-2026-08-28-203627-link-section-requirement-scoped-to-corpus.md)
