#!/usr/bin/env bash
# Appends a timestamped line at the end of a project's journal.
# Never opens the file for reading; never rewrites an existing line.
# Creates the file and its folder if they do not exist.
#
# usage: append-journal.sh <chemin-projet> "<texte>"
#
# --- External memory wiring: removed (Mission 147) ------------------------------
# A fail-open wiring fed an external memory bank after the line was written
# (Mission 122). It is removed: the Mission 146 benchmark measured the tool
# on ten questions and a frozen corpus, Decision 113850 decided the
# removal. This script's behaviour is unchanged by the removal: same line
# written, same exit code -- invariance proven by diff in Mission 147.
# The memory write was never a source of state: the journal is.

set -u

PROJECT="${1:-}"
TEXT="${2:-}"

if [ -z "$PROJECT" ] || [ -z "$TEXT" ]; then
  echo "usage: append-journal.sh <chemin-projet> \"<texte>\"" >&2
  exit 1
fi

# --- 300-character stop (Decision 191407, Mission 123) --------------------------
# Fail-closed, before any write: the text supplied by the caller (excluding the
# timestamp, which this script itself prefixes further down) must never exceed
# MAX_LINE_CHARS. Counted in characters (wc -m), not in bytes -- consistent
# with the convention already measured in Missions 121/122 on the STATE: line.
# Refusal without writing anything.
MAX_LINE_CHARS=300

TEXT_LEN="$(printf '%s' "$TEXT" | wc -m)"
if [ "$TEXT_LEN" -gt "$MAX_LINE_CHARS" ]; then
  echo "REFUS append-journal.sh : ligne de $TEXT_LEN caracteres, plafond $MAX_LINE_CHARS (Decision 191407). Rien ecrit." >&2
  exit 1
fi

STATE_DIR="$PROJECT/state"
JOURNAL="$STATE_DIR/journal.md"

mkdir -p "$STATE_DIR"

if [ ! -f "$JOURNAL" ]; then
  # Mission 168, ticket 03: "## Liens" section added at creation --
  # tools/check-links.sh requires it on every .md outside skills/external and
  # skills-warehouse (RULES-2026-08-21-115658-document-linking-standard.md).
  # The link points to the project's own README: always present (written
  # by project-bootstrap.sh before this call) and independent of the workspace
  # geometry (no assumption about a neighbouring repository).
  PROJECT_NAME="$(basename "$PROJECT")"
  printf '# Journal — %s\n\nJournal en ajout seul. Genere/alimente par tools/append-journal.sh, jamais edite a la main.\n\n## Liens\n\n- `see also` — [%s](../README.md)\n\n' "$PROJECT_NAME" "$PROJECT_NAME" > "$JOURNAL"
fi

TS="$(date +"%Y-%m-%dT%H:%M:%S%:z")"
printf '%s %s\n' "$TS" "$TEXT" >> "$JOURNAL"
APPEND_STATUS=$?

# Explicit capture of the write's exit code, so as not to let the
# last command of the file decide the script's exit code.
exit "$APPEND_STATUS"
