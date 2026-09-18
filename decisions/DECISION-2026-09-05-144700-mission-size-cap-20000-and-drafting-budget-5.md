---
type: decision
title: "Decision — Mission size cap (20,000 bytes) and Pilot drafting budget (5 calls before the write cycle), fail-closed, not retroactive"
created_at: "2026-09-05T14:47:00-04:00"
timezone: America/Montreal
status: active
description: "Puts figures on the two caps that Decision 140714 was waiting for: a Mission fits under 20,000 bytes; drafting a Pilot artefact costs at most 5 tool calls before the write cycle, existence checks included. Measurements: twelve artefacts of cycle 128–141 (sizes by get_file_info), seven draftings counted. Not retroactive; mechanization by the mission-lint validator (prototype first), the RELAY flags until then."
---

# DECISION — Mission size cap and Pilot drafting budget

## Context

Decision 140714 (2026-09-03) named two caps without putting figures on them, for lack of measurements: the size of a Mission and the budget of the Pilot's drafting phase. The measurements exist since cycle 136–141.

**Mission sizes, in bytes, reported by get_file_info on the repository (MESURÉ — measured)**: seven recent Missions before the cycle — 15,175, 15,483, 17,356, 17,745, 18,067, 20,298, 25,000 (Owner, 2026-09-04, distribution of the last seven); then 137: 20,385; 137-B: 13,139; 139: 13,355; 140: 17,901; 141: 14,192. Twelve values; median ≈ 17,000; the two largest (25,000 and 20,385) are those whose Context and « Existant mesuré » (measured existing) copied facts already present in the conversation — a defect of proportionality, not of content.

**Drafting cost, in tool calls before the write cycle (write, info, edit, move), MESURÉ by counting in session**: 136: 10 (including a whole reading of a 128 KB index for one useful line); 137: 1; 137-B: 0; Decision 124647: 3; PROPOSAL 140326: 2; 140: 1; 141: 3 (1 sweep + 2 path existence checks). A single value above 3, and it is the measured fault of the cycle.

**What a cap costs when it is missing**: 136 at 25,000 bytes required 22 substitutions after its challenge; the Missions under 15,000 (137-B, 139) required only one or two. A long Mission has more places to be wrong (PROPOSAL 140326, point 11).

## Decision (Owner, chat, 2026-09-05)

1. **Size: a Mission fits under 20,000 bytes**, measured by the tool (get_file_info or wc -c) on the filed file. Twelve measurements: ten pass, two — the two defects of proportionality — are refused; that is the meaning of the cap. The same cap applies to the Pilot's Decisions and Proposals.
2. **Drafting: at most 5 tool calls before the write cycle**, every reading, search and existence check included; tool searches (loading of schemas) are counted separately (Decision 145256). Beyond that, the Pilot stops and says why instead of continuing. Seven measurements: six under 3, one at 10 by fault; 5 leaves the margin for the existence checks that the manual screen imposes (2 on 141).
3. **Proportionality, writing rule**: when nothing is created and the measurements are already in the conversation, the « Existant mesuré » and « Contexte » rubrics cite the measurement by its report or RELAY number in one line, without copying it. An index is read by tail or by searching for a line, never in full (Decision 124647, point 6).
4. **Fail-closed, not retroactive.** Missions already committed are neither truncated nor rewritten. A Pilot artefact that exceeds is refused at its promotion, not committed.
5. **Mechanization.** The size cap is enforced by the mission-lint validator (PROPOSAL 140326; prototype first, Owner arbitration of 2026-09-05, point 7); the drafting budget is counted by the Pilot in the « Ouverture / budget » (opening / budget) rubric of each filing and checked by the Owner. As long as the validator does not exist, the rule is an author instruction, and the RELAY or the Pilot flags any overrun — same transitional regime as Decision 191407.

## Consequences

- Decision 140714 now has figures on its two pending points; it is not rewritten (Decision 145256).
- The Mission template receives a scale clause (rule 3) through a Mission updating the templates, to be grouped with the skill changes that audit 141 measured.
- The reading list of the Mission-drafting skill takes up rules 2 and 3.
- The mission-lint prototype (to come, outside the repository) takes size as its first deterministic check; its entry into the Vault follows the arbitration of the Delivery Gate Decision.

## Alternatives set aside

- Cap at 25,000 (nothing refused): teaches nothing, the largest Mission measured is also the most faulty.
- Cap at 15,000: would refuse seven of the twelve measurements, including 140, judged proportionate; too tight before the template's scale clause.
- Drafting budget at 3: would refuse 141 as it was written with its existence checks, which we want to encourage.
- No cap: Decision 140714 already settled that one was needed.

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `see also` — [Decision — Pilot context budget](./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md)
- `see also` — [Decision — An index is a locator](./DECISION-2026-09-05-124647-index-as-locator-8000-cap-live-archive.md)
- `see also` — [Decision — Journal and index as pointers, ≤ 300 characters](./DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)
- `source` — PROPOSAL — Delivery Gate, DRAFT → CANONICAL, mission-lint (workshop history, not distributed) (hors Vault)
- `applies` — [Decision — Evidence status and STOP control](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
