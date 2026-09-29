---
type: how-to
title: "Uninstall"
description: "Remove Second Brain from your machine: delete the workspace folder, optionally remove the tools set up in your profile, clear the profile links of an installation older than Mission 173, and know what the sources say about the MCP server entry."
status: active
---

# UNINSTALL

This page tells you how to remove Second Brain from your machine. **There is no uninstall tool**: removal is a manual deletion, described in the README's "Uninstallation" section ([README](../../README.md)). One script helps only with installations made before Mission 173.

## Before you start

- **Know your workspace folder.** It is the folder that holds the *VAULT-ROOT.md* marker, your `second-brain` clone and your projects ([INSTALL.md §3](../../INSTALL.md)). On Windows, the installer proposes a folder named *second-brain-workspace* in your profile by default ([install.ps1](../../install.ps1)). Below, `<workspace>` is its absolute path, for example C:/Users/you/Workspaces.
- **Your projects are inside it.** Deleting the workspace deletes the `second-brain` clone, its history, and every project created next to it. Copy out anything you want to keep first.
- **Installed before Mission 173?** Do step 1 *before* deleting the workspace. The script it uses lives in your clone, and it refuses a workspace that no longer contains a `second-brain` folder ([remove-profile-links.ps1](../../tools/remove-profile-links.ps1)).
- Step 1 is a Windows PowerShell script; it looks in your Windows profile (*%USERPROFILE%*).

## Steps

### 1. Installations older than Mission 173 only: remove the profile links

