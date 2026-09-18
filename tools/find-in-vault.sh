#!/usr/bin/env bash
# Content search in the .md files under a root.
# Returns the matching lines, never the files: one result per line,
# format "chemin:numero-de-ligne:texte" (path:line-number:text), suffixed with " [REMPLACÉ]" when the
# source file appears in <racine>/superseded-files.txt (list produced
# by tools/build-indexes.sh, objective B, Mission 029). The line is still
# always returned, never filtered. List absent => search without the mark,
# without error. The mark is only as fresh as the last generation of the indexes
# (build-indexes.sh): a supersedes added afterwards only appears after
# a regeneration.
#
# usage: find-in-vault.sh [--root <dir>] [--limit N] [--frontmatter-only] <motif>

set -u

ROOT="."
LIMIT=50
FM_ONLY=0
PATTERN=""
HAVE_PATTERN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      ROOT="${2:-.}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-50}"
      shift 2
      ;;
    --frontmatter-only)
      FM_ONLY=1
      shift
      ;;
    --)
      shift
      if [ "$#" -gt 0 ]; then PATTERN="$1"; HAVE_PATTERN=1; shift; fi
      ;;
    *)
      PATTERN="$1"
      HAVE_PATTERN=1
      shift
      ;;
  esac
done

if [ "$HAVE_PATTERN" -ne 1 ] || [ -z "$PATTERN" ]; then
  echo "usage: find-in-vault.sh [--root <dir>] [--limit N] [--frontmatter-only] <motif>" >&2
  exit 1
fi

if [ ! -d "$ROOT" ]; then
  echo "REFUS : racine introuvable : $ROOT" >&2
  exit 1
fi

EXCLUDE_RE='(^|/)(\.git|\.githooks|\.claude|\.codex|graphify-out|node_modules|\.venv|venv|__pycache__)(/|$)'

# --- Marking of superseded documents (objective B, Mission 029) ---
# The list superseded-files.txt is written by build-indexes.sh at the root
# that was passed to it; since the default root of this script remains the
# caller's current directory (OPEN 1, Mission 027, outside the perimeter of
# Mission 029), that root may differ from the generation root (e.g.
# a call from workshop-build, list written under workshop-production/). We
# therefore look for the file anywhere under $ROOT, not only at its root.
# Set carried by tools/kvmap.sh: `declare -A` does not exist in the
# bash 3.2 shipped by Apple (Mission 181).
. "$(dirname "$0")/kvmap.sh"
while IFS= read -r SUP_LIST_FILE; do
  [ -z "$SUP_LIST_FILE" ] && continue
  while IFS= read -r SUP_REL; do
    [ -z "$SUP_REL" ] && continue
    kv_set SUPERSEDED_BASENAMES "${SUP_REL##*/}" 1
  done < "$SUP_LIST_FILE"
done < <(find "$ROOT" -type f -name 'superseded-files.txt' 2>/dev/null | grep -vE "$EXCLUDE_RE")

mark_superseded() {
  while IFS= read -r RESLINE; do
    RESPATH="${RESLINE%%:*}"
    RESFN="$(basename "$RESPATH")"
    if kv_has SUPERSEDED_BASENAMES "$RESFN"; then
      printf '%s [REMPLACÉ]\n' "$RESLINE"
    else
      printf '%s\n' "$RESLINE"
    fi
  done
}

if [ "$FM_ONLY" -eq 1 ]; then
  # Front-matter mode: the "---" bounds differ per file (FNR), but a
  # single awk process handles all the files passed as arguments (fast).
  FILES="$(find "$ROOT" -type f -name '*.md' | grep -vE "$EXCLUDE_RE")"
  if [ -n "$FILES" ]; then
    printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 awk -v pat="$PATTERN" '
      FNR==1 { infm=0 }
      FNR==1 && $0=="---" { infm=1; next }
      infm && $0=="---" { infm=0; next }
      infm && $0 ~ pat { print FILENAME ":" FNR ":" $0 }
    ' 2>/dev/null
  fi
else
  grep -rnE --include='*.md' -- "$PATTERN" "$ROOT" 2>/dev/null | grep -vE "$EXCLUDE_RE"
fi | mark_superseded | head -n "$LIMIT"
