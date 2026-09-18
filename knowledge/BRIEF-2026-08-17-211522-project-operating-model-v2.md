---
type: brief
title: "Project operating model V2 — Vault/project boundary and hierarchy Vault rules → Project rules → Mission/task instructions"
created_at: 2026-08-17T21:15:22-04:00
timezone: America/Montreal
status: active
scope: transverse-project-guidance
supersedes: "BRIEF-2026-08-17-140100-project-operating-model.md"
---

# PROJECT OPERATING MODEL V2 — VAULT/PROJECT BOUNDARY AND HIERARCHY OF INSTRUCTIONS

## Purpose

Explain how a project collaborates with the Vault, versions its Missions and receives generated outputs without copying the whole architecture of the Vault.

This model applies the [Vault/projects architecture](../decisions/DECISION-2026-08-17-003000-vault-central-architecture.md), the [context lifecycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md) and the [rule on versioning Missions and generated outputs](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md).

## 1. Vault vs projet (Vault vs project)

The Vault keeps the way of working: rules, methods, cross-project knowledge and templates. The project keeps what is being worked on: objective, context, state, specific rules and business productions.

The Vault never replaces the local context and does not automatically import a project's decisions or artefacts.

## 2. Recommended minimal core

A project driven by AI may start with:

```text
project/
├── README.md
├── AGENTS.md
├── .gitignore
├── docs/
│   ├── project-overview.md
│   └── current-state.md
└── generated/
```

`generated/` receives only the outputs without a known canonical destination. It is non-canonical by default and each content awaits a review or an explicit promotion.

If no such output exists, the folder does not need to be created: **real need → structure**.

## 3. Structure on demand

Add only when the need appears:

```text
rules/          # rules specific to the project
missions/       # Missions and active register
proposals/      # important options to arbitrate
decisions/      # decisions specific to the project
captures/       # durable learnings
handoffs/       # real handoffs
resources/      # inventory of external resources
src/            # code if applicable
tests/          # tests if applicable
assets/         # versionable assets if applicable
```

## 4. Missions and active versions

When a project uses Missions, each objective receives an ID `NNN`. The `Cxx` corrections keep that ID, use a new real timestamp and remain complete and self-contained.

The Mission and its Executor Prompt carry the same `NNN/Cxx`. The old versions are historical; `<projet>/missions/MISSION-INDEX.md` resolves the active version without copying perishable Git state.

Decisions remain cumulative and are never silently requalified.

## 5. Inheritance of rules

```text
Vault rules
    ↓
Project rules
    ↓
Mission / task instructions
```

Project rules specialize the business domain, the stack and the local constraints. They do not silently neutralize the guardrails of security, of evidence or of external boundary.

## 6. Git and external resources

Preferably version code, Markdown, configuration, tests, schemas, small assets and reproducible sources.

Videos, large datasets, heavy media, licensed assets and other heavy binaries may stay outside Git, but the project keeps their role and their provenance in a manifest without secrets.

Default rule: a project has one main repo. Several repos are justified only by really distinct permissions, deployment cycles, products or security constraints.

## 7. Design principle

> **The Vault defines the common frame. The project keeps its context and specializes the frame. Real need → structure.**

## Liens

- `supersedes` — [BRIEF-2026-08-17-140100-project-operating-model — Project operating model](BRIEF-2026-08-17-140100-project-operating-model.md)
