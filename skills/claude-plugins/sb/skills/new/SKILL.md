---
name: new
description: "sb new — Create a project from nothing"
argument-hint: "<folder> \"<Display Name>\" [--group <group>] [--lang FR|EN|ES] [--vcs none|git] [--ask]"
disable-model-invocation: true
license: "MIT"
---

# /sb:new

The Second Brain command `sb new`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb new $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb new $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" new $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Run it only on a Mission, an initiation order or the Owner's word, since it writes into the Vault's registry. With --ask it asks, in the terminal, the name, the location, Git, then the three questions of the project interview (expected result, current blocker, review rhythm; Enter leaves one empty). Relay the whole output, including the block to paste as the Pilot Project's instructions and the Project name `SB - <Display Name>`.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
