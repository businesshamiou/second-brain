# Canonical ingestion standard

> **Current storage amendment:** the workflow and decision order below remain binding, but all staging is external to Git; `sources/`, `intake/`, collection `releases/`, root `skills/`, and root `dist/` are retired local paths. Preserve compact evidence in `provenance/`, record outcomes in `logs/`, package externally, then publish immutable assets externally. See [THIN_REPOSITORY_STANDARD.md](THIN_REPOSITORY_STANDARD.md).

Apply [COLLECTIONS_STANDARD.md](COLLECTIONS_STANDARD.md) to classify every accepted Skill before integration. After ingestion, all distributable releases must follow [PRODUCTION_STANDARD.md](PRODUCTION_STANDARD.md). Ingestion never authorizes an independent rewrite of a chat or collection package.

This document is the source of truth for bringing new Skill sources into this warehouse. It is independent of any LLM, vendor, interface, or runtime. Apply it together with [PORTABILITY_STANDARD.md](PORTABILITY_STANDARD.md): this document governs ingestion; the portability standard governs canonical Skill content.

## 1. Default interpretation of a message

When a user supplies one or more apparent Skill sources without another instruction, treat the message as an ingestion request.

Inspect all source-bearing parts of the current context that the runtime can actually access:

- text in the current message;
- repository, subdirectory, or other accessible URLs;
- absolute or relative local paths;
- ZIP files and other archives;
- individual `SKILL.md` files or groups of files;
- files attached to the current message;
- files attached to the current conversation or session, when accessible;
- any combination of these forms.

Transport does not change the workflow. A URL, local path, attached file, archive, repository, and pasted file are all ways to provide a **source**.

If several sources appear in one message, process them as one batch unless the user explicitly separates them. Do not ask where a source is when it is already identifiable and accessible. Ask for clarification only when no source can be identified, a source cannot be opened with the available capabilities, or a material ambiguity cannot be resolved safely.

An instruction accompanying the sources takes precedence over the default ingestion interpretation. Supplying a source does not by itself authorize unrelated external changes, publication, installation, or execution of unsafe code.

## 2. Resolve sources by capability

Use the capabilities available in the current runtime, without depending on proprietary tool names:

- **attached-file access capability** for files supplied with the current message or session;
- **filesystem capability** for local paths and directories;
- **repository-access capability** for repositories and repository subdirectories;
- **web-access capability** for other reachable URLs;
- **archive-extraction capability** for ZIPs or other supported archives;
- **agent delegation capability** only when available and useful, never as a requirement.

Prefer read-only resolution. Copy resolved material into `intake/incoming/` before analysis and do not modify the supplied source.

### Graceful degradation

- If one resolution capability is absent, try another faithful method available in the runtime.
- If a repository URL cannot be cloned but its files are readable, inspect or download the relevant files without claiming a clone was performed.
- If an archive cannot be extracted, report that precise limitation and do not infer its contents.
- If an attached file is mentioned but unavailable to the runtime, ask the user to attach it again or provide an accessible path or URL.
- Never invent access, contents, provenance, hashes, validation results, or successful ingestion.

## 3. A source is not necessarily a Skill

A source can contain zero, one, or many Skills. A repository, archive, directory, attachment set, or URL must be inspected before its Skill units are known.

A candidate Skill normally has a coherent directory rooted at `SKILL.md`, plus only the scripts, references, assets, metadata, and other resources its workflow actually needs. Locate and understand these units before integration.

Never copy an entire source into a collection's `skills/` merely because it was provided. Repository infrastructure, documentation indexes, caches, examples, deprecated content, unrelated projects, and other non-Skill material remain outside the active library unless a discovered Skill genuinely requires a resource.

A source containing no valid Skill is a valid inspection result. Record or report the reason; do not manufacture a Skill.

## 4. Mandatory batch pipeline

Every explicit or implicit ingestion runs this pipeline in order:

INGEST → RESOLVE SOURCES → INSPECT → IDENTIFY SKILLS → SECURITY CHECK → FILTER → CLASSIFY COLLECTION → DEDUPLICATE WAREHOUSE-WIDE → PORTABILITY AUDIT → LLM-AGNOSTIC NORMALIZATION → LICENSE AUDIT → PRESERVE ORIGINAL → INTEGRATE INTO COLLECTION → UPDATE COLLECTION REGISTRY → UPDATE COLLECTION LICENSES → UPDATE WAREHOUSE INDEX → PACKAGE COLLECTION → VALIDATE → GENERATE SHA-256

### INGEST

Identify the whole batch from the current message and accessible context. Preserve the user's grouping unless instructed otherwise.

### RESOLVE SOURCES

Resolve each source through available capabilities and place a read-only working copy under `intake/incoming/`. Record source identity, transport form, and any version, commit, URL, or path that can be established honestly.

### INSPECT

Inventory the resolved source before executing anything. Examine structure, `SKILL.md` files, referenced resources, scripts, metadata, licenses, provenance, and maintenance-only content.

### IDENTIFY SKILLS

Determine the actual Skill boundaries. A source may yield zero, one, or many candidates. Keep each candidate self-contained and exclude unrelated source material.

### SECURITY CHECK

Inspect scripts, commands, hooks, network behavior, secret handling, external side effects, destructive operations, binary files, and suspicious or obfuscated content. Inspection does not authorize execution. Quarantine or reject unsafe or unverifiable candidates and record the reason.

Run the mandatory static SkillSpector gate before a candidate can be integrated. The pinned tool identity is `tools/skillspector-lock.json`; invoke `tools/scan-skillspector.py` on each candidate Skill and retain its aggregate JSON report under `provenance/skillspector/`. The scanner runs with `--no-llm`: semantic analysis is optional additional evidence, never a substitute for this reproducible static gate. A scanner error, incomplete analysis, or HIGH/CRITICAL finding is `OPEN — SKILLSPECTOR SECURITY REVIEW`; do not activate or package that Skill without an explicit recorded Owner decision and an evidence-bound suppression or remediation.

