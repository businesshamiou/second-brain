---
type: how-to
title: "Start something new"
description: "Which window to open, with which prompt, for every way of starting: telling Second Brain who you are, a new idea, a new project, an existing folder, a project that already exists, a question with no project, a first installation. Follows the entry-scenario matrix of the session-start skill."
status: active
---

# START SOMETHING NEW

Every way of starting has one line in the entry-scenario matrix at the head of the [session-start skill](../../skills/session-start/SKILL.md) (§0): what the agent measures, the gesture it makes, the prompt, the tool, and the test that proves it. This guide reads the same matrix from your side: what you want to do, which window you open, what you paste. What each window answers first, line by line, is in [Opening scenarios](opening-scenarios.md); `sb help scenarios` prints the short version in a terminal. The rules behind it are in the [rule on workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md).

In the commands below, `<workspace>` is the absolute path of your workspace and the installed Second Brain is `<workspace>/second-brain`.

**First time?** Type `sb help start` in a terminal: the first steps, in ten lines and in your language, from checking the machine to closing a session; its step 2 is the welcome Pilot below ([Commands, help pages](../reference/commands.md#help-pages)).

## Before you start

- **Names.** Every project has a display name in the [Project Registry](../../projects/PROJECT-REGISTRY.md). Its Pilot is a Project of the Claude desktop application named `SB - <display name>`: the letters `SB`, a space, a hyphen-minus, a space, then the display name — plain ASCII, so it types the same on every keyboard. The welcome Pilot is `SB - Accueil`. `sb pilot-prompt <folder>` prints a project's exact Project name and the block to paste.
- **Folders.** A project lives in `<workspace>/<folder>`, or in `<workspace>/<group>/<folder>` when you choose a group. The root of the workspace holds nothing else than the marker and its two guides (`CLAUDE.md`, `AGENTS.md`), Second Brain, the projects and groups, its declared organs, `_trash`, `_archive` and `_orders`; `sb clean` (or `tools/check-workspace-root.sh`) says what is out of place, as a warning, never a block.
- **Throwaway files** of the tools go to the declared temporary folder, outside the workspace (`<system temporary folder>/second-brain` unless the marker says otherwise).

## Steps

### You have an idea, no project yet (scenario E9)

1. Once, create the welcome Pilot. This command, typed anywhere in your workspace (PowerShell, Terminal or Git Bash alike), prints the block to paste; it writes nothing:

   ```text
   sb pilot-prompt --accueil
   ```

   _Not executed by the documentation check._

   Create a Project named `SB - Accueil`, paste the block as its instructions. The block is the one `tools/project-bootstrap.sh accueil-prompt` prints; `sb` calls it for you, so there is no `bash` to type.
2. Open a conversation in `SB - Accueil`; the first message is the path of your workspace. It reads your starting profile first ([The starting interview](starting-interview.md)): shown with "what has changed?", or asked one question at a time when it is missing. Think the project through with it; before proposing the order it asks the project's three questions — expected result, current blocker, review rhythm — one at a time. When you agree on it, it writes one initiation order in `<workspace>/_orders/` (it announces the path first) and hands you an `initiation` mini-prompt.

### You want Second Brain to know you (scenario E9, then E3)

In `SB - Accueil`, the starting interview ends, with your yes, on a profile order `<workspace>/_orders/PROFILE-<YYYY-MM-DD-HHMMSS>.md`. Paste the mini-prompt it gives you in an Executor opened in the workspace: it runs `sb profile --order <order>`, which rewrites only the section `## Profil de départ` of `<workspace>/second-brain/USER.md` and files the order in `<workspace>/_archive/orders/`; the Executor then commits `USER.md` alone. `sb profile` shows the profile and what it lacks ([The starting interview](starting-interview.md)).

### You have an order: create the project (scenarios E3, then E7)

1. Open Claude Code or Codex **in the workspace** and paste the `initiation` mini-prompt. The Executor runs `sb new --order <order>`, that is `tools/project-bootstrap.sh --order <order>`; with the order's optional `Groupe` field, the project goes to `<workspace>/<group>/<name>`; its optional fields `Résultat attendu`, `Blocage actuel`, `Rythme de revue` go under `## Profil du projet` of the project's `README.md`. It relays the block that ends the run and moves the order to `<workspace>/_archive/orders/`.
2. Create the Project the block names, `SB - <Name>`, paste the framed instructions, and send the project's path as the first message ([Create a project](create-a-project.md), step 3).

### You already have a folder (scenario E2)

Open an Executor in it and ask it to open the session. The folder is not adopted: the Executor answers `NOT-READY (dossier non adopté, ordre d'initiation rendu)` and prints the order to fill in (`project-bootstrap.sh order <folder>`), writing nothing. Fill it with the welcome Pilot or by hand, then follow [Adopt an existing folder](adopt-a-project.md); `sb adopt` in that folder adopts it directly, and `sb adopt --ask` also asks the project's three questions.

### You work on a project that exists (scenarios E1, E7)

- **Pilot:** open a conversation in its Project `SB - <display name>`, first message the project's path. The Pilot returns the canary and says whether the name of its Project matches. `sb pilot-prompt <folder>` prints the name, the block, the first message and the canary.
- **Executor:** open Claude Code or Codex in the project folder, type `sb open` or paste the Mission's mini-prompt. It checks the workspace root and the project's identity card before anything else.

### You only want to ask or read (scenario E10)

Open any window without a project path, a Mission or an order: it is a free session. Its first line is `READY (session libre)`; it reads and discusses, and writes nothing. The [free-session template](../../templates/free-session-prompt-template.md) opens one on purpose.

### Your machine has no Second Brain yet (scenario E11)

Install it ([INSTALL.md](../../INSTALL.md)): the installer writes the workspace marker, with the line of the declared temporary folder, puts `sb` on your PATH and creates your first project, whose final block names `SB - <Name>`. Then, in a new terminal, `sb install` and `sb doctor` ([Use the sb command and its plugin](use-the-sb-command-and-plugin.md)).

## What you should see

- The first line of every opening is `READY` or `NOT-READY (<reason>)` (`READY (session libre)` in a free session).
- An Executor opened at the root of the workspace, without an order, answers `NOT-READY (racine de l'espace …)` and writes nothing.
- `sb doctor` shows `VERDICT: CONFORME (…)` on its `Workspace root` line when the root is in order (`sb clean` names what is out of place); underneath, it is `tools/check-workspace-root.sh`.
- A Pilot given a path its server may not read answers `NOT-READY (chemin non autorisé : …)`, distinct from `NOT-READY (projet non adopté)` for a readable folder with no Pilot prompt ([Opening scenarios, E8](opening-scenarios.md)).

## Known errors

- **`REFUS : --group (ou le champ Groupe de l'ordre) ne vaut que pour create`**: an adoption keeps the folder where it is; move the folder yourself first if you want it in a group.
- **`REFUS : le groupe … est un projet`**: a group only holds projects; choose another group name.
- **`ANOMALY (nom du Project)`** at a Pilot opening: rename the Project in the application to the name the identity card gives (`project-bootstrap.sh identity <project>`).

## Scripts used

- `tools/project-bootstrap.sh` — `accueil-prompt` (through `sb pilot-prompt --accueil`), `--order`, `order`, `create --group`, `identity`: [project tools](../reference/tools-projects.md)
- `tools/starting_profile.py` — `sb profile`, the two profiles: [project tools](../reference/tools-projects.md)
- `tools/check-workspace-root.sh` — the root against its whitelist: [guardians](../reference/tools-guardians.md)
- `tools/lib/tmp.sh` — the declared temporary folder: [internal helpers](../reference/tools-internal-helpers.md)

## Liens

- `source` — [Rule — Workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
- `source` — [Skill: session-start, entry-scenario matrix](../../skills/session-start/SKILL.md)
- `source` — [Template: welcome Pilot](../../templates/accueil-pilot-prompt-template.md)
- `source` — [Template: free session](../../templates/free-session-prompt-template.md)
- `source` — [Template: initiation order](../../templates/initiation-order-template.md)
- `source` — [Project bootstrap script](../../tools/project-bootstrap.sh)
- `source` — [Workspace-root guardian](../../tools/check-workspace-root.sh)
- `see also` — [The starting interview](starting-interview.md)
- `see also` — [Create a project](create-a-project.md)
- `see also` — [Adopt an existing folder](adopt-a-project.md)
- `see also` — [Open a session](open-a-session.md)
- `see also` — [Opening scenarios](opening-scenarios.md)
- `see also` — [Use the sb command and its plugin](use-the-sb-command-and-plugin.md)
