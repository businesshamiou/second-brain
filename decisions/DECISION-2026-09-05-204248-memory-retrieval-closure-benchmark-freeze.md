---
type: decision
title: "Decision — Close of the memory/retrieval phase before V1 STABLE: bounded benchmark native Vault / Mnemosyne / OpenViking, KEEP or REMOVE verdict per tool, no coexistence by default, then FREEZE"
created_at: "2026-09-05T20:42:48-04:00"
timezone: America/Montreal
status: active
description: "Owner amendment of 2026-09-05 to the V1 closing plan (PROPOSAL 165829): Mnemosyne is not a given; OpenViking receives one last test in a sandbox, without integration or widening; a benchmark compares native Vault, Vault + Mnemosyne, Vault + OpenViking on recall, precision, latency, context volume, operational cost; each tool receives a reasoned KEEP, REMOVE or DEFER; coexistence only on demonstrated benefit; any technology without measurable fruit is removed cleanly and documented; then FREEZE of the memory/retrieval layer for V1 STABLE. The benchmark starts only after the autonomy blockers are closed."
---

# DECISION — Close of the memory/retrieval phase before V1 STABLE

## Context

V1 is closing (PROPOSAL 165829, arbitrations of 2026-09-05): autonomous Vault (Mission 142, objective reached, Owner opening test pending), then Legacy inventory and promotion (Mission 143). Two memory/retrieval tools are in play: Mnemosyne, installed in recall-only mode since Mission 126 and never measured for real gain (no Mission triggered by its recall; empty recall on "OpenViking" on 2026-09-04, two false results with a zero score); OpenViking, evaluated on its README and website on 2026-09-04 (three-level context base L0/L1/L2, local server, model required), never installed. Four other candidates were set aside on reading (Rta-Smriti, ModelDeck, Cortex Suite). The measured problem that motivates the question: reading a whole index costs up to 58 times the digest (audit 139) — the structural answer (locator indexes, Decision 124647) is under way; the question of the recall tool remains open.

## Decision (Owner, chat, 2026-09-05)

1. **Mnemosyne is not a given.** Its real contribution is measured; without demonstrable gain, or if its cost and complexity exceed its usefulness, it is removed cleanly. The absence of a tool is preferred to a dependency without measured value.
2. **OpenViking receives one last test, in sandbox/LAB only**: no permanent integration before a result, no widening of the architecture, no impact on the critical path of stabilization.
3. **Bounded benchmark**, three configurations at minimum — native Vault; Vault + Mnemosyne; Vault + OpenViking — on the same questions and the same corpus; measurements: recall quality, precision, latency, volume of context and tokens loaded, operational cost and complexity (installation, dependencies, maintenance).
4. **Explicit verdict per tool** at the end: KEEP, REMOVE, or DEFER only if a measurable reason really prevents concluding — the reason is written.
5. **No coexistence by default.** Mnemosyne and OpenViking coexist only if the benchmark demonstrates two complementary functions with a real benefit.
6. **Clean and documented removal** of any technology without measurable fruit: uninstallation, wiring removed, manifest and rules up to date, "experimented / rejected" note with the measurements.
7. **FREEZE** of the memory/retrieval layer afterwards for V1 STABLE: no other memory tool, vector base, graph memory or retrieval is tested before the next NEXT/LAB phase. OpenViking is the last trial of this phase, not the opening of a work item.
8. **Order**: the benchmark starts only after the autonomy blockers are closed (Pilot opening test of 142, machine dependency of the repository). It precedes the Legacy inventory and Mission 143 in the closing plan.

## Consequences

- Benchmark Mission to be drafted (LAB, outside the repositories, in a throwaway folder): corpus and questions fixed before any installation, three configurations, measurements pasted, KEEP/REMOVE/DEFER verdicts proposed for Owner arbitration.
- Removal Mission, if REMOVE: Mnemosyne (MCP server, bank, store wiring on the journal, rules and skills that name it) and/or OpenViking (sandbox destroyed); rejected-experiment note in the project's knowledge.
- The closing plan (PROPOSAL 165829, section 3) is amended: step 2 bis, benchmark and verdicts, between 142 and the Legacy inventory.
- The OpenViking capture of 2026-08-24, parked "post-workshop", is the only earlier trace: it is a source of the benchmark, never a norm.

## Alternatives set aside

- Keep Mnemosyne by default: dependency without measurement, contrary to point 1.
- Integrate OpenViking without a benchmark: widening of the architecture in the stabilization phase, contrary to the guiding principle of the close.
- Postpone the whole question until after V1: would leave an unmeasured tool in the stable version; the benchmark is short and bounded, it fits before the tag.

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `source` — PROPOSAL — Closing of V1 (workshop history, not distributed) (hors Vault)
- `see also` — [Decision — An index is a locator](./DECISION-2026-09-05-124647-index-as-locator-8000-cap-live-archive.md)
- `applies` — [Decision — Evidence status and STOP control](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
