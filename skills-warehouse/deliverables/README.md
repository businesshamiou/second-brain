# Deliverables

`deliverables/` is the repository's canonical shelf of finished packages: the files a user downloads and uploads to a target interface.

Each release is immutable and lives at `deliverables/<collection>/<YYYY-MM-DD-label>/`. Never overwrite a release directory or alter a published checksum; a changed source always ships as a new `<YYYY-MM-DD-label>`.

Two release shapes coexist here, produced by two different scripts:

- **Full production release** (`../tools/package-collection-release.py`, gated on a passing SkillSpector scan): `<collection>-skills-full.zip`, `chat-zips/<skill>.zip`, `manifest.md`, `LICENSES.md`, `validation-report.md`, `SHA256SUMS.txt`. Build and inspect in external staging first; copy here only after every validation passes. Example: `software-engineering/2026-09-07-v1/`.
- **Chat-zip release** (`../../tools/package-warehouse-deliverables.ps1`, no SkillSpector dependency, Mission 171-C01 step 5): `chat-zips/<skill>.zip`, `index.md` (one line per Skill: name, licence, usage), `SHA256SUMS.txt`. No collection-wide ZIP, no `manifest.md`/`validation-report.md`. Rerun the script to reproduce a release byte-for-byte from unchanged sources; it refuses to silently overwrite a release whose content would differ.

Source snapshots, raw intake, caches, and temporary build files remain outside Git. External GitHub releases may mirror a deliverable, but this directory is the authoritative in-repository delivery location.

## Installing a Skill package in a desktop application

Every release's `chat-zips/<skill>.zip` is a self-contained, single-Skill archive: one top-level folder named after the Skill, with `SKILL.md` at its root. Pick the target that matches your interface.

- **Claude.ai / Claude Desktop, Projects → Skills**: open the Project's Skills panel and upload `<skill>.zip` directly; the platform reads the top-level folder as the Skill.
- **ChatGPT Projects (or any interface that accepts a project-level file upload)**: attach `<skill>.zip` to the project; unzip it first if the interface expects individual files rather than an archive.
- **Claude Code, per-project Skill**: unzip `<skill>.zip` under `.claude/skills/` in the target repository, so the Skill ends up at `.claude/skills/<skill>/SKILL.md`. For a Skill available to every project, unzip it under `~/.claude/skills/` instead.
- **Any other agent runtime that reads a `SKILL.md` directory**: unzip `<skill>.zip` anywhere the runtime scans for Skills; the folder name and `SKILL.md` are the only two things that must line up.

Check the Skill's licence in the release's `index.md` (or `LICENSES.md` for a full production release) before redistributing it further; `NOASSERTION` means no licence grant was found and is not itself a licence.
