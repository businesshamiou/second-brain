---
type: how-to
title: "Pilot hosts and role mixing"
description: "Run the Pilot or the Executor in the tool you choose — the Claude app, Claude Code, Codex, Gemini CLI, Cursor, Windsurf, Cline, LM Studio — and mix them: one server, one block, the same verbs. For each combination, the exact gesture and what is proven or only declared; why ChatGPT is not a Pilot host today. The page that is authoritative."
status: active
---

# PILOT HOSTS AND ROLE MIXING

The Pilot and the Executor are roles, not products ([rule on model-agnostic Pilot and Executor hosts](../../rules/RULES-2026-09-28-121219-model-agnostic-pilot-and-executor-hosts.md)). A **host** is the tool an agent runs in. A Pilot host needs the Vault's MCP server and no shell; an Executor host needs a shell. The files, the server and the `sb` verbs are the same in all of them, so you can mix: a Pilot in the Claude app with an Executor in Codex, a Pilot in Codex with an Executor in Claude Code, any pair.

In the commands below, `<workspace>` is the absolute path of your workspace and the installed Second Brain is `<workspace>/second-brain`.

## Before you start

- **Which hosts you have.** `sb doctor` lists each host present on this machine with the line `MCP · <host>`: the Vault's server declared or not. The hosts it does not find are on the line `MCP hosts absent`.
- **The server in every host.** `sb install --mcp` declares the server in every host present — the Claude app, Claude Code, Codex, Gemini CLI, Cursor, Windsurf, Cline (its command-line tool), LM Studio — and writes nothing for an absent one. Restart each host afterwards. A server name too long for some hosts is refused with a shorter label proposed: `sb install --mcp --label <label>` (at most 14 characters).
- **What is proven.** The rule's matrix gives each host a state: *proven* (played on this machine or by the agent bench), *declared* (documentation read and dated, not played yet), *not supported today* (with the reason). `sb pilot-prompt` says the state of each host it prints.

## The hosts, in one table

| Host | As a Pilot | As an Executor | Where the block goes |
|---|---|---|---|
| Claude desktop application | proven | — (no shell) | a Project named `SB - <name>`, its instructions |
| Claude Code | proven (no shell: `--restricted`, the agent bench) | proven | an appended system prompt, or the first message |
| Codex (command line and app) | declared | declared | the first message (or `AGENTS.md`) |
| Gemini CLI | declared | declared | the first message (or `GEMINI.md`) |
| Cursor, Windsurf, Cline | declared | declared | the first message (or their rules) |
| LM Studio, Jan | declared | — | the first message (or a preset) |
| ChatGPT (web, desktop), Gemini web | **not supported today** | — | — |

## Steps

### Get the block and the steps for your host

In a terminal, in the project's folder (or anywhere in the workspace for the welcome Pilot):

```text
sb pilot-prompt
sb pilot-prompt --host codex
sb pilot-prompt --accueil --host gemini
```

_Not executed by the documentation check._

The block between the two lines is the same, byte for byte, for every host. After it come the steps of each Pilot host present (or of the one `--host` names: `claude-desktop`, `codex`, `gemini`, `cursor`, `windsurf`, `cline`, `lmstudio`):

- **Claude desktop application.** Create (or open) the Project named `SB - <name>`, paste the block as its instructions; the first message of each conversation is the project's path.
- **Any other host.** Open a new session where the Vault's server is declared, without a shell (the step says how for that host), and send **the block, then, on its own line, the path** as the first message. The block tells the agent that it is its instructions when it arrives this way.

### Open a Pilot without a shell

| Host | Without a shell | State |
|---|---|---|
| Codex | `codex --sandbox read-only --ask-for-approval never --disable shell_tool`, or a profile `~/.codex/<name>.config.toml` with `sandbox_mode = "read-only"`, `approval_policy = "never"` and `[features] shell_tool = false`, started with `codex --profile <name>` | declared: the flag exists in Codex 0.144.5 and is documented; its effect on the tools the model sees has not been played |
| Gemini CLI | `gemini --approval-mode plan`, and `deny` rules for `run_shell_command`, `write_file` and `replace` in its policy engine | declared |
| Windsurf | Cascade's Ask mode | declared |
| Cline | Plan mode | declared |
| Cursor, LM Studio | no documented mode: allow only the Vault server's tools | declared |

### Mix the roles

Each window reads the same files through the same server; nothing has to be moved between hosts. The relay stays yours: you paste the mini-prompt from the Pilot into the Executor, and the `RELAY` block back.

