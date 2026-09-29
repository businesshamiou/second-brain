---
type: decision
title: "Two relay modes — the Mission, and the Owner's prompt executed without a Mission, traced by an execution Note written before the first write; the absence of a Mission is never a reason to refuse"
description: "Engraves the Owner arbitration of 2026-09-23 (D-C): mode 1 is the Mission, unchanged; mode 2 is a prompt of the Owner, pasted as is (2a) or 'read <files> and execute' (2b). Mode 2 is the light regime: its trace is an execution Note, extended with its origin, the real time of reception, the verbatim prompt and its sha256 or each consumed file and its sha256, and its scope; the Note is the first write. The one-off instruction and the Owner's 'MISSION EXPRESS' header are forms of mode 2. A closed list of refusal reasons; full scope in projects, non-structuring changes only in the Vault."
created_at: "2026-09-23T01:25:00-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
  - "../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md"
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  - "../templates/execution-note-template.md"
  - "../templates/vault-root-template.md"
---

# DECISION — TWO RELAY MODES: THE MISSION, AND THE OWNER'S PROMPT TRACED BY A NOTE

## Date

2026-09-23

## Status

`ARBITRATED`

## Measured problem

On 2026-09-23 an Executor window could refuse a prompt of the Owner for want of a Mission: the role charter said the Executor consumes as instructions only `type: mission` pieces. Three light forms of delegation existed side by side with no articulation — the one-off instruction of the relay rule (Decision 100016), the execution Note of the light regime (rule 012259), and the Owner's own "MISSION EXPRESS" header — and none said what trace the Executor leaves when the Owner speaks to it directly.

## Decision

1. **Mode 1 — the Mission.** Unchanged: the Pilot writes it, the mini-prompt leads to it, the Executor applies it.
2. **Mode 2 — the Owner's prompt.** **2a**: a prompt of the Owner pasted as is into the Executor window. **2b**: "read <files> and execute". Mode 2 **is** the light regime: its trace is an execution Note (`<projet>/missions/NOTE-<YYYY-MM-DD-HHMMSS>-<slug>.md`, never a row of the Mission register, one journal line), to which it adds: `origin: owner-prompt`; `mode: 2a` or `2b`; `received_at`, the real time measured when the prompt is received; for 2a, the prompt verbatim and its sha256; for 2b, each consumed file with its path and its sha256; and the scope. **The Note is the first write** of the window.
3. **Attached forms.** The one-off instruction of the relay rule and the Owner's "MISSION EXPRESS" header are forms of mode 2 and leave the same trace.
4. **The absence of a Mission is never a reason to refuse.** The list of refusal reasons is closed: a gesture reserved to the Owner; an ambiguous irreversible action; an exposed secret; a gesture out of scope; a full-regime criterion that the Owner has not lifted. Each is announced with its reason. In the last case the Executor states the criterion and asks for the go-ahead; it does not refuse.
5. **Same guardians.** A Note empties no control: the same commit guardians judge what is committed under a Mission and under a Note; `tools/check-work-regime.sh` refuses a mode-2 Note that lacks its prompt, its fingerprints or its scope, or whose fingerprint is wrong.
6. **Return.** The same RELAY block, headed `RELAY NOTE-<YYYY-MM-DD-HHMMSS>`; the report is filed in `<projet>/reports/`.
7. **Scope.** Full in projects. In the Vault, non-structuring changes only: doctrine — a Decision, a rule, a template — still requires a Decision and the full regime (criterion `R3-doctrine`).

Owner's choices, verbatim: « Dossier instructions/ » ["An instructions/ folder"], then, on an inconsistency the Pilot reported, « Unifier avec la Note (Recommandé) » ["Unify with the Note (Recommended)"] — the second choice prevails; and « Non structurant seulement (Recommandé) » ["Non-structuring only (Recommended)"].

## Reason

The Owner must be able to hand work to an Executor without first having a Mission written, and the Executor must not be the one to refuse. A second trace format beside the Note would have been a third light regime; unifying mode 2 with the Note keeps a single light form, with the proofs the Note already requires, and adds only what makes an Owner's prompt auditable afterwards: its words, their fingerprint, the time they arrived.

## Impact

- `templates/execution-note-template.md`: the mode-2 fields.
- `tools/check-work-regime.sh`: the mode-2 refusals, named.
- Rule 124937: the mode-2 mini-prompt (the prompt or the files to consume instead of the source), the `RELAY NOTE-<ts>` header. Rule 012259: mode 2 as the light regime, its fields, its scope in the Vault. Role charter §3: consumption and the closed list of refusal reasons.
- `AGENTS.md`, the `ecriture-de-mission` and `session-close` skills; the project instruction files rendered by `tools/project-bootstrap.sh`.

## Important alternatives

- An `instructions/` folder with its own format: chosen first, then withdrawn by the Owner in favour of the Note, because it made a second light regime.
- Mode 2 in the Vault without restriction: rejected, doctrine keeps its Decision.
- Let the Executor refuse on a full-regime criterion: rejected, it states the criterion and asks; the Owner decides.

## Human gate

- Validation: granted
- Reference: Owner, Pilot session of 2026-09-23 at 00:4x, multiple-choice questions of the Pilot, quoted under "Decision"; recorded in Mission 218 (workshop history, not distributed).

## Linked artefacts

- Mission 218 and its entry audit (workshop history, not distributed).

## Liens

- `amends` — [Relay between roles through mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amends` — [Two work regimes: the light Note and the full Mission](../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)
- `amends` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `amends` — [Template — execution Note](../templates/execution-note-template.md)
- `amends` — [Template — working-root marker](../templates/vault-root-template.md) (how the Vault is fed)
- `see also` — [Decision — Copy protocol: snippets and destinations](./DECISION-2026-08-27-100016-copy-protocol-snippets-and-destinations.md)
- `see also` — [Decision — Relay and delegation, one rule in one place](./DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
- `prescribed by` — [Context lifecycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amended by` — [Decision — The Owner's go-ahead quoted in the Note; a local language file](./DECISION-2026-09-23-105507-owner-greenlight-in-note-and-local-language-file.md) (point 4: how a criterion is lifted)
