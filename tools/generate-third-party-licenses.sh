#!/usr/bin/env bash
# Third-party skill licence aggregator (Mission 168, ticket 09, T20 point 2).
#
# Role: rebuild the repo-root THIRD-PARTY-LICENSES.md from the warehouse's
# own per-collection licence records. This script never decides a licence
# itself -- the warehouse's own ingestion process
# (skills-warehouse/INGESTION_STANDARD.md) already did that, once per
# skill, and recorded the verdict in that collection's own licence file.
# This script only reads those files and stitches them into one root-level
# document, verbatim.
#
# Usage:
#   tools/generate-third-party-licenses.sh [--out <path>] [--check]
#
#   --out <path>   Write the generated document to <path> instead of the
#                  default root/THIRD-PARTY-LICENSES.md. Used by
#                  tests/test-third-party-licenses.sh so a test run never
#                  has to touch the committed file. <path> may be spelled
#                  as a POSIX path or a Windows path (C:\... or C:/...);
#                  an already-absolute <path>, in either notation, is
#                  never prefixed with the current directory. Refused
#                  (before anything is written) if it resolves inside this
#                  repository -- Mission 171-C01 step 9, same family as
#                  acceptance-wizard.sh's report-path guard.
#   --check        Write nothing. Regenerate in memory and compare against
#                  the file already on disk at the target path (the
#                  default root file, or the path given to --out): exit 0
#                  if identical, exit 1 with a one-line message otherwise.
#                  Same "measure, never silently fix" contract as this
#                  repo's other guardians (tools/check-indexes-fresh.sh,
#                  tools/check-distribution-manifest.sh).
#
# Inputs:
#   skills-warehouse/skill-collections/<collection>/LICENSES.md, one per
#   collection, read-only -- this script never writes under
#   skills-warehouse/.
#
# Outputs:
#   THIRD-PARTY-LICENSES.md (default: repo root), a single Markdown
#   document with one section per collection, each section reproducing
#   that collection's own licence table and "Owner exceptions" list
#   unchanged.
#
# Exit codes:
#   0  file written (or --check found no drift).
#   1  not run from inside a Git repository; no collection found under
#      skill-collections/; a collection's licence file is missing; or
#      --check found the on-disk file stale.

set -u

VAULT_ROOT="$(git rev-parse --show-toplevel)" || {
  echo "REFUS : hors d'un depot Git : script non executable." >&2
  exit 1
}

WAREHOUSE_DIR="$VAULT_ROOT/skills-warehouse/skill-collections"
OUT_PATH="$VAULT_ROOT/THIRD-PARTY-LICENSES.md"
CHECK_ONLY=0

# sb_is_absolute_path PATH -- true for a POSIX absolute path (leading '/')
# or a Windows drive-letter absolute path (e.g. C:\Users\... or
# C:/Users\...) -- this script runs under Git Bash/MSYS on Windows too
# (VAULT_ROOT above, from `git rev-parse --show-toplevel`, is itself
# spelled "C:/Users/..." there), so a caller may naturally pass --out a
# Windows-spelled path (audit defect, same family as acceptance-wizard.sh's
# resolve_report_path). Matched with a regex (`[[ =~ ]]`), never a glob
# `case` bracket expression: bash's glob engine treats an unquoted
# backslash inside `[...]` as an escape character, not a literal one, so a
# bracket meant to match either '/' or '\' silently never matches '\' at
# all (measured while building the equivalent check in install.sh).
sb_is_absolute_path() {
  case "$1" in
    /*) return 0 ;;
  esac
  [[ "$1" =~ ^[A-Za-z]:[/\\] ]]
}

# sb_normalize_path_for_compare PATH -- string-only normalization so the
# same location spelled as a Windows drive-letter path (C:\... or C:/...)
# or an MSYS/Git-Bash mount path (/c/...) compares equal to VAULT_ROOT
# regardless of which form either side happens to use: backslashes become
# slashes, a drive letter becomes the equivalent lowercase MSYS mount
# segment, and a trailing slash is stripped. Never touches the filesystem.
sb_normalize_path_for_compare() {
  local p drive rest
  p="$(printf '%s' "$1" | tr '\\' '/')"
  if [[ "$p" =~ ^([A-Za-z]):(/.*)$ ]]; then
    drive="$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')"
    rest="${BASH_REMATCH[2]}"
    p="/$drive$rest"
  fi
  case "$p" in
    ?*/) p="${p%/}" ;;
  esac
  printf '%s' "$p"
}

