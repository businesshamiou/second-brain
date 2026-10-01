---
type: how-to
title: "Close a session"
description: "How to close a work session with the session-close skill: the Pilot's inventory of holes, handoff and capture, the Executor's journal lines, digest and commit, the guardian that refuses a handoff without its close, and the delegated push that may follow."
status: active
---

# CLOSE A SESSION

A session is closed in two halves. The **Pilot** (chat) checks that nothing is left open, then writes a handoff and a capture. The **Executor** (Claude Code or Codex) writes the closing lines into the project journal, regenerates the state sheet and the digest, and commits. Both halves use the same skill, `session-close` ([skill](../../skills/session-close/SKILL.md)). A guardian, `tools/check-session-close.sh`, refuses a commit that brings in a handoff without its close.

**Under Windows.** The `bash <workspace>/second-brain/tools/…` lines of this page are typed by the Executor, in its own shell (Git Bash under Windows). To type one yourself in PowerShell, where `bash` is unknown, replace `bash` with `& "C:\Program Files\Git\bin\bash.exe"`, or type the `sb` verb that carries the gesture ([Commands](../reference/commands.md)); `sb doctor` says whether `bash` is on your PATH.

## Before you start

- The skill never starts on its own. You launch it with the verb `sb close` — first **in the Pilot**, as a message, then in the Executor window, as one complete block that starts with an order sentence — `You are the Executor. In <project folder>, run: sb close. Show the output as it is.` (in your language: `Tu es l'Executor. …`, `Eres el Executor. …`) — valid in any Executor, with or without the plugin (Mission 245; the shortcuts you may type yourself: [Commands](../reference/commands.md)), or by saying `wrap` or `close` (in French, `on ferme`, `clôture`); on the Executor surface `/session-close` also works. `sb handoff` writes a handoff without closing. It pushes nothing, deletes nothing and settles nothing ([skill](../../skills/session-close/SKILL.md)).
- The skill picks its branch by measurement: it tries `git --version`. If a shell answers, it runs the Executor branch; if not, the Pilot branch.
- Canary: `templates/handoff-template.md` and `templates/capture-template.md` must exist in the Vault. If one is missing, the answer is `NOT-READY`, nothing is closed, and the repair is a Mission.
- `<workspace>` below is the absolute path of your workspace (for example `C:/Users/you/Workspaces`), the installed Vault is `<workspace>/second-brain`, and your project is `<workspace>/<project>` ([absolute paths rule](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)).

## Which close is yours: seven situations

The close **starts in the Pilot**: it writes the handoff the next Pilot session reads; the Executor does its part afterwards. `sb close` is marked *Pilot: yes* ([Commands](../reference/commands.md)): in the Pilot, as a message, it runs the Pilot half; in an Executor window it runs the Executor half and first prints the **situation** it measured — the pieces filed since the last `STATE:` line of the journal — and one **Push** line per repository.

| Situation | Where to type what |
|---|---|
| Welcome session (profile, idea, orders) | **In the welcome Pilot:** `sb close`. It lists the orders written and still waiting (`<workspace>/_orders/`) and those applied today (`<workspace>/_archive/orders/`), measured; nothing else to record, no handoff. An idea you only spoke about: ask it to write it as an initiation order, or it is lost. **In the terminal**, at the workspace root: `sb close --accueil` prints the same list. |
| Project just created, nothing else | Nothing to do by hand: `tools/project-bootstrap.sh` already committed the project and the Vault's registry. `sb close` shows a light close. |
| Pilot session that produced nothing | **In the Pilot:** `sb close` answers « rien à consigner » and gives the light closing block. **In the Executor:** paste that block — `You are the Executor. In <project folder>, run: sb close --light. Show the output as it is.` —; `sb close --light` writes one `STATE:` line, regenerates the state sheet and the digest, and commits those three files. No handoff, no execution Note. |
| Normal work session (Missions, RELAY) | **In the Pilot:** `sb close` — holes, handoff, capture, closing command (steps 1 to 3 below). **In the Executor:** paste the closing command (steps 4 to 7). |
| Your Vault's `origin` is the public Second Brain repository | No push hole for it: it is the **distribution repository** you installed from, never a push target. Your Vault is always ahead of it (the installer's commits, your profile, your projects); that is normal. |
| A project or a Vault with a remote of yours | The push hole stays: pushing is your gesture, or delegated by you (step 8). |
| Executor alone, no Pilot | **In the Executor:** `You are the Executor. In <project folder>, run: sb close. Show the output as it is.` A light close when nothing waits; otherwise it says what waits and your gesture in plain words: **in the project's Pilot**, write `sb close`. |