| Pilot | Executor | The gesture | State |
|---|---|---|---|
| Claude desktop application | Claude Code | the Pilot's block in its Project; `sb open` or the Mission's mini-prompt in Claude Code, in the project folder | proven |
| Claude desktop application | Codex | the same Pilot; in Codex, opened in the project folder, `sb open` (or `$sb open`) or the mini-prompt; Codex reads `AGENTS.md`, which points to the role charter | declared (case E6 written) |
| Codex (no shell) | Claude Code | `sb pilot-prompt --host codex`, the block then the path as the first message in Codex started without a shell; the Executor as usual in Claude Code | declared (case P4 written) |
| Gemini CLI (plan mode) | Codex | `sb pilot-prompt --host gemini`; the Executor in Codex as above | declared (cases P5 and E6 written) |
| Claude Code (no shell) | Codex or Claude Code | `claude --restricted` with the Vault's server only, the block as an appended system prompt or first message | proven for the Pilot (bench P1-P3) |
| any Pilot host | any Executor host | the block of `sb pilot-prompt --host <host>`; `sb` in the Executor's terminal | as the weaker of the two |

### Check a host in five minutes

For each host `sb doctor` lists:

1. `sb doctor`: the line `MCP · <host>` says `declared`. Otherwise `sb install --mcp`, then restart the host.
2. `sb pilot-prompt --host <host>`: follow its steps 1 and 2 (a new session, no shell).
3. Send the block and the project's path as the first message.
4. The first line of the answer is `READY` or `NOT-READY (<reason>)`, and the answer carries the project's canary (the value of `canary:` in `<project>/state/PILOT-PROMPT.md`).
5. Ask it to write nothing and to name the Executor window for any `sb` verb that needs a shell. A host that passes these five points on your machine can be written *proven* in the rule by the next Mission.

## What you should see

- `sb doctor`: one `MCP · <host>` line per host present, `second-brain-vault-<label> declared`.
- `sb pilot-prompt --host <host>`: `Pilot « SB - <name> »`, the block between two lines, then a section `<host> — proven` or `<host> — declared (dated documentation, not yet played as a Pilot)`.
- The Pilot's first line: `READY` or `NOT-READY (<reason>)`, whatever the host.

## Known errors

- **`sb pilot-prompt --host chatgpt`** answers that ChatGPT is not supported today as a Pilot host (exit 2): see the question below.
- **`Refused: the server name … makes tool names of 65 characters`** at `sb install --mcp`: a label of at most 14 characters, `sb install --mcp --label <label>`; nothing was written.
- **`MCP · <host> … not declared in this host`** in `sb doctor`: `sb install --mcp`, then restart that host.

## Questions

**Why can't my Pilot run in ChatGPT today?** ChatGPT does not start a local MCP server: it reaches a server only by an HTTPS address, or through OpenAI's Secure MCP Tunnel. The Plus plan opens no custom connector at all; Pro allows reading only; Business with administrator rights allows reading and writing. The tunnel needs an OpenAI Platform organisation, a key and a program kept running on your machine, does not lift the plan restriction, and its own price is not documented; every result the server returns — the content of the files read — passes through OpenAI (and through a third party with a public tunnel such as ngrok). A ChatGPT Project keeps instructions, but no documented setting turns a connector on in all its conversations. The way, the day you want it: a Pro or Business plan, and a Mission that builds the tunnel or an HTTP façade of the server. Until then, ChatGPT is not a Pilot host; its Codex part is (see Codex).

**And Gemini in the browser?** The same: a server address only, and an eligibility (United States, English interface) that does not apply here. Gemini CLI, on the contrary, runs the Vault's server.

**Do I paste a different block in each tool?** No. The block is the same bytes everywhere; only where you paste it, and how you open the tool without a shell, change.

## Scripts used

- `tools/lib/mcp-hosts.sh` — the table of hosts: [internal helpers](../reference/tools-internal-helpers.md)
- `tools/install-vault-mcp.sh` — the server in every host present, the name length guard: [assistant and MCP tools](../reference/tools-assistant-and-mcp.md)
- `tools/check-mcp-containment.sh` — `--all`: every host present: [assistant and MCP tools](../reference/tools-assistant-and-mcp.md)
- `tools/sb/sb.py` — `sb pilot-prompt --host`, `sb doctor`, `sb install --mcp --label`: [Commands](../reference/commands.md)

## Liens

- `prescribed by` — [Rule — Model-agnostic Pilot and Executor hosts](../../rules/RULES-2026-09-28-121219-model-agnostic-pilot-and-executor-hosts.md)
- `see also` — [Use the sb command and its plugin](use-the-sb-command-and-plugin.md)
- `see also` — [Opening scenarios](opening-scenarios.md)
- `see also` — [Start something new](start-something-new.md)
- `see also` — [Support FAQ](../reference/support-faq.md)
