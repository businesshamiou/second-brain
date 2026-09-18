---
type: rules
title: "Context cycle V2 — capture → proposal → decision → current state → handoff"
created_at: 2026-08-17T11:10:18-04:00
timezone: America/Montreal
status: active
supersedes: "./RULES-2026-08-17-013937-context-lifecycle.md"
---

# CONTEXT CYCLE V2 — CAPTURE → PROPOSAL → DECISION → CURRENT STATE → HANDOFF

This rule applies the [V1 information architecture Decision](../decisions/DECISION-2026-08-17-111018-vault-v1-information-architecture.md). It **supersedes** the [previous minimal context cycle](./RULES-2026-08-17-013937-context-lifecycle.md), which remains kept as history and must no longer be used as the current rule.

## 1. Selective principle

Keep a piece of information only if it must survive the session, will remain useful and is not already carried by a sufficient canonical source. The real need determines the artefact; no session must mechanically produce a capture, a proposal, a decision or a handoff.

Do not keep:

- transient exchanges, trials without consequence and chronological details;
- brainstorming ideas that do not justify a future arbitration;
- replaced drafts with no lasting lesson;
- copies of content or state already accessible in a canonical source;
- hashes, counters or technical states that can be measured again;
- a project's business context or current state in the central Vault.

## 2. Capture

Create a capture when a durable fact, observation, learning or question deserves a standalone source. State its context, its level of certainty, its possible impact and its links.

A capture is neither a proposal nor a decision. Use the [capture template](../templates/capture-template.md).

## 3. Proposal

Create a proposal only when an important option must be kept until an arbitration. Describe the proposal, its reason, its expected impact and the alternatives that are genuinely useful.

Its status remains `PROPOSED`. An accepted proposal is never silently requalified: create a new `DECISION` artefact that references it and keep both histories. Use the [proposal template](../templates/proposal-template.md).

## 4. Decision

Create a decision to record a structuring choice and its explicit arbitration. As long as the human gate has not been granted, its status remains `PROPOSED`; after arbitration, record `ARBITRATED` and the validation reference.

A decision describes the choice, its reason, its impact, the important alternatives and its links, notably the source proposal when there is one. Use the [decision template](../templates/decision-template.md).

## 5. Current state

When a project uses a resume state, maintain in that project a single `<projet>/current-state.md` file. It stays short and describes the current objective, the operational state, the last validated step forward, the next step, the blockers and the active sources.

The current state is a **living state**: update it in place. It serves neither as a dated history nor as a register of copied technical evidence. Use the [current state template](../templates/current-state-template.md).

## 6. Handoff

Create a handoff only when a reliable resume is genuinely necessary: significant interruption, new session, new agent or transfer of responsibility.

The handoff is a **dated historical handover**, not a living state to maintain. It describes the situation at the moment of the transfer, the finished work, the open points, the next action and the constraints. It points to the current state and the priority sources without copying them. Use the [handoff template](../templates/handoff-template.md).

## 7. Applicable cycle

```text
work
  → capture if durable knowledge appears
  → proposal if an important option must wait for an arbitration
  → decision when a choice is explicitly arbitrated
  → update of the current state if the operational state changes
  → handoff only if a reliable resume is necessary
  → resume from the current state, the decisions and the linked sources
```

## 8. Vault / projects boundary

The Vault keeps this rule, the cross-cutting explanations and the templates. External projects carry their own current state and their own captures, proposals, decisions and handoffs.

An improvement coming from a project joins the Vault only after human validation of its cross-cutting character. The associated evidence mechanism is explained in [Verification and evidence](../knowledge/verification-and-evidence.md).

## Liens

- `supersedes` — [RULES-2026-08-17-013937-context-lifecycle — Minimal cycle for keeping and resuming context](RULES-2026-08-17-013937-context-lifecycle.md)
