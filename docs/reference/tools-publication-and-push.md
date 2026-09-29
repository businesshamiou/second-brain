---
type: reference
title: "Publication and push tools"
description: "One sheet per script for pushing a branch safely, publishing a laboratory, setting the release version, and producing licences, backup checks and warehouse packages."
status: active
---

# PUBLICATION AND PUSH TOOLS

This page describes, script by script, the tools that send work out of your machine or package it: the verified push, the publication of a laboratory, the version it names, and three helpers (third-party licences, backup check, warehouse packages). In the commands, `<workspace>` is the absolute path of your workspace (for example C:/Users/you/Workspaces or /Users/you/Workspaces) and your installed Vault is `<workspace>/second-brain`. The rule behind the push tool is [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md).

**Under Windows.** A `bash …/tools/…` line of this page, typed in PowerShell where `bash` is unknown, starts with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`; where an `sb` verb carries the same gesture ([Commands](commands.md)), type the verb. `sb doctor` says whether `bash` is on your PATH.

## verified-push.sh

**Role.** The one way a Mission, a report or a block handed to the Owner prescribes a push (new in Mission 226). It pushes exactly the range it is given, to the branch the repository is on, and nothing else: never a forced push, never a tag.

**Called by.** No tool calls it; people and agents do. It is prescribed by `templates/mission-template.md`, `templates/handoff-template.md`, `skills/session-close/SKILL.md` and item 31 of `skills/mission-writing/mission-checklist.md`. Tested by `tests/test-verified-push.sh` and, for the declared address of a repository that is not a Vault, `tests/test-verified-push-declared-url.sh`.

**Syntax.** `verified-push.sh <absolute repository path> <from>..<to> [<remote>] [--url <url>] [--dry-run]`

**Options.**

| Option | Effect |
|---|---|
| `<remote>` | The remote to push to. Default `origin`. |
| `--url <url>` | The push URL you expect that remote to have; it always comes first. Without it, the tool reads `vault_origin` from `VAULT-IDENTITY.md` at the repository root (a Vault); otherwise, since Mission 231, the `# push_url:` key of the birth certificate that heads the repository's `.pre-commit-config.yaml` (a project, the workshop; a `# push_url:` line outside a certificate declares nothing). A repository that declares neither needs `--url`. A trailing slash or a final .git does not matter in the comparison. |
| `--dry-run` | Runs every check, pushes nothing, ends on `WOULD-PUSH`. |

**Refusals.** Each one prints `VERIFIED-PUSH-REFUSED: <reason>. Nothing pushed.` on the error output and exits 1. In the order the checks run:

| Reason printed (shortened) | Cause |
|---|---|
| `--url needs a value` · `--force is never accepted` · `unknown option` · `too many arguments` | `--url` with nothing after it; `--force`, `-f`, `--force-with-lease`, or anything else extra on the line. |
| `repository path is not absolute` · `no such folder` | A relative path (`.` included), or a folder that does not exist. |
| `<path> is in no Git repository` · `<path> is not the root of its repository (<root>)` | The workspace root, a folder in no repository, or a sub-folder. |
| `range is not <from>..<to>` · `<from> is not a commit` · `<to> is not a commit` | A malformed range, or an end that is not a commit. |
| `HEAD is detached` · `HEAD (<short>) is not <to>` | No branch checked out, or its head is not the end of your range. |
| `no remote named '<remote>'` · `declares no remote` | The remote is missing, or no `--url`, no `vault_origin` and no `# push_url:` in a birth certificate. |
| `remote '<remote>' pushes to <url>, not to the declared <url>` | The remote points somewhere other than the declared URL. |
| `cannot read refs/heads/<branch>` · `remote head of <branch> is <sha>, not <from>` | Network or missing branch; or someone else pushed, or your range is stale. |
| `<to> ... does not descend from <from>` · `git push failed` | Not a fast-forward; or Git itself refused. |

**Exit codes and last line.** Exit 0: `WOULD-PUSH <remote> <branch> <from>..<to> (<push url>)` with `--dry-run`; otherwise a line `ls-remote <remote> refs/heads/<branch>: <hash>`, then `PUSHED <remote> <branch> <from>..<to>` (hashes shortened to seven characters). Exit 1: a refusal above; the usage line alone when the path or the range is missing; or, after the push, `VERIFIED-PUSH-MISMATCH: the remote reads <hash> after the push, not <to>`.

