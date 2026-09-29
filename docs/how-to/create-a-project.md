---
type: how-to
title: "Create a project"
description: "Create a new Second Brain project from nothing with tools/project-bootstrap.sh create: prerequisites, the initiation order route, the exact command, what is written, and the refusals you may meet."
status: active
---

# CREATE A PROJECT

`create` gives birth to a new project: a folder of your workspace that Second Brain knows about. It inherits the method, the guardians and the skills without carrying a copy of them, and it stays the only source of its own memory: the [Project Registry](../../projects/PROJECT-REGISTRY.md) knows its address, not its content. To turn a folder you already have into a project, see [Adopt an existing folder](adopt-a-project.md). To fill the gaps of a project the conformity check reports as `ÉCART`, see [Bring a project into conformity](bring-a-project-into-conformity.md).

The verb is `sb new <folder> "<Display Name>"` (`sb new --order <file>` from an order); it runs the script below ([Commands](../reference/commands.md)).

In the commands below, `<workspace>` is the absolute path of your workspace (for example C:/Users/you/Workspaces or /Users/you/Workspaces), the installed Second Brain is `<workspace>/second-brain`, and the project to create is `<workspace>/<project>`.

## Before you start

- **Who runs it.** Creation is an Executor gesture: it writes into the Second Brain registry. The skill `skills/project-bootstrap/SKILL.md` runs it only on the prescription of a Mission, of an initiation order dated by the Owner, or of an Owner arbitration.
- **The target does not exist yet.** `create` refuses a folder that is already there: the script presumes nothing about how you organise your workspace.
- **Where it goes.** The target path is absolute, lies outside the Second Brain repository, and is not the workspace root itself. Walking up from its parent folder must reach the workspace marker `<workspace>/VAULT-ROOT.md`.
- **Tools.** `bash` and `uv` (every message of the script goes through `uv`). With Git: `git`, and `pre-commit` for the hook.
- **Three answers to prepare.** The display name; Git or not (`--vcs git` or `--vcs none`); the language. If neither the command nor an order says `--vcs`, the script asks `Track this project with Git? (git or none, default: none)`.

## Steps

1. **Get an initiation order, if no Mission covers the creation.** This command writes nothing. On a folder that does not exist, it prints the order pre-filled with `Type : create`, `Nom` (the folder name), `Emplacement` (the parent folder) and the identity of this Second Brain:

   ```bash
   bash <workspace>/second-brain/tools/project-bootstrap.sh order <workspace>/<project>
   ```

   In PowerShell, where `bash` is unknown: `& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/project-bootstrap.sh order <workspace>/<project>`.

   The Pilot chooses `Git` (`none` or `git`) and fills `Objet` (one sentence, copied into the project sheet and shown as `Purpose:` in the final block); the Owner writes `Autorisation Owner datée` verbatim with a `AAAA-MM-JJ` date (year-month-day). Three optional fields carry the project's profile — `Résultat attendu`, `Blocage actuel`, `Rythme de revue` —, which the Pilot asks one at a time before proposing the order ([The starting interview](starting-interview.md)); left out, nothing changes. The order is saved as a file, `<order-file>`. The field names stay in French: the script finds each one by its exact name followed by a colon ([the template](../../templates/initiation-order-template.md)). With an order, `Nom` is both the folder name and the display name. The order travels to the Executor in an `initiation` mini-prompt, whose source is the order itself ([relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)).

2. **Run the creation.** From an order:

   ```text
   sb new --order <order-file>
   ```

   _Not executed by the documentation check._

   Or directly, on a Mission:

   ```text
   sb new <workspace>/<project> "<Name>" --vcs git --lang EN
   ```

   _Not executed by the documentation check._

   | Option | Effect |
   |---|---|
   | `<target-path>` | absolute path of the new project folder |
   | `<display_name>` | required; quote it when it has spaces |
   | `--vcs none\|git` | Git or not; asked if absent. `none`: no repository, no hook, checks by command |
   | `--ask` | asks the folder name and the location before writing; Enter keeps the proposal. Then the three questions of the project profile (expected result, current blocker, review rhythm), Enter leaving one empty; `sb new <folder> "<Name>" --ask` does the same |
   | `--lang FR\|EN\|ES` | language of the script's messages, English by default; also accepted as a third positional argument |
   | `--order <order-file>` | takes every answer from a dated order; `Mode : ask` asks the name and location, `Mode : answered` asks nothing but Git, and Git only when `Git` is not `none` or `git` |
   | `--group <group>` | creates `<workspace>/<group>/<project>` instead of `<workspace>/<project>` (folders are flat by default); in an order, the optional field `Groupe`. Refused when the group is a project, carries `VAULT-ROOT.md` or is not a single folder name |

   The project's language (recorded in the Pilot prompt, and used for `CLAUDE.md`, `AGENTS.md` and the journal birth line) is read first from `<workspace>/second-brain/USER.local.yaml`, then from the `language:` field of `USER.md`; the language you name is used only when neither records one. The historical call without a subcommand, `project-bootstrap.sh <target-path> <display_name> [language]`, still means `create`: without `--vcs` it does not ask about Git and creates the repository, and it prints no final block. The installers use it.