## Steps

### 1. Pilot: inventory the holes

The Pilot opens `skills/session-close/closing-checklist.md` and runs each of its lines with the tool the line names. It names that file in its answer ("closing-checklist.md run, N lines"). A hole is observed, never assumed. The list is the single source; today it has eight families ([checklist](../../skills/session-close/closing-checklist.md)):

| # | Hole |
|---|---|
| 1 | A Mission in `<project>/missions/MISSION-INDEX.md` without a final state |
| 2 | A RELAY block received and not consumed |
| 3 | A Pilot artefact filed but not tracked by Git |
| 4 | An `OPEN:` door in the journal whose condition is met, without a later `CLOSE:` |
| 5 | A flagged residue without an Owner arbitration |
| 6 | A local head different from `origin/main` on a remote of yours, without your word on the push (never the distribution repository of an installed Vault) |
| 7 | A previous handoff whose resume queue was neither run nor arbitrated |
| 8 | A pin behind in `<project>/.pre-commit-config.yaml` (only a remote `repo:` with a `rev:` line) |

Before the list, the light close: a session with no Mission opened or closed, no RELAY received and no artefact filed needs no handoff; the Pilot says « rien à consigner » and returns the light closing block for the Executor, complete with its order sentence: `You are the Executor. In <project folder>, run: sb close --light. Show the output as it is.` (in your language; never the command alone, which an Executor may refuse — Mission 245).

**One hole means no close.** The Pilot returns the list, each hole with the action that would close it: a Mission to write, your arbitration, or your prompt to an Executor (mode 2, traced by an execution Note). It waits for your word on each one. "We'll see later" counts as settled only if you said it.

### 2. Pilot: file the handoff, then the capture

With zero holes, the Pilot files, in this order:

1. The **handoff**, from `templates/handoff-template.md`, in `<project>/handoffs/`. Each fact carries `VERIFIED` or `DECLARED`, and the resume queue gives one exact word per point, the word you will paste.
2. The **capture**, from `templates/capture-template.md`, in `<project>/captures/`: the session's Pilot faults, one per line, dated.

Each file goes through the same filing pattern in one turn: a `DRAFT-…` file, a `get_file_info`, the measured timestamp, the final rename, a final `get_file_info`.

### 3. Pilot: return the Executor closing command

The Pilot returns a snippet with the five rubrics of the relay rule ([relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)): title line, « Position », « Source à appliquer » (the handoff, by its path), « Interdits absolus » (the four standard prohibitions only), « Sortie attendue ». The same snippet is filed inside the handoff, in its `## Executor closing command` section. That section is mandatory: the template's own wording is the model ([handoff template](../../templates/handoff-template.md)):

```text
Session Executor — Close (<session>)

Position : free.

Source à appliquer : the `session-close` skill, Executor branch, on <relative path of this handoff>. [...]

Interdits absolus : no non-delegated git push, no model call, no deletion; move to `_trash/` only on a Mission's prescription; every write or push command names the absolute path of its repository, and a push goes through tools/verified-push.sh.

Sortie attendue : end the window with the RELAY block of rule 124937, filled in.
```

You paste it into the Executor window.

### 4. Executor: position, then the handoff

The Executor establishes its position (current directory, repository, the Vault found by walking up to `<workspace>/VAULT-ROOT.md`, never a hard-coded folder name), then reads the handoff named by the closing command, in full.

### 5. Executor: the journal lines

Through `tools/append-journal.sh`, the Executor writes a closing `STATE:` line (heads of the two repositories, lead over `origin`, remaining open doors), then the `CLOSE:` lines the handoff prescribes, one per door, exact key. No `CLOSE:` the handoff does not name. Each text is at most 300 characters. A door key matches `open-…` or `frozen-…` and is followed by ` -- ` ([build-state.sh header](../../tools/build-state.sh)).