An installation made before Mission 173 may have placed links in your profile, in *.claude/agents/*, *.claude/skills* and *.agents/skills* ([README](../../README.md), "Uninstallation"). The script `tools/remove-profile-links.ps1` looks only at the immediate contents of those three profile folders. It selects a link when it points inside `<workspace>/second-brain`, and also a dead junction whose stored target no longer exists but still names a folder called `second-brain`. Anything else, such as a skill you installed from elsewhere, is left untouched.

First, list. Pass the **workspace** folder, not the clone:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <workspace>\second-brain\tools\remove-profile-links.ps1 -WorkspacePath "<workspace>"
```

Without `-Remove`, the script only lists: each link, its kind (`Junction`, `HardLink` or `DeadJunction`) and what it points at. Read the list. Then run it again with `-Remove`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <workspace>\second-brain\tools\remove-profile-links.ps1 -WorkspacePath "<workspace>" -Remove
```

_Not executed by the documentation check._

PowerShell asks you to confirm each link, one by one, never all at once, so you can keep any of them. Only the link itself is removed, never the content it points at.

### 2. Take `sb` off your PATH and remove its plugin

The installer put the `sb` command on your user PATH, and `sb install` may have added the Claude Code marketplace `second-brain` and the plugin `sb@second-brain`. `sb uninstall` prints these steps with your own paths, and deletes nothing:

```bash
sb uninstall --path
claude plugin uninstall sb@second-brain
```

_Not executed by the documentation check._

The first line removes the PATH entry (the user `Path` variable on Windows, the marked block of your profile script elsewhere); the second, the plugin, only if you had added it. Do both **before** deleting the workspace: `sb` lives in it ([Use the sb command and its plugin](use-the-sb-command-and-plugin.md)).

### 3. Delete the workspace folder

Once step 2 is done, uninstalling Second Brain consists of deleting your workspace folder, and nothing else ([README](../../README.md)). Delete the folder `<workspace>` with your file manager. The clone, the assistant and the method's skills all live inside it, or in links that your projects point into it.

Second Brain keeps no copy of it elsewhere on your machine: the README says nothing is written outside that folder (but see steps 2 and 5).

### 4. Optional: remove the tools installed for you

The installer sets up Git, `uv` and `pre-commit` in your profile when they are missing, never machine-wide and never with administrator rights ([INSTALL.md §3](../../INSTALL.md)). If you no longer want them, the README says:

- they live in the hidden local subfolder of your profile (on Windows: *%USERPROFILE%\\.local\\*), outside the workspace: delete that folder;
- then remove the matching entries from your account's `Path` variable (on Windows: Settings, then Environment variables).

For reference, the bootstrap script places portable Git in *%USERPROFILE%\\.local\\share\\second-brain\\PortableGit* on Windows, and the static Git for Linux in *$HOME/.local/share/second-brain/git-linux64* ([bootstrap.ps1](../../bootstrap.ps1), [bootstrap.sh](../../bootstrap.sh)). The README names the Windows location only, and does not list what else that *.local* folder may hold: look at its contents before you delete it.

Skip this step if you use Git, `uv` or `pre-commit` for anything else.

### 5. The MCP server entry: what the sources say, and what they do not

The installer itself writes nothing into your profile ([INSTALL.md §4](../../INSTALL.md)). The Pilot's disk access is set up afterwards by `/first-install`, which runs `tools/install-vault-mcp.sh`. That script declares this Vault's server, named `second-brain-vault-<workspace label>`, in the tools it finds ([install-vault-mcp.sh](../../tools/install-vault-mcp.sh)):

| Tool | How the entry is written |
|---|---|
| Claude Code | `claude mcp add -s user`, in the user configuration (*~/.claude.json*) |
| Codex | `codex mcp add`, in *config.toml* under *~/.codex* (or `CODEX_HOME`) |
| Claude desktop application | merged into *claude_desktop_config.json*, in each configuration folder the script measures |

What the sources do **not** say: how to remove that entry when you uninstall.

- The README's "Uninstallation" section does not mention it.
- The script's `--retire <key>` option never removes the key `second-brain-vault` or a key that starts with `second-brain-vault-`. Asked to, it refuses with `REFUSED: retirement refused: <key> is a Vault's server, --retire never retires a Vault server. Nothing is changed.` ([catalog.en.json](../../i18n/catalog.en.json), key vaultMcp.retireRefused).
- The script does call `claude mcp remove -s user <name>` and `codex mcp remove <name>` itself, but only to replace its own entry, to migrate a former name of the same Vault, or to retire a key given with `--retire` that is not a Vault's server. No source presents these as an uninstall step.

Once the workspace is deleted, the entry points at a folder that no longer exists.

## What you should see

The listing run (step 1) prints first:

```text
Second Brain (Mission 173) -- profile links pointing at <workspace>\second-brain
```

then one of two outcomes:

- `None found under <profile> (.claude/skills, .claude/agents/, .agents/skills). Nothing to do.`: you have no old links; go to step 2.
- `Found <n> link(s) left by a pre-Mission-173 installation:`, one `- [<kind>] <path>` line per link with its `-> <target>` line, a line recalling that only the links themselves would be removed, then `Listing only (pass -Remove to actually remove, after reviewing the list above).`

After the run with `-Remove`, the last line is `Removed <m> of <n> link(s).` A number lower than the total means you declined some confirmations.

Steps 2 and 3 print nothing: the folder is gone from your file manager.

## Known errors

| Message | Cause | What to do |
|---|---|---|
| `Workspace path not found: <path>` | The `-WorkspacePath` folder does not exist. | Give the absolute path of your workspace. |
| `No second-brain clone found at <path>\second-brain -- pass the WORKSPACE path (the folder that contains VAULT-ROOT.md and second-brain\), not the clone itself.` | You passed the clone instead of the workspace, or the clone is already deleted. | Pass the workspace folder. If the clone is already gone, the script cannot run from it: the sources describe no other way. |
| `REFUSED: retirement refused: <key> is a Vault's server, ...` | `install-vault-mcp.sh --retire` was given a Vault server key. | None: this option never removes a Vault server (step 5). |

## Scripts used

- `tools/remove-profile-links.ps1`: lists, then removes on confirmation, the profile links of an installation older than Mission 173. Sheet: [install and update tools](../reference/tools-install-and-update.md).
- `tools/install-vault-mcp.sh`: declares the Vault's MCP server; cited here for what it does not remove. Sheet: [assistant and MCP tools](../reference/tools-assistant-and-mcp.md).

## Liens

- `source` — [README, "What is installed, and where" and "Uninstallation"](../../README.md)
- `source` — [Install guide, sections 3 and 4](../../INSTALL.md)
- `source` — [Profile link removal script](../../tools/remove-profile-links.ps1)
- `source` — [MCP server installer](../../tools/install-vault-mcp.sh)
- `source` — [English message catalogue](../../i18n/catalog.en.json)
- `source` — [Installer (PowerShell), default workspace](../../install.ps1)
- `source` — [Bootstrap (PowerShell), portable Git location](../../bootstrap.ps1)
- `source` — [Bootstrap (bash), Linux Git location](../../bootstrap.sh)
- `see also` — [Update](update.md)
- `see also` — [Use the sb command and its plugin](use-the-sb-command-and-plugin.md)
- `see also` — [Install and update tools](../reference/tools-install-and-update.md)
- `see also` — [Assistant and MCP tools](../reference/tools-assistant-and-mcp.md)
- `see also` — [Troubleshooting](troubleshoot.md)
- `see also` — [Architecture](../explanation/architecture.md)
