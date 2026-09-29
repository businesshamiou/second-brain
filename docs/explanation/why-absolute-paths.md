---
type: explanation
title: "Why absolute paths"
description: "Why every command that writes or pushes names the absolute path of its repository, why the Vault's tools refuse the workspace root, and what these guards do not protect against."
status: active
---

# WHY ABSOLUTE PATHS

Every command that writes or pushes, in a Mission, a report or a block handed to the Owner, names the absolute path of the repository it acts on. The Vault's writing tools refuse the workspace root, and every push goes through one verified script. This page explains where that rule comes from and what it does and does not protect. The rule itself is [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md).

**Under Windows.** A `bash …/tools/…` line of this page, typed in PowerShell where `bash` is unknown, starts with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`; where an `sb` verb carries the same gesture ([Commands](../reference/commands.md)), type the verb. `sb doctor` says whether `bash` is on your PATH.

## The incident

On 2026-09-21 the index builder was run with `.` as its argument from the workspace root. It rewrote about 2,400 index files in sibling folders. Six of those folders had no Git, so there was nothing to restore them from (Mission 210, workshop history, not distributed). A comment in `tools/build_indexes.py` records a second effect of the same day: under NTFS, writing `index.md` over a hand-written index file named INDEX.md replaced its content and kept its name, 532 files of one knowledge base. Since Mission 218 the builder never overwrites a file it did not generate.

On 2026-09-25 the same command, `bash ../vault/tools/build-indexes.sh .`, was typed again from the same folder. It did nothing only because `bash` was not found in that PowerShell window. The command had been handed over with a path relative to the folder it was meant to run in, and it ran in another one.

Both times the danger was `.`: its meaning depends on the folder the reader happens to be in, and the reader was in the wrong one.

## What a workspace root is

A workspace is the folder that holds the Vault and the projects side by side, for example `C:/Users/you/Workspaces`. It is not a repository: it holds several repositories without being one. It carries the marker `<workspace>/VAULT-ROOT.md`, which lets any project folder find the Vault by walking up its parent folders ([tools/resolve-vault.sh](../../tools/resolve-vault.sh)).

Because the workspace root is not a repository, a tool launched there acts on every sibling folder at once, including folders that have no Git history to fall back on. That is why it is the one place a writing tool must never take as its target.

For the guard, a folder is a workspace root when it has no `.git` of its own and either carries the marker (`<folder>/VAULT-ROOT.md`) or holds two or more Git repositories as direct children ([tools/repo_root_guard.py](../../tools/repo_root_guard.py)).

## Why words alone were not enough

A rule in prose that says "write absolute paths" depends on every writer remembering it, every time. Four days after the first incident, a command with `.` was handed over and typed again. The Owner, the morning of the second time:

```
« il faudrait l'ajouter […] comme règle et comme peut-être une règle de validation avant le pousser […] dans des outils ça devrait être mécanique. Comme ça on n'aura jamais ce genre de problème »
```

> "it should be added […] as a rule, and maybe as a validation rule before the push […] in the tools it should be mechanical. That way we will never have this kind of problem"

So the rule has two parts: words for the people and agents who write commands, and mechanics in the tools, which hold even when the words are forgotten.

In practice, the words look like this. A command handed to someone else names the repository in full:

```bash
bash <workspace>/second-brain/tools/build-indexes.sh <workspace>/<project>
```
_Not executed by the documentation check._

`<workspace>` is the absolute path of the workspace, `<project>` the project's folder. In a laboratory, the Vault's folder is `vault` instead of `second-brain`.

## The first mechanism: the repository-root guard

[`tools/repo_root_guard.py`](../../tools/repo_root_guard.py) is the one place that decides whether a Vault tool may write under a target folder. It walks up from the target. The target is admitted when it finds a `.git` (a folder, or a file for a worktree) or a project's birth certificate before any workspace root. Otherwise it is refused before anything is written, with one line that starts with `REPO-ROOT-REFUSED` and names the path received and the root expected. There is no switch and no environment variable that turns it off.

The walk stops at the workspace root. An earlier check in the index builder, `root_admitted` (Mission 218), did the same walk without that stop; the comment that replaced it in `tools/build_indexes.py` says so. The stop matters: a `.git` higher up, such as a dotfiles repository in the user profile, never admits the whole workspace.

The tools that carry the guard are `build-indexes.sh`, `append-journal.sh`, `build-state.sh`, `build-digest.sh`, `set-release-version.sh`, `vault-identity.sh ensure`, `propose-link-repairs.sh` and `project-bootstrap.sh create|adopt`. The bootstrap uses the guard's `--new-project` mode: its target is a new project folder, often in no repository yet, so it is refused only when that folder is itself a workspace root. Two tools, `write-marker.sh` and `install-vault-mcp.sh`, take the workspace root on purpose, because that is where the marker and the server's allowed folder live.

You can watch the guard refuse the workspace root. This writes nothing:

```bash
uv run --no-project <workspace>/second-brain/tools/repo_root_guard.py <workspace>
```

It exits with code 2 and prints `REPO-ROOT-REFUSED: <workspace> (...) is not inside a repository: ... is a workspace root (it carries VAULT-ROOT.md).`, followed by the expected root, an example `<workspace>/<repository>`, and `Nothing written.`

The proof is [`tests/test-repo-root-guard.sh`](../../tests/test-repo-root-guard.sh). In a throwaway workspace it replays the incident against every tool above except the bootstrap: `.` from the workspace, a sub-folder without Git, `..` from inside a repository, and `.` from a second workspace that has two repositories and no marker. The bootstrap is played on the workspace itself (`create`), on a folder that holds two repositories (`adopt`), and with `prompt .` from the workspace. Each launch must be refused with no file written. Witnesses check that the same tools still write normally when given a repository's absolute path, and that the bootstrap still creates a project below the workspace.

One folder is never a workspace root: the system temporary folder (Mission 231). Other work leaves Git repositories there, and the guard used to refuse every throwaway folder a test made in it. A folder below it is now admitted when nothing closer decides; the temporary folder itself stays refused, and so does a workspace root built below it. [`tests/test-repo-root-guard-system-temp.sh`](../../tests/test-repo-root-guard-system-temp.sh) proves it, and checks again that the real workspace root is refused.

## The second mechanism: the verified push

[`tools/verified-push.sh`](../../tools/verified-push.sh) is the only way a Mission, a report or a block handed to the Owner prescribes a push of a branch. It pushes exactly the range it is given, to the branch the repository is on:

```bash
bash <workspace>/second-brain/tools/verified-push.sh <absolute repository path> <from>..<to> [<remote>] [--url <url>]
```
_Not executed by the documentation check._

Before pushing anything, it refuses (exit 1, `VERIFIED-PUSH-REFUSED` on standard error) when:

| Check | Refused when |
| --- | --- |
| Path | the path is not absolute, or is not the root of a Git repository |
| Range | it is not `<from>..<to>`, or either end is not a commit |
| HEAD | HEAD is detached, or is not `<to>` |
| Remote | its push URL is not the declared one: `--url`, or `vault_origin` in a Vault's `VAULT-IDENTITY.md`; a project declares none, so the Mission names it with `--url` |
| Remote head | the remote's head of the branch is not `<from>` (someone else pushed, or the range is stale) |
| Ancestry | `<to>` does not descend from `<from>` |
| Options | any forcing option (`--force`, `-f`, `--force-with-lease`) |

`--dry-run` runs every check and pushes nothing. Its last line starts with `WOULD-PUSH`. After a real push, `git ls-remote` must read `<to>`, and the last line is `PUSHED <remote> <branch> <from>..<to>`.

Given the workspace root, it refuses at the first check:

```bash
bash <workspace>/second-brain/tools/verified-push.sh <workspace> HEAD~1..HEAD --dry-run
```

The usual message is `VERIFIED-PUSH-REFUSED: <workspace> is in no Git repository (a workspace root holds repositories without being one). Nothing pushed.` If the workspace itself sits inside another repository, the message says instead that it is not the root of its repository.

Publication is the one exception. It goes through its own script, which pushes a fast-forward itself ([Publish](../how-to/publish.md)).

## What these guards do not protect against

The role charter states the threat model: the Vault's mechanical guardrails are "anti-accident, not anti-evasion" ([role charter, §4](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)). They stop errors. They do not confine an agent that deliberately tries to go around them. In practice:

- **Only the Vault's tools carry the guard.** A hand-written loop that edits files across folders, or a bare `git push`, goes around both mechanisms. That is why the rule says writing goes through the protected tools and never prescribes a bare `git push`.
- **The guard checks "a repository", not "the right repository".** Any folder inside any repository is admitted. Naming the intended repository in full is still the writer's job.
- **Recognition has limits.** A folder with no marker and fewer than two child repositories is not seen as a workspace root. The walk then continues upward, and a `.git` higher up would admit it.
- **The verified push checks the range, not its content or its permission.** Delegating a push still needs a clear expression of the Owner that names the gesture and its target.

When a tool refuses, the rule asks the Executor to read the message, rewrite the command with the absolute path of the right repository, and never look for another way to write to the refused place. If the refusal comes from the session's permission tool instead, the gesture goes to the final block for the Owner, with absolute paths, in order, ready for Git Bash. See [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md).

## Liens

- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `source` — [tools/repo_root_guard.py](../../tools/repo_root_guard.py)
- `source` — [tools/verified-push.sh](../../tools/verified-push.sh)
- `source` — [tests/test-repo-root-guard.sh](../../tests/test-repo-root-guard.sh)
- `source` — [tools/build_indexes.py](../../tools/build_indexes.py)
- `source` — [tools/resolve-vault.sh](../../tools/resolve-vault.sh)
- `see also` — [Guardians](guardians.md)
- `see also` — [Delegate and push](../how-to/delegate-and-push.md)
- `see also` — [Publish](../how-to/publish.md)
- `see also` — [React to a guardian refusal](../how-to/react-to-a-guardian-refusal.md)
- `see also` — [Guardian tools](../reference/tools-guardians.md)
- `see also` — [Publication and push tools](../reference/tools-publication-and-push.md)
