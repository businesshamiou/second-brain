---
type: reference
title: "Tools: install and update"
description: "One sheet per script for the bootstrap lines, the installer's options, its prerequisite, questionnaire and link libraries, the update tool, the profile-link cleaner, the installer's Python helper and the environment fingerprints."
status: active
---

# TOOLS: INSTALL AND UPDATE

This page describes, script by script, what installs Second Brain and what brings an installed copy to a new version, as the code reads today. The full installation flow (steps, questions, what lands where) is in [INSTALL.md](../../INSTALL.md); this page only gives the installers' options. Scripts come in a macOS/Linux form (`.sh`, bash) and a Windows form (`.ps1`, Windows PowerShell 5.1), except where noted. Placeholders: `<profile>` is your home folder (`HOME`, or `USERPROFILE` on Windows); `<temp>` is the temporary folder (`TMPDIR`, else /tmp; `TEMP` on Windows); `<clone>` is a local second-brain clone.

**Under Windows.** A `bash …/tools/…` line of this page, typed in PowerShell where `bash` is unknown, starts with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`; where an `sb` verb carries the same gesture ([Commands](commands.md)), type the verb. `sb doctor` says whether `bash` is on your PATH.

## `bootstrap.sh`

**Role.** What the published macOS/Linux line downloads and runs. It needs nothing installed first: (1) if `git` is not on the PATH, on Linux it downloads the static Git pinned in `tools/prerequisites.sh`, checks its SHA-256 and extracts it into `<profile>/.local/share/second-brain/git-linux64`; on macOS it asks for Apple's Command Line Tools (`xcode-select --install`) and stops, asking you to run the line again once they are installed; (2) it brings the clone at `--target` to `--ref` with that Git, PATH untouched; (3) it runs the cloned `install.sh` with `--source <target>`. Nothing uses `sudo`.

**Called by.** The published line ([INSTALL.md §2](../../INSTALL.md)); the `smoke-from-github` job of `.github/workflows/ci.yml`. `tools/set-release-version.sh` rewrites its `REF=` line and the URL in its header. Tests: `tests/test-bootstrap-stale-temp-clone.sh`, `tests/test-bootstrap-keyboard.sh`.

**Syntax.** `bootstrap.sh [--ref <tag-or-branch>] [--repo-url <url-or-path>] [--raw-base <url-or-directory>] [--target <dir>] [--answers-file <path>] [--test-mode --test-root <dir>] [--stop-after-step <name>]`

| Option | Default | Meaning |
|---|---|---|
| `--ref` | `v0.1.14` | Tag, branch or commit to install. |
| `--repo-url` | `https://github.com/businesshamiou/second-brain.git` | Repository to clone; a local path is accepted. |
| `--raw-base` | `https://raw.githubusercontent.com/businesshamiou/second-brain/<ref>` | Where `tools/prerequisites.sh` is read from; a local directory is accepted. |
| `--target` | `<temp>/second-brain/second-brain-install`, or `$SB_TMP/second-brain-install` (test mode: `<test-root>/second-brain-install`) | The clone the installer is run from. |
| `--answers-file`, `--stop-after-step` | none | Passed to `install.sh` (`--stop-after-step` is for tests only). |
| `--test-mode --test-root <dir>` | off | Passed to `install.sh`; the profile becomes `<test-root>/profile`. `--test-root` is required with `--test-mode`. |

**An existing clone at `--target`** is brought to `--ref`, never deleted: its `origin` must name the same repository; it runs `git fetch --tags origin`, resolves `--ref` as a tag, then a remote branch, then a commit, checks it out detached and checks that HEAD equals it. **Keyboard:** under `curl … | bash`, with no answers file and a terminal device that opens, `install.sh` reads your keyboard, not the pipe.

