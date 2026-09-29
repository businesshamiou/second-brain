---
type: decision
title: "State sheet — one name, generated, created at birth: STATE.md carries the contract, DIGEST.md is its capped extract, the Pilot prompt names its path"
description: "Engraves the Owner arbitration of 2026-09-23 (D-A): a project's state sheet is <projet>/state/STATE.md, generated from its journal by build-state.sh, never copied from a template; DIGEST.md is its capped extract and carries the same Pilot contract; create and adopt both give birth to journal, sheet and digest; the Pilot prompt names the sheet's path (state_path). current-state.md and its template are superseded."
created_at: "2026-09-23T01:24:58-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
supersedes:
  - "../templates/current-state-template.md"
amends:
  - "../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md"
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  - "../templates/session-opening-prompt-template.md"
  - "../templates/handoff-template.md"
  - "../templates/vault-root-template.md"
  - "../skills/session-start/reading-list.md"
---

# DECISION — STATE SHEET: ONE NAME, GENERATED, CREATED AT BIRTH

## Date

2026-09-23

## Status

`ARBITRATED`

## Measured problem

On 2026-09-22 the adoption of a knowledge base found the state sheet named three ways across the corpus: `<projet>/current-state.md` (`AGENTS.md`, the context lifecycle V2 rule §5, the current-state template), the digest (role charter §2, the session-start reading list), and `<projet>/state/STATE.md` (the marker template, the common Pilot prompt). `adopt` created none of them, so the Pilot of an adopted project was sent to a file that did not exist; the Executor of that project then wrote one by hand from the current-state template. A project whose state lives in a sub-workshop (the Owner's workshop keeps it under `workshop-production/`) had no way to tell the Pilot where. The digest, read first at opening, did not carry the Pilot contract that the common prompt says is "at the head of the sheet".

## Decision

1. **One name.** A project's state sheet is `<projet>/state/STATE.md`, where `<projet>` is the folder that carries `<projet>/state/journal.md` — the project root, or its sub-workshop when it has one. No other name designates it.
2. **Generated, never copied.** `tools/build-state.sh` generates the sheet from `<projet>/state/journal.md`, the Git state and the file listing; `tools/build-digest.sh` generates `<projet>/state/DIGEST.md`, its extract capped at 8,000 bytes, read in full at opening. Both carry the seven-line Pilot contract at their head, copied from `templates/pilot-contract-template.md`. Neither is ever edited by hand, and neither tool overwrites a sheet it did not generate: it refuses and names the file.
3. **Created at birth.** `tools/project-bootstrap.sh create` and `adopt` both write a birth entry in the journal, then generate the sheet and the digest. An adopted project is never left without them.
4. **The Pilot prompt names the path.** Each project's generated Pilot prompt (`<projet>/state/PILOT-PROMPT.md`) carries `state_path`, the sheet's path relative to the project path, and says that step 3 of the common prompt reads that sheet. The common prompt's step 3 names the sheet by `state_path` instead of a fixed path; an instruction already pasted keeps working, since the Pilot prompt it reads at step 2 names the sheet.
5. **Superseded.** `<projet>/current-state.md` and `templates/current-state-template.md` are superseded by this Decision; the context lifecycle V2 rule §5 is amended accordingly. A sheet written by hand from that template is replaced by the generated one, its content carried into the journal first.

Owner's choice, verbatim: « STATE.md + DIGEST (Recommandé) » ["STATE.md + DIGEST (Recommended)"].

## Reason

A sheet that carries the Pilot contract must exist before the first Pilot session and be found without searching. A generated sheet cannot drift from the journal it is built from; a copied one starts drifting the day it is written. One name, one path named in the file the Pilot reads first, ends the three-name confusion without asking the Owner to paste anything again.

## Impact

- `tools/project-bootstrap.sh`: birth entry, sheet and digest at `adopt` too; `state_path` in the Pilot prompt; `prompt` regenerates it.
- `tools/build-state.sh`, `tools/build-digest.sh`: refusal to overwrite a sheet they did not generate; the digest carries the contract; its "last Mission" line reads lineage suffixes (door `open-194-build-digest-last-mission-line`).
- Amended texts: `AGENTS.md`, the context lifecycle V2 rule §5, the role charter §2, the common Pilot prompt, the handoff template, the marker template, the session-start reading list.
- Adopted projects receive their journal, sheet and digest (Mission 218, lot 7).

## Important alternatives

- Keep the current-state file name (`<projet>/current-state.md`): rejected, it was the least used of the three and the only one no tool generates.
- Make the digest the only opening sheet: rejected, the full sheet stays the reference; the digest is its extract for the reading budget.
- Search for the sheet at opening: rejected, the reading list forbids exploratory searches; the path is named.

## Human gate

- Validation: granted
- Reference: Owner, Pilot session of 2026-09-23 at 00:4x, multiple-choice questions of the Pilot; choice quoted under "Decision"; authorization of 00:38 quoted in Mission 218 (workshop history, not distributed).

## Linked artefacts

- Mission 218 and its entry audit (workshop history, not distributed).

## Liens

- `supersedes` — [Template — current state](../templates/current-state-template.md)
- `amends` — [Context lifecycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amends` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `amends` — [Template — minimal opening prompt](../templates/session-opening-prompt-template.md)
- `amends` — [Template — handoff](../templates/handoff-template.md)
- `amends` — [Template — working-root marker](../templates/vault-root-template.md)
- `amends` — [Session opening reading list](../skills/session-start/reading-list.md)
- `see also` — [Template — Pilot contract](../templates/pilot-contract-template.md)
- `see also` — [Decision — Project initiation and adoption, birth certificate](./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `prescribed by` — [Context lifecycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
