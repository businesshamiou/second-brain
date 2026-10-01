---
type: how-to
title: "Troubleshoot"
description: "Match a refusal of the installer, the bootstrap, the update, the MCP server installer, the project bootstrap, the repository-root guard or the verified push to its cause, and fix it with commands in absolute-path form."
status: active
---

# TROUBLESHOOT

This page is the index of the known refusals of Second Brain outside the commit guardians. Each entry gives the message (copied from the code, placeholders in angle brackets), its cause, and what to do. A refusal is a stop: read the message, fix the cause, run the same command again. Never look for another way to reach the refused place.

## Before you start

- `<workspace>` is the absolute path of your workspace (for example `C:/Users/you/Workspaces` or `/Users/you/Workspaces`). The installed Vault is `<workspace>/second-brain`; a project is `<workspace>/<project>`. Every command below names these paths in full: never `.`, never a path that depends on the folder you are in.
- On Windows, run the `bash` commands in Git Bash (see [Other known problems](#other-known-problems)).
- **A commit refused by the guardians** (the pre-commit hook's table of PASS, FAIL and SKIPPED) is not covered here: see [React to a guardian refusal](react-to-a-guardian-refusal.md).

## Installer

The installer (`install.sh` on macOS and Linux, `install.ps1` on Windows) ends on one line. On a stop, that line is `Stopped at step <step>: <cause> What to do: <remedy>` and the exit code is 1. The step is one of prerequisites, workspace, clone, guardians, marker, assistant, first project, profile. The logbook `<workspace>/second-brain/.install/state.json` keeps the steps already done, so running the installation line again resumes at the missing step.

- **`Stopped at step <step>: <cause> What to do: Review the error above; once it is fixed, run the installer line again to resume.`**
  Cause: the named step failed; the cause says what (for example `git clone failed (source: <source>, dest: <clone>)`, or `failed to commit (<message>) in <clone> (guardians refused)`).
  What to do: fix what the cause names, then run the installation line from [INSTALL.md](../../INSTALL.md) again. For a guardian refusal, see [React to a guardian refusal](react-to-a-guardian-refusal.md).
- **`Stopped at step <step>: Network unreachable while downloading a required tool. What to do: Check your internet connection, then run the installer line again.`** (Windows only)
  Cause: a download failed while the prerequisites were being installed.
  What to do: restore the connection, then run the installation line again.
- **`Stopped at step workspace: The workspace folder <path> is <n> characters long; on Windows it can be at most <max>, ...`** (Windows only)
  Cause: without long paths enabled, Python on Windows cannot read a path longer than 259 characters. The installer computes the maximum at each run as 259 − 1 − 13 − the length of the longest tracked Markdown file outside `skills-warehouse/`. On this tree that file is 127 characters long, so the maximum is 118. Nothing is written in the workspace. macOS and Linux have no such limit.
  What to do: choose a shorter folder (the message proposes the default one), then run the installation line again.
- **`Second Brain is already installed in <clone>. To receive <version> without reinstalling, run: <command>`**
  Cause: the installation line found an existing clone that does not contain the version it brings. It installs nothing over it and exits with code 1.
  What to do: run the exact command printed. It is the update tool of the new version, with `--vault <clone>` (on Windows, `tools/second-brain-update.ps1` with `-Vault <clone>`; see [Update](#update)).
- **`Stopped at step prerequisites: Source is not a git repository: <source>`**
  Cause: the installer was pointed at a folder that is not a Git working tree, for example a folder extracted from an archive.
  What to do: use the published installation line from [INSTALL.md](../../INSTALL.md), which clones a real repository.

The workspace question is asked again, with one of these messages, until the answer is valid. Pressing Enter accepts the proposed default.

| Message | Cause | What to do |
| --- | --- | --- |
| `'<answer>' is not a workspace path (yes/no answers and a blank line are not accepted here). Enter an absolute path, for example <default>.` | You typed `oui`, `non`, `y` or `n` (any case). | Type an absolute path, or press Enter. |
| `'<answer>' is not an absolute path. Enter an absolute path, for example <default>.` | A relative path would depend on the folder the installer runs from. | Type the full path. |
| `'<answer>' is inside the source repository being installed from and cannot be used as the workspace. Choose a path outside it, for example <default>.` | Second Brain would be cloned into its own source. | Choose a path outside it. |

- **`gum is not available: the questionnaire is shown in plain mode.`**
  Cause: gum is **optional** — it only draws the questions. It is set up by winget (Windows) or Homebrew (macOS); a Windows Sandbox, or a fresh Windows without the Microsoft Store, has no winget. gum is not among the pinned prerequisites (Git, uv, pre-commit).
  What to do: nothing. The same questions appear as plain text and the files written are the same.
- **The last screen names no Executor (`Executor (agent with a shell)` … `none`).**
  Cause: Second Brain installs no AI agent; neither Claude Code nor Codex is on this machine.
  What to do: in the terminal, the official line `sb doctor` names (Claude Code: `irm https://claude.ai/install.ps1 | iex` in PowerShell, `curl -fsSL https://claude.ai/install.sh | bash` elsewhere; Codex: see [Your first installation](../tutorials/install.md), step 1), then `sb install`.

## Bootstrap

The published line first runs `bootstrap.sh` or `bootstrap.ps1`. It brings a temporary clone (the folder second-brain-install in the declared temporary folder, `<temp>/second-brain`) to the requested version, then runs the installer from it. It never deletes that clone and never forces: on a mismatch it stops with `Second Brain bootstrap stopped: <reason>` and exit code 1. On Windows, the reasons that follow a failed Git command also carry ` (exit <code>)`.

| Reason (after `Second Brain bootstrap stopped: `) | Cause | What to do |
| --- | --- | --- |
| `<target> is a clone of '<origin>', not of '<repo-url>'; move <target> aside and run the line again.` | A clone of another repository is in the temporary folder. | Rename that folder (for example add `-old` to its name), then run the line again. |
| `git fetch of <repo-url> failed in <target>; move <target> aside and run the line again.` | The existing clone could not be updated (network, or a damaged clone). | Check the network; if it persists, rename the folder and run the line again. |
| `<ref> does not exist in <repo-url>; nothing was installed.` | The requested version is not published. | Check the version in the line you copied. |
| `<ref> could not be checked out in <target>; move <target> aside and run the line again.` or `<target> is at <commit>, not at <ref> (<commit>); move <target> aside and run the line again.` | The existing clone could not be brought to the version. | Rename the folder, then run the line again. |
| `<target> exists but is not a Git repository; move it aside and run the line again.` | Something else occupies the folder. | Rename it, then run the line again. |
| `git clone of <repo-url> failed.` or `<ref> could not be checked out from <repo-url>.` | The first clone failed. | Check the network, then run the line again. |
| `Git comes with Apple's Command Line Tools: finish the installation Apple just offered, then run the same line again.` | macOS without Git: the bootstrap asked Apple's dialog to install it. | Finish that installation, then run the line again. |
| `the downloaded Git archive does not match its pinned SHA-256 (expected <sha>, got <sha>).` | Linux or Windows without Git: the downloaded Git is not the pinned one. | Run the line again; if it repeats, do not go further and ask for help. |

## Update

`sb update <version>` (that is `bash <workspace>/second-brain/tools/second-brain-update.sh <version> --vault <workspace>/second-brain`) ends on one line: `VERDICT: UPDATED`, `VERDICT: UP-TO-DATE` or `VERDICT: REFUSED` (exit code 1). Every refusal says that nothing was changed; a merge already started is aborted first.

| Message (start) | Cause | What to do |
| --- | --- | --- |
| `<folder> is not a Git clone: it cannot be updated.` | `--vault` names a folder that is not a clone. | Name the installed Vault, `<workspace>/second-brain`. |
| `This Vault has changes that are not committed (<files>): commit them first, then run the update again.` | Uncommitted work in the Vault. | Commit it (`git -C <workspace>/second-brain add <file>`, then `git -C <workspace>/second-brain commit -m "<message>"`), then run the update again. |
| `This Vault has no generated identity (<file>): it is not an installed Second Brain.` or `This Vault has no origin remote: there is nowhere to fetch a version from.` | The folder is not an installed Second Brain. | Run the update on the installed Vault. |
| `This Vault's origin is the installer's temporary folder (<origin>): it was installed before v0.1.4 and cannot receive a version.` | Installation older than v0.1.4. | Reinstall with the published line ([INSTALL.md](../../INSTALL.md)), in a new folder. |
| `Fetching from <origin> failed (network, or the remote moved).` or `The version <version> does not exist at <origin>.` | Network, or a version that is not a published tag. | Check the network and the version name. |
| `The update to <version> conflicts with local changes in: <files>. The merge was aborted, ...` | A file of the method was edited locally (conflicts on `index.md` files are resolved automatically). | Keep your own work outside the Vault's corpus files, or ask for help. |
| `The update would change this Vault's identity (<id> -> <id>).` | The merge would replace this Vault's `vault_id`. | Ask for help. |
| `The assistant could not be regenerated with version <version>.` or `The indexes could not be regenerated after merging <version>.` | A generation step of the version failed. | Ask for help. |
| `The Vault's guardians refused the update to <version> (output above).` | The merge commit was refused by a guardian. | Read the guardian output shown; see [React to a guardian refusal](react-to-a-guardian-refusal.md). |

After a success, when the server's name changed, when the merge changed `tools/vault-mcp.py` or `tools/install-vault-mcp.sh`, or when that installer does not yet name the server by `vid_server_name`, `The Vault's MCP server may have changed: run bash <path> <workspace> again, then restart the Claude app.` asks you to rerun the MCP installation below. See also [Update](update.md).

## MCP server

`sb install --mcp` runs the step below for you ([Use the sb command and its plugin](use-the-sb-command-and-plugin.md)). This command declares this Vault's server in Claude Code, Codex and the Claude desktop app, with `<workspace>` as the only allowed folder:

```
bash <workspace>/second-brain/tools/install-vault-mcp.sh <workspace>
```

_Not executed by the documentation check._ In PowerShell, where `bash` is unknown, `sb install --mcp` runs the same script.

| Message | Cause | What to do |
| --- | --- | --- |
| The Pilot answers `NOT-READY` about its channel, or the Claude app shows « No server added » (Settings → Developer) although `sb doctor` says `declared` | The Claude app loads its servers only at start-up, and closing its window does not stop it (Windows: it stays in the background). While it runs it may also rewrite `claude_desktop_config.json` from memory and drop the `mcpServers` section written meanwhile (measured 2026-09-30). | End it — **in Windows:** Settings → Apps → Installed apps → Claude → Advanced options → Terminate (**macOS:** Cmd+Q) — then reopen it. If `sb doctor` now says the server is missing, run `sb install --mcp` with the app ended; `sb install` asks to close it for you (`(Y/n)`), and reads the file back after writing. |
| `sb doctor`: `MCP server name … tool names of 72 characters, over 64` | A workspace label longer than 14 characters, from an installation before Mission 244 (`second-brain-workspace`). | `sb install --mcp --label second-brain` (or another label of 14 characters at most); the label is committed in `VAULT-IDENTITY.md`, then regenerate each project's prompt with `sb pilot-prompt <folder> --regen`. |
| `REFUS : espace de travail introuvable : <workspace>` (after the usage line) | The argument is missing or is not a folder. | Pass the absolute path of the workspace. |
| `REFUS : uv introuvable : le serveur MCP du Vault se lance par uv.` | `uv` is not on the PATH. | Install `uv` (a prerequisite of the installer), then rerun. |
| `Python not found through uv: the server cannot start, nothing is configured.` | `uv` cannot start Python. | Fix `uv`, then rerun. |
| `This Vault has no generated identity (<file>): its server name cannot be derived, nothing is configured. Run bash tools/vault-identity.sh ensure (under Windows, in PowerShell: & "C:\Program Files\Git\bin\bash.exe" tools/vault-identity.sh ensure), then run this line again.` | `VAULT-IDENTITY.md` carries no generated identity. | Run `bash <workspace>/second-brain/tools/vault-identity.sh ensure <workspace>/second-brain`, then rerun. |
| `<tool>: the server <name> already points to another Vault (<path>, identity <id>); this Vault is <id>. Refused: ...` then `Two Vaults cannot carry the same server name. Proposed name for this Vault: <name>; run again with --label <label> to accept it. Nothing was written.` | Two Vaults would announce one server name. | Rerun with `--label <label>` as proposed. |
| `REFUS : libelle vide apres normalisation : <label>` | The `--label` value normalises to nothing. | Choose another label. |
| `REFUSED: retirement refused: <key> is a Vault's server, --retire never retires a Vault server. Nothing is changed.` | `--retire` named `second-brain-vault` or a key starting with `second-brain-vault-`. | Retire only generic servers. |
| `<tool>: the tool refused the configuration -- server not added.` | That tool rejected the entry; the other tools are still processed. | Rerun; if it repeats, ask for help. |

When a tool was found, the run ends with `Remaining step: restart each tool detected above (the Claude app, Claude Code, Codex, Gemini CLI…) so it loads the server.`; when none was, with `No tool detected (Claude app, Claude Code, Codex, Gemini CLI, Cursor, Windsurf, Cline, LM Studio): nothing to configure.` The server runs on your machine: a browser-only tool (ChatGPT, Gemini on the web) cannot start it ([Pilot hosts and role mixing](pilot-hosts-and-role-mixing.md)). To check a configuration, `bash <workspace>/second-brain/tools/check-mcp-containment.sh <configuration> <workspace>/<project>` prints one PASS or FAIL line per path, then `VERDICT: PASS` or `VERDICT: FAIL`.

## Project bootstrap

`tools/project-bootstrap.sh` (create, adopt, order) refuses on the error output, with exit code 1. The main messages:

| Message | Cause | What to do |
| --- | --- | --- |
| `REFUS : chemin cible non absolu : <target>` | Relative target path. | Write `<workspace>/<project>` in full. |
| `REFUS : chemin cible a l'interieur du depot Vault (<vault>) : <target>` | The project would sit inside the Vault. | Choose a folder next to it, in the workspace. |
| `REPO-ROOT-REFUSED: ... is a workspace root (...)` | The target is the workspace itself. | Name the project's own folder, `<workspace>/<project>`. |
| `REFUS : la cible existe deja : <target>` | `create` on an existing folder. | Use `adopt` (see [Adopt a project](adopt-a-project.md)). |
| `REFUS : la cible a adopter n'existe pas (mode create) : <target>` | `adopt` on a missing folder. | Use `create` (see [Create a project](create-a-project.md)). |
| `REFUS : chemin deja inscrit au registre : <path>` or `REFUS : fiche projet deja existante pour cet identifiant : <file>` | `create` on a path already registered, or a project sheet already exists for the identifier (today's date and a code taken from the display name). | Do not create it again; open it. For the sheet, choose another display name. |
| `REFUS : marqueur VAULT-ROOT.md introuvable en remontant depuis <folder>` | The target is outside an adopted workspace. | Create the project under `<workspace>`. |
| `BASELINE-DIRTY-TREE : <n> porcelain line(s) in <target>: ...` | `adopt` on a Git tree with uncommitted changes. | Commit or restore first, or have the order carry `Arbre sale : accepté — <raison>`. |
| `REFUS : ordre d'initiation sans autorisation Owner datée (AAAA-MM-JJ)`, `REFUS : l'ordre nomme le Vault <id>, ce Vault est <id>`, or another `REFUS : ordre d'initiation ...` | The initiation order is incomplete or names another Vault. | Fix the order file, then rerun with `--order <order-file>`. |

`bash <workspace>/second-brain/tools/project-bootstrap.sh order <workspace>/<project>` (in PowerShell, `& "C:\Program Files\Git\bin\bash.exe"` in place of `bash`) writes nothing: it prints `This folder is not adopted and no initiation order was received: nothing is written. ...` followed by the order to fill in. The Pilot fills it in, the Owner dates it, and it is handed to the Executor.

## Repository-root guard

`tools/repo_root_guard.py` runs before any write in `tools/build-indexes.sh`, `tools/append-journal.sh`, `tools/build-state.sh`, `tools/build-digest.sh`, `tools/set-release-version.sh`, `tools/vault-identity.sh` (`ensure`), `tools/propose-link-repairs.sh` and `tools/project-bootstrap.sh` (in its `--new-project` mode for `create` and `adopt`, in its default mode for `prompt`). It has no switch and no environment variable that turns it off. Its refusal is one line on the error output, and nothing is written:

- `REPO-ROOT-REFUSED: <path> (<absolute>) is not inside a repository: <folder> is a workspace root (it carries VAULT-ROOT.md). Expected ..., for example <folder>/<repository>. Nothing written.` The reason can also be `it holds <n> Git repositories without being one`.
- `REPO-ROOT-REFUSED: <path> (<absolute>) is in no Git repository and carries no birth certificate; expected .... Nothing written.`
- `REPO-ROOT-REFUSED: <path> (<absolute>) is not a folder; expected .... Nothing written.`

Cause: the target (often `.`, typed from the workspace root) is not a repository, nor a folder inside one, nor a project with a birth certificate. What to do: rewrite the command with the absolute path of the right repository, for example `bash <workspace>/second-brain/tools/build-indexes.sh <workspace>/<project>`. See [Why absolute paths](../explanation/why-absolute-paths.md).

## Verified push

`bash <workspace>/second-brain/tools/verified-push.sh <workspace>/<repository> <from>..<to> [<remote>] [--url <url>]` (or `sb push`, which calls it; in PowerShell, `& "C:\Program Files\Git\bin\bash.exe"` in place of `bash`) refuses, before anything is pushed, with `VERIFIED-PUSH-REFUSED: <reason>. Nothing pushed.` and exit code 1. `--dry-run` runs every check and pushes nothing.

| Reason | What to do |
| --- | --- |
| `repository path is not absolute: '<path>' ...`, `<path> is in no Git repository ...` or `<path> is not the root of its repository (<root>); a sub-folder is never pushed from` | Name the repository's root in full. |
| `range is not <from>..<to>: '<range>'`, `<from> is not a commit of <path>: <from>` or `<to> is not a commit of <path>: <to>` | Give an exact range of two commits. |
| `HEAD is detached in <path>: a push names a branch` or `HEAD (<commit>) is not <to> (<to>)` | Push from the branch whose last commit is `<to>`. |
| `no remote named '<remote>' in <path>` or `remote '<remote>' pushes to <url>, not to the declared <url>` | Push to the declared remote: `vault_origin` for a Vault, `--url <url>` for a project. |
| `<path> declares no remote (no vault_origin in VAULT-IDENTITY.md): pass --url <expected url>` | A project declares no remote: pass `--url`. |
| `cannot read refs/heads/<branch> on '<remote>' (network, or no such branch)` or `remote head of <branch> is <commit>, not <from> (<from>)` | Read the remote again; someone else pushed, or the range is stale. |
| `<to> (<to>) does not descend from <from> (<from>)` | The push would not be a fast-forward; ask the Owner. |
| `--force is never accepted`, `unknown option: <option>` or `too many arguments: <argument>` | Remove the option. |

`VERIFIED-PUSH-MISMATCH: the remote reads <commit> after the push, not <to>` means the push ran but the remote does not read `<to>`: read it with `git -C <workspace>/<repository> ls-remote <remote> refs/heads/<branch>` before anything else. See [Delegate and push](delegate-and-push.md).

## The sb command and its plugin

The authoritative page is [Use the sb command and its plugin](use-the-sb-command-and-plugin.md), whose "Known errors" table covers each case; in short:

| Message or symptom | Cause | What to do |
| --- | --- | --- |
| `sb` is not recognised as a command | `sb` is not on the PATH, or the terminal predates it. | Open a new terminal; else `<workspace>/second-brain/tools/sb/bin/sb install --path`. |
| `REFUSED: sb <verb> runs <place>. You are <where>.` (exit 3) | Wrong folder for that verb. | Go where the second line says. Outside any workspace (a PowerShell opens in `C:\Windows\system32`) `sb` works in its own Vault's workspace and says so; only a verb that needs a project or a repository still refuses there. |
| `/sb:<verb>` missing, or older than `sb help <verb>` | The plugin is not installed, or Claude Code's cached copy is behind the Vault's. | `sb doctor`, then `sb install`, then `/reload-plugins`. |
| A Pilot answers that a verb needs a shell | The verb is not marked « Pilot: yes ». | Type it in an Executor window. |

`sb doctor "<the whole refusal line>"` looks a refusal up in the guides for you.

## Other known problems

- **`bash` answers "command not found" in PowerShell.** `bash` is not on the PATH of plain PowerShell; `sb doctor` says so on its `bash` line (a `WARN`, never blocking). First look for the `sb` verb that carries the gesture — `sb pilot-prompt --accueil` for the welcome Pilot's block, `sb new --order`, `sb adopt`, `sb update`, `sb install --mcp`, `sb push` ([Commands](../reference/commands.md)). Otherwise open Git Bash from the Start menu, or call Git's Bash by its full path:

  ```
  & "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/install-vault-mcp.sh <workspace>
  ```

  _Not executed by the documentation check._
- **`python` answers "Python was not found; run without arguments to install from the Microsoft Store".** On Windows, `python` and `python3` are, by default, shortcuts ("app execution aliases") to the Microsoft Store, not an interpreter. The Vault's tools never call `python`: they run their Python files through `uv run --no-project`, which uses the interpreter `uv` installed. Run a helper by hand the same way:

  ```bash
  uv run --no-project <workspace>/second-brain/tools/repo_root_guard.py <folder>
  ```

  _Not executed by the documentation check._ If you want `python` itself, turn the two aliases off in Windows Settings (Apps, Advanced app settings, App execution aliases) and install Python; the Vault does not need it (Mission 231).
- **`fatal: Unable to create '<repository>/.git/index.lock': File exists` while another window is working.** A plain `git status` refreshes the index and takes its lock for a moment; two windows reading and committing the same repository then collide. For a read from a second window (an Executor measuring, a Pilot's check), turn those optional locks off for that command:

  ```bash
  GIT_OPTIONAL_LOCKS=0 git -C <repository> status --porcelain
  ```

  _Not executed by the documentation check._ It reads without writing anything under `.git/`. Never delete an `index.lock` while a Git command may still be running (Mission 231).
- **`git add` fails with `Permission denied` on a file that exists.** On Windows, a file written by another account or by an agent's sandbox (Codex's, measured 2026-09-25) can carry an access control list that your account cannot read. Before staging, `tools/check-readable.sh` reads every file about to be staged and names the unreadable ones with their remedy; `install.sh` and `install.ps1` run it before their own staging:

  ```bash
  bash <workspace>/second-brain/tools/check-readable.sh <repository> [<path>...]
  ```

  In PowerShell, where `bash` is unknown: `& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/check-readable.sh <repository> [<path>...]`.

  _Not executed by the documentation check._ It prints `UNREADABLE <path>` for each such file, then the two commands to run for it, in a terminal of your own account: `takeown /f "<file>"` (take ownership back), then `icacls "<file>" /reset` (the inherited permissions again); on macOS or Linux, `chmod u+r <file>`. Its last line is `READABLE <n>` (exit 0) or `REFUSED` (exit 1); nothing is staged (Mission 231).
- **Claude Code asks for an approval the first time you open a project.** The project bootstrap prints `Note: the first time you open this project in Claude Code, it will ask for a one-time approval (an external import) ...`: the assistant and skills links point outside the project's folder. Answer yes; the links only give read access to `second-brain`.

## Scripts used

- `install.sh`, `install.ps1`, `bootstrap.sh`, `bootstrap.ps1`, `tools/second-brain-update.sh`: [Install and update tools](../reference/tools-install-and-update.md)
- `tools/install-vault-mcp.sh`, `tools/check-mcp-containment.sh`: [Assistant and MCP tools](../reference/tools-assistant-and-mcp.md)
- `tools/project-bootstrap.sh`, `tools/vault-identity.sh`: [Project tools](../reference/tools-projects.md)
- `tools/repo_root_guard.py`: [Internal helpers](../reference/tools-internal-helpers.md)
- `tools/verified-push.sh`: [Publication and push tools](../reference/tools-publication-and-push.md)
- `tools/sb/sb.py`: [Install and update tools](../reference/tools-install-and-update.md)

## Liens

- `source` — [install.sh](../../install.sh)
- `source` — [install.ps1](../../install.ps1)
- `source` — [questionnaire.ps1](../../tools/questionnaire.ps1)
- `source` — [bootstrap.sh](../../bootstrap.sh)
- `source` — [bootstrap.ps1](../../bootstrap.ps1)
- `source` — [English catalog](../../i18n/catalog.en.json)
- `source` — [second-brain-update.sh](../../tools/second-brain-update.sh)
- `source` — [second-brain-update.ps1](../../tools/second-brain-update.ps1)
- `source` — [install-vault-mcp.sh](../../tools/install-vault-mcp.sh)
- `source` — [check-mcp-containment.sh](../../tools/check-mcp-containment.sh)
- `source` — [vault-identity.sh](../../tools/vault-identity.sh)
- `source` — [project-bootstrap.sh](../../tools/project-bootstrap.sh)
- `source` — [repo_root_guard.py](../../tools/repo_root_guard.py)
- `source` — [build-indexes.sh](../../tools/build-indexes.sh)
- `source` — [append-journal.sh](../../tools/append-journal.sh)
- `source` — [build-state.sh](../../tools/build-state.sh)
- `source` — [build-digest.sh](../../tools/build-digest.sh)
- `source` — [set-release-version.sh](../../tools/set-release-version.sh)
- `source` — [propose-link-repairs.sh](../../tools/propose-link-repairs.sh)
- `source` — [VAULT-IDENTITY.md](../../VAULT-IDENTITY.md)
- `source` — [verified-push.sh](../../tools/verified-push.sh)
- `source` — [check-readable.sh](../../tools/check-readable.sh)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [README, frequently asked questions](../../README.md)
- `source` — [Installation guide](../../INSTALL.md)
- `see also` — [React to a guardian refusal](react-to-a-guardian-refusal.md)
- `see also` — [Update](update.md)
- `see also` — [Create a project](create-a-project.md)
- `see also` — [Adopt a project](adopt-a-project.md)
- `see also` — [Delegate and push](delegate-and-push.md)
- `see also` — [Why absolute paths](../explanation/why-absolute-paths.md)
- `see also` — [Install and update tools](../reference/tools-install-and-update.md)
- `see also` — [Assistant and MCP tools](../reference/tools-assistant-and-mcp.md)
- `see also` — [Project tools](../reference/tools-projects.md)
- `see also` — [Internal helpers](../reference/tools-internal-helpers.md)
- `see also` — [Publication and push tools](../reference/tools-publication-and-push.md)
