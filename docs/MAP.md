---
type: guide
title: "Documentation map"
description: "One table from a kind of question to the documentation page that answers it; the assistant reads it before anything else, and the generators embed it in every form of the assistant."
status: active
---

# DOCUMENTATION MAP

This map sends a question to the one page that answers it, so that the answer costs one reading instead of a search; the assistant carries it in its instructions ([Decision — the assistant reads the documentation map first](../decisions/DECISION-2026-09-23-232720-assistant-reads-documentation-map-first-lightest-model.md)).

<!-- doc-map:start -->
## Documentation map

Read the page named for the kind of question first; open the file in the last column only if that page does not answer. In a web Project, where only the package's knowledge files are uploaded, name the page and its path to the person instead of opening it.

| If the question is about… | Read first | Then, if needed |
|---|---|---|
| a customer or support question | `docs/reference/support-faq.md` | the page its answer names |
| a command, the sb verbs, what to type for an operation | `docs/reference/commands.md` | `docs/COMMANDS-CARD.md` |
| installing, checking or repairing sb, the Claude Code plugin /sb:, $sb in Codex, sb doctor, a stale plugin copy | `docs/how-to/use-the-sb-command-and-plugin.md` | `docs/reference/commands.md` |
| what Second Brain is, its pieces, the workspace | `docs/explanation/architecture.md` | `CONTEXT.md` |
| installing, the installation line, the questionnaire | `docs/tutorials/install.md` | `INSTALL.md`, `docs/how-to/troubleshoot.md` |
| a first project, a first Mission | `docs/tutorials/first-project.md` | `docs/tutorials/first-mission.md` |
| opening a session, the Pilot, the Executor | `docs/how-to/open-a-session.md` | `skills/session-start/SKILL.md` |
| a READY or NOT-READY verdict and its reason, an opening scenario E1 to E11 | `docs/how-to/opening-scenarios.md` | `skills/session-start/SKILL.md` |
| starting something new, the session types, the welcome Pilot SB - Accueil, project names | `docs/how-to/start-something-new.md` | `rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md` |
| the person's profile or a project's profile, the starting interview, sb profile | `docs/how-to/starting-interview.md` | `skills/starting-interview/SKILL.md` |
| closing a session, a handoff | `docs/how-to/close-a-session.md` | `skills/session-close/SKILL.md` |
| creating a project | `docs/how-to/create-a-project.md` | `docs/reference/tools-projects.md` |
| adopting an existing folder, the conformity check | `docs/how-to/adopt-a-project.md` | `docs/how-to/bring-a-project-into-conformity.md` |
| a Mission and where to write it, a Note | `docs/how-to/write-a-mission.md` | `docs/explanation/mission-lifecycle.md` |
| running a Mission, a report, a RELAY block | `docs/how-to/run-a-mission-as-executor.md` | `docs/how-to/read-a-relay.md` |
| the roles, who may do what | `docs/explanation/two-roles.md` | `docs/reference/roles-and-permissions.md` |
| a push, its delegation, absolute paths | `docs/how-to/delegate-and-push.md` | `docs/explanation/why-absolute-paths.md` |
| a script, its options, what it writes | `docs/reference/index.md` | the script's own header |
| a file format: Mission, report, journal, state | `docs/reference/formats.md` | `templates/index.md` |
| the skills shipped, adding a skill | `docs/reference/skills.md` | `docs/how-to/add-a-skill.md` |
| a guardian that refused a commit, the tests | `docs/how-to/react-to-a-guardian-refusal.md` | `docs/reference/guardians-and-hooks.md` |
| updating, uninstalling | `docs/how-to/update.md` | `docs/how-to/uninstall.md` |
| the assistant itself | `docs/explanation/assistant.md` | `assistant/ASSISTANT.md` |
| an error message or a refusal | `docs/how-to/troubleshoot.md` | the page it links to |
| my Pilot in another tool | `docs/how-to/pilot-hosts-and-role-mixing.md` | `rules/index.md` |
| publishing a version from a laboratory | `docs/how-to/publish.md` | `tools/publish-from-laboratory.sh` |
| the meaning of a term | `CONTEXT.md` | `docs/reference/glossary.md` |
| a rule or a decision | `docs/explanation/decisions.md` | `rules/index.md`, `decisions/index.md` |
| a request to write, create or run something | refuse: the assistant is read-only | `docs/explanation/assistant.md` |
<!-- doc-map:end -->

## Liens

- `see also` — [Tutorials](./tutorials/index.md)
- `see also` — [How-to guides](./how-to/index.md)
- `see also` — [Reference](./reference/index.md)
- `see also` — [Explanation](./explanation/index.md)
- `see also` — [Support FAQ](./reference/support-faq.md)
- `see also` — [Opening scenarios](./how-to/opening-scenarios.md)
- `see also` — [Use the sb command and its plugin](./how-to/use-the-sb-command-and-plugin.md)
- `see also` — [Installation guide](../INSTALL.md)
- `see also` — [Glossary](../CONTEXT.md)
- `applies` — [Decision — the assistant reads the documentation map first](../decisions/DECISION-2026-09-23-232720-assistant-reads-documentation-map-first-lightest-model.md)
- `source` — [Assistant identity](../assistant/ASSISTANT.md)
- `source` — [PowerShell assistant generator](../tools/generate-assistant.ps1)
- `source` — [Python assistant generator](../tools/sb_installer_helper.py)
