# Deliverables

`deliverables/` is the repository's canonical shelf of finished packages: the files a user downloads and uploads to a target interface.

Each release is immutable and lives at `deliverables/<collection>/<YYYY-MM-DD-label>/`. It contains the collection ZIP, one chat-upload ZIP per Skill, `manifest.md`, `LICENSES.md`, `validation-report.md`, and `SHA256SUMS.txt`. Build and inspect a release in external staging first; copy it here only after every validation passes. Never overwrite a release directory or alter a published checksum.

Source snapshots, raw intake, caches, and temporary build files remain outside Git. External GitHub releases may mirror a deliverable, but this directory is the authoritative in-repository delivery location.
