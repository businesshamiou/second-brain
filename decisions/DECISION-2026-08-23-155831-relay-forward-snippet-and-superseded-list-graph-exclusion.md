---
type: decision
title: "Outbound direction of the relay as a snippet, and superseded list outside the graph but versioned"
created_at: "2026-08-23T15:58:31-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
---

# DECISION — Outbound direction of the relay as a snippet, and superseded list outside the graph but versioned

## Date

2026-08-23

## Status

`ARBITRATED`

Arbitration: Owner/Pilot session of 2026-08-23, formalized by Mission 030 (workshop history, not distributed).

## Decision

Two arbitrations by the Owner on 2026-08-23.

1. **Outbound direction of the relay, engraved and delivered as a snippet.** The mini-prompt that opens an Executor session now follows a fixed structure with five rubrics (title line naming the session, opening root — the Vault as an absolute path, source to apply — the path of the Mission file relative to the Vault, absolute prohibitions, expected output — the Mission's RELAY block), and it is delivered by the Pilot **as a snippet copyable in a single gesture** (a code block in the chat), never as a file to open nor as prose to reassemble. The return direction (RELAY block, engraved by the [Decision of 2026-08-23 12:49](./DECISION-2026-08-23-124937-role-relay-mini-prompts.md)) is not modified: both directions now live in the same rule, [RULES-2026-08-23-124937](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md). *Amendment note (2026-08-26): the rubric "opening root — the Vault as an absolute path" above is revoked by Decision `213150` — the opening position is free; see `RULES-2026-08-23-124937` rubric 2, amended accordingly.*

2. **List of superseded files (`superseded-files.txt`) excluded from the graph, but versioned.** The flat file produced by `tools/build-indexes.sh` (Mission 029) is added to the `.graphifyignore` (supprimé, Mission 040) of each root where it is produced — a machine file without prose bringing only noise to a semantic graph — but remains tracked by Git: without it on a fresh installation (clone), the `[REMPLACÉ]` mark of `tools/find-in-vault.sh` disappears silently.

## Reason

1. A mini-prompt to be reassembled from memory or found in a file introduces a risk of drift at every handover; a snippet copyable in a single gesture, with five fixed rubrics, eliminates this risk and makes the handover as cheap on the way out as on the way back (RELAY block).
2. A graph node for a flat file with neither prose nor semantic relation serves no `graphify query`/`explain`/`path` request; excluding it from the graph is a gain in signal without loss. But excluding it from Git would remove the very feature that Mission 029 has just built (the `[REMPLACÉ]` marking) on any installation that does not regenerate the indexes before its first search.

## Impact

- `vault/rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md` now carries both directions of the relay (outbound with five rubrics as a snippet, return as a RELAY block) in the same rule.
- `vault/.graphifyignore` (supprimé, Mission 040) and (workshop history, not distributed) (supprimé, Mission 040) each exclude `superseded-files.txt` from their root; the file remains tracked by Git in both repositories (`git ls-files` already checked before this Decision: present at both locations).
- Any future Mission that delivers a mini-prompt opening an Executor session does so as a five-rubric snippet, never otherwise.

## Important alternatives

- Outbound mini-prompt left with three free rubrics (previous state): rejected, the five-rubric structure covers a case that the three old ones did not cover explicitly (the title line naming the session, and the expected output).
- Remove `superseded-files.txt` from Git rather than from the graph only: rejected, would make the `[REMPLACÉ]` mark disappear on any fresh installation that has not yet regenerated the indexes.
- Let `superseded-files.txt` enter the graph like any other tracked file: rejected, a flat file without prose brings only noise to a semantic graph (same reason as the exclusion of `tools/`, `.githooks/` and `rules/patterns/` in `.graphifyignore` (supprimé, Mission 040)).

## Human gate

- Validation: granted
- Reference: arbitration by the Owner in session on 2026-08-23, executed by Mission 030.

## Linked artefacts

- Execution Mission: (workshop history, not distributed)
- Rule amended: `../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md`
- Source report of the « à trancher » ["to be decided"] point: (workshop history, not distributed)

## Liens

- `applies` — [Relay between roles through mini-prompts with fixed rubrics](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amended by` — Decision — Opening directory of a session, position freed (workshop history, not distributed)
- `see also` — [Adoption of the rule of relay between roles through mini-prompts](./DECISION-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — Mission 030 — Outbound direction of the relay engraved, superseded list outside the graph (workshop history, not distributed) (hors Vault)
