# Instructions for agents

Before any action: determine your role. Read [the role charter](./rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md).

- The Vault's files are the source of truth. Read the linked sources before any modification.
- The model's memory is never a source of state or of hypothesis: what has not been read in a file during the session is not known. Not asking oneself whether a file exists is a form of assertion.
- Without an active filesystem MCP server or shell access: ask the Owner for the files and produce nothing from memory.
- Write prose in French. Use idiomatic English for machine identifiers, slugs, keys and folder names.
- Record every structuring decision explicitly. Never silently turn a proposal into a decision.
- Apply the [context lifecycle V2](./rules/RULES-2026-08-17-111018-context-lifecycle-v2.md) selectively: capture only what will be durably useful, and create a proposal only when an important option must wait for an arbitration.
- Apply the [rule on versioning Missions and generated outputs](./rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) when a project uses Missions or a `generated/` landing zone.
- Maintain the `<projet>/current-state.md` file when a project uses it; update it instead of stacking successive states.
- Produce a handoff only when a reliable resume is really necessary.
- Keep every structuring decision at status `PROPOSED` until it is arbitrated by a human gate.
- Never write a secret, key, token, password or credential in the Vault or in Git.
- Git hooks check for secrets and bypass patterns; they are activated by `core.hooksPath` pointing to `.githooks/`. This configuration is local and not versioned: redo it after every clone.
- Inspect each file before staging, stage file by file by explicit path (`git add -- <chemin>`), then inspect the staged diff of the same path (`git diff --cached -- <chemin>`). Bulk staging is banned in all its forms: `git add .` and `git add -A`, which stage a whole folder or repository; `git add -u`, which stages all tracked modifications; `git commit -a`, which stages and commits without inspection. Reason: the guardians check only the staged files — staging without reading silently widens the surface they validate and passes off as verified what nobody has read.
- Measure the technical state and the evidence again at the moment it matters instead of copying perishable values.
- Gestures reserved to the Owner: `push`, and permanent deletion, never executed by an agent even when authorized (agent substitute: move to `_trash/` at the root of the workspace, [Decision 110852](./decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)). Require a human gate for any structuring rename, sensitive sharing or other sensitive action. The push may be delegated to an Executor window by a clear expression of the Owner that names the gesture and its target — the `main` branch of the repositories concerned, and, separately, a named tag; no formula is required ([Decision 201623](./decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md), part A, which amends [Decision 154553](./decisions/DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)). The Executor measures that the expression is there and what it covers; without it, the push is not done.
- Maintain the boundary between the Vault and external projects: the Vault holds what is cross-project; each project keeps its local context.
- Never automatically import into the Vault the business context, decisions or artefacts specific to a project.
- Any cross-project improvement coming from a project must be validated before it is integrated into the Vault.
- Do not bring into the Vault the prompts, presentations, storyboards, materials or tools whose only role is to build the workshop.
- Every Executor execution report is a file in the `reports/` folder of the current project (Decision of 2026-08-21); in chat, two lines: the report's path and the « gates » line.
- The old Vault installation runbook is withdrawn from the distribution; kept, not deleted, in [`_trash/`](./_trash/runbook-vault-setup.md), for historical purposes only — no longer any obligation to update it.
- Every document carries a `## Liens` section compliant with the [linking standard](./rules/RULES-2026-08-21-115658-document-linking-standard.md); the `tools/check-links.sh` check runs at pre-commit.
- Any delegation to the Executor follows the [rule on relay between roles through mini-prompts](./rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md): mini-prompt on the way out, `RELAY` block at the end of the report on the way back.
- For any work in `skills-warehouse/`: first read [`skills-warehouse/AGENTS.md`](./skills-warehouse/AGENTS.md) — this subfolder follows its own conventions, distinct from those above (T02, Mission 168). Codex loads it automatically when launched in this subfolder or below; this line routes Codex launched at the root, and any other agent, to the same source.

## Liens

- `applies` — [Context lifecycle V2](./rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `applies` — [Document linking standard](./rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `applies` — [Relay between roles through mini-prompts with fixed rubrics](./rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `applies` — [Decision — Relay and delegation, one rule in one place](./decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
- `applies` — [Decision — Permanent deletion is an Owner gesture](./decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
