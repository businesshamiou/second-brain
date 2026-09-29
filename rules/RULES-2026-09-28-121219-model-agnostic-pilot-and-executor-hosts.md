---
type: rules
title: "Model-agnostic Pilot and Executor hosts"
description: "The Pilot and the Executor are roles, not products: what Second Brain creates is created outside any provider and is read by any agent. One disk channel (the Vault's local MCP server) declared in every host present, one block identical for every host, a canary described by its tool, and a host matrix where a host is promised only when measured (proven, declared, not supported today)."
created_at: "2026-09-28T12:12:19-04:00"
timezone: America/Montreal
status: active
scope: hosts, pilot, executor, mcp, model-agnostic
amends:
  - "../templates/session-opening-prompt-template.md"
  - "../templates/accueil-pilot-prompt-template.md"
  - "../skills/session-start/SKILL.md"
---

# MODEL-AGNOSTIC PILOT AND EXECUTOR HOSTS

The Owner, 2026-09-28: every gesture of Second Brain is model-agnostic; what it creates is created outside any provider and must be recognised by any agent; any agent may play the Pilot or the Executor, and the roles mix — a Pilot in the Claude application with an Executor in Codex, a Pilot in another tool with an Executor in Claude Code, any combination. Mission 242 turns that into this rule, from the research the Owner commissioned and from what was measured on the laboratory machine.

## 1. Definitions

- **Role.** Pilot or Executor, as the [role charter](./RULES-2026-08-23-224706-role-charter-and-session-determination.md) defines them. A role is determined by a capability (a shell or not), never by a product.
- **Host.** The software an agent runs in: the Claude desktop application, Claude Code, Codex, Gemini CLI, Cursor… A host is not a role.
- **Pilot host.** A host with the disk channel and no shell (or a shell it can be denied).
- **Executor host.** A host with a shell.
- **Disk channel.** The Vault's MCP server, `tools/vault-mcp.py`, a local process spoken to over stdio, bounded to the workspace (`--allow`). The only way a Pilot reads or writes.
- **Instructions space.** Where a host keeps the text an agent reads before every conversation: a Project (Claude desktop application), `AGENTS.md` (Codex), GEMINI.md (Gemini CLI), rules (Cursor, Windsurf, Cline), a preset (LM Studio). A host without one takes the block as the first message.

## 2. The principle

What Second Brain creates — Markdown files, Git history, the MCP server, the `sb` command — belongs to no provider. Every agent reads the same files through the same server and types the same verbs. The Vault never names a product where it speaks of a role; a product is named only where the gesture depends on it (a host-specific step, below), or where the thing is the product's own (`/sb:<verb>` and the plugin of Claude Code, the assistant's sub-agent form).

## 3. The architecture

1. **Two roles, N hosts.** The Pilot and the Executor are roles; each runs in any host that has what the role needs (§1).
2. **One disk channel.** `sb install --mcp` (tools/install-vault-mcp.sh) declares the Vault's server in **every host present** on the machine that accepts a local server — its configuration folder or its command measured, never assumed — through one adapter per host (file, key, form); `tools/lib/mcp-hosts.sh` is the single table. An absent host gets nothing written. Another Vault's server is never touched.
3. **One block, the same everywhere.** The Pilot's block (a project's common trunk, the welcome Pilot's block) is the same bytes whatever the host; only the steps around it change (where to paste it, how to open without a shell, how to send the first message). `sb pilot-prompt [<folder>|--accueil] --host <host>` prints them; by default, for every Pilot host present.
4. **The canary is agnostic.** The canary is the Vault server's `list_allowed_directories` tool, whatever prefix the host gives it, and its answer (the allowed folders, the Vault's commit). No block and no opening step names a prefixed tool name (`mcp__…`): hosts do not agree on one (§5). A project's `<project>/state/PILOT-PROMPT.md` names the server (`mcp_server`), never a prefixed tool.
5. **A host is promised only when measured.** Each host of the matrix (§4) carries one state: **proven** (played on the machine or by the agent bench), **declared** (dated documentation read, not played), **not supported today** (with the reason, and the way the day the Owner wants it).
6. **Mixing the roles is the rule.** Any Pilot host with any Executor host: the files and the server are the common ground. [Pilot hosts and role mixing](../docs/how-to/pilot-hosts-and-role-mixing.md) gives, for each measurable combination, the exact gesture.

