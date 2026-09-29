---
name: run
description: "sb run — Carry out a Mission (in the Executor window)"
argument-hint: "<mission number or file>"
disable-model-invocation: true
license: "MIT"
---

# /sb:run

The Second Brain command `sb run`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb run $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb run $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" run $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Executor only: open (the Executor section of skills/session-start/reading-list.md), read the Mission in full, check its preconditions, carry it out within its scope, file the report and end with the RELAY block. Pilot: this verb needs a shell; hand the Owner the mini-prompt `sb run` prints, for an Executor window.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
