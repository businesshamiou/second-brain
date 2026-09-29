---
type: reference
title: "Internal helpers and the repository-root guard"
description: "What the repository-root guard admits and refuses before a Vault tool writes, and what each internal helper and data entry of tools/ is for and who uses it."
status: active
---

# INTERNAL HELPERS AND THE REPOSITORY-ROOT GUARD

This page covers the parts of `tools/` that you rarely run yourself. It starts with the repository-root guard, the check that stops a writing tool before it writes into the wrong folder. Then it lists the helper libraries that other tools load, and the entries of `tools/` that are not scripts.

## repo_root_guard.py

**Role.** `tools/repo_root_guard.py` is the one place that decides whether a Vault tool may write under a target folder (Mission 226). It exists because the index builder was once run with `.` from the workspace root, a folder that holds several repositories without being one, and rewrote index files in sibling folders ([the rule](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)). There is no switch and no environment variable that turns it off.

**Called by** (measured with `git grep -n repo_root_guard`):

| Caller | How | What the caller does on a refusal |
|---|---|---|
| `tools/append-journal.sh` | runs it on `<chemin-projet>` before writing | exits 1 |
| `tools/build-state.sh` | runs it on `<chemin-projet>` before writing | exits 1 |
| `tools/build-digest.sh` | runs it on `<chemin-projet>` before writing | exits 1 |
| `tools/set-release-version.sh` | runs it on `<root>` before writing | prints `REFUS : racine refusee par le garde-fou : <root>`, last line `REFUSED`, exits 1 |
| `tools/vault-identity.sh` | runs it in `ensure` mode on the root it is given (the Vault root by default) before writing the identity | exits 1 |
| `tools/project-bootstrap.sh` | runs it with `--new-project` on the target folder (`create` or `adopt`), and in default mode on the project folder (`prompt`) | exits 1 |
| `tools/build_indexes.py` (launched by `tools/build-indexes.sh`) | imports it, calls `check()` for each root | skips that root, goes on with the others, then exits 1 |
| `tools/propose_link_repairs.py` (launched by `tools/propose-link-repairs.sh`) | imports it, calls `check()` before reading or writing | exits 2 |

The Bash callers run it with `uv run --no-project`. The test `tests/test-repo-root-guard.sh` replays the incident against each of these tools.

**Syntax** (from the code):

```
repo_root_guard.py [--new-project] <path>
```

**Options.**

| Option | Effect |
|---|---|
| `<path>` | The folder the calling tool is about to write under. Relative paths are turned into absolute paths; the message shows both. |
| `--new-project` | Mode for a project that is being created or adopted, and is often in no repository yet. See below. |

**Two words used below.**

- A **workspace root** is a folder that has no `<folder>/.git` entry of its own and either carries `<workspace>/VAULT-ROOT.md`, or holds two or more direct subfolders that each contain their own `<subfolder>/.git`.
- A **birth certificate** is the comment block at the top of `<project>/.pre-commit-config.yaml` whose header line is `# second-brain-birth-certificate: v1` (read by `read_certificate()` in `tools/project_baseline.py`).

**What it admits and refuses (default mode).** The guard first refuses a path that exists and is not a folder. Otherwise it starts from the path (or from its nearest existing parent, if the path does not exist yet) and walks up, one folder at a time. At each folder it checks, in this order:

1. a `<folder>/.git` entry (folder, or file for a worktree): **admitted**;
2. a birth certificate: **admitted**;
3. the system temporary folder (Mission 231): **admitted** -- the target is a throwaway folder below it;
4. a workspace root: **refused**. The walk stops there, so a Git repository higher up (for example a dotfiles repository in your profile) never admits the whole workspace;
5. the filesystem root, with nothing found: **refused**.

