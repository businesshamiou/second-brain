---
type: template
title: "Template — initiation order"
description: "The eight fields of the order (and optional ones: a dirty tree, a group, the three fields of the project profile) that gives birth to or adopts a project without a Mission: filled in by the Pilot, dated by the Owner, consumed by the Executor."
status: active
---

# TEMPLATE — INITIATION ORDER

The initiation order replaces the Mission for a single gesture: giving birth to (`create`) or adopting (`adopt`) a project. The Pilot fills it in, the Owner writes their dated authorization in it, the Executor consumes it through `sb new --order <fichier>` (`tools/project-bootstrap.sh --order` underneath), which commits the new project and the Vault's registry itself (Mission 244). It travels in a mini-prompt of type `initiation`, with no « Source à appliquer » [source to apply] rubric: the order is the source ([relay rule](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)).

An agent that opens a non-adopted folder without an order stops and returns this order pre-filled: `tools/project-bootstrap.sh order <dossier>`.

The block below keeps its French labels as they are: the title line `Session Executor — initiation (<nom du projet>)` [“Executor session — initiation (<project name>)”] is the fixed form of the relay rule; `Ordre d'initiation` [initiation order] is the heading that `tools/project-bootstrap.sh order` prints; the eight field names, and the optional ones, are read by `tools/project-bootstrap.sh --order`, which finds each one by its exact name followed by a colon; the rubrics « Position », « Interdits absolus » [absolute prohibitions] and « Sortie attendue » [expected output] are those of the relay rule.

<!-- ORDER:BEGIN -->
Session Executor — initiation (<nom du projet>)

Position : free; establish your awareness of position.

Ordre d'initiation
- Type : <create | adopt>
- Mode : <answered | ask>
- Nom : <folder name>
- Emplacement : <parent folder, absolute path — the workspace root>
- Groupe : <optional group folder, or delete this line>
- Vault + construction : vault_id=<…>, vault_origin=<…>, vault_ref=<…>
- Git : <none | git>
- Objet : <one sentence>
- Résultat attendu : <optional: the expected result, or delete this line>
- Blocage actuel : <optional: what blocks it now, or delete this line>
- Rythme de revue : <optional: how often to review it, or delete this line>
- Autorisation Owner datée : <the Owner's sentence, verbatim, AAAA-MM-JJ>

Interdits absolus : no non-delegated git push, no model call, no deletion; writing bounded to the target folder and to the Vault's register; reorganization proposed, never applied.

Sortie attendue : the output of sb new --order, including its two commits; then sb pilot-prompt <folder> --copy, and the Owner's gesture said by its place (« Dans l'application Claude : crée le Project SB - <nom>, colle (Ctrl+V) »).
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
| `Arbre sale` [dirty tree], optional | `accepté — <raison>` [accepted — reason] | only for a Git working tree with uncommitted changes: without it, `adopt` refuses (`BASELINE-DIRTY-TREE`) and writes nothing, since the baseline would engrave that content (Mission 218) |
| `Résultat attendu` [expected result], optional | one sentence, or absent | with `Blocage actuel` and `Rythme de revue`, the project profile (Mission 240): at least one of the three is written under `## Profil du projet` of the project's `README.md`, never generated afterwards and copied into its state sheet by `tools/build-state.sh`; an existing section is kept at adoption; all three absent, `-` or a placeholder: nothing is written. The Pilot asks them one at a time before proposing the order ([the starting-interview skill](../skills/starting-interview/SKILL.md)) |
| `Blocage actuel` [current blocker], optional | one sentence, or absent | see `Résultat attendu` |
| `Rythme de revue` [review rhythm], optional | a day or a frequency, or absent | see `Résultat attendu` |
| `Groupe` [group], optional | one folder name, or absent | `create` only: the project is created in `<Emplacement>/<Groupe>/<Nom>` instead of `<Emplacement>/<Nom>`; refused when the group is a project, carries `VAULT-ROOT.md`, is not a single folder name, or lies outside the workspace (Mission 234, rule on workspace hygiene §6) |

## Liens

- `see also` — [Relay between roles through mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Decision — Project initiation and adoption, birth certificate](../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `see also` — [Rule — Workspace hygiene, project names and session types](../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
- `amended by` — [Decision — The starting interview](../decisions/DECISION-2026-09-27-213059-starting-interview-owner-and-project-profiles.md) (three optional fields: the project profile)
