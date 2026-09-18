---
type: decision
title: "« Résumé » rubric in the RELAY block of the return direction"
created_at: "2026-08-23T18:05:00-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
amends: "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
---

# DECISION — « Résumé » rubric in the RELAY block of the return direction

## Date

2026-08-23

## Status

`ARBITRATED`

Arbitration formalized by Mission 036 (workshop history, not distributed).

## Decision

The RELAY block of the return direction of the [rule of relay between roles](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md) now has **six rubrics** instead of five. The new one, **Résumé** (summary), is inserted **before** « À trancher » (to be decided) (rank 5 of 6, between « Commits » and « À trancher »):

> **Résumé**: three to five lines. The figures that change a conclusion, any deviation from the protocol or from the Mission, and what surprised the Executor.

Three constraints attach to it:

1. **Facts, not assessments.** « Q5 en hausse » ["Q5 up"] is worth nothing; « Q5 : 12 décisions trouvées contre 7 » ["Q5: 12 decisions found versus 7"] is worth the whole rubric. A figure, a comparison, a named deviation.
2. **Ceiling of five lines, strict.** Beyond that, the rubric becomes a second report again and the cost it saves is paid back.
3. **Every deviation from the protocol or from the Mission appears in it**, even minor, even with no apparent consequence — it is the only place where the Pilot can see it without opening the report.

The outbound direction (the five rubrics of the mini-prompt, delivered as a snippet) is not touched.

**Principle behind the rubric**: the Pilot reads a full report only on explicit decision; the summary in the RELAY block is the default reading mode.

## Reason

Measurement of the defect, made on 2026-08-23 on Mission 033: the RELAY announced « Q5 en hausse » ["Q5 up"]. The end-of-window summary, passed on separately by the Owner, said that condition C3 had found twelve decisions versus seven — the only concrete deviation in the whole measurement, invisible in the five-rubric RELAY. Two other decisive facts were also missing: cost and duration halved, and a possible breach of the protocol (« fenêtre persistante » ["persistent window"]) that the RELAY did not flag.

Consequence of the defect: the Pilot had either to open the full report — costly, several thousand words that stay in its window — or to reason on incomplete information. Neither is an acceptable default mode. The report remains filed on disk and readable; what was missing was a summary rich enough for reading the report to become the exception, decided case by case rather than endured.

## Impact

- `vault/rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md` now carries six rubrics in the RELAY block of the return direction, the new one before « À trancher », with its three constraints.
- `vault/templates/report-template.md` carries the same rubric at the same rank, with its one-line instruction and its ceiling, in the RELAY block of the report template.
- Every future Mission whose report ends with a RELAY block carries the Résumé rubric, facts and figures only, five lines at most.
- Mission 036, which engraves this Decision, itself applies the rubric in its own RELAY block (see its report).

## Important alternatives

- Leave the RELAY block at five rubrics and rely on the Pilot to open the full report at every potential deviation: rejected, this is precisely the costly default mode that the defect found on Mission 033 revealed as insufficient.
- Résumé rubric with no line ceiling: rejected, a rubric free in length becomes a second report again and cancels the cost gain it is meant to bring (§2 of the Mission).
- Résumé rubric based on qualitative assessments (« Q5 en hausse » ["Q5 up"]) rather than on figured facts: rejected, this is exactly the measured defect — an assessment does not allow the Pilot to tell a minor deviation from a decisive one without opening the report.

## Human gate

- Validation: granted
- Reference: Mission `036`, `AUTHORIZED` by the Owner (MISSION-2026-08-23-174203-036-relay-summary-rubric.md).

## Linked artefacts

- Execution Mission: (workshop history, not distributed)
- Rule amended: `../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md`
- Template amended: `../templates/report-template.md`
- Source measurement of the defect: (workshop history, not distributed)

## Liens

- `amends` — [Relay between roles through mini-prompts with fixed rubrics](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Outbound direction of the relay as a snippet, and superseded list outside the graph but versioned](./DECISION-2026-08-23-155831-relay-forward-snippet-and-superseded-list-graph-exclusion.md)
- `see also` — Mission 036 — « Résumé » rubric imposed on the RELAY block (workshop history, not distributed) (hors Vault)
