---
type: reference
title: "Guardian and session tools"
description: "One sheet per guardian and session script: what it checks, who calls it, its syntax, exit codes, what it reads and writes, and which pre-commit guardian name it carries."
status: active
---

# GUARDIAN AND SESSION TOOLS

These scripts refuse; they never fix. Each sheet is copied from the code. The **guardian name** is the name `.githooks/pre-commit` prints in its `=== Guardian suite ===` report; a script without one is not run by that hook. The hook runs every guardian with `bash` (or `uv run` for Python), so a missing execute bit never skips it. None of these scripts carries `tools/repo_root_guard.py`: none writes into a repository through an argument. Run the read-only examples from the root of the Vault.

**Under Windows.** A `bash …/tools/…` line of this page, typed in PowerShell where `bash` is unknown, starts with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`; where an `sb` verb carries the same gesture ([Commands](commands.md)), type the verb. `sb doctor` says whether `bash` is on your PATH.

## tools/check-secrets.sh

- **Role**: refuses a forbidden file name (a .env file other than `.env.example`, key and certificate extensions, a secrets or credentials folder, database dumps) and any added line matching `rules/patterns/secret-patterns.txt`. The value found is never printed.
- **Guardian name**: `secrets` (depends on `preflight`). Also the `vault-check-secrets` hook of `.pre-commit-hooks.yaml`, which `tools/project-bootstrap.sh` pins into each project's pre-commit file.
- **Called by**: the two files above, `tools/bench-folder-guardians.sh`, `tests/standalone.sh`, `tests/test-guardian-secret-refusal.sh` and other tests.
- **Syntax**: `bash tools/check-secrets.sh` (staged diff of the repository of the current folder) or `bash tools/check-secrets.sh <projet>` (folder mode: whole content of every listed file).
- **Baseline**: when the project's birth certificate names a baseline (`tools/project-baseline.sh`), an engraved file left untouched is not judged; an engraved file that was touched is judged in full. Folder mode and reading a baseline need `uv`.
- **Exit codes and last line**: 0, silent on standard output (folder mode prints `progress:` lines on the error output); 1 with `REFUS : ...` on the error output, for example `REFUS : dossier de projet introuvable : no-such-folder`. After a pattern hit the last line is `Ne contourne pas ce controle.`
- **Reads**: the staged diff, or the folder's files; the patterns file, located from the script's own folder, never from the calling repository. **Writes**: nothing. **Repository-root guard**: none needed; the folder argument is only read.

```bash
bash tools/check-secrets.sh templates
bash tools/check-secrets.sh no-such-folder
```

## tools/check-private-patterns.sh

- **Role**: refuses private patterns in the tracked tree and, in full mode, in the whole history (`git log --all`): three names from machine paths, one private repository name, and a Google API key (`AIza` followed by 35 characters, masked in the refusal). The script and its test are excluded because they spell the patterns. In a laboratory (a `release` remote declared and a branch that does not follow it), `projects/` is exempted and a line says so.
- **Guardian name**: none.
- **Called by**: `tools/publish-from-laboratory.sh` (`--tree-only`, before publishing); `tests/suite.tsv`, played by `tests/run-suite.sh`: `--tree-only` blocking, full mode informational; `tests/test-check-private-patterns.sh`.
- **Syntax**: `bash tools/check-private-patterns.sh [--tree-only]`. Any other first argument runs the full mode.
- **Exit codes and last line**: 0, `PASS : 0 motif prive dans l'arbre (mode --tree-only, 5 motifs verifies).` or `PASS : 0 motif prive dans l'arbre et l'historique (5 motifs verifies).`; 1, `REFUS : motif(s) prive(s) trouve(s).` or a refusal outside a Git repository.
- **Reads**: the repository that holds the script. **Writes**: nothing. **Repository-root guard**: none needed.

```bash
bash tools/check-private-patterns.sh --tree-only
```

## tools/check-distribution-manifest.sh

