---
type: how-to
title: "Add a skill"
description: "Add a skill of your own or a third-party skill to Second Brain, with its triggers, index, manifest lines, provenance and licence, and get it linked into your projects for Claude Code and Codex."
status: active
---

# ADD A SKILL

This guide adds one skill to your Second Brain and brings it into your projects. It covers two cases: a skill of your own, in its own folder under `skills/`, and a third-party skill, under `skills/external/`. The list of the skills already shipped, and how you invoke them, is in the [skills reference](../reference/skills.md); this page does not repeat it.

In the commands, `<workspace>` is the absolute path of your workspace (for example `C:/Users/you/Workspaces`), the installed Second Brain is `<workspace>/second-brain`, a project is `<workspace>/<project>`, and `<name>` is the skill's folder name.

**Under Windows.** The `bash <workspace>/second-brain/tools/…` lines of this page are typed by the Executor, in its own shell (Git Bash under Windows). To type one yourself in PowerShell, where `bash` is unknown, replace `bash` with `& "C:\Program Files\Git\bin\bash.exe"`, or type the `sb` verb that carries the gesture ([Commands](../reference/commands.md)); `sb doctor` says whether `bash` is on your PATH.

## Before you start

- **Git Bash** (Windows) or a terminal (macOS, Linux), and `uv`: the index builder and the link step run through it.
- **Pick the name once.** The folder name is the name of the link placed in each project, so it is what your tools see. Keep the `name:` field equal to the folder name, as every shipped skill does (the [provenance note](../../skills/external/PROVENANCE.md) records that match for the 33 skills of the warehouse package).
- **Check the name is free.** If the same name exists in `skills/` and in `skills/external/`, only the one in `skills/` is linked ([sb_installer_helper.py](../../tools/sb_installer_helper.py), `_merge_skill_entries`).
- **A third-party skill needs its origin and its licence in hand** before it enters: source address, frozen commit or archive checksum, licence evidence.

## Steps

### A skill of your own

1. **Create the folder and its SKILL.md.** Create `<workspace>/second-brain/skills/<name>/` and, inside it, a file named SKILL.md. Only a folder that holds a SKILL.md is linked; any other folder is skipped. The seven shipped skills open with this front matter (see [internal-search](../../skills/internal-search/SKILL.md) or [session-close](../../skills/session-close/SKILL.md)):

   ```markdown
   ---
   name: <name>
   description: "<What it does, one sentence>. Use when <situation>. Triggers on: « <French phrase> », « <French phrase> », \"<English phrase>\"."
   license: "MIT"
   metadata:
     vault-implements: "<rules/... or decisions/... files it applies>"
     vault-validated: "<date and time, ISO 8601>"
   ---
   ```

   Then write the instructions, in English. The body of a skill under `skills/` is part of the distributed corpus, which [the language test](../../tests/test-corpus-language-english.sh) reads; your French trigger phrases stay far below its threshold.

2. **Write the triggers in both languages.** The `description:` is what Claude Code and Codex read to decide when the skill applies. End it with `Triggers on:` and the phrases that should wake it: French phrases in « », English phrases in escaped double quotes. The test [test-skill-triggers-bilingual.sh](../../tests/test-skill-triggers-bilingual.sh) holds a closed list, one line per skill (`skill|French phrases;...|English phrases;...`, in its `TRIGGERS` block). Add a line for your skill there so the test guards it, then run it (read-only):

   ```bash
   bash <workspace>/second-brain/tests/test-skill-triggers-bilingual.sh
   ```

3. **Keep the description short.** Every character counts toward the Codex budget (see "Make it reach your projects" below).

4. **Generate the folder's index.** Each skill folder carries an `index.md` written by the index builder, never by hand. Build it for the new folder only:

   ```bash
   bash <workspace>/second-brain/tools/build-indexes.sh <workspace>/second-brain/skills/<name>
   ```
   _Not executed by the documentation check._

   Do not point the builder at `<workspace>/second-brain/skills` itself: [skills/index.md](../../skills/index.md) is written by hand, and the builder refuses a folder whose `index.md` it did not generate (`INDEX-CASE-COLLISION`, below).

