---
type: how-to
title: "Adopt an existing folder as a project"
description: "Adopt a folder you already have, with or without Git, so that Second Brain knows it: clean tree or accepted dirty tree, dated baseline, missing indexes only, a reorganisation plan that is proposed, and link repairs applied only under a Mission."
status: active
---

# ADOPT AN EXISTING FOLDER AS A PROJECT

Adoption turns a folder that already exists into a Second Brain project. It writes only what is missing, never moves an existing file of the folder and modifies none, with two exceptions: a `<project>/.pre-commit-config.yaml` holding nothing but older guardians is replaced (see the end of Known errors), and `adopt --git` on a project already adopted without Git rewrites the `# vcs:` line of its certificate. Every adoption also records a dated baseline of what is there, and ends with a proposed reorganisation that nothing applies. To start a project from nothing, see [Create a project](create-a-project.md).

The verb is `sb adopt [<folder>] ["<Display Name>"]`; it runs the script below ([Commands](../reference/commands.md)). Run again on a project already adopted, it also replaces the links to a skill Second Brain renamed (`ecriture-de-mission` became `mission-writing`, `recherche-interne` became `internal-search`) by links under the new name, and notes it in the project's journal ([Update](update.md), "What the update also does for your projects").

In the commands below, `<workspace>` is the absolute path of your workspace (for example `C:/Users/you/Workspaces`), the installed Second Brain is `<workspace>/second-brain`, and the folder to adopt is `<workspace>/<project>`.

## Before you start

- **Who runs it.** Adoption is an Executor gesture. The skill `skills/project-bootstrap/SKILL.md` runs it only on a Mission, on an initiation order dated by the Owner, or on an Owner arbitration, because it writes into the Second Brain registry.
- **Where the folder lives.** Walking up from the folder's parent must reach the workspace marker `<workspace>/VAULT-ROOT.md`. The folder must not be inside the Second Brain repository, and must not be the workspace root itself.
- **Tools.** `uv` is required (baseline and indexes). With Git: `git`, and `pre-commit` for the hook.
- **Git or not.** Decide `--vcs git` or `--vcs none`. If neither the command nor the order says it, the script asks `Track this project with Git? (git or none, default: ...)`; the default is `git` when the folder already has a `.git`, `none` otherwise.
- **A clean tree.** If the folder is a Git working tree, this command must print nothing:

```bash
git -C <workspace>/<project> status --porcelain
```

If it prints lines, commit or restore them first. The other way is an initiation order carrying the `Arbre sale` field (step 2).

## Steps

1. **Check the tree** with the command above. The baseline records the content of the working tree as it is: an uncommitted change would be recorded as if it were the reference.

2. **Get an initiation order, if no Mission covers the adoption.** This command writes nothing and prints the order, pre-filled for the folder (`Type : adopt` when the folder exists, `Git : git` when it has a `.git`):

   ```bash
   bash <workspace>/second-brain/tools/project-bootstrap.sh order <workspace>/<project>
   ```

   In PowerShell, where `bash` is unknown: `& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/project-bootstrap.sh order <workspace>/<project>`.

   The Pilot completes `Objet` (one sentence), the Owner writes `Autorisation Owner datée` verbatim with a `AAAA-MM-JJ` date (year-month-day), and the order is saved as a file, `<order-file>`. The field names stay in French: the script finds each one by its exact name followed by a colon ([the template](../../templates/initiation-order-template.md)). The order travels to the Executor in an `initiation` mini-prompt, which has no « Source à appliquer » rubric: the order is the source ([relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)).

   **Project profile.** The optional fields `Résultat attendu`, `Blocage actuel` and `Rythme de revue` carry the project's profile; the Pilot preparing the adoption asks them one at a time before proposing the order ([The starting interview](starting-interview.md)). Left out, nothing changes.

   **Dirty tree.** When the Owner accepts that the baseline records uncommitted changes, add the optional ninth line to the order. The script accepts a value that starts with `accepté`, `accepte`, `accepted` or `aceptado`:

   ```text
   - Arbre sale : accepté — <raison>
   ```

   This field is read only from an order: a direct `adopt` has no way to accept a dirty tree.

