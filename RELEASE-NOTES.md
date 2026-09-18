---
title: "Release notes"
description: "What each published version of Second Brain contains, and what it does not promise."
status: active
---

# RELEASE NOTES

## v0.1.6

Language version: what Second Brain is made of is now written in English; what it says to you stays in the language you chose. One fix for everyone who installed v0.1.5.

**What this version brings.**

- **The corpus is in English, one version.** Rules, skills, templates, documentation, these release notes, the copies of Decisions, and the comments of the scripts and tests are translated faithfully: same rules, same numbers, same prohibitions, same file paths and link targets. An agent of any language reads one reference text.
- **You keep your language.** The messages the installer shows you still come from its catalogues, in the language you picked (French, English or Spanish), exactly as before. The skills keep their French trigger phrases next to the English ones: « wrap », « clôture », « écris la Mission » still work.
- **The published line installs the version it names.** The v0.1.5 line downloaded a bootstrap whose default version was still v0.1.4, so it installed v0.1.4. The line and the bootstrap's default version now agree, and a test keeps them agreed.
- **One command plays the whole test suite on your machine.** `bash tests/run-suite.sh` plays the same list the public CI plays (see [`README.md`](./README.md)).

**How it is proven.** Four named tests, each with its negative control, chained in the public CI: the corpus has no file above the French-language threshold, the link targets are the ones frozen before the translation, the skills carry their triggers in both languages, and the published line agrees with the bootstrap. The inventory is in [`tests/index.md`](./tests/index.md).

**What this version does not promise.**

- A few fixed strings stay in French because the tools read them literally: the `## Liens` heading, the `(hors Vault)` and `(supprimé)` markers, the field lines of `VAULT-ROOT.md`, the RELAY block, the headings of the generated state sheets. They are anchors, not prose.
- The messages printed by the scripts outside the catalogues (guardian refusals, test labels) are unchanged in this version.
- The limits of the previous versions remain valid: no update mechanism, S7 and S8 at `SKIP` without a provider key.

**What remains to be done on your side.**

- If you installed with the v0.1.5 line, you received v0.1.4: run the line above to get this version.

## v0.1.5

Comfort version: three touch-ups to the way you delegate a gesture to the agent and the way you start a new Project — nothing that changes what is executed.

**What this version brings.**

- **Delegating a push no longer requires a formula to recite.** Until now, authorizing a push required a precise sentence, copied word for word. A clear sentence from you, which says what to push, is now enough — the agent measures it, it no longer judges its form.
- **The instructions to paste into a Project (Claude Desktop or ChatGPT) are ready to use.** The installer generates them in full, at the moment a project is created or adopted, in the very text to paste: you no longer need to go and open a separate file to find them.
- **The installation documentation is reworked, with an expanded FAQ.** README.md and INSTALL.md now follow the same four-step path (install, the MCP server, open the Pilot, adopt an existing folder), and the FAQ answers the most frequent questions met during installation.

**How it is proven.** Six named tests, each with its negative control, chained in the public CI. The inventory is in [`tests/index.md`](./tests/index.md).

**What this version does not promise.**

- Nothing new on the execution features side: this version clarifies what is read and pasted, it touches no gesture that the agent executes for you.
- The limits of the previous versions remain valid: no update mechanism, S7 and S8 at `SKIP` without a provider key.

**What remains to be done on your side.**

- Nothing immediate: these changes apply the next time you delegate a push or create or adopt a project. If you want to start again from this version, rerun the published line above.

## v0.1.4

Corrective version: v0.1.3 replayed by hand on an already-used Windows machine, in the desktop application, showed eleven defects that the CI could not see — its scenarios always start from a blank machine. If you have already run the published line at least once, install from this version.

**What this version fixes.**

