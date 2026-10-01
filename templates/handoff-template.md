---
type: handoff
title: "<subject of the handoff>"
created_at: "YYYY-MM-DDTHH:MM:SS±HH:MM"
timezone: America/Montreal
status: active
---

# HANDOFF — <subject>

This handoff is a dated historical handover, created to allow a reliable resume after an interruption or a transfer. It summarizes what is necessary and points to the sources without copying the whole project. Do not maintain it as a second current state.

A session with no Mission opened or closed, no RELAY and no Pilot artefact filed needs no handoff: it is a light close (`sb close --light`, the situations table of the `session-close` skill; Mission 244).

## Objective

<Result currently being pursued.>

## Current state

<Short snapshot of the situation at the moment of the handover.>

## Done

- <Item done and verified.>

## Active decisions

- Decision: `<relative path>` — <effect on the resume>

## Open points

- <Question, risk or hypothesis still open.>

## Recommended next action

<One precise, immediately executable action.>

## Constraints and prohibitions

- <Constraint to respect during the resume.>

## Artifacts to read first

1. Main source: `<relative path>`
2. State sheet: `<relative path to the project's state/STATE.md — the state_path of its Pilot prompt>`

## Executor closing command

<Mandatory (Mission 217). The command the Owner pastes into the Executor window to close the session: one code block, the five rubrics of rule 124937, naming THIS handoff by its relative path. A handoff filed without it is not filed (Pilot checklist, line 29), and `tools/check-session-close.sh` refuses the commit that brings the handoff in without its DIGEST and its `STATE:` line.>

```text
Session Executor — Close (<session>)

Position : free.

Source à appliquer : the `session-close` skill, Executor branch, on <relative path of this handoff>. CLOSE: exactly the doors that its §7 names; OPEN: the ones it says to open. STATE.md, DIGEST, register and indexes only.

Interdits absolus : no non-delegated git push, no model call, no deletion; move to `_trash/` only on a Mission's prescription; every write or push command names the absolute path of its repository, and a push goes through tools/verified-push.sh.

Sortie attendue : end the window with the RELAY block of rule 124937, filled in.
```

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amended by` — [Decision — State sheet, one name, generated](../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md)
- (to be completed: type — title — relative path, see the linking standard)
