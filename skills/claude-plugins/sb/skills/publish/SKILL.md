---
name: publish
description: "sb publish — Publish a version (the maintainer, from the laboratory)"
argument-hint: "[--version vX.Y.Z] [--dry-run]"
disable-model-invocation: true
license: "MIT"
---

# /sb:publish

The Second Brain command `sb publish`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb publish $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb publish $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" publish $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Owner only. An agent runs it with --dry-run under a Mission; the real publication, the tag and its push are the Owner's gestures.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
