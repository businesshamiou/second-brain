---
name: first-install
description: "Install Second Brain from Claude Code or Codex: ask the same seven questions the installer's own terminal questionnaire asks, in the agent's own chat, write them to an answers file, then run install.ps1 or install.sh non-interactively. Also handles an already-existing clone: examines the parent folder for a prior or partial installation before deciding whether to start fresh, resume, or update. Use when asked to install, repair, resume, or update Second Brain from an agent chat. Triggers on: « installe Second Brain », « installer Second Brain », \"install Second Brain\"."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), (historique de l'atelier, non distribué), (historique de l'atelier, non distribué)"
  vault-validated: "2026-09-11T17:00:00-04:00"
---

Installs Second Brain by driving **the same mechanism** as the human door (`install.ps1` on Windows, `install.sh` on macOS/Linux): this skill never reimplements the installer, it only supplies its two required inputs — an **answers file** and a **local source** — then launches it. Everything the installer already guarantees (idempotence, installation log, same three language catalogues, same verdict) is inherited unchanged.

## 1. Locate the source and determine the scenario

This `SKILL.md` file lives at `<clone>/skills/first-install/SKILL.md` in a Second Brain clone — whether that clone is the one you are working in directly, or the original clone from which this skill was linked (never copied) when it was deployed into the personal skills folder (`tools/deploy-skills.ps1`/`deploy-skills.sh`, ticket 07). In both cases, resolve `<clone>` as two folders above the real path of this file, and use it as the installer's `-Source`/`--source` — always a local path, never a URL.

Then examine the parent folder of `<clone>` (the workspace):

- **`<workspace>/.install` or `<clone>/.install/state.json` is absent** — no installation has ever started here. Treat this case as a **fresh installation**: propose the parent of `<clone>` itself, or a new neighbouring workspace, at question 3 below.
- **`<clone>/.install/state.json` exists but is incomplete** (a previous run was interrupted) — **resume**: first read yourself the answers already recorded and the steps already done, and ask only what is really missing, in the fixed order below.
- **`<clone>/.install/state.json` exists and all the steps are done** — this is an **already installed** workspace. Show what was recorded, ask « quelque chose a changé ? » ["has anything changed?"], and rewrite an answer only if the person answers yes — never a silent rerun on a finished installation.

Never guess this state from memory: read the real log. Never write to it yourself — the installer script is its only owner; this skill produces only the answers file that the installer reads.

## 2. Ask the seven questions, in this exact order

Same order and same defaults as the terminal questionnaire (T06 complement 2), because a mix of questions answered in the terminal and by the agent, on the same installation, must remain indistinguishable for the installer:

1. **Language** — `FR`, `EN` or `ES`. Default: the language already used in this conversation, if it matches one of the three; otherwise `EN`. It is also the language to use for the rest of this conversation.
2. **Assistant name** — default `Brian`.
3. **Workspace** — where Second Brain (and its first project) must live. Default: the parent folder found at step 1 (fresh installation) or the existing folder (resume/update — never moved).
4. **First name.**
5. **What the person does, in one sentence.**
6. **How they work with AI** — comma-separated tokens among `claude-code`, `codex`, `claude-ai`, `chatgpt`. You already know which of the first two are true for *this* conversation — propose it as the default, never ask the person what you can already observe.
7. **What matters to them** — default: « simplicity, no over-engineering ».

The skills of the method (`skills/` and `skills/external/`) are now always deployed by link, for Claude Code as for Codex: no question concerns them any more (the former eighth question, withdrawn). The warehouse (`skills-warehouse/`) is never deployed by this skill.

Then confirm the **first project**: default yes, suggested name derived from the answer to question 5 (lower case, non-alphanumeric runs reduced to a hyphen), editable.

Never ask a question whose answer can be measured from the environment (OS, shell, presence of Claude Code or Codex, time zone) — that is exactly what T06 forbids, agent questionnaire included.

## 3. Write the answers file and call the installer

Write a JSON file (a temporary path is fine — it is never committed, the installer only reads it) in the following format, one field per question above, plus the fixed defaults for everything that was not asked because already known from a resumed log:

```json
{
  "language": "EN",
  "vaultName": "Brian",
  "workspacePath": "/chemin/vers/le/workspace",
  "firstName": "...",
  "activity": "...",
  "aiTools": ["claude-code", "codex"],
  "whatMatters": "simplicity, no over-engineering",
  "firstProject": { "create": true, "name": "...", "displayName": "..." },
  "git": { "userName": "Second Brain Installer", "userEmail": "installer@example.invalid" }
}
```

Then launch, depending on the platform, exactly one of these two commands:

- Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File "<clone>\install.ps1" -Source "<clone>" -AnswersFile "<fichier-de-reponses>"`
- macOS/Linux: `bash "<clone>/install.sh" --source "<clone>" --answers-file "<fichier-de-reponses>"`

Never pass `-TestMode`/`--test-mode` here — this skill drives a real installation in the person's profile and workspace, never a throwaway installation (`-TestMode`/`--test-mode` exist only for the automated tests of this repository, tickets 03 to 08). The installer prints exactly one verdict line, signed with the chosen assistant name, on success — or a line naming the step, the cause and the remedy otherwise. Relay that line as it is; do not paraphrase it, since it is also what the installation log has just recorded.

## 4. Lay down the Vault's MCP server (the Pilot's disk access)

Once the installer's verdict has been relayed, provide the Pilot's disk access, which comes only from the Vault:

1. Launch `bash "<clone>/tools/install-vault-mcp.sh" "<workspace>" --lang <langue>` (on Windows, through Git's `bash`). The script detects what is present — `claude` (Claude Code), `codex`, the Claude desktop application at its measured configuration folder — and declares the `second-brain-vault` server there (`claude mcp add`, `codex mcp add`, merge into `claude_desktop_config.json` that keeps the other servers). Authorized folder: the root of the workspace. Python is checked by `uv`. A second pass changes nothing.
2. Check the containment for the first project: `bash "<clone>/tools/check-mcp-containment.sh" <configuration> "<workspace>/<projet>"` must return `VERDICT: PASS` (project and Vault under an authorized folder).
3. Relay the remaining gesture that the script prints: **restart the Claude application** (and relaunch Claude Code or Codex). The Pilot role requires the desktop application: the MCP server does not exist in the browser.
4. Relay the first project's block to consume (Project to create, common prompt to paste, first message = path of the project); the canary of this project is in its `<projet>/state/PILOT-PROMPT.md`.

This gesture writes into the configurations of the person's tool: it is run only in a real installation, never in `-TestMode`/`--test-mode`.

## 5. What this skill never does

- Reimplements no step of the installer (prerequisites, cloning, guardians, assistant generator, skills deployment, profile) — all of that remains the work of `install.ps1`/`install.sh`, unchanged.
- Never overwrites an existing, complete installation without an explicit « oui, quelque chose a changé » ["yes, something has changed"] from the person.
- Pushes nothing, deletes nothing, touches nothing outside the workspace it installs.
- Never invents an answer to a question intended for a human — on resume, it reads the answers already recorded, it never fabricates new ones.

## Liens

- `see also` — [install.ps1](../../install.ps1)
- `see also` — [install.sh](../../install.sh)
- `see also` — [AGENTS.md](../../AGENTS.md)
- `see also` — [Decision — Project initiation and adoption, embedded MCP server](../../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
