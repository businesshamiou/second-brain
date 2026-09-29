---
type: reference
title: "Guardians and hooks"
description: "The exact behaviour of the Vault's Git hooks, its ten pre-commit guardians, the project-side hooks a birth certificate wires, and the test runners that replay them."
status: active
---

# GUARDIANS AND HOOKS

This page lists what each hook and guardian runs, refuses and prints, and how the test suite and the mechanical acceptance are played. For why the guardians exist, read [Guardians](../explanation/guardians.md). For what to do when one refuses, read [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md).

## Activation: core.hooksPath

Git runs the files of `.githooks` only when the repository's local setting `core.hooksPath` is `.githooks`. `install.sh` and `install.ps1` set it in the clone they install. The setting is local and not versioned ([AGENTS.md](../../AGENTS.md)): after any other clone, set it again. Git also ignores a hook without the execute bit; the three hooks are tracked as `100755`. Read the setting (expected output: `.githooks`; when it is not set, nothing is printed and the exit code is 1), then set it if needed:

```
git -C <workspace>/second-brain config core.hooksPath
```

```
git -C <workspace>/second-brain config core.hooksPath .githooks
```

_Not executed by the documentation check._

## .githooks/pre-commit: the ten guardians

The hook runs every guardian, even after one has failed. A guardian whose dependency failed or was itself skipped is not run and gets `SKIPPED (blocked by <name>)`; this propagates down the chain. A missing script or a missing `uv` is a failure, never a silent skip: `REFUS : garde-fou introuvable : <script>`, `REFUS : uv introuvable, impossible d'executer <script>`.

| # | Name as printed | Runs | Depends on | Also needs | Refuses |
|---|---|---|---|---|---|
| 0 | `preflight` | inline function of the hook | none | the stamp `<workspace>/second-brain/.claude/.preflight_stamp.json` | a missing stamp, a stamp without `"ready": true`, a stamp older than 1440 minutes |
| 1 | `reciprocite` | `tools/check-obsolescence-guardrail.py` (through `uv run`) | preflight | `uv` | on staged Markdown files: R1 a `supersedes`/`amends` link without its reciprocal, R2 a superseded target still `status: active`, R3 a typed link whose target does not resolve |
| 2 | `fraicheur-index` | `tools/check-indexes-fresh.sh`, which runs `tools/check_indexes_fresh.py` | preflight | `uv` | an index with a missing entry, an extra entry or a status out of step; an indexed folder without `index.md`; a case variant of `index.md` tracked in a folder; an entry line of a Mission after 122 over 300 characters in `<project>/missions/MISSION-INDEX.md` |
| 3 | `poids-index` | `tools/check-index-weight.sh`, which runs `tools/check_index_weight.py` | fraicheur-index | `uv` | a staged `index.md`, archive index or Mission register over 8000 bytes; a register entry line of a Mission after 122 over 300 characters |
| 4 | `secrets` | `tools/check-secrets.sh` | preflight | `uv` only when a project baseline exists | a staged file named .env or .env.something (except `.env.example`), a file ending in .key, .pem, .pfx, .p12, .crt, .cer, .der, .jks, .keystore, .sql, .dump, .sqlite, .db or .mdb, a file under a folder named secret, secrets, credential or credentials; an added line matching `rules/patterns/secret-patterns.txt` (the value is never printed) |
| 5 | `liens` | `tools/check-links.sh` | fraicheur-index | `uv` only when a project baseline exists | a staged Markdown file with a link whose target is missing (`LIENS: cible introuvable: <file>:<line> -> <target>`), or without a `## Skipped tests (Mission 237)

A test that exits 77 is a SKIP. `tests/run-suite.sh` and `tests/run-suite.ps1` name every SKIP under their `RESULT` line, with the test's own reason (`SKIP: <test> -- <reason>`). In `tests/suite.tsv`, a platform letter followed by `!` (`W!UM`) marks a test **required** on that platform: on a workstation its SKIP there is a blocking FAIL (`FAIL (required, skipped)`); in CI, whose runners carry neither gum nor tui-test, it stays a named SKIP. The gum questionnaire test is required on Windows; its tui-test lives in `<profile>/.local/share/second-brain/tui-test`, next to the other tools the prerequisites install, never under the temporary folder.

## Liens` section (outside `skills/external/` and `skills-warehouse/`); lines with `avertissement` are warnings |
| 6 | `chemins-affirmes` | `tools/check-asserted-paths.sh` | preflight | `git`, `awk` | a file path between single backticks that does not exist, in tracked Markdown files of type `rules` or `decision`, under `knowledge/`, `templates/` or at the root, not `superseded`; a path followed by `(supprimé)` or `(supprimé, Mission NNN)` is accepted |
| 7 | `manifeste` | `tools/check-distribution-manifest.sh` | preflight | `distribution-manifest.txt` | a tracked file missing from the manifest, a listed path no longer tracked, a duplicate, a verdict other than `DISTRIBUABLE` or `INTERNE`, a `distributable:` front matter that contradicts the verdict |
| 8 | `sans-agents` | `tools/check-no-slash-agents.sh` | preflight | `git` | a tracked Markdown file that mentions the Claude Code command made of a slash and the word agents |
| 9 | `bit-execution` | `tools/check-exec-bit-bare-scripts.sh` | preflight | `git` | a shell script invoked bare (without bash in front) in a tracked script, an `entry:` of `.pre-commit-hooks.yaml`, or any file under `.githooks`, whose execute bit is missing from the Git index |

