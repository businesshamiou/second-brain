---
type: how-to
title: "Write a Mission"
description: "How the Pilot decides between an execution Note and a Mission, writes and files the Mission from the template, runs the form checklist, and hands the Executor its five-rubric mini-prompt as one snippet."
status: active
---

# WRITE A MISSION

A Mission is the file in which the Pilot tells the Executor what to do, in which order, under which limits, and how the result will be proven. The Pilot writes it with the `mission-writing` skill ("mission writing"). You start it by asking the Pilot window, for example « écris la Mission » or "write the Mission". The skill executes nothing and never decides the architecture in your place: any choice that is more than a way of implementing comes back to you as a question, with a recommendation.

Not every gesture needs a Mission. The first step below chooses the regime, by command.

**Under Windows.** The `bash <workspace>/second-brain/tools/…` lines of this page are typed by the Executor, in its own shell (Git Bash under Windows). To type one yourself in PowerShell, where `bash` is unknown, replace `bash` with `& "C:\Program Files\Git\bin\bash.exe"`, or type the `sb` verb that carries the gesture ([Commands](../reference/commands.md)); `sb doctor` says whether `bash` is on your PATH.

## Before you start

- An open Pilot session in the project (see [Open a session](open-a-session.md)).
- The project has its `<project>/missions/` folder: Missions and Notes are project files, never Vault files.
- What you want done, in one or two sentences, and your authorization in your own words: the Mission quotes it verbatim and dated in its `## Gates`.
- A shell with Bash to run `tools/check-work-regime.sh` (Git Bash on Windows).

## Steps

### 1. Choose the regime: a Note or a Mission

The two regimes are set by [the work-regime rule](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md), and the choice is made by a command, never by judgement.

| | Light regime | Full regime |
|---|---|---|
| Form | an execution Note, six rubrics, at most 4000 characters | a Mission, its report, its relay |
| Trace | one journal line, no row in the Mission register | the register row, the report, the journal |
| Proofs | a measure before, a measure after | kept, and replayed |

First write the gesture as a Note from [the Note template](../../templates/execution-note-template.md): `<project>/missions/NOTE-<YYYY-MM-DD-HHMMSS>-<slug>.md`, with exactly these six rubrics in order: `## Intent`, `## Scope`, `## Measure before`, `## Gesture` (the exact commands in a fenced block), `## Measure after`, `## Journal line` (one line, at most 300 characters, starting `STATE:`, `OPEN:` or `CLOSE:`), then an optional `## Liens`. Then check it:

```bash
bash <workspace>/second-brain/tools/check-work-regime.sh note <workspace>/<project>/missions/NOTE-<YYYY-MM-DD-HHMMSS>-<slug>.md
```

- Last line `REGIME-LIGHT-OK` (exit 0): no Mission is needed, and the skill stops here. After the gesture, the real change is checked the same way: `bash <workspace>/second-brain/tools/check-work-regime.sh diff <workspace>/<project> <from>..<to>`.
- Last line `REFUSED <id>[,<id>...]` (exit 1): the full regime is compulsory. Go on to step 2.

