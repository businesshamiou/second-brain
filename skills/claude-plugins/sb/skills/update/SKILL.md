---
name: update
description: "sb update — Bring the Vault to a published version"
argument-hint: "<version> [--lang FR|EN|ES]"
disable-model-invocation: true
license: "MIT"
---

# /sb:update

The Second Brain command `sb update`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb update $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb update $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" update $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Apply the update skill (skills/update/SKILL.md): run it only on the Owner's word, relay the verdict and, on a refusal, the file it names; never resolve a conflict behind the Owner's back.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
