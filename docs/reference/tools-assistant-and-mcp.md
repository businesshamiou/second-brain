---
type: reference
title: "Tools: assistant and MCP server"
description: "One sheet per script for the assistant generator, the Vault's MCP server, its installer, its containment check and the assistant acceptance harness: syntax, options, exit codes, what each reads and writes."
status: active
---

# TOOLS: ASSISTANT AND MCP SERVER

Five scripts: one builds the read-only assistant, three give the Pilot bounded disk access through the Vault's own MCP server, and one checks that the assistant answers. In the examples, `<workspace>` is the absolute path of your workspace and the installed Vault is `<workspace>/second-brain`.

**Under Windows.** A `bash …/tools/…` line of this page, typed in PowerShell where `bash` is unknown, starts with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`; where an `sb` verb carries the same gesture ([Commands](commands.md)), type the verb. `sb doctor` says whether `bash` is on your PATH.

## generate-assistant.ps1

**Role.** A PowerShell library, dot-sourced (not run on its own). It reads the single identity source `assistant/ASSISTANT.md`, puts the chosen name in place of the `{{ASSISTANT_NAME}}` token, appends the documentation map of `docs/MAP.md`, and writes three forms of the assistant.

**Called by.** `install.ps1` (dot-sources it, then calls `Move-AssistantFormsToTrash` for a former name and `New-AssistantForms`). Tests: `tests/test-assistant-generation.ps1` and the other test-assistant and test-web-package suites under `tests/`. On macOS and Linux the same forms come from its Python twin, `tools/sb_installer_helper.py`.

**Syntax** (from the file's header):

```powershell
. "$PSScriptRoot\tools\generate-assistant.ps1"
$slug = New-AssistantForms -ClonePath $clonePath -Name $vaultName -Language $language
```

**Options.**

| Function | Parameters | Returns |
|---|---|---|
| `New-AssistantForms` | `-ClonePath` (required), `-Name` (required), `-Language` `FR`, `EN` or `ES` (default `FR`; an unknown code falls back to `FR`) | the slug |
| `Move-AssistantFormsToTrash` | `-ClonePath`, `-OldSlug` (required), `-At` (date, default now) | `$true` if something was moved |
| `ConvertTo-AssistantSlug` | `-Name` | lower case, accents removed, every other run of characters becomes one hyphen; empty result gives `assistant` |

**Errors.** It throws (stops) when: the identity source is missing; its `corps-generateur` markers are missing; `docs/MAP.md` or its `doc-map` markers are missing; a knowledge-file source is missing; the instructions text would exceed 8000 characters; the web package would hold more than 25 files. **Reads.** `assistant/ASSISTANT.md` (only the text between `<!-- corps-generateur:debut -->` and `<!-- corps-generateur:fin -->`), `docs/MAP.md` (between `<!-- doc-map:start -->` and `<!-- doc-map:end -->`), `CONTEXT.md` and the six rule, skill, template and brief files listed in `$Script:WebPackageKnowledgeFiles`.

**Writes** (UTF-8 without byte-order mark; the same name twice gives byte-identical files):

| Form | Path |
|---|---|
| Claude Code subagent (front matter `tools: Read, Glob, Grep`, `model: haiku`) | `<clone>/.claude/agents/<slug>.md` |
| Codex skill (read-only by instruction only) | `<clone>/.agents/skills/<slug>/SKILL.md` |
| Web package: INSTRUCTIONS.md, GLOSSARY.md, PROJECT-BOUNDARY.md, METHOD.md, README.md | `<clone>/web-package/<slug>/` |

The `description` field of the subagent and of the skill is written in the chosen language. On a rename, `Move-AssistantFormsToTrash` moves the old forms to `<clone>/_trash/assistant-rename-<old slug>-<yyyyMMdd-HHmmss>/`; it never deletes. **Repository-root guard.** Does not carry `tools/repo_root_guard.py`: it writes only under the `-ClonePath` its caller gives.

**Example** (no side effect; prints `elodie-martin`, the slug that name will get):

```powershell
. <workspace>/second-brain/tools/generate-assistant.ps1; ConvertTo-AssistantSlug -Name 'Élodie Martin'
```

## vault-mcp.py

**Role.** The Vault's MCP server: it gives the Pilot disk access limited to the folders it is given. Python standard library only, started by `uv`. Transport: standard input and output, JSON-RPC 2.0, one message per line; logs go to standard error, prefixed `[vault-mcp]`.

**Called by.** The tool configurations that `tools/install-vault-mcp.sh` writes (Claude Code, Codex, the Claude desktop application) start it. Tests: `tests/test-vault-mcp.sh`, `tests/test-vault-mcp-server-name.sh`, `tests/test-vault-mcp-refusal-message.py`, `tests/test-install-vault-mcp-workspace-label.sh`.

**Syntax** (from the code):

```
uv run --no-project tools/vault-mcp.py --allow <folder> [--allow <folder>...] [--vault <root>]
```

**Options.** `--allow <folder>`: required, repeatable; a folder the server may read and write under, which must exist. `--vault <root>`: the Vault whose name and commit the server announces; default, the folder above the script's `tools/`.

**How it names itself.** The name is read from `VAULT-IDENTITY.md` at the root of `--vault`, the same rule as `vid_server_name` in `tools/vault-identity.sh`:

| Front matter of `VAULT-IDENTITY.md` | Name announced |
|---|---|
| `vault_id` and a `workspace_label` | `second-brain-vault-<workspace_label>` (label lower-cased, accents folded, other characters turned into single hyphens) |
| `vault_id`, no label | `second-brain-vault-` plus the first 8 characters of `vault_id` after `sb-` |
| no file, no front matter, empty `vault_id` | `second-brain-vault` |

**Tools it offers.**

| Tool | Arguments | What it does |
|---|---|---|
| `list_allowed_directories` | none | Lists the allowed folders, the Vault path and the Vault commit |
| `list_directory` | `path` | Lists a folder, `[DIR]` or `[FILE]` per entry |
| `read_text_file` | `path`, optional `head` or `tail` | Reads a text file, whole or its first or last lines |
| `read_multiple_files` | `paths` | Reads several files, separated by `---` |
| `write_file` | `path`, `content` | Writes a file, replacing it if it exists |
| `edit_file` | `path`, `edits` (`oldText`, `newText`), optional `dryRun` | Replaces exact passages; returns the diff; `dryRun` writes nothing |
| `create_directory` | `path` | Creates a folder and its parents |
| `search_files` | `path`, `pattern` | Finds file and folder names by glob or substring; skips `.git`, does not follow links, stops after about 500 matches |
| `get_file_info` | `path` | Size, dates, folder or file |
| `move_file` | `source`, `destination` | Moves or renames; refuses an existing destination |

**Bounds.** Every path is resolved (links followed) before it is compared, so a link or junction that leaves the allowed folders is refused. A refusal is a tool result marked `isError`, whose text names the path asked for and the allowed folders (`accès refusé : <path> est hors des dossiers autorisés.`). Only protocol defects are JSON-RPC errors: unknown method or tool (`-32601`), unreadable JSON (`-32700`), internal error (`-32603`). The version it announces is the first 12 characters of the Vault's commit.

**Exit codes.** `2` with `dossier autorisé introuvable : <folder>` when an `--allow` folder does not exist; `0` when its input closes. **Reads.** Files under the allowed folders; `VAULT-IDENTITY.md` and the Git HEAD of the Vault. **Writes.** Only through `write_file`, `edit_file`, `create_directory` and `move_file`, inside the allowed folders. **Repository-root guard.** Does not carry `tools/repo_root_guard.py`; its perimeter is the `--allow` list.

**Example** (read-only: asks the server what it may reach; the answer's text starts with `Allowed directories:` and ends with `Vault commit: <sha>`):

```bash
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_allowed_directories"}}' | uv run --no-project <workspace>/second-brain/tools/vault-mcp.py --allow <workspace>
```

## install-vault-mcp.sh

**Role.** Declares this Vault's MCP server in every host found on the machine (the table of [`tools/lib/mcp-hosts.sh`](./tools-internal-helpers.md), Mission 242): Claude Code (`claude mcp add -s user`), Codex (`codex mcp add`), the Claude desktop application (merged into its `<desktop config folder>/claude_desktop_config.json`, other servers kept), and, each only when present (its folder or its command measured), Gemini CLI (`<home>/.gemini/settings.json`), Cursor (`<home>/.cursor/mcp.json`, with `"type": "stdio"`), Windsurf (`<home>/.codeium/windsurf/mcp_config.json`), Cline's command-line tool (`<home>/.cline/mcp.json`) and LM Studio (`<home>/.lmstudio/mcp.json`) — the same merge under `mcpServers`, other servers and keys kept; an absent host is said `Not found: <host>` and gets nothing written. The allowed folder is the workspace root. The installer itself never calls it.

**Called by.** `sb install` (its fourth step, or `sb install --mcp` alone: [Use the sb command and its plugin](../how-to/use-the-sb-command-and-plugin.md)); `skills/first-install/SKILL.md` (after the install). `tools/second-brain-update.sh` only tells you to run it again when the server may have changed. Tests: `tests/test-vault-mcp.sh`, `tests/test-install-vault-mcp-name-per-vault.sh`, `tests/test-install-vault-mcp-workspace-label.sh`.

**Syntax** (usage line from the code):

```
usage: install-vault-mcp.sh <espace-de-travail> [--vault <racine>] [--lang FR|EN|ES] [--label <libelle>] [--retire <cle>]... [--skip-desktop]
```

**Options.**

| Option | Meaning |
|---|---|
| `<espace-de-travail>` | The workspace root, which must exist. It becomes the server's `--allow` folder. |
| `--vault <root>` | The Vault to declare. Default: the folder above the script's `tools/`. |
| `--lang FR\|EN\|ES` | Language of the messages, from the matching catalog under `i18n/` (for example `i18n/catalog.en.json`). Default `EN`. |
| `--label <label>` | Workspace label to use. Default: the label already in `VAULT-IDENTITY.md`, else the name of the workspace folder. Normalised; empty after normalisation is refused. |
| `--retire <key>` | Repeatable. Removes a generic server (for example `workshops`) from each configuration that holds it, quoting its former entry. A key that is `second-brain-vault` or starts with `second-brain-vault-` is refused. |
| `--skip-desktop` | Leaves the desktop application's configuration as it is. |

**What it does, in order.** Derives the name `second-brain-vault-<label>`; refuses, before anything is written, a name whose longest tool name `mcp__<server>__list_allowed_directories` passes 64 characters (a label over 14 characters), proposing the label cut to 14 (`vaultMcp.nameTooLong`, exit `1`); checks `uv` and a Python reachable through it; runs every refusal before writing anything (a `--retire` of a Vault server; a server of the same name pointing to a Vault with another identity, in which case it proposes `second-brain-vault-<label>-<8 characters>` to accept with `--label`, the label cut when the name would pass the length guard: `works-<8 characters>` for `workspaces`); writes the label into `VAULT-IDENTITY.md`; then, per tool, migrates this Vault's former names (`second-brain-vault`, the name by identity, a former label) and writes the entry `<uv> run --no-project <vault>/tools/vault-mcp.py --vault <vault> --allow <workspace>`. An entry already identical is left untouched, so a second run changes nothing. Desktop configuration folders, used only if they exist: macOS `<home>/Library/Application Support/Claude`; Windows (Git Bash) `<APPDATA>/Claude` and each `<LOCALAPPDATA>/Packages/Claude_*/LocalCache/Roaming/Claude`; elsewhere `<XDG_CONFIG_HOME, else home/.config>/Claude`.

**Exit codes and last line.** `0` at the end, with the last line `Remaining step: restart each tool detected above (the Claude app, Claude Code, Codex, Gemini CLI…) so it loads the server.` or `No tool detected (Claude app, Claude Code, Codex, Gemini CLI, Cursor, Windsurf, Cline, LM Studio): nothing to configure.` (English catalog). A tool that refuses its entry prints `the tool refused the configuration -- server not added.` and the exit stays `0`. `1` for a usage error, a missing workspace (`REFUS : espace de travail introuvable`), `uv` or Python missing, a Vault with no generated identity, a refused `--retire`, a crossed identity, or a label that could not be written.

**Reads.** `VAULT-IDENTITY.md`, `<home>/.claude.json`, `<home>/.codex/config.toml` (or `$CODEX_HOME`), the desktop configuration. **Writes.** The `workspace_label` line of `VAULT-IDENTITY.md`; the configuration of each host present. **Repository-root guard.** Targets the workspace by design: it takes the workspace root as its argument because that is where the server's allowed folder lives, and writes nothing into a repository through it ([rule on absolute paths](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)).

**Example.**

```bash
bash <workspace>/second-brain/tools/install-vault-mcp.sh <workspace> --lang EN
```

_Not executed by the documentation check._

## check-mcp-containment.sh

**Role.** Read-only check that a project and its Vault both lie under an allowed folder of that Vault's server in one tool configuration. It finds the Vault through `tools/resolve-vault.sh` (birth certificate, then the `<workspace>/VAULT-ROOT.md` marker) and the server name through `vid_server_name`, never a fixed name: another Vault's server does not count.

**Called by.** `skills/first-install/SKILL.md` (step 2, must return `VERDICT: PASS`). Tests: `tests/test-check-mcp-containment-per-vault.sh`, `tests/test-vault-mcp.sh`.

**Syntax.** `check-mcp-containment.sh <configuration> <projet>`, where `<configuration>` is a `<desktop config folder>/claude_desktop_config.json`, `<home>/.claude.json`, `<home>/.codex/config.toml` or the file of another host; `check-mcp-containment.sh --all <projet>` (Mission 242) checks every host present, each line prefixed by the host's name, `ABSENT <host>` for the others (never a FAIL), then one verdict.

**Exit codes and last line.** One `PASS <path>` or `FAIL <path> hors des dossiers autorises (...)` line for the project and the Vault, then `VERDICT: PASS` (exit `0`) or `VERDICT: FAIL` (exit `1`). Other `FAIL` lines: `projet introuvable`, `Vault non résolu`, `Vault sans identité générée`, `configuration introuvable`, `serveur <name> absent de <config>`, `serveur <name> sans dossier autorise`. A missing argument prints the usage line and exits `1` with no verdict.

**Reads.** The configuration, the project's birth certificate or marker, `VAULT-IDENTITY.md`. Needs `uv`. **Writes.** Nothing. **Repository-root guard.** Writes nothing.

**Example** (read-only):

```bash
bash <workspace>/second-brain/tools/check-mcp-containment.sh <home>/.claude.json <workspace>/<project>
```

## acceptance-harness.sh

**Role.** Runs acceptance scenarios S7 and S8, the only two allowed to call a model. It asks the three test questions of `assistant/ASSISTANT.md` (section `## Trois questions de test`, exactly three) several times and judges the answers by strings and disk state, never by a model. S7 asks the deployed assistant inside the installed clone; S8 plays the web package by equivalence (`<clone>/web-package/<slug>/INSTRUCTIONS.md` as system instructions, the files the package's README lists as documents, an empty folder, no tool). The upload gesture in a web interface is not proven.

