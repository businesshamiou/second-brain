---
type: reference
title: "Project tools"
description: "Script sheets for the four tools that create, adopt and measure projects, mark the workspace and identify the Vault, plus the birth certificate they write and read."
status: active
---

# PROJECT TOOLS

One sheet per script. `<workspace>` is the absolute path of your workspace (for example C:/Users/you/Workspaces), the installed Vault is `<workspace>/second-brain`, a project is `<workspace>/<project>`. Most refusal messages are printed in French, as the code writes them; the `REPO-ROOT-REFUSED` and `BASELINE-DIRTY-TREE` lines are in English.

**Under Windows.** A `bash …/tools/…` line of this page, typed in PowerShell where `bash` is unknown, starts with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`; where an `sb` verb carries the same gesture ([Commands](commands.md)), type the verb. `sb doctor` says whether `bash` is on your PATH.

## project-bootstrap.sh

**Role.** Makes a project aware of the Vault. `create` builds a new project in the seven-function layout; `adopt` writes only what is missing in an existing folder, records a dated baseline and proposes a reorganisation it never applies; `order` prints an initiation order to fill in and writes nothing; `prompt` regenerates the Pilot prompt of an adopted project, taking the display name from the registry; `identity` prints the identity card of a project (folder, group, display name, `project_id`, registry row, canary, expected Pilot Project `SB - <display name>`); `accueil-prompt` prints the block that creates the welcome Pilot Project `SB - Accueil` (Mission 234); `sb pilot-prompt --accueil` calls it and frames the block with the steps in the reader's language (Mission 241). The Pilot prompt carries `pilot_project_name`, and the final block of `create` says « Create a Project named "SB - <Name>" ».

**Called by.** `install.sh` and `install.ps1` (first project, historical call without subcommand); `skills/project-bootstrap/SKILL.md` (`create`, `adopt`, `--order`); `skills/session-start/SKILL.md` (`--order`, `order`); `templates/initiation-order-template.md`; tests under `tests/`.

**Syntax** (the usage the script prints):

```
project-bootstrap.sh [create|adopt] <chemin-cible> <display_name> [langue FR|EN|ES] [--vcs none|git] [--ask] [--git]
project-bootstrap.sh --order <fichier-ordre> [langue]
project-bootstrap.sh order <dossier> [langue]
project-bootstrap.sh prompt <dossier> [--state-path <chemin relatif>]
project-bootstrap.sh identity <dossier> [--check]
project-bootstrap.sh accueil-prompt
project-bootstrap.sh create <espace>/<dossier> <display_name> --group <groupe> ...
```

Without a subcommand, the call is the installers' historical `create`: Git is chosen unless `--vcs` says otherwise, and the final report is not printed. `adopt <target> <language>` is accepted: at adoption the display name is optional and defaults to the folder name.

**Options.**

| Option | Effect |
|---|---|
| `--vcs none\|git` or `--vcs=<value>` | `git`: creates the repository if missing, sets a local Git identity if none resolves, runs `pre-commit install`. `none`: no repository, no hook. Other value: `REFUS : vcs doit valoir none ou git`. |
| `--git` | Answers the Git question with `git`. On a project already adopted with `vcs: none`, switches it to `git`: certificate line, project sheet and registry row are rewritten, repository and hook added. |
| `--ask` | Asks name and location on standard input before writing; Enter keeps the proposal. The Git question follows the rule below. Then the three questions of the project interview (Mission 240): expected result, current blocker, review rhythm, one at a time, Enter leaving one empty (only those the order does not already carry). |
| `--lang FR\|EN\|ES` | Same as the positional language: chooses the catalogue of the messages. The project's own language comes from `<workspace>/second-brain/USER.local.yaml`, then `USER.md`, then a language named on the command line. |
| `--order <file>` | Reads an initiation order: `Type`, `Mode`, `Nom`, `Emplacement`, `Vault + construction`, `Git`, `Objet`, `Autorisation Owner datée`, optional `Arbre sale`, `Groupe`, and the three optional fields of the project profile `Résultat attendu`, `Blocage actuel`, `Rythme de revue` (absent, `-` or a placeholder: nothing is written). |
| `--state-path <path>` | `prompt` only: the state sheet the prompt points to; relative to the project, no `..`, an existing file. Default: the value the prompt carries, else `<project>/state/STATE.md`. |
| `--group <group>` | `create` only (also the order's optional `Groupe` field, which the option overrides): the project is created in `<workspace>/<group>/<folder>` instead of `<workspace>/<folder>`, and registered with the path `<group>/<folder>`. Refused before any write when the group is a project (registered, or carrying a birth certificate or a `.git`), carries `VAULT-ROOT.md`, is not a single folder name, lies outside a workspace, or comes with `adopt` (Mission 234). |
| `--check` | `identity` only: compares the birth certificate, the registry row, the Pilot prompt (`project_id`, `pilot_project_name`) and the README title, and prints one `ANOMALY: …` line per mismatch, then `IDENTITY: CONCORDANT` (exit 0) or `IDENTITY: <n> ANOMALY` (exit 1). |

When nothing gives Git (no `--vcs`, no `--git`, no `Git` field) and a subcommand or `--order` was used, the Git question is asked (default `git` if the folder has a `.git`, else `none`).

**Exit codes and last line.**

| Code | When | Last line |
|---|---|---|
| 0 | `create`, `adopt`, `--order`, historical call | absolute path of the project sheet, `<workspace>/second-brain/projects/PROJECT-<project_id>.md` |
| 0 | `order` | the order and its closing note; nothing written |
| 0 | `prompt` | `PILOT-PROMPT regenere : <path> (serveur …, commit …, fiche …, langue …)` |
| 1 | any refusal; those on the arguments, the target path, the order and a dirty tree come before any write | the refusal, on standard error |

Main refusals: `REFUS : chemin cible non absolu`; `REFUS : chemin cible a l'interieur du depot Vault`; `REPO-ROOT-REFUSED: …` (the target is a workspace root); `REFUS : la cible existe deja` (`create`); `REFUS : la cible a adopter n'existe pas (mode create)` (`adopt`); `BASELINE-DIRTY-TREE : …` (`adopt` on a Git tree with uncommitted changes, unless the order carries `Arbre sale : accepté — <raison>`); `REFUS : chemin deja inscrit au registre` (`create`); `REFUS : l'ordre nomme le Vault …, ce Vault est …`; `REFUS : ordre d'initiation sans autorisation Owner datée (AAAA-MM-JJ)`; a missing workspace marker. `prompt` refuses a project that has no Pilot prompt (`le projet n'est pas adopte (adopt d'abord)`) and a Vault without a generated identity.

**Reads.** `VAULT-IDENTITY.md`, `USER.md`, the `i18n/` catalogues, its templates under `templates/`, the marker `<workspace>/VAULT-ROOT.md` (found by walking up from the target's parent), the order file, and the project's existing `<project>/.pre-commit-config.yaml`, `<project>/.gitignore` and Pilot prompt.

**Writes.** In the project (`create`: all; `adopt`: only what is missing, never an existing file):

- the seven folders `rules`, `state`, `missions`, `decisions`, `proposals`, `knowledge`, `handoffs`, `<project>/README.md` and `<project>/missions/MISSION-INDEX.md` (`create` only);
- when at least one of the three profile answers is given (order or `--ask`): the section `## Profil du projet` of `<project>/README.md`, through `tools/starting_profile.py` — at adoption an existing README gains the section, an existing section is kept, a folder without README gets one carrying its title and the section; the report says `Profil du projet écrit …` or `… déjà présent, laissé tel quel`;
- `<project>/.pre-commit-config.yaml` with the birth certificate (below); at adoption, the baseline `<project>/.vault-baseline-<stamp>.tsv`;
- `<project>/CLAUDE.md` and `<project>/AGENTS.md` pointing to the Vault, `<project>/.gitignore` with three link lines, `<project>/state/PILOT-PROMPT.md`;
- `<project>/state/journal.md` (birth entry through `tools/append-journal.sh`), `<project>/state/STATE.md` and `<project>/state/DIGEST.md` (through `tools/build-state.sh` and `tools/build-digest.sh`), the missing indexes (through `tools/build-indexes.sh`);
- with `vcs: git`: the repository, a local Git identity if none resolves, the pre-commit hook;
- the links `<project>/.claude/skills/`, `<project>/.claude/agents/`, `<project>/.agents/skills/` (through `tools/sb_installer_helper.py`), each folder with its own `.gitignore` naming its links (Mission 231); a folder whose `.gitignore` is the project's own gets no link.

