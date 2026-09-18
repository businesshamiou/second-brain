---
type: decision
title: "Vault installation runbook — living register, Missions required to update it"
description: "Institutes the installation runbook, its line-by-line VERIFIED/DECLARED qualification, and the obligation for every installation Mission to update it in the same commit."
created_at: 2026-08-21T10:51:17-04:00
timezone: America/Montreal
status: ARBITRATED
scope: vault-installation-runbook
owner_gate: granted
---

# DECISION — VAULT INSTALLATION RUNBOOK

## Context

The Vault and its tooling (Git, hooks, Graphify, Gemini key, "workshops" MCP server, sibling repositories) have been installed through successive gestures since 2026-08-17. No document says how to rebuild them. The `README.md` explains the why and the what, not the how. The installation facts are scattered across audits, reports and Decisions, and some gestures left no trace (the way the Gemini key is loaded, lost between Missions 018 and 020). The workshop's product must be rebuildable by someone other than the Owner, from the files alone.

## Decision

This decision takes up, with no addition of substance, the points of the proposal (workshop history, not distributed) that it engraves:

**D1.** A file [`vault/_trash/runbook-vault-setup.md`](../_trash/runbook-vault-setup.md) (since removed from distribution, kept for the record): ordered instructions to install and verify the Vault and its tooling. Fixed sections: prerequisites · repositories and branches · Git (hooks, `core.hooksPath`, attributes) · Graphify (version, installation, `.env.example`, usage commands, report regeneration, backups) · "workshops" MCP server (configuration, with no sensitive value) · roles and sessions (Pilot, Executor, where to open the session) · check of correct operation (commands and expected results) · change history.

**D2.** Each line is qualified `VERIFIED` (measured at the time of writing, command in support) or `DECLARED` (taken from a document). A `DECLARED` line becomes `VERIFIED` when a Mission measures it.

**D3.** Obligation: every Mission that installs, updates, configures or removes a component updates the runbook **in the same commit**. The execution report contract gains a section "Installation impact: none / runbook lines modified".

**D4.** `AGENTS.md` carries a line pointing to the runbook and recalling the obligation, as well as the report channel (`reports/`, two lines in chat).

**D5.** Before the workshop, a "dry-run installation" Mission rebuilds everything in an empty folder by following only the runbook; whatever is missing is added.

**D6.** No secret in the runbook: variable names, file locations, never a value.

## Reason

The runbook is the only artefact that makes the product transportable. Kept up as work goes along, it costs a few lines per Mission; reconstructed at the end, it costs an archaeology and remains incomplete.

## Impact

First real use in the present Mission (022): runbook V1 is created, and its History + Verification section is updated for what the Mission itself installs (isolated, temporary Python environment, under `%TEMP%`). The following Missions that touch the installation now carry the same obligation.

## Important alternatives

- Reconstruct at the end of the project: rejected (proven loss of information, untraced gestures).
- Put the installation in the `README.md`: rejected, the README is a text of intent, the runbook a text of procedure; two update rhythms.
- Automate with an installation script: premature; the runbook comes first, a script may follow it.

## Human gate

- Validation: granted
- Reference: Owner/Pilot arbitration in the session of 2026-08-21, engraved by Mission 022 (workshop history, not distributed).

## Linked artefacts

- Source Proposal: (workshop history, not distributed)
- Mission that engraves this Decision: (workshop history, not distributed)
- Runbook instituted: `../_trash/runbook-vault-setup.md` (removed from distribution, kept for the record)

## Liens

- `see also` — [Vault installation runbook — V1](../_trash/runbook-vault-setup.md) (removed from distribution, kept for the record)
