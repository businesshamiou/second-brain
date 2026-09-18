---
type: knowledge
title: "Corpus layering: where an artefact lives, and whether it enters a graph"
description: "Two axes — scope and nature — that determine where an artefact lives and whether it enters a knowledge graph."
created_at: 2026-08-19T16:14:22-04:00
timezone: America/Montreal
status: active
scope: vault-and-project-corpus
---

# CORPUS LAYERING

## The problem

Two questions arise for every artefact produced, and they are often confused:

1. **Where does it live?** In the cross-project Vault, or in a project's folder?
2. **Does it enter a knowledge graph?** Or does it remain accessible through direct reading only?

Treating them as a single question leads to shaky rules: either business matters are brought up into the Vault, or the graph is drowned under history. They are two independent axes.

## Axis 1 — scope

> What holds for any project lives in the Vault.
> What makes sense only in one project lives in that project.

The Vault carries the **universal how**: processes, guardrails, doctrine of evidence, conventions, document lifecycle, agent behaviours, [project registry](../projects/PROJECT-REGISTRY.md).

Each project carries its **business how**: its own rules, its constraints, its glossary, its production decisions, its context. These rules never go up into the Vault — a client project, a product, a consulting assignment each have a domain that has no business in a cross-project layer.

This point is often misunderstood: the Vault is not the only place where rules are written. It is the place where the **common** rules are written. Each project needs its own instruction layer, symmetrical to the Vault's.

## Axis 2 — nature

> What explains how or why enters the graph.
> What attests that work took place stays outside.

A rule, a decision, a piece of knowledge, a context, a registry explain. An audit, an archived prompt, a closed mission, an old handoff prove.

Evidence keeps its full value: it stays on disk, versioned in Git, readable on demand. It simply does not enter the semantic navigation layer, because it degrades its signal without adding anything to understanding.

This distinction is measured, not assumed: reducing the corpus from seventeen to fifteen better-chosen documents took a graph from sixteen to twenty-eight edges, and three knowledge tests from partial to conclusive.

## The matrix

```text
                    INSTRUCTION                    EVIDENCE
                    (how / why)                    (it was done)
              ┌────────────────────────────┬────────────────────────────┐
 CROSS-       │  rules                     │  old handoffs              │
 PROJECT      │  decisions                 │  test results              │
 (Vault)      │  knowledge                 │                            │
              │  skills                    │                            │
              │  project registry          │                            │
              │  test standards            │                            │
              │  → Vault graph             │  → outside the graph       │
              ├────────────────────────────┼────────────────────────────┤
 BUSINESS     │  project business rules    │  closed missions           │
 (Project)    │  production decisions      │  archived prompts          │
              │  master context            │  audits                    │
              │  constraints, glossary     │  old handoffs              │
              │  test strategies           │  execution results         │
              │  → project graph           │  → outside the graph       │
              └────────────────────────────┴────────────────────────────┘
```

The principle reads in two steps:

- **where it lives**: scope decides;
- **whether it enters the graph**: nature decides.

## The graph model

Each perimeter has its own graph. No merged global graph: merging would lose the boundaries, mix unrelated contexts and degrade the portability of each project taken in isolation.

```text
                  ┌─────────────────────────────┐
                  │   VAULT — the universal      │
                  │   how                        │
                  │   ────────────────────       │
                  │   project registry ●─────────┼──┐
                  └─────────────────────────────┘  │
                             graph A                │
                                                    │
        ┌───────────────────────┬───────────────────┴──────┐
        ▼                       ▼                          ▼
  ┌───────────┐          ┌───────────┐            ┌───────────┐
  │ project 1 │          │ project 2 │            │ project N │
  │ business  │          │ business  │            │ business  │
  │ how       │          │ how       │            │ how       │
  │ + what    │          │ + what    │            │ + what    │
  │ graph B   │          │ graph C   │            │ graph D   │
  └───────────┘          └───────────┘            └───────────┘
```

The project registry is the link: the Vault knows the address of each project, never its content. The graphs stay separate but connected through this single entry point.

## The trap of the mixed folder

A single folder may contain both natures. The clearest case is that of tests:

- a **test strategy** says how to verify — it is an instruction, it enters the graph;
- a **test result** attests that a verification took place — it is evidence, it stays outside.

The scope axis applies there too: the common standards — doctrine of evidence, definition of the confidence marks, requirements before a Mission is closed — live in the Vault; the strategies specific to a domain — how to test an interface, a page, a business flow — live in the project concerned.

The same trap holds for handoffs: the current handoff is an instruction on the state of the moment, old handoffs are evidence.

Hence a practical principle:

> When a folder mixes instruction and evidence, separate physically rather than filter finely.

A filter that must guess a file's nature from its name or its date is fragile and degrades with every addition. Two distinct locations make the sorting mechanical, readable by a human as by an agent, and robust over time.

## The special case of the current state

The instruction layer subdivides into two temporalities:

- **stable**: what is durably true — rules, decisions, knowledge;
- **current**: what describes the state of the moment — current state, mission index, handoff in progress.

Both enter the graph. But the current, by nature, is replaced rather than accumulated: a single state file updated in place, rather than a dated series. Without this discipline, the current layer becomes a disguised history layer, and the graph degrades.

## What this document does not settle

Applying these principles to specific cases — which folders exactly, by which mechanism to distinguish a current handoff from an old one, when to create a project's graph — belongs to separate arbitrations, to be carried out project by project.

## Liens

- `see also` — [Project Registry](../projects/PROJECT-REGISTRY.md)
