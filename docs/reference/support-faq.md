---
type: reference
title: "Support FAQ"
description: "The questions people really ask about Second Brain — installing, opening a session, each READY or NOT-READY reason, the sb command and its plugin, the MCP server, updating, uninstalling, a guardian's refusal, where files live, what the assistant can and cannot do — each with a short answer and the page that is authoritative."
status: active
---

# SUPPORT FAQ

One short answer per question, in plain words, and the page that is authoritative for it. The assistant reads this page first for a customer or support question ([documentation map](../MAP.md)); an answer that needs more detail opens the page named, and nothing here is said without that page behind it. The verdicts are fixed strings in French, the method's language; a translation follows in brackets.

## Installing

**How do I install Second Brain?**
Run the one installation line for your system (PowerShell on Windows, a terminal on macOS or Linux), or `/first-install` from Claude Code or Codex, then answer nine questions. Nothing needs to be installed first. → [Your first installation](../tutorials/install.md), [INSTALL.md](../../INSTALL.md)

**The installation stopped halfway. Do I start again?**
Run the same line again: the installer keeps a logbook and resumes at the missing step without asking the answered questions again. → [Update, "Resume an interrupted installation"](../how-to/update.md)

**What is left to do after the installer's verdict?**
Open a new terminal and run `sb install`: it puts `sb` on your PATH if needed, installs the Claude Code plugin behind `/sb:<verb>`, and declares your Vault's MCP server in every tool present; then restart them (the Claude desktop application, Codex…). `sb doctor` checks everything. → [Use the sb command and its plugin](../how-to/use-the-sb-command-and-plugin.md)

**Can I install from a zip archive?**
No: the guardians need a real Git repository; the installation line always clones one. → [README, "Installation line"](../../README.md)

## Opening a session

**Which window do I open for what I want to do?**
A new idea: the Pilot `SB - Accueil`. An existing project: its Pilot `SB - <display name>` in a Pilot host (the Claude desktop application, or another tool: [Pilot hosts and role mixing](../how-to/pilot-hosts-and-role-mixing.md)), and an Executor (Claude Code or Codex) opened in the project folder. A question with no project: any window, as a free session. `sb help scenarios` prints the same table. → [Start something new](../how-to/start-something-new.md)

**How do I open a Pilot, and an Executor?**
Pilot: in the Claude desktop application, a Project named `SB - <display name>`, with the block `sb pilot-prompt <folder>` prints as its instructions, and the project's path as first message; in another tool, `sb pilot-prompt <folder> --host <host>` gives its steps. Executor: open Claude Code or Codex in the project folder and type `sb open` (or `/sb:open`, `$sb open`). → [Open a session](../how-to/open-a-session.md)

**What should the first line of the answer be?**
The verdict, `READY` or `NOT-READY (<reason>)`, with nothing before it — `READY (session libre)` [free session] when there is no project, no Mission and no order. → [Opening scenarios](../how-to/opening-scenarios.md)

**What do I name my Pilot's Project?**
`SB - <display name>`: the letters `SB`, a space, a hyphen, a space, then the project's name from the registry. `sb pilot-prompt <folder>` prints the exact name. → [Create a project](../how-to/create-a-project.md)

## READY and NOT-READY

**I got `READY`. What now?**
The session is open; the Pilot also returned the project's canary, the proof it read your disk. Work. → [Opening scenarios, E1 and E7](../how-to/opening-scenarios.md)

**`READY (session libre)` — why won't it write anything?**
A free session reads and discusses, and writes nothing, by design. For work that writes, open the project's Pilot or an Executor with a Mission, or `SB - Accueil` for a project that does not exist yet. → [Opening scenarios, E10](../how-to/opening-scenarios.md)

**`NOT-READY (dossier non adopté, ordre d'initiation rendu)` [folder not adopted, initiation order returned]?**
The Executor's folder is not a Second Brain project, and an agent never adopts one on its own. Fill in the order it printed and hand it back, or run `sb adopt` in that folder. → [Opening scenarios, E2](../how-to/opening-scenarios.md), [Adopt an existing folder](../how-to/adopt-a-project.md)

