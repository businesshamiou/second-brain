---
type: decision
title: "Adoption of the OKF format as the reference standard"
created_at: 2026-08-19T11:53:06-04:00
timezone: America/Montreal
status: active
scope: vault-artifact-format
owner_gate: granted
source_proposal: none
---

# DECISION — ADOPTION OF THE OKF FORMAT

## Context

The Vault has developed its own artefact conventions: Markdown, typed YAML front matter, relative links, Git versioning. A comparison with Open Knowledge Format v0.2, an open, vendor-neutral format published by Google Cloud Platform, showed strong convergence and conformance already achieved.

Reference: https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf

## Conformance observed

The Vault meets the three OKF v0.2 conformance criteria without modification: parsable YAML front matter on every document, a non-empty `type` field everywhere, no non-conforming use of the reserved names `index.md` and log.md.

## Decision

The project adopts OKF as the external reference standard for the format of its knowledge artefacts, and cites it as such in the workshop's teaching production.

Adoption is gradual and without disruption.

### Adopted immediately

- `index.md` per top-level folder of the Vault, for progressive disclosure: an agent reads the index before deciding which files to open. This also makes visible in Git the folders that would otherwise be empty.
- `stale_after` on artefacts subject to going stale, starting with the entries of the [Project Registry](../projects/PROJECT-REGISTRY.md).
- A `description` field in the front matter of newly created artefacts.

### Kept as is, and documented as an accepted deviation

- Lower-case `type` values. OKF does not register these values centrally and imposes no case; the stock freeze rule moreover forbids any retroactive renaming.
- A `status` field carrying a business status (`AUTHORIZED`, `ARBITRATED`, `COMPLETED`, `PROPOSED`) where OKF reserves it for the document lifecycle. The deviation is accepted and traced here.

### Postponed

- Structured `generated` and `verified` with an actor convention. The OKF trust tiers correspond exactly to the project's VERIFIED / DECLARED doctrine; alignment will have value when Skills make use of these fields.
- A structured `sources` field.
- log.md per scope.

## Consequences

No migration, no renaming, no rewriting of any existing artefact. The Vault's file-naming conventions remain the only source on this point: OKF does not specify naming.

A future alignment of the postponed points will be the subject of a distinct cumulative Decision.

## Human gate

Owner arbitration given in a steering session.

## Liens

- `see also` — [Project Registry](../projects/PROJECT-REGISTRY.md)
