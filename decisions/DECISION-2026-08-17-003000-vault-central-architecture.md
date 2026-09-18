---
type: decision
title: "Central architecture — permanent Vault and sibling projects"
created_at: 2026-08-17T00:30:00-04:00
timezone: America/Montreal
status: active
---

# DECISION — CENTRAL VAULT AND SIBLING PROJECTS

## Status

**ARBITRATED**

## Decision

The workshop's central system is no longer conceived as a project named `ai-context-workshop`.

It becomes a permanent **Vault**.

In prose and teaching materials, the concept is named **Vault**.

In machine identifiers and the file system, the folder and future repository use the name:

`vault`

The Vault stays at a fixed location and serves as a mini second brain / operating system for working with AI.

It contains only the **cross-cutting and reusable** knowledge and mechanisms:

- working rules;
- conventions;
- methods;
- skills;
- useful templates;
- capture principles;
- handoff principles;
- decision principles;
- Git rules;
- security rules;
- Graphify principles;
- general knowledge needed for the system to function.

The Vault **must not absorb the detailed business context of every project**.

Each real project has its own folder or repository, created **outside the Vault**, as a sibling folder, with its local context:

- objectives;
- current state;
- its own decisions;
- business knowledge;
- handoffs;
- sketches;
- other specific artefacts.

The Vault may help create and guide these projects without being copied into each of them.

## Logical architecture

```text
workspace/
└── workshops/
    ├── bootstrap/
    ├── prompt-archive/
    ├── vault/
    ├── project-a/
    ├── project-b/
    └── (workshop history, not distributed)
```

(workshop history, not distributed) is a separate space, to be designed later, intended for building the training: Codex prompts, presentation, teaching materials, build journals and production tools.

## Inheritance principle

The Vault carries the cross-cutting rules.

Projects carry only:

- their own context;
- their own decisions;
- their exceptions;
- their working artefacts.

A general improvement discovered in a project may move up to the Vault **only after human validation**.

A decision specific to a project does not move up to the Vault automatically.

## Graphify

The Vault and each project must remain separate context spaces.

The Vault may have its own Graphify graph.

Each project may have its own Graphify graph.

No global merge is considered settled until it has been tested and validated.

**Note (2026-08-26, Mission 065)**: this section describes an architecture option that no longer applies. Graphify was taken out of the "Vault graph" role and then entirely eradicated (Mission 040, 2026-08-24); kept for historical reading, not corrected in place (`amended by` below).

## Reason

This architecture avoids:

- duplicating the central brain in every project;
- drift of diverging rules between projects;
- mixing unrelated business contexts;
- contaminating the graph with decisions specific to other projects;
- confusing working infrastructure with building the workshop.

It lets the system capitalize on experience while keeping clean context boundaries.

## Impact

Earlier references to `ai-context-workshop` as the name of the central repository are **superseded**.

Any Mission 001 or execution prompt that creates `ai-context-workshop` is obsolete.

The next bootstrap must create `vault`.

The eight initial artefacts remain kept as history and are not silently rewritten.

## Liens

- `amended by` — [Withdrawal of Graphify from the "Vault graph" role](./DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md) (Graphify section)
