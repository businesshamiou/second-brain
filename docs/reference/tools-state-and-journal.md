---
type: reference
title: "Tools: state and journal"
description: "One sheet per script for the tools that append to a project journal, generate its state sheet and capped digest, measure its phases, and check that a handoff arrives with its session close."
status: active
---

# TOOLS: STATE AND JOURNAL

A project keeps an append-only journal, `<project>/state/journal.md`. Every other state file is generated from it: the state sheet `<project>/state/STATE.md` and its capped extract `<project>/state/DIGEST.md`. This page describes the five scripts around that journal, as their code reads today.

**Under Windows.** A `bash …/tools/…` line of this page, typed in PowerShell where `bash` is unknown, starts with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`; where an `sb` verb carries the same gesture ([Commands](commands.md)), type the verb. `sb doctor` says whether `bash` is on your PATH.

## Journal lines and tags

`tools/append-journal.sh` writes each line as `<timestamp> <text>`, the timestamp in ISO form with its offset (for example `2026-09-25T10:04:19-04:00`). The readers only look at lines that start with such a date. New lines use the English tags; the French ones (`ETAT:`, `PROCHAIN:`, `REPRISE:`, `OUVERT:`) are historical and still recognised ([tag rule](../../rules/RULES-2026-08-23-220049-activity-classification-and-system-keywords.md)).

| Tag | Form | How it is read |
|---|---|---|
| `STATE:` | `STATE: <text>` | `tools/build-state.sh`: the last line containing `STATE:` (or `ETAT:`) gives the "État courant" section. `tools/check-session-close.sh` only counts it right after the timestamp. |
| `NEXT:` | `NEXT: <text>` | `tools/build-state.sh`: the last line containing `NEXT:` (or `PROCHAIN:`) gives the "Prochaine action" section. |
| `RESUME:` | `RESUME: <text>` | `tools/build-state.sh`: shown in the "Reprise" section only when the journal's last dated line contains `RESUME:` (or `REPRISE:`). |
| `OPEN:` | `OPEN:<key> -- <text>` | Opens or reopens a door. Must come right after the timestamp. The key matches `^(open\|frozen)-[a-z0-9-]+` and is followed by ` -- `. |
| `CLOSE:` | `CLOSE:<key> -- <reference>` | Closes the door with that exact key, if it was opened earlier. No French twin ([door Decision](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)). |
| `PHASE:` | `PHASE:<name>:<debut\|fin>` | Read only by `tools/phase-report.sh`; the name is letters, digits and hyphens. Not a state tag: `tools/build-state.sh` ignores it. |

For each door key, the last occurrence in the journal wins: a later `CLOSE:` removes it, a later `OPEN:` brings it back. An `OPEN:` line without a conforming key is not listed as a door; `tools/build-state.sh` counts such lines in its "Historique legacy" section. A line with no recognised tag feeds no section.

## `tools/append-journal.sh`

**Role.** Adds one timestamped line at the end of a project's journal. It never reads the journal and never rewrites a line. It creates `<project>/state/` and the journal if they are missing; a new journal gets a title, one sentence and a `## Liens` section pointing to the project's README.

**Called by.** `tools/project-bootstrap.sh` (the birth line of a created or adopted project); the Executor close in `skills/session-close/SKILL.md` (closing `STATE:` and `CLOSE:` lines). Tests: `tests/test-repo-root-guard.sh`, `tests/test-phase-report.sh`, `tests/test-state-sheet-at-birth.sh`, `tests/test-work-regime-mode2.sh`, `tests/test-install-e2e.sh`, `tests/test-nominal-flow-no-atelier-vocabulary.sh`, `tests/standalone.sh`; on Windows, `tests/test-install-e2e.ps1`, `tests/test-prerequisites-e2e.ps1`, `tests/test-nominal-flow-no-atelier-vocabulary.ps1`.

**Syntax.** `append-journal.sh <chemin-projet> "<texte>"`. No option; both arguments are required.

**300-character cap.** The text you pass, without the timestamp the script adds, may not exceed 300 characters, counted as characters (`wc -m`), not bytes ([Decision 191407](../../decisions/DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)). Over the cap, nothing is written.

**Exit codes and last line.**

| Exit | Message on stderr | Cause |
|---|---|---|
| 0 | none | Line appended. |
| 1 | `usage: append-journal.sh <chemin-projet> "<texte>"` | A missing argument. |
| 1 | `REPO-ROOT-REFUSED: ...` | The repository-root guard refused the path. |
| 1 | `REFUS append-journal.sh : ligne de <n> caracteres, plafond 300 (Decision 191407). Rien ecrit.` | Text over 300 characters. |

