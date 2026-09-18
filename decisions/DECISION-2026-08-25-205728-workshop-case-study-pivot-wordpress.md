---
type: decision
title: "Pivot of the workshop's use case — abandonment of « Une semaine sans écran », adoption of the WordPress case piloted by the Vault"
created_at: "2026-08-25T20:57:28-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-25-205728-workshop-case-study-pivot-wordpress.md"
---

# DECISION — PIVOT OF THE WORKSHOP'S USE CASE

## Date

2026-08-25

## Status

`ARBITRATED`

Arbitrated in session by the Owner on 2026-08-25, in a Pilot session `plan · open`, on point-by-point brainstorming.

## Decision

Six points arbitrated as a block.

1. **Abandonment.** The case study « Une semaine sans écran / MiroShark » ["A week without screens / MiroShark"] is abandoned as the workshop's use case. It must no longer be proposed nor serve as a common thread. Its material fate in the repositories (inventory then possible deletion) remains an Executor gesture under human gate; no deletion is authorized by the present Decision.

2. **New use case.** The workshop builds a WordPress site — Elementor, Blocksy theme in its free version, NovaMira as the MCP bridge between the assistant and WordPress — **piloted by the Vault method**, with a *staging* environment and an explicit promotion to production.

3. **Two distinct resources, ranked.** The Vault is the **product**: it is the resource the audience will have access to and will reuse for any project. The WordPress workshop is the **proof** that the Vault stands up on real work. The workshop materials may be included in the distributed package, but they are not its core. Any later design of the content respects this hierarchy.

4. **Audience and motive.** About 200 non-developers following the academy's programmes. They already practise WordPress in these programmes and experience it as a difficulty. The use case is therefore not a prerequisite to teach but an existing pain to address.

5. **Format.** The Owner builds alone; the room watches. Session recorded. A summary sheet covering the steps, the context and the materials is distributed. No live building by the participants is planned: the dependency chain (hosting, domain, DNS, plugins, Node.js, MCP connector) stays on the Owner's side.

6. **Duration.** Target 3 h to 3 h 30, the academy's usual pace.

## Reason

The previous case did not satisfy two criteria that became visible on examination: it rested on no pain experienced by the audience, and it provided no proof that the method withstands real, messy work.

The WordPress case satisfies both. It starts from a failure the audience already endures, and it sets against what the state of the art commonly does — a pasted prompt, an awaited result, a direct publication to production, no trace of the decisions — the three pieces the Vault brings: a disposable environment before production, a versioned corpus where the plan, the decisions and the prompts are dated artefacts, and bounded, verifiable gestures rather than a single command.

Settling on the format "the Owner builds alone" moreover removes the main risk identified in the brainstorming: the uncontrollable duration of the generation phases, measured at about ten minutes for the design and about one hour for the migration in the external source studied.

## Impact

- The door `open-workshop-deliverable` changes object and stays open.
- The dismountable model project of batch E (`open-distribution-lot-e`) must be re-examined: the distributable package and the workshop materials share part of their substance without merging, the Vault remaining the product.
- The planned demonstration chain (ChatGPT + Codex as the main one) comes into tension with the new case, whose natural tooling is a desktop assistant connected through MCP. **Point not arbitrated**, to be decided separately.
- The work order arbitrated in the handoff of 2026-08-25 is amended: building the Vault and packaging it come before designing the workshop's content.
- A split of the run into five blocks was sketched in session; it is **explicitly not retained at this stage**, having been built before the hierarchy of point 3 was established.

## Important alternatives

- **Keep « Une semaine sans écran » ["A week without screens"].** Rejected: no audience pain, no proof of the method's robustness.
- **Reproduce the external tutorial as is.** Rejected: it is a product demonstration, not a method one; it leaves no rereadable trace and publishes directly to production.
- **Have the participants build live.** Rejected: an unmanageable dependency chain for about 200 non-developers in a video conference.

## Human gate

- Validation: granted
- Reference: arbitration in session by the Owner, Pilot session of 2026-08-25; recorded in the journal.

## Linked artefacts

- External source studied (to be filed): case study of the external WordPress tutorial, `../knowledge-notes/`
- Work order amended: `../handoffs/HANDOFF-2026-08-25-145859-pilot-session-close-purge-anglicization-content-plan.md` (supprimé)

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amends` — Pilot session close 2026-08-25 (workshop history, not distributed)
- `amends` — [Decision — Seven session arbitrations of 2026-08-23](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
