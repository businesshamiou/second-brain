# Canonical Collections Standard

> **Current layout amendment:** [THIN_REPOSITORY_STANDARD.md](THIN_REPOSITORY_STANDARD.md) is authoritative for artifact locations. The active collection contract remains authoritative here; historical references below to local `releases/`, `sources/`, `intake/`, root `skills/`, or `dist/` describe the pre-2026-09-02 layout only.

This document is the source of truth for organizing the Skills Warehouse into domain collections. It is LLM-, vendor-, interface-, and runtime-agnostic. A human or agent must be able to reconstruct the repository's organization from this file without conversation history.

## 1. Canonical architecture

New active Skills belong to exactly one canonical collection:

```text
skill-collections/
  <collection-slug>/
    README.md
    registry.md
    LICENSES.md
    skills/
      <skill-name>/
        SKILL.md
        ... companion files
    releases/
      <YYYY-MM-DD-label>/
        <collection-slug>-skills-full.zip
        chat-zips/
          <skill-name>.zip
        manifest.md
        LICENSES.md
        validation-report.md
        SHA256SUMS.txt
```

Shared source evidence and temporary intake remain outside active collections:

```text
sources/originals/<source-id>/<version-or-commit>/...
intake/incoming/...
intake/processed/...
intake/rejected/...
```

`sources/originals/` and `intake/` are never active Skills and never enter a collection release.

## 2. Naming rules

- Repository display name: **Skills Warehouse**.
- Collection root: `skill-collections/`.
- Collection slugs use stable lowercase kebab-case.
- Skill directories use stable lowercase kebab-case and exactly match front-matter `name`.
- Provider, author, campaign, customer, or temporary project names are provenance, not collection names.
- A collection ZIP is named `<collection-slug>-skills-full.zip`.
- A chat ZIP is named `<skill-name>.zip`.
- Releases are immutable and use `releases/<YYYY-MM-DD-label>/`.
- Renaming a collection or Skill is a declared migration, never a silent packaging change.

## 3. Canonical category catalog

The machine-readable mirror is `skill-collections/catalog.json`. This table defines the meaning of every approved category.

| Slug | Meaning | Includes | Excludes or redirects |
|---|---|---|---|
| `software-engineering` | Building, testing, maintaining, debugging, reviewing, and architecting software. | Code review, TDD, Git, debugging, domain modeling, repository architecture, implementation workflows. | Visual design goes to `web-design`; game-specific systems go to `game-development`. |
| `web-design` | Designing and implementing websites and browser-based visual experiences. | Landing pages, UI composition, CSS, motion, scroll, canvas, WebGL, Three.js, interaction design. | General engineering workflows go to `software-engineering`; non-web illustration goes to `visual-content`. |
| `visual-content` | Creating visual narratives and non-site visual artifacts. | Storyboards, diagrams, Excalidraw workflows, illustration systems, visual explanation. | Full websites go to `web-design`; audio/video production pipelines go to `media-production`. |
| `game-development` | Designing, implementing, testing, and shipping games. | Gameplay, combat, AI, levels, game cameras, game assets, playable browser games. | Generic Three.js presentation sites go to `web-design`. |
| `research-writing` | Discovering, evaluating, synthesizing, and communicating knowledge. | Research, cited synthesis, specifications, questionnaires, teaching, structured writing. | Marketing copy belongs to `business-marketing`; operational automation belongs to `automation-workflows`. |
| `automation-workflows` | Orchestrating repeatable actions across tools, services, repositories, or human gates. | Publishing, capture pipelines, scheduled workflows, external integrations, operational handoffs. | A provider-specific integration remains here only when automation is the primary outcome; otherwise classify by domain. |
| `media-production` | Producing or transforming audio, video, images, and related media assets. | TTS, voiceover, video capture, image sourcing, media conversion, asset generation. | Storyboarding without media production goes to `visual-content`. |
| `business-marketing` | Supporting commercial communication, acquisition, conversion, positioning, and business operations. | Marketing content, conversion workflows, social publishing, offer and campaign systems. | Page implementation remains `web-design`; general writing remains `research-writing`. |
| `general-purpose` | Truly cross-domain agent workflows with no honest dominant domain. | Narrow reusable coordination or reasoning workflows that apply equally across collections. | Never use as a default or uncertainty bucket; ambiguous cases become `OPEN`. |

New category slugs require an explicit Owner decision and updates to both this table and `skill-collections/catalog.json` in the same change.

## 4. Classification algorithm

Classify each accepted Skill before integration:

