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

### Reusable test bench — Mission 188

Each file carries its oracle and its negative control in its header.

- T1 `test-suite-manifest-matches-ci.sh` (U) — `suite.tsv` = the `ci.yml` suite at `42f74e6a` (108 triplets).
- T2 `test-run-suite-reports-red.sh` (W / U / M) — the launcher plays everything, counts, names the reds.
- T3 `test-setup-test-env-offline.sh` (U, CI) — the cached environment answers offline.
- T4 `test-reference-clone-equivalence.sh` (U) — the reference clone installs the same thing.

### Doors closed by Mission 186 (v0.1.5)

Six measurements: the single source of the Pilot↔Executor relay (DECISION-2026-09-17-201623) synchronized across the whole distributed corpus, plus the « Instructions du Projet » ["Project Instructions"] block made ready to paste and the reworked install path. U = Ubuntu, W = Windows, M = macOS.

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

### Earlier families

- **End-to-end install** — `test-install-e2e.ps1` / `.sh`, `test-bootstrap-no-git.ps1`, `test-install-standard-user.ps1`, `test-prerequisites-e2e.ps1`.
- **Project initiation and adoption** — `test-project-initiation.sh`, `test-project-bootstrap-path-validation.sh`, `test-project-structure-standard-conformity.ps1`.
- **Embedded MCP server** — `test-vault-mcp.sh` (server, injection on a simulated profile, containment).
- **Guardians** — `test-githooks-run-on-commit.sh`, `test-guardian-offline-commit.sh`, `test-guardian-path-special-chars.sh`, `test-guardian-secret-refusal.sh`, `test-exec-bit-bare-scripts.sh`.
- **Questionnaire and assistant** — `test-questionnaire-*.ps1`, `test-assistant-*.ps1`.
- **Portability and vocabulary** — `test-participant-shell-portability.sh`, `test-nominal-flow-no-atelier-vocabulary.ps1` / `.sh`, `test-distributed-documents-no-atelier-vocabulary.ps1` / `.sh`.

## Liens

- `see also` — [Guardrails and levels of evidence](../rules/RULES-2026-08-19-210803-guardrails-and-evidence-levels.md)
- `prescribed by` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
