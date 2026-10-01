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

## Documentation

The documentation lives in [`docs/`](./docs/index.md), in four families; each page cites the files it relies on.

| Family | What you find there |
|---|---|
| [Tutorials](./docs/tutorials/index.md) | Learn by doing, in order: [install](./docs/tutorials/install.md), [your first project](./docs/tutorials/first-project.md), [your first Mission end to end](./docs/tutorials/first-mission.md). |
| [How-to guides](./docs/how-to/index.md) | One operation each, with its exact commands: open or close a session, create, adopt or bring a project into conformity, write or run a Mission, read a RELAY, delegate and push, update, uninstall, publish, react to a guardian's refusal, add a skill, troubleshoot. |
| [Reference](./docs/reference/index.md) | Every script of `tools/` with its options, what it reads and writes and its repository-root guard; the skills; the guardians and hooks; the file formats; roles and permissions; the glossary. |
| [Explanation](./docs/explanation/index.md) | Why it works this way: the architecture, the two roles, the guardians, the life of a Mission, the Decisions, why every command names an absolute path, the assistant. |
| [Documentation map](./docs/MAP.md) | One table from a kind of question to the page that answers it; your assistant carries it. |
| [Support FAQ](./docs/reference/support-faq.md) | The questions people ask most — installing, a `READY` or `NOT-READY` verdict, the `sb` command, updating — with a short answer and the page behind it. |
| [Glossary](./CONTEXT.md) · [Release notes](./RELEASE-NOTES.md) · [Installation](./INSTALL.md) | Terms, versions, the installation line and its options. |

## Prerequisites

