---
name: pilot-prompt
description: "sb pilot-prompt — The block to paste into a project's Pilot Project, or into the welcome one"
argument-hint: "[<folder>] [--regen] [--host <host>]"
disable-model-invocation: true
license: "MIT"
---

# /sb:pilot-prompt

The Second Brain command `sb pilot-prompt`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb pilot-prompt $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb pilot-prompt $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" pilot-prompt $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Show the output as it is: the Pilot's name, the block between two lines (the same bytes for every host), then, for each Pilot host present on this machine or the one --host names, where to paste the block, how to open without a shell, the first message and what the first answer shows. With --accueil (or `accueil`), anywhere in the workspace: the same pieces for the welcome Pilot `SB - Accueil`, whose block tools/project-bootstrap.sh accueil-prompt prints; its first exchange is the starting interview. A host the rule marks declared is said so; ChatGPT and Gemini web are refused with the reason (docs/how-to/pilot-hosts-and-role-mixing.md). Pilot, without a shell: read the project's state/PILOT-PROMPT.md and the Vault's templates/session-opening-prompt-template.md, and give the same pieces for the host the Owner names; `--regen` and `--accueil` need a shell.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
