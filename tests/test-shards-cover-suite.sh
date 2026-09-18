#!/usr/bin/env bash
# Mission 189, T1: splitting the Windows suite into CI shards drops no test
# and plays none twice.
#
# Oracle (PASS expected):
#   1. the union of the Windows lines played by `--shard k/n`, k = 1..n,
#      equals the Windows lines played without --shard, with no line in two
#      shards and none left out;
#   2. .github/workflows/ci.yml runs exactly the n shards the manifest
#      declares (matrix 1..n, runner called with /n);
#   3. the three longest Windows tests measured in CI (report 188, run
#      35349101214) sit in three different shards.
# Negative control: a throwaway copy of the manifest where one Windows line
#   has no shard makes check 1 fail, naming that line.
#
# usage: bash tests/test-shards-cover-suite.sh

set -u
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUNNER="$REPO_ROOT/tests/run-suite.sh"
MANIFEST="$REPO_ROOT/tests/suite.tsv"
CI="$REPO_ROOT/.github/workflows/ci.yml"
LONGEST="tests/test-install-vault-origin.sh tests/test-prerequisites-e2e.ps1 tests/test-project-initiation.sh"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m189-shards-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

shard_count() {
  awk -F'\t' '!/^#/ && NF && index($4, "W") && $7 ~ /^[0-9]+$/ && $7 + 0 > m { m = $7 + 0 } END { print m + 0 }' "$1"
}

cover() {
  # $1 = manifest. Sets MISSING, DOUBLED, N.
  N="$(shard_count "$1")"
  bash "$RUNNER" --manifest "$1" --platform W --list | cut -f1 | sort > "$TMP/all"
  : > "$TMP/union"
  k=1
  while [ "$k" -le "$N" ]; do
    bash "$RUNNER" --manifest "$1" --platform W --shard "$k/$N" --list | cut -f1 >> "$TMP/union"
    k=$((k + 1))
  done
  sort "$TMP/union" > "$TMP/union.sorted"
  MISSING="$(comm -23 "$TMP/all" "$TMP/union.sorted" | sort -u)"
  DOUBLED="$(uniq -d "$TMP/union.sorted")"
  # A label that is legitimately listed twice on W (same test, two lines)
  # appears twice in both lists: compare counts, not only presence.
  if [ -z "$MISSING" ] && [ "$(wc -l < "$TMP/all")" != "$(wc -l < "$TMP/union.sorted")" ]; then
    MISSING="(line count: $(wc -l < "$TMP/all" | tr -d ' ') without --shard, $(wc -l < "$TMP/union.sorted" | tr -d ' ') across shards)"
  fi
  [ -n "$DOUBLED" ] && [ "$(uniq -d "$TMP/all")" = "$DOUBLED" ] && DOUBLED=""
}

echo "=== T1 : the Windows shards cover the suite exactly ==="
cover "$MANIFEST"
TOTAL="$(wc -l < "$TMP/all" | tr -d ' ')"
if [ "$N" -ge 2 ] && [ -z "$MISSING" ] && [ -z "$DOUBLED" ]; then
  pass "(1) $N shards, $TOTAL Windows lines, each played once"
else
  fail "(1) shards N=$N; missing: $(printf '%s' "$MISSING" | tr '\n' ' '); doubled: $(printf '%s' "$DOUBLED" | tr '\n' ' ')"
fi

MATRIX="$(sed -n 's/^[[:space:]]*shard:[[:space:]]*\[\(.*\)\][[:space:]]*$/\1/p' "$CI" | tr -d ' ')"
EXPECTED="$(k=1; out=""; while [ "$k" -le "$N" ]; do out="$out${out:+,}$k"; k=$((k + 1)); done; printf '%s' "$out")"
if [ "$MATRIX" = "$EXPECTED" ] && grep -q "run-suite.ps1 -Shard \"\${{ matrix.shard }}/$N\"" "$CI"; then
  pass "(2) ci.yml runs shards [$MATRIX] of $N"
else
  fail "(2) ci.yml matrix [$MATRIX], manifest declares $N shard(s)"
fi

SEEN=""
DISTINCT=1
for t in $LONGEST; do
  s="$(awk -F'\t' -v t="$t" '!/^#/ && $1 == t && index($4, "W") { print $7; exit }' "$MANIFEST")"
  case " $SEEN " in *" $s "*) DISTINCT=0 ;; esac
  SEEN="$SEEN $s"
  echo "    $t -> shard $s"
done
[ "$DISTINCT" -eq 1 ] && pass "(3) the three longest Windows tests are in three different shards" \
  || fail "(3) two of the three longest Windows tests share a shard"

echo "=== negative control ==="
VICTIM="tests/test-install-e2e.ps1"
awk -F'\t' -v OFS='\t' -v v="$VICTIM" '!/^#/ && $1 == v && index($4, "W") { $7 = "-" } { print }' "$MANIFEST" > "$TMP/manifest-cut.tsv"
cover "$TMP/manifest-cut.tsv"
case "$MISSING" in
  *"$VICTIM"*) pass "control: a Windows line with no shard is caught, named ($VICTIM)" ;;
  *) fail "control: a Windows line with no shard went unnoticed" ;;
esac

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
