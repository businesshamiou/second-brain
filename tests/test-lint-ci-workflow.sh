#!/usr/bin/env bash
# Regression test for tools/lint-ci-workflow.py (Mission 168, ticket 10): the
# structural YAML/GitHub Actions lint fallback, chosen because `actionlint`
# and `shellcheck` are both absent from this machine (measured, ticket 10
# report) and the ticket's own fallback clause is "analyse YAML par uv run +
# bibliotheque standard" -- not a third-party YAML parser.
#
# Cases:
#   1. a well-formed minimal workflow passes (exit 0).
#   2. a tab character in the indentation is caught.
#   3. a duplicate key at the same mapping level is caught.
#   4. a missing required top-level key (`jobs:`) is caught.
#   5. a job missing `runs-on:`/`steps:` is caught.
#   6. the real, committed .github/workflows/ci.yml passes -- pins the tool
#      to the file it was built to check, same freshness idea as
#      test-third-party-licenses.sh case 3.
#
# usage: tests/test-lint-ci-workflow.sh
# sortie : "PASS: 6/6 cas conformes" (exit 0) ou "FAIL: <n> cas non
# conformes" (exit 1), meme convention que test-check-links-cross-repo.sh.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LINTER="$REPO_ROOT/tools/lint-ci-workflow.py"
REAL_WORKFLOW="$REPO_ROOT/.github/workflows/ci.yml"

if [ ! -f "$LINTER" ]; then
  echo "FAIL: script cible introuvable : $LINTER" >&2
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "FAIL: uv introuvable -- prerequis du fallback (ticket 04)" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0

# --- 1. well-formed minimal workflow -> PASS ---------------------------------
GOOD="$TMP/good.yml"
cat > "$GOOD" <<'EOF'
name: Sample

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run
        run: echo "hello"
EOF
OUT_1="$(uv run "$LINTER" "$GOOD" 2>&1)"; RC_1=$?
if [ "$RC_1" -eq 0 ]; then
  echo "ok [1-valide]: fichier bien forme -> PASS"
else
  echo "FAIL [1-valide]: exit=$RC_1, sortie:" >&2
  printf '%s\n' "$OUT_1" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 2. tab character -> caught ----------------------------------------------
TABBED="$TMP/tabbed.yml"
printf 'name: Sample\n\non:\n\tpush:\n\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo hi\n' > "$TABBED"
OUT_2="$(uv run "$LINTER" "$TABBED" 2>&1)"; RC_2=$?
if [ "$RC_2" -ne 0 ] && printf '%s' "$OUT_2" | grep -q "tab character"; then
  echo "ok [2-tab]: caractere tabulation detecte"
else
  echo "FAIL [2-tab]: exit=$RC_2, sortie:" >&2
  printf '%s\n' "$OUT_2" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 3. duplicate key at the same level -> caught ----------------------------
DUP="$TMP/dup.yml"
cat > "$DUP" <<'EOF'
name: Sample
name: Sample again

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hi
EOF
OUT_3="$(uv run "$LINTER" "$DUP" 2>&1)"; RC_3=$?
if [ "$RC_3" -ne 0 ] && printf '%s' "$OUT_3" | grep -q "duplicate key"; then
  echo "ok [3-cle-dupliquee]: cle dupliquee au meme niveau detectee"
else
  echo "FAIL [3-cle-dupliquee]: exit=$RC_3, sortie:" >&2
  printf '%s\n' "$OUT_3" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 4. missing required top-level key (jobs:) -> caught ---------------------
NOJOBS="$TMP/nojobs.yml"
cat > "$NOJOBS" <<'EOF'
name: Sample

on:
  push:
EOF
OUT_4="$(uv run "$LINTER" "$NOJOBS" 2>&1)"; RC_4=$?
if [ "$RC_4" -ne 0 ] && printf '%s' "$OUT_4" | grep -q "missing required top-level key"; then
  echo "ok [4-cle-racine-manquante]: 'jobs:' manquant detecte"
else
  echo "FAIL [4-cle-racine-manquante]: exit=$RC_4, sortie:" >&2
  printf '%s\n' "$OUT_4" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 5. job missing runs-on:/steps: -> caught --------------------------------
NORUNSON="$TMP/norunson.yml"
cat > "$NORUNSON" <<'EOF'
name: Sample

on:
  push:

jobs:
  build:
    steps:
      - run: echo hi
EOF
OUT_5="$(uv run "$LINTER" "$NORUNSON" 2>&1)"; RC_5=$?
if [ "$RC_5" -ne 0 ] && printf '%s' "$OUT_5" | grep -q "no 'runs-on:'"; then
  echo "ok [5-job-incomplet]: job sans 'runs-on:' detecte"
else
  echo "FAIL [5-job-incomplet]: exit=$RC_5, sortie:" >&2
  printf '%s\n' "$OUT_5" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 6. the real, committed workflow passes ----------------------------------
if [ ! -f "$REAL_WORKFLOW" ]; then
  echo "FAIL [6-fichier-reel]: introuvable : $REAL_WORKFLOW" >&2
  FAILURES=$((FAILURES + 1))
else
  OUT_6="$(uv run "$LINTER" "$REAL_WORKFLOW" 2>&1)"; RC_6=$?
  if [ "$RC_6" -eq 0 ]; then
    echo "ok [6-fichier-reel]: .github/workflows/ci.yml -> PASS"
  else
    echo "FAIL [6-fichier-reel]: exit=$RC_6, sortie:" >&2
    printf '%s\n' "$OUT_6" >&2
    FAILURES=$((FAILURES + 1))
  fi
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 6/6 cas conformes"
  exit 0
else
  echo "FAIL: $FAILURES cas non conformes"
  exit 1
fi
