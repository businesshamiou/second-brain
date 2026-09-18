---
title: "List of closing holes, one measurement per line"
description: "Single source of the inventory run by the session-close skill before any close: each family of hole with the tool that measures it and the dated fault that paid for it. This is the file that is amended when a new hole appears — the body of the skill does not move. amended by chain followed by the skill."
created_at: "2026-09-01T19:30:00-04:00"
timezone: America/Montreal
status: active
---

# LIST OF CLOSING HOLES

Run by the `session-close` skill (§2, step 1 on the Pilot side; §3 on the Executor side for the lines marked E). One line = one possible hole, the tool that measures it, the fault that paid for it. An unmeasured hole is a hole.

| # | Hole | Measurement (Pilot: MCP · Executor: shell) | Fault paid |
|---|---|---|---|
| 1 | Mission of `MISSION-INDEX.md` without a final state (line absent, or status neither `COMPLETED` nor a dated `STOP`/`PARTIEL`) | `read_text_file` of `missions/MISSION-INDEX.md`, compare with the Missions filed during the session · E: `grep` of each number | Mission 112: three windows without a 112 line, 113 STOPped on it (2026-09-01) |
| 2 | RELAY block received in the conversation and not consumed (verdict not taken up, « À trancher » [to be decided] without an Owner word) | review of the conversation, one RELAY = one line | RELAY 112 (resume) not settled before the /goal 113 was issued (2026-09-01) |
| 3 | Pilot artefact filed (capture, proposal, decision, mission) not tracked by Git | `get_file_info` on each path announced in the conversation, then presence in the repository's last commit · E: `git status --porcelain` | uncommitted residues dragged along for three sessions (28-30 August, tidied by Mission 109) |
| 4 | Open door (`OPEN:` in the journal) without a later `CLOSE:` although its condition is met | `read_text_file` of `state/STATE.md` (doors section) · E: `build-state.sh` dry run | door `open-mission-internal-coherence` closed only by Mission 111 |
| 5 | Flagged residue (report, RELAY: phantom diff, tool by-product, concurrent file) without Owner arbitration | "Deviations" [« Écarts »] / « Consignations » [records] rubrics of the session's reports | `proposals/superseded-files.txt` dragged along for two windows before prescription (Mission 112) |
| 6 | Push state: local head ≠ `refs/remotes/origin/main` on a repository, without an Owner word on the push | `read_text_file` of `.git/refs/heads/main` and `.git/refs/remotes/origin/main` (or `packed-refs`) · E: `git status -sb` (`ahead`) | push suspended by the Owner on 2026-09-01 01:00, to be recalled at each close |
| 7 | Previous handoff not consumed (resume queue with a point that was neither run nor arbitrated) | reading of the last `handoffs/HANDOFF-*.md` | handoff 004859: points "chat skills" and "obsolete override" taken up two sessions later |
| 8 | Pin behind: the Vault received a commit during the session and `<projet>/.pre-commit-config.yaml` still points to the old SHA — reference of truth `origin/main`, `repo:` designating a remote repository (Mission 155); re-pinning possible **after the Owner push** only, otherwise hole carried to the handoff, with regeneration of `_dist/skills-chat/` | `grep rev:` of the file compared with the Vault's `.git/refs/remotes/origin/main` · E: `bash tools/check-vault-pin.sh` | ANOMALY of reports 153 and 154, four manual re-pinnings in one day |

Rule: the list is an inventory; a hole is closed by a Mission, an Owner arbitration or a one-off instruction — never by the skill itself.

## Liens

- `see also` — [session-close skill](./SKILL.md)
- `applies` — [Decision — CLOSE: tag and keyed doors of the journal](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