When the preflight stamp fails, the nine others are all skipped; its printed remedy is to run `tools/session-preflight.sh` with bash (that script prints `READY` or `NOT-READY: <n> issue(s)`). `reciprocite` accepts a traced override: the file `<workspace>/second-brain/.obsolescence-guardrail-override`, staged with a reason, turns its R1-R3 refusals into a `CONTOURNEMENT trace` line.

The hook prints `=== Guardian suite ===`, one line per guardian (name, then `PASS`, `FAIL` or `SKIPPED (blocked by <name>)`), a `---` line, then the output of each failed guardian under `--- <name> (FAIL) ---`. The last line is `PASS : 10/10 gardiens (0 echec).` (exit code 0) or `REFUS : <n> gardien(s) en echec sur 10.` (exit code 1). You can run the hook by hand; it writes nothing:

```
cd <workspace>/second-brain && bash .githooks/pre-commit
```

## .githooks/commit-msg: bypass patterns

The hook reads `rules/patterns/bypass-patterns.txt`: one `grep -E` pattern per line, case-insensitive, blank lines and `#` lines ignored. It refuses a message that matches any of `--no-verify`, `--force`, `skip[- ]?hook`, `bypass`, `contourne`, `temporaire`, `provisoire`, `quick ?fix`, `wip`. A pattern matches anywhere, even inside a word (`wip` matches "wipe"). Messages: `REFUS : motif de contournement dans le message de commit.`, then `  motif : <pattern>` and `Reformule le message. Un commit se decrit par ce qu il fait.` A missing message file or pattern file is also a refusal. Exit code 1 on refusal, 0 otherwise.

## .githooks/pre-push: no rewrite of remote history

It refuses deleting a remote branch or tag (`REFUS : suppression de <branche|tag> distante (<name>).`) and a push that is not fast-forward (`REFUS : ce push n est pas en avance rapide.`). A new remote ref is accepted. The only gate is the single-use variable `VAULT_PUSH_GATE`, set to the exact remote ref (`refs/heads/<b>` or `refs/tags/<t>`); it opens that ref alone and prints `GATE accepté : <label> <name> (geste Owner)`. Pushes themselves go through `tools/verified-push.sh` ([absolute paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)).

## Project-side hooks: the birth certificate

`tools/project-bootstrap.sh`, in mode `create` or `adopt`, writes `<project>/.pre-commit-config.yaml` when it is missing. The file opens with the birth certificate, then pins four guardians with `repo: local`:

```
# second-brain-birth-certificate: v1
# vault_id: <id>
# vault_origin: <origin>
# vault_ref: <ref>
# vcs: <none|git>
# baseline: <file>            (only when an adoption recorded one)
repos:
  - repo: local
    hooks:
      - id: vault-check-secrets          entry: <relative path to the Vault>/tools/check-secrets.sh
      - id: vault-check-indexes-fresh    entry: <...>/tools/check-indexes-fresh.sh
      - id: vault-check-index-weight     entry: <...>/tools/check-index-weight.sh
      - id: vault-check-links            entry: <...>/tools/check-links.sh
```

Each hook also carries `name: "Vault : contrôle de ..."`, `language: script`, `always_run: true`, `pass_filenames: false` (shown condensed above). The entry is a relative path measured from the project to the Vault: no remote URL, no network. The same four hooks are declared in `.pre-commit-hooks.yaml`. These guardians find the Vault's files from their own location, never from the project's Git root.

- **Existing config with a certificate:** kept as is; `adopt --git` only switches `# vcs: none` to `# vcs: git`.
- **Existing config without a certificate, holding only Vault pins:** copied to `<project>/.pre-commit-config.yaml.before-adopt-<date>`, then replaced.
- **Existing config without a certificate, holding anything else:** left as is; the script prints the certificate lines to add at the top.
- **Git hook:** with `vcs: git`, the script runs `pre-commit install` in the project. If `pre-commit` or the repository is missing, it prints `Note: Git hook not installed (pre-commit or repository not found) -- run "pre-commit install" in <folder>.` With `vcs: none`, no hook is installed; the four pinned guardians accept the project folder as argument and then judge its whole content.

## The test suite: tests/run-suite.sh and tests/run-suite.ps1

`tests/suite.tsv` is the single list of tests. Tab-separated columns, `-` for an empty field, `#` lines are comments:

| Column | Content |
|---|---|
| path | file to run, relative to the repository root |
| args | arguments passed to it |
| interpreter | `bash`, `bash+uv` (uv put on PATH first), `uv-python` (`uv run --no-project`), `ps1` (`powershell -File` on Windows, `pwsh -File` elsewhere) |
| platforms | letters among `W` (Windows), `U` (Ubuntu), `M` (macOS) |
| severity | `blocking` or `informational` (reported, never fails the run) |
| origin | the Mission that brought the test and what it proves; a leading `+` marks a line added after `tests/fixtures/ci-42f74e6a-steps.tsv` |
| shard | the CI shard (1 to 3) that plays the line, or `-` |

The first two lines, the guardian lines, play `tools/session-preflight.sh` and `.githooks/pre-commit`. Syntax (from the code):

```
bash tests/run-suite.sh [--manifest <file>] [--platform W|U|M] [--shard k/n] [--changed [<ref>]] [--list]
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-suite.ps1 [-Manifest <file>] [-Shard k/n] [-Changed [-Ref <ref>]] [-List]
```

| Option | Effect |
|---|---|
| `--manifest <file>` / `-Manifest` | another manifest than `tests/suite.tsv` |
| `--platform W\|U\|M` | the platform whose lines are played; default from `SB_SUITE_PLATFORM`, else `uname` (MINGW, MSYS, CYGWIN give W, Darwin gives M, anything else U). The PowerShell runner always plays W. |
| `--shard k/n` / `-Shard` | plays only the lines whose shard column is k; refused unless the manifest's highest shard for the platform is n |
| `--changed [<ref>]` / `-Changed [-Ref <ref>]` | plays the two guardian lines, the lines whose path is a changed file, and the lines whose path or origin contains (case-insensitive) the name without extension of a changed file under `tools/`, `tests/` or `.githooks` (index files excepted). "Changed" means `git diff --name-only <ref>` plus untracked files; the default ref is `origin/main`, or `HEAD` without it. It never selects the whole suite. The selection is announced on standard error: `--changed : <n> ligne(s) selectionnee(s) sur <m> (ref <ref>)`. Combined with `--shard`, it is an intersection. |
| `--list` / `-List` | prints `<path args>`, interpreter and severity per selected line, plays nothing, exits 0 |

Every selected line is played, even after a red one. A test exit code 77 is `SKIP`; any other non-zero code is `FAIL`, or `FAIL (informational)` on an informational line. The run ends with `=== SUITE (<platform>[, shard k/n], suite.tsv) ===`, one verdict line per test, then:

```
RESULT: <pass>/<total> PASS (<skip> SKIP, <n> FAIL blocking, <m> FAIL informational)
```

Exit codes: 0 when no blocking line is red; 1 when one is, or when no line matches the platform (`REFUS : no line for platform <p> in <manifest>`); 2 for a usage error, an unknown platform, a missing manifest, a wrong `--shard`, an unknown ref or a checkout without Git. Under GitHub Actions each test is wrapped in `::group::` lines.

```
bash <workspace>/second-brain/tests/run-suite.sh --list
bash <workspace>/second-brain/tests/run-suite.sh --changed --list
```

Called by: `.github/workflows/ci.yml` (Windows `-Shard "<k>/3"`, Ubuntu and macOS without options), `README.md`, `templates/mission-template.md` (`--changed origin/main`), and the tests `tests/test-run-suite-changed.sh`, `tests/test-run-suite-reports-red.sh`, `tests/test-shards-cover-suite.sh` and `tests/test-suite-on-detached-head.sh`. The full run plays every test, so it is kept apart:

```
bash <workspace>/second-brain/tests/run-suite.sh
```

_Not executed by the documentation check._

## The mechanical acceptance: tests/run-mechanical-acceptance.ps1

It writes the acceptance report of a commit. It needs Windows PowerShell 5.1 or later and finds Git's bash through `tools/resolve-bash-exe.ps1`.

```
powershell -NoProfile -ExecutionPolicy Bypass -File <workspace>/second-brain/tests/run-mechanical-acceptance.ps1 [-Out <path outside the repository>] [-RequireS9]
```

_Not executed by the documentation check._

- `-Out <path>`: the report file. Default: `<workspace>/second-brain-mechanical-acceptance-<yyyyMMdd-HHmmss>.md`, beside the checkout. A path inside the repository stops the run: `Error: report path <path> is inside <repo> -- pick a path outside second-brain.`
- `-RequireS9`: S9 must be PASS for the run to pass (the CI acceptance job uses it).

| Id | Title in the report | Played by |
|---|---|---|
| S1, S4, S6 | Fresh install, Windows; First project; Cold session (session-start) | one shared run of `tests/test-install-e2e.ps1` |
| S2 | Re-run without changes | `tests/test-questionnaire-update-mode.ps1` |
| S3 | Resume after a forced stop | `tests/test-questionnaire-resume.ps1` |
| S5 | A guardian refuses, then accepts | `tests/test-guardian-secret-refusal.sh` |
| S7 | The assistant answers (two providers) | `tools/acceptance-harness.sh` with `--scenario S7`, `--provider` `claude` then `codex`, `--runs 3` |
| S8 | Web package, by equivalence | same harness, `--scenario S8`; the upload gesture is not proven |
| S9 | No Git, no admin rights | `tests/test-install-standard-user.ps1`; when it exits 3, INDETERMINE, with the local half `tests/test-bootstrap-no-git.ps1` in the detail |
| S10 | Offline commit | `tests/test-guardian-offline-commit.sh` |
| T21 | No atelier vocabulary in the nominal flow | `tests/test-nominal-flow-no-atelier-vocabulary.ps1` |

Verdicts are `PASS`, `FAIL`, `SKIP` or `INDETERMINE (<cause>)`. For S7 and S8, the harness runs against a test-mode installation (`install.ps1` with `-TestMode`) made in a temporary folder: any provider FAIL gives FAIL, both PASS give PASS, both skipped give `SKIP (no provider credentials in CI)`, anything else `INDETERMINE`. The runner also fingerprints the real environment (PATH hash, entries under .claude/skills, .codex/skills, .agents/skills, .local/bin) before and after. The last line is `=== RESULT: PASS (11 lines, 0 FAIL) ===` with exit code 0 only when no line is FAIL, the environment is identical and, with `-RequireS9`, S9 is PASS; otherwise `=== RESULT: FAIL (...) ===` and exit code 1.

## Liens