5. **List the skill in the skills index, by hand.** Add one line to [skills/index.md](../../skills/index.md), in the form of the others: the folder, a short purpose, and a link to its SKILL.md. That new link changes the link targets of a distributed file, so declare it in [corpus-link-targets-changes.tsv](../../tests/fixtures/corpus-link-targets-changes.tsv), one tab-separated line: `+`, the file, the target, then the Mission and reason. The `update` skill was declared exactly this way. The two lines, index first, then fixture:

   ```text
   - `<name>/` — <short purpose> — see [SKILL.md](./<name>/SKILL.md).
   +	skills/index.md	./<name>/SKILL.md	<Mission> -- <reason>
   ```

6. **Add the manifest lines.** Every file Git tracks, outside a few areas the check exempts (such as `skills-warehouse/`), needs one line in [distribution-manifest.txt](../../distribution-manifest.txt): the path, a tab, then `DISTRIBUABLE` or `INTERNE`. A skill meant for everyone is `DISTRIBUABLE`:

   ```text
   skills/<name>/SKILL.md	DISTRIBUABLE
   skills/<name>/index.md	DISTRIBUABLE
   ```

   One line per companion file too (a checklist, a template), next to the other lines of `skills/`.

7. **Stage, check, commit.** The manifest check compares the manifest with `git ls-files`, so run it after staging:

   ```bash
   git -C <workspace>/second-brain add skills/<name> skills/index.md distribution-manifest.txt tests/test-skill-triggers-bilingual.sh tests/fixtures/corpus-link-targets-changes.tsv
   cd <workspace>/second-brain && bash tools/check-distribution-manifest.sh
   bash <workspace>/second-brain/tests/test-links-targets-unchanged.sh
   git -C <workspace>/second-brain commit -m "skills: add <name>"
   ```
   _Not executed by the documentation check._

   The pre-commit hook runs the guardians, among them `manifeste` and `fraicheur-index` ([guardians](../explanation/guardians.md)).

### A third-party skill

`skills/external/` holds third-party material only, never Second Brain's own skills ([provenance note](../../skills/external/PROVENANCE.md)). The steps above apply, with these differences:

1. **Folder.** `<workspace>/second-brain/skills/external/<name>/`. The body and the companion files stay exactly as the author wrote them; the language test excludes this folder.
2. **Front matter: six fields at most.** `name`, `description`, `license`, `compatibility`, `allowed-tools`, `metadata`. A skill carrying any other field (for example `disable-model-invocation`) does not enter as it is. Under `metadata:`, only string-to-string pairs, which carry the provenance. The [tdd skill](../../skills/external/tdd/SKILL.md) shows the set in use: `upstream-repo` (frozen source), `upstream-license-evidence` (address of the licence proof), `vault-source` and `vault-source-sha256` (the package it came from and its checksum), `vault-body-sha256` (checksum of the body after the closing `---`), `vault-entered` (date).
3. **Licence.** Put the real licence in `license:`, never rewritten to MIT. Keep the licence text: the upstream LICENSE file verbatim inside the skill folder (as [scroll-world](../../skills/external/scroll-world/LICENSE) does), or, for skills from the mattpocock repository, the shared [LICENSE-mattpocock-skills.txt](../../skills/external/LICENSE-mattpocock-skills.txt). A licence outside the default permissive policy (`AGPL-3.0-only`), or none at all (`NOASSERTION`), enters only by an Owner decision, recorded as an entry in [OWNER-EXCEPTIONS.md](../../skills/external/OWNER-EXCEPTIONS.md): skill, licence, source, finding, dated decision. `NOASSERTION` is never a permission to redistribute.
4. **Provenance.** Add a dated line to the cycle journal of [PROVENANCE.md](../../skills/external/PROVENANCE.md): what entered, from which source and checksum, and the new count of the library.
5. **Index.** Build the index of the new folder with `bash <workspace>/second-brain/tools/build-indexes.sh <workspace>/second-brain/skills/external/<name>`, then update the count in the line for `skills/external/` in [skills/index.md](../../skills/index.md) (40 today). No link change there, so no declaration in the fixture.
6. **Manifest.** One `DISTRIBUABLE` line per file of the folder, as for the others under `skills/external/`.

### Where the warehouse fits