**Reads.** Nothing from the project. **Writes.** `<project>/state/journal.md` (append only; created if missing).

**Repository-root guard.** Yes: `tools/repo_root_guard.py` runs first, through `uv run --no-project`, before the cap check and before any write.

**Example.**

```bash
bash <workspace>/second-brain/tools/append-journal.sh <workspace>/<project> "STATE: Mission 012 FINAL, 3 files"
```

_Not executed by the documentation check._

## `tools/build-state.sh`

**Role.** Regenerates `<project>/state/STATE.md`, the state sheet, from the journal, the Git state and the list of recent documents. The sheet is a catalogue, never edited by hand ([Decision 012458](../../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md)). Sections, in order: Pilot contract, session references, current state, next action, project profile, open doors, legacy history, recent documents, repository state, resume note, `## Liens`.

**Called by.** `tools/project-bootstrap.sh` (at birth, only when the sheet is missing); step 3 of the Executor close in `skills/session-close/SKILL.md`; `tools/session-preflight.sh` checks that it is executable. Tests: `tests/test-repo-root-guard.sh`, `tests/test-state-sheet-at-birth.sh`, `tests/standalone.sh`.

**Syntax.** `build-state.sh [--replace-hand-written] <chemin-projet>`

**Options.**

- `--replace-hand-written` (must come first): replaces a `<project>/state/STATE.md` that this script did not generate, only when Git tracks that file and holds it unchanged at HEAD. The script prints the blob it replaces, so the old content stays recoverable. Carry its content into the journal before running it.

**generated_by.** Every sheet it writes carries, in its front matter, a `generated_by:` line pointing to `tools/build-state.sh`. If a `<project>/state/STATE.md` exists without that line (searched in lines 2 to 12), the script refuses and writes nothing, unless `--replace-hand-written` is given and Git holds the file.

**Exit codes and last line.**

| Exit | Output | Cause |
|---|---|---|
| 0 | nothing, or `HAND-WRITTEN-REPLACED : <file> (blob <sha>, held by Git at HEAD)` on stdout | Sheet written. |
| 1 | `usage: build-state.sh [--replace-hand-written] <chemin-projet>` | No project path. |
| 1 | `REPO-ROOT-REFUSED: ...` | The repository-root guard refused the path. |
| 1 | `ERREUR build-state.sh : gabarit de contrat introuvable (...)` | `templates/pilot-contract-template.md` is missing. |
| 1 | `ERREUR build-state.sh : le gabarit de contrat (...) porte <n> ligne(s) ...` | The contract block does not hold exactly seven lines. |
| 1 | `STATE-NOT-GENERATED : <file> exists and was not generated by build-state.sh: nothing written. ...` | A hand-written sheet, without the option. |
| 1 | `STATE-NOT-GENERATED : <file> was not generated and Git does not hold it unchanged at HEAD: --replace-hand-written refused, nothing written.` | The option was given but Git does not hold the file unchanged. |

**Reads.** `<project>/state/journal.md`; the section `## Profil du projet` of the project's `README.md` — in the state folder's parent first, then walking up to the birth certificate or the Git root, never at the workspace root; copied with its source, or one line « Aucun … (facultatif) » when absent (Mission 240); the seven lines between `CONTRACT:BEGIN` and `CONTRACT:END` in `templates/pilot-contract-template.md`; the 15 most recently modified Markdown files of the project and their `title:`; `git status -sb` of the Vault and of the project's repository ("non mesurable" when the project has no Git). Relative paths come from `tools/relpath.sh`.

**Writes.** `<project>/state/STATE.md` (creates `<project>/state/` if needed).

**Repository-root guard.** Yes, before anything is written.

**Example.** A refusal: the workspace root is not a repository.

```bash
bash <workspace>/second-brain/tools/build-state.sh <workspace>
```

## `tools/build-digest.sh`

**Role.** Regenerates `<project>/state/DIGEST.md`, the Pilot's capped opening read and the capped extract of the state sheet. Bash, apart from the Python repository-root guard it runs first; no network call, no model call. Sections, in order: Pilot contract (same seven lines as the sheet), header (generation time, last journal entry), repository state (short HEAD and `origin/main`, ahead/behind, count of porcelain lines), the last three journal lines (each cut at 300 characters with `[…]`), open door keys only, last Mission and its status, last handoff and last report (file names only).

