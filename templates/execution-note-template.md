---
type: note
title: "<what the gesture does, in one line>"
description: "<one sentence: the gesture and its result>"
created_at: "YYYY-MM-DDTHH:MM:SS±HH:MM"
timezone: America/Montreal
regime: light
scope: <slug-kebab-case>
---

# NOTE — <TITLE>

<!-- The light regime, for a gesture that meets none of the full-regime criteria: `tools/check-work-regime.sh note <this file>` must answer REGIME-LIGHT-OK BEFORE the gesture, and `tools/check-work-regime.sh diff <repo> <range>` after it. A refusal sends the gesture to a Mission (mission-template.md). The six rubrics below, in this order, and nothing else but a final Liens rubric; at most 4000 characters. The proofs stay (measure before, measure after); what falls is the long Context, the commit simulation, the two passes and the multi-page report. Filed in the project's missions/ folder as NOTE-<YYYY-MM-DD-HHMMSS>-<slug>.md; never a row of the Mission register: its trace is the journal line. -->

<!-- Mode 2 (Decision 012500): when the Note is written by the Executor from a prompt of the Owner, it is the Executor's FIRST write, and its front matter adds four lines after `scope:` — `origin: owner-prompt`, `mode: 2a` (the prompt pasted as is) or `mode: 2b` ("read <files> and execute"), `received_at: "<real time the prompt arrived, ISO 8601 with offset>"`, and for 2a `prompt_sha256: <sha256 of the prompt text, LF line ends, no final newline>`. The Intent then holds, for 2a, the prompt verbatim in one fenced block whose info string is `prompt`; for 2b, one fenced block whose info string is `files`, one line `<sha256> <path>` per consumed file, the path relative to the project root. `tools/check-work-regime.sh note` refuses a mode-2 Note whose origin, mode, time, prompt, files or fingerprints do not hold (R8-origin); the verbatim prompt block is not counted in the cap. The report ends with `RELAY NOTE-<YYYY-MM-DD-HHMMSS>` (rule 124937). -->

<!-- The Owner's go-ahead (Decision 105507): when the Owner's prompt meets a full-regime criterion, `check-work-regime.sh note` refuses and says to ask the Owner. Ask; then add to the Intent, after the prompt block, exactly one fenced block whose info string is `owner_greenlight`: a line `at: <real time of the answer, ISO 8601 with offset>`, a line `lifts: <criterion id>[, <criterion id>...]` (R1-egress..R6-guardians, only those the answer covers), then the Owner's answer as received. The check lifts only the criteria named, never the form; the block is not counted in the cap. -->



## Intent

<One or two sentences: what is done, and why now.>

## Scope

- <One path or repository written per line; nothing outside these lines is touched.>

## Measure before

```
<command that measures the state before the gesture>
```

<What it returned, in figures.>

## Gesture

```
<the exact commands, one per line, as they will be run>
```

## Measure after

```
<the same command(s) as before>
```

<What they returned, before → after in figures.>

## Journal line

```
STATE: <one line, at most 300 characters, figures included>
```

## Liens

- `prescribed by` — [Two work regimes: the light Note and the full Mission](../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)
- `see also` — [Mission template](./mission-template.md)
- `amended by` — [Decision — Two relay modes](../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md) (mode 2: the Note written first by the Executor)
- `amended by` — [Decision — The Owner's go-ahead quoted in the Note; a local language file](../decisions/DECISION-2026-09-23-105507-owner-greenlight-in-note-and-local-language-file.md) (the `owner_greenlight` block)