`skills-warehouse/` is a separate warehouse of vetted skills: it resolves sources, deduplicates them, keeps their provenance and produces validated archives ([warehouse README](../../skills-warehouse/README.md)). It follows its own rules (read its `skills-warehouse/AGENTS.md` before working there) and is outside the distribution manifest. Nothing in it is ever linked into a project: [deploy-skills.ps1](../../tools/deploy-skills.ps1) and `link-project` read only `skills/` and `skills/external/`. A warehouse skill reaches your projects only once it is placed in `skills/external/` by the steps above; the current library of 40 was built from a warehouse package on 2026-09-01: 33 skills from the package itself, 7 converted from the earlier library ([provenance note](../../skills/external/PROVENANCE.md)).

### Make it reach your projects

Skills are linked, never copied, and never placed in your profile. `tools/project-bootstrap.sh` calls the `link-project` subcommand of `tools/sb_installer_helper.py` with the clone and the project, which links every skill folder of `skills/` and `skills/external/` into `<project>/.claude/skills/<name>` (Claude Code) and `<project>/.agents/skills/<name>` (Codex). On Windows the link is an NTFS junction; elsewhere a symbolic link.

- **A project created after your commit** gets the new skill with the others.
- **An existing project** already links each skill folder, so an edit to an existing skill reaches it at once. A new folder has no link there yet. Rerunning the adoption creates what is missing and leaves existing links as they are (`AlreadyLinked`):

  ```bash
  bash <workspace>/second-brain/tools/project-bootstrap.sh adopt <workspace>/<project> --vcs git
  ```
  _Not executed by the documentation check._

  Use `--vcs none` for a project without Git. The [project-bootstrap skill](../../skills/project-bootstrap/SKILL.md) runs this only on a Mission, a dated initiation order or an Owner arbitration, because it writes into the registry ([adopt a project](adopt-a-project.md)).

**The Codex description budget.** `link-project` adds up the length of the `description:` of every skill in `skills/` and `skills/external/` and compares it with `MAX_CODEX_DEFAULT_SKILLS_BUDGET = 8000` ([sb_installer_helper.py](../../tools/sb_installer_helper.py); the same ceiling, `$Script:MaxCodexDefaultSkillsBudget = 8000`, in [deploy-skills.ps1](../../tools/deploy-skills.ps1)). Over 8000 characters, Codex receives `skills/` only and Claude Code still receives everything; it is never a stop. The header of `deploy-skills.ps1` records 7451 characters on 2026-09-12.

## What you should see

- The trigger test ends with `  PASS - <name>: French and English triggers present` for your line, then `=== RESULT: PASS ===`.
- The manifest check prints `Comptes : DISTRIBUABLE=<n> INTERNE=<n> TOTAL=<n>` and exits 0.
- The link test ends with `=== RESULT: PASS ===`.
- New files: `<workspace>/second-brain/skills/<name>/SKILL.md` and its `index.md`; for a third-party skill, its licence file when it has one.
- In each linked project: `<project>/.claude/skills/<name>` and `<project>/.agents/skills/<name>`, both pointing at the clone's folder. Adoption prints nothing about a skill that linked cleanly.

## Known errors

| Message | Cause | What to do |
|---|---|---|
| `missing French trigger « <phrase> » (<name>)` or `missing English trigger "<phrase>" (<name>)` | the `description:` lost a phrase listed in the test | put the phrase back, word for word |
| `FAIL - <name>: SKILL.md not found` | a test line names a folder with no SKILL.md | fix the folder name in the line or in `skills/` |
| `ABSENT-DU-MANIFESTE : fichier suivi sans ligne au manifeste :` then the paths | a staged file has no manifest line | add one line per path, with its verdict |
| `FANTOME-AU-MANIFESTE : chemin du manifeste non suivi par Git :` | a manifest line names a file Git does not track | stage the file, or fix the path |
| `DOUBLON-AU-MANIFESTE : chemin present plus d'une fois :` | the same path twice | keep one line |
| `VERDICT-INVALIDE : ligne <n>, <path> : verdict '<v>' ni DISTRIBUABLE ni INTERNE` | a typo, or a space instead of the tab | write the path, a tab, then one of the two words |
| `INDEX-FRESHNESS [<folder>]` then `dossier indexe sans index.md (...)` | the new folder was committed without its index | step 4, then stage the `index.md` |
| `INDEX-CASE-COLLISION : <path> exists and was not generated` | the builder was pointed at a folder with a hand-written index, such as `skills/` | point it at the new skill folder only |
| `  FAIL - added:` then a line naming the skills index and the new link | the new link in the skills index is not declared | add the `+` line of step 5 to the changes fixture |
| `Note: <n> link(s) already occupied by something else in this project -- left untouched, the existing file/folder always wins:` | something already sits at `<project>/.claude/skills/<name>` or `<project>/.agents/skills/<name>` | remove or rename that item yourself, then rerun |
| `Note: combined skill description budget exceeds the Codex ceiling in this project -- Codex received skills/ only, Claude Code received everything (Doctrine rule 3).` | descriptions total over 8000 characters | shorten descriptions, then rerun the adoption |
| `Note: .gitignore hides whole folders below; they also hide any skill this project installs there. The links are now kept out of Git by each folder's own .gitignore: these lines can be removed (the file is left as it is):` | the project's own .gitignore carries a folder-wide line that also hides the skills the project installs there | remove the printed lines if you want those skills tracked; the links stay out of Git either way (Mission 231) |
| `REFUS : la creation des liens (assistant/skills) dans <path> a echoue` | `link-project` failed; exit code 1 | read the error above it, fix, rerun |

