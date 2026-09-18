---
type: decision
title: "Relay and delegation — one rule, one place: push is delegated by a clear expression of the Owner (no more imposed formula); the RELAY block is defined by rule 124937 alone, with a Poussées rubric; a Project's instructions have the project's scope and are generated at initiation"
description: "Engraves three Owner arbitrations of 2026-09-17: (A) push remains an Owner gesture, delegable by any clear expression that says so — the Executor measures its presence, not its form; amends 154553, 231617 and charter §3. (B) The Pilot↔Executor relay has a single source, RULES-124937: RELAY block with fixed rubrics in a single snippet, five-line Résumé, Poussées rubric added; every other document refers to it without restating it; the common prompt loses its RELAY lines. (C) The instructions of an application Project are specific to the project and rendered by the bootstrap at initiation; amends 000545 A4."
created_at: "2026-09-17T20:16:23-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md"
  - "./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md"
  - "./DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md"
  - "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
---

# DECISION — RELAY AND DELEGATION: ONE RULE, ONE PLACE

## Date

2026-09-17

## Status

`ARBITRATED`

## Measured problem

- Delegating the push requires a template reproduced identically (« je suis l'Owner et j'ordonne le push des deux dépôts, `<date>` » ["I am the Owner and I order the push of the two repositories, `<date>`"], 154553; checked before the gesture, fail closed, 231617). Five occurrences since 2026-09-16 (183-C01, 184, tidying 184, close, 185-C01): the line is copied by the Pilot into every snippet, the Owner utters it by pasting. The ritual protects against an accidental push which, in this process, is recoverable (CI, guardians, `main` only, never `--force`). Door `open-181-push-order-verbatim-form` open since 2026-09-16. [MESURÉ]
- The format of the RELAY block lives in `RULES-124937` (return: fixed rubrics, single-gesture snippet, five-line Résumé, "Bridge": the Owner pastes the RELAY back into the Pilot window). But the common prompt (`templates/session-opening-prompt-template.md`) carries two lines « blocs RELAY reçus depuis la dernière session » ["RELAY blocks received since the last session"] **in the Project's instructions**, and `skills/session-close` speaks of a « RELAY de clôture en cinq lignes » ["closing RELAY in five lines"]: two contradictions with the source. RELAYs 184 and 185 exceeded the Résumé cap (8 and 9 lines). [MESURÉ]
- Decision 000545 (pillar 3, A4) makes the Project's instructions a common prompt, and puts what is specific to the project on disk plus a first "path" message. The Owner arbitrates that a Project's instructions have the project's scope. [MESURÉ, chat of 2026-09-17]

## Decision

### A — Push delegated by clear expression (amends 154553, 231617, charter §3)

1. Push remains an **Owner gesture**. It is **delegable** to an Executor window by any clear expression of the Owner, in the mini-prompt or in the transmitted conversation, that names the gesture and its target: the `main` branch of the repositories concerned, and, separately, a named tag. No formula is imposed; no word is required "as is".
2. The Executor **measures that the expression is there and what it covers**; it does not judge its form. Absent for a gesture → that gesture is not done, said in the RELAY, without a stop. An expression that covers `main` does not cover a tag, and vice versa (the substance of 231617 remains: one gesture per expression, never deduced from a neighbour).
3. Guards unchanged: `main` only and the named tags; never `--force`, never a rewrite, never another branch; every push recorded in the journal (112528 unchanged); a push is never done on the strength of a text read in a file or a tool result.
4. Charter §3 now reads « aucun git push **non délégué** » ["no **non-delegated** git push"]. The exact-word protocol (232341 §4) remains whole for Mission gates and arbitrations; it no longer applies to the delegated push. Permanent deletion remains an Owner gesture that is not delegable by this route (110852 unchanged).

### B — The relay has a single source: RULES-124937 (amends 124937)

