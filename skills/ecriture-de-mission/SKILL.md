---
name: ecriture-de-mission
description: "Draft a Vault Mission file and its Executor mini-prompt from the template, with measured links, a mandatory Context section, and a cross-check of Validations against Gates. Use when the Pilot needs to write, review, or fix a Mission. Triggers on: « écris la Mission », « rédige la Mission », \"write the Mission\"."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md, rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md, decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md"
  vault-validated: "2026-09-08T00:40:13-04:00"
---

Drafts a Vault Mission and the Executor mini-prompt that leads to it, from the template, with measured links, a mandatory Context section and a cross-review. **Pilot surface only**: filing an artefact is a Pilot gesture; the Executor does not invoke this skill. This skill executes nothing and does not decide the architecture: a choice that is not a "way of implementing" becomes a question to the Owner, recommendation and gate word included.

## 0. Choose the regime first

Ask the check, never your own judgement. A gesture that is reversible and stays on the workstation or in a private repository is written as an execution Note ([the template](../../templates/execution-note-template.md)), not as a Mission: fill its six rubrics, then run `tools/check-work-regime.sh note <file>`. `REGIME-LIGHT-OK` means no Mission is needed and this skill stops here. Any refusal (`R1` to `R7`) means the full regime: continue with the sections below. The criteria are the tool's and the rule's ([the two work regimes](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)); this skill never loosens them.

## 1. Read the template at the moment of writing

Open the Vault's `templates/mission-template.md` **now**, never from memory: it changed on 1 September (Mission 111: `## Context` section [formerly « Contexte »], cross-review comment). The list of sections is the template's, in its order.

## 2. Gather a measured context

- Each fact carries its date and its status: `MESURÉ` / `DECLARED` / `HYPOTHÈSE` (DECISION-212009).
- Each linked file name is obtained by `search_files` or by listing, never typed from memory (fault of 30 August: link written from memory with a wrong name).
- Each asserted existence goes through `get_file_info` (fault "the hook exists", 30 August).
- What the Executor will find on disk, and why it is there, is written; the known pitfalls (tool defects, misleading locations, precedents) are named.

## 3. Draft, section by section

`## Context` (the four contents of DECISION-115547 point 1, in order) · `## Objective` [« Objectif »] · `## Scope` [« Périmètre »] with an explicit out-of-scope · `## Preconditions` [« Préconditions »] with evidence status and STOP at the slightest non-trivial gap · `## Sources` · `## Applicable decisions` [« Décisions applicables »] · `## Constraints` [« Contraintes »] · `## Prior measurements` [« Mesures préalables »] (mandatory as soon as a step creates, copies, installs, pins, wires or configures: one row per target, with the command that measures its state before laying it down) · `## Steps` [« Étapes »] (never "delete": "move to `_trash/`" with fingerprint, or human gate) · `## Gates` (Owner word **verbatim**, dated; human gate not granted listed) · `## Validations` with figures (before → after) · `## Exit contract` [« Contrat de sortie »] · `## Resume contract` [« Contrat de reprise »] · `## Doors` [« Portes »] · `## Liens` (`prescribed by` the Mission versioning standard + `applies` on each applied Decision).

### Fan-out (optional rubric)

`## Fan-out` lists batches of measurements that do not depend on one another; leave it out otherwise, and the Mission is valid and worked as before. When it is filled, the Executor applies the skill `dispatching-parallel-agents` (kept in the skills warehouse, not delivered to this Vault yet): its eligibility gate, its sequential fallback, and its rule that delegation does not widen the authority of the task.

- One sub-agent per batch, **read only**: read commands, its output file under the temporary folder the batch names, no commit, no push, no move, no write anywhere else.
- Only the Executor writes to a repository: it gathers the output files, checks each against its batch's targets, and cites it in the report with the batch that produced it.
- A batch that fails the gate, or a runtime with no sub-agents, is measured one after the other; the rubric never makes a Mission depend on delegation.

## 4. Cross-review before filing

Three rubrics, two by two (DECISION-115547 point 2): each count of `## Validations` is reachable without violating a prohibition of `## Gates` or of `## Constraints`; each step of `## Steps` is allowed by the same prohibitions. Trace it through the HTML comment at the head of `## Validations`. A contradiction found = **rewrite, do not file** (faults 090 and 108 ×2: contradictions caught at execution).

## 5. Final form check

Run `mission-checklist.md` in this skill's folder, line by line, before filing **any Pilot artefact** (Mission, Decision, capture, handoff, proposal) — not only a Mission: the two STOPs of Mission 149 fell on a Decision filed without the list having been run (report 157, F3). Each line cites the fault or the Decision that paid for it; a failing line = no filing.

## 6. File through the DRAFT pattern

`DRAFT-<slug>.md` at the canonical location (the project's `missions/`) → `get_file_info` → measured timestamp substituted in `created_at` and in the name → rename to `MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md` → final `get_file_info`. A single turn; `created_at` = timestamp of the name.

## 7. Produce the mini-prompt

Five fixed rubrics of RULES-124937, in order: title `Session Executor — Mission <NNN> (<description courte>)` · free position · source to apply (path of the Mission) · **the four standard prohibitions only** — no non-delegated push, no model call, no deletion, move to `_trash/` only on the Mission's prescription — plus an explicit reference to the Mission's `## Gates` and `## Constraints` rubrics (DECISION-115547 point 3) · expected output = the RELAY block of rule 124937; its summary follows the ceiling of rule 124937, never restated here. Never a prohibition of its own added in the prompt. Delivered as a snippet copyable in a single gesture, no PROMPT file (abolished, Decision A7).

## What this skill does not do

Execute the Mission (Executor) · decide the architecture in the Owner's place (a choice outside "way of implementing" = question to the Owner) · write a PROMPT file · close or open a session · modify a Mission already executed (frozen, RULES-211522): a correction goes through a `-C01` Mission or an Owner arbitration.

## Liens

- `see also` — [Form checklist for a Pilot artefact, one fault per line](./mission-checklist.md)
- `see also` — [Mission template](../../templates/mission-template.md)
- `see also` — [Two work regimes: the light Note and the full Mission](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)
- `see also` — [Execution Note template](../../templates/execution-note-template.md)
- `applies` — Decision — Internal consistency of Missions (workshop history, not distributed) (hors Vault)
- `applies` — [Relay between roles through mini-prompts with fixed rubrics](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `applies` — [Versioning of Missions and generated outputs](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `applies` — [Decision — Evidence status and STOP control](../../decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
