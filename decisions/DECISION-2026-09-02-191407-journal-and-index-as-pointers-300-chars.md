---
type: decision
title: "Decision — Journal and index as pointers: every line ≤ 300 characters, the narrative lives in the document pointed to"
created_at: "2026-09-02T19:14:07-04:00"
timezone: America/Montreal
status: active
description: "Every future line of the journal and of the Mission indexes is a pointer (date, tag, one sentence, file name) capped at 300 characters; the detail lives in the report, capture or handoff pointed to. Enforceable by a guardian."
---

# DECISION — Journal and index as pointers (≤ 300 characters per line)

## Context

Mission 120 measured that the cost of opening a Pilot session comes first from the size of the lines, not from the number of files: journal lines of 3 to 5,000 characters, a Mission index line at ~2,500 characters, 55,969 bytes prescribed at opening. Mission 121 created a capped digest that truncates these lines on reading; it relieves the Pilot but does not change the source, which the Executor, the guardians and the memory layer (Mission 122) continue to read in full. A capped rule already exists for a single line — the closing `STATE:`, ≤ 300 characters — but it is checked by the Executor on a Mission instruction, not by a guardian: no script today refuses a line that is too long (measurement: reports 121 and 122 declare the length, no guardian enforces it). This Decision extends it to all lines and requires its mechanization.

## Decision (Owner, chat, 2026-09-02)

1. **The line is a pointer; the document pointed to is the narrative.** Every line added to the project's journal (file journal.md of the state folder) and every entry line of the project's Mission index (file MISSION-INDEX.md of the missions folder) carries: timestamp, tag, a one-sentence summary, and the name of the file where the detail lives. Measurements, lists, tables, justifications live in the report, capture, handoff or Decision pointed to — never in the line.
2. **Cap: 300 characters per line**, journal and index, aligned with the existing rule for the closing `STATE:` line.
3. **Not retroactive.** The journal is append-only; existing lines are neither rewritten nor truncated. The rule applies to lines added after this Decision is engraved.
4. **Mandatory mechanization.** A rule written without a guardian drifts: the cap is enforced by a fail-closed stop in the existing mechanism (`tools/append-journal.sh` for the journal, `tools/check-indexes-fresh.sh` for the Mission index), delivered by a separate Mission. As long as the stop is not delivered, the rule is an author instruction, and the RELAY flags any line that exceeds it.
5. **Reach**: (workshop history, not distributed) first; the rule is a Vault mechanism (distributable guardian), not a local convention.

## Consequences

- Mission to be drafted: guardian "line ≤ 300 characters" on journal and index, fail-closed, wired to the pre-commit of (workshop history, not distributed) via a revision pin (two pushes minimum).
- The `écriture-de-mission` skill and the `session-close` skill take up the rule in their checklists (a Mission's index line is drafted as a pointer).
- The opening digest (Mission 121) keeps its truncation at 300 characters: intended redundancy, it stays correct on the old lines.

## Liens

- `source` — Report 120 — audit of the state loop (workshop history, not distributed) (hors Vault)
- `see also` — Mission 121 — capped opening digest (workshop history, not distributed) (hors Vault)
- `see also` — [Decision — CLOSE: tag and keyed doors of the journal](./DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
- `applies` — [Decision — Evidence status and STOP control](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
