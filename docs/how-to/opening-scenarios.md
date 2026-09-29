---
type: how-to
title: "Opening scenarios"
description: "For each of the eleven ways a session can start (E1 to E11), what you see first — the exact verdict line —, why, and what to do next, on the Pilot's side and on the Executor's side; plus the verdicts every opening shares."
status: active
---

# OPENING SCENARIOS

Every session starts in one of eleven situations, E1 to E11. The agent recognises its situation **by measuring** — the surface it runs on, the folder it was opened in, your first message, what it received — before any gesture, and answers with a verdict on its very first line. This page reads the eleven lines from your side: what you see, why, and what to do. The mechanics (what is measured, which tool runs, which test proves it) live in the entry-scenario matrix at the head of the [session-start skill](../../skills/session-start/SKILL.md) (§0); how to open each window is in [Open a session](open-a-session.md), and which window to choose for what you want to do is in [Start something new](start-something-new.md).

The verdicts are fixed strings in French, the language the method was written in; a translation follows each one in brackets. The rest of the answer is in your language.

## Before you start

- **Two surfaces.** An **Executor** has a shell: Claude Code or Codex, opened in a folder. A **Pilot** has no shell: a conversation in a Pilot host — a Project of the Claude desktop application, or another tool where your Vault's MCP server is declared ([Pilot hosts and role mixing](pilot-hosts-and-role-mixing.md)) — reaching your files only through that server. The agent decides which one it is by trying a shell command ([role charter §1](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)).
- **Four session types.** A **project** session (a project path, or a birth certificate found walking up from the folder), a **welcome** session (the Project `SB - Accueil`), a **free** session (no project, no Mission, no order) and a **Vault** session (a window opened in the Vault itself) ([rule on workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md) §7).
- **Names.** A project's Pilot is a Project named `SB - <display name>`; `sb pilot-prompt <folder>` prints that name, the block to paste as its instructions, the first message and the canary ([Use the sb command](use-the-sb-command-and-plugin.md)).

## What every opening shares

- **The verdict comes first.** The first line of the answer is `READY` or `NOT-READY (<reason>)` — `READY (session libre)` in a free session — with nothing before it: no greeting, no summary. An anomaly found while opening is the reason inside the verdict, never a paragraph before it.
- **Then the announcement and a short state.** `[role: <pilot|executor> · <plan|implement|validate> · open]` (`· accueil` for the welcome Pilot), then at most five lines of state, each value marked `VERIFIED` (measured now), `DECLARED` (copied from a file, with its timestamp) or `ANOMALY` (two sources disagree).
- **`NOT-READY` stops the window's work.** An Executor makes no gesture — no writing, no commit — for the whole window; a Pilot files nothing for the whole session. Reading and discussing stay allowed. The repair is a Mission or your decision.
- **A situation that fits no line** is never improvised: `NOT-READY (scénario non reconnu : <what was measured>)` [scenario not recognised].

## The Executor's side

### E1 — An Executor in an adopted project, with a Mission

- **You see:** `READY`, then `[role: executor · … · open]` and the state.
- **Why:** a birth certificate was found walking up from the folder, and you named a Mission. The opening also checks the workspace root (each `ÉCART` [gap] is a warning, never a block) and the project's identity card (folder, certificate, registry: each mismatch is an `ANOMALY`, never a block).
- **What to do:** nothing; it runs the Mission. `sb open` (or `/sb:open`, `$sb open`) opens the same way.

### E2 — An Executor in a folder that is not adopted, with no order

- **You see:** `NOT-READY (dossier non adopté, ordre d'initiation rendu)` [folder not adopted, initiation order returned], followed by an initiation order to fill in. Nothing is written.
- **Why:** there is no birth certificate above the folder, and adopting a folder writes into your Vault's registry: an agent never does it on its own initiative.
- **What to do:** fill in the order (with the welcome Pilot, or by hand) and give it back as an `initiation` mini-prompt (E3), or adopt the folder yourself with `sb adopt` ([Adopt an existing folder](adopt-a-project.md)).

### E3 — An Executor that receives an initiation order

- **You see:** the output of the project's creation or adoption, ending with the block `Create a Project named "SB - <Name>"` and the instructions to paste; then the opening goes on in the new project (E1).
- **Why:** an order you dated is the one thing that lets an agent adopt a folder without a Mission. The Executor runs it (`sb new --order <file>`, which calls `tools/project-bootstrap.sh --order <file>`) and moves the order to `<workspace>/_archive/orders/`.
- **What to do:** create the Project with the exact name the block gives, paste the block, and send the project's path as its first message (E7).

### E4 — An Executor opened at the workspace root

- **You see:** `NOT-READY (racine de l'espace : ouvrir la fenêtre dans le dossier d'un projet)` [workspace root: open the window in a project folder]. Nothing is written.
- **Why:** the root of the workspace holds no work; the tools refuse it by themselves, so that a command typed in the wrong window cannot rewrite your workspace. A received order is the one exception (E3).
- **What to do:** open the window in a project folder (`sb list` shows them). A question with no project is a free session (E10).

### E5 — An Executor opened in the Vault

- **You see:** `READY` after the Vault's own opening; the role `executor` is injected by the Vault's startup hook.
- **Why:** work on the Vault itself goes through a Mission of the Vault, or through a prompt of yours traced by an execution Note for a change that sets no doctrine.
- **What to do:** give it the Vault Mission, or your prompt.

### E6 — An Executor under Codex

