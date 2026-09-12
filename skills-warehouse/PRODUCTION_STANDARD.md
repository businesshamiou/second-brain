# Production Standard

> **Current delivery location amendment:** packages are produced in an external staging directory, validated, then committed under `deliverables/<collection>/<YYYY-MM-DD-label>/`. An immutable external release may mirror them, but is optional. This overrides historical local `releases/` path examples below. See [THIN_REPOSITORY_STANDARD.md](THIN_REPOSITORY_STANDARD.md).

This document is the permanent release contract for the Skills Warehouse. It is LLM-, vendor-, interface-, and runtime-agnostic and does not depend on conversation history. Collection ownership and paths are defined by `COLLECTIONS_STANDARD.md`.

## 1. One canonical pass

Every versioned collection release is generated from one temporary cleaned tree. The same bytes create both:

- one chat-upload ZIP per Skill; and
- the owning collection package `<collection-slug>-skills-full.zip`.

For a given release and Skill, `SKILL.md` must be byte-for-byte identical in both package types. One release never mixes independently edited package variants.

## 2. Allowed front matter

Only these top-level keys are allowed: `name`, `description`, `license`, `compatibility`, `allowed-tools`, and `metadata`.

- `name` exactly equals the Skill directory name.
- `description` is a single line no longer than 200 characters for chat-upload compatibility.
- `metadata` is a single-level mapping of string keys to string values.
- Runtime-specific fields are moved under `metadata` with an explicit runtime prefix when they must be preserved.
- Only front matter may be normalized during packaging.
- The body and companion files remain byte-for-byte unchanged unless an exception is declared per Skill in `validation-report.md`.

## 3. Licence evidence

Every Skill records `upstream-repo` and `upstream-license-evidence` in `metadata`. Every active collection and release contains `LICENSES.md` with one row per Skill.

Never invent or replace a licence. A missing licence is `NOASSERTION`, which is not a licence grant. Restrictive, ambiguous, incompatible, or missing licence cases require an explicit Owner decision recorded in `LICENSES.md` and `validation-report.md`.

Historical Owner exceptions remain documented in the immutable legacy release. A migration must carry their exact status forward unless the evidence or Owner decision changes explicitly.

## 4. Versioned delivery

Each new release is written once, after staging and validation, to:

```text
deliverables/<collection-slug>/<YYYY-MM-DD-label>/
```

Required contents:

```text
<collection-slug>-skills-full.zip
chat-zips/<skill-name>.zip
manifest.md
LICENSES.md
validation-report.md
SHA256SUMS.txt
```

The producer refuses to overwrite an existing release directory. Previous releases and published checksums are immutable.

`SHA256SUMS.txt` lists every delivery file except itself. Self-inclusion cannot produce a stable checksum because writing the checksum changes the file being hashed. Paths are relative to the release directory and must be compatible with `sha256sum -c SHA256SUMS.txt`.

## 5. Packaging rules

Each chat ZIP has exactly one top-level directory named after the Skill. The collection ZIP contains `skills/<skill-name>/...` plus `LICENSES.md` at its root.

Packages exclude:

- `sources/originals/` and all `intake/` material;
- other collections and all `releases/` directories;
- VCS metadata, caches, dependency directories, temporary files, and OS artifacts;
- nested or recursive ZIP files;
- any companion file excluded by a documented security or licence decision.

A whole source repository is never copied into an active package merely because it contains Skills.

## 6. Required validation

Before a release is accepted, reopen and inspect every ZIP and verify:

- the release contains only the owning collection;
- the Skill inventory matches the collection registry and manifest;
- every chat ZIP has exactly one correctly named root directory and a root `SKILL.md`;
- allowed front-matter fields, folder/name equality, one-level string metadata, and description length;
- warehouse-wide name uniqueness and zero silent duplicates;
- licence evidence and all Owner exceptions;
- body and companion-file integrity;
- byte identity of each `SKILL.md` between chat and collection packages;
- absence of forbidden paths and files;
- all recorded SHA-256 values;
- per-Skill differences from the previous collection release.
- a passing static SkillSpector report that covers every current Skill name and exact tree hash; the package producer rejects a missing, stale, partial, or non-passing report.

Report `PASS` only when every required check succeeds in reality.

## 7. Legacy production compatibility

Root `skills/`, root `dist/`, `affiliate-pro-skills-full.zip`, and `sources/build-versioned-release.py` belong to the immutable legacy 33-Skill production model. They remain valid historical evidence and must not be overwritten or silently repurposed.

The legacy producer may reproduce only its documented legacy format. New collection releases use `sources/build-collection-release.py`; warehouse-wide validation uses `sources/validate-collections.py`. These command names are replaceable implementation details, while the observable requirements in this standard remain authoritative.
