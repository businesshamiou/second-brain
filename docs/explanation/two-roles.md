---
type: explanation
title: "Roles and Missions"
description: "How work is shared between the Owner, the Pilot and the Executor, and how a piece of work travels from a Mission or an Owner prompt to a report, a journal line and the state sheet."
status: active
---

# ROLES AND MISSIONS

This page explains who does what in Second Brain, how a session knows its role, and which files carry a piece of work from the request to the proof.

## Three participants

Work is split between one human and two session roles. Every session holds a single role, never both ([role charter](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)).

| | Owner | Pilot | Executor |
|---|---|---|---|
| Who | you, the human | an AI session | an AI session |
| Job | decide, arbitrate, push | think, arbitrate with you, write Missions | measure, execute, prove |
| Shell | yours | none | yes |
| Where | anywhere | the Claude desktop application, with disk access through the Second Brain MCP server, bounded to your workspace ([README](../../README.md)) | Claude Code or Codex, in a folder of your workspace |

- The **Pilot** never measures the technical state itself: it has it measured. It writes its own new files (Missions, Decisions, captures) at their canonical place, announces each filing beforehand, and never modifies an existing canonical file without your explicit arbitration. It never runs `git add`, `commit` or `push`, never deletes, and never runs a script that changes state. It proposes; it does not decide.
- The **Executor** works only within the scope it was given, commits file by file after inspecting each diff, and marks every inconsistency it meets as `ANOMALY` instead of silently correcting it. It never decides the architecture.
- **You** are the only channel between the two windows: you paste the Pilot's mini-prompt into the Executor window, and paste the Executor's RELAY block back into the Pilot window ([relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)).

## How a session determines its role

At opening, a session climbs three rungs, in this order:

1. **Startup hook (binding).** If the environment runs a `SessionStart` hook that injects a role, that role prevails, without discussion.
2. **Capability probe.** Otherwise the session asks itself one question: *can I execute a shell command?* Yes means `executor`, no means `pilot`. The Executor also has `git` and a current directory; the Pilot has neither and reaches files only through the MCP server.
3. **Declaration.** The mini-prompt's title line, `Session Executor — Mission <NNN>`, confirms the role. It never proves it on its own.

If two rungs contradict each other, the session stops and asks you. If a doubt remains, the least powerful role, `pilot`, is presumed: a Pilot that believes it is the Executor would commit wrongly, while an Executor that believes it is the Pilot merely asks for permission. The role is announced in the first message as `[role: <rôle> · <type PIV> · <session>]`, so you can correct it with one word.

## What a Mission is and where it lives

A Mission is the file that prescribes a piece of work to the Executor, frozen once issued ([glossary](../../CONTEXT.md)). It is written by the Pilot from the [Mission template](../../templates/mission-template.md). Its sections include a measured existing state, a mandatory Context, the Objective, the Scope with an explicit out-of-scope, Preconditions, Steps, Gates, Validations with before/after figures, an Exit contract and a Resume contract.

A Mission lives in the project, in `<project>/missions/`, named `MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md` ([mission-writing skill](../../skills/mission-writing/SKILL.md), §6). The Vault itself carries no missions folder: Missions are project files, like the example in `templates/example-project-book-club/missions/`. Its `status` field freezes the authorization at creation; the execution state lives only in `<project>/missions/MISSION-INDEX.md` ([Mission template](../../templates/mission-template.md), [Mission versioning rule](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)). An executed Mission is never edited: a correction is a new `Cxx` Mission with the same number.

A Mission never contains a "delete" step. It either prescribes "move to `_trash/`" as an agent step, with a fingerprint before and after, or lists "deletion by the Owner" as a human gate outside the steps.

## The mini-prompt going out

The Pilot hands a Mission over as a mini-prompt, delivered as one code block you copy in a single gesture, never as a file. It has five fixed rubrics, in this order. Their labels are French literals, glossed here:

1. Title line: `Session Executor — Mission <NNN> (<description courte>)` (short description).
2. « Position »: free; the Executor establishes where it is on its own.
3. « Source à appliquer » (source to apply): the path of the Mission file, read and applied in full.
4. « Interdits absolus » (absolute prohibitions): always no non-delegated push, no model call, no deletion, move to `_trash/` only on the Mission's prescription, plus whatever the Mission's Gates and Constraints add.
5. « Sortie attendue » (expected output): end the window with the RELAY block, filled in.

