---
type: marker
title: "{{VAULT_NAME}} — working-root marker"
description: "Marker found by walking up: identifies the working root and locates the Vault from any project folder."
status: active
generated_by: tools/write-marker.sh
---

# {{VAULT_NAME}}

Working-root marker. A file placed here lets any project folder
find the Vault again by walking up the parent folders until it
finds it — same principle as detecting a Git repository by its
`.git` folder. [arbitration: Decision seven arbitrations of 2026-08-23, §1]

## Role contract

- **What it contains**: what is cross-cutting — rules, decisions, templates, durable knowledge, tooling common to all sibling projects.
- **What it does not do**: it carries no personality (voice, tone, way of answering); it stores no secret, key or credential; it does not replace the context specific to each project.
- **How it is queried**: by direct reading of the linked files (path cited, never an assertion without a source); by `tools/find-in-vault.sh` for search by content; by the state sheet of the current project (`<projet>/state/STATE.md`, generated; the path its Pilot prompt names by `state_path`).
- **How it is fed**: only by a Mission executed in the Vault — or, for a non-structuring change, by a prompt of the Owner traced by an execution Note (mode 2, Decision of 2026-09-23 on the two relay modes); every structuring decision goes through a Decision set in stone in `decisions/`, never by direct writing outside a Mission. **Clarification (2026-08-26, Mission 066)**: this feeding goes through the Executor on a Mission, from an opening position that is now free — "A session may open anywhere in the workspace, and typically opens in the folder of the project under development" (Decision — Opening directory of a session, 2026-08-25, point 2; quoted, translated from French); the Pilot, who "now writes its new artifacts directly at their canonical location, after announcing the door" (Decision: PIV taxonomy and English system language, §A5; quoted, translated from French), thereby deposits into the artifact folders of the current project — never into the Vault.

## Location

The field lines below keep their French labels, which tools read exactly as written (relative path of the Vault from this working root; identity of the Vault; origin of the Vault; declared temporary folder; organs declared at this root; provisional exceptions at this root).

Chemin relatif du Vault depuis cette racine de travail : `{{VAULT_RELATIVE_PATH}}`

Identité du Vault : `{{VAULT_ID}}`

Origine du Vault : `{{VAULT_ORIGIN}}`

Dossier temporaire déclaré : `{{TMP_DIR}}`

Organes déclarés à cette racine : `{{ORGANS}}`

Exceptions provisoires à cette racine : `{{EXCEPTIONS}}`

The declared temporary folder holds every throwaway file of the tooling, outside this working root (`tools/lib/tmp.sh`). The root of this working folder holds only what the computed whitelist allows: this marker and its two guides (`CLAUDE.md`, `AGENTS.md`), the Vault, the projects and group folders of the registry, the organs named above, `_trash`, `_archive` and `_orders`; a provisional exception is named, not a gap (`tools/check-workspace-root.sh`, rule on workspace hygiene, project names and session types). `-` means none.

A project names its Vault through its birth certificate (`vault_id` in `.pre-commit-config.yaml`); this marker resolves on its own only if there is a single candidate Vault in this workspace.

---

Generated automatically by `tools/write-marker.sh` from this template. Do not edit `VAULT-ROOT.md` by hand: regenerate it.

## Liens

- `prescribed by` — [Seven session arbitrations of 2026-08-23](../decisions/DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
- `amended by` — [Decision — Project initiation and adoption, birth certificate](../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `amended by` — [Decision — State sheet, one name, generated](../decisions/DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md)
- `amended by` — [Decision — Two relay modes](../decisions/DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md)
- `amended by` — [Rule — Workspace hygiene, project names and session types](../rules/RULES-2026-09-26-112218-workspace-hygiene-project-names-session-types.md)