In the Vault: `VAULT-IDENTITY.md` if it is still the skeleton, a row in `projects/PROJECT-REGISTRY.md`, the project sheet, and the Vault's indexes. `project_id` is the date plus up to three words of the display name in capitals (`My notes` gives `<date>-MY-NOTES`).

At adoption, an existing `<project>/.pre-commit-config.yaml` without certificate is replaced only when it holds nothing but Vault guardian lines; the old one is kept as `<project>/.pre-commit-config.yaml.before-adopt-<date>`. Any other config is left alone and the certificate lines to add are printed.

**Repository-root guard.** Carried by every form that writes a project (`create`, `adopt`, `--order`, the historical call): after the path checks and before any write, `tools/repo_root_guard.py` runs in its `--new-project` mode and refuses a target that is itself a workspace root (it carries the marker, or holds two or more Git repositories without being one). `order` writes nothing and does not run it. `prompt` runs the guard in its default mode, before it reads the Pilot prompt: walking up from the project folder, a `.git` or a birth certificate must be found before any workspace root; otherwise `REPO-ROOT-REFUSED: … is not inside a repository …` (a workspace root was reached) or `REPO-ROOT-REFUSED: … is in no Git repository and carries no birth certificate …` (the filesystem root was reached), and nothing is written.

**Example.** Print the order for a folder (nothing written), then see a refusal (exit code 1, `REPO-ROOT-REFUSED: … is a workspace root …`):

