---
type: reference
title: "Skills"
description: "The skills Second Brain ships, how you invoke them, and how they are linked into each of your projects for Claude Code and Codex."
status: active
---

# SKILLS

This page tells you which skills Second Brain ships, how you call them, and how they reach Claude Code and Codex in your projects.

## What a skill is here

A skill is a folder holding a `SKILL.md` file in the Agent Skills format: a short front matter (`name`, `description`, `license`, `metadata`) followed by the instructions the agent follows ([skills index](../../skills/index.md)). The `description:` field matters: it is what your tool reads to decide when a skill applies, and it counts toward the Codex budget described below.

Second Brain ships two sets, both always deployed:

- the method's own skills, one folder each under `skills/`;
- a library of adopted third-party skills under `skills/external/`.

A third folder, `skills-warehouse/`, also holds skills, but the installer never deploys it (see the last section).

## The method's own skills

There are eight, one folder each under `skills/`. Two were renamed to English: `mission-writing` (formerly `ecriture-de-mission`) and `internal-search` (formerly `recherche-interne`); their French trigger phrases stay in their descriptions, and an update or `sb adopt` replaces a project's links under the former names ([Update](../how-to/update.md)). The purpose below is condensed from each `SKILL.md` `description:` field. Each operation also has one verb of the `sb` command ([Commands](./commands.md)); the skills below are what the agent applies behind the verb.

| Skill | What it does | Where it runs |
|---|---|---|
| [session-start](../../skills/session-start/SKILL.md) | Opens a work session: reads the state files in order and announces your role and readiness. Read-only. | Pilot and Executor |
| [session-close](../../skills/session-close/SKILL.md) | Closes a session: lists the holes, refuses to close while any remain, then produces the handoff (Pilot) or the closing commit (Executor). | Pilot and Executor |
| [first-install](../../skills/first-install/SKILL.md) | Installs Second Brain from Claude Code or Codex: asks the installer's nine prompts in the chat, writes an answers file, then runs `install.ps1` or `install.sh`. Also resumes or repairs a partial install. | Agent chat with a shell |
| [update](../../skills/update/SKILL.md) | Updates an installed Second Brain to a published version by merging it over your own commits, without reinstalling. | Executor only |
| [project-bootstrap](../../skills/project-bootstrap/SKILL.md) | Makes a project aware of the Vault: registers it, pins the guardians, installs the preflight hook, and proposes (never imposes) the seven-function layout. | Executor only |
| [internal-search](../../skills/internal-search/SKILL.md) | Searches the Vault and the project corpus by discipline: indexes and `description` fields first, then exact grep or glob, never an unmeasured path. Writes nothing. | Pilot and Executor |
| [mission-writing](../../skills/mission-writing/SKILL.md) | Drafts a Mission file and its Executor mini-prompt from the template, with measured links and a mandatory Context section; reads the two profiles first. | Pilot only |
| [starting-interview](../../skills/starting-interview/SKILL.md) | The starting interview: reads your profile or a project's first, shows it, asks only what changed, one question at a time, and files an order — never the profile itself ([The starting interview](../how-to/starting-interview.md)). | Pilot (welcome, or a project to adopt) |
| [sb](../../skills/sb/SKILL.md) | The router of the `sb` command for agents that load skills: a message that starts with `sb ` is run as `sb <verb>`, then the verb's card is applied. One skill for every verb, because of the Codex budget below. | Pilot and Executor |

"Pilot" and "Executor" are the two roles of a session; [Roles and Missions](../explanation/two-roles.md) explains them.

## How you invoke them

