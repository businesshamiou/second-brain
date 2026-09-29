---
type: explanation
title: "Guardians and tests"
description: "What the automatic guardians refuse at commit, how to fix each refusal, and how to run the test suite and the mechanical acceptance."
status: active
---

# GUARDIANS AND TESTS

This page explains the automatic checks that run when you commit or push, how to answer each refusal, the guard that stops a writing tool outside a repository, and how the test suite and the acceptance run are played.

In the commands of this page, `<workspace>` is the absolute path of your workspace (for example C:/Users/you/Workspaces), and your Second Brain is `<workspace>/second-brain` (in a laboratory, `<workspace>/vault`).

**Under Windows.** The remedies below are quoted as the guardians print them, for bash (`Remede : bash tools/…`, relative to the repository concerned). In PowerShell, where `bash` is unknown, start the line with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`, or run it in Git Bash; `sb doctor` says whether `bash` is on your PATH.

## What a guardian is

[CONTEXT.md](../../CONTEXT.md) defines a guardian as "an automatic check at commit, which refuses what violates a rule". Each guardian but one is a script under `tools/`; the preflight check is written inside `.githooks/pre-commit` itself. The Git hooks in `.githooks/` are only the mechanism that calls them.

Every guardian follows the same stance: refusal is the default position. If a guardian cannot verify (its script is missing, `uv` is not installed, you are outside a Git repository), it refuses instead of passing silently ([.githooks/pre-commit](../../.githooks/pre-commit)).

## The three Git hooks

| Hook | When it runs | What it refuses |
|---|---|---|
| `.githooks/pre-commit` | before each commit | anything one of the ten guardians below refuses |
| `.githooks/commit-msg` | after you write the message | a message matching a pattern in `rules/patterns/bypass-patterns.txt` (case-insensitive), for example `--no-verify`, `bypass`, `wip`, `quick fix` |
| `.githooks/pre-push` | before each push | deleting a remote branch or tag, or a push that is not fast-forward (it would rewrite remote history) |

For `pre-push`, the only accepted gate is a single-use variable, `VAULT_PUSH_GATE`, set to the exact remote ref (for example `refs/heads/<branch>`); it opens that ref alone. Pushing is an Owner gesture, which the Owner may delegate by a clear expression naming the gesture and its target ([AGENTS.md](../../AGENTS.md)); every push of a branch goes through `tools/verified-push.sh` ([the absolute-paths rule](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)).

### How the hooks are activated

Git only runs these hooks when `core.hooksPath` points to `.githooks/`. The installers do this for you: `install.sh` and `install.ps1` run `git config core.hooksPath .githooks` in the clone. [AGENTS.md](../../AGENTS.md) reminds you that this setting is local and not versioned: redo it after every clone.

Git also ignores a hook that lacks the execute bit, which is why the `bit-execution` guardian checks the files under `.githooks/`.

## The ten guardians of pre-commit

`.githooks/pre-commit` runs every guardian, even after one has failed, then prints one report: a `=== Guardian suite ===` block with one verdict per name, the output of each failed guardian, and a final line (`PASS : 10/10 gardiens (0 echec).` or `REFUS : <n> gardien(s) en echec sur 10.`).

Some guardians depend on another. If the dependency fails or is itself skipped, the dependent guardian is not run and is reported `SKIPPED (blocked by <name>)`; this propagates down the chain. Fix the first failure and commit again.

| Name as printed (gloss) | Script | Depends on | What it refuses | How to fix |
|---|---|---|---|---|
| `preflight` (session preflight) | inline in the hook | none | a missing preflight stamp, a stamp without `"ready": true`, or a stamp older than 1440 minutes | run `bash <workspace>/second-brain/tools/session-preflight.sh` |
| `reciprocite` (reciprocity) | `tools/check-obsolescence-guardrail.py` | preflight | on staged `.md` files: a `supersedes`/`amends` link without its reciprocal (R1), a superseded target still `status: active` (R2), a typed link whose target does not resolve (R3) | add the missing inverse link, set the superseded target's status, or fix the target path |
| `fraicheur-index` (index freshness) | `tools/check-indexes-fresh.sh` | preflight | any folder carrying an `index.md` (touched by the commit or not) whose index is stale (a missing or extra entry, or a status out of step), or any folder receiving a staged `.md` that has no `index.md`, or a case collision (a variant such as INDEX.md tracked in a folder) | the printed instruction: `bash tools/build-indexes.sh <racine>` (write the Vault's tool and `<racine>` as absolute paths), `git add` the index, reread `git diff --cached`; for a case collision, never regenerate that folder in full mode |
| `poids-index` (index weight) | `tools/check-index-weight.sh` | fraicheur-index | a staged index over 8,000 bytes, or a line of a Mission register (missions/MISSION-INDEX.md in a project) over 300 characters | shorten the index (one locator per line, or split live/archive with `tools/build-indexes.sh`); cut the register line to an execution status |
| `secrets` (secrets) | `tools/check-secrets.sh` | preflight | a forbidden file name (.env files, .key or .pem files, a secrets or credentials folder, database dumps, and similar; `.env.example` is allowed) or an added line matching `rules/patterns/secret-patterns.txt` | remove the value, put it in an untracked .env file, document the expected key in `.env.example` |
| `liens` (links) | `tools/check-links.sh` | fraicheur-index | a staged `.md` without a `## Liens` section, or with an internal link whose target is missing | add the section, or correct the target; lines marked `avertissement` are warnings and do not block |
| `chemins-affirmes` (asserted paths) | `tools/check-asserted-paths.sh` | preflight | a file path cited between backticks that does not exist, in tracked rules, decisions, `knowledge/`, `templates/` or root documents that are not superseded | correct the path; a token followed by the mark `(supprimé)` or `(supprimé, Mission NNN)` is accepted |
| `manifeste` (distribution manifest) | `tools/check-distribution-manifest.sh` | preflight | `distribution-manifest.txt` out of step with Git: a tracked file missing, a path no longer tracked, a duplicate, a verdict other than `DISTRIBUABLE` or `INTERNE`, or a clash with a file's `distributable:` front matter | add, remove or correct the manifest line the refusal names |
| `sans-agents` (no agents command) | `tools/check-no-slash-agents.sh` | preflight | any tracked `.md` mentioning the Claude Code agents command (a slash followed by the word agents) | name the assistant instead, for example `demande a Brian : ...` |
| `bit-execution` (execute bit) | `tools/check-exec-bit-bare-scripts.sh` | preflight | a tracked `.sh` invoked without `bash` in front, an `entry:` of `.pre-commit-hooks.yaml`, or a file under `.githooks/`, whose execute bit is missing from the Git index | `git -C <workspace>/second-brain update-index --chmod=+x <chemin>` |

