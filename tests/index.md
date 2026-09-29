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

### Secret-pattern boundary and bare links — Mission 229

- `test-check-secrets-prefix-boundary.sh` (W / U / M) — the `sk-` pattern takes a key only at a word boundary: every true positive is still refused by that line, `risk-`, `task-`, `disk-` words pass.
- `test-check-links-bare-relative.sh` (W / U / M) — a bare link (`README.md`, `docs/x.md`) resolves as `./x.md`: counted, or refused when missing; a URL, an anchor or a name without `.md` is not.

### Pre-publication fixes — Mission 223

- `test-update-installed-vault.sh` (W / U / M), amended — the update regenerates the assistant's three forms under the name the installer recorded, also when the version was merged by an older tool; without a recorded name nothing is generated.

### Night run: guard, update handover, project tooling — Mission 231

- `test-repo-root-guard-system-temp.sh` (W / U / M) — the system temporary folder is never a workspace root; the real one stays refused.
- `test-update-delegates-to-received-tool.sh` (W / U / M) — the update tool hands over to the received version's tool, once.
- `test-preflight-hook-launcher.sh` (W / U / M) — projects keep a launcher of the Vault's preflight hook; matcher with `PowerShell`.
- `test-bootstrap-gitignore-installed-skills.sh` (W / U / M) — a project's own skills are tracked; each link folder ignores its links.
- `test-check-readable.sh` (W / U / M) — an unreadable file stops staging, `takeown` and `icacls /reset` named.
- `test-troubleshoot-windows-pitfalls.sh` (W / U / M) — Store `python` alias, `GIT_OPTIONAL_LOCKS=0`, unreadable files: written down.
- `test-adopt-completes-partial-adoption.sh` (W / U / M) — `adopt` on a partially adopted project adds journal, `STATE.md`, `DIGEST.md` and changes nothing that was there.
- `test-warehouse-entry-links.sh` (W / U / M) — `skills-warehouse/AGENTS.md` and `README.md` carry no dead relative link.
- `test-verified-push-declared-url.sh` (W / U / M) — `verified-push.sh` reads `# push_url:` from a birth certificate; `--url` stays first.

### Workspace hygiene, names, session types — Mission 234

- `test-declared-temp-folder.sh` (W / U / M) — every throwaway file goes through `tools/lib/tmp.sh`: no bare `mktemp`, no `/tmp` or `$env:TEMP` in the tools, no test next to its repository; both runners export `<SB_TMP>/tests`; a root under a marker refused; `write-marker.sh` writes and keeps the three new lines.
- `test-check-workspace-root.sh` (W / U / M) — the workspace root against its computed whitelist: gaps named, a group holds only projects, provisional exceptions, organs from the marker.
- `test-resolve-vault-marker-identity.sh` (W / U / M) — a marker without identity is refused; retired, the walk resolves the enclosing workspace's Vault.
- `test-project-identity-group-accueil.sh` (W / U / M) — `SB - <Name>` in the block and the Pilot prompt; `identity --check`; `prompt` follows the registry; `--group` and the order's `Groupe`; refusals; `accueil-prompt`.
- `agent-evals/run-agent-evals.sh` (W, on demand) — headless agents on throwaway folders: first line and next gesture of each entry scenario.
- `test-common-prompt-verdict-and-e8.sh` (W / U / M) — Mission 235: the pasted common Pilot prompt puts the verdict on the first line and carries E8 (no Pilot prompt: `NOT-READY (projet non adopté)`, order proposed).

### Starting interview — Mission 240

- `test-starting-profile.sh` (W / U / M) — `sb profile` shows the « Profil de départ » section of `USER.md` and applies a profile order: that section only, every other line kept, BOM and CRLF kept, the order filed in `_archive/orders/`; four refusals leave everything unchanged; the initiation order's three optional fields and `--ask` (`sb new --ask` included) write « Profil du projet » in `README.md` and the state sheet; a project without it stays conforming.
- `test-update-user-profile-merge.sh` (W / U / M) — extended: a filled « Profil de départ » survives an update byte for byte, never doubled by the skeleton's.

### Model-agnostic hosts — Mission 242

- `test-mcp-hosts-agnostic.sh` (W / U / M) — the MCP server in every host present; length guard (M242).

### Missions 185-C01 to 219

Their tables and lists are frozen in [`index-archive-2026-09.md`](./index-archive-2026-09.md) (Missions 187, 188, 189 and 191-C01 moved there by Mission 218) in [`index-archive-2026-09-c.md`](./index-archive-2026-09-c.md) (Missions 220, 221 and 222, Mission 234; Mission 226, Mission 242) and in [`index-archive-2026-09-b.md`](./index-archive-2026-09-b.md) (Missions 192, 198, 199 and 201, Mission 219; Missions 206, 209, 214-217 and 218, Mission 222; Mission 219, Mission 231), each time this index reached its 8,000-byte cap.

### Earlier families

- **End-to-end install** — `test-install-e2e.ps1` / `.sh`, `test-bootstrap-no-git.ps1`, `test-install-standard-user.ps1`, `test-prerequisites-e2e.ps1`.
- **Project initiation and adoption** — `test-project-initiation.sh`, `test-project-bootstrap-path-validation.sh`, `test-project-structure-standard-conformity.ps1`.
- **Embedded MCP server** — `test-vault-mcp.sh` (server, injection on a simulated profile, containment).
- **Guardians** — `test-githooks-run-on-commit.sh`, `test-guardian-offline-commit.sh`, `test-guardian-path-special-chars.sh`, `test-guardian-secret-refusal.sh`, `test-exec-bit-bare-scripts.sh`.
- **Questionnaire and assistant** — `test-questionnaire-*.ps1`, `test-assistant-*.ps1`.
- **Portability and vocabulary** — `test-participant-shell-portability.sh`, `test-nominal-flow-no-atelier-vocabulary.ps1` / `.sh`, `test-distributed-documents-no-atelier-vocabulary.ps1` / `.sh`.

## Liens

- `see also` — [Vault tests — archive 2026-09](./index-archive-2026-09.md)
- `see also` — [Vault tests — archive 2026-09 (b)](./index-archive-2026-09-b.md)
- `see also` — [Vault tests — archive 2026-09 (c)](./index-archive-2026-09-c.md)
- `see also` — [Guardrails and levels of evidence](../rules/RULES-2026-08-19-210803-guardrails-and-evidence-levels.md)
- `prescribed by` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
