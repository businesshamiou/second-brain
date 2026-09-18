---
type: decision
title: "Amendment — one Owner authorization line covers a single gesture"
description: "Amends DECISION-154553 (delegated push): a verbatim Owner authorization line never covers more than one gesture; any merging of gestures in one line counts as refusal of the merged gestures; the template is checked before execution, fail closed."
created_at: "2026-08-26T23:16:17-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md"
---

# DECISION — ONE AUTHORIZATION LINE = ONE GESTURE

## Date

2026-08-26

## Status

`ARBITRATED`

## Decision

A verbatim Owner authorization line, whatever template it serves (delegated push of `DECISION-154553` or any future template of the same type), covers **only one gesture**. If a line merges several distinct gestures in one sentence (e.g. deletion and push), **only the gestures covered by the exact recognized template are executable**; any additional gesture merged into the same line, without its own recognized template, counts as **refusal** of that specific gesture — it is never inferred from the presence of a neighbouring template in the same sentence. The authorization template is checked **before** the execution of the gesture it covers, never after the fact: fail closed, in accordance with the anti-accident threat model (§3.2 of `DECISION-232341`, hors Vault).

## Reason

Incident `RELAY PUSH-067` (2026-08-26): the authorization line pasted by the Owner merged a deletion order and the push order into a single sentence, without reproducing identically the push-only template of `DECISION-154553` (the push clause lost its own « j'ordonne » ["I order"], interleaved after the deletion clause). The Executor executed the push **before** checking this template against the text of the Decision, noticed it after the fact and reported it without hiding it (journal, `open-mot-exact-push-suppression-blend`); it did on the other hand **refuse** the deletion in the name of its own operating policy — conduct held up as exemplary, no merged gesture having been executed without a recognized template. The push was ratified by the Owner because its intent was explicit and its content sound (commits of Mission 067 already reviewed). This Decision engraves the lesson to prevent repetition: the next incident of the same pattern could bear on a gesture whose content is less harmless.

## Impact

- `DECISION-154553` receives an amendment, in the same repository: its push-only template stays unchanged in its form, but its application is now bounded by the general rule "a single gesture per line" — a line that mixes the push template with any other order validates only the push, never the other order, and only if the push template is reproduced identically in it.
- Reciprocal `amended by` link placed on `DECISION-154553` in this same commit (repair of the blockage of Mission 068, step 2: the previous version, written in (workshop history, not distributed), had been refused by the reciprocity guardian because it could not write the reciprocal link in `vault`).
- Check moved **before** execution: any Executor faced with an authorization line must locate and reread the text of the Decision that defines the template concerned before acting, not after.
- Closes `open-mot-exact-push-suppression-blend` (see journal line `CLOSE:`, Mission 069).

## Important alternatives

- Require that no authorization line carry **any** additional free text, even after the date: rejected — `DECISION-154553` already explicitly authorizes free text after the date for the covered gesture; the problem is not additional text as such, but the merging of several distinct gestures without a template of their own for each.
- Let the Executor judge case by case whether a merge is "substantially" covered: rejected — that is exactly the after-the-fact reasoning that produced the incident; the rule must decide before the gesture, not after.

## Human gate

- Validation: granted
- Reference: Mission `069` (exact word « je valide tout, dépose 069 » ["I validate everything, drop 069"], 2026-08-26), which repairs the engraving blocked at step 2 of Mission `068`; the source incident is `RELAY PUSH-067` (chat, 2026-08-26, following Mission 067).

## Linked artefacts

- Amended Decision: `DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md`.
- Source incident: `RELAY PUSH-067` (chat, 2026-08-26).
- Source Mission: (workshop history, not distributed) (hors Vault); previous blocked attempt: (workshop history, not distributed) (hors Vault).

## Liens

- `amends` — [Decision — Delegated push becomes a rule](./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)
- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — Mission 069 — Distribution repairs and repaired engraving (workshop history, not distributed) (hors Vault)
- `amended by` — [Decision — Relay and delegation, one rule in one place](./DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
