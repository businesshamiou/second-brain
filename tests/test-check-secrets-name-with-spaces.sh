#!/usr/bin/env bash
# Mission 219, lot D, A7 (report of Mission 218): check-secrets.sh printed a
# forbidden file name with `printf '  %s\n' $BAD_NAMES` -- unquoted, so a name
# holding spaces came out cut in pieces (`Lou IA/.venv/.../cacert.pem` read on
# youtube-kb as "Lou" and "IA/.venv/..."). Each forbidden name is now printed
# whole, one per line.
#
#   (a) a staged `Lou IA/.venv/lib/cert file.pem` -> refused, and the refusal
#       prints the name whole on one line;
#   (b) two forbidden names -> two lines, each whole;
#   (c) witness: the verdict (refusal, exit code) is unchanged.
#
# usage: bash tests/test-check-secrets-name-with-spaces.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$REPO_ROOT/tools/check-secrets.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m219-a7-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

R="$TMP/repo"
mkdir -p "$R/Lou IA/.venv/lib" "$R/Other dir"
git init -q "$R"
printf 'x\n' > "$R/Lou IA/.venv/lib/cert file.pem"
printf 'x\n' > "$R/Other dir/my key.key"
( cd "$R" && git add -f -- "Lou IA/.venv/lib/cert file.pem" "Other dir/my key.key" && bash "$GUARD" ) >"$TMP/out" 2>&1
RC=$?

[ "$RC" != 0 ] && pass "(c) temoin : refus, rc=$RC" || fail "(c) temoin : le gardien accepte (rc=0)"
grep -qx '  Lou IA/.venv/lib/cert file.pem' "$TMP/out" \
  && pass "(a) le nom a espaces est affiche entier sur une ligne" \
  || fail "(a) nom coupe [$(grep -E '^  ' "$TMP/out" | head -5 | tr '\n' '|')]"
grep -qx '  Other dir/my key.key' "$TMP/out" \
  && pass "(b) le second nom interdit est affiche entier" \
  || fail "(b) second nom coupe ou absent [$(grep -E '^  ' "$TMP/out" | head -5 | tr '\n' '|')]"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
