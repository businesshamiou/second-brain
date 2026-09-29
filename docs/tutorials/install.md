---
type: tutorial
title: "Your first installation"
description: "Install Second Brain end to end on a new machine: the installation line, the nine questions, the closing verdict, the MCP server and the restart of the Claude app."
status: active
---

# YOUR FIRST INSTALLATION

This tutorial takes you from a machine without Second Brain to an installed Vault, a first project and the Claude app ready for the Pilot. It follows the guided path only. For the options (installing from Claude Code or Codex, adopting a folder, updating), read [INSTALL.md](../../INSTALL.md).

Below, `<workspace>` is the absolute path of your workspace, for example C:/Users/you/second-brain-workspace or /Users/you/second-brain-workspace. Your installed Vault is `<workspace>/second-brain`.

## Step 1. Check that you are ready

- A paid subscription to at least one AI agent (Claude Pro or higher, or ChatGPT Plus or higher). Nothing is designed or tested for a free account.
- Windows with PowerShell 5.1 or higher, macOS, or Linux with Bash.
- Nothing else. Git, Python (through `uv`) and `pre-commit` are reused if present, otherwise set up in your own profile, without administrator rights.

Open a terminal: **PowerShell** on Windows, **Terminal** on macOS or Linux. A standard account is enough.

## Step 2. Run the installation line

Paste the line for your system, exactly as published, and press Enter.

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
- Then the first step line and a fixed English sentence:

```text
Step: Prerequisites -- OK
Second Brain installer -- answer each question, or press Enter to accept the default shown in parentheses.
```

In a terminal the questions are shown by **gum**. If gum is missing, the installer tries to set it up with winget (Windows) or Homebrew (macOS) and prints `Installing gum, the tool that displays the questionnaire…`. Without gum you see `gum is not available: the questionnaire is shown in plain mode.`, and the same questions appear as plain text. The answers and the files written are the same either way. Pressing Esc or Ctrl+C in gum cancels the installation.

## Step 3. Answer the nine questions

Press Enter to accept the default in parentheses. From question 2 on, the questions appear in the language you chose at question 1 (the English wording is shown here).

| # | What you see | Default when you press Enter |
|---|---|---|
| 1 | `Language / Langue / Idioma -- FR, EN or ES [EN]:` | Your system's language if it is French or Spanish, otherwise EN. An answer other than FR, EN or ES takes that default. |
| 2 | `What name would you like to give your assistant? (default: Brian)` | `Brian` |
| 3 | `Where should your Second Brain workspace live? (default: …)` | `second-brain-workspace` in your home folder (`%USERPROFILE%` on Windows, `$HOME` on macOS and Linux). |
| 4 | `What is your first name?` | None: the question comes back until you type something. |
| 5 | `What do you do, in one sentence?` | `Not specified yet.` |
| 6 | `How do you work with AI? (comma-separated: claude-code, codex, claude-ai, chatgpt) (detected on this machine: …)` | The tools found: `claude-code` if `<home>/.claude/skills` exists, `codex` if `<home>/.codex/skills` exists; empty otherwise. |
| 7 | `What matters most to you?` | `simplicity, no over-engineering` |
| 8 | `Create a first project now? (default: yes)` | yes. `y`, `yes`, `o`, `oui`, `s` and `si` mean yes; anything else means no. |
| 9 | `Name for the first project?` (only after a yes) | Built from your answer to question 5: lower case, each run of other characters than `a-z` and `0-9` turned into one hyphen, 40 characters at most. `premier-projet` when nothing is left. |

The name at question 9 becomes a folder, `<workspace>/<project>`. Choose a short one.

**Question 3 refuses some answers** and asks again, naming the cause: a yes/no answer (`oui`, `non`, `y`, `n`), a path that is not absolute, or a path inside the temporary copy being installed from. On Windows, a workspace path that is too long is refused before anything is written in it; the message gives its length and the maximum (118 characters for this version). Choose a shorter folder and run the line again.

## Step 4. Watch the steps, then read the verdict

The questions are interleaved with one line per step. These lines stay in English whatever your language. With a first project, the whole run reads:

```text
Step: Prerequisites -- OK
  (questions 1 to 3)
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

When you decline a first project, the `First project` and `Project links` lines do not appear. Between them, the project creation prints its notes in your language, among them that Claude Code will ask a one-time approval the first time you open the project (answer yes). The installer's call stays silent about the Pilot: the project's Pilot prompt is written to `<workspace>/<project>/state/PILOT-PROMPT.md`, which [Your first project](first-project.md) uses.

The last line is the **verdict**, signed with your assistant's name:

```text
Installation complete: everything is in place. — Brian
```

In French it reads `Installé, tout est en place. — Brian`. The installer then ends with exit code 0.

If a step fails, the last line names it instead, then says what to do, for example `Stopped at step clone: <cause> What to do: Review the error above; once it is fixed, run the installer line again to resume.` The exit code is then 1.

**What is now on your disk:**

- `<workspace>/second-brain`: your Vault, a Git clone with its guardians switched on, your profile `USER.md`, its identity `VAULT-IDENTITY.md` and your assistant.
- `<workspace>/VAULT-ROOT.md`, with a `CLAUDE.md` and an `AGENTS.md` next to it.
- `<workspace>/<project>`: your first project, if you said yes.
- `<workspace>/second-brain/.install/state.json`: the installation logbook, never tracked by Git.
- The `sb` command on your user PATH (`<workspace>/second-brain/tools/sb/bin`): open a **new** terminal and type `sb --version` to see it.

**If it stopped:** run the same line again. The logbook keeps each step done and each answer given. When your workspace is at the default location, the installer reads that logbook back and does not ask again the questions already answered; with another location, it asks them again. Running the line where the installation at the default location is complete switches to update mode instead (`Has anything changed? (y/N)`), on Windows as on macOS and Linux; see [Update](../how-to/update.md). Known refusals are listed in [Troubleshooting](../how-to/troubleshoot.md).

## Step 5. Set up the MCP server

The installer does not configure your AI tools, so the Pilot's disk access is a separate step. The shortest way is `sb install` in a new terminal: its last step declares the server (`sb install --mcp` runs that step alone), and its other steps install the Claude Code plugin behind `/sb:<verb>` ([Use the sb command and its plugin](../how-to/use-the-sb-command-and-plugin.md)). Underneath, `tools/install-vault-mcp.sh` finds Claude Code, Codex and the Claude desktop app, and declares this Vault's server in each: `second-brain-vault-<label>`, where `<label>` is the name of your workspace folder in lower case (accents dropped, every other run of characters than `a-z` and `0-9` turned into one hyphen), with your workspace as the only folder it may read.

**macOS / Linux:**

```bash
bash <workspace>/second-brain/tools/install-vault-mcp.sh <workspace>
```

_Not executed by the documentation check._

**Windows (PowerShell)**, where `bash` is not on the PATH; call Git's by its full path, as [INSTALL.md](../../INSTALL.md) does:

```powershell
& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/install-vault-mcp.sh <workspace>
```

_Not executed by the documentation check._

Its report is in English by default; add `--lang FR` or `--lang ES` for another language. **What you should see**, for example:

```text
Python through uv: <version>
Workspace label posed in VAULT-IDENTITY.md: <label> (server second-brain-vault-<label>).
Detected: Claude Code
Claude Code: server second-brain-vault-<label> configured (allowed folder: <workspace>).
Not found: Codex
Detected: <path of claude_desktop_config.json>
<path of claude_desktop_config.json>: server second-brain-vault-<label> configured (allowed folder: <workspace>).
Remaining step: restart each tool detected above (the Claude app, Claude Code, Codex, Gemini CLI…) so it loads the server.
```

The Claude app's lines name its configuration file (`Not found: Claude Desktop` when it is not installed). A tool that is not installed reads `Not found: …` (Gemini CLI, Cursor, Windsurf, Cline, LM Studio each have their line), and that is fine. Running the command a second time changes nothing (`… already configured, unchanged.`). If no tool is found at all, the last line is `No tool detected (Claude app, Claude Code, Codex, Gemini CLI, Cursor, Windsurf, Cline, LM Studio): nothing to configure.`

## Step 6. Restart the Claude app

Quit the Claude desktop app completely, then open it again. Do the same for Claude Code or Codex if they were running. The server loads only at start-up.

The Pilot role is played in the desktop app: the server does not exist in the browser. You check that it really runs when you open your project's Pilot: its first answer carries a **canary**, the proof that it read your disk through this server.

## Step 7. Go on to your first project

Your installation is done. Run `sb doctor` in a new terminal: it checks `sb` on the PATH, Git, `uv`, the guardians, the plugin and your workspace, and ends with `Nothing blocking.` when all is well; under Windows, a `WARN` on `bash` only says that PowerShell does not know `bash`, and names the form to type instead. Then type `sb help start`: the first steps, in your language — step 2 creates the welcome Pilot `SB - Accueil` with `sb pilot-prompt --accueil` and starts the starting interview ([Commands, help pages](../reference/commands.md#help-pages)). Continue with [Your first project](first-project.md): regenerate the project's Pilot prompt so that it names the server you just installed, open the project's Pilot in the Claude app, and check the canary.

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