```bash
bash <workspace>/second-brain/tools/append-journal.sh <workspace>/<project> "STATE: close -- vault <sha>, project <sha>, ahead <n>, doors: <keys or none>"
bash <workspace>/second-brain/tools/append-journal.sh <workspace>/<project> "CLOSE: open-<key> -- <reference>"
```
_Not executed by the documentation check._

### 6. Executor: state sheet, digest, indexes

```bash
bash <workspace>/second-brain/tools/build-state.sh <workspace>/<project>
bash <workspace>/second-brain/tools/build-digest.sh <workspace>/<project>
bash <workspace>/second-brain/tools/build-indexes.sh <workspace>/<project>/<touched folder>
```
_Not executed by the documentation check._

`<project>/missions/MISSION-INDEX.md` must give every Mission closed during the session its final state. `tools/build-indexes.sh` runs on the touched roots only, never on the workspace root.

### 7. Executor: one commit per touched repository

File by file, diff inspected, never `git add .`; the hook's output is pasted. A guardian refusal means **STOP**, verbatim, with no workaround and no override.

```bash
git -C <workspace>/<project> add handoffs/<handoff file> state/journal.md state/STATE.md state/DIGEST.md
git -C <workspace>/<project> commit -m "<message>"
```
_Not executed by the documentation check._

If the Vault received a commit during the session, the Executor reads how `<project>/.pre-commit-config.yaml` wires the guardians. With `repo: local` and no `rev:` line (the wiring `tools/project-bootstrap.sh` lays), there is nothing to re-pin. Only a remote `repo:` with a `rev:` is behind: it can be re-pinned only after your push, on the pushed SHA; before the push, it is a hole carried to the handoff.

The window ends with the RELAY block of the relay rule.

### 8. After a delegated push

Pushing is your gesture. The Executor pushes only if you delegate it: a clear expression that names the gesture and its target, one per gesture. The push then goes through `tools/verified-push.sh` with the absolute repository path and the exact range; a project declares no remote, so it takes `--url` ([verified-push.sh](../../tools/verified-push.sh)). Check first with `--dry-run`, which pushes nothing:

```bash
bash <workspace>/second-brain/tools/verified-push.sh <workspace>/<project> <from>..<to> origin --url <url> --dry-run
bash <workspace>/second-brain/tools/verified-push.sh <workspace>/<project> <from>..<to> origin --url <url>
```
_Not executed by the documentation check._

The RELAY block's « Poussées » rubric reports what was actually pushed, measured by `git ls-remote`.

## What you should see

- Pilot: "closing-checklist.md run, N lines", then either the list of holes or the two filed paths and the closing command.
- Executor: one or more new lines (the `STATE:` line, then any `CLOSE:` lines) at the end of `<project>/state/journal.md`, a regenerated `<project>/state/STATE.md` and `<project>/state/DIGEST.md` whose `Dernier handoff :` line names the new handoff, one commit per touched repository with the hook output pasted.
- Push: last line `WOULD-PUSH <remote> <branch> <from>..<to> (<url>)` for a dry run, `PUSHED <remote> <branch> <from>..<to>` for a real push, exit 0.
- Next opening: when the digest names the newest handoff, there is no `NOT-READY (session close missing)`. A digest stale by one line after a pushed close is the ordinary case ([reading list](../../skills/session-start/reading-list.md)).

To check the guardian by hand before committing (it only reads the Git index):

```bash
cd <workspace>/<project> && bash <workspace>/second-brain/tools/check-session-close.sh
```

No output and exit 0: accepted, or no handoff staged (then it reads nothing).

## The guardian and the NOT-READY verdict

