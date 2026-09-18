---
type: project-readme
title: "Les Pages Suspendues — example project"
description: "Fictional project, invented for this repository, illustrating the seven-function skeleton of a Second Brain project."
status: active
---

# LES PAGES SUSPENDUES

**This is an example project, entirely invented for the Second Brain documentation.** Nothing here comes from a real project: "Les Pages Suspendues" ["The Suspended Pages"] is an imaginary neighbourhood book club, chosen as a neutral theme to illustrate, with concrete rather than abstract content, the [seven-function skeleton](../../rules/RULES-2026-08-26-142800-project-structure-standard.md) that `tools/project-bootstrap.sh` lays down for each of your own projects.

This folder is **not** a real project: it is not entered in the [project registry](../../projects/PROJECT-REGISTRY.md), which stays empty until you have created yours. To start a real project, use the `project-bootstrap` skill — see the [boundary rule between a project and Second Brain](../../rules/RULES-2026-09-11-190000-project-second-brain-boundary.md).

## Who

Les Pages Suspendues is a fictional book club of about ten members, who meet once a month to discuss a book chosen together.

## The seven functions, in this example

| Function | Folder | What it contains here |
|---|---|---|
| Identity | this file | who this club is, in two sentences |
| Business rules | [rules/](./rules/) | how the club chooses its book of the month |
| State memory | `state/` | the club's journal (not tracked as a document, see its own note) |
| Execution | [missions/](./missions/) | the organization of a meeting |
| Arbitration | [decisions/](./decisions/) | a settled choice (alternating genres) |
| Material | [knowledge/](./knowledge/) | notes taken after a meeting |
| Handover | [handoffs/](./handoffs/) | passing the facilitation from one month to the next |

## Writing

In a real project, `CLAUDE.md` and `AGENTS.md` (laid down by `tools/project-bootstrap.sh`, absent from this documentary example) carry the same rule: every change starts from a Mission written in `missions/`, the project's assistant is read-only, and the agent that opens the project writes nothing on its own initiative outside this frame.

## Liens

- `see also` — [Project structure standard](../../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- `see also` — [Boundary rule between a project and Second Brain](../../rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
- `see also` — [Project registry](../../projects/PROJECT-REGISTRY.md)
