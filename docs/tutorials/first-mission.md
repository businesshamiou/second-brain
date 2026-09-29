---
type: tutorial
title: "Your first Mission"
description: "Run one small Mission end to end on your first project: the Pilot writes it and hands you a mini-prompt, the Executor carries it out and returns a RELAY block, and the session is closed."
status: active
---

# YOUR FIRST MISSION

This tutorial takes you through one full round trip on your first project. You ask the Pilot for a small Mission. You carry its mini-prompt to an Executor window. The Executor does the work and hands back a `RELAY` block. You carry that block back to the Pilot, then you close the session. At each step you see what appears on screen.

You are the only link between the two windows. You paste the mini-prompt on the way out and the `RELAY` block on the way back ([relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md), "Bridge").

In the commands, `<workspace>` is the absolute path of your workspace (for example `C:/Users/you/Workspaces` or `/Users/you/Workspaces`). The installed Vault is `<workspace>/second-brain`, and your project is `<workspace>/<project>`.

## Before you start

- Your first project exists and is adopted (see [Your first project](first-project.md)). It has a `<project>/missions/` folder and a `<project>/missions/MISSION-INDEX.md` register.
- Two windows are open on it, both with a `READY` verdict on their first line (see [Open a session](../how-to/open-a-session.md)):
  - the **Pilot**, in the Claude desktop application;
  - the **Executor**, in Claude Code or Codex, opened in `<workspace>/<project>`.
- One small thing you want done, in one or two sentences.

## The round trip at a glance

| Step | Window | You do | You see |
|---|---|---|---|
| 1 | Pilot | Ask for the Mission | A question for your agreement, then a Mission file |
| 2 | Pilot | Copy the mini-prompt | One code block with five rubrics |
| 3 | Executor | Paste the mini-prompt | Measurements, commits, a report, then a `RELAY` block |
| 4 | Pilot | Paste the `RELAY` block | The Pilot resumes from the block |
| 5 | Both | Say `wrap` | A handoff, a closing command, the Executor's closing `RELAY` |

## Step 1. Ask the Pilot for a small Mission

In the Pilot window, say « écris la Mission » or "write the Mission", then describe what you want and give your authorization in your own words. This starts the `mission-writing` skill ([skill](../../skills/mission-writing/SKILL.md)). The Pilot will quote your words verbatim, with their date, in the Mission's `## Gates`.

What the Pilot does:

1. **The regime is chosen by a check, not by judgement.** Your gesture is first written as a light execution Note, which `tools/check-work-regime.sh note` checks. This check runs in a shell with Bash (Git Bash on Windows). If the last line is `REGIME-LIGHT-OK`, no Mission is needed and the skill stops there. If it is `REFUSED <id>[,<id>...]`, a full Mission is required and the Pilot goes on ([Write a Mission](../how-to/write-a-mission.md), step 1).
2. **It opens the template now**, never from memory: `templates/mission-template.md`.
3. **It measures before writing.** Each fact carries a date and a status, `MESURÉ` (measured), `DECLARED` or `HYPOTHÈSE` (hypothesis). Each file name it cites comes from a search or a listing.
4. **It fills the rubrics in the template's order:** `## Measured existing state`, `## Context`, `## Objective`, `## Scope` (with an explicit "Out of scope"), `## Preconditions`, `## Sources`, `## Applicable decisions`, `## Constraints`, `## Prior measurements`, `## Fan-out` (optional), `## Steps`, `## Gates`, `## Validations`, `## Exit contract`, `## Resume contract`, `## Doors`, `## Liens`.
5. **It cross-checks** that each count of `## Validations` can be reached without breaking a prohibition of `## Gates` or `## Constraints`, then runs `skills/mission-writing/mission-checklist.md` line by line. A failing line means no filing.
6. **It asks for your agreement just before writing.** No file is filed without your explicit agreement ([Pilot contract](../../templates/pilot-contract-template.md), line 1). Answer yes.
7. **It files the Mission** through a draft: `<project>/missions/DRAFT-<slug>.md`, then the final name with its measured timestamp.

What you should see: one new file, `<project>/missions/MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md`, and no `DRAFT-` file left. Its front matter says `status: AUTHORIZED`. That field freezes your authorization and is never touched again. The execution state lives in the `Statut` column of `<project>/missions/MISSION-INDEX.md`.

To see the shape of a Mission before your own is written, open the example project's Mission: [Organize the October meeting](../../templates/example-project-book-club/missions/MISSION-2026-09-11-193500-organize-the-october-meeting.md) (`mission_id: "EX-01"`). It belongs to Les Pages Suspendues, a book club invented for this documentation. It keeps only `## Objective` and `## Steps`. Your real Mission carries all the rubrics above. The example is there to be read, not executed.

