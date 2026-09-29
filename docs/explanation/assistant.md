---
type: explanation
title: "The assistant"
description: "Who your Second Brain assistant is, what it refuses, the three forms it is generated in, how you reach each form, how it searches, and what happens when you rename it."
status: active
---

# THE ASSISTANT

This page explains the assistant you name at installation (by default « Brian »): what it does, where it lives and how you talk to it.

## Who it is and what it refuses

The assistant is Second Brain's own agent. You choose its name in the installation questionnaire; the default name is Brian ([CONTEXT.md](../../CONTEXT.md)). It guides the installation, then answers read-only once the installation is finished ([README.md](../../README.md)).

Its identity text describes it as knowing everything in the repository: rules, decisions, knowledge, skills, warehouse and installation. It answers by citing its source by relative path, never a claim without a file behind it. Its tone is warm and direct, with a touch of humour, and it signs its answers with its name ([ASSISTANT.md](../../assistant/ASSISTANT.md)).

It refuses three things ([ASSISTANT.md](../../assistant/ASSISTANT.md)):

- any writing or execution outside the installation itself; once installed, it has only reading tools;
- any answer about something that is not in the repository (it says, in French, that it is not in the Vault and it would rather not make things up);
- any claim without a source: when it does not know, it says so and points to where to look.

If you ask it to create a file, it refuses, explains that it is read-only, and tells you how to do it yourself or with the main agent.

## One identity source

The single identity source is `assistant/ASSISTANT.md`. Inside it, the name appears only as the `{{ASSISTANT_NAME}}` token. The generator, `tools/generate-assistant.ps1`, reads the body between the `corps-generateur` markers, replaces the token with the name you chose, and derives all three forms from that one body. Nobody copies the text by hand, so the three forms never drift apart ([ASSISTANT.md](../../assistant/ASSISTANT.md), [generate-assistant.ps1](../../tools/generate-assistant.ps1)).

The generator is called by the installer. On macOS and Linux the same work is done by `tools/sb_installer_helper.py`, as the generated web package README states. The file names use a slug of the name: lowercase, no accents, no spaces (for « Brian », brian).

To change what the assistant says, you edit `assistant/ASSISTANT.md`, never a generated form.

## The three generated forms

All three are written inside your `second-brain` clone ([generate-assistant.ps1](../../tools/generate-assistant.ps1)).

1. **Claude Code subagent**: `<workspace>/second-brain/.claude/agents/<slug>.md`. Its front matter restricts it to the tools `Read, Glob, Grep`. This is a mechanical restriction: the subagent simply has no tool that writes or runs anything. The same front matter sets `model: haiku`, the lightest model the Claude Code subagent format accepts: answering from a named page is a reading task ([Decision — the documentation map first](../../decisions/DECISION-2026-09-23-232720-assistant-reads-documentation-map-first-lightest-model.md)).
2. **Codex skill**: `<workspace>/second-brain/.agents/skills/<slug>/SKILL.md`, the location Codex scans. Codex offers no per-skill tool restriction, so this form is read-only by instruction (its own text refuses writing and execution), not by mechanism.
3. **Web package**: the folder `<workspace>/second-brain/web-package/<slug>/`, for a claude.ai or ChatGPT Project. It holds five files:
   - **INSTRUCTIONS.md**: the text for the Project's custom instructions field, never more than 8,000 characters;
   - **GLOSSARY.md**: a copy of the product glossary, `CONTEXT.md`;
   - **PROJECT-BOUNDARY.md**: a copy of the rule deciding whether something belongs in Second Brain or in one of your projects;
   - **METHOD.md**: how to open a session and what a Mission is and where to write one, condensed from the session-start skill, the Mission template, the project operating model and the Mission versioning rule;
   - **README.md**: a short usage note in English, for your own reference.

The generator stops with an error if the finished package holds more than 25 files, and a test checks that the package README announces exactly the files in the folder, in both directions ([test-web-package-readme-matches-contents.ps1](../../tests/test-web-package-readme-matches-contents.ps1)).

The front matter `description` of the subagent and of the Codex skill is written in the language you chose at installation (French, English or Spanish). It tells the agent to invoke the assistant for any question about its name or Second Brain: the subagent's description adds the Vault, the method, a rule or a decision, and the Codex skill's adds how the workspace works ([generate-assistant.ps1](../../tools/generate-assistant.ps1)).

## How you reach each form

