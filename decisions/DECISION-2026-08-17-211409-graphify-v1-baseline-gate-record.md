---
type: decision
title: "Arbitration of the Vault's Graphify V1 baseline"
created_at: 2026-08-17T21:14:09-04:00
timezone: America/Montreal
status: ARBITRATED
scope: vault-graphify-baseline
source_audit: "../audits/AUDIT-2026-08-17-165250-graphify-v1-vault-baseline.md"
related_mission: "../missions/MISSION-2026-08-17-211122-004-graphify-v1-vault-baseline.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-17-211409-graphify-v1-baseline-gate-record.md"
---

# DECISION — ARBITRATION OF THE GRAPHIFY V1 BASELINE

## Status

**ARBITRATED — human gate historically granted by the Owner / Pilot.**

This decision records the arbitration without rewriting proposal `163400`.

## Decision

The Graphify V1 baseline of the Vault alone is authorized within the limits of Mission 004: standard mode, Vault boundaries, no hook, MCP, watch, deep mode, global graph, source modification, staging, commit or push.

## Execution state

The first execution stopped with `NEEDS_OWNER_INPUT` because Graphify was missing. This interruption does not end Mission 004.

Mission `007-C01` then made `graphify 0.9.26` available according to audit `174601`. Mission 004 remains `READY_TO_RESUME` since its preflight; the tool's availability is not evidence that the baseline was executed.

**Note (2026-08-26, Mission 065)**: this `READY_TO_RESUME` state is outdated twice over — `MISSION-INDEX.md` has recorded since Mission 004-C02 the `COMPLETED` status of this lineage, and Graphify was taken out of the "Vault graph" role and then entirely eradicated (Mission 040, 2026-08-24). Kept for historical reading, not corrected in place.

## Impact

- proposal `163400` remains historical and unchanged;
- the active Mission is `004`;
- any execution must re-measure the real state;
- the baseline results will require a new human gate.

## Liens

- `amends` — DECISION-2026-08-17-163400-graphify-v1-vault-baseline — Graphify V1 — separate baseline of the Vault (workshop history, not distributed)
- `amended by` — [Withdrawal of Graphify from the "Vault graph" role](../../../vault/decisions/DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md) (hors l'atelier (historique, non distribué))
