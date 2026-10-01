---
name: session-close
description: "Close a work session: inventory holes, refuse while any remain, then the handoff (Pilot) or the closing commit (Executor). Use when the Owner ends the session. Triggers on: « wrap », « on ferme », « clôture », « clos la session », \"close\"."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md, rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  vault-validated: "2026-09-08T00:40:13-04:00"
---

Closes a work session: inventories the holes, refuses to close as long as one remains, then produces the handover. This skill is **never triggered on its own**: the Owner launches it with the word « wrap » (or « close », « on ferme » ["we're closing"]) — `commande` principle, DECISION-144931 §2. On the Executor surface, the fixed command is `/session-close`. It pushes nothing, deletes nothing, settles nothing.

## The situations of a close

Mission 244: the close **starts in the Pilot** — the Pilot writes the handoff that the next Pilot session consumes — and the Executor does its part afterwards. Seven situations, each with its path; `sb close` in an Executor window measures which one applies (the pieces filed since the last `STATE:` line of the journal, and the push state of each repository).

| Situation | Path |
|---|---|
| Welcome session (profile, idea, orders) | `sb close` in the welcome Pilot: the measured list of the orders written and waiting (`<workspace>/_orders/`, today's `<workspace>/_archive/orders/`), nothing else to record, no handoff; offer to write an idea left spoken as an initiation order. In a terminal at the workspace root: `sb close --accueil` |
| Project just created, nothing else | already committed by `tools/project-bootstrap.sh`; `sb close` = light close |
| Pilot session that produced nothing | Pilot: « rien à consigner » [nothing to record] and the light closing command; Executor: `sb close --light` — one `STATE:` line, state sheet, digest, commit of those three files |
| Normal work session (Missions, RELAY) | Pilot (holes, handoff, capture, closing command), then Executor (journal, state sheet, digest, commit) — §2 and §3 below |
| Client Vault whose `origin` is the public repository | no push hole for that remote: it is the distribution repository, never a push target (`closing-checklist.md` line 6) |
| Project or Vault with a remote of the Owner | push hole unchanged; a push only on the Owner's delegation, through `tools/verified-push.sh` |
| Executor alone, no Pilot | `sb close` in the Executor, no handoff: a light close when no Mission, report or Pilot artefact waits; otherwise it names what waits and the Owner's gesture in plain words (« in the project's Pilot, write `sb close` »), without jargon |

**Light close.** A session with no Mission opened or closed, no RELAY and no Pilot artefact filed needs **no** handoff. The Pilot says so and returns the light closing command; the Executor writes one `STATE:` line, runs the Vault's `tools/build-state.sh` and `tools/build-digest.sh` and commits the three state files — `sb close --light` does exactly that — **without an execution Note**: it is a planned path of this skill, not an order outside a Mission (Decision 012500 unchanged). `tools/check-session-close.sh` accepts it: it asks nothing of a commit that brings in no handoff.

## 1. Determine your surface, mechanically

Try a harmless shell gesture (`git --version`). It answers → **Executor** branch (§3). No shell → **Pilot** branch (§2). The measured capability decides.

## 2. Pilot branch (chat)

0. **Light close first.** If this session opened or closed no Mission, received no RELAY and filed no artefact (capture, proposal, decision, Mission), say « rien à consigner » [nothing to record], file nothing, and return the light closing command for an Executor window (`sb close --light`); stop there. After a welcome session, list `<workspace>/_orders/` and today's `<workspace>/_archive/orders/` (measured, never from memory) and offer to write an idea left spoken as an initiation order; a welcome session has no handoff.
1. **Inventory of the holes, measured.** Open `closing-checklist.md` in this skill's folder and run each line with the tool it names. **Name this file in your answer** — "`closing-checklist.md` run, N lines": a list of holes of which nobody knows which checklist it comes from is not a measurement (Mission 153, fault measured in report 152).
   Tools per line (MCP: `read_text_file`, `get_file_info`, `search_files`). A hole is observed, never assumed. The families of holes are those of `closing-checklist.md`, single source; this file holds no enumeration of them — an enumeration copied here falls behind as soon as a line is added there, and it had fallen two behind (report 157, §7).