**Called by.** `tools/project-bootstrap.sh` (at birth, only when the digest is missing); step 3 of the Executor close in `skills/session-close/SKILL.md`; read first by the Pilot per `skills/session-start/reading-list.md`. Tests: `tests/test-check-session-close.sh`, `tests/test-repo-root-guard.sh`, `tests/test-state-sheet-at-birth.sh`, `tests/test-work-regime-mode2.sh`, `tests/standalone.sh`.

**Syntax.** `build-digest.sh <chemin-projet>`

**Options.** None. The environment variable `BUILD_DIGEST_CAP_OVERRIDE=<n>` lowers the cap for tests; it is absent in normal use.

**DIGEST cap.** 8,000 bytes, fail-closed. The script sets aside 600 bytes for the page frame and splits the rest among the sections (header 5%, repositories 15%, journal 40%, doors 30%, Mission 5%, pointers 5%); a section over its share is cut at a line end with `[…] (section tronquée à <n> octets)`. The digest is then written to a temporary file and measured: over the cap, nothing is written or overwritten and the temporary file is removed.

**generated_by.** The digest carries a `generated_by:` line pointing to `tools/build-digest.sh`. An existing `<project>/state/DIGEST.md` without it is refused. There is no `--replace-hand-written` here.

**Exit codes and last line.**

| Exit | Output | Cause |
|---|---|---|
| 0 | `OK build-digest.sh : <file> écrit, <size> octets (plafond 8000).` | Digest written. |
| 1 | `usage: build-digest.sh <chemin-projet>` | No project path. |
| 1 | `REPO-ROOT-REFUSED: ...` | The repository-root guard refused the path. |
| 1 | `DIGEST-NOT-GENERATED : <file> exists and was not generated by build-digest.sh: nothing written.` | A hand-written digest. |
| 1 | `REFUS build-digest.sh : le gabarit de contrat (...) porte <n> ligne(s) ...` | The contract block does not hold exactly seven lines. |
| 1 | `REFUS build-digest.sh : digest généré à <size> octets, plafond <cap> octets. DIGEST.md non écrit (fail-closed).` | Over the cap. |

**Reads.** `<project>/state/journal.md`; `templates/pilot-contract-template.md`; Git refs of the Vault and of the project's repository; `<project>/missions/MISSION-INDEX.md` (last row, status taken from the column headed `Statut`, found by name as `templates/mission-index-template.md` requires); the last `HANDOFF-<YYYY>-...` file in `<project>/handoffs/` and the last `REPORT-<YYYY>-...` file in `<project>/reports/`, by name order. **Writes.** `<project>/state/` if it is missing, `<project>/state/.DIGEST.XXXXXX` (temporary), then `<project>/state/DIGEST.md`.

**Repository-root guard.** Yes, before anything is written.

**Example.**

```bash
bash <workspace>/second-brain/tools/build-digest.sh <workspace>/<project>
```

_Not executed by the documentation check._

## `tools/phase-report.sh`

**Role.** Reads the `PHASE:` lines of a project journal and shows how long each phase lasted. Read-only. It reads the last run only: a run restarts each time the first phase seen opens again while nothing is open.

**Called by.** No tool. Test: `tests/test-phase-report.sh`. Named in the tag rule's note of Mission 203.

**Syntax.** `phase-report.sh <chemin-projet>` (reads `<project>/state/journal.md`). No option.

**Output.** A table `phase | debut | fin | secondes`, one row per phase in journal order, then a `total` row that adds up closed phases only. A last phase still open is shown as `ouverte`.

**Exit codes and last line.** 0 with the table. 2 with `usage: phase-report.sh <chemin-projet>` when the path is missing. 1, with one `REFUS phase-report.sh : ...` line on stderr and nothing rendered, when: the journal is missing; there is no `PHASE:` line; a phase opens before the previous one is closed; a phase opens twice in the same run; a closing has no matching opening; a phase ends before it begins.

**Reads.** `<project>/state/journal.md`. **Writes.** Nothing.

**Repository-root guard.** No: it writes nothing.

**Example.**

```bash
bash <workspace>/second-brain/tools/phase-report.sh <workspace>/<project>
```

## `tools/check-session-close.sh`

**Role.** Project guardian (Mission 217): a handoff cannot enter a project without its session close. When a commit adds or modifies the newest `<project>/handoffs/HANDOFF-<YYYY>-<...>.md` of a project, the same commit must hold a `<project>/state/DIGEST.md` whose `Dernier handoff :` line names that handoff, and a `<project>/state/journal.md` with a `STATE:` (or `ETAT:`) line, right after its timestamp, later than the handoff's `created_at` (instants compared in UTC). An older handoff, or a commit with no handoff, passes without further reading.

