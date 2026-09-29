---
type: how-to
title: "Publish a version"
description: "How the maintainer of a laboratory Vault publishes a new version of Second Brain to its release remote with one command, then poses and pushes its tag."
status: active
---

# PUBLISH A VERSION

This page is for you, the maintainer of a laboratory Vault. It gives the gestures of a publication in order: push your laboratory's `main`, read the public tags, run the tool as a dry run, publish, then pose and push the tag. `<workspace>` is the absolute path of your workspace (for example `C:/Users/you/Workspaces`). In a laboratory the Vault's folder is named `vault`, not `second-brain`: the laboratory Vault is `<workspace>/vault` ([rule, §2 point 3](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)).

## Before you start

- **The publication worktree is the maintainer's own.** `<workspace>/m-publish/second-brain` is the worktree the tool creates to hold `publish`: declared as an organ at the workspace root (the marker's line « Organes déclarés », `m-publish`), it is neither a project nor a place to work — never open a session in it, never commit in it by hand; the tool alone writes there.

- **You are in a laboratory.** A laboratory is a Vault that declares a Git remote named `release`: the published repository. An installation has no such remote, so nothing on this page applies to it (the tool's first precondition).
- **Your laboratory's `main` is checked out, committed and clean.** The tool refuses any other branch (never `publish`) and any uncommitted change.
- **You chose the version**, in the form `vX.Y.Z`, and it is not yet a tag on `release`: a published version is never republished.
- **The release notes are written.** `RELEASE-NOTES.md` says what a published version contains and what it does not promise, newest first. Entries from v0.1.4 to v0.1.14 have four parts: what the version brings (for v0.1.4, what it fixes), how it is proven, what it does not promise, and what remains to be done on your side; v0.1.7 adds why it replaces v0.1.6; entries v0.1.0 to v0.1.3 have no "How it is proven" part. Today its newest entry is headed "v0.1.15 (draft, not published)", with the same four parts. The file is not in the closed list (below), so it goes out with the tree of your `main`: what you write on `main`, heading included, reaches `release` with the next publication.

The laboratory's history and the published history are unrelated by construction: your `main` is never a fast-forward of `release/main`. A laboratory also adopts your own projects, whose sheets under `projects/` carry their absolute path, which is a private pattern by definition. So `tools/check-private-patterns.sh` exempts `projects/` when two conditions hold, both measured in Git only: the repository declares a `release` remote, AND the checked-out branch does not follow that remote. On the branch `publish`, which follows `release/main`, the exemption is not inherited and the check stays entire.

## Steps

**1. Push your laboratory's `main` first**, through the verified push, like every push of a branch. `<from>` is the head of `main` on `origin`, `<to>` your local `main`; `origin` must push to the `vault_origin` declared in `VAULT-IDENTITY.md`. Run it once with `--dry-run` (last line `WOULD-PUSH ...`), then for real:

```bash
git -C <workspace>/vault ls-remote origin refs/heads/main
git -C <workspace>/vault rev-parse main
bash <workspace>/vault/tools/verified-push.sh <workspace>/vault <from>..<to> origin --dry-run
bash <workspace>/vault/tools/verified-push.sh <workspace>/vault <from>..<to> origin
```

_Not executed by the documentation check._

**2. Read the public tags before**, on **both** remotes — step 5 pushes the tag to both. Keep the two lists: you compare them at step 6. `<vX.Y.Z>` must be in neither (the tools check it too).

```bash
git -C <workspace>/vault ls-remote --tags release
git -C <workspace>/vault ls-remote --tags origin
```

_Not executed by the documentation check._

**3. Dry run.** It goes as far as the private-pattern check, with the version applied to the publication tree, then resets the publication worktree. Nothing is committed, nothing is pushed. It can still create the local branch `publish` and the publication worktree if they are missing.

```bash
bash <workspace>/vault/tools/publish-from-laboratory.sh --dry-run --version <vX.Y.Z>
```

_Not executed by the documentation check._

**4. Publish.** The same command without `--dry-run`:

```bash
bash <workspace>/vault/tools/publish-from-laboratory.sh --version <vX.Y.Z> [--message-file <file>]
```

_Not executed by the documentation check._

The full syntax is `publish-from-laboratory.sh [--version <vX.Y.Z>] [--dry-run] [--message-file <file>]`:

- `--version <vX.Y.Z>`: sets the version the published install line names. A tag that is not `vX.Y.Z`, or a tag that already exists on `release`, is refused.
- `--dry-run`: stops after the private-pattern check, as in step 3.
- `--message-file <file>`: the publication commit takes its message from this file. Without it, the message is "Publish the laboratory's main" followed by the short hash of your `main`.

Any other argument is refused. In particular no argument can widen the closed list of kept paths: adding a path to it is a Mission. What the tool does, in order:

1. Checks the preconditions: a `release` remote, the current branch is `main`, no uncommitted change; then it fetches `release` and, with `--version`, checks with `git ls-remote --tags release` that the tag is not already there.
2. Creates the local branch `publish` on `release/main` if it does not exist, following `release/main`. If `release/main` is not an ancestor of `publish` (someone else advanced it), it refuses: the push would not be a fast-forward.
3. Creates or reuses the publication worktree `<workspace>/m-publish/second-brain`, holding `publish`, and loads into it the whole tree of your `main`.
4. Puts back the closed list exactly as it is on `release`: `VAULT-IDENTITY.md` and `projects/`. A file that only the laboratory has there never leaves it.
5. With `--version`, runs `tools/set-release-version.sh` on the publication tree, never on your `main`. It rewrites the install line of `README.md` and `INSTALL.md` (every raw.githubusercontent.com URL that fetches `bootstrap.sh` or `bootstrap.ps1`), `REF="<ref>"` in `bootstrap.sh` and `$Ref = '<ref>'` in `bootstrap.ps1`, so the commit that will receive the tag names that very tag. It reads the four places back and refuses, writing nothing, if one disagrees.
6. Rebuilds the indexes of the published tree with `tools/build-indexes.sh`, and stages only the closed list, the four version files and the indexes, never a stray untracked file.
7. If `publish` already carries this tree and equals `release/main`, it stops: nothing to publish.
8. Runs `tools/check-private-patterns.sh` with `--tree-only` on the tree about to go out. This check runs before every push, including when `publish` is already ahead of `release/main` with nothing new to commit.
9. With `--dry-run`, it resets the worktree to `publish` and stops here.
10. Otherwise it makes one commit on `publish` (the Vault's guardians can refuse it), then runs `git push release publish:main`: a fast-forward, never `--force`.

**5. Pose the annotated tag and push it to BOTH remotes**, with [`tools/publish-tag.sh`](../../tools/publish-tag.sh), after `PUBLISHED`. The tool leaves the new commit at the head of `publish`, checked out in the publication worktree and pushed to `release/main`; this command tags that commit, with exactly the version you passed to `--version` (the tag the install line of the published commit already names):

```bash
bash <workspace>/vault/tools/publish-tag.sh <vX.Y.Z> --repo <workspace>/vault --dry-run
bash <workspace>/vault/tools/publish-tag.sh <vX.Y.Z> --repo <workspace>/vault
```

_Not executed by the documentation check._

**Both remotes, not `release` alone.** A participant installs and updates from `release` (`second-brain.git`). A Vault installed from `origin` (`vault.git`) — the company's, whose branch descends from the published line and shares no ancestor with your `main` — reads the tags of **its own** origin. Up to v0.1.14 those tags reached `vault.git` only because they were pushed there by hand; a version tagged on `release` alone is invisible to that Vault, and `second-brain update <version>` answers that there is no such version (report 227, P2). So `tools/publish-tag.sh` pushes the one tag to `release` and to `origin`, and reads each remote back with `git ls-remote --tags` before it says `TAGGED`.

It refuses, before anything is pushed: a version that is not `vX.Y.Z`; a repository that is not a laboratory (no `release` or no `origin` remote); an `origin` that pushes somewhere other than the declared URL (`vault_origin` of `VAULT-IDENTITY.md`, or `--url`); no local `publish` branch; a `release/main` that is not the head of `publish` — the tag never names a commit the publication did not push; a tag already on either remote; a local tag of that name on another commit. `--dry-run` checks everything, creates nothing and pushes nothing, and ends `WOULD-TAG <vX.Y.Z> <commit>`.

This tag push and the tool's own fast-forward push (`git push release publish:main`) are the two publication exceptions to the verified-push rule ([rule, §2 point 4](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)): `tools/verified-push.sh` pushes a branch range and never a tag. Every other push, starting with your laboratory's `main` in step 1, goes through it.

**6. Read the public tags after**, with the two commands of step 2, and compare: on each remote, the only new lines are those of `<vX.Y.Z>`.

## What you should see

| Last line | Meaning |
|---|---|
| `PUBLISHED <commit>` | `release/main` now points to that commit on `publish`. |
| `NOTHING-TO-PUBLISH` | The laboratory is already published; exit 0, nothing pushed. |
| `DRY-RUN` | The run stopped after the private-pattern check; nothing committed or pushed. |
| `REFUSED` | Exit 1; the reason is printed before it on the error output, prefixed `REFUS :`. |

Before `PUBLISHED`, a run with `--version` prints `VERSION-SET <vX.Y.Z>` (from `tools/set-release-version.sh`), then `PUBLISH: commit de publication <commit> (laboratoire <main>), chemins gardes de release : VAULT-IDENTITY.md projects` and `PUBLISH: release/main : <old>..<new> (avance rapide)`. A dry run ends with `PUBLISH: essai a blanc : rien n'est commite, rien n'est pousse`, then `DRY-RUN`. The verified push of step 1 ends with `PUSHED origin main <from>..<to>`.

**Your laboratory's `main` keeps the previous tag.** `--version` rewrites the publication tree only; the laboratory's `main` is never rewritten ([test-publish-version-line.sh](../../tests/test-publish-version-line.sh), case b). So after a publication, the install line and the two bootstraps on your `main` still name the tag they named before (today v0.1.14, [README.md](../../README.md) "Installation line"). This is consistent, not stale: [test-published-line-ref.sh](../../tests/test-published-line-ref.sh) only requires that every line in `README.md` and `INSTALL.md` names one and the same tag, and that this tag is the default ref of `bootstrap.sh` and `bootstrap.ps1`. It passes on your `main` (all at the previous tag) and on the published commit (all at the new one). The defect it guards appeared at v0.1.5 (the line installed v0.1.4) and came back at v0.1.14 (it installed v0.1.9).

## Known errors

Every refusal of `tools/publish-from-laboratory.sh` pushes nothing; in the last row the publication commit already exists on `publish`, but nothing reached `release`.

| Message after `REFUS :` | Cause | What to do |
|---|---|---|
| `... n'a pas de distant release : ce n'est pas un laboratoire` | No `release` remote. | This Vault is an installation: there is nothing to publish from it. |
| `l'outil se lance depuis le main du laboratoire (branche courante : ...), jamais depuis publish` | Another branch is checked out. | Check out `main` in `<workspace>/vault`. |
| `le laboratoire porte des changements non commites` | Uncommitted changes. | Commit them, push `main` (step 1), run again. |
| `--version : etiquette invalide '<tag>' (attendu vX.Y.Z)` | The tag is not `vX.Y.Z`. | Write it as `vX.Y.Z`. |
| `l'etiquette <tag> existe deja sur release : une version publiee ne se republie pas` | The tag is already public. | Choose the next version. |
| `pas une avance rapide : release/main (...) n'est pas un ancetre de publish (...)` | A third party advanced `release/main`. | Never force: find out what reached `release/main` before running again. |
| `publish est deja extraite dans un autre worktree : <folder> (attendu : <workspace>/m-publish/second-brain)` | `publish` is held elsewhere. | Free that worktree; the tool wants its own. |
| `argument non reconnu : ...` | An unknown argument. | Use only the three options above. |
| `--message-file sans fichier` or `fichier de message introuvable : <file>` | The message file is missing. | Give an existing file. |
| `la version <tag> n'a pas pu etre posee dans l'arbre publie` | `tools/set-release-version.sh` refused (its own `REFUS :` line says why, for example `relecture en desaccord`). | Fix the four version places on `main`, commit, push, run again. |
| `motif prive dans l'arbre publie` | The check found a private pattern in the published tree. | Remove it on `main`, commit, push, run again. |
| `commit de publication refuse (gardiens)` | A guardian refused the publication commit. | Read the guardian's message above. |
| `poussee refusee (le commit <commit> reste sur publish, rien n'a atteint release)` | The push to `release` failed after the commit. | Run again with `main` unchanged and the same `--version`: `publish` is then ahead of `release/main` with nothing new, and the tool reruns the private-pattern check and pushes that commit. |

The tool can also refuse with `git fetch release a echoue`, `git ls-remote --tags release a echoue ...`, `worktree de publication non cree ...` or `reconstruction des index a echoue`. A refusal of the verified push of step 1 starts with `VERIFIED-PUSH-REFUSED:` and ends with `Nothing pushed.`: see [Delegate and push](delegate-and-push.md).

## Scripts used

- `tools/verified-push.sh`: pushes your laboratory's `main` ([sheet](../reference/tools-publication-and-push.md)).
- `tools/publish-from-laboratory.sh`: the publication itself ([sheet](../reference/tools-publication-and-push.md)).
- `tools/set-release-version.sh`: raises the four version places in the publication tree ([sheet](../reference/tools-publication-and-push.md)).
- `tools/check-private-patterns.sh`: the private-pattern check before every push ([sheet](../reference/tools-guardians.md)).
- `tools/build-indexes.sh`: rebuilds the indexes of the published tree ([sheet](../reference/tools-indexes-and-links.md)).

## Liens

- `source` — [Publish from the laboratory](../../tools/publish-from-laboratory.sh)
- `source` — [Set the release version](../../tools/set-release-version.sh)
- `source` — [Verified push](../../tools/verified-push.sh)
- `source` — [Private-pattern check](../../tools/check-private-patterns.sh)
- `source` — [Index builder](../../tools/build-indexes.sh)
- `source` — [Rule: absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Test: the published line names the new tag](../../tests/test-publish-version-line.sh)
- `source` — [Test: the published line installs the version it names](../../tests/test-published-line-ref.sh)
- `source` — [Release notes](../../RELEASE-NOTES.md)
- `source` — [README, installation line](../../README.md)
- `source` — [Laboratory identity](../../VAULT-IDENTITY.md)
- `see also` — [Publication and push tools](../reference/tools-publication-and-push.md)
- `see also` — [Delegate and push](delegate-and-push.md)
- `see also` — [Architecture](../explanation/architecture.md)
- `see also` — [Guardians and tests](../explanation/guardians.md)
- `see also` — [Update](update.md)
- `see also` — [Troubleshooting](troubleshoot.md)
