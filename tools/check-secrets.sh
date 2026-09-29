#!/usr/bin/env bash
# Secrets check on the added lines of a staged diff.
# Portable shell: no dependency on Python.
# Refusal is the default position: any abnormal condition blocks.

set -u

# Mission 168, ticket 03: no more `git rev-parse --show-toplevel` to
# locate the patterns file -- this path must always point to THIS
# repository (second-brain), never to the calling repository when this guardian is
# reused by a neighbouring project (repo: local, tools/project-bootstrap.sh):
# `--show-toplevel` there returns the neighbouring project's root, not this one. Same
# cause and same remedy as tools/check-indexes-fresh.sh and
# tools/check-index-weight.sh (Mission 137-B / 140): path derived from the
# location of this script, never from the calling repository.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PATTERNS_FILE="$VAULT_ROOT/rules/patterns/secret-patterns.txt"
. "$SCRIPT_DIR/project-baseline.sh"

# usage: check-secrets.sh             (current repository, staged diff)
#        check-secrets.sh <projet>    (folder mode, without Git: entire content
#                                      of each file -- vcs: none,
#                                      Decision 000545 A4)
DIR_MODE=0
if [ -n "${1:-}" ]; then
  if [ ! -d "$1" ]; then
    echo "REFUS : dossier de projet introuvable : $1" >&2
    exit 1
  fi
  DIR_MODE=1
  PROJECT_ROOT="$(cd "$1" && pwd)"
else
  # Git guard (Mission 125): outside a repository, `git diff --cached` further down
  # would fail silently (empty staged, a skip wrongly taken for a PASS).
  # Explicit refusal here, before any diff -- no longer used to locate a path.
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "REFUS : hors d'un depot Git : gardien non executable." >&2
    exit 1
  }
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
fi

if [ ! -f "$PATTERNS_FILE" ]; then
  echo "REFUS : fichier de motifs introuvable : $PATTERNS_FILE" >&2
  echo "Le controle ne peut pas verifier, il refuse." >&2
  exit 1
fi

# --- 1. Forbidden file names ---
FORBIDDEN_NAMES='(^|/)\.env($|\.)|\.(key|pem|pfx|p12|crt|cer|der|jks|keystore)$|(^|/)(secrets?|credentials?)(/|$)|\.(sql|dump|sqlite|db|mdb)$'

if [ "$DIR_MODE" = "1" ]; then
  STAGED="$(pb_list_files "$PROJECT_ROOT")"
else
  STAGED="$(git diff --cached --name-only --diff-filter=ACM)"
fi

# Baseline (Decision 000545, A4): a file engraved at adoption and not
# touched is never judged; a file engraved then touched is judged in full
# (TOUCHED, complete content read further down); the baseline file
# itself is only a list of fingerprints and names, never content.
#
# Mission 218, lot 6: one pass. The list goes once through pb_classify, which
# reads the baseline once and fingerprints every file in one process; the old
# loop re-read the whole baseline per file, three times (pb_untouched, then
# pb_touched, which calls it again). Same verdicts, byte for byte
# (tests/test-folder-guardians-one-pass.sh). Progress lines go to stderr,
# prefixed `progress:`, in folder mode only.
pb_load "$PROJECT_ROOT"
TOUCHED=""
if [ "$DIR_MODE" = "1" ]; then
  echo "progress: check-secrets: $(printf '%s\n' "$STAGED" | grep -c . ) file(s) listed in $PROJECT_ROOT${PB_FILE:+, baseline $PB_NAME read once}" >&2
fi
if [ -n "$PB_NAME" ] && [ -n "$STAGED" ]; then
  CLASSIFIED="$(printf '%s\n' "$STAGED" | pb_classify "$PROJECT_ROOT")" || {
    echo "REFUS : ligne de base illisible, le controle ne peut pas verifier." >&2
    exit 1
  }
  STAGED="$(printf '%s\n' "$CLASSIFIED" | awk -F'\t' '$1 == "N" || $1 == "T" { print substr($0, 3) }')"
  if [ -n "$PB_FILE" ]; then
    TOUCHED="$(printf '%s\n' "$CLASSIFIED" | awk -F'\t' '$1 == "T" { print substr($0, 3) }')"
  fi
  if [ "$DIR_MODE" = "1" ]; then
    echo "progress: check-secrets: $(printf '%s\n' "$STAGED" | grep -c . ) file(s) to judge after the baseline" >&2
  fi
