---
type: decision
title: "Permanent deletion is an Owner gesture — moving outside the repositories is its agent substitute"
description: "Engraves the fact measured three times by Mission 087: no agent, Pilot or Executor, permanently deletes a file, even under a granted human gate — the environment's policy refuses it, and the refusal cannot be worked around. Deletion joins push among the gestures reserved to the Owner. Agent substitute: move the file to a drop zone outside any repository (_trash at the root of the workspace), which the Owner alone empties. Amends the role charter (§2, §3), the relay rule (rubric 4 and return direction) and the Mission template (no Executor deletion step); AGENTS.md distinguishes Owner gestures from human gates."
created_at: "2026-08-29T11:08:52-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  - "../templates/mission-template.md"
  - "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
---

# DECISION — PERMANENT DELETION IS AN OWNER GESTURE

## Date

2026-08-29

## Status

`ARBITRATED`

## Decision

**1. Reserved gesture.** The permanent deletion of a file — tracked by Git or not, whatever its content — is an Owner gesture, just like `push`. No agent executes it: neither the Pilot (already forbidden by the charter §2), nor the Executor, **including when a Mission grants it the human gate**. The charter §3 (« aucune suppression sans human gate » ["no deletion without a human gate"]) suggested that a gate was enough; it is not enough. The refusal comes from the policy of the agent's environment, it is identical through every tool, and it cannot be worked around — neither by rewording, nor by an alternative tool, nor by upstream authorization.

**2. Agent substitute: moving outside the repositories.** When a Mission requires a file to stop existing in the corpus, the agent **moves** it to the drop zone outside the repositories: `_trash/` at the root of the workspace, outside any Git repository. A move is not a deletion: it is reversible and does not fall under the refusal. The move is proven by a SHA-256 fingerprint before and after (the file is not altered) and by the remeasured absence at the old path. The Pilot may execute it itself through its filesystem access when an Executor's Mission is blocked on it — this is the case of 087.

**3. `_trash/` — status.** Zone outside the documentary norm: no index, no front matter, no link; nothing in it is cited from the corpus. It is emptied by the Owner alone, at their own pace; its emptying is never a precondition of a Mission. A links guardian that met it as a target signals an error of the corpus, not of the zone.

**4. Mission template.** A Mission never again prescribes a "delete" step to the Executor. Two forms only: **(a)** "move to `_trash/`" as an agent step, with fingerprint and remeasurement of absence in validation; or **(b)** "deletion by the Owner" as a human gate, outside the steps, with the resume precondition "absence measured at the old path, STOP otherwise". The launch snippet never asserts that an Owner deletion has taken place: it asks the Executor to measure it.

**5. Relay, snippets and agent replies.** In the mini-prompt of the outbound direction (RULES-124937, rubric 4), the prohibition "no deletion" becomes "no deletion; move to `_trash/` only on the Mission's prescription". A snippet from the Pilot never asserts that an Owner gesture — push, deletion, emptying of `_trash/` — has taken place: it asks the Executor to measure it, STOP if absent. In the return direction, when a reserved gesture blocks a Mission, the « À trancher » rubric names the exact path and the available substitute (move to `_trash/`), and the Executor stops with no attempt at a workaround and no second tool: a refusal of this class is structural, repeating it is a wasted window. The Pilot, on receipt, executes the move itself or has it prescribed, without relaunching on an unmeasured fact.

**6. Options set aside.** Workaround by guardian override or `--no-verify` — moot, the refusal is not a guardian of the repository but the agent's policy; "the Owner always deletes" (S1) — true in principle but produced two resumes blocked on a fact announced and not done, hence the preference for the measurable substitute (S2); letting both copies coexist (S3) — contrary to the goal of the enveloping.

## Reason

Mission 087: the Executor attempted the deletion of the enveloped source file through two distinct tools and twice received the same verbatim refusal, classed "Permanently deleting data" in a category that the agent's system policy never executes, whatever authorization is received. Two resumes launched on a snippet asserting the Owner deletion rightly blocked (file still present, same fingerprint). The move by the Pilot to `_trash/` unblocked the Mission in one turn, with proof of identity and of absence. Owner arbitration: « s2 », 2026-08-29.

The lesson is of the same family as the delegated push (DECISION-154553 and amendments): a gesture the agent cannot perform must be engraved as an Owner gesture, with its measurable substitute, otherwise every Mission that meets it rediscovers the wall.

## Impact

- The Vault's `AGENTS.md`: the line « human gate pour tout push, suppression importante… » ["human gate for any push, significant deletion…"] now distinguishes the gestures reserved to the Owner (push, permanent deletion) from the gestures under a human gate (structuring rename, sensitive sharing).
- Relay rule §outbound rubric 4 and §return: wordings of §5 above.
- Role charter §2: "deletion" stays forbidden to the Pilot; "move to `_trash/`" is explicitly allowed as a bounded write.
- Role charter §3: « aucune suppression sans human gate » ["no deletion without a human gate"] becomes « aucune suppression, même sous human gate ; déplacement vers `_trash/` sur prescription de Mission » ["no deletion, even under a human gate; move to `_trash/` on a Mission's prescription"].
- Mission template: comment in the Steps section recalling §4 above.
- The reciprocal `amended by` links are placed in the three amended documents, in the same commit as this Decision (RULES-115658), by the Executor of the tidying Mission.
- The `_trash/` folder has existed since 2026-08-29 at the root of the workspace, outside the repositories `vault` and (workshop history, not distributed).

## Human gate

- Validation: granted
- Reference: « s2 » then « on continue » ["we carry on"] (N1 — engrave first), Owner, 2026-08-29.

## Linked artefacts

- Reports of Mission 087 (the workshop (history, not distributed), outside the Vault): REPORT-2026-08-29-011726-087-second-audit-enveloping-STOP.md (verbatim refusal, two tools), REPORT-2026-08-29-013432-…-resume-STOP.md and REPORT-2026-08-29-103907-…-resume2-STOP.md (resumes rightly blocked), REPORT-2026-08-29-105604-…-completion.md (measured move, completion).

## Liens

- `amends` — [Role charter and session determination](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `amends` — [Mission template](../templates/mission-template.md)
- `amends` — [Relay between roles through mini-prompts with fixed rubrics](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `applies` — [Instructions for agents](../AGENTS.md)
- `see also` — [Decision — The amendment lives in the repository of the amended document](./DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md)
