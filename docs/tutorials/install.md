---
type: tutorial
title: "Your first installation"
description: "Install Second Brain end to end on a new machine: an Executor first, the installation line, the nine questions, the verdict, what the installer chains (sb install, the Claude app asked about, sb doctor, the welcome block on the clipboard), then three gestures, each with its place."
status: active
---

# YOUR FIRST INSTALLATION

This tutorial takes you from a machine without Second Brain to an installed Vault, a first project and your welcome Pilot open: **one line, then three gestures**. It follows the guided path only. For the options (installing from Claude Code or Codex, adopting a folder, updating), read [INSTALL.md](../../INSTALL.md).

Below, `<workspace>` is the absolute path of your workspace, for example C:/Users/you/second-brain-workspace or /Users/you/second-brain-workspace. Your installed Vault is `<workspace>/second-brain`.

**Where to type what.** Every instruction below starts with its place: **In the terminal** (PowerShell on Windows, Terminal on macOS or Linux), **In the Pilot** (a conversation with your Pilot, in the Claude desktop app on the proven path), **In the Executor** (an agent with a shell: Claude Code or Codex, opened in the right folder). The same verb is typed `sb <verb>` in a terminal, `/sb:<verb>` in Claude Code, `$sb <verb>` in Codex ([the table of places](../how-to/use-the-sb-command-and-plugin.md#where-to-type-what)).

## Step 1. Check that you are ready

- **A paid subscription** to at least one AI agent. Two paths are guided end to end:
  - **The Claude path** (proven): Claude Pro or higher. The Pilot lives in the Claude desktop app, the Executor is Claude Code.
  - **The OpenAI path** (declared: documented and dated, not yet played as a Pilot): ChatGPT Plus or higher, through **Codex**, which plays the Executor and can host the Pilot. ChatGPT itself cannot be a Pilot today: it runs no local MCP server ([Pilot hosts](../how-to/pilot-hosts-and-role-mixing.md)).
  - Any other agent: [adapt another agent](../how-to/pilot-hosts-and-role-mixing.md) is the standard page.
  Nothing is designed or tested for a free account.
- **An Executor installed**, before the installation: an agent with a shell. Second Brain installs none on its own. The official lines, read on 2026-09-30:

| Agent | Windows (PowerShell) | macOS, Linux (Terminal) | Source |
|---|---|---|---|
| Claude Code | `irm https://claude.ai/install.ps1 \| iex` | `curl -fsSL https://claude.ai/install.sh \| bash` | code.claude.com/docs/en/setup |
| Codex | `powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 \| iex"` | `curl -fsSL https://chatgpt.com/codex/install.sh \| sh` | github.com/openai/codex |

  Installed later is fine too: `sb doctor` then says `Executor (agent with a shell)` … `none` and names these lines; run `sb install` again once the agent is there.
- Windows with PowerShell 5.1 or higher, macOS, or Linux with Bash.
- Nothing else. Git, Python (through `uv`) and `pre-commit` are reused if present, otherwise set up in your own profile, without administrator rights.

Open a terminal: **PowerShell** on Windows, **Terminal** on macOS or Linux. A standard account is enough.

## Step 2. Run the installation line

**In the terminal**, paste the line for your system, exactly as published, and press Enter.

**Windows (PowerShell):**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.14/bootstrap.ps1)))"
```

_Not executed by the documentation check._

**macOS / Linux (Terminal):**

```bash
curl -fsSL https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.14/bootstrap.sh | bash
```

_Not executed by the documentation check._

The line downloads a small bootstrap script (`bootstrap.ps1` or `bootstrap.sh`). It fetches Second Brain at version v0.1.14 into a temporary folder, then starts the installer (`install.ps1` or `install.sh`).

**What you should see first:**

- On Linux without Git: `Downloading Git (static build, into your profile)...`.
- On macOS without Git, the bootstrap stops with `Second Brain bootstrap stopped: Git comes with Apple's Command Line Tools: finish the installation Apple just offered, then run the same line again.` Accept Apple's dialog, wait for the end, then run the same line again.
- Then a fixed English sentence, before any language is chosen:

```text
Second Brain installer -- answer each question, or press Enter to accept the default shown in parentheses.
```

**gum is optional.** In a terminal the questions are drawn by **gum** when it is there. If it is missing, the installer tries winget (Windows) or Homebrew (macOS) and prints `Installing gum, the tool that displays the questionnaire…`. Where neither is available — a Windows Sandbox, a fresh Windows without the Microsoft Store — you see `gum is not available: the questionnaire is shown in plain mode.`, and the same questions appear as plain text. The answers and the files written are the same either way. Pressing Esc or Ctrl+C in gum cancels the installation.

## Step 3. Answer the nine questions

Press Enter to accept the default in parentheses; a question marked *(optional: Enter to skip)* has no hidden default — an answer you do not give is recorded as not given. From question 2 on, the questions appear in the language you chose at question 1 (the English wording is shown here).

