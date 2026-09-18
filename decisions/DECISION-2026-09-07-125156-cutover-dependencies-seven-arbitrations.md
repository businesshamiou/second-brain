---
type: decision
title: "Decision — Machine dependencies before cutover: seven Owner arbitrations on report 148, measured divergence of the Legacy remote annotated, disk target of 143 left OPEN"
created_at: "2026-09-07T12:51:56-04:00"
timezone: America/Montreal
status: active
amends:
  - "./DECISION-2026-09-06-114521-legacy-already-prepared-migration-from-acquired-state.md"
description: "Owner arbitrations of 2026-09-07 on the seven questions of report 148 (read-only inventory of the workstation's dependencies). Architecture fact measured and engraved: the Legacy and the NEXT push to two distinct remote repositories (businesshamiou/vault.git and businesshamiou/ai-context-vault.git); Decision 114521 is annotated, never rewritten. Final remote target confirmed: modern main + legacy branch in businesshamiou/vault. vault-view in LEGACY-2/UNKNOWN status, intact and outside 143; backup-vault-migration backup not confirmed as canonical; scheduled tasks, PowerShell profile, Workspaces.lnk and safe.directory: no action before v1.0.0-stable. One point remains OPEN: the disk location of 143 (aios-stable\\vault according to PROPOSAL 165829, <depot-prive>-works\\vault according to arbitration 5). Work order confirmed: push 4c9cc09, this Decision, Mission 149 packed-refs, cold start replayed, then 143."
---

# DECISION — Seven arbitrations on the machine dependencies before cutover

## Context

Mission 148 (report (workshop history, not distributed), outside the Vault, commit the workshop (history, not distributed) `4c9cc09`) inventoried read-only what, on the workstation, depends on a Vault path: 188 scheduled tasks of which 2 retained, 4 PowerShell profile paths of which 1 active, 3 repositories measured, 0 NTFS junctions, 14 configuration files, 0 access denied. It asked seven questions without recommendation. The Owner arbitrated on 2026-09-07.

## Measured fact that contradicts an engraved Decision

Report 148 (§5, question 1) measures that `<depot-prive>-works\vault` has `businesshamiou/vault.git` as `origin`, and `workshops\vault` (NEXT) `businesshamiou/ai-context-vault.git`. Decision 114521 stated "the old content lives as a branch of the same remote repository as the new Vault". This is the new and measured divergence that that Decision provided for. In accordance with Decision 145256, 114521 is not rewritten: it receives a dated annotation naming the present Decision, with `amends` / `amended by` reciprocity.

## Decision (Owner, 2026-09-07, verbatim, translated from French)

1. **Legacy remote.** YES, `legacy` is indeed kept on `businesshamiou/vault.git`. On the other hand, `ai-context-vault.git` remains the current/source repository of the NEXT; it does not automatically become the final canonical repository. The target already decided remains: future modern `main` + `legacy` branch in `businesshamiou/vault`. Annotate the measured divergence without rewriting the historical Decision.
2. **`vault-view`.** Provisional status LEGACY-2 / UNKNOWN. Leave it strictly intact, outside the cutover and outside the scope of 143. Do not "secure it like the Legacy" nor open it further as long as its role is not established.
3. **`backup-vault-migration\2026-09-05-200520\`.** NOT CONFIRMED as the canonical cold backup. Do not use it as proof of satisfying Decision 114521 without existing evidence that identifies it explicitly. Leave it intact.
4. **`VaultDoctorNightly` and `VaultReflect`.** Modify nothing during 143. After `v1.0.0-stable`, check that their commands still exist in the modern Vault; if so, repoint them to the stable production. If the corresponding function no longer exists, disable them rather than artificially recreating a dependency.
5. **PowerShell profile.** Modify nothing before the cutover/tag. The final target being `<depot-prive>-works\vault`, validate after cutover that the dot-source does resolve to the new Vault; modify the profile only if the target file has really changed path.
6. **`Workspaces.lnk`.** Outside the product and outside the cutover. Do not move it to `_trash` now. Leave it intact and postpone its possible cleanup until after stabilization; it must neither block nor enter 143.
7. **Global `safe.directory`.** No action now. 143 measures the behaviour on the STABLE clone. Add a `safe.directory` exception only if Git really demands it and within the corresponding Owner gesture.

These arbitrations do not change the agreed order: (1) push `4c9cc09`; (2) record these arbitrations; (3) short `packed-refs` intervention in Mission 149; (4) replay the cold start to check `READY` and the call budget; (5) only after PASS of this acceptance, resume 143. Do not reopen Mnemosyne, OpenViking, Legacy or a memory architecture work item.

## Point left OPEN — not filled in by the Pilot

**Disk location of 143.** Arbitration 5 names `<depot-prive>-works\vault` as the final target. PROPOSAL 165829 (accepted) prescribes a clone to `<depot-prive>-works\aios-stable\vault`, `<depot-prive>-works\vault` remaining LEGACY intact on disk. Two locations for one and the same gesture. As long as the Owner has not said which one is that of 143 — or whether the second is a later step —, 143 is not written. A dated annotation on the present Decision will close this point.

   **Dated annotation 2026-09-08 (Owner, chat, recorded by Mission 165).** The disk location of 143 is <depot-prive>-works, subfolder aios-stable, subfolder vault; <depot-prive>-works, subfolder vault alone, remains LEGACY intact on disk, unchanged by 143. The point is closed.

## Consequences

- Precondition of Mission 143: the `legacy` branch is checked by `git ls-remote` on `businesshamiou/vault.git`; the STABLE clone starts from the pushed head of `ai-context-vault.git`. The final canonical repository (`businesshamiou/vault`, modern `main` + `legacy`) is a remote promotion target, later than the tag, which requires its own human gate (new external frontier).
- Mission 143 mentions neither `vault-view`, nor `backup-vault-migration\`, nor `Workspaces.lnk`, except to observe that they are intact.
- Gestures 4 and 5 are Owner gestures post-`v1.0.0-stable`, to be measured by a reading Mission before any repointing.
- Mission 149 commits the present Decision, the annotation of 114521 and the Decisions index in its vault batch.

## Alternatives set aside

- Understanding arbitration 5 as a change of target for 143: that is a reading, not an arbitration; the Pilot does not fill an OPEN by proximity (charter §2).
- Rewriting Decision 114521: forbidden by Decision 145256.

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amends` — [Decision — Legacy already prepared, migration from the acquired state](./DECISION-2026-09-06-114521-legacy-already-prepared-migration-from-acquired-state.md)
- `applies` — [Decision — Evidence status and STOP control](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `source` — Report 148 — read-only inventory of the machine dependencies (workshop history, not distributed) (hors Vault)
- `see also` — PROPOSAL — Closing of V1 (workshop history, not distributed) (hors Vault)
