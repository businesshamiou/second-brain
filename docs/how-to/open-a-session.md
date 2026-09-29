---
type: how-to
title: "Open a session"
description: "How to open a Pilot session in the Claude desktop application and an Executor session in Claude Code or Codex, and how to read the READY or NOT-READY verdict each one returns first."
status: active
---

# OPEN A SESSION

Every session holds a single role, `pilot` or `executor`, determined at opening and then announced ([role charter, §1](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)):

- The **Pilot** thinks, arbitrates with you (the Owner) and designs the Missions. It runs in the Claude desktop application and reaches the disk only through the Vault's MCP server.
- The **Executor** runs shell commands, measures, writes and commits. It runs in Claude Code or Codex, inside the project folder.

Both openings end the same way: a `READY` or `NOT-READY` verdict as the very first line of the answer ([session-start skill, §4](../../skills/session-start/SKILL.md)). Closing a session is a separate gesture, described in [Close a session](close-a-session.md).

Both openings also have one verb of the `sb` command: `sb open` in a terminal, `/sb:open` in Claude Code, `$sb open` in Codex ([Use the sb command and its plugin](use-the-sb-command-and-plugin.md)).

Before its role, a session identifies its **type** and its line in the entry-scenario matrix at the head of the [session-start skill](../../skills/session-start/SKILL.md) (§0); [Opening scenarios](opening-scenarios.md) gives, for each line, the verdict you see and what to do: a **project** session (a project path, or a birth certificate walking up), a **welcome** session (the Project `SB - Accueil`, for a project that does not exist yet), a **free** session (no path, no Mission, no order: first line `READY (session libre)`, reads and writes nothing), or a **Vault** session. To start something that does not exist yet, see [Start something new](start-something-new.md).

## Before you start

- A project that is already created or adopted. It carries a Pilot prompt at `<project>/state/PILOT-PROMPT.md`, generated at its creation, with the project's path, the Vault's server name and a **canary** ([README, "Open a project's Pilot"](../../README.md)).
- The Vault's MCP server installed by `sb install` (step 4, or `sb install --mcp` alone), the `first-install` skill or `tools/install-vault-mcp.sh`, and the desktop application restarted afterwards ([INSTALL.md §4](../../INSTALL.md)).
- For the Pilot: the Claude desktop application. The MCP server does not exist in the browser. It is named after your workspace folder, `second-brain-vault-<workspace>` (for example `second-brain-vault-workspaces`); only when no workspace label is recorded in `VAULT-IDENTITY.md` does it use the first 8 characters of the Vault's identity. Two Vaults on one machine have two servers side by side ([README, "The MCP server"](../../README.md)).
- For the Executor: Claude Code or Codex, opened in the project folder.

## Steps

### A. Open the Pilot (Claude desktop application)

1. Create a **Project** named `SB - <display name>` — the display name of the [Project Registry](../../projects/PROJECT-REGISTRY.md), the one the Pilot prompt carries as `pilot_project_name`. At every opening the Pilot compares the name of its Project with that value: a mismatch is reported as `ANOMALY (nom du Project)`, never a block ([rule on workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md) §5).
2. Paste the common prompt as the Project's instructions. The simplest way to get it: `sb pilot-prompt <workspace>/<project>` in a terminal prints the Project's name, this block with your server's name filled in, the first message and the expected canary; it writes nothing. The block is the text between the markers `PROMPT:BEGIN` and `PROMPT:END` in `templates/session-opening-prompt-template.md`. `tools/project-bootstrap.sh` prints this block, framed by `---` lines, at the end of a `create`, `adopt` or `--order` run, with the server name already filled in for your Vault ([`tools/project-bootstrap.sh`](../../tools/project-bootstrap.sh), "Block to consume"). If you copy it from the template yourself, the placeholder `{{VAULT_SHORT_ID}}` stands for your server's suffix (the `<workspace>` part) and must be replaced ([template, line 12](../../templates/session-opening-prompt-template.md)).
3. Send the project's path as the first message of the conversation.

The common prompt carries no behaviour rules. It tells the Pilot to use only the `second-brain-vault-<workspace>` server, to answer you in the language you write in, and to run a fixed opening sequence. Read the template itself for the exact wording; here is what each step proves.

