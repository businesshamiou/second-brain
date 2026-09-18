---
type: brief
title: "Project operating model"
created_at: 2026-08-17T14:01:00-04:00
timezone: America/Montreal
status: superseded
scope: transverse-project-guidance
---

# PROJECT OPERATING MODEL

## Purpose

Explain how an external project must collaborate with the Vault without copying the architecture of the Vault.

This model applies the [separation between the Vault and sibling projects](../decisions/DECISION-2026-08-17-003000-vault-central-architecture.md) as well as the [information architecture V1](../decisions/DECISION-2026-08-17-111018-vault-v1-information-architecture.md). Optional artefacts follow the [context lifecycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md) and the [Vault's templates](../templates/).

## 1. Vault vs project

The Vault keeps the way of working.

The project keeps what is being worked on.

The Vault contains the rules, methods, cross-project knowledge and reusable templates.

The project contains its objective, its context, its state, its specific rules and its business productions.

## 2. Recommended minimal core

A new project may start with:

```text
project/
├── README.md
├── AGENTS.md
├── .gitignore
└── docs/
    ├── project-overview.md
    └── current-state.md
```

Do not create other folders in anticipation.

## 3. Structure on demand

Add only when the need appears:

```text
rules/          # rules specific to the project
proposals/      # important options to arbitrate
decisions/      # decisions specific to the project
captures/       # durable learnings
handoffs/       # real handoffs
resources/      # inventory of external resources
src/            # code if applicable
tests/          # tests if applicable
assets/         # versionable assets if applicable
```

The business structure remains free and depends on the type of project.

Folders appear to carry a real need; their mere availability in the Vault does not justify creating them in every project.

## 4. Vault rules and project rules

Order of specialization:

```text
Vault rules
    ↓
Project rules
    ↓
Mission / task instructions
```

The Vault's rules carry what is cross-project.

Project rules carry the business domain, the stack, the format, the constraints or the conventions specific to the project.

A project rule may specialize the frame, but must not silently neutralize the Vault's structuring guardrails.

## 5. Git: what goes into the repo

Preferably version:

- code and scripts;
- Markdown files;
- configuration;
- tests;
- small assets;
- schemas;
- reasonably small source files;
- any important and reproducible textual artefact.

## 6. Resources outside Git

Some elements may stay outside Git:

- raw videos;
- large media;
- voluminous datasets;
- heavy binary files;
- purchased or licensed assets;
- temporary exports.

They nevertheless remain known to the project through a manifest, for example:

`resources/resources-manifest.md`

The manifest may contain:

- `name`
- `purpose`
- `location`
- `version`
- `license`
- `git_tracked`
- `checksum` when relevant

The manifest must not contain any secret.

## 7. One repo or several?

Default rule:

> One project = one main repo.

Split into several repos only if a real need justifies it:

- different permissions;
- independent deployment cycles;
- distinct products;
- security constraints;
- strong technical autonomy.

Do not multiply repos only to file away files.

## 8. Design principle

> **Real need → structure.**

The objective is to make projects structured enough to be driven by agents, without reproducing the complexity of the Vault.

## Liens

- `superseded by` — [BRIEF-2026-08-17-211522-project-operating-model-v2 — Project operating model V2 — Vault/project boundary and hierarchy Vault rules → Project rules → Mission/task instructions](BRIEF-2026-08-17-211522-project-operating-model-v2.md)
