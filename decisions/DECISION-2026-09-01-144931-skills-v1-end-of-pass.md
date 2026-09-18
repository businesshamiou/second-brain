---
type: decision
title: "End of the skills V1 pass — list of six skills plus a hook, command principle, session-start / session-close / first-install arbitrations, research split in three, build order, staleness by sources"
description: "Engraves all the arbitrations of the skills V1 pass rendered between 2026-08-30 and 2026-09-01: final list (session-start, session-close, écriture-de-mission, project-bootstrap, first-install, internal research; executor-preflight becomes a hook), command principle (the Owner launches, never an agent → agent channel), the arbitrated points of session-start (six), session-close (four) and first-install (four), the split of research (internal built, web covered by the library's research skill, images without a skill), keeping the name to-questionnaire after investigation, the build order starting with session-start and ending with first-install, and the staleness-by-sources mechanism (vault-implements + vault-validated crossed with superseded-files.txt and the amended by lines). Amends DECISION-2026-08-25-232341 §5.1."
created_at: "2026-09-01T14:49:31-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-09-01-144931-skills-v1-end-of-pass.md"
---

# DECISION — END OF THE SKILLS V1 PASS

## Date

2026-09-01 (arbitrations rendered from 2026-08-30 to 2026-09-01)

## Status

`ARBITRATED` — exact words of the Owner, Pilot window: « hook », « ok » (session-start), « ok » (session-close), « je valide » ["I validate"] (command), then on this day « fi-ok », « garder » ["keep"], « c-ok », « péremption-implements » ["staleness-implements"], and the split of research dictated in full.

## Decision

**1. V1 list: six skills and a hook.** The skills built by the Vault are `session-start`, `session-close`, `écriture-de-mission` (new, added by this Decision), `project-bootstrap`, `first-install`, `recherche-interne`. `executor-preflight` is not a skill: it is a `PreToolUse` hook placed by the bootstrap, plus the pre-commit filter, plus three lines in `session-start` (arbitration « hook »). This list amends `DECISION-2026-08-25-232341` §5.1 (which said six skills including an `executor-preflight` and an unspecified research skill).

**2. `commande` (command) principle, common to all.** The Pilot prepares on disk; the Owner launches a fixed command in Claude Code; the Executor finishes alone and returns a RELAY. Never an agent → agent channel: the Owner remains the only bridge between windows.

**3. `session-start`, six points (arbitrated on 2026-08-31).** Completes the opening prompt, does not replace it · the hook is the trigger on the Executor side, automatic only once placed by the bootstrap · a single skill, mechanical switch according to the surface (shell available?) · opening canary = `rev:` of `.pre-commit-config.yaml` compared with the Vault's head + presence of the hook + presence of the guardian scripts · NOT-READY = stop (Executor: no gesture; Pilot: no filing) · the reading list per role lives in a Vault file, `amended by` chain followed.

**4. `session-close`, four points (arbitrated on 2026-08-31).** Triggered by the Owner (« wrap ») · two surfaces · refuses to close with holes (doors without a line, unarbitrated residues, unconsumed RELAY) · keeping `MISSION-INDEX.md` up to date is part of its spec.

**5. `first-install`, four points (arbitrated « fi-ok » on 2026-09-01).** Executor only · reuses the library's `to-questionnaire` skill for its interrogation · replayable without overwriting (on an already installed machine, it completes) · proposes the chat skills without ever declaring them installed — chat installation is an observed Owner gesture. It is built **last**: installing everything requires having seen everything.

**6. Research: three objects, only one built.** (a) **Research internal to the Vault**: V1 skill `recherche-interne`, a discipline and not an engine — indexes and `description` fields first (progressive disclosure), then exact `grep`/glob on the corpus, never an assertion without a measured path; two surfaces; consistent with the conclusion of the Mnemosyne study (wire up the existing rather than tool up anew). (b) **Web research**: covered by the `research` skill of the external library (measured in catalogue v3, box UD, invocation `/research` or automatic — "high-trust primary sources", cited Markdown output); nothing to build; if the Owner provides a better source, it will go through the ordinary adoption circuit. (c) **Image search**: no skill, the rules in place suffice.

**7. `to-questionnaire` keeps its name (arbitration « garder » ["keep"], after investigation).** Measured: the name comes from the upstream `github.com/mattpocock/skills` (front-matter `upstream-repo`, version 1.2.3), and "questionnaire" is an English word in its own right — the English naming is respected. Renaming it would break the matching by name of the update-or-reject cycle at each warehouse package, the junction, the catalogue and the manifest, to fix a defect that does not exist.

**8. Build order (arbitration « c-ok »).** The preliminary study is done (research on the golden rules of documentation freshness, on this day, recorded in Reason). Then: `session-start` → `session-close` → `écriture-de-mission` → `project-bootstrap` (adopt mode) → `recherche-interne` → `first-install`. One skill at a time, fully specified before launch, anti-overlap rule at creation (232341, unchanged). Accepted consequence: the adoption of the `skills-warehouse` project waits for `project-bootstrap`.

