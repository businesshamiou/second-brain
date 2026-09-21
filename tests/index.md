---
type: index
title: "Vault tests"
description: "Scenarios that verify the system's behaviour."
created_at: 2026-08-19T11:53:06-04:00
timezone: America/Montreal
status: active
---

# Vault tests

Scenarios that verify the system's behaviour.

This file is kept by hand: `tools/build-indexes.sh` indexes only Markdown documents with front matter, and a test is a script. The complete inventory remains the folder itself; the sequence per system is [`suite.tsv`](./suite.tsv), the single source of truth for what runs where, played identically locally and in CI by [`run-suite.sh`](./run-suite.sh) (and [`run-suite.ps1`](./run-suite.ps1) on Windows) — `bash tests/run-suite.sh` plays the whole suite. [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) now only calls this launcher, after the shared action [`setup-test-env`](../.github/actions/setup-test-env/action.yml) (uv, Python and pre-commit, cached).

## Contents

Each test returns a closed verdict — `PASS`, `FAIL`, or `SKIP (cause, platform)` — and carries its own negative control: the same measurement, on a case built to fail. A test without a control does not prove it can fail.

### Publishing from the laboratory — Mission 192 (v0.1.9)

- `test-publish-from-laboratory.sh` (W / U / M) — one command publishes the laboratory as a fast-forward, the closed list kept from `release`; second run: nothing to publish; third-party advance and a widening argument refused.
- `test-private-patterns-lab-exemption.sh` (U) — `projects/` exempt in a laboratory only; never on `publish`, never outside `projects/`.
- `test-workshop-gitignore-links.sh` (U) — an existing `.gitignore` given the three link exclusions gets its links; `git status` shows none.
- `test-backup-oracle.sh` (U) — a bundle is proven by restoring it; a truncated pack fails where `git bundle verify` passes.

### Publishing, the check before every push — Mission 198

- `test-publish-private-check-before-push.sh` (W / U / M) — the private-pattern check runs once before every push of the publication tool, also when `publish` is already ahead of `release` with nothing to commit; a private pattern is refused on both paths, a clean tree is published on both, a laboratory already published is left alone.

### Two work regimes — Mission 199

- `test-check-work-regime.sh` (W / U / M) — the work-regime check refuses a gesture that meets a full-regime criterion (push to the published repository, deletion, doctrine, refs, company repository, guardians) and the Note's wrong form, each refusal with its accepted twin; `diff` on a real change; the template is a valid Note; the criterion ids of the tool and of the rule stay the same set.

### Fan-out — Mission 201

- `test-fan-out-rubric.sh` (W / U / M) — the Mission template's optional `## Fan-out` rubric: exactly one, before `## Steps`, every other rubric kept, additions only; the skill instruction in at most ten lines naming `dispatching-parallel-agents`; the rubric form refused for a batch with no output, an output inside a repository, a duplicate name, no targets; an absent or empty rubric stays valid.

### The server named after its workspace — Mission 206 (v0.1.12)

- `test-install-vault-mcp-workspace-label.sh` (W / U / M) — the server is `second-brain-vault-<workspace_label>`: label posed by the installer and normalised alike in shell and Python; former key of the same Vault migrated; `workshops` retired on request, a Vault's key never; two Vaults with one label refused, suffixed name proposed, nothing written; `--skip-desktop`.
- `test-project-bootstrap-refresh-prompt.sh` (W / U / M) — `project-bootstrap.sh prompt <dossier>` regenerates a project's Pilot prompt (old and current formats), keeping its canary and identity.

### One MCP server per Vault, and the update — Mission 191-C01 (v0.1.8)

