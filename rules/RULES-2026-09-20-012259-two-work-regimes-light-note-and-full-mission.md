---
type: rules
title: "Two work regimes: the light Note and the full Mission"
description: "A gesture that is reversible and stays on the workstation or in a private repository is carried out under a light regime (an execution Note); a gesture that pushes to the published repository, deletes, amends doctrine, changes a remote, a branch or a tag, touches the company repository or a guardian stays under the full regime (a Mission). The choice is made by a command, not by judgement."
created_at: "2026-09-20T01:22:59-04:00"
timezone: America/Montreal
status: active
scope: work-regimes
amended_by: "DECISION-2026-09-20-235129-one-proof-pass-when-green-two-for-git-and-publication (workshop history, not distributed)"
---

# TWO WORK REGIMES: THE LIGHT NOTE AND THE FULL MISSION

## 1. Why two

The Mission is a rich form, and each of its rubrics was added after a real incident: the measured context, the internal cross-review, the preflight, the evidence status. None of it is decoration. But it costs the same whatever the gesture is worth: on the nine Missions measured before this rule, the Mission file was 12 600 to 26 700 characters (coefficient of variation 0.25), the report 10 700 to 18 600 (0.18), the steps 4 to 9 (seven in five cases out of nine), while the elapsed time went from 10 to 233 minutes and the amount of committed substance from nothing to 116 501 lines. Five of the nine committed no line of substance in the Vault. A fixed ceremony on a variable stake is a fixed floor: the floor is the whole cost of a light gesture, and a small part of the cost of a heavy one.

So the Mission is not lightened. A second regime is added beside it, and the choice between the two is made by a command.

## 2. The two regimes

| | Light regime | Full regime |
|---|---|---|
| Form | an execution Note, six rubrics, at most 4000 characters ([the template](../templates/execution-note-template.md)) | a Mission ([the template](../templates/mission-template.md)), its report, its relay |
| Trace | one journal line; no row in the Mission register | the register row, the report, the journal |
| Proofs | **kept**: a measure before, a measure after | kept, and replayed |
| What falls | the long context, the commit simulation, the two passes, the multi-page report, the mini-prompt | nothing |
| Who decides it applies | `tools/check-work-regime.sh`, before the gesture and after | the same command, by its refusal |

**Annotation (2026-09-21, Decision 235129, Mission 209).** In the table above, "the two passes" names the exception, not the rule. Proofs are played once when the first pass is green. Two passes are kept only for a Mission whose Scope holds a commit in the Vault or a publication, and only for the proofs that bear on that commit or that publication. A red proof is corrected, then the corrected proof alone is replayed; the whole suite is replayed only when the correction touches a shared tool. To know which tests a change calls for, `bash tests/run-suite.sh --changed origin/main` lists and plays exactly those, the two guardian lines included.

The light regime keeps the proofs. What is dropped is the ceremony around the proof, never the proof.

## 3. The choice, by command

`tools/check-work-regime.sh note <file>` reads a Note before its gesture and answers `REGIME-LIGHT-OK` or `REFUSED <criteria>`; `tools/check-work-regime.sh diff <repo> <range>` reads the real change afterwards. A refusal sends the gesture to a Mission. The check refuses; it never warns.

**The full regime is compulsory as soon as one criterion is true.** The list is closed; its ids are the tool's, and a test fails when the two lists drift apart.

| Id | The gesture... |
|---|---|
| `R1-egress` | leaves the workstation otherwise than by `git push origin <refspec>` or `git fetch origin`: a push to the published repository, of the publication branch, forced, of tags, deleting, without a named target, or to another remote; a network tool |
| `R2-destructive` | deletes a file or moves it out of its repository, or rewrites or throws away history (`rm`, `git rm`, `git clean`, `git reset --hard`, `git rebase`, `git commit --amend`) |
| `R3-doctrine` | creates or amends a Decision, a rule or a template |
| `R4-refs` | creates, renames or removes a remote, a branch, a tag or a worktree |
| `R5-company` | names the company repository at all |
| `R6-guardians` | touches a guardian, the preflight, a hook, the publication tool or the hook configuration, or bypasses a hook |

A seventh refusal, `R7-shape`, is not a criterion but the Note's form: the front matter, the six rubrics in order and nothing else, the size cap, one conforming journal line.

The list is tightened by a Mission and never loosened, and no argument extends what the light regime accepts: the same principle as the closed list of the publication tool. `R6-guardians` tightens the list the Owner gave, on the measure that the publication tool is what carries the private-pattern check: a change to it is not a light gesture, whatever its size.

A criterion is not "it is small". A small gesture can touch what is most precious, and the check looks at what is touched, not at how much.

## 4. The Note

Six rubrics, in this order, then an optional Liens rubric: **Intent** (what and why now), **Scope** (each path or repository written, one per line), **Measure before**, **Gesture** (the exact commands, one per line), **Measure after** (the same measure, before → after in figures), **Journal line** (one line, at most 300 characters, starting `STATE:`, `OPEN:` or `CLOSE:`). Nothing else: a Note that needs a Context rubric is a Mission.

It is filed in the project's `missions/` folder as `NOTE-<date>-<time>-<slug>.md`, beside the Missions it shares a lineage with. It is not a row of the Mission register: the register is read by the tools that follow the Missions, and a Note reaches the state sheet through its journal line, which is what the digest reads.

## 5. What does not change

- The Mission template, the ten guardians, the preflight and the register work as before: nothing in this rule modifies them, and a Note is filed through the same commit guardians as any other file.
- The absolute prohibitions of the relay rule hold in both regimes: no non-delegated push, no model call, no deletion.
- The role charter holds: the Executor measures, executes and proves; a Note is not a way to decide the architecture.

## 6. To watch

The light regime becomes the default if nothing watches it. After ten Notes, measure whether each was chosen for a gesture that the check accepts for the right reason, or whether the criteria are being avoided by wording; and count how many gestures would have been Missions under the old habit. The door stays open until then.

## Liens

- `see also` — [Note template](../templates/execution-note-template.md)
- `see also` — [Mission template](../templates/mission-template.md)
- `see also` — [Skill: writing a Mission](../skills/ecriture-de-mission/SKILL.md)
- `see also` — [Relay between roles through mini-prompts with fixed rubrics](./RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Role charter and session determination](./RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Versioning of Missions and generated outputs](./RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `applies` — [Decision — Evidence status and STOP control](../decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `amended by` — Decision — One proof pass when green, two only for Git and publication (workshop history, not distributed) (hors Vault)
