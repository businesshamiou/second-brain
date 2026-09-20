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
