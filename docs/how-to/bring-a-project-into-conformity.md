---
type: how-to
title: "Bring a project into conformity"
description: "Measure a project against the Vault's conventions with the conformity check, fix each gap it reports, and refresh the project's Pilot prompt."
status: active
---

# BRING A PROJECT INTO CONFORMITY

The conformity check measures a project and reports what is missing. It never fixes anything and never blocks anything. This page shows how to run it, what each gap means, which gesture fixes it, and how to refresh the Pilot prompt of an adopted project.

In the commands below, `<workspace>` is the absolute path of your workspace (for example `C:/Users/you/Workspaces` or `/Users/you/Workspaces`), the Vault is installed at `<workspace>/second-brain`, and the project is `<workspace>/<project>`.

## Before you start

- A Bash shell (Git Bash on Windows). `tools/project-bootstrap.sh` also needs `uv`, which it calls for its helpers.
- The project sits under the workspace folder that carries the Vault's marker file. The check needs that marker to find the registry row; `adopt` refuses without it.
- Measuring is read-only: you can run the check at any time. Fixing is not. `adopt` writes into the Vault's registry, so the [project-bootstrap skill](../../skills/project-bootstrap/SKILL.md) runs it only on the prescription of a Mission, an initiation order dated by the Owner, or an Owner arbitration.
- Applying the seven-function layout (moving files) needs the Owner's categorical yes **written in the Mission**. A yes given in conversation is not enough.

## Steps

### 1. Measure

```bash
bash <workspace>/second-brain/tools/check-project-conformity.sh <workspace>/<project>
```

In PowerShell, where `bash` is unknown: `& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/check-project-conformity.sh <workspace>/<project>`. `sb doctor`, typed in the project folder, shows the same verdict on its `Project conformity` line.

Without an argument the script measures the current folder; always give the absolute path instead. It prints one line: `CONFORME`, or `ÉCART:` followed by the missing items, separated by commas. Read each item in the table of step 2.

### 2. Find the fix for each gap

The items are printed in French, in this order. `<file>` is `AGENTS.md` or `CLAUDE.md`.

| Gap printed | What it means | Fix |
|---|---|---|
| `README.md`, `rules`, `state`, `missions`, `decisions`, `proposals`, `knowledge`, `handoffs` | This item of the seven-function skeleton does not exist at the project root | Step 5 (`state` alone: step 3) |
| `registre introuvable (<path>)` | The Vault has no project registry | Step 3: `adopt` creates it from its template |
| `inscription au registre non vérifiable (projet hors de l'espace de travail du Vault)` | No marker file found walking up from the project, so its registry path cannot be computed | Move the project under the workspace folder that carries the marker |
| `inscription au registre (<relative path>)` | No registry row has this path in its `relative_path` column | Step 3 |
| `acte de naissance absent` | The project's pre-commit config has no birth certificate | Step 4 |
| `acte de naissance sans vault_origin` (or `vault_ref`) | The certificate has an empty key (an empty `vault_id` stops the check instead, with `REFUS : acte de naissance sans vault_id : <file>`) | Step 4 |
| `acte de naissance : vcs invalide (<value>)` | The certificate's `vcs` is neither `none` nor `git` (`absent` when missing) | Step 4 |
| `ligne de base nommée par l'acte introuvable (<name>)` | The certificate names a baseline file that is not at the project root | Put that file back under that name; the script never rewrites an existing certificate |
| `épingle des gardiens absente` | No `repo: local` pin in the config | Step 4 |
| `épingle incomplète (<ids>)` | Some of the four guardian hooks are missing from the pin | Step 4 |
| `épingle hors du Vault résolu (<path>)` | The pin's `entry:` paths do not lead to the resolved Vault (the certificate's, or the marker's when there is no certificate; `entrée absente` when there is no entry) | Step 4 |
| `dépôt Git absent (vcs: git)` | The certificate says `vcs: git` but the project has no repository | Step 3 |
| `hook Git absent (pre-commit install)` | Repository present, pre-commit hook not installed | Step 3 |
| `fichier de pointage absent (<file>)` | The pointer file is missing | Step 3 |
| `fichier de pointage sans chemin vers le Vault (<file>)` | The pointer file names no path to the Vault | Step 6 |
| `fichier de pointage incohérent avec l'acte (<file> : <path>)` | The pointer file names a folder that is not the resolved Vault | Step 6 |

With `vcs: none`, no Git hook is expected and the two Git gaps never appear.

### 3. Fill what is missing with adopt

`adopt` writes only what is missing and never moves an existing file of the project; it modifies one only in the cases of step 4 (a config holding nothing but older Vault guardians) and of `--git` below. Run it again on an adopted project to fill the gaps: the registry row, a missing repository with `vcs: git`, the pointer files, the state files.

```text
sb adopt <workspace>/<project> --vcs git
```

_Not executed by the documentation check._

