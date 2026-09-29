---
type: how-to
title: "React to a guardian refusal"
description: "Match each refusal of the commit guardians, the commit-message check, the project hooks and the repository-root guard to its cause and its fix, with commands in absolute-path form."
status: active
---

# REACT TO A GUARDIAN REFUSAL

A guardian refused your commit, or a tool refused its target folder. This page gives, for each refusal, the exact message (copied from the code, French as printed), what it means and how to fix it. The rule never changes: a refusal is a stop, not an obstacle. You fix the cause and run the same command again. An agent never bypasses a guardian (`--no-verify`, or anything else that skips a hook) without the Owner's explicit authorization in the current request, and the commit-message check refuses a message that even mentions such a bypass.

Problems met during installation, the first session or an update are in [Troubleshooting](troubleshoot.md).

**Under Windows.** The remedies below are quoted as the guardians print them, for bash (`Remede : bash tools/…`, relative to the repository concerned). In PowerShell, where `bash` is unknown, start the line with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`, or run it in Git Bash; `sb doctor` says whether `bash` is on your PATH.

## Before you start

- `<workspace>` is the absolute path of your workspace (for example C:/Users/you/Workspaces or /Users/you/Workspaces). Your Vault is `<workspace>/second-brain`, a project is `<workspace>/<project>`.
- `<repo>` below is the absolute path of the repository whose commit was refused: `<workspace>/second-brain` or `<workspace>/<project>`.
- On Windows, run the commands in Git Bash. `uv` must be installed: three guardians run through it (`reciprocite`, `fraicheur-index`, `poids-index`), and a missing `uv` is itself a refusal.

## Steps

1. **Read the report.** The Vault's hook `.githooks/pre-commit` runs all ten guardians, then prints `=== Guardian suite ===`, one line per guardian with `PASS`, `FAIL` or `SKIPPED (blocked by <name>)`, then `--- <name> (FAIL) ---` followed by the output of each failed guardian, and ends with `REFUS : <n> gardien(s) en echec sur 10.`
2. **Fix the failures, not the skips.** A guardian is skipped when a guardian it depends on failed or was skipped. Everything depends on `preflight`; `poids-index` and `liens` also depend on `fraicheur-index`. Fix those first; the skipped ones run again at the next attempt.
3. **Find each message under [Known errors](#known-errors)** and apply its fix.
4. **Replay the whole suite without committing** (it reads, it writes nothing):

   ```bash
   cd <workspace>/second-brain && bash <workspace>/second-brain/.githooks/pre-commit
   ```

5. **Commit again** with the same message, or a reworded one if the commit-message check refused it:

   ```bash
   git -C <repo> commit
   ```

   _Not executed by the documentation check._

## What you should see

The hook ends with `PASS : 10/10 gardiens (0 echec).` and Git records the commit. In a project, each of the four `Vault : ...` hooks is reported as passed by pre-commit.

## Known errors

### preflight (the session stamp)

- `REFUS : preflight absent. Remede : bash tools/session-preflight.sh`, `REFUS : preflight illisible ou ready != true. Remede : bash tools/session-preflight.sh` or `REFUS : preflight perime (> 1440 min). Remede : bash tools/session-preflight.sh` — the local stamp `<workspace>/second-brain/.claude/.preflight_stamp.json` is missing, does not say `"ready": true`, or is older than 24 hours. Fix: run `bash <workspace>/second-brain/tools/session-preflight.sh`. It must print `READY`. If it prints `NOT-READY: <n> issue(s)`, each issue follows on its own line (missing role charter, missing pointer in `AGENTS.md` or `CLAUDE.md`, missing or invalid `.claude/settings.json`, `git` or `bash` not on the PATH, `tools/build-state.sh`, `tools/build-indexes.sh` or `tools/check-links.sh` missing or not executable, hooks log silent for more than 72 hours). Fix each one and run it again. _Not executed by the documentation check._

### Any guardian: the check cannot run

- `REFUS : garde-fou introuvable : <script>` or `REFUS : uv introuvable, impossible d'executer <script>` — the hook refuses rather than skip a check it cannot run. Restore the script (an update, see [Update](update.md)) or install `uv`.
- `REFUS : hors d'un depot Git : gardien non executable.` — the guardian was started outside a Git repository. Run it from inside `<repo>` (`cd <repo> && ...`).

### reciprocite (supersedes and amends links)

Checks the staged Markdown files. Each problem is one line `OBSOLESCENCE [<rule>] <file>: <detail>`:

