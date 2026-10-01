---
type: how-to
title: "Use the sb command and its plugin"
description: "How to get the sb command on your PATH, install the Claude Code plugin behind /sb:<verb>, check everything with sb doctor, keep the plugin's cached copy up to date, and type the same verb in a terminal, in Claude Code, in Codex or to the Pilot."
status: active
---

# USE THE SB COMMAND AND ITS PLUGIN

Every operation of Second Brain has one English verb of the `sb` command: `sb open`, `sb close`, `sb new`, `sb update`, `sb doctor`, and so on — 22 verbs in five groups ([Commands](../reference/commands.md) lists them all, with their usage and where they run; the [command card](../COMMANDS-CARD.md) fits them on one page). `sb` is a real program of your Vault, `tools/sb/sb.py`, which works without any model; the same verb is reached from every surface you use. This page is the one that says how to install it, check it, keep it up to date and repair it. The rule behind it is the [rule on the sb command surface](../../rules/RULES-2026-09-26-200933-sb-command-surface.md).

## Before you start

- Second Brain is installed ([Install](../tutorials/install.md)). Below, `<workspace>` is the absolute path of your workspace and your Vault is `<workspace>/second-brain`.
- `uv` is on your PATH (the installer sets it up); `sb` runs through it, or through Python 3.8 or later when `uv` is missing.
- For `/sb:<verb>`: Claude Code installed, with its `claude` command on the PATH.

## Where to type what

Four places, and one form of the same verb in each (Mission 244: « even I struggle to know where to run which command »). Every instruction Second Brain gives you — in its outputs, its guides, its Pilots — starts with its place.