**Reads.** The repository's Git state, `VAULT-IDENTITY.md` at its root, the birth certificate of its `.pre-commit-config.yaml`, the remote's head (`git ls-remote`). **Writes.** Nothing local; the push itself, `git push <remote> <to>:refs/heads/<branch>`.

**Repository-root guard.** It does not use `tools/repo_root_guard.py`; it carries its own check: an absolute path that is the root of a Git repository, nothing else.

**Example.** A refusal, safe to run in any Vault; it prints `VERIFIED-PUSH-REFUSED: <workspace>/second-brain/tools is not the root of its repository (<workspace>/second-brain); a sub-folder is never pushed from. Nothing pushed.`

```bash
bash <workspace>/second-brain/tools/verified-push.sh <workspace>/second-brain/tools HEAD~1..HEAD --dry-run
```

A check without pushing, then the real push of a project, which declares no remote:

```bash
bash <workspace>/second-brain/tools/verified-push.sh <workspace>/second-brain <from>..<to> --dry-run
bash <workspace>/second-brain/tools/verified-push.sh <workspace>/<project> <from>..<to> origin --url <url>
```
_Not executed by the documentation check._

## publish-from-laboratory.sh

**Role.** Publishes a laboratory Vault (one that has a `release` remote) in one command: one commit on the local branch `publish` carrying the tree of your `main`, then `git push release publish:main` as a fast-forward, never forced. It is one of the two named exceptions to the verified push. The full procedure, and the tag you pose afterwards, are in [Publishing](../how-to/publish.md).

**Called by.** No tool; the maintainer runs it. Tested by `tests/test-publish-from-laboratory.sh`, `tests/test-publish-private-check-before-push.sh` and `tests/test-publish-version-line.sh`. `tools/check-work-regime.sh` counts a change to this script as a guardian change (criterion `R6-guardians`).

**Syntax.** `publish-from-laboratory.sh [--version <vX.Y.Z>] [--dry-run] [--message-file <file>]`

**Options.**

| Option | Effect |
|---|---|
| `--version <vX.Y.Z>` | Runs `tools/set-release-version.sh` on the publication tree before the commit, so the install line names that tag. Refused when the tag is not `vX.Y.Z` or already exists on `release`. Your `main` is never rewritten. |
| `--dry-run` | Goes up to and including the private-pattern check, then resets the publication worktree to `publish`: nothing committed, nothing pushed. |
| `--message-file <file>` | The commit message comes from this file. Default: `Publish the laboratory's main <short hash>`. |

**The closed list.** Two paths are kept exactly as they are on `release`, whatever your `main` holds: `VAULT-IDENTITY.md` and the projects folder. A file that only the laboratory has there never leaves it. No argument can extend this list (any other argument is refused); adding a path is a Mission.

**Exit codes and last line.** Exit 0 with `PUBLISHED <commit>`, `NOTHING-TO-PUBLISH` or `DRY-RUN`; when there is nothing to publish, `--dry-run` also ends on `NOTHING-TO-PUBLISH`. Exit 1 with `REFUSED`, the reason printed before it on the error output, prefixed `REFUS :`. It refuses when there is no `release` remote, the current branch is not `main`, there are uncommitted changes, release/main is not an ancestor of `publish` (a third party advanced it), `publish` is checked out in another worktree, an argument is unknown or lacks its value, the message file is missing, a private pattern is found, `release/main` cannot be found, the public tags cannot be read, or the fetch, the creation of the branch `publish` or of its worktree, the read-tree, the version setting, the index rebuild, the staging, the commit or the push fails.

**Reads.** The laboratory's `main`, the `release` remote (fetched), the tree of release/main. **Writes.** The branch `publish` (created on release/main if absent), the publication worktree `<workspace>/m-publish/second-brain` and its rebuilt indexes, one commit on `publish`, the push to `release`. With `--dry-run`, the branch and the worktree can still be created.

**Repository-root guard.** It does not use `tools/repo_root_guard.py` and takes no path: it acts on the repository that holds it and on the fixed worktree `<workspace>/m-publish/second-brain`.

**Example.** In an installed Vault, which has no `release` remote, this is refused and pushes nothing: `REFUS : <workspace>/second-brain n'a pas de distant release : ce n'est pas un laboratoire`, then `REFUSED`.

```bash
bash <workspace>/second-brain/tools/publish-from-laboratory.sh --dry-run
```
_Not executed by the documentation check._

