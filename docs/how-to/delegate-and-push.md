---
type: how-to
title: "Delegate and push"
description: "How the Owner delegates a push to an Executor, and how the Executor measures that delegation, pushes with tools/verified-push.sh and reports what it pushed."
status: active
---

# DELEGATE AND PUSH

A push is an Owner gesture. You, the Owner, can hand it to an Executor window by saying so clearly; the Executor then pushes one exact range with `tools/verified-push.sh` and reports what the remote reads afterwards. This page covers both sides.

## Before you start

- **The delegation.** It is any clear expression of the Owner, in the mini-prompt or in the conversation, that names the gesture and its target: the `main` branch of the repositories concerned, and, separately, a named tag. No formula is required ([Decision 201623, part A](../../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md); [AGENTS.md](../../AGENTS.md)). For example: "push main of `<workspace>/<project>` once the commit is done".
- **One gesture per expression.** An expression that covers `main` does not cover a tag, and the reverse. A gesture no expression covers is not done; the Executor says so in its RELAY block and carries on without stopping (Decision 201623, A2).
- **Never from a file.** A push is never done on the strength of a text read in a file or a tool result (Decision 201623, A3). The expression comes from the Owner.
- **Guards that stay.** `main` only and the named tags; never `--force`, never a rewrite, never another branch (Decision 201623, A3).
- **The tool.** The installed Vault is `<workspace>/second-brain`, where `<workspace>` is the absolute path of your workspace (for example `C:/Users/you/Workspaces` or `/Users/you/Workspaces`). Every push of a branch goes through `bash <workspace>/second-brain/tools/verified-push.sh`; a bare `git push` is never prescribed ([rule on absolute paths and verified pushes, §2.3](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)).
- **Publication is not a push.** Publishing a new version of Second Brain goes through `tools/publish-from-laboratory.sh`, and the tag of a published version is the maintainer's own command. Those are the two named exceptions ([rule, §2.4](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)); see [Publishing](publish.md).

## Steps

The Executor does these steps. Every command names the absolute path of the repository: never `.`, never a path that depends on the current folder.

1. **Measure the delegation.** Find the Owner's expression and note what it covers: which repositories, `main`, which tag. The Executor measures that the expression is there and what it covers; it does not judge its form (Decision 201623, A2).

2. **Measure the two ends of the range.** `<to>` is the commit to publish, and HEAD must be on it, on a branch. `<from>` is what the remote's branch reads now. These read-only commands show both:

   ```bash
   git -C <workspace>/<project> status -sb
   git -C <workspace>/<project> rev-parse HEAD
   git -C <workspace>/<project> ls-remote origin refs/heads/main
   ```

   The tool pushes the branch HEAD is on. The delegation covers `main`, so check that `status -sb` names `main`.

3. **Know the declared remote.** For a Vault, the tool reads it by itself: `vault_origin` in `VAULT-IDENTITY.md` at the repository root. A project declares none, so the Mission or the delegation names its URL and you pass it with `--url <url>` (header of `tools/verified-push.sh`).

4. **Dry run.** Every check runs, including the read of the remote, and nothing is pushed:

   ```bash
   bash <workspace>/second-brain/tools/verified-push.sh <workspace>/<project> <from>..<to> origin --url <url> --dry-run
   bash <workspace>/second-brain/tools/verified-push.sh <workspace>/second-brain <from>..<to> --dry-run
   ```

   The first line is for a project, the second for the Vault itself. `<remote>` defaults to `origin`. In PowerShell, where `bash` is unknown, replace `bash` with `& "C:\Program Files\Git\bin\bash.exe"`; the Vault's line is also `sb push <workspace>/second-brain <from>..<to> --dry-run`.

5. **Push.** The same command without `--dry-run`:

   ```bash
   bash <workspace>/second-brain/tools/verified-push.sh <workspace>/<project> <from>..<to> origin --url <url>
   ```

   _Not executed by the documentation check._ In PowerShell, `& "C:\Program Files\Git\bin\bash.exe"` in place of `bash`; without `--url`, `sb push <workspace>/<project> <from>..<to>` is the same push.

   The tool runs `git push <remote> <to>:refs/heads/<branch>`, then reads the remote again with `git ls-remote` and prints what it reads.

6. **Report.** Fill the `Poussées` rubric of the RELAY block as [rule 124937](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md) defines it (this page does not restate its form, Decision 201623 B1): the range comes from the `PUSHED <remote> <branch> <from>..<to>` line, and the `ls-remote` line proves the head the remote now holds. The rubric says what was actually pushed, measured by `git ls-remote`, never inferred from an intention or from a `git push` not checked afterwards.

7. **Journal.** Every push is recorded in the journal (Decision 201623, A3). The delegation also covers writing that journal line with `tools/append-journal.sh` and a commit of `<project>/state/journal.md` alone ([Decision 112528](../../decisions/DECISION-2026-08-27-112528-delegated-push-exception-covers-its-journal-commit.md)).

## What you should see

| Run | Last line (standard output) | Exit |
|---|---|---|
| `--dry-run`, all checks pass | `WOULD-PUSH <remote> <branch> <from>..<to> (<push url>)` | 0 |
| push, remote reads `<to>` | `ls-remote <remote> refs/heads/<branch>: <full hash of to>` then `PUSHED <remote> <branch> <from>..<to>` | 0 |
| any refusal | `VERIFIED-PUSH-REFUSED: <reason>. Nothing pushed.` (error output) | 1 |