| Place | What it is | How you get there | What you type there |
|---|---|---|---|
| **In the terminal** | PowerShell (Windows), Terminal (macOS, Linux) | open it; `sb` works from any folder (outside your workspace it serves your Vault's workspace and says so) | `sb <verb>` |
| **In the Pilot** | a conversation with the Pilot: in the Claude desktop app, the Project `SB - Accueil` or `SB - <project>` (proven); in Codex, a session opened with the block (declared) | open the Project, start a conversation | plain words, or a message that starts with `sb ` for a verb marked « Pilot: yes » (`help`, `status`, `list`, `profile`, `pilot-prompt`, `mission`, `relay`, `close`) |
| **In the Executor** | an agent with a shell: Claude Code or Codex, opened in the right folder (the project's, or the workspace root for an order) | in the terminal, `cd <folder>` then `claude` or `codex` | `/sb:<verb>` in Claude Code, `$sb <verb>` in Codex, or the mini-prompt the Pilot handed you |
| **In Windows' Settings** (or macOS's menu) | the one gesture outside Second Brain: ending the Claude app | Settings → Apps → Installed apps → Claude → Advanced options → Terminate (macOS: Cmd+Q) | nothing: then reopen the app |

A block to paste (a Pilot's instructions) is never selected in the terminal — a selection there cuts its long lines: `sb pilot-prompt … --copy` puts it on your clipboard, and you paste it with Ctrl+V (Cmd+V on macOS).

## Steps

### 1. Get `sb` on your PATH

The installer already puts `<workspace>/second-brain/tools/sb/bin` on your user PATH (on Windows the user `Path` variable, elsewhere a marked block of your profile script). **Open a new terminal**, then type:

```bash
sb --version
```

_Not executed by the documentation check._

It prints `sb <version> · Second Brain · vault <commit> · <path of your Vault>`. On an installation that has no `sb` yet, call it once by its full path; it adds itself:

```bash
<workspace>/second-brain/tools/sb/bin/sb install --path
```

_Not executed by the documentation check._

In PowerShell or `cmd`, the launcher is `sb.cmd` in the same folder: `<workspace>\second-brain\tools\sb\bin\sb.cmd install --path`. There is no PowerShell script launcher, so a machine whose execution policy blocks scripts still runs it.

### 2. Finish the installation: `sb install`

```bash
sb install
```

_Not executed by the documentation check._

It runs the last four steps of an installation, in order, **each one only if needed**, and prints one numbered line per step:

1. `sb` on your user PATH;
2. the Claude Code marketplace `second-brain` (it runs `claude plugin marketplace add <workspace>/second-brain/skills/claude-plugins`);
3. the Claude Code plugin `sb@second-brain` (it runs `claude plugin install sb@second-brain`), so that `/sb:<verb>` exists — and reinstalls it when your copy is older than your Vault's (step 4 of this page);
4. your Vault's MCP server, declared in your tools: the Pilot's access to your files ([`tools/install-vault-mcp.sh`](../reference/tools-assistant-and-mcp.md)).

`sb install --path`, `sb install --plugin` or `sb install --mcp` runs one step alone; `sb install --run` resumes or repairs the installation itself. A step already done says `already there`; without Claude Code on the machine, steps 2 and 3 say `Claude Code not found on this machine: skipped`. `sb install` writes into your profile only what you ask it for: the PATH entry and Claude Code's own plugin settings. After a plugin install, in a Claude Code session that was already open, type `/reload-plugins`, then `/sb:help`. After the MCP step, restart the Claude desktop application so that the server loads.

### 3. Check everything: `sb doctor`

```bash
sb doctor
```

_Not executed by the documentation check._

Run it anywhere inside your workspace. It checks `sb` on the PATH, Git and `uv`, the workspace root, the Vault's guardians and working tree, the Codex skill budget, the Claude Code plugin, and, inside a project, its identity, its conformity and its skill links. Each line reads `OK`, `WARN` or `FAIL`; a problem comes with the command that fixes it, on the line under it. It repairs nothing itself. Given a refusal message in quotes, `sb doctor "<message>"` finds its cause and fix in the guides.

### 4. When the plugin's copy is behind

Claude Code does not read the plugin from your Vault: it installs a **copy** of it in its own cache (in the `plugins` folder of your Claude Code profile). When your Vault's plugin changes — typically after `sb update` — that copy falls behind, and a `/sb:<verb>` may then run an older card. `sb doctor` compares the two and says so:

```text
  WARN  Claude Code plugin     installed, but older than the Vault's plugin: sb install
```

Run `sb install` (or `sb install --plugin`): it uninstalls the stale copy and installs the Vault's plugin again. Then `/reload-plugins` in any open Claude Code session.

### 5. Update

`sb update <version>` brings your Vault to a published version ([Update](update.md)). Then run `sb doctor`, and `sb install` if it reports the plugin's copy as behind or the MCP server as changed.

### 6. The same verb on every surface

| Where you are | What you type | What happens |
|---|---|---|
| Any terminal (Git Bash, PowerShell, `cmd`, macOS, Linux) | `sb <verb>` | the program runs the verb |
| Claude Code, plugin installed | `/sb:<verb>` | one thin skill per verb, invoked only by you (never by the model on its own); it runs `sb <verb>` and applies the verb's card |
| Codex | `$sb <verb>` | a single router skill, `skills/sb/`, linked into each project like the other method skills |
| The Pilot (any Pilot host: the Claude desktop application, Codex, Gemini CLI…) | a message that starts with `sb ` | the Pilot has no shell: it applies the card of a verb marked « Pilot: yes » in [Commands](../reference/commands.md) (`help`, `status`, `list`, `profile`, `pilot-prompt`, `mission`, `relay`, `close` — the close starts in the Pilot); for any other verb it answers that the verb needs a shell and names the Executor window |
| Any other agent with a shell | a message that starts with `sb ` | it runs `sb <verb>` (or `bash <workspace>/second-brain/tools/sb/bin/sb <verb>` when `sb` is not on its PATH; in PowerShell, `& "<workspace>\second-brain\tools\sb\bin\sb.cmd" <verb>`), shows the output as is, then applies the card |

Always type a verb with its prefix (`sb status`, `/sb:status`, `$sb status`): the bare names `help`, `status`, `doctor`, `run` and `new` exist natively in some tools.

### 7. Help, in your language

`sb help` shows the welcome screen, `sb help <verb>` the page of one verb (usage, where it runs, what it does and does not do, examples, next steps), and `sb help start`, `sb help concepts` and `sb help scenarios` three short guides. Verbs stay in English; the help is written in French, English or Spanish: `--lang FR|EN|ES`, else the `SB_LANG` variable, else `USER.local.yaml`, else the `language:` of your `USER.md`, else the system's language, else English.

### 8. Tidy up, uninstall

- `sb clean` lists what the workspace root holds beyond its allowed list and measures the declared temporary folder and the trash; `sb clean --purge-temp` empties the declared temporary folder after asking you (`--yes` skips the question). It never touches `_trash` nor `_archive`, and an agent never runs it on its own initiative.
- `sb uninstall` prints your steps and deletes nothing: `sb uninstall --path` takes `sb` off your PATH, `claude plugin uninstall sb@second-brain` removes the plugin; the rest is in [Uninstall](uninstall.md).

## What you should see

- Every verb checks where it runs before doing anything, and a refusal is one line that starts with `REFUSED` (in your language), then the reason, then where to go.
- The exit code says what happened:

| Code | Meaning |
|---|---|
| 0 | done (or the card of an agent verb shown) |
| 1 | the underlying tool refused or failed; its own message is shown as is |
| 2 | usage: unknown verb, missing or extra argument |
| 3 | wrong place: the refusal names where the verb runs |
| 4 | not allowed here: an Owner-only verb outside the laboratory |

- `sb doctor` ends with `Nothing blocking.` (exit 0), or `At least one FAIL: follow the fix under it.`

## Known errors

| What you see | Cause | What to do |
|---|---|---|
| `sb` is not recognised as a command | `sb` is not on your PATH yet, or the terminal was opened before it was added. | Open a new terminal; otherwise run `<workspace>/second-brain/tools/sb/bin/sb install --path` (step 1). |
| `sb doctor`: `sb on the PATH … not found (a new terminal may be needed)` | Same cause. | Same fix. |
| `sb doctor`: `<path> is not this Vault's sb` | Another program named `sb` comes first on your PATH — for example the Storybook alias installed by `npm install -g sb`. | Put this Vault's `tools/sb/bin` before it, or remove the other one; `sb install --path` adds this Vault's. |
| `REFUSED: sb <verb> runs <place>. You are <where>.` then where to go (exit 3) | The verb does not run in this folder: `sb open` at the workspace root, for instance. | `cd` into the place named (a project folder: `sb list` shows them), then type it again. |
| `REFUSED: unknown verb « <verb> ».` (exit 2) | A typo, or a verb that does not exist. | `sb help` lists every verb. |
| `/sb:<verb>` does not exist in Claude Code | The plugin is not installed, or the open session has not reloaded it. | `sb install --plugin`, then `/reload-plugins`. |
| `/sb:<verb>` runs, but its card looks older than `sb help <verb>` | Claude Code's cached copy of the plugin is behind your Vault's. | `sb doctor` confirms it; `sb install` reinstalls it (step 4). |
| `sb doctor`: `marketplace not added: sb install` or `marketplace added, plugin not installed: sb install` | Step 2 or 3 of `sb install` was never made. | `sb install`. |
| The Pilot answers that a verb needs a shell | The verb is not marked « Pilot: yes »: it measures or writes, and the Pilot has no shell. | Type it in an Executor window (Claude Code or Codex opened in the project folder). |
| `REFUS : sb needs uv or Python 3.8+ on the PATH (sb install).` | Neither `uv` nor Python 3.8 is reachable. | Install `uv` (a prerequisite of the installer), then open a new terminal. |

Any other refusal: `sb doctor "<the whole line>"`, then [Troubleshoot](troubleshoot.md).

## Scripts used

- `tools/sb/sb.py`, `tools/sb/bin/sb`, `tools/sb/bin/sb.cmd`: the command and its two launchers. Sheet: [Install and update tools](../reference/tools-install-and-update.md).
- `tools/install-vault-mcp.sh`: step 4 of `sb install`. Sheet: [Assistant and MCP tools](../reference/tools-assistant-and-mcp.md).
- `tools/check-workspace-root.sh`, `tools/lib/tmp.sh`: read by `sb doctor` and `sb clean`. Sheets: [Guardian tools](../reference/tools-guardians.md), [Internal helpers](../reference/tools-internal-helpers.md).

## Liens

- `source` — [Rule — The sb command surface](../../rules/RULES-2026-09-26-200933-sb-command-surface.md)
- `source` — [Commands](../reference/commands.md)
- `source` — [Command card](../COMMANDS-CARD.md)
- `source` — [The sb program](../../tools/sb/sb.py)
- `source` — [The sb catalogue](../../tools/sb/verbs.json)
- `source` — [The Codex router skill](../../skills/sb/SKILL.md)
- `source` — [English message catalogue](../../i18n/catalog.en.json)
- `see also` — [Install and update tools](../reference/tools-install-and-update.md)
- `see also` — [Skills](../reference/skills.md)
- `see also` — [Update](update.md)
- `see also` — [Uninstall](uninstall.md)
- `see also` — [Troubleshoot](troubleshoot.md)
- `see also` — [Opening scenarios](opening-scenarios.md)
- `see also` — [Support FAQ](../reference/support-faq.md)
