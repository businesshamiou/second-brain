---
title: "Installation checklist, one measurement per item"
description: "Single source of the inventory run by the first-install skill: each item of the Vault's installation on a machine, with the measurement that says installed or missing and the gesture that installs it without overwriting. This is the file that is amended when a new item appears — the body of the skill does not move. amended by chain followed by the skill."
created_at: "2026-09-01T21:05:00-04:00"
timezone: America/Montreal
status: active
---

# INSTALLATION CHECKLIST

Run by the `first-install` skill (§2 inventory, §3 installation). One line = one item, its measurement, the gesture if it is missing. An installed item is never touched again.

| # | Item | Measurement (installed if…) | Gesture if missing | Answer |
|---|---|---|---|---|
| 1 | Work root marked | `VAULT-ROOT.md` found by walking up from the Vault, line « Chemin relatif du Vault » ["Relative path of the Vault"] readable | the Vault's `tools/write-marker.sh` (Executor gesture on prescription) | machine |
| 2 | Vault cloned | `.git` present at the root of the Vault (found through the marker), `git -C <racine du Vault> status -sb` answers | clone by the human (URL and location = answers of the questioning) | human (path) |
| 3 | The Vault's `core.hooksPath` | `git -C <racine du Vault> config core.hooksPath` = `.githooks` | `git -C <racine du Vault> config core.hooksPath .githooks` | machine |
| 4 | Guardians' tools | `command -v bash git sha256sum` all present | installation by the human (Git for Windows provides all three) | machine → human |
| 5 | `pre-commit` | `command -v pre-commit` present | installation by the human (`pipx`/`uv tool install pre-commit`); without it, the projects keep the native hook only | machine → human |
| 6 | Junction support | Windows: `fsutil` present and a test junction readable; others: `ln -s` | none (capability of the machine, flagged) | machine |
| 7 | Personal skills folder | `%USERPROFILE%\.claude\skills\` exists | `mkdir` | machine |
| 8 | Junctions of the Vault's skills | for each `skills/<nom>/SKILL.md` of the Vault (outside `external/`): junction of the same name, `test -ef` IDENTICAL — **third state (Mission 125)**: junction of the same name **present but `test -ef` FALSE** (it targets another Vault installed on this machine) = neither installed nor missing, **STOP and ask the Owner**; never rewrite an existing junction, whatever its state | `mklink /J` (or `ln -s`) towards the Vault's `skills/<nom>`, never over an existing junction | machine |
| 9 | Junctions of the external library | for each `skills/external/<nom>/SKILL.md` of the Vault: junction of the same name, `test -ef` IDENTICAL — same third state as at item 8 (existing junction, different target): **STOP and ask the Owner**, never a rewrite | same, towards the Vault's `skills/external/<nom>` | machine |
| 10 | Foreign junctions | junction of the personal folder without a target in the Vault | no gesture: flagged, left (it does not belong to the Vault) | machine |
| 11 | Machine tier — Claude Code | `~/.claude/CLAUDE.md` exists and mentions `VAULT-ROOT` | create the minimal file (DECISION-210731 point 1); if it exists without the mention: flagged, not modified | machine |
| 12 | Machine tier — Codex | `~/.codex/AGENTS.md` exists (size > 0) and mentions `VAULT-ROOT` | absent, or present at 0 bytes: create the minimal file (DECISION-210731 point 1); present with non-empty content without the mention: flagged, not modified | machine |
| 13 | MCP filesystem root (Pilot surface) | configuration of the chat client readable and pointing to the work root | human gesture (client settings), path proposed | machine → human |
| 14 | Registered projects: `pre-commit install` | for each `relative_path` of the registry: `.git/hooks/pre-commit` laid down by pre-commit, or native `core.hooksPath` present — **clarification (Mission 125)**: `projects/PROJECT-REGISTRY.md` is `INTERNE` in the manifest (content specific to this machine, never distributed); **absent on a fresh clone, this is not a lack** — 0 registered projects, nothing to do here; the registry is created from `templates/project-registry-template.md` (`DISTRIBUABLE`) by `project-bootstrap.sh` at the first project, not by `first-install` | `pre-commit install` in the project, if item 5 is installed and the registry present | machine |
| 15 | Chat skills (claude.ai) | never measurable from the machine | list of the zips with measured path, `laissé (geste humain)` [left (human gesture)] | human |
| 16 | Installation report | file filed at the path named by the Owner | `install-report-template.md` filled in | human (path) |

## Liens

- `see also` — [first-install skill](./SKILL.md)
- `see also` — [Installation report template](./install-report-template.md)
- `applies` — Decision — Awareness of the Vault by a project, three tiers (workshop history, not distributed) (hors Vault)