- **Step zero, the channel answers.** Before any reading, the Pilot runs one tool search for the Vault server's file tools and one cheap read (`list_allowed_directories`), timed. Both are counted outside the budget. This proves the server is actually connected.
- **Step 1, the path.** The list of authorized folders must contain the project path you gave. The Pilot notes the Vault commit it returns.
- **Step 2, the canary.** The Pilot reads `<project>/state/PILOT-PROMPT.md` and returns its canary: the proof that it read the disk through the server rather than answering from memory ([README](../../README.md)). It also compares the Vault commit with the one recorded in that file; a gap is stated but does not block.
- **Step 3, the state sheet.** The Pilot reads the state sheet the Pilot prompt names (its `state_path`, by default `<project>/state/STATE.md`) and applies the seven-line Pilot contract at its head. That contract says, among other things, that no file is deposited without your explicit agreement, asked just before writing ([Pilot contract template](../../templates/pilot-contract-template.md)).
- **The verdict first; a path not authorized is not a project not adopted.** The first line of the Pilot's answer is `READY` or `NOT-READY (<reason>)`, nothing before it. If the path you gave lies under none of the folders the server may read, the Pilot answers `NOT-READY (chemin non autorisé : réinstaller le serveur MCP, sb install)` [path not authorized] and proposes no order: the project may well exist, the server's allowed folder is what is wrong. If the path is authorized but carries no `state/PILOT-PROMPT.md`, it answers `NOT-READY (projet non adopté)` [project not adopted] and proposes the initiation order from the Vault's template, writing nothing (scenario E8, [Opening scenarios](opening-scenarios.md)). These rules, and the handling of a message that starts with `sb `, are in the pasted block itself.

The Pilot then follows its reading list: the digest, the handoff the digest names, the Git refs of the two repositories, and the listing of `<project>/handoffs/` ([reading list, Pilot](../../skills/session-start/reading-list.md)).

### B. Open an Executor (Claude Code or Codex)

1. Open Claude Code or Codex in the project folder.
2. Type `sb open` (or `/sb:open` in Claude Code, `$sb open` in Codex), or ask it to open the session, for example "open the session". Both run the `session-start` skill.
   Its opening also runs `tools/check-workspace-root.sh` (anything at the root of the workspace that the whitelist does not allow is a warning, `ÉCART`) and, in a project, `tools/project-bootstrap.sh identity <project> --check` (folder, birth certificate and registry row agree, or each mismatch is an `ANOMALY`). An Executor opened at the workspace root itself answers `NOT-READY (racine de l'espace …)` and writes nothing.

The role is determined by measurement, in three rungs ([charter, §1](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)):

| Rung | What decides | Where it applies |
|---|---|---|
| 1. Startup hook | A `SessionStart` hook that injects a role prevails. | In the Vault repository, `.claude/settings.json` runs `tools/session-start-role.sh`, which injects `role: executor`, the Vault root and the charter path. The bootstrap installs no such hook in a project. |
| 2. Capability probe | The skill tries a harmless shell command (`git --version`). It answers: Executor. No shell: Pilot ([session-start skill, §1](../../skills/session-start/SKILL.md)). | Everywhere else. |
| 3. Declaration | The mini-prompt's title line `Session Executor — Mission <NNN>` confirms the role; it never proves it on its own. | When a mini-prompt is pasted. |

If two rungs disagree, the session stops and asks you. In doubt, `pilot` is presumed.

The Executor then:

1. **Checks that the folder is adopted.** It walks up to a birth certificate: `<project>/.pre-commit-config.yaml` whose first line is `# second-brain-birth-certificate: v1`. `tools/resolve-vault.sh` returns the Vault or a named refusal. With an initiation order received, it runs `project-bootstrap.sh --order <file>` and relays its output. Without certificate and without order, it does not adopt the folder: it prints the order to fill in and stops ([session-start skill, §1 bis](../../skills/session-start/SKILL.md)). You can print that order yourself; it writes nothing:

   ```bash
   bash <workspace>/second-brain/tools/project-bootstrap.sh order <workspace>/<project>
   ```

   In PowerShell, where `bash` is unknown: `& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/project-bootstrap.sh order <workspace>/<project>`.

2. **Establishes its position**: current directory, repository, relative paths to the Vault (found by walking up to the `<workspace>/VAULT-ROOT.md` marker, never a hard-coded folder name) and to the project's repository.
3. **Reads the Mission** named by the mini-prompt it received, in full, Context section included. That Mission is its only source of instructions ([reading list, Executor](../../skills/session-start/reading-list.md)).
4. **Measures the guardians**: the `rev:` pin of `<project>/.pre-commit-config.yaml` against the Vault's head (not applicable to a `repo: local` pin), the native hook `.githooks/pre-commit` and `core.hooksPath` pointing to it, each guardian script the hook names present in `tools/`. Then it pastes `git status -sb` for both repositories.

