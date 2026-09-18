---
title: "Install Second Brain"
description: "Installation guide: prerequisites, installation line per platform, what the questionnaire does, installation from an archive refused."
status: active
---

# INSTALL SECOND BRAIN

**First condition: a paid subscription to at least one AI agent** (Claude Pro or higher, or ChatGPT Plus or higher). Nothing in Second Brain is designed or tested for a free account.

This repository contains Second Brain: a durable memory and a cross-project operating system for working with AI (see [README.md](./README.md) for the why and the what). A single line is enough to install it.

## 1. Prerequisites

- The paid subscription above.
- Nothing else to install by hand. Git, Python and `pre-commit` are reused if they are already on your machine; otherwise, the line below sets them up itself in your user profile, without administrator rights. On macOS, Git comes with Apple's command line tools: if they are missing, Apple offers to install them, then you rerun the same line.
- Windows (PowerShell 5.1 or higher), macOS or Linux (Bash).

## 2. Installation line

**Windows (PowerShell, a standard account is enough):**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.8/bootstrap.ps1)))"
```

**macOS / Linux (Terminal):**

```bash
curl -fsSL https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.8/bootstrap.sh | bash
```

The line downloads a bootstrap script (`bootstrap.ps1` or `bootstrap.sh`, at the root of this repository) that requires nothing installed: it sets up Git in your profile if needed, verifies its fingerprint, fetches the repository at the indicated version, then launches the installer (`install.ps1` or `install.sh`). No elevation prompt, no writing outside your profile.

**From Claude Code or Codex** (machine already equipped, or existing clone to examine): open a session in any folder and run `/first-install`. The agent asks the same questions in its own chat, writes an answers file, then calls the same installer — behaviour identical to a participant who answers live in the terminal.

**Do not extract an archive.** Second Brain is published by version tag on the Git repository, never by a zip archive that would accompany it. The guardians of this repository (checks of secrets, of links, of index freshness — `.githooks/pre-commit`) and the installation script require a real Git repository (`git rev-parse --show-toplevel` must answer): without `.git`, they refuse explicitly rather than run halfway. A folder extracted from an archive is not a Git repository and can run neither the guardians nor `/first-install` correctly — the line above always fetches a real repository.

## 3. What the installer does

In order:

1. It makes sure that Git, `uv` and `pre-commit` are usable (fetched into your profile as needed, never globally, never with elevation).
2. It creates your workspace (the folder that will contain `second-brain` and your projects), clones `second-brain` into it at its final location, and sets up the `VAULT-ROOT.md` marker there.
3. It asks seven short questions, in the language you choose at the first one (French, English or Spanish): assistant's name, location of the workspace, first name, what you do, how you work with AI, what matters to you — then confirms a first project.
4. It writes `USER.md` from your answers, generates the assistant (Claude Code subagent, Codex skill, web package to upload yourself) and sets up a `CLAUDE.md`/`AGENTS.md` of ten lines at most next to `VAULT-ROOT.md`.
5. It creates your first project if you confirmed it, with its own `CLAUDE.md`/`AGENTS.md`, and links the assistant and the method's skills (`skills/` and `skills/external/`) into it — never into your profile.
6. It returns a one-line verdict, signed with your assistant's name: installation finished, or the step where it stopped and the cause.

The installer also generates the **identity** of your Second Brain (`VAULT-IDENTITY.md`, tracked by Git like `USER.md`): each project copies it into its birth certificate, and the `VAULT-ROOT.md` marker carries it.

Each step is noted in a logbook (`.install/state.json`, at the root of your clone, never tracked by Git): an interruption resumes at the missing step, without asking again the questions already answered. Rerunning the installer on an already-installed machine switches to update mode (current answers displayed, confirmation of any change, `USER.md` rewritten) — this mode never touches the code; see ["Resume and update" in the README](./README.md#reprise-et-mise-à-jour) for what this version promises and does not promise.

## 4. The MCP server

The installer writes nothing into your profile. **The Pilot's disk access (desktop application)** is set up afterwards by `/first-install` (or by hand, line below): it detects Claude Code, Codex and the Claude desktop application, declares **this Vault's server** in them — `second-brain-vault-<8 characters of its identity>`, read in `VAULT-IDENTITY.md` — with your workspace as the only authorized folder, checks Python through `uv`, then asks you to restart the application. Two Second Brains on one machine (a laboratory and a company, for instance) therefore have two servers side by side: the script never replaces another Vault's server, and it migrates the former fixed name `second-brain-vault` (up to v0.1.7) when it pointed to this Vault. `check-mcp-containment.sh <configuration> <projet>` verifies that the project and Second Brain are indeed within the authorized perimeter.

By hand, from the root of your `second-brain` clone:

```bash
bash tools/install-vault-mcp.sh <espace de travail>
bash tools/check-mcp-containment.sh <configuration> <projet>
```

**Under Windows, in PowerShell**, `bash` is not on the PATH; call Git's by its full path (measured at the acceptance of 2026-09-17):

```powershell
& "C:\Program Files\Git\bin\bash.exe" tools/install-vault-mcp.sh <espace de travail>
& "C:\Program Files\Git\bin\bash.exe" tools/check-mcp-containment.sh <configuration> <projet>
```

**How to verify that it is running.** `check-mcp-containment.sh` validates the configuration written on disk. That the server is really active in the restarted application is confirmed at the opening of the Pilot (next section): its first answer carries a **canary**, the proof that it read the disk through this server rather than from its memory.

## 5. Open the Pilot

The first time you open a project in Claude Code, it detects that the links to the assistant and the skills leave the working folder (external import) and asks for an approval, once per project. Answer yes: see the question "Why does Claude Code ask me for an approval" in the frequently asked questions of the [README](./README.md).

The Pilot role (thinking, arbitrating, writing the Missions) is played in the Claude desktop application. Each project carries its Pilot prompt, `<projet>/state/PILOT-PROMPT.md`, generated at its creation: create a **Project** bearing the name of your project, paste the common prompt (`templates/session-opening-prompt-template.md`) as instructions, and give the project's path as first message. Complete details of the gesture in ["Open a project's Pilot" in the README](./README.md).

## 6. Adopt an existing folder

A folder that already exists (with or without Git) becomes a project without anything it contains being modified:

```bash
bash second-brain/tools/project-bootstrap.sh adopt /chemin/du/dossier --vcs git
```

The script adds only what is missing (birth certificate, pointer files, Pilot prompt, line in the registry) and reorganizes nothing without confirmation. Complete details (baseline, `--vcs none`, initiation order) in ["Adopt an existing folder" in the README](./README.md).

## 7. Update to a new version

An installed Second Brain receives a new version **without being reinstalled**: the version is merged over your own commits — your profile (`USER.md`), your Vault's identity, your projects' sheets and registry — which stay as they are; the indexes are regenerated. Nothing else is touched: not your projects, not your profile, not your tools' configuration.

From **v0.1.8 on**, from your workspace:

```bash
bash second-brain/tools/second-brain-update.sh v0.1.9
```

Under Windows, in PowerShell: `powershell -File second-brain\tools\second-brain-update.ps1 v0.1.9`.

From **v0.1.7 or earlier** (the tool is not in your installation yet): run the installation line of the new version (section 2). It sees that Second Brain is already installed, installs nothing, and prints the exact update command to run, which uses the new version's tool.

The last line says what happened: `VERDICT: UPDATED`, `VERDICT: UP-TO-DATE` or `VERDICT: REFUSED`. A refusal changes nothing and names its cause: changes not committed yet, a conflict with a local edit of a file of the method (named), an installation from before v0.1.4 (its origin is the installer's temporary folder: reinstall it in a new folder). If the message says the MCP server may have changed, run `tools/install-vault-mcp.sh` again (section 4) and restart the application.

## License

Second Brain, including the skills built by this repository, is distributed under the MIT license. See [LICENSE](./LICENSE). The third-party skills adopted in the warehouse each carry their own license, listed in [THIRD-PARTY-LICENSES.md](./THIRD-PARTY-LICENSES.md), generated by script from the warehouse's manifests.

## Liens

- `see also` — [README](./README.md)
- `see also` — [Release notes](./RELEASE-NOTES.md)
- `see also` — [Product glossary](./CONTEXT.md)
- `see also` — [MIT license](./LICENSE)
- `see also` — [Third-party licenses](./THIRD-PARTY-LICENSES.md)
