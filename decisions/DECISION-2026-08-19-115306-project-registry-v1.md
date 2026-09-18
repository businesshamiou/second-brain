---
type: decision
title: "Project Registry V1 — architecture and write contract"
created_at: 2026-08-19T11:53:06-04:00
timezone: America/Montreal
status: active
scope: vault-project-discovery
owner_gate: granted
source_proposal: "(historique de l'atelier, non distribué)"
---

# DECISION — PROJECT REGISTRY V1

## Context

The Vault knows how to work but does not explicitly know the existing projects, their location and their entry points. An agent that opens the Vault therefore depends on a manual indication from the Owner to locate a project.

The source Proposal was brainstormed and then arbitrated with the Owner. Its `PROPOSED` status is not modified: a Decision references its Proposal, it does not rewrite it.

## Principle

> The Vault knows the project's address, not its content.

The project remains the canonical source of its own memory.

## Decisions

### D1 — Form and location

One entry per project, plus an index, in `vault/projects/`:

    vault/projects/
    ├── PROJECT-REGISTRY.md            (index)
    └── PROJECT-<project_id>.md        (une fiche par projet)

The index is structured in sections `Active`, `Paused`, `Archived`, Active first. An archived entry stays in place, never deleted.

Field names and identifiers in English; prose in French.

### D1b — Project identifier

    project_id : YYYY-MM-DD-CODE

Full date of the project's first creation, then a mnemonic code derived from the name: one to three segments of two to four upper-case alphanumeric characters separated by hyphens, for example `AI-CTX-WRKS`. The first three segments of a `project_id` are always the date; everything after is the code. In case of collision, adjust the code, never the date.

### D2 — Minimal schema

Entry, eight fields: `project_id`, `display_name`, `status`, `relative_path`, `purpose` in one sentence, `canonical_context`, `entry_point`, `last_verified`.

Index, four columns: `project_id`, `display_name`, `status`, `relative_path`.

Entry sections: Identity, Location, Entry Points, Notes.

Explicitly excluded: last handoff, repository, graph, any Git state, any SHA — perishable or deducible.

### D3 — Paths

`relative_path` is relative to the Vault's parent, the workspace being implicit. No machine-specific path is versioned, which preserves portability across machines and providers.

The schema remains extensible through optional fields — `workspace_root`, `remote` — the day a project leaves the workspace, without breaking what exists.

### D4 — Write contract

No one edits the Registry by hand. Three write paths, all going through an Executor:

1. the `project-bootstrap` Skill automatically writes the entry and the index line when a project is created;
2. a Mission or Executor instruction, on Owner arbitration, applies lifecycle changes: status, path, entry points;
3. the `session-start` Skill only reads: it checks the opened project and reports discrepancies as ANOMALY, without correcting.

Closed statuses: `ACTIVE`, `PAUSED`, `ARCHIVED`.

### D5 — Graphify

The index and the entries enter the Vault's active Graphify corpus. The Vault graph thus carries the "what and where" of projects; each project keeps its own graph for its content. No merged global graph: the Graphify V1 Decision remains unchanged.

### D6 — Staleness

Each entry carries `last_verified` and `stale_after`, in accordance with the OKF adoption Decision. `session-start` checks that the paths of the project it opens exist, not the whole Registry: the Registry repairs itself through real use, without periodic inventory.

## Success criterion

An agent that knows only the Vault can answer: which active projects exist, where they are, what they are for, and which file to read to start — without the Vault copying their memory.

## Human gate

Owner arbitration given in a steering session.

## Liens

- `source` — [Project Registry](../projects/PROJECT-REGISTRY.md)
- `source` — Source Proposal (workshop history, not distributed) (hors Vault)
- `amended by` — [Withdrawal of Graphify from the "Vault graph" role](./DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md) (D5 becomes moot)
- `amended by` — [Project structure standard](../rules/RULES-2026-08-26-142800-project-structure-standard.md) (D3, additive extension of the schema — registry v2, Mission 061)
- `amended by` — [Decision — Project initiation and adoption, birth certificate](./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md) (D2: `vcs` field and column; D4: writing by `adopt`)
