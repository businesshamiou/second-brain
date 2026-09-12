# Thin Repository Standard

This is the current architecture contract for Skills Warehouse. It is LLM-, vendor-, interface-, and runtime-agnostic. It supersedes historical path references in prior standards without changing their substantive rules for classification, ingestion, portability, front matter, licensing, or validation.

## System language

All system nomenclature is English. Paths, directory names, file names, collection slugs, schema keys, metadata keys, status values, release labels and machine-readable identifiers follow [SYSTEM_NAMING_STANDARD.md](SYSTEM_NAMING_STANDARD.md). Human-facing prose may be French.

## Canonical repository state

```text
skill-collections/<collection>/{README.md,registry.md,LICENSES.md,skills/<skill>/...}
deliverables/<collection>/<YYYY-MM-DD-label>/  # immutable validated package outputs
provenance/     # compact source, licence, integrity and archive evidence
logs/           # dated ingestion, migration and release decision records
tools/          # reproducible local validation and packaging tools
```

`skill-collections/<collection>/skills/` is the only active Skill tree. A Skill appears in exactly one collection; its directory matches `name` in `SKILL.md`.

The repository must not contain `skills/`, `dist/`, `intake/`, `sources/`, collection `releases/`, caches, dependency directories or source snapshots. Generated ZIPs are prohibited everywhere except a complete, validated, immutable version directory under `deliverables/`. Resolve and inspect a new batch in an operating-system temporary directory or another explicitly external workspace.

## Evidence and archival policy

Record source URL, revision, licence evidence, original/canonical hashes, classification and decisions in collection records and `provenance/`. Store lightweight licence text locally when available. Full originals and raw intake are stored externally. Validated package binaries are committed under `deliverables/`; an optional external mirror has a durable URL and SHA-256 in a committed provenance or release-log record.

The pre-thin-repository material is retained at the private GitHub Release `legacy-archive-2026-09-02`; its complete asset map is `provenance/cold-archive-2026-09-02.json`.

## Ingestion and delivery

Follow the canonical pipeline already defined by `INGESTION_STANDARD.md`, with these locations:

1. resolve, inspect, security-check and stage outside Git;
2. preserve original evidence externally and record hashes/provenance locally;
3. integrate only valid canonical units into one collection;
4. update that collection's registry and licence inventory plus warehouse indexes;
5. package chat and collection ZIPs from the same external cleaned tree;
6. validate every observable invariant, copy the complete immutable delivery into `deliverables/<collection>/<YYYY-MM-DD-label>/`, and commit it with its report facts and SHA-256s. An external mirror is optional, never the sole canonical delivery.

Run `python tools/validate-warehouse.py` before declaring `PASS`. The validator checks active structure, records, uniqueness, six-field front matter, migration integrity and the cold-archive manifest. It cannot prove availability of a remote artifact without network access; that check must be stated separately when performed.
