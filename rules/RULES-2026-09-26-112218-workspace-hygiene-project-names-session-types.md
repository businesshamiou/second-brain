---
type: rules
title: "Workspace hygiene, project names and session types"
description: "One declared temporary folder outside the workspace; a workspace root that holds only what a computed whitelist allows, checked at every Executor opening; one trash and one archive; the Pilot Project of every project named `SB - <display name>` and checked at opening; four session types recognised by measurement; flat project folders with an optional group; the entry-scenario matrix that session-start applies first."
created_at: "2026-09-26T11:22:18-04:00"
timezone: America/Montreal
status: active
scope: workspace-hygiene, project-names, session-types, entry-scenarios
amends:
  - "./RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  - "../templates/vault-root-template.md"
---

# WORKSPACE HYGIENE, PROJECT NAMES AND SESSION TYPES

## 1. Why

The read-only audit of the workspace (Mission 233, workshop history, not distributed) found, at the root of the workspace, six entries outside the closed list then in force, three of which had come back after being tidied away; 181 leftovers of the tooling in the system temporary folder; a second workspace marker without identity that resolved an old Vault; and the name of a project written four different ways. The Owner, 2026-09-26: a temporary folder « dont le chemin est renseigné partout » ["whose path is given everywhere"], and « quelque chose de mécanique pour empêcher ce désordre » ["something mechanical to prevent this mess"]; the name of a project matched between the Pilot side and the Executor side; sessions recognised as tied to a project or not.

Four decisions of the Owner (2026-09-26 10:13) are applied as they stand:

- **D-A** — the Pilot Project of a project is named `SB - <display name>`: exact prefix `SB - `, a hyphen-minus (U+002D, ASCII) with one space on each side. **Amended by Mission 237:** the first form used a middle dot (U+00B7); it caused two encoding defects in one day and is typed by participants on Windows PowerShell 5.1, so the separator became ASCII — the decision (a fixed prefix, then the display name) is unchanged.
- **D-B** — a dedicated welcome Pilot, the Project `SB - Accueil`, tied to the Vault: it thinks about projects that do not exist yet, drafts initiation orders and handles cross-project questions.
- **D-C** — a free session is allowed, without writing: it declares itself `session libre`, may read, writes and commits nothing.
- **D-D** — project folders are flat by default, `<workspace>/<folder>`, or `<workspace>/<group>/<folder>` when the initiation order names a group.

## 2. The declared temporary folder

1. **One folder, declared.** Every throwaway file of the tooling lives under one folder, `SB_TMP`. Its default is `<system temporary folder>/second-brain` (on Windows `%TEMP%\second-brain`). It is declared once, in the workspace marker `VAULT-ROOT.md`, on the fixed-label line `Dossier temporaire déclaré : \`<path>\``, written by `tools/write-marker.sh` (and so by both installers).
2. **One access function.** [`tools/lib/tmp.sh`](../tools/lib/tmp.sh) (`sb_tmp_root`, `sb_tmp_dir <use>`, `sb_tmp_export <use>`) and its twin [`tools/lib/tmp.ps1`](../tools/lib/tmp.ps1) (`Get-SbTmpRoot`, `Get-SbTmpDir`). Order: the `SB_TMP` environment variable; the marker line, found by walking up from the Vault; the default. The folder is created when missing. One sub-folder per use: `m<NNN>` for a Mission's hand work, `tests` for the suite, `reference-clones` for the shared reference clones, `tools` for the tools' own work files, `second-brain-install` for the bootstrap clone.
3. **Never under the workspace.** A declared folder that lies below a folder carrying `VAULT-ROOT.md` is refused by the access function: a sandbox below it would walk up to the real marker and resolve the real Vault, the Pilot's MCP server would reach it, and the index builder and the link guardian would sweep it.
4. **What goes through it.** Every tool that writes a throwaway file sources the access function and gives every `mktemp` a template under `$(sb_tmp_dir tools)`; a bare `mktemp`, or one under `${TMPDIR:-/tmp}`, is not written any more. `tools/build-digest.sh` is a named exception: its `mktemp` is an atomic rewrite inside the project's own `state/` folder, not a throwaway file. `tests/run-suite.sh` and `tests/run-suite.ps1` export the `tests` sub-folder for every test they play. Named exceptions: `bootstrap.sh` and `bootstrap.ps1` run before any Vault exists on the machine and cannot load the function; they apply the same rule inline (`$SB_TMP`, else `<system temporary folder>/second-brain`, sub-folder `second-brain-install`). `tests/test-declared-temp-folder.sh` holds the line.
5. **Leftovers.** What the tooling left in the system temporary folder before this rule stays where it is: emptying it is an Owner gesture. A dated inventory gives it a way out.

## 3. The workspace root: a computed whitelist

The root of the workspace holds only what the following list allows. The list is **computed**, never copied by hand, so that a new project never "misses" from it:

1. `VAULT-ROOT.md`, and the two workspace guides `CLAUDE.md` and `AGENTS.md` that `tools/write-marker.sh` writes next to it (Mission 235) — they route any session opened at the root to the entry matrix before its answer (§8);
2. the Vault, at the path the marker names;
3. the first segment of every `relative_path` of the [project registry](../projects/PROJECT-REGISTRY.md): the projects, and the group folders (§6). A group folder holds only registered projects; anything else inside it is a gap;
4. the organs declared by the marker's line `Organes déclarés à cette racine : \`<name> …\`` (`-` for none) — in the laboratory, `m-publish`, the publication worktree that `tools/publish-from-laboratory.sh` writes;
5. `_trash`, `_archive` and `_orders` (§5), one of each;
6. the declared temporary folder, only if an Owner put it there against §2.3 (it is then reported);
7. nothing else.

