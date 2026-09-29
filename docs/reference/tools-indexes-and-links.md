---
type: reference
title: "Tools: indexes and links"
description: "One sheet per script that builds or checks the generated indexes, the links between documents and the paths cited in prose: syntax, options, exit codes, what each reads and writes, and whether it carries the repository-root guard."
status: active
---

# TOOLS: INDEXES AND LINKS

This page has one sheet for each script that builds or checks the generated indexes (`index.md`), the relative links between documents, and the paths cited in prose. Every syntax, message and exit code below comes from the script's own code. In the commands, `<workspace>` is the absolute path of your workspace (for example `C:/Users/you/Workspaces` or `/Users/you/Workspaces`), the installed Vault is `<workspace>/second-brain`, and a project is `<workspace>/<project>`.

Four of these scripts are short launchers that run a Python file through `uv`: `uv` must be on your `PATH`. Messages quoted in French are the tools' literal output.

| Script | Writes | Repository-root guard |
|---|---|---|
| `tools/build-indexes.sh` | indexes, archives, superseded list | yes |
| `tools/check-indexes-fresh.sh` | nothing | not needed |
| `tools/check-index-weight.sh` | nothing | not needed |
| `tools/check-links.sh` | nothing | not needed |
| `tools/propose-link-repairs.sh` | the project's .md files, only with `--apply` | yes |
| `tools/link-graph-drone-view.sh` | nothing (standard output only) | not needed |
| `tools/find-in-vault.sh` | nothing | not needed |
| `tools/check-asserted-paths.sh` | nothing | not needed |

**The repository-root guard** (`tools/repo_root_guard.py`, Mission 226) admits a target when, walking up from it, it finds a `<repository>/.git` or a birth certificate before any workspace root. A workspace root is a folder that carries `<workspace>/VAULT-ROOT.md`, or that holds two or more Git repositories without being one. Anything else is refused before anything is written, with one line that starts with `REPO-ROOT-REFUSED:`, names the path received and the root expected, and ends with `Nothing written.` No option or environment variable turns it off.

