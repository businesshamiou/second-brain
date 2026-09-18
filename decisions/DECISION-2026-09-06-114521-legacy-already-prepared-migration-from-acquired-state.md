---
type: decision
title: "Decision — Legacy already prepared: cold backup verified, legacy branch pushed; the work item does not reopen, the migration starts from this acquired state"
created_at: "2026-09-06T11:45:21-04:00"
timezone: America/Montreal
status: active
description: "Owner amendment of 2026-09-06 (file amendement-owner-legacy-deja-prepare.txt, in chat): the preparation of the Legacy is finished and validated — cold backup verified, legacy branch created and pushed to the Vault's remote repository. Consequences: no new preparation, backup or general audit of the Legacy; the migration Mission (143) starts from this acquired state and runs only the cutover of the V1 plan; the Legacy work item reopens only on a new and measured divergence. Amends sequence 3 of PROPOSAL 165829 on these points; the targeted extraction of the Owner's data according to the arbitrated manifest remains due, from the legacy branch."
---

# DECISION — Legacy already prepared, migration from the acquired state

## Context

The V1 closing PROPOSAL (165829, 2026-09-05, accepted) prescribed in sequence 3: preservation of the Legacy (tag, zero writes), READ-ONLY inventory by Claude Code under a dedicated authorization, Owner arbitration of the extraction manifest, then Mission 143. The Owner carried out the preparation on their side and validated it on 2026-09-06.

## Decision (Owner, 2026-09-06, verbatim of the transmitted file, translated from French)

Acquired state: cold backup verified; legacy branch created and pushed to the remote repository businesshamiou/vault; the Legacy is secured and ready for the future cutover.

1. **Redo neither preparation, nor backup, nor audit of the Legacy.** These steps of the V1 sequence are acquired and leave the plan.
2. **The migration phase (Mission 143) starts from this acquired state** and carries out only the necessary cutover operations, in accordance with the V1 plan.
3. **The Legacy work item does not reopen**, unless a new and **measured** divergence requires it.
4. The V1 closing plan continues from the current state.

## Consequences

- Mission 143 replaces its preservation and inventory steps with a **measurement precondition**: the legacy branch exists on the remote (`git ls-remote`), its HEAD is pasted, and the STABLE clone is made on main — the legacy branch is never merged or modified.
- The targeted extraction of the Owner's data (manifest of PROPOSAL 165829, Owner arbitration required) remains due; its source is the pushed legacy branch, not a new audit.
- Architecture fact recorded, to be measured as a precondition of 143: the old content lives as a **branch of the same remote repository** as the new Vault, not as a separate repository.
- PROPOSAL 165829 is not rewritten (it remains the accepted plan); the present Decision amends it on points 1–2 and prevails in case of discrepancy.

## Alternatives set aside

- Replay the inventory out of caution: contrary to the Owner's order and to the principle « pas de précipitation, mais pas de re-travail » ["no haste, but no rework"]; the cold backup and the pushed branch are the measurable insurance.
- Engrave only in chat: an unengraved order loses against a committed plan over the sessions — measured several times in this project.

## Annotation of 2026-09-07

Measured fact (report 148 §5): `<depot-prive>-works\vault` (Legacy) pushes to `businesshamiou/vault.git`, `workshops\vault` (NEXT) to `businesshamiou/ai-context-vault.git` — two distinct remotes, not "the same remote repository". Decision 125156 amends this point: the confirmed final target remains `businesshamiou/vault` (modern `main` + `legacy` branch), reached from two repositories that are separate today.

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `see also` — PROPOSAL — Closing of V1 (workshop history, not distributed) (hors Vault)
- `applies` — [Decision — Evidence status and STOP control](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `amended by` — [Decision — Seven arbitrations on the machine dependencies before cutover](./DECISION-2026-09-07-125156-cutover-dependencies-seven-arbitrations.md)
