---
name: help
description: "sb help — This screen; sb help <verb> for one command"
disable-model-invocation: true
license: "MIT"
---

# /sb:help

The Second Brain command `sb help`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb help $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb help $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" help $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Show the output as it is. Pilot, without a shell: answer from docs/reference/commands.md (this page) in the Owner's language — the verbs by group with one line each, or the section of the verb asked; verbs stay in English.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