In a laboratory:

```bash
bash <workspace>/<laboratory>/tools/publish-from-laboratory.sh --version <vX.Y.Z>
```
_Not executed by the documentation check._

## publish-tag.sh

**Role.** Poses the annotated tag of a published version and pushes it to **both** remotes of the laboratory, `release` and `origin`. A participant installs and updates from `release` (`second-brain.git`); a Vault installed from `origin` (`vault.git`) reads the tags of its own origin, so a version tagged on `release` alone is invisible to it and its update answers that there is no such version (report 227, P2). Run it after `tools/publish-from-laboratory.sh --version <vX.Y.Z>` has printed `PUBLISHED`. It is, with the tool's own fast-forward, one of the two named exceptions to the verified push. The full procedure is in [Publishing](../how-to/publish.md), step 5.

**Called by.** No tool; the maintainer runs it. Tested by `tests/test-publish-tag-both-remotes.sh`, on two local bare repositories.

**Syntax.** `publish-tag.sh <vX.Y.Z> [--repo <absolute repository path>] [--url <origin url>] [--message <text>] [--dry-run]`

**Options.**

| Option | Effect |
|---|---|
| `--repo <absolute path>` | The laboratory to act on. Default: the repository that holds the script. A relative path, or a path that is not the root of a repository, is refused (rule 100419). |
| `--url <url>` | The URL `origin` must push to. Default: `vault_origin` of `VAULT-IDENTITY.md` at the repository root. |
| `--message <text>` | The annotated tag's message. Default: the version itself. |
| `--dry-run` | Runs every check, creates nothing and pushes nothing; last line `WOULD-TAG <version> <commit>`. |

**What it tags.** The head of the local branch `publish`, and only if `git ls-remote release refs/heads/main` reads that very commit: the tag never names a commit the publication did not push.

**Exit codes and last line.** Exit 0 with `TAGGED <version> <commit>` or `WOULD-TAG <version> <commit>`. Exit 1 with `REFUSED`, the reason printed before it on the error output, prefixed `PUBLISH-TAG-REFUSED:`. It refuses when the version is not `vX.Y.Z`, the repository path is not absolute or not a repository root, the repository has no `release` or no `origin` remote, `origin` pushes somewhere other than the declared URL, there is no local `publish` branch, `release/main` is not the head of `publish`, the tag already exists on either remote, a local tag of that name names another commit, or a remote cannot be read. After the pushes it reads each remote back with `git ls-remote --tags`; a remote that does not read the tagged commit gives `PUBLISH-TAG-MISMATCH` and exit 1.

**Reads.** The branch `publish`, the two remotes' refs. **Writes.** The annotated tag locally (if absent), then that tag on `release` and on `origin`. Nothing else; no forcing option is accepted.

**Repository-root guard.** It does not use `tools/repo_root_guard.py`: it takes a repository, not a write target, and checks that path itself (absolute, root of a repository).

**Example.** A dry run, which pushes nothing:

```bash
bash <workspace>/vault/tools/publish-tag.sh <vX.Y.Z> --repo <workspace>/vault --dry-run
```
_Not executed by the documentation check._

## set-release-version.sh

