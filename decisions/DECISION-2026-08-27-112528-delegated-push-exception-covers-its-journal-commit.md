---
type: decision
title: "Amendment — the delegated push exception covers the commit of its own journal line"
description: "Amends DECISION-154553: the delegated push exception now authorizes the writing AND the commit of its journal line, nothing else; the perimeter of gestures stays unchanged for everything else."
created_at: "2026-08-27T11:25:28-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md"
---

# DECISION — THE DELEGATED PUSH EXCEPTION COVERS THE COMMIT OF ITS JOURNAL LINE

## Date

2026-08-27

## Status

`ARBITRATED`

## Decision

The delegated push exception (`DECISION-2026-08-26-154553`) now covers, in addition to the writing of the closing journal line, **the commit of that line alone**. The added gesture is strictly bounded: a `git add` bearing only on `<projet>/state/journal.md`, then a commit bearing only on that file. Nothing else is added to the perimeter: `git status -sb` (before/after), `git push` on `main` only, no `add` of any other file, no deletion, no `--force` remain, as before, the only other gestures covered. The verbatim authorization template and its reach limited to a single gesture (`DECISION-2026-08-26-231617`) stay unchanged.

## Reason

Three dated occurrences of 2026-08-27 (sixth, seventh and eighth delegated pushes of the journal, measured at the opening of Mission 072) showed the same design defect: the exception authorized the writing of the line but not its commit, systematically leaving state/journal.md modified and uncommitted after each delegated push — each one reported by the Executor under the « À trancher » rubric of its RELAY block without any rule remedying it. A fourth occurrence (ninth delegated push, `2026-08-27T11:18:19-04:00`) occurred one minute after Mission 072 was written, during the push instruction that preceded this window — it was not measurable when the Mission was written, but confirms the same pattern once more. An exception repeated without being named drifts — the very motive of `DECISION-154553`, here applied to its own design defect rather than to an external pattern.

## Impact

- `DECISION-154553` receives an amendment, in the same repository: its verbatim template and its perimeter of gestures stay unchanged in their form; the exception now covers one more gesture, bounded to a single file (`<projet>/state/journal.md`) and a single commit.
- Reciprocal `amended by` link placed on `DECISION-154553` in this same commit.
- No change to `DECISION-2026-08-26-231617` (one line = one gesture): this Decision adds a gesture covered by the same authorization template; it does not change the no-merge rule.
- `open-delegated-push-journal-commit` is closed by this batch (Mission 072, step 6): the three (then four) measured occurrences stop recurring for any future delegated push.

## Important alternatives

- Extend the exception to a commit covering `<projet>/state/journal.md` **and** any other file modified at the same time: rejected — would widen the perimeter well beyond the measured defect (a single orphan journal line), contradicts the doctrine "one authorization line, one bounded gesture" of `DECISION-231617`.
- Let a later Mission absorb the orphan line each time, without amending the exception: rejected — that is exactly the pattern repeated four times that motivates this engraving; letting a fifth occurrence slip by brings nothing more than a fifth report.

## Human gate

- Validation: granted
- Reference: Mission `072` (exact word « Rédige la Mission 072 : les deux R1, l'amendement de 154553, la ligne de journal de la porte fantôme » ["Write Mission 072: the two R1s, the amendment of 154553, the journal line of the phantom door"], 2026-08-27), which prescribes this engraving.

## Linked artefacts

- Amended Decision: `DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md`.
- Source occurrences: journal (workshop history, not distributed), lines of 2026-08-27 (sixth, seventh, eighth and ninth delegated pushes). (hors Vault)
- Source Mission: (workshop history, not distributed) (hors Vault).

## Liens

- `amends` — [Decision — Delegated push becomes a rule](./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)
- `see also` — [Decision — One Owner authorization line covers a single gesture](./DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md)
- `see also` — Mission 072 — Clean-up batch (workshop history, not distributed) (hors Vault)
