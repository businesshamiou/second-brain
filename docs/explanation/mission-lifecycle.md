---
type: explanation
title: "The life of a Mission"
description: "Why a Mission goes through each of its stages, from the draft file to the regenerated state sheet, which rule or Decision set each stage, and why a lighter execution Note sits beside it."
status: active
---

# THE LIFE OF A MISSION

A Mission is the file in which the Pilot prescribes a piece of work to the Executor. Its life has more stages than a to-do list needs, and almost every stage was added after a real incident. This page follows one Mission from the draft to the state sheet, says why each stage exists, and names the rule or Decision that set it. For the gestures themselves, see [write a Mission](../how-to/write-a-mission.md) and [run a Mission as Executor](../how-to/run-a-mission-as-executor.md); for who does what, see [the two roles](two-roles.md).

## The stages at a glance

| Stage | Who | What it leaves behind | Set by |
|---|---|---|---|
| Choose the regime | Pilot | a Note, or the decision to write a Mission | [two work regimes](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md) |
| Draft, then rename | Pilot | `<project>/missions/MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md` | [mission-writing skill](../../skills/mission-writing/SKILL.md) §6 |
| Hand over the mini-prompt | Pilot, then you | a snippet; the Mission is now frozen | [relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md), [Decision 013217](../../decisions/DECISION-2026-08-30-013217-mission-frozen-at-snippet-emission.md) |
| Preconditions | Executor | a measurement, or a STOP with nothing written | [role charter](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md) §3 |
| Steps and commits | Executor | commits, file by file | [Mission template](../../templates/mission-template.md), [versioning rule](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) §10 |
| Report and RELAY | Executor, then you | a report file and a RELAY block | [Decision 000236](../../decisions/DECISION-2026-08-21-000236-execution-report-channel.md), relay rule |
| Register, journal, sheet | Executor | a register row, journal lines, a regenerated `<project>/state/STATE.md` and `<project>/state/DIGEST.md` | [Decision 015748](../../decisions/DECISION-2026-08-20-015748-mission-status-field-semantics.md), [Decision 191407](../../decisions/DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md), [Decision 012458](../../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md) |

## 1. Choosing the regime comes first

Before any Mission is written, the Pilot asks a command, not its own judgement, whether a Mission is needed at all. The [mission-writing skill](../../skills/mission-writing/SKILL.md) (§0) has it fill an execution Note and run `tools/check-work-regime.sh` on it. `REGIME-LIGHT-OK` means the Note is enough and no Mission is written; a refusal `R1` to `R7` sends the work to the full regime. The reason is given in the last section of this page.

## 2. The draft becomes a Mission in one turn

The Pilot writes the file from `templates/mission-template.md`, opened at the moment of writing and never recalled from memory: the template changes, and the skill (§1) names a change that a memory would have missed. The file is first laid down under a draft name, `<project>/missions/DRAFT-<slug>.md`. Its real creation time is then measured, written into `created_at` and into the name, and the file is renamed `<project>/missions/MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md`, all in one turn (skill §6).

Why the detour: the Pilot has no shell, so its real timestamp comes from the filing itself, read back from the file system, then carried into the name and `created_at` ([Decision 131034](../../decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md) point 1). The Pilot contract says every filed file carries its real timestamp and its final name before the end of the turn ([Decision 143542](../../decisions/DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md), line 6), and the form checklist refuses a Mission whose `created_at`, name timestamp and `mission_id` disagree (`skills/mission-writing/mission-checklist.md`, line 10). The name holds two things on purpose: the timestamp says when the file was created, the three-digit number says which Mission it is ([versioning rule](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) §1).

Several rubrics of the template carry their incident with them:

- **Context** is mandatory, with dated facts marked `MESURÉ`, `DECLARED` or `HYPOTHÈSE`, because a Mission without context makes the Executor rebuild the history or ignore it ([Decision 115547](../../decisions/DECISION-2026-09-01-115547-mission-context-coherence-and-least-powerful-reading.md) point 1; [Decision 212009](../../decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)).
- **Cross-review** of Validations, Gates, Constraints and Steps, two by two, is traced before filing, because Missions 090 and 108 asked in one rubric for what another forbade, and no guardian can see a contradiction of meaning (Decision 115547 point 2).
- **Preconditions**, relative counts in the Validations, **Doors** and **Resume contract** were added together after the consolidation of 2026-08-25 ([Decision 232341](../../decisions/DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md), Impact).
- **Step 0, the preflight**, runs every guardian on the files of the Scope and reports all violations at once, because Mission 134-A took five Executor windows to find two defects one by one ([Decision 154756](../../decisions/DECISION-2026-09-04-154756-mission-preflight-step-zero.md)).

