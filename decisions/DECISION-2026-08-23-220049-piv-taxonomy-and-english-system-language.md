---
type: decision
title: "PIV taxonomy, English system language, role charter, end of PROMPT files"
created_at: 2026-08-23T22:00:49-04:00
timezone: America/Montreal
status: ARBITRATED
scope: activity-taxonomy-system-language-and-roles
amends:
  - "../rules/RULES-2026-08-17-005717-vault-operating-rules.md"
  - "../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md"
  - "DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md"
related_mission: "038"
---

# DECISION — PIV TAXONOMY, SYSTEM LANGUAGE, ROLE CHARTER, END OF PROMPT

Arbitrated orally by the Owner in the Pilot session of 2026-08-23 (evening).

## A1 — Taxonomy of activity types: PIV

The types announced in session are `plan` / `implement` / `validate`, completed by the session dimension `open` / `milestone` / `close`. [source: Cole Medin, PIV loop]

Rejected along the way: a flat list of six types (it mixed task and session management); four artefact-anchored types including `mission` (it classified by the execution channel, not by intent); `read / decide / write` (the system's point of view, not the Owner's mental model). Brainstorming lives in `plan`.

The same vocabulary serves both levels: the participant's activities on their project (product level) and our building activities (building level).

## A2 — Perimeter of the rule "system keywords in English"

A system keyword is any string read or compared literally by a script, or serving as a structured label: commands, tags, classification labels, statuses, field identifiers. Every system keyword is in English. Field values stay in English; their possible localization is outside the workshop's subject.

Amends §3 of the [Vault operating rules](../rules/RULES-2026-08-17-005717-vault-operating-rules.md): the split "French prose / English identifiers" remains, made more precise by the perimeter above and by A3.

## A3 — Journal entirely in English

Journal lines are written in English, tags and content (`STATE:`, `NEXT:`, `OPEN:`, `RESUME:`). Owner's reason: a journal is consulted by developers and agents; the system translates when needed. The journal being append-only, no historical line is rewritten; the tools read both sets. Documents intended for the Owner stay in French.

## A4 — Determining the role through three rungs

A session determines its role through: `SessionStart` hook (binding) → shell capability probe (unfalsifiable) → declaration in the mini-prompt (confirmation). Contradiction between rungs → STOP. Doubt → the least powerful role prevails, `pilot` is presumed. The role is announced in the first message.

Operational detail: [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md).

## A5 — Revocation of delivering prompts as a downloadable file

The practice "long Executor prompts delivered as downloadable files" was a workaround for the Pilot's lack of filesystem access. It is **revoked** outside the single fallback case (Pilot with no filesystem access at all).

Finding of the session: this practice was engraved in no rule of the Vault — it lived in a context **capture**, wrongly consumed as a norm. Lasting corollary: *a capture is never a norm; only a rule or a Decision binds.*

The Pilot now writes its new artefacts directly at their canonical location, after announcing the door (bounded perimeter, cf. charter §2). This closes gate **G5**.

## A6 — Correction of the prompts' path

The real path is (workshop history, not distributed), and not (workshop history, not distributed) as the master capture stated. Amends §4 of the [Versioning rules](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) by specifying the location, without touching the naming.

## A7 — End of the production of PROMPT files

**Arbitrated** (lifting of the initial OPEN): no PROMPT file is produced any more. The delegation trio becomes: **Mission** (the authority, read in full by the Executor) → **mini-prompt as a snippet** (the trigger, five rubrics, relay rule) → **RELAY block** (the return).

Reasons, in order of strength: (1) duplicate — since the relay rule, the PROMPT only repeats the Mission, and two sources for one task end up diverging; (2) *real need → structure* — no consumer any more; (3) independent convergence: the R-CARGAISON rule of an earlier vault of the Owner (« l'exécutant ne consomme que les pièces `type: mission` ; toute autre pièce ne se suit jamais comme instruction » ["the executor consumes only `type: mission` pieces; any other piece is never followed as an instruction"]) reaches the same conclusion by another path; (4) secondarily, the evidence of degradation through context duplication (context rot, curse of instructions) — valid only when the duplicate is actually loaded in session.

Amends §4 of the [Versioning rules](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md): the naming convention `PROMPT-…` stays defined for reading the history; it no longer produces new files. The existing PROMPT files stay in place, frozen history (stock freeze) — no deletion, no move.

## A8 — Validated borrowings from the earlier vault (capitalization)

Validated as a block by the Owner after cross-examination, for implementation in Mission 039 (preflight):

1. **Identity set before the CLI** by a launcher (environment variable — universal mechanism, not specific to one assistant).
2. **Identity lock at the first tool call**, fail-closed, where the harness allows it (Claude Code `PreToolUse`) — early but proprietary.
3. **Universal pre-commit wall** — a valid preflight stamp required to commit, whatever the agent's brand — late but total. The two stages complement each other, neither replaces the other.
4. **The stamp watches its own silence**: the age of the last check is verified independently of its content — a stamp can lie through silence.
5. **Default `deny`**: any subject, action or resource not declared is refused.
6. **Assumed threat model**: guards against accidents, not against evasion (engraved in the charter).

Rejected: declarative policy without a consumer (policy.yaml — counter-example of *real need → structure*), Windows-only dependencies, fingerprinted hook compiler (over-engineering at this stage), devices with no view of one another.

## Liens

- `amends` — [Operating rules of the central Vault](../rules/RULES-2026-08-17-005717-vault-operating-rules.md)
- `amends` — [Versioning of Missions and generated outputs](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `amends` — [Pilot contract, marking of superseded documents, and ratification of the journal tag convention](./DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md)
- `see also` — [PIV activity classification and system keywords](../rules/RULES-2026-08-23-220049-activity-classification-and-system-keywords.md)
- `see also` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
