---
type: decision
title: "Pilot context budget: Mission size cap on a measured distribution, opening order digest → handoff → refs, dryRun as a measurement, snippet emitted once"
description: "Decision arbitrated on 2026-09-03 (gate « plafonne »): a fail-closed cap on the size of MISSION files whose value will be set only after measuring the existing distribution; four doctrinal rules of parsimony on the Pilot side; a named HYPOTHÈSE on the fixed conversation prefix and its only possible measurement."
created_at: "2026-09-03T14:07:14-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: pilot-context-budget, mission-size-cap, session-opening
---

# DECISION — PILOT CONTEXT BUDGET

## Date

2026-09-03

## Status

`ARBITRATED`

## Decision

1. **Mission size cap — conditional.** A fail-closed cap on the size in bytes of every Mission file (prefix MISSION-) will be installed by a guardian, on the model of the digest cap (Mission 121: constant, fail-closed, not bypassable) and with a non-retroactive baseline (Mission 123). **Its value is not set here.** Precondition, Executor gesture prescribed by a measurement Mission: size of each Mission file (prefix MISSION-) of the two repositories, median, maximum, the five largest named with their size; table pasted into the report. The Owner settles the value on this table. What would refute the point: a distribution where the useful cap would exclude the majority of existing Missions — the guardian would then be replaced by a simple warning. The size of a particular Mission (including Mission 131, 15,509 bytes) is never an argument for the value.
2. **Pilot opening order: (workshop history, not distributed) first, then the handoff it names, then the Git refs.** The digest carries the freshness test (Mission 121); it names the last handoff, which removes the listing of the `handoffs/` folder. Amends order 1–2 of `vault/skills/session-start/reading-list.md` (Mission 121) without changing the three readings.
3. **`dryRun` is a measurement in the sense of Decision 212009.** The Pilot's own artefact — filed in the session, present in the context — is never reread in full to be corrected. Its verification is done by `edit_file` in `dryRun` (failure on an absent string is the measurement; the rendered diff is the proof), by `head` or by `tail`. Rereading in full what one has just written is a convenience reading in the sense of the charter §2 "Reading".
4. **The snippet is emitted once.** Any resumption of an already emitted mini-prompt says « snippet inchangé » ["snippet unchanged"] and does not copy it again; if it changes, only the modified rubric is re-emitted, named. Holds for the Pilot; the Owner pastes the RELAY blocks once.
5. **Bounded tool discovery and memory recall.** A single tool search per family, by the exact name of the tool; Mnemosyne `recall` at `limit 3` by default.

**Amended on 2026-09-04** by [Decision 145256](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md): the tool search is phrased on the tool's description, the index carrying descriptions and not names; a second search is allowed and counted in the budget. Applied text: [reading-list](../skills/session-start/reading-list.md).
6. **Named HYPOTHÈSE — fixed conversation prefix.** The prefix present at each turn (Project instructions, memory, loaded tool schemas, skills) would be the first item of expense of a Pilot session, and it grows with each `tool_search`: a loaded schema is paid at each following turn, not once. No Vault tool measures it. **Only possible measurement**: at the end of the session, the Pilot counts the `tool_search` calls played and the schemas loaded (number, families), and records them in the « Ouverture / budget » ["Opening / budget"] rubric of the handoff — a rubric itself to be created (table of gaps of 128). Three sessions counted before any conclusion, as for the Mnemosyne observation.

## Reason

Pilot session of 2026-09-03: one opening and one micro-Mission consumed, according to the interface, ~70% of a conversation. Survey of the calls (estimated, audit turn): ~130 KB of calls and prose, of which the life cycle of a single Mission ≈ 48 KB — written (15.5 KB), reread in full (15.5 KB), re-edited (17 KB of input and diff) —, ~10 KB of tool discovery in six searches, a snippet emitted twice. The rest of the 70% is covered by no survey: it is the fixed prefix, hence point 6.

The precedent comes in two pairs: 120 → 121 (measure the state loop — 55,969 bytes prescribed at opening — then cap: digest 2,220 / 8,000 bytes, fail-closed) and 118 batch 8 → 127 (time the guardians — 110 s, two guardians = 99% — then optimize with byte-identical output: 3.21 s). In both cases the first hypothesis of cause was incomplete or false (127: the per-file fork weighed 0.42 s), and only measurement settled it. Point 1 respects this order; setting the cap's value today, on the size of a Mission in front of one's eyes, would be reasoning backwards.

On the chat side, length **is** the cost: a byte read or written is paid until the end of the conversation. On the scripts side, it is not (127). This Decision therefore only touches the Pilot item; scripts other than guardians remain unmeasured and fall under a distinct measurement Mission, after 128, before 129.

## Impact

- A measurement Mission (read-only, report only) precedes the guardian of point 1; the guardian then comes by Mission, with the two-push cycle.
- `vault/skills/session-start/reading-list.md` (Pilot section) receives points 2, 3, 4 and 5 — by amendment of Mission 131, already open on this file and not launched.
- The `écriture-de-mission` checklist receives: « artefact propre relu en entier » ["own artefact reread in full"], « snippet réémis » ["snippet re-emitted"], « recherche d'outils par tâtonnement » ["tool search by trial and error"].
- The handoff template receives an « Ouverture / budget » rubric (bytes read, calls, `tool_search` played, schemas loaded) — in the table of gaps of 128, checkable by a format guardian.

## Important alternatives

- Set the cap's value now (10,000 or 16,000 bytes): set aside — value without a measured distribution, precedent 127 against.
- Reading counter per document: set aside — not mechanizable on the Pilot side (the MCP server logs nothing), redundant on the Executor side (reports paste the commands).
- Cut into the guardians: set aside — chain at 3.21 s since 127, measured cost nil.
- Proposal before Decision: set aside — nothing is cut here; the proposal will come if there is something to cut, after measurement.

## Human gate

- Validation: granted
- Reference: gate « plafonne » ["cap it"], Owner, 2026-09-03, in chat, « sous la condition 1 » ["under condition 1"] (cap value on a measured distribution, precondition of the Decision, not a hypothesis).

## Linked artefacts

- Mission open on `vault/skills/session-start/reading-list.md`: (workshop history, not distributed)
- Measurements cited: (workshop history, not distributed), (workshop history, not distributed), (workshop history, not distributed), (workshop history, not distributed)

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `applies` — [Decision — Evidence status and stop control](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Session opening reading list, by role](../skills/session-start/reading-list.md)
- `see also` — Mission 131 — alignment of the Pilot opening protocol (workshop history, not distributed) (hors Vault)
- `amended by` — [Decision — Amendment of two engraved norms](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)