3. **Run the adoption.** From an order:

   ```text
   sb new --order <order-file>
   ```

   (`sb new --order` runs any initiation order, an adoption as well as a creation: it is `tools/project-bootstrap.sh --order`.)

   _Not executed by the documentation check._

   Or directly, on a Mission:

   ```text
   sb adopt <workspace>/<project> --vcs git
   ```

   _Not executed by the documentation check._

   | Option | Effect |
   |---|---|
   | `[display_name]` | optional; defaults to the folder name |
   | `--vcs none\|git` | Git or not; asked if absent |
   | `--ask` | asks the name and the location first; Enter keeps the proposal. Then the three questions of the project profile, Enter leaving one empty; `sb adopt --ask` does the same |
   | `--git` | on a project adopted with `vcs: none`, moves it to `vcs: git` |
   | `--lang FR\|EN\|ES` | language of the script's messages (English by default) |

   With `--order`, the target is `Emplacement` joined to `Nom`; `Mode : ask` asks the name and location, `Mode : answered` asks nothing, except the Git question when `Git` is neither `none` nor `git`.

4. **Read the report.** Each file is listed as `Already there, left as is: <file>` or `Added: <file>`. With profile answers, the report says `Project profile written under « ## Profil du projet »: <README>` — an existing `README.md` gains that one section, a folder without one gets a README (listed as added) — or `Project profile already there, kept as it is: <README>`. Then comes the plan, headed `Proposed reorganisation plan (seven functions) -- nothing is applied:`. It proposes `create <folder>` for each of the seven-function folders that is missing and for a missing `README.md`, and `move <file> to <folder>/<file>` for files at the root of the project, guessed from their names (`MISSION-*` to `missions`, `DECISION-*` to `decisions`, other `.md` files to `knowledge`, and so on). Files this run added are left out of the plan. The plan is applied only on the Owner's categorical yes written in a Mission, never on a yes given in conversation ([Bring a project into conformity](bring-a-project-into-conformity.md)).

5. **Look for broken links that predate adoption.** Adoption repairs none. This command reads only and returns a plan:

   ```bash
   bash <workspace>/second-brain/tools/propose-link-repairs.sh <workspace>/<project>
   ```

   In PowerShell, where `bash` is unknown: `& "C:\Program Files\Git\bin\bash.exe" <workspace>/second-brain/tools/propose-link-repairs.sh <workspace>/<project>`.

   A broken link is a relative Markdown link (`./` or `../`) to a `.md` file that does not exist, outside code. A repair is proposed only when the project holds exactly one file of that name. The plan prints `PROPOSE <file>:<line>: <old> -> <new>`, or `SANS-PROPOSITION <file>:<line>: <target> (<n> candidat(s))`, and ends with `PLAN: <n> lien(s) cassé(s), <p> réparation(s) proposée(s), <a> appliquée(s)`.

   To apply the proposals, a Mission is required: the file named by `--mission` must have a name starting with `MISSION-` and contain `type: mission`. Only `PROPOSE` lines are applied, each reported as `APPLIQUE <file>:<line>`.

   ```bash
   bash <workspace>/second-brain/tools/propose-link-repairs.sh <workspace>/<project> --apply --mission <mission-file>
   ```

   _Not executed by the documentation check._ This one is the Executor's, under the Mission, in its own shell.

6. **Without Git**, no hook runs; check by command, for example `bash <workspace>/second-brain/tools/check-links.sh <workspace>/<project>` and `bash <workspace>/second-brain/tools/check-project-conformity.sh <workspace>/<project>` (in PowerShell, `& "C:\Program Files\Git\bin\bash.exe"` in place of `bash`; `sb doctor`, typed in the project folder, runs the conformity check and counts dead skill links). To move to Git later, rerun `adopt <workspace>/<project> --git`: it adds the repository, the hook and the active pin, and rewrites only the `vcs` line of the certificate, the sheet and the registry line.

## What you should see

