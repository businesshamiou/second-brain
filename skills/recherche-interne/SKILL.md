---
name: recherche-interne
description: "Search the Vault and the project corpus by discipline: indexes and description fields first, then exact grep or glob, and never assert a path that was not measured. Use when looking for a document, a rule, a decision, a term, or when asked where something lives. Triggers on: « où est », « trouve », « cherche dans le Vault », « quel fichier », \"where is\"."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md, (historique de l'atelier, non distribué)"
  vault-validated: "2026-09-07T20:31:20-04:00"
---

Searches the Vault and a project's corpus **by discipline, not by engine** (DECISION-144931 §6a, Mnemosyne study: wire up the existing rather than tool up anew). Two surfaces: Pilot (MCP `read_text_file`, `search_files`, `get_file_info`) and Executor (shell: `cat`, `grep`, `find`, the Vault's `tools/find-in-vault.sh`). This skill **writes nothing**: it returns measured paths, or "not found". The four steps are run in order, none is skipped.

**Precedence.** The entry chain required by the surface (`VAULT-ROOT.md` walked up to, then the charter) is read **before** any search and does not count as a search reading; it never exempts from §1, whose **first search reading is an index**, never a `grep`. Neither of the two rules cancels the other (Mission 153, gap measured in report 152).

## 1. Index first — progressive disclosure

Open the `index.md` of the root concerned, at the root of the Vault (`index.md`, `rules/index.md`, `decisions/index.md`, `skills/index.md`, `knowledge/index.md`, `templates/index.md`, `projects/index.md`, …) or of the current project, and read the `description` field of each entry. `skills-warehouse/` follows its own convention (a single native `index.md` at `skills-warehouse/skill-collections/index.md`, not one per folder): look for it there, not elsewhere in that subtree. Note the candidates: exact file name as listed, one line of reason. Go down into a file only after the index: it is the index that says what exists.

## 2. Then exact pattern

On the candidates and on the corpus: `search_files` (glob on the name) or `grep` (exact pattern on the content, `grep -rn -- '<motif>' <racine>`), with the exclusions `.git`, `node_modules`, and `skills/` unless the skills are the target (the external library is adopted material, not normative corpus). A pattern is **exact**: what you typed, not an approximation presented as such. Zero results is said "0 results for `<motif>` in `<racine>`", never "nothing relevant".

## 3. Go up to the version in force

For any document found, read its `## Liens` section: an `amended by` or `superseded by` line designates a more recent document — follow it to the last one, and check the root's `superseded-files.txt`. The version in force is the one you return; the superseded version is named as such (fault "reading of a superseded document", Pilot contract point 4: a document marked superseded is not a source).

## 4. Return measured paths

The output is a list: one path per line, relative to the workspace, each **measured** (`get_file_info` succeeded, or appeared in a real listing), one line of reason, and the mention "in force" / "superseded by …" (DECISION-212009: a path is MESURÉ or is not). A path reconstructed from memory is never returned. What was not found is said as it is: "not found: `<terme>` — indexes read: …, patterns tried: …".

## What this skill does not do

Web search (`research`, external library) · image search (no skill, rules in place) · writing, filing, commit · summary in place of the document (it returns the address, not the content) · assertion of an unmeasured path.

## Liens

- `applies` — Decision — End of the skills V1 pass (workshop history, not distributed) (hors Vault)
- `applies` — [Decision — Evidence status and STOP control](../../decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `applies` — Note — Mnemosyne: retrieval against the real Vault (workshop history, not distributed) (hors Vault)
- `see also` — [Standard for links between documents](../../rules/RULES-2026-08-21-115658-document-linking-standard.md)
