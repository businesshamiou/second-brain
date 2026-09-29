---
type: rules
title: "The sb command surface"
description: "One command, `sb`, carries every operation of Second Brain: a real terminal program shipped by the Vault, grammar `sb <verb> [arguments]`, English verbs, one verb per operation, a place check before any gesture, fixed exit codes; Claude Code, Codex, the Pilot and any other agent only relay it, under a prefix that no native command uses."
created_at: "2026-09-26T20:09:33-04:00"
timezone: America/Montreal
status: active
scope: command-surface, sb, verbs, help, surfaces
amends:
  - "./RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  - "./RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md"
---

# THE SB COMMAND SURFACE

## 1. Why

Until this rule, an operation of Second Brain had several names: a skill triggered by a phrase (« ouvre la session », « nouvelle session pilote », "open the session"), a script under `tools/` with its own usage line, a how-to guide, and two skills named in French. Each tool (Claude Code, Codex, the Claude application) offered its own way in, and the Owner had to know which one applied where. The Owner, 2026-09-26: « un système qui marche d'une façon standard » ["a system that works one standard way"], « je ne veux pas mille façons » ["I do not want a thousand ways"], commands in English because they are system commands, independent of the model and of the interface, reachable from any terminal, recognised by the Vault, distinct from the native commands of every tool, and a help « digne de son nom » ["worthy of the name"]. The read-only audit of Mission 236 (workshop history, not distributed) measured the ground this rule stands on: 21 operations, each tied to an existing skill, tool or guide; no executable named `sb` on the three systems; a Codex skill budget at 7,957 of 8,000 characters.

## 2. Proven references

The rule copies systems used for years rather than inventing one:

- **Git** separates a small set of stable user-facing commands (the "porcelain") from the internal tools (the "plumbing"): <https://git-scm.com/docs/git>. Here, the verbs of `sb` are the porcelain; the scripts of `tools/` stay the plumbing, still callable, never required.
- **Command Line Interface Guidelines**: short lower-case names, the same verbs everywhere, never two names that can be confused (`update` and `upgrade`), help always one command away: <https://clig.dev/>.
- **GitHub CLI**: one program, a small set of verbs reused across objects: <https://cli.github.com/manual/gh>.
- **`brew doctor`, `flutter doctor`**: one command that checks everything and says what to do.
- **Claude Code** skills and commands, and the naming of skills (lower case, hyphens, consistent forms): <https://code.claude.com/docs/en/slash-commands>, and the Agent Skills best practices of the Claude Platform documentation (platform.claude.com, section « Agent Skills », page « Best practices »).

## 3. One source: the `sb` program

1. `sb` is a real terminal program shipped by the Vault: `tools/sb/sb.py`, launched by `tools/sb/bin/sb` (Git Bash, macOS, Linux) and `tools/sb/bin/sb.cmd` (PowerShell and `cmd` on Windows — no PowerShell script launcher, so a machine whose execution policy blocks scripts still runs it). It works without any model.
2. The installers put `tools/sb/bin` on the user's `PATH` through the primitive they already use for Git, `uv` and `pre-commit` (Windows: the user `Path` variable; macOS and Linux: a marked block in the profile script of the home folder). `sb install --path` does the same on a machine installed before this rule.
3. Grammar: `sb <verb> [arguments]`, like `git` or `gh`. `sb`, `sb help` and `sb --help` show the welcome screen; `sb help <verb>` the page of one verb; `sb --version` the version.
4. Every verb calls what already exists — a tool of `tools/`, a skill, a guide — and never rewrites it. The verbs with no former equivalent (`status`, `help`, `list`, `pilot-prompt`, `handoff`, `clean`, `doctor`) assemble existing pieces.
5. The single source of the catalogue is `tools/sb/verbs.json` (group, usage, place, nature, what the verb is built on, the former phrasings) and the `sb.*` keys of `i18n/catalog.fr.json`, `i18n/catalog.en.json` and `i18n/catalog.es.json` (every text of the help). `docs/reference/commands.md`, `docs/COMMANDS-CARD.md` and the Claude Code plugin are generated from them by `sb.py generate`; a test refuses a generated file that no longer matches its source.

## 4. The catalogue

Twenty-one verbs in five groups. Adding, renaming or removing a verb is a Mission; the catalogue is a starting point that use will improve.