## Step 2. Copy the mini-prompt

The Pilot ends with the mini-prompt, one code block you copy in one gesture. There is no PROMPT file to open. It has five fixed rubrics, in this order, and it does not repeat the Mission's content ([relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md), "Outbound"):

| # | Rubric | What it holds |
|---|---|---|
| 1 | Title line | `Session Executor — Mission <NNN> (<description courte>)`: it names the session |
| 2 | « Position » | Free: the Executor establishes its own position |
| 3 | « Source à appliquer » (source to apply) | The Mission's path, to be read and applied in full |
| 4 | « Interdits absolus » (absolute prohibitions) | The four standard prohibitions, plus a pointer to the Mission's `## Gates` and `## Constraints` |
| 5 | « Sortie attendue » (expected output) | End the window with the filled-in `RELAY` block |

The four standard prohibitions are always the same: no push that you have not delegated, no model call, no deletion, and a move to `_trash/` only when the Mission prescribes it. The Pilot never adds a prohibition of its own there ([skill, §7](../../skills/mission-writing/SKILL.md)). For the book-club example, the title line would read `Session Executor — Mission EX-01 (<description courte>)`.

What you should see: exactly one code block in the Pilot's answer. Use the copy button of the block.

## Step 3. Paste the mini-prompt into the Executor window

Paste the block into the Executor window and send it. You do not type anything else. The Executor now works on its own ([Run a Mission as Executor](../how-to/run-a-mission-as-executor.md)).

What the Executor does, and what scrolls past:

1. **It announces its role**, for example `[role: executor · implement · open]`. It then measures its position and pastes `git status -sb` for the Vault and for your project. `NOT-READY` on the first line means no gesture for the whole window ([session-start skill, §4](../../skills/session-start/SKILL.md)).
2. **It reads the Mission in full**, the file named by « Source à appliquer ». That Mission is its only source of instructions.
3. **It measures each line of `## Preconditions`.** At the slightest non-trivial gap it stops, reports and writes nothing.
4. **It works inside `## Scope` only**, following `## Steps` in order. Every write goes through the Vault's tools, with the absolute path of your project.
5. **It commits through the guardians.** It stages each file by its explicit path, reads the staged diff, then commits. The commit runs the guardians. If a guardian refuses, the Executor stops and quotes the refusal word for word; it never looks for a workaround ([React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)).
6. **It updates the state.** It appends lines to `<project>/state/journal.md` through `tools/append-journal.sh`, regenerates the state sheet, the digest and the indexes, and updates the Mission's row in `<project>/missions/MISSION-INDEX.md`.
7. **It writes the report**, `<project>/reports/REPORT-<AAAA-MM-JJ>-<HHMMSS>-<mission_id>-<slug>.md`, from the [report template](../../templates/report-template.md). Its sections are `## 1. Gates`, `## 2. Files created and modified`, `## 3. Commits`, `## 4. Impact on the installation`, `## 5. Final state measured`, `## 6. Deviations`, `## 7. Final remeasurement, stop`, then `## RELAY block`. No `<…>` placeholder may remain in a final report.

What you should see at the end of the window: two lines, the report's path and the gates line ([AGENTS.md](../../AGENTS.md)), then one code block that starts with `RELAY <NNN>`. That block is the last thing on screen.

What the block holds, and in which order, is set in one place only, [rule 124937](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md), "Return". Every other document points to it and restates neither its rubrics nor its length ([Decision 201623](../../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md), part B1), so this tutorial does not copy it.

## Step 4. Paste the RELAY block back into the Pilot

Copy the block with the copy button and paste it, as is, into the Pilot window. If the Executor gave it as prose or split it up, ask it to render it again as one code block. You never reassemble it by hand ([Read a RELAY block](../how-to/read-a-relay.md)).

Read the verdict first:

| Verdict | Meaning | What happens next |
|---|---|---|
| `FAIT` | Done | The Pilot resumes on the strength of the block. |
| `PARTIEL` | Partial | The verdict's line says why. The Mission's `## Resume contract` gives the last healthy commit and where the next window resumes. |
| `BLOQUÉ` | Blocked | The verdict's line and « À trancher » say what stopped the work. If a gesture reserved to you blocked it, « À trancher » names the exact path and the substitute (a move to `_trash/`). |

The Pilot reopens the full report only when the verdict or « À trancher » requires it.

On a first Mission, the pushes rubric usually reads `aucune` (none). That is normal: a push is your gesture, delegated only by a clear sentence of yours that names the gesture and its target. You can check what the remote holds yourself, read-only:

```bash
git -C <workspace>/<project> ls-remote origin refs/heads/main
```