**Exit codes and last line.** The exit code of `install.sh`, or 1 with `Second Brain bootstrap stopped: <reason>`. Reasons: `unknown argument: <arg>`; `--test-root is required with --test-mode.`; the pinned Git entry cannot be read; a Git download or extraction failure; `the downloaded Git archive does not match its pinned SHA-256 (expected …, got …).`; `<target> is a clone of '<origin>', not of '<repo-url>'; move <target> aside and run the line again.`; a failed fetch or checkout; `<ref> does not exist in <repo-url>; nothing was installed.`; `<target> exists but is not a Git repository; move it aside and run the line again.`; `git clone of <repo-url> failed.`; on macOS, `Git comes with Apple's Command Line Tools: finish the installation Apple just offered, then run the same line again.`; `cannot create <dir>`; `cannot read tools/prerequisites.sh from <raw-base>`. **Reads.** `tools/prerequisites.sh` from `--raw-base` (Linux, only when Git is missing). **Writes.** `<profile>/.local/share/second-brain/downloads` and `<profile>/.local/share/second-brain/git-linux64` (Linux, only when Git is missing); the clone at `--target`. **Repository-root guard.** No: it writes to fixed profile paths and to its own clone folder. **Example.**

```bash
curl -fsSL https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.14/bootstrap.sh | bash
```

_Not executed by the documentation check._

## `bootstrap.ps1`

**Role.** The Windows twin of `bootstrap.sh`, with no Git and no administrator rights needed. Differences: it reads the `git` entry of `tools/prerequisites.lock.json` from `-RawBase`; a missing Git is the pinned PortableGit, extracted into `<profile>\.local\share\second-brain\PortableGit`; an archive that fails its SHA-256 is deleted before the refusal; it sets `core.longpaths true` on the clone; it runs the cloned `install.ps1` with `-Source <Target>` in a separate `powershell -NoProfile -ExecutionPolicy Bypass` process. **Called by.** The published line ([INSTALL.md §2](../../INSTALL.md)); `tools/set-release-version.sh` rewrites its `$Ref` default. Tests: `tests/test-bootstrap-no-git.ps1`, `tests/test-bootstrap-stale-temp-clone.ps1`, `tests/test-install-standard-user.ps1`. **Syntax.** `bootstrap.ps1 [-Ref <tag-or-branch>] [-RepoUrl <url-or-path>] [-RawBase <url-or-directory>] [-Target <directory>] [-AnswersFile <path>] [-TestMode -TestRoot <path>] [-StopAfterStep <name>]`. Same defaults as `bootstrap.sh`, except `-Target`: `<temp>\second-brain\second-brain-install` (or `$env:SB_TMP\second-brain-install`).

**Exit codes and last line.** The exit code of `install.ps1`, or 1 with `Second Brain bootstrap stopped: <reason>` (the same reasons, except that an unknown parameter is rejected by PowerShell itself and the test-mode reason reads `-TestRoot is required with -TestMode.`; any unexpected error is caught and reported the same way). **Writes.** `<profile>\.local\share\second-brain\downloads` and `<profile>\.local\share\second-brain\PortableGit` (only when Git is missing); the clone at `-Target`. **Repository-root guard.** No, for the same reason. **Example.**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.14/bootstrap.ps1)))"
```

_Not executed by the documentation check._

## `install.sh`

**Role.** The macOS/Linux installer, run from a local clone; its steps are in [INSTALL.md §3](../../INSTALL.md). It sources `tools/prerequisites.sh` and uses `tools/sb_installer_helper.py` for every JSON read or write. **Called by.** `bootstrap.sh`; the `first-install` skill ([SKILL.md](../../skills/first-install/SKILL.md)), with an answers file. Test: `tests/test-install-e2e.sh`.

**Syntax.** `install.sh --source <path-to-local-second-brain-repo> [--answers-file <path-to-json>] [--test-mode --test-root <path>] [--scripted-answers <line>]... [--stop-after-step <name>]`

| `install.sh` | `install.ps1` | Meaning |
|---|---|---|
| `--source <path>` | `-Source <path>` | Required. A local second-brain repository, cloned with `git clone`, never fetched over the network. |
| `--answers-file <json>` | `-AnswersFile <json>` | No question is printed: each field comes from the file or its default. Shape: `tests/fixtures/install-answers.sample.json`; `workspacePath` is required. |
| `--test-mode` + `--test-root <dir>` | `-TestMode` + `-TestRoot <dir>` | Everything written outside the workspace (profile defaults, prerequisites, PATH) goes under the test root. |
| `--scripted-answers <line>` (repeatable) | `-ScriptedAnswers <string[]>` | Test only: answers replayed in order instead of the keyboard. |
| `--stop-after-step <name>` | `-StopAfterStep <name>` | Test only: `prerequisites`, `workspace`, `clone`, `guardians`, `marker`, `assistant`, `firstProject` or `profile`; stops with `Forced stop for testing, after step: <name>` once that step is saved. |
| `--verbose` | `-Verbose` | Prints the per-index detail of the index rebuild. |
| `-h`, `--help` | — | Prints the header and exits 0. |

**Exit codes and last line.** 0: the one-line verdict, signed with the assistant's name; also 0 in update mode when you answer that nothing changed. 1: `Stopped at step <step>: <cause> What to do: …` (in your language once it is chosen), also written to the notebook; or, when an installation is already there without this version, the message naming the update command. 2: `Unknown argument: <arg>`, a missing `--source` (usage line on stderr), or `--test-root is required with --test-mode.` 130: Esc or Ctrl+C in the gum questionnaire. **Writes.** The workspace and its clone; the notebook `<workspace>/second-brain/.install/state.json`; when it installs a prerequisite, a PATH block marked `# Added by the Second Brain installer` in `<profile>/.profile` (test mode: `<test-root>/simulated-user-path.txt`). **Repository-root guard.** No: it creates the workspace by design. **Example.**

