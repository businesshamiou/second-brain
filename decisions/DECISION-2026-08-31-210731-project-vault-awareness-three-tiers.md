---
type: decision
title: "Awareness of the Vault by a project — three tiers (machine, workspace, project), stop on a non-adopted folder, adopt mode of the bootstrap, hook and pin included"
description: "Engraves the Owner's arbitration of 2026-08-31 after a brainstorm on a real case (folder moved into the workspace, Codex opened in it, session started knowing nothing of the Vault): a project becomes aware of the Vault through files that agents read natively, on three tiers — machine (global files per tool, placed by first-install), workspace (VAULT-ROOT.md marker), project (pointer files, startup hook, guardians pin, registry line, placed by project-bootstrap). An agent that finds itself in a non-adopted folder stops and asks; the adopt mode of the bootstrap adds what is missing without touching the content; hook and pin are part of the bootstrap. Amends 232341 §5.1 for first-install and project-bootstrap."
created_at: "2026-08-31T21:07:31-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md"
---

# DECISION — AWARENESS OF THE VAULT BY A PROJECT, IN THREE TIERS

## Date

2026-08-31

## Status

`ARBITRATED`

## Measured problem

A folder moved into the workspace, opened with Codex, started with no knowledge of the Vault, of its rules or of its role. Cause measured on 2026-08-31:

- Agents (Codex, Claude Code) natively read, before any work, a global instruction file in their personal folder, then the project's instruction files from the Git root down to the current folder (Codex doc: `AGENTS.md`; Claude Code: `CLAUDE.md`). A folder without these files is a blind folder. [MESURÉ: official Codex doc; listing of (workshop history, not distributed), which carries `AGENTS.md` and `CLAUDE.md`]
- `tools/project-bootstrap.sh` creates a new project only (refusal if the target exists), requires the `VAULT-ROOT.md` marker upstream, and lays down skeleton, README, journal, v2 sheet, registry line and index. It has no mode for an existing folder. [MESURÉ: head and tail of the script read]
- The `SessionStart` hook that injects the Executor role exists only in the Vault's `.claude/` folder; (workshop history, not distributed) does not have one. Sessions opening in a project never trigger it. [MESURÉ: listing of (workshop history, not distributed), no `.claude/`]

## Decision

**1. Three tiers, from the widest to the most precise.** A project becomes aware of the Vault through files that agents read without a prompt:

- **Machine tier** — one global file per tool, outside the repositories (`~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`), with minimal content: « il existe un Vault sur cette machine ; si un marqueur `VAULT-ROOT.md` se trouve en remontant depuis le dossier courant, lire la charte à son emplacement, déterminer le rôle selon ses trois barreaux, ne rien faire avant » ["there is a Vault on this machine; if a `VAULT-ROOT.md` marker is found going up from the current folder, read the charter at its location, determine the role according to its three rungs, do nothing before"]. Placed by the `first-install` skill. This gesture is not distributed by the Vault alone: each recipient performs it on their own machine, `first-install` accompanies it.
- **Workspace tier** — the `VAULT-ROOT.md` marker, existing, which bounds the Vault's territory.
- **Project tier** — at the root of the folder: pointer files (`AGENTS.md`, `CLAUDE.md`) to the charter, startup hook, pin of the Vault's guardians (`.pre-commit-config.yaml`), line in the project registry. Placed by the `project-bootstrap` skill.

**2. An agent that finds itself in a non-adopted folder stops and asks.** The machine tier prescribes this to it. It does not launch the adoption on its own initiative: adopting writes into the Vault's registry, it is a gesture on a Mission's prescription or an Owner arbitration.

**3. The bootstrap has two modes.** *Be born*: the current behaviour of the script. *Adopt*: on an existing folder, add what is missing at the project tier — pointer files, hook, pin, registry line, v2 sheet — **without touching the existing content**. The reorganization into seven functions is never automatic, but it is **always proposed** on adoption, because it serves the workflow: the bootstrap in adopt mode presents the reorganization plan (what would move, where) and applies it only on a **categorical yes from the Owner**; without that yes, the folder stays as it is, adopted but not reorganized, and the v2 sheet says so.

**4. Hook and pin are part of the bootstrap**, in both modes. A project adopted without hook or pin is non-conforming; `check-project-conformity.sh` must say so (extension to be prescribed in the Mission that applies the present Decision).

**5. Rule in one sentence.** *The Vault adopts projects; the machine catches those not yet adopted; nobody works in a folder that is neither one nor the other.* The opening position stays free (DECISION-213150): it is the folder that speaks, not the order of the windows.

**6. Effect on 232341 §5.1.** `first-install` now carries the machine tier (point 1); `project-bootstrap` carries the two modes and points 3 and 4. The four other skills are unchanged. This Decision builds nothing: it sets what the two skills will have to do.

## Reason

Owner–Pilot brainstorm of 2026-08-31 on the real case, in four points submitted each with a single recommendation; the Owner took the four recommendations in one word. The choice "files, neither a prompt nor a skill alone" rests on a fact: a skill cannot be invoked from a session that does not know it exists, and a prompt serves only a chat window with no folder. Instruction files are the only thing an agent reads without being told to.

## Impact

- 232341 receives `amended by` (reciprocal link to be placed by the Executor at the next tidying, same commit as the present Decision).
- `project-bootstrap.sh`: adopt mode, writing of the pointer files, the hook, the pin — Mission to come, with `check-project-conformity.sh` extended.
- (workshop history, not distributed) itself is today non-conforming to point 4 (no hook): first candidate for the adopt mode.
- The Owner's Codex folder: second candidate, once named.
- `first-install`: specification to be written before building (rule "one skill at a time, fully fleshed out").

## Important alternatives

- "Always open the Vault first": set aside, already revoked on 2026-08-25; the order of the windows does not replace a folder that speaks.
- An opening prompt per tool: set aside, one has to remember to paste it; forgetting is exactly the measured case.
- The agent adopts the non-adopted folder by itself: set aside, write to the registry without the Owner.
- Automatic reorganization into seven functions on adoption: set aside, write on the content without the Owner. Reorganization never proposed: also set aside (Owner, 2026-08-31) — it helps the workflow, so it is always suggested, applied only on a categorical yes.

## Human gate

- Validation: granted
- Reference: « Je prends ta recommandation ou bien tes recommandations » ["I take your recommendation, or rather your recommendations"], Owner, 2026-08-31, on the four points submitted.

## Liens

- `amends` — [Decision — Evening consolidation, project standard and plan](./DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md)
- `see also` — [Role charter and session determination](../../../vault/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md) (hors Vault)
- `see also` — [Decision — Opening directory of a session, position freed](./DECISION-2026-08-25-213150-session-opening-directory-freed.md)
- `amended by` — [Decision — Project initiation and adoption, birth certificate](./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md) (point 2: stop only without an initiation order)
