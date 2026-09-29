---
name: mission
description: "sb mission — Write a Mission (in the Pilot window)"
disable-model-invocation: true
license: "MIT"
---

# /sb:mission

The Second Brain command `sb mission`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb mission $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb mission $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" mission $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Pilot: apply the mission-writing skill (skills/mission-writing/SKILL.md) — the regime check first (a Note may be enough), then the DRAFT, the checklist, and the five-rubric mini-prompt as one snippet. Executor: a Mission is written by the Pilot; say so and name the Pilot window.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
