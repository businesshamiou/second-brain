# Agent entrypoint

> **Read [THIN_REPOSITORY_STANDARD.md](THIN_REPOSITORY_STANDARD.md) first.** It is the current architecture and supersedes historical path references below. Active Skills exist only under `skill-collections/<collection>/skills/`; generated archives belong only in complete validated version directories under `deliverables/`, and full source snapshots never belong inside Git.

Architecture and classification are governed by [COLLECTIONS_STANDARD.md](COLLECTIONS_STANDARD.md). Release production is governed by [PRODUCTION_STANDARD.md](PRODUCTION_STANDARD.md). Read both before integrating, moving, packaging, or releasing any Skill.

All system nomenclature is English under [SYSTEM_NAMING_STANDARD.md](SYSTEM_NAMING_STANDARD.md); prose may be French.

1. Read [README.md](README.md) to understand this warehouse.
2. Read and apply [COLLECTIONS_STANDARD.md](COLLECTIONS_STANDARD.md) to resolve the owning collection and canonical paths.
3. Before any ingestion, read and apply [INGESTION_STANDARD.md](INGESTION_STANDARD.md).
4. Before integrating or updating any Skill, read and apply [PORTABILITY_STANDARD.md](PORTABILITY_STANDARD.md).
5. Before producing any release, read and apply [PRODUCTION_STANDARD.md](PRODUCTION_STANDARD.md).
6. Use [sources/COLLECTION-OPERATIONS.md](sources/COLLECTION-OPERATIONS.md) for current repository commands and validation entrypoints.
7. Treat the standards as the source of truth; runtime-specific files and command wrappers must not define competing policy.
8. A message containing only one or more source URLs, paths, files, archives, or attachments is an ingestion request by default. Treat multiple sources as one batch unless instructed otherwise.

Never treat `sources/originals/`, `intake/`, another collection, or a release directory as active Skills. Root `skills/` and `dist/` are immutable pre-migration history. Report `PASS` only after the canonical collection pipeline and validation complete.