| # | What you see | Default when you press Enter |
|---|---|---|
| 1 | `Language / Langue / Idioma -- FR, EN or ES [EN]:` | Your system's language if it is French or Spanish, otherwise EN. An answer other than FR, EN or ES takes that default. |
| 2 | `What name would you like to give your assistant? (default: Brian)` | `Brian` |
| 3 | `Where should your Second Brain workspace live? (default: …)` | `second-brain-workspace` in your home folder (`%USERPROFILE%` on Windows, `$HOME` on macOS and Linux). |
| 4 | `What is your first name?` | None: the question comes back until you type something. |
| 5 | `What do you do, in one sentence? (optional: Enter to skip)` | Not given. |
| 6 | `How do you work with AI? (comma-separated: claude-code, codex, claude-ai, chatgpt) (detected on this machine: …)` | The agents found: `claude-code` when the `claude` command (or `<home>/.claude/skills`) is there, `codex` when the `codex` command (or `<home>/.codex/skills`) is there; `none` is said as such. |
| 7 | `What matters most to you? (optional: Enter to skip)` | Not given. |
| 8 | `Create a first project now? (default: yes)` | yes. `y`, `yes`, `o`, `oui`, `s` and `si` mean yes; anything else means no. |
| 9 | `Name for the first project?` (only after a yes) | Built from your answer to question 5: lower case, each run of other characters than `a-z` and `0-9` turned into one hyphen, 40 characters at most. `premier-projet` when nothing is left. |

Your answers to questions 5, 6 and 7 are written under `## Profil de départ` in `<workspace>/second-brain/USER.md` (`Ce que je fais`, `Outils du quotidien`, `Ce qui compte pour moi`): the starting interview of your welcome Pilot shows them and asks only what changed ([The starting interview](../how-to/starting-interview.md)). The answer to question 6 also picks your path: `codex` or `chatgpt` without `claude` gives the OpenAI path's gestures at the end, anything else the Claude path's.

The name at question 9 becomes a folder, `<workspace>/<project>`. Choose a short one.

**Question 3 refuses some answers** and asks again, naming the cause: a yes/no answer (`oui`, `non`, `y`, `n`), a path that is not absolute, or a path inside the temporary copy being installed from. On Windows, a workspace path that is too long is refused before anything is written in it; the message gives its length and the maximum (118 characters for this version). Choose a shorter folder and run the line again.

## Step 4. Watch the steps, then read the verdict

The questions are interleaved with one line per step, **in the language you chose** (here in English). With a first project, the whole run reads:

```text
  (question 1: the language)
Step: Prerequisites -- OK
  (questions 2 and 3)
Step: Workspace -- OK
Step: Clone -- OK
  (questions 4 to 7)
Step: Guardians -- OK
Step: Workspace CLAUDE.md/AGENTS.md -- OK
Step: Assistant -- OK
  (questions 8 and 9)
Step: First project -- OK
  (notes from the project creation)
Step: Project links -- OK
```

In French the lines read `Étape : prérequis — OK`, `Étape : espace de travail — OK`, and so on. When you decline a first project, the `First project` and `Project links` lines do not appear. Between them, the project creation prints its notes in your language, among them that Claude Code will ask a one-time approval the first time you open the project (answer yes).

The **verdict** comes next, signed with your assistant's name:

```text
Installation complete: everything is in place. — Brian
```

In French it reads `Installé, tout est en place. — Brian`. If a step fails, the last line names it instead, then says what to do, for example `Stopped at step clone: <cause> What to do: Review the error above; once it is fixed, run the installer line again to resume.` The exit code is then 1.

**The installer's own commits.** Your Vault is a Git clone of the public Second Brain repository. The installer commits locally what it writes — the identity and the workspace label (`Generate vault identity`), your assistant, your profile (`Write user profile from installer answers`), your first project's registration, `Installation complete` — so your Vault starts a few commits ahead of the public repository, and stays ahead as you work. That is normal: the public repository is where you install and update from, never where you push; `sb close` never counts it as a push to do ([Close a session](../how-to/close-a-session.md)).

**What is now on your disk:**

- `<workspace>/second-brain`: your Vault, a Git clone with its guardians switched on, your profile `USER.md`, its identity `VAULT-IDENTITY.md` and your assistant.
- `<workspace>/VAULT-ROOT.md`, with a `CLAUDE.md` and an `AGENTS.md` next to it.
- `<workspace>/<project>`: your first project, if you said yes.
- `<workspace>/second-brain/.install/state.json`: the installation logbook, never tracked by Git.
- The `sb` command on your user PATH (`<workspace>/second-brain/tools/sb/bin`).

**If it stopped:** run the same line again. The logbook keeps each step done and each answer given. When your workspace is at the default location, the installer reads that logbook back and does not ask again the questions already answered; with another location, it asks them again. Running the line where the installation at the default location is complete switches to update mode instead (`Has anything changed? (y/N)`), on Windows as on macOS and Linux; see [Update](../how-to/update.md). Known refusals are listed in [Troubleshooting](../how-to/troubleshoot.md).

## Step 5. The installer finishes the setup

After the verdict, the installer chains what used to be yours to type:

1. **`sb install`**: `sb` on your PATH, the Claude Code plugin behind `/sb:<verb>` when Claude Code is there, and this Vault's MCP server — the Pilot's access to your files — declared in every AI tool present (the Claude desktop app, Claude Code, Codex, Gemini CLI, Cursor, Windsurf, Cline, LM Studio). The server is named `second-brain-vault-<label>`; the label is your workspace folder's name in lower case, cut at a word boundary to 14 characters at most, so that every tool name stays within 64 characters (`second-brain-workspace` gives `second-brain`). It is recorded in `VAULT-IDENTITY.md` and committed.
2. **The Claude desktop app, if it is open**, is asked about first: `The Claude app is open: shall I close it so that the server is taken into account? (Y/n)`. While it runs it may erase the server's declaration, and it loads a new server only once **ended and reopened** — closing its window is not enough, it stays in the background. Answer yes and reopen it afterwards; answer no and do it yourself: **In Windows:** Settings → Apps → Installed apps → Claude → Advanced options → Terminate, then reopen Claude (**On macOS:** Cmd+Q, then reopen). The file is read back after writing, and the last line names the tools written, for example `Gesture left: restart Claude Code, Claude Desktop so that it loads the server`.
3. **`sb doctor`**: the check of the machine, ending with `Nothing blocking.` when all is well. Its line `Executor (agent with a shell)` names the agents found, or `none` with the official lines of Step 1.
4. **The welcome Pilot's block goes to your clipboard** (`The welcome Pilot's block is on your clipboard.`) — never select it in the terminal: a selection there cuts its long lines. Where no clipboard is reachable, the block is written to `<workspace>/second-brain/.install/accueil-block.txt`, and the line names that file.

## Step 6. The three gestures

The last lines of the installation are your three gestures, each with its place. **On the Claude path:**

```text
Installation done. Three gestures left:
  1. In the Claude app: create a Project named "SB - Accueil".
  2. In its instructions: paste (Ctrl+V, Cmd+V on macOS) the block.
  3. In a conversation of that Project: write "hello".
```

The Pilot answers `READY`, in the language you chose, then starts the starting interview. **On the OpenAI path** (declared): in the terminal, go to `<workspace>` and run `codex`; in Codex, paste the block as the first message and send it.

The block names your workspace itself: the first message no longer has to be a path. To get the block again later: **In the terminal:** `sb pilot-prompt --accueil --copy`.

**If the Pilot does not see the server** (it answers `NOT-READY` about the channel): in the Claude app, Settings → Developer must list `second-brain-vault-<label>`; if it does not, end the app as in Step 5 and reopen it ([Troubleshooting](../how-to/troubleshoot.md)).

To declare the server again by hand, **In the terminal:** `sb install --mcp` (or, underneath, `bash <workspace>/second-brain/tools/install-vault-mcp.sh <workspace>`; under PowerShell, `& "C:\Program Files\Git\bin\bash.exe" …`).

## Step 7. Go on to your first project

Type `sb help start` **in the terminal**: the first steps, each with its place, in your language ([Commands, help pages](../reference/commands.md#help-pages)). Your first project was already committed by the installer. Continue with [Your first project](first-project.md): its Pilot's block comes from `sb pilot-prompt <project> --copy`, and its first answer carries a **canary**, the proof that it read your disk through the server.

## Liens

- `source` — [Installation guide](../../INSTALL.md)
- `source` — [README](../../README.md)
- `source` — [Bootstrap (macOS / Linux)](../../bootstrap.sh)
- `source` — [Bootstrap (Windows)](../../bootstrap.ps1)
- `source` — [Installer (macOS / Linux)](../../install.sh)
- `source` — [Installer (Windows)](../../install.ps1)
- `source` — [Questionnaire helpers (Windows)](../../tools/questionnaire.ps1)
- `source` — [English message catalogue](../../i18n/catalog.en.json)
- `source` — [French message catalogue](../../i18n/catalog.fr.json)
- `source` — [MCP server installer](../../tools/install-vault-mcp.sh)
- `source` — [Project creation tool](../../tools/project-bootstrap.sh)
- `source` — [Installer helper (logbook reading)](../../tools/sb_installer_helper.py)
- `source` — [Vault identity and workspace label](../../tools/vault-identity.sh)
- `see also` — [Your first project](first-project.md)
- `see also` — [Open a session](../how-to/open-a-session.md)
- `see also` — [Update](../how-to/update.md)
- `see also` — [Troubleshooting](../how-to/troubleshoot.md)
- `see also` — [Install and update tools](../reference/tools-install-and-update.md)
- `see also` — [Assistant and MCP tools](../reference/tools-assistant-and-mcp.md)
- `see also` — [Architecture](../explanation/architecture.md)
- `see also` — [Glossary](../reference/glossary.md)
- `see also` — [Use the sb command and its plugin](../how-to/use-the-sb-command-and-plugin.md)
- `see also` — [Pilot hosts and role mixing](../how-to/pilot-hosts-and-role-mixing.md)
- `see also` — [The starting interview](../how-to/starting-interview.md)
- `see also` — [Close a session](../how-to/close-a-session.md)
