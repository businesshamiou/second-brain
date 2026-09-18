---
type: decision
title: "Evidence status of arbitration lines and mandatory stop control on any unread assertion"
description: "Every line submitted to the Owner's arbitration declares its evidence status — measured, hypothesis or judgement — and every Decision point asserting the content of a document not read in the session goes out with a named stop control in its execution Mission."
created_at: "2026-08-29T21:20:09-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: pilot-conduct, arbitration-protocol
---

# DECISION — EVIDENCE STATUS OF ARBITRATION LINES

## Date

2026-08-29

## Status

`ARBITRATED`

## Decision

1. **Declaration of the evidence status.** Every line of a table submitted to the Owner's arbitration carries one of these three statuses, explicitly:
   - `MESURÉ` [measured] — the source was read in the current session, and it is named on the line.
   - `HYPOTHÈSE` [hypothesis] — the assertion rests on an inference; the document that would settle it is named, and it has not been read.
   - `JUGEMENT` [judgement] — the line carries a priority, an order or a preference, and claims nothing about the content of a document.
2. **Conditional wording.** A Decision point resting on a `HYPOTHÈSE` line is worded in the conditional and states what would refute it.
3. **Mandatory stop control.** Any Mission executing a point that comes from a `HYPOTHÈSE` line carries, before the write concerned, an explicit measurement step with a named `STOP`, its source to read and its refutation condition.
4. **Reach of a global validation.** An overall validation — « je valide les recos » ["I validate the recommendations"] or equivalent — covers a `HYPOTHÈSE` line only in the conditional form of point 2, with its stop control of point 3. Without them, the line is not submitted to arbitration: it is withdrawn from the table.

## Reason

On 2026-08-29, a table of thirteen questions was submitted to the Owner, who validated it in one word. Twelve lines rested on readings done in the session or on priority judgements. One rested on an inference drawn from an unopened document, and nothing distinguished it from the others. The inference was false: the counter it proposed to remove is prescribed by `DECISION-2026-08-25-110935` §4.

The format did not let the Owner see the difference: a measurement and a supposition had the same typographic weight and were engraved by the same word. The defect is not the supposition — it is legitimate and often necessary — but its disguise as a finding.

What held was the stop control written into the execution Mission: the Executor window read the source, measured the contradiction and stopped before any write, with no text wrongly modified. This Decision generalizes what worked.

## Impact

- Every arbitration table produced by the Pilot now carries a column or a mark of evidence status.
- Every Mission executing a `HYPOTHÈSE` line carries a named `STOP` before the write concerned, and the execution report cites the source read.
- Holds for all projects, whatever the window.

## Important alternatives

- Forbid `HYPOTHÈSE` lines in an arbitration table: set aside. It would require reading the whole corpus before any proposal, a prohibitive cost, and would push inference to hide instead of declaring itself.
- Carry this rule by amending the role charter rather than as a standalone Decision: set aside for now. A Vault Decision is normative by precedence; amending the charter would cost a reciprocal edit of a rule file and a push-then-re-pin cycle, for a gain in discoverability only. Carrying it over into the charter remains open as a distinct gesture.

## Accepted limit

No guardrail can check that a file has been read. Point 1 stays doctrinal and will drift if nothing recalls it. Only point 3 can be mechanized, because it lives in the text of a Mission that the Executor window applies and whose measurement it reports. It is the mechanized part that avoided the fault of 2026-08-29; the doctrinal part would not have been enough.

## Human gate

- Validation: granted
- Reference: « séparée » ["separate"], Owner, 2026-08-29, in answer to the question of where to place this rule.

## Linked artefacts

- Founding incident: (workshop history, not distributed)

## Liens

- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Relay between roles through mini-prompts with fixed rubrics](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Decision — CLOSE: tag and keyed doors of the journal](./DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