- **You see:** the same lines as E1 to E4.
- **Why:** Codex runs no startup hook; the `AGENTS.md` it loads points to the role charter, which points to the matrix.
- **What to do:** the same as in E1 to E4; `$sb <verb>` replaces `/sb:<verb>`.

### E11 — Installation, a machine with no Second Brain

- **You see:** no session verdict: the installer's steps, then its own one-line verdict, `Installation complete: everything is in place. — <assistant>` or the step where it stopped.
- **Why:** there is no Vault and no marker yet; the `first-install` skill (or the published installation line) installs it and creates your first project, whose final block names `SB - <Name>`.
- **What to do:** follow [Your first installation](../tutorials/install.md), then `sb doctor` and `sb install`.

## The Pilot's side

Before any reading, every Pilot checks that its channel answers: one search for the server's file tools and one cheap read. No answer within 60 seconds gives `NOT-READY (channel not answering)`: the server is not connected — restart your Pilot's host, or run `sb install --mcp` in a terminal first. The server runs on your machine: a browser-only tool cannot start it.

### E7 — The Pilot of a project

- **You see:** `READY`, then the project's **canary** (`pp-` followed by 12 hexadecimal characters) — the proof that it read your disk through the server rather than answering from memory.
- **Why:** the path you sent is under an authorized folder, and `<project>/state/PILOT-PROMPT.md` exists; the Pilot then reads the state sheet it names (`state_path`, by default `<project>/state/STATE.md`) and applies the contract at its head.
- **The name of the Project.** When the application shows the Project's name, the Pilot compares it with `pilot_project_name`: a mismatch is `ANOMALY (nom du Project)` [Project name] in the state, **never** a `NOT-READY`; when the name is not shown, the line says `DECLARED`. Fix: rename the Project to the name `sb pilot-prompt <folder>` gives.
- **What to do:** work. If you sent no path at all, the answer is `NOT-READY (projet non nommé)` [project not named]: send the project's path.

### E8 — A path the Pilot cannot use as a project

Two different verdicts, two different causes — the Pilot tells them apart:

| You see | Why | What to do |
|---|---|---|
| `NOT-READY (chemin non autorisé : réinstaller le serveur MCP, sb install)` [path not authorized: reinstall the MCP server] | The path lies under none of the folders your Vault's server may read. The project may well exist: the Pilot proposes no order. | In a terminal, `sb install --mcp` (or `sb install`), then restart the desktop application. |
| `NOT-READY (projet non adopté)` [project not adopted] | The path is authorized, but it carries no `state/PILOT-PROMPT.md`: the folder is not an adopted project. | The Pilot proposes an initiation order from `templates/initiation-order-template.md`, writing nothing; date it and hand it to an Executor (E3), or run `sb adopt` in that folder. |

### E9 — The welcome Pilot, a new idea

- **You see:** `READY`, then `[role: pilot · plan · accueil]`.
- **Why:** you opened the Project `SB - Accueil` and your first message names the workspace, not a project. It thinks new projects through with you, and has one writing gesture: with your agreement on its exact content, one initiation order in `<workspace>/_orders/`.
- **What to do:** once agreed, it hands you an `initiation` mini-prompt; paste it in an Executor window opened in the workspace (E3). Create `SB - Accueil` once, with the block `sb pilot-prompt --accueil` prints, typed anywhere in the workspace (it is `tools/project-bootstrap.sh accueil-prompt` underneath; [Start something new](start-something-new.md)).

### E10 — A free session, on any surface

- **You see:** `READY (session libre)` [free session].
- **Why:** you asked a question with no project path, no Mission and no order — even at the workspace root. It reads and discusses; it writes, commits and moves nothing.
- **What to do:** ask. If you ask for something that writes, it names the session type you need — a project's Pilot `SB - <name>` or an Executor with a Mission, or `SB - Accueil` for a project that does not exist yet — and stops there.

## Other verdicts you may meet

| You see | Why | What to do |
|---|---|---|
| `NOT-READY (session close missing)` | The newest handoff of the project was filed but its close was never made, so every state value read is stale. | Run that handoff's Executor closing command first ([Close a session](close-a-session.md)). |
| `READY` with `ANOMALY (unlinked channel)` | The Pilot's tools answer but run on the client side: each first use of a tool waits for your approval. | Do not leave unattended work running from that window. |
| The session stops and asks which role it holds | Two ways of determining the role disagree. | Answer with the role; in doubt, `pilot` is presumed. |

## Liens

- `source` — [Skill: session-start, entry-scenario matrix](../../skills/session-start/SKILL.md)
- `source` — [Session opening reading list, by role](../../skills/session-start/reading-list.md)
- `source` — [Rule — Workspace hygiene, project names and session types](../../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
- `source` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `source` — [Template — minimal opening prompt for a Pilot session](../../templates/session-opening-prompt-template.md)
- `source` — [Template — welcome Pilot](../../templates/accueil-pilot-prompt-template.md)
- `source` — [Template — free session](../../templates/free-session-prompt-template.md)
- `source` — [Template — initiation order](../../templates/initiation-order-template.md)
- `see also` — [Open a session](open-a-session.md)
- `see also` — [Start something new](start-something-new.md)
- `see also` — [Use the sb command and its plugin](use-the-sb-command-and-plugin.md)
- `see also` — [Adopt an existing folder](adopt-a-project.md)
- `see also` — [Support FAQ](../reference/support-faq.md)
