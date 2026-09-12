# Skills Warehouse

> **Current operating model.** This checkout is a thin, LLM- and runtime-agnostic warehouse: active Skills live only in `skill-collections/*/skills/`; compact evidence lives in `provenance/`; operational records live in `logs/`; tools live in `tools/`; validated package outputs live in versioned `deliverables/`. Full upstream snapshots remain external, while the packages are attached to the repository. Where older text in this file mentions `skills/`, `dist/`, `sources/`, `intake/`, or collection `releases/`, it is historical context and is superseded by [THIN_REPOSITORY_STANDARD.md](THIN_REPOSITORY_STANDARD.md).

> Collection architecture is governed by [COLLECTIONS_STANDARD.md](COLLECTIONS_STANDARD.md). Versioned production is governed by [PRODUCTION_STANDARD.md](PRODUCTION_STANDARD.md).

This repository is a canonical warehouse for Agent Skills. It centralizes Skills from multiple sources, identifies the real Skill units inside those sources, filters and deduplicates them, preserves their provenance, removes accidental runtime coupling, and distributes validated individual and master archives.

It is designed to be understood from the files in this directory alone. No conversation history, particular LLM, agent product, or proprietary interface is required.

## Purpose and compatibility

The warehouse maintains one portable active version of each accepted Skill in exactly one domain collection under `skill-collections/<collection>/skills/`. Canonical instructions describe outcomes, workflows, and required capabilities rather than assuming particular tool names or invocation syntax. Root `skills/` and `dist/` preserve the immutable pre-migration 33-Skill history.

The target is practical compatibility with runtimes including Claude, Claude Code, ChatGPT, Codex, and other agents capable of reading a `SKILL.md`. A provider-specific dependency may remain only when that provider is intrinsic to the Skill's purpose; it must be explicit and classified. Optional runtime adapters never replace the canonical workflow.

Canonical state:

- Active collections: 3
- `software-engineering`: 29 Skills
- `web-design`: 90 Skills
- `visual-content`: 2 Skills
- Warehouse-wide active Skills: 121
- Duplicate active Skill names: 0

Portability state inherited from the validated migration source:

- Active Skills: 33
- Active Skill files: 446
- `UNIVERSAL`: 10
- `MINOR-PORTABILITY-FIX`: 13
- `RUNTIME-COUPLED`: 8
- `INTRINSIC-PROVIDER-DEPENDENCY`: 2
- `OPEN`: 0

See [skill-collections/index.md](skill-collections/index.md) for the active collection catalog. [compatibility-report.md](compatibility-report.md), [sources/registry.md](sources/registry.md), root `index.md`, and root `manifest.md` preserve the legacy audit and provenance snapshot.

## Source of truth

- [README.md](README.md) — warehouse identity, layout, and general use.
- [COLLECTIONS_STANDARD.md](COLLECTIONS_STANDARD.md) — canonical architecture, category catalog, classification, collection contract, and legacy migration rules.
- [INGESTION_STANDARD.md](INGESTION_STANDARD.md) — canonical rules for resolving and ingesting new sources.
- [PORTABILITY_STANDARD.md](PORTABILITY_STANDARD.md) — canonical rules for LLM/runtime-agnostic Skill content.
- [PRODUCTION_STANDARD.md](PRODUCTION_STANDARD.md) — canonical rules for immutable, single-pass collection releases.
- [SYSTEM_NAMING_STANDARD.md](SYSTEM_NAMING_STANDARD.md) — permanent English-only naming contract for system paths and identifiers; prose may be French.
- [sources/COLLECTION-OPERATIONS.md](sources/COLLECTION-OPERATIONS.md) — replaceable command mapping for collection builds and warehouse validation.
- [AGENTS.md](AGENTS.md) — short operational entrypoint for any agent opening the repository.

Runtime-specific pointer or metadata files may translate optional mechanics, but they do not define competing policy.

## Repository layout

- `skill-collections/` is the canonical home for domain collections. The approved machine-readable category catalog is `skill-collections/catalog.json`.
- `skill-collections/<collection>/skills/` contains canonical active Skills owned by that collection.
- `deliverables/<collection>/<version>/` contains the committed, immutable collection ZIP, individual chat ZIPs, manifest, licences, validation report, and SHA-256 inventory. There is no new global `dist/` or per-collection `releases/` directory.
- `provenance/` contains compact provenance evidence, integrity inventories, and legacy source records.
- External temporary intake and source snapshots are never active and are excluded from delivery packages.
- Root `skills/` and `dist/` are historical pre-migration layout names, not active repository directories. `affiliate-pro-skills-full.zip` is a historical filename and not the naming model for future collections.
- `skill-collections/index.md` describes the current active catalog. Root `index.md` and `manifest.md` describe the immutable legacy snapshot.