# sb_path_is_inside_or_equal CANDIDATE ROOT -- both normalized before
# comparing (see sb_normalize_path_for_compare above).
sb_path_is_inside_or_equal() {
  local candidate root
  candidate="$(sb_normalize_path_for_compare "$1")"
  root="$(sb_normalize_path_for_compare "$2")"
  [ "$candidate" = "$root" ] && return 0
  case "$candidate" in
    "$root"/*) return 0 ;;
  esac
  return 1
}

# sb_resolve_out_path PATH -- honours an already-absolute PATH (POSIX or
# Windows notation) verbatim, never prefixing it with the current
# directory; prefixes a relative PATH with the current directory. Refuses
# (prints to stderr, returns 1) when the resolved path lands inside
# VAULT_ROOT: this script's default output IS inside VAULT_ROOT on
# purpose, so this guard only ever runs against an explicit --out, never
# against the default.
sb_resolve_out_path() {
  local path="$1"
  if ! sb_is_absolute_path "$path"; then
    path="$(pwd)/$path"
  fi
  if sb_path_is_inside_or_equal "$path" "$VAULT_ROOT"; then
    echo "REFUS : --out $path est a l'interieur de $VAULT_ROOT -- choisir un chemin hors du depot" >&2
    return 1
  fi
  printf '%s' "$path"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --out)
      [ $# -ge 2 ] || { echo "REFUS : --out attend un chemin" >&2; exit 1; }
      OUT_PATH="$(sb_resolve_out_path "$2")" || exit 1
      shift 2
      ;;
    --check)
      CHECK_ONLY=1
      shift
      ;;
    *)
      echo "REFUS : option inconnue : $1" >&2
      exit 1
      ;;
  esac
done

if [ ! -d "$WAREHOUSE_DIR" ]; then
  echo "REFUS : dossier introuvable : $WAREHOUSE_DIR" >&2
  exit 1
fi

# Collections are the immediate sub-directories of skill-collections/ that
# carry their own licence file. Sorted (`sort`) so the generated document
# is byte-identical across runs regardless of the filesystem's own
# directory order -- required for --check to mean anything.
COLLECTIONS="$(find "$WAREHOUSE_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"

if [ -z "$COLLECTIONS" ]; then
  echo "REFUS : aucune collection trouvee sous $WAREHOUSE_DIR" >&2
  exit 1
fi

TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

{
  cat <<'HEADER'
---
type: generated-report
title: "Licences tierces — skills adoptés"
description: "Agrégat, généré par script, des licences de chaque skill adopté du warehouse, par collection."
status: active
generated_by: tools/generate-third-party-licenses.sh
---

# LICENCES TIERCES

Ce fichier est généré automatiquement par le script `generate-third-party-licenses.sh`, dans le dossier `tools/` de ce dépôt, depuis le fichier de licences propre à chaque collection, sous le dossier `skill-collections/` du warehouse. Ne pas éditer à la main : régénérer.

Second Brain lui-même (ce dépôt, hors le sous-dossier du warehouse) est sous licence MIT — voir [LICENSE](./LICENSE). Ce fichier couvre uniquement les skills tiers adoptés dans le warehouse.

`NOASSERTION` signifie qu'aucune licence n'a pu être établie pour ce skill ; ce n'est pas une licence.

HEADER

  while IFS= read -r collection; do
    [ -z "$collection" ] && continue
    LICENSES_FILE="$WAREHOUSE_DIR/$collection/LICENSES.md"
    if [ ! -f "$LICENSES_FILE" ]; then
      echo "REFUS : fichier de licences introuvable : $LICENSES_FILE" >&2
      exit 1
    fi
    printf '## %s\n\n' "$collection"
    # Reproduce the collection's own table (and any "Owner exceptions"
    # list that follows it) verbatim, starting at the table's own header
    # row -- this drops only that file's leading "# Licences — <n>" title
    # and the NOASSERTION note, already stated once above. Aggregation
    # only: this script never reorders or reformats a row.
    sed -n '/^| Skill /,$p' "$LICENSES_FILE"
    printf '\n'
  done <<EOF_COLLECTIONS
$COLLECTIONS
EOF_COLLECTIONS

  cat <<'FOOTER'
## Liens

- `see also` — [Standard d'ingestion du warehouse](./skills-warehouse/INGESTION_STANDARD.md)
- `see also` — [Licence MIT de Second Brain](./LICENSE)
FOOTER
} > "$TMP_OUT" || exit 1

if [ "$CHECK_ONLY" -eq 1 ]; then
  if [ ! -f "$OUT_PATH" ]; then
    echo "REFUS : $OUT_PATH introuvable -- lancer sans --check pour le creer." >&2
    exit 1
  fi
  if cmp -s "$TMP_OUT" "$OUT_PATH"; then
    echo "OK : $OUT_PATH a jour."
    exit 0
  fi
  echo "REFUS : $OUT_PATH perime. Remede : bash tools/generate-third-party-licenses.sh" >&2
  exit 1
fi

cp "$TMP_OUT" "$OUT_PATH"
echo "OK : $OUT_PATH regenere."
exit 0