## 3. A frozen authorization, a living register

The front matter of the template carries `status: AUTHORIZED`, with the comment that it is frozen and never touched afterwards. The execution state lives somewhere else: in the `Statut` column of `<project>/missions/MISSION-INDEX.md`.

Why two places: on 2026-08-20 a measurement of 18 Mission files found `status` holding an authorization in some files and an execution result in others. [Decision 015748](../../decisions/DECISION-2026-08-20-015748-mission-status-field-semantics.md) separated the two. The front matter only records, after the fact, which authorization let the file be opened (D1, D4). The register is the only authority on execution (D2), and its `Statut` takes `AUTHORIZED`, `IN_PROGRESS`, `COMPLETED` or `ABANDONED`, updated by the Executor at the end of each Mission (D3). A file that never changes can be trusted as a record; a single register can be trusted as the state.

## 4. The mini-prompt, and the freeze it triggers

The Pilot hands the Mission over as a mini-prompt, one code block with five fixed rubrics: title line, position, source to apply, absolute prohibitions, expected output ([relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)). It does not repeat the Mission. Its prohibitions are the four standard ones plus a pointer to the Mission's Gates and Constraints, never a prohibition of its own: a second list of prohibitions is invisible to the cross-review, and that is how Mission 108 contradicted itself (Decision 115547 point 3).

Handing over the snippet is the moment the Mission freezes ([Decision 013217](../../decisions/DECISION-2026-08-30-013217-mission-frozen-at-snippet-emission.md)). From then on its text is never retouched in place, even for a typo. The freeze sits there because it is the only moment the Pilot can observe: it does not commit, and it does not see you open the Executor window. Missions 096 and 097 were retouched while their windows were running, which left a record whose text differed from what had been executed.

## 5. Preconditions: measure, or STOP

The Executor reads the whole Mission, then measures what the Preconditions declare before writing anything. At the slightest gap: STOP, report, no write (charter §3). A point that rests on a `HYPOTHÈSE` carries a named STOP before the write concerned (Decision 212009 point 3), and it was such a stop that caught a false inference on 2026-08-29 before any text was changed.

A contradiction inside the Mission is different: it is not a STOP. The Executor keeps the least powerful reading, the one that writes least and deletes nothing, and reports it in the deviations and in the RELAY summary (Decision 115547 point 4). The error must fall on the harmless side.

## 6. Steps, committed one by one

The Executor writes within the Mission's Scope only, and runs `git add` and `commit` file by file after inspecting each diff (charter §3). For the closing commits, the [session-close skill](../../skills/session-close/SKILL.md) (§3) makes a guardian refusal a STOP, quoted verbatim, with no workaround. A Mission contains no "delete" step: it moves a file to `_trash/` with a fingerprint, or lists deletion by you as a human gate outside the steps ([Decision 110852](../../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)). Every write or push command names the absolute path of its repository ([absolute paths rule](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)).

As its last steps, a Mission commits its own file and regenerates the generated indexes; leaving that to a later window is declared as ANOMALY (versioning rule §10). Why: closes that took three windows (Missions 041, 044, 045) took one each once Missions tidied after themselves (050, 051, 052) ([Decision 131034](../../decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md) point 2).

## 7. The report and the RELAY block

The Executor files a report from `templates/report-template.md` in `<project>/reports/`, staged in the same commit as the work it proves ([Decision 000236](../../decisions/DECISION-2026-08-21-000236-execution-report-channel.md), D5). A report in a chat window is lost when the window closes; a filed report is committed evidence the Pilot can read without you copying it over.

The window then ends with the RELAY block, one code block with fixed rubrics: report path, verdict (`FAIT`, `PARTIEL` or `BLOQUÉ`), criteria passed, commits, pushes, a summary of at most five lines, and what you must decide ([relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)). You paste it back into the Pilot window. The pushes rubric says what was actually pushed, measured with `git ls-remote`, never what was intended. The summary is capped so it does not become a second report, and it lists every deviation, because it is the one place the Pilot sees them without opening the report. See [read a RELAY](../how-to/read-a-relay.md).

## 8. Register row, journal lines, regenerated sheet

Three traces follow the Mission:

- **The register row** in `<project>/missions/MISSION-INDEX.md` carries at least the identifier, the objective, the active version, the status and the path of the active Mission, plus the report ([versioning rule](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) §6; `templates/mission-index-template.md`). Its status header stays `Statut`, because `tools/build-digest.sh` finds the column by that name.
- **Journal lines** in `<project>/state/journal.md`, added only through `tools/append-journal.sh`, which timestamps each line, never rewrites an existing one, and refuses a text over 300 characters. The 300-character cap exists because journal lines of up to 5,000 characters had made opening a Pilot session expensive: a line is a pointer, the narrative lives in the report ([Decision 191407](../../decisions/DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)).
- **The state sheet and digest**, `<project>/state/STATE.md` and `<project>/state/DIGEST.md`, regenerated by `tools/build-state.sh` and `tools/build-digest.sh` and never edited by hand ([Decision 012458](../../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md)). The digest, capped at 8,000 bytes, is what the Pilot reads first at opening; it shows the last Mission's number and status taken from the register.

The journal tags that `tools/build-state.sh` reads are:

| Tag | Effect on the sheet |
|---|---|
| `STATE:` | current state; the last occurrence wins |
| `NEXT:` | next action; the last occurrence wins |
| `OPEN:<key> -- <text>` | opens or reopens a door |
| `CLOSE:<key> -- <reference>` | closes that door |
| `RESUME:` | resume note, shown only when it is the last line of the journal |

The French tags `ETAT:`, `PROCHAIN:`, `REPRISE:` and `OUVERT:` are still read, for the older lines. A line with no recognised tag feeds no section of the sheet. The convention was ratified rather than left as a habit ([Decision 143542](../../decisions/DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md) point 4). At close, the Executor writes a closing `STATE:` line, then the `CLOSE:` lines the handoff names, then regenerates sheet and digest ([session-close skill](../../skills/session-close/SKILL.md) §3; [close a session](../how-to/close-a-session.md)).

## 9. Doors

A door is a pending question or follow-up, kept in the journal under one key per door: `open-…` or `frozen-…`, lowercase, followed by ` -- ` and the text. For each key, `tools/build-state.sh` keeps the last occurrence in the journal: an `OPEN:` shows the door, a later `CLOSE:` of the same key removes it, a later reopening brings it back. Older `OPEN:` lines with no conforming key are not shown; they are counted in one line. The digest lists the open door keys only.

Why keys: before [Decision 110935](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md), the sheet showed every door ever opened, with no way to close one: 11 entries, at least 4 outdated, one repeated four times. The journal is append-only, so a door cannot be erased; it can only be closed by a later line. That is why the template's `## Doors` rubric has one line per door the Mission opens or closes, with its exact `CLOSE:` line when it closes here, and why the session close writes no `CLOSE:` that the handoff does not name.

## 10. The resume contract

A window does not always finish. The template's `## Resume contract` is filled only when the window stops at `PARTIEL`: the last healthy commit, what remains, and how the next window resumes without replaying what is done. It was added with the Preconditions and Doors rubrics ([Decision 232341](../../decisions/DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md), Impact), so that a window stopped at `PARTIEL` ends on a named resume point. Separately, a `RESUME:` line in the journal reaches the state sheet only while it is the journal's last line.

## 11. Replacing a Mission that was never launched

What you may do with a Mission that did not run depends on one fact: was its snippet handed over?

- **Not yet handed over.** Nobody has read it. It stays freely modifiable in place ([Decision 013217](../../decisions/DECISION-2026-08-30-013217-mission-frozen-at-snippet-emission.md) point 4).
- **Handed over, even if no window ever opened.** It is frozen. Any change, however small, goes through a correction: a new file with the same number and a suffix `C01` to `C10`, its own real timestamp, `supersedes` pointing to the replaced file, the reciprocal `superseded by`, and a new snippet (Decision 013217 point 2; [versioning rule](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) §2). A text changed without a new snippet was never communicated.

A correction is complete in itself: the Executor reads the latest active version, never a sum of patches (versioning rule §3). The old versions stay as history, and reaching `C10` means asking whether the objective has become a new Mission. The cost is accepted on purpose: a typo in an issued Mission costs a full correction, because the line between a typo and a change of meaning always moves toward whoever wants to retouch.

## The light regime beside it

Every rubric above earned its place, but together they cost the same whatever the gesture is worth. On nine Missions measured before the rule, Mission files ran from 12,600 to 26,700 characters and reports from 10,700 to 18,600, while elapsed time went from 10 to 233 minutes and five of the nine committed no line of substance in the Vault ([two work regimes](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md) §1). A fixed ceremony on a variable stake is a fixed floor.