```
bash <workspace>/second-brain/tools/project-bootstrap.sh order <workspace>/my-notes
bash <workspace>/second-brain/tools/project-bootstrap.sh create <workspace> "My notes" --vcs none
```

A creation, then an adoption:

```
bash <workspace>/second-brain/tools/project-bootstrap.sh create <workspace>/my-notes "My notes" --vcs git --lang EN
bash <workspace>/second-brain/tools/project-bootstrap.sh adopt <workspace>/old-project --vcs none
```

_Not executed by the documentation check._

## The birth certificate

`tools/project-bootstrap.sh` writes it as the comment block at the top of `<project>/.pre-commit-config.yaml`, in this order, followed by the guardian pin:

```
# second-brain-birth-certificate: v1
# vault_id: <vault_id of the Vault, sb-...>
# vault_origin: <remote URL of the Vault clone, or its folder path>
# vault_ref: <Vault commit (git rev-parse HEAD), or unknown without Git>
# vcs: <none | git>
# baseline: .vault-baseline-<YYYY-MM-DD-HHMMSS>.tsv
repos:
  - repo: local
    hooks:
      - id: vault-check-secrets
      ...
```

| Key | Written | Meaning |
|---|---|---|
| first line | always | marks the file as a certificate, version `v1` |
| `vault_id`, `vault_origin` | always | copied from `VAULT-IDENTITY.md`; a certificate naming another `vault_id` is refused by the Vault resolution |
| `vault_ref` | always | the Vault commit the project was born from |
| `vcs` | always | `none` or `git`; `adopt --git` turns `none` into `git` |
| `baseline` | adoption only | the file listing what existed before adoption |

