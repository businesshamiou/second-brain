---
type: context
title: "Second Brain — glossary"
description: "Glossary of the product's terms, validated in T18, in the CONTEXT.md format of the domain-modeling skill."
status: active
---

# Second Brain — glossary

The product's terms, as a user or an agent meets them in this repository. Validated by the Owner (DECISION, T18 of Mission 168), delivered here as is.

## Language

**Second Brain**:
The installed system — rules, methods, templates, skills, guardians — versioned in the `second-brain` repository.
_Avoid_: OS, framework.

**Vault**:
Internal name of Second Brain in the rules and the tools; the same thing.

**Workspace**:
The folder that contains `second-brain` and your projects, marked by `VAULT-ROOT.md`.
_Avoid_: root folder.

**Project**:
A work folder next to `second-brain`, entered in the registry, which inherits the method.

**Built skill**:
A skill written for Second Brain, in `skills/`.

**Adopted skill**:
A verified third-party skill, brought in through ingestion.
_Avoid_: plugin, extension.

**Warehouse**:
The library of adopted skills, `skills-warehouse/`.

**Assistant**:
Second Brain's agent, named by the user at installation; default proposed name: Brian. It guides the installation, then answers read-only.
_Avoid_: bot.

**Owner**:
You, who decide and who push.
_Avoid_: admin.

**Pilot**:
The session role that thinks, arbitrates and drafts, without executing; it runs in any Pilot host.

**Host**:
The software an agent runs in (the Claude desktop application, Claude Code, Codex, Gemini CLI…). A Pilot host has the Vault's MCP server and no shell; an Executor host has a shell. A host is not a role.
_Avoid_: calling a role by a product's name.

**Executor**:
The session role that executes, measures and commits, within the scope of a Mission (mode 1) or of an Owner's prompt traced by an execution Note (mode 2).

**Mission**:
The file that prescribes a piece of work to the Executor, frozen when issued.
_Avoid_: task, prompt.

**Decision**:
A recorded and dated choice that is authoritative.
_Avoid_: ADR.

**Guardian**:
An automatic check at commit, which refuses what violates a rule.
_Avoid_: hook, linter.

**Installation logbook**:
The trace that makes it possible to resume an interrupted installation.

## Sessions and commands

The terms of the sessions and of the command, as the tools and the guides use them ([Opening scenarios](./docs/how-to/opening-scenarios.md), [Use the sb command and its plugin](./docs/how-to/use-the-sb-command-and-plugin.md)).

**sb command**:
The one command of Second Brain: one English verb per operation, typed `sb <verb>` in a terminal, `/sb:<verb>` in Claude Code, `$sb <verb>` in Codex, or sent to the Pilot as a message that starts with `sb `.
_Avoid_: script, shortcut.

**sb plugin**:
The Claude Code plugin `sb@second-brain` that provides `/sb:<verb>`; Claude Code keeps a copy of it in its own cache, which `sb install` refreshes.

**Pilot Project**:
The instructions space where a project's Pilot works, named `SB - <display name>`: a Project, in the Claude desktop application; in another Pilot host, the block sent as the first message.

**Welcome Pilot**:
The Pilot `SB - Accueil`, tied to the Vault: it thinks about projects that do not exist yet and writes their initiation order.

**Initiation order**:
A form, dated by you, that lets an Executor create or adopt a project without a Mission.

**Starting interview**:
The Pilot's way of knowing you and a project: it reads the profile first and asks only what changed; without one, one question at a time, at least three; it shows the whole profile before anything is written.

**Starting profile**:
Your profile, under `## Profil de départ` of your `USER.md`: what you do, what matters to you, your three headaches, your review rhythm, your everyday tools.

**Project profile**:
A project's expected result, current blocker and review rhythm, under `## Profil du projet` of its `README.md`.

**Profile order**:
The form, dated by you, that the welcome Pilot files in `_orders/` and an Executor applies with `sb profile --order` to write your starting profile.

**Session type**:
Project, welcome, free or Vault, recognised by measurement before any gesture.

**Free session**:
A session with no project, no Mission and no order: it answers `READY (session libre)`, reads, and writes nothing.

**Verdict**:
The first line of every opening, `READY` or `NOT-READY (<reason>)`, with nothing before it.

**Entry scenario**:
One of the eleven ways a session can start, E1 to E11, each with its measured signs, its gesture and its verdict.

**State sheet**:
The generated summary of a project's state, in the project's state folder (or where its Pilot prompt's `state_path` says), read by the Pilot at opening.

**Declared temporary folder**:
The one folder, outside the workspace, where the tools put their throwaway files; the workspace marker names it.

## Note

« Atelier » ["workshop"] is absent from this glossary: this term does not exist for the user of Second Brain — see the [boundary rule between a project and Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md).

## Liens

- `see also` — [README](./README.md)
- `see also` — [Boundary rule between a project and Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
- `see also` — [Rule — The sb command surface](./rules/RULES-2026-09-26-200933-sb-command-surface.md)
- `see also` — [Rule — Workspace hygiene, project names and session types](./rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
- `see also` — [Opening scenarios](./docs/how-to/opening-scenarios.md)
- `see also` — [Decision — Two relay modes](./decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md) (the Executor's two modes)
