---
type: decision
title: "Amendment of two engraved norms on measurement: tool search by description, report naming pattern aligned with usage; and the general rule — an engraved Decision is never rewritten, it is amended by a Decision"
description: "Decision arbitrated on 2026-09-04 after report 132: amends the tool search rule of Decision 140714 (search phrased on the description, second search allowed and counted) and the report naming pattern of Decision 000236 (form aligned with measured usage); and engraves the general rule that was missing — the body of an arbitrated Decision is not rewritten, it receives a dated annotation pointing to the Decision that amends it, with reciprocal links."
created_at: "2026-09-04T14:52:56-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md"
  - "./DECISION-2026-08-21-000236-execution-report-channel.md"
scope: tool-search-rule, report-naming, decision-amendment-doctrine
---

# DECISION — AMENDMENT OF TWO ENGRAVED NORMS, AND THE AMENDMENT RULE

## Date

2026-09-04

## Status

`ARBITRATED`

Owner arbitration in plain words, Pilot session of 2026-09-04, gate « annote va graver aussi la décision » ["annotate, go engrave the decision too"].

## Triggering fact

Report 132 measured two engraved norms at odds with practice. The tool search rule of Decision 140714 (« par le nom exact de l'outil » ["by the exact name of the tool"]) had already been replaced in `../skills/session-start/reading-list.md` by text T7 of Mission 132-B, under an Owner gate — **an amendment living in a Mission and absent from the corpus of Decisions**. The report naming pattern of Decision 000236 includes a segment that usage never respected, which produced an out-of-pattern report at Mission 133 without any guardian seeing it.

These two cases have the same shape: an engraved norm that one does not dare rewrite, a usage that diverges, and nothing linking the two.

## Decision

1. **Tool search.** The rule of Decision 140714 by which a tool search is phrased « par le nom exact de l'outil » is amended. The search is phrased **on the tool's description** — verb and object — because the search index carries the descriptions and not the names (measurements of Missions 132-A and 132-B). A second search is allowed, and counted in the opening budget, if the first does not bring up the intended tool. The applied text lives in `../skills/session-start/reading-list.md`.

2. **Report naming.** The naming pattern for execution reports of Decision 000236 is aligned with measured usage: `REPORT-<AAAA-MM-JJ>-<HHMMSS>-<mission_id>-<slug>.md`. The segment never respected is removed from the norm rather than imposed retroactively on dozens of existing files. Having the retained pattern enforced by a guardian remains open and is not decided here.

3. **General amendment rule.** The body of a Decision with status `arbitrated` is never rewritten. It receives, at the exact place of the superseded rule, a **dated annotation** that names the amending Decision and the place where the applied text lives. The amending Decision carries `amends`, the amended Decision receives `amended by`: reciprocity makes the divergence visible to the link guardians. An amendment obtained by a Mission gate, without a Decision, is a transitional state to be regularized — never a final state.

## Reason

- A norm that contradicts its own practice is worse than an absent norm: it is read, cited in Missions, and propagates the error. Three texts produced real faults this week through this mechanism alone.
- Rewriting the body of a Decision would erase the trace of what was arbitrated and when. The annotation preserves the history and flags the drift at the same place.
- Point 3 is the structural remedy: without it, the next Mission gate will create a new orphan amendment.

## Impact

- Decisions 140714 and 000236 each receive a dated annotation and an `amended by` link to this one — gesture of Mission 134-A.
- The Decision template and the linking rule do not change: `amends` and `amended by` already exist, they were simply unused in this case.
- No existing file is renamed. No guardian is created or modified.
- The Pilot's opening budget now explicitly counts a possible second tool search.

## Important alternatives

- Rewrite the body of the two Decisions directly: rejected, loss of the arbitration trace.
- Let the amendment live in `../skills/session-start/reading-list.md` alone: rejected, that is the starting state, and it is invisible to anyone reading the Decision.
- Enforce the original naming pattern by a guardian and rename the existing files: rejected, cost without benefit, and measured usage is the best candidate.

## Human gate

- Validation: granted
- Reference: Owner order in plain words, Pilot session of 2026-09-04, gate « annote va graver aussi la décision » ["annotate, go engrave the decision too"]

## Linked artefacts

- Source proposal: none
- Source measurement: (workshop history, not distributed) (hors Vault)
- Application: Mission 134-A, (workshop history, not distributed) (hors Vault)

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amends` — [Decision — Pilot context budget](./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md)
- `amends` — [Decision — Execution report channel](./DECISION-2026-08-21-000236-execution-report-channel.md)
- `see also` — [Decision — Existence sweep, memory and hypotheses](./DECISION-2026-09-04-121443-existence-sweep-memory-hypothesis-measured-existing.md)
- `see also` — [Session opening reading list, by role](../skills/session-start/reading-list.md)
- `see also` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
