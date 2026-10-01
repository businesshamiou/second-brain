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
3. Then apply the card: Run it only on a Mission, an initiation order or the Owner's word, since it writes into the Vault's registry. With --ask it asks, in the terminal, the name, the location, Git, then the three questions of the project interview (expected result, current blocker, review rhythm; Enter leaves one empty). Relay the whole output: the tool commits the new project and the Vault's registry itself, each through its guardians (a refusal is relayed as it is, never worked around). Then tell the Owner, by its place: « Dans l'application Claude : crée le Project SB - <Display Name>, colle (Ctrl+V) dans ses instructions » -- in this order: the Project created first; then, just before the paste, `sb pilot-prompt <folder> --copy` in a terminal (anything copied in between, the Project's name included, replaces the block); then the paste. Never say the block is already on the clipboard without that command next to it.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
