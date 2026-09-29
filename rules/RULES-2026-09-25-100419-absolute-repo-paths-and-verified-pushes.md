---
type: rules
title: "Absolute repository paths and verified pushes"
description: "Every write or push command in a Mission, a report or a block handed to the Owner names the absolute path of its repository and goes through the protected tools; never `.` nor a path that depends on the current folder. The writing tools refuse the workspace root and any folder in no repository; every push goes through tools/verified-push.sh."
created_at: "2026-09-25T10:04:19-04:00"
timezone: America/Montreal
status: active
scope: repository-paths, pushes
---

# ABSOLUTE REPOSITORY PATHS AND VERIFIED PUSHES

## 1. Why

On 2026-09-21 the index builder was run with `.` from the workspace root, a folder that holds several repositories without being one. It rewrote about 2,400 index files in sibling folders, six of them without Git, so there was nothing to restore them from (Mission 210, workshop history, not distributed). On 2026-09-25 the same command, `bash ../vault/tools/build-indexes.sh .`, was typed again from the same folder. It did nothing only because `bash` was not found in that PowerShell window. The command had been handed over with a path relative to the folder it was meant to run in, and it ran in another one.

The Owner, the same morning: « il faudrait l'ajouter […] comme règle et comme peut-être une règle de validation avant le pousser […] dans des outils ça devrait être mécanique. Comme ça on n'aura jamais ce genre de problème » ["it should be added […] as a rule, and maybe as a validation rule before the push […] in the tools it should be mechanical. That way we will never have this kind of problem"].

So the rule has two parts: words for the people and the agents who write commands, and mechanics in the tools, which hold even when the words are forgotten.

## 2. The rule

1. **Absolute paths.** Every command that writes or pushes, in a Mission, a report, a handoff's closing command or any block handed to the Owner, names the absolute path of the repository it acts on: `git -C <absolute path> …`, `cd <absolute path> && …`, or the path as the tool's argument. Never `.`, and never a relative path whose meaning depends on the folder the reader happens to be in. In a document meant for any machine, write the path as `<workspace>/<repository>` and say that `<workspace>` is the absolute path of the workspace.
2. **Protected tools.** Writing into a repository goes through the Vault's tools, which carry the repository-root guard (§3). A hand-written loop that edits files across folders is not a substitute.
3. **Verified pushes.** Every push of a branch goes through [`tools/verified-push.sh`](../tools/verified-push.sh), with the exact range: `bash <workspace>/second-brain/tools/verified-push.sh <absolute repository path> <from>..<to> [<remote>] [--url <url>]` (in a laboratory, the Vault's folder is `vault` instead of `second-brain`). A bare `git push` is never prescribed. The delegation of a push is unchanged: a clear expression of the Owner that names the gesture and its target (relay rule).
4. **Publication.** Publishing is not a push of a branch: it goes through [`tools/publish-from-laboratory.sh`](../tools/publish-from-laboratory.sh), which pushes a fast-forward itself, and the tag of a published version is pushed by `tools/publish-tag.sh` (Mission 230), which pushes that one tag to `release` and to `origin` and reads each remote back ([publishing](../docs/how-to/publish.md)). Those are the two named exceptions to point 3.

## 3. The mechanics

- **Repository-root guard** ([`tools/repo_root_guard.py`](../tools/repo_root_guard.py)), the one place that decides. A target is admitted when a `.git` or a birth certificate is found, walking up from it, before any workspace root. A workspace root is a folder that carries `VAULT-ROOT.md`, or that holds two or more Git repositories without being one. Anything else is refused before anything is written, with a message that names the path received and the root expected. No switch and no environment variable turns it off.
- **Tools that carry it:** `build-indexes.sh` (through `build_indexes.py`), `append-journal.sh`, `build-state.sh`, `build-digest.sh`, `set-release-version.sh`, `vault-identity.sh ensure`, `propose-link-repairs.sh` (through `propose_link_repairs.py`), and `project-bootstrap.sh create|adopt`. The bootstrap uses the guard's `--new-project` mode: its target is a project folder, often in no repository yet, and it is refused only when that folder is itself a workspace root.
- **Tools that target the workspace by design:** `write-marker.sh` and `install-vault-mcp.sh` take the workspace root as their argument, because that is where the marker and the server's allowed folder live. The guard does not apply to them. `write-marker.sh` writes the marker and the pointer files into the folder it is given; `install-vault-mcp.sh` records that folder as the server's allowed folder and writes the tool configurations and the Vault's label, nothing into the workspace. Their argument is written as an absolute path all the same (point 1).
- **Verified push** ([`tools/verified-push.sh`](../tools/verified-push.sh)) refuses, before anything is pushed:
  - a relative or non-root path;
  - HEAD other than `<to>`, or a detached HEAD;
  - a remote head other than `<from>`;
  - a remote other than the declared one: `--url` when given; otherwise `vault_origin` for a Vault, or, for any other repository (a project, the workshop), the `# push_url:` key of the birth certificate that heads its `.pre-commit-config.yaml` (Mission 231); a repository that declares nothing and gets no `--url` is refused;
  - a `<to>` that does not descend from `<from>`;
  - any forcing option.

  `--dry-run` checks everything and pushes nothing.
- Proof: `tests/test-repo-root-guard.sh` replays the incident against every tool above, and `tests/test-verified-push.sh` checks each refusal on local bare repositories.

## 4. What an Executor does when a tool refuses

It reads the message, which names the path received and the expected root. It rewrites the command with the absolute path of the right repository. It never looks for another way to write to the refused place. If the refusal comes from the session's permission tool rather than from the Vault's guard, the gesture goes to the final block for the Owner, with absolute paths, in order, ready for Git Bash.

## Liens

- `applies` — [Relay between roles through mini-prompts](./RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Role charter and session determination](./RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Decision — Permanent deletion is an Owner gesture](../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
- `see also` — [Mission template](../templates/mission-template.md)
