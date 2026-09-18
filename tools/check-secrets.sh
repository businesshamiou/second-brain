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
pb_load "$PROJECT_ROOT"
TOUCHED=""
if [ -n "$PB_NAME" ] && [ -n "$STAGED" ]; then
  KEPT=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    pb_is_baseline_file "$f" && continue
    if [ -n "$PB_FILE" ]; then
      pb_untouched "$f" && continue
      pb_touched "$f" && TOUCHED="${TOUCHED}${TOUCHED:+
}$f"
    fi
    KEPT="${KEPT}${KEPT:+
}$f"
  done <<PB_EOF
$STAGED
PB_EOF
  STAGED="$KEPT"
fi

if [ -n "$STAGED" ]; then
  BAD_NAMES="$(printf '%s\n' "$STAGED" | grep -E "$FORBIDDEN_NAMES" || true)"
  # .env.example is the only exception: a template with no value.
  BAD_NAMES="$(printf '%s\n' "$BAD_NAMES" | grep -v '\.env\.example$' || true)"
  if [ -n "$BAD_NAMES" ]; then
    echo "REFUS : fichier(s) au nom interdit dans le staging :" >&2
    printf '  %s\n' $BAD_NAMES >&2
    exit 1
  fi
fi

# --- 2. Patterns in the added lines ---
# full_content FILE...: entire content of text files (a binary
# file -- null byte in its beginning -- is never read as text).
full_content() {
  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$PROJECT_ROOT/$f" ] || continue
    if head -c 8000 "$PROJECT_ROOT/$f" | tr -d '\000' | cmp -s - <(head -c 8000 "$PROJECT_ROOT/$f"); then
      sed 's/^/+/' "$PROJECT_ROOT/$f"
    fi
  done
}

if [ "$DIR_MODE" = "1" ]; then
  ADDED="$(printf '%s\n' "$STAGED" | full_content || true)"
elif [ -n "$PB_NAME" ]; then
  # Repository mode with a baseline: diff of the retained files only, plus the
  # entire content of the files engraved then touched (ratchet).
  ADDED=""
  if [ -n "$STAGED" ]; then
    ADDED="$(printf '%s\n' "$STAGED" | while IFS= read -r f; do
      [ -z "$f" ] && continue
      (cd "$PROJECT_ROOT" && GIT_LITERAL_PATHSPECS=1 git diff --cached -U0 --diff-filter=ACM -- "$f")
    done | grep -E '^\+' | grep -Ev '^\+\+\+' || true)"
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
