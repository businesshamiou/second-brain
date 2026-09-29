#!/usr/bin/env bash
# Mission 237, step 5: a skipped test is seen, and a required one cannot be
# skipped.
#
# Oracle, on a trial manifest (bash runner; the PowerShell runner too on
# Windows):
#   (a) a test that exits 77 saying « SKIP : raison du test » is named under the
#       RESULT line, with that reason; the run stays green;
#   (b) the same test marked required on the platform (`W!UM`, `U!`, `M!`)
#       turns red: « FAIL (required, skipped) », a blocking FAIL, exit 1;
#   (c) a required test that passes stays green;
#   (d) in CI (GITHUB_ACTIONS=true) the requirement is not enforced: the SKIP
#       stays a named SKIP (the runners carry no gum nor tui-test).
#
# usage: bash tests/test-run-suite-skip-visible.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "$(sb_tmp_dir tests)/m237-skip-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

WINDOWS=0
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WINDOWS=1 ;; esac
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) PLAT=W ;; Darwin) PLAT=M ;; *) PLAT=U ;; esac

printf '#!/usr/bin/env bash\necho "debut"\necho "SKIP : raison du test"\nexit 77\n' > "$TMP/skipper.sh"
printf '#!/usr/bin/env bash\necho ok\nexit 0\n' > "$TMP/green.sh"

manifest() { # $1 = platforms of the skipper, $2 = platforms of green
  printf '# trial manifest\n' > "$TMP/m.tsv"
  printf '%s\t-\tbash\t%s\tinformational\ttrial skipper\n' "$TMP/skipper.sh" "$1" >> "$TMP/m.tsv"
  printf '%s\t-\tbash\t%s\tblocking\ttrial green\n' "$TMP/green.sh" "$2" >> "$TMP/m.tsv"
}
run_sh() { OUT="$(GITHUB_ACTIONS="${CI_FLAG:-}" bash "$REPO_ROOT/tests/run-suite.sh" --manifest "$TMP/m.tsv" --platform "$PLAT" 2>&1)"; RC=$?; }
run_ps1() {
  OUT="$(GITHUB_ACTIONS="${CI_FLAG:-}" powershell -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$REPO_ROOT/tests/run-suite.ps1")" -Manifest "$(cygpath -w "$TMP/m.tsv")" 2>&1)"
  RC=$?
  OUT="$(printf '%s' "$OUT" | tr -d '\r')"
}

echo "=== Mission 237 : SKIP nomme, test requis ($PLAT) ==="
for runner in sh ps1; do
  [ "$runner" = ps1 ] && [ "$WINDOWS" -eq 0 ] && continue
  manifest "WUM" "WUM"
  "run_$runner"
  if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q "^SKIP: .*skipper.sh -- SKIP : raison du test"; then
    pass "(a) [$runner] le SKIP est nomme sous RESULT, avec sa raison ; exit 0"
  else
    fail "(a) [$runner] rc=$RC, ligne SKIP absente : $(printf '%s\n' "$OUT" | grep -A3 '^RESULT' | tr '\n' ' ')"
  fi
  manifest "${PLAT}!WUM" "${PLAT}!WUM"
  "run_$runner"
  if [ "$RC" -ne 0 ] && printf '%s\n' "$OUT" | grep -q "FAIL (required, skipped)" \
     && printf '%s\n' "$OUT" | grep -q "^SKIP (required on $PLAT, counted FAIL): .*skipper.sh"; then
    pass "(b) [$runner] requis sur $PLAT et saute : FAIL bloquant, exit $RC"
  else
    fail "(b) [$runner] rc=$RC : $(printf '%s\n' "$OUT" | grep -A3 '^RESULT' | tr '\n' ' ')"
  fi
  printf '%s\n' "$OUT" | grep -q "PASS .*green.sh" && pass "(c) [$runner] un test requis qui passe reste vert" \
    || fail "(c) [$runner] green.sh non PASS"
  CI_FLAG=true "run_$runner"
  if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q "^SKIP: .*skipper.sh -- .*not enforced in CI"; then
    pass "(d) [$runner] en CI, un test requis saute reste un SKIP nomme (exigence non appliquee)"
  else
    fail "(d) [$runner] CI : rc=$RC -- $(printf '%s\n' "$OUT" | grep -A3 '^RESULT' | tr '\n' ' ')"
  fi
done

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES, $PASSES PASS) ==="
exit 1