| Group | Verb | Operation | Built on |
|---|---|---|---|
| Sessions | `open` | open a session: measure, then the READY / NOT-READY verdict | skill `session-start`, `tools/session-preflight.sh`, `project-bootstrap.sh identity --check`, `check-workspace-root.sh` |
| Sessions | `close` | close a session: journal, state sheet, digest, closing commit | skill `session-close` |
| Sessions | `handoff` | write a handoff for the next session, without closing | `templates/handoff-template.md` |
| Sessions | `status` | where you are, what is pending, what to do next | marker, `resolve-vault.sh`, Git, the state sheet |
| Sessions | `help` | the welcome screen, one page per verb, three guides | the `sb.*` catalogue keys |
| Projects | `new` | create a project | `project-bootstrap.sh create` / `--order` |
| Projects | `adopt` | adopt an existing folder | `project-bootstrap.sh adopt` |
| Projects | `list` | the projects this Second Brain knows | `projects/PROJECT-REGISTRY.md` |
| Projects | `pilot-prompt` | the block to paste in a project's Pilot Project | `<project>/state/PILOT-PROMPT.md`, the common trunk, `project-bootstrap.sh prompt` |
| Work | `mission` | write a Mission (Pilot) | skill `mission-writing` |
| Work | `run` | carry out a Mission (Executor) | skill `session-start`, the Mission |
| Work | `relay` | read the RELAY block of a report | `<project>/reports/REPORT-*.md` |
| Work | `push` | push a range, verified | `tools/verified-push.sh` |
| Work | `search` | find a document, a rule, a term | skill `internal-search`, `tools/find-in-vault.sh` |
| Maintenance | `doctor` | check everything, explain a refusal | the guardians, `check-project-conformity.sh`, the refusal tables of the guides |
| Maintenance | `clean` | what clutters the workspace root and the temporary folder, and where it should go; `--purge-temp` empties the temporary folder on the Owner's word | `check-workspace-root.sh`, `tools/lib/tmp.sh` |
| Maintenance | `update` | bring the Vault to a published version | skill `update` and the update script it runs |
| Maintenance | `install` | the last steps of an installation, each one if needed: `sb` on the `PATH`, the Claude Code marketplace, the plugin; `--run` repairs the installation | skill `first-install`, `install.ps1` / `install.sh`, `claude plugin` |
| Maintenance | `uninstall` | what to remove, and how | `docs/how-to/uninstall.md`, `remove-profile-links.ps1` |
| Maintenance | `add-skill` | check a new skill and its effect on the Codex budget | `docs/how-to/add-a-skill.md`, `sb_installer_helper.py` |
| Owner only | `publish` | publish a version from the laboratory | `publish-from-laboratory.sh` |

The tools with no verb (`build-indexes.sh`, `build-state.sh`, `append-journal.sh`, the guardians (`tools/check-links.sh` and its siblings), `publish-tag.sh`, `vault-identity.sh`, `write-marker.sh`, …) are plumbing: they keep their names and their sheets in `docs/reference/`.

## 5. One operation, one verb

- An operation has one verb and one only; a verb does one operation. `update` exists, `upgrade` never will.
- The former phrasings lead to the same verb: « ouvre la session », « nouvelle session », « nouvelle session pilote » and "open the session" are `sb open`; « wrap », « clôture » are `sb close`; « écris la Mission » is `sb mission`; « où est », « trouve » are `sb search`. The page of each verb lists them under "Also recognised"; the skills keep them as trigger phrases.
- Verbs are English and never translated; the help is written in the participant's language (French, English or Spanish: `SB_LANG`, else `USER.local.yaml`, else the `language:` of `USER.md`, else the system's language, else English).

## 6. Where a verb runs — checked first

Every verb measures where it runs before any gesture, and refuses elsewhere by naming the right place:

| Place | Meaning |
|---|---|
| `anywhere` | no condition |
| `workspace` | inside the workspace of this Vault (the folder that carries `VAULT-ROOT.md`) |
| `project` | inside an adopted project (a birth certificate found walking up), never the workspace root |
| `project-or-vault` | an adopted project, or the Vault itself |
| `adoptable` | a folder of the workspace that is neither its root nor the Vault |
| `vault` | inside the Vault |
| `repository` | inside a Git repository of the workspace |
| `laboratory` | the laboratory Vault (it has a `release` remote) |

The nature of a verb says who carries it out: **tool** (the terminal does it all), **agent** (reading and judgement belong to an agent: in a terminal, `sb` shows what it can measure and the card the agent applies, then says where to type the verb) or **tool+agent**. A verb of nature agent or tool+agent that the Pilot can apply without a shell (`help`, `status`, `list`, `relay`, `mission`, `pilot-prompt`) is applied by reading its card; any other verb, asked of the Pilot, is refused with the words "this verb needs a shell: type it in an Executor window".

## 7. Exit codes

