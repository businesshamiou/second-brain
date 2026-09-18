---
type: knowledge
title: "Verification and evidence — STATE → CHANGE → VALIDATION → SNAPSHOT → EXTERNAL BOUNDARY"
created_at: 2026-08-17T11:10:18-04:00
timezone: America/Montreal
status: active
---

# VERIFICATION AND EVIDENCE — STATE → CHANGE → VALIDATION → SNAPSHOT → EXTERNAL BOUNDARY

Verification turns a claim about the work into a reproducible observation. It follows the [information architecture decision V1](../decisions/DECISION-2026-08-17-111018-vault-v1-information-architecture.md) and complements the [rules of conduct](../rules/RULES-2026-08-17-005717-vault-operating-rules.md).

## Two principles

### Measure, don't copy

A technical state that can be recomputed must be measured at the moment it is used. Durably copying a hash, a counter or an old `git status` creates a perishable value that may diverge from reality.

A dated report may record a measurement as evidence of its execution. It must not present that historical measurement as the permanent current state.

### A check exists ≠ the check works

The presence of a test, a rule, a hook or a configuration proves only that the check exists. To know whether it works, it must be executed under the relevant conditions, its result observed and, when the risk justifies it, verified that it does detect an invalid case.

## Evidence model V1

```text
STATE → CHANGE → VALIDATION → SNAPSHOT → EXTERNAL BOUNDARY
```

These levels answer different questions and complement one another. No counter or isolated success message replaces the whole of the relevant evidence.

## `git status` — STATE

- **Role**: show the real state of the working tree and of the index relative to Git.
- **Problem detected**: files modified, added, deleted, untracked or already staged; unexpected branch.
- **Benefit**: quickly establishes the local perimeter before and after an intervention.
- **Limits**: does not show the content of the changes, does not validate their behaviour and does not prove the absence of earlier external effects.
- **When to use it**: at the start, before staging, before commit and at the end of a mission.

The short form `git status --short --branch` makes for compact evidence; the full form provides more explanations.

## `git diff` and staged diff — CHANGE

- **Role**: show the exact content of the local change.
- **Problem detected**: accidental modification, content outside the perimeter, unintended deletion, visible secret, incorrect link or text.
- **Benefit**: allows a line-by-line review before recording a snapshot.
- **Limits**: `git diff` shows by default only the unstaged changes; `git diff --staged` shows only the index. Untracked files must also be spotted through `git status` and inspected directly before staging.
- **When to use it**: after modification, before staging for each file, then after staging on the whole of the future commit.

For a safe mission, consult both views: `git diff -- <fichier>` for the working tree and `git diff --staged` for the content that will really be committed.

## Tests and checks — VALIDATION

- **Role**: confront the result with the expected behaviours, constraints or formats.
- **Problem detected**: functional regression, invalid syntax, broken link, incorrect structure or unmet requirement, depending on the check chosen.
- **Benefit**: provides behavioural or structural evidence that the diff alone does not provide.
- **Limits**: a check covers only what it tests. A success does not demonstrate the absence of all defects; a check not executed provides no validation.
- **When to use it**: after the changes and again on the staged content when staging or generation may modify the result.

Checks must be proportionate to the risk and explicitly reported with their command, their scope and their result.

## Commit and hash — SNAPSHOT

- **Role**: freeze a coherent set of changes in the local history and give it a measurable identifier.
- **Problem detected**: the hash, combined with the commit's diff, makes it possible to establish that a content or a history is no longer the one that had been validated.
- **Benefit**: provides a resume point and an exact reference for review.
- **Limits**: a commit proves neither the quality of the change, nor the success of the tests, nor a push. The hash depends on the complete Git object and changes if the commit is rewritten.
- **When to use it**: after inspection of the staged diff and success of the relevant checks.

Measure the current snapshot with `git rev-parse HEAD` and inspect its content with `git show --stat --oneline HEAD` or `git show HEAD` depending on the level of detail required.

## Counters — sanity checks

- **Role**: provide a quick plausibility check, for example the number of files, links or results.
- **Problem detected**: gross discrepancy, missing element, duplicate or unexpected order of magnitude.
- **Benefit**: quickly signals that a more precise inspection is necessary.
- **Limits**: a correct total may hide wrong content, and a different total may be legitimate. A counter is never sufficient evidence of compliance.
- **When to use it**: as a complement to a content inspection, never as a substitute for the diff, the tests or the review.

## `git remote -v` — EXTERNAL BOUNDARY

- **Role**: reveal the configured Git remotes and their fetch/push URLs.
- **Problem detected**: unexpected external boundary, wrong push destination or remote added outside the perimeter.
- **Benefit**: makes visible part of the boundary between local work and external systems.
- **Limits**: an empty output proves only that no remote is configured at that instant. The command does not prove on its own that no publication or other network operation took place.
- **When to use it**: during the initial verification, before any remote action considered, and in the final evidence of a bounded local mission.

A remote, a push or a publication constitutes a distinct external effect. Its presence in the plan requires the human gate provided for by the applicable rules.

## Checksums and fingerprints — read-only boundary

- **Role**: compare at a given point the bytes of a source read with those observed before or after an operation.
- **Problem detected**: unintended modification of a file or difference between two copies assumed identical.
- **Benefit**: provides a precise integrity verification at a read-only boundary.
- **Limits**: an identical fingerprint proves neither the quality nor the authenticity of the source; a fingerprint copied without a chain of trust may itself be false. It becomes perishable if the file is allowed to evolve.
- **When to use it**: when a mission requires demonstrating that a read-only source has not changed, or comparing two exact objects.

Use a suitable hash algorithm and measure both sides of the comparison. Keep the fingerprint only in the one-off evidence that explains what it verifies.

## Proportionate verification sequence

For a bounded local modification:

1. measure the root, the branch, the HEAD, the status and the remotes;
2. inspect the sources and the targeted files;
3. examine the status and each change;
4. execute the relevant tests and checks;
5. stage file by file;
6. inspect `git diff --staged` and verify the absence of secrets;
7. create the authorized local commit;
8. measure again the HEAD, the status and the external boundary.

This sequence produces complementary evidence: it does not turn an isolated measurement into a general guarantee.

## Liens

- `see also` — [Guardrails and evidence levels](../rules/RULES-2026-08-19-210803-guardrails-and-evidence-levels.md)