### FILTER

Exclude deprecated, obsolete, experimental, WIP, in-progress, cache, vendored dependency, build-output, repository-infrastructure, and irrelevant content unless explicitly requested and safe.

### CLASSIFY COLLECTION

Apply [COLLECTIONS_STANDARD.md](COLLECTIONS_STANDARD.md). Classify by primary user outcome, select the narrowest approved category, and give each Skill exactly one canonical home. Record cross-domain relevance as registry metadata rather than copying the Skill. An unresolved classification becomes `OPEN — COLLECTION CLASSIFICATION`.

### DEDUPLICATE

Compare folder name, frontmatter `name`, purpose, provenance, original and canonical hashes, and full content across every collection plus the legacy `skills/` snapshot and registries. Identical content is not copied again. Ambiguous version collisions become `OPEN — VERSION CONFLICT`; never overwrite silently.

### PORTABILITY AUDIT

Read and apply [PORTABILITY_STANDARD.md](PORTABILITY_STANDARD.md). Classify each candidate and distinguish intrinsic dependencies from accidental runtime coupling.

### LLM-AGNOSTIC NORMALIZATION

Normalize only accidental coupling. Describe capabilities rather than proprietary tools, preserve useful intent and workflow, add truthful degradation paths, and isolate legitimate runtime-specific translations in adapters when necessary.

### LICENSE AUDIT

Identify the licence that actually applies to each Skill and required companion file. Record the exact source and evidence. Never infer MIT from public availability or from a dependency's licence. Use `NOASSERTION` when no licence grant is found, and require an explicit Owner decision for missing, ambiguous, incompatible, or restrictive cases as defined by [PRODUCTION_STANDARD.md](PRODUCTION_STANDARD.md).

### PRESERVE ORIGINAL

Before changing a candidate, preserve its complete original under `sources/originals/<source>/<version-or-commit>/` and verify its hashes. Originals are evidence, never active Skills, and never enter a collection release.

### INTEGRATE INTO COLLECTION

Place only accepted canonical Skill units in `skill-collections/<collection-slug>/skills/`. Do not overwrite an ambiguous existing Skill or duplicate it in another collection. Keep all required local resources and valid relative references. Root `skills/` is legacy history and is changed only by an explicit migration.

### UPDATE COLLECTION REGISTRY, COLLECTION LICENSES, AND WAREHOUSE INDEX

Update the owning collection's `registry.md` and `LICENSES.md`, the warehouse index, integrity records, and compatibility report as applicable. Record provenance, original and canonical hashes, collection classification, changed files, licence evidence, reason, status, batch result, exclusions, duplicates, and open conflicts.

### PACKAGE COLLECTION

After external staging and validation, create an immutable release under `deliverables/<collection-slug>/<YYYY-MM-DD-label>/`. Rebuild the ZIP for every included Skill and the owning collection ZIP from the same cleaned bytes. Exclude originals, intake, other collections, all release directories, recursive archives, repository metadata, caches, and temporary artifacts.

### VALIDATE

Validate structure, collection ownership, security disposition, provenance, warehouse-wide deduplication, licences, portability, integrity inventory, local references, documentation consistency, individual ZIPs, collection ZIP contents, and all exclusions. A partial or simulated check is not `PASS`.

### GENERATE SHA-256

After the final validated release is in place, generate SHA-256 entries under that collection release's `SHA256SUMS.txt`. The reported hashes must match the actual delivered files.

## 5. Repository zones

- `skill-collections/` — canonical domain collections and their machine-readable category catalog.
- `skill-collections/<collection>/skills/` — canonical active Skills owned by one collection.
- `skill-collections/<collection>/releases/` — immutable collection-owned deliveries.
- `sources/` — provenance registry, integrity inventories, operational procedures, validators, and distributable source documentation.
- `sources/originals/` — local, non-active provenance archive excluded from distribution.
- `intake/incoming/` — unresolved or newly resolved batch material.
- `intake/processed/` — validated candidates and temporary packaging candidates.
- `intake/rejected/` — rejected or quarantined material with reasons when retention is appropriate.
- Root `skills/` and `dist/` — immutable legacy snapshot and releases pending explicit migration.

## 6. Completion states

An ingestion is complete only when every source and candidate in the batch has a recorded outcome:

- `ACTIVE` — accepted, normalized if necessary, registered, packaged, and validated;
- `DUPLICATE` — already represented canonically; provenance may be added without duplicating content;
- `REJECTED` — excluded with a concrete security, structure, scope, or quality reason;
- `OPEN` — unresolved ambiguity or required decision prevents safe integration.

Report `PASS` only when the batch has no unreported candidate, all required artifacts are coherent, and generated hashes match delivered files. List every `OPEN` item explicitly.

## 7. Persistence and authority

This standard must be sufficient without conversation history. Future humans, LLMs, and agents reconstruct expected behavior from the repository itself:

- [README.md](README.md) defines warehouse identity and general use;
- [COLLECTIONS_STANDARD.md](COLLECTIONS_STANDARD.md) defines architecture, categories, classification, and migration behavior;
- this file defines ingestion behavior;
- [PORTABILITY_STANDARD.md](PORTABILITY_STANDARD.md) defines portability behavior;
- [PRODUCTION_STANDARD.md](PRODUCTION_STANDARD.md) defines collection release behavior;
- [AGENTS.md](AGENTS.md) is the short operational entrypoint.

Runtime-specific files may point to these documents or translate optional mechanics. They must not define a competing policy.
