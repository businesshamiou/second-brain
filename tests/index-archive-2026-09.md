---
type: index
title: "Vault tests — archive 2026-09"
description: "Frozen part of the tests index: the families closed by Missions 185-C01 and 186, moved out of tests/index.md when it reached its 8,000-byte cap (Mission 189); then those of Missions 187, 188, 189 and 191-C01 (Mission 218)."
created_at: 2026-09-18T11:30:00-04:00
timezone: America/Montreal
status: active
---

# Vault tests — archive 2026-09

Frozen: moved as is from [`index.md`](./index.md) (Decision 2026-09-05-124647, live index and frozen archive). U = Ubuntu, W = Windows, M = macOS.

### Doors closed by Mission 186 (v0.1.5)

Six measurements: the single source of the Pilot↔Executor relay (DECISION-2026-09-17-201623) across the distributed corpus, plus the « Instructions du Projet » ["Project Instructions"] block made ready to paste and the reworked install path. U = Ubuntu, W = Windows, M = macOS.

| # | File | What it proves | Negative control | Systems |
|---|---|---|---|---|
| T1 | `test-no-push-formula.sh` | zero occurrences, in the distributed corpus, of the four wordings of the old imposed push formula (« j'ordonne le push » ["I order the push"], « verbatim »/« à l'identique » ["identically"] tied to push, « aucun push » ["no push"] without « non délégué » ["not delegated"]) | one file per pattern, never written in this repository → each detected and named | U |
| T2 | `test-relay-single-source.sh` | the RELAY block grammar (exact headings) appears only in `RULES-2026-08-23-124937`; the pieces that mention it refer to it by name (« 124937 ») without restating it | a skill copy that restates the grammar → detected and named | U |
| T3 | `test-common-prompt-no-relay.sh` | the `PROMPT:BEGIN/END` block of the common Pilot prompt no longer carries the word RELAY, and keeps the MCP server exclusivity sentence | RELAY reinjected into a throwaway copy of the template → failure | U |
| T4 | `test-project-bootstrap-instructions-block.sh` | the « Instructions du Projet » block rendered by `tools/project-bootstrap.sh` carries the complete common trunk, ready to paste (native path, `vault_id`, canary identical to `state/PILOT-PROMPT.md`), in French and in the three questionnaire languages | template stripped of `<!-- PROMPT:BEGIN -->` → clean failure, no partial rendering | W / U / M |
| T5 | `test-install-doc-participant-path.sh` | README.md and INSTALL.md carry, in order, the four steps of the participant path (install, MCP server, open the Pilot, adopt) and a FAQ of the four lessons of acceptance 184 | copy of README.md stripped of a section, then of a FAQ entry → failure | U |
| T6 | `test-i18n-parity.sh` | the catalogues `i18n/catalog.{fr,en,es}.json` declare exactly the same set of keys, including the new keys `projectBootstrap.consume.instructions*` | a key removed from a throwaway copy of a catalogue → detected and named | U |

### Doors closed by Mission 185-C01 (v0.1.4)

Twelve measurements, one per defect found during the human acceptance of 2026-09-17. W = Windows, U = Ubuntu, M = macOS.

| # | File | What it proves | Negative control | Systems |
|---|---|---|---|---|
| T1 | `test-bootstrap-stale-temp-clone.ps1` / `.sh` | an already-cloned temporary folder is brought to `--ref` | nonexistent `--ref`; different origin → refusal, nothing installed | W / U / M |
| T2 | `test-install-vault-origin.sh` | `vault_origin`, marker and birth certificate of the first project carry the real origin | source without a remote → fallback to the path, told to the participant | W / U / M |
| T3 | `test-install-leaves-vault-clean.sh` | the installed Vault is left with an empty porcelain | interrupted install → non-empty porcelain, seen by the same measurement | W / U / M |
| T4 | `test-project-bootstrap-git-identity.sh` | every repository created or taken over carries an author identity | local identity removed → commit refused, « Author identity unknown » | W / U / M |
| T5 | `test-project-bootstrap-adopt-git-no-question.sh` | `--git` counts as an answer: no question, standard input is not read | without `--git` or `--vcs` → the question is asked and its answer applied | W / U / M |
| T6 | `test-vault-mcp-refusal-message.py` | an MCP refusal is an `isError` result naming the path and the perimeter | path inside → no `isError`, content returned | W / U / M |
| T7 | `test-project-bootstrap-native-paths.ps1` / `.sh` | on Windows, the rendered paths are native (`C:\…`) | on Unix, the POSIX path comes back strictly unchanged | W / U / M |
| T8 | `test-project-bootstrap-adopt-plan.sh` | the adoption plan speaks only of what exists | an existing misfiled file is still proposed for moving | W / U / M |
| T9 | `test-common-prompt-exclusivity.sh` | the common Pilot prompt says `second-brain-vault` is the only file tool | copy of the template without the sentence → failure | U |
| T10 | `test-install-doc-windows-invocation.sh` | `INSTALL.md` and `README.md` carry the exact Windows invocation | copy without these lines → failure | U |
| T11 | `test-catalog-key-parity.sh` / `.ps1` | fr/en/es parity, and presence of the new keys | a key removed from a catalogue → failure | U |
| T12 | Mission 184 suites | the 106 cases and the eleven acceptance lines keep their verdict | — (this is the "break nothing" rule) | W / U / M |

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

## Liens

- `see also` — [Vault tests (live index)](./index.md)
