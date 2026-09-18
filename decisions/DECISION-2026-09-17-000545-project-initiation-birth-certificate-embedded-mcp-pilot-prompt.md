---
type: decision
title: "Project initiation and adoption — birth certificate, resolution of the Vault by verified identity, embedded MCP server, common Pilot prompt: amendments of 124848 §1, 115306 D2/D4, 210731 point 2, 124937 and of the role charter"
description: "A project resolves its Vault through a birth certificate with a verified identity, never by proximity; the bootstrap gains an additive adopt mode and a vcs field; an initiation order makes it possible to adopt without a Mission; an embedded MCP server, pinned to the Vault's commit, gives the Pilot bounded access; a common Pilot prompt is personalized per project on disk."
created_at: "2026-09-17T00:05:45-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md"
  - "./DECISION-2026-08-19-115306-project-registry-v1.md"
  - "./DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md"
  - "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
---

# DECISION — PROJECT INITIATION AND ADOPTION: BIRTH CERTIFICATE, EMBEDDED MCP SERVER, COMMON PILOT PROMPT

## Date

2026-09-17 (arbitration given on 2026-09-16).

## Status

`ARBITRATED`

## Measured problem

- `tools/project-bootstrap.sh` knew only one mode: to be born; it refused any existing target. The adopt mode of Decision 210731 point 3 existed only as doctrine in the `project-bootstrap` skill. [MESURÉ]
- The Vault was resolved only by the `VAULT-ROOT.md` marker found by walking up, which carries a name and a relative path, no identity; two Vaults in the same workspace cannot be told apart; a pointer file of the workshop still pointed to a neighbouring `vault` folder, hard-coded, the proximity set aside by 124848 §1 and 214607. [MESURÉ]
- The Pilot had disk access only through an MCP server installed by hand, outside any repository, with no proven version or perimeter. [MESURÉ]
- An agent that finds itself in a non-adopted folder always stops (210731 point 2), even when the Owner has just ordered the adoption: the rule blocks the gesture it meant to protect. [MESURÉ]
- The Pilot opening prompt (template `session-opening-prompt-template.md`) is common but nothing personalized it per project on disk; the Pilot opened from memory. [MESURÉ]

## Decision

### Pillars

1. **Agnostic**: any model, any harness (Claude Code, Codex, Claude Desktop, ChatGPT), same mechanism.
2. **The project names its Vault and its build**: nothing is deduced from the neighbourhood.
3. **Common Pilot prompt**, single source in the Vault, **personalized per project on disk**.
4. **Single source, explicit pointers**: no copy of doctrine, no cascade of instruction files, no resolution by proximity.

### A1 — Birth certificate (amends 124848 §1)