```bash
bash <clone>/install.sh --source <clone> --answers-file <answers.json>
```

_Not executed by the documentation check._

## `install.ps1`

**Role.** The Windows installer, same flow and same options (table above); `-Source` is mandatory and `-StopAfterStep` only accepts the eight step names. It dot-sources `tools/resolve-bash-exe.ps1`, `tools/prerequisites.ps1`, `tools/questionnaire.ps1`, `tools/generate-assistant.ps1` and `tools/deploy-skills.ps1`. **Called by.** `bootstrap.ps1`; the `first-install` skill. Test: `tests/test-install-e2e.ps1`. **Exit codes and last line.** 0 or 1, as for `install.sh`. A network failure while fetching a prerequisite gives the cause `Network unreachable while downloading a required tool.` (or its translation). **Writes.** As `install.sh`, with the PATH entry in your account's user `Path` variable instead of `<profile>/.profile`. **Repository-root guard.** No. **Example.**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone>\install.ps1" -Source "<clone>" -AnswersFile "<answers.json>"
```

_Not executed by the documentation check._

## `tools/prerequisites.sh`

**Role.** Library sourced by `install.sh`; defines `ensure_prerequisites`, which makes Git, uv and pre-commit usable. A tool already on the PATH is reused as is. Otherwise, into the profile, never with `sudo`: Git on macOS through `xcode-select --install`; on Linux through `brew` or `nix-env` if already present, else the pinned static build into `<profile>/.local/share/second-brain/git-linux64`; uv through its pinned `install.sh` (version 0.12.13) into `<profile>/.local/bin`; pre-commit through `uv tool install pre-commit==<version>`, the version read from the lock file. The two downloads (the Git archive, the uv install script) are checked against their SHA-256 and deleted on mismatch. The caller must define `add_installer_path_entry`, `CTX_PROFILE_ROOT` and `CTX_TEST_MODE`; with `CTX_TEST_MODE=1`, uv's tool, cache and Python folders are redirected under the test profile. **Called by.** `install.sh`; `bootstrap.sh` reads its three `SB_GIT_LINUX64_*` lines. Test: `tests/test-install-e2e.sh`. **Pins.** `SB_GIT_LINUX64_*` and `SB_UV_INSTALL_SH_*` repeat entries of `tools/prerequisites.lock.json` as shell constants, because uv is not there yet to read JSON; they must stay identical to it. **Exit codes.** `ensure_prerequisites` returns 0, or 1 with a message on stderr (for example `SHA-256 mismatch for '<file>' downloaded from <url> …`, `Static Git extraction failed: …`, `uv tool install pre-commit ran but pre-commit is not on PATH.`). **Repository-root guard.** No: fixed profile paths.

## `tools/prerequisites.ps1`

**Role.** The Windows twin, dot-sourced by `install.ps1`: `Assure-Prerequisites -Context <context> -AddPersistentPathEntry <function>` returns `{ Git; Uv; PreCommit }`. Git is the PortableGit of the lock file, extracted into `<profile>\.local\share\second-brain\PortableGit`; its cached archive is re-verified on each run. uv is its pinned `install.ps1`, into `<profile>\.local\bin`; pre-commit comes through `uv tool install`. Never elevated. Test hook: `SB_TEST_FORCE_NETWORK_FAILURE=1` simulates a network failure. **Called by.** `install.ps1`. Test: `tests/test-prerequisites-e2e.ps1`. **Errors.** It throws, for example `Prerequisites lock file not found: …` or `SHA-256 mismatch for '<file>' downloaded from <url> …`; `install.ps1` turns that into its step verdict. **Repository-root guard.** No.

### `tools/prerequisites.lock.json`

Data file, not a script: `git` (PortableGit 2.55.0.5 for Windows, and its `linux64` entry, an unofficial community static build 2.55.0), `uv` (0.12.13, the Windows and Unix install scripts with their SHA-256) and `preCommit` (4.6.2). Read by `tools/prerequisites.ps1`, `bootstrap.ps1`, `tools/prerequisites.sh` (pre-commit version) and the CI setup action.

## `tools/questionnaire.ps1`

**Role.** Library dot-sourced by `install.ps1`: loads the English, French and Spanish catalogs of `i18n/`; reads one answer at a time (keyboard, or the scripted queue of the tests); proposes the Windows display language as the default of the first question; validates the workspace path; writes `USER.md` (`Write-UserProfile`). In a real terminal, without an answers file or scripted answers, the questions are shown by gum, installed with `winget` (Windows) or `brew` (macOS) when missing; a failed install falls back to plain questions. In test mode, gum is set up only when a test forces a terminal (`SB_INSTALLER_TEST_FORCE_TTY=1`), and then only with tools found under the test root. **Called by.** `install.ps1`. **Writes.** `<clone>/USER.md` when `install.ps1` calls it; gum, when it installs it. **Repository-root guard.** No: it writes where `install.ps1` tells it.

## `tools/second-brain-update.sh`

**Role.** Brings an installed Second Brain to a published version, by a merge, never a copy. In order: (1) refusals before anything is touched; (2) `git fetch --tags origin`, the version must be a tag there; (3) if the version is already in HEAD's history: `VERDICT: UP-TO-DATE`, unless the assistant's forms are stale; (3b) since Mission 231, if the version's own `tools/second-brain-update.sh` differs from the running one (line endings ignored), the version's `tools/` and `i18n/` are extracted to a temporary folder and **that** tool is run with `--vault`, once (the environment variable `SB_UPDATE_DELEGATED` marks it, and it never hands over again); its exit code and verdict are returned, after a line `SB-UPDATE-HANDOVER: <version>`; a version without an update tool is refused; (4) `git merge --no-ff --no-commit`, where conflicts on `index.md` take the version's side and any other conflict aborts; (5) `vault_id` must be unchanged; (5b) the assistant's three forms (`<clone>/.claude/agents/<slug>.md`, `<clone>/.agents/skills/<slug>`, `<clone>/web-package/<slug>`) are regenerated by the version's own `tools/sb_installer_helper.py` (subcommand `render-assistant`), under the name the installer recorded in its notebook `<clone>/.install/state.json` (the assistant's name, else the answer to the name question) and in the language recorded there; with no recorded name nothing is generated and the message says so; (6) indexes rebuilt by `tools/build-indexes.sh`, `tools/session-preflight.sh` stamped, then one merge commit `Update to second-brain <version>` through the guardians. Since Mission 223, steps 3 and 5b regenerate the assistant's forms: a version merged by an older tool gets them regenerated in a guarded commit of their own, and the verdict is then `UPDATED`. Run from inside the Vault it updates, it first copies `tools/` and `i18n/` to a temporary folder and runs from there.

**Called by.** `tools/second-brain-update.ps1`; the `update` skill ([SKILL.md](../../skills/update/SKILL.md)); [INSTALL.md §7](../../INSTALL.md); the "already installed" message of both installers. Tests: `tests/test-update-installed-vault.sh`; the handover (3b), `tests/test-update-delegates-to-received-tool.sh`. **Syntax.** `usage: second-brain-update.sh <version> [--vault <racine>] [--lang FR|EN|ES]`. **Options.** `--vault <root>`: the installed clone to update (default: the Vault that holds the script). `--lang`: message language (default: the language in the notebook, else English; an unknown code falls back to English).

**Exit codes and last line.** 0 with `VERDICT: UPDATED` or `VERDICT: UP-TO-DATE`. 1 with `VERDICT: REFUSED` after a message from the catalog of that language (English: `i18n/catalog.en.json`): not a Git clone, uncommitted changes, no generated identity, no `origin`, an `origin` that is the installer's temporary folder (installed before v0.1.4: reinstall), a failed fetch, an unknown version, a version without an update tool, a version tool that could not be extracted, a conflict outside `index.md`, an identity that would change, an assistant that could not be regenerated, indexes that could not be rebuilt, a guardian refusal. 1 with the usage line alone for a bad argument. If the MCP server may have changed, a message says to run `tools/install-vault-mcp.sh` again. **Writes.** Only this Vault: the merge commit (or the regeneration commit); never a project, the profile or a tool configuration. **Repository-root guard.** No: it acts on the Git clone given by `--vault` (or its own) and refuses a folder that is not one. **Example.** A refusal, nothing touched:

```bash
bash <workspace>/second-brain/tools/second-brain-update.sh
```

### `tools/skill-renames.tsv`

**Role.** The table of the skills the Vault renamed (Mission 237): one line per rename, old name, new name, Mission, tab-separated (`ecriture-de-mission` → `mission-writing`, `recherche-interne` → `internal-search`, Mission 236). **Read by.** `tools/sb_installer_helper.py relink-renamed`, called by `tools/second-brain-update.sh` for every project of the registry after an update (verdict `UPDATED` or `UP-TO-DATE`), by `tools/project-bootstrap.sh adopt`, and by `sb doctor`, which names the command. A link under an old name that points nowhere is **replaced** by the link under the new name, and the project's journal gets one `APPLY:` line; a dead link with no known rename is named, never touched.

## `tools/second-brain-update.ps1`

**Role.** Windows entry point: finds Git's bash through `tools/resolve-bash-exe.ps1` and runs `tools/second-brain-update.sh` with the same arguments. **Called by.** [INSTALL.md §7](../../INSTALL.md), the `update` skill, `install.ps1`'s "already installed" message; test `tests/test-update-installed-vault.ps1`. **Syntax.** `second-brain-update.ps1 <Version> [-Vault <root>] [-Lang FR|EN|ES]` (`-Version` is mandatory, position 0). **Exit code and last line.** Those of the bash script. **Repository-root guard.** No, as above. **Example.**

```powershell
powershell -File <workspace>\second-brain\tools\second-brain-update.ps1 <version>
```

_Not executed by the documentation check._

## `tools/remove-profile-links.ps1`

**Role.** Lists, then removes on request, the links an installation made before Mission 173 left in your profile (`<profile>/.claude/skills`, `<profile>/.claude/agents/`, `<profile>/.agents/skills`) that point into `<workspace>/second-brain`, plus dead junctions whose target names a `second-brain` folder. It removes only the link itself, never its target, and never a link pointing elsewhere. **Called by.** Only `tests/test-remove-profile-links.ps1`; you run it yourself. **Syntax.** `remove-profile-links.ps1 -WorkspacePath <workspace> [-ProfileRoot <path>] [-Remove]`. `-WorkspacePath` is required and is the workspace, not the clone; `-ProfileRoot` defaults to your profile. Without `-Remove` it only lists; with `-Remove`, each removal is confirmed one by one (`-Confirm:$false` skips the prompts, `-WhatIf` shows without removing). **Exit codes and last line.** 0: `None found under <profile> (…). Nothing to do.`, or `Listing only (pass -Remove to actually remove, after reviewing the list above).`, or `Removed <n> of <m> link(s).` A missing folder throws `Workspace path not found: …` or `No second-brain clone found at <path> -- pass the WORKSPACE path …`. **Writes.** Nothing without `-Remove`. **Repository-root guard.** No: it acts on the profile. **Example.** Listing only:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <workspace>\second-brain\tools\remove-profile-links.ps1 -WorkspacePath "<workspace>"
```

