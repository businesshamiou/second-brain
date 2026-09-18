---
type: decision
title: "Internal coherence of Missions — mandatory Context section, cross-review before filing, mini-prompt with no prohibition of its own, least powerful reading at execution"
description: "Engraves four rules for writing and consuming Missions after three internal contradictions caught at execution (Mission 090, Mission 108 twice) that no guardian can see: a mandatory Context section with fixed content, a traced Validations ↔ Prohibitions ↔ Steps cross-review before filing, a mini-prompt that carries no prohibition specific to the Mission, and the execution rule by which the Executor retains the least powerful reading of a contradiction and reports it. Closes the door open-mission-internal-coherence by its own condition (\"a written rule\")."
created_at: "2026-09-01T11:55:47-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-09-01-115547-mission-context-coherence-and-least-powerful-reading.md"
---

# DECISION — INTERNAL COHERENCE OF MISSIONS

## Date

2026-09-01

## Status

`ARBITRATED` — exact word « graver » ["engrave"], Owner, 2026-09-01, in the Pilot window, after a single recommendation.

## Decision

Four rules, applicable to every Mission written or executed from this day on, in the Vault as in any project.

**1. The `## Contexte` (Context) section is mandatory in a Mission**, placed between the status reminder and `## Objectif` (Objective). It contains, in this order and without exception: the measured facts that motivate the Mission, each with its date and its mode of measurement (`MESURÉ`, `DECLARED`, `HYPOTHÈSE`); what the Executor will find on disk and why it is there; the known traps (precedents, tool defects, misleading locations); and why the decision that authorizes the Mission is what it is. A Mission without context forces the Executor to reconstruct the history — or to ignore it, which amounts to deciding the architecture in its place.

**2. Before filing, the Pilot does a cross-review** of three rubrics two by two: each criterion of `## Validations` must be reachable without violating a prohibition of `## Gates` or of `## Contraintes` (Constraints), and each step of `## Étapes` (Steps) must be allowed by the same prohibitions. The review is traced by an HTML comment at the head of `## Validations` (« Relecture croisée faite par le Pilot avant dépôt : … » ["Cross-review done by the Pilot before filing: …"]). A count of Validations that the Prohibitions make impossible is a drafting fault of the Pilot, not a case for the Executor to arbitrate.

**3. The Executor mini-prompt carries no prohibition specific to the Mission.** Its rubric 4 (`RULES-2026-08-23-124937`) is limited to the four standard prohibitions — no push, no model call, no deletion, move to `_trash/` only when prescribed by the Mission — plus an explicit reference to the Mission's `## Gates` and `## Contraintes` rubrics as the only list of its own prohibitions. A Mission has a single source of gates; a prohibition added in the mini-prompt is a second normative text, invisible to the review of point 2, and that is how Mission 108 contradicted itself.

**4. At execution, an internal contradiction is resolved by the least powerful reading.** When two rubrics of a Mission contradict each other, the Executor retains the interpretation that writes the least, deletes nothing and modifies no file outside the narrowest perimeter; it records the contradiction and its resolution in the « Écarts » ["Deviations"] rubric of the report and in the `Résumé` of the RELAY. It does not stop for this (it is not a precondition STOP), unless no reading is harmless. It is the mirror, for Missions, of the charter's rule for roles: the error must fall on the harmless side.

## Reason

Three internal contradictions in three Missions, all of the same type — one rubric asks for what another forbids:

- Mission 090 (2026-08-29): the Doors rubric prescribed a verbatim that the Validations rubric counted at zero. Caught at execution; door `open-mission-internal-coherence` opened with the closing condition « une règle écrite ou le futur skill d'écriture de Mission » ["a written rule or the future Mission-writing skill"].
- Mission 108 (2026-09-01), first contradiction: Validations required `vault-source-sha256 = e23edad2…(workshop history, not distributed)superseded-files.txt`, which the Executor tidied among the residues. The contradiction was not in the Mission: it was between the Mission and a text nobody rereads.

No guardian can see these faults: they bear on meaning, not on form. Both times Mission 108 contradicted itself, the Executor took the least powerful reading, said so in the RELAY and broke nothing — a reflex that was written nowhere and held on doctrine alone. A measured constant of the Vault (audit 057, DECISION-153503): what holds on doctrine alone drifts; what is written and then mechanized holds. The rule is therefore engraved now, and the mechanism — the Mission-writing skill, designated by the measured evidence as the most cost-effective (handoff 2026-09-01 §3) — will inherit it when it is built.

## Impact

- The template `vault/templates/mission-template.md` is amended (Mission 111): `## Contexte` section added with its instruction comment; cross-review comment added at the head of `## Validations`.
- `RULES-2026-08-23-124937` rubric 4 is amended by this Decision (reciprocal `amended by` placed in the Vault, Mission 111): four standard prohibitions plus a reference to the Gates, nothing else.
- The charter (`RULES-2026-08-23-224706` §3, Executor role) receives a reciprocal `amended by` for point 4: the Executor never corrects silently — nor does it « corrige » ["correct"] a contradiction by choosing the broadest reading.
- Missions 109 and 110 (filed on 2026-09-01 before this Decision) already apply points 1 to 3; they are not touched up (freeze, DECISION-013217).
- Door `open-mission-internal-coherence`: closed by this Decision, condition "a written rule" satisfied. The `CLOSE:` line is written by Mission 111.
- Skills V1 work item (point 3 of the queue): the Mission-writing skill gains one more argument for the build order; this Decision becomes one of its sources. Nothing is settled here on that order.
- Cost: one short Mission (111), no push/re-pin cycle (template and rule are not hooks).

## Important alternatives

- **Engrave nothing, let the Mission-writing skill carry these rules.** Rejected: the skill does not exist, its build order is not settled, and the fault has replayed twice in three days since the door was opened. The skill will inherit from the Decision; the reverse would have left three more sessions without a rule.
- **Note it in a capture at close only.** Rejected: a capture is never a norm; the door would stay open with its condition unmet.
- **A coherence guardian.** Rejected as unfeasible: the contradiction is semantic; the only possible mechanism is the skill that writes the Mission, not a check that reads it.
- **Allow the Executor to stop (STOP) on a contradiction.** Kept open as a variant of point 4: the STOP costs a whole window for a case that the least powerful reading settles without damage. Reserved for the case where no reading is harmless.

## Human gate

- Validation: granted — « graver » ["engrave"], Owner, 2026-09-01.
- Reference: this Pilot window (single recommendation, exact word embedded, one-word answer).

## Linked artefacts

- Source: `../reports/REPORT-2026-09-01-111007-108-skills-library-update-from-package.md` (§6, the two contradictions and their resolution)
- Source: `../missions/MISSION-2026-09-01-105013-108-skills-library-update-from-package.md` (contradictory Mission, frozen, not touched up)
- Execution: Mission 111 (template, reciprocals, `CLOSE:` line)

## Liens

- `prescribed by` — [Decision template](../../../vault/templates/decision-template.md) (hors Vault)
- `amends` — [Relay between roles through mini-prompts with fixed rubrics](../../../vault/rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md) (hors Vault)
- `amends` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `amends` — [Mission template](../../../vault/templates/mission-template.md) (hors Vault)
- `see also` — Decision — Door hygiene, thirteen arbitrations (workshop history, not distributed)
- `see also` — Decision — Code is never a norm (workshop history, not distributed)
- `see also` — Report 108 — skills library update (workshop history, not distributed)