Every project carries at its root a **birth certificate**: the `.pre-commit-config.yaml` pin extended with four data items, in the same file — `vault_id` (identifier of the installed Vault), `vault_origin` (origin of the clone: URL or path), `vault_ref` (commit of the Vault at instantiation, replaces the sheet's `vault_head` fingerprint), `vcs` (`none` | `git`). The exact form is the one that produces neither error nor warning at `pre-commit validate-config`: measured, a block of comments with a fixed grammar at the head of the file.

**Resolution of the Vault, in this order.** (a) The certificate, found by walking up from the current folder like `.git`; it names the Vault; the Vault found must carry the same identity (`vault_id`), otherwise **refusal naming both identities**. (b) Without a certificate: the `VAULT-ROOT.md` marker found by walking up, which now carries an identity, resolves **only if there is a single candidate**; two candidate Vaults in the workspace → refusal, question to the Owner. The written declaration remains a reading convenience (124848 §1 unchanged on this point); proximity disappears from every pointer file: a path written in a project's `AGENTS.md`/`CLAUDE.md` is copied from the certificate at generation, never assumed, and a check verifies their consistency.

### A2 — Registry: `vcs` and writing by `adopt` (amends 115306 D2 and D4)

D2: the project sheet gains the `vcs` field (`none` | `git`); the index gains the column. D4, path 1: `adopt` writes the registry line, the sheet and the certificate, in the same way as birth; always by an Executor, never by hand.

### A3 — Stop only without an order (amends 210731 point 2)

An agent that finds itself in a non-adopted folder: **with an initiation order** (A5), it adopts and continues; **without an order**, it stops and **proposes the adoption** by rendering the order to be filled in. Point 2 no longer prescribes an unconditional stop.

### A4 — Bootstrap in two additive modes

`create` and `adopt`, both additive. `adopt` touches no existing file; the reorganization into seven functions is **always proposed, never applied** (210731 point 3 unchanged). **Question before writing**: folder name and location proposed, the Owner confirms or changes. **Git question** if the order does not carry it: `vcs: none` → checks by command (`tools/check-*.sh <projet>`), no hook; `adopt --git` later adds hook and active pin. **Dated baseline and ratchet**: at adoption, the list of existing files is engraved, dated; the guardians judge only what is new and what is touched; a baseline file that is touched must become compliant. Earlier broken links are repaired by a **script that proposes**; application takes place only under a Mission. The target receives a generated Pilot prompt with a **canary identifier**, and a **block to consume** is rendered in chat: Project (claude.ai/ChatGPT) to create, common instructions to paste, first message = path of the project.

### A5 — Initiation order, `initiation` mini-prompt type (amends 124937 and charter §3)

A Pilot **without a Mission** may issue an **initiation order**: `Type` (`create` | `adopt`), `Mode` (`answered`: all the answers carried by the order, no question; `ask`: the bootstrap asks name, location, Git), `Nom` [name], `Emplacement` [location], `Vault + construction` [Vault + build] (`vault_id`, `vault_origin`, `vault_ref`), `Git` (`none` | `git`), `Objet` [purpose], `Autorisation Owner datée` [dated Owner authorization] (verbatim). It travels by a mini-prompt of type `initiation`, **the only type without a « Source à appliquer » (source to apply) rubric**: the order is the source. Charter §3: a first Executor prompt may be an initiation; the Executor consumes it as it consumes a Mission, perimeter bounded to the target and to the Vault's registry.

### A6 — Embedded MCP server and workstation

`tools/vault-mcp.py`: MCP server in Python, stdio transport, allowed folders passed as arguments, refusal of any path outside the perimeter and of any symbolic link that escapes it, **pinned by the commit** of the installed Vault (the server returns its commit; the Pilot compares it). `first-install` detects the tools present (`claude`, `codex`, Claude Desktop application) and injects the configuration (`claude mcp add`, `codex mcp add`, Claude Desktop JSON **at the measured path**), allowed folder = root of the workspace, checks Python, and states restarting the application as the remaining gesture. A **containment check** verifies that project and Vault are included in the allowed folders. **Pilot canary at opening**: `list_allowed_directories` must contain the path of the project, then reading the project's Pilot prompt returns the canary identifier. The common prompt says that the Pilot role requires the desktop application (MCP does not exist in the browser).

### A7 — Marker

The generated `VAULT-ROOT.md` carries the identity of the Vault (`vault_id`, `vault_origin`) in addition to the name and the relative path.

## Reason

Owner arbitration of 2026-09-16 on the specification proposed by the Pilot: « tout ce que tu dis me va, conforme » ["everything you say suits me, compliant"]. The substance: proximity and the marker alone break as soon as a workspace carries two Vaults or a project is cloned alone (214607 D4); a verified identity in a birth certificate is the only thing a project carries everywhere. The Pilot's disk access must come from the Vault, versioned and bounded, not from a manual installation invisible to the Missions.

## Impact

- Delivered in this repository in v0.1.3: bootstrap `create|adopt|order`, birth certificate, resolution by identity, baseline and ratchet, proposed link repair, Pilot prompt with canary, MCP server, injection and containment, each proven in CI with a negative control.
- Amended: 124848 §1; 115306 D2, D4; 210731 point 2; rule 124937 (`initiation` type); charter §3 (first consumption). The copies of these documents in this repository carry the `amended by` mention (Decision 205904: the amendment lives in the amended repository).
- 214607 D4 becomes a CI test (project cloned alone, its rules apply).

## Important alternatives

- **OpenViking**: set aside — context base, AGPL, another need.
- **Copy of the registry at the root of the project**: set aside — copy of doctrine (214607 D1).
- **Sandbox/Vagrant as a base**: set aside — not a new machine, not a participant.
- **Automatic reorganization at adoption**: set aside (210731 point 3 maintained).
- **Certificate file separate from the pin**: set aside — two files to keep consistent; the pin is already the only file that every project carries.

## Human gate

- Validation: granted
- Reference: Owner, 2026-09-16, « tout ce que tu dis me va, conforme » ["everything you say suits me, compliant"]; confirmed on 2026-09-17.

## Liens

- `amends` — [Seven session arbitrations of 2026-08-23](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
- `amends` — [Project Registry V1](./DECISION-2026-08-19-115306-project-registry-v1.md)
- `amends` — [Decision — Awareness of the Vault by a project, in three tiers](./DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md)
- `amends` — [Relay between roles through mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amends` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `applies` — [Distribution of transverse mechanisms](./DECISION-2026-08-24-214607-transverse-mechanism-distribution.md)
- `applies` — [Decision — The amendment lives in the repository of the amended document](./DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md)
- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amended by` — [Decision — Relay and delegation, one rule in one place](./DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
