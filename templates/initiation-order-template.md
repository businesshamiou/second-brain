---
type: template
title: "Template — initiation order"
description: "The eight fields of the order that gives birth to or adopts a project without a Mission: filled in by the Pilot, dated by the Owner, consumed by the Executor."
status: active
---

# TEMPLATE — INITIATION ORDER

The initiation order replaces the Mission for a single gesture: giving birth to (`create`) or adopting (`adopt`) a project. The Pilot fills it in, the Owner writes their dated authorization in it, the Executor consumes it through `tools/project-bootstrap.sh --order <fichier>`. It travels in a mini-prompt of type `initiation`, with no « Source à appliquer » [source to apply] rubric: the order is the source ([relay rule](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)).

An agent that opens a non-adopted folder without an order stops and returns this order pre-filled: `tools/project-bootstrap.sh order <dossier>`.

The block below keeps its French labels as they are: the title line `Session Executor — initiation (<nom du projet>)` [“Executor session — initiation (<project name>)”] is the fixed form of the relay rule; `Ordre d'initiation` [initiation order] is the heading that `tools/project-bootstrap.sh order` prints; the eight field names are read by `tools/project-bootstrap.sh --order`, which finds each one by its exact name followed by a colon; the rubrics « Position », « Interdits absolus » [absolute prohibitions] and « Sortie attendue » [expected output] are those of the relay rule.

<!-- ORDER:BEGIN -->
Session Executor — initiation (<nom du projet>)

Position : free; establish your awareness of position.

Ordre d'initiation
- Type : <create | adopt>
- Mode : <answered | ask>
- Nom : <folder name>
- Emplacement : <parent folder, absolute path>
- Vault + construction : vault_id=<…>, vault_origin=<…>, vault_ref=<…>
- Git : <none | git>
- Objet : <one sentence>
- Autorisation Owner datée : <the Owner's sentence, verbatim, AAAA-MM-JJ>

Interdits absolus : no non-delegated git push, no model call, no deletion; writing bounded to the target folder and to the Vault's register; reorganization proposed, never applied.

Sortie attendue : the output of tools/project-bootstrap.sh --order, including the block to consume, as a copyable snippet.
<!-- ORDER:END -->

## Fields

| Field | Values | Effect |
|---|---|---|
| `Type` | `create`, `adopt` | give birth (target absent) or adopt (existing folder, nothing modified) |
| `Mode` | `answered`, `ask` | all the answers in the order, or questions for name, location and Git |
| `Nom` [name] | text | folder name and display name |
| `Emplacement` [location] | absolute path | parent folder |
| `Vault + construction` | `vault_id`, `vault_origin`, `vault_ref` | the Vault that executes must carry this `vault_id`, otherwise refusal |
| `Git` | `none`, `git` | `none`: checks by command, no hook; absent: the question is asked |
| `Objet` [purpose] | one sentence | copied into the project's sheet |
| `Autorisation Owner datée` [dated Owner authorization] | verbatim with `AAAA-MM-JJ` (year-month-day) | without a date, refusal |

## Liens

- `see also` — [Relay between roles through mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Decision — Project initiation and adoption, birth certificate](../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
