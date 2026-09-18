---
type: decision
title: "Outgoing links to another repository — marked, checked only when the target repository is present on disk"
description: "(workshop history, not distributed)"
created_at: "2026-09-02T00:50:41-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-09-02-005041-cross-repo-links-checked-only-when-target-repo-present.md"
---

# DECISION — OUTGOING LINKS TO ANOTHER REPOSITORY

## Date

2026-09-02

## Status

`ARBITRATED` — exact word « exempter » ["exempt"], Owner, 2026-09-02, Pilot window, after a single recommendation.

## Decision

1. **Definition.** A link is *outgoing* when its resolved target leaves the root of the current repository (relative path that crosses `..` beyond the root, or path to a sibling repository). Examples: the `amended by` lines that the Vault carries towards (workshop history, not distributed) (placement 205904: the reciprocal lives in the repository of the amended document), the `prescribed by` lines that a project carries towards `vault/rules/`.
2. **Marking.** Every outgoing link carries, after the link, the mention `(hors Vault)` when the target is the Vault, `(hors dépôt)` ["outside the repository"] otherwise. The mention is for the reader; the guardian decides by the path, not by the mention.
3. **Check.** `check-links.sh` treats an outgoing link as follows: if the **target repository is present** on disk (its root exists) → the target is checked like an ordinary link, absent = refusal; if the **target repository is absent** → warning naming the link, **no refusal**. Links internal to the repository do not change: absent = refusal.
4. **Reach.** The rule holds in the working corpus (the two repositories side by side: everything is checked as before) and in a standalone package (the Vault alone: the 22 outgoing links are warned, the package is clean). It does not cover links to `INTERNE` files of the same repository (registry, installation history): those remain internal links, dead by verdict in the package, recorded in the build report — the Owner settled their verdict, not the link.
5. **Erratum (Mission 127, 2026-09-02).** The figure "22" above (and at the other occurrences in this document) was a snapshot from report 117; the real count is measured at each build of the package (86 warnings measured in report 118, normal growth of the corpus) and is not normative — none of the previous occurrences is rewritten.

## Reason

The placement principle (205904) requires the Vault to carry links to the project Decisions that amend it. A standalone package does not contain the project: these links are dead there **by construction**, not by error. Report 117 counted them for the first time on a real object: 22, all structural. A guardian that refused the package for this would refuse an intended property; a guardian that ignored every outgoing link would lose control in the working corpus. The rule keeps both: full check when the target can exist, warning when it cannot.

## Impact

- `RULES-2026-08-21-115658-document-linking-standard.md` amended (reciprocal placed in the Vault, Mission 118); `DECISION-2026-08-28-203627` (Links section scoped to the corpus) unchanged, compatible.
- `tools/check-links.sh` modified by Mission 118 according to pattern 107: canaries in a throwaway repository (outgoing to absent repository → warned; outgoing to present repository, target absent → refusal; internal absent → refusal), test added under `tests/`, re-pin cycle at the end of the Mission.
- `build-package.sh`: the link check on the extracted tree becomes part of the verification (117 did it by hand); expected result after this Decision: 0 refusals, 22 warnings, 12 internal links to `INTERNE` files recorded.
- Cost: one Mission; no change for authors, who already mark « (hors Vault) ».

## Important alternatives

- **Leave the 22 dead and record it**: rejected — the delivered guardian would refuse the delivered package; one does not distribute a check that fails on what it accompanies.
- **Remove the outgoing `amended by` from the Vault**: rejected — contrary to placement 205904 and to the traceability of amendments.
- **Exempt by the mention rather than by the path**: rejected — a forgotten or false mention would mislead the guardian; the path does not lie.

## Human gate

- Validation: granted — « exempter » ["exempt"], Owner, 2026-09-02.
- Reference: Pilot window, review of end-of-session debts.

## Linked artefacts

- Source: `../reports/REPORT-2026-09-02-002016-117-manifest-verdicts-and-package-rebuild.md` (35 links, of which 22 outgoing)
- Execution: Mission 118 (guardian, test, reciprocal)

## Liens

- `prescribed by` — [Decision template](../../../vault/templates/decision-template.md) (hors Vault)
- `amends` — [Document linking standard](../../../vault/rules/RULES-2026-08-21-115658-document-linking-standard.md) (hors Vault)
- `see also` — [Decision — The amendment lives in the repository of the amended document](../../../vault/decisions/DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md) (hors Vault)
- `see also` — Decision — Code is never a norm (workshop history, not distributed)
