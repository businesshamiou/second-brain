---
name: add-skill
description: "sb add-skill — Check a new skill before adding it"
argument-hint: "<skill folder>"
disable-model-invocation: true
license: "MIT"
---

# /sb:add-skill

The Second Brain command `sb add-skill`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb add-skill $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb add-skill $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" add-skill $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Show the output as it is; then follow docs/how-to/add-a-skill.md for the index, the manifest lines, the provenance and the licence, under a Mission.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
