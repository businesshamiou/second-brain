---
type: decision
title: "Execution report channel — report type, reports/ folder"
description: "Institutes an execution report as a file, of type report, in (workshop history, not distributed), staged with the work it proves."
created_at: 2026-08-21T00:02:36-04:00
timezone: America/Montreal
status: ARBITRATED
scope: executor-report-channel
owner_gate: granted
---

# DECISION — EXECUTION REPORT CHANNEL: REPORT TYPE, REPORTS/ FOLDER

## Context

The Executor has no channel to the Pilot: its report lived only in its chat window, and the Owner copied it over by hand. Since 2026-08-20, the Pilot reads the file system directly ("workshops" MCP server). A report written as a file becomes readable by the Pilot with no intermediary, and survives the closing of the window — what is not filed is lost.

The `audits/` folder exists but carries another intention: an audit measures a state at a point in time; a report accounts for an execution. Mixing them would blur both.

## Decision

This decision takes up, with no addition of substance, the points of the proposal (workshop history, not distributed) that it engraves:

**D1.** Every Executor Prompt requires an execution report **as a file**, in (workshop history, not distributed) (repository (workshop history, not distributed)).

**D2 — Naming.** `REPORT-YYYY-MM-DD-HHMMSS-NNN-executor-<slug>.md`; a `Cxx` correction gives `NNN-Cxx`.

**Amended on 2026-09-04** by [Decision 145256](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md): pattern aligned with measured usage (report 132, C6) — form retained `REPORT-<AAAA-MM-JJ>-<HHMMSS>-<mission_id>-<slug>.md`.

**D3 — Front matter.** `type: report`, `role: executor`, `mission_id`, `related_mission`, `related_prompt`, `status: FINAL`, `created_at` at the real mtime, `timezone`.

**D4 — Content, in this order.** Gates first · files created and modified · commit SHAs and messages · measured final state · deviations from the prompt · explicit stop. One page is the target. Raw outputs only for the measurements that prove something.

**D5 — Staging.** The report is staged **in the same commit** as the work it proves.

**D6 — Chat channel.** In chat, the Executor does not repeat the report: two lines, the file path and the "gates" line.

**D7 — Graph perimeter.** `reports/` belongs to the History / Evidence layer: excluded from the graph of (workshop history, not distributed) if such a graph comes into being.

**D8 — Registry.** MISSION-INDEX.md (hors Vault) gains a « Rapport actif » ["Active report"] column at its next touch-up. No retroactive rework of existing lineages.

## Reason

The cycle becomes readable at a glance: Mission (what we want) → Prompt (what we order) → Report (what happened) → Audit (what we re-measure afterwards, if needed). The report becomes committed evidence instead of a perishable text. The Owner stops being the courier between the two roles.

## Impact

One short file per Mission, negligible cost. First Prompts concerned: 020 and 019. The present report of Mission 020 is its first real use.

## Important alternatives

- Store the report in `audits/`: rejected, two different intentions.
- Store the report next to its Mission in `missions/`: rejected, one type per folder.
- `LOG`: rejected, evokes the transcript we want to avoid, and OKF reserves log.md.
- `RUN`, `EVIDENCE`, `RECEIPT`: rejected, jargon or meaning too broad.

## Human gate

- Validation: granted
- Reference: Owner/Pilot arbitration in the session of 2026-08-20, engraved by Mission 020 (MISSION-2026-08-20-234802-020-restore-semantic-graph-and-report-channel.md (workshop history, not distributed) (hors Vault)).

## Linked artefacts

- Source Proposal: PROPOSAL-2026-08-20-234824-execution-report-channel.md (workshop history, not distributed) (hors Vault)
- Mission that engraves this Decision: MISSION-2026-08-20-234802-020-restore-semantic-graph-and-report-channel.md (workshop history, not distributed) (hors Vault)

## Liens

- `source` — PROPOSAL-2026-08-20-234824-execution-report-channel.md (workshop history, not distributed) (hors Vault)
- `source` — MISSION-2026-08-20-234802-020-restore-semantic-graph-and-report-channel.md (workshop history, not distributed) (hors Vault)
- `applies` — missions/MISSION-INDEX.md (workshop history, not distributed) (hors Vault)
- `amended by` — [Decision — Amendment of two engraved norms](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)