- **The `sb` command.** The first way in: `sb <verb>` in a terminal, `/sb:<verb>` in Claude Code once the plugin `sb` is installed (`skills/claude-plugins/`, marketplace `second-brain`: `claude plugin marketplace add <Vault>/skills/claude-plugins`, then `claude plugin install sb@second-brain`, which `sb install` runs for you), `$sb <verb>` in Codex. Claude Code keeps a copy of the plugin in its cache, which falls behind when the Vault's plugin changes: `sb doctor` reports it and `sb install` reinstalls it ([Use the sb command and its plugin](../how-to/use-the-sb-command-and-plugin.md)). See [Commands](./commands.md).
- **Slash command.** In Claude Code, type `/<name>`, for example `/session-start`. The [README](../../README.md) shows `/first-install` run "from Claude Code or Codex" alike, and [session-close](../../skills/session-close/SKILL.md) names `/session-close` as its fixed command on the Executor surface.
- **Trigger phrases.** Each `description:` ends with the phrases that should wake the skill, in French and English: « nouvelle session » or "open the session" for session-start, « wrap » or "close" for session-close, « où est » or "where is" for internal-search, "update second-brain" for update, and so on. Your tool matches these against what you type.
- **Only on your word.** session-close is never triggered on its own: you launch it. project-bootstrap runs only when a Mission, a dated initiation order or an Owner arbitration calls for it, because adopting writes into the Vault's registry.

The `SKILL.md` files do not give a Codex-specific syntax beyond this; if in doubt, use the trigger phrase.

## Adopted third-party skills

`skills/external/` holds **40** third-party skills (40 folders, each with a `SKILL.md`; the [skills index](../../skills/index.md) describes the library). They cover engineering and writing workflows (for example `tdd`, `code-review`, `grill-me`, `handoff`) and a few visual ones.

Where they come from and under which licence:

- [PROVENANCE.md](../../skills/external/PROVENANCE.md) records the origin: a package built by the `skills-warehouse` project, installed in September 2026, which grew the library from 38 to 40 skills. Each skill carries at most the six standard fields, with its provenance under `metadata:`. The folder holds third-party material only, never the Vault's own skills.
- [OWNER-EXCEPTIONS.md](../../skills/external/OWNER-EXCEPTIONS.md) lists the three exceptions to the default permissive-licence policy: `excalidraw-automate` kept under `AGPL-3.0-only`, and `script-to-whiteboard-storyboard` and `scroll-film-studio` kept under `NOASSERTION`. `NOASSERTION` means no licence could be established; it is not a permission to redistribute.
- [THIRD-PARTY-LICENSES.md](../../THIRD-PARTY-LICENSES.md) is a generated table (skill, licence, source, evidence, decision) grouped by warehouse collection. Many entries are MIT skills from one upstream repository, whose licence text is kept in [LICENSE-mattpocock-skills.txt](../../skills/external/LICENSE-mattpocock-skills.txt). Second Brain itself is under the MIT [LICENSE](../../LICENSE).

## How skills reach your tools

Skills are **linked, never copied**, and **never placed in your profile** ([deploy-skills.ps1](../../tools/deploy-skills.ps1) header; [README, "What is installed, and where"](../../README.md)):

- Each project gets links in `<project>/.claude/skills/` (Claude Code) and `<project>/.agents/skills/` (Codex), set up when the project is created or adopted by [project-bootstrap.sh](../../tools/project-bootstrap.sh).
- Nothing goes into the `.claude`, `.agents` or `.codex` folders of your account. Deleting a project, or the whole workspace, removes everything with no separate cleanup.
- On Windows a link is an NTFS junction, which needs no administrator rights and no Developer Mode; elsewhere it is a symbolic link.
- Because it is a link, a fix made in the clone's `skills/<name>/` reaches every project at once, with no reinstall.
- A second run changes nothing. An existing link to the same source is left as is. Anything else already at that path is left alone and reported as a conflict, never overwritten or deleted.
- The links are kept out of the project's Git history by a `.gitignore` in each of the three folders (`<project>/.claude/skills/.gitignore`, `<project>/.agents/skills/.gitignore`, `<project>/.claude/agents/.gitignore`) that names them one by one; `link-project` writes it before any link of its folder and rewrites it on each run (Mission 231). A skill you install for the project in those folders is tracked as usual. The project's own `.gitignore` no longer carries the folder-wide lines `/.claude/skills/`, `/.claude/agents/`, `/.agents/skills/`, which hid those skills: adoption reports them when an existing file has them, and leaves the file as it is. A `.gitignore` of your own in one of the three folders is never overwritten: that folder then gets no link, and adoption says so.