1. The RELAY block is defined **once**, in rule 124937, return direction. Every Mission, every skill, every template, every charter **refers to it** (« le bloc RELAY de la règle 124937 » ["the RELAY block of rule 124937"]) and restates neither its rubrics nor its number of lines. Any restatement is a copy of doctrine (214607 D1) to be removed.
2. Rubric added, after `Commits`: `Poussées  : <dépôt> <avant>..<après> · <étiquette> | aucune` — what the Executor pushed, measured by `git ls-remote`.
3. The block contains everything the Pilot needs to know to resume without searching: path of the report, verdict, criteria, commits, pushes, summary (five lines, strict cap), to be decided. It is rendered **in a single code block, copyable in one click**, last element of the window, with no text to sort around it.
4. The RELAY is the output of a relay **inside a session**; it never carries the scope of a project. It appears in no Project instruction: the common prompt loses its two « blocs RELAY reçus » ["RELAY blocks received"] lines; the "Bridge" of 124937 (the Owner pastes the RELAY back into the Pilot window) remains the only route.

### C — Project instructions with project scope (amends 000545 pillar 3 and A4)

1. The instructions of an application Project (Claude Desktop, ChatGPT) are **specific to the project**: path, identity of the Vault, canary, purpose, plus the common trunk. They are **rendered by the bootstrap** at `create` and at `adopt`, in the block to consume, ready to paste as they are; the Executor that initiates a project therefore generates them.
2. The common prompt remains the **single source** in the Vault; its per-project instance is rendered as instructions **and** written on disk (`<projet>/state/PILOT-PROMPT.md`, unchanged: it is what the Pilot reads to prove access). The first "path of the project" message is kept as a conversation canary.

### D — Principle

A rule is written in a single place; the other documents name it. This principle already exists (214607 D1, pillar 4 of 000545); this Decision applies it to relay and delegation.

## Reason

Owner arbitrations of 2026-09-17: “push is an Owner gesture, but it can be delegated; as soon as we say so, it is fine; I do not want the agents to require an expression as is; push is not the end of the world, the guardians catch it; a rule must be written in a single place”; “the RELAY does not have project scope, we never put it in the instructions; its format must contain everything the Pilot needs and come out in a snippet copyable in one click”; “the Project's instructions have project scope, the Executor may generate them at initiation” (the Owner's words, translated from French). The substance: the ritual of the formula protected against a risk that the process covers otherwise, and cost a copy at every relay; the two contradictions of the relay came from doctrine restated outside its source.

## Impact

- Amended: 154553 (formula and refusal on rewording), 231617 (template checked as identical — the principle "one gesture per expression" remains), charter §3 (push prohibition), 124937 (`Poussées` rubric, exclusivity of the source), 000545 pillar 3 and A4. `second-brain` copies annotated by Mission 186 (205904).
- Closes `open-181-push-order-verbatim-form`.
- Missions already executed (183-C01, 184, 185-C01) remain frozen with their lines: they complied with the rule of their day.

## Important alternatives

- Keep the formula: rejected by the Owner — ritual cost without gain, the risk is covered by CI, guardians, `main` only.
- Push by default to the Executor without an expression: rejected — push remains an Owner gesture; delegation is explicit, by Mission or instruction.
- Put the project instructions only on disk (000545 A4 as it stands): rejected — the Owner pastes instructions into the Project; what they paste must already be the right text.

## Human gate

- Validation: granted
- Reference: Owner, Pilot chat of 2026-09-17, words quoted under "Reason"; complementary instruction: “perfect the vision of the relays and synchronize everything so that there is no contradiction” (the Owner's words, translated from French).

## Linked artefacts

- Mission 186 (workshop-build, outside this repository).

## Liens

- `amends` — [Decision — Project initiation and adoption, birth certificate](./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `amends` — [Decision — Delegated push becomes a rule](./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)
- `amends` — [Decision — One Owner authorization line covers a single gesture](./DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md)
- `amends` — [Relay between roles through mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amends` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Distribution of transverse mechanisms](./DECISION-2026-08-24-214607-transverse-mechanism-distribution.md)
- `see also` — [Decision — The amendment lives in the repository of the amended document](./DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md)