fi

if [ -n "$STAGED" ]; then
  BAD_NAMES="$(printf '%s\n' "$STAGED" | grep -E "$FORBIDDEN_NAMES" || true)"
  # .env.example is the only exception: a template with no value.
  BAD_NAMES="$(printf '%s\n' "$BAD_NAMES" | grep -v '\.env\.example$' || true)"
  if [ -n "$BAD_NAMES" ]; then
    echo "REFUS : fichier(s) au nom interdit dans le staging :" >&2
    # One name per line, whole: unquoted, a name with spaces came out cut
    # (Mission 219, A7).
    printf '%s\n' "$BAD_NAMES" | sed 's/^/  /' >&2
    exit 1
  fi
fi

# --- 2. Patterns in the added lines ---
# full_content FILE...: entire content of text files (a binary
# file -- null byte in its beginning -- is never read as text).
# Mission 218, lot 6: one process for all the files (pb_text), where the loop
# launched head, tr, cmp, head and sed per file. Same bytes.
# staged_diff_batch: NUL-separated paths on stdin, their staged added lines by
# batch (Mission 218, lot 6). One function so the xargs line carries its
# portability note (Mission 219): -0 is in BSD and GNU xargs, and every `--`
# option on that line is git's, not xargs's.
staged_diff_batch() {
  (cd "$PROJECT_ROOT" && GIT_LITERAL_PATHSPECS=1 xargs -0 git diff --cached -U0 --diff-filter=ACM --)  # portability: -0 is BSD and GNU; the -- options are git's
}

full_content() {
  pb_text "$PROJECT_ROOT"
}

if [ "$DIR_MODE" = "1" ]; then
  ADDED="$(printf '%s\n' "$STAGED" | full_content || true)"
elif [ -n "$PB_NAME" ]; then
  # Repository mode with a baseline: diff of the retained files only, plus the
  # entire content of the files engraved then touched (ratchet).
  ADDED=""
  if [ -n "$STAGED" ]; then
    # Mission 218, lot 6: the retained files by batch (xargs), not one `git
    # diff` per file; git prints them in the same path order, and only the
    # added lines are kept -- the same lines.
    ADDED="$(printf '%s\n' "$STAGED" | tr '\n' '\0' | staged_diff_batch \
      | grep -E '^\+' | grep -Ev '^\+\+\+' || true)"
  fi
  if [ -n "$TOUCHED" ]; then
    ADDED="${ADDED}
$(printf '%s\n' "$TOUCHED" | full_content || true)"
  fi
else
  ADDED="$(git diff --cached -U0 --diff-filter=ACM | grep -E '^\+' | grep -Ev '^\+\+\+' || true)"
fi

if [ -z "$ADDED" ]; then
  exit 0
fi

FOUND=0
while IFS= read -r pattern; do
  case "$pattern" in
    ''|'#'*) continue ;;
  esac
  MATCH="$(printf '%s\n' "$ADDED" | grep -E -- "$pattern" || true)"
  if [ -n "$MATCH" ]; then
    echo "REFUS : motif de secret detecte." >&2
    echo "  motif : $pattern" >&2
    echo "  (valeur non affichee)" >&2
    FOUND=1
  fi
done < "$PATTERNS_FILE"

if [ "$FOUND" -ne 0 ]; then
  echo "" >&2
  echo "Retire la valeur du fichier, place-la dans .env (non suivi)," >&2
  echo "et documente la cle attendue dans .env.example." >&2
  echo "Ne contourne pas ce controle." >&2
  exit 1
fi

exit 0
