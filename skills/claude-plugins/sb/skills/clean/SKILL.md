---
name: clean
description: "sb clean — What clutters the workspace, and where it should go"
disable-model-invocation: true
license: "MIT"
---

# /sb:clean

The Second Brain command `sb clean`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb clean $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb clean $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" clean $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Show the output as it is. It never touches _trash nor _archive. `--purge-temp` deletes the declared temporary folder's content for good: the Owner's gesture, run only on the Owner's word in this window, never on an agent's initiative.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
