---
title: "Second Brain"
description: "Entry page of the repository: what Second Brain is, how to install it, what is installed and where, how to uninstall it."
status: active
---

**Second Brain is a durable memory and a cross-project operating system for working with AI agents — rules, methods, templates, skills and guardrails, versioned in one Git repository you own.** It installs itself from one command line (Windows, macOS or Linux), asks a short questionnaire, and never overwrites what already exists. It requires a paid subscription to at least one AI agent (Claude Pro or higher, or ChatGPT Plus or higher) — nothing here is designed or tested against a free account. Licensed under MIT.

---

# SECOND BRAIN

## What it is

Second Brain is a durable memory and a cross-project operating system for working with AI agents: rules, methods, templates, skills and automatic guardians, versioned in a single Git repository that you own. The files remain the source of truth; the tools revolve around them.

It also ships a library of already-verified third-party skills (license, portability) — see "What is installed, and where" — and an assistant, named by you at installation (by default « Brian »), which guides the installation and then answers read-only once it is finished.

The complete glossary of the product's terms lives in [CONTEXT.md](./CONTEXT.md).

## Prerequisites

- **A paid subscription to at least one AI agent**: Claude Pro (or higher), or ChatGPT Plus (or higher). Nothing in Second Brain is designed or tested for a free account — the installer does not check it itself, but the questionnaire assumes that access.
- **Git.** Detected and reused if it is already on your machine; otherwise installed for you in your own profile, without administrator rights.
- Python and `pre-commit`: same conditions as Git, installed as needed by the installer (the `uv` manager), never globally nor with elevation.
- Windows, macOS or Linux. The PowerShell installer (`install.ps1`) and the shell installer (`install.sh`) ask the same questions, write the same logbook and produce the same verdict.

## Installation line