`reciprocite` offers a traced override: a file named in the script (`OVERRIDE_FILENAME`), staged with a reason. Treat it as a bypass option under the rule below.

## The preflight stamp

`tools/session-preflight.sh` verifies without modifying anything, then writes the local stamp `.claude/.preflight_stamp.json` (never committed). It prints `READY`, or `NOT-READY: <n> issue(s)` with details on standard error. It checks that:

- the role charter exists, and `AGENTS.md` and `CLAUDE.md` point to it;
- `.claude/settings.json` exists and is valid JSON;
- `git` and `bash` are on the PATH, and `tools/build-state.sh`, `tools/build-indexes.sh` and `tools/check-links.sh` are executable;
- the hooks log under .claude/, if present, is not silent for more than 72 hours.

The `preflight` guardian refuses when this stamp is older than 24 hours, so run the script at the start of each work session.

## Guardians in your projects

`tools/project-bootstrap.sh` writes a .pre-commit-config.yaml in each project it creates or adopts. The file opens with a birth-certificate comment block (`vault_id`, `vault_origin`, `vault_ref`, `vcs`), then pins the Vault's guardians with `repo: local`: four hooks (`vault-check-secrets`, `vault-check-indexes-fresh`, `vault-check-index-weight`, `vault-check-links`) whose `entry:` is a relative path to the Vault's `tools/`. No network or remote URL is involved. The same four hooks are declared in `.pre-commit-hooks.yaml`.

The secrets and index guardians locate the Vault from their own location, never from `git rev-parse`, so they read the Vault's files even when called from a project ([tools/check-secrets.sh](../../tools/check-secrets.sh)). See [Create a project](../how-to/create-a-project.md).

## The repository-root guard

Not every guard runs at commit. The Vault's writing tools also carry a repository-root guard, [tools/repo_root_guard.py](../../tools/repo_root_guard.py), which decides before anything is written whether a tool may write under its target folder. It exists because on 2026-09-21 the index builder, run with `.` from the workspace root, rewrote about 2,400 index files in sibling folders ([why absolute paths](why-absolute-paths.md)).

- A target is admitted when, walking up from it, a `.git` or a project's birth certificate is found before any workspace root. A workspace root is a folder that carries the marker `<folder>/VAULT-ROOT.md`, or that holds two or more Git repositories without being one.
- Anything else is refused: one line starting with `REPO-ROOT-REFUSED`, naming the path received and the root expected, ending with `Nothing written.`; the guard exits 2.
- `tools/project-bootstrap.sh` uses its `--new-project` mode for create and adopt: the project folder is refused only when it is itself a workspace root.
- No switch and no environment variable turns it off. The tools that carry it are listed in [the absolute-paths rule](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md), section 3.

