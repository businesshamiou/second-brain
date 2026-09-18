---
type: decision
title: "Copy protocol — return direction as a snippet, exact words grouped and addressed, identity line extended to one-off instructions"
description: "Engraves four fixes to the Owner/Pilot/Executor copy protocol: the RELAY block of the return direction delivered as a snippet copyable in a single gesture, the Pilot's exact words delivered as snippets grouped at the end of the turn, each snippet meant for the Owner naming its destination window, and the identity line 'Tu es l'Executor — Mission <NNN>' extended to one-off instructions in the form 'Tu es l'Executor — instruction ponctuelle (<description courte>)'."
created_at: "2026-08-27T10:00:16-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
---

# DECISION — COPY PROTOCOL: SNIPPETS AND DESTINATIONS

## Date

2026-08-27

## Status

`ARBITRATED`

## Decision

The copy channel between the Owner, the Pilot and the Executor receives four fixes, engraved together:

1. **Return direction as a snippet.** The `RELAY` block with six rubrics (`RULES-2026-08-23-124937`) is delivered by the Executor **as a snippet copyable in a single gesture** (code block at the end of the window), never as prose to be reassembled. Symmetry with the outbound direction, already engraved in this form by `DECISION-2026-08-23-155831`.
2. **Exact words grouped.** The exact words the Pilot proposes to the Owner (arbitration, authorization, formula to paste) are delivered **as snippets**, one snippet per arbitration, and **grouped at the end of the turn**, never scattered through the prose that justifies them.
3. **Destination named.** Each snippet meant for the Owner carries, immediately before it, a line naming its destination window — for the Pilot in the chat window, or for the Executor in a Claude Code window.
4. **Identity line extended.** The identity line of an Executor window, `Tu es l'Executor — Mission <NNN> (<description courte>)` [“You are the Executor — Mission <NNN> (<short description>)”], applies **to any instruction delegated to the Executor**, Mission or one-off instruction. For a one-off instruction with no Mission number, the form is `Tu es l'Executor — instruction ponctuelle (<description courte>)` [“You are the Executor — one-off instruction (<short description>)”]. This line remains a confirmation (rung 3) and never proves the role on its own — rung 2 (capability probe) keeps primacy.

## Reason

Defects measured in the session of 2026-08-27: a RELAY block rendered as free prose with none of the six rubrics (no verdict, no count of criteria, no « À trancher » rubric), forcing the Pilot to reconstruct the verdict itself; exact words scattered through the Pilot's prose over several turns; a push authorization snippet delivered without naming its destination window, the Owner having had to ask explicitly where to carry it. The outbound direction of the relay has been prescribed as a copyable snippet since `DECISION-2026-08-23-155831`; nothing imposed the same form on the return direction, nor framed the delivery of the Pilot's exact words, nor named the destination of a snippet, nor extended the identity line to one-off instructions.

## Impact

- `RULES-2026-08-23-124937` (relay between roles through mini-prompts) receives two additions to its body: the **Return** rubric now prescribes delivery of the RELAY block as a copyable snippet; the **Outbound** rubric, rubric 1 (title line), extends the form to `Tu es l'Executor — Mission <NNN>` and mentions the « instruction ponctuelle » ["one-off instruction"] variant. Reciprocal `amended by` link placed in the same commit.
- `RULES-2026-08-23-224706` (role charter), §2 role `pilot`, **Output** rubric, receives two additions to its body: snippets grouped at the end of the turn, destination named before each snippet. Reciprocal `amended by` link placed in the same commit.
- No new opening of perimeter: these four parts frame the delivery form of artefacts already prescribed (mini-prompt, RELAY block, exact authorization words); they create no new category of artefact.
- No door opened or closed by this Decision (Owner arbitration of 2026-08-27: no door is opened retroactively only to be closed in the same batch).

## Important alternatives

- Leave the return direction as free prose and count on the Résumé rubric (`DECISION-2026-08-23-180500`) to carry the essentials: rejected — the measurement of 2026-08-27 shows that free prose omits verdict and criteria, not just the summary; only the fixed-rubric form as a snippet removes this risk, as it already did for the outbound direction.
- Leave the exact words scattered through the Pilot's reasoning, on the grounds that the context justifies them better that way: rejected — scattered, they force the Owner to reread the whole turn to find them; the motive that had the outbound direction engraved as a snippet (risk of drift on reassembly) applies identically here.
- Do not name the destination, on the grounds that it can be inferred from the snippet's content: rejected — the incident of 2026-08-27 (push delivered with no destination) shows that the inference fails in practice and costs the Owner a round trip.
- Restrict the extended identity line to numbered Missions only, on the grounds that a one-off instruction is by nature lighter: rejected — it is precisely the absence of an identity line on a one-off instruction that deprives rung 3 of the charter of its purpose in this case.

## Human gate

- Validation: granted
- Reference: Owner arbitrations in chat of 2026-08-27 (« Je valide la gravure : une Decision au vault, amendant RULES-124937 (sens retour en snippet) et RULES-224706 §2 (mots exacts en snippets groupés en fin de tour) » ["I validate the engraving: a Decision in the vault, amending RULES-124937 (return direction as a snippet) and RULES-224706 §2 (exact words as snippets grouped at the end of the turn)"], then « Ajoute le troisième volet : chaque snippet nomme sa destination » ["Add the third part: each snippet names its destination"], then the addition of part 4 on the identity line of mini-prompts); Mission `070`.

## Linked artefacts

- Source Mission: (workshop history, not distributed) (hors Vault).
- Direct precedent (outbound direction as a snippet): `./DECISION-2026-08-23-155831-relay-forward-snippet-and-superseded-list-graph-exclusion.md`.
- Precedent amending the return direction (Résumé rubric): `./DECISION-2026-08-23-180500-relay-summary-rubric.md`.

## Liens

- `amends` — [Relay between roles through mini-prompts with fixed rubrics](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amends` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Outbound direction of the relay as a snippet, and superseded list outside the graph but versioned](./DECISION-2026-08-23-155831-relay-forward-snippet-and-superseded-list-graph-exclusion.md)
- `see also` — [« Résumé » rubric in the RELAY block of the return direction](./DECISION-2026-08-23-180500-relay-summary-rubric.md)
- `see also` — Mission 070 — Engraving of the copy protocol (workshop history, not distributed) (hors Vault)
