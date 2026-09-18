---
type: decision
title: "Opening directory of a session — revocation of the position constraint, requirement of position awareness"
created_at: "2026-08-25T21:31:50-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-25-213150-session-opening-directory-freed.md"
---

# DECISION — OPENING DIRECTORY OF A SESSION

## Date

2026-08-25

## Status

`ARBITRATED`

Arbitrated in session by the Owner on 2026-08-25, in a Pilot session `plan · open`, following the stop at the preconditions of Mission 056.

## Decision

1. **Revocation.** The constraint "every Executor session always opens in the Vault, never elsewhere" is revoked. It currently appears in the role charter, §3, rubric "Opening", and in several derived pieces; the present Decision deprives it of effect from its date.

2. **Free position.** A session may open anywhere in the workspace, and typically opens in the folder of the project under development. The starting directory is no longer a precondition, can no longer ground a stop, and must no longer be checked as such.

3. **Position awareness required.** What is required is no longer a position but a capability, in four points, to be established at opening:
   - determine its current directory;
   - identify the repository in which this directory lies, or note that it lies in none;
   - reach the sibling repositories through a relative path, and change directory when needed;
   - run every Git operation in the repository concerned by the gesture, never by default in the one of the starting directory.

4. **Project business rules.** They stay in their project's folder and are read after locating it through the Vault or the registry, unchanged.

5. **What the charter must say.** The role charter must be amended to carry points 2 to 4 in place of the revoked wording. **This amendment is not executed by the present Decision**: modifying an existing rules file is an Executor gesture, and the Owner arbitrated that the audit comes before any correction.

## Reason

The position constraint answered a real motive — guaranteeing that the session knows how to reach the Vault and its rules. This motive is now satisfied otherwise: the agent knows how to locate itself and move, and the work mostly takes place in the folder of the project under development, which made the constraint both artificial and costly.

The stop of Mission 056 made this cost visible: an otherwise correct session was blocked by a precondition whose motive had been abandoned but whose text remained active.

## Impact

- The precondition "session opened in `vault`" disappears from upcoming Missions and must be removed from the correction of Mission 056.
- The role charter `RULES-2026-08-23-224706` §3 becomes **partially outdated** as long as the amendment of point 5 is not executed. Any session reading this charter until then must hold §3 "Opening" as revoked.
- **Accepted loss.** A mechanically verifiable constraint is traded for a behavioural requirement. The control becomes more flexible and less provable. The trade is accepted knowingly.
- **Point not arbitrated, material for audit 057.** This episode is the third occurrence in one day of the same pattern: an engraved rule survives the abandonment of its motive, for lack of a gesture that amends the source text at the time of the revocation. The advisability of engraving a general obligation — every Decision that revokes amends the text it revokes — is not decided here and awaits the audit's measurements.

## Important alternatives

- **Keep the constraint.** Rejected: its motive is extinct and its cost is demonstrated.
- **Weakened constraint — open in a Git repository, never at the root of the workspace.** Set aside at this stage in favour of the entirely free position; remains reopenable if a session outside a repository causes a real incident.

## Human gate

- Validation: granted
- Reference: arbitration in session by the Owner, Pilot session of 2026-08-25, following RELAY 056.

## Linked artefacts

- Stop that revealed the gap: `../reports/REPORT-2026-08-25-210526-056-executor-case-study-pivot-engraving-STOP.md`
- Rule to amend: `../../../vault/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md`

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amends` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — Stop report of Mission 056 (workshop history, not distributed)
