---
type: rules
title: "Operating rules of the central Vault"
created_at: 2026-08-17T00:57:17-04:00
timezone: America/Montreal
status: active
---

# VAULT OPERATING RULES

## 1. Perimeter

The Vault keeps only the cross-cutting knowledge and mechanisms needed for working with AI. Its canonical architecture is defined in the [Decision on the central Vault](../decisions/DECISION-2026-08-17-003000-vault-central-architecture.md).

External projects keep their business context, their objectives, their state, their decisions and their artefacts. The workshop's production also stays outside the Vault.

## 2. Source of truth

- versioned files are the source of truth;
- read the sources and their links before modifying;
- a generated output does not become canonical without validation;
- a file must carry one main idea and enough context to be understood on its own.

## 3. Language and naming

- prose and explanations: French;
- machine identifiers, slugs, keys and folder names: idiomatic English;
- dated artefacts: `TYPE-YYYY-MM-DD-HHMMSS-description.ext`;
- timestamp to the second in the `America/Montreal` time zone;
- description as an English slug, without accents or spaces.

## 4. Decisions

- record every structuring decision with its date, its status, its reason and its impact;
- explicitly distinguish decisions, proposals, hypotheses and unverified elements;
- never silently turn a proposal into a decision;
- do not automatically raise a decision specific to a project into the Vault.

## 5. Capitalizing from projects

A lesson discovered in a project may be proposed to the Vault only if it can be generalized. Its integration requires prior human validation, in accordance with the [operating model](../_trash/BRIEF-2026-08-17-003000-vault-concept-operating-model.md) (withdrawn from distribution, kept for historical reference).

## 6. Git

- inspect each file before staging;
- stage file by file;
- inspect the staged diff before commit;
- produce small, coherent commits with an explicit message;
- never push automatically;
- require a human gate before any push or sensitive commit.

## 7. Security

- no secret, token, password, credential or private key in tracked files;
- do not share sensitive data without human validation;
- check files before commit.

## 8. Graphify

- Graphify helps find what is written; it does not invent an absent decision;
- favour Markdown and explicit relative links;
- use `.graphifyignore` (supprimé, Mission 040) to exclude noise;
- never manually edit `graphify-out/` (supprimé, Mission 040);
- consider no merging of the graphs as settled before testing and validation.

## 9. Sensitive actions

A human gate is required before:

- push or creation of a remote;
- a significant deletion;
- a structuring rename;
- a change of source of truth;
- integration of an improvement coming from a project;
- sharing sensitive data.

## 10. Freezing the existing stock

A new naming rule triggers no retroactive mass renaming. Any migration must be an explicit, inventoried and verified work item.

## Liens

- `amended by` — [Decision: PIV taxonomy, English system language, role charter, end of PROMPT, §3 language](../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md)
