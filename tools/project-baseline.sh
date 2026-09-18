#!/usr/bin/env bash
# Dated baseline and ratchet (Decision 2026-09-17-000545, A4) -- functions
# shared by the guardians written in shell (check-links.sh,
# check-secrets.sh). Python twin: tools/project_baseline.py, same format,
# same verdict.
#
# When an existing folder is adopted, tools/project-bootstrap.sh records the
# list of its files, with the SHA-256 fingerprint of each, in a dated file
# that the birth certificate names (`# baseline: <file>`). The guardians
# then judge only what is new and what is touched:
#   - a baseline file, identical content: never red;
#   - a touched baseline file: judged in full, must become
#     compliant (ratchet);
#   - a file absent from the baseline: judged as usual.
# No certificate, or a certificate without a baseline: no change in behaviour.
#
# The content compared is that of the working tree.
#
# usage (source):
#   . "$SCRIPT_DIR/project-baseline.sh"
#   pb_load "<project-root>"
#   pb_untouched "<relative path>" && continue
#   pb_list_files "<project-root>"   # folder mode (vcs: none)

_pb_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_pb_lib_dir/resolve-vault.sh"

PB_ROOT=""
PB_FILE=""
PB_NAME=""

# pb_sha256 <file>: SHA-256 fingerprint of the content without carriage returns --
# a rewrite of line endings by Git (core.autocrlf) does not count
# as a modification (measured in Mission 184 under Windows).
pb_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    tr -d '\r' < "$1" | sha256sum | awk '{print $1}'  # portability: guarded by command -v
  elif command -v shasum >/dev/null 2>&1; then
    tr -d '\r' < "$1" | shasum -a 256 | awk '{print $1}'
  else
    tr -d '\r' < "$1" | openssl dgst -sha256 | awk '{print $NF}'
  fi
}

# pb_load <project-root>: PB_FILE = baseline named by the certificate, empty
# otherwise.
pb_load() {
  local cfg="$1/.pre-commit-config.yaml"
  PB_ROOT="$1"
  PB_FILE=""
  PB_NAME=""
  bc_file_has_certificate "$cfg" || return 0
  PB_NAME="$(bc_get "$cfg" baseline)"
  [ -n "$PB_NAME" ] || return 0
  [ -f "$1/$PB_NAME" ] && PB_FILE="$1/$PB_NAME"
  return 0
}

# pb_is_baseline_file <relative path>: 0 for the baseline file
# itself (generated data: fingerprints and names, never content).
pb_is_baseline_file() {
  [ -n "$PB_NAME" ] && [ "$1" = "$PB_NAME" ]
}

# pb_listed_hash <relative path>: recorded fingerprint, empty if not listed.
pb_listed_hash() {
  [ -n "$PB_FILE" ] || return 0
  tr -d '\r' < "$PB_FILE" | awk -F '\t' -v p="$1" '$2 == p { print $1; exit }'
}

# pb_untouched <relative path>: 0 if the file is in the baseline
# and its content has not changed.
pb_untouched() {
  local want have
  [ -n "$PB_FILE" ] || return 1
  want="$(pb_listed_hash "$1")"
  [ -n "$want" ] || return 1
  [ -f "$PB_ROOT/$1" ] || return 1
  have="$(pb_sha256 "$PB_ROOT/$1")"
  [ "$want" = "$have" ]
}

# pb_touched <relative path>: 0 if the file is in the baseline and
# its content has changed (the ratchet: judged in full).
pb_touched() {
  local want
  [ -n "$PB_FILE" ] || return 1
  want="$(pb_listed_hash "$1")"
  [ -n "$want" ] || return 1
  ! pb_untouched "$1"
}

# pb_list_files <project-root>: all the files of the project, relative
# paths, excluding .git, dependencies and links placed towards the Vault.
pb_list_files() {
  (
    cd "$1" || exit 1
    find . \( -name .git -o -name node_modules -o -path ./.claude/skills -o -path ./.claude/agents -o -path ./.agents/skills \) -prune -o -type f -print
  ) | sed 's#^\./##' | LC_ALL=C sort
}
