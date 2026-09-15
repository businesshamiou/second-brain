# Legacy-to-collections migration report

Date: `2026-09-02`

Result: **PASS**

## Source lineage

- Conformance source: `dist/2026-09-01-conformance/affiliate-pro-skills-full.zip`
- Conformance source SHA-256: `0314157a4f57ba7428506d3f3d5ab31e5118e96c5b2d81f880280dac9db89056`
- Historical master SHA-256 preserved: `e23edad2c53db59d9e10445c04e8c9b5733e47e69e06c7585505658dbf4fe45f`
- Migration map: `sources/legacy-collection-migration.json`

## Migration result

| Collection | Active Skills | Skill files | Release | Collection ZIP SHA-256 |
|---|---:|---:|---|---|
| `software-engineering` | 29 | 86 | `2026-09-02-migration-v1` | `bddfb9f5ea3484f790c36e6a11de84e8378831e87c235514e2b67f00735d300f` |
| `web-design` | 2 | 21 | `2026-09-02-migration-v1` | `c389a8f729294064b489fc17536c6e3aff3e3f34b8f02044c1e5d2081a0e3409` |
| `visual-content` | 2 | 106 | `2026-09-02-migration-v1` | `fbf91b1eb7c5bf3ad5be2f7219d3491e179ad6e43f4d9934c1cf59b9f24b09c2` |
| **Total** | **33** | **213** | **3 releases** | — |

## Verified invariants

- Approved catalog categories: **9**, unique.
- Active collections: **3**.
- Active Skill names: **33**, warehouse-wide duplicates: **0**.
- Active trees identical to the immutable conformance source: **33/33**.
- Bodies and companion files changed by migration: **0**.
- Collection releases reopened and validated: **3/3**.
- Chat/collection package byte identity: **33/33**.
- Release checksum entries verified: **45/45**.
- Legacy master and conformance package hashes unchanged: **2/2**.
- Owner licence exceptions preserved: `excalidraw-automate`, `script-to-whiteboard-storyboard`, and `scroll-film-studio`.

## Legacy disposition

Nothing was removed. Root `skills/`, root `dist/`, legacy registries, indexes, manifests, reports, ZIPs, and published SHA-256 values remain as pre-migration historical evidence. Canonical active Skills now live only under `skill-collections/<collection>/skills/`.
