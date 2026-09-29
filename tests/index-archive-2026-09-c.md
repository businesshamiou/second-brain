---
type: index
title: "Vault tests — archive 2026-09 (c)"
description: "Frozen part of the tests index, third slice: the families of Missions 220, 221 and 222, moved out of tests/index.md by Mission 234 when it reached its 8,000-byte cap; the first two slices are full."
created_at: 2026-09-26T12:20:00-04:00
timezone: America/Montreal
status: active
---

# Vault tests — archive 2026-09 (c)

Frozen. The live index is [`index.md`](./index.md); the earlier slices are [`index-archive-2026-09.md`](./index-archive-2026-09.md) and [`index-archive-2026-09-b.md`](./index-archive-2026-09-b.md).

### gum in the installation questionnaire — Mission 220

- `test-install-gum-branch.sh` (W / U / M) — in a terminal the nine questions are displayed by gum (a fake gum, forced terminal in test mode), with the same files written as the plain questionnaire; a missing gum is installed by winget or brew, a failure falls back in one line; an answers file or no terminal never calls gum or an installer.

### Deferred corrections — Mission 221

- `test-conformity-registry-anchored.sh` (W / U / M) — a register entry is found by its path column only.
- `test-install-workspace-too-deep.sh` (W / U / M), `.ps1` (W) — on Windows a root past the measured maximum (118) is refused before any write.
- `test-bootstrap-keyboard.sh` (W / U / M) — `curl … | bash` gives `install.sh` the keyboard.
- `test-check-private-patterns.sh`: a Google API key shape is refused, masked.

### Publication readiness — Mission 222

- `test-publish-version-line.sh` (W / U / M) — `publish-from-laboratory.sh --version <tag>` makes the published install line and both bootstrap defaults name that tag, the laboratory's main untouched; `--dry-run` commits and pushes nothing; `set-release-version.sh` keeps line endings and refuses a tag that is not vX.Y.Z.

- `test-assistant-doc-map.ps1` (W) — both generators append the documentation map (`docs/MAP.md`) to the assistant's three forms and set `model: haiku` on the subagent; without the map they refuse; the three test questions of `ASSISTANT.md` and three documentation questions each find their row.

### Repository-root guard and verified push — Mission 226

- `test-repo-root-guard.sh` (W / U / M) — the writing tools (`build-indexes`, `append-journal`, `build-state`, `build-digest`, `set-release-version`, `vault-identity ensure`, `propose-link-repairs`, `project-bootstrap`) refuse the workspace root, a folder in no repository and a relative path out of one, 0 file written; a repository root writes as before.
- `test-verified-push.sh` (W / U / M) — `verified-push.sh` refuses a relative or non-root path, a stale range, a foreign remote, a rewritten history and `--force`; pushes a valid range, checked by `ls-remote`.
- `test-docs-reference-coverage.sh` (W / U / M) — every script of `tools/` has its sheet or its line in the reference documentation (`docs/reference/tools-*.md`).

## Liens

- `see also` — [Vault tests (live index)](./index.md)
- `see also` — [Vault tests — archive 2026-09](./index-archive-2026-09.md)
- `see also` — [Vault tests — archive 2026-09 (b)](./index-archive-2026-09-b.md)