- ``[R1] ... reciprocite absente : <file> `supersedes` <target>, <target> ne porte pas `superseded by` vers <file>`` (or `amends` / `amended by`) — add, in the `## Liens` section of the target, the inverse line pointing back: `` - `amended by` — [<title>](<relative path to your file>) ``.
- ``[R1] ... incoherence front-matter/Liens pour `<field>`/`<type>` `` — the `supersedes:` or `amends:` field of the front matter and the `supersedes` or `amends` lines of `## Liens` do not name the same files. Make the two lists identical.
- `[R1] ... reciprocite non verifiable, <target> missing` (or `unreadable`) — the target cannot be read; fix its path or its front matter.
- `[R2] ... statut incoherent : <target> declare remplace par <file> mais porte encore status='active'` — set `status: superseded` in the target's front matter and stage it.
- ``[R3] ... cible introuvable pour `<type>`: <path>`` (or ``cible introuvable pour front-matter `<field>`: <path>``) — a link typed `applies`, `supersedes`, `amends`, `source`, `prescribed by` or `see also` points to no file. Correct the relative path. A target that lives outside the Vault is written with the suffix `(hors Vault)` after the link.
- `[FM] ... front-matter illisible` — the front matter uses a form the guardian does not read: flat `key: value` lines, lists or one-level sub-keys indented by two spaces, closed by `---`.
- The closing line `REFUS : <n> violation(s) de reciprocite/statut/cible. ...` also names a traced override file. That is not a fix: correct the links.

### fraicheur-index (index freshness)

- `INDEX-FRESHNESS [<folder>]`, then `Ecart : <gap>` (missing entry, extra entry, `status desynchronise`, or `dossier indexe sans index.md`), then `Consigne : bash tools/build-indexes.sh <racine> ; git add <index> ; relire git diff --cached`. The index of that folder does not match the staged files. Fix: `bash <workspace>/second-brain/tools/build-indexes.sh <repo>`, then `git -C <repo> add <folder>/index.md`, then read `git -C <repo> diff --cached` and commit again. _Not executed by the documentation check._
- `INDEX-CASE-COLLISION [<folder>]` with `Remedy : never regenerate this folder in full mode; ...` — the folder tracks a case variant of `index.md` (INDEX.md, Index.md). Do not regenerate it: the message names the options (declare the folder exempt, or rename the file), and the choice is the Owner's.
- `INDEX-LINE-CAP [missions/MISSION-INDEX.md]`, `Ligne : <n> (Mission <NNN>)`, `Longueur : <n> caracteres > 300 (Decision 191407)` — see the next section.

### poids-index (index weight)

- `INDEX-WEIGHT [<index>]` with `Ecart : index de <n> octets > 8000 (DECISION-2026-09-05-124647)` — a staged index is over 8,000 bytes. Its `Consigne` says to lighten it: one line per entry as a locator, or a split between a live index and an archive, which `bash <workspace>/second-brain/tools/build-indexes.sh <repo>` produces. Stage the result. _Not executed by the documentation check._
- `INDEX-WEIGHT [<register>]` with `Ecart : ligne <n> (Mission <NNN>) de <n> caracteres > 300 (DECISION-2026-09-02-191407)` — a line of the Mission register (after Mission 122) is too long. Shorten it to an execution status, with no story, as the `Consigne` says.

### secrets

- `REFUS : fichier(s) au nom interdit dans le staging :` followed by the names — a staged file is named like a secret or a data dump (a dot-env file; the extensions key, pem, pfx, p12, crt, cer, der, jks, keystore, sql, dump, sqlite, db, mdb; a folder named secret, secrets, credential or credentials). Only `.env.example` is allowed. Take it out of the commit, keeping it on disk: `git -C <repo> rm --cached -- <file>`. _Not executed by the documentation check._
- `REFUS : motif de secret detecte.`, `motif : <pattern>`, `(valeur non affichee)` — an added line matches a pattern of `rules/patterns/secret-patterns.txt`. The message says what to do: remove the value from the file, put it in a local dot-env file that Git does not track, and document the expected key in `.env.example`. Then stage the cleaned file. The `sk-` pattern takes a key only at the start of a line or after a character that is not a letter or a digit, so `risk-assessment-…` or `task-based-…` is not a secret (Mission 229).

### liens (links)

