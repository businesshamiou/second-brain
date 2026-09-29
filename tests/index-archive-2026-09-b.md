---
type: index
title: "Vault tests — archive 2026-09 (b)"
description: "Frozen part of the tests index, second slice: the families of Missions 192, 198, 199 and 201 (Mission 219), then 206, 209, 214-217 and 218 (Mission 222), then 219 (Mission 231), moved out of tests/index.md each time it reached its 8,000-byte cap; the first slice is full."
created_at: 2026-09-23T11:25:00-04:00
timezone: America/Montreal
status: active
---

# Vault tests — archive 2026-09 (b)

Frozen. The live index is [`index.md`](./index.md); the first slice is [`index-archive-2026-09.md`](./index-archive-2026-09.md).

### Publishing from the laboratory — Mission 192 (v0.1.9)

- `test-publish-from-laboratory.sh` (W / U / M) — one command publishes the laboratory as a fast-forward, the closed list kept from `release`; second run: nothing to publish; third-party advance and a widening argument refused.
- `test-private-patterns-lab-exemption.sh` (U) — `projects/` exempt in a laboratory only; never on `publish`, never outside `projects/`.
- `test-workshop-gitignore-links.sh` (U) — an existing `.gitignore` given the three link exclusions gets its links; `git status` shows none.
- `test-backup-oracle.sh` (U) — a bundle is proven by restoring it; a truncated pack fails where `git bundle verify` passes.

### Publishing, the check before every push — Mission 198

- `test-publish-private-check-before-push.sh` (W / U / M) — the private-pattern check runs once before every push of the publication tool, also when `publish` is already ahead of `release` with nothing to commit; a private pattern is refused on both paths, a clean tree is published on both, a laboratory already published is left alone.

### Two work regimes — Mission 199

- `test-check-work-regime.sh` (W / U / M) — the work-regime check refuses a gesture that meets a full-regime criterion (push to the published repository, deletion, doctrine, refs, company repository, guardians) and the Note's wrong form, each refusal with its accepted twin; `diff` on a real change; the template is a valid Note; the criterion ids of the tool and of the rule stay the same set.

### Fan-out — Mission 201

- `test-fan-out-rubric.sh` (W / U / M) — the Mission template's optional `## Fan-out` rubric: exactly one, before `## Steps`, every other rubric kept, additions only; the skill instruction in at most ten lines naming `dispatching-parallel-agents`; the rubric form refused for a batch with no output, an output inside a repository, a duplicate name, no targets; an absent or empty rubric stays valid.

### The server named after its workspace — Mission 206 (v0.1.12)

- `test-install-vault-mcp-workspace-label.sh` (W / U / M) — the server is `second-brain-vault-<workspace_label>`: label posed by the installer and normalised alike in shell and Python; former key of the same Vault migrated; `workshops` retired on request, a Vault's key never; two Vaults with one label refused, suffixed name proposed, nothing written; `--skip-desktop`.
- `test-project-bootstrap-refresh-prompt.sh` (W / U / M) — `project-bootstrap.sh prompt <dossier>` regenerates a project's Pilot prompt (old and current formats), keeping its canary and identity.

### Play only what changed — Mission 209

- `test-run-suite-changed.sh` (W / U / M) — `run-suite.sh --changed [<ref>]` plays the two guardian lines and the lines the changed files name, the whole suite when the runner or the manifest changes; `run-suite.ps1 -Changed` lists the same lines.

### Step zero, guardian launches, session close — Missions 215, 214, 217

- `test-pilot-opening-step-zero.sh` (W / U / M) — the opening carries a step zero (reading list, prompt, rendered block).
- `test-check-asserted-paths-constant-launches.sh` (W / U / M) — the guardian's launches are counted; a larger corpus adds none.
- `test-check-session-close.sh` (W / U / M) — a handoff enters only with the DIGEST that names it and a later `STATE:` line.

### Coherent correction of six reports — Mission 218

- `test-build-indexes-case-collision.sh` (W / U / M) — a hand-written `INDEX.md` is never overwritten (content and exact name kept, `INDEX-CASE-COLLISION`), on both faces of the collision; the freshness guardian never prescribes the full mode for it; an exemption by the certificate's key or by `.vault-exempt` (folder names with spaces) is honoured; a root outside any repository is refused.
- `test-state-sheet-at-birth.sh` (W / U / M) — `create` and `adopt` give birth to the journal, `STATE.md` and `DIGEST.md`; the Pilot prompt carries `state_path`; the digest carries the Pilot contract; a hand-written sheet is never overwritten; lineage rows reach the digest.
- `test-owner-language-rendered.sh` (W / U / M) — the language recorded in `USER.md` (BOM included) is rendered in the Pilot prompt and the project guide; without it, the language of the Owner's messages, never English by default; the common prompt keeps one placeholder.
- `test-work-regime-mode2.sh` (W / U / M) — a mode-2 Note (an Owner's prompt, verbatim with its sha256, or the consumed files with theirs) is accepted, a wrong fingerprint refused (`R8-origin`); the same guardians under a Mission and a Note.
- `test-baseline-dirty-tree-and-amend.sh` (W / U / M) — a dirty Git tree is never engraved; a baseline is amended by tool against a Git reference, all or nothing.
- `test-folder-guardians-one-pass.sh` (W / U / M) — the folder-mode guardians read the baseline once, with the same verdicts byte for byte as before, and say their progress. The full-scale bench stays outside the suite: `tools/bench-folder-guardians.sh`.

### Settling 218's leftovers before publication — Mission 219

- `test-work-regime-owner-greenlight.sh` (W / U / M) — a mode-2 Note meeting a full-regime criterion is accepted only with one `owner_greenlight` block (time, lifted criteria, the Owner's answer as received); without it, refused with "ask the Owner"; only the named criteria are lifted, never the form.
- `test-lab-language-local-file.sh` (W / U / M) — `USER.local.yaml` is read before `USER.md`, ignored by Git, refused by the manifest check; every front-matter reader tolerates the BOM.
- `test-project-bootstrap-registry-path-column.sh` (W / U / M) — a project whose path is `none` or `git` is created: the registry lookup is anchored on the path column.
- `test-index-weight-nested-mission-index.sh` (W / U / M) — the weight guardian judges every `missions/MISSION-INDEX.md`, nested ones included.
- `test-check-secrets-name-with-spaces.sh` (W / U / M) — a forbidden name with spaces is printed whole.
- `test-baseline-retire-and-gitignored.sh` (W / U / M) — `project_baseline.py retire`, all or nothing; in a Git work tree, what Git ignores and does not track is neither engraved nor judged.

## Liens

- `see also` — [Vault tests (live index)](./index.md)
- `see also` — [Vault tests — archive 2026-09](./index-archive-2026-09.md)