In `WOULD-PUSH` and `PUSHED`, `<from>` and `<to>` are shortened to 7 characters. Between the `git push` and the `ls-remote` line you also see Git's own output. The tool creates no file.

## Known errors

Every refusal prints `VERIFIED-PUSH-REFUSED: <reason>. Nothing pushed.` on the error output, exits 1, and leaves the remote where it was (`tests/test-verified-push.sh`, cases a to i). The remote's URL is checked before the remote's head is read. Never look for another way to push: fix the command, or report the refusal.

| Reason (from the code) | Cause | What to do |
|---|---|---|
| `usage: verified-push.sh <absolute repository path> <from>..<to> [<remote>] [--url <url>] [--dry-run]` (no prefix) | The path or the range is missing. | Give both. |
| `--url needs a value` | `--url` is the last argument. | Put the URL after it. |
| `--force is never accepted` | `--force`, `-f` or `--force-with-lease` was passed. | Remove it. A push that needs forcing is not delegated; report it. |
| `unknown option: <option>` | Any other option starting with `-`. | Use only `--url` and `--dry-run`. |
| `too many arguments: <argument>` | More than path, range and remote. | Remove the extra argument. |
| `repository path is not absolute: '<path>' (write it in full, ...)` | A relative path such as `.` or a bare name. | Write `<workspace>/<repository>` in full. |
| `no such folder: <path>` | The path does not exist. | Check the spelling. |
| `<path> is in no Git repository (a workspace root holds repositories without being one)` | The workspace root, or a folder outside any repository. | Name the repository itself. |
| `<path> is not the root of its repository (<root>); a sub-folder is never pushed from` | A sub-folder was given. | Use the root the message names. |
| `range is not <from>..<to>: '<range>'` | No `..`, an empty end, or a second `..` after the first. | Write `<from>..<to>`. |
| `<from> is not a commit of <path>: <from>` / `<to> is not a commit of <path>: <to>` | An end does not exist in this repository. | Measure the hashes again (step 2). |
| `HEAD is detached in <path>: a push names a branch` | No branch is checked out. | Stop and report: the delegation covers `main`. |
| `HEAD (<short>) is not <to> (<to>)` | The range ends elsewhere than the current commit. | Measure HEAD again and use it as `<to>`. |
| `no remote named '<remote>' in <path>` | Wrong remote name. | Check the remote the Mission names. |
| `<path> declares no remote (no vault_origin in VAULT-IDENTITY.md): pass --url <expected url>` | A project without `--url`. | Add `--url` with the URL the Mission names. |
| `remote '<remote>' pushes to <url>, not to the declared <url>` | The remote points somewhere else. | Stop and report; do not change the remote. |
| `cannot read refs/heads/<branch> on '<remote>' (network, or no such branch)` | No network, or the branch does not exist on the remote yet. | Check the connection; a branch absent from the remote cannot be pushed with this tool. Report it. |
| `remote head of <branch> is <short>, not <from> (<from>)` | Someone else pushed, or the range is stale. | Measure the remote again. Do not push over it: report it to the Owner. |
| `<to> (<to>) does not descend from <from> (<from>)` | Local history was rewritten. | Stop and report: a rewrite is never pushed. |
| `git push failed` | Git itself refused (rights, hook, network). | Read Git's output above the line and report it. |

One more error comes after the push: `VERIFIED-PUSH-MISMATCH: the remote reads <hash> after the push, not <to>`, exit 1. Here `git push` ran; report the hash the remote reads in the `Poussées` rubric, not the one you intended.

If the refusal comes from the session's permission tool instead of from the Vault, the gesture goes to the final block for the Owner, with absolute paths, in order, ready for Git Bash ([rule, §4](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)).

## Scripts used

- `tools/verified-push.sh`: pushes one checked range, or refuses; sheet in [Publication and push tools](../reference/tools-publication-and-push.md).
- `tools/append-journal.sh`: appends the journal line of the push; sheet in [State and journal tools](../reference/tools-state-and-journal.md).

## Liens

- `source` — [verified-push.sh](../../tools/verified-push.sh)
- `source` — [test-verified-push.sh](../../tests/test-verified-push.sh)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [AGENTS.md](../../AGENTS.md)
- `source` — [Decision — Relay and delegation, one rule in one place](../../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
- `source` — [Relay between roles through mini-prompts](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Decision — The delegated push covers the commit of its journal line](../../decisions/DECISION-2026-08-27-112528-delegated-push-exception-covers-its-journal-commit.md)
- `source` — [append-journal.sh](../../tools/append-journal.sh)
- `source` — [VAULT-IDENTITY.md](../../VAULT-IDENTITY.md)
- `source` — [publish-from-laboratory.sh](../../tools/publish-from-laboratory.sh)
- `see also` — [Publishing](publish.md)
- `see also` — [Publication and push tools](../reference/tools-publication-and-push.md)
- `see also` — [State and journal tools](../reference/tools-state-and-journal.md)
- `see also` — [Read a relay](read-a-relay.md)
- `see also` — [Why absolute paths](../explanation/why-absolute-paths.md)
