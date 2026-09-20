---
type: rules
title: "PIV activity classification and system keywords"
description: "Taxonomy of activity types (plan / implement / validate), session dimension (open / milestone / close), announcement format, perimeter of the \"system keywords in English\" rule and language of the journal."
created_at: 2026-08-23T22:00:49-04:00
timezone: America/Montreal
status: active
scope: activity-classification-and-system-keywords
related_mission: "038"
---

# PIV ACTIVITY CLASSIFICATION AND SYSTEM KEYWORDS

## 1. Reach

This rule applies to every Pilot and Executor session, in the Vault and in every project. It implements the [Decision: PIV taxonomy and English system language](../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md), arbitrated by the Owner.

## 2. Taxonomy of activity types

Three types, drawn from the PIV loop (Plan–Implement–Validate). [source: Cole Medin, PIV loop, https://github.com/coleam00/skills]

| Type | Activity | Typical artefacts |
|---|---|---|
| `plan` | explore, compare, decide, frame | captures, proposals, decisions, missions, prompts |
| `implement` | produce, integrate, execute | master content, commits, Executor runs |
| `validate` | test, measure, check | audits, reports |

Brainstorming and divergent research live in `plan`. Pure reading (finding, checking a fact) is not a type: it is classified in the phase it prepares.

## 3. Session dimension

A second dimension, independent of the type: `open` / `milestone` / `close`. It can coexist with any type. The `wrap` command triggers `close`.

## 4. Announcement

The AI announces the classification in one short line, at the head of the sequence: `[<type> · <session>]` followed by a sentence in French. The session marker is optional outside an opening, a milestone or a close.

- Example: `[plan · milestone] taxonomie arbitrée, on rédige la Mission` [“taxonomy arbitrated, we are writing the Mission”].
- The Owner corrects with one word; the correction is authoritative, with no justification asked for.
- Neither silent classification, nor a request for confirmation before moving on.
- A micro-check does not trigger an announcement.

## 5. Classifying is not filing

The classification is informative. It opens no write right: any filing of a file remains an announced door, in accordance with the [Guardrails and evidence levels](./RULES-2026-08-19-210803-guardrails-and-evidence-levels.md).

## 6. System keywords: perimeter and language

A **system keyword** is any string read or compared literally by a script, or serving as a structured label: commands (`wrap`), journal tags, classification labels (`plan`, `implement`, `validate`, `open`, `milestone`, `close`), statuses, field identifiers.

Every system keyword is in **idiomatic English, without accents**. Announcements, prose and documents intended for the Owner remain in French.

## 7. Language of the journal

Journal lines are from now on written **entirely in English** — tags and content. Tags: `STATE:`, `NEXT:`, `OPEN:`, `RESUME:`.

**Note (2026-08-26, Mission 066)**: this enumeration has since been extended — the `CLOSE:` tag was added by [DECISION-2026-08-25-110935](../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md); the list of tags is extended by Decision, never by silent editing of this paragraph.

**Note (2026-09-20, Mission 203)**: a measurement line, `PHASE:<name>:<debut|fin>`, may be appended to a project journal by `tools/append-journal.sh` at each boundary of a piece of work (the Owner asked, on 2026-09-20, to measure where the minutes of a Mission go). The name is one word (`lecture`, `preflight`, ...); the closed pair `debut` / `fin` is spelled as the reader expects it. It is not a state tag: `tools/build-state.sh` ignores it, as it ignores any line with no recognised tag. `tools/phase-report.sh <project>` reads the last run (from the last opening of its first phase) and renders `phase | debut | fin | secondes`; it refuses a phase opened before the previous one is closed, a phase opened twice, and a closing without an opening. Whether the list of state tags itself should grow is left to a Decision, as the note above requires.

- The journal is append-only: the historical French lines (`ETAT:`, `PROCHAIN:`, `OUVERT:`, `REPRISE:`) are never rewritten.
- The reading tools recognize both sets of tags.
- Documents intended for the Owner (state sheet, handoffs, Decisions) remain in French.

## 8. Extensibility

If a real case fits no type during use, it is noted in the journal (`OPEN:`) and this rule is amended through the normal cycle — never a silent extension of the taxonomy.

## Liens

- `applies` — [Decision: PIV taxonomy and English system language](../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md)
- `see also` — [Vault operating rules](./RULES-2026-08-17-005717-vault-operating-rules.md)
- `see also` — [Relay between roles through mini-prompts](./RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amended by` — [Decision — Extension of the journal tag convention — CLOSE: tag and keyed doors](../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
