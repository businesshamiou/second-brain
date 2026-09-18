#!/usr/bin/env bash
# Mission 188, T1: moving the test list out of ci.yml into tests/suite.tsv
# lost nothing and added nothing.
#
# Oracle (PASS expected):
#   1. the set {test, platform, severity} of tests/suite.tsv -- lines whose
#      origin starts with "+" left out, they were added after the reference
#      and are listed -- equals the set frozen in
#      tests/fixtures/ci-42f74e6a-steps.tsv, read from ci.yml at 42f74e6a,
#      the last commit where ci.yml listed the tests itself;
#   2. ci.yml lists no test and installs no uv any more: 0 "tests/test-",
#      0 uv install script, and each of the three suite jobs calls a runner.
# Negative controls: a copy of the manifest with one line removed fails and
#   names the missing test; a copy of the fixture with one line removed fails
#   and names the unexplained extra line.
#
# usage: bash tests/test-suite-manifest-matches-ci.sh

set -u
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/tests/suite.tsv"
FIXTURE="$REPO_ROOT/tests/fixtures/ci-42f74e6a-steps.tsv"
CI="$REPO_ROOT/.github/workflows/ci.yml"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m188-manifest-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

expand_manifest() {
  # $1 = manifest. One "test<TAB>platform<TAB>severity" line per platform
  # letter, reference lines only (origin not starting with "+").
  awk -F'\t' '
    /^#/ || NF == 0 { next }
    substr($6, 1, 1) == "+" { next }
    {
      t = $1; if ($2 != "-") t = t " " $2
      for (i = 1; i <= length($4); i++) print t "\t" substr($4, i, 1) "\t" $5
    }' "$1" | sort
}

fixture_set() { grep -v '^#' "$1" | grep -v '^$' | sort; }

compare() {
  # $1 = manifest, $2 = fixture. Sets MISSING and EXTRA.
  expand_manifest "$1" > "$TMP/m.set"
  fixture_set "$2" > "$TMP/f.set"
  MISSING="$(comm -13 "$TMP/m.set" "$TMP/f.set")"
  EXTRA="$(comm -23 "$TMP/m.set" "$TMP/f.set")"
}

echo "=== T1 : tests/suite.tsv = the suite ci.yml played at 42f74e6a ==="
[ -f "$MANIFEST" ] || { echo "FAIL : manifest not found"; exit 1; }
[ -f "$FIXTURE" ] || { echo "FAIL : fixture not found"; exit 1; }

compare "$MANIFEST" "$FIXTURE"
N="$(wc -l < "$TMP/f.set" | tr -d ' ')"
if [ -z "$MISSING" ] && [ -z "$EXTRA" ]; then
  pass "(1) $N {test, platform, severity} triples, 0 lost, 0 added"
else
  [ -n "$MISSING" ] && fail "(1) lost from the manifest: $(printf '%s' "$MISSING" | tr '\t\n' ' ;')"
  [ -n "$EXTRA" ] && fail "(1) added without a leading + origin: $(printf '%s' "$EXTRA" | tr '\t\n' ' ;')"
fi
echo "  added after the reference (origin +):"
awk -F'\t' '!/^#/ && NF && substr($6,1,1) == "+" { print "    " $1 " [" $4 "] " $6 }' "$MANIFEST"

# --- (2) ci.yml lists no test and installs no uv ----------------------------
C_TESTS="$(grep -c 'tests/test-' "$CI")"
C_UV="$(grep -c 'astral.sh/uv' "$CI")"
if [ "$C_TESTS" = "0" ] && [ "$C_UV" = "0" ]; then
  pass "(2) ci.yml: 0 test listed, 0 uv install block"
else
  fail "(2) ci.yml still lists $C_TESTS test line(s) and $C_UV uv install line(s)"
fi
for job in windows ubuntu macos; do
  body="$(awk -v j="  $job:" '$0 == j { on = 1; next } on && /^  [a-z-]+:$/ { on = 0 } on' "$CI")"
  if printf '%s\n' "$body" | grep -qE 'tests/run-suite\.(sh|ps1)'; then
    pass "(2) job $job calls the suite runner"
  else
    fail "(2) job $job does not call tests/run-suite.sh or .ps1"
  fi
  if printf '%s\n' "$body" | grep -q 'uses: ./.github/actions/setup-test-env'; then
    pass "(2) job $job sets up its environment through the shared action"
  else
    fail "(2) job $job does not use ./.github/actions/setup-test-env"
  fi
done

# --- negative controls ------------------------------------------------------
echo "=== negative controls ==="
VICTIM="tests/test-install-vault-origin.sh"
grep -v "^$VICTIM	" "$MANIFEST" > "$TMP/manifest-cut.tsv"
compare "$TMP/manifest-cut.tsv" "$FIXTURE"
if printf '%s\n' "$MISSING" | grep -q "^$VICTIM	"; then
  pass "control: a manifest without $VICTIM is refused, the test named"
else
  fail "control: a manifest without $VICTIM went unnoticed"
fi

awk 'BEGIN { cut = 0 } !cut && $0 ~ /^tools\/check-private-patterns.sh --tree-only\tU\t/ { cut = 1; next } { print }' "$FIXTURE" > "$TMP/fixture-cut.tsv"
compare "$MANIFEST" "$TMP/fixture-cut.tsv"
if printf '%s\n' "$EXTRA" | grep -q "^tools/check-private-patterns.sh --tree-only	U	"; then
  pass "control: a line absent from the reference is refused, the line named"
else
  fail "control: an unexplained extra line went unnoticed"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