| Question | Passes when the answer |
|---|---|
| Q1 | names session-start, SKILL.md and reading-list.md |
| Q2 | names mission-template.md, the project operating model brief V2, and "projet" or "project" |
| Q3 | refuses, and no file appeared or changed (S7: full Git status of the clone, ignored files included; S8: listing of the work folder) |

**Called by.** `tests/run-mechanical-acceptance.ps1`, which makes a test-mode installation and runs S7 and S8 with providers `claude` and `codex` and `--runs 3`: both PASS gives PASS, any FAIL gives FAIL. Test: `tests/test-acceptance-harness-oracles.sh` (stub providers, no model call).

**Syntax** (from the header):

```
acceptance-harness.sh --scenario S7|S8 --provider claude|codex|command
         --clone <installed second-brain clone> [--slug <assistant slug>]
         [--runs N] [--provider-command <executable>] [--log <file>]
```

**Options.** `--clone` must contain `.git`. `--slug` defaults to the first Markdown file under `<clone>/.claude/agents/`. `--runs` defaults to 3; a question passes only if every run passes. `--provider command` calls `<executable> <scenario> <workdir> <question-file>`, which prints the answer. `--log` appends each run's result to a file. **Exit codes and last line.** `PASS (...)` `0`; `FAIL (...)` `1` (also every usage error); `SKIP (no <provider> credentials in CI)` `2`, when the provider is missing under GitHub Actions; `INDETERMINE (...)` `3`, when the provider is not installed or answers with a quota, login or rate-limit message.