**In Claude Code and Codex**, the subagent and the skill are linked into `<project>/.claude/agents/` and `<project>/.agents/skills/` of each project, set up when the project is created. Nothing goes into your profile ([README.md](../../README.md), [INSTALL.md](../../INSTALL.md)). The first time you open a project, Claude Code may ask you to approve these links, because their target is outside the project folder. It asks once per project; answering yes is safe, because the links only give read access to your clone ([README.md](../../README.md)).

**On the web**, nothing is automatic: you upload the package yourself. The package README describes the gesture ([generate-assistant.ps1](../../tools/generate-assistant.ps1)):

1. Create a Project on claude.ai or ChatGPT (paid plan required: Claude Pro or above, or ChatGPT Plus or above).
2. Paste the contents of `<workspace>/second-brain/web-package/<slug>/INSTRUCTIONS.md` into the Project's custom instructions field. Do not upload that file itself.
3. Upload **GLOSSARY.md**, **PROJECT-BOUNDARY.md** and **METHOD.md** to the Project's knowledge (or files) section.

The README itself never needs uploading. The package is a Project package, not a Skill package: there is no zip to upload.

## Asking it something in Claude Code

Name the assistant explicitly in your question. The README gives this example: `Demande à Brian : quelles sont les décisions actives sur la structure des projets ?` (in English: "Ask Brian: which decisions are active on the structure of projects?"). Claude Code then delegates to the dedicated read-only subagent, which cites its sources by path ([README.md](../../README.md)).

If you do not name it, Claude Code's main agent may answer in its place. That answer is generally correct, but it does not carry the read-only guarantee of your assistant.

## How it searches

Every form carries the [documentation map](../MAP.md): the generator appends it to the assistant's instructions, so reading it costs no tool call. For an ordinary question, the assistant makes at most 8 tool calls before answering: the page the map names, its source, and one widening ([ASSISTANT.md](../../assistant/ASSISTANT.md)). It searches from the most precise to the widest, never skipping a step:

1. the page the map names for your kind of question, then, only if that page does not answer, the file in the map's last column;
2. the file named exactly by your question;
3. otherwise, the index of the folder closest to the subject (for example `decisions/index.md`, `rules/index.md`, `skills/index.md`, `knowledge/index.md`), never a file opened by guesswork;
4. the file that index points to;
5. a wide search across the whole workspace, only if the previous steps each failed.

In a web Project, where only the package's knowledge files are uploaded, it names the page and its path to you instead of opening it.

It stops as soon as the file it read answers your question. When it has read enough, it answers with what it read and names clearly what it did not read or could not verify.

## After an update

The forms are generated from this repository's own documents, so a new version can change them. The update tool regenerates them with the version's generator, under the name the installer recorded, and commits them with the update ([update](../how-to/update.md), [second-brain-update.sh](../../tools/second-brain-update.sh)).

## Renaming the assistant

You can change the name by rerunning the installer, which switches to update mode on an installed machine ([INSTALL.md](../../INSTALL.md)). The old forms are never overwritten silently and never deleted: before generating the new forms, the installer moves every path generated for the old slug (the subagent file, the skill folder and the web package folder) under `<workspace>/second-brain/_trash/assistant-rename-<old-slug>-<timestamp>/`, keeping their relative structure. They stay readable there ([generate-assistant.ps1](../../tools/generate-assistant.ps1)).

## Liens

- `source` — [Documentation map](../MAP.md)
- `source` — [Decision — the documentation map first](../../decisions/DECISION-2026-09-23-232720-assistant-reads-documentation-map-first-lightest-model.md)
- `source` — [Assistant identity](../../assistant/ASSISTANT.md)
- `source` — [Assistant generator](../../tools/generate-assistant.ps1)
- `source` — [README](../../README.md)
- `source` — [Installation guide](../../INSTALL.md)
- `source` — [Product glossary](../../CONTEXT.md)
- `source` — [Web package README/contents parity test](../../tests/test-web-package-readme-matches-contents.ps1)
- `source` — [Installer helper for macOS and Linux](../../tools/sb_installer_helper.py)
- `source` — [Update tool](../../tools/second-brain-update.sh)
- `source` — [Update](../how-to/update.md)
- `see also` — [Architecture](architecture.md)
- `see also` — [Open a session](../how-to/open-a-session.md)
- `see also` — [Create a project](../how-to/create-a-project.md)
- `see also` — [Skills](../reference/skills.md)
- `see also` — [Troubleshoot](../how-to/troubleshoot.md)