- `source` — [Pre-commit hook](../../.githooks/pre-commit)
- `source` — [Commit-msg hook](../../.githooks/commit-msg)
- `source` — [Pre-push hook](../../.githooks/pre-push)
- `source` — [Bypass patterns](../../rules/patterns/bypass-patterns.txt)
- `source` — [Secret patterns](../../rules/patterns/secret-patterns.txt)
- `source` — [Reciprocity guardian](../../tools/check-obsolescence-guardrail.py)
- `source` — [Index freshness launcher](../../tools/check-indexes-fresh.sh)
- `source` — [Index freshness guardian](../../tools/check_indexes_fresh.py)
- `source` — [Index weight launcher](../../tools/check-index-weight.sh)
- `source` — [Index weight guardian](../../tools/check_index_weight.py)
- `source` — [Secrets guardian](../../tools/check-secrets.sh)
- `source` — [Links guardian](../../tools/check-links.sh)
- `source` — [Asserted paths guardian](../../tools/check-asserted-paths.sh)
- `source` — [Distribution manifest guardian](../../tools/check-distribution-manifest.sh)
- `source` — [Distribution manifest](../../distribution-manifest.txt)
- `source` — [No agents command guardian](../../tools/check-no-slash-agents.sh)
- `source` — [Execute bit guardian](../../tools/check-exec-bit-bare-scripts.sh)
- `source` — [Project baseline library](../../tools/project-baseline.sh)
- `source` — [Session preflight](../../tools/session-preflight.sh)
- `source` — [Project bootstrap](../../tools/project-bootstrap.sh)
- `source` — [Birth certificate header](../../tools/resolve-vault.sh)
- `source` — [English message catalog](../../i18n/catalog.en.json)
- `source` — [Pre-commit hooks declaration](../../.pre-commit-hooks.yaml)
- `source` — [Installer, shell](../../install.sh)
- `source` — [Installer, PowerShell](../../install.ps1)
- `source` — [Instructions for agents](../../AGENTS.md)
- `source` — [Test suite manifest](../../tests/suite.tsv)
- `source` — [Frozen CI reference](../../tests/fixtures/ci-42f74e6a-steps.tsv)
- `source` — [Suite runner, bash](../../tests/run-suite.sh)
- `source` — [Suite runner, PowerShell](../../tests/run-suite.ps1)
- `source` — [Changed-selection test](../../tests/test-run-suite-changed.sh)
- `source` — [Red-report test](../../tests/test-run-suite-reports-red.sh)
- `source` — [Shard coverage test](../../tests/test-shards-cover-suite.sh)
- `source` — [Detached-head test](../../tests/test-suite-on-detached-head.sh)
- `source` — [Mechanical acceptance](../../tests/run-mechanical-acceptance.ps1)
- `source` — [Bash resolver](../../tools/resolve-bash-exe.ps1)
- `source` — [Acceptance harness](../../tools/acceptance-harness.sh)
- `source` — [Install end-to-end test](../../tests/test-install-e2e.ps1)
- `source` — [Update-mode test](../../tests/test-questionnaire-update-mode.ps1)
- `source` — [Resume test](../../tests/test-questionnaire-resume.ps1)
- `source` — [Secret refusal test](../../tests/test-guardian-secret-refusal.sh)
- `source` — [Standard user test](../../tests/test-install-standard-user.ps1)
- `source` — [No-Git bootstrap test](../../tests/test-bootstrap-no-git.ps1)
- `source` — [Offline commit test](../../tests/test-guardian-offline-commit.sh)
- `source` — [No atelier vocabulary test](../../tests/test-nominal-flow-no-atelier-vocabulary.ps1)
- `source` — [CI workflow](../../.github/workflows/ci.yml)
- `source` — [README](../../README.md)
- `source` — [Mission template](../../templates/mission-template.md)
- `source` — [Verified push](../../tools/verified-push.sh)
- `source` — [Absolute paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `see also` — [Guardians, the why](../explanation/guardians.md)
- `see also` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `see also` — [Guardian tools](tools-guardians.md)
- `see also` — [Formats](formats.md)
- `see also` — [Create a project](../how-to/create-a-project.md)
- `see also` — [Adopt a project](../how-to/adopt-a-project.md)
