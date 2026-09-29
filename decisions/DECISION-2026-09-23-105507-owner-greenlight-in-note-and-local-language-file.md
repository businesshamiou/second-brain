---
type: decision
title: "The Owner's go-ahead on a full-regime criterion is quoted word for word in the mode-2 Note, and a Vault's local language lives in an unversioned file read before USER.md"
description: "Engraves two Owner arbitrations of 2026-09-23 09:08. First: when a prompt of the Owner meets a full-regime criterion, the Executor asks; the answer is written word for word in the mode-2 Note (one owner_greenlight block, real time, the criteria it lifts), and execution goes on under the light regime; tools/check-work-regime.sh lifts only the criteria named. Second: a local, unversioned file, USER.local.yaml, carries language: for one Vault and is read before USER.md; the distributed USER.md skeleton stays empty. Amends Decision 012500 (D-C) and Decision 012459 (D-B)."
created_at: "2026-09-23T10:55:07-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "./DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md"
  - "./DECISION-2026-09-23-012459-owner-language-recorded-rendered-fixed-sentence.md"
  - "../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md"
  - "../templates/execution-note-template.md"
---

# DECISION — THE OWNER'S GO-AHEAD QUOTED IN THE NOTE; A LOCAL LANGUAGE FILE

## Date

2026-09-23

## Status

`ARBITRATED`

## Measured problem

1. Decision 012500 (D-C) says a full-regime criterion met by an Owner's prompt is a refusal only when "the Owner has not lifted" it; rule 012259 §3 says "no argument extends what the light regime accepts". The tool stayed closed: it refused, and nothing said what trace a go-ahead leaves (report of Mission 218, « À trancher » 1).
2. The laboratory Vault's `USER.md` is the distributed skeleton: it records no language, so every Pilot prompt it renders carries the fallback sentence. Recording `language: fr` in that file would publish the laboratory's language in the skeleton (report of Mission 218, « À trancher » 3).

## Decision

1. **The go-ahead is quoted in the Note.** When an Owner's prompt (mode 2) meets a full-regime criterion (`R1`–`R6` of rule 012259), the Executor does not refuse: it states the criterion and asks. The Owner's answer is written word for word in the Note's Intent, in exactly one fenced block whose info string is `owner_greenlight`: a line `at: <real time of the answer, ISO 8601 with offset>`, a line `lifts: <criterion id>[, <criterion id>...]`, then the answer as received. Execution then goes on under the light regime.
2. **What the check does.** `tools/check-work-regime.sh note` lifts only the criteria the block names, and prints `OWNER-GREENLIGHT <ids> at <time>` before `REGIME-LIGHT-OK`. It refuses (`R8-origin`) a block without time, without answer or without `lifts:`, a second block, a block naming anything but `R1`–`R6`, and a block in a Note whose origin is not `owner-prompt`. The form (`R7-shape`, `R8-origin`) is never lifted. Without the block, a mode-2 Note meeting a criterion is refused with the instruction to ask the Owner. The block, like the prompt block, is not counted in the size cap.
3. **What does not move.** The gestures reserved to the Owner stay reserved (role charter §3): a go-ahead in a Note never makes the Executor push without a delegation by clear expression, nor delete permanently.
4. **A local language file.** `USER.local.yaml`, at the root of a Vault, one line `language: <fr|en|es>`, never versioned (`.gitignore`) and never distributed (`tools/check-distribution-manifest.sh` refuses it, named, whether listed or force-added). `tools/project-bootstrap.sh` reads it before the `language:` field of `USER.md`; without it, Decision 012459 applies unchanged. The distributed `USER.md` skeleton keeps an empty `language:`.
5. **The byte-order mark.** Every tool that reads the front matter of `USER.md` tolerates the UTF-8 byte-order mark that Windows PowerShell 5.1 writes at its head (measured list: `project-bootstrap.sh`, `build_indexes.py`, `check_indexes_fresh.py`, `find-in-vault.sh`, `check-asserted-paths.sh`, `check-obsolescence-guardrail.py`).

Owner's choices, verbatim (multiple-choice questions of the Pilot, 2026-09-23 09:08): « Note avec feu vert cité (Recommandé) » ["Note with the go-ahead quoted (Recommended)"]; « Fichier local non publié (Recommandé) » ["Unpublished local file (Recommended)"].

## Reason

A go-ahead that lives only in a chat window is not auditable afterwards; a Mission written for the sole purpose of carrying one sentence of consent is the fixed ceremony the light regime exists to avoid. The Note already carries the Owner's prompt verbatim and its fingerprint: its answer belongs next to it, with its time and the criteria it covers, and the check keeps refusing everything it does not name.

A language is a fact of one machine's Vault, not of the distribution: an unversioned file keeps the skeleton neutral for every participant while letting the laboratory speak French.

## Impact

- `tools/check-work-regime.sh`, `templates/execution-note-template.md`, rule 012259 §3 and §4.
- `tools/project-bootstrap.sh`, `.gitignore`, `tools/check-distribution-manifest.sh`, and the five front-matter readers named above.
- `CONTEXT.md`: the Executor's definition names both relay modes.
- Tests: `tests/test-work-regime-owner-greenlight.sh`, `tests/test-lab-language-local-file.sh`.

## Important alternatives

- A Mission for every go-ahead: rejected by the Owner, it restores the fixed floor.
- `language: fr` written in the laboratory's `USER.md`: rejected, it would publish the laboratory's language in the distributed skeleton.
- A local `.md` file: rejected, `tools/build_indexes.py` walks the folder and would index an untracked file.

## Human gate

- Validation: granted
- Reference: Owner, Pilot session of 2026-09-23 at 09:08, multiple-choice questions of the Pilot, quoted under "Decision"; recorded in Mission 219 (workshop history, not distributed).

## Linked artefacts

- Mission 219 and its report (workshop history, not distributed).

## Liens

- `amends` — [Decision — Two relay modes](./DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md)
- `amends` — [Decision — Language recorded once, rendered per project](./DECISION-2026-09-23-012459-owner-language-recorded-rendered-fixed-sentence.md)
- `amends` — [Two work regimes: the light Note and the full Mission](../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)
- `amends` — [Template — execution Note](../templates/execution-note-template.md)
- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
