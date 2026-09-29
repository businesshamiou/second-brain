---
name: close
description: "sb close — Close the session: journal, state sheet, closing commit"
disable-model-invocation: true
license: "MIT"
---

# /sb:close

The Second Brain command `sb close`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb close $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb close $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" close $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Apply the session-close skill (skills/session-close/SKILL.md): inventory the holes, refuse to close while any remain, then the closing gestures of your role — the Pilot prepares the pieces and never declares the close done; the Executor writes the journal lines, regenerates STATE.md and DIGEST.md, and makes the closing commit. Never push unless the Owner delegated it in this window.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