A project not created this way has no links; run `first-install` or `project-bootstrap` on it to get them ([Create a project](../how-to/create-a-project.md)).

## The Codex description budget

Codex has a measured ceiling of about 8000 characters on its initial skills list. The deployment adds up the length of the `description:` field of every skill in `skills/` **and** `skills/external/` and compares it with that ceiling, set to `8000` in [deploy-skills.ps1](../../tools/deploy-skills.ps1) and in [sb_installer_helper.py](../../tools/sb_installer_helper.py), whose `link-project` step places a project's links for `project-bootstrap.sh`:

- **At or under 8000 characters:** Claude Code and Codex both receive both sets.
- **Over 8000 characters:** Codex receives `skills/` alone, while Claude Code still receives everything. This is never a stop and never an error; `project-bootstrap.sh` prints a notice that the fallback was applied.

The script's header records a measurement of 7451 characters on 2026-09-12; on 2026-09-26 (Mission 236) the total was 7,957 before the `sb` router, 7,898 after it, the descriptions of `mission-writing` and `internal-search` having been shortened; on 2026-09-27 (Mission 240) 7,994 with `starting-interview` — six characters left. `sb doctor` shows the current total. Keep descriptions short when you edit a `SKILL.md`: every character counts toward this total.

## The skills warehouse

`skills-warehouse/` is a separate, canonical warehouse for Agent Skills: it gathers skills from many sources, deduplicates them, keeps their provenance, and produces validated archives ([warehouse README](../../skills-warehouse/README.md)). Its active skills live in `skills-warehouse/skill-collections/`, in three collections: software-engineering, web-design and visual-content.

The installer **never deploys it**. [deploy-skills.ps1](../../tools/deploy-skills.ps1) reads only `skills/` and `skills/external/`, and [first-install](../../skills/first-install/SKILL.md) states the same. The rest of the warehouse is delivered as zip packages that you install by hand if you want them.

## Liens

- `source` — [Vault skills index](../../skills/index.md)
- `source` — [session-start skill](../../skills/session-start/SKILL.md)
- `source` — [session-close skill](../../skills/session-close/SKILL.md)
- `source` — [first-install skill](../../skills/first-install/SKILL.md)
- `source` — [update skill](../../skills/update/SKILL.md)
- `source` — [project-bootstrap skill](../../skills/project-bootstrap/SKILL.md)
- `source` — [internal-search skill](../../skills/internal-search/SKILL.md)
- `source` — [mission-writing skill](../../skills/mission-writing/SKILL.md)
- `source` — [External skills index](../../skills/external/index.md)
- `source` — [Provenance of the external skills library](../../skills/external/PROVENANCE.md)
- `source` — [Owner exceptions to the licence policy](../../skills/external/OWNER-EXCEPTIONS.md)
- `source` — [Third-party licences](../../THIRD-PARTY-LICENSES.md)
- `source` — [Skill deployment by link](../../tools/deploy-skills.ps1)
- `source` — [Project bootstrap script](../../tools/project-bootstrap.sh)
- `source` — [Installer helper, link-project step](../../tools/sb_installer_helper.py)
- `source` — [README, "What is installed, and where"](../../README.md)
- `source` — [Skills warehouse README](../../skills-warehouse/README.md)
- `see also` — [Architecture](../explanation/architecture.md)
- `see also` — [Open a session](../how-to/open-a-session.md)
- `see also` — [Create a project](../how-to/create-a-project.md)
- `see also` — [Roles and Missions](../explanation/two-roles.md)
- `see also` — [Guardians and tests](../explanation/guardians.md)
- `see also` — [Update](../how-to/update.md)
- `see also` — [The assistant](../explanation/assistant.md)
- `see also` — [Troubleshoot](../how-to/troubleshoot.md)
- `see also` — [Publish a version](../how-to/publish.md)
- `see also` — [Domain vocabulary](../../CONTEXT.md)
- `source` — [sb skill](../../skills/sb/SKILL.md)
- `see also` — [Commands](./commands.md)
- `see also` — [Use the sb command and its plugin](../how-to/use-the-sb-command-and-plugin.md)