- `test-install-vault-mcp-name-per-vault.sh` (W / U / M) — two Vaults, two servers named after their identity; idempotent; former name migrated; crossed identity refused.
- `test-check-mcp-containment-per-vault.sh` (W / U / M) — containment finds the server of the project's own Vault.
- `test-project-instructions-name-server.sh` (W / U / M) — Project instructions and Pilot prompt name this Vault's server.
- `test-agents-language-line.sh` (U) — `AGENTS.md` and `CLAUDE.md`: corpus in English, the participant's language from `USER.md`.
- `test-update-installed-vault.sh` (W / U / M) and `.ps1` (W) — `second-brain update` from v0.1.7 to v0.1.8 over local commits; conflict, altered identity, temporary origin and the install line on an existing workspace all refused with nothing touched.

### Windows shards and tag checkout — Mission 189 (v0.1.7)

- `test-shards-cover-suite.sh` (U) — the three Windows shards play every W line once.
- `test-suite-on-detached-head.sh` (U) — the suite holds on a detached HEAD.
- `test-no-push-formula.sh` (U) — now also reads `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.codex/`.

### Corpus in English — Mission 187 (v0.1.6)

- `test-corpus-language-english.sh` (W / U / M) — no corpus file above the French threshold.
- `test-links-targets-unchanged.sh` (U) — link targets as frozen at `653910c`.
- `test-skill-triggers-bilingual.sh` (U) — skill triggers in both languages.
- `test-published-line-ref.sh` (U) — the published line and the bootstraps name one tag.

### Reusable test bench — Mission 188

- T1 `test-suite-manifest-matches-ci.sh` (U) — `suite.tsv` = the `ci.yml` suite at `42f74e6a` (108 triplets).
- T2 `test-run-suite-reports-red.sh` (W / U / M) — the launcher plays everything, counts, names the reds.
- T3 `test-setup-test-env-offline.sh` (U, CI) — the cached environment answers offline.
- T4 `test-reference-clone-equivalence.sh` (U) — the reference clone installs the same thing.

### Play only what changed — Mission 209

- `test-run-suite-changed.sh` (W / U / M) — `run-suite.sh --changed [<ref>]` plays the two guardian lines and the lines the changed files name, the whole suite when the runner or the manifest changes; `run-suite.ps1 -Changed` lists the same lines.

### Opening step zero and guardian launches — Missions 215 and 214

- `test-pilot-opening-step-zero.sh` (W / U / M) — the opening carries a step zero, in the reading list, the opening prompt and the rendered block; a copy without it fails.
- `test-check-asserted-paths-constant-launches.sh` (W / U / M) — the guardian's external launches are counted, and a larger corpus adds none.

### Missions 186 and 185-C01

Their tables are frozen in [`index-archive-2026-09.md`](./index-archive-2026-09.md).

### Earlier families

- **End-to-end install** — `test-install-e2e.ps1` / `.sh`, `test-bootstrap-no-git.ps1`, `test-install-standard-user.ps1`, `test-prerequisites-e2e.ps1`.
- **Project initiation and adoption** — `test-project-initiation.sh`, `test-project-bootstrap-path-validation.sh`, `test-project-structure-standard-conformity.ps1`.
- **Embedded MCP server** — `test-vault-mcp.sh` (server, injection on a simulated profile, containment).
- **Guardians** — `test-githooks-run-on-commit.sh`, `test-guardian-offline-commit.sh`, `test-guardian-path-special-chars.sh`, `test-guardian-secret-refusal.sh`, `test-exec-bit-bare-scripts.sh`.
- **Questionnaire and assistant** — `test-questionnaire-*.ps1`, `test-assistant-*.ps1`.
- **Portability and vocabulary** — `test-participant-shell-portability.sh`, `test-nominal-flow-no-atelier-vocabulary.ps1` / `.sh`, `test-distributed-documents-no-atelier-vocabulary.ps1` / `.sh`.

## Liens

- `see also` — [Vault tests — archive 2026-09](./index-archive-2026-09.md)
- `see also` — [Guardrails and levels of evidence](../rules/RULES-2026-08-19-210803-guardrails-and-evidence-levels.md)
- `prescribed by` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
