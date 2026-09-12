# Thin-repository migration — 2026-09-02

## Decision

The repository retains canonical active Skills, governance, compact provenance and validators in Git. Full upstream originals, historical root layouts and generated ZIPs were externalized to the private immutable release `legacy-archive-2026-09-02`.

## Removed from the working tree

- duplicate legacy active tree: `skills/`;
- generated output: `dist/` and collection `releases/` directories;
- upstream snapshots and old staging: `sources/originals/`, `intake/`;
- superseded legacy producers and records under `sources/`.
- historical root reports: `compatibility-report.md`, `index.md`, `manifest.md`, and `SOURCE.md`.

Asset URLs and SHA-256s are in [cold archive provenance](../../provenance/cold-archive-2026-09-02.json). The migration retains 33 active Skills in 3 collections, preserves names/bodies/companions, keeps collection registry and licence records, and records canonical tree hashes in `provenance/migration-2026-09-02.json`.
