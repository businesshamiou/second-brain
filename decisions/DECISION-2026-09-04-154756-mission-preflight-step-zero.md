---
type: decision
title: "Preflight step 0: all guardians run on the Scope before the first commit, all violations reported at once"
description: "Decision arbitrated on 2026-09-04 after five Executor windows for a single Mission: every Mission that commits an artefact filed by the Pilot starts with a step 0 that runs the guardians on the files of the Scope and reports all the violations before any commit; the Pilot rereads itself against the guardian contracts measured in report 132 before filing; and the Mission template receives the two rubrics that the Decisions of the day require without the template carrying them."
created_at: "2026-09-04T15:47:56-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: mission-preflight, pilot-self-check, mission-template
---

# DECISION — PREFLIGHT STEP 0

## Date

2026-09-04

## Status

`ARBITRATED`

Owner arbitration in plain words, Pilot session of 2026-09-04, gate « go pour le step 0 » ["go for step 0"].

## Triggering fact

Mission 134-A required five Executor windows: a precondition STOP, then two guardian refusals both bearing on the same new file filed by the Pilot — a front-matter reciprocity, then a bare path token. Both defects were present from the filing. Since the guardians stop at the first refusal, they were discovered one after the other, at the price of a complete round trip each: Executor window, Pilot snippet, Owner gesture.

No bypass was used, and that is the right behaviour. The cost, however, is avoidable.

## Decision

1. **Preflight step 0.** Every Mission whose Scope includes the commit of an artefact filed by the Pilot starts with a step 0: run all the applicable checks on the files of the Scope, collect **all** the violations, report them at once, and stop before any commit if any of them remains. The preflight corrects nothing: it measures. A defect found is corrected at its source, by the role that wrote the file.

2. **Pilot rereading against the measured contracts.** Before filing an artefact, the Pilot rereads itself against the guardian contracts established by report 132: no bare path token between backticks, agreement between the front-matter fields and the `## Liens` section, manifest line planned for every new Vault file, canonical timestamped name. This rereading is doctrinal: nothing mechanizes it, since nothing reads the chat.

3. **Two missing rubrics in the Mission template.** The template receives the « Existant mesuré » (measured existing) rubric that Decision 121443 requires for every Mission creating a file, and step 0 above. It also receives, in its default Scope, the file `superseded-files.txt` of the repository concerned as soon as a step regenerates an index: it is a guaranteed output of the indexing tool, never an exception (report 132, case C4).

## Reason

- A guardian that stops at the first refusal is right for protecting the repository, but costly for correcting a file: it turns *n* defects into *n* round trips. The preflight turns them into one.
- The guardian contracts were readable nowhere before report 132: the Pilot was writing blind. They now are, so the rereading becomes possible — it was not the day before.
- Two Decisions of 2026-09-04 prescribe rubrics that the template does not carry. A norm that its template ignores applies only to the memory of whoever drafts.

## Impact

- `../templates/mission-template.md` receives three additions — gesture of a separate Mission, not of this Decision.
- Existing Missions are not amended retroactively.
- The preflight adds one run of guardians per Mission; the timing of report 132 puts it between one and six seconds, with no effect on the budget.
- Point 2 is doctrinal and joins the checklist of the Mission-writing skill; it will drift if nothing recalls it, and that is accepted.

## Important alternatives

- Have each guardian report all its violations instead of stopping at the first: rejected here, it modifies six scripts and changes their behaviour; the preflight obtains the same effect without touching them.
- Let the Pilot run the guardians itself: impossible, the Pilot executes nothing.
- Change nothing and accept the round trips: rejected, five windows for four prose corrections is a cost that distribution to two hundred participants would not bear.

## Human gate

- Validation: granted
- Reference: Owner order in plain words, Pilot session of 2026-09-04, gate « go pour le step 0 » ["go for step 0"]

## Linked artefacts

- Source proposal: none
- Source measurement: (workshop history, not distributed) (hors Vault)
- Triggering fact: (workshop history, not distributed) (hors Vault)

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `see also` — [Decision — Existence sweep, memory and hypotheses](./DECISION-2026-09-04-121443-existence-sweep-memory-hypothesis-measured-existing.md)
- `see also` — [Decision — Amendment of two engraved norms](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)
- `see also` — [Mission template](../templates/mission-template.md)
- `see also` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
