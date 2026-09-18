---
type: rules
title: "Project structure standard — seven functions, skeleton, Vault/project boundary, YAGNI, grandfather clause"
description: "Sets in stone the project standard arbitrated on the evening of 2026-08-25: the seven minimal functions of a project, the reference skeleton, the Vault/project boundary test, the YAGNI principle and the grandfather clause for (workshop history, not distributed)."
created_at: "2026-08-26T14:28:00-04:00"
timezone: America/Montreal
status: active
scope: project-structure-standard
amends: "../decisions/DECISION-2026-08-19-115306-project-registry-v1.md"
---

# PROJECT STRUCTURE STANDARD

This rule sets in stone, for every project of the workspace, the structure contract that registry v2 measures (Mission 061). It applies the arbitrations of the Decision — Consolidation of the evening of 2026-08-25 (workshop history, not distributed) (hors Vault), §1.

## 1. The seven functions

A project's vital minimum is defined by seven functions, not by folders:

1. **Identity** — "what is this project?"
2. **Business rules** — "which laws apply here and only here?"
3. **State memory** — "where do we stand?"
4. **Execution** — "what have we had done?"
5. **Arbitration** — "what have we decided?"
6. **Material** — "what have we learned?"
7. **Handover** — "how do we resume?"

## 2. Reference skeleton

The functions live at the root of the project — no intermediate working subfolder. Additional subfolders are born as the real need arises, never in anticipation (§4, YAGNI), according to the naming norms and the good practices of the software industry.

    <projet>/
    ├── README.md      (identity, entry point)
    ├── rules/         (the project's business rules)
    ├── state/         (journal + generated sheet)
    ├── missions/      (Missions AND their reports — same lineage)
    ├── decisions/     (arbitrations rendered)
    ├── proposals/     (pending options — kept separate: an option is not an arbitration)
    ├── knowledge/     (material: captures, studies, notes)
    └── handoffs/      (handover)

Explicit exclusions from the standard: `prompt-archive/` (abolished, mini-prompts as copyable snippets only), `audits/` (an audit is an execution, its report goes into `missions/` with the others), `generated/` (born as needed, outside the minimum).

## 3. Vault/project boundary test

Every candidate rule is submitted to the following test:

> "Would this rule make sense in another project?"

Yes → it lives in the Vault (portable, distributable). No → it lives in the project's `rules/` folder. The Vault remains distributable; business rules stay at home.

## 4. YAGNI principle

No subfolder, no field, no mechanism is created in anticipation of a future need. A project is born with the skeleton of §2 and nothing more; extension happens at the moment the need is real and measured, never before.

## 5. Grandfather clause

(workshop history, not distributed) stays as it is: no restructuring, no migration to the skeleton of §2. Known cost (relative links, cf. Missions 052–055) for zero gain. Its non-conformity to the present standard has the teaching value of a before/after and will be **noted, never corrected** by `tools/check-project-conformity.sh` (Mission 061, step 4). The only rule that still applies to it: no more filing in its dead folders.

(workshop history, not distributed) is the sole beneficiary of this clause. Every project created after the adoption of this standard conforms to it from its birth, without exception or grace period.

## Liens

- `see also` — [Versioning of Missions and generated outputs](./RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) (§8, Mission 172 clarification: its inheritance clause does not exempt from the reference skeleton above)
- `amends` — [Decision — Project Registry V1](../decisions/DECISION-2026-08-19-115306-project-registry-v1.md)
- `source` — Decision — Consolidation of the evening of 2026-08-25 (workshop history, not distributed) (hors Vault)