- Give `--vcs none` or `--vcs git`; without it the script asks. When the project already has a certificate, the certificate's `vcs` value is kept.
- `adopt <project> --git` moves a project adopted with `vcs: none` to `vcs: git`: repository, hook, and the `vcs` line of the certificate, the sheet and the registry row.
- **Registry row.** If no row carries the project's path, one is added: `project_id`, `display_name`, `ACTIVE`, `relative_path` (relative to the workspace folder), `vcs`, and the measured conformity. The project's sheet `<workspace>/second-brain/projects/PROJECT-<project_id>.md` is written next to the registry.
- **State files.** `adopt` creates `<project>/state/` and writes, only if absent, `<project>/state/PILOT-PROMPT.md`, `<project>/state/journal.md` with its birth entry, `<project>/state/STATE.md` and `<project>/state/DIGEST.md`. An existing one is reported as `Already there, left as is: <file>`.
- **Pointer files.** `<project>/CLAUDE.md` and `<project>/AGENTS.md` are written only if absent.
- **Git hook.** With `vcs: git`, a missing repository is created and `pre-commit install` is run. If `pre-commit` cannot be found, the script says so; install the hook yourself:

```bash
cd <workspace>/<project> && pre-commit install
```

_Not executed by the documentation check._

`adopt` also rebuilds the Vault's indexes and writes the project's missing indexes. It does not refresh the `conformity` column of a row that already exists: that value is written when the row is added, and again only on a `--git` switch.

### 4. Complete the birth certificate and the pin

The certificate is a comment block at the top of `<project>/.pre-commit-config.yaml`, followed by the pin. `adopt` writes both when the file is absent. When the file holds nothing but older Vault guardians, it replaces it and keeps a dated copy next to it. When the file carries anything of the project, it leaves the file as it is and prints the block to add at the top:

```text
Note: .pre-commit-config.yaml exists without a birth certificate -- left as is; add these lines at the top of the file:
# second-brain-birth-certificate: v1
# vault_id: <vault_id>
# vault_origin: <vault_origin>
# vault_ref: <vault_ref>
# vcs: <none|git>
```

Paste those lines yourself. A config that already has a certificate is never rewritten by `adopt` (apart from its `vcs` line on a `--git` switch), so an empty key, an invalid `vcs` or a wrong pin is corrected by hand. The pin `adopt` writes is `repo: local` with four hooks, `vault-check-secrets`, `vault-check-indexes-fresh`, `vault-check-index-weight` and `vault-check-links`, each with an `entry:` that is the relative path from the project to the Vault followed by the checker. For a project that sits directly in `<workspace>`, the first one reads:

```text
      - id: vault-check-secrets
        name: "Vault : contrôle de secrets"
        entry: ../second-brain/tools/check-secrets.sh
```

The check reads the Vault's location from the entry of `tools/check-secrets.sh`.

### 5. Apply the seven-function layout, only on a written yes

At the end of each run, `adopt` prints a plan, never applied:

```text
Proposed reorganisation plan (seven functions) -- nothing is applied:
  - create <folder>
  - move <file> to <folder>/<file>
  This plan is only applied on the Owner's categorical yes, written in a Mission.
```

It proposes to create each missing folder among `rules`, `state`, `missions`, `decisions`, `proposals`, `knowledge`, `handoffs`, and `README.md` if absent. It proposes moves only for files already at the project root before the run, by name:

| File name | Proposed folder |
|---|---|
| `MISSION-*` or containing `mission` (Markdown) | `missions` |
| `DECISION-*` or containing `decision` (Markdown) | `decisions` |
| `HANDOFF-*` or containing `handoff` (Markdown) | `handoffs` |
| `RULES-*` or containing `rule` (Markdown) | `rules` |
| `PROPOSAL-*` or containing `proposal` (Markdown) | `proposals` |
| `STATE*`, `DIGEST*`, or containing `journal` (Markdown) | `state` |
| any other Markdown file | `knowledge` |

`README.md`, `AGENTS.md`, `CLAUDE.md`, `LICENSE*` and dot files stay where they are. The plan is applied only when the Mission that launches the skill carries the Owner's categorical yes. Without it, the project stays adopted but not reorganised, its sheet says `reorganisation: proposed-not-applied`, and the check keeps listing the missing folders. That `ÉCART` is expected.

Where a rule belongs, once the layout is in place: ask whether it would make sense in another project. Yes: it lives in the Vault. Only this one: it lives in `<project>/rules/` ([structure standard](../../rules/RULES-2026-08-26-142800-project-structure-standard.md) §3, [boundary rule](../../rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)).

### 6. Point the pointer files at the Vault

`adopt` never rewrites an existing `<project>/CLAUDE.md` or `<project>/AGENTS.md`. Edit them yourself. The check accepts, in each file, a path that starts with `..` and ends in `CLAUDE.md` or `AGENTS.md` after a slash, written as an import (`@`) or as a Markdown link target, or a path that starts with `..` and leads to the Vault's role charter. Every such path must lead to the resolved Vault (the one the certificate names, or the one the marker points to when there is no certificate). The form `adopt` writes, for a project that sits directly in `<workspace>`:

