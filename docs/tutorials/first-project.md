---
type: tutorial
title: "Your first project"
description: "Find the first project the installer created (or create one), look at what it contains, open its first Pilot session and check its conformity."
status: active
---

# YOUR FIRST PROJECT

This tutorial follows the installation. At the end you will have one project registered in your Second Brain, you will know what each of its files is for, you will have opened its first Pilot session, and you will have measured it with the conformity check.

Throughout, `<workspace>` is the absolute path of your workspace (for example C:/Users/you/Workspaces or /Users/you/Workspaces), your Second Brain is `<workspace>/second-brain`, and `<project>` is the folder name of your project. Run the commands in Git Bash; under Windows in PowerShell, `bash` is not on the PATH, see [INSTALL.md, section 4](../../INSTALL.md) for how to call Git's own.

## Step 1. Find the project the installer created

Near its end, the installer asks "Create a first project now?" (default: yes), then "Name for the first project?". The proposed name is built from your answer to "what you do" (lower case, dashes, at most 40 characters); if you left that question blank, its default sentence is used, and only an answer with no ASCII letter or digit gives `premier-projet`. The project is created at `<workspace>/<project>` by `tools/project-bootstrap.sh`, and the installer then makes two commits: `Register first project: <Name>` in your Second Brain and `Initial scaffold from project-bootstrap` in the project ([install.sh](../../install.sh), [install.ps1](../../install.ps1)).

List your workspace:

```bash
ls <workspace>
```

**What you should see:** `<workspace>/second-brain`, the marker `<workspace>/VAULT-ROOT.md` and a folder `<workspace>/<project>` named after your first project. If you answered no to the question, there is no such folder: go to step 2. Otherwise skip to step 3.

## Step 2. Create a project (only if you have none)

Choose a folder name and a display name, then run:

```text
sb new <workspace>/<project> "<Name>" --vcs git --lang FR
```
_Not executed by the documentation check._ `sb new` calls `tools/project-bootstrap.sh create` with the same arguments, in PowerShell, Terminal or Git Bash alike.

- `--vcs git` creates the Git repository and installs the hook; without it, the script asks the Git question.
- `--lang FR` chooses the language of the script's messages (`FR`, `EN` or `ES`). The project's own files take the language recorded in the `USER.md` of your Second Brain; `--lang` is used for them only when none is recorded.

**What you should see**, in this order: a note about a one-time approval in Claude Code (step 4 explains it), then the **block to consume**, then, on the last line, the path of the new project sheet. With `--lang FR` the block reads:

```text
Pour ouvrir le Pilot de ce projet (application de bureau Claude, ou ChatGPT) :
  1. Crée un Projet nommé « <Name> ».
  2. Colle ce bloc tel quel comme instructions du Projet :
  ---
<the common Pilot prompt, with your Vault's server name filled in>
  ---
Chemin du projet : <project path>
Vault : <vault_id>, construit au commit <vault_ref>
Canari : pp-<12 hexadecimal characters>
Objet : <Name>
  3. Premier message de chaque conversation : <project path>
  Canari attendu à l'ouverture : pp-<...> (dans <project path>/state/PILOT-PROMPT.md).
<workspace>/second-brain/projects/PROJECT-<project_id>.md
```

Keep this output open: step 4 uses it. Unlike the installer, `create` commits nothing: the project's files and the new registry row stay uncommitted until an Executor commits them.

If the script refuses with one of the messages below, nothing of the project is created; a few later refusals (a path already in the registry, a name that gives no code, a project sheet already there) leave the project's empty folders in place. The refusals you are most likely to meet ([tools/project-bootstrap.sh](../../tools/project-bootstrap.sh)):

| Message | Cause | What to do |
|---|---|---|
| `REFUS : la cible existe deja : <target>` | `create` never writes into an existing folder | choose another name, or adopt the folder ([create a project](../how-to/create-a-project.md)) |
| `REFUS : chemin cible non absolu : <target>` | the target path is relative | give `<workspace>/<project>` in full |
| `REFUS : chemin cible a l'interieur du depot Vault (...)` | the target is inside `second-brain` | put the project next to it, in `<workspace>` |
| `REFUS : marqueur VAULT-ROOT.md introuvable en remontant depuis ...` | the target is outside your workspace | create it under `<workspace>` |

## Step 3. Look at what the project contains

Whether the installer or you created it, the project holds the same pieces. Open them one by one.

