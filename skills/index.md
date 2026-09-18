---
type: index
title: "Vault skills"
description: "Agent behaviours in the Agent Skills format."
created_at: 2026-08-19T11:53:06-04:00
timezone: America/Montreal
status: active
---

# Vault skills

Agent behaviours in the Agent Skills format.

## Contents

- `external/` — library of 40 external skills in the standard Agent Skills form (six fields, provenance under `metadata:`), built from the package of the `skills-warehouse` project — see [PROVENANCE.md](./external/PROVENANCE.md).
- `ecriture-de-mission/` — drafts a Mission file and its Executor mini-prompt from the template, measured links, mandatory Context section — see [SKILL.md](./ecriture-de-mission/SKILL.md).
- `first-install/` — installs the Vault on a machine for the first time, or completes a partial installation without overwriting what exists — see [SKILL.md](./first-install/SKILL.md).
- `project-bootstrap/` — makes a project aware of the Vault, at one of the three tiers (registry, guardians, preflight hook) — see [SKILL.md](./project-bootstrap/SKILL.md).
- `recherche-interne/` — disciplined search in the Vault and the project corpus: index and description first, never an unmeasured path — see [SKILL.md](./recherche-interne/SKILL.md).
- `session-close/` — closes a work session: inventory of the holes, refusal to close as long as any remain, handoff or closing commit — see [SKILL.md](./session-close/SKILL.md).
- `session-start/` — opens a work session: measures the state of the repository and of the guardians, announces the role — see [SKILL.md](./session-start/SKILL.md).
- `update/` — updates an installed Second Brain to a published version without reinstalling: merge over the participant's commits, clean refusal on a conflict — see [SKILL.md](./update/SKILL.md).

## Liens

- `prescribed by` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `source` — [Provenance — external skills library](./external/PROVENANCE.md)