The `Note:` lines come from [catalog.en.json](../../i18n/catalog.en.json); in a French or Spanish installation they appear in that language.

## Scripts used

- `tools/project-bootstrap.sh` — adoption and the link step: [project tools](../reference/tools-projects.md)
- `tools/sb_installer_helper.py` (`link-project`) and `tools/deploy-skills.ps1` — linking and the Codex budget: [install and update tools](../reference/tools-install-and-update.md)
- `tools/build-indexes.sh` — the folder's index: [index and link tools](../reference/tools-indexes-and-links.md)
- `tools/check-distribution-manifest.sh` — the `manifeste` guardian: [guardian tools](../reference/tools-guardians.md)
- `tests/test-skill-triggers-bilingual.sh` and `tests/test-links-targets-unchanged.sh` — the two tests named above: [guardians and hooks](../reference/guardians-and-hooks.md)

## Liens

- `source` — [Vault skills index](../../skills/index.md)
- `source` — [internal-search skill](../../skills/internal-search/SKILL.md)
- `source` — [session-close skill](../../skills/session-close/SKILL.md)
- `source` — [project-bootstrap skill](../../skills/project-bootstrap/SKILL.md)
- `source` — [tdd skill, external](../../skills/external/tdd/SKILL.md)
- `source` — [scroll-world licence](../../skills/external/scroll-world/LICENSE)
- `source` — [Provenance of the external library](../../skills/external/PROVENANCE.md)
- `source` — [Owner exceptions to the licence policy](../../skills/external/OWNER-EXCEPTIONS.md)
- `source` — [mattpocock skills licence](../../skills/external/LICENSE-mattpocock-skills.txt)
- `source` — [Test: bilingual skill triggers](../../tests/test-skill-triggers-bilingual.sh)
- `source` — [Test: link targets unchanged](../../tests/test-links-targets-unchanged.sh)
- `source` — [Declared link changes](../../tests/fixtures/corpus-link-targets-changes.tsv)
- `source` — [Test: corpus in English](../../tests/test-corpus-language-english.sh)
- `source` — [Installer helper, link-project](../../tools/sb_installer_helper.py)
- `source` — [Skill deployment by link](../../tools/deploy-skills.ps1)
- `source` — [Project bootstrap script](../../tools/project-bootstrap.sh)
- `source` — [Index builder](../../tools/build-indexes.sh)
- `source` — [Index builder, Python](../../tools/build_indexes.py)
- `source` — [Index freshness guardian](../../tools/check_indexes_fresh.py)
- `source` — [Distribution manifest](../../distribution-manifest.txt)
- `source` — [Manifest check](../../tools/check-distribution-manifest.sh)
- `source` — [English message catalogue](../../i18n/catalog.en.json)
- `source` — [Skills warehouse README](../../skills-warehouse/README.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `see also` — [Skills reference](../reference/skills.md)
- `see also` — [Adopt a project](adopt-a-project.md)
- `see also` — [Create a project](create-a-project.md)
- `see also` — [React to a guardian refusal](react-to-a-guardian-refusal.md)
- `see also` — [Guardians](../explanation/guardians.md)