**`NOT-READY (racine de l'espace : …)` [workspace root]?**
The window was opened at the root of the workspace, which holds no work. Open it in a project folder; `sb list` shows them. → [Opening scenarios, E4](../how-to/opening-scenarios.md)

**`NOT-READY (projet non adopté)` [project not adopted]?**
The Pilot can read the path, but the folder has no `state/PILOT-PROMPT.md`. It proposes an initiation order; hand it to an Executor, or run `sb adopt` there. → [Opening scenarios, E8](../how-to/opening-scenarios.md)

**`NOT-READY (chemin non autorisé : réinstaller le serveur MCP, sb install)` [path not authorized]?**
The Pilot's server may not read that folder; the project may well exist. In a terminal, `sb install --mcp`, then restart your Pilot's host. → [Opening scenarios, E8](../how-to/opening-scenarios.md)

**`NOT-READY (channel not answering)`?**
The Pilot's MCP server did not answer: it is not connected. Restart your Pilot's host; if it persists, `sb install --mcp`. → [Open a session, "Known errors"](../how-to/open-a-session.md)

**`NOT-READY (projet non nommé)` [project not named]?**
Your first message named no project. Send the project's path. → [Open a session, "Known errors"](../how-to/open-a-session.md)

**`NOT-READY (session close missing)`?**
The last session was not closed: its handoff exists but its close was never made. Run that handoff's Executor closing command first. → [Close a session](../how-to/close-a-session.md)

**`ANOMALY (nom du Project)` [Project name] in the state?**
The Project's name differs from the one the project expects. It never blocks; rename the Project to the name `sb pilot-prompt <folder>` prints. → [Opening scenarios, E7](../how-to/opening-scenarios.md)

## The sb command and its plugin

**`sb` is not recognised as a command.**
Open a new terminal; if it is still missing, run `<workspace>/second-brain/tools/sb/bin/sb install --path` once (`sb.cmd` in PowerShell). → [Use the sb command, step 1](../how-to/use-the-sb-command-and-plugin.md)

**`/sb:<verb>` does not exist, or does not answer, in Claude Code.**
The plugin is not installed, or the open session has not reloaded it: `sb install --plugin` in a terminal, then `/reload-plugins`. → [Use the sb command, steps 2 and 6](../how-to/use-the-sb-command-and-plugin.md)

**`/sb:<verb>` seems older than `sb help <verb>`.**
Claude Code keeps a copy of the plugin in its cache, which falls behind when your Vault changes. `sb doctor` says `installed, but older than the Vault's plugin`; `sb install` reinstalls it. → [Use the sb command, step 4](../how-to/use-the-sb-command-and-plugin.md)

**What is the equivalent in Codex, and with the Pilot?**
`$sb <verb>` in Codex. To the Pilot, send a message that starts with `sb `: it applies the verbs marked « Pilot: yes » and sends the others to an Executor window. → [Use the sb command, step 6](../how-to/use-the-sb-command-and-plugin.md)

**`sb` refused with exit code 3.**
The verb does not run in this folder; the refusal names where it runs. Change folder and type it again. → [Use the sb command, "Known errors"](../how-to/use-the-sb-command-and-plugin.md)

**Where is the list of every verb?**
`sb help` in a terminal; all 22 verbs, with their usage, are in the command reference. → [Commands](commands.md)

## The MCP server

**The Pilot says the server does not exist.**
The conversation is in a tool where the server is not declared (`sb doctor` lists the tools that have it), or in a browser-only tool that cannot run it (ChatGPT, Gemini on the web); or the server was never declared: `sb install --mcp`, then restart the tool. → [Open a session, "Known errors"](../how-to/open-a-session.md)

**Can my Pilot run in Codex, Gemini CLI or ChatGPT?**
Codex, Gemini CLI, Cursor, Windsurf, Cline and LM Studio run the Vault's server: declared hosts, `sb pilot-prompt --host <host>` gives the steps. ChatGPT and Gemini on the web accept only a remote server: not supported today — the reason and the way are on the page. → [Pilot hosts and role mixing](../how-to/pilot-hosts-and-role-mixing.md)

