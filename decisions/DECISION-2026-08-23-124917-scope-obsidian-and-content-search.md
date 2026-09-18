---
type: decision
title: "Scope decisions — Obsidian out of the first workshop, content search built in-house"
created_at: "2026-08-23T12:49:17-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
---

# DECISION — Scope decisions of 2026-08-23

## Date

2026-08-23

## Status

`ARBITRATED`

Arbitration: Owner/Pilot session of 2026-08-23.

## Decision

Adoption of the two scope decisions that arose during the session on 2026-08-23, recorded in the proposal of the seven arbitrations and the revised batch order (workshop history, not distributed), §4.

1. **Obsidian out of the first workshop.** Obsidian is set aside from the workshop and the distributed package: the target audience is non-developers, and adding a piece of software to install contradicts the system's promise of lightness. Associated finding: the search skills examined (kepano/obsidian-skills, gmickel/obsidian-skill, the Obsidian skill of hermes-agent, an MCP search server based on ripgrep) do not depend on Obsidian in their mechanism — they search plain Markdown files; the strategy is reusable without the tool. Set aside: integrating Obsidian into the first workshop. Obsidian remains a possible subject for a second workshop built on this one.

2. **Content search built in-house.** The Vault gets its own search: a script that searches the content and returns the lines found, not the files (path, line number, line), and a thin skill that translates the question into the script's arguments and presents the result without reading anything else. Naming convention: an English name drawn from what the skill produces. The third-party skills examined serve as design references and are not imported into the Vault, in accordance with the existing rule. Set aside: depending on a third-party tool or imported skill for content search.

## Reason

Obsidian: the non-developer audience and the promise of lightness take precedence over Obsidian's search capabilities, all the more since these capabilities are reachable without the tool (the third-party skills examined search plain Markdown, with no mechanical dependency on Obsidian).

Content search: finding a single word in the corpus cost, during the session, the reading of an entire capture, for lack of content search on the chat side. On the Executor side the need is already covered natively; building a thin script and a skill in the Vault closes this gap without an external dependency.

## Impact

The distribution package (batch E) does not install Obsidian. Batch A (Mission 027, objective D) builds `tools/find-in-vault.sh` and the associated search skill. No third-party skill is imported into `vault/`.

## Important alternatives

- Integrate Obsidian into the first workshop for its native search: rejected, installation cost contrary to the promise of lightness for a non-developer audience.
- Import a third-party Obsidian search skill as is: rejected, contrary to the existing rule on third-party skills; serves as a design reference only.

## Human gate

- Validation: granted
- Reference: arbitration by the Owner in session on 2026-08-23, formalized by Mission 028.

## Linked artefacts

- Source Proposal: (workshop history, not distributed)

## Liens

- `source` — Proposal seven arbitrations and revised batch order (workshop history, not distributed) (hors Vault)
- `see also` — [Decision — Seven session arbitrations of 2026-08-23](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
- `see also` — Mission 027 — Batch A (workshop history, not distributed) (hors Vault)