The first time you open a project in Claude Code, it asks for an approval. Your assistant and skills are linked into the project (`<project>/.claude/agents/`, `<project>/.claude/skills/`, `<project>/.agents/skills/`) by links to your `second-brain` clone, a neighbouring folder. Claude Code treats a link whose target leaves the working folder as an **external import** and asks once per project, not at each session. Answer yes: these links only give read access to the clone you installed yourself, and a project never writes there. The exact wording depends on your Claude Code version ([README, "Frequently asked questions"](../../README.md); [INSTALL.md §5](../../INSTALL.md)).

## What you should see

The first line of the answer is the verdict, nothing before it: no greeting, no summary. An anomaly found during the opening is the reason inside the verdict, never a paragraph before it. Then, in this order ([session-start skill, §4](../../skills/session-start/SKILL.md)):

```
READY
[role: <pilot|executor> · <plan|implement|validate> · open]
<state, five lines at most, each value VERIFIED, DECLARED or ANOMALY>
<Opening / budget: tool calls before the verdict, bytes reported by get_file_info>
```

or `NOT-READY (<measured reason>)` on the first line.

- `VERIFIED` means measured in this session, source named; `DECLARED` means copied from the digest or the handoff, with its timestamp; `ANOMALY` means two sources disagree. On the Pilot, the `git status` gaps are always `DECLARED`.
- **Budget.** The Pilot's opening costs nine filesystem calls when the digest is fresh, eleven at worst ([reading list](../../skills/session-start/reading-list.md)). The Executor's budget is 12 calls.
- **Consequence of `NOT-READY`.** Pilot: no filing for the whole session. Executor: no gesture at all, no writing and no commit, for the whole window. Reading and discussing remain allowed. The repair is a Mission or your arbitration.

The skill itself writes nothing, on any surface; the only exception is an initiation order received, whose writing belongs to `tools/project-bootstrap.sh`.

## Known errors

| What you see | Cause | What to do |
|---|---|---|
| `NOT-READY (channel not answering)` | Step zero got no answer within 60 seconds, or the answer "No result received from client-side tool execution": the server is not connected. | Restart the desktop application; if it persists, declare the server again with `sb install --mcp` and check it with `tools/check-mcp-containment.sh` ([INSTALL.md §4](../../INSTALL.md)). |
| `READY` with an `ANOMALY` (unlinked channel) | The tools answer but run client-side: the session is not linked to the computer. | Each tool used for the first time will wait for your approval: do not leave work running unattended from that window. |
| The Pilot says the server does not exist and stops | The conversation is not in the desktop application, or the server was never declared. | Open the Project in the Claude desktop application; if it is already there, run `sb install --mcp`, then restart the application. |
| `NOT-READY (chemin non autorisé : réinstaller le serveur MCP, sb install)` [path not authorized] | The project path lies under none of the server's allowed folders. | `sb install --mcp`, then restart the desktop application ([Opening scenarios, E8](opening-scenarios.md)). |
| `NOT-READY (projet non nommé)` [project not named] | Nothing names the project; the Pilot never searches for one. | Send the project's path as the first message. |
| `NOT-READY (projet non adopté)` [project not adopted]: the Pilot finds no `<project>/state/PILOT-PROMPT.md` | The path is authorized but the project is not adopted. | The Pilot proposes an initiation order from `templates/initiation-order-template.md`; see [Adopt a project](adopt-a-project.md), or run `sb adopt` in that folder. |
| `NOT-READY (session close missing)` | The newest handoff on disk is more recent than the one the digest names: its close was never made ([reading list, point 4](../../skills/session-start/reading-list.md)). | First run that handoff's Executor closing command (its `## Executor closing command` section), see [Close a session](close-a-session.md). |
| `NOT-READY (dossier non adopté, ordre d'initiation rendu)` [folder not adopted, initiation order returned] | Executor in a folder with no birth certificate and no initiation order. | The Pilot fills in the order, you date it, then hand it to the Executor. |
| The session stops and asks which role it holds | Two rungs of the charter disagree. | Answer with the role; `pilot` is presumed in doubt. |
| A context line starting `Preflight NOT-READY:` | `tools/session-start-role.sh` found the Vault's preflight not ready. | Run `tools/session-preflight.sh`; see [Troubleshoot](troubleshoot.md). |
| The Pilot names an old server | The server name changed, and adoption never rewrites an existing Pilot prompt. | Regenerate the prompt, below. |

