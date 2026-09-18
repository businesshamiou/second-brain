---
type: decision
title: "V1 information architecture — primitives, evidence and human gates"
created_at: 2026-08-17T11:10:18-04:00
timezone: America/Montreal
status: active
owner_gate: granted
---

# DECISION — V1 INFORMATION ARCHITECTURE OF THE VAULT

## Status

**ARBITRATED**

This decision records in the Vault the validated V1 arbitrations for its document primitives, its information layers and its evidence model.

## Decision

### 1. Document primitives

The primitives have distinct roles:

- a **capture** keeps useful durable knowledge without any implicit arbitration value;
- a **proposal** keeps an important option awaiting arbitration;
- a **decision** records an explicitly validated choice;
- the **current state** is the live, short and up-to-date state of a project;
- a **handoff** is a dated handover, created only when a reliable resume is needed.

A brainstorming idea does not automatically produce a proposal. A proposal stays `PROPOSED` until the human gate. When it is accepted, it is neither renamed nor silently transformed: a new `DECISION` artefact is created and points to it. The two histories remain distinct.

The current state is updated in place. The handoff does not become a second current state: it summarizes the minimum needed for the handover and points to the active sources.

### 2. Vault / projects boundary

The Vault keeps the cross-cutting rules, explanations and templates. Each external project keeps its own current state, captures, proposals, decisions and handoffs. No project state is imported automatically into the Vault.

### 3. Document layers

- `rules/` prescribes the expected behaviours;
- `knowledge/` explains the mechanisms, their reasons and their limits;
- `templates/` materializes the form of the artefacts;
- `AGENTS.md` contains the minimal operational instructions;
- `README.md` remains the entry point.

The same doctrine must not be copied in full into every layer.

### 4. V1 evidence model

The evidence model follows five levels:

1. **STATE** — `git status` measures the real state of the working tree and the index;
2. **CHANGE** — `git diff` and `git diff --staged` show the real change;
3. **VALIDATION** — the relevant tests and checks evaluate the expected behaviour;
4. **SNAPSHOT** — a local commit and its hash identify a measured snapshot;
5. **EXTERNAL BOUNDARY** — remotes, pushes, publications and other external effects are treated as a distinct boundary.

Hashes, counters and Git states are re-measured when they are needed rather than copied as durable truth. A declared or present check does not prove that it works: its execution and its result must be observed.

### 5. Human gates

A local, bounded and reversible mission may authorize a complete chain of inspection, modification, validation, file-by-file staging, inspection of the staged diff, local commit and evidence report.

An explicit human gate remains required for an unarbitrated structuring decision, a significant deletion or migration, a security or secret concern, a boundary change, a remote, a push, a publication or any other sensitive or hard-to-reverse external effect.

## Reason

This architecture avoids confusion between knowledge and arbitration, between live state and historical handover, and between local check and external effect. It also makes it possible to verify work from reproducible observations rather than from copied declarations.

## Impact

- the V2 context lifecycle explicitly supersedes the previous rule;
- a proposal template joins the existing templates;
- verification knowledge becomes queryable on its own;
- entry points and templates use the stabilized roles without duplicating the whole doctrine.

## Human gate

- Validation: granted
- Arbitration reference: validation explicitly provided before this canonical decision was recorded.

## Linked artefacts

- Parent architecture: [Central Vault and sibling projects](./DECISION-2026-08-17-003000-vault-central-architecture.md)
- General rules: [operating rules](../rules/RULES-2026-08-17-005717-vault-operating-rules.md)
- Applicable lifecycle: [V2 context lifecycle](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- Operating model: [concept and operating model](../_trash/BRIEF-2026-08-17-003000-vault-concept-operating-model.md) (removed from distribution, kept for the record)
- Evidence: [verification and evidence](../knowledge/verification-and-evidence.md)

## Liens

- `see also` — [Central Vault and sibling projects](./DECISION-2026-08-17-003000-vault-central-architecture.md)
- `see also` — [Vault — teaching concept and operating model](../_trash/BRIEF-2026-08-17-003000-vault-concept-operating-model.md) (removed from distribution, kept for the record)
