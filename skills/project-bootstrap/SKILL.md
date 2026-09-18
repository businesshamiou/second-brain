---
name: project-bootstrap
description: "Make a project aware of the Vault at one of its three tiers: register it, pin the Vault guardians, install the pre-tool preflight hook, and propose (never impose) the seven-function layout. Use when adopting an existing project or starting a new one under the Vault. Triggers on: « adopte ce projet », « nouveau projet », \"adopt this project\", \"new project\"."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), (historique de l'atelier, non distribué), (historique de l'atelier, non distribué)"
  vault-validated: "2026-09-01T21:02:20-04:00"
---

Makes a project aware of the Vault at one of its three tiers (DECISION-210731): registers it, pins the guardians, lays down the `executor-preflight` hook, and **proposes** the seven-function layout without ever imposing it. **Executor surface only** (files, local Git, hook). This skill is launched only on the prescription of a Mission, an initiation order dated by the Owner or an Owner arbitration: adopting writes into the Vault's registry (DECISION-210731 point 2, amended by Decision 000545 A3). The source of behaviour is Decision 210731, **to be read in full before the first gesture**; this body does not paraphrase it.

## 1. Measure the current tier and say it

From the root of the project: **machine** — a global file per tool exists (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`) and names the marker; **workspace** — `VAULT-ROOT.md` found by walking up, its line « Chemin relatif du Vault » ["Relative path of the Vault"] read; **project** — presence of `AGENTS.md`/`CLAUDE.md` pointing to the charter, of a pinned `.pre-commit-config.yaml` (`repo: local`, on the neighbouring Vault — T01), of `.claude/settings.json` with the `PreToolUse` hook, of a line in the Vault's `projects/PROJECT-REGISTRY.md` registry, of a Vault sheet `projects/PROJECT-<id>.md`. Return the measured tier. **Never degrade a tier**: nothing is removed, nothing is rewritten.

## 2. Adopt mode — existing project

`bash <Vault>/tools/project-bootstrap.sh adopt <projet> [nom] --vcs none|git [--lang FR|EN|ES]` (or `--order <fichier>` for an initiation order). The script writes only what is missing, **without touching any existing file of the project** (a file present, even incomplete, is left as it is and flagged):
1. **Birth certificate and pin** `.pre-commit-config.yaml`: comment block at the head (`vault_id`, `vault_origin`, `vault_ref`, `vcs`, `baseline`), then `repo: local` on this Vault by measured relative path, four hooks (`vault-check-secrets`, `vault-check-indexes-fresh`, `vault-check-index-weight`, `vault-check-links`). A pin already present without a certificate is not modified: the block to add is returned.
2. **Dated baseline** (`.vault-baseline-<date>.tsv`, named by the certificate): the existing files and their fingerprint. The guardians judge only what is new and what is touched; an engraved file that is then touched must become compliant (ratchet). Broken links from before: `tools/propose-link-repairs.sh <projet>` returns a plan; `--apply` exists only under a Mission.
3. **Pointer files** `AGENTS.md` and `CLAUDE.md`, Pilot prompt `<projet>/state/PILOT-PROMPT.md` (canary), `.gitignore` of the links, absent indexes: only if absent.
4. **Line in the registry** (`vcs` column) and the Vault's **v2 sheet**; `conformity` measured by `tools/check-project-conformity.sh <projet>` (seven functions, registry, certificate, pin, Git hook if `vcs: git`, consistency of the pointer files with the certificate).
5. **Git**: `vcs: git` → repository created if missing, `pre-commit install`; `vcs: none` → no hook, checks by command (`tools/check-links.sh <projet>`, `check-secrets.sh`, `check-indexes-fresh.sh`, `check-index-weight.sh`, `check-project-conformity.sh`). `adopt --git` later moves the project to `vcs: git`.

The `executor-preflight` hook (companion `preflight-hook.sh`, fragment `settings-hook.json`) remains a gesture of this skill: copy the hook into `.claude/hooks/` if it is missing; an existing `.claude/settings.json` is never modified, the fragment is returned.

## 3. New mode — project to be born

`bash <Vault>/tools/project-bootstrap.sh create <chemin-cible> <display_name> --vcs none|git` (or the historical call without a subcommand): skeleton of the seven functions, README, journal, index, birth certificate and pin, Pilot prompt, v2 sheet, registry line, repository and hook if `vcs: git`. `--ask` first asks for name, location and Git. The script ends with the **block to consume** (Project to create, common prompt to paste, first message = path of the project, canary).

## 4. Propose the reorganization, never apply it alone

At the end of the run, on an adopted project: present the **reorganization plan** into seven functions (`README.md`, `rules/`, `state/`, `missions/`, `decisions/`, `proposals/`, `knowledge/`, `handoffs/` — RULES-142800 §2): the list of moves, what would move and where, **none executed**. It is applied only on a categorical "yes" from the Owner **written in the Mission** that launches this skill — never on a conversational yes. Without that yes: the project stays as it is, adopted but not reorganized, and the v2 sheet says so.

## 5. Verdict

Tier before → tier after; list of the files added; **nothing modified** — proof: the project's `git status --porcelain` shows only `??` (or `A`), no ` M`; output of `check-project-conformity.sh` pasted; the proposed reorganization plan; the remaining human gestures.

## What this skill does not do

Open or close a session (`session-start`, `session-close`) · push · modify or move an existing file of the project · apply the seven functions without the yes written in the Mission · adopt (workshop history, not distributed), the Vault or a warehouse without a dedicated Mission · install the machine (`first-install`) · degrade a tier.

## Liens

- `see also` — [executor-preflight hook, to be copied into the project](./preflight-hook.sh)
- `see also` — [PreToolUse fragment to merge into .claude/settings.json](./settings-hook.json)
- `applies` — Decision — Awareness of the Vault by a project, three tiers (workshop history, not distributed) (hors Vault)
- `applies` — Decision — End of the skills V1 pass (workshop history, not distributed) (hors Vault)
- `applies` — Decision — Evening consolidation, project standard and plan (workshop history, not distributed) (hors Vault)
- `see also` — [Project structure standard, seven functions](../../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- `see also` — [Project registry template](../../templates/project-registry-template.md)
- `see also` — [Project registry](../../projects/PROJECT-REGISTRY.md)
- `applies` — [Decision — Project initiation and adoption, birth certificate](../../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
