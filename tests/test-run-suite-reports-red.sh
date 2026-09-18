#!/usr/bin/env bash
# Mission 188, T2: the suite runner plays every line of its manifest, even
# after a red one, counts n/total, names the red line and fails the run.
#
# Oracle (PASS expected): a trial manifest of three lines -- the red one
#   FIRST, then two green -- gives "RESULT: 2/3 PASS", names the red line,
#   exits non-zero, and all three lines left their marker (nothing stopped
#   at the first red).
# Negative control: the same manifest with the red line made green gives
#   "RESULT: 3/3 PASS" and exit 0 -- the runner does not fail by default.
# Extra: a red INFORMATIONAL line is named but does not fail the run; a line
#   exiting 77 is counted SKIP.
# On Windows the same cases run through tests/run-suite.ps1 as well, the
# runner CI uses there.
#
# usage: bash tests/test-run-suite-reports-red.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m188-runner-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

WINDOWS=0
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WINDOWS=1 ;; esac

# Three trial scripts; each leaves a marker so the test can see it ran.
mk() {
  # $1 = name, $2 = exit code
  printf '#!/usr/bin/env bash\necho "%s ran"\n: > "%s/%s.ran"\nexit %s\n' "$1" "$TMP" "$1" "$2" > "$TMP/$1.sh"
}
mk red 1
mk green-a 0
mk green-b 0
mk flip 0
mk info-red 1
mk skipper 77

manifest() {
  # $@ = "name severity" pairs; writes $TMP/m.tsv
  : > "$TMP/m.tsv"
  printf '# trial manifest\n' >> "$TMP/m.tsv"
  for pair in "$@"; do
    n="${pair% *}"; s="${pair#* }"
    printf '%s\t-\tbash\tWUM\t%s\ttrial\n' "$TMP/$n.sh" "$s" >> "$TMP/m.tsv"
  done
}

run_sh() { OUT="$(bash "$REPO_ROOT/tests/run-suite.sh" --manifest "$TMP/m.tsv" 2>&1)"; RC=$?; }
run_ps1() {
  OUT="$(powershell -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$REPO_ROOT/tests/run-suite.ps1")" -Manifest "$(cygpath -w "$TMP/m.tsv")" 2>&1)"
  RC=$?
}

check_runner() {
  # $1 = runner name (sh | ps1)
  r="$1"
  echo "=== runner: $r ==="

  # --- oracle: red first, then two green ----------------------------------
  rm -f "$TMP"/*.ran
  manifest "red blocking" "green-a blocking" "green-b blocking"
  "run_$r"
  case "$OUT" in *"RESULT: 2/3 PASS"*) pass "($r) 2/3 PASS counted" ;; *) fail "($r) summary is not 2/3 PASS: $(printf '%s' "$OUT" | tail -n 1)" ;; esac
  if printf '%s\n' "$OUT" | grep -E '^FAIL ' | grep -q "red.sh"; then pass "($r) the red line is named"; else fail "($r) the red line is not named in the summary"; fi
  if [ "$RC" -ne 0 ]; then pass "($r) exit code $RC (non-zero)"; else fail "($r) exit code 0 with a blocking red"; fi
  if [ -f "$TMP/red.ran" ] && [ -f "$TMP/green-a.ran" ] && [ -f "$TMP/green-b.ran" ]; then
    pass "($r) all three lines ran, none skipped after the red one"
  else
    fail "($r) a line did not run after the red one"
  fi

  # --- negative control: all green -----------------------------------------
  manifest "flip blocking" "green-a blocking" "green-b blocking"
  "run_$r"
  case "$OUT" in *"RESULT: 3/3 PASS"*) pass "($r) control: 3/3 PASS" ;; *) fail "($r) control: summary is not 3/3 PASS" ;; esac
  if [ "$RC" -eq 0 ]; then pass "($r) control: exit code 0"; else fail "($r) control: exit code $RC on an all-green manifest"; fi

  # --- informational red and SKIP -----------------------------------------
  manifest "green-a blocking" "info-red informational" "skipper blocking"
  "run_$r"
  case "$OUT" in *"RESULT: 1/3 PASS (1 SKIP, 0 FAIL blocking, 1 FAIL informational)"*) pass "($r) informational red and SKIP counted apart" ;; *) fail "($r) informational/SKIP summary: $(printf '%s' "$OUT" | tail -n 1)" ;; esac
  if [ "$RC" -eq 0 ]; then pass "($r) an informational red does not fail the run"; else fail "($r) an informational red failed the run (exit $RC)"; fi
}

check_runner sh
if [ "$WINDOWS" -eq 1 ]; then
  check_runner ps1
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