A folder the Owner has not settled yet is named on the marker's line `Exceptions provisoires à cette racine : \`<name> …\``: it is reported as a **provisional exception**, not as a gap. The line is written by `tools/write-marker.sh --exceptions`, and kept when the marker is regenerated.

[`tools/check-workspace-root.sh`](../tools/check-workspace-root.sh) compares the root with the list: `ÉCART: <name> — <reason>` for everything else, `EXCEPTION-PROVISOIRE: <name>` for the named ones, then one verdict line. It is called by the Executor's session preflight as a **warning**, never a block, and by `session-start` in the Executor branch.

This rule **replaces** the closed list of eleven entries of Decision 180611 B (workshop history, not distributed).

## 4. One trash, one archive

- **Trash:** `<workspace>/_trash/<NNN>-<slug>/` (or `<date>-<slug>/`), one sub-folder per Mission or per gesture. It is the zone of [Decision 110852](../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md): the Owner alone empties it.
- **Archive:** `<workspace>/_archive/<NNN>-<slug>/`: what must be kept as proof (Git bundles, retention of an audit) and is never emptied without the Owner.
- **No trash inside a repository.** A `_trash` found inside a project is moved to `<workspace>/_trash/<NNN>-<project>/`.
- **Tidying is moving**, on the same volume, with a manifest `<workspace>/_trash/<NNN>-<slug>/MOVES.md` in the Mission's trash sub-folder: one line per move, source, destination, inverse command. Nothing is deleted.

## 5. Project names and the identity card

1. **The registry carries the display name** the Owner wants. The project's `README.md` copies it on its title line. The `project_id` never changes.
2. **The Pilot Project is named `SB - <display name>`** (D-A). The project's `<project>/state/PILOT-PROMPT.md` carries it in the key `pilot_project_name`; `tools/project-bootstrap.sh create`, `adopt` and `prompt` write it, and the block printed at the end of `create` says « Create a Project named "SB - <Name>" ».
3. **The identity card.** `tools/project-bootstrap.sh identity <folder>` prints the folder, the group, the display name, the `project_id`, the registry line, the canary and the expected Pilot Project name. `identity --check` compares the certificate, the registry and the Pilot prompt, and names every mismatch `ANOMALY`.
4. **Checks at opening.**
   - **Executor:** the current folder, the birth certificate and the registry line agree (`identity --check`); a mismatch is an `ANOMALY`, reported, not blocking.
   - **Pilot:** when the surface shows the name of the Project the conversation belongs to, it is compared with `pilot_project_name`; a mismatch is `ANOMALY (nom du Project)`, never blocking; a surface that does not show it gives `DECLARED`. The instruction lives in [`skills/session-start/SKILL.md`](../skills/session-start/SKILL.md), read from disk: the Owner pastes nothing new.

## 6. Folders: flat by default, optional group

`tools/project-bootstrap.sh create <workspace>/<folder> <name> --group <group>` creates `<workspace>/<group>/<folder>`; an initiation order carries the same thing in its optional field `Groupe`. The group is refused when it is itself a project (registered, or carrying a birth certificate or a `.git`), when it carries `VAULT-ROOT.md`, when it is not a single folder name, or when it would lie outside the workspace.

## 7. Four session types

A session recognises its type **by measurement**, before any gesture:

| Type | Measured by | May write |
|---|---|---|
| **project** | a project path in the first message, or a birth certificate found walking up from the current folder | yes, by its role |
| **welcome** (`accueil`) | the Project `SB - Accueil`, a first message that names the Vault or the workspace root, no project path | one gesture only: an initiation order in `<workspace>/_orders/`, with the Owner's agreement |
| **free** (`libre`) | no path, no Mission, no order | nothing: it declares `session libre`, reads, writes and commits nothing (D-C) |
| **Vault** | a window opened in the Vault itself: the Vault's role hook | by the role the hook injects |

The welcome Pilot's instructions are [`templates/accueil-pilot-prompt-template.md`](../templates/accueil-pilot-prompt-template.md); `tools/project-bootstrap.sh accueil-prompt` prints the block to paste. Its order is written in `<workspace>/_orders/ORDER-<YYYY-MM-DD-HHMMSS>-<slug>.md` and relayed to an Executor by an `initiation` mini-prompt; once executed, the Executor moves it to `<workspace>/_archive/orders/`. The free session's text is [`templates/free-session-prompt-template.md`](../templates/free-session-prompt-template.md).

## 8. Entry scenarios

Every way of starting — an Executor or a Pilot first, in an adopted folder or not, with or without an order, at the workspace root, in the Vault, under Codex, a welcome or a free session, a first installation — has its line in the matrix at the head of [`skills/session-start/SKILL.md`](../skills/session-start/SKILL.md): what is measured, the prescribed gesture, the prompt to use, the tool called, and the test that proves it. The agent identifies its line before any gesture. The guide [Start something new](../docs/how-to/start-something-new.md) follows the same matrix.

## Liens

- `amends` — [Role charter and session determination](./RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `amends` — [Template — working-root marker](../templates/vault-root-template.md)
- `applies` — [Decision — Permanent deletion is an Owner gesture](../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
- `see also` — [Absolute repository paths and verified pushes](./RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `see also` — [Decision — Project initiation and adoption, birth certificate](../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `see also` — [Project structure standard](./RULES-2026-08-26-142800-project-structure-standard.md)
- `amended by` — [Rule — The sb command surface](./RULES-2026-09-26-200933-sb-command-surface.md) (`sb status`, `sb clean` and `sb doctor` read the whitelist and the identity card; `sb help scenarios` renders the entry matrix)
