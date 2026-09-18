---
name: session-start
description: "Open a work session: read the state files in order (Pilot: digest, handoff, Git refs; Executor: also repo and guardian state), and announce role and readiness. Use at the start of any session, or when asked to (re)open, resume, or check readiness. Triggers on: « nouvelle session », « nouvelle session pilote », « ouvre la session », « ouverture », \"open the session\"."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), (historique de l'atelier, non distribué), rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  vault-validated: "2026-09-07T21:32:10-04:00"
---

Opens a work session: measures the state of the machine, reads the state files in order, announces the role and the readiness verdict. This skill is **read-only**: it files nothing, commits nothing, moves nothing — never, on any surface. Sole exception: an initiation order received, which it has executed by `tools/project-bootstrap.sh --order` (§1 bis); the writing then belongs to the bootstrap, bounded to the target folder and to the Vault's registry. It complements the Owner's opening prompt, it does not replace it: what the prompt has already had read, do not read again — check that it is done and fill in the gaps only.

## 1. Determine your surface, mechanically

Try a harmless shell gesture (`git --version`). It answers → **Executor** branch. No shell (chat, MCP only) → **Pilot** branch. The measured capability decides; never declare for yourself a role you have not measured.

## 1 bis. Is the folder adopted?

**Executor**: walk up from the current folder to a birth certificate (`.pre-commit-config.yaml` whose first line is `# second-brain-birth-certificate: v1`); `bash <Vault>/tools/resolve-vault.sh <dossier>` returns the Vault or a named refusal.

- **Certificate found**: continue.
- **No certificate, but an initiation order received** (mini-prompt of type `initiation`): write the order into a temporary file, launch `bash <Vault>/tools/project-bootstrap.sh --order <fichier>`, relay its output (including the block to consume), then continue the opening on the adopted project.
- **Neither certificate nor order**: do not adopt it. Launch `bash <Vault>/tools/project-bootstrap.sh order <dossier>`, return the order to fill in as it comes out, and stop: `NOT-READY (dossier non adopté, ordre d'initiation rendu)` [folder not adopted, initiation order returned].

**Pilot**: the MCP server first — `list_allowed_directories` must contain the path of the project given in the first message; then the project's `<projet>/state/PILOT-PROMPT.md`, whose canary you return. Without this file, the project is not adopted: propose the initiation order (template `templates/initiation-order-template.md`), presume nothing about it.

## 2. Read your role's reading list

Open `reading-list.md` in this skill's folder and perform the readings of your section, in its order. If this file carries an `amended by` line, also read the amendment and apply it: it is the source of the opening protocol, not this body.

## 3. Measure your branch's canary

**Pilot**: the MCP root answers (a `get_file_info` on `<projet>/state/DIGEST.md` (reference form: from the root of the workspace)); the digest is readable, passes the freshness test of `reading-list.md` and names the last handoff; that handoff exists, is readable and dated; the four Git refs are readable.

**Executor**: awareness of position first (current directory, repository, relative paths to the root of the Vault — found by walking up to the `VAULT-ROOT.md` marker, never a hard-coded folder named `vault` — and to the project's repository). Then the three measurements: (a) `rev:` of the project's `.pre-commit-config.yaml` compared with the head of the Vault (`.git/refs/heads/main` at its root) — a gap means guardians pinned behind, not applicable to a `repo: local` pin (T01, projects born after ticket 02 of Mission 168); (b) the native hook present (`.githooks/pre-commit` at the root of the Vault) and `core.hooksPath` pointing to it; (c) each guardian script named by the hook present in `tools/` at the root of the Vault. Finally `git status -sb` of the two repositories, pasted as it is.

**Call budget**: 8 in a chat session (Decision 140714); **12 on the Executor surface**, where the role probe and the shell cost calls that the chat budget did not provide for (Mission 154, measurement of report 153: correct form in 13 calls).

## 4. Return the verdict, then stop

**Nothing before the verdict.** No greeting, no « voici la synthèse » ["here is the summary"], no table, no recap of the readings: the first character of the answer is the `R` of `READY` or the `N` of `NOT-READY`. Everything that explains comes after (Mission 153, fault measured in report 152: correct verdict, returned after two thousand characters of preamble). **An anomaly found during the opening is the reason for the `NOT-READY`**, never a paragraph before it (Mission 154, fault measured in report 153: answer opening on `**ANOMALY détectée**`).

Format, in this order: the line `READY` or `NOT-READY (<motif mesuré, verbatim>)`, **first line of prose of the answer**; the announcement `[role: <pilot|executor> · <plan|implement|validate> · open]`; a state in five lines with figures at most (heads of the repositories, lead over origin, open doors, last handoff, `git status` gaps), each value carrying `VERIFIED` (measured in this session, source named), `DECLARED` (copied from the digest or the handoff, timestamp of the source) or `ANOMALY` (disagreement between two sources, named). Pilot: the `git status` gaps are always `DECLARED`. Then an "Opening / budget" [« Ouverture / budget »] rubric: number of tool calls before the verdict, bytes reported by `get_file_info` only — digest and journal —, the other readings named with the mention "size not reported" [« taille non rapportée »], never estimated, tool searches run (Decision 140714, point 6).

`NOT-READY` has a single consequence, non-negotiable: **Executor — no gesture** (neither writing nor commit for the whole window); **Pilot — no filing** for the whole session. Reading and discussing remain allowed. The repair is a Mission or an Owner arbitration, never a gesture of this skill.

## What this skill does not do

The close (`session-close`) · the installation or repair of the machine (`first-install`, `project-bootstrap`) · laying down the hook (bootstrap) · the slightest writing outside an initiation order received, including a journal line — the announcement lives in the conversation · search: you read a fixed list, you do not rummage.

## Liens

- `see also` — [Session opening reading list, by role](./reading-list.md)
- `see also` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Template — initiation order](../../templates/initiation-order-template.md)