The pin is `repo: local` with four hooks, `vault-check-secrets`, `vault-check-indexes-fresh`, `vault-check-index-weight`, `vault-check-links`; each entry is `<relative path to the Vault>/tools/check-<name>.sh`, with `language: script`, `always_run: true`, `pass_filenames: false`. The certificate is read by `tools/resolve-vault.sh` (which Vault serves the project), by `tools/check-project-conformity.sh`, and by the repository-root guard, which admits a project without Git when it carries one. The guardians also read an optional `# exempt:` key, which the bootstrap never writes. `tools/verified-push.sh` reads an optional `# push_url:` key (Mission 231): the address the repository's remote must push to, so that its push needs no `--url`; the bootstrap never writes it either, the owner of the repository adds it.

## starting_profile.py

**Role.** The only writer of the two profiles of the starting interview (Mission 240, [Decision — the starting interview](../../decisions/DECISION-2026-09-27-213059-starting-interview-owner-and-project-profiles.md)): the section `## Profil de départ` of the installed Vault's `USER.md` (the Owner) and the section `## Profil du projet` of a project's `README.md`. It rewrites the section it owns and no other line, and keeps the file's byte-order mark and line ends.

**Called by.** `tools/sb/sb.py` (`sb profile`, `sb profile --order`); `tools/project-bootstrap.sh` (`project-write`, at creation and adoption). Test: `tests/test-starting-profile.sh`.

**Syntax.**

```
uv run --no-project tools/starting_profile.py owner-show <USER.md>
uv run --no-project tools/starting_profile.py owner-apply <order file> <USER.md> --archive <folder> [--today YYYY-MM-DD]
uv run --no-project tools/starting_profile.py project-write <README.md> [--result T] [--blocker T] [--cadence T] [--title NAME] [--today YYYY-MM-DD]
```

**Exit codes and last line.**

| Exit | Last line | When |
|---|---|---|
| 0 | `OWNER-PROFILE PRESENT missing=<n>` or `OWNER-PROFILE ABSENT missing=5` | `owner-show`; the line before names the missing fields (`MISSING …`) |
| 0 | `OWNER-PROFILE-WRITTEN` | `owner-apply`: section written, order moved to the archive folder (`ARCHIVED <path>`), fields the order left out kept (`KEPT …`) |
| 0 | `PROJECT-PROFILE-WRITTEN`, `PROJECT-PROFILE-KEPT`, `PROJECT-PROFILE-NONE` | `project-write`: section written; already there, kept; no answer, nothing written |
| 1 | `REFUSED <reason>` | order missing; `USER.md` is the distributed skeleton (`status: template`); no `Autorisation Owner datée` with a date; no profile field; the archive already holds the order's name (nothing written, nothing moved) |
| 2 | usage | unknown command or missing argument |

**Reads.** The order (fields by exact name followed by a colon, as `project-bootstrap.sh --order`); `USER.md`; the project's `README.md`.

**Writes.** The one section, in `USER.md` or `README.md` (inserted before `## Liens`, or at the end); `owner-apply` moves the order into `--archive` (`<workspace>/_archive/orders/` from `sb profile`), never deletes it; `project-write` creates a README carrying `# <title>`, the section and `## Liens` when the file is absent.

**Example.**

```
uv run --no-project <workspace>/second-brain/tools/starting_profile.py owner-show <workspace>/second-brain/USER.md
```

_Not executed by the documentation check._

## check-project-conformity.sh

**Role.** Measures a project against the structure standard and the Vault-awareness contract. Never blocks, never fixes.

**Called by.** `tools/project-bootstrap.sh` (the `conformity` value of the registry row and sheet); `skills/project-bootstrap/SKILL.md`; tests under `tests/`.

**Syntax.** `check-project-conformity.sh [chemin-projet]` (default: the current folder; pass the absolute path). **Options.** None.

**Exit codes and last line.** 0 with `CONFORME`, or 0 with `ÉCART: <gap1, gap2, ...>`. 1 when the measurement fails: `REFUS : chemin de projet introuvable`, or `REFUS : <cause>` when the Vault is not resolved.