| Written in the project, only if absent | Content |
|---|---|
| `<project>/.pre-commit-config.yaml` | birth certificate (`vault_id`, `vault_origin`, `vault_ref`, `vcs`, `baseline`) and a `repo: local` pin with four guardian hooks |
| `<project>/.vault-baseline-<YYYY-MM-DD-HHMMSS>.tsv` | each existing file with its SHA-256 fingerprint; the report shows the file count in brackets |
| `<project>/CLAUDE.md`, `<project>/AGENTS.md` | pointer files, in the project's language |
| `<project>/state/PILOT-PROMPT.md` | Pilot prompt with its canary |
| `<project>/state/journal.md` | journal with the birth `STATE:` line |
| `<project>/state/STATE.md`, `<project>/state/DIGEST.md` | generated state sheet and digest |
| `<project>/.gitignore` | a comment only: the links are named by each link folder's own `.gitignore` (Mission 231) |
| `<folder>/index.md` | only in folders that have no index |

In Second Brain: a registry line in `projects/PROJECT-REGISTRY.md` and a sheet `<workspace>/second-brain/projects/PROJECT-<project_id>.md` with `bootstrap_mode: adopt` and `reorganisation: proposed-not-applied`. The sheet and the registry carry the conformity measured by `tools/check-project-conformity.sh`: an adopted project that is not reorganised usually shows `ÉCART`.

**Indexes.** Adoption calls `tools/build-indexes.sh --only-missing <project>`: an index is written only in a folder that carries none (neither index nor archive), an existing index is never rewritten, and `superseded-files.txt` is written only if absent. The Second Brain indexes are then rebuilt for the new sheet.

**Baseline.** The guardians then judge only what is new or touched: an untouched listed file is never red, a listed file you touch is judged in full and must become compliant ([baseline functions](../../tools/project-baseline.sh)). The baseline is never edited by hand; listed corrections go through `tools/project_baseline.py amend <project-root> --paths <file> --by <who> --reason <why> [--ref <ref>]`.

After the report comes the block to consume (the Project to create, the instructions to paste, the first message, the canary). The last line is the path of the project sheet. `git -C <workspace>/<project> status --porcelain` then shows only new files (`??`), no ` M`, except in the replaced-config case below and for the changes an accepted dirty tree already carried.

The skill adds one gesture of its own: it copies the launcher `skills/project-bootstrap/preflight-launcher.sh` to `<project>/.claude/hooks/preflight-hook.sh` if missing; an existing `<project>/.claude/settings.json` is never modified, and the fragment `skills/project-bootstrap/settings-hook.json` is returned to merge (its matcher covers `Bash` and `PowerShell`). The launcher runs the Vault's own `skills/project-bootstrap/preflight-hook.sh`, found through `VAULT-ROOT.md`: the project never keeps a copy of the checks that ages behind the Vault (Mission 231). A project that still keeps such a copy, or whose matcher leaves out `PowerShell`, is reported by `tools/check-project-conformity.sh`; replace the copy by the launcher and add `PowerShell` to the matcher.

## Known errors

| Message | Cause | What to do |
|---|---|---|
| `BASELINE-DIRTY-TREE : <n> porcelain line(s) in <path>: ... Nothing written.` | Git tree with uncommitted changes, baseline due | commit or restore, or have the order carry `Arbre sale : accepté — <raison>` |
| `BASELINE-TREE-UNMEASURED : <path> is not a Git working tree ...` | no Git: cleanliness cannot be measured | information only; the folder is recorded as it is |
| `REFUS : chemin cible non absolu : <path>` | relative target | give the absolute path |
| `REFUS : chemin cible a l'interieur du depot Vault (...)` | target inside Second Brain | adopt a folder outside it |
| `REPO-ROOT-REFUSED: ... is a workspace root ...` | target is the workspace root | name the project folder below it |
| `REFUS : la cible a adopter n'existe pas (mode create) : <path>` | folder missing | use `create` ([Create a project](create-a-project.md)) |
| `REFUS : marqueur VAULT-ROOT.md introuvable en remontant depuis <path>` | no workspace marker above | adopt a folder of the workspace |
| `REFUS : ordre d'initiation sans autorisation Owner datée (AAAA-MM-JJ)` | no date in the authorization | the Owner dates it |
| `REFUS : l'ordre nomme le Vault <a>, ce Vault est <b>` | order written for another Second Brain | run it with the Second Brain it names, or redo the order |
| `REFUS : ordre d'initiation : Type doit valoir create ou adopt (lu : ...)` | bad `Type` | write `adopt` |
| `REFUS : ordre d'initiation en mode answered sans Nom ou sans Emplacement` | field missing | fill `Nom` and `Emplacement` |
| `REFUS : vcs doit valoir none ou git (lu : ...)` | bad Git answer | answer `none` or `git` |
| `REFUS : fiche projet deja existante pour cet identifiant : <file>` | a sheet with the same id (date plus a code from the display name) exists | give another display name |
| `Note: .pre-commit-config.yaml exists without a birth certificate -- left as is; ...` | the config holds hooks of the project | add the printed block at the top by hand; no baseline is recorded in this case |
| `Note: .gitignore hides whole folders below; ...` | an existing `.gitignore` carries `/.claude/skills/`, `/.claude/agents/` or `/.agents/skills/`, which also hide the skills the project installs there | remove the printed lines if you want those skills tracked; the links stay out of Git either way |
| `Note: Git hook not installed ...` | `pre-commit` or repository missing | run `pre-commit install` in the project |
| `INDEX-CASE-COLLISION : <path> exists and was not generated` | a file named `<folder>/index.md` in any case (itself or a variant such as `<folder>/INDEX.md`), or a case variant of an archive name `<folder>/index-archive-<suffix>.md`, that the index tool did not generate | declare its folder in the certificate's `# exempt:` key, or rename it (Owner's decision) |
| `REFUS : --apply est reserve a une Mission (...)` | `--apply` without a valid Mission file | keep the plan, or run it under a Mission |

