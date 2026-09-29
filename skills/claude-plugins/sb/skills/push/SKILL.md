---
name: push
description: "sb push — Push a range, verified"
argument-hint: "[<repository>] [<from>..<to>] [--dry-run]"
disable-model-invocation: true
license: "MIT"
---

# /sb:push

The Second Brain command `sb push`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb push $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb push $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" push $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: A push is the Owner's gesture. An Executor runs it only when the Owner delegated that push in this window by a clear expression naming the repository; otherwise it prints the command for the Owner. Never force.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