The mini-prompt never repeats the Mission's content, and never asserts that an Owner gesture (a push, a deletion) has happened: it asks the Executor to measure it and stop if it is absent.

## The RELAY block coming back

The Executor files a report, then ends its window with a RELAY block, also as one copyable code block:

```text
RELAY <NNN>
Rapport   : <chemin du fichier REPORT déposé>
Verdict   : <FAIT | PARTIEL | BLOQUÉ> + une ligne
Critères  : <n>/<total> PASS
Commits   : <dépôt> <hash> · <dépôt> <hash>
Poussées  : <dépôt> <avant>..<après> · <étiquette> | aucune
Résumé    : <cinq lignes>
À trancher: <une ligne, ou « rien »>
```

The labels mean: `Rapport` report path, `Verdict` done, partial or blocked, `Critères` criteria passed, `Poussées` pushes, `Résumé` summary, `À trancher` what you must decide. `Poussées` states what was actually pushed, measured with `git ls-remote`. `Résumé` is capped at five lines of facts with figures, and lists every deviation from the Mission, even minor. The Pilot resumes from this block and reopens the full report only when the verdict or `À trancher` requires it.

## Two relay modes

The [two relay modes Decision](../../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md) defines how work reaches the Executor:

- **Mode 1, the Mission.** The Pilot writes it, the mini-prompt leads to it, the Executor applies it.
- **Mode 2, your own prompt.** You speak to the Executor directly, either by pasting a prompt as is (**2a**) or by saying "read <files> and execute" (**2b**). No Mission is written. The Executor's **first write** is an execution Note, `<project>/missions/NOTE-<YYYY-MM-DD-HHMMSS>-<slug>.md`, recording `origin: owner-prompt`, the mode, `received_at` (the real time the prompt arrived), your prompt verbatim with its sha256 (2a) or each consumed file with its sha256 (2b), and the scope. `tools/check-work-regime.sh note` must accept that Note before the gesture. The RELAY block is the same, headed `RELAY NOTE-<YYYY-MM-DD-HHMMSS>`, and the report goes to `<project>/reports/`.

The absence of a Mission is never a reason for the Executor to refuse. Its refusal reasons form a closed list: a gesture reserved to you, an ambiguous irreversible action, an exposed secret, a gesture out of scope, or a full-regime criterion you have not lifted. In that last case it does not refuse: it names the criterion and asks for your go-ahead. In the Vault itself, mode 2 covers non-structuring changes only; a rule, a Decision or a template still needs a Decision and a Mission.

## Two work regimes

The Mission costs the same whatever the gesture is worth, so a lighter form sits beside it ([two work regimes rule](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)). The choice is made by a command, not by judgement.

| | Light regime | Full regime |
|---|---|---|
| Form | an execution Note: six rubrics (Intent, Scope, Measure before, Gesture, Measure after, Journal line), at most 4000 characters ([template](../../templates/execution-note-template.md)) | a Mission, its report and its relay |
| Trace | one journal line, no row in the Mission register | register row, report, journal |
| Proofs | kept: a measure before and after | kept |

`tools/check-work-regime.sh note <file>` answers `REGIME-LIGHT-OK` or `REFUSED <criteria>`; it refuses, it never merely warns. The full regime is compulsory as soon as one criterion is true: `R1-egress` (leaving the workstation other than a plain push or fetch to `origin`), `R2-destructive` (deleting, moving out of the repository, rewriting history), `R3-doctrine` (a Decision, rule or template), `R4-refs` (remotes, branches, tags, worktrees), `R5-company` (the company repository), `R6-guardians` (a guardian, hook or the publication tool). `R7-shape` and `R8-origin` check the Note's own form. Only your own answer lifts a criterion: the Executor quotes it word for word in an `owner_greenlight` block of the Note.

## Decisions

A Decision is a recorded, dated, authoritative choice. The Pilot drafts it from the [Decision template](../../templates/decision-template.md) at status `PROPOSED` with `owner_gate: required`. It becomes `ARBITRATED` only after an explicit human gate: your answer, quoted with its reference. No proposal is ever silently turned into a decision ([AGENTS.md](../../AGENTS.md)).

## Reports

Every Executor execution report is a file in the current project, in `<project>/reports/`; in the chat, the Executor gives two lines: the report's path and the gates line. The [report template](../../templates/report-template.md) covers gates, files created and modified, commits, impact on the installation, the final measured state, deviations, a final remeasurement, and the RELAY block, filled in last.

