---
name: close
description: "sb close — Close the session: starts in the Pilot, ends in the Executor"
disable-model-invocation: true
license: "MIT"
---

# /sb:close

The Second Brain command `sb close`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb close $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb close $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" close $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Apply the session-close skill (skills/session-close/SKILL.md); the close starts in the Pilot. Pilot: run closing-checklist.md; a session with no Mission opened or closed, no RELAY and no Pilot artefact filed is a light close: say « rien à consigner », write no handoff, hand the light closing block for the Executor, complete with its order sentence in the Owner's language: « You are the Executor. In <project folder>, run: sb close --light. Show the output as it is. » (never the command alone, never a plugin or Codex shortcut); otherwise the holes, then the handoff and the capture and the Executor closing command; after a welcome session, list _orders/ and today's _archive/orders/ and offer to write a spoken idea as an initiation order. Executor: show the situation `sb close` measured; light: run `sb close --light`; full: apply the handoff's closing command, or, without a handoff, say in plain words that the Owner writes `sb close` in the project's Pilot. A distribution remote is never a push target. Never push unless the Owner delegated it in this window.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