Asked about the workspace itself, the guard refuses:

```
uv run --no-project <workspace>/second-brain/tools/repo_root_guard.py <workspace>
```

It prints `REPO-ROOT-REFUSED: <workspace> (...) is not inside a repository: ... is a workspace root (it carries VAULT-ROOT.md). ... Nothing written.` and exits 2.

## Never bypass a guardian

A refusal is information, not an obstacle. [The guardrails rule](../../rules/RULES-2026-08-19-210803-guardrails-and-evidence-levels.md) says an agent does not disable, bypass or modify a mechanism that constrains it (hooks, pattern files, the configuration that activates them, any bypass option) without the Owner's explicit authorization in the current request. The `commit-msg` hook refuses messages that announce a bypass, and `tools/check-secrets.sh` ends its refusal of a secret pattern with `Ne contourne pas ce controle.`. Fix the cause, then commit again.

## The test suite

[tests/suite.tsv](../../tests/suite.tsv) is the single list of tests, played the same way locally and in CI. Columns are tab-separated, `-` for an empty field:

| Column | Meaning |
|---|---|
| path | file to run, relative to the repository root |
| args | arguments passed to it |
| interpreter | `bash`, `bash+uv` (uv put on PATH first), `uv-python`, or `ps1` |
| platforms | `W` Windows, `U` Ubuntu, `M` macOS |
| severity | `blocking` (a red one fails the run) or `informational` (reported, never fails) |
| origin | the Mission that brought the test and what it proves |
| shard | Windows lines only: the CI shard (1..3) that plays the line |

A test exits 77 to report SKIP. The first two lines play `tools/session-preflight.sh` and `.githooks/pre-commit` on the checkout.

On macOS, Linux or Git Bash, the usage text of [tests/run-suite.sh](../../tests/run-suite.sh) is:

```
bash tests/run-suite.sh [--manifest <file>] [--platform W|U|M] [--shard k/n] [--changed [<ref>]] [--list]
```

_Not executed by the documentation check._

- Without options it plays every line for your platform (detected from `uname`), even after a red one, and ends with `RESULT: <pass>/<total> PASS (...)`. Exit code 1 if a blocking line is red.
- `--shard k/n` plays only shard k; it refuses if the manifest's highest shard for the platform is not n.
- `--changed [<ref>]` plays only the lines that files changed since `<ref>` call for (default `origin/main`, or `HEAD`), plus the two guardian lines. It never falls back to the whole suite.
- `--list` lists the selection without playing it.

