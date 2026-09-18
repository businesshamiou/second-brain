---
type: decision
title: "One MCP window, one workspace; skills fully exposed"
description: "Decision arbitrated on 2026-09-03 (Owner order, Pilot session): a single filesystem MCP server configured once at the level of the Desktop application, root = the whole workspace, sole window of every chat session onto the files; installation includes this MCP and the skills exposed to chat; by default the whole list of the project's skills is exposed to the chat session, under a cost HYPOTHÈSE to be measured before any reduction; the list of skills to install is derived from the Vault's skills index, never written by hand."
created_at: "2026-09-03T23:06:04-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: mcp-filesystem, workspace-root, skills-exposure, installation
---

# DECISION — ONE MCP WINDOW, ONE WORKSPACE; SKILLS FULLY EXPOSED

## Date

2026-09-03

## Status

`ARBITRATED`

Owner arbitration given in plain words in the Pilot session of 2026-09-03 (evening), before the drafting of Mission 132-A. No source proposal: the Decision comes directly from the Owner.

## Decision

1. **A single filesystem MCP server per workspace.** It is configured once, at the level of the Desktop application, and its root is the whole workspace. It is the sole window through which every chat session, of every project, touches files. No filesystem MCP server per project; a new project is a folder of the workspace, reachable without reconfiguration. The current state is not asserted by this Decision, it is to be measured: name of the server (`workshops` expected), declared root equal to the workspace (by the tool that lists the allowed directories), and configuration file actually read by Desktop (same method as Mission 128-bis for the Mnemosyne server).

2. **Installation includes the MCP and the skills.** The installation runbook (INSTALL.md), the first-install skill and the project-bootstrap skill say explicitly, each in its place: install and configure this MCP server in the file that Desktop reads; install the skills exposed to chat sessions. An installation that leaves a chat session without a file window or without skills is incomplete.

3. **Skills: whole list exposed by default.** The chat session receives the WHOLE list of the project's skills, so as to know what exists. HYPOTHÈSE to be measured before any reduction: an exposed skill costs, in the fixed conversation prefix, only its name and its description, the body being loaded only on call; the measurement is "bytes per skill × number of skills". If the measured impact is negative, the fallback is named in advance: a generated skills digest, capped, fail-closed (name, description, path of each skill), and only the main list installed.

4. **The list of skills to install is derived, never written by hand.** It is derived from the Vault's skills index, deterministically, from the `description` field of each skill. Registry v2 carries this derivation as a structural contract.

## Reason

- Two filesystem MCP servers for two projects means two configurations to maintain, two roots to measure and a reconfiguration at each new project — the opposite of a system distributed to two hundred non-developers.
- A chat session that does not know which skills exist cannot invoke them: whole exposure is the condition of use. Reduction is an optimization, it comes after measurement, not before (Decision 140714: the cap waits for the measurement).
- A list of skills written by hand drifts; a list derived from a generated index cannot diverge from the source.

## Impact

- Mission 132-A "session-start: installation and compliance" takes this Decision among its applicable Decisions and adds to its measurement part: point 1 (name, declared root, file read) and point 3 (cost per skill × number).
- INSTALL.md and the first-install and project-bootstrap skills will be amended by Mission, after measurement; this Decision edits no existing file.
- Registry v2 receives one more contract: the derivation of the list of skills from the index.
- Point 3 is a HYPOTHÈSE: as long as it is not measured, the whole list is the rule and the fallback stays inactive.

## Important alternatives

- One filesystem MCP server per project, root = the project: rejected (reconfiguration at each project, multiple roots to measure, Pilot write perimeter scattered).
- Expose to chat only a reduced list of skills chosen by hand: rejected by default, kept as the fallback of point 3 in the form of a generated digest, only if the measurement justifies it.
- Leave the installation of skills out of the runbook, up to each participant: rejected (incomplete installation by construction).

## Human gate

- Validation: granted
- Reference: Owner order in plain words, Pilot session of 2026-09-03 (evening), « Ordre Owner — Décision à graver avant la 132-A » ["Owner order — Decision to engrave before 132-A"]

## Linked artefacts

- Source proposal: none
- Role charter, §2 "Writing — bounded" and §5 stage 2 (Pilot perimeter enforced by the MCP server's configuration): `vault/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md`
- Report 131, contract of the guardians encountered: (workshop history, not distributed)

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Decision — Pilot context budget](./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md)
- `see also` — [Session opening reading list, by role](../skills/session-start/reading-list.md)
- `see also` — Report 131 — alignment of the Pilot opening protocol (workshop history, not distributed) (hors Vault)
