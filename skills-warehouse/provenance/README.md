# Provenance

This directory is the durable, lightweight audit layer. It records source identity, licence evidence, integrity, migration mappings, and the external location of large artifacts. Collection-level `registry.md` and `LICENSES.md` are the per-Skill source of truth.

Large originals and ZIPs deliberately remain outside Git. Retrieve them from the recorded URL and verify their SHA-256 only when audit or update work needs them.
