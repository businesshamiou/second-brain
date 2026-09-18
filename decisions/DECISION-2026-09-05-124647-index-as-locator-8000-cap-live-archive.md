---
type: decision
title: "Decision — An index is a locator: line without description, cap of 8,000 bytes per index, live index and archive index, lightened Mission register"
created_at: "2026-09-05T12:46:47-04:00"
timezone: America/Montreal
status: active
description: "Owner arbitration of 2026-09-05 on the PROPOSAL of audit 139: a generated index line is a locator (identifier, status, short title, file name), never a description; every index is capped at 8,000 bytes, fail-closed and mechanized; the Mission index splits into live and archive; the manual register MISSION-INDEX.md is kept with a role reduced to execution status. Complements Decision 191407 (line ≤ 300) without amending it."
---

# DECISION — An index is a locator (≤ 8,000 bytes per index, live/archive, lightened register)

## Context

Audit 139 (report and PROPOSAL of 2026-09-05, read-only) inventoried 37 indexes in the two repositories and measured: missions/MISSION-INDEX.md 127,892 bytes for 136 entries, longest line 4,534 characters; missions/index.md 68,242 bytes of which 50 % descriptions; reports/index.md 34,773 bytes; five indexes above the 8,000 bytes that cap the opening digest (2,209 bytes). Reading the whole register costs 233 times a targeted `grep` and 58 times the digest. Mission 080 had added title, type, status and the whole description to every index line: that is the origin of the weight. The manual register and the generated Mission index overlap, but the execution status exists only in the register, the front-matter `status` of a Mission being frozen at its creation by the template. The same day, the index freshness guardian had to be rewritten (Mission 137-B) because its cost grew with the number of entries and the length of the descriptions.

Decision 191407 (2026-09-02) caps the **line** of the journal and of the register at 300 characters; it was not mechanized on the register (line measured at 4,534). The present Decision does not rewrite it: it sets the **content** of a generated index line and the **weight** of an index file, and makes both mechanizable.

## Decision (Owner, chat, 2026-09-05)

1. **A generated index line is a locator.** For every index.md produced by `tools/build-indexes.sh`, an entry carries: identifier (Mission number, timestamp or name), front-matter status, short title, file name. **No description**: it lives in the front matter of the file pointed to. The short title is the front-matter `title`, truncated by the tool to a length set by the compliance Mission, never by hand.
2. **Mission register kept, role lightened.** MISSION-INDEX.md remains the only place of the **execution status** (the front-matter `status` stays frozen at creation, template doctrine unchanged). It becomes a four-column table — identifier, execution status, date, report name — one line per Mission, without description or note; Decision 191407 (≤ 300 characters) applies to it and is mechanized on it. Whatever is not an execution status leaves the register.
3. **Cap: 8,000 bytes per index file**, generated or register, aligned with the digest cap. Fail-closed: an index that exceeds it is refused at commit by a weight guardian, delivered by the compliance Mission. **Not retroactive** as long as that Mission is not delivered: until then, the rule is an author instruction and the RELAY flags any index that exceeds it.

   **Annotation (2026-09-08, Mission 161).** The weight guardian of point 3 was wired into the pre-commit of (workshop history, not distributed) on 2026-09-08 — it had never been, as the history measures: 0 occurrences of `index-weight` in the past of `.pre-commit-config.yaml`. It immediately refused MISSION-INDEX.md, measured at **134,241 bytes** for 159 table lines, blocking every commit touching the register — that is, every Mission. The 8,000-byte cap is reachable by the register only once **point 2** is delivered, that is, the four-column table without description or note; `tools/build-indexes.sh` neither produces nor splits the register, so the instruction of the refusal (« ligne en localisateur, ou scission vivant/archive » ["line as locator, or live/archive split"]) is inapplicable to it. On Owner arbitration of 2026-09-08, `tools/check_index_weight.py` **exempts the register from the weight cap** and applies to it only the 300-character limit per line (Decision 191407). **The exemption falls with the delivery of point 2**: point 3 remains unchanged in its intent — "generated or register" —, only its application to the register is suspended.

   **Annotation (2026-09-08, Mission 163) — point 2 delivered, exemption withdrawn.** The Mission register has moved to four columns (identifier, execution status, date, report name), which point 2 prescribed: batch 3 of Mission 140, postponed on 2026-09-05 to close V1, was taken up as it was. The weight exemption set by Mission 161 is **withdrawn** from `tools/check_index_weight.py`: the register is again subject to the 8,000-byte cap of point 3, as to the 300-character limit per line of Decision 191407. The live register is split into slices; its archives carry a name distinct from that of the generated index archives, which the freshness guardian recognizes by their prefix. The annotation of Mission 161 above describes a bygone state and is not rewritten: it dates what was true between 2026-09-08 and this delivery.

   **Annotation (2026-09-08, Mission 164) — point 5 delivered, door closed.** The test bench of the freshness and weight guardians announced by this point — never delivered, known since Mission 140 under the name « banc 138 » ["bench 138"] — is written and versioned in the Vault: a throwaway Git repository, ten cases proven by report 140, a Python script calling the two real guardians (never copies), replayable in one command, tools/bench-guardians.sh. The index-conformance door of Mission 140 closes on this deliverable.
4. **Live index and archive index.** The generated Mission index (and any index that does not fit under 8,000 bytes as a pure locator — measurement 139: 136 entries exceed it) splits into a current index, which lists the open entries and the last N closed ones, and an archive index, read on request only. N is computed by the compliance Mission to fit under the cap, and recomputed by the tool, never by hand. The freshness guardian checks both.
5. **Order of compliance: doctrine first.** This Decision, then a single Mission that delivers a compliant `tools/build-indexes.sh` (points 1 and 4), the lightened register (point 2), the weight guardian (point 3) and the 300 limit on the register (191407, point 4), with byte-measured before/after proof on the 37 indexes of the audit; then the guardians' test bench (138) tests the whole.
6. **Reading.** An index is read by `tail` or by searching for a line, never in full; the opening reading list takes up this rule. The opening digest remains the only whole reading prescribed.

## Consequences

- Mission to be drafted (140): build-indexes.sh as locator + live/archive, four-column register, weight guardian ≤ 8,000 fail-closed, 300 limit on the register; wiring into the pre-commit of (workshop history, not distributed) via a revision pin (two pushes minimum); proof on the 37 indexes measured by 139.
- The `check-indexes-fresh` guardian (Python, 137-B) checks "set of names + status"; the disappearance of descriptions from the indexes reduces what it compares — its byte-identical proof is to be replayed by Mission 140.
- The `écriture-de-mission` and `session-close` skills take up the rule: a Mission's register line is a status, not a narrative.
- The opening reading list (`skills/session-start/reading-list.md`) takes up point 6.
- Five duplicates named by audit 139: handled by Mission 140 according to the measured roles, no deletion before it.

## Alternatives set aside

- Capped description in the line: as a pure locator, missions/index.md stays above 8,000 bytes (measurement 139); a description, even a short one, cannot fit under the cap.
- Merging the register into the front matter: would require making the front-matter `status` mutable, against the doctrine of the Mission template; set aside.
- Single index with marking: does not reduce the weight; set aside in favour of live/archive.
- No cap: the digest proved that a fail-closed cap holds where an instruction drifts.

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `source` — Report 139 — audit of the indexes (workshop history, not distributed) (hors Vault)
- `source` — PROPOSAL — index rules: content, cost, duplicates (workshop history, not distributed) (hors Vault)
- `see also` — [Decision — Journal and index as pointers, ≤ 300 characters](./DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)
- `applies` — [Decision — Evidence status and STOP control](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