- **Role**: compares `distribution-manifest.txt` with `git ls-files`. Refuses a tracked file with no line, a line for an untracked path, a duplicate, a verdict other than `DISTRIBUABLE` or `INTERNE`, a front matter `distributable: false` classed `DISTRIBUABLE` (or `true` classed `INTERNE`), and the machine-local USER.local.yaml file named in the manifest or tracked. Outside the check: `skills-warehouse/`, the project sheets PROJECT-<date>-<code>.md under `projects/`, and the assistant forms written at installation.
- **Guardian name**: `manifeste` (depends on `preflight`).
- **Called by**: `.githooks/pre-commit`, `tests/standalone.sh`, `tests/test-distribution-manifest-no-heredoc-hang.sh`.
- **Syntax**: `bash tools/check-distribution-manifest.sh` (no argument; the repository of the current folder).
- **Exit codes and last line**: 0, `Comptes : DISTRIBUABLE=<n> INTERNE=<n> TOTAL=<n>`; 1, `REFUS : le manifeste ne passe pas les controles ci-dessus.` Each defect is printed with its label (`ABSENT-DU-MANIFESTE`, `FANTOME-AU-MANIFESTE`, `DOUBLON-AU-MANIFESTE`, `VERDICT-INVALIDE`, `INCOHERENCE-DISTRIBUTABLE`, `LOCAL-FILE-DISTRIBUTED`).
- **Reads**: the manifest and the first 20 lines of each listed file. **Writes**: three temporary files (`mktemp`), removed on exit. **Repository-root guard**: none needed.

```bash
bash tools/check-distribution-manifest.sh
```

## tools/check-no-slash-agents.sh

- **Role**: refuses, in every tracked Markdown file, a mention of the Claude Code command formed by a slash and the lower-case word agents, when it is not followed by another slash (a folder path stays allowed). The remedy is to call the assistant by its name.
- **Guardian name**: `sans-agents` (depends on `preflight`).
- **Called by**: `.githooks/pre-commit`, `tests/test-check-no-slash-agents.sh`.
- **Syntax**: `bash tools/check-no-slash-agents.sh` (no argument).
- **Exit codes and last line**: 0, a line starting `PASS : 0 mention`; 1, the hits, then a `Remede : ...` line.
- **Reads**: tracked Markdown files of the repository that holds the script. **Writes**: nothing. **Repository-root guard**: none needed.

```bash
bash tools/check-no-slash-agents.sh
```

## tools/check-exec-bit-bare-scripts.sh

- **Role**: refuses a file whose mode in the Git index is not `100755` when it is run without `bash` in front: a quoted path built on a variable and ending in .sh, at the head of a command in a tracked shell script, an `entry:` of `.pre-commit-hooks.yaml`, or any tracked file under `.githooks/` (Git ignores a hook without the bit).
- **Guardian name**: `bit-execution` (depends on `preflight`).
- **Called by**: `.githooks/pre-commit`, `tests/test-exec-bit-bare-scripts.sh`.
- **Syntax**: `bash tools/check-exec-bit-bare-scripts.sh` (no argument; the repository of the current folder).
- **Exit codes and last line**: 0, `PASS : <n> script(s) nu(s) verifie(s), tous executables dans l'index Git.`; 1, `Remede : git update-index --chmod=+x <chemin(s) ci-dessus>.`
- **Reads**: the tracked shell scripts, `.pre-commit-hooks.yaml` and the Git index. **Writes**: nothing. **Repository-root guard**: none needed.

```bash
bash tools/check-exec-bit-bare-scripts.sh
```

## tools/check-obsolescence-guardrail.py

- **Role**: on the staged Markdown files only (added or modified, a graphify-out folder excluded), refuses R1 (a `supersedes` or `amends` relation not matched between front matter and `## Liens`, or a target without the inverse `superseded by` / `amended by` link), R2 (a superseded target still `status: active`, except a `type: mission` document) and R3 (a typed link whose target does not exist, except a link suffixed `(hors Vault)`). A front matter it cannot read is refused (`FM`).
- **Traced override**: a file named `<repository>/.obsolescence-guardrail-override`, staged in the same commit and holding a reason, lets R1 to R3 pass with a `CONTOURNEMENT trace` line. It never lifts `FM` or a tool failure.
- **Guardian name**: `reciprocite` (depends on `preflight`; needs `uv`).
- **Called by**: `.githooks/pre-commit`, `tests/standalone.sh`, `tests/test-lab-language-local-file.sh`.
- **Syntax**: `uv run tools/check-obsolescence-guardrail.py` (no argument).
- **Exit codes and last line**: 0, silent (nothing staged, or no violation); 0 also when the override is accepted, after the violations and the `CONTOURNEMENT trace` line on the error output; 1, one `OBSOLESCENCE [<rule>] <file>: <message>` line per violation, then `REFUS : <n> violation(s) de reciprocite/statut/cible. ...`.
- **Reads**: the staged Markdown files and their link targets, including targets in a sibling repository of the workspace. **Writes**: nothing. **Repository-root guard**: none needed.