| Code | Meaning |
|---|---|
| 0 | done (or the card of an agent verb shown) |
| 1 | the underlying tool refused or failed — its own message is shown as is |
| 2 | usage: unknown verb, missing or extra argument |
| 3 | wrong place: the refusal names where the verb runs |
| 4 | not allowed here: an Owner-only verb outside the laboratory |

A refusal is one line that starts with the word for "refused" in the participant's language, then the reason, then where to go.

## 8. The surfaces relay, they never duplicate

| Surface | How it reaches `sb` |
|---|---|
| Any terminal | `sb <verb>` |
| Claude Code | the plugin `sb` (`skills/claude-plugins/sb/`, marketplace `second-brain` at `skills/claude-plugins/`): one thin skill per verb, `/sb:<verb>`, invoked by the user only (`disable-model-invocation: true`, so nothing enters the model's context until it is used); each one runs `sb <verb>` and applies the card |
| Codex | a single router skill `skills/sb/` (`$sb <verb>`), linked like every method skill; a single skill because of the 8,000-character budget of the initial skills list |
| The Pilot (Claude application) | one sentence of the common trunk: a message that starts with `sb ` is a Second Brain command; the Pilot applies the card of `docs/reference/commands.md` or refuses a verb that needs a shell |
| Any other agent | one sentence in the `CLAUDE.md` and `AGENTS.md` of the Vault and of the workspace: "A message that starts with `sb ` is a Second Brain command: run it, or, without a shell, apply its card in `docs/reference/commands.md`." |

Installing the plugin writes into the user's Claude Code settings: it is a gesture of the participant — `sb install` (Mission 237) runs `claude plugin marketplace add <Vault>/skills/claude-plugins` and `claude plugin install sb@second-brain` for them, each only if needed — never of the installer, which writes nothing into the profile (Decision Q17 of Mission 173). Claude Code installs a **copy** of the plugin in its cache (measured, Mission 237): when the Vault's plugin changes, `sb doctor` says the copy is behind and `sb install` reinstalls it.

## 9. No collision

- The name `sb` and every verb are checked against the documented native commands of Claude Code, Codex CLI and Gemini CLI, kept with their sources in `tools/sb/native-commands.tsv`, and against the executables named `sb` on the three systems. A test refuses a native command named `sb` or starting with `sb:`.
- Measured on 2026-09-26: no collision. The bare names `help`, `status`, `doctor`, `run` and `new` exist natively in some tools, which is why a verb is always typed with its prefix (`sb status`, `/sb:status`, `$sb status`), never bare. The npm package `sb` is the Storybook command-line alias: installed on the `PATH` only by an explicit `npm install -g sb`; `sb doctor` checks that `sb` resolves to this Vault.
- A proven collision on the name `sb` is a Mission: another short name is chosen and the rule amended.

## 10. Skill names

The method's skills are named in English, lower case, with hyphens, in the forms of the collection (`session-start`, `project-bootstrap`, `update`). The two French names are replaced: `ecriture-de-mission` becomes `mission-writing`, `recherche-interne` becomes `internal-search`; their French trigger phrases stay in their descriptions. A project receives the new links from its tool (`sb adopt` on an adopted project, which runs `project-bootstrap.sh adopt`), never by hand; a link left behind under the former name points nowhere and is reported by `sb doctor`, never deleted by a tool.

## 11. What `sb` never does

`sb` never calls a model, never forces a push, and never pushes on its own initiative: `sb push` is the Owner's command, or an Executor's under a delegation measured as the relay rule says. It deletes one thing only, on the Owner's word: `sb clean --purge-temp` empties the declared temporary folder, after a confirmation (`--yes` to skip it) — permanent deletion is the Owner's gesture ([Decision 110852](../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)), run here by the Owner's own command; it never touches `_trash` nor `_archive`, and an agent never runs it on its own initiative. It writes into the user's profile only what `sb install` is asked for: the `PATH` entry and Claude Code's plugin settings. Paths are shown in the form of the terminal: drive letter and backslashes in PowerShell and `cmd`, a leading slash and the drive in lower case in Git Bash. Amended by Mission 237.

## Liens

- `amends` — [Role charter and session determination](./RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `amends` — [Rule — Workspace hygiene, project names and session types](./RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
- `see also` — [Absolute repository paths and verified pushes](./RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `see also` — [Relay between roles through mini-prompts](./RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Decision — Permanent deletion is an Owner gesture](../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
- `see also` — [Command reference](../docs/reference/commands.md)
- `see also` — [Command card](../docs/COMMANDS-CARD.md)
- `see also` — [Skills](../docs/reference/skills.md)