2. **One hole → refusal to close.** Return the list of holes, each with the action that would close it (Mission to write, Owner arbitration, Owner's prompt to an Executor — mode 2, traced by an execution Note). You do not close; you wait for the Owner's word on each hole. A "we'll see later" residue is an arbitrated hole only if the Owner said so.
3. **Zero holes → handover.** File at the canonical location, in this order: the **handoff** (the Vault's `templates/handoff-template.md` template, the project's `handoffs/` folder) then the **capture** (the Vault's `templates/capture-template.md` template, `captures/` folder). Filing pattern: `DRAFT-…` → `get_file_info` → measured timestamp → final rename → final `get_file_info`, in a single turn. The handoff carries, for each fact, VERIFIED or DECLARED, and an ordered resume queue with **one exact word per point** (the word the Owner will paste). The capture lists the session's Pilot faults, one per line, dated.
4. **Return the Executor closing command**: a snippet, five rubrics (RULES-124937), carrying the four standard prohibitions only and pointing to the handoff by its path. Nothing else: the Executor close is fixed by §3 of this skill, not by free text. The same snippet is filed inside the handoff, in its `## Executor closing command` section (Mission 217): a handoff without its close is refused at the commit by `tools/check-session-close.sh`.

## 3. Executor branch (Claude Code, `/session-close`)

0. Run `sb close` (or `/sb:close`, `$sb close`) and read the situation it measured. **Light**: `sb close --light`, then the RELAY; nothing else. **Full, with a handoff**: go on from step 1. **Full, without a handoff** (Executor alone): name what waits and the Owner's gesture in plain words — « in the project's Pilot, write `sb close`: it writes the handoff and hands you the closing command » — and stop.
1. Awareness of position (current directory, repository, relative paths to the root of the Vault — found by walking up to the `VAULT-ROOT.md` marker, never a hard-coded folder named `vault` — and to the project's repository), then read the **handoff named** by the closing command, in full.
2. **Journal** (the project's `state/journal.md`, through the Vault's `tools/append-journal.sh`): a closing `STATE:` line — heads of the two repositories, lead over `origin`, remaining open doors; then the `CLOSE: <clé> -- <référence>` lines that the handoff prescribes, **one per door, exact key** (DECISION-110935). No `CLOSE:` that the handoff does not name. Every `STATE:`/`CLOSE:`/`REPRISE:` line is a pointer ≤ 300 characters (DECISION-191407) — `append-journal.sh` refuses it fail-closed otherwise (Mission 123): draft the pointer, leave the narrative to the report or the handoff.
3. The Vault's `tools/build-state.sh` on the project, then the Vault's `tools/build-digest.sh` on the same project (Mission 121, capped opening digest); `MISSION-INDEX.md` up to date (every Mission closed during the session carries its final state); the Vault's `tools/build-indexes.sh` on the touched roots only.
4. **One commit per touched repository**, file by file, diff inspected, never `git add .`; the hook's output pasted. Guardian refusal = **STOP** with verbatim, no workaround, no override.
5. **If the Vault received a commit during the session**: read how `<projet>/.pre-commit-config.yaml` wires the guardians. With `repo: local`, entries under the Vault's `tools/` reached by relative path and no `rev:` line — the wiring `tools/project-bootstrap.sh` lays — the hooks run the Vault's working tree as it is: **there is nothing to re-pin** (measured Mission 221). Only a remote `repo:` carrying a `rev:` is behind: its reference of truth is **`origin/main`** of that repository (measurement Mission 155), so re-pinning is possible **only after the Owner push**; as long as the push has not taken place, it is a **hole carried to the handoff**, never a pin laid on a local commit; after the push, re-pin on the pushed SHA and commit `re-épinglage sur <SHA>` [re-pinning on <SHA>].
6. Closing RELAY: the RELAY block of rule 124937, at the end of the window.

## 4. Canary

Before any gesture, the templates `handoff-template.md` and `capture-template.md` exist in the Vault's `templates/` (`get_file_info` or `test -f`). A missing template → `NOT-READY`, no close, the repair is a Mission.

## What this skill does not do

Open a session (`session-start`) · push (Owner gesture, delegated by named instruction only, then through `tools/verified-push.sh` with the absolute path of the repository) · settle a hole (the Owner) · fabricate or rewrite a Mission (`mission-writing`) · invent a `CLOSE:` line absent from the handoff · close with a "minor" hole.

## Liens

- `see also` — [List of closing holes, one measurement per line](./closing-checklist.md)
- `applies` — Decision — End of the skills V1 pass (workshop history, not distributed) (hors Vault)
- `applies` — [Decision — CLOSE: tag and keyed doors of the journal](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
- `applies` — [Decision — Journal and index as pointers](../../decisions/DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)
- `applies` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Relay between roles through mini-prompts with fixed rubrics](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Handoff template](../../templates/handoff-template.md)
- `see also` — [Capture template](../../templates/capture-template.md)
