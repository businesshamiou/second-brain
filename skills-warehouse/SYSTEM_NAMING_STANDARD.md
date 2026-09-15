# System Naming Standard

This is the permanent naming-language contract for Skills Warehouse. It is runtime- and LLM-agnostic.

## Rule

All system nomenclature is English. This includes repository directories, file names, collection and category slugs, schema keys, metadata keys, status values, release labels, command names, and machine-readable identifiers.

System names use ASCII lowercase `kebab-case` unless a file format or established upstream interface requires another conventional form (for example `SKILL.md`, `SHA256SUMS.txt`, JSON keys, or Python identifiers).

Canonical repository terms include `skill-collections`, `deliverables`, `provenance`, `logs`, `tools`, `registry`, `manifest`, `validation-report`, and `release`.

## Human prose

Human-facing prose may be written in French or another appropriate language. This permission never changes paths, identifiers, metadata keys, or status values into French.

## Boundaries and changes

Do not rename third-party source files, canonical Skill names, or their bodies merely to translate them: those are content or provenance, not warehouse system nomenclature. A deliberate system-name migration must update every local reference, validation rule, manifest, and release record in the same change; it must never silently overwrite a published deliverable.

## Current audit

The canonical delivery directory is `deliverables/` — the English plural noun. The current canonical root names comply with this standard. `livrables` is not a repository system path.
