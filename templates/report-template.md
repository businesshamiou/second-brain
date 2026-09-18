---
type: report
title: "Execution report — Mission <NNN>"
created_at: "YYYY-MM-DDTHH:MM:SS±HH:MM"
timezone: America/Montreal
mission_id: "<NNN>"
role: executor
related_mission: "<chemin relatif vers la Mission>"
related_prompt: "<chemin relatif vers le Prompt>"
status: FINAL
---

# EXECUTION REPORT — MISSION <NNN>

## 1. Gates

- Push: <done | not done>, in <which repository>.
- <Other gate measured: system version, model call, guardrail touched or not.>

## 2. Files created and modified

**Vault:**
- <Created | Modified>: `<relative path>`

**\<project\>:**
- <Created | Modified>: `<relative path>`

## 3. Commits

- Vault: `<SHA>` — "<message>"
- \<project\>: `<SHA>` — "<message>"

The SHA of the Vault commit and the final `git status -sb` are measured **before** this report is staged. The SHA of the project commit that contains this report cannot be known before that commit (the report would reference itself); it is given in the chat, never left as an empty placeholder here.

## 4. Impact on the installation

<System, environment or runbook change, or "No change".>

## 5. Final state measured

<Direct measurement, backed by a command, distinguished VERIFIED / DECLARED according to the levels of proof.>

## 6. Deviations

- <Deviation from the Prompt, or "No deviation".>

## 7. Final remeasurement, stop

```
<remeasurement command and result>
```

This remeasurement is made **before** this report is staged, never left as a placeholder of the "filled in after commit" kind. No `<…>` placeholder may remain in a final report.

Mission stopped here.

## RELAY block

This block is filled in **last** and displayed **as it is** at the end of the Executor window, following the fixed grammar (rubrics, including `Poussées`, and the five-line cap for `Résumé`) of the [rule of relay between roles, RULES-2026-08-23-124937](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md) — the single source of that grammar (`DECISION-2026-09-17-201623`, part B1): neither the rubrics nor the number of lines are restated here.

## Liens

- `prescribed by` — [Execution report channel](../decisions/DECISION-2026-08-21-000236-execution-report-channel.md)
- `prescribed by` — [Relay between roles through mini-prompts with fixed rubrics](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Decision — « Résumé » rubric in the RELAY block of the return direction](../decisions/DECISION-2026-08-23-180500-relay-summary-rubric.md)
- `amended by` — [Decision — Relay and delegation, one rule in one place](../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
- (to be completed: type — title — relative path, see the linking standard)