**Called by.** Test: `tests/test-check-session-close.sh`. Named in `skills/session-close/SKILL.md`, `skills/session-start/reading-list.md` and `templates/handoff-template.md`. Its header says a project wires it in its own `<project>/.pre-commit-config.yaml`; no tracked file of this repository does so.

**Syntax and options.** `tools/check-session-close.sh`, with no argument and no option; it runs on the staged files of the repository you are in.

**Exit codes and last line.** 0: nothing to check, or every newest handoff is closed. 1: `REFUS : hors d'un depot Git : gardien non executable.`; `REFUS : git diff --cached a echoue : gardien non executable.`; or, per faulty handoff, `SESSION-CLOSE-MISSING : <handoff> entre <what is missing>` and a `Remede :` line, then the last line `REFUS : la cloture de session manque (Mission 217).` The remedy for a missing digest prints a relative command; run it with absolute paths instead.

**Reads.** The Git index only (`git diff --cached`, `git show :<path>`), never the working tree. **Writes.** Nothing.

**Repository-root guard.** No: it writes nothing.

**Example.** Read-only; passes when no handoff is staged.

```bash
cd <workspace>/<project> && bash <workspace>/second-brain/tools/check-session-close.sh
```

## The repository-root guard

`tools/repo_root_guard.py` admits a target when, walking up from it, it finds a `.git` or a birth certificate (the header of `<project>/.pre-commit-config.yaml`, read by `tools/project_baseline.py`) before any workspace root. A workspace root is a folder that carries `<workspace>/VAULT-ROOT.md`, or holds two or more Git repositories without being one. Otherwise it prints one `REPO-ROOT-REFUSED:` line naming the path received and the root expected, and the three writing scripts above stop with exit 1. It needs `uv` on the PATH. No switch turns it off ([absolute paths rule](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)); `tests/test-repo-root-guard.sh` replays the incident against each tool.

## Liens

- `source` — [Journal appender](../../tools/append-journal.sh)
- `source` — [State sheet builder](../../tools/build-state.sh)
- `source` — [Digest builder](../../tools/build-digest.sh)
- `source` — [Phase report](../../tools/phase-report.sh)
- `source` — [Session-close guardian](../../tools/check-session-close.sh)
- `source` — [Repository-root guard](../../tools/repo_root_guard.py)
- `source` — [Birth certificate reader](../../tools/project_baseline.py)
- `source` — [Relative path helper](../../tools/relpath.sh)
- `source` — [Project bootstrap](../../tools/project-bootstrap.sh)
- `source` — [Session preflight](../../tools/session-preflight.sh)
- `source` — [Pilot contract template](../../templates/pilot-contract-template.md)
- `source` — [Mission index template](../../templates/mission-index-template.md)
- `source` — [Handoff template](../../templates/handoff-template.md)
- `source` — [session-close skill](../../skills/session-close/SKILL.md)
- `source` — [Session-start reading list](../../skills/session-start/reading-list.md)
- `source` — [Tag rule](../../rules/RULES-2026-08-23-220049-activity-classification-and-system-keywords.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Decision 110935, CLOSE: tag and keyed doors](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
- `source` — [Decision 191407, 300-character pointers](../../decisions/DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)
- `source` — [Decision 012458, generated state sheet](../../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md)
- `source` — [Repository-root guard test](../../tests/test-repo-root-guard.sh)
- `source` — [Phase report test](../../tests/test-phase-report.sh)
- `source` — [Session-close guardian test](../../tests/test-check-session-close.sh)
- `source` — [State sheet at birth test](../../tests/test-state-sheet-at-birth.sh)
- `source` — [Mode 2 work regime test](../../tests/test-work-regime-mode2.sh)
- `source` — [End-to-end install test](../../tests/test-install-e2e.sh)
- `source` — [End-to-end install test, Windows](../../tests/test-install-e2e.ps1)
- `source` — [Prerequisites end-to-end test, Windows](../../tests/test-prerequisites-e2e.ps1)
- `source` — [Nominal flow test](../../tests/test-nominal-flow-no-atelier-vocabulary.sh)
- `source` — [Nominal flow test, Windows](../../tests/test-nominal-flow-no-atelier-vocabulary.ps1)
- `source` — [Standalone test](../../tests/standalone.sh)
- `see also` — [Close a session](../how-to/close-a-session.md)
- `see also` — [Open a session](../how-to/open-a-session.md)
- `see also` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `see also` — [Guardian tools](./tools-guardians.md)
- `see also` — [Project tools](./tools-projects.md)
- `see also` — [Internal helpers](./tools-internal-helpers.md)
- `see also` — [Formats](./formats.md)
- `see also` — [The two roles](../explanation/two-roles.md)