**Reads.** The clone's identity source, assistant forms and web package. **Writes.** A temporary folder, removed on exit, and the `--log` file if given. **Repository-root guard.** Writes nothing into a repository.

**Example** (a refusal, no model call; prints `FAIL (usage: --scenario S7|S8)` and exits `1`):

```bash
bash <workspace>/second-brain/tools/acceptance-harness.sh --scenario S9 --provider claude --clone <workspace>/second-brain
```

## Liens

- `source` — [Assistant generator](../../tools/generate-assistant.ps1)
- `source` — [Vault MCP server](../../tools/vault-mcp.py)
- `source` — [MCP server installer](../../tools/install-vault-mcp.sh)
- `source` — [MCP containment check](../../tools/check-mcp-containment.sh)
- `source` — [Acceptance harness](../../tools/acceptance-harness.sh)
- `source` — [Mechanical acceptance runner](../../tests/run-mechanical-acceptance.ps1)
- `source` — [Installer (Windows)](../../install.ps1)
- `source` — [Installer helper, Python twin](../../tools/sb_installer_helper.py)
- `source` — [Vault identity functions](../../tools/vault-identity.sh)
- `source` — [Vault resolution](../../tools/resolve-vault.sh)
- `source` — [Repository-root guard](../../tools/repo_root_guard.py)
- `source` — [Update tool](../../tools/second-brain-update.sh)
- `source` — [Vault identity file](../../VAULT-IDENTITY.md)
- `source` — [Assistant identity source](../../assistant/ASSISTANT.md)
- `source` — [Documentation map](../MAP.md)
- `source` — [Glossary](../../CONTEXT.md)
- `source` — [English message catalog](../../i18n/catalog.en.json)
- `source` — [first-install skill](../../skills/first-install/SKILL.md)
- `source` — [Rule: absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Test: assistant generation](../../tests/test-assistant-generation.ps1)
- `source` — [Test: MCP server](../../tests/test-vault-mcp.sh)
- `source` — [Test: MCP server name](../../tests/test-vault-mcp-server-name.sh)
- `source` — [Test: MCP refusal message](../../tests/test-vault-mcp-refusal-message.py)
- `source` — [Test: one server per Vault](../../tests/test-install-vault-mcp-name-per-vault.sh)
- `source` — [Test: workspace label](../../tests/test-install-vault-mcp-workspace-label.sh)
- `source` — [Test: containment per Vault](../../tests/test-check-mcp-containment-per-vault.sh)
- `source` — [Test: harness oracles](../../tests/test-acceptance-harness-oracles.sh)
- `see also` — [The assistant, explained](../explanation/assistant.md)
- `see also` — [Architecture](../explanation/architecture.md)
- `see also` — [Guardians and acceptance](../explanation/guardians.md)
- `see also` — [Tools: install and update](./tools-install-and-update.md)
- `see also` — [Tools: internal helpers](./tools-internal-helpers.md)
- `see also` — [Troubleshoot](../how-to/troubleshoot.md)