If you do delegate a push, the Executor makes it only through the verified push, with the exact range ([Delegate and push](../how-to/delegate-and-push.md)):

```bash
bash <workspace>/second-brain/tools/verified-push.sh <workspace>/<project> <from>..<to> [<remote>] [--url <url>]
```

_Not executed by the documentation check._ The same push from the `sb` command, when the remote is `origin` and needs no `--url`: `sb push <workspace>/<project> <from>..<to>` (add `--dry-run` to check only). Otherwise, in PowerShell, where `bash` is unknown: `& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/verified-push.sh …`.

## Step 5. Close the session

In the Pilot window, say `wrap` (or `close`, « on ferme »). This starts the `session-close` skill ([skill](../../skills/session-close/SKILL.md)). It never starts on its own.

What the Pilot does:

1. It runs `skills/session-close/closing-checklist.md`, line by line, and names that file in its answer. For example, a Mission left without a final state in `<project>/missions/MISSION-INDEX.md`, or a `RELAY` block not yet consumed, is a hole.
2. **One hole means no close.** The Pilot lists each hole with the action that would close it, and waits for your word on each one.
3. **Zero holes:** it files a handoff in `<project>/handoffs/`, then a capture in `<project>/captures/`.
4. It returns the Executor closing command: one snippet with the same five rubrics, pointing to the handoff by its path. The same snippet is also filed inside the handoff.

Paste that closing command into the Executor window. The Executor runs its branch of `session-close`:

- it reads the handoff in full;
- it appends a closing `STATE:` line to the journal, then the `CLOSE:` lines the handoff names, one per door;
- it regenerates the state sheet and the digest, and the indexes of the folders it touched;
- it makes one commit per touched repository, through the guardians;
- it ends with a closing `RELAY` block.

Carry that last block back to the Pilot, as in step 4. The details of both halves are in [Close a session](../how-to/close-a-session.md).

## What you have now

- `<project>/missions/MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md`: your Mission, frozen at `status: AUTHORIZED`.
- `<project>/missions/MISSION-INDEX.md`: its row, with its final state in `Statut`.
- `<project>/reports/REPORT-<AAAA-MM-JJ>-<HHMMSS>-<mission_id>-<slug>.md`: the Executor's report.
- New lines at the end of `<project>/state/journal.md`, and a regenerated `<project>/state/STATE.md` and `<project>/state/DIGEST.md`.
- A handoff in `<project>/handoffs/`, which the next Pilot session reads at opening, and a capture in `<project>/captures/`.

## Liens

- `source` — [Skill: writing a Mission](../../skills/mission-writing/SKILL.md)
- `source` — [Form checklist for a Pilot artefact](../../skills/mission-writing/mission-checklist.md)
- `source` — [Mission template](../../templates/mission-template.md)
- `source` — [Relay between roles through mini-prompts (rule 124937)](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Decision 201623, relay single source (part B1)](../../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
- `source` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `source` — [session-start skill](../../skills/session-start/SKILL.md)
- `source` — [Session opening reading list, by role](../../skills/session-start/reading-list.md)
- `source` — [session-close skill](../../skills/session-close/SKILL.md)
- `source` — [List of closing holes](../../skills/session-close/closing-checklist.md)
- `source` — [Report template](../../templates/report-template.md)
- `source` — [Decision 145256, report naming (point 2)](../../decisions/DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)
- `source` — [Pilot contract template](../../templates/pilot-contract-template.md)
- `source` — [Mission register template](../../templates/mission-index-template.md)
- `source` — [Example Mission EX-01, Les Pages Suspendues](../../templates/example-project-book-club/missions/MISSION-2026-09-11-193500-organize-the-october-meeting.md)
- `source` — [Les Pages Suspendues, example project overview](../../templates/example-project-book-club/README.md)
- `source` — [Instructions for agents](../../AGENTS.md)
- `source` — [README: Pilot and Executor surfaces, Bash on Windows](../../README.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Work-regime check](../../tools/check-work-regime.sh)
- `source` — [Verified push](../../tools/verified-push.sh)
- `source` — [Journal append tool](../../tools/append-journal.sh)
- `see also` — [Your first project](first-project.md)
- `see also` — [Open a session](../how-to/open-a-session.md)
- `see also` — [Write a Mission](../how-to/write-a-mission.md)
- `see also` — [Run a Mission as Executor](../how-to/run-a-mission-as-executor.md)
- `see also` — [Read a RELAY block](../how-to/read-a-relay.md)
- `see also` — [Delegate and push](../how-to/delegate-and-push.md)
- `see also` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `see also` — [Close a session](../how-to/close-a-session.md)
- `see also` — [Mission lifecycle](../explanation/mission-lifecycle.md)
- `see also` — [The two roles](../explanation/two-roles.md)
