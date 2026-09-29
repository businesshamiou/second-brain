---
type: how-to
title: "Update"
description: "Bring an installed Second Brain to a new published version without reinstalling, resume an interrupted installation, or change your profile answers."
status: active
---

# UPDATE

This page tells you how to bring Second Brain up to a new version, how to resume an interrupted installation, and how to change the answers you gave the installer. The verb is `sb update <version>`, in a terminal (`/sb:update` in Claude Code, `$sb update` in Codex); it runs the update tool described below ([Use the sb command and its plugin](use-the-sb-command-and-plugin.md)).

To remove Second Brain from your machine, see [Uninstall](uninstall.md).

## Before you start

- **Your installation is at v0.1.8 or later.** The update tool exists from v0.1.8 on. Earlier installations follow [From v0.1.7 or earlier](#from-v017-or-earlier) below ([INSTALL.md §7](../../INSTALL.md)).
- **Know the version you want.** `<version>` is the tag of a published version, as named in [RELEASE-NOTES.md](../../RELEASE-NOTES.md) (for example `v0.1.9`). Most entries there, including every recent one, also say "What remains to be done on your side" for that version.
- **Nothing uncommitted in your Vault.** The tool refuses otherwise, and that includes new files not yet added to Git.
- **Git and `uv`**, both set up by the installer ([INSTALL.md §3](../../INSTALL.md)): the tool uses `uv` to print its messages.
- Below, `<workspace>` is the absolute path of your workspace (for example C:/Users/you/Workspaces); your installed Vault is `<workspace>/second-brain`.

## Steps

### 1. Check that the Vault is clean

```bash
git -C <workspace>/second-brain status --porcelain
```

This must print nothing. If it lists files, commit them or set them aside first.

### 2. Run the update

In any terminal, with `sb` on your PATH:

```bash
sb update <version>
```

_Not executed by the documentation check._

The same without `sb`, in Git Bash or a macOS/Linux terminal:

```bash
bash <workspace>/second-brain/tools/second-brain-update.sh <version>
```

_Not executed by the documentation check._ In PowerShell, where `bash` is unknown, type `sb update <version>`: it calls this script.

On Windows, in PowerShell:

```powershell
powershell -File <workspace>\second-brain\tools\second-brain-update.ps1 <version>
```

_Not executed by the documentation check._

The full syntax, from the code, is `second-brain-update.sh <version> [--vault <root>] [--lang FR|EN|ES]`. `--vault` points at another installed clone; `--lang` picks the message language (otherwise the language recorded in the installer's logbook, else English). The Windows script `tools/second-brain-update.ps1` is only a wrapper: it finds Git's bash and runs the same bash script. It takes the same options in PowerShell form, `-Vault <root>` and `-Lang <language>`, and passes them on as `--vault` and `--lang` ([second-brain-update.ps1](../../tools/second-brain-update.ps1)).

The version is **merged** over your own commits: `USER.md`, `VAULT-IDENTITY.md`, your project sheets and registry, and your history stay as they are; the indexes are regenerated ([INSTALL.md §7](../../INSTALL.md)). The tool that starts is the one already in your Vault: since the merge rewrites it, it first copies itself to a temporary folder and runs from there. From v0.1.15 on, that tool then hands over to the tool of the version you receive when the two differ (step 3b below): the version is merged by its own rules. **This does not reach back.** An installation at v0.1.14 or earlier runs its old tool, which does not hand over: for the update *to* v0.1.15, run the new version's tool yourself with `--vault` (see [From an installation whose tool is older than the version](#from-an-installation-whose-tool-is-older-than-the-version)). The updates after that one hand over by themselves.

What the tool does, in order ([second-brain-update.sh](../../tools/second-brain-update.sh)):

1. **Refuses before touching anything** if the folder is not a Git clone, has uncommitted changes, has no generated identity, has no `origin` remote, or its `origin` is the installer's temporary folder (an installation older than v0.1.4).
2. Fetches the tags from `origin`; the version must be a published tag there.
3. If that version is already in your history, it says so and stops. Exception: if your assistant's forms are older than the version (it was merged by an update tool older than v0.1.15), it regenerates them as in step 6, in one commit of their own through the guardians, and says so.
   - 3b. If the version's `tools/second-brain-update.sh` differs from the tool running, it says so (`SB-UPDATE-HANDOVER: <version>`), extracts the version's tools to a temporary folder and runs **that** tool on your Vault, once; the steps below are then the version's. A version without an update tool is refused, nothing changed.
4. Merges the version without committing yet. Conflicts on `index.md` files are expected: they take the version's side and are rebuilt afterwards. Any other conflict aborts the merge and names the files.
5. Checks that your Vault's identity (`vault_id`) is unchanged, or aborts.
6. Regenerates your assistant's three forms (the Claude Code subagent, the Codex skill and the web package) with the version's own generator, under the name and in the language the installer recorded in `<workspace>/second-brain/.install/state.json`, never the default name. If the logbook records no name, nothing is generated and the message says so.
7. Regenerates the indexes with the version's own `tools/build-indexes.sh`, then makes **one** merge commit named `Update to second-brain <version>`, through the Vault's guardians (never bypassed). A guardian refusal aborts the merge and shows its output.

It touches only this Vault: never a project, never your profile, never a tool configuration. Your projects' birth certificates keep their `vault_ref`, which records their birth, not the current version.

### 3. If the message says the MCP server may have changed

Declare the server again with `sb install --mcp`, then restart the Claude app. The same without `sb`: run the MCP installer again with your workspace ([INSTALL.md §4](../../INSTALL.md), which also gives the PowerShell form):

```bash
bash <workspace>/second-brain/tools/install-vault-mcp.sh <workspace>
```

_Not executed by the documentation check._ In PowerShell, type `sb install --mcp`: it runs this script on your workspace.

### 4. Check, and refresh the Claude Code plugin

Run `sb doctor`. Claude Code keeps its own copy of the `sb` plugin, which falls behind when a version changes it: `sb doctor` then says `installed, but older than the Vault's plugin: sb install`, and `sb install` reinstalls it ([Use the sb command and its plugin](use-the-sb-command-and-plugin.md), step 4). If the version's notes ask you to paste your Pilots' block again, `sb pilot-prompt <workspace>/<project>` prints it for each project.

### What the update also does for your projects

The update touches no project's files, with one exception: the links to a skill the version renamed. The table `tools/skill-renames.tsv` lists the renames (`ecriture-de-mission` became `mission-writing`, `recherche-interne` became `internal-search`). After an update that ends on `UPDATED` or `UP-TO-DATE`, the tool looks in every project of the registry: a link under a former name that points nowhere is **replaced** by the link under the new name, the tool prints `<link>: renamed skill relinked, <old name> -> <new name>`, and the project's journal gets one `APPLY:` line. A dead link that matches no known rename is named, never removed. `sb adopt` in an adopted project does the same, and `sb doctor` reports a link left behind ([Install and update tools](../reference/tools-install-and-update.md), `tools/skill-renames.tsv`).

### From an installation whose tool is older than the version

When a version changes how an update is done, an installation whose tool predates the handover (v0.1.14 and earlier) merges it by the old rules and may refuse — for v0.1.15, the refusal names `USER.md`. Run the **new version's** tool on your Vault with `--vault`. The simplest way is the one below for v0.1.7 and earlier: run the installation line of the new version; it installs nothing and prints the exact command, which runs the new version's tool with `--vault`. The same by hand, from a clone of the version in a temporary folder:

```bash
git clone --branch <version> https://github.com/businesshamiou/second-brain.git <temporary-folder>
bash <temporary-folder>/tools/second-brain-update.sh <version> --vault <workspace>/second-brain
```

_Not executed by the documentation check._ In PowerShell, the second line reads `& "C:\Program Files\Git\bin\bash.exe" <temporary-folder>/tools/second-brain-update.sh <version> --vault <workspace>/second-brain`.

From then on your Vault's tool hands over by itself.

### From v0.1.7 or earlier

The update tool does not exist yet in those installations. **Run the installation line of the new version** ([INSTALL.md §2](../../INSTALL.md)). It sees that Second Brain is already installed, installs nothing, and prints `Second Brain is already installed in <clone>. To receive <version> without reinstalling, run: <command>`. That command uses the new version's tool with `--vault` (`-Vault` from `install.ps1`) pointing at your clone ([install.sh](../../install.sh), [install.ps1](../../install.ps1)). If the installer first shows your recorded answers and asks `Has anything changed? (y/N)` (update mode, below), answering no stops it there, before it prints that command. After updating from v0.1.7 or earlier, the v0.1.8 notes also ask you to run `tools/install-vault-mcp.sh` again and restart the app, because the server name changed.

### From Claude Code or Codex: the update skill

The `update` skill ([skills/update/SKILL.md](../../skills/update/SKILL.md)) wraps the same tool. It first measures: `git status --porcelain` must be empty, `origin` must be the published repository, and the version must be a published tag. Then it runs the tool and reads the verdict. It never pushes, never resolves a conflict by hand, never forces anything, and never touches a project, your profile or a tool configuration.

### Resume an interrupted installation

If the installation stops halfway (you closed the window, the network failed while fetching Git), **rerun the same installation line**. The installer keeps a logbook, `<workspace>/second-brain/.install/state.json`, never tracked by Git. It records each step already done and each answer already given, so the installer picks up at the missing step without asking again ([README, "Resume and update"](../../README.md#reprise-et-mise-à-jour); [INSTALL.md §3](../../INSTALL.md)).

If the installer then behaves strangely, the README advises deleting the temporary folder it reuses before rerunning the line: *%TEMP%\\second-brain\\second-brain-install* on Windows, *${TMPDIR:-/tmp}/second-brain/second-brain-install* on macOS/Linux (the declared temporary folder).

### Change your profile answers: the installer's update mode

Rerunning the installer on a machine where Second Brain is already fully installed switches it to **update mode**:

1. it shows the answers it recorded (`install.sh` lists language, assistant name, workspace path and first name; `install.ps1` prints all recorded answers);
2. it asks `Has anything changed? (y/N)`;
3. if you say no, it prints `Nothing changed: no file was modified.` and stops; if you say yes, it asks the questions again and rewrites `USER.md` with its new date.

The workspace location is never asked again: once a real installation exists there, it does not move ([install.sh](../../install.sh), update-mode passage). The installer header says it looks for the existing logbook at the default workspace path ([install.ps1](../../install.ps1), header).

**Update mode never touches the code.** It only refreshes your profile answers. To receive a newer version, use the update tool (step 2).

## What you should see

The last line is a closed verdict. Exit code 0 for the first two, 1 for a refusal.

| Last line | Line above it | Meaning |
|---|---|---|
| `VERDICT: UPDATED` | `Updated to <version> (commit <hash>): your profile, identity, projects and history are kept.` | The merge commit exists. |
| `VERDICT: UPDATED` | `<version> was already there, but the forms of your assistant <name> were older: they are regenerated (commit <hash>).` | Only your assistant's forms were regenerated, in their own commit. |
| `VERDICT: UP-TO-DATE` | `Already up to date: <version> is already part of this Vault. Nothing was changed.` | Nothing was changed. |
| `VERDICT: REFUSED` | the cause (next section) | Nothing was changed. |

After an update, two more lines may appear before the verdict: `Files left uncommitted after the update: <files>`, and `The Vault's MCP server may have changed: run bash <path> <workspace> again, then restart the Claude app.` (step 3). Messages come from [catalog.en.json](../../i18n/catalog.en.json), keys `sbUpdate.*`.

For v0.1.15 from an installation at v0.1.14 or earlier, the one run of the new version's tool (with `--vault`, above) brings the version, keeps your profile and regenerates your assistant's forms in the same commit (`VERDICT: UPDATED`) ([RELEASE-NOTES.md](../../RELEASE-NOTES.md)).

## Known errors

Every refusal ends with `VERDICT: REFUSED`, exit code 1, and changes nothing.

| Message | Cause | What to do |
|---|---|---|
| `<folder> is not a Git clone: it cannot be updated.` | The folder is not a Git repository. | Point at your installed clone (`--vault`). |
| `This Vault has changes that are not committed (<files>): commit them first, ...` | Uncommitted or untracked files. | Commit them, then run the update again. |
| `This Vault has no generated identity (<file>): it is not an installed Second Brain.` | No generated `VAULT-IDENTITY.md`. | This folder cannot be updated. |
| `This Vault has no origin remote: there is nowhere to fetch a version from.` | No `origin` remote. | This folder cannot be updated as it stands. |
| `This Vault's origin is the installer's temporary folder (<path>): it was installed before v0.1.4 ...` | Installation older than v0.1.4. | Reinstall with the published line ([INSTALL.md](../../INSTALL.md)), in a new folder. |
| `Fetching from <origin> failed (network, or the remote moved).` | Fetch failed. | Check your network. |
| `The version <version> does not exist at <origin>.` | Unknown tag. | Check the name in `RELEASE-NOTES.md`. |
| `The update to <version> conflicts with local changes in: <files>. The merge was aborted, ...` | You edited a method file locally. | Keep your own work outside the Vault's corpus files, or ask for help. |
| `The update would change this Vault's identity (<old> -> <new>). The merge was aborted, ...` | Identity changed by the merge. | Read the message; ask for help. |
| `The assistant could not be regenerated with version <version>. The update was aborted, ...` | The version's generator failed. | Ask for help. |
| `The indexes could not be regenerated after merging <version>. The merge was aborted, ...` | `tools/build-indexes.sh` failed. | Ask for help. |
| `The Vault's guardians refused the update to <version> (output above). The merge was aborted, ...` | A guardian refused the commit. | Read the guardian output shown above it. |

After an aborted merge you may also see `Warning: HEAD is no longer at <commit> after the abort; check git log before anything else.` Do what it says. A wrong command line (no version, two versions, an unknown option) prints only the usage line and exits 1, with no verdict.

## Scripts used

- `tools/second-brain-update.sh`: merges a published version into the installed Vault. Sheet: [install and update tools](../reference/tools-install-and-update.md).
- `tools/second-brain-update.ps1`: Windows wrapper of the same script. Sheet: [install and update tools](../reference/tools-install-and-update.md).
- `install.sh`, `install.ps1`: the installers (resume, update mode, v0.1.7 path). Sheet: [install and update tools](../reference/tools-install-and-update.md).
- `tools/install-vault-mcp.sh`: declares the Vault's MCP server again after an update (`sb install --mcp`). Sheet: [assistant and MCP tools](../reference/tools-assistant-and-mcp.md).
- `tools/sb/sb.py`: `sb update`, `sb doctor`, `sb install`. Sheet: [install and update tools](../reference/tools-install-and-update.md).
- `tools/sb_installer_helper.py relink-renamed`, with `tools/skill-renames.tsv`: the renamed skills' links. Sheet: [install and update tools](../reference/tools-install-and-update.md).

## Liens

- `source` — [README, "Resume and update"](../../README.md)
- `source` — [Install guide, sections 2, 3, 4 and 7](../../INSTALL.md)
- `source` — [Update tool (bash)](../../tools/second-brain-update.sh)
- `source` — [Update tool (Windows wrapper)](../../tools/second-brain-update.ps1)
- `source` — [Update skill](../../skills/update/SKILL.md)
- `source` — [Release notes](../../RELEASE-NOTES.md)
- `source` — [MCP server installer](../../tools/install-vault-mcp.sh)
- `source` — [Installer (bash), update-mode passage](../../install.sh)
- `source` — [Installer (PowerShell), update-mode passage](../../install.ps1)
- `source` — [English message catalogue](../../i18n/catalog.en.json)
- `see also` — [Uninstall](uninstall.md)
- `see also` — [Use the sb command and its plugin](use-the-sb-command-and-plugin.md)
- `source` — [Table of renamed skills](../../tools/skill-renames.tsv)
- `see also` — [Install and update tools](../reference/tools-install-and-update.md)
- `see also` — [Architecture](../explanation/architecture.md)
- `see also` — [Troubleshooting](troubleshoot.md)
- `see also` — [Assistant](../explanation/assistant.md)
- `see also` — [Install guide](../../INSTALL.md)
- `see also` — [Product glossary](../../CONTEXT.md)
