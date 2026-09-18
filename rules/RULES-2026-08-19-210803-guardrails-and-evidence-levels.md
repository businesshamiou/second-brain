---
type: rules
title: "Guardrails and evidence levels"
description: "What protects the repository, and how to qualify a fact according to its level of persistence."
created_at: 2026-08-19T21:08:03-04:00
timezone: America/Montreal
status: active
scope: vault-guardrails
---

# GUARDRAILS AND EVIDENCE LEVELS

## 1. The three levels of truth

The word "done" is forbidden on its own. Any claim that a piece of work is accomplished states its level of persistence:

| Level | Meaning | Verification |
|---|---|---|
| done on disk | the file exists and contains what is claimed | reading the file |
| done and committed | the content has entered the local history | `git log`, `git show` |
| done and pushed | the content exists outside this machine | `git status -sb`, measuring the remote |

Work done on disk and not committed disappears with a hardware incident. Work committed and not pushed disappears with the machine. Saying "it's done" without a qualifier hides this risk.

This scale complements the evidence doctrine without replacing it: `VERIFIED` says **who** measured, the three levels say **how far** the work has gone.

## 2. Refusal is the default position

Faced with an ambiguous situation, a control mechanism refuses. It does not let things through.

This holds for any automatic check: an unknown pattern, a missing dependency, an unreadable file lead to blocking, never to silently passing. A check that cannot verify does not conclude that all is well.

The same principle applies to roles: an agent that cannot decide does not decide — it measures, it reports, and it stops.

## 3. Evidence is shown

A claim about the state of a repository comes with the measurement it rests on. Declaring that a check has passed is not the same as showing its output.

Corollary: never reword a failure or a refusal in one's own favour. A check that blocks is information, not an obstacle to get around.

## 4. A role does not modify its own guardrail

An agent does not disable, bypass or modify a mechanism that constrains it, except with the Owner's explicit authorization stated in the current request.

This covers hooks, pattern files, the configuration that activates them, and any bypass option.

An authorization given in a past session does not hold for the current session.

## 5. What is not filed is lost

Knowledge produced in conversation and not written into a file before the close is deemed lost.

This holds for an opinion, an arbitration, a useful observation, a principle discovered along the way. A session's memory is not passed on; only a file is passed on.

## 6. A pending gate is flagged at every turn

A human gate not yet arbitrated is recalled at every turn, by every role, until the Owner decides.

The Executor places it at the top of the report, not in a list of residual anomalies. The Pilot recalls it at the opening of the session and at every Mission close.

A gate that sleeps in a list is not a gate, it is a note. Prolonged silence on a gate is itself an anomaly.

## 7. No secret in a versioned file

No key, no token, no password, no access identifier enters a file tracked by Git.

Sensitive values live in a local environment file, excluded from versioning, and a template without values documents the expected keys.

This rule is checked mechanically at commit. The mechanism does not exempt anyone from vigilance: it catches what it knows, not what it does not know.

## 8. Detection patterns are data

The patterns that define what a secret or a bypass is live in versioned data files, never hard-coded in a script.

They are read, reread and amended without touching the code that applies them. An added pattern requires no modification of the check.

## 9. Reach of the mechanisms

A Vault guardrail applies whatever the client used — one agent, another agent, a human, a script. No protection mechanism is wired to a particular vendor.

A check that activates only in a given tool is not a guardrail: it is a local convention, and it must be documented as such.

## 10. An untested guardrail is not one

A control mechanism that is active but faulty is more dangerous than its absence: it gives false assurance. Every guardrail is therefore tested by a trial that must fail, before being considered in service.

The trial is part of the installation, not of later verification. A check whose refusal has never been observed is not installed: it is merely present.

## Liens

- `see also` — [Verification and evidence](../knowledge/verification-and-evidence.md)
