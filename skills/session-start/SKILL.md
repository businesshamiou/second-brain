---
name: session-start
description: "Open a work session: read the state files in order, announce role and readiness. Use at session start, or to (re)open or resume. Triggers on: « nouvelle session », « nouvelle session pilote », « ouvre la session », « ouverture », \"open the session\"."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), (historique de l'atelier, non distribué), rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  vault-validated: "2026-09-07T21:32:10-04:00"
---

Opens a work session: measures the state of the machine, reads the state files in order, announces the role and the readiness verdict. This skill is **read-only**: it files nothing, commits nothing, moves nothing — never, on any surface. Sole exceptions: an initiation order received, which it has executed by `tools/project-bootstrap.sh --order` (§1 bis) — the writing then belongs to the bootstrap, bounded to the target folder and to the Vault's registry —, and a profile order received, applied by `sb profile --order` (E3), whose tool writes only the `## Profil de départ` section of `USER.md`. It complements the Owner's opening prompt, it does not replace it: what the prompt has already had read, do not read again — check that it is done and fill in the gaps only.

## 0. Identify your entry scenario — before any gesture

Mission 234 ([rule on workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md) §7-§8). Find your line by **measuring** (the surface, the current folder, the first message, what you received), then follow it. Four session types: **project**, **welcome** (`SB - Accueil`), **free** (`session libre`: reads, writes nothing), **Vault**. The rest of this skill applies to your line.

| # | Scenario | Measured | Prescribed gesture | Prompt | Tool called | Proof |
|---|---|---|---|---|---|---|
| E1 | Executor in an adopted folder, with a Mission | shell; a birth certificate walking up; a `type: mission` named | the opening of §1-§4, then `identity --check` and the root guardian (warnings); the Mission | the Mission's mini-prompt | `resolve-vault.sh`, `project-bootstrap.sh identity --check`, `check-workspace-root.sh` | `tests/test-project-identity-group-accueil.sh` (3), `tests/test-check-workspace-root.sh`; agent: `tests/agent-evals` E1 |
| E2 | Executor, folder not adopted, no order | shell; no certificate; no initiation order | print the order to fill in; `NOT-READY (dossier non adopté, ordre d'initiation rendu)`; nothing written | — | `project-bootstrap.sh order <dossier>` | `tests/test-project-initiation.sh`, `tests/test-project-identity-group-accueil.sh` (10); agent: E2 |
| E3 | Executor with an initiation order received | shell; a mini-prompt of type `initiation`, or a path under `<workspace>/_orders/` | run the order; relay its output (the block that creates the project's own Pilot, `SB - <Name>`); then move the order to `<workspace>/_archive/orders/`. A profile order (`_orders/PROFILE-…`): `sb profile --order <file>`, which rewrites only `## Profil de départ` of `USER.md` and files the order itself; commit `USER.md` alone | the `initiation` mini-prompt, or the profile order's | `project-bootstrap.sh --order <file>` (field `Groupe`: `<workspace>/<group>/<name>`; fields `Résultat attendu`, `Blocage actuel`, `Rythme de revue`: `## Profil du projet` of `README.md`); `tools/starting_profile.py` | `tests/test-project-initiation.sh`, `tests/test-project-identity-group-accueil.sh` (9); agent: E3 |
| E4 | Executor opened at the workspace root, asked to work (open a session, a gesture) | shell; the current folder carries `VAULT-ROOT.md`; no certificate; no order; no Mission | `NOT-READY (racine de l'espace : ouvrir la fenêtre dans le dossier d'un projet)`; nothing written (a received order is the one exception: E3) | — | the tools' repository-root guard refuses by itself | `tests/test-repo-root-guard.sh`, `tests/test-project-identity-group-accueil.sh` (5, 11); agent: E4 |
| E5 | Executor opened in the Vault | the Vault's `SessionStart` hook injects `role: executor` | the Vault's opening; a Vault Mission, or mode 2 under a Note | the Vault Mission | `tools/session-preflight.sh` (root guardian as warning) | suite line `tools/session-preflight.sh`; `tests/test-check-workspace-root.sh` (h) |
| E6 | Executor under Codex | shell; `AGENTS.md` loaded by Codex, no hook | the same lines E1-E4: `AGENTS.md` points to the charter, which points here | the same | the same | `tools/session-preflight.sh` (pointers in `AGENTS.md`); agent: E6 written (Codex runner, Mission 242), not played |
| E7 | Pilot of a project | no shell, in any Pilot host where the Vault's server is declared ([rule on model-agnostic hosts](../../rules/RULES-2026-09-28-121219-model-agnostic-pilot-and-executor-hosts.md)); a project path in the first message, alone or after the common trunk (a host without an instructions space); its `PILOT-PROMPT.md` | canary: the Vault server's `list_allowed_directories` tool, whatever prefix the host gives it, and its answer (allowed folders, Vault commit); when the host shows the name of its instructions space, that name against `pilot_project_name` (verdict `ANOMALY (nom du Project)`, never blocking; `DECLARED` otherwise); the reading list | the common trunk, as the host's instructions or first message (`sb pilot-prompt --host`) | the Vault's MCP server | `tests/test-pilot-opening-step-zero.sh`, `tests/test-common-prompt-verdict-and-e8.sh` (7); agent: P1 (Claude Code), P4 (Codex) and P5 (Gemini CLI) written, not played |
| E8 | Pilot on a project without `PILOT-PROMPT.md` | no shell; a project path; no Pilot prompt | `NOT-READY (projet non adopté)`; to prepare the adoption, ask the project's three questions one at a time (expected result, current blocker, review rhythm; [starting-interview](../starting-interview/SKILL.md)), then propose the initiation order (template) carrying them; presume nothing | the common trunk | — | agent: P2 |
| E9 | Welcome Pilot, a new idea | no shell; the welcome Pilot `SB - Accueil`, in any Pilot host; the first message names the workspace or the Vault, alone or after the welcome block | welcome opening; read `## Profil de départ` of `USER.md` first and run the [starting interview](../starting-interview/SKILL.md) (shown and "what changed?", or one question at a time, at least three); think with the Owner; with their agreement, one order in `<workspace>/_orders/` — `ORDER-…` (initiation, with the project's three questions asked first) or `PROFILE-…` (profile); relay by a mini-prompt | [welcome template](../../templates/accueil-pilot-prompt-template.md) | `sb pilot-prompt --accueil [--host <host>]` (`project-bootstrap.sh accueil-prompt`: the block) | `tests/test-project-identity-group-accueil.sh` (12); agent: P3 |
| E10 | Free session | a question or a reading, with no project path, no Mission and no order — on any surface, the workspace root included | first line `READY (session libre)`; read and discuss; write, commit, move nothing | [free-session template](../../templates/free-session-prompt-template.md) | — | agent: F1 |
| E11 | Installation (first project) | no Vault on the machine, or no marker | the `first-install` skill: bootstrap, installer, first project (its block names `SB - <Name>`) | the published installation line | `bootstrap.*`, `install.*`, `write-marker.sh` (declared temporary folder line) | `tests/test-install-e2e.sh`, `tests/test-declared-temp-folder.sh` (h) |

A line not found in this table is not improvised: `NOT-READY (scénario non reconnu : <ce qui a été mesuré>)`.

## 1. Determine your surface, mechanically

Try a harmless shell gesture (`git --version`). It answers → **Executor** branch. No shell (chat, MCP only) → **Pilot** branch. The measured capability decides; never declare for yourself a role you have not measured.

## 1 bis. Is the folder adopted?

**Executor**: walk up from the current folder to a birth certificate (`.pre-commit-config.yaml` whose first line is `# second-brain-birth-certificate: v1`); `bash <Vault>/tools/resolve-vault.sh <dossier>` returns the Vault or a named refusal.

- **Certificate found**: continue.
- **No certificate, but an initiation order received** (mini-prompt of type `initiation`): write the order into a temporary file, launch `bash <Vault>/tools/project-bootstrap.sh --order <fichier>`, relay its output (including the block to consume), then continue the opening on the adopted project.
- **Neither certificate nor order**: do not adopt it. Launch `bash <Vault>/tools/project-bootstrap.sh order <dossier>`, return the order to fill in as it comes out, and stop: `NOT-READY (dossier non adopté, ordre d'initiation rendu)` [folder not adopted, initiation order returned].

**Pilot**: the MCP server first — `list_allowed_directories` must contain the path of the project given in the first message; then the project's `<projet>/state/PILOT-PROMPT.md`, whose canary you return. Without this file, the project is not adopted: ask the project's three questions one at a time (the `starting-interview` skill), then propose the initiation order carrying them (template `templates/initiation-order-template.md`), presume nothing about it.

## 2. Read your role's reading list

Open `reading-list.md` in this skill's folder and perform the readings of your section, in its order. If this file carries an `amended by` line, also read the amendment and apply it: it is the source of the opening protocol, not this body.

## 3. Measure your branch's canary

**Pilot**: the MCP root answers (a `get_file_info` on `<projet>/state/DIGEST.md` (reference form: from the root of the workspace)); the digest is readable, passes the freshness test of `reading-list.md` and names the last handoff; that handoff exists, is readable and dated; the four Git refs are readable.

**Executor**: awareness of position first (current directory, repository, relative paths to the root of the Vault — found by walking up to the `VAULT-ROOT.md` marker, never a hard-coded folder named `vault` — and to the project's repository). Then the three measurements: (a) `rev:` of the project's `.pre-commit-config.yaml` compared with the head of the Vault (`.git/refs/heads/main` at its root) — a gap means guardians pinned behind, not applicable to a `repo: local` pin (T01, projects born after ticket 02 of Mission 168); (b) the native hook present (`.githooks/pre-commit` at the root of the Vault) and `core.hooksPath` pointing to it; (c) each guardian script named by the hook present in `tools/` at the root of the Vault. Finally `git status -sb` of the two repositories, pasted as it is.

**Call budget**: 8 in a chat session (Decision 140714); **12 on the Executor surface**, where the role probe and the shell cost calls that the chat budget did not provide for (Mission 154, measurement of report 153: correct form in 13 calls).

## 4. Return the verdict, then stop

**Nothing before the verdict.** No greeting, no « voici la synthèse » ["here is the summary"], no table, no recap of the readings: the first character of the answer is the `R` of `READY` or the `N` of `NOT-READY`. Everything that explains comes after (Mission 153, fault measured in report 152: correct verdict, returned after two thousand characters of preamble). **An anomaly found during the opening is the reason for the `NOT-READY`**, never a paragraph before it (Mission 154, fault measured in report 153: answer opening on `**ANOMALY détectée**`).

Format, in this order: the line `READY` or `NOT-READY (<motif mesuré, verbatim>)` — `READY (session libre)` for a free session (E10) —, **first line of prose of the answer**; the announcement `[role: <pilot|executor> · <plan|implement|validate> · open]` (`· accueil` for the welcome Pilot, E9); a state in five lines with figures at most (heads of the repositories, lead over origin, open doors, last handoff, `git status` gaps), each value carrying `VERIFIED` (measured in this session, source named), `DECLARED` (copied from the digest or the handoff, timestamp of the source) or `ANOMALY` (disagreement between two sources, named). Pilot: the `git status` gaps are always `DECLARED`. Then an "Opening / budget" [« Ouverture / budget »] rubric: number of tool calls before the verdict, bytes reported by `get_file_info` only — digest and journal —, the other readings named with the mention "size not reported" [« taille non rapportée »], never estimated, tool searches run (Decision 140714, point 6).

**Where to type what** (Mission 244, capture 121525: « even I struggle to know where to run which command »). Every instruction addressed to the Owner, on any surface, starts with its place, in the Owner's language: « Dans le terminal : », « Dans le Pilot : » or « Dans l'Executor (<host>) : » (in English: « In the terminal: », « In the Pilot: », « In the Executor (<host>): »). A verb the Owner types is given in the form of that host — `sb <verb>` in a terminal, `/sb:<verb>` with the sb plugin, `$sb <verb>` in Codex — or in the three forms when the host is unknown; a mini-prompt meant for an agent may keep the terminal form. A Pilot that hands a mini-prompt first says it goes to an Executor window (any agent with a shell) and, when the Owner has none, points to the installation page (`docs/tutorials/install.md`, « An Executor »). A first message that carries no language (a path alone) is answered in the recorded language (the PILOT-PROMPT's, or `USER.md`'s for the welcome Pilot; Decision 012459).

`NOT-READY` has a single consequence, non-negotiable: **Executor — no gesture** (neither writing nor commit for the whole window); **Pilot — no filing** for the whole session. Reading and discussing remain allowed. The repair is a Mission or an Owner arbitration, never a gesture of this skill.

## What this skill does not do

The close (`session-close`) · the installation or repair of the machine (`first-install`, `project-bootstrap`) · laying down the hook (bootstrap) · the slightest writing outside an initiation order received, including a journal line — the announcement lives in the conversation · search: you read a fixed list, you do not rummage.

## Liens

- `see also` — [Session opening reading list, by role](./reading-list.md)
- `see also` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Template — initiation order](../../templates/initiation-order-template.md)
- `see also` — [Rule — Workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
- `see also` — [Template — welcome Pilot](../../templates/accueil-pilot-prompt-template.md)
- `see also` — [Template — free session](../../templates/free-session-prompt-template.md)
- `see also` — [The starting-interview skill](../starting-interview/SKILL.md)
- `amended by` — [Rule — Model-agnostic Pilot and Executor hosts](../../rules/RULES-2026-09-28-121219-model-agnostic-pilot-and-executor-hosts.md) (Mission 242: E7 and E9 in any Pilot host, the canary by its tool)