```text
@../second-brain/CLAUDE.md
```

### 7. Refresh the Pilot prompt

`adopt` never rewrites a Pilot prompt that exists. When the Vault changes (its identity, its MCP server name, its commit), regenerate it:

```text
sb pilot-prompt <workspace>/<project> --regen
```

_Not executed by the documentation check._

It keeps what belongs to the project (`project_id`, canary, title, project path) and regenerates what belongs to the Vault (identity, server name, commit, date, links). It touches nothing else: no registry, no certificate, no Git. `--state-path <relative path>` names another state sheet; it must be relative to the project, without `..`, and name an existing file. Without it, the path the prompt already carries is kept, or `<project>/state/STATE.md` by default.

### 8. Measure again

Rerun step 1. Each gap you fixed disappears from the list.

## What you should see

- The check prints `CONFORME`, or an `ÉCART:` line that lists only the items (folders, `README.md`) of a plan not yet approved.
- `adopt` prints `Added: <file>` and `Already there, left as is: <file>` lines, the plan, the block to consume, and last the path of the project's sheet, `<workspace>/second-brain/projects/PROJECT-<project_id>.md`. These messages follow the language you give (`--lang FR|EN|ES`); English is shown here.
- `prompt` ends with `PILOT-PROMPT regenere : <path> (serveur <name>, commit <ref>, fiche <state path>, langue <language>)`.

## Known errors

The check exits 0 whenever it gives a verdict; it exits 1 only when it cannot measure. The literal messages:

```text
(1) REFUS : chemin de projet introuvable : <path>
(2) REFUS : ni acte de naissance ni marqueur VAULT-ROOT.md en remontant depuis <folder>
(3) REFUS : identité du Vault différente : l'acte nomme <vault_id>, trouvé : <ids>
(4) REFUS : plusieurs Vaults candidats sans acte de naissance, question à l'Owner : <folders>
(5) REFUS : pas de state/PILOT-PROMPT.md dans <folder> : le projet n'est pas adopte (adopt d'abord)
(6) REFUS : <prompt> ne porte pas project_id, canary, title et « Chemin du projet » : format non reconnu, rien n'est ecrit
(7) REFUS : --state-path doit etre un chemin relatif au projet, sans '..' : <path> ; prompt inchange
(8) REFUS : fiche projet deja existante pour cet identifiant : <sheet>
(9) BASELINE-DIRTY-TREE : <n> porcelain line(s) in <folder>: the baseline would engrave uncommitted content. Nothing written. ...
```

| # | Cause | What to do |
|---|---|---|
| 1 | The project path does not exist (check) | Give the absolute path of an existing folder |
| 2 | No certificate and no marker walking up from the project (check) | Place the project under the workspace folder that carries the marker |
| 3 | The certificate names a Vault that is not found | Check the certificate's `vault_id` and the pin's paths |
| 4 | Several Vaults in the workspace and no certificate to choose | Ask the Owner which Vault; adoption writes the certificate |
| 5 | `prompt` on a project that was never adopted | Adopt it first |
| 6 | The Pilot prompt was edited by hand and lost a field | Nothing is written; restore the fields |
| 7 | `--state-path` absolute or with `..` | Give a path relative to the project |
| 8 | `adopt` derived a project id whose sheet already exists | The id is the date plus a code from the display name: give another display name |
| 9 | `adopt` would write a baseline over uncommitted changes | Commit or restore first, or have the order carry `Arbre sale : accepté — <reason>` |

## Scripts used

- `tools/check-project-conformity.sh`: measures, prints `CONFORME` or `ÉCART:` ([sheet](../reference/tools-projects.md)).
- `tools/project-bootstrap.sh`: `adopt` fills what is missing, `prompt` regenerates the Pilot prompt ([sheet](../reference/tools-projects.md)).
- `tools/resolve-vault.sh`: finds the Vault from the certificate, then the marker ([sheet](../reference/tools-internal-helpers.md)).

## Liens

- `source` — [Project conformity check](../../tools/check-project-conformity.sh)
- `source` — [Project bootstrap script](../../tools/project-bootstrap.sh)
- `source` — [Vault resolution and certificate helpers](../../tools/resolve-vault.sh)
- `source` — [English message catalogue](../../i18n/catalog.en.json)
- `source` — [Skill: project-bootstrap](../../skills/project-bootstrap/SKILL.md)
- `source` — [Project structure standard, seven functions](../../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- `source` — [Boundary between a project and Second Brain](../../rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `see also` — [Adopt a project](adopt-a-project.md)
- `see also` — [Create a project](create-a-project.md)
- `see also` — [Write a Mission](write-a-mission.md)
- `see also` — [Open a session](open-a-session.md)
- `see also` — [Project tools reference](../reference/tools-projects.md)
- `see also` — [Internal helpers reference](../reference/tools-internal-helpers.md)