## `tools/deploy-skills.ps1`

**Role.** Library dot-sourced by `install.ps1`: link primitives that never copy, overwrite or delete. `Publish-SkillLink` links a folder (a junction on Windows, a symbolic link elsewhere); `Publish-FileLink` links one file (a hard link on Windows). Both return `Created`, `AlreadyLinked` or `Conflict`. `Measure-MethodSkillsCodexBudget` sums the `description` lengths of `skills/` and `skills/external/` against a ceiling of 8000 characters. **Called by.** `install.ps1` dot-sources it; no tracked file calls its functions. Project links are made by `tools/project-bootstrap.sh` through the `link-project` subcommand of `tools/sb_installer_helper.py`, the Python twin of these primitives. **Writes.** Nothing on its own. **Repository-root guard.** No.

## `tools/sb_installer_helper.py`

**Role.** The JSON and text backend of `install.sh` and of several shell tools, run as `uv run --no-project <workspace>/second-brain/tools/sb_installer_helper.py <subcommand> …`. Each subcommand prints its result on stdout and exits 0, or exits non-zero on failure; with no or an unknown subcommand, the parser prints its usage and exits 2.

| Subcommand | Arguments | Does | Used by |
|---|---|---|---|
| `load-carnet` | `<path>` | Prints the notebook's answers and steps as shell assignments. | `install.sh` |
| `load-answers-file` | `<path>` | Same for an answers file; refuses one without `workspacePath`. | `install.sh` |
| `save-carnet` | `<path> [--language …] [--steps …] …` | Writes the notebook. | `install.sh` |
| `field` | `<file> <dotted-path>` | Prints one JSON value. | `tools/prerequisites.sh`, `tools/second-brain-update.sh` |
| `format-catalog` | `<file> <key> [args…]` | Prints a catalog message with `{0}`, `{1}` filled in. | `install.sh`, `tools/second-brain-update.sh`, `tools/project-bootstrap.sh`, `tools/install-vault-mcp.sh` |
| `slugify` | `<name>` | Prints the slug of an assistant name. | `install.sh` |
| `render-assistant` | `<clone_path> <name> [--language FR]` | Writes the assistant's three forms; prints the slug. | `install.sh`, `tools/second-brain-update.sh` |
| `move-assistant-trash` | `<clone_path> <old_slug>` | Moves a former name's forms to `_trash/`; prints `moved` or `none`. | `install.sh` |
| `relink-renamed` | `<clone_path> [<project_path>…] [--registry]` | For each project named (or, with `--registry`, every project of the registry), replaces a link under a skill's former name that points nowhere by the link under its new name, from `tools/skill-renames.tsv`; prints `RELINKED <project> <folder> <old> <new>`, `DEAD <path>` for a dead link with no known rename (left untouched), `CONFLICT <path>` when the new name is already taken, and `JOURNAL <project> <state folder>` for the caller's journal line. Never deletes without a replacement. | `tools/second-brain-update.sh`, `tools/project-bootstrap.sh adopt` |
| `link-project` | `<clone_path> <project_path>` | Links skills and assistant into a project; first writes, in each link folder, a `.gitignore` naming its links (Mission 231; a folder whose `.gitignore` is the project's own gets no link, `FOREIGN_GITIGNORE <path>`); prints statuses and `CONFLICT_COUNT <n>`. | `tools/project-bootstrap.sh` |
| `write-user-profile` | `<path> [--language …] …` | Writes `USER.md`. | `install.sh` |
| `merge-mcp-json`, `remove-mcp-json`, `mcp-server-args` | `<config> <name> …` | Adds, removes or reads one MCP server entry. | `tools/install-vault-mcp.sh` |
| `mcp-containment` | `<config> <name> <paths…>` | `PASS`/`FAIL` per path against the server's `--allow` folders. | `tools/check-mcp-containment.sh` |

**Repository-root guard.** No: it writes only the file or folder its caller names. **Example.** Read-only, prints the pinned pre-commit version:

```bash
uv run --no-project <workspace>/second-brain/tools/sb_installer_helper.py field <workspace>/second-brain/tools/prerequisites.lock.json preCommit.version
```

## `tools/environment-fingerprint.sh`

**Role.** Test library: `environment_fingerprint <path-persistence-file>` prints six lines, `PATH_FILE_HASH=` (SHA-256 of the file, or `none`), then `CLAUDE_SKILLS=`, `CODEX_SKILLS=`, `CODEX_AGENTS_SKILLS=`, `LOCAL_BIN=`, `UV_TOOLS=` (sorted, comma-joined listings of those profile folders), so a test can prove the real profile was not touched. **Called by.** `tests/test-install-e2e.sh`. **Writes.** Nothing.

## `tools/environment-fingerprint.ps1`

**Role.** Windows twin: `Get-EnvironmentFingerprint` returns `{ PathValue; PathHash; ClaudeSkills; ClaudeAgents; CodexSkills; CodexAgentsSkills; LocalBin }` (the user `Path` from `HKCU:\Environment`, hashed, and the listings of the profile folders). **Called by.** `tests/test-install-e2e.ps1`, `tests/test-prerequisites-e2e.ps1`, `tests/test-bootstrap-no-git.ps1`, `tests/test-install-no-profile-writes.ps1`, `tests/run-mechanical-acceptance.ps1`. **Writes.** Nothing.

## `tools/sb/sb.py`, `tools/sb/bin/sb`, `tools/sb/bin/sb.cmd`

**Role.** The `sb` command: one program, grammar `sb <verb> [arguments]`, 22 verbs in five groups, each calling an existing tool, skill or guide ([rule on the sb command surface](../../rules/RULES-2026-09-26-200933-sb-command-surface.md); every verb in [Commands](./commands.md)). `bin/sb` launches it from Git Bash, macOS and Linux, `bin/sb.cmd` from PowerShell and `cmd`, both through `uv run --no-project` (Python 3.8 or later when `uv` is missing). **Reads.** `tools/sb/verbs.json` (the catalogue; a verb's `formPlaces` names a form that runs in another place than the verb's own — `sb pilot-prompt --accueil`, anywhere in the workspace, Mission 241), the `sb.*` keys of `i18n/catalog.{fr,en,es}.json` (every text; the language comes from `--lang`, `SB_LANG`, `USER.local.yaml`, `USER.md`, then the system), `tools/sb/native-commands.tsv` (the native commands the names are checked against, read by the tests), the workspace marker, birth certificates, `projects/PROJECT-REGISTRY.md`, the state sheets. **Writes.** Nothing of its own, except: `sb install --path` and `sb uninstall --path` (one entry of the user `PATH`: the `Path` value of `HKCU\Environment` on Windows, a marked block of `~/.profile` elsewhere — the same primitive as the installers); `sb install` (the four steps, each only if needed: that PATH entry; `claude plugin marketplace add <Vault>/skills/claude-plugins`; `claude plugin install sb@second-brain`, after `claude plugin uninstall sb@second-brain` when Claude Code's cached copy differs from the Vault's plugin; `tools/install-vault-mcp.sh`; `--path`, `--plugin` and `--mcp` run one step, `--run` resumes the installation), so Claude Code's plugin settings and the tools' MCP configurations; `sb clean --purge-temp [--yes]` (empties the declared temporary folder after a confirmation, the one deletion `sb` makes, on the Owner's own command; never `_trash` nor `_archive`); `sb generate` (maintainer, from the Vault: `docs/reference/commands.md`, `docs/COMMANDS-CARD.md` and the plugin under `skills/claude-plugins/`; `sb generate --check` refuses a drifted file). The verbs that write (`new`, `adopt`, `pilot-prompt --regen`, `push`, `update`, `publish`) do it through the tool they call. **Exit codes.** 0 done, 1 the tool refused or failed, 2 usage, 3 wrong place, 4 not allowed here. **Called by.** The participant; the plugin `sb` of Claude Code and the router skill `skills/sb/` (Codex); `install.ps1` and `install.sh` put `tools/sb/bin` on the `PATH`. **Reads for `sb doctor`.** Claude Code's `known_marketplaces.json` and `installed_plugins.json` in its plugins folder: the plugin is `marketplace not added`, `marketplace added, plugin not installed`, `installed`, or `installed, but older than the Vault's plugin` when a skill of the cached copy differs from `skills/claude-plugins/sb/skills/`. Under Windows, whether a `bash` outside the Windows folder is on the `PATH` (a `WARN` naming `& "<Git's bash.exe>"`, never blocking); the Codex skill budget and its margin under 8000 (a `WARN` below 500, Mission 241). How to use it: [Use the sb command and its plugin](../how-to/use-the-sb-command-and-plugin.md). **Repository-root guard.** Its own: every verb checks its place first and refuses elsewhere, naming where it runs.

## Liens

- `source` — [Bootstrap, macOS/Linux](../../bootstrap.sh)
- `source` — [Bootstrap, Windows](../../bootstrap.ps1)
- `source` — [Installer, macOS/Linux](../../install.sh)
- `source` — [Installer, Windows](../../install.ps1)
- `source` — [Prerequisites, shell](../../tools/prerequisites.sh)
- `source` — [Prerequisites, PowerShell](../../tools/prerequisites.ps1)
- `source` — [Prerequisites lock file](../../tools/prerequisites.lock.json)
- `source` — [Questionnaire library](../../tools/questionnaire.ps1)
- `source` — [Update tool](../../tools/second-brain-update.sh)
- `source` — [Update tool, Windows wrapper](../../tools/second-brain-update.ps1)
- `source` — [Profile link cleaner](../../tools/remove-profile-links.ps1)
- `source` — [Link primitives](../../tools/deploy-skills.ps1)
- `source` — [Installer helper](../../tools/sb_installer_helper.py)
- `source` — [Environment fingerprint, shell](../../tools/environment-fingerprint.sh)
- `source` — [Environment fingerprint, PowerShell](../../tools/environment-fingerprint.ps1)
- `source` — [Bash resolver](../../tools/resolve-bash-exe.ps1)
- `source` — [Assistant generator](../../tools/generate-assistant.ps1)
- `source` — [Release version setter](../../tools/set-release-version.sh)
- `source` — [Project bootstrap](../../tools/project-bootstrap.sh)
- `source` — [Index builder](../../tools/build-indexes.sh)
- `source` — [Session preflight](../../tools/session-preflight.sh)
- `source` — [MCP server installer](../../tools/install-vault-mcp.sh)
- `source` — [MCP containment check](../../tools/check-mcp-containment.sh)
- `source` — [English message catalog](../../i18n/catalog.en.json)
- `source` — [Sample answers file](../../tests/fixtures/install-answers.sample.json)
- `source` — [Bootstrap clone test](../../tests/test-bootstrap-stale-temp-clone.sh)
- `source` — [Bootstrap keyboard test](../../tests/test-bootstrap-keyboard.sh)
- `source` — [Bootstrap without Git test](../../tests/test-bootstrap-no-git.ps1)
- `source` — [Bootstrap clone test, PowerShell](../../tests/test-bootstrap-stale-temp-clone.ps1)
- `source` — [Standard-account install test](../../tests/test-install-standard-user.ps1)
- `source` — [No profile writes test](../../tests/test-install-no-profile-writes.ps1)
- `source` — [Mechanical acceptance runner](../../tests/run-mechanical-acceptance.ps1)
- `source` — [CI setup action](../../.github/actions/setup-test-env/action.yml)
- `source` — [End-to-end install test, shell](../../tests/test-install-e2e.sh)
- `source` — [End-to-end install test, PowerShell](../../tests/test-install-e2e.ps1)
- `source` — [Prerequisites test](../../tests/test-prerequisites-e2e.ps1)
- `source` — [Update test, shell](../../tests/test-update-installed-vault.sh)
- `source` — [Update test, PowerShell](../../tests/test-update-installed-vault.ps1)
- `source` — [Profile link cleaner test](../../tests/test-remove-profile-links.ps1)
- `source` — [CI workflow](../../.github/workflows/ci.yml)
- `source` — [Install guide](../../INSTALL.md)
- `source` — [first-install skill](../../skills/first-install/SKILL.md)
- `source` — [update skill](../../skills/update/SKILL.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `see also` — [Install tutorial](../tutorials/install.md)
- `see also` — [Update](../how-to/update.md)
- `see also` — [Assistant and MCP tools](./tools-assistant-and-mcp.md)
- `see also` — [Project tools](./tools-projects.md)
- `see also` — [Commands](./commands.md)
- `source` — [Rule — The sb command surface](../../rules/RULES-2026-09-26-200933-sb-command-surface.md)