- **An already-used machine no longer installs an outdated version.** This is the most serious defect. The installation line downloads the repository into a temporary folder; that folder survives from one time to the next, and the bootstrap reused it as is. A folder forgotten from the previous week therefore installed its old content — without identity, without birth certificate, without Pilot prompt — while announcing « Installé, tout est en place » ["Installation complete: everything is in place."]. The folder is now updated and brought to the requested version, and the bootstrap verifies that it got there. In case of a gap (another repository, a nonexistent version), it refuses, naming the folder to set aside: never a deletion, never `--force`.
- **Your Second Brain knows where it comes from.** `vault_origin` — in `VAULT-IDENTITY.md`, in the `VAULT-ROOT.md` marker and in each project's birth certificate — named the temporary folder instead of the origin repository. It now carries the real origin; when the source has none, the fallback to its path is told to you, never set silently.
- **A refusal from the MCP server is readable.** In the desktop application, a read outside the perimeter displayed "Tool execution failed", with neither path nor reason. The server now returns a text that names the requested file **and** the list of authorized folders.
- **A project's first commit succeeds.** `adopt` created the Git repository without an author identity: on a machine without a global `user.email`, the first commit died on "Author identity unknown". Every repository created or taken over receives a local identity — that of your Second Brain, otherwise a neutral identity.
- **`--git` counts as an answer.** `project-bootstrap.sh adopt <projet> --git` still asked the question « Suivre ce projet avec Git ? » ["Track this project with Git?"], which blocked any call without a terminal. The option settles the question instead of preceding it.
- **The Pilot knows that Second Brain's server is its only file tool.** The common prompt now says so in one sentence: any other file tool is outside the perimeter, even if it is available.
- **The installation leaves your Second Brain clean.** It used to end leaving the first project's sheet untracked and two indexes modified — the state the guardians refuse. A last pass regenerates the indexes and records what remains.
- **The paths displayed are those of your system.** Under Windows, the Pilot prompt, the project sheet and the block to consume carried the project's path in Git Bash form, with the drive letter at the start and forward slashes; they now carry the native Windows form, the one the application and the MCP server return.
- **The documentation gives a line that can be pasted.** `INSTALL.md` and `README.md` wrote `bash tools/install-vault-mcp.sh`; `bash` is not on PowerShell's `PATH`. The exact Windows invocation, through Git's bash, now appears there.
- **The adoption plan now speaks only of what already exists.** It used to propose filing away the index that the same call had just written.

**How it is proven.** Twelve named tests, each with its negative control — the same measurement on a case built to fail — chained in the Windows, Ubuntu and macOS jobs of the public CI. The inventory is in [`tests/index.md`](./tests/index.md).

**What this version does not promise.**

- Nothing new on the features side: this version closes doors, it does not open any.
- The folder of the desktop application's Project (the application's own file tools, outside the MCP server) remains an open question, not settled here.
- The limits of the previous versions remain valid: no update mechanism, S7 and S8 at `SKIP` without a provider key, injection of the MCP server proven on a simulated profile.

**What remains to be done on your side.**

- If you have already installed a previous version: simply rerun the published line above. If it refuses, naming a temporary folder, set that folder aside as it asks, then rerun.
- For the rest, nothing changes: `/first-install` for the MCP server, then one Project per project with the common prompt and the path as first message.

## v0.1.3

Initiation version: a project is born or is adopted by naming its Second Brain, and the Pilot receives a disk access versioned with it.

**What this version brings.**

- **Adopt an existing folder without modifying it.** `tools/project-bootstrap.sh adopt` adds only what is missing. It records a dated baseline of the files present:
  - the guardians judge only what is new and what is touched;
  - an old file that is modified must become compliant;
  - the reorganization into seven functions and the repair of broken links are proposed, never applied.
- **One birth certificate per project.** At the head of `.pre-commit-config.yaml`, a block of comments names:
  - the identity of the Second Brain (`vault_id`, generated at installation in `VAULT-IDENTITY.md`);
  - its origin and its commit;
  - the Git tracking (`vcs: git` or `none`).
  `tools/resolve-vault.sh` resolves a project's Second Brain through this certificate, then through the marker if there is only one candidate, never by proximity. Two Second Brains in the same workspace are no longer confused, and a project copied on its own keeps its checks.
- **Without Git too.** With `vcs: none`, no hook: `check-links.sh`, `check-secrets.sh`, `check-indexes-fresh.sh`, `check-index-weight.sh` and `check-project-conformity.sh` accept a folder as argument. `adopt --git` adds Git later.
- **An initiation order.** An agent that opens a non-adopted folder stops and renders the order to fill in (`project-bootstrap.sh order`). With the order dated by the Owner, it adopts without a Mission (`--order`).
- **An embedded MCP server.** `tools/vault-mcp.py` (Python, standard library, launched by `uv`):
  - bounds the Pilot's access to the authorized folders;
  - refuses a link that escapes them;
  - returns Second Brain's commit.
  `tools/install-vault-mcp.sh`, called by `/first-install`, declares it in Claude Code, Codex and the desktop application. `tools/check-mcp-containment.sh` verifies the perimeter.
- **One Pilot prompt per project.** `<projet>/state/PILOT-PROMPT.md` carries the project's path, Second Brain's identity and a canary that the Pilot returns at opening; creation returns the block to consume (Project to create, common prompt to paste, first message).
- **Conformity measures the project tier**: certificate, pin, Git hook, consistency of the pointer files with the certificate. The registry gains the `vcs` column.

The public CI exercises each of these behaviours on Windows, macOS and Linux, each with its negative control, in addition to the five existing jobs.

**What this version does not promise.**

