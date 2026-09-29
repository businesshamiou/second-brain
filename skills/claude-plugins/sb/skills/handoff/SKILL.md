---
name: handoff
description: "sb handoff — Write a handoff for the next session, without closing"
argument-hint: "[<slug>]"
disable-model-invocation: true
license: "MIT"
---

# /sb:handoff

The Second Brain command `sb handoff`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb handoff $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb handoff $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" handoff $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Write only the handoff: copy templates/handoff-template.md to the path `sb handoff` printed, fill its resume queue from what was measured in this session, and stop — no inventory of holes, no journal line, no state sheet, no commit. Say that committing a handoff requires its close (tools/check-session-close.sh refuses it otherwise): the close is `sb close`.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