- **A paid subscription to at least one AI agent**: Claude Pro (or higher), or ChatGPT Plus (or higher). Nothing in Second Brain is designed or tested for a free account — the installer does not check it itself, but the questionnaire assumes that access. Two paths are guided end to end: **Claude** (the Claude desktop app as Pilot, Claude Code as Executor: proven) and **OpenAI** (Codex as Executor and as Pilot: declared); any other agent: [adapt another agent](./docs/how-to/pilot-hosts-and-role-mixing.md#adapt-another-agent).
- **An Executor, installed first**: an agent with a shell, Claude Code or Codex — Second Brain installs none. The official lines are in [Your first installation](./docs/tutorials/install.md), step 1; `sb doctor` says when there is none.
- **Git.** Detected and reused if it is already on your machine; otherwise installed for you in your own profile, without administrator rights.
- Python and `pre-commit`: same conditions as Git, installed as needed by the installer (the `uv` manager), never globally nor with elevation.
- Windows, macOS or Linux. The PowerShell installer (`install.ps1`) and the shell installer (`install.sh`) ask the same questions, write the same logbook and produce the same verdict.

## Installation line

**Windows (PowerShell, a standard account is enough):**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.16/bootstrap.ps1)))"
```

**macOS / Linux (Terminal):**

```bash
curl -fsSL https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.16/bootstrap.sh | bash
```

Nothing needs to be installed beforehand: the bootstrap script sets up Git in your profile if it is missing, fetches this repository, then launches the installer (details in [INSTALL.md](./INSTALL.md)).

**From Claude Code or Codex**, open a session in any folder and run `/first-install`: the agent asks the same questions in its own chat, writes the answers file, then calls the same installer.

In all three cases, the installer creates your workspace, clones `second-brain` into it at its final location, sets up the `VAULT-ROOT.md` marker, and asks you nine short questions (language, assistant's name, location of the workspace, first name, what you do, how you work with AI, what matters most to you, whether to create a first project now, and that project's name). It then chains `sb install` and `sb doctor`, puts the welcome Pilot's block on your clipboard, and ends on **three gestures, each with its place**: *In the Claude app:* create a Project named `SB - Accueil`; *In its instructions:* paste (Ctrl+V); *In a conversation of that Project:* write « bonjour ». Where to type what, always: [the table of places](./docs/how-to/use-the-sb-command-and-plugin.md#where-to-type-what).

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
| The `sb` command | `tools/sb/bin` of your clone, added to your user PATH | your user PATH |

Nothing is installed at a machine-wide location (system registry, shared folder), nothing asks for administrator rights, and nothing is placed in your profile (the *.claude*, *.agents* or *.codex* folders of your account) — except, on your own command, what `sb install` adds: the Claude Code plugin `sb@second-brain` in Claude Code's own settings: the assistant and the method's skills live only in the `second-brain` clone and in the projects that link them — deleting a project or the whole workspace is enough to remove everything, without a separate cleanup gesture. Only a project not listed here loses these links; recreate it with the `first-install`/`project-bootstrap` skill to get them.

## The sb command

Every operation has one English verb of the `sb` command — `sb open`, `sb close`, `sb new`, `sb adopt`, `sb update`, `sb doctor` and 16 more — typed in any terminal, as `/sb:<verb>` in Claude Code, as `$sb <verb>` in Codex, or as a message that starts with `sb ` to the Pilot. `sb help` shows the welcome screen in your language, `sb help <verb>` one page per verb. The installer puts `sb` on your PATH; after it, in a new terminal, run `sb install` (the Claude Code plugin behind `/sb:<verb>`, and the MCP server below, each only if needed), then `sb doctor`, which checks everything. How to install, check and repair it: [Use the sb command and its plugin](./docs/how-to/use-the-sb-command-and-plugin.md); every verb: [Commands](./docs/reference/commands.md).

## The MCP server

The Pilot role (thinking, arbitrating, writing the Missions) is played in **a Pilot host** — the Claude desktop application today, or another tool that runs a local MCP server (Codex, Gemini CLI, Cursor, Windsurf, Cline, LM Studio: [Pilot hosts and role mixing](./docs/how-to/pilot-hosts-and-role-mixing.md)) — through Second Brain's MCP server, `second-brain-vault-<workspace>`, named after the folder of the workspace it covers (for example `second-brain-vault-workspaces`; the first 8 characters of your Vault's identity only when no workspace label is recorded), one per Vault, so two Second Brains on one machine keep two servers side by side — which gives the Pilot disk access bounded to your workspace. It runs on your machine: a browser-only tool (ChatGPT, Gemini on the web) cannot start it — see the [rule on model-agnostic hosts](./rules/RULES-2026-09-28-121219-model-agnostic-pilot-and-executor-hosts.md).

The installer sets up this server at its end (`sb install`); `sb install --mcp` in a terminal, or `/first-install` from Claude Code or Codex, does it again (`tools/install-vault-mcp.sh`) in every tool it finds — the Claude desktop application, Claude Code, Codex, Gemini CLI, Cursor, Windsurf, Cline, LM Studio — with your workspace as the only authorized folder. Then restart each of them; **the Claude app must be ended, not only closed** (in Windows: Settings → Apps → Installed apps → Claude → Advanced options → Terminate; macOS: Cmd+Q) — while it runs in the background it may drop the server from its configuration, so `sb install` asks to close it for you and reads the file back. `sb doctor` shows one line per tool found. By hand, from the root of your clone:

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

## Open a project's Pilot

The steps below are those of the Claude desktop application; for another Pilot host, `sb pilot-prompt <folder> --host <host>` gives its own ([Pilot hosts and role mixing](./docs/how-to/pilot-hosts-and-role-mixing.md)): the same block, sent as the first message with the path.

Each project carries its Pilot prompt, `<projet>/state/PILOT-PROMPT.md`, generated at its creation. The creation returns a **block to consume**:

1. Create a **Project** in the desktop application named `SB - <display name>`: the letters `SB`, a space, a hyphen, a space, then your project's name as the registry records it.
2. Paste the common prompt (`templates/session-opening-prompt-template.md`) as instructions.
3. Give the project's path as first message.

`sb pilot-prompt <folder>` prints all of it for one project — the Project's name, the block with your server's name filled in, the first message and the canary — and writes nothing.

At opening, the Pilot verifies that the server sees this path, then reads the project's prompt and returns its **canary**: the proof that it read the disk rather than its memory. Its first line is always the verdict, `READY` or `NOT-READY (<reason>)`; each reason, and what to do about it, is in [Opening scenarios](./docs/how-to/opening-scenarios.md).

## Adopt an existing folder

A folder that already exists (with or without Git) becomes a project without anything it contains being modified — `sb adopt <folder>`, or the tool it calls:

```bash
bash second-brain/tools/project-bootstrap.sh adopt /chemin/du/dossier --vcs git
```

The script adds only what is missing: the **birth certificate** (at the head of `.pre-commit-config.yaml`: identity of the Second Brain that adopted it, commit, `vcs`), the pointer files, the Pilot prompt, the line in the registry. It records a **dated baseline** of the files present: the guardians judge only what is new or modified, and an old file that you touch must become compliant. It **proposes** a reorganization plan into seven functions and applies none of it; `tools/propose-link-repairs.sh` likewise proposes the repair of broken links. Without Git (`--vcs none`), no hook is set up: the checks are run by hand, `tools/check-links.sh <dossier>` and its neighbours; `adopt --git` adds Git later.

A project attaches to its Second Brain through this certificate, never by proximity: two Second Brains in the same workspace are not confused, and a project copied on its own elsewhere keeps its checks. An agent that opens a non-adopted folder stops and renders an **initiation order** to fill in (`project-bootstrap.sh order <dossier>`, template `templates/initiation-order-template.md`); with this order dated by you, it adopts without a Mission.

<a id="reprise-et-mise-à-jour"></a>

## Resume and update

If the installation is interrupted (accidental closing, network failure while fetching Git), rerun the same installation line: the logbook (`.install/state.json`, at the root of your clone) retains each step already done and each answer already given, and the installer resumes at the missing step without asking again the questions already answered.

Rerunning the installer on an already-installed machine switches to **update mode**: your current answers are displayed, a question asks you whether something has changed, and `USER.md` is cleanly rewritten with its new date if you confirm a change.

**This mode never touches the code.** A more recent version is received by the **update** (from v0.1.8 on): `sb update <version>`, or `bash second-brain/tools/second-brain-update.sh <version>`, merges the published version over your own commits — profile, identity, projects and history kept, indexes regenerated, the links to a renamed skill remade in your projects — and refuses cleanly, with nothing touched, on a conflict or an uncommitted change. When your installation's update tool is older than the version (v0.1.14 and earlier for v0.1.15), or from v0.1.7 or earlier, run the installation line of the new version: it prints the exact update command, which runs the new version's tool, instead of installing. Details in [INSTALL.md, section 7](./INSTALL.md) and [Update](./docs/how-to/update.md).

## Uninstallation

Since Mission 173 (nothing in the profile), uninstalling Second Brain consists of **deleting your workspace folder** — after taking `sb` off your PATH (`sb uninstall --path`) and, if you added it, removing the Claude Code plugin (`claude plugin uninstall sb@second-brain`); `sb uninstall` prints these steps. The `second-brain` clone, the assistant, the method's skills: everything lives inside that folder or in links that your projects point into it. Details in [Uninstall](./docs/how-to/uninstall.md).

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

**The Pilot answers `NOT-READY (…)` — what does it mean?** The reason in brackets is measured; each one, from `projet non adopté` [project not adopted] to `chemin non autorisé` [path not authorized], has its cause and its fix in [Opening scenarios](./docs/how-to/opening-scenarios.md). More short answers: [Support FAQ](./docs/reference/support-faq.md).

**`sb` is not recognised, or `/sb:<verb>` does not exist in Claude Code — what should I do?** Open a new terminal (the PATH entry applies to new ones), then run `sb install`, and `/reload-plugins` in an open Claude Code session; `sb doctor` says what is still missing. See [Use the sb command and its plugin](./docs/how-to/use-the-sb-command-and-plugin.md).

**Can I install Second Brain without a paid subscription to an AI agent?** Technically the installer does not check it, but nothing is designed or tested for a free account: the results are not guaranteed.

**Can I install from a zip archive downloaded from GitHub?** No, by construction: see "Installation line" above. Always clone the repository with `git clone`.

**What is the warehouse, and do I need it?** `skills-warehouse/` is a library of already-verified third-party skills (license, portability). The installer deploys none of its collections: only the method's skills (`skills/` and `skills/external/`) are linked into your projects; your assistant explains to you how to add a collection from the warehouse later.

**Are « Vault » and « Second Brain » the same thing?** Yes: « Vault » is the internal name, used in the rules and the tools; « Second Brain » is the name you see. See [CONTEXT.md](./CONTEXT.md).

**Who decides what goes into `second-brain` as opposed to my projects?** See the [boundary rule between your projects and Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md).

**Which license for the warehouse's third-party skills?** Each carries its own, listed in [THIRD-PARTY-LICENSES.md](./THIRD-PARTY-LICENSES.md), generated from the warehouse's manifests.

**Under Windows, `bash tools/...` returns "command not found" — what should I do?** In bare PowerShell, `bash` is not on the PATH; usually only `git` is. Launch it by Git's full path, for example `& "C:\Program Files\Git\bin\bash.exe" tools/install-vault-mcp.sh <espace de travail>` (replace the end with the command you want), or open **"Git Bash"** directly from the Start menu and type the command without the `bash` prefix.

**After a failed or interrupted installation, the installer behaves strangely — what should I do?** First delete the temporary folder that the installer reuses, then rerun the installation line: `%TEMP%\second-brain\second-brain-install` under Windows, `${TMPDIR:-/tmp}/second-brain/second-brain-install` under macOS/Linux. The installer normally brings this folder up to date on its own and refuses explicitly if it cannot, but a folder left by a previous attempt remains the first thing to set aside if the behaviour observed does not match what you expect.

**I want to check `claude_desktop_config.json` by hand — where do I find it?** Two possible locations depending on how the Claude desktop application was installed: **Microsoft Store** version, under `%LOCALAPPDATA%\Packages\Claude_<identifiant>\LocalCache\Roaming\Claude\claude_desktop_config.json`; **classic** version (official site), under `%APPDATA%\Claude\claude_desktop_config.json`. `tools/install-vault-mcp.sh` detects and writes to the right file automatically — this manual check serves only to confirm afterwards.

**Why must the Pilot use exclusively the `second-brain-vault-<workspace>` server, even if another file server is configured?** This exclusivity exists because nothing else bounds its disk access to your workspace: another server (for example that of another project) could let the Pilot read or write outside the intended folder, or mix two projects without your noticing — `templates/session-opening-prompt-template.md` explicitly forbids it to do so. If the Pilot seems confused about the context (wrong project, paths that do not match), check with `check-mcp-containment.sh <configuration> <projet>` that `second-brain-vault-<workspace>` is indeed configured with your workspace as authorized folder, then explicitly ask it again to reread the disk through this server.

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
- `see also` — [Documentation pages (index)](./docs/index.md)
- `see also` — [Tutorials](./docs/tutorials/index.md)
- `see also` — [How-to guides](./docs/how-to/index.md)
- `see also` — [Reference](./docs/reference/index.md)
- `see also` — [Explanation](./docs/explanation/index.md)
- `see also` — [Documentation map](./docs/MAP.md)
- `see also` — [Support FAQ](./docs/reference/support-faq.md)
- `see also` — [Use the sb command and its plugin](./docs/how-to/use-the-sb-command-and-plugin.md)
- `see also` — [Opening scenarios](./docs/how-to/opening-scenarios.md)
- `see also` — [Rule — The sb command surface](./rules/RULES-2026-09-26-200933-sb-command-surface.md)
- `see also` — [Boundary rule between a project and Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
- `see also` — [Third-party licenses](./THIRD-PARTY-LICENSES.md)
- `see also` — [MIT license](./LICENSE)
- `see also` — [Instructions for agents](./AGENTS.md)
- `see also` — [Document linking standard](./rules/RULES-2026-08-21-115658-document-linking-standard.md)
