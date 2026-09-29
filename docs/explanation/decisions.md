---
type: explanation
title: "Decisions"
description: "What a Decision is in Second Brain, how its status and its amendments work, where Decisions live and how their index is built, and which Decisions govern the things a participant meets most."
status: active
---

# DECISIONS

This page explains what a Decision is, why it is never rewritten, where to find one, and which Decisions you will meet most often, grouped by theme.

## What a Decision is

A Decision records a structuring choice together with its explicit arbitration by the Owner ([context cycle V2](../../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md), §4). The glossary puts it in one line: a recorded and dated choice that is authoritative ([CONTEXT.md](../../CONTEXT.md)).

It sits in a cycle: work, then a capture if durable knowledge appears, a proposal if an important option must wait for an arbitration, a Decision when the choice is arbitrated, then the state and, if needed, a handoff (cycle V2, §7). Three consequences follow:

- **A proposal never becomes a Decision in place.** An accepted proposal keeps its status; a new Decision is created that references it, and both histories stay (cycle V2, §3). [AGENTS.md](../../AGENTS.md) says the same: record every structuring decision explicitly, never silently turn a proposal into a decision.
- **Only a rule or a Decision binds.** A capture is never a norm; a practice that lived only in a capture was revoked for that reason ([Decision 220049](../../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md), A5).
- **Doctrine exists once.** Rules, Decisions and templates live in the Vault in a single copy, never duplicated into a project ([Decision 214607](../../decisions/DECISION-2026-08-24-214607-transverse-mechanism-distribution.md), D1). A project keeps its own business decisions in its own folder, and the Vault never imports them automatically ([AGENTS.md](../../AGENTS.md); cycle V2, §8).

The Pilot drafts Decisions: `decisions/` is one of the artefact folders it may create in ([Decision 232341](../../decisions/DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md), §3.1). In the Vault, changing doctrine (a Decision, a rule, a template) always goes through a Decision and the full regime, even when the Owner asks for the work directly ([Decision 012500](../../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md), point 7).

## Its shape and its status

The [Decision template](../../templates/decision-template.md) sets the sections: Date, Status, Decision, Reason, Impact, Important alternatives, Human gate (validation and the reference that proves it), Related artifacts, then `## Liens`. Recent Decisions add a "Measured problem" section before the Decision itself.