## How to add Skills

After initialization, no special ingestion command is required. Provide any accessible combination of:

- one URL or several URLs;
- a repository or repository-subdirectory URL;
- a local absolute or relative path;
- a ZIP or another supported archive;
- an individual `SKILL.md` or a group of files;
- one or more files attached to the current message or accessible session;
- pasted files or a mixture of the forms above.

When a message contains sources and no other instruction, it is an ingestion request by default. Multiple sources in the same message form one batch unless the user says otherwise. The runtime resolves them with its available attached-file, filesystem, repository, web, and archive capabilities. It should not ask the user to locate a source that is already identifiable and accessible.

A source is not necessarily a Skill. A repository, archive, directory, or attachment set can contain zero, one, or many Skills. The ingestion workflow inspects it and identifies coherent Skill directories before anything enters a collection's `skills/`; it never copies a whole source into the active library merely because it was supplied.

If a required access capability is absent, the runtime uses a faithful available alternative or reports the exact limitation. It never invents access, source contents, provenance, validation, or success.

## Permanent incremental workflow

Every explicit or implicit ingestion applies both canonical standards and runs:

INGEST → RESOLVE SOURCES → INSPECT → IDENTIFY SKILLS → SECURITY CHECK (SKILLSPECTOR) → FILTER → CLASSIFY COLLECTION → DEDUPLICATE WAREHOUSE-WIDE → PORTABILITY AUDIT → LLM-AGNOSTIC NORMALIZATION → LICENSE AUDIT → PRESERVE ORIGINAL → INTEGRATE INTO COLLECTION → UPDATE COLLECTION RECORDS → PACKAGE COLLECTION → VALIDATE → GENERATE SHA-256

The complete decision rules are in [INGESTION_STANDARD.md](INGESTION_STANDARD.md). [sources/COLLECTION-OPERATIONS.md](sources/COLLECTION-OPERATIONS.md) maps those rules to the current architecture; [sources/INCREMENTAL-INGESTION.md](sources/INCREMENTAL-INGESTION.md) is legacy-only. The process is incremental: unchanged active Skills remain untouched, duplicates are not recopied, version ambiguities become `OPEN`, and releases are rebuilt only for affected collections.

`SECURITY CHECK` is a mandatory reproducible static scan by the pinned NVIDIA SkillSpector release recorded in `tools/skillspector-lock.json`. `tools/scan-skillspector.py` writes compact evidence under `provenance/skillspector/`; an incomplete scan or a HIGH/CRITICAL finding is `OPEN — SKILLSPECTOR SECURITY REVIEW` until an Owner records an evidence-bound suppression or remediation.

## Provenance and originals

Sources are read and copied, never normalized in place. Before an accepted Skill is changed, its full original is preserved under `sources/originals/<source>/<version-or-commit>/` and verified by hash. The owning collection registry records source identity, version or commit, canonical hashes, classification, compatibility, licence, reason, and status.

Originals are local provenance evidence. They are not interpreted as active Skills and are excluded from every distributed archive.

## Validation philosophy

`PASS` means the observable warehouse invariants passed together: valid Skill structure and names, correct collection ownership, complete local references, security disposition, provenance, deduplication, portability, integrity hashes, documentation consistency, exact individual ZIP contents, readable collection ZIP contents, required canonical documents, and exclusion of originals, intake, other collections, previous releases, repository metadata, caches, and temporary files.

Validation is honest about scope. Static multi-runtime analysis is not reported as execution in runtimes that were not run. A missing capability or unresolved version is surfaced as a limitation or `OPEN`, never simulated away.

The committed warehouse validates autonomously from its archived originals and integrity inventories. When a checkout of the recorded upstream commit is available, the validator also performs an optional independent comparison against it; that stronger cross-check is reported separately and is not a hidden requirement for using a fresh clone.

The collection producer is `sources/build-collection-release.py`; the warehouse validator is `sources/validate-collections.py`. The existing `sources/incremental-pack.ps1` and `sources/build-versioned-release.py` remain legacy producers for the historical root layout.

## Collection ZIPs and legacy ZIP

Each canonical collection produces its own `<collection-slug>-skills-full.zip`; there is no future cross-collection master ZIP by default. Its complete, versioned delivery is committed under `deliverables/`. All packages exclude originals, intake, releases, other collections, nested ZIPs, source-control metadata, dependencies, caches, and temporary artifacts.