1. Identify the Skill's primary user outcome, not its implementation technology or source repository.
2. Select the narrowest approved category whose definition covers that outcome.
3. Give the Skill one canonical home only. Cross-domain relevance is recorded as tags or related collections in the registry, never by duplicating the Skill.
4. Keep an intrinsic provider dependency explicit, but do not create a provider-named category.
5. If two categories remain equally plausible and the primary outcome cannot be established from evidence, set `OPEN — COLLECTION CLASSIFICATION` and do not integrate.
6. Use `general-purpose` only when the workflow is genuinely domain-neutral; lack of analysis is not sufficient.

Deduplication is warehouse-wide, not merely collection-local. The same canonical Skill name cannot silently exist in two collections.

## 5. Collection contract

Every active collection contains:

- `README.md` — purpose, scope, audience, boundaries, and release instructions;
- `registry.md` — one entry per active Skill with provenance, status, hashes, classification, and compatibility;
- `LICENSES.md` — one entry per active Skill with licence, source, evidence, and exceptions;
- `skills/` — canonical active Skill folders only;
- `releases/` — immutable generated deliveries for that collection.

Optional collection-level indexes and compatibility reports may be added when useful. They must not compete with the required files above.

## 6. Ingestion and transformation pipeline

Every source follows this order:

```text
INGEST
→ RESOLVE SOURCES
→ INSPECT
→ IDENTIFY SKILLS
→ SECURITY CHECK
→ FILTER
→ CLASSIFY COLLECTION
→ DEDUPLICATE WAREHOUSE-WIDE
→ PORTABILITY AUDIT
→ LLM-AGNOSTIC NORMALIZATION
→ LICENSE AUDIT
→ PRESERVE ORIGINAL
→ INTEGRATE INTO COLLECTION
→ UPDATE COLLECTION REGISTRY
→ UPDATE COLLECTION LICENSES
→ UPDATE WAREHOUSE INDEX
→ PACKAGE COLLECTION
→ VALIDATE
→ GENERATE SHA-256
```

The content transformation rules remain those of `PORTABILITY_STANDARD.md`. Packaging remains a single-pass operation under `PRODUCTION_STANDARD.md`: the chat ZIP and collection ZIP for a Skill use the same cleaned bytes.

## 7. Release model

There is no new global `dist/` directory and no collection-local `releases/` directory. Generated outputs live in the versioned repository shelf `deliverables/<collection-slug>/<YYYY-MM-DD-label>/`.

Each release:

- is created from one cleaned staging tree;
- refuses to overwrite an existing release directory;
- packages only the owning collection;
- contains individual chat ZIPs and one collection ZIP;
- includes a manifest, licence inventory, validation report, and checksums;
- excludes originals, intake, other collections, previous releases, VCS metadata, caches, dependencies, and recursive archives.

## 8. Legacy compatibility and migration

The root `skills/` and `dist/` directories are the immutable legacy layout used by the original 33-Skill release. Existing files, releases, names, and published SHA-256 values remain untouched.

The collection migration was completed on 2026-09-02 from the immutable conformance package whose SHA-256 is `0314157a4f57ba7428506d3f3d5ab31e5118e96c5b2d81f880280dac9db89056`. Root `skills/` is no longer the active catalog; it and root `dist/` remain legacy evidence. `affiliate-pro-skills-full.zip` is a historical filename, not a future collection name.

The completed migration map for the 33 legacy Skills is:

- `software-engineering` — the 29 engineering and agent-workflow Skills sourced from `mattpocock/skills`;
- `web-design` — `scroll-world` and `scroll-film-studio`;
- `visual-content` — `excalidraw-automate` and `script-to-whiteboard-storyboard`.

The migration copied the conformant Skill trees without changing their bytes, validated names and licences, built collection releases under `2026-09-02-migration-v1`, recorded the lineage, and left every legacy release intact. Future migrations follow the same additive, versioned rule.

The immutable source, mapping, package hashes, and verified invariants are recorded in `skill-collections/migration-report.md` and `sources/legacy-collection-migration.json`.

## 9. Agent operating rules

An agent entering this repository must:

1. read `README.md`, `COLLECTIONS_STANDARD.md`, `INGESTION_STANDARD.md`, `PORTABILITY_STANDARD.md`, and `PRODUCTION_STANDARD.md`;
2. determine whether the task concerns legacy history or a canonical collection;
3. resolve category from the catalog before integrating a Skill;
4. preserve original sources and licence evidence;
5. avoid cross-collection duplication;
6. build releases only within the owning collection;
7. report `PASS` only after all observable invariants succeed;
8. use `OPEN` rather than inventing a category, licence, version, source, or validation result.

Runtime-specific instruction files may point to this standard or translate capabilities. They must not redefine the architecture.
