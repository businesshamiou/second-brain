---
name: open
description: "sb open — Open a work session and get the READY / NOT-READY verdict"
disable-model-invocation: true
license: "MIT"
---

# /sb:open

The Second Brain command `sb open`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb open $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb open $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" open $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Apply the session-start skill (skills/session-start/SKILL.md) from its section 0, the entry-scenario matrix: the output of `sb open` is the measurement of your branch; the first line of your answer is the verdict, READY or NOT-READY (<reason>), with nothing before it. The Pilot opens through its Project instructions, not through this verb.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