On Windows, [tests/run-suite.ps1](../../tests/run-suite.ps1) has the same verdicts; its usage text is:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-suite.ps1 [-Manifest <file>] [-Shard k/n] [-Changed [-Ref <ref>]] [-List]
```

_Not executed by the documentation check._

### CI

[.github/workflows/ci.yml](../../.github/workflows/ci.yml) runs on every push and on manual dispatch. It lists no tests: after the shared action `.github/actions/setup-test-env/action.yml` (uv, Python, pre-commit), the Windows job runs `tests/run-suite.ps1 -Shard "<k>/3"` in three parallel shards, and the Ubuntu and macOS jobs run `bash tests/run-suite.sh` (macOS with Apple's bash 3.2 and BSD tools only). A smoke job plays the published install line pinned to the commit, and an acceptance job runs the mechanical acceptance below with `-RequireS9`.

## The mechanical acceptance

[tests/run-mechanical-acceptance.ps1](../../tests/run-mechanical-acceptance.ps1) writes the acceptance report of a commit: one line per scenario, verdicts `PASS`, `FAIL`, `SKIP` or `INDETERMINE` (cause named). A scenario that could not be measured is never PASS.

| Id | What it proves | Played by |
|---|---|---|
| S1 | fresh install, Windows | `tests/test-install-e2e.ps1` |
| S2 | re-run without changes | `tests/test-questionnaire-update-mode.ps1` |
| S3 | resume after a forced stop | `tests/test-questionnaire-resume.ps1` |
| S4 | first project | `tests/test-install-e2e.ps1` |
| S5 | a guardian refuses | `tests/test-guardian-secret-refusal.sh` |
| S6 | cold session (session-start) | `tests/test-install-e2e.ps1` |
| S7 | the assistant answers | `tools/acceptance-harness.sh` |
| S8 | web package, by equivalence | `tools/acceptance-harness.sh` |
| S9 | no Git, no admin rights | `tests/test-install-standard-user.ps1` |
| S10 | offline commit | `tests/test-guardian-offline-commit.sh` |
| T21 | no atelier vocabulary | `tests/test-nominal-flow-no-atelier-vocabulary.ps1` |

S7 and S8 are the only scenarios that call a model. [tools/acceptance-harness.sh](../../tools/acceptance-harness.sh) asks the three test questions of `assistant/ASSISTANT.md` three times each through two provider CLIs, `claude` and `codex`, and judges answers by strings and disk state. When a CLI is missing, the harness reports SKIP under CI and INDETERMINE locally. The line is PASS only if both providers pass, and SKIP only if both are skipped. S8 does not prove the upload gesture in a web interface.

S9 needs a disposable machine (it creates a local standard account); elsewhere it is INDETERMINE. The runner finds the repository from its own location, so name it by its absolute path:

```
powershell -NoProfile -ExecutionPolicy Bypass -File <workspace>\second-brain\tests\run-mechanical-acceptance.ps1 [-Out <absolute path outside the repo>] [-RequireS9]
```

_Not executed by the documentation check._

The report is written outside the repository; exit code 0 means no line is FAIL, the real-environment fingerprint is unchanged, and, with `-RequireS9`, S9 is PASS; any other outcome, or a refused report path, exits 1.

## Liens

- `source` — [Glossary](../../CONTEXT.md)
- `source` — [Instructions for agents](../../AGENTS.md)
- `source` — [Pre-commit hook](../../.githooks/pre-commit)
- `source` — [Commit-msg hook](../../.githooks/commit-msg)
- `source` — [Pre-push hook](../../.githooks/pre-push)
- `source` — [Bypass patterns](../../rules/patterns/bypass-patterns.txt)
- `source` — [Secret patterns](../../rules/patterns/secret-patterns.txt)
- `source` — [Installer, macOS and Linux](../../install.sh)
- `source` — [Installer, Windows](../../install.ps1)
- `source` — [Reciprocity guardian](../../tools/check-obsolescence-guardrail.py)
- `source` — [Index freshness guardian](../../tools/check-indexes-fresh.sh)
- `source` — [Index freshness guardian, Python](../../tools/check_indexes_fresh.py)
- `source` — [Index weight guardian](../../tools/check-index-weight.sh)
- `source` — [Index weight guardian, Python](../../tools/check_index_weight.py)
- `source` — [Secrets guardian](../../tools/check-secrets.sh)
- `source` — [Links guardian](../../tools/check-links.sh)
- `source` — [Asserted paths guardian](../../tools/check-asserted-paths.sh)
- `source` — [Distribution manifest guardian](../../tools/check-distribution-manifest.sh)
- `source` — [No agents command guardian](../../tools/check-no-slash-agents.sh)
- `source` — [Execute bit guardian](../../tools/check-exec-bit-bare-scripts.sh)
- `source` — [Session preflight](../../tools/session-preflight.sh)
- `source` — [Project bootstrap](../../tools/project-bootstrap.sh)
- `source` — [Pinned hooks for projects](../../.pre-commit-hooks.yaml)
- `source` — [Repository-root guard](../../tools/repo_root_guard.py)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Verified push](../../tools/verified-push.sh)
- `source` — [Guardrails and evidence levels](../../rules/RULES-2026-08-19-210803-guardrails-and-evidence-levels.md)
- `source` — [Test suite manifest](../../tests/suite.tsv)
- `source` — [Suite runner, bash](../../tests/run-suite.sh)
- `source` — [Suite runner, PowerShell](../../tests/run-suite.ps1)
- `source` — [Mechanical acceptance](../../tests/run-mechanical-acceptance.ps1)
- `source` — [Acceptance harness](../../tools/acceptance-harness.sh)
- `source` — [CI workflow](../../.github/workflows/ci.yml)
- `source` — [Test environment action](../../.github/actions/setup-test-env/action.yml)
- `source` — [Vault tests index](../../tests/index.md)
- `see also` — [Architecture](architecture.md)
- `see also` — [Why absolute paths](why-absolute-paths.md)
- `see also` — [Guardians and hooks](../reference/guardians-and-hooks.md)
- `see also` — [Guardian and session tools](../reference/tools-guardians.md)
- `see also` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `see also` — [Open a session](../how-to/open-a-session.md)
- `see also` — [Create a project](../how-to/create-a-project.md)
- `see also` — [Troubleshoot](../how-to/troubleshoot.md)
- `see also` — [Publish a version](../how-to/publish.md)