3. **Consume the final block** to open the project's Pilot: create a Project with the name shown — always `SB - <display name>`, the name the Pilot checks at every opening ([rule on workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md) §5) —, paste the framed instructions as they are, give the project path as the first message, and expect the canary at opening. The README section [Open a project's Pilot](../../README.md#open-a-projects-pilot-desktop-application) walks through it. Lost the block? `sb pilot-prompt <workspace>/<project>` prints the Project's name, the block, the first message and the canary again, writing nothing.

4. **Check the identity card.** The folder, the registry row, the Pilot prompt and the README must agree; the card also names the Project to create:

   ```bash
   bash <workspace>/second-brain/tools/project-bootstrap.sh identity <workspace>/<project> --check
   ```

   _Not executed by the documentation check._ In PowerShell, where `bash` is unknown: `& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/project-bootstrap.sh identity <workspace>/<project> --check`. `sb doctor`, typed in the project folder, runs the same check on its `Project identity` line.

   The last line is `IDENTITY: CONCORDANT`, or `IDENTITY: <n> ANOMALY` after one `ANOMALY: …` line per mismatch. If you rename a project later, change its display name in the registry, then run `project-bootstrap.sh prompt <workspace>/<project>`: the Pilot prompt follows, its `project_id` and canary do not change, and you rename the Project in the application to `SB - <new name>`.

## What you should see

- With at least one profile answer (order or `--ask`): the line `Profil du projet écrit sous « ## Profil du projet » : <README>` in the report (in French; the English catalogue says `Project profile written under …`), the section in `<workspace>/<project>/README.md`, and the same fields under `## Profil du projet` of `state/STATE.md`. Without any: no such line, and the state sheet says « Aucun … (facultatif) »; the project conforms all the same.

The run may print notes first (link conflicts, no assistant to link, `Note: Git hook not installed ...`, and the one-time external import approval that Claude Code will ask for). Then comes the block to consume, and the last line is the path of the project sheet:

```text
To open this project's Pilot (Claude desktop app, or ChatGPT):
  1. Create a Project named "SB - <Name>".
  2. Paste this block as-is as the Project's instructions:
  ---
  <the common prompt, from templates/session-opening-prompt-template.md>
  ---
Project path: <project path>
Vault: <vault_id>, built at commit <vault_ref>
Canary: pp-<12 hexadecimal characters>
Purpose: <Objet of the order, or the display name>
  3. First message of every conversation: <project path>
  Canary expected at opening: pp-<...> (in <project path>/state/PILOT-PROMPT.md).
<workspace>/second-brain/projects/PROJECT-<project_id>.md
```

Written in the new project:

| File or folder | Content |
|---|---|
| `<project>/rules/`, `<project>/state/`, `<project>/missions/`, `<project>/decisions/`, `<project>/proposals/`, `<project>/knowledge/`, `<project>/handoffs/` | the skeleton of the seven functions (table below) |
| `<project>/README.md` | identity: display name, `project_id`, `status: ACTIVE`, creation date |
| `<project>/missions/MISSION-INDEX.md` | the Mission register, copied from `templates/mission-index-template.md` |
| `<project>/.pre-commit-config.yaml` | birth certificate (`vault_id`, `vault_origin`, `vault_ref`, `vcs`), then a `repo: local` pin on this Second Brain with four guardian hooks (`vault-check-secrets`, `vault-check-indexes-fresh`, `vault-check-index-weight`, `vault-check-links`) |
| `<project>/CLAUDE.md`, `<project>/AGENTS.md` | identical pointer files in the project's language, importing the method from the Second Brain `CLAUDE.md` |
| `<project>/state/PILOT-PROMPT.md` | Pilot prompt: canary, `state_path`, language, MCP server name, Vault commit. Generated; never edit it by hand (`project-bootstrap.sh prompt <folder>` regenerates it) |
| `<project>/state/journal.md` | journal, append-only, with the birth `STATE:` line |
| `<project>/state/STATE.md`, `<project>/state/DIGEST.md` | generated state sheet and digest (by `tools/build-state.sh` and `tools/build-digest.sh`) |
| `<project>/.gitignore` | a comment only: each link folder carries its own `.gitignore` naming its links, written before them (Mission 231) |
| `<project>/.claude/skills/`, `<project>/.agents/skills/`, `<project>/.claude/agents/` | links to the method skills, and to the assistant when this Second Brain names one; an item already at a link's place always wins |
| the first indexes | built by `tools/build-indexes.sh`, never by hand |
| `<project>/.git` | with `--vcs git` only: repository on branch `main`, a local Git identity if none resolves, and `pre-commit install` |

The Git identity set when none resolves is the local identity of the installed Second Brain, otherwise `Second Brain Installer`, `installer@example.invalid`.

Written in Second Brain: the Second Brain identity if it is still missing; the registry, created from `templates/project-registry-template.md` if absent; a row in the Active table of `projects/PROJECT-REGISTRY.md`, `| <project_id> | <Name> | ACTIVE | <relative_path> | <vcs> | <conformity> |`; and the sheet `<workspace>/second-brain/projects/PROJECT-<project_id>.md` with `bootstrap_mode: create`, and `initiation_order` when an order was used; and the Second Brain indexes, rebuilt by `tools/build-indexes.sh` together with the project's. The `project_id` is the date plus a code made of the first three words of the display name in capitals (`<YYYY-MM-DD>-<CODE>`). The `relative_path` is relative to the workspace folder that carries the marker. The conformity is measured by `tools/check-project-conformity.sh`, never guessed.

The seven functions, defined by the [project structure standard](../../rules/RULES-2026-08-26-142800-project-structure-standard.md):

| Function | Question | Location |
|---|---|---|
| Identity | what is this project? | `<project>/README.md` |
| Business rules | which laws apply here only? | `<project>/rules/` |
| State memory | where do we stand? | `<project>/state/` |
| Execution | what have we had done? | `<project>/missions/` |
| Arbitration | what have we decided? | `<project>/decisions/` |
| Material | what have we learned? | `<project>/knowledge/` |
| Handover | how do we resume? | `<project>/handoffs/` |

Pending options go in `<project>/proposals/`. Nothing else is created in advance. The fictional [book club example](../../templates/example-project-book-club/README.md) shows the layout with content; it is not a registered project. A rule that makes sense only for this project goes in its own `<project>/rules/`; a project never writes into Second Brain ([boundary rule](../../rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)).

## Known errors

Every refusal below exits with code 1.

| Message | Cause | What to do |
|---|---|---|
| `REFUS : chemin cible non absolu : <path>` | relative target | give the absolute path, `<workspace>/<project>` |
| `REFUS : chemin cible a l'interieur du depot Vault (<vault>) : <path>` | target inside the Second Brain repository | create the project outside it |
| `REPO-ROOT-REFUSED: <path> (<abs>) is a workspace root (it carries VAULT-ROOT.md); a project is created in its own folder below it, e.g. <abs>/<project>. Nothing written.` | target is the workspace root, or a folder holding two or more Git repositories | name a new folder below it |
| `REPO-ROOT-REFUSED: <path> (<abs>) is not a folder; ...` | target is an existing file | choose another path |
| `REFUS : la cible existe deja : <path>` | target folder already there | adopt it instead ([Adopt an existing folder](adopt-a-project.md)) |
| `REFUS : marqueur VAULT-ROOT.md introuvable en remontant depuis <parent>` | no workspace marker above the target | create the project inside the workspace |
| `REFUS : chemin deja inscrit au registre : <relative_path>` | the registry already has a row for this path | choose another path, or check the registry |
| `REFUS : fiche projet deja existante pour cet identifiant : <file>` | same date and same code from the display name | give another display name |
| `REFUS : impossible de deriver un code depuis display_name : <name>` | the display name has no letter A-Z or digit | use a name with Latin letters or digits |
| `REFUS : vcs doit valoir none ou git (lu : <value>)` | bad Git answer | answer `none` or `git` |
| `REFUS : option inconnue : <option>` or `REFUS : argument en trop : <arg>` | typo, or an unquoted name of three words or more (an unquoted two-word name is read as a name plus a language, without refusal) | quote `"<Name>"`, check the options |
| `REFUS : ordre d'initiation introuvable : <file>` | wrong order path | give the order file's path |
| `REFUS : ordre d'initiation sans autorisation Owner datée (AAAA-MM-JJ)` | no date in the authorization | the Owner dates it |
| `REFUS : l'ordre nomme le Vault <a>, ce Vault est <b>` | order written for another Second Brain | run it with the Second Brain it names, or redo the order |
| `REFUS : ordre d'initiation : Type doit valoir create ou adopt (lu : ...)` | bad `Type` | write `create` |
| `REFUS : ordre d'initiation : Mode doit valoir answered ou ask (lu : ...)` | bad `Mode` | write `answered` or `ask` |
| `REFUS : ordre d'initiation en mode answered sans Nom ou sans Emplacement` | field missing | fill `Nom` and `Emplacement` |
| `Note: Git hook not installed (pre-commit or repository not found) -- ...` | `pre-commit` or `git` missing | install it, then run `pre-commit install` in the project |

Without a target or a display name, the script prints its usage lines and exits with code 1.

## Scripts used

- `tools/project-bootstrap.sh` — creation, order, `prompt`: [project tools](../reference/tools-projects.md)
- `tools/repo_root_guard.py` — refuses a workspace root as target: [internal helpers](../reference/tools-internal-helpers.md)
- `tools/check-project-conformity.sh` — conformity written in the registry and the sheet: [project tools](../reference/tools-projects.md)
- `tools/build-indexes.sh` — first indexes: [index and link tools](../reference/tools-indexes-and-links.md)
- `tools/append-journal.sh`, `tools/build-state.sh`, `tools/build-digest.sh` — journal birth line, state sheet, digest: [state and journal tools](../reference/tools-state-and-journal.md)

## Liens

- `see also` — [The starting interview](starting-interview.md)

- `source` — [Project bootstrap script](../../tools/project-bootstrap.sh)
- `source` — [Skill: project-bootstrap](../../skills/project-bootstrap/SKILL.md)
- `source` — [Repository-root guard](../../tools/repo_root_guard.py)
- `source` — [Workspace marker lookup](../../tools/resolve-vault.sh)
- `source` — [Link helper, link-project](../../tools/sb_installer_helper.py)
- `source` — [English message catalogue](../../i18n/catalog.en.json)
- `source` — [Template: initiation order](../../templates/initiation-order-template.md)
- `source` — [Template: common Pilot prompt](../../templates/session-opening-prompt-template.md)
- `source` — [Template: Mission register](../../templates/mission-index-template.md)
- `source` — [Template: Project Registry](../../templates/project-registry-template.md)
- `source` — [Project Registry](../../projects/PROJECT-REGISTRY.md)
- `source` — [Project conformity check](../../tools/check-project-conformity.sh)
- `source` — [Index builder launcher](../../tools/build-indexes.sh)
- `source` — [Journal appender](../../tools/append-journal.sh)
- `source` — [State sheet builder](../../tools/build-state.sh)
- `source` — [Digest builder](../../tools/build-digest.sh)
- `source` — [Relay between roles, initiation type](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Project structure standard, seven functions](../../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- `source` — [Boundary between a project and Second Brain](../../rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [README: open a project's Pilot](../../README.md)
- `source` — [Example project: book club](../../templates/example-project-book-club/README.md)
- `see also` — [Adopt an existing folder](adopt-a-project.md)
- `see also` — [Bring a project into conformity](bring-a-project-into-conformity.md)
- `see also` — [First project, tutorial](../tutorials/first-project.md)
- `see also` — [Open a session](open-a-session.md)
- `see also` — [Project tools](../reference/tools-projects.md)
- `see also` — [Roles and Missions](../explanation/two-roles.md)
- `see also` — [Troubleshooting](troubleshoot.md)
- `see also` — [Product glossary](../../CONTEXT.md)
- `see also` — [Rule — Workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
- `see also` — [Start something new](start-something-new.md)
- `see also` — [Commands](../reference/commands.md)
