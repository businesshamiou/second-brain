---
type: decision
title: "Amendment — a Mission file is frozen as soon as its snippet is issued"
description: "A Mission is no longer retouched in place from the moment its mini-prompt is handed to the Owner: the Pilot cannot observe when an Executor window opens, so the issuing of the snippet is the only observable freeze point; any evolution goes through a Cxx correction and a new snippet."
created_at: "2026-08-30T01:32:17-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: mission-lifecycle, pilot-conduct
amends: "../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md"
---

# DECISION — FREEZING OF A MISSION WHEN ITS SNIPPET IS ISSUED

## Date

2026-08-30

## Status

`ARBITRATED`

## Decision

1. **Freeze point.** A Mission file is frozen at the moment its consumption mini-prompt is handed to the Owner. From that moment, its text is no longer retouched in place, whatever the nature of the modification and even if it changes neither the objective, nor the scope, nor the criteria.
2. **Single path of evolution.** Any evolution of a frozen Mission goes through a `Cxx` correction, with its own timestamp, its `supersedes`, its reciprocal `superseded by`, and **a new snippet**. A Mission whose text has changed without a new snippet has not been communicated.
3. **Retouch already made.** If an in-place retouch has already happened, it is not undone by reflex. First measure which version the window read — the execution report says so — then record the gap. Undoing the text while a window is using it desynchronizes in the other direction.
4. **Unconsumed file.** A Mission file that has been filed but whose snippet has not yet been issued remains freely modifiable: it is not frozen, nobody has read it.

## Reason

The obvious freeze point would be the commit, or the start of execution. Neither is observable by the Pilot: it does not commit, and it does not see the Owner open a window. The only moment it controls is the issuing of the snippet. A freeze must be placed where the one who must respect it can observe it.

Two occurrences on 2026-08-30 showed it. The file of Mission 096 was modified when its execution had already started — the report bears 01:16:44, the retouch came after. The file of Mission 097 was modified while its window was open. In both cases the modification was minor and had no effect on the deliverable; in both cases the record would have shown a Mission whose text differs from the one that was executed, with no trace explaining the difference.

It is the same pattern as the other writing defects of that night: a constraint the Pilot believed it held through caution, and that no named moment held in place.

## Impact

- `RULES-2026-08-17-211522` receives a reciprocal `amended by` link: its section on corrections gains a named cutover moment.
- A `Cxx` correction stops being reserved for substantive changes: it becomes the only path for any modification after the snippet is issued.
- The cost is accepted: a typo in an issued Mission will now produce a complete `Cxx` correction rather than a silent retouch.
- The door `open-mission-internal-coherence` stays open and distinct: it carries the internal coherence checks of a Mission before issue, whereas the present Decision carries its immutability after.

## Important alternatives

- Freeze at the commit: rejected, the Executor window reads the file on disk, not the commit; an untracked file is already consumable.
- Freeze at the start of execution: rejected, this moment is observable neither by the Pilot nor by anyone other than the Owner, who does not have to signal it.
- Allow the retouching of typos only: rejected, the boundary between typo and change of meaning always shifts in the direction of whoever wants to retouch.

## Human gate

- Validation: granted
- Reference: « garder » ["keep"], Owner, 2026-08-30, after the misunderstanding at the origin of the filing was named and the three options — keep, withdraw, freeze — laid out.
- **Circumstance of the filing, recorded**: this Decision was filed on a misunderstanding. The Owner was asking for a corrective prompt to send into an open Executor window; the Pilot understood « amendement » ["amendment"] in the sense of an amendment of the Vault and engraved the present text without it having been requested. The validation above is later than this finding and bears on the content, not on the circumstance.

## Liens

- `amends` — [Versioning of Missions and generated outputs](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `see also` — [Relay between roles through mini-prompts with fixed rubrics](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Decision — Evidence status and stop control](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