**Checks.** The seven folders and `README.md`; the registry row (matched on its path column); the certificate with `vault_id`, `vault_origin`, `vault_ref`, a valid `vcs` and, if named, the baseline file; the `repo: local` pin with its four ids and an entry leading to the resolved Vault; with `vcs: git`, the repository and the pre-commit hook; `CLAUDE.md` and `AGENTS.md` present, each with a path to the Vault (its `CLAUDE.md`, `AGENTS.md` or role charter) that is the certificate's Vault. Since Mission 231: a `<project>/.claude/hooks/preflight-hook.sh` that is not the Vault's launcher `skills/project-bootstrap/preflight-launcher.sh` (line endings ignored) — an older copy of the checks — and a `<project>/.claude/settings.json` that calls that hook with a matcher leaving out `PowerShell`. A project without the hook is not reported.

**Reads.** The project, `projects/PROJECT-REGISTRY.md` of the resolved Vault, `<workspace>/VAULT-ROOT.md`. **Writes.** Nothing. **Repository-root guard.** Not carried: it writes nothing.

**Example.**

```
bash <workspace>/second-brain/tools/check-project-conformity.sh <workspace>/<project>
```

## write-marker.sh

**Role.** Writes the workspace marker `<workspace>/VAULT-ROOT.md` from `templates/vault-root-template.md` (Vault name, relative path to the Vault, `vault_id`, `vault_origin`), and by default `<workspace>/CLAUDE.md` and `<workspace>/AGENTS.md`.

**Called by.** `install.sh` and `install.ps1` (marker step); `skills/first-install/install-checklist.md`; tests under `tests/`.

**Syntax.** `write-marker.sh [--marker-only] [--tmp <path>] [--organs "<name> ..."] [--exceptions "<name> ..."] <racine-de-travail> [nom-du-vault]` (Vault name default: `Brian`). **Options.** `--marker-only`: writes the marker and nothing else, so a folder's own `CLAUDE.md` and `AGENTS.md` are left alone. Mission 234: `--tmp` sets the line `Dossier temporaire déclaré` (default: the value the marker already carries, else `SB_TMP`, else `<system temporary folder>/second-brain`; refused below the working root); `--organs` and `--exceptions` set the lines `Organes déclarés à cette racine` and `Exceptions provisoires à cette racine` read by `tools/check-workspace-root.sh` (default: the values the marker already carries, else `-`).

**Exit codes and last line.** 0, last line the absolute path of the marker. 1 with the usage line when no folder is given, or `REFUS : gabarit introuvable`.

**Reads.** `templates/vault-root-template.md`, `VAULT-IDENTITY.md`. **Writes.** Creates the folder if needed; writes the marker and, without `--marker-only`, the two guides (overwritten at each run; since Mission 235 they route any session opened at the root to the entry matrix of the session-start skill, a free session answering `READY (session libre)`; `tools/check-workspace-root.sh` admits them); generates `VAULT-IDENTITY.md` in the Vault if it is missing.

**Repository-root guard.** Not carried: it targets the workspace root by design, that is where the marker lives.

```
bash <workspace>/second-brain/tools/write-marker.sh <workspace> Brian
```

_Not executed by the documentation check._

## vault-identity.sh

**Role.** Reads and writes the identity of the installed Vault, `VAULT-IDENTITY.md`: `vault_id` (`sb-` plus random hexadecimal), `vault_origin`, and the optional `workspace_label`, which names the Vault's MCP server `second-brain-vault-<label>` (without a label: `second-brain-vault-` plus the first 8 characters of `vault_id` after `sb-`).

**Called by.** Command line: `install.sh` (`ensure`, `get status`), `install.ps1` (`ensure`). Sourced by `tools/resolve-vault.sh` (hence by the two scripts above), `tools/write-marker.sh`, `tools/install-vault-mcp.sh`, `tools/second-brain-update.sh`. Its label rule has a Python twin in `tools/vault-mcp.py`. Tests under `tests/`.

**Syntax.** `vault-identity.sh ensure|get <cle>|set-label <libelle>|label-normalize <texte> [<racine-du-vault>]` (root default: the Vault that holds the script).

