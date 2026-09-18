---
type: context
title: "Second Brain — glossary"
description: "Glossary of the product's terms, validated in T18, in the CONTEXT.md format of the domain-modeling skill."
status: active
---

# Second Brain — glossary

The product's terms, as a user or an agent meets them in this repository. Validated by the Owner (DECISION, T18 of Mission 168), delivered here as is.

## Language

**Second Brain**:
The installed system — rules, methods, templates, skills, guardians — versioned in the `second-brain` repository.
_Avoid_: OS, framework.

**Vault**:
Internal name of Second Brain in the rules and the tools; the same thing.

**Workspace**:
The folder that contains `second-brain` and your projects, marked by `VAULT-ROOT.md`.
_Avoid_: root folder.

**Project**:
A work folder next to `second-brain`, entered in the registry, which inherits the method.

**Built skill**:
A skill written for Second Brain, in `skills/`.

**Adopted skill**:
A verified third-party skill, brought in through ingestion.
_Avoid_: plugin, extension.

**Warehouse**:
The library of adopted skills, `skills-warehouse/`.

**Assistant**:
Second Brain's agent, named by the user at installation; default proposed name: Brian. It guides the installation, then answers read-only.
_Avoid_: bot.

**Owner**:
You, who decide and who push.
_Avoid_: admin.

**Pilot**:
The session role that thinks, arbitrates and drafts, without executing.

**Executor**:
The session role that executes, measures and commits, within a Mission's scope.

**Mission**:
The file that prescribes a piece of work to the Executor, frozen when issued.
_Avoid_: task, prompt.

**Decision**:
A recorded and dated choice that is authoritative.
_Avoid_: ADR.

**Guardian**:
An automatic check at commit, which refuses what violates a rule.
_Avoid_: hook, linter.

**Installation logbook**:
The trace that makes it possible to resume an interrupted installation.

## Note

« Atelier » ["workshop"] is absent from this glossary: this term does not exist for the user of Second Brain — see the [boundary rule between a project and Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md).

## Liens

- `see also` — [README](./README.md)
- `see also` — [Boundary rule between a project and Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