- Injection of the MCP server is proven on a simulated profile, with stand-ins for `claude` and `codex`: the CI launches neither the real tools nor the desktop application.
- The desktop application reads the configuration at the path measured on your machine; under Windows, the two known locations are filled in when they exist, without proof of which one the application reads.
- The limits of the previous versions remain valid: no update mechanism, S7 and S8 at `SKIP` without a provider key.

**What remains to be done on your side.**

- Run `/first-install` to set up the MCP server, then restart the Claude application.
- For each project: create the Project, paste the common prompt, give the project's path as first message.

## v0.1.2

Corrective version: the installation line of v0.1.1 fails under Windows on a machine that carries the WSL launcher (`C:\Windows\System32\bash.exe`). If that is your case, install from this version.

**What this version fixes.**

- **Git Bash is found even when WSL is present.** The installer took WSL's `bash.exe` for Git's and stopped. It now starts from `git.exe`, goes up to Git's `bash.exe` whatever the depth of the folder, and refuses a `bash.exe` located under the Windows folder.
- **pre-commit is found when uv comes from elsewhere.** If uv was already installed (winget, scoop), the installer looked for pre-commit next to uv instead of in uv's tools folder, and stopped. It now asks uv for that folder and adds it to your `PATH`.
- **Tests that measure what they say.** None of these changes touches the installation:
  - the web package test obtains uv the way the installer does and launches the copy of the index generator present in the clone;
  - the S9 test gives the standard account the right to log on as a batch job, without which the scheduled task did not start, then verifies that right.

The public CI passes on this content, with its five jobs, including S9 under a standard account. S7 and S8 remain marked `SKIP` there.

**What this version does not promise.**

- The limits of v0.1.1 remain valid (see below): no update mechanism, S7 and S8 at `SKIP` without a provider key, upload of the web package not proven.

## v0.1.1

Proof version: everything that served to accept Second Brain becomes replayable, without a human gesture.

**What this version brings.**

- **An installation line that requires nothing installed.** It downloads a bootstrap script (`bootstrap.ps1`, `bootstrap.sh`). That script sets up Git in your profile if it is missing, verifying its fingerprint, then fetches the repository and launches the installer. The line of v0.1.0 started with `git clone`: a machine without Git could not start. Nothing asks for administrator rights.
- **A fully mechanical acceptance.** `tests/run-mechanical-acceptance.ps1` returns eleven dated lines (S1 to S10 and T21):
  - the assistant (S7) and the web package (S8) are asked the three questions of `assistant/ASSISTANT.md`, three times each, by two providers;
  - S9 installs the published line under a standard Windows account, without Git, with a control that proves no elevation is possible;
  - the human wizard of v0.1.0 is withdrawn (kept in `_trash/`).
- **The web package contains exactly what its README announces.** A superfluous `index.md` disappears, and the README's file count becomes exact again.
- **The assistant loads in Codex.** Under Windows, the generated forms carried a byte order mark (BOM), which prevented Codex from reading the skill.
- **macOS and Linux as they are shipped.** Since v0.1.0:
  - the guardians really run at commit (the hooks were not executable);
  - the tools work with Apple's bash 3.2 and BSD tools, which the CI now exercises on macOS at every push;
  - a path containing `&` or a backslash no longer escapes two guardians;
  - the Unix installer's test mode no longer writes into your real profile.

**What this version does not promise.**

- Still no update mechanism: a v0.1.0 installation does not become v0.1.1 by itself. Reinstall from the published line if you want this version.
- S7 and S8 call a model: in the public CI, without a provider key, these two lines are marked `SKIP`, never passed by default.
- S8 proves the content of the package and the answers obtained by equivalence; it does not prove the upload gesture in the web interface.

**What remains to be done on your side.**

- Paste the installation line.
- Under macOS, accept the installation of Apple's command line tools if it is offered.
- In a claude.ai or ChatGPT Project, paste the web package's instructions file and upload the files its README lists.

## v0.1.0

First published version: a fresh history, without any ancestor from the development history, and no private pattern either in the tree or in the history (verified by `tools/check-private-patterns.sh` in full mode).

**What this version contains.** The one-line installer (Windows, macOS, Linux); the seven-question questionnaire; the generated assistant (Claude Code subagent, Codex skill, web package); the method's skills and the warehouse of third-party skills; the automatic guardians (`.githooks/pre-commit`); the Mission register and the project templates.

**What this version does not promise.** No update mechanism: an installation holds for the installed version, it cannot fetch a more recent one. For a more recent version, reinstall from the published repository — see ["Resume and update" in the README](./README.md#reprise-et-mise-à-jour). A project created during the questionnaire cannot be renamed afterwards. macOS is not exercised by the automatic CI: its job starts only on manual trigger.

## Liens

- `see also` — [README](./README.md)
- `see also` — [INSTALL](./INSTALL.md)
