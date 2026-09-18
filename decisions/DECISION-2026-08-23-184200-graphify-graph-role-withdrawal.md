---
type: decision
title: "Withdrawal of Graphify from the “Vault graph” role"
created_at: "2026-08-23T18:42:00-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: granted
scope: graphify-case-study, verdict
amends:
  - "DECISION-2026-08-18-004740-graphify-v1-architecture.md"
  - "DECISION-2026-08-19-115306-project-registry-v1.md"
  - "DECISION-2026-08-17-003000-vault-central-architecture.md"
  - "DECISION-2026-08-19-233650-graphify-integrations-amendment.md"
---

# DECISION — WITHDRAWAL OF GRAPHIFY FROM THE "VAULT GRAPH" ROLE

## Date

2026-08-23

## Status

`ARBITRATED`

## Decision

Graphify leaves the "Vault graph" role. This Decision applies mechanically, without loosening or tightening it, the decision rule of the measurement bench protocol (workshop history, not distributed) §2.6 to the figures measured by Missions 032 (C2), 033 (C3) and 034 (C1) — full trace in the case study (workshop history, not distributed) §5.

The rule: "Graphify is kept if, and only if, C3 obtains an accuracy strictly higher than C2 on at least one question, without degrading accuracy on any other." Measured: C3 wins on Q5 (2 versus 1) but degrades Q1 (1 versus 2). The second condition of the rule — no degradation — fails. The retention criterion is not met. This is the last-attempt clause, accepted in advance by the [Decision of the seven arbitrations of 2026-08-23, point 6](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md) and by protocol B1 itself: no new measurement.

### What stays in place

Nothing that replaced Graphify for navigation depends on it, and nothing of it is withdrawn by this Decision: the corpus, the generated state sheet (`<projet>/state/journal.md` + `<projet>/state/STATE.md`), the generated per-folder indexes (`tools/build-indexes.sh`), content search (`tools/find-in-vault.sh`) and written links (Standard for links between documents) remain the navigation system of the Vault. The three measured conditions confirm it: Q2, Q3 and Q4 obtain 2/2 in all three conditions, including C1, which has none of these tools.

### Withdrawal gestures to perform (planned, not executed by this Decision)

Outside the scope of the Mission that engraves this Decision (035) — to be planned by a separate Mission:

1. `graphify hook uninstall`: remove the `post-commit`/`post-checkout` hooks installed in `vault`, and the entry `graphify-out/graph.json merge=graphify` from `.gitattributes`.
2. Uninstall the package outside the repository: `uv tool uninstall graphifyy`.
3. Archive or remove `graphify-out/` (supprimé, Mission 040 — deleted) (already unversioned) once the decision is executed.
4. Remove `.env`/`.env.example` (`GEMINI_API_KEY`) if no use requires it any more.
5. Remove the automatic reminder "MANDATORY: run graphify..." injected at every Bash/Read/Grep call — observed and explicitly ignored in all the measurement windows of batch B (reports 032 §8, 033 §6, 034 §6).
6. Update `_trash/runbook-vault-setup.md` §4 (remove or requalify the Graphify section, add the history entry of the withdrawal in §9 — an obligation already written in the runbook itself; runbook withdrawn from distribution since, Mission 175).
7. Review the mention of Graphify in `DECISION-2026-08-19-115306-project-registry-v1.md` (D5: the index and the Registry sheets entered the Graphify active corpus) — becomes moot.
8. Check that no first-install skill (arbitration 7 of the seven arbitrations) installs Graphify as a component of the distributed graph.

### Return door

The subject may be reopened if a future measurement — conducted under this protocol or a successor that does not loosen it — produces a condition C3 where the graph is **actually queried** (at least one `graphify query`/`path`/`explain` request per question, unlike the zero requests over five questions of this measurement, report 033 §6 (workshop history, not distributed)) and where the result then satisfies, without loosening, the criterion of rule B1 §2.6. As long as this condition is not met, the subject remains closed.

## Reason

The Decision of the seven arbitrations of 2026-08-23 (point 6) had chosen "fix, test, then decide" rather than freezing or withdrawing Graphify in advance. The identified defect (the generated indexes did not enter the graph) was fixed and measured as effective by Mission 033 (33 nodes from 9 `index.md` files, out of 434 nodes in total). The three-condition comparative measurement was then conducted according to protocol B1, filed in advance and not modified since. The measured result does not satisfy the retention criterion written in advance: a degradation on Q1 accompanies the only gain observed, on Q5.

## Impact

- No installation or removal is made by this Decision — see "Withdrawal gestures to perform" above.
- No component of the fixed system (state sheet, indexes, content search, written links) is affected.
- The distribution package (arbitration 7 of the seven arbitrations) will no longer present Graphify as a component of the Vault graph once the withdrawal gestures are executed.
- The episode opened by Mission 025 ("Graphify withdrawn from the 'Vault graph' role, formal Decision to be written") is closed by this Decision.

## Important alternatives

- **Keep Graphify despite the degradation on Q1**: rejected — the rule written in advance (B1 §2.6) explicitly requires the absence of degradation on any other question; loosening it after the fact to keep only the gain on Q5 would contradict the constraint of Mission 035 ("without loosening or tightening it after the fact").
- **Remeasure C3 while making sure the graph is actually queried** before deciding: rejected by the protocol itself — the last-attempt clause (B1 §2.6) explicitly excludes a new measurement after this result. The fact that C3 never queried the graph (§"What the study does not say" of the case study) is documented as a return door, not as a reason for immediate remeasurement.
- **Also withdraw the rest of the fixed system** (state sheet, indexes, search, links): rejected — these elements do not depend on Graphify and obtain the same accuracy as the other conditions on the questions they cover (Q2, Q3, Q4).

## Human gate

- Validation: granted.
- Reference: the [Decision of the seven arbitrations of 2026-08-23, point 6](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md) pre-authorized the mechanism "fix, test, then decide"; protocol B1 (workshop history, not distributed), filed under an `AUTHORIZED` Mission, sets the decision rule in advance and with no margin of judgement. This Decision mechanically executes this pre-authorized rule on the measured figures; it does not constitute a new arbitration of substance and therefore does not require a new separate gate.

## Linked artefacts

- Source protocol of the applied rule: (workshop history, not distributed)
- Case study and full trace of the verdict: (workshop history, not distributed)
- Measurements: (workshop history, not distributed), (workshop history, not distributed), (workshop history, not distributed)

## Liens

- `amends` — [Graphify V1 architecture — optional navigation and bounded active corpus](./DECISION-2026-08-18-004740-graphify-v1-architecture.md)
- `amends` — [Project Registry V1 — architecture and write contract](./DECISION-2026-08-19-115306-project-registry-v1.md) (D5 becomes moot)
- `amends` — [Central architecture — permanent Vault and sibling projects](./DECISION-2026-08-17-003000-vault-central-architecture.md) (Graphify section, Mission 065)
- `amends` — [Graphify V1 amendment — native integrations](./DECISION-2026-08-19-233650-graphify-integrations-amendment.md) (D1, D5 — Mission 065)
- `amends` — Arbitration of the Vault's Graphify V1 baseline (workshop history, not distributed) (hors Vault) (status `READY_TO_RESUME` outdated — Mission 065)
- `source` — Measurement bench protocol — Graphify case study (workshop history, not distributed) (hors Vault)
- `source` — Graphify case study — synthesis, verdict and material for illustration (workshop history, not distributed) (hors Vault)
- `see also` — [Decision — Seven session arbitrations of 2026-08-23, point 6](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