| Command | Effect | Output, exit code |
|---|---|---|
| `ensure [<root>]` | Generates the identity if the file is missing, still the skeleton, or without `vault_id`; never rewrites a generated one | the `vault_id`, 0; 1 if the guard refuses |
| `get <key> [<root>]` | Reads a front-matter key (`vault_id`, `vault_origin`, `workspace_label`, `status`…); `vault_ref` gives the Vault commit, `server_name` the MCP server name | the value, 0; `server_name` without identity: empty, 1; no key: usage, 1 |
| `set-label <label> [<root>]` | Normalises the label, sets or replaces `workspace_label` | the stored label, 0; `REFUS : libelle non pose (libelle vide ou identite absente)`, 1 |
| `label-normalize <text>` | Prints the normalised label only: accents folded, lower case, other runs of characters become one hyphen | the label, 0 |

**Reads / writes.** Reads `VAULT-IDENTITY.md` of the root and, for `ensure`, its Git remote `origin`. `ensure` and `set-label` write that file only.

**Repository-root guard.** `ensure` carries it (default mode): the root must lie in a Git repository or a project with a birth certificate, below any workspace root; otherwise `REPO-ROOT-REFUSED: …` and nothing is written. `set-label` does not run it and writes only an existing identity file.

**Example.** The second line prints `mon-espace-2`:

```
bash <workspace>/second-brain/tools/vault-identity.sh get server_name <workspace>/second-brain
bash <workspace>/second-brain/tools/vault-identity.sh label-normalize "Mon Espace (2)"
```

```
bash <workspace>/second-brain/tools/vault-identity.sh ensure <workspace>/second-brain
bash <workspace>/second-brain/tools/vault-identity.sh set-label Workspaces <workspace>/second-brain
```

_Not executed by the documentation check._

## Liens

- `source` — [project-bootstrap.sh](../../tools/project-bootstrap.sh)
- `source` — [check-project-conformity.sh](../../tools/check-project-conformity.sh)
- `source` — [write-marker.sh](../../tools/write-marker.sh)
- `source` — [vault-identity.sh](../../tools/vault-identity.sh)
- `source` — [resolve-vault.sh](../../tools/resolve-vault.sh)
- `source` — [repo_root_guard.py](../../tools/repo_root_guard.py)
- `source` — [project_baseline.py](../../tools/project_baseline.py)
- `source` — [sb_installer_helper.py](../../tools/sb_installer_helper.py)
- `source` — [append-journal.sh](../../tools/append-journal.sh)
- `source` — [build-state.sh](../../tools/build-state.sh)
- `source` — [build-digest.sh](../../tools/build-digest.sh)
- `source` — [build-indexes.sh](../../tools/build-indexes.sh)
- `source` — [install-vault-mcp.sh](../../tools/install-vault-mcp.sh)
- `source` — [second-brain-update.sh](../../tools/second-brain-update.sh)
- `source` — [vault-mcp.py](../../tools/vault-mcp.py)
- `source` — [install.sh](../../install.sh)
- `source` — [install.ps1](../../install.ps1)
- `source` — [project-bootstrap skill](../../skills/project-bootstrap/SKILL.md)
- `source` — [session-start skill](../../skills/session-start/SKILL.md)
- `source` — [Installation checklist](../../skills/first-install/install-checklist.md)
- `source` — [Initiation order template](../../templates/initiation-order-template.md)
- `source` — [Workspace marker template](../../templates/vault-root-template.md)
- `source` — [Vault identity](../../VAULT-IDENTITY.md)
- `source` — [USER.md](../../USER.md)
- `source` — [Project registry](../../projects/PROJECT-REGISTRY.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `see also` — [Create a project](../how-to/create-a-project.md)
- `see also` — [Adopt a project](../how-to/adopt-a-project.md)
- `see also` — [Bring a project into conformity](../how-to/bring-a-project-into-conformity.md)
- `see also` — [Internal helpers](tools-internal-helpers.md)
- `see also` — [Formats](formats.md)
