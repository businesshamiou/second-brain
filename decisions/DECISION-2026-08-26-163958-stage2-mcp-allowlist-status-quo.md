---
type: decision
title: "Arbitration d — stage 2 (MCP write allowlist) in documented status quo, three wake-up conditions"
description: "Engraves the Owner's arbitration « d »: the MCP write allowlist on the Pilot side has no satisfactory native route (Mission 063, confirmed by the report of the older Vault); stage 3 remains the protection in force; three wake-up conditions named, no effective scope."
created_at: "2026-08-26T16:39:58-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
---

# DECISION — STAGE 2 (MCP ALLOWLIST) IN DOCUMENTED STATUS QUO

## Date

2026-08-26

## Status

`ARBITRATED`

## Decision

Two measurements converge: Mission `063` established that the installed MCP filesystem server (`@modelcontextprotocol/server-filesystem@2026.7.10`, native launch) carries no per-folder read-only mechanism, neither through CLI arguments nor through MCP Roots. The report of the older Vault (knowledge-note `KNOWLEDGE-NOTE-2026-08-26-163649`) independently confirms that its own write-restriction mechanism rests entirely on Claude Code's `PreToolUse` hook — with no equivalent under Claude Desktop + MCP, and whose porting would be a substantial rewrite, not a minor adaptation (knowledge-note §5.3). The Owner decides « d »: stage 2 of the role charter (Pilot write allowlist through the MCP server configuration) stays **in documented status quo**, not implemented. Stage 3 (pre-commit wall) remains the effective mechanical protection in force, with evidence: three real refusals by the guardrail at Mission `057` (two refusals of link reciprocity, one tool crash on a cross-repository target — no workaround attempted, all three documented in report 057).

The lesson of the 5-day outage of the older Vault (guardrail silently inactive from 21 to 26 July, detected only afterwards by reading the journal — knowledge-note §4.2) justifies, in one sentence, the guardrail canary already planned in the `session-start` skill (Decision `232341` §5.1): a mechanism that can fail without signalling it is a protection only as long as someone checks that it is still running.

## Reason

The status quo is not a silent renunciation: it is documented, dated, and bounded by explicit wake-up conditions (below), in line with the YAGNI refusal of the complete policy engine (Decision `232341` §5.4) — do not build a mechanism whose real need is not yet measured.

## Wake-up conditions

Three, and only three:

1. **The upstream server gains native per-folder read-only support** (new version of the package, or a change of launch method measured and validated) — revisit the allowlist at level 1.
2. **A real Pilot write accident occurs** (not a theoretical risk: a gesture actually observed outside the expected perimeter) → wake-up route: MCP wrapper on the Pilot side, on the model of the older system's per-role airlock (knowledge-note §5.3, route 2 — rewrite of the interception, not a copy).
3. **A real Executor write accident occurs** → wake-up route: porting of pre_tool_use.py, on the same Claude Code runtime as the one already in use here — the "Git hooks + policy" layer that the older system itself describes as "close to copy-paste" is already covered, in another form, by our stage 3; it is the Write/Edit interposition layer that would remain to be ported.

## Impact

- No configuration is applied to claude_desktop_config.json; no application gesture took place or is planned by this Decision.
- The door `open-mcp-allowlist-verification` closes; a frozen door `frozen-mcp-write-allowlist` opens, carrying the three conditions above as its only wake-up condition.
- No change to the write perimeter of the Pilot or of the Executor: the role charter (`RULES-2026-08-23-224706`) applies without modification.

## Important alternatives

- Build an MCP wrapper immediately (route 2 of the wake-up conditions) with no real accident observed: rejected, YAGNI (232341 §5.4) — the need is not measured, only anticipated.
- Document no status quo and leave the question implicitly closed: rejected — this is exactly the pattern that an unengraved rule drifts, already named at Missions 062 and 063 for other subjects.

## Human gate

- Validation: granted
- Reference: exact word « je tranche : d, dépose 064 » ["I decide: d, file 064"], 2026-08-26, Mission `064`.

## Linked artefacts

- Measurement: (workshop history, not distributed) (hors Vault).
- Raw finding: (workshop history, not distributed) (hors Vault).
- Report of the older Vault (wrapped): (workshop history, not distributed) (hors Vault).

## Liens

- `source` — Execution report — Mission 063 (workshop history, not distributed) (hors Vault)
- `source` — Knowledge-note — Write-restriction mechanism of the older Vault (workshop history, not distributed) (hors Vault)
- `applies` — Decision — Consolidation of the evening of 2026-08-25 (workshop history, not distributed) (hors Vault)
- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