`tools/check-session-close.sh` acts when a commit adds or modifies the project's **newest** handoff (`<project>/handoffs/HANDOFF-<YYYY>-….md`, newest by name in the index). It then requires, in the same commit, `<project>/state/DIGEST.md` naming that handoff on its `Dernier handoff :` line, and `<project>/state/journal.md` carrying a `STATE:` line later than the handoff's `created_at`, compared in UTC. A correction to an older handoff demands nothing. It reads the index, never the working tree, and refuses when the DIGEST, the journal or the `created_at` is missing. A project wires it in its `<project>/.pre-commit-config.yaml`; `tools/project-bootstrap.sh` does not wire it (the guardian's header calls that a separate door).

At the next opening, if the listing of `<project>/handoffs/` holds a handoff newer than the one the digest names, the Pilot's verdict is `NOT-READY (session close missing)`. The first gesture is then the `## Executor closing command` of that newest handoff, not its resume queue ([reading list, point 4](../../skills/session-start/reading-list.md)).

## Known errors

| Message | Cause | What to do |
|---|---|---|
| `SESSION-CLOSE-MISSING : <handoff> entre sans DIGEST qui le nomme (aucun state/DIGEST.md dans l'index)` | the digest is not staged | run `tools/build-digest.sh` on the project, stage the digest with the handoff |
| `… sans DIGEST qui le nomme (le DIGEST de l'index nomme « <name> »)` | digest generated before the handoff was filed | regenerate it after the handoff is on disk, stage it |
| `… sans created_at lisible` | handoff front matter lacks an ISO `created_at` | give it `YYYY-MM-DDTHH:MM:SS+HH:MM` |
| `… sans ligne STATE: postérieure …` | no journal staged, or no `STATE:` line later than `created_at` in UTC | write the closing `STATE:` line with `tools/append-journal.sh`, stage the journal |
| `REFUS : hors d'un depot Git : gardien non executable.` | guardian run outside a repository | run it from inside the project |
| `REFUS append-journal.sh : ligne de <n> caracteres, plafond 300 …` | journal text over 300 characters | shorten it to a pointer; the narrative goes in the handoff or report |
| `DIGEST-NOT-GENERATED : …` | a `<project>/state/DIGEST.md` not written by `tools/build-digest.sh` | stop; nothing was written |
| `REFUS build-digest.sh : digest généré à <n> octets, plafond 8000 octets …` | digest over its cap | stop; the digest is not written |
| `VERIFIED-PUSH-REFUSED: <reason>. Nothing pushed.` | relative path, bad range, HEAD not `<to>`, remote head not `<from>`, undeclared URL, `<to>` not descending, a force option | fix the cause the reason names; never push by another way |
| `NOT-READY (session close missing)` | a handoff filed without its close | paste that handoff's Executor closing command |

The guardian's remedies print relative forms (`bash tools/build-digest.sh …`); write them with absolute paths as in the steps above.

## Scripts used

- `tools/append-journal.sh` — [State and journal tools](../reference/tools-state-and-journal.md)
- `tools/build-state.sh`, `tools/build-digest.sh` — [State and journal tools](../reference/tools-state-and-journal.md)
- `tools/build-indexes.sh` — [Index and link tools](../reference/tools-indexes-and-links.md)
- `tools/check-session-close.sh` — [Guardian tools](../reference/tools-guardians.md)
- `tools/verified-push.sh` — [Publication and push tools](../reference/tools-publication-and-push.md)

## Liens

- `source` — [session-close skill](../../skills/session-close/SKILL.md)
- `source` — [List of closing holes](../../skills/session-close/closing-checklist.md)
- `source` — [Handoff template](../../templates/handoff-template.md)
- `source` — [Capture template](../../templates/capture-template.md)
- `source` — [Session-close guardian](../../tools/check-session-close.sh)
- `source` — [Session opening reading list, point 4](../../skills/session-start/reading-list.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Relay between roles through mini-prompts](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [append-journal.sh](../../tools/append-journal.sh)
- `source` — [build-state.sh](../../tools/build-state.sh)
- `source` — [build-digest.sh](../../tools/build-digest.sh)
- `source` — [build-indexes.sh](../../tools/build-indexes.sh)
- `source` — [build_indexes.py](../../tools/build_indexes.py)
- `source` — [verified-push.sh](../../tools/verified-push.sh)
- `source` — [project-bootstrap.sh](../../tools/project-bootstrap.sh)
- `see also` — [Open a session](open-a-session.md)
- `see also` — [Delegate and push](delegate-and-push.md)
- `see also` — [React to a guardian refusal](react-to-a-guardian-refusal.md)
- `see also` — [Run a Mission as Executor](run-a-mission-as-executor.md)
- `see also` — [Why absolute paths](../explanation/why-absolute-paths.md)
