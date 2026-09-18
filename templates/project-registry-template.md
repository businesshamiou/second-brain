---
type: template
title: "Template — Project Registry"
description: "Blank template of the Vault's Project Registry: column headers and write contract kept, no data row. Meant to be instantiated by the future first-install skill (not built by this batch)."
status: active
write_contract: "executor-only — voir DECISION project-registry-v1"
---

# TEMPLATE — PROJECT REGISTRY

Blank template of the [Project Registry](../projects/PROJECT-REGISTRY.md): index of the projects known to the Vault. The Vault knows the address of the projects, not their content — each project remains the canonical source of its own memory. The detail of each project lives in its sheet `PROJECT-<project_id>.md`.

Paths are relative to the Vault's parent. The `vcs` column is `git` or `none` (Decision 000545, A2).

## Active

| project_id | display_name | status | relative_path | vcs | conformity |
|---|---|---|---|---|---|

## Paused

No project.

## Archived

No project.

## Liens

- `see also` — [Project Registry — index of the projects known to the Vault](../projects/PROJECT-REGISTRY.md)
- `source` — [Decision — Project Registry V1](../decisions/DECISION-2026-08-19-115306-project-registry-v1.md)
