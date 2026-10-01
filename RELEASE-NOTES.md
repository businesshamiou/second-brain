---
title: "Release notes"
description: "What each published version of Second Brain contains, and what it does not promise."
status: active
---

# RELEASE NOTES

## v0.1.16 (draft, not published)

_Draft prepared by Mission 244, after the final tests of v0.1.15 from the public repository (a Windows Sandbox, the welcome and first-project scenarios); the version is published only by the maintainer's own gesture ([publishing](./docs/how-to/publish.md))._

**What this version brings.**

- **One line, then three gestures.** The installer now chains what was yours to type: `sb install` (the plugin, the MCP server in every tool present), `sb doctor`, the welcome Pilot's block on your clipboard, and ends on three gestures, each with its place — in the Claude app, create the Project `SB - Accueil`; paste; write « bonjour ». The welcome block names your workspace, so the first message no longer has to be a path, and a message with no language gets the one you chose.
- **The Claude app no longer eats the server.** It rewrites its configuration while it runs in the background and loads a server only once ended: `sb install` asks to close it (`(Y/n)`, never without your yes), reads the file back after writing, and names the exact gesture otherwise; `sb doctor` says what to do when the Pilot sees no server.
- **An Executor is announced.** Second Brain installs no agent: the documentation, the installer's question 6 and `sb doctor` now say which agents are there, and give the official line of Claude Code or Codex when one is missing. Two paths are guided: Claude (proven) and OpenAI through Codex (declared).
- **A close that ends, in every situation.** The close starts in the Pilot (`sb close` is marked « Pilot: yes »); a session that produced nothing needs no handoff: `sb close --light` writes one `STATE:` line, the state sheet and the digest, and commits them. `sb close` measures the situation and the push state; the public repository of an installed Vault is never counted as a push to do. `sb close --accueil` closes a welcome session.
- **Mechanical commits are made by the tools.** `sb new --order` and `sb adopt` commit the new project and the Vault's registry; `sb profile --order` commits `USER.md` alone, with LF line ends; `sb install --mcp --label` commits `VAULT-IDENTITY.md` alone — each through the guardians, a refusal shown as it is.
- **Where to type what.** Every instruction starts with its place — « In the terminal », « In the Pilot », « In the Executor (<host>) » — and a verb comes in the form of its host; [the table of places](./docs/how-to/use-the-sb-command-and-plugin.md#where-to-type-what). `sb` works from any folder, serving your Vault's workspace. Blocks go to the clipboard (`sb pilot-prompt … --copy`), never through a terminal selection that cuts long lines.
- **Shorter server names, no hidden default, your language everywhere.** The default workspace label is cut to 14 characters (`second-brain-workspace` → `second-brain`); the installer's optional questions have no hidden default and seed your starting profile; the step lines and `sb profile`'s refusals speak your language; a new project's `CLAUDE.md` carries the order's purpose.

## v0.1.15 (draft, not published)

_Draft prepared by Missions 222, 223, 226, 230, 231, 234, 235, 236, 237, 240, 241 and 242; the version is published only by the maintainer's own gesture ([publishing](./docs/how-to/publish.md))._

**What this version brings.**

- **One command for everything: `sb`.** Every operation of Second Brain now has one English verb — `sb open`, `sb close`, `sb handoff`, `sb status`, `sb new`, `sb adopt`, `sb list`, `sb pilot-prompt`, `sb mission`, `sb run`, `sb relay`, `sb push`, `sb search`, `sb doctor`, `sb clean`, `sb update`, `sb install`, `sb uninstall`, `sb add-skill`, `sb publish` — typed in any terminal (Git Bash, PowerShell, macOS, Linux), as `/sb:<verb>` in Claude Code (plugin `sb`, installed once with `claude plugin marketplace add <Vault>/skills/claude-plugins` and `claude plugin install sb@second-brain`), as `$sb <verb>` in Codex, or as a message to the Pilot. `sb help` opens a welcome screen in your language, `sb help <verb>` a page per verb, `sb help start`, `concepts` and `scenarios` three short guides; every verb checks where it runs first and says where to go. The installer puts `sb` on your PATH; on an existing installation, run `<workspace>/second-brain/tools/sb/bin/sb install --path` once. Two skills get English names: `mission-writing` (formerly `ecriture-de-mission`) and `internal-search` (formerly `recherche-interne`); `sb adopt` gives an existing project the new links. See [Commands](./docs/reference/commands.md).
- **Second Brain gets to know you, and each project.** The welcome Pilot `SB - Accueil` now reads your starting profile first — what you do, what matters to you, your three biggest headaches, your review rhythm, your everyday tools — shows it and asks only what has changed; when there is none, it asks one question at a time. With your yes it files a profile order, and `sb profile --order <file>` writes it under `## Profil de départ` of your `USER.md`, touching nothing else; `sb profile` shows it. A new or adopted project can carry its expected result, its current blocker and its review rhythm — three optional fields of the initiation order, or asked by `sb new --ask` and `sb adopt --ask` — under `## Profil du projet` of its README, and its state sheet shows them. Missions are written, and your assistant answers, with both in mind. The installer and its nine questions do not change; paste the welcome Pilot's block again once (`sb pilot-prompt --accueil`). See [The starting interview](./docs/how-to/starting-interview.md).
- **Your Pilot in any tool that runs a local MCP server.** The Pilot and the Executor are roles, not products: Second Brain's server is now declared by `sb install --mcp` in every tool present on your machine — the Claude app, Claude Code, Codex, Gemini CLI, Cursor, Windsurf, Cline, LM Studio — and in none that is absent; `sb doctor` shows one line per tool. The Pilot's block is the same for every tool, and `sb pilot-prompt --host <tool>` gives the steps around it (where to paste it, how to open the tool without a shell, the first message); the Pilot finds its server by the tool, whatever name the tool gives it. You can mix: a Pilot in the Claude app with an Executor in Codex, or the other way round. A server name too long for some tools is refused with a shorter label proposed (`sb install --mcp --label <label>`). What each tool is — proven, or declared from its dated documentation — is in [Pilot hosts and role mixing](./docs/how-to/pilot-hosts-and-role-mixing.md). The pages that said « 21 verbs » say 22, and the last line of `sb install` speaks your language.
- **Your first steps, on one page and in your language.** `sb help start` walks you through ten steps; its second step creates the welcome Pilot `SB - Accueil` and starts the starting interview. Its block is printed by `sb pilot-prompt --accueil`, typed anywhere in your workspace — in PowerShell as in any other terminal, with no `bash` to type. The command card and the [command reference](./docs/reference/commands.md#help-pages) cite the page. Under Windows, `sb doctor` says when `bash` is not on your terminal's PATH and names the form to type instead; the guides give the `sb` verb, or the PowerShell form next to each `bash` line. Four method skills have shorter descriptions, so the Codex skill budget keeps a margin of more than 500 characters, which `sb doctor` shows.
- **Your projects' names are plain ASCII: `SB - <name>`.** The Pilot Project of a project is named with a hyphen, no longer a middle dot, so it types the same on every keyboard and in every terminal. The tools write, check and show the new form; if you already created Projects under the former prefix (a middle dot after `SB`), rename them once in the Claude application.
- **An update keeps your skill links working.** When a version renames a skill, updating your Vault replaces, in each of your projects, the link under the old name by the link under the new one, and notes it in the project's journal; a link it does not know is named, never removed. Adopting a project again does the same.
- **`sb install` finishes the job, `sb clean` can empty the temporary folder.** `sb install` puts `sb` on your PATH, adds the Claude Code marketplace, installs the plugin (and reinstalls it when your copy is older than your Vault's), and declares your Vault's MCP server — each step only if needed. `sb clean --purge-temp` empties the declared temporary folder after asking you; it never touches the trash nor the archive. Paths are shown the way your terminal writes them.
- **A skipped test can no longer hide.** The test runner names every skipped test and its reason; a test marked required on your system counts as a failure when it skips.
- **An update no longer stops at your own profile.** `USER.md` is written whole by the questionnaire from your answers, while the version carries the empty skeleton — so the slightest change to that skeleton used to end every update on `VERDICT: REFUSED`, for every installation. The update now resolves that one file: your side is kept **byte for byte**, and only what the new skeleton adds and you do not have — a front-matter key, a section heading — is appended. The `language:` key this version adds is filled from what the installer recorded, not left empty. No other file of yours is ever resolved behind your back: a conflict elsewhere is still refused by name, with nothing changed.
- **A published version reaches every Vault.** The tag of a version is now posed and pushed by one command, `tools/publish-tag.sh`, to **both** repositories the laboratory pushes to, and each one is read back before the command says it is done. A Vault installed from the other repository used to see nothing of a new version, and its update answered that there was no such version.
- **Running the installation line again no longer fails.** On a completed installation, it stopped on an `unbound variable` error instead of switching to update mode — measured on Git Bash as well as on macOS and Linux. It asks whether anything has changed, and a "no" touches nothing.
- **Your first project names the server you really have.** The installer records your workspace label with your Vault's identity, before creating that project, so its Pilot prompt names the MCP server `tools/install-vault-mcp.sh` configures. It used to name a server that did not exist.
- **Re-running the MCP setup never renames your server.** A Vault whose identity carries no workspace label — one installed before that key existed — kept its server name on a re-run instead of being renamed after its workspace folder, which would have made every project's Pilot prompt wrong. Renaming is still possible, and is now asked for explicitly with `--label`.
- **The installation line installs the version it names.** The published v0.1.14 still named v0.1.9 in its line and in the default of both bootstraps, so it installed v0.1.9. Publishing now raises the four places to the new tag in the very commit that receives it (`tools/publish-from-laboratory.sh --version`, `tools/set-release-version.sh`).
- **A complete documentation, in four families.** [`docs/`](./docs/index.md) now holds tutorials (install, your first project, your first Mission end to end), a how-to guide per operation with its exact commands, a reference sheet for every script of `tools/` (options, what it reads and writes, exit codes), and explanations of why things work as they do. Each page was written from the code it cites and read again, statement by statement, by a reader who had not written it; the README leads to each family in one click.
- **Your assistant finds answers at a lower cost.** It carries a [documentation map](./docs/MAP.md) in its instructions and reads the page the map names first; its Claude Code form runs on the lightest model the format accepts (`haiku`).
- **Clearer installation.** In a terminal, the nine questions are displayed by gum, set up for you when it is missing, with a plain fallback; with the macOS / Linux line (`curl … | bash`) the questions read your keyboard; on Windows, a workspace folder too deep for the 260-character path limit is refused before anything is written, with its length and the maximum.
- **Your language, recorded once.** The installer records it in `USER.md`; a local, never-published `USER.local.yaml` can carry it instead; each project's Pilot prompt renders it.
- **Sturdier checks.** The private-pattern check recognises Google API keys (masked in its report); the conformity check finds a project in the registry by its path only; guardians and tools read `USER.md` written with a byte-order mark.
- **Your assistant follows your updates.** From this version on, the update tool regenerates your assistant's three forms with the version it brings, under the name you chose at installation (never the default one), inside the same update commit.
- **A session close cannot be skipped.** A guardian refuses a commit that brings in a project's newest handoff without the state digest that names it and a later `STATE:` line in the journal; the handoff template carries the Executor's closing command, and the Pilot's opening says `NOT-READY (session close missing)` when the digest is behind the newest handoff.
- **The tools refuse to write in the wrong place.** Every tool that writes into a folder you name (the index builder, the journal, the state sheet and its digest, the version setter, the identity, the link repairs, the Pilot prompt's regeneration) now refuses your workspace root and any folder that is in no repository and has no birth certificate, before writing anything, and says which folder it expected; creating or adopting a project refuses a target that is itself your workspace root. Typing `.` in the wrong window can no longer rewrite your workspace.
- **A verified push.** `tools/verified-push.sh <absolute repository path> <from>..<to>` pushes exactly that range to the declared remote, after checking the path, the current commit, the remote's head and the history; it never forces. A new rule asks every command that writes or pushes to name the absolute path of its repository.
- **From this version on, your update hands over to the version it brings.** When the tool that updates your Vault differs from the tool of the version you receive, it now runs the received one (once, on your Vault) instead of merging by its own, older rules. This does not reach back: an installation older than v0.1.15 runs its old tool, which does not hand over — hence the exact command the published line prints for this one update, below. The updates after that one hand over by themselves.
- **Your projects' own skills are kept in Git.** A skill you install for a project in `.claude/skills` or `.agents/skills` used to be hidden by the project's `.gitignore`, which excluded those whole folders to keep the links to your Vault's skills out of Git. Each of those folders now carries its own `.gitignore` naming the links one by one; the project's `.gitignore` excludes no whole folder any more. Adopting a project whose `.gitignore` still has those lines says so, and leaves the file as it is.
- **The pre-tool check of a project never ages.** A project keeps a small launcher that runs the Vault's own check, instead of a copy of the check that fell behind the Vault; its trigger covers PowerShell as well as Bash. The conformity check reports a project that still keeps an old copy, or a trigger without PowerShell.
- **A file you cannot read stops the staging, with its remedy.** On Windows, a file written by another account or an agent's sandbox can refuse your own account; the installers now check every file before staging it and name the two commands that give it back to you (`takeown`, then `icacls … /reset`). The troubleshooting guide also covers the `python` shortcut to the Microsoft Store and reading a repository from a second window.
- **Scratch folders are never taken for a workspace.** The repository-root guard no longer refuses a throwaway folder of your system's temporary folder when other work has left repositories there; the temporary folder itself, and your real workspace root, stay refused.
- **A project can declare where it is pushed.** `tools/verified-push.sh` reads a `# push_url:` line of a project's birth certificate, so a push of that project needs no `--url`.
- **Changed-files runs stay small.** `tests/run-suite.sh --changed` (and `run-suite.ps1 -Changed`) never falls back to the whole suite any more, even when the test list or the runners change: the whole suite is played on purpose, without `--changed`.
- **One temporary folder, declared, outside your workspace.** Every throwaway file of the tools and tests now lives under one folder, `<system temporary folder>/second-brain` unless `SB_TMP` or your workspace marker says otherwise (the marker carries it on the line `Dossier temporaire déclaré`). Nothing is written next to your projects any more, a scratch folder never resolves your real Vault, and a declared folder inside your workspace is refused. The installation's temporary clone moved there too (`second-brain/second-brain-install`).
- **A tidy workspace root, checked at every opening.** `tools/check-workspace-root.sh` compares the root of your workspace with a whitelist computed from your marker and your project registry: your Vault, your projects and group folders, the organs the marker declares, `_trash`, `_archive` and `_orders`. Anything else is named as a gap; the Executor's opening reports it as a warning, never a block. A folder you have not decided about yet can be named as a provisional exception.
- **One name per project, the same on both sides.** The Pilot Project of a project is named `SB - <display name>` — the name of your project registry. The Pilot prompt of each project carries it (`pilot_project_name`), the block at the end of a creation says « Create a Project named "SB - <Name>" », and the Pilot compares it with the name of its Project at every opening. `tools/project-bootstrap.sh identity <project> --check` prints a project's identity card and names every mismatch between the folder, the registry, the Pilot prompt and the README.
- **A welcome Pilot for what does not exist yet.** `tools/project-bootstrap.sh accueil-prompt` prints the instructions of the Project `SB - Accueil`: tied to your Vault, it thinks with you about new projects and writes their initiation order in `<workspace>/_orders/`, for an Executor to run.
- **A free session, which writes nothing.** A question with no project, no Mission and no order opens a free session: its first line is `READY (session libre)`, it reads and discusses, and writes nothing.
- **Projects in groups, if you want.** Folders are flat by default; `create --group <group>`, or the optional `Groupe` field of an initiation order, puts a project in `<workspace>/<group>/<folder>`.
- **Every way of starting has its line.** The session-start skill opens with a matrix of entry scenarios — an Executor or a Pilot first, in an adopted folder or not, with or without an order, at the workspace root, in the Vault, under Codex, a welcome or a free session, a first installation — and the guide [Start something new](./docs/how-to/start-something-new.md) follows it.
- **An old workspace marker no longer captures your tools.** A marker without a Vault identity (written before identities existed) is refused by the Vault resolution instead of resolving an old Vault.
- **A Pilot answers with its verdict first, and knows what to do in a folder that is not adopted.** The common Pilot prompt you paste in each Project now says that the first line of the answer is `READY` or `NOT-READY (<reason>)`, and that a project path without `<project>/state/PILOT-PROMPT.md` gets `NOT-READY (projet non adopté)` and a proposed initiation order. Paste the new block again in each Project (the block that ends a creation prints it). The two guides the installer writes at the root of your workspace (`CLAUDE.md`, `AGENTS.md`) now send any session opened there to the entry matrix first: a question with no project, no Mission and no order opens a free session, `READY (session libre)`, which writes nothing.

**How it is proven.** Named tests, each with its negative control (inventory in [`tests/index.md`](./tests/index.md)); the whole Windows suite was played on its own for this draft — 94 of 96 lines green, no blocking failure (Mission 230), then again with the additions of Mission 231, and once more with those of Mission 234 — 103 of 109 lines green; its three blocking reds were caused by the new declared temporary folder in two tests and in the documentation map, fixed and replayed green, and the two informational lines are the known ones. The questionnaire was also played **for real, in a real terminal**: gum drew its nine screens in order, an accented answer reached `USER.md` byte for byte, and the run was recorded. The publication itself was rehearsed end to end on local bare repositories: published, tagged on both, then received by a company Vault and by a plain v0.1.14 participant, `UPDATED` both times, with their profiles intact.

**What this version does not promise.** The update of an installation made **before** v0.1.15 is run with the new version's tool (the published installation line prints the exact command): the tool already in such a Vault predates the fix above and still refuses on `USER.md`. The gum display and the keyboard under `curl … | bash` are proven on Windows and by simulation, not yet on a real macOS or Linux terminal. The assistant's answers were not measured with a model: its map and model field are proven by the generated files only. A Pilot in Codex, Gemini CLI, Cursor, Windsurf, Cline or LM Studio is **declared**, not proven: their adapters are tested on a simulated profile and the agent bench has their cases written, not played. **ChatGPT (web and desktop) and Gemini on the web are not Pilot hosts**: they accept only a remote MCP server, and ChatGPT Plus opens no custom connector; the way the day you want it is on the page above.

**What remains to be done on your side.** Run the published installation line of this version; on an existing installation it prints the exact update command, which runs the v0.1.15 tool with `--vault`. That one run brings the version, keeps your profile, and regenerates your assistant's forms under the name you chose, inside the same commit (`VERDICT: UPDATED`). If the message says the MCP server may have changed, run `sb install --mcp` again and restart each tool it names. Paste the Pilots' blocks again once (`sb pilot-prompt <folder>`, `sb pilot-prompt --accueil`): they now speak of a host, not of the Claude application.

## v0.1.14

A version for the Pilot's opening and for a faster guardian.

**What this version brings.**

- **The Pilot proves its file channel answers before it reads.** Every Pilot opening now starts with a step zero: one cheap read, timed, that must come back within 60 seconds, the tool prefix recorded as data. The criterion is the read that comes back, never the name of the application. A channel that answers only on the client side gives `READY` with an `ANOMALY`: no unattended work in that window. The step is written the same way in the opening reading list and in the Pilot prompt that `tools/project-bootstrap.sh create` renders.
- **The asserted-paths guardian is eight times faster.** It used to launch 316 commands per pass on the laboratory Vault (13.3 s); it now reads the documents in three passes and lists the tracked files once: 8 launches, 1.6 s, with the same verdicts on the six corpora measured.

**How it is proven.** A test of the step zero (red before, green after), and the guardian replayed against its former version on six corpora, output and exit code compared byte for byte.

**What this version does not promise.** The guardian now reads every tracked document, so it is stricter than before in two cases: a tracked `.md` file missing from the disk, and a tracked `.md` file whose name carries a non-ASCII character. The limits of v0.1.13 remain valid.

**What remains to be done on your side.** `bash second-brain/tools/second-brain-update.sh v0.1.14` brings this version. If a commit is then refused by `chemins-affirmes`, read its message: it names the tracked document concerned.

## v0.1.13

A version for the people who run the tests.

**What this version brings.**

- **Play only the tests your change calls for.** `tests/run-suite.sh --changed [<ref>]` (and `run-suite.ps1 -Changed` on Windows) plays the two guardian lines, plus the lines of the test list whose path is a changed file or whose path or origin names a changed tool, test or hook. Untracked files count as changed; the selection is announced before anything is played, and a change that no test names is said as such. Without `--changed`, nothing changes.
- **One proof pass is the rule.** The work-regime rule and the Mission template say that the proofs of a gesture are played once; a second pass is the exception.

**How it is proven.** A new test, `tests/test-run-suite-changed.sh`, with the bash and PowerShell runners in parity; ten runs without `--changed` compared byte for byte with the former runner.

**What this version does not promise.** In this version, a change to the test list or to the runners still plays the whole suite. The limits of v0.1.12 remain valid.

**What remains to be done on your side.** `bash second-brain/tools/second-brain-update.sh v0.1.13` brings this version; nothing in it changes an installation's behaviour.

## v0.1.12

The version where your Vault's server carries the name of your workspace.

**What this version brings.**

- **One recognisable server per workspace.** The MCP server of your Vault is now named `second-brain-vault-<workspace>`, from the normalised name of your workspace folder, which the installer records in `VAULT-IDENTITY.md`. `tools/install-vault-mcp.sh` migrates the former keys of the same Vault (the fixed name, the name by identity, a former workspace name).
- **Two Vaults with the same workspace name are caught before anything is written.** The server installer refuses the second one, names both identities and proposes a suffixed name.
- **Two options for the server installer.** `--retire <key>` removes a generic server entry (never a Vault's own), and `--skip-desktop` leaves the desktop application's configuration alone.
- **Regenerate an adopted project's Pilot prompt.** `tools/project-bootstrap.sh prompt <folder>` rewrites `<project>/state/PILOT-PROMPT.md` of a project already adopted, keeping its canary.

**How it is proven.** Two new tests (the workspace name and its installer; the regeneration of the Pilot prompt), and the v0.1.11 server-name test extended with the workspace-name cases.

**What this version does not promise.** The limits of v0.1.11 remain valid.

**What remains to be done on your side.** `bash second-brain/tools/second-brain-update.sh v0.1.12` brings this version. Then run `tools/install-vault-mcp.sh` again with your workspace, so the Claude app knows your server under its new name, and restart the app.

## v0.1.11

The version where two Vaults on one machine are two servers.

**What this version brings.**

- **Your Vault's server announces its own name.** It used to announce `second-brain-vault` in every Vault, while the installer registered each Vault under its own name: with two Vaults on one machine, the desktop application could show only one. The server now takes its name from your Vault's identity (`VAULT-IDENTITY.md`); a Vault without a generated identity still announces `second-brain-vault`. The list of its tools does not change.
- **Adopting an existing project is smoother.** A birth certificate may carry an optional `# exempt: <path/> …` line, read by the link and index guardians only (never by the secrets check); the index builder prunes the right folders wherever your workspace lives; `adopt` replaces a hook configuration that has no birth certificate and holds nothing but the Vault's guardians, keeping a dated copy beside it; `write-marker.sh --marker-only` writes the marker alone; the conformity check accepts a link to the role charter as the project's pointer.
- **Read the phases of a journal.** `tools/phase-report.sh` reads the `PHASE` lines of a project journal.

**How it is proven.** A test with two servers started side by side that read two different names, plus the skeleton, line-ending and `--vault` cases; each adoption fix has its own test, with a red witness replaying the tool as it was before.

**What this version does not promise.** The limits of v0.1.10 remain valid.

**What remains to be done on your side.** `bash second-brain/tools/second-brain-update.sh v0.1.11` brings this version. The update tells you the MCP server may have changed: run `tools/install-vault-mcp.sh` again with your workspace, then restart the Claude app.

## v0.1.10

A version for the way work is handed to the Executor.

**What this version brings.**

- **Two work regimes, chosen by a command.** Beside the full Mission, a light execution Note keeps the proofs (measure before, measure after) without the ceremony around them. `tools/check-work-regime.sh` reads the Note before the gesture, or the real change afterwards, and refuses the light regime when a closed list of criteria is true: a push to the published repository or any network exit, a deletion or a history rewrite, a Decision, rule or template amended, a remote, branch or tag changed, a guardian, a hook or the publication tool touched.
- **Parallel read-only measurements, when a Mission asks for them.** The Mission template gains an optional `## Fan-out` section: batches of independent measurements, each with its targets, its read commands and its output file. Left out, a Mission works exactly as before.
- **Publishing checks private patterns before every push.** For the people who publish from a laboratory: `tools/publish-from-laboratory.sh` now runs the private-pattern check before both of its pushes, including when a publication commit already existed.

**How it is proven.** Named tests, each with its negative control: the work-regime check is also played against weakened copies of itself (one that accepts everything, one that refuses everything, one with a criterion removed) and must fail against each.

**What this version does not promise.** The limits of v0.1.9 remain valid.

**What remains to be done on your side.** `bash second-brain/tools/second-brain-update.sh v0.1.10` brings this version; nothing in it changes an installation's behaviour.

## v0.1.9

A maintenance version for the people who build Second Brain: nothing changes for an installation.

**What this version brings.**

- **Publishing from the laboratory is one command.** `tools/publish-from-laboratory.sh` publishes the laboratory Vault's `main` to the published repository as a fast-forward, keeping a closed list of laboratory-local paths (its identity, its project sheets) as they are in the published repository; it refuses anything that would not be a fast-forward, and says "nothing to publish" when there is nothing new. This very version was published by it.
- **A laboratory's own project sheets no longer trip the private-pattern check.** The exemption applies only to `projects/`, only in a repository that declares a `release` remote, and never on the branch that is published. Nothing changes for an installation: without a `release` remote, the check is exactly what it was.
- **A backup is proven by restoring it.** `tools/check-backup-bundle.sh` checks a Git bundle by fetching it into a throwaway repository and checking its objects: `git bundle verify` alone accepts a bundle whose pack is truncated.

**How it is proven.** Named tests, each with its negative control, chained in the public CI; the inventory is in [`tests/index.md`](./tests/index.md).

**What this version does not promise.** The limits of v0.1.8 remain valid.

**What remains to be done on your side.** Nothing if you run v0.1.8: `bash second-brain/tools/second-brain-update.sh v0.1.9` brings this version, and nothing in it concerns an installation's behaviour.

## v0.1.8

The version you will not have to reinstall: from now on, a new version is received by an update.

**What this version brings.**

- **Update without reinstalling.** `tools/second-brain-update.sh <version>` (and `second-brain-update.ps1` on Windows, skill `update`) merges a published version into your installation: your profile, your Vault's identity, your projects and your history are kept, the indexes are regenerated, one merge commit goes through the Vault's guardians. A conflict, an identity that would change or an uncommitted change is refused, with nothing touched. Run from an installation at v0.1.7 or earlier, the installation line of this version no longer installs over it: it prints the update command.
- **One MCP server per Vault.** The Pilot's server is named after the Vault's identity (`second-brain-vault-<8 characters>`). Two Second Brains on one machine keep two servers side by side; the former fixed name is migrated when it pointed to the same Vault, and never replaced when it points to another. The containment check and the instructions of each Project name the server of their own Vault.
- **The agents' instructions say which language to use.** `AGENTS.md` and `CLAUDE.md` now say: files in English, and speak to you in the language of your `USER.md` (they still said "Write prose in French").
- **A CI round takes about 15 minutes.** The Windows acceptance runs in parallel with the Windows shards again; it only waits for what it really needs.
- **A copy of a Vault is a new Vault.** An installation, like a throwaway test Vault, never inherits an identity its source may carry. The identity file an installation generates (`VAULT-IDENTITY.md`) is now written in English, like the rest of the corpus; an identity already generated is never rewritten.

**How it is proven.** Named tests, each with its negative control, chained in the public CI; the inventory is in [`tests/index.md`](./tests/index.md).

**What this version does not promise.** The limits of v0.1.7 remain valid. An installation from before v0.1.4 (its origin is the installer's temporary folder) cannot be updated: it is reinstalled.

**What remains to be done on your side.** If you installed v0.1.7 or earlier: run the installation line above; it prints the update command. Then run `tools/install-vault-mcp.sh` again so the Claude app knows the server under its new name, and restart the app.

## v0.1.7

Maintenance version: compared with v0.1.6, the only installed file that changes is `AGENTS.md` (one paragraph, below); the rest is the proof around it.

**Why it replaces v0.1.6.** v0.1.6 stays published as it is, but its tag run in the public CI went red on a test defect (a test that assumed a `main` branch, which a tag checkout does not have); v0.1.7 carries the corrected test and is published only on a commit whose CI is green on `main` and on the tag.

**What this version brings.**

- **The agents' instructions say how a push is delegated today.** `AGENTS.md` still asked for a verbatim, dated authorization line; it now says what the role charter says: a clear sentence from you, naming what to push, is enough. The test that guards this wording now reads `AGENTS.md`, `CLAUDE.md`, `.claude/` and `.codex/` too.
- **The whole test suite is proven on a tag checkout.** A test replays the suite on a detached HEAD with no branch — the state a tag gives the CI — so a test that silently assumes `main` is caught before a release.
- **A CI round takes less time.** The Windows suite, about 38 minutes played one test after the other, is split into three shards run in parallel, balanced on measured durations; a test proves that the three shards together play every Windows test exactly once.

**How it is proven.** Named tests, each with its negative control, chained in the public CI; the inventory is in [`tests/index.md`](./tests/index.md).

**What this version does not promise.** The limits of v0.1.6 remain valid.

**What remains to be done on your side.** Nothing urgent if you installed v0.1.6: only the push-delegation paragraph of `AGENTS.md` differs. To have it, or if you installed an earlier version, run the line above.

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
