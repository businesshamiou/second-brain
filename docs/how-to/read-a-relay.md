---
type: how-to
title: "Read a RELAY block"
description: "How to carry the RELAY block from the Executor window back to the Pilot, read each of its rubrics, and know when the full report must be reopened."
status: active
---

# READ A RELAY BLOCK

When an Executor finishes a Mission or an Owner's prompt, it ends its window with a `RELAY` block. You, the Owner, carry that block to the Pilot, who resumes from it without reading the whole report. This page shows how to carry it and how to read it. The grammar of the block has a single source, the [relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md); this page does not restate it.

## Before you start

- A Pilot window (a session that cannot run shell commands) and an Executor window (a session that can) are open on the same project; see [Open a session](open-a-session.md).
- The Executor has received its work: a Mission through the Pilot's mini-prompt (mode 1), an Owner's prompt pasted as is (mode 2a), or "read <files> and execute" (mode 2b).
- You are the only channel between the two windows: you paste the mini-prompt on the way out and the `RELAY` block on the way back.

## Steps

1. **Wait for the end of the Executor window.** The Executor first files its report, then displays the `RELAY` block as the last element of the window, in a single code block with no text to sort around it.
2. **Copy the block in one gesture.** Use the copy button of the code block. If the Executor gave the block as prose, or split it, ask it to render it again as one code block: the rule forbids reassembling it by hand.
3. **Paste it into the Pilot window**, as is. Nothing else is needed; the Pilot resumes on the strength of the block.
4. **Read the header.** It names the Mission the block answers or, for an Owner's prompt (mode 2), the timestamp of the execution Note the Executor wrote first, `<project>/missions/NOTE-<YYYY-MM-DD-HHMMSS>-<slug>.md`; in mode 2 the report is filed in `<project>/reports/`. The rest of the block is the same in both modes.
5. **Read the rubrics against the rule**, with the reading notes below.
6. **Let the Pilot decide whether to reopen the report.** It reopens the full report only if the verdict or the `À trancher` rubric requires it; otherwise the block is the default reading.

The block's exact grammar (its rubrics, their order, their forms and caps) lives in one place, [rule 124937](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md): Decision 201623 B1 says no other document restates it. Open the rule next to the block. The notes below only say how to read four of its rubrics; the labels are French literals.

| Rubric | How to read it |
| --- | --- |
| `Verdict` | The Pilot rereads the full report only if the verdict or the `À trancher` rubric requires it; the block gives the report's path. |
| `Poussées` (pushes) | What the Executor actually pushed, measured by `git ls-remote`, never inferred from an intention. No push is expected when none was delegated. |
| `Résumé` (summary) | Facts with figures, not appraisals: "Q5: 12 decisions found against 7", not "Q5 up". It names every deviation from the protocol or the Mission, even minor: it is the only place the Pilot sees one without opening the report. |
| `À trancher` (to be decided) | A question for you or the Pilot. When a gesture reserved to the Owner blocked the work, it names the exact path and the available substitute (a move to `_trash/`). |

## What you should see

- In the Executor window: the report filed, then one code block, the `RELAY` block, as the last thing on screen.
- In the Pilot window, after you paste: the Pilot resumes from the block. It reopens the full report only when the `Verdict` or `À trancher` calls for it, and it delivers any words it needs from you as copyable snippets, each preceded by a line naming the window they go to.

To check a `Poussées` line yourself, read the remote head with Git (read-only; `<workspace>/<project>` is the absolute path of the repository):

```bash
git -C <workspace>/<project> ls-remote origin refs/heads/main
```

_Not executed by the documentation check._

The hash printed must equal the pushed commit that the `Poussées` line names.

## Known errors

| What you see | Cause | What to do |
| --- | --- | --- |
| The block is prose, or scattered across the window. | The rule requires one code block, copyable in one gesture. | Ask the Executor to render the `RELAY` block again as one code block. |
| `Poussées` reports no push while you expected one. | A push is an Owner gesture, delegated only by a clear expression naming the gesture and its target. Without it, the Executor does not push and says so in the block. | Delegate the push explicitly, or push yourself with `tools/verified-push.sh`. |
| `Résumé` runs past the rule's ceiling, or says "better" or "up" with no figure. | The rule caps the rubric strictly and takes facts only. | Ask the Executor for a summary within the rule; the Pilot should not have to open the report to find a figure. |
| `À trancher` names a path and `_trash/`. | A permanent deletion (or another gesture reserved to the Owner) blocked the work; the Executor stops there, with no workaround. | Make the gesture yourself, or accept the substitute it names. |
| The header names a Note, but no such Note exists in `<project>/missions/`. | In mode 2, the Note must be the Executor's first write, accepted by `tools/check-work-regime.sh` before the gesture. | Tell the Pilot when you paste the block. |

## Scripts used

Reading a relay runs no script. Two scripts produce what you read:

- `tools/verified-push.sh` — pushes an exact range and prints the `ls-remote` line behind `Poussées`; see [publication and push tools](../reference/tools-publication-and-push.md).
- `tools/check-work-regime.sh` — accepts the mode-2 execution Note before the gesture that the block then answers; see [guardian tools](../reference/tools-guardians.md).

## Liens

- `source` — [Relay between roles through mini-prompts](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Decision — « Résumé » rubric in the RELAY block](../../decisions/DECISION-2026-08-23-180500-relay-summary-rubric.md)
- `source` — [Decision — Relay and delegation, one rule in one place](../../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
- `source` — [Decision — Two relay modes](../../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md)
- `source` — [Decision — Copy protocol: snippets and destinations](../../decisions/DECISION-2026-08-27-100016-copy-protocol-snippets-and-destinations.md)
- `source` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Report template](../../templates/report-template.md)
- `source` — [Verified push script](../../tools/verified-push.sh)
- `source` — [Work-regime check](../../tools/check-work-regime.sh)
- `see also` — [Run a Mission as Executor](run-a-mission-as-executor.md)
- `see also` — [Write a Mission](write-a-mission.md)
- `see also` — [Delegate and push](delegate-and-push.md)
- `see also` — [Open a session](open-a-session.md)
- `see also` — [Roles and Missions](../explanation/two-roles.md)