**The system temporary folder** (Mission 231) is never a workspace root, however many repositories other work has left in it (six on the Owner's workstation, measured 2026-09-26). It is the folder Python's `tempfile.gettempdir()` names. The folder itself is **refused**, in both modes. A workspace root *below* it is judged as anywhere else, so a throwaway workspace built by a test is still refused. It is not taken for the temporary folder when it is your home folder, a filesystem root, or carries `VAULT-ROOT.md` (a `TMPDIR` pointed at a workspace by mistake leaves that workspace a workspace root). Proof: `tests/test-repo-root-guard-system-temp.sh`.

**What it admits and refuses (`--new-project`).** A path that exists and is not a folder is refused. The system temporary folder itself is refused. A folder that is itself a workspace root is refused. Everything else is admitted, including a folder that does not exist yet; `tools/project-bootstrap.sh` does its own checks after that.

**Exit codes and last line.**

| Code | Meaning | Output |
|---|---|---|
| 0 | Admitted | nothing |
| 1 | Usage error (no path, or more than one) | `usage: repo_root_guard.py [--new-project] <path>` on stderr |
| 2 | Refused | one line on stderr starting with `REPO-ROOT-REFUSED:` and ending with `Nothing written.` |

**The REPO-ROOT-REFUSED messages.** Each one names the path received, then its absolute form in brackets. The four forms, from the code:

| Case | Message, after `REPO-ROOT-REFUSED: <path> (<absolute path>)` |
|---|---|
| Not a folder | `is not a folder; expected <expected>. Nothing written.` |
| Below a workspace root | `is not inside a repository: <folder> is a workspace root (<reason>). Expected <expected>, for example <folder>/<repository>. Nothing written.` |
| No repository, no certificate, up to the filesystem root | `is in no Git repository and carries no birth certificate; expected <expected>. Nothing written.` |
| `--new-project` on a workspace root | `is a workspace root (<reason>); a project is created in its own folder below it, e.g. <path>/<project>. Nothing written.` |

`<expected>` is the text `the root of a Git repository, or a folder inside one, or a project with a birth certificate, below the workspace root`. `<reason>` is either "it carries VAULT-ROOT.md" or "it holds <n> Git repositories without being one". The example path is built with your system's separator (a backslash on Windows).

**Reads.** For each folder on the walk: whether `<folder>/.git` and `<workspace>/VAULT-ROOT.md` exist, its direct subfolders, and its birth certificate.

**Writes.** Nothing.

**Repository-root guard.** This is the guard itself. It writes nothing.

**Example.** The workspace root is refused; the Vault is admitted. Neither command writes anything.

```bash
uv run --no-project <workspace>/second-brain/tools/repo_root_guard.py <workspace>; echo "exit $?"
uv run --no-project <workspace>/second-brain/tools/repo_root_guard.py <workspace>/second-brain; echo "exit $?"
```

The first prints a line that starts with `REPO-ROOT-REFUSED: <workspace>` and names the reason "it carries VAULT-ROOT.md", then `exit 2`. The second prints only `exit 0`. If a writing tool shows you this message, rewrite your command with the absolute path of the right repository ([react to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)).

## Internal helpers

These files are loaded by other tools. You do not run them yourself, except `tools/resolve-vault.sh` and `tools/project_baseline.py`, which also work on their own. "Sourced" means loaded into a Bash script with `.`; "dot-sourced" is the PowerShell equivalent.

| Helper | Role | Who sources or imports it |
|---|---|---|
| `tools/check-readable.sh` | Reads every file about to be staged in a repository (`check-readable.sh <repo> [<path>...]`; without paths, every path `git status --porcelain -uall` lists) and refuses when one cannot be read -- the case of a file whose access control list, left by an agent's sandbox, denies your account (Mission 231). Prints `UNREADABLE <path>` per file, the remedy (`takeown /f`, then `icacls ... /reset`; `chmod u+r` on macOS and Linux), last line `REFUSED`, exit 1; otherwise `READABLE <n>`, exit 0; exit 2 on a usage error. Writes nothing. | Run by `install.sh` (`stage_and_commit_clone_changes`) and `install.ps1` (`Save-ClonePendingChanges`) before their staging; prescribed by hand before `git add` in [Troubleshoot](../how-to/troubleshoot.md); tested by `tests/test-check-readable.sh`. |
| `tools/lib/tmp.sh` | The declared temporary folder (Mission 234, [rule on workspace hygiene](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md) §2): `sb_tmp_root` (the folder: `SB_TMP`, else the marker line `Dossier temporaire déclaré`, else `<system temporary folder>/second-brain`; refused, before anything is created, when it lies below a folder that carries `VAULT-ROOT.md`), `sb_tmp_dir <use>` (a sub-folder: `tests`, `tools`, `reference-clones`, `m<NNN>`...), `sb_tmp_export <use>` (exports `SB_TMP`, `TMPDIR` and, on Windows, `TEMP`/`TMP`). | Sourced by every tool that writes a throwaway file (each `mktemp` gets a template under `sb_tmp_dir tools`), by `tools/write-marker.sh`, `tools/check-workspace-root.sh`, `install.sh`, `tests/run-suite.sh` (exports `tests`) and `tests/sandbox-vault.sh` (reference clones); tested by `tests/test-declared-temp-folder.sh`. `bootstrap.sh` applies the same rule inline, before any Vault exists. |
| `tools/lib/mcp-hosts.sh` | The hosts of the Vault's MCP server (Mission 242, [rule on model-agnostic hosts](../../rules/RULES-2026-09-28-121219-model-agnostic-pilot-and-executor-hosts.md)): `mcp_hosts` prints one line per host configuration, tab-separated — id, name, format (`claude-cli`, `codex-cli`, `json`, `json-stdio`), configuration path, present `1`/`0` (its folder or its command measured); `mcp_hosts --native` gives the paths in the native form; `mcp_tool_name_length <server>` the length of `mcp__<server>__list_allowed_directories` (cap `MCP_TOOL_NAME_MAX`, 64). Writes nothing. | Sourced by `tools/install-vault-mcp.sh`, `tools/check-mcp-containment.sh` and `tools/sb/sb.py` (`sb doctor`, `sb pilot-prompt --host`); tested by `tests/test-mcp-hosts-agnostic.sh`. |
| `tools/lib/tmp.ps1` | PowerShell twin: `Get-SbTmpRoot`, `Get-SbTmpDir -Use <use>`, same order and same refusal. | Dot-sourced by `install.ps1` and `tests/run-suite.ps1` (sets `SB_TMP`, `TEMP`, `TMP`, `TMPDIR` for the tests); `bootstrap.ps1` applies the rule inline. |
| `tools/relpath.sh` | Defines `rel_path BASE TARGET` (the path of TARGET relative to BASE) and `abs_path`, in plain shell that works on Windows, macOS and Linux, instead of GNU-only `realpath` options. | Sourced by `tools/build-digest.sh`, `tools/build-state.sh`, `tools/check-links.sh`, `tools/check-project-conformity.sh`, `tools/link-graph-drone-view.sh`, `tools/project-bootstrap.sh`, `tools/write-marker.sh`; named in 3 files under `tests/`. |
| `tools/kvmap.sh` | Key-value maps for bash 3.2 (the macOS default, which has no `declare -A`): `kv_set`, `kv_get`, `kv_has`, `kv_keys`, keys kept in insertion order. | Sourced by `tools/check-distribution-manifest.sh`, `tools/find-in-vault.sh`, `tools/link-graph-drone-view.sh`; named in 3 files under `tests/`. |
| `tools/resolve-vault.sh` | Finds a project's Vault: first the birth certificate (walking up), then the workspace marker, with a matching `vault_id`; sets `RV_STATUS`, `RV_VAULT`, `RV_MODE`, `RV_PROJECT`, `RV_WORKSPACE`, `RV_MESSAGE`. Run directly as `resolve-vault.sh [<folder>]`, it prints the Vault path (exit 0) or `REFUS : <cause>` on stderr (exit 1). It sources `tools/vault-identity.sh`. | Sourced by `tools/check-mcp-containment.sh`, `tools/check-project-conformity.sh`, `tools/project-baseline.sh`, `tools/project-bootstrap.sh`; run directly by the [session-start skill](../../skills/session-start/SKILL.md); named in 5 files under `tests/`. |
| `tools/resolve-sibling-repo.sh` | `resolve_declared_sibling <workspace-root>`: reads a sibling repository declared by the `SECOND_BRAIN_SIBLING_REPO` variable or by the first line of `<workspace>/SIBLING-REPO.txt`; sets `SIBLING_DECLARED`, `SIBLING_NAME`, `SIBLING_ROOT`; prints nothing. Never presumes a sibling. | Sourced by `tools/check-asserted-paths.sh`, `tools/link-graph-drone-view.sh`, `tools/session-preflight.sh`; named in 4 files under `tests/`. |
| `tools/resolve-bash-exe.ps1` | Defines the PowerShell function `Resolve-BashExe`, which finds Git Bash's `bash.exe` from `git.exe` (up to three folders up), and falls back to a `bash.exe` on the PATH only if it is not under the Windows folder (which would be the WSL stub). | Dot-sourced by `install.ps1` and `tools/second-brain-update.ps1`; named in `tools/environment-fingerprint.ps1` and in 20 files under `tests/`. |
| `tools/project-baseline.sh` | The dated baseline and ratchet for the Bash guardians: `pb_load`, `pb_untouched`, `pb_touched`, `pb_classify`, `pb_text`, `pb_list_files`, `pb_sha256`. A file listed in an adopted project's baseline and left unchanged is never flagged; a touched one must become compliant. It sources `tools/resolve-vault.sh` and calls `tools/project_baseline.py` for `filter`, `text` and `list`. | Sourced by `tools/check-links.sh` and `tools/check-secrets.sh`; named in 4 files under `tests/`. |
| `tools/project_baseline.py` | Python twin of the above, same file format and verdict; also reads the birth certificate (`read_certificate`) and the `# exempt:` key. Subcommands: `write`, `list`, `filter`, `text`, `amend`, `retire`. | Imported by `tools/build_indexes.py`, `tools/check_index_weight.py`, `tools/check_indexes_fresh.py`, `tools/propose_link_repairs.py`, `tools/repo_root_guard.py`; run by `tools/project-bootstrap.sh` (`write`, at adoption), `tools/project-baseline.sh` and `tools/bench-folder-guardians.sh`; its `amend` subcommand is described in the [project-bootstrap skill](../../skills/project-bootstrap/SKILL.md); named in 5 files under `tests/`. |

## Entries of tools/ that are not scripts

Measured with `git ls-files tools` and a listing of the folder.

| Entry | What it is |
|---|---|
| `tools/prerequisites.lock.json` | Tracked data file: the pinned versions of Git, uv and pre-commit, with the download addresses and SHA-256 fingerprints of Git and of uv's install scripts. Read by `tools/prerequisites.ps1`, `tools/prerequisites.sh`, `bootstrap.ps1`, and the test-environment action under `.github/actions/setup-test-env/`. |
| `tools/__pycache__/` | Python's own cache of compiled modules, created when the Python tools run. Not tracked: `git ls-files` lists nothing in it, and a Python-cache line of `.gitignore` ignores it. You can ignore it. |

## Liens

- `source` — [tools/repo_root_guard.py](../../tools/repo_root_guard.py)
- `source` — [Rule: absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [tests/test-repo-root-guard.sh](../../tests/test-repo-root-guard.sh)
- `source` — [tools/append-journal.sh](../../tools/append-journal.sh)
- `source` — [tools/build-state.sh](../../tools/build-state.sh)
- `source` — [tools/build-digest.sh](../../tools/build-digest.sh)
- `source` — [tools/set-release-version.sh](../../tools/set-release-version.sh)
- `source` — [tools/vault-identity.sh](../../tools/vault-identity.sh)
- `source` — [tools/project-bootstrap.sh](../../tools/project-bootstrap.sh)
- `source` — [tools/build_indexes.py](../../tools/build_indexes.py)
- `source` — [tools/build-indexes.sh](../../tools/build-indexes.sh)
- `source` — [tools/propose_link_repairs.py](../../tools/propose_link_repairs.py)
- `source` — [tools/propose-link-repairs.sh](../../tools/propose-link-repairs.sh)
- `source` — [tools/relpath.sh](../../tools/relpath.sh)
- `source` — [tools/kvmap.sh](../../tools/kvmap.sh)
- `source` — [tools/resolve-vault.sh](../../tools/resolve-vault.sh)
- `source` — [tools/resolve-sibling-repo.sh](../../tools/resolve-sibling-repo.sh)
- `source` — [tools/resolve-bash-exe.ps1](../../tools/resolve-bash-exe.ps1)
- `source` — [tools/project-baseline.sh](../../tools/project-baseline.sh)
- `source` — [tools/project_baseline.py](../../tools/project_baseline.py)
- `source` — [tools/check-links.sh](../../tools/check-links.sh)
- `source` — [tools/check-secrets.sh](../../tools/check-secrets.sh)
- `source` — [tools/check-project-conformity.sh](../../tools/check-project-conformity.sh)
- `source` — [tools/check-mcp-containment.sh](../../tools/check-mcp-containment.sh)
- `source` — [tools/check-asserted-paths.sh](../../tools/check-asserted-paths.sh)
- `source` — [tools/check-distribution-manifest.sh](../../tools/check-distribution-manifest.sh)
- `source` — [tools/check_index_weight.py](../../tools/check_index_weight.py)
- `source` — [tools/check_indexes_fresh.py](../../tools/check_indexes_fresh.py)
- `source` — [tools/find-in-vault.sh](../../tools/find-in-vault.sh)
- `source` — [tools/link-graph-drone-view.sh](../../tools/link-graph-drone-view.sh)
- `source` — [tools/write-marker.sh](../../tools/write-marker.sh)
- `source` — [tools/session-preflight.sh](../../tools/session-preflight.sh)
- `source` — [tools/bench-folder-guardians.sh](../../tools/bench-folder-guardians.sh)
- `source` — [tools/second-brain-update.ps1](../../tools/second-brain-update.ps1)
- `source` — [tools/environment-fingerprint.ps1](../../tools/environment-fingerprint.ps1)
- `source` — [install.ps1](../../install.ps1)
- `source` — [bootstrap.ps1](../../bootstrap.ps1)
- `source` — [tools/prerequisites.lock.json](../../tools/prerequisites.lock.json)
- `source` — [tools/prerequisites.ps1](../../tools/prerequisites.ps1)
- `source` — [tools/prerequisites.sh](../../tools/prerequisites.sh)
- `source` — [.gitignore](../../.gitignore)
- `source` — [session-start skill](../../skills/session-start/SKILL.md)
- `source` — [project-bootstrap skill](../../skills/project-bootstrap/SKILL.md)
- `see also` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `see also` — [Why absolute paths](../explanation/why-absolute-paths.md)
- `see also` — [Tools: state and journal](tools-state-and-journal.md)
- `see also` — [Tools: indexes and links](tools-indexes-and-links.md)
- `see also` — [Tools: projects](tools-projects.md)
- `see also` — [Tools: guardians](tools-guardians.md)
- `see also` — [Tools: install and update](tools-install-and-update.md)