| Piece | Where | What it is |
|---|---|---|
| Seven functions | seven folders in `<workspace>/<project>`: rules, state, missions, decisions, proposals, knowledge, handoffs | the skeleton of the [project structure standard](../../rules/RULES-2026-08-26-142800-project-structure-standard.md); `<workspace>/<project>/missions/MISSION-INDEX.md` is already there |
| Identity | `<workspace>/<project>/README.md` | name, `project_id`, creation date |
| Pointer files | `<workspace>/<project>/CLAUDE.md` and `<workspace>/<project>/AGENTS.md` | identical; they import the method from your Second Brain |
| Journal | `<workspace>/<project>/state/journal.md` | append-only; one birth line, a timestamp followed by `STATE: ...` |
| State sheet | `<workspace>/<project>/state/STATE.md` | generated by `tools/build-state.sh`, the Pilot contract at its head; never edited by hand |
| Digest | `<workspace>/<project>/state/DIGEST.md` | generated by `tools/build-digest.sh`, the Pilot's short opening read, capped at 8,000 bytes |
| Pilot prompt | `<workspace>/<project>/state/PILOT-PROMPT.md` | generated; carries the canary |
| Birth certificate | `<workspace>/<project>/.pre-commit-config.yaml` | identity of your Second Brain, then the guardian pin |
| Registry row and sheet | `<workspace>/second-brain/projects/PROJECT-REGISTRY.md` and `<workspace>/second-brain/projects/PROJECT-<project_id>.md` | how your Second Brain knows the project's address |

Look at the journal:

```bash
cat <workspace>/<project>/state/journal.md
```

**What you should see:** a title `# Journal — <project>`, a `## Liens` section, then one dated line whose text begins with `STATE:` and names the birth of the project. New lines are only ever added by `tools/append-journal.sh`.

Look at the Pilot prompt:

```bash
cat <workspace>/<project>/state/PILOT-PROMPT.md
```