So the Mission was not lightened; a second regime was put beside it. A gesture that is reversible and stays on the workstation or in a private repository is carried out under an execution Note from `templates/execution-note-template.md`: six rubrics (Intent, Scope, Measure before, Gesture, Measure after, Journal line), at most 4,000 characters, filed as `<project>/missions/NOTE-<YYYY-MM-DD-HHMMSS>-<slug>.md`.

| | Mission | Execution Note |
|---|---|---|
| Trace | register row, report, RELAY, journal | one journal line, no register row |
| Proofs | measured before and after | measured before and after |
| Dropped | nothing | long context, commit simulation, multi-page report, mini-prompt |
| Decided by | a refusal of `tools/check-work-regime.sh` | `REGIME-LIGHT-OK` from the same tool |

The proof stays; only the ceremony around it falls. The choice is made by `tools/check-work-regime.sh note <file>` before the gesture and `tools/check-work-regime.sh diff <repo> <range>` after it, and the full regime is compulsory as soon as one criterion holds: leaving the workstation otherwise than a plain push or fetch to `origin`, deleting or rewriting history, touching doctrine, remotes, branches, tags or worktrees, naming the company repository, or touching a guardian (`R1` to `R6`). The check looks at what is touched, not at how much: a small gesture can touch what is most precious.

The Note is also the trace of mode 2, when you hand a prompt to the Executor without a Mission: the Note is then its first write, it quotes your prompt with its sha256 (or, when you said "read <files> and execute", lists each file with its sha256), and the RELAY is headed `RELAY NOTE-<YYYY-MM-DD-HHMMSS>` ([Decision 012500](../../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md)). The same commit guardians judge what a Note and a Mission commit.

## Liens

- `source` — [Versioning of Missions and generated outputs](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `source` — [Mission template](../../templates/mission-template.md)
- `source` — [Skill: writing a Mission](../../skills/mission-writing/SKILL.md)
- `source` — [Form checklist for a Pilot artefact](../../skills/mission-writing/mission-checklist.md)
- `source` — [Two work regimes: the light Note and the full Mission](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)
- `source` — [Relay between roles through mini-prompts](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Decision — Semantics of the status field](../../decisions/DECISION-2026-08-20-015748-mission-status-field-semantics.md)
- `source` — [Decision — Execution report channel](../../decisions/DECISION-2026-08-21-000236-execution-report-channel.md)
- `source` — [Decision — Pilot contract and journal tags ratification](../../decisions/DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md)
- `source` — [Decision — CLOSE: tag and keyed doors](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
- `source` — [Decision — Doctrinal arbitrations of 2026-08-25](../../decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md)
- `source` — [Decision — Consolidation of the evening of 2026-08-25](../../decisions/DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md)
- `source` — [Decision — Evidence status and STOP control](../../decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `source` — [Decision — Permanent deletion is an Owner gesture](../../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
- `source` — [Decision — A Mission is frozen when its snippet is issued](../../decisions/DECISION-2026-08-30-013217-mission-frozen-at-snippet-emission.md)
- `source` — [Decision — Internal coherence of Missions](../../decisions/DECISION-2026-09-01-115547-mission-context-coherence-and-least-powerful-reading.md)
- `source` — [Decision — Journal and index as pointers](../../decisions/DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)
- `source` — [Decision — Preflight step 0](../../decisions/DECISION-2026-09-04-154756-mission-preflight-step-zero.md)
- `source` — [Decision — State sheet, one name, generated](../../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md)
- `source` — [Decision — Two relay modes](../../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md)
- `source` — [Skill: session close](../../skills/session-close/SKILL.md)
- `source` — [Mission register template](../../templates/mission-index-template.md)
- `source` — [Report template](../../templates/report-template.md)
- `source` — [Execution Note template](../../templates/execution-note-template.md)
- `source` — [State sheet generator](../../tools/build-state.sh)
- `source` — [Digest generator](../../tools/build-digest.sh)
- `source` — [Journal append tool](../../tools/append-journal.sh)
- `source` — [Work-regime check](../../tools/check-work-regime.sh)
- `see also` — [The two roles](two-roles.md)
- `see also` — [Why decisions are recorded](decisions.md)
- `see also` — [Write a Mission](../how-to/write-a-mission.md)
- `see also` — [Run a Mission as Executor](../how-to/run-a-mission-as-executor.md)
- `see also` — [Read a RELAY](../how-to/read-a-relay.md)
- `see also` — [Close a session](../how-to/close-a-session.md)
- `see also` — [Formats](../reference/formats.md)
- `see also` — [Tools: state and journal](../reference/tools-state-and-journal.md)