## 4. The host matrix

Measured on the laboratory machine on 2026-09-28 (Mission 242, lot 0); documentation read on the same day unless dated otherwise. « Local » = the host runs a local MCP server (stdio); « remote only » = it accepts only a server reached by URL.

| Host | Disk channel | Instructions space | Without a shell | Minimum plan | Pilot | Executor | Source |
|---|---|---|---|---|---|---|---|
| Claude desktop application | local (`claude_desktop_config.json`, `mcpServers`) | Project | yes (no shell) | the Owner's Claude plan | **proven** (the Owner's Pilot sessions since Mission 184) | — (no shell) | measured 2026-09-28: configuration and stdio probe |
| Claude Code | local (`<home>/.claude.json`, `claude mcp add`) | `CLAUDE.md`, the plugin `sb`, an appended system prompt | yes: `--restricted`, no built-in tool | the Owner's Claude plan | **proven** (bench P1-P3, S3: headless, no shell, the Vault's server only) | **proven** (bench E1-E4, S1-S2; this Mission) | measured 2026-09-28: `claude` 2.1.283; `tests/agent-evals/run-agent-evals.sh` (Missions 234-236) |
| Codex CLI | local (`<home>/.codex/config.toml`, `[mcp_servers.<name>]`, `codex mcp add`) | `AGENTS.md`, profiles `<home>/.codex/<name>.config.toml` | declared: `--sandbox read-only --ask-for-approval never --disable shell_tool` | ChatGPT sign-in or API key | declared (case P4 written, not played) | declared (case E6 written, not played) | measured 2026-09-28: `codex-cli` 0.144.5 (`--help`, `features list`: `shell_tool` stable, on); learn.chatgpt.com/docs/config-file/config-reference, read 2026-09-28 |
| Codex application | local (the same `config.toml`) | `AGENTS.md` | as the CLI | as the CLI | declared | declared | measured 2026-09-28: package `OpenAI.Codex` installed; capture 112500 §3 (Codex docs, s.d., read 2026-09-28) |
| Gemini CLI | local (`<home>/.gemini/settings.json`, `mcpServers`) | GEMINI.md | declared: `--approval-mode plan` and `deny` rules (`run_shell_command`, `write_file`, `replace`) | free with a Google account | declared (case P5 written, not played) | declared | google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html, read 2026-09-28; capture 112500 §4; absent from the machine |
| Cursor | local (`<home>/.cursor/mcp.json`, `mcpServers`, `"type": "stdio"`) | `.cursor/rules`, `AGENTS.md` | not documented: allow only the server's tools | not documented | declared | declared | cursor.com/docs/mcp, read 2026-09-28; absent from the machine |
| Windsurf | local (`<home>/.codeium/windsurf/mcp_config.json`, `mcpServers`) | rules, `AGENTS.md` | declared: Ask mode | not documented | declared | declared | github.com/github/github-mcp-server, installation guide for Windsurf, read 2026-09-28; capture 112500 §6; absent from the machine |
| Cline | local (CLI: `<home>/.cline/mcp.json`, `mcpServers`; extension: its own file, through its interface) | .clinerules | declared: Plan mode | not documented (the model billed apart) | declared | declared | docs.cline.bot/mcp/configuring-mcp-servers, read 2026-09-28; absent from the machine |
| LM Studio | local (`<home>/.lmstudio/mcp.json`, `mcpServers`) | presets (not tied to a folder) | not documented: enable only the server | none indicated | declared | — | lmstudio.ai/blog/lmstudio-v0.3.17 (2025-06-25); absent from the machine |
| Jan | local, through its interface (Settings) | not documented per project | per-tool permissions | open source (the model apart) | declared (not written by `sb install`) | — | capture 112500 §6 (docs.jan.ai, 2024-12-31 / s.d.); absent from the machine |
| ChatGPT web | **remote only** (an HTTPS URL, or OpenAI's Secure MCP Tunnel) | Project instructions | per connector | **Plus gives no custom connector**; Pro: read only; Business with admin rights: read and write | **not supported today** | — | capture 112500 §1-§2 (OpenAI Help, 2026-09-22) |
| ChatGPT desktop (Chat view) | no local server documented | Projects | — | as the web | **not supported today** | — | capture 112500 §1 (OpenAI Help, 2026-09-23) |
| Gemini web and mobile | **remote only** (a server URL) | none local | per app | eligibility (United States, English, personal account); plan not documented | **not supported today** | — | capture 112500 §4 (Google Help, read 2026-09-28) |

**Why not ChatGPT today, and the way.** ChatGPT runs no local MCP server: it reaches a server by an HTTPS URL, or by OpenAI's Secure MCP Tunnel, which needs an OpenAI Platform organisation, a key and a daemon kept running, and does not lift the plan restriction; its own price is not documented, and every result the server returns — the content of the files read — passes through OpenAI (and through a third party with a public tunnel such as ngrok). The Owner's plan, Plus, opens no custom connector. The way, the day the Owner wants it: a Pro plan (read only) or Business with admin rights (read and write), plus either the tunnel or an HTTP façade of the server (Streamable HTTP) — a Mission, the Owner's decision; nothing of it is built today. Gemini web is in the same place: a server URL only, and an eligibility the Owner does not meet.

**Tool names.** MCP fixes no prefix; hosts build the name the model sees: Claude and Codex show `mcp__<server>__<tool>` (Codex's own prompt says so, measured 2026-09-28), Gemini CLI shows the bare tool name unless two servers collide (then `<server>__<tool>`) and truncates beyond 63 characters, and the Gemini API caps a function name at 64. Hence §3.4, and a guard: `install-vault-mcp.sh` refuses a server name whose longest tool name, `mcp__<server>__list_allowed_directories`, goes over 64 characters (a label of at most 14 characters), before anything is written, and proposes a shorter label (`sb install --mcp --label <label>`).

## 5. What stays specific, named as such

- `/sb:<verb>` and the plugin `sb` are Claude Code's; `$sb <verb>` is Codex's; a message `sb <verb>` works for any agent (rule on the [sb command surface](./RULES-2026-09-26-200933-sb-command-surface.md)).
- The verdict `ANOMALY (nom du Project)` compares the name a host shows for its instructions space with `pilot_project_name`; only the Claude desktop application shows one today. Elsewhere the comparison is `DECLARED`.
- The assistant has three generated forms (a Claude Code sub-agent, a Codex skill, a web package); its instructions are the same.

## 6. What this rule changes, and what it does not

It changes the words and the tools listed in §3. It does not change the roles, the charter's determination of the role, the server's tools, the nine questions of the installer, nor the naming of the server (Decision 162812: `second-brain-vault-<label>`); it adds the length guard. A host moves from declared to proven only by a measurement written in a report.

## Liens

- `amends` — [Template — minimal opening prompt for a Pilot session](../templates/session-opening-prompt-template.md)
- `amends` — [Template — welcome Pilot](../templates/accueil-pilot-prompt-template.md)
- `amends` — [Skill — session-start](../skills/session-start/SKILL.md)
- `see also` — [Role charter and session determination](./RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Rule — The sb command surface](./RULES-2026-09-26-200933-sb-command-surface.md)
- `see also` — [Rule — Workspace hygiene, project names and session types](./RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
- `see also` — [Pilot hosts and role mixing](../docs/how-to/pilot-hosts-and-role-mixing.md)