**What you should see:** a front matter with `project_id`, `canary` (the form `pp-` followed by 12 hexadecimal characters), `vault_id`, `mcp_server`, `vault_ref`, `state_path` (the state sheet's path relative to the project, by default the one of `<workspace>/<project>/state/STATE.md`), `language` and `generated_at`, then the project path and a three-step Pilot opening. Write down the canary: the Pilot must give it back to you in step 4. Never edit this file by hand; the `prompt` mode of `tools/project-bootstrap.sh` regenerates it ([open a session](../how-to/open-a-session.md)).

Look at the birth certificate:

```bash
head -n 5 <workspace>/<project>/.pre-commit-config.yaml
```

**What you should see:** five comment lines, `# second-brain-birth-certificate: v1`, then `# vault_id:`, `# vault_origin:`, `# vault_ref:` and `# vcs: git`. The rest of the file pins four guardians (`vault-check-secrets`, `vault-check-indexes-fresh`, `vault-check-index-weight`, `vault-check-links`) as `repo: local` hooks on your Second Brain. The project finds its Second Brain through this certificate, never by proximity.

Look at the registry row:

```bash
grep -n "<project>" <workspace>/second-brain/projects/PROJECT-REGISTRY.md
```

**What you should see:** one row under `## Active`, of the form `| <project_id> | <Name> | ACTIVE | <project> | git | CONFORME |`. The `project_id` is the creation date followed by a code made from the display name in capitals, for example `2026-09-25-BOOK-CLUB`. The path column is relative to your workspace. The last column is the conformity measured at creation.

## Step 4. Open the first Pilot session

The Pilot works in the Claude desktop application and reads your disk only through your Second Brain's MCP server. That server must be installed and the application restarted ([INSTALL.md, section 4](../../INSTALL.md)).

1. In the desktop application, create a **Project** named `SB - <display name>`: the letters `SB`, a space, a hyphen, a space, then your project's display name (for example `SB - Book Club`). The Pilot compares this name with the one its prompt expects at every opening.
2. Paste the common prompt as the Project's instructions. The shortest way: `sb pilot-prompt <workspace>/<project>` in a terminal prints the Project's name, the block with your server's name filled in, the first message and the canary (add `--regen` first if the installer created the project, for the reason below). Otherwise:
   - if you ran `create` in step 2, paste the block printed between the two `---` lines, exactly as it is;
   - if the installer created the project, it did not print that block (it calls the bootstrap in its historical form, which prints no block), and the project's Pilot prompt still names the server as it was before `tools/install-vault-mcp.sh` gave it your workspace's name. First regenerate that prompt, after installing the server:

     ```text
     sb pilot-prompt <workspace>/<project> --regen
     ```

     (`sb` calls `tools/project-bootstrap.sh prompt`, then prints the block.)

     _Not executed by the documentation check._ It prints `PILOT-PROMPT regenere : <workspace>/<project>/state/PILOT-PROMPT.md (serveur second-brain-vault-<name>, ...)` and keeps the canary. Then copy the text between the markers `PROMPT:BEGIN` and `PROMPT:END` of `templates/session-opening-prompt-template.md`, and replace every `{{VAULT_SHORT_ID}}` with what follows `second-brain-vault-` in the `mcp_server` line of that regenerated file.
3. Start a conversation and send the project path as the first message, in the form the block printed (for the installer's project, the path that file shows after "Chemin du projet").

**What you should see:** the Pilot first checks that the server answers and that its allowed folders contain your project path, then reads `<workspace>/<project>/state/PILOT-PROMPT.md` and gives back its canary, then reads the state sheet and applies the contract at its head ([the template](../../templates/session-opening-prompt-template.md)). The first line of its answer is the verdict, `READY` or `NOT-READY (<reason>)`, with nothing before it, followed by `[role: pilot · <plan|implement|validate> · open]` ([session-start skill, §4](../../skills/session-start/SKILL.md)). Compare the canary it returns with the one you wrote down: the same value proves it read your disk and did not answer from memory. `NOT-READY` means the Pilot files nothing in this session; reading and discussing remain allowed. Each reason, and what to do, is in [Opening scenarios](../how-to/opening-scenarios.md).

The first time you open the project in Claude Code (the Executor side), Claude Code asks once for an approval, an external import: the assistant and skills links in the project point to `<workspace>/second-brain`. Answer yes; it only grants read access to your Second Brain.

## Step 5. Check the project

```bash
bash <workspace>/second-brain/tools/check-project-conformity.sh <workspace>/<project>
```

In PowerShell, where `bash` is unknown: `& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/check-project-conformity.sh <workspace>/<project>`. `sb doctor`, typed in the project folder, runs the same check on its `Project conformity` line.

The check only measures; it fixes nothing ([tools/check-project-conformity.sh](../../tools/check-project-conformity.sh)). It looks at the seven functions and `<workspace>/<project>/README.md`, the registry row, the birth certificate, the guardian pin, the Git hook (because `vcs: git`) and whether `<workspace>/<project>/CLAUDE.md` and `<workspace>/<project>/AGENTS.md` point to the same Second Brain as the certificate.

**What you should see:** one line, `CONFORME`. Otherwise it prints `ÉCART: <missing1, missing2, ...>`; both verdicts exit with code 0. A non-zero exit means the measurement itself failed, for example `REFUS : chemin de projet introuvable : <path>`.

The most common gap on a fresh project is `hook Git absent (pre-commit install)`, when `pre-commit` was not found at creation. Install the hook, then run the check again:

```bash
cd <workspace>/<project> && pre-commit install
```
_Not executed by the documentation check._

## Where to go next

- Write and run your first Mission: [your first Mission](first-mission.md).
- Every option of `create`, `adopt` and the initiation order: [create a project](../how-to/create-a-project.md).
- Opening sessions in detail, Pilot and Executor: [open a session](../how-to/open-a-session.md).

## Liens

- `source` — [Project bootstrap script](../../tools/project-bootstrap.sh)
- `source` — [Installer for macOS and Linux](../../install.sh)
- `source` — [Installer for Windows](../../install.ps1)
- `source` — [Project conformity check](../../tools/check-project-conformity.sh)
- `source` — [session-start skill](../../skills/session-start/SKILL.md)
- `source` — [Template — minimal opening prompt for a Pilot session](../../templates/session-opening-prompt-template.md)
- `source` — [Journal appender](../../tools/append-journal.sh)
- `source` — [State sheet builder](../../tools/build-state.sh)
- `source` — [Digest builder](../../tools/build-digest.sh)
- `source` — [Project Registry](../../projects/PROJECT-REGISTRY.md)
- `source` — [Project structure standard, seven functions](../../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- `source` — [Installation guide, sections 3 and 4](../../INSTALL.md)
- `source` — [Message catalogue, English](../../i18n/catalog.en.json)
- `source` — [Message catalogue, French](../../i18n/catalog.fr.json)
- `see also` — [Create a project](../how-to/create-a-project.md)
- `see also` — [Open a session](../how-to/open-a-session.md)
- `see also` — [Install Second Brain](install.md)
- `see also` — [Your first Mission](first-mission.md)
- `see also` — [Project tools reference](../reference/tools-projects.md)
- `see also` — [Opening scenarios](../how-to/opening-scenarios.md)
- `see also` — [Glossary](../reference/glossary.md)
