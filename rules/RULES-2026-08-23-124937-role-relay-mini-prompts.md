---
type: rules
title: "Relay between roles through mini-prompts with fixed rubrics"
description: "Symmetric handover format between the Pilot window and the Executor window: a mini-prompt on the way out, a RELAY block on the way back."
created_at: 2026-08-23T12:49:37-04:00
timezone: America/Montreal
status: active
scope: role-relay, mission-workflow
---

# RELAY BETWEEN ROLES THROUGH MINI-PROMPTS

> ### Rule — relay between roles through mini-prompts
>
> **Outbound.** Every Mission leaves with a consumption mini-prompt, delivered by the Pilot **as a snippet copyable in a single gesture** (a code block in the chat), never as a file to open nor as prose to reassemble. Five fixed rubrics, in this order:
>
> 1. Title line: `Session Executor — Mission <NNN> (<description courte>)` — it names the session. The form `Tu es l'Executor — Mission <NNN> (<description courte>)` [“You are the Executor — Mission <NNN> (<short description>)”] is equivalent, and extends to any one-off instruction delegated to the Executor without a Mission number, in the form `Tu es l'Executor — instruction ponctuelle (<description courte>)` [“You are the Executor — one-off instruction (<short description>)”] (`DECISION-2026-08-27-100016`). A one-off instruction is a form of mode 2, below: it leaves the trace of mode 2.
> 2. « Position »: free; the session establishes its awareness of position (Decision `213150`).
> 3. « Source à appliquer » [source to apply]: the path of the Mission file, relative to the Vault, to be read and applied in full.
> 4. « Interdits absolus » [absolute prohibitions]: always "no non-delegated git push (delegation: a clear expression by the Owner that names the gesture and its target, one per gesture), no model call, no deletion; move to `_trash/` only on the Mission's prescription", plus the prohibitions specific to the Mission. The mini-prompt never asserts that an Owner gesture (push, deletion, emptying of `_trash/`) has taken place: it asks the Executor to measure it, STOP if absent (`DECISION-2026-08-29-110852`).
> 5. « Sortie attendue » [expected output]: end the window with the RELAY block defined in the Mission, filled in.
>
> The mini-prompt does not duplicate the content of the Mission.
>
> **`initiation` type (amendment of 2026-09-17, Decision 000545 A5).** A Pilot without a Mission may issue an **initiation order** to give birth to or adopt a project. Its mini-prompt carries the title line `Session Executor — initiation (<nom du projet>)` [“Executor session — initiation (<project name>)”], the position, the absolute prohibitions and the expected output, but **no « Source à appliquer » rubric**: the order is the source. In its place it carries the eight fields of the order, in this order:
>
> 1. `Type`: `create` or `adopt`.
> 2. `Mode`: `answered` (all the answers are in the order, no question) or `ask` (the bootstrap asks for name, location and Git).
> 3. `Nom` [name]: name of the project's folder.
> 4. `Emplacement` [location]: parent folder, absolute path.
> 5. `Vault + construction`: `vault_id=…, vault_origin=…, vault_ref=…`.
> 6. `Git`: `none` or `git`.
> 7. `Objet` [purpose]: one sentence.
> 8. `Autorisation Owner datée` [dated Owner authorization]: the Owner's sentence, verbatim, with its date `AAAA-MM-JJ` (year-month-day).
>
> An optional ninth field, `Arbre sale` [dirty tree], is written only when the target is a Git working tree with uncommitted changes and the Owner accepts that the baseline records them: `accepté — <raison>` [accepted — <reason>]. Without it, `adopt` refuses a dirty tree (`BASELINE-DIRTY-TREE`, Mission 218).
>
> The Executor consumes it like a Mission, with a scope bounded to the target and to the Vault's register: `tools/project-bootstrap.sh --order <fichier>`. The blank order, pre-filled for a folder, is rendered by `tools/project-bootstrap.sh order <dossier>`; the template is [the initiation order](../templates/initiation-order-template.md).
>
> **Mode 2 — the Owner's prompt (amendment of 2026-09-23, Decision 012500).** The Owner may hand work to the Executor without a Mission: a prompt pasted as is (**2a**), or "read <files> and execute" (**2b**). The one-off instruction above and the Owner's « MISSION EXPRESS » header are forms of it. No Pilot mini-prompt is required; when the Pilot prepares one, its title line names the gesture, and its rubric 3 is replaced by the prompt verbatim (2a) or by « Fichiers à consommer » [files to consume], one path per line (2b). The Executor's **first write** is an execution Note (template `templates/execution-note-template.md`, fields `origin: owner-prompt`, `mode`, `received_at`, the prompt and its sha256 or each file and its sha256, the scope), accepted by `tools/check-work-regime.sh note` before the gesture. The absence of a Mission is never a reason to refuse (role charter §3). In the Vault, mode 2 covers non-structuring changes only.
>
> **Return.** Every execution report ends with a `RELAY` block displayed at the end of the Executor window, with the following fixed rubrics, in this order: this block is delivered **as a snippet copyable in a single gesture** (a code block at the end of the window), never as prose to reassemble — symmetry with the outbound direction (`DECISION-2026-08-27-100016`). [The block's labels are French literals: `Rapport` = report, `Verdict` `FAIT | PARTIEL | BLOQUÉ` = done, partial, blocked, `Critères` = criteria, `Poussées` = pushes, `Résumé` = summary, `À trancher` = to be decided.]
>
> ```text
> RELAY <NNN>
> Rapport   : <chemin du fichier REPORT déposé>
> Verdict   : <FAIT | PARTIEL | BLOQUÉ> + une ligne
> Critères  : <n>/<total> PASS
> Commits   : <dépôt> <hash> · <dépôt> <hash>
> Poussées  : <dépôt> <avant>..<après> · <étiquette> | aucune
> Résumé    : <cinq lignes>
> À trancher: <une ligne, ou « rien »>
> ```
>
> In mode 2 the block is the same, headed `RELAY NOTE-<YYYY-MM-DD-HHMMSS>` (the timestamp of the Note) instead of `RELAY <NNN>`; the report is filed in the project's `reports/` folder.
>
> The **Poussées** rubric says what the Executor actually pushed, measured by `git ls-remote` — never inferred from an intention or from a `git push` launched without checking afterwards.
>
> The **Résumé** rubric fits in five lines, a strict ceiling — beyond that, it becomes a second report again and the cost it saves is paid back. Three constraints:
>
> 1. Facts, not appraisals: a figure, a comparison, a named gap. « Q5 en hausse » [“Q5 up”] is worth nothing; « Q5 : 12 décisions trouvées contre 7 » [“Q5: 12 decisions found against 7”] is worth the whole rubric.
> 2. The figures that change a conclusion, and what surprised the Executor.
> 3. Every deviation from the protocol or from the Mission appears there, even minor, even with no apparent consequence — it is the only place where the Pilot can see it without opening the report.
> When a gesture reserved to the Owner blocks the Mission, the « À trancher » rubric names the exact path and the available substitute (move to `_trash/`); the Executor stops with no second tool and no workaround — the refusal is structural (`DECISION-2026-08-29-110852`).
>
> **Bridge.** The Owner is the only channel between the two windows: they paste the mini-prompt on the way out, they paste the `RELAY` block back on the way back. The Pilot resumes on the strength of the block, and rereads the whole report only if the verdict or the « À trancher » rubric requires it.
>
> **Scope.** The rule holds for every action delegated to the Executor — Mission (mode 1), Owner's prompt (mode 2, of which the one-off instruction is a form) or initiation order — in all projects.

## Liens

- `source` — Proposal — Relay between roles through mini-prompts with fixed rubrics (workshop history, not distributed) (hors Vault)
- `see also` — [Decision — Adoption of the rule of relay between roles](../decisions/DECISION-2026-08-23-124937-role-relay-mini-prompts.md)
- `amended by` — [Decision — « Résumé » rubric in the RELAY block of the return direction](../decisions/DECISION-2026-08-23-180500-relay-summary-rubric.md)
- `amended by` — Decision — Opening directory of a session, position freed (workshop history, not distributed)
- `amended by` — [Decision — Delegated push becomes a rule](../decisions/DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)
- `amended by` — [Decision — Copy protocol: snippets and destinations](../decisions/DECISION-2026-08-27-100016-copy-protocol-snippets-and-destinations.md)
- `amended by` — [Decision — Permanent deletion is an Owner gesture](../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
- `amended by` — Decision — Internal consistency of Missions (workshop history, not distributed) (hors Vault)
- `amended by` — [Decision — Project initiation and adoption, birth certificate](../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md) (`initiation` mini-prompt type)
- `amended by` — [Decision — Relay and delegation, one rule in one place](../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
- `amended by` — [Decision — Two relay modes](../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md) (mode 2, `RELAY NOTE-<ts>`)