```bash
uv run tools/check-obsolescence-guardrail.py
```

## tools/check-work-regime.sh

- **Role**: decides by command whether a gesture may be done as a light execution Note or must be a Mission. Full-regime criteria: `R1-egress` (anything leaving the workstation other than a named `git push origin <refspec>` or `git fetch origin`), `R2-destructive`, `R3-doctrine` (paths under `decisions/`, `rules/`, `templates/`), `R4-refs`, `R5-company` (the company repository named), `R6-guardians`. Form refusals: `R7-shape` (see `templates/execution-note-template.md`: six rubrics in order, 4,000-character cap, one journal line of 300 characters at most) and `R8-origin` (a mode-2 Note written from an Owner's prompt). An `owner_greenlight` block in a mode-2 Note lifts only the criteria R1 to R6 it names.
- **Guardian name**: none.
- **Called by**: no tool or hook; run by hand as `rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md` prescribes. Tests: `tests/test-check-work-regime.sh`, `tests/test-work-regime-mode2.sh`, `tests/test-work-regime-owner-greenlight.sh`.
- **Syntax**: `bash tools/check-work-regime.sh note <file>` or `bash tools/check-work-regime.sh diff <repo> <range>`.
- **Exit codes and last line**: 0, `REGIME-LIGHT-OK` (after `OWNER-GREENLIGHT <ids> at <time>` when a go-ahead applies); 1, `REFUSED <id>[,<id>...]`, details on the error output; 2, the usage line, a missing file, a folder that is not a Git repository, or an unreadable or empty range.
- **Reads**: the Note (and, in mode 2b, the files it lists), or `git diff --name-status` of the range. **Writes**: in `note` mode, one temporary copy (`mktemp`), removed on exit. **Repository-root guard**: none needed; `<repo>` is only read.

```bash
bash tools/check-work-regime.sh note templates/execution-note-template.md
bash tools/check-work-regime.sh
```

## tools/session-preflight.sh

- **Role**: checks the session is ready: the role charter exists; `AGENTS.md` and `CLAUDE.md` point to it (also in a declared sibling repository, `tools/resolve-sibling-repo.sh`; declared but absent is only a warning); `.claude/settings.json` is valid JSON (node, else python3); `git` and `bash` are on the path; `tools/build-state.sh`, `tools/build-indexes.sh` and `tools/check-links.sh` are executable; `<workspace>/second-brain/.claude/hooks.log`, if present, is not older than 72 hours.
- **Guardian name**: none itself. The `preflight` guardian, inline in `.githooks/pre-commit`, reads its stamp and refuses when it is missing, not `"ready": true`, or older than 1440 minutes; every other guardian depends on it.
- **Called by**: `tools/session-start-role.sh`, `install.sh`, `install.ps1`, `tests/suite.tsv` (first line), `tests/run-suite.sh`.
- **Syntax**: `bash tools/session-preflight.sh` (no argument).
- **Exit codes and last line**: 0, `READY`; 1, `NOT-READY: <n> issue(s)`, each issue on the error output.
- **Reads**: the files above, from the Vault that holds the script. **Writes**: the stamp `<workspace>/second-brain/.claude/.preflight_stamp.json` (role, time, ready, issues, warnings), never committed.
- **Repository-root guard**: none; the stamp path is fixed, derived from the script's location.

```bash
bash <workspace>/second-brain/tools/session-preflight.sh
```

_Not executed by the documentation check._

Since Mission 234 the preflight also runs `tools/check-workspace-root.sh` on the parent of the Vault when that folder carries the marker: each `ÉCART`, `EXCEPTION-PROVISOIRE` or `SIGNALÉ` line becomes a warning of the stamp, never an issue.

## tools/check-workspace-root.sh

- **Role**: compares the root of the workspace with the computed whitelist of the [rule on workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md) §3: `VAULT-ROOT.md` and the workspace guides `CLAUDE.md`, `AGENTS.md` that `tools/write-marker.sh` writes; the Vault at the marker's path; the first segment of every `relative_path` of the project registry (projects and group folders; a group folder holds only registered projects); the organs of the marker line `Organes déclarés à cette racine`; `_trash`, `_archive`, `_orders`. A name on the marker line `Exceptions provisoires à cette racine` is a provisional exception, not a gap. Read-only.
- **Guardian name**: none; called by `tools/session-preflight.sh` as a warning, and by the Executor branch of the session-start skill.
- **Syntax**: `bash tools/check-workspace-root.sh [<workspace root>]` (default: the folder that carries the marker, walking up from the Vault).
- **Exit codes and last line**: 0, `VERDICT: CONFORME (<n> exception(s) provisoire(s)) — <root>`; 1, `VERDICT: <n> ÉCART(S) — <root>`, one `ÉCART: <name> — <reason>` line per gap before it; 2, no marker, no Vault or no registry (named on the error output).
- **Reads**: the marker, the registry, a listing of the root and of each group folder. **Writes**: nothing.
- **Proof**: `tests/test-check-workspace-root.sh`.

```bash
bash <workspace>/second-brain/tools/check-workspace-root.sh <workspace>
```

_Not executed by the documentation check._

## tools/session-start-role.sh

- **Role**: the `SessionStart` hook of `.claude/settings.json`. Prints one JSON line whose context gives the role `executor`, the Vault root, the charter and the forbidden gesture (`git push`). It runs the preflight (if executable) and adds `Preflight NOT-READY...` to the context only when the preflight is not ready.
- **Guardian name**: none. **Called by**: `.claude/settings.json`.
- **Syntax**: `bash tools/session-start-role.sh` (no argument). **Exit codes**: 0 (the preflight's failure is absorbed).
- **Reads**: nothing itself. **Writes**: nothing itself; the preflight it runs writes its stamp. **Repository-root guard**: none; fixed paths only.

```bash
bash <workspace>/second-brain/tools/session-start-role.sh
```

_Not executed by the documentation check._

## tools/start-executor.sh

- **Role**: identity launcher. Exports `VAULT_AGENT=executor` and `VAULT_ROOT`, prints one reminder line of the role and its prohibitions, moves to the Vault root and replaces itself with `claude`, passing every argument through.
- **Guardian name**: none. **Called by**: nothing in the repository (measured); run by hand.
- **Syntax**: `bash tools/start-executor.sh [<claude arguments>...]`.
- **Exit codes**: 1 with `ERREUR start-executor.sh : commande 'claude' introuvable dans PATH.`; otherwise the exit code of `claude`.
- **Reads / Writes**: nothing. **Repository-root guard**: none; it takes no path.

```bash
bash <workspace>/second-brain/tools/start-executor.sh
```

_Not executed by the documentation check._

## tools/bench-folder-guardians.sh

- **Role**: times `tools/check-secrets.sh` and `tools/check-links.sh` in folder mode on a synthetic corpus with a baseline, then the same guardians taken from `--old-ref` (`git archive`) on a sample, with a projection. Outside the test suite: it can write tens of thousands of files and run for minutes.
- **Guardian name**: none. **Called by**: nothing (measured); run by hand.
- **Syntax**: `bash tools/bench-folder-guardians.sh [--files N] [--md M] [--sample S] [--old-ref REF] [--no-before] [--keep]`. Defaults: 60000 files, 4000 Markdown, sample 300, `HEAD`.
- **Exit codes**: 2, the usage line (unknown option); 1, `REFUS : uv introuvable`; otherwise 0, whatever the guardians returned (their code is printed as `rc=`).
- **Writes**: only a throwaway folder `bench-fg-XXXXXX` under the temporary directory, removed at the end unless `--keep` (then `kept: <path>`). **Repository-root guard**: none; it takes no target path.

```bash
bash <workspace>/second-brain/tools/bench-folder-guardians.sh --files 2000 --md 200 --no-before
```

_Not executed by the documentation check._

## tools/lint-ci-workflow.py

- **Role**: structural lint of a GitHub Actions file with the standard library only: tabs, indentation matching no enclosing level, duplicate keys at one level, unbalanced quotes and brackets, missing `name`, `on` or `jobs`, a job without `runs-on:` or `steps:`. It does not check action versions or `${{ }}` expressions.
- **Guardian name**: none. **Called by**: `tests/test-lint-ci-workflow.sh` only.
- **Syntax**: `uv run tools/lint-ci-workflow.py <workflow.yml> [...]`.
- **Exit codes and last line**: 0, `PASS : <n> fichier(s) YAML, 0 probleme structurel trouve.`; 1, one finding per line then `REFUS : <n> probleme(s) structurel(s) trouve(s).` on the error output; 1 also with the usage line when no file is given.
- **Reads**: the files given. **Writes**: nothing. **Repository-root guard**: none needed.

```bash
uv run tools/lint-ci-workflow.py .github/workflows/ci.yml
```

## Liens

- `source` — [Pre-commit hook](../../.githooks/pre-commit)
- `source` — [Secrets check](../../tools/check-secrets.sh)
- `source` — [Private-pattern check](../../tools/check-private-patterns.sh)
- `source` — [Distribution-manifest check](../../tools/check-distribution-manifest.sh)
- `source` — [Agents-command check](../../tools/check-no-slash-agents.sh)
- `source` — [Execute-bit check](../../tools/check-exec-bit-bare-scripts.sh)
- `source` — [Obsolescence guardrail](../../tools/check-obsolescence-guardrail.py)
- `source` — [Work-regime check](../../tools/check-work-regime.sh)
- `source` — [Session preflight](../../tools/session-preflight.sh)
- `source` — [Session-start hook](../../tools/session-start-role.sh)
- `source` — [Executor launcher](../../tools/start-executor.sh)
- `source` — [Folder-guardian bench](../../tools/bench-folder-guardians.sh)
- `source` — [CI workflow lint](../../tools/lint-ci-workflow.py)
- `source` — [Baseline library](../../tools/project-baseline.sh)
- `source` — [Sibling-repository resolver](../../tools/resolve-sibling-repo.sh)
- `source` — [Repository-root guard](../../tools/repo_root_guard.py)
- `source` — [Pre-commit framework hooks](../../.pre-commit-hooks.yaml)
- `source` — [Project bootstrap](../../tools/project-bootstrap.sh)
- `source` — [Publication tool](../../tools/publish-from-laboratory.sh)
- `source` — [Claude Code settings](../../.claude/settings.json)
- `source` — [Test suite list](../../tests/suite.tsv)
- `source` — [Suite runner](../../tests/run-suite.sh)
- `source` — [Standalone run](../../tests/standalone.sh)
- `source` — [Secret refusal test](../../tests/test-guardian-secret-refusal.sh)
- `source` — [Private-pattern test](../../tests/test-check-private-patterns.sh)
- `source` — [Manifest test](../../tests/test-distribution-manifest-no-heredoc-hang.sh)
- `source` — [Agents-command test](../../tests/test-check-no-slash-agents.sh)
- `source` — [Execute-bit test](../../tests/test-exec-bit-bare-scripts.sh)
- `source` — [Front-matter BOM test](../../tests/test-lab-language-local-file.sh)
- `source` — [Work-regime tests](../../tests/test-check-work-regime.sh)
- `source` — [Work-regime mode-2 test](../../tests/test-work-regime-mode2.sh)
- `source` — [Owner go-ahead test](../../tests/test-work-regime-owner-greenlight.sh)
- `source` — [Lint test](../../tests/test-lint-ci-workflow.sh)
- `source` — [Installer, shell](../../install.sh)
- `source` — [Installer, PowerShell](../../install.ps1)
- `source` — [Execution Note template](../../templates/execution-note-template.md)
- `source` — [Two work regimes](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `see also` — [Guardians and hooks](./guardians-and-hooks.md)
- `see also` — [Why guardians](../explanation/guardians.md)
- `see also` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `see also` — [Internal helpers](./tools-internal-helpers.md)
