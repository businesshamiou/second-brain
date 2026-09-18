---
type: rules
title: "Versioning of Missions and generated outputs"
created_at: 2026-08-17T21:15:22-04:00
timezone: America/Montreal
status: active
scope: transverse-project-governance
owner_gate: granted
---

# VERSIONING OF MISSIONS AND GENERATED OUTPUTS

This cross-cutting rule applies to the Vault and to the projects that inherit from it. It complements the [context cycle V2](./RULES-2026-08-17-111018-context-lifecycle-v2.md) without imposing the creation of folders without a real need.

## 1. Permanent identity of a Mission

A Mission receives a project identifier on three digits: `001`, `002`, `003`, etc.

Convention:

`<projet>/missions/MISSION-YYYY-MM-DD-HHMMSS-NNN-description.md`

The timestamp answers "when was this file created?". The ID answers "which Mission does it represent?".

## 2. Corrections

A correction keeps the ID and adds `C01` to `C10`:

`<projet>/missions/MISSION-YYYY-MM-DD-HHMMSS-NNN-Cxx-description.md`

The original never uses `C00`. Reaching `C10` requires re-examining whether the objective must become a new Mission.

Each correction receives its real timestamp. No fictitious redating is allowed.

## 3. Complete, self-contained version

A correction is not an isolated patch. The latest active version contains the objective, the scope, the sources, the applicable decisions, the constraints, the steps, the gates, the validations and the output contract currently valid.

The Executor consumes the latest active version; it does not reconstruct the current state by adding up all the previous versions.

The old versions remain kept as history. Each correction declares at least `mission_id`, `correction`, `supersedes` and `status`.

## 4. Aligned prompts (historical note — convention closed at Mission `038`)

Convention active until Mission `038` (end of the PROMPT files, Decision `220049`); kept for reading earlier Missions, not applied beyond. The canonical Executor Prompt carried the same functional identifier as its Mission:

- original: PROMPT-YYYY-MM-DD-HHMMSS-NNN-executor-description.md;
- correction: PROMPT-YYYY-MM-DD-HHMMSS-NNN-Cxx-executor-description.md.

The Prompt has its own real timestamp. A correction that modifies the Executor contract aligns Mission and Prompt on the same `Cxx`.

## 5. Cumulative Decisions

Decisions do not follow the `NNN-Cxx` numbering. They remain cumulative.

A more recent Decision replaces an earlier one only if it explicitly declares `supersedes`, `amends` or `revokes`. An arbitrated proposal is not silently rewritten: a new Decision records the arbitration and references the history.

## 6. Living register

A project that uses Missions maintains, when the need exists:

`<projet>/missions/MISSION-INDEX.md`

The register states at least the ID, the objective, the active version, its status and the path of the active Mission. It does not copy perishable technical measurements.

## 7. `generated/` zone

`generated/` is a landing zone for an output whose canonical destination is not yet determined.

Rules:

- non-canonical by default;
- review and validation before promotion;
- provenance kept;
- dated naming respected;
- never use it when a canonical destination is already known;
- never place a secret there or bypass the project's Git rules.

Promotion to a canonical location is explicit. Deleting an output follows the applicable human gates.

## 8. Inheritance

Order of specialization:

```text
Vault rules
    ↓
Project rules
    ↓
Mission / task instructions
```

A project inherits this doctrine and documents only its authorized specializations or exceptions. Inheritance concerns behaviour; it does not force the creation of folders without a real need beyond the reference skeleton.

Clarification (Mission 172, audit defect 8): this clause does not contradict the [Project structure standard](./RULES-2026-08-26-142800-project-structure-standard.md), which is later and more specific — its §2 mandates `missions/` in the reference skeleton of **every** project created after its adoption, without exception. "Without a real need" targets folders **outside** that skeleton (for example `generated/`, which remains a landing zone created as needed, §7 above) — never `missions/`, whose need is already established by the standard itself from the project's birth.

## 9. Active consumption

To execute a Mission:

1. read the relevant active Decisions;
2. resolve the latest active version via `<projet>/missions/MISSION-INDEX.md` when it exists;
3. read the complete Mission;
4. read the aligned Prompt (only for Missions earlier than Mission `038`; convention closed beyond, Decision `220049`);
5. measure the useful technical state again;
6. respect the project's gates and boundaries.

## 10. Self-tidying

Every Mission commits its own file and regenerates the generated indexes as the last steps of its execution window. A Mission that leaves this tidying to a later window declares it explicitly as ANOMALY in its report. [source: [Decision — Doctrinal arbitrations of 2026-08-25](../decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md), point 2]

## Liens

- `see also` — [Project structure standard](./RULES-2026-08-26-142800-project-structure-standard.md) (§8, Mission 172 clarification: the reference skeleton mandates `missions/` without exception, more specific than the present inheritance clause)
- `amended by` — [Decision: PIV taxonomy, English system language, role charter, end of PROMPT, §4 aligned prompts](../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md)
- `amended by` — [Decision — A Mission file is frozen as soon as its snippet is issued](../decisions/DECISION-2026-08-30-013217-mission-frozen-at-snippet-emission.md)
- `source` — [Decision — Doctrinal arbitrations of 2026-08-25](../decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md)
