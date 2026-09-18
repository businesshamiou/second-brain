---
type: decision
title: "Distribution of transverse mechanisms — single doctrine, pinned implementation, local adapter"
created_at: "2026-08-24T21:46:07-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: granted
---

# DECISION — DISTRIBUTION OF TRANSVERSE MECHANISMS

## Date

2026-08-24

## Status

`ARBITRATED`

Human gate granted by the Owner in the session of 2026-08-24 at 22:31:52-04:00, on the measurement of Mission 048.

## Decision

Three classes of objects, three distinct rules. The current confusion comes from treating them as one.

**D1 — Doctrine lives in the Vault, in a single copy.** Rules, Decisions, templates. Never duplicated in a project, never copied "for convenience". Two copies of a rule are two rules that will diverge, and on the day of the divergence nobody will know which one is authoritative.

**D2 — Transverse mechanisms have a single implementation, consumed by pinned version.** Secrets check, links check, obsolescence guardrail, generators of the state sheet and of the indexes. The code exists once. A project consumes it by declaring *which version* it applies — never by reaching a sibling folder through a relative path.

**D3 — Each project carries only a declarative adapter and its business scripts.** The adapter says which checks apply and at which version. The scripts specific to a project's business stay in that project and have no business in the Vault.

**D4 — Arbitration criterion, enforceable.** Faced with any new script, a single question: *does this project, cloned alone on a new machine, still apply its rules?* If the answer is no, the coupling is wrong and must be redone.

**D5 — Duplicating an adapter is not duplicating a rule.** A Git hook is per-repository and per-clone by construction; requiring it to be single would be requiring the impossible. The forbidden duplication concerns the doctrine and the mechanism's code, never the few lines that invoke them.

**D6 — No automatic retroactive rework.** In accordance with the Vault operating rules §10, this Decision opens no correction of the existing stock. Convergence is an explicit work item, opened by a separate Mission.

**D7 — The pinning vehicle is V1: pinned configuration.** Each project carries a configuration file declaring the checks it applies and the exact version at which it applies them. Arbitrated on the measurement of Mission 048, which set aside V3 (last in gestures after a bare clone and in version upgrade) and separated V1 from V2 on the readability of the pinning: a `rev` in configuration can be read and reviewed in a diff, a submodule pointer cannot be read.

Cost accepted and named: V1 is the only one of the three routes requiring a third-party tool on the machine (measured at 3.70 s + 2.31 s of cold install). If the distributable repository intended for non-developers becomes a priority, this extra step in the installation questionnaire legitimately reopens the arbitration.

## Reason

The current state is an accidental hybrid, never decided, measured by direct reading on 2026-08-24:

- `tools/check-secrets.sh` exists **in two copies**, one per repository, free to diverge silently.
- `tools/check-links.sh` exists **only in the Vault** and is never called from (workshop history, not distributed), whose hook does not mention it.
- The hook of (workshop history, not distributed) reaches the Vault through a **hard-coded `../vault/`** to read the preflight stamp.

The third point is the most serious, and not for a reason of aesthetics. The roadmap plans a **separate distributable repository**, packaged by a later Mission with an installation questionnaire. A repository that requires the presence of a sibling folder named `vault` on the user's machine **is not distributable**. The coupling through a filesystem path is set exactly against the product goal it will prevent from being reached.

## Impact

**What it costs.** A central mechanism can break N projects with a single commit. This is precisely what version pinning buys: a project upgrades when it chooses to, not when the Vault commits. **Centralizing without pinning would trade duplication for a worse fragility** — it is the only serious failure mode of this Decision, and D2 exists to forbid it.

**What it changes in practice.** The obsolescence guardrail delivered by Mission 046 works today — five fabricated cases proven on the real hook. This Decision does not call it into question: it changes the way it will be *reached*. The transition is therefore a moment of risk, and must be proven before being declared.

**What remains open.** Two facts that Mission 048 did not measure and that must be measured before going into production:

- **The failure mode.** What does the check do when the tools' source is unreachable at commit time? Does it refuse, or does it let things through silently? This is exactly the defect fixed by Mission 046 in the Vault's hook; reintroducing it through the vehicle would be losing what has just been gained.
- **SSH versus HTTP.** Criterion C4 was measured on a local HTTP Basic server. A private repository reached over SSH does not behave the same way. Not measured.

These two points are proven in the convergence Mission, on the chosen route, rather than by an additional measurement Mission.

## Important alternatives

- **Duplicate everything per project.** Rejected: this is the current state of `tools/check-secrets.sh`, and silent divergence is its mechanical consequence, not an accident.
- **Centralize everything through a relative path.** Rejected: works on the Owner's machine, fails on any other. Incompatible with the distributable repository.
- **Copy/`cookiecutter` with re-synchronization.** Kept open for the project template, where drift is accepted then reconciled. Not suited to the checks, which must be identical and not "close".
- **Decide nothing and fix case by case.** Rejected: this is what produced the current hybrid.

## Human gate

- Validation: granted
- Date: 2026-08-24T22:31:52-04:00
- Scope: D1 to D7, vehicle V1 included
- Reference: arbitration given in a piloting session on the 3 routes × 5 criteria table of Mission 048

## Linked artefacts

- Measurement of the state of the hooks and tools: direct reading of 2026-08-24, Pilot session
- Mission that delivered the guardrail concerned: (workshop history, not distributed) (hors Vault)

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `applies` — [Operating rules of the Vault](../rules/RULES-2026-08-17-005717-vault-operating-rules.md)
- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `see also` — Mission 046 — obsolescence guardrail (workshop history, not distributed) (hors Vault)
