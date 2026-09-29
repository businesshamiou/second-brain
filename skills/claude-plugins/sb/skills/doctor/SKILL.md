---
name: doctor
description: "sb doctor — Check everything, and explain a refusal"
disable-model-invocation: true
license: "MIT"
---

# /sb:doctor

The Second Brain command `sb doctor`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb doctor $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb doctor $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" doctor $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Show the output as it is; for each FAIL or WARN, give the fix it names and nothing else. Under Windows, a WARN on bash means only that `bash` is not on the PATH of that terminal: give the form it names, never install anything. The `MCP · <host>` lines say, for each host present, whether the Vault's server is declared there; a missing one is `sb install --mcp`, on the Owner's word. Never repair on your own: a repair is a Mission or the Owner's gesture.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
