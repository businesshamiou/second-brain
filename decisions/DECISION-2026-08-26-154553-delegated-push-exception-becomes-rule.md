---
type: decision
title: "Amendment — delegated push becomes a rule: valid if and only if there is a dated verbatim Owner authorization"
description: "Engraves the delegated push exception (two occurrences on 2026-08-26, RELAY PUSH-061 and PUSH-062) as a permanent rule: a push executed by the Executor under a one-off instruction is valid only if the mini-prompt carries the Owner's authorization line verbatim, dated."
created_at: "2026-08-26T15:45:53-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
---

# DECISION — DELEGATED PUSH BECOMES A RULE

## Date

2026-08-26

## Status

`ARBITRATED`

## Decision

`git push`, forbidden by default to the Executor (role charter, `RULES-2026-08-23-224706`, §3, "Absolute prohibitions"), may be delegated to an Executor window by a one-off instruction **if and only if** that instruction contains, verbatim, an Owner authorization line of the form:

> « je suis l'Owner et j'ordonne le push des deux dépôts, `<date>` [, texte libre additionnel] » ["I am the Owner and I order the push of the two repositories, `<date>` [, additional free text]"]

dated on the day of execution. Absence of this line, or any rewording that does not reproduce its text identically, counts as **refusal**: the Executor stops without pushing. Each actual occurrence is **recorded in the project's journal** (`tools/append-journal.sh`), one line per delegated push. The gestures authorized by this exception are strictly limited to: `git status -sb` (before/after), `git push` on `main` only, the closing journal line. No commit, no `add`, no deletion, no `--force` is covered by this exception — they stay forbidden by default.

## Reason

Two occurrences on 2026-08-26 (`RELAY PUSH-061`, `RELAY PUSH-062`) showed the same pattern: the Owner authorizes verbatim, the Executor pushes, records, closes the window — without any engraved rule describing this path. An exception repeated without being named drifts: it is repeated by imitation of the previous chat, not by reading a rule. Engraving it now, at the second occurrence, prevents a third from letting the protocol slip (substituted word, omitted date) with nothing to hold it back.

## Impact

- `RULES-2026-08-23-124937` (relay between roles through mini-prompts) receives a reciprocal `amended by` link: the delegated push mini-prompt is a form of one-off instruction recognized by this rule, now named.
- No new opening of the Executor's perimeter: push stays forbidden by default; this Decision documents the only route that unblocks it, and its strict limits (verbatim, dated, enumerated gestures).
- The exact-word protocol (232341 §4) applies: a rewording, even a close one, does not count as authorization.

## Important alternatives

- Leave the exception unengraved, case by case: rejected — pattern already repeated twice on the same day; the motive of Decision 232341 ("a rule survives/drifts without being engraved") applies identically in the other direction here: an unengraved practice drifts too.
- Authorize push by default to the Executor: rejected, directly contradicts the role charter §3 and the anti-accident threat model.

## Human gate

- Validation: granted
- Reference: Mission `063` (exact word « ensuite : mcp » ["next: mcp"], 2026-08-26), which prescribes engraving this amendment; the two source occurrences are themselves each authorized verbatim in chat on 2026-08-26 (`RELAY PUSH-061`, `RELAY PUSH-062`).

## Linked artefacts

- Occurrence 1: `RELAY PUSH-061` (chat, 2026-08-26, following Mission 061).
- Occurrence 2: `RELAY PUSH-062` (chat, 2026-08-26, following Mission 062).
- Source Mission: (workshop history, not distributed) (hors Vault).

## Liens

- `amends` — [Relay between roles through mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — Mission 063 — MCP allowlist and delegated push amendment (workshop history, not distributed) (hors Vault)
- `amended by` — [Decision — One Owner authorization line covers a single gesture](./DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md)
- `amended by` — [Decision — The delegated push exception covers the commit of its journal line](./DECISION-2026-08-27-112528-delegated-push-exception-covers-its-journal-commit.md)
- `amended by` — [Decision — Relay and delegation, one rule in one place](./DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