**9. Staleness by sources (arbitration « péremption-implements » ["staleness-implements"]).** Each skill built by the Vault carries in `metadata`: `vault-implements` (paths of the Decisions and rules it embodies, comma-separated string — `metadata` accepts only string → string pairs) and `vault-validated` (date of last validation). A skill is **deemed stale** as soon as one of its sources appears in `superseded-files.txt` or receives an `amended by` line later than its `vault-validated`. Manual check at each end of pass to begin with; candidate mechanical guardian (crossing of existing files, no new tool) — trajectory doctrine → rule → mechanism. Adopted external skills do not carry `vault-implements`: their staleness is that of the update-or-reject cycle.

## Reason

The V1 pass had been two-thirds arbitrated since 2026-08-31 (handoff §3); first-install, research, the order and staleness remained. Today's verdicts close the pass.

The addition of `écriture-de-mission` to the list rests on measured evidence: three internal contradictions of Missions in three days (090, 108 ×2), engraved with their rules by `DECISION-2026-09-01-115547` — the skill only has to embody rules already written; it is the safest yield of the work item.

The split of research comes from a measurement: catalogue v3 shows that web research is already served by an adopted skill (`research`), and the Mnemosyne study (2026-08-30) had concluded that wiring up existing mechanisms is better than new tooling — internal research is therefore a discipline over the existing indexes, not an engine.

Staleness by sources merges the Pilot's recommendation with the field's golden rules, researched on this day at the Owner's request: link each document to its sources in a manifest the machine reads; date the last validation in the document itself and enforce it in CI; update in the same gesture as the change, with periodic review and a named person responsible. The Vault already has the two machine-readable stocks needed (`superseded-files.txt`, `amended by` lines): the future guardian is a crossing, not a tool.

## Impact

- `DECISION-2026-08-25-232341` §5.1 is amended (reciprocal `amended by` placed by the execution Mission).
- Building can begin: first spec = `session-start`, one skill at a time.
- The template of built skills gains two `metadata` fields (`vault-implements`, `vault-validated`) — to be placed in the spec of the first skill, not retroactively on the 40 external ones.
- The staleness review enters the close of each skills pass; `session-close` (point 4) does not inherit it — it is a pass check, not a session check.
- Chat installation (queue point 2) and the adoption of the warehouse (point 4) remain open, unchanged by this Decision.
- A naming investigation is closed: `to-questionnaire`, recorded in point 7, no hole or dead link created.

## Important alternatives

- **Build `écriture-de-mission` first** (strongest measured evidence): set aside by the Owner (« on commence par le commencement » ["we start at the beginning"]) — `session-start` opens every session, its absence costs every window; Mission writing comes third.
- **An internal search engine** (retrieval, embeddings): set aside, against the conclusion of the Mnemosyne study and without measured need.
- **Rename `to-questionnaire`**: set aside after investigation (point 7).
- **Calendar staleness** (review at a fixed date with no link to sources): set aside — it makes one reread what has not moved and misses what moved between two dates; the periodic review stays as a safety net, not as the main mechanism.

## Human gate

- Validation: granted — verdicts named in Status, Owner, 2026-08-31 and 2026-09-01.
- Reference: Pilot window of 2026-09-01 (arbitration table in one pass, one verdict per rubric); handoff `HANDOFF-2026-09-01-004859` §3 for the arbitrations of 2026-08-31.

## Linked artefacts

- Source: `../handoffs/HANDOFF-2026-09-01-004859-session-close-skills-rework-library-pending-106.md` (supprimé) (§3, arbitrations of the two thirds)
- Source: `../knowledge-notes/KNOWLEDGE-NOTE-2026-09-01-110501-skills-library-v3-catalog.md` (measurement of the `research` skill, `to-questionnaire` entry)
- Source: `../knowledge-notes/KNOWLEDGE-NOTE-2026-08-30-211552-mnemosyne-retrieval-vs-vault-reel.md` (wire up the existing rather than tool up)
- Execution: Mission to come (reciprocal on 232341, `session-start` spec)

## Liens

- `prescribed by` — [Decision template](../../../vault/templates/decision-template.md) (hors Vault)
- `amends` — [Decision — Evening consolidation, project standard and plan](./DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md)
- `applies` — [Decision — Awareness of the Vault by a project, in three tiers](./DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md)
- `applies` — [Decision — Internal coherence of Missions](./DECISION-2026-09-01-115547-mission-context-coherence-and-least-powerful-reading.md)
- `see also` — Decision — Score criterion withdrawn, adoption by name (workshop history, not distributed)
- `see also` — Catalogue v3 of the 40 external skills (workshop history, not distributed)