The full regime is compulsory as soon as one of these criteria is true (the ids are the tool's):

| Id | The gesture... |
|---|---|
| `R1-egress` | leaves the workstation other than by `git push origin <refspec>` or `git fetch origin` (published repository, forced push, tags, another remote, a network tool) |
| `R2-destructive` | deletes a file, moves it out of its repository, or rewrites history |
| `R3-doctrine` | creates or amends a Decision, a rule or a template |
| `R4-refs` | creates, renames or removes a remote, a branch, a tag or a worktree |
| `R5-company` | names the company repository |
| `R6-guardians` | touches a guardian, the preflight, a hook, the publication tool or the hook configuration, or bypasses a hook |

"It is small" is not a criterion: the check looks at what is touched, not at how much. If you give a prompt straight to the Executor window (mode 2), no Mission is written at all: the Executor writes the Note itself as its first write ([Roles and Missions](../explanation/two-roles.md)).

### 2. Open the template at the moment of writing

The Pilot opens `templates/mission-template.md` now, never from memory: the list of rubrics and their order are the template's.

### 3. Measure before writing

- Each fact of the context carries a date and a status: `MESURÉ` (measured), `DECLARED`, or `HYPOTHÈSE` (hypothesis).
- Each file name linked or cited is obtained by a search or a listing, never typed from memory; each asserted existence ("the hook exists") is checked.
- A behaviour of a tool, a hook or a flag that no command has exercised is written `HYPOTHÈSE`.
- The Mission says what the Executor will find on disk and why, and names the known pitfalls.

### 4. Fill the rubrics, in the template's order

| Rubric | What goes in it |
|---|---|
| `## Measured existing state` | Mandatory as soon as the Scope creates a file: the listing or search command run, what it showed, and the conclusion (nothing fulfils this function, or an existing file is amended instead). Caps, quotas and versions of third-party instruments go here too. |
| `## Context` | Mandatory, in this order: the measured facts (dated, with status); what the Executor will find on disk; the known pitfalls; why the authorizing decision is what it is. |
| `## Objective` | The result pursued and why the Mission is opened. |
| `## Scope` | Repositories and folders concerned, then an explicit "Out of scope". |
| `## Preconditions` | What the Executor measures before writing anything; at the slightest non-trivial gap, STOP. `git status` tolerances named file by file. |
| `## Sources`, `## Applicable decisions` | Reports, Decisions, earlier measurements; a web address goes in Sources, never in Liens. |
| `## Constraints` | The limits; the template's line on absolute repository paths stays. |
| `## Prior measurements` | Mandatory as soon as a step creates, copies, installs, pins, wires or configures: one row per target, with the command that measures it before. A commit simulation follows when a commit is prescribed. |
| `## Fan-out` | Optional: batches of read-only measurements that do not depend on one another. Empty or absent is valid. |
| `## Steps` | Step 0 is the preflight as soon as the Scope commits a file filed by the Pilot. Never "delete": "move to `_trash/`" with a fingerprint, or a deletion by you as a human gate outside the steps. |
| `## Gates` | Your authorization verbatim and dated; the human gates not granted; each delegated push (absolute repository path and exact range); the stop conditions. |
| `## Validations` | Each criterion with a count before and after, in figures ("3 before, 0 after", not "fixed"). |
| `## Exit contract`, `## Resume contract`, `## Doors` | The expected closing report; where a partial run resumes; one line per door opened or closed. |
| `## Liens` | `prescribed by` the Mission versioning rule, and `applies` on each applied Decision. |

Every command in the Mission that writes or pushes names the absolute path of its repository, never `.` nor a relative path. A push is written through the verified-push tool with its exact range:

```bash
bash <workspace>/second-brain/tools/verified-push.sh <workspace>/<project> <from>..<to> [<remote>] [--url <url>]
```

_Not executed by the documentation check._

### 5. Cross-check Validations, Gates, Constraints and Steps

Two by two: each count of `## Validations` must be reachable without breaking a prohibition of `## Gates` or `## Constraints`, and each step must be allowed by the same prohibitions. The preconditions must also agree with one another and with the steps. The trace is an HTML comment at the head of `## Validations`. A contradiction found means rewrite, not file.

### 6. Run the form checklist, line by line

The Pilot runs `skills/mission-writing/mission-checklist.md` before filing any Pilot artefact, not only a Mission. Each of its 31 lines cites the fault or the Decision that paid for it; one failing line means no filing. Among them: the four contents of `## Context` (line 1), the traced cross-review (line 2), the mini-prompt without prohibitions of its own (line 3), links obtained by search (line 5), no "delete" step (line 12), your words verbatim in the Gates (line 13), a Validation criterion reachable in the measured state (line 20), the preflight step 0 (line 22).

Line 31 checks absolute paths and verified pushes: every write or push command names the absolute path of its repository, never `.` nor a relative path, and every push is written with `tools/verified-push.sh` and its exact range. Its measurement is a search that must find nothing outside quotations:

```bash
grep -n -E 'git push| \. |cd \.\.' <workspace>/<project>/missions/DRAFT-<slug>.md
```

### 7. File through the DRAFT pattern

In a single turn:

1. Write `<project>/missions/DRAFT-<slug>.md`.
2. Read its measured timestamp, and put it in `created_at` and in the name.
3. Rename it to `<project>/missions/MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md`, where `<NNN>` is the `mission_id`.
4. Check the final file exists.

`created_at` equals the timestamp of the name. The `status` field freezes the authorization at creation and is never touched again; the execution state lives in `<project>/missions/MISSION-INDEX.md`, whose row stays at 300 characters or fewer (checklist, line 15). An executed Mission is never edited: a correction is a new `-C01` Mission or your arbitration.

### 8. Issue the mini-prompt as one snippet

The Pilot hands the Executor a mini-prompt with the five fixed rubrics of [the relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md), in this order, as a code block you copy in one gesture. No PROMPT file, and no copy of the Mission's content. The labels stay in French:

```text
Session Executor — Mission <NNN> (<description courte>)

Position : free.

Source à appliquer : <path of the Mission file>, to be read and applied in full.

Interdits absolus : no non-delegated git push, no model call, no deletion; move to `_trash/` only on the Mission's prescription. The Mission's ## Gates and ## Constraints rubrics apply.

Sortie attendue : end the window with the RELAY block of rule 124937, filled in.
```

The prohibitions rubric carries only the four standard prohibitions plus the reference to `## Gates` and `## Constraints`; the skill never adds a prohibition of its own there (checklist, line 3). You paste the snippet into the Executor window; the RELAY block comes back the same way ([Read a relay](read-a-relay.md)).

## What you should see

- A single file `<project>/missions/MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md`, no `DRAFT-` file left, `created_at` equal to the timestamp of the name.
- In the chat, one code block: the mini-prompt, five rubrics.
- For the check of step 1, a last line `REGIME-LIGHT-OK` or `REFUSED <ids>`.

A Mission file itself is never a valid Note. This runs as is from the root of a Vault:

```bash
bash tools/check-work-regime.sh note templates/mission-template.md
```

It lists its reasons on standard error (`REFUS : R7-shape -- front matter lacks 'regime: light'`, and others) and ends with `REFUSED R7-shape`, exit 1.

## Known errors

| Message | Cause | What to do |
|---|---|---|
| The usage line, starting `usage:` (exit 2) | Wrong mode or wrong number of arguments. | Use `note <file>` or `diff <repo> <range>`. |
| `REFUS : fichier introuvable : <file>` (exit 2) | The Note path does not exist. | Give the full path of the Note. |
| `REFUSED R7-shape` | The Note's form: `type: note` or `regime: light` missing, rubrics not exactly the six in order, over 4000 characters, empty rubric, journal line absent, over 300 characters or not starting `STATE:`, `OPEN:` or `CLOSE:`. | Fix the Note. A Note that needs a Context rubric is a Mission. |
| `REFUSED R1-egress` ... `R6-guardians` | A full-regime criterion is met. | Write a Mission (steps 2 to 8). |
| `REFUSED R8-origin` | The form of a mode-2 Note (written by the Executor from your prompt): origin, mode, reception time, prompt or files and their sha256. | The Executor fixes its Note; see the Note template. |
| `REFUS : pas un depot Git`, `REFUS : plage illisible`, `REFUS : plage vide` (exit 2, `diff` mode) | The repository path is not a Git repository, or the range cannot be read or is empty. | Give the absolute repository path and a `<from>..<to>` range that exists. |
| A contradiction between Validations, Gates, Constraints or Steps | Found at the cross-check. | Rewrite before filing. |
| A checklist line fails | A form defect the checklist names. | No filing until it passes. |
| The Executor's preflight (step 0) reports violations | A defect in a file the Pilot filed. | The Pilot corrects it; the preflight corrects nothing. |

## Scripts used

- `tools/check-work-regime.sh`: chooses the regime of a Note and checks the real change afterwards ([guardian tools](../reference/tools-guardians.md)).
- `tools/verified-push.sh`: the only form in which a Mission prescribes a push ([publication and push tools](../reference/tools-publication-and-push.md)).

## Liens

- `source` — [Skill: writing a Mission](../../skills/mission-writing/SKILL.md)
- `source` — [Form checklist for a Pilot artefact](../../skills/mission-writing/mission-checklist.md)
- `source` — [Mission template](../../templates/mission-template.md)
- `source` — [Execution Note template](../../templates/execution-note-template.md)
- `source` — [Relay between roles through mini-prompts](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Two work regimes: the light Note and the full Mission](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Work-regime check](../../tools/check-work-regime.sh)
- `source` — [Verified push](../../tools/verified-push.sh)
- `see also` — [Roles and Missions](../explanation/two-roles.md)
- `see also` — [Mission lifecycle](../explanation/mission-lifecycle.md)
- `see also` — [Why absolute paths](../explanation/why-absolute-paths.md)
- `see also` — [Run a Mission as Executor](run-a-mission-as-executor.md)
- `see also` — [Read a relay](read-a-relay.md)
- `see also` — [Delegate and push](delegate-and-push.md)
- `see also` — [First Mission](../tutorials/first-mission.md)
- `see also` — [Skills](../reference/skills.md)
