---
name: adopt
description: "sb adopt — Adopt a folder you already have"
argument-hint: "[<folder>] [\"<Display Name>\"] [--git] [--lang FR|EN|ES] [--ask]"
disable-model-invocation: true
license: "MIT"
---

# /sb:adopt

The Second Brain command `sb adopt`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb adopt $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb adopt $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" adopt $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Run it only on a Mission, an initiation order or the Owner's word. On an adopted project it only completes what is missing, including the skill links of renamed skills. With --ask it also asks the three questions of the project interview (Enter leaves one empty) and writes them under `## Profil du projet` of README.md; an existing profile is kept. Relay the plan it proposes: it applies no reorganisation. It commits only the files it added (the project) and the registry (the Vault), each through its guardians.

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
