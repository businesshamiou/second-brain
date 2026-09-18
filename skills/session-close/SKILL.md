---
name: session-close
description: "Close a work session: inventory holes, refuse to close while any remain, then produce the handoff and capture (Pilot) or the closing commit (Executor). Use when the Owner says wrap, close, or asks to end the session. Triggers on: « wrap », « on ferme », « clôture », « clos la session », \"close\"."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md, rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  vault-validated: "2026-09-08T00:40:13-04:00"
---

Closes a work session: inventories the holes, refuses to close as long as one remains, then produces the handover. This skill is **never triggered on its own**: the Owner launches it with the word « wrap » (or « close », « on ferme » ["we're closing"]) — `commande` principle, DECISION-144931 §2. On the Executor surface, the fixed command is `/session-close`. It pushes nothing, deletes nothing, settles nothing.

## 1. Determine your surface, mechanically

Try a harmless shell gesture (`git --version`). It answers → **Executor** branch (§3). No shell → **Pilot** branch (§2). The measured capability decides.

## 2. Pilot branch (chat)

1. **Inventory of the holes, measured.** Open `closing-checklist.md` in this skill's folder and run each line with the tool it names. **Name this file in your answer** — "`closing-checklist.md` run, N lines": a list of holes of which nobody knows which checklist it comes from is not a measurement (Mission 153, fault measured in report 152).
   Tools per line (MCP: `read_text_file`, `get_file_info`, `search_files`). A hole is observed, never assumed. The families of holes are those of `closing-checklist.md`, single source; this file holds no enumeration of them — an enumeration copied here falls behind as soon as a line is added there, and it had fallen two behind (report 157, §7).
2. **One hole → refusal to close.** Return the list of holes, each with the action that would close it (Mission to write, Owner arbitration, one-off instruction). You do not close; you wait for the Owner's word on each hole. A "we'll see later" residue is an arbitrated hole only if the Owner said so.
3. **Zero holes → handover.** File at the canonical location, in this order: the **handoff** (the Vault's `templates/handoff-template.md` template, the project's `handoffs/` folder) then the **capture** (the Vault's `templates/capture-template.md` template, `captures/` folder). Filing pattern: `DRAFT-…` → `get_file_info` → measured timestamp → final rename → final `get_file_info`, in a single turn. The handoff carries, for each fact, VERIFIED or DECLARED, and an ordered resume queue with **one exact word per point** (the word the Owner will paste). The capture lists the session's Pilot faults, one per line, dated.
4. **Return the Executor closing command**: a snippet, five rubrics (RULES-124937), carrying the four standard prohibitions only and pointing to the handoff by its path. Nothing else: the Executor close is fixed by §3 of this skill, not by free text.

## 3. Executor branch (Claude Code, `/session-close`)

1. Awareness of position (current directory, repository, relative paths to the root of the Vault — found by walking up to the `VAULT-ROOT.md` marker, never a hard-coded folder named `vault` — and to the project's repository), then read the **handoff named** by the closing command, in full.
2. **Journal** (the project's `state/journal.md`, through the Vault's `tools/append-journal.sh`): a closing `STATE:` line — heads of the two repositories, lead over `origin`, remaining open doors; then the `CLOSE: <clé> -- <référence>` lines that the handoff prescribes, **one per door, exact key** (DECISION-110935). No `CLOSE:` that the handoff does not name. Every `STATE:`/`CLOSE:`/`REPRISE:` line is a pointer ≤ 300 characters (DECISION-191407) — `append-journal.sh` refuses it fail-closed otherwise (Mission 123): draft the pointer, leave the narrative to the report or the handoff.
3. The Vault's `tools/build-state.sh` on the project, then the Vault's `tools/build-digest.sh` on the same project (Mission 121, capped opening digest); `MISSION-INDEX.md` up to date (every Mission closed during the session carries its final state); the Vault's `tools/build-indexes.sh` on the touched roots only.
4. **One commit per touched repository**, file by file, diff inspected, never `git add .`; the hook's output pasted. Guardian refusal = **STOP** with verbatim, no workaround, no override.
5. **If the Vault received a commit during the session**: the pin of `<projet>/.pre-commit-config.yaml` is behind. Its reference of truth is the one `repo:` designates — **a remote repository, hence `origin/main`** (measurement Mission 155): re-pinning is possible **only after the Owner push**. As long as the push has not taken place, it is a **hole carried to the handoff**, never a pin laid on a local commit. After the push: re-pin on the pushed SHA, commit `re-épinglage sur <SHA>` [re-pinning on <SHA>], then regenerate `_dist/skills-chat/` with the Vault's `tools/build-skills-chat-package.sh` and check that `MANIFEST.txt` carries that same SHA.
6. Closing RELAY: the RELAY block of rule 124937, at the end of the window.

## 4. Canary

Before any gesture, the templates `handoff-template.md` and `capture-template.md` exist in the Vault's `templates/` (`get_file_info` or `test -f`). A missing template → `NOT-READY`, no close, the repair is a Mission.

## What this skill does not do

Open a session (`session-start`) · push (Owner gesture, delegated by named instruction only) · settle a hole (the Owner) · fabricate or rewrite a Mission (`ecriture-de-mission`) · invent a `CLOSE:` line absent from the handoff · close with a "minor" hole.

## Liens

- `see also` — [List of closing holes, one measurement per line](./closing-checklist.md)
- `applies` — Decision — End of the skills V1 pass (workshop history, not distributed) (hors Vault)
- `applies` — [Decision — CLOSE: tag and keyed doors of the journal](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
- `applies` — [Decision — Journal and index as pointers](../../decisions/DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)
- `applies` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Relay between roles through mini-prompts with fixed rubrics](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Handoff template](../../templates/handoff-template.md)
- `see also` — [Capture template](../../templates/capture-template.md)