A config that holds nothing but older Second Brain guardians is replaced, not refused: the old file is kept next to it as `<project>/.pre-commit-config.yaml.before-adopt-<date>` and printed in full. Every `project-bootstrap.sh` refusal in this table exits with code 1 and writes nothing in the project. `propose-link-repairs.sh` exits 0 with its plan, 1 on a refusal, 2 when the repository-root guard refuses the folder.

## Scripts used

- `tools/project-bootstrap.sh` — adoption, order, `--git`: [project tools](../reference/tools-projects.md)
- `tools/propose-link-repairs.sh` — link repair plan: [index and link tools](../reference/tools-indexes-and-links.md)
- `tools/build-indexes.sh` — missing indexes: [index and link tools](../reference/tools-indexes-and-links.md)
- `tools/project-baseline.sh` — baseline functions shared by the guardians: [internal helpers](../reference/tools-internal-helpers.md)
- `tools/check-project-conformity.sh` — conformity measurement: [project tools](../reference/tools-projects.md)

## Liens

- `see also` — [The starting interview](starting-interview.md)

- `source` — [Project bootstrap script](../../tools/project-bootstrap.sh)
- `source` — [Skill: project-bootstrap](../../skills/project-bootstrap/SKILL.md)
- `source` — [Template: initiation order](../../templates/initiation-order-template.md)
- `source` — [Relay between roles, initiation type](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Baseline functions](../../tools/project-baseline.sh)
- `source` — [Baseline tool, amend](../../tools/project_baseline.py)
- `source` — [Link repair plan, launcher](../../tools/propose-link-repairs.sh)
- `source` — [Link repair plan, code](../../tools/propose_link_repairs.py)
- `source` — [Index builder](../../tools/build_indexes.py)
- `source` — [Index builder launcher](../../tools/build-indexes.sh)
- `source` — [Repository-root guard](../../tools/repo_root_guard.py)
- `source` — [English message catalogue](../../i18n/catalog.en.json)
- `source` — [Project conformity check](../../tools/check-project-conformity.sh)
- `source` — [Link check](../../tools/check-links.sh)
- `source` — [Project Registry](../../projects/PROJECT-REGISTRY.md)
- `source` — [executor-preflight hook](../../skills/project-bootstrap/preflight-hook.sh)
- `source` — [PreToolUse fragment](../../skills/project-bootstrap/settings-hook.json)
- `see also` — [Create a project](create-a-project.md)
- `see also` — [Bring a project into conformity](bring-a-project-into-conformity.md)
- `see also` — [Write a Mission](write-a-mission.md)
- `see also` — [React to a guardian refusal](react-to-a-guardian-refusal.md)
- `see also` — [Project tools](../reference/tools-projects.md)
- `see also` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `see also` — [Commands](../reference/commands.md)
- `see also` — [Update](update.md)