- `LIENS: section manquante: <file>` — every staged Markdown file needs a `## Liens` section (outside the Vault's own adopted folders `skills/external/` and `skills-warehouse/`). Add it. In a project, if the file comes from a third party and must stay byte-identical (an installed framework, a vendored folder), do not edit it: exempt its folder in the project's birth certificate, on the `# exempt:` line of `<workspace>/<project>/.pre-commit-config.yaml` (prefixes ending with `/`, separated by spaces), or one prefix per line in `<workspace>/<project>/.vault-exempt`. The link, index-freshness and index-weight guardians then skip it; the secrets check never does.
- `LIENS: cible introuvable: <file>:<line> -> <target>` — a relative link to a Markdown file resolves to nothing. That includes a bare link such as `README.md` or `docs/guide.md`, read as `./README.md`. Correct the path.
- `LIENS: avertissement ...` lines (no internal link, target repository absent) are warnings: they never block.

### chemins-affirmes (asserted paths)

- ``CHEMIN-AFFIRME-MORT : <file>:<line> [<section>] jeton `<token>` introuvable sous les racines candidates``, then `REFUS : <n> chemin(s) affirmé(s) introuvable(s).` — a file path written between backticks in a rule, a Decision, a file under `knowledge/` or `templates/`, or a file at the repository root, names no file. It checks the whole corpus, not only your staged files: deleting or renaming a file can make an untouched document fail. Fix the path in the named document. If the file was removed on purpose, write `(supprimé)` or `(supprimé, Mission <NNN>)` right after the token, as the guardian's own rule provides.

### manifeste (distribution manifest)

`distribution-manifest.txt` holds one line per tracked file: the path, a tab, `DISTRIBUABLE` or `INTERNE`. The guardian ends with `REFUS : le manifeste ne passe pas les controles ci-dessus.` after one or more of:

- `ABSENT-DU-MANIFESTE : fichier suivi sans ligne au manifeste :` — add a line for each file listed.
- `FANTOME-AU-MANIFESTE : chemin du manifeste non suivi par Git :` — remove the lines of files that Git no longer tracks.
- `DOUBLON-AU-MANIFESTE : chemin present plus d'une fois :` — keep one line.
- `VERDICT-INVALIDE : ligne <n>, <path> : verdict '<v>' ni DISTRIBUABLE ni INTERNE` — correct the verdict.
- `INCOHERENCE-DISTRIBUTABLE : <path> porte 'distributable: false' en front-matter mais le manifeste le classe DISTRIBUABLE` (or the reverse) — make the front matter and the manifest agree.
- `LOCAL-FILE-DISTRIBUTED : USER.local.yaml is machine-local and never distributed: ...` — follow the message: remove its manifest line and run `git -C <repo> rm --cached -- USER.local.yaml`. _Not executed by the documentation check._

Stage `distribution-manifest.txt` with your fix.

### sans-agents (no Claude Code command in the docs)

- `REFUS : mention de la commande Claude Code '<command>' trouvee dans la documentation :` followed by `<file>:<line>:<text>` for each hit. This page writes `<command>` because the real message quotes Claude Code's command made of a slash and the word agents, and this guardian would refuse this very page if it were spelled out. The remedy line says: `Remede : remplacer par la facon d'appeler l'assistant en le nommant, avec un exemple (ex. "demande a Brian : ...").` Rewrite the sentence to call the assistant by its name.

### bit-execution (execute bit)

- `REFUS : <path> invoque nu (bare) mais mode 100644 (bit d'execution absent de l'index).` (or `hook Git (execute par Git, qui ignore un hook non executable)` for a file under `.githooks/`), then `Remede : git update-index --chmod=+x <chemin(s) ci-dessus>.` — a script called without `bash` in front, or a hook, lacks the execute bit in Git's index (Windows never shows it). Fix: `git -C <repo> update-index --chmod=+x <path>`, then commit again. _Not executed by the documentation check._

### Commit message: bypass patterns

`.githooks/commit-msg` compares the message with `rules/patterns/bypass-patterns.txt`, ignoring case and matching any part of a word: `--no-verify`, `--force`, `skip hook`, `bypass`, `contourne`, `temporaire`, `provisoire`, `quick fix`, `wip`.

- `REFUS : motif de contournement dans le message de commit.`, `motif : <pattern>`, `Reformule le message. Un commit se decrit par ce qu il fait.` — describe what the commit does, without those words, and commit again.

### Project hooks (vault-check-*)

A project with `vcs: git` runs four hooks through pre-commit, pinned in its `<workspace>/<project>/.pre-commit-config.yaml` on your Vault's scripts: `vault-check-secrets` (`Vault : contrôle de secrets`), `vault-check-indexes-fresh`, `vault-check-index-weight` and `vault-check-links`. They print the same messages as [secrets](#secrets), [fraicheur-index](#fraicheur-index-index-freshness), [poids-index](#poids-index-index-weight) and [liens](#liens-links) above; apply the same fixes with `<repo>` = `<workspace>/<project>`. A project with `vcs: none` has no hook: you run the checks by command, for example `bash <workspace>/second-brain/tools/check-links.sh <workspace>/<project>`. That form adds `REFUS : dossier de projet introuvable : <path>` (wrong folder). In either form, a project with an adoption baseline can also get `REFUS : ligne de base illisible, le controle ne peut pas verifier.` (the baseline cannot be read).

### Repository-root guard: REPO-ROOT-REFUSED

Tools that write (`tools/build-indexes.sh`, `tools/append-journal.sh`, `tools/build-state.sh`, `tools/build-digest.sh`, `tools/set-release-version.sh`, `tools/vault-identity.sh` ensure, `tools/propose-link-repairs.sh`, `tools/project-bootstrap.sh` create and adopt) first ask `tools/repo_root_guard.py` whether the target may be written. Below, `<expected>` stands for `the root of a Git repository, or a folder inside one, or a project with a birth certificate, below the workspace root`. Nothing is written after any of these lines:

- `REPO-ROOT-REFUSED: <received> (<absolute>) is not inside a repository: <folder> is a workspace root (<reason>). Expected <expected>, for example <folder>/<repository>. Nothing written.` — you gave the workspace root, often as `.`. `<reason>` is `it carries VAULT-ROOT.md` or `it holds <n> Git repositories without being one`.
- `REPO-ROOT-REFUSED: <received> (<absolute>) is in no Git repository and carries no birth certificate; expected <expected>. Nothing written.`
- `REPO-ROOT-REFUSED: <received> (<absolute>) is not a folder; expected <expected>. Nothing written.`
- `REPO-ROOT-REFUSED: <received> (<absolute>) is a workspace root (<reason>); a project is created in its own folder below it, e.g. <absolute>/<project>. Nothing written.` — from the project bootstrap only.

Fix: run the same command again with the absolute path of the right repository, for example `bash <workspace>/second-brain/tools/build-indexes.sh <workspace>/<project>` (_Not executed by the documentation check._). There is no switch that turns the guard off. `tools/set-release-version.sh` adds `REFUS : racine refusee par le garde-fou : <root>` and `REFUSED`.

## Scripts used

- The ten guardians and the two hooks: see [Guardians and hooks](../reference/guardians-and-hooks.md) and [Tools: guardians](../reference/tools-guardians.md).
- `tools/session-preflight.sh` and `tools/repo_root_guard.py`: their source files are listed below.

## Liens

- `source` — [Native pre-commit hook](../../.githooks/pre-commit)
- `source` — [Commit-message hook](../../.githooks/commit-msg)
- `source` — [Rule — Guardrails and evidence levels](../../rules/RULES-2026-08-19-210803-guardrails-and-evidence-levels.md)
- `source` — [Bypass patterns](../../rules/patterns/bypass-patterns.txt)
- `source` — [Session preflight](../../tools/session-preflight.sh)
- `source` — [Reciprocity guardian](../../tools/check-obsolescence-guardrail.py)
- `source` — [Index freshness launcher](../../tools/check-indexes-fresh.sh)
- `source` — [Index freshness guardian](../../tools/check_indexes_fresh.py)
- `source` — [Index weight launcher](../../tools/check-index-weight.sh)
- `source` — [Index weight guardian](../../tools/check_index_weight.py)
- `source` — [Secrets guardian](../../tools/check-secrets.sh)
- `source` — [Secret patterns](../../rules/patterns/secret-patterns.txt)
- `source` — [Links guardian](../../tools/check-links.sh)
- `source` — [Asserted-paths guardian](../../tools/check-asserted-paths.sh)
- `source` — [Distribution manifest guardian](../../tools/check-distribution-manifest.sh)
- `source` — [No-command guardian](../../tools/check-no-slash-agents.sh)
- `source` — [Execute-bit guardian](../../tools/check-exec-bit-bare-scripts.sh)
- `source` — [Index builder, refusal summary](../../tools/build_indexes.py)
- `source` — [Release version tool](../../tools/set-release-version.sh)
- `source` — [Project hooks](../../.pre-commit-hooks.yaml)
- `source` — [Project bootstrap, pinned hooks](../../tools/project-bootstrap.sh)
- `source` — [project-bootstrap skill, vcs none checks](../../skills/project-bootstrap/SKILL.md)
- `source` — [Repository-root guard](../../tools/repo_root_guard.py)
- `source` — [Rule — Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Troubleshooting](troubleshoot.md)
- `see also` — [Guardians and hooks](../reference/guardians-and-hooks.md)
- `see also` — [Tools: guardians](../reference/tools-guardians.md)
- `see also` — [Why the guardians](../explanation/guardians.md)
- `see also` — [Why absolute paths](../explanation/why-absolute-paths.md)
- `see also` — [Update](update.md)
