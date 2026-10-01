---
name: install
description: "sb install — Install, repair, put sb on the PATH"
disable-model-invocation: true
license: "MIT"
---

# /sb:install

The Second Brain command `sb install`, relayed ([rule](../../../../../rules/RULES-2026-09-26-200933-sb-command-surface.md)).

1. Run in the shell: `sb install $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb install $ARGUMENTS` (in PowerShell: `& "<Vault>\tools\sb\bin\sb.cmd" install $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.
3. Then apply the card: Show the output as it is. `sb install` writes one entry into the user's PATH, Claude Code's plugin settings (marketplace second-brain, plugin sb) and the Vault's MCP server into every host present (Claude desktop app, Claude Code, Codex, Gemini CLI, Cursor, Windsurf, Cline, LM Studio): run it only on the Owner's word. A name too long for the hosts is refused with a shorter label proposed: `sb install --mcp --label <label>`, on the Owner's choice. The Claude app's Code tab is an Executor host: without the `claude` command, the plugin step uses the app's own Claude Code, or says in one line that the Code tab needs no plugin (the Executor blocks give the plain `sb <verb>`). For a first installation or a repair driven from the chat, apply the first-install skill (skills/first-install/SKILL.md).

## Liens

- `see also` — [Commands](../../../../../docs/reference/commands.md)