**Windows (PowerShell, a standard account is enough):**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.6/bootstrap.ps1)))"
```

**macOS / Linux (Terminal):**

```bash
curl -fsSL https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.6/bootstrap.sh | bash
```

Nothing needs to be installed beforehand: the bootstrap script sets up Git in your profile if it is missing, fetches this repository, then launches the installer (details in [INSTALL.md](./INSTALL.md)).

**From Claude Code or Codex**, open a session in any folder and run `/first-install`: the agent asks the same questions in its own chat, writes the answers file, then calls the same installer.

In all three cases, the installer creates your workspace, clones `second-brain` into it at its final location, sets up the `VAULT-ROOT.md` marker, and asks you seven short questions (language, assistant's name, location of the workspace, first name, activity, way of working with AI, what matters to you) before proposing a first project to you.

**Installation from an archive (zip) remains refused.** Second Brain is published by version tag on a Git repository, never accompanied by an archive: the guardians of this repository (checks of secrets, of links, of index freshness) require a real Git repository (`git rev-parse` must answer) in order to run, and a folder extracted from an archive is not one — neither the guardians nor `/first-install` work correctly there. The line above always fetches a real repository.

**Acceptance:** no step requires a human gesture. `tests/run-mechanical-acceptance.ps1` (PowerShell) replays the eleven acceptance scenarios (S1 to S10 and T21) and writes their dated report next to the repository; the `.sh` scripts it calls go through the Bash shipped with Git, which it finds on its own.

## What is installed, and where

| Component | Location | Scope |
|---|---|---|
| The `second-brain` repository itself (rules, built skills, warehouse, tools) | folder chosen by you at question 3, in your workspace | this repository only |
| The method's skills, always deployed (`skills/` and `skills/external/`) | links in `.claude/skills/` and `.agents/skills/` of **each project**, set up at its creation (Codex receives `skills/` alone if the description budget exceeds the measured ceiling) | that project only |
| The assistant (by default « Brian ») | Claude Code subagent and Codex skill linked in `.claude/agents/` and `.agents/skills/` of **each project**, plus a web package to upload yourself into a claude.ai or ChatGPT Project | that project only, plus one manual gesture for the web package |
| Git, Python and `pre-commit`, if absent from your machine | your user profile only (never a machine-wide location, never with elevation) | your user profile |
| Your `USER.md` sheet, your possible first project | in `second-brain` (`USER.md`) and next to it in the workspace (the project) | your workspace |
| The installation logbook | `.install/state.json`, at the root of your clone, never tracked by Git | your local clone |

Nothing is installed at a machine-wide location (system registry, shared folder), nothing asks for administrator rights, and nothing is placed in your profile (the *.claude*, *.agents* or *.codex* folders of your account): the assistant and the method's skills live only in the `second-brain` clone and in the projects that link them — deleting a project or the whole workspace is enough to remove everything, without a separate cleanup gesture. Only a project not listed here loses these links; recreate it with the `first-install`/`project-bootstrap` skill to get them.

## The MCP server

The Pilot role (thinking, arbitrating, writing the Missions) is played in **the Claude desktop application**: that is where Second Brain's MCP server (`second-brain-vault`) lives, which gives the Pilot disk access bounded to your workspace. It does not exist in the browser.

From Claude Code or Codex, `/first-install` sets up this server (`tools/install-vault-mcp.sh`) in the tools it finds — Claude Code, Codex, the desktop application — with your workspace as the only authorized folder. Then restart the application. By hand, from the root of your clone:

```bash
bash tools/install-vault-mcp.sh <espace de travail>
bash tools/check-mcp-containment.sh <configuration> <projet>
```

**Under Windows, in PowerShell**, `bash` is not on the PATH; call Git's by its full path:

```powershell
& "C:\Program Files\Git\bin\bash.exe" tools/install-vault-mcp.sh <espace de travail>
& "C:\Program Files\Git\bin\bash.exe" tools/check-mcp-containment.sh <configuration> <projet>
```

**How to verify that it is running.** `check-mcp-containment.sh` tells you whether the configuration written is correct. To confirm that the server is indeed active once the application has restarted, open the Pilot (next section): its very first answer carries a **canary**, the proof that it read the disk through this server rather than from its memory.

## Open a project's Pilot (desktop application)

Each project carries its Pilot prompt, `<projet>/state/PILOT-PROMPT.md`, generated at its creation. The creation returns a **block to consume**:

1. Create a **Project** (in claude.ai or the desktop application) bearing the name of your project.
2. Paste the common prompt (`templates/session-opening-prompt-template.md`) as instructions.
3. Give the project's path as first message.

At opening, the Pilot verifies that the server sees this path, then reads the project's prompt and returns its **canary**: the proof that it read the disk rather than its memory.

## Adopt an existing folder

A folder that already exists (with or without Git) becomes a project without anything it contains being modified:

```bash
bash second-brain/tools/project-bootstrap.sh adopt /chemin/du/dossier --vcs git
```

The script adds only what is missing: the **birth certificate** (at the head of `.pre-commit-config.yaml`: identity of the Second Brain that adopted it, commit, `vcs`), the pointer files, the Pilot prompt, the line in the registry. It records a **dated baseline** of the files present: the guardians judge only what is new or modified, and an old file that you touch must become compliant. It **proposes** a reorganization plan into seven functions and applies none of it; `tools/propose-link-repairs.sh` likewise proposes the repair of broken links. Without Git (`--vcs none`), no hook is set up: the checks are run by hand, `tools/check-links.sh <dossier>` and its neighbours; `adopt --git` adds Git later.

A project attaches to its Second Brain through this certificate, never by proximity: two Second Brains in the same workspace are not confused, and a project copied on its own elsewhere keeps its checks. An agent that opens a non-adopted folder stops and renders an **initiation order** to fill in (`project-bootstrap.sh order <dossier>`, template `templates/initiation-order-template.md`); with this order dated by you, it adopts without a Mission.

<a id="reprise-et-mise-à-jour"></a>

## Resume and update

If the installation is interrupted (accidental closing, network failure while fetching Git), rerun the same installation line: the logbook (`.install/state.json`, at the root of your clone) retains each step already done and each answer already given, and the installer resumes at the missing step without asking again the questions already answered.

Rerunning the installer on an already-installed machine switches to **update mode**: your current answers are displayed, a question asks you whether something has changed, and `USER.md` is cleanly rewritten with its new date if you confirm a change.

**This mode never touches the code.** This version installs as is, and no mechanism brings a more recent version into an existing installation: to get one, reinstall from the published repository (in a new folder, or in this one after having backed up your `USER.md` and your projects).

## Uninstallation

Since Mission 173 (nothing in the profile), uninstalling Second Brain consists of **deleting your workspace folder — nothing else**. The `second-brain` clone, the assistant, the method's skills: everything lives inside that folder or in links that your projects point into it; nothing is written elsewhere on your machine.

If you also want to remove the tools installed for you (portable Git and `uv`, with `pre-commit`, if you no longer want to keep them): they live in the hidden local subfolder of your profile (Windows: `%USERPROFILE%\.local\`), outside the workspace — delete that folder, then remove the corresponding entries from your account's `Path` variable (Windows: Settings → Environment variables).

**Installation older than Mission 173?** If you installed Second Brain before that Mission, an older version may have placed links in your profile (*.claude/agents/*, *.claude/skills/*, *.agents/skills/*, in your account). The `tools/remove-profile-links.ps1` script (in your clone) lists them and removes them on confirmation, without ever touching the content they pointed to — run it, read what it proposes, then confirm.

## Link a second repository (advanced)

By default, Second Brain assumes the existence of no other repository next to yours: the tools that could compare your clone with a neighbouring repository (`tools/session-preflight.sh`, `tools/check-asserted-paths.sh`, `tools/link-graph-drone-view.sh`) look for nothing and warn about nothing as long as you do not declare one explicitly.

If you use a second repository next to `second-brain` in your workspace (for example to keep your own missions and reports there) and you want these tools to see it, declare it in one of the following two ways:

- the environment variable `SECOND_BRAIN_SIBLING_REPO` (the folder's name, not a path) before running a command; or
- a *SIBLING-REPO.txt* file (which you create yourself), a single line with that same name, at the root of your workspace (next to `VAULT-ROOT.md`) — handy for a lasting declaration, valid for every session opened from that folder.

Without a declaration: silence, as if the tool did not exist. With a declaration whose folder cannot be found: a single clear warning, never a refusal.

## Frequently asked questions

**How do I ask my assistant something?** Name it explicitly in your question, for example `Demande à Brian : quelles sont les décisions actives sur la structure des projets ?` (in English: "Ask Brian: which decisions are active on the structure of projects?") — Claude Code then really delegates to the dedicated read-only subagent, which cites its sources by path. Without naming it, Claude Code's main agent may answer by itself in its place; its answer is generally correct, but it does not have the read-only guarantee that your dedicated assistant carries.

**Why does Claude Code ask me for an approval the first time I open a project?** Your assistant and your skills are linked into that project (`.claude/agents/`, `.claude/skills/`, `.agents/skills/`) by junction or direct link to your `second-brain` clone, a neighbouring folder. Claude Code treats a link whose target leaves the working folder as an **external import** and asks for an approval — once per project, never at each session. Answer **yes** (the exact text depends on your version of Claude Code): it is safe, because these links give only read access to `second-brain` itself, never write access (a project never writes there, see the [boundary rule](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md) below), and because it is the clone that you installed yourself.

**Can I install Second Brain without a paid subscription to an AI agent?** Technically the installer does not check it, but nothing is designed or tested for a free account: the results are not guaranteed.

**Can I install from a zip archive downloaded from GitHub?** No, by construction: see "Installation line" above. Always clone the repository with `git clone`.

**What is the warehouse, and do I need it?** `skills-warehouse/` is a library of already-verified third-party skills (license, portability). The installer deploys none of its collections: only the method's skills (`skills/` and `skills/external/`) are linked into your projects; your assistant explains to you how to add a collection from the warehouse later.

**Are « Vault » and « Second Brain » the same thing?** Yes: « Vault » is the internal name, used in the rules and the tools; « Second Brain » is the name you see. See [CONTEXT.md](./CONTEXT.md).

**Who decides what goes into `second-brain` as opposed to my projects?** See the [boundary rule between your projects and Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md).

**Which license for the warehouse's third-party skills?** Each carries its own, listed in [THIRD-PARTY-LICENSES.md](./THIRD-PARTY-LICENSES.md), generated from the warehouse's manifests.

**Under Windows, `bash tools/...` returns "command not found" — what should I do?** In bare PowerShell, `bash` is not on the PATH; usually only `git` is. Launch it by Git's full path, for example `& "C:\Program Files\Git\bin\bash.exe" tools/install-vault-mcp.sh <espace de travail>` (replace the end with the command you want), or open **"Git Bash"** directly from the Start menu and type the command without the `bash` prefix.

**After a failed or interrupted installation, the installer behaves strangely — what should I do?** First delete the temporary folder that the installer reuses, then rerun the installation line: `%TEMP%\second-brain-install` under Windows, `${TMPDIR:-/tmp}/second-brain-install` under macOS/Linux. The installer normally brings this folder up to date on its own and refuses explicitly if it cannot, but a folder left by a previous attempt remains the first thing to set aside if the behaviour observed does not match what you expect.

**I want to check `claude_desktop_config.json` by hand — where do I find it?** Two possible locations depending on how the Claude desktop application was installed: **Microsoft Store** version, under `%LOCALAPPDATA%\Packages\Claude_<identifiant>\LocalCache\Roaming\Claude\claude_desktop_config.json`; **classic** version (official site), under `%APPDATA%\Claude\claude_desktop_config.json`. `tools/install-vault-mcp.sh` detects and writes to the right file automatically — this manual check serves only to confirm afterwards.

**Why must the Pilot use exclusively the `second-brain-vault` server, even if another file server is configured?** This exclusivity exists because nothing else bounds its disk access to your workspace: another server (for example that of another project) could let the Pilot read or write outside the intended folder, or mix two projects without your noticing — `templates/session-opening-prompt-template.md` explicitly forbids it to do so. If the Pilot seems confused about the context (wrong project, paths that do not match), check with `check-mcp-containment.sh <configuration> <projet>` that `second-brain-vault` is indeed configured with your workspace as authorized folder, then explicitly ask it again to reread the disk through this server.

## Run the test suite

The whole suite fits in one list, [`tests/suite.tsv`](./tests/suite.tsv): one test per line, with the systems where it runs, whether it is blocking or informational, and the Mission that brought it. The CI no longer lists any test, it plays this list; the same command plays it on your machine, from the root of the repository:

```bash
bash tests/run-suite.sh
```

Under Windows, the same runner exists in PowerShell, the one the CI uses: `powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-suite.ps1`. Each test runs, even after a red one; the last line gives `RESULT: <n>/<total> PASS` and the list of red tests precedes it. `--list` displays only what would be played on your system.

## License

Second Brain is distributed under the MIT license — see [LICENSE](./LICENSE). The third-party skills adopted in the warehouse each carry their own license, listed in [THIRD-PARTY-LICENSES.md](./THIRD-PARTY-LICENSES.md).

## Liens

- `see also` — [Installation guide](./INSTALL.md)
- `see also` — [Release notes](./RELEASE-NOTES.md)
- `see also` — [Product glossary](./CONTEXT.md)
- `see also` — [Boundary rule between a project and Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
- `see also` — [Third-party licenses](./THIRD-PARTY-LICENSES.md)
- `see also` — [MIT license](./LICENSE)
- `see also` — [Instructions for agents](./AGENTS.md)
- `see also` — [Document linking standard](./rules/RULES-2026-08-21-115658-document-linking-standard.md)
