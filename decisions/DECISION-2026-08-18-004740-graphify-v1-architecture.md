---
type: decision
title: "Graphify V1 architecture — optional navigation and bounded active corpus"
created_at: 2026-08-18T00:47:40-04:00
timezone: America/Montreal
status: active
owner_gate: granted
scope: graphify-v1-architecture
---

# DECISION — GRAPHIFY V1 ARCHITECTURE

## Date

2026-08-18

## Status

`ARBITRATED`

## Decision

Graphify `0.9.26` is validated as an **optional** navigation layer above the Vault's canonical sources. It helps find files and their links, but replaces neither reading them, nor a rule, nor an explicit decision. Every execution keeps a fallback to the files, the Markdown links and local search.

### Machine

- Graphify and its Gemini extra are installed outside the repo via `uv tool`, with the version pinned at `0.9.26`;
- `GEMINI_API_KEY` is the canonical name of the Gemini backend variable;
- its value stays in `.env`, a local file ignored by Git, and is loaded only into the process environment;
- `.env.example`, with no secret value, may be versioned;
- no hook, MCP or automatic update mechanism is enabled by default.

### Vault

The V1 active corpus consists only of the useful cross-cutting sources:

- `README.md` and `AGENTS.md`;
- active Decisions;
- active Knowledge: Vault model, V2 project model, verification and evidence;
- active Rules: Vault conduct, V2 context lifecycle, Mission versioning;
- the five document Templates.

Explicitly superseded sources, secrets, local configurations, caches, generated outputs and unneeded history are excluded by `.graphifyignore` (supprimé, Mission 040). The corpus points directly to the canonical sources; no dedicated mirror folder or duplicate is created.

### Projects

The Vault and each project keep separate graphs. A project graph stays in the project and covers only its active local context. No global merge or automatic import of project context into the Vault is authorized in V1.

### Generated outputs

`graphify-out/` (supprimé, Mission 040) is derived, rebuildable, local and ignored by Git. It remains usable by Graphify on the machine, but its graphs, manifests, caches and backups are not versioned. These files are never edited by hand.

### Refresh

The graph is rebuilt explicitly after a significant canonical change to the corpus. A refresh is not triggered mechanically at every session. Any future automation, hook/MCP activation, global merge or boundary change requires a distinct Mission and human gate.

## Reason

The C01 baseline established that Graphify works with Gemini, but revealed a noisy corpus and uneven A/B/C retrieval. C02 reduced the corpus from 17 to 15 documents, removed two superseded sources from the graph, raised the edges from 16 to 28 and obtained `PASS` on the three A/B/C navigation tests.

V1 therefore favours a bounded signal, explicit sources and a reduced cost, while accepting that Graphify remains mainly a document index.

## Impact

- `.graphifyignore` (supprimé, Mission 040) carries the exclusions of the active corpus;
- `.gitignore` excludes `graphify-out/` (supprimé, Mission 040);
- `.env` stays local and `.env.example` may be tracked;
- the Vault files remain the source of truth;
- the Vault and project graphs remain separate;
- Graphify remains optional and replaceable by local navigation.

The limits accepted in V1 are the mainly document-level granularity, labels that are sometimes normalized, the dominant `references` relation and limited selectivity on a small corpus.

## Important alternatives

- **Version `graphify-out/`** (supprimé, Mission 040): rejected in V1, because the output is derived, contains caches and can be rebuilt.
- **Make Graphify mandatory**: rejected, because the sources must remain usable without the tool or the backend.
- **Merge the Vault and project graphs**: rejected in V1 to preserve context boundaries.
- **Add document copies dedicated to Graphify**: rejected to avoid divergence and duplication.
- **Enable hooks or MCP**: postponed to a distinct Mission if a real need appears.

## Human gate

- Validation: granted
- Reference: explicit approval by the Owner of the Graphify V1 gate on 2026-08-18; execution evidence kept in (workshop history, not distributed).

## Linked artefacts

- Vault/projects architecture: [Central Vault and sibling projects](./DECISION-2026-08-17-003000-vault-central-architecture.md)
- Information architecture: [V1 information architecture](./DECISION-2026-08-17-111018-vault-v1-information-architecture.md)
- Active project model: [Project operating model V2](../knowledge/BRIEF-2026-08-17-211522-project-operating-model-v2.md)
- Active lifecycle: [V2 context lifecycle](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- Evidence: [Verification and evidence](../knowledge/verification-and-evidence.md)

## Liens

- `amended by` — [Graphify V1 amendment](./DECISION-2026-08-19-233650-graphify-integrations-amendment.md)
- `amended by` — [Withdrawal of Graphify from the "Vault graph" role](./DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md)