**What is my server called?**
`second-brain-vault-<workspace>`, after your workspace folder (for example `second-brain-vault-workspaces`). → [Architecture, "The MCP server"](../explanation/architecture.md)

**The Pilot seems confused about which project it is in.**
It must use only your Vault's server; check the server's configuration with `tools/check-mcp-containment.sh`, then ask it to read the disk again. → [README, "Frequently asked questions"](../../README.md)

## Updating

**How do I update to a new version?**
`sb update <version>`, for example `sb update v0.1.15`: the version is merged over your own commits and your profile, identity and projects stay as they are. Then `sb doctor`. → [Update](../how-to/update.md)

**The update refused and named `USER.md`.**
Your installation is older than v0.1.15, and its update tool is older than the version: run the new version's tool with `--vault`; the published installation line of the new version prints the exact command. → [Update, "From an installation whose tool is older than the version"](../how-to/update.md)

**After the update, my old skill links point nowhere.**
The update replaces, in each project, a link under a renamed skill's old name (`ecriture-de-mission`, `recherche-interne`) by the link under its new name (`mission-writing`, `internal-search`); `sb adopt` in a project does the same, and `sb doctor` names a link left behind. → [Update, "What the update also does for your projects"](../how-to/update.md)

**The update said the MCP server may have changed.**
`sb install --mcp`, then restart your Pilot's host. → [Update](../how-to/update.md)

## Uninstalling

**How do I uninstall?**
`sb uninstall` prints your steps: take `sb` off your PATH (`sb uninstall --path`), remove the Claude Code plugin, then delete your workspace folder. Nothing else is written elsewhere, except the tools installed for you and the MCP server entry. → [Uninstall](../how-to/uninstall.md)

## Guardians and commits

**A guardian refused my commit.**
A refusal is a stop, not an obstacle: read the report, fix the failed guardians (not the skipped ones), then commit again. Never bypass a guardian. → [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)

**Something at the root of my workspace is reported as a gap (`ÉCART`).**
The root may hold only the marker and its two guides, the Vault, your projects and groups, the declared organs, `_trash`, `_archive` and `_orders`. It is a warning, never a block; `sb clean` says what is out of place. → [Start something new, "Before you start"](../how-to/start-something-new.md)

## Files and folders

**Where are my files?**
Everything lives in your workspace folder: the Vault (`second-brain`), your projects next to it, and the marker `VAULT-ROOT.md`. Each project keeps its state sheet in `state/STATE.md` (or where its Pilot prompt's `state_path` says). → [Architecture, "The workspace"](../explanation/architecture.md), [README, "What is installed, and where"](../../README.md)

**Where do the tools' throwaway files go?**
To one declared temporary folder outside your workspace, `<system temporary folder>/second-brain` unless the marker says otherwise. `sb clean --purge-temp` empties it after asking you. → [Use the sb command, step 8](../how-to/use-the-sb-command-and-plugin.md)

## The assistant

**How do I ask the assistant something?**
Name it in your question, for example "Ask Brian: …". It then answers read-only and cites its sources by path. → [The assistant](../explanation/assistant.md)

**What can the assistant do, and not do?**
It reads and explains, citing the file behind every answer. It never writes, creates or runs anything once the installation is finished, and it says so when something is not in your Vault instead of making it up. → [The assistant, "Who it is and what it refuses"](../explanation/assistant.md)

## Liens

- `source` — [Documentation map](../MAP.md)
- `source` — [Opening scenarios](../how-to/opening-scenarios.md)
- `source` — [Use the sb command and its plugin](../how-to/use-the-sb-command-and-plugin.md)
- `source` — [Open a session](../how-to/open-a-session.md)
- `source` — [Start something new](../how-to/start-something-new.md)
- `source` — [Update](../how-to/update.md)
- `source` — [Uninstall](../how-to/uninstall.md)
- `source` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `source` — [Architecture](../explanation/architecture.md)
- `source` — [The assistant](../explanation/assistant.md)
- `source` — [Commands](commands.md)
- `see also` — [Troubleshoot](../how-to/troubleshoot.md)
- `see also` — [Installation guide](../../INSTALL.md)
