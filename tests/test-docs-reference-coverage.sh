#!/usr/bin/env bash
# Mission 226, phase 6: every script of tools/ has its sheet, or its line, in
# the reference documentation (docs/reference/tools-*.md).
#
# Corpus: every file of `git ls-files tools/` except data files (*.json) --
# tools/__pycache__ is never tracked. A script is covered when its path
# `tools/<name>` appears in a docs/reference/tools-*.md page on a heading
# (`## `, `### `), a list line (`- `) or a table row (`| `).
#   (a) every tracked script of tools/ is covered;
#   (b) witness: a script name that no page mentions is reported, named --
#       the check is proven able to fail, on a throwaway copy of the pages.
#
# usage: bash tests/test-docs-reference-coverage.sh
# Exit 0: PASS. Exit 1: FAIL, each uncovered script named.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

# uncovered <pages-dir> <list>: prints each script of <list> no page covers.
uncovered() {
  local dir="$1" list="$2" f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if ! cat "$dir"/tools-*.md 2>/dev/null | grep -E '^(#{2,3} |- |\| )' | grep -qF "tools/$f"; then
      printf '%s\n' "tools/$f"
    fi
  done < "$list"
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m226-cov-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
git -C "$REPO_ROOT" ls-files tools/ | sed 's#^tools/##' | grep -v '/' | grep -v '\.json$' > "$TMP/scripts"
N="$(wc -l < "$TMP/scripts" | tr -d ' ')"

echo "=== Mission 226 : chaque script de tools/ a sa fiche ($N scripts) ==="
MISSING="$(uncovered "$REPO_ROOT/docs/reference" "$TMP/scripts")"
if [ -z "$MISSING" ]; then
  pass "(a) $N/$N scripts couverts par docs/reference/tools-*.md"
else
  fail "(a) $(printf '%s\n' "$MISSING" | wc -l | tr -d ' ')/$N scripts sans fiche : $(printf '%s' "$MISSING" | tr '\n' ' ')"
fi

mkdir -p "$TMP/pages"
cp "$REPO_ROOT"/docs/reference/tools-*.md "$TMP/pages/" 2>/dev/null
printf 'never-documented-witness.sh\n' > "$TMP/witness"
W="$(uncovered "$TMP/pages" "$TMP/witness")"
if [ "$W" = "tools/never-documented-witness.sh" ]; then
  pass "(b) temoin : un script qu'aucune page ne nomme est signale"
else
  fail "(b) temoin non signale : [$W]"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then echo "=== RESULT: PASS ==="; exit 0; fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