| Status | Meaning |
|---|---|
| `PROPOSED` | The template's starting value. A structuring decision stays here until a human gate arbitrates it ([AGENTS.md](../../AGENTS.md); cycle V2, §4). |
| `ARBITRATED` | The Owner has arbitrated; the Human gate section names the proof (often the Owner's words, quoted). The front matter writes it `ARBITRATED` in older files and `arbitrated` in newer ones. |
| `active` | Some Decisions carry this value instead; the index copies it as written. |

## Why a Decision is never rewritten: amends and amended by

The body of an arbitrated Decision is never rewritten. When a later choice changes it, the old Decision receives a **dated annotation** at the exact place of the changed rule, naming the amending Decision; the amending Decision carries `amends` in its front matter and its `## Liens`, and the amended one receives `amended by` ([Decision 145256](../../decisions/DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md), point 3). Rewriting would erase what was arbitrated and when; the annotation keeps the history and flags the change at the spot. The reciprocal pair is what makes the change visible to the links guardian.

A Decision that replaces a document outright uses `supersedes` instead; for example, [Decision 012458](../../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md) supersedes the old current-state template. The six relation types (`applies`, `supersedes`, `amends`, `source`, `prescribed by`, `see also`) come from the [links standard](../../decisions/DECISION-2026-08-21-115658-document-linking-standard.md).

An amending Decision lives in the repository of the document it amends; if it must amend documents in two repositories, it is split in two ([Decision 205904](../../decisions/DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md)). The Vault is distributed alone, so its amendment chains must stay whole inside it.

**How to read one.** Open its `## Liens` first. An `amended by` line means part of it no longer holds as written: read the amending Decision, then the annotation it left. The chain on delegated pushes is a good example: [154553](../../decisions/DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md) set a fixed authorization formula, [231617](../../decisions/DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md) and [112528](../../decisions/DECISION-2026-08-27-112528-delegated-push-exception-covers-its-journal-commit.md) amended it, and [201623](../../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md) replaced the formula with a clear expression of the Owner.

## Where they live

- **The folder.** Every Vault Decision is a file in `decisions/`, named DECISION-, then the date and time of its creation, then a short slug. Documents cite a Decision by the time part of its name: "Decision 012458" is the file that begins DECISION-2026-09-23-012458. Two Decisions share the time 115306 (the OKF format and the project registry), so check the slug when the number is ambiguous.
- **The live index.** `decisions/index.md` is generated by `tools/build-indexes.sh`, never edited by hand. Each line is a locator: identifier, status, short title, file name, and no description ([Decision 124647](../../decisions/DECISION-2026-09-05-124647-index-as-locator-8000-cap-live-archive.md), point 1). It lists the most recent entries.
- **The archives.** Everything is also listed in frozen archives, one per month: `decisions/index-archive-2026-08.md` and `decisions/index-archive-2026-09.md`. An archive's entries never change (Decision 124647, point 4).
- **How to search.** An index is read by searching for a line, never in full (Decision 124647, point 6). Search the index for a word of the title, then open the file it names.

## A guided index, by theme

One line per Decision: what it governs today. Where a Decision has been amended, the line says so. A Decision with several points may appear under two themes, each time for a different point.

### Roles and relay

| Decision | What it governs |
|---|---|
| [220049](../../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md) | The plan / implement / validate activity types; a session finds its role through three rungs (startup hook, shell probe, declaration), and in doubt is the Pilot; no more PROMPT files: Mission, then mini-prompt, then RELAY block. |
| [124937](../../decisions/DECISION-2026-08-23-124937-role-relay-mini-prompts.md) | Adopts the relay rule: a mini-prompt on the way to the Executor, a RELAY block at the end of its report on the way back. |
| [213150](../../decisions/DECISION-2026-08-25-213150-session-opening-directory-freed.md) | A session may open anywhere in the workspace; what it must know is where it is and which repository each Git gesture targets. |
| [000236](../../decisions/DECISION-2026-08-21-000236-execution-report-channel.md) | Every execution report is a file in the project's `<project>/reports/` folder, committed with the work it proves; in chat, only its path and the gates line. Naming amended by 145256. |
| [012500](../../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md) | Two relay modes: the Mission, or the Owner's own prompt traced by an execution Note written first; a missing Mission is never a reason to refuse, and the list of refusal reasons is closed. |
| [105507](../../decisions/DECISION-2026-09-23-105507-owner-greenlight-in-note-and-local-language-file.md) | When an Owner's prompt meets a full-regime criterion, the Executor asks, and the Owner's answer is quoted word for word in the Note, which `tools/check-work-regime.sh` checks. |
| [212009](../../decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md) | Every line put to the Owner for arbitration says whether it is measured, a hypothesis or a judgement; a Mission built on a hypothesis carries a named STOP before the write. |
| [230604](../../decisions/DECISION-2026-09-03-230604-one-mcp-window-per-workspace-skills-fully-exposed.md) | One filesystem MCP server per workspace, rooted at the whole workspace, is every chat session's only window onto files; the chat session sees the whole list of skills. |

### Pushes and deletion

| Decision | What it governs |
|---|---|
| [201623](../../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md) | Push is an Owner gesture that the Owner may delegate to an Executor by any clear expression naming the gesture and its target; `main` and a named tag are separate; the RELAY block is defined once, with a pushes rubric. |
| [154553](../../decisions/DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md) | Where delegated push began: a fixed, dated authorization line. The formula is gone (amended by 201623); `main` only and never `--force` remain. |
| [231617](../../decisions/DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md) | One authorization covers one gesture; a gesture merged into the same sentence is never inferred. The principle survives 201623. |
| [112528](../../decisions/DECISION-2026-08-27-112528-delegated-push-exception-covers-its-journal-commit.md) | A delegated push also covers committing its own journal line, and nothing else. |
| [110852](../../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md) | No agent deletes a file permanently, even under a human gate; the agent moves it to `<workspace>/_trash/`, which only the Owner empties. |

### State sheet and journal

| Decision | What it governs |
|---|---|
| [012458](../../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md) | The state sheet is `<project>/state/STATE.md`, generated by `tools/build-state.sh` from the journal, never edited by hand; `tools/build-digest.sh` makes its capped extract; both exist from the project's birth. |
| [124848](../../decisions/DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md) | Points 2 and 4: the sheet is a generated catalogue, not a summary; the state is kept in an append-only journal that the Pilot feeds and never rewrites. |
| [143542](../../decisions/DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md) | The seven-line Pilot contract, whose single source is `templates/pilot-contract-template.md`; search marks superseded files; the journal tags are ratified. |
| [110935](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md) | Open points are keyed doors: `OPEN:` with a key, closed by a later `CLOSE:` with the same key; the sheet shows the net. |
| [191407](../../decisions/DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md) | A journal or Mission-index line is a pointer of at most 300 characters; the detail lives in the file it names. |
| [124647](../../decisions/DECISION-2026-09-05-124647-index-as-locator-8000-cap-live-archive.md) | An index line is a locator; each index is capped at 8,000 bytes; large indexes split into live and archive. |

### Projects and birth certificate

| Decision | What it governs |
|---|---|
| [000545](../../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md) | A project names its Vault in a birth certificate with a checked identity, never by proximity; `tools/project-bootstrap.sh` has `create` and `adopt` modes; an initiation order allows adoption without a Mission; a Pilot prompt per project. Project instructions amended by 201623. |
| [210731](../../decisions/DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md) | A project knows the Vault through three tiers of files (machine, workspace marker, project); adoption adds what is missing without touching content, and reorganizing is only proposed. Its unconditional stop is amended by 000545. |
| [232341](../../decisions/DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md) | The project standard of seven functions (identity, rules, state, execution, arbitration, material, handover), the test for what belongs in the Vault, and the Pilot's per-folder write rights. |
| [115306 (registry)](../../decisions/DECISION-2026-08-19-115306-project-registry-v1.md) | The project registry: the Vault knows a project's address, not its content; nobody edits the registry by hand. |

### The assistant

| Decision | What it governs |
|---|---|
| [232720](../../decisions/DECISION-2026-09-23-232720-assistant-reads-documentation-map-first-lightest-model.md) | The assistant carries the table of `docs/MAP.md` and reads the page it names first; its Claude Code form runs on `haiku`; the cap of 8 tool calls stays. A new documentation page goes into the map in the same commit. |
| [124848](../../decisions/DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md) | Point 5: the Vault's identity is a name ("Brian") plus a role contract; a personality was set aside. |

### Language

| Decision | What it governs |
|---|---|
| [012459](../../decisions/DECISION-2026-09-23-012459-owner-language-recorded-rendered-fixed-sentence.md) | Your language is recorded once in `USER.md`, rendered in each project's Pilot prompt, and a fixed sentence in the common prompt makes a Pilot speak the language you write in from its first line; never English by default. |
| [105507](../../decisions/DECISION-2026-09-23-105507-owner-greenlight-in-note-and-local-language-file.md) | Point 4: a local file, USER.local.yaml, never versioned nor distributed, is read before `USER.md`. |
| [220049](../../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md) | A2 and A3: every system keyword (command, tag, status, field) is in English, and so is the journal. |

### Publication and distribution

No Decision in `decisions/` governs the publication command itself: that is set by the [rule on absolute paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md), §2 point 4, and described in [Publishing](../how-to/publish.md). These Decisions shape what is distributed:

| Decision | What it governs |
|---|---|
| [124848](../../decisions/DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md) | Point 7: a skeleton package plus a removable model project; the laboratory's real history is never installed at a participant's. |
| [205904](../../decisions/DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md) | Point 4: because the Vault ships alone, every amendment chain must stay inside it. |
| [005041](../../decisions/DECISION-2026-09-02-005041-cross-repo-links-checked-only-when-target-repo-present.md) | A link to another repository is marked and checked only when that repository is on disk; in the standalone package it only warns. |
| [105507](../../decisions/DECISION-2026-09-23-105507-owner-greenlight-in-note-and-local-language-file.md) | Point 4: `tools/check-distribution-manifest.sh` refuses the local language file. |

### Guardians

| Decision | What it governs |
|---|---|
| [214607](../../decisions/DECISION-2026-08-24-214607-transverse-mechanism-distribution.md) | A check has one implementation, consumed by a project at a pinned version; test: a project cloned alone on a new machine still applies its rules. |
| [220049](../../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md) | A8: preflight stamp, pre-commit wall, deny by default, and a threat model against accidents, not evasion. |
| [115658](../../decisions/DECISION-2026-08-21-115658-document-linking-standard.md) | The links standard: a `## Liens` section and typed links, checked at commit by `tools/check-links.sh`. |
| [203627](../../decisions/DECISION-2026-08-28-203627-link-section-requirement-scoped-to-corpus.md) | The `## Liens` requirement covers the Vault's corpus, not adopted external skills; broken links are refused everywhere. |
| [154756](../../decisions/DECISION-2026-09-04-154756-mission-preflight-step-zero.md) | A Mission that commits an artefact filed by the Pilot starts with step 0: it runs every applicable check on its scope, reports all violations at once, and stops before any commit if one remains. |

The Decisions on the shape of a Mission are explained in [the Mission lifecycle](mission-lifecycle.md). The others (Graphify, the skills library, the memory benchmark, the laboratory's migration) are building history; find them through `decisions/index.md` and its archives.

## Liens

- `source` — [Context cycle V2](../../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `source` — [Instructions for agents](../../AGENTS.md)
- `source` — [Glossary](../../CONTEXT.md)
- `source` — [Decision template](../../templates/decision-template.md)
- `source` — [Decisions index](../../decisions/index.md)
- `source` — [Decisions index, archive 2026-08](../../decisions/index-archive-2026-08.md)
- `source` — [Decisions index, archive 2026-09](../../decisions/index-archive-2026-09.md)
- `source` — [Rule — absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Assistant identity](../../assistant/ASSISTANT.md)
- `source` — [Decision 220049](../../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md)
- `source` — [Decision 124937](../../decisions/DECISION-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Decision 213150](../../decisions/DECISION-2026-08-25-213150-session-opening-directory-freed.md)
- `source` — [Decision 000236](../../decisions/DECISION-2026-08-21-000236-execution-report-channel.md)
- `source` — [Decision 012500](../../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md)
- `source` — [Decision 105507](../../decisions/DECISION-2026-09-23-105507-owner-greenlight-in-note-and-local-language-file.md)
- `source` — [Decision 212009](../../decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `source` — [Decision 230604](../../decisions/DECISION-2026-09-03-230604-one-mcp-window-per-workspace-skills-fully-exposed.md)
- `source` — [Decision 201623](../../decisions/DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
- `source` — [Decision 154553](../../decisions/DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)
- `source` — [Decision 231617](../../decisions/DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md)
- `source` — [Decision 112528](../../decisions/DECISION-2026-08-27-112528-delegated-push-exception-covers-its-journal-commit.md)
- `source` — [Decision 110852](../../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
- `source` — [Decision 012458](../../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md)
- `source` — [Decision 124848](../../decisions/DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
- `source` — [Decision 143542](../../decisions/DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md)
- `source` — [Decision 110935](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
- `source` — [Decision 191407](../../decisions/DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)
- `source` — [Decision 124647](../../decisions/DECISION-2026-09-05-124647-index-as-locator-8000-cap-live-archive.md)
- `source` — [Decision 000545](../../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `source` — [Decision 210731](../../decisions/DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md)
- `source` — [Decision 232341](../../decisions/DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md)
- `source` — [Decision 115306, project registry](../../decisions/DECISION-2026-08-19-115306-project-registry-v1.md)
- `source` — [Decision 232720](../../decisions/DECISION-2026-09-23-232720-assistant-reads-documentation-map-first-lightest-model.md)
- `source` — [Decision 012459](../../decisions/DECISION-2026-09-23-012459-owner-language-recorded-rendered-fixed-sentence.md)
- `source` — [Decision 205904](../../decisions/DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md)
- `source` — [Decision 145256](../../decisions/DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)
- `source` — [Decision 005041](../../decisions/DECISION-2026-09-02-005041-cross-repo-links-checked-only-when-target-repo-present.md)
- `source` — [Decision 214607](../../decisions/DECISION-2026-08-24-214607-transverse-mechanism-distribution.md)
- `source` — [Decision 115658](../../decisions/DECISION-2026-08-21-115658-document-linking-standard.md)
- `source` — [Decision 203627](../../decisions/DECISION-2026-08-28-203627-link-section-requirement-scoped-to-corpus.md)
- `source` — [Decision 154756](../../decisions/DECISION-2026-09-04-154756-mission-preflight-step-zero.md)
- `see also` — [Roles and Missions](two-roles.md)
- `see also` — [The Mission lifecycle](mission-lifecycle.md)
- `see also` — [Guardians](guardians.md)
- `see also` — [The assistant](assistant.md)
- `see also` — [Delegate and push](../how-to/delegate-and-push.md)
- `see also` — [Publishing](../how-to/publish.md)
- `see also` — [Glossary](../reference/glossary.md)
