---
type: rules
title: "Standard for links between documents"
description: "(workshop history, not distributed)"
created_at: 2026-08-21T11:56:58-04:00
timezone: America/Montreal
status: active
scope: document-linking-standard
---

# STANDARD FOR LINKS BETWEEN DOCUMENTS

## 1. Reach

Every document of the Vault and of (workshop history, not distributed) (rule, decision, capture, proposal, current state, handoff, brief, mission, prompt, report, project sheet) carries at least one link to another document. [source: Zettelkasten] [measure: Mission 021]

## 2. Two places

The link appears in context, in the sentence that states the relation, **and** in a final `## Liens` section that recaps it with its type. [source: adr-tools writes the link under the Status and the typed relation; MADR "More Information"] [choice: the name "Liens"]

## 3. Form

A link is written `[titre lisible](chemin relatif)`; the path is relative to the file's location; never an absolute path, never a bare name, never an identifier in backticks alone. A mention by name without a link does not count. [measure: Missions 021-022, this is what the tool reads]

## 4. Closed vocabulary of types

Each entry of the `## Liens` section carries one type among the six below, in English. No other type without an amendment of this rule. [source: adr-tools "Supersedes / Amends"] [choice: the list retained] [amends: Decision — doctrinal arbitrations of 2026-08-25, point 4, anglicization carried out by Mission 054]

## 5. Inverse link

`supersedes` and `amends` require the inverse line in the target (`superseded by`, `amended by`) in the same commit. [source: adr-tools always writes the back link]

## 6. Outside the corpus

A link to the other repository is written all the same, suffixed `(hors Vault)` or (workshop history, not distributed); it documents the relation without producing an edge in the graph. [choice]

## 7. Front matter

The fields `supersedes`, `amends`, `sources`, `related_mission` remain and must be consistent with the `## Liens` section; they complement it, they do not replace it. [source: OKF `sources`] [measure: Mission 021, front matter PARTIEL]

## 8. Templates

Each template carries the `## Liens` section pre-filled with at least the `prescribed by` line pointing to the rule that prescribes it. [measure: Mission 021, no template linked]

## 9. Machine verification

The pre-commit check `tools/check-links.sh` applies to every new or modified `.md` outside `graphify-out/` (supprimé, Mission 040): missing `## Liens` section → blocking; broken relative link → blocking; no internal relative link → warning, not blocking. [choice: the blocking/warning split]

## 10. Human verification

The Pilot review covers the right link type and the presence of the link in context, beyond what `tools/check-links.sh` can measure. [choice]

## 11. Retroactivity

Existing documents without links are not touched up on the fly; they are corrected by a dedicated Mission, starting from Mission 021's map of missing links. [choice]

## 12. Anchoring

A line in `AGENTS.md` points to this rule. [established practice: execution report, runbook]

## Vocabulary of types

System keywords in English without exception, aligned with the front matter that is already in English (`supersedes`, `amends`) — [Decision — doctrinal arbitrations of 2026-08-25](../decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md), point 4. The French vocabulary above is **withdrawn**; the historical correspondence is kept as a note for reading the corpus prior to the migration (Mission 054).

| Type | Definition | Inverse |
|---|---|---|
| `applies` | the document implements a cited rule or decision | — |
| `supersedes` | the document makes the target obsolete; the target ceases to be a source of truth | `superseded by` (mandatory in the target) |
| `amends` | the document partially modifies the target, which remains in force for the rest | `amended by` (mandatory in the target) |
| `source` | the document relies on the target as a foundation or evidence | — |
| `prescribed by` | the document is a template or an artefact governed by the cited rule | — |
| `see also` | informative relation without normative dependency | — |

**Historical correspondence** (withdrawn, for reading the corpus prior to Mission 054 only):

| French (withdrawn) | English (canonical) |
|---|---|
| `applique` | `applies` |
| `remplace` | `supersedes` |
| `amende` | `amends` |
| `source` | `source` (unchanged) |
| `prescrit par` | `prescribed by` |
| `voir aussi` | `see also` |
| `remplacé par` | `superseded by` |
| `amendé par` | `amended by` |

## Example

Fictitious five-line document, link in context and then the `## Liens` section:

```markdown
# NOTE — Example

This note applies the [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md) to a fictitious case.

## Liens

- `applies` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
```

## Liens

- `applies` — [Vault operating rules, §8](./RULES-2026-08-17-005717-vault-operating-rules.md)
- `source` — Proposal: links standard (workshop history, not distributed) (hors Vault)
- `see also` — [Vault installation runbook](../_trash/runbook-vault-setup.md) (withdrawn from distribution, kept for historical reference)
- `amended by` — [Decision — Scoping the links standard to the corpus](../decisions/DECISION-2026-08-28-203627-link-section-requirement-scoped-to-corpus.md)
- `amended by` — Decision — Outgoing links to another repository (workshop history, not distributed) (hors Vault)