**Under Windows.** A `bash …/tools/…` line of this page, typed in PowerShell where `bash` is unknown, starts with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`; where an `sb` verb carries the same gesture ([Commands](commands.md)), type the verb. `sb doctor` says whether `bash` is on your PATH.

## build-indexes.sh (engine: build_indexes.py)

- **Role.** Regenerates one `index.md` in every folder that holds at least one .md file (other than its indexes), under each root you pass. It reads the working files on disk, not the staged tree. Never edit an index by hand.
- **Called by.** `install.sh` and `install.ps1` (the clone's own indexes); `tools/project-bootstrap.sh` (create: the project and the Vault; adopt: `--only-missing` on the project, then the Vault); `tools/second-brain-update.sh`; `tools/publish-from-laboratory.sh`; `tools/session-preflight.sh` checks that it is executable; the `session-close` skill (touched roots only); the remedy lines of the two index guardians below; tests such as `tests/test-build-indexes-case-collision.sh` and `tests/test-repo-root-guard.sh`.
- **Syntax.** `build_indexes.py [-v|--verbose] [--only-missing] <racine...>` (header of the engine; the launcher passes its arguments through unchanged).
- **Options.**
  - `-v`, `--verbose`: prints on standard error each index written, each archive with its size (`(N o)`, followed by `DEPASSE LE PLAFOND` if it is over the cap), the live index as `(vivant, N=n)`, then the summary `build_indexes.py: X index(es) regenerated (Y archived) across Z root(s)`. Without `-v` a successful run prints nothing.
  - `--only-missing`: writes an index only in a folder that has neither `index.md` nor a generated archive. It never rewrites, removes or splits an existing index, and writes `<root>/superseded-files.txt` only if that file is absent. Used when a project with existing content is adopted.
- **What an index holds.** A front matter with `type: index` and the marker line `generated_by: tools/build-indexes.sh`, then one locator line per file: identifier, status (or the type when there is no status, or `inconnu`), title cut to 80 characters, file name. A file named in another file's `supersedes:` field gets ` — REMPLACÉ par <name>`. The `## Liens` section points to the linking standard, with `(hors Vault)` when the folder is outside the Vault.
- **The 8,000-byte cap and archives.** When a folder's index would exceed 8,000 bytes, the entries are split into frozen archives. File names that carry a Mission or report number go into slices of 20 numbers (`<folder>/index-archive-<start>-<end>.md`); other dated names go into one archive per month (`<folder>/index-archive-<YYYY-MM>.md`). An entry never changes archive. A name with neither a number nor a date goes into no archive. `index.md` then keeps the most recent entries that fit under 8,000 bytes, and links to every archive. Generated archives that are no longer produced are removed.
- **Case-variant refusal.** If a folder holds `index.md`, or any spelling of it in other letter case (`<folder>/INDEX.md`, for example), that does not carry the generation marker, nothing is written in that folder, in either mode. The same holds for an archive name. Standard error gets `INDEX-CASE-COLLISION : <path> exists and was not generated`. This check runs before `--only-missing`, so Windows and Linux give the same answer.
- **Exit codes and last line.** `0`: done (a root that does not exist is skipped without a message). `1` with `usage: build_indexes.py [-v|--verbose] [--only-missing] <racine...>`: no root given. `1` when any root or folder was refused; the other roots are still processed. A root refused by the repository-root guard gets its `REPO-ROOT-REFUSED:` line. When at least one folder was refused (case variant, above), the last line is ``build_indexes.py: N refusal(s). A case variant of index.md that was not generated is never overwritten: declare its folder in the project's .vault-exempt (one prefix per line) or the birth certificate's `# exempt:` key, or rename the file (Owner's decision).``, where N counts the refused folders.
- **Reads.** The .md files one level deep in every folder (front matter fields `title`, `type`, `status`, `supersedes`); the birth certificate's `# exempt:` key and `<project>/.vault-exempt`. It skips folders named .git, .githooks, .claude, .codex, .agents, graphify-out, tools, patterns, node_modules, state, .venv, venv, __pycache__, skills-warehouse, _trash and web-package, at any depth below the root.
- **Writes.** `index.md` and archives in each indexed folder; `<root>/superseded-files.txt` (the relative paths of superseded files, deleted when the list would be empty).
- **Repository-root guard.** Yes, on every root, before anything is written.
- **Example.** Regenerate a project's indexes and see each file written:

```
bash <workspace>/second-brain/tools/build-indexes.sh -v <workspace>/<project>
```
_Not executed by the documentation check._

The same command with the workspace root as argument is refused, writes nothing and exits `1`: `bash <workspace>/second-brain/tools/build-indexes.sh <workspace>`.

## check-indexes-fresh.sh (engine: check_indexes_fresh.py)

- **Role.** Pre-commit guardian: refuses a commit whose indexes no longer match their folders. It never regenerates anything.
- **Called by.** `.githooks/pre-commit` (guardian `fraicheur-index`); `.pre-commit-hooks.yaml` (hook `vault-check-indexes-fresh`), which `tools/project-bootstrap.sh` pins in each project and `tools/check-project-conformity.sh` checks; by hand for a project without Git (`project-bootstrap` skill).
- **Syntax.** No usage line in the code. Without argument: the repository that contains the current folder, staged tree. With one argument `<project>`: folder mode for a project without Git (`vcs: none`); every .md on disk counts as added.
- **What it checks.** Every folder that received a staged .md, and every folder that carries an `index.md` (in any letter case). For each: the index exists; the entries of `index.md` plus its archives list exactly the folder's .md files; each entry's status matches the file's `status` (or its `type`). If `<repository>/missions/MISSION-INDEX.md` is staged (in folder mode: if it exists), each register line for a Mission above 122 must stay within 300 characters. Files recorded in the adoption baseline and not touched since are not judged; the exempt prefixes are skipped.
- **Exit codes and last line.** `0`: no gap, nothing printed. `1`: each gap prints a block on standard output, `INDEX-FRESHNESS [<folder>]`, then `Ecart` (the gap) and `Consigne : bash tools/build-indexes.sh <racine> ; git add <index> ; relire git diff --cached`. A tracked case variant of `index.md` prints `INDEX-CASE-COLLISION [<folder>]` with a remedy that never prescribes a full regeneration. The register cap prints `INDEX-LINE-CAP [...]` on standard error. Also `1`: `REFUS : hors d'un depot Git : gardien non executable.` or `REFUS : dossier de projet introuvable : <argument>`.
- **Reads.** Git mode: three Git calls (staged changes, tracked files, their staged contents). Folder mode: the files on disk.
- **Writes.** Nothing.
- **Repository-root guard.** Not needed: it writes nothing.
- **Example.** `bash <workspace>/second-brain/tools/check-indexes-fresh.sh <workspace>/<project>` (folder mode, read-only).

## check-index-weight.sh (engine: check_index_weight.py)

- **Role.** Pre-commit guardian: refuses a commit in which a staged index weighs more than 8,000 bytes, or a Mission register line is too long.
- **Called by.** `.githooks/pre-commit` (guardian `poids-index`); `.pre-commit-hooks.yaml` (hook `vault-check-index-weight`), pinned by `tools/project-bootstrap.sh`, checked by `tools/check-project-conformity.sh`; by hand for a project without Git.
- **Syntax.** No usage line in the code. Without argument: the files staged in the repository you run it from. With `<project>`: folder mode, every file of the project.
- **What it checks.** Every staged `index.md`, archive, and register at `<repository>/missions/MISSION-INDEX.md` or deeper (`<repository>/<folder>/missions/MISSION-INDEX.md`): size above 8,000 bytes is refused. In a register, a line for a Mission above 122 longer than 300 characters is refused. Baseline and exempt prefixes apply as above.
- **Exit codes and last line.** `0`: nothing printed. `1`: for each defect, on standard error, `INDEX-WEIGHT [<path>]`, then `Ecart` (for example `index de N octets > 8000 (DECISION-2026-09-05-124647)`) and `Consigne` (lighten the index, or split it with `tools/build-indexes.sh`). Also `1`: `REFUS : dossier de projet introuvable : <argument>`.
- **Reads.** Staged contents (Git mode) or the files on disk (folder mode). **Writes.** Nothing.
- **Repository-root guard.** Not needed: it writes nothing.
- **Example.** `bash <workspace>/second-brain/tools/check-index-weight.sh <workspace>/<project>`.

## check-links.sh

- **Role.** Pre-commit guardian for links between Markdown documents.
- **Called by.** `.githooks/pre-commit` (guardian `liens`); `.pre-commit-hooks.yaml` (hook `vault-check-links`), pinned by `tools/project-bootstrap.sh`, checked by `tools/check-project-conformity.sh`; `tools/session-preflight.sh` checks that it is executable; `tools/bench-folder-guardians.sh`; `AGENTS.md` and the `project-bootstrap` skill prescribe it.
- **Syntax.** `tools/check-links.sh` (current repository, staged files) or `tools/check-links.sh <projet>` (folder mode, every .md of a project without Git).
- **Rules.** 1: every .md outside `skills/external/` and `skills-warehouse/` has a line `## Liens`. Those two prefixes are folders of the Vault itself: paths are read relative to the repository being checked, so they exempt nothing in a project, the sibling `skills-warehouse` repository included. A project exempts its vendored files by its birth certificate (`# exempt:` key or `.vault-exempt`, [formats](./formats.md)). 2: every relative link to a .md (`./x.md`, `../x.md`, or bare `x.md` and `dir/x.md`, which resolve as `./x.md`), outside code blocks and inline code, resolves to an existing file (a percent-encoded target, `My%20File.md`, is tried decoded when the raw path is missing); a URL, a drive or anything with a colon, an absolute path, an anchor alone, `<...>`, `~/...` and a target without `.md` are not links to check (Mission 229). A link that leaves the repository is checked only if the target repository's folder exists in the workspace; otherwise it is a warning. 3: a file with no resolved link gets a warning. Files under graphify-out are skipped; baseline and exempt prefixes apply.
- **Exit codes and last line.** `0`: pass (warnings do not block). `1`: at least one `LIENS: section manquante: <file>` or `LIENS: cible introuvable: <file>:<line> -> <target>` on standard error; also `REFUS : hors d'un depot Git : gardien non executable.`, `REFUS : dossier de projet introuvable : <argument>`, or `REFUS : ligne de base illisible, le controle ne peut pas verifier.` Folder mode adds progress lines on standard error, prefixed `progress: check-links:`.
- **Reads.** The .md files, their link targets, the baseline; in folder mode or with a baseline it runs `tools/project_baseline.py` through `uv`. **Writes.** Nothing.
- **Repository-root guard.** Not needed: it writes nothing.
- **Example.** A refusal: `bash <workspace>/second-brain/tools/check-links.sh <workspace>/no-such-folder` prints `REFUS : dossier de projet introuvable : ...` and exits `1`.

## propose-link-repairs.sh (engine: propose_link_repairs.py)

- **Role.** Returns a repair plan for the broken links of an adopted project. It applies nothing unless a Mission is named.
- **Called by.** No tool. Prescribed by the `project-bootstrap` skill and `README.md`; tested by `tests/test-project-initiation.sh` and `tests/test-repo-root-guard.sh`.
- **Syntax.** `propose_link_repairs.py <projet> [--apply --mission <fichier>]`.
- **Options.** `--apply` rewrites each link that has a proposal; it requires `--mission` with a file whose name starts with `MISSION-` and whose content contains `type: mission`.
- **How it decides.** A broken link is a relative link (`./` or `../`) to a missing .md, outside code blocks and inline code. A repair is proposed only when the project holds exactly one file of that name.
- **Exit codes and last line.** `0`, with lines `PROPOSE <file>:<line>: <target> -> <new>`, `SANS-PROPOSITION <file>:<line>: <target> (N candidat(s))`, `APPLIQUE <file>:<line>` (with `--apply`), and the last line `PLAN: N lien(s) cassé(s), P réparation(s) proposée(s), A appliquée(s)`. `1`: no argument (usage line), `REFUS : dossier de projet introuvable : <argument>`, or `REFUS : --apply est reserve a une Mission (--mission <fichier MISSION-...> de type mission)`. `2`: refused by the repository-root guard.
- **Reads.** The project's files (the Git listing when the project is a repository, otherwise the disk). **Writes.** With `--apply` only: the lines of the .md files that carry a proposed repair.
- **Repository-root guard.** Yes, checked after the folder exists and before the Mission check or any reading.
- **Example.** A read-only plan: `bash <workspace>/second-brain/tools/propose-link-repairs.sh <workspace>/<project>`. A refusal: `bash <workspace>/second-brain/tools/propose-link-repairs.sh <workspace>` exits `2` with `REPO-ROOT-REFUSED: ... is a workspace root (it carries VAULT-ROOT.md) ... Nothing written.`

## link-graph-drone-view.sh

- **Role.** A measurement of the written links, with no model call and no network: it reads the `## Liens` sections and prints a report.
- **Called by.** No tool. Named in `README.md`; tested by `tests/test-link-graph-drone-view-empty-status-field.sh`.
- **Syntax.** `tools/link-graph-drone-view.sh` (no argument). It reads the repository that holds the script, whatever your current folder.
- **Options.** None. A sibling repository is added only when declared, by the environment variable `SECOND_BRAIN_SIBLING_REPO` or by `<workspace>/SIBLING-REPO.txt` (see `tools/resolve-sibling-repo.sh`); `LINK_GRAPH_WORKSHOP_SUBDIR` names its subfolder (default `workshop-production`). Without a sibling it prints `No sibling repository declared -- analyzing this repository's own corpus only.` on standard error.
- **Output.** A preliminary count, then four measurements: the 15 documents with the most incoming links; orphans; reach from the sibling's state sheet (without a sibling, standard error gets `ANOMALY : fiche d'etat introuvable ...` and the counts are zero); reciprocity of supersession links. Then two Mermaid graphs.
- **Exit codes and last line.** `0`: the last line closes the second Mermaid block. `1`: more than one link in ten is unresolved; standard error gets `ARRET : plus d'un lien sur dix est non resolu (condition d'arret, build history). Aucune mesure rendue.`
- **Reads.** The .md files tracked by Git. **Writes.** Nothing: standard output and standard error only.
- **Repository-root guard.** Not needed: it writes nothing.
- **Example.** `bash <workspace>/second-brain/tools/link-graph-drone-view.sh`. On this Vault (Git Bash, 2026-09-25) it ran for more than ten minutes.

## find-in-vault.sh

- **Role.** Content search in the .md files under a folder. It returns matching lines, never whole files.
- **Called by.** The `internal-search` skill (search by content); `templates/vault-root-template.md`.
- **Syntax.** `find-in-vault.sh [--root <dir>] [--limit N] [--frontmatter-only] <motif>`.
- **Options.** `--root`: the folder to search (default: the current folder; pass it explicitly). `--limit`: maximum number of lines (default 50). `--frontmatter-only`: search only inside each file's front matter. `<motif>` is an extended regular expression.
- **Output.** One line per match, `path:line-number:text`. A line whose file name appears in a superseded-files.txt list found anywhere under the root (written by `tools/build-indexes.sh`) gets ` [REMPLACÉ]`; the mark is only as fresh as the last index build. Folders named .git, .githooks, .claude, .codex, graphify-out, node_modules, .venv, venv and __pycache__ are excluded.
- **Exit codes and last line.** `0`, including when nothing matches (no output). `1`: the usage line when no pattern is given, or `REFUS : racine introuvable : <root>`.
- **Reads.** The .md files and every superseded-files.txt list under the root. **Writes.** Nothing.
- **Repository-root guard.** Not needed: it writes nothing.
- **Example.** `bash <workspace>/second-brain/tools/find-in-vault.sh --root <workspace>/second-brain/rules --limit 3 "repository-root guard"`.

## check-asserted-paths.sh

- **Role.** Pre-commit guardian: checks that the file paths cited between backticks in the normative documents of the repository exist.
- **Called by.** `.githooks/pre-commit` (guardian `chemins-affirmes`); the Mission checklist of the `mission-writing` skill; `README.md`; tests such as `tests/test-check-asserted-paths-constant-launches.sh`.
- **Syntax.** `tools/check-asserted-paths.sh` (no argument; the repository that contains the current folder).
- **Perimeter.** Tracked .md files at the repository root, under `knowledge/` or `templates/`, or whose `type` is `rules` or `decision`, unless their `status` is `superseded`.
- **What counts as a path.** A backticked token whose last segment ends in .md, .yaml, .sh, .txt, .py, .json, .svg, .js, .html, .example or .cjs, or starts with a dot. Tokens with a space, `{{`, `}}`, `<` or `>`, or that start with `$` or `-`, are not paths; neither is a bare folder. Code blocks are not read.
- **Accepted without resolution.** A token followed by `(supprimé)` or `(supprimé, Mission NNN)`; a line marked `(hors Vault)`; a path that leaves the repository or names the declared sibling; a path Git ignores; a short list of known external files. Otherwise the token must exist under the repository root, the document's folder, the declared sibling or the workspace root, or name exactly one tracked file.
- **Exit codes and last line.** When the check runs to its end, standard output ends with `Comptes : fichiers du périmètre=... défauts=N`. `0`: no defect. `1`: each defect prints `CHEMIN-AFFIRME-MORT : <doc>:<line> [<section>] jeton ... introuvable sous les racines candidates` on standard error, then `REFUS : N chemin(s) affirmé(s) introuvable(s).`; also `1` outside a Git repository or when a read fails (`REFUS : ... gardien non executable.`).
- **Reads.** The perimeter files and the list of tracked files. **Writes.** Nothing.
- **Repository-root guard.** Not needed: it writes nothing.
- **Example.** `cd <workspace>/second-brain && bash <workspace>/second-brain/tools/check-asserted-paths.sh` (on this Vault on 2026-09-25: 116 files, 0 defects, about 2 seconds).

## Liens

- `source` — [build-indexes.sh](../../tools/build-indexes.sh)
- `source` — [build_indexes.py](../../tools/build_indexes.py)
- `source` — [check-indexes-fresh.sh](../../tools/check-indexes-fresh.sh)
- `source` — [check_indexes_fresh.py](../../tools/check_indexes_fresh.py)
- `source` — [check-index-weight.sh](../../tools/check-index-weight.sh)
- `source` — [check_index_weight.py](../../tools/check_index_weight.py)
- `source` — [check-links.sh](../../tools/check-links.sh)
- `source` — [propose-link-repairs.sh](../../tools/propose-link-repairs.sh)
- `source` — [propose_link_repairs.py](../../tools/propose_link_repairs.py)
- `source` — [link-graph-drone-view.sh](../../tools/link-graph-drone-view.sh)
- `source` — [find-in-vault.sh](../../tools/find-in-vault.sh)
- `source` — [check-asserted-paths.sh](../../tools/check-asserted-paths.sh)
- `source` — [repo_root_guard.py](../../tools/repo_root_guard.py)
- `source` — [project_baseline.py](../../tools/project_baseline.py)
- `source` — [project-baseline.sh](../../tools/project-baseline.sh)
- `source` — [resolve-sibling-repo.sh](../../tools/resolve-sibling-repo.sh)
- `source` — [project-bootstrap.sh](../../tools/project-bootstrap.sh)
- `source` — [check-project-conformity.sh](../../tools/check-project-conformity.sh)
- `source` — [session-preflight.sh](../../tools/session-preflight.sh)
- `source` — [second-brain-update.sh](../../tools/second-brain-update.sh)
- `source` — [publish-from-laboratory.sh](../../tools/publish-from-laboratory.sh)
- `source` — [bench-folder-guardians.sh](../../tools/bench-folder-guardians.sh)
- `source` — [install.sh](../../install.sh)
- `source` — [install.ps1](../../install.ps1)
- `source` — [pre-commit hook](../../.githooks/pre-commit)
- `source` — [pre-commit hooks declaration](../../.pre-commit-hooks.yaml)
- `source` — [AGENTS.md](../../AGENTS.md)
- `source` — [README.md](../../README.md)
- `source` — [project-bootstrap skill](../../skills/project-bootstrap/SKILL.md)
- `source` — [internal-search skill](../../skills/internal-search/SKILL.md)
- `source` — [session-close skill](../../skills/session-close/SKILL.md)
- `source` — [Mission checklist](../../skills/mission-writing/mission-checklist.md)
- `source` — [Vault root template](../../templates/vault-root-template.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [repository-root guard test](../../tests/test-repo-root-guard.sh)
- `source` — [case-collision test](../../tests/test-build-indexes-case-collision.sh)
- `source` — [project initiation test](../../tests/test-project-initiation.sh)
- `source` — [drone view test](../../tests/test-link-graph-drone-view-empty-status-field.sh)
- `source` — [asserted-paths launches test](../../tests/test-check-asserted-paths-constant-launches.sh)
- `see also` — [Decision: index as locator, 8,000-byte cap, live and archive](../../decisions/DECISION-2026-09-05-124647-index-as-locator-8000-cap-live-archive.md)
- `see also` — [Document linking standard](../../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `see also` — [Guardians and hooks](./guardians-and-hooks.md)
- `see also` — [Internal helpers](./tools-internal-helpers.md)
- `see also` — [Project tools](./tools-projects.md)
- `see also` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `see also` — [Why absolute paths](../explanation/why-absolute-paths.md)
