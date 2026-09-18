---
type: decision
title: "Extension of the journal tag convention — CLOSE: tag and keyed doors"
created_at: "2026-08-25T11:09:35-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: granted
amends:
  - "DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md"
  - "../rules/RULES-2026-08-23-220049-activity-classification-and-system-keywords.md"
related_mission: "051"
---

# DECISION — EXTENSION OF THE JOURNAL TAG CONVENTION: `CLOSE:` TAG AND KEYED DOORS

## Date

2026-08-25

## Status

`ARBITRATED`

Arbitration: Owner/Pilot session of 2026-08-25, line by line on the closures, keys and freezes (« je valide go » ["I validate, go"]), executed by Mission 051 (workshop history, not distributed).

## Decision

1. The tag `CLOSE: <clé> -- <référence>` is added to the journal tag convention ratified by the [Decision of 2026-08-23-143542](./DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md).
2. Every door is now written one-door-one-line-one-key: key `open-*` or `frozen-*`, in English kebab-case, followed by ` -- ` then the text.
3. The state displayed by the sheet is the net: last `OPEN:` per key, minus a later `CLOSE:` of the same key.
4. Legacy `OPEN:` lines with no key, earlier than the baseline of 2026-08-25, are excluded from the sheet and counted in a single line; the journal is never rewritten.
5. Closures F1–F6 of the baseline of 2026-08-25:
   - **F1** — check-links active on the workshop (history, not distributed) (Mission 049).
   - **F2** — non-executable skip defect fixed (Missions 046/049).
   - **F3** — repositories pushed and outdated list (push of 2026-08-24).
   - **F4** — graphify PreToolUse hooks removed (2026-08-24T11:23).
   - **F5** — wording "Graphify verdict suspended until batch B" dead: batch B was executed and Graphify eradicated (Mission 040); the freeze survives under the key `frozen-graphify-verdict`.
   - **F6** — numbering gap 047 accepted.

## Reason

The state sheet displayed the union of all sessions, with no closure or deduplication: a need demonstrated on 2026-08-24/25 (11 entries of which at least 4 outdated, one item repeated four times), not anticipated at the initial ratification of the tags.

## Impact

- `vault/tools/build-state.sh` recognizes `CLOSE:` as a closure and computes the net state per key; `OUVERT:`/`OPEN:` remain recognized on reading for the history, new writes use `OPEN:`/`CLOSE:`.
- The arbitrated baseline (13 doors) is engraved in the journal of (workshop history, not distributed) in Mission 051, step 5.
- Historical journal lines are neither rewritten nor deleted.

## Important alternatives

- Rewrite or deduplicate the existing journal: set aside, the journal is append-only by structural constraint of the Vault.
- Close the legacy doors with retroactive `CLOSE:` lines one by one: set aside, none of these lines carries a conforming key; they are counted as legacy rather than formally closed.

## Human gate

- Validation: granted
- Reference: line-by-line arbitration by the Owner, Pilot session of 2026-08-25 (« je valide go » ["I validate, go"]), executed by Mission 051.

## Linked artefacts

- Execution Mission: (workshop history, not distributed)

## Liens

- `amends` — [Decision — Pilot contract, marking of superseded documents, and ratification of the journal tag convention](./DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md)
- `amends` — [PIV activity classification and system keywords](../rules/RULES-2026-08-23-220049-activity-classification-and-system-keywords.md) (§7, list of tags — Mission 066)
- `see also` — Mission 051 — Purge of the open doors, CLOSE tag, index caught up (workshop history, not distributed) (hors Vault)