**Role.** Sets the four places that name the version a published install line installs to one tag: every raw.githubusercontent.com URL of `bootstrap.sh` or `bootstrap.ps1` in `README.md` and `INSTALL.md`, `REF="<ref>"` in `bootstrap.sh`, and `$Ref = '<ref>'` in `bootstrap.ps1` (the same URL in each bootstrap's usage comment follows). Only the matched text changes; line endings are kept. It works on copies, reads the four places back, and writes nothing unless all four read the tag.

**Called by.** `tools/publish-from-laboratory.sh` with `--version`, on the publication tree. Tested by `tests/test-publish-version-line.sh` and `tests/test-repo-root-guard.sh`.

**Syntax.** `set-release-version.sh <vX.Y.Z> [<root>]`. **Options.** `<root>` is the folder that holds the four files; default: the repository that holds the script.

**Exit codes and last line.** Exit 0, last line `VERSION-SET <tag>`. Exit 1, last line `REFUSED`, after a `REFUS :` line on the error output: invalid tag, root refused by the guard, missing file, or the four places disagree after rewriting.

**Reads and writes.** `README.md`, `INSTALL.md`, `bootstrap.sh` and `bootstrap.ps1` under `<root>`; a temporary folder, removed at the end.

**Repository-root guard.** Yes. It runs `tools/repo_root_guard.py` on `<root>` through `uv run --no-project` before anything is written, so it needs `uv`. The workspace root, or a folder in no repository, is refused with `REFUS : racine refusee par le garde-fou : <root>`.

**Example.** A refusal, safe to run; it prints `REFUS : etiquette invalide : '1.0' (attendu vX.Y.Z)`, then `REFUSED`.

```bash
bash <workspace>/second-brain/tools/set-release-version.sh 1.0
```

## generate-third-party-licenses.sh

**Role.** Rebuilds `THIRD-PARTY-LICENSES.md` at the repository root by copying, verbatim, the licence table of each collection of the skills warehouse. It never decides a licence itself: the warehouse's ingestion ([ingestion standard](../../skills-warehouse/INGESTION_STANDARD.md)) did that. **Called by.** Tested by `tests/test-third-party-licenses.sh`; no other caller.

**Syntax.** `tools/generate-third-party-licenses.sh [--out <path>] [--check]`. **Options.** `--out <path>` writes elsewhere; it is refused when the path lies inside the repository. `--check` writes nothing and compares the regenerated text with the file on disk.

**Exit codes and last line.** Exit 0: `OK : <file> regenere.` or, with `--check`, `OK : <file> a jour.` Exit 1, a `REFUS :` line on the error output: not inside a Git repository, unknown option, `--out` given with no path, `--out` inside the repository, no warehouse folder or no collection, a collection without its licence file, or with `--check` a missing or stale file (`REFUS : <file> perime.`, followed by the remedy: run the script with no option).

**Reads.** The licence file of every sub-folder of `skills-warehouse/skill-collections` (one LICENSES.md per collection). **Writes.** `THIRD-PARTY-LICENSES.md`, or the `--out` path; nothing with `--check`.

**Repository-root guard.** It does not use `tools/repo_root_guard.py`. Its target is the root of the Git repository of your current folder (not the one that holds the script), and its output is a fixed file there. So enter the Vault by its absolute path first.

**Example.** A check that writes nothing:

```bash
cd <workspace>/second-brain && bash <workspace>/second-brain/tools/generate-third-party-licenses.sh --check
```

## check-backup-bundle.sh

**Role.** Proves a Git bundle backup by restoring it. `git bundle verify` only reads the header, so a bundle cut in the middle of its pack still passes it. This script checks the header, fetches every ref of the bundle into a throwaway repository (which checks the whole pack), then runs `git fsck` there. **Called by.** Tested by `tests/test-backup-oracle.sh`; no other caller.

**Syntax.** `check-backup-bundle.sh <file.bundle>`

**Exit codes and last line.** Exit 0: the restored refs, one per line, then `PASS : <n> reference(s) restauree(s), pack et objets verifies`. Exit 1, last line `FAIL : <cause>`: missing file (with the usage line on the error output), invalid header, unreadable or truncated pack, no ref restored, or inconsistent objects.

**Reads.** The bundle, read-only. **Writes.** A throwaway repository in the temporary folder, removed at the end. **Repository-root guard.** Not needed: it writes into no repository.

**Example.** Read-only; the bundle is one you made earlier:

```bash
bash <workspace>/second-brain/tools/check-backup-bundle.sh <backups>/second-brain.bundle
```

## package-warehouse-deliverables.ps1

**Role.** A PowerShell script (5.1 or later) that packages every skill of the chosen warehouse collections into one ZIP per skill, ready to upload to a chat interface, with an index and a checksum file per release. The same inputs give the same bytes. A release folder is never overwritten: a file whose new content differs stops the run and asks for a new `-DateLabel`.

**Called by.** Nothing; it is run by hand. `skills-warehouse/deliverables/README.md` describes its output. No test.

**Syntax.** From its parameters: `package-warehouse-deliverables.ps1 [-Collections <slug>[,<slug>...]] [-DateLabel <label>] [-WarehouseRoot <path>] [-IndexUsageMaxChars <n>]`

**Options.**

| Parameter | Default | Effect |
|---|---|---|
| `-Collections` | `software-engineering`, `web-design`, `visual-content` | Collections to package; each must be listed in `skills-warehouse/skill-collections/catalog.json`. |
| `-DateLabel` | today, `yyyy-MM-dd-v1` | Name of the release folder. |
| `-WarehouseRoot` | the `skills-warehouse` folder next to the script's `tools` | The warehouse to read and write. |
| `-IndexUsageMaxChars` | 45 | Length of the usage cue in the index, which must stay under 8000 bytes (the limit of the index-weight guardian). |

**Exit codes and last line.** The code sets no explicit exit code. A run ends on `Grand total bytes across all packaged collections: <n>`, after one `== <slug> ==` block per collection with `skills=`, `zips=`, `bytes=`, `created=` and `unchanged=`. Any problem is a thrown error that stops the run: missing collection folder, unknown slug, no skill, a front-matter `name` that does not match its folder, missing `description` or `license`, a forbidden file (for example a .git folder or a nested ZIP), an index too heavy, or a release file that would change.

**Reads.** Each skill's `<skill folder>/SKILL.md` front matter and files, and `skills-warehouse/skill-collections/catalog.json`. **Writes.** Under `skills-warehouse/deliverables`, one folder per collection and label: `<release folder>/chat-zips/<skill>.zip`, `<release folder>/index.md` and `<release folder>/SHA256SUMS.txt`. **Repository-root guard.** It does not use `tools/repo_root_guard.py`; it writes only under the warehouse named by `-WarehouseRoot`, by default the Vault's own.

**Example.** Re-running an existing release with unchanged sources writes nothing:

```powershell
pwsh <workspace>/second-brain/tools/package-warehouse-deliverables.ps1 -Collections visual-content -DateLabel 2026-09-12-v1
```
_Not executed by the documentation check._

## Liens

- `source` — [Verified push](../../tools/verified-push.sh)
- `source` — [Publish from the laboratory](../../tools/publish-from-laboratory.sh)
- `source` — [Pose and push the publication tag](../../tools/publish-tag.sh)
- `source` — [Set the release version](../../tools/set-release-version.sh)
- `source` — [Third-party licences generator](../../tools/generate-third-party-licenses.sh)
- `source` — [Backup bundle check](../../tools/check-backup-bundle.sh)
- `source` — [Warehouse deliverables packager](../../tools/package-warehouse-deliverables.ps1)
- `source` — [Rule: absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Repository-root guard](../../tools/repo_root_guard.py)
- `source` — [Work regime check](../../tools/check-work-regime.sh)
- `source` — [Mission template](../../templates/mission-template.md)
- `source` — [Handoff template](../../templates/handoff-template.md)
- `source` — [Session close skill](../../skills/session-close/SKILL.md)
- `source` — [Mission checklist](../../skills/mission-writing/mission-checklist.md)
- `source` — [Vault identity](../../VAULT-IDENTITY.md)
- `source` — [README](../../README.md)
- `source` — [INSTALL](../../INSTALL.md)
- `source` — [Bootstrap, Bash](../../bootstrap.sh)
- `source` — [Bootstrap, PowerShell](../../bootstrap.ps1)
- `source` — [Third-party licences](../../THIRD-PARTY-LICENSES.md)
- `source` — [Warehouse ingestion standard](../../skills-warehouse/INGESTION_STANDARD.md)
- `source` — [Warehouse catalog](../../skills-warehouse/skill-collections/catalog.json)
- `source` — [Warehouse deliverables](../../skills-warehouse/deliverables/README.md)
- `source` — [Test: verified push](../../tests/test-verified-push.sh)
- `source` — [Test: repository-root guard](../../tests/test-repo-root-guard.sh)
- `source` — [Test: publish from the laboratory](../../tests/test-publish-from-laboratory.sh)
- `source` — [Test: the publication tag reaches both remotes](../../tests/test-publish-tag-both-remotes.sh)
- `source` — [Test: private check before every push](../../tests/test-publish-private-check-before-push.sh)
- `source` — [Test: published version line](../../tests/test-publish-version-line.sh)
- `source` — [Test: third-party licences](../../tests/test-third-party-licenses.sh)
- `source` — [Test: backup oracle](../../tests/test-backup-oracle.sh)
- `see also` — [Publishing](../how-to/publish.md)
- `see also` — [Delegate and push](../how-to/delegate-and-push.md)
- `see also` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `see also` — [Why absolute paths](../explanation/why-absolute-paths.md)
- `see also` — [Guardian tools](tools-guardians.md)
- `see also` — [Internal helpers](tools-internal-helpers.md)
