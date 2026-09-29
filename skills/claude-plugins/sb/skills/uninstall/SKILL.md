---
name: uninstall
description: "sb uninstall — What to remove, and how"
disable-model-invocation: true
license: "MIT"
---

# /sb:uninstall

The Second Brain command `sb uninstall`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb uninstall $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb uninstall $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" uninstall $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Show the steps as they are. Deleting the workspace is the Owner's gesture; never delete anything yourself.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
