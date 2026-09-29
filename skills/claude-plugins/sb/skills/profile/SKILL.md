---
name: profile
description: "sb profile — Show or apply your starting profile"
disable-model-invocation: true
license: "MIT"
---

# /sb:profile

The Second Brain command `sb profile`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb profile $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb profile $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" profile $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Without --order: show the output, then apply the starting-interview skill (skills/starting-interview/SKILL.md) — a profile present is shown and only what changed is asked; absent, or with missing fields, the interview asks one question at a time, at least three, only the missing ones. With --order: an Executor gesture, run only on a profile order the Owner dated; relay the section written, inspect the diff of USER.md and commit it on its own. Pilot, without a shell: read the `## Profil de départ` section of the Vault's USER.md, run the interview, show the full profile, and with the Owner's agreement write only the order <workspace>/_orders/PROFILE-<YYYY-MM-DD-HHMMSS>.md (templates/profile-order-template.md), announcing the path first; never USER.md itself.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