## The journal and the state sheet

Each project keeps an append-only journal, `<project>/state/journal.md`. You never edit it by hand: `tools/append-journal.sh <project-path> "<text>"` adds a timestamped line at the end, never rewrites an existing one, and refuses any text over 300 characters. Lines start with a tag:

- `STATE:` the current state (the last one wins);
- `OPEN:<key> -- <text>` opens a door, a pending question or follow-up, with a key such as `open-…`;
- `CLOSE:<key> -- <reference>` closes that door.

From the journal, `tools/build-state.sh` generates the state sheet `<project>/state/STATE.md`, and `tools/build-digest.sh` its capped extract `<project>/state/DIGEST.md`, which the Pilot reads first at opening. Neither is ever edited by hand: append a journal line, then regenerate.

## Gestures reserved to you

Two gestures are yours alone ([AGENTS.md](../../AGENTS.md)):

- **Push.** You may delegate it to an Executor window by a clear expression that names the gesture and its target (the `main` branch of the repositories concerned, and separately a named tag); no formula is required. The Executor checks the expression is there and what it covers; without it, it does not push. A push of a branch always goes through `tools/verified-push.sh`, with the absolute path of the repository and the exact range `<from>..<to>`, never a bare `git push` ([verified pushes rule](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)).
- **Permanent deletion.** No agent deletes a file, even with a granted human gate: the environment's policy refuses it and cannot be worked around. The substitute is to move the file to `_trash/` at the root of the workspace, outside the repositories, with a fingerprint before and after; you alone empty it ([deletion Decision](../../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)).

A structuring rename, a sensitive sharing or a change of source of truth also needs a human gate. Closing a session is your gesture too: the Pilot prepares the pieces, you declare it done.

## The mission-writing skill

The Pilot writes Missions with the [mission-writing skill](../../skills/mission-writing/SKILL.md). It first runs the regime check: if the gesture fits a Note, no Mission is written. Otherwise it reads the template at the moment of writing, gathers a context in which every fact is dated and marked measured, declared or hypothesis, cross-checks each Validation against the Gates and Constraints, runs `skills/mission-writing/mission-checklist.md`, files the Mission through a `DRAFT-` file renamed with its measured timestamp, and produces the five-rubric mini-prompt. It executes nothing and never decides the architecture in your place.

## Liens

- `source` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `source` — [Relay between roles through mini-prompts](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Two work regimes: the light Note and the full Mission](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)
- `source` — [Decision — Two relay modes](../../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md)
- `source` — [Decision — Permanent deletion is an Owner gesture](../../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
- `source` — [Decision — State sheet, one name, generated](../../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md)
- `source` — [Versioning of Missions and generated outputs](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `source` — [Mission template](../../templates/mission-template.md)
- `source` — [Execution Note template](../../templates/execution-note-template.md)
- `source` — [Decision template](../../templates/decision-template.md)
- `source` — [Report template](../../templates/report-template.md)
- `source` — [Skill: writing a Mission](../../skills/mission-writing/SKILL.md)
- `source` — [Instructions for agents](../../AGENTS.md)
- `source` — [README](../../README.md)
- `source` — [Project operating model V2](../../knowledge/BRIEF-2026-08-17-211522-project-operating-model-v2.md)
- `source` — [Journal append tool](../../tools/append-journal.sh)
- `source` — [State sheet generator](../../tools/build-state.sh)
- `source` — [Work-regime check](../../tools/check-work-regime.sh)
- `source` — [Digest generator](../../tools/build-digest.sh)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Verified push tool](../../tools/verified-push.sh)
- `see also` — [Architecture](architecture.md)
- `see also` — [Open a session](../how-to/open-a-session.md)
- `see also` — [Create a project](../how-to/create-a-project.md)
- `see also` — [Skills](../reference/skills.md)
- `see also` — [Guardians and tests](guardians.md)
- `see also` — [Update](../how-to/update.md)
- `see also` — [Uninstall](../how-to/uninstall.md)
- `see also` — [The assistant](assistant.md)
- `see also` — [Troubleshoot](../how-to/troubleshoot.md)
- `see also` — [Publish a version](../how-to/publish.md)
- `see also` — [Delegate and push](../how-to/delegate-and-push.md)
- `see also` — [Glossary](../../CONTEXT.md)
