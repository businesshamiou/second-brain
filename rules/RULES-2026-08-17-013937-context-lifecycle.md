---
type: rules
title: "Minimal cycle for keeping and resuming context"
created_at: 2026-08-17T01:39:37-04:00
timezone: America/Montreal
status: superseded
---

# MINIMAL CONTEXT CYCLE

This rule defines how to keep only the context that must survive a session. It complements the [general Vault rules](./RULES-2026-08-17-005717-vault-operating-rules.md) without turning the Vault or a project into an exhaustive journal.

## 1. Selective principle

Keep a piece of information only if it is durable, useful to a future resume and absent from an already sufficient canonical source.

Do not systematically keep:

- transient exchanges and trials without consequence;
- every action executed or every chronological detail;
- replaced drafts with no lasting lesson;
- a copy of content already available in a linked source;
- a project's business context inside the central Vault.

## 2. Degrees of certainty

Each artefact explicitly distinguishes the nature of its content:

| Nature | Meaning |
|---|---|
| Fact | Information observed or backed by an identifiable source. |
| Proposal | Suggested option, still open to arbitration. |
| Decision | Explicit choice whose status says whether it is proposed, arbitrated or superseded. |
| Open question | Unresolved point that calls for an answer, a test or a human gate. |

A proposal never becomes `ARBITRATED` through implicit rewording. A structuring decision requires a human gate and a proof of arbitration.

A capture also states its level of certainty: `CONFIRMED` if the information is verified by a source, `OBSERVED` if it comes from direct observation, `INFERRED` if it results from reasoning, or `UNCERTAIN` if it still has to be verified.

## 3. Capture

Create a capture when a new piece of information:

- will remain useful beyond the current session;
- sheds light on a decision, a method, a constraint or an incident;
- deserves a standalone source and links to the artefacts concerned.

A capture describes its context, the information kept, its level of certainty, its possible impact and its links. It does not constitute a decision.

Use the [capture template](../templates/capture-template.md).

## 4. Decision

Create or update a decision when a structuring choice influences the rest of the work, the rules, the architecture, security or context boundaries.

The document records the date, the choice, its status, its reason, its impact, the important alternatives and its links. Before validation, its status remains `PROPOSED`. Only a human gate can move it to `ARBITRATED`.

Use the [decision template](../templates/decision-template.md).

## 5. Current state

When a project uses a resume state, maintain a single `current-state.md` file. It contains only the current objective, the operational state, the last validated step forward, the next step, the blockers, the relevant recent decisions and the reference sources.

Update this file in place. Do not stack dated copies to manufacture a history; Git and the linked artefacts already carry the useful history.

Use the [current state template](../templates/current-state-template.md).

## 6. Handoff

Create a handoff only when a reliable resume is necessary: new session, new agent, significant interruption or transfer of responsibility.

The handoff summarizes the objective, the current state, what is done, the active decisions, the open points, the next action and the constraints. It points to the priority sources instead of copying the project.

Use the [handoff template](../templates/handoff-template.md).

## 7. Work cycle

```text
work
  → capture if durable knowledge appears
  → decision if a structuring choice must be traced
  → update of current-state if the operational state changes
  → handoff only if a resume is necessary
  → resume from current-state, the decisions and the linked sources
```

The four mechanisms are available in every session, but none is mandatory out of mere routine. The real need dictates the artefact.

## 8. Vault / projects boundary

The Vault keeps this method and its templates. Each external project keeps its captures, decisions, handoffs and its current state in its own space. A lesson coming from a project rises into the Vault only after human validation of its cross-cutting character.

## Liens

- `superseded by` — [RULES-2026-08-17-111018-context-lifecycle-v2 — Context cycle V2 — capture → proposal → decision → current state → handoff](RULES-2026-08-17-111018-context-lifecycle-v2.md)
