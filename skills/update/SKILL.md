---
name: update
description: "Update an installed Second Brain to a published version without reinstalling: fetch the version, merge it over the participant's own commits (profile, identity, projects, indexes kept), regenerate the indexes, refuse cleanly on a conflict or an identity change. Use when the participant wants the new version, or when the published line says Second Brain is already installed. Triggers on: « mets à jour second-brain », « mise à jour », « nouvelle version », \"update second-brain\", \"update\", \"new version\"."
license: "MIT"
metadata:
  vault-implements: "decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md, (historique de l'atelier, non distribué)"
  vault-validated: "2026-09-18T18:00:00-04:00"
---

Brings an installed Second Brain to a published version. Receiving a version is a **merge** of the published tag into the installed clone, never a copy of files and never a reinstallation: the participant's own commits — `USER.md`, `VAULT-IDENTITY.md`, project sheets and registry, indexes — stay. **Executor surface only** (shell and Git). The tool is `tools/second-brain-update.sh`; this body does not paraphrase it.

## 1. Measure before anything

From the installed Vault (`<workspace>/second-brain`): `git status --porcelain` must be empty (uncommitted work is committed or set aside first — the tool refuses otherwise); `git remote get-url origin` must be the published repository; the version wanted is a published tag (`git ls-remote --tags origin`). Say what was measured.

## 2. Run the update

- Installation at **v0.1.8 or later**: `bash <workspace>/second-brain/tools/second-brain-update.sh <version>` (Windows: `powershell -File <workspace>\second-brain\tools\second-brain-update.ps1 <version>`).
- Installation at **v0.1.7 or earlier** (the tool is not there yet): run the published line of the new version (INSTALL.md). It fetches the version into a temporary folder, sees the existing installation and prints the exact update command, which runs the new version's tool with `--vault <workspace>/second-brain`.

The last line is a closed verdict: `VERDICT: UPDATED`, `VERDICT: UP-TO-DATE` or `VERDICT: REFUSED`.

## 3. Read the verdict

- `UPDATED`: one merge commit named `Update to second-brain <version>`; the indexes regenerated; the identity (`vault_id`) unchanged; the projects untouched (their birth certificates keep `vault_ref`, which records their birth). If the message says the MCP server may have changed, run `tools/install-vault-mcp.sh <workspace>` again and restart the Claude app.
- `UP-TO-DATE`: nothing was changed.
- `REFUSED`: nothing was changed, HEAD is where it was. The message names the cause: uncommitted changes, a conflict with local edits of corpus files (named), an identity that would change, a guardian's refusal, or an installation older than v0.1.4 (its origin is the installer's temporary folder: such an installation is reinstalled in a new folder, it cannot be updated).

## What this skill does not do

Push · touch a project, the profile or a tool configuration · resolve a conflict by hand · force anything (`--force`, `reset`) · update an installation whose origin is a temporary folder.

## Liens

- `applies` — [Decision — Project initiation and adoption, birth certificate](../../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `see also` — [Install guide](../../INSTALL.md)
- `see also` — [First install](../first-install/SKILL.md)