**Regenerate a project's Pilot prompt.** `sb pilot-prompt <workspace>/<project> --regen` does it; underneath, the usage from the code ([`tools/project-bootstrap.sh`](../../tools/project-bootstrap.sh)) is `project-bootstrap.sh prompt <dossier> [--state-path <chemin relatif>]`.

```bash
bash <workspace>/second-brain/tools/project-bootstrap.sh prompt <workspace>/<project>
```
_Not executed by the documentation check._ In PowerShell, `sb pilot-prompt <workspace>/<project> --regen` above is the form to type.

It rewrites only `<project>/state/PILOT-PROMPT.md`. It keeps what belongs to the project (identifier, canary, title, path) and regenerates what belongs to the Vault (identity, server name, commit, date, links). It touches no registry, no birth certificate and no Git, and ends with `PILOT-PROMPT regenere : <path> (serveur <name>, commit <sha>, fiche <state_path>, langue <lang>)`. It does not print the Project instructions again; those instructions name the server too, so paste the new block if needed. Under Windows in PowerShell, call Git's `bash` by its full path (README, frequently asked questions). Its refusals, each exit 1 with nothing written:

- A refusal ending `le projet n'est pas adopte (adopt d'abord)`: the folder has no Pilot prompt; adopt it first.
- `REFUS : --state-path doit etre un chemin relatif au projet, sans '..'` or `REFUS : --state-path introuvable`: `--state-path` must be relative to the project and name an existing file.
- `REFUS : ce Vault n'a pas d'identite generee`: the server name cannot be derived.
- `REFUS : dossier du projet introuvable`, or `... format non reconnu, rien n'est ecrit` when the prompt lacks its project fields.

## Scripts used

- `tools/project-bootstrap.sh`: prints the block to consume, the initiation order, and regenerates the Pilot prompt. Sheet: [Project tools](../reference/tools-projects.md).
- `tools/resolve-vault.sh`: finds the project's Vault from its birth certificate. Sheet: [Internal helpers](../reference/tools-internal-helpers.md).
- `tools/session-start-role.sh` and `tools/session-preflight.sh`: the Vault's startup hook and its preflight. Sheet: [Guardians and hooks](../reference/guardians-and-hooks.md).
- `tools/install-vault-mcp.sh` and `tools/check-mcp-containment.sh`: install and check the Pilot's server. Sheet: [Assistant and MCP tools](../reference/tools-assistant-and-mcp.md).

## Liens

- `source` — [Template — minimal opening prompt for a Pilot session](../../templates/session-opening-prompt-template.md)
- `source` — [Template — Pilot contract](../../templates/pilot-contract-template.md)
- `source` — [Template — initiation order](../../templates/initiation-order-template.md)
- `source` — [session-start skill](../../skills/session-start/SKILL.md)
- `source` — [Session opening reading list, by role](../../skills/session-start/reading-list.md)
- `source` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `source` — [README — The MCP server, Open a project's Pilot, Frequently asked questions](../../README.md)
- `source` — [Installation guide, sections 4 and 5](../../INSTALL.md)
- `source` — [Project bootstrap script](../../tools/project-bootstrap.sh)
- `source` — [Startup role hook](../../tools/session-start-role.sh)
- `source` — [Session preflight](../../tools/session-preflight.sh)
- `source` — [Vault resolution](../../tools/resolve-vault.sh)
- `source` — [Vault identity and server name](../../tools/vault-identity.sh)
- `source` — [MCP server installer](../../tools/install-vault-mcp.sh)
- `source` — [MCP containment check](../../tools/check-mcp-containment.sh)
- `source` — [Claude Code settings of the Vault](../../.claude/settings.json)
- `see also` — [Close a session](close-a-session.md)
- `see also` — [Adopt a project](adopt-a-project.md)
- `see also` — [Create a project](create-a-project.md)
- `see also` — [Run a Mission as Executor](run-a-mission-as-executor.md)
- `see also` — [Troubleshoot](troubleshoot.md)
- `see also` — [Roles and Missions](../explanation/two-roles.md)
- `see also` — [Architecture](../explanation/architecture.md)
- `see also` — [Skills](../reference/skills.md)
- `see also` — [Glossary](../../CONTEXT.md)
- `see also` — [Rule — Workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
- `see also` — [Start something new](start-something-new.md)
- `see also` — [Opening scenarios](opening-scenarios.md)
- `see also` — [Use the sb command and its plugin](use-the-sb-command-and-plugin.md)
