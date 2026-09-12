#!/usr/bin/env bash
# Unit tests for the isolated, testable functions of
# tools/acceptance-wizard.sh (Mission 168, ticket 11). The wizard itself is
# an interactive script meant for the Owner, in person, after this Mission's
# local green (T14) -- never run end to end by an agent (ticket 11,
# criterion 4). What IS testable without a human at the keyboard is the
# handful of small functions the interactive stages call into: the y/N
# reply parser (_is_yes), the note sanitizer (_sanitize_note), the report
# path guard (resolve_report_path) and the report writer (write_report),
# plus record_scenario/record_skipped (fed simulated stdin, never a real
# prompt waiting on a human).
#
# Sourcing the wizard script (guarded by its own
# `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` check) defines every function below
# without running main(): this file never plays a real acceptance stage.
#
# usage: tests/test-acceptance-wizard-functions.sh
# output: "PASS: N/N cases" (exit 0) or "FAIL: <n> cases" (exit 1), same
# convention as test-check-private-patterns.sh.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WIZARD="$REPO_ROOT/tools/acceptance-wizard.sh"

if [ ! -f "$WIZARD" ]; then
  echo "FAIL: target script not found: $WIZARD" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$WIZARD"

FAILURES=0

check() {
  local label="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    echo "ok [$label]"
  else
    echo "FAIL [$label]: got [$got], want [$want]" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

# --- 1. _is_yes: the reply parser -------------------------------------------
for reply in y Y yes Yes YES; do
  if _is_yes "$reply"; then r="yes"; else r="no"; fi
  check "1-is_yes-true-$reply" "$r" "yes"
done
for reply in n N no "" nope garbage " "; do
  if _is_yes "$reply"; then r="yes"; else r="no"; fi
  check "1-is_yes-false-[$reply]" "$r" "no"
done

# --- 2. _sanitize_note: pipe delimiter safety -------------------------------
check "2-sanitize-plain" "$(_sanitize_note "all good")" "all good"
check "2-sanitize-pipe" "$(_sanitize_note "a|b|c")" "a-b-c"
check "2-sanitize-empty" "$(_sanitize_note "")" ""

# --- 3. resolve_report_path: default is a sibling of the repo, never inside it
DEFAULT_PATH="$(resolve_report_path "")"
RC_DEFAULT=$?
case "$DEFAULT_PATH" in
  "$REPO_ROOT"/*)
    echo "FAIL [3-default-outside-repo]: default path landed inside the repo: $DEFAULT_PATH" >&2
    FAILURES=$((FAILURES + 1))
    ;;
  *second-brain-acceptance-*.md)
    if [ "$RC_DEFAULT" -eq 0 ]; then
      echo "ok [3-default-outside-repo]"
    else
      echo "FAIL [3-default-outside-repo]: non-zero exit ($RC_DEFAULT)" >&2
      FAILURES=$((FAILURES + 1))
    fi
    ;;
  *)
    echo "FAIL [3-default-outside-repo]: unexpected shape: $DEFAULT_PATH" >&2
    FAILURES=$((FAILURES + 1))
    ;;
esac

# --- 4. resolve_report_path: a path inside the repo is refused -------------
INSIDE="$REPO_ROOT/leaked-report.md"
if OUT="$(resolve_report_path "$INSIDE" 2>&1)"; then
  echo "FAIL [4-inside-repo-refused]: accepted an in-repo path: $OUT" >&2
  FAILURES=$((FAILURES + 1))
else
  echo "ok [4-inside-repo-refused]"
fi

# --- 5. resolve_report_path: an explicit outside path is honoured verbatim -
TMP_OUT_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_OUT_DIR"' EXIT
CUSTOM_OUT="$TMP_OUT_DIR/custom-report.md"
GOT_CUSTOM="$(resolve_report_path "$CUSTOM_OUT")"
check "5-custom-path-honoured" "$GOT_CUSTOM" "$CUSTOM_OUT"

# --- 6. record_scenario: simulated stdin, "yes" branch ----------------------
# A herestring (not a pipe) feeds stdin: a pipe would run record_scenario in
# a subshell, and its append to the global SCENARIOS array would then be
# lost the moment that subshell exits -- caught for real by this suite (see
# the ticket 11 report for the red/green trace).
SCENARIOS=()
record_scenario "S-TEST" "Test scenario" >/dev/null <<< $'y\nlooks good'
check "6-record-yes" "${SCENARIOS[0]}" "S-TEST|yes|looks good"

# --- 7. record_scenario: simulated stdin, "no" branch, note with a pipe -----
SCENARIOS=()
record_scenario "S-TEST" "Test scenario" >/dev/null <<< $'n\nsaw a|problem'
check "7-record-no-sanitized" "${SCENARIOS[0]}" "S-TEST|no|saw a-problem"

# --- 8. record_scenario: empty reply defaults to "no" (no default-yes) -----
SCENARIOS=()
record_scenario "S-TEST" "Test scenario" >/dev/null <<< ''
check "8-record-empty-is-no" "${SCENARIOS[0]}" "S-TEST|no|"

# --- 9. record_skipped -------------------------------------------------------
SCENARIOS=()
record_skipped "S11" "optional stage, not run"
check "9-record-skipped" "${SCENARIOS[0]}" "S11|skipped|optional stage, not run"

# --- 10. write_report: renders every scenario as one table row -------------
SCENARIOS=("S1|yes|" "S5|no|forgot to remove the secret" "S11|skipped|optional stage, not run")
ASSISTANT_NAME="Ibrahim"
REPORT_PATH="$TMP_OUT_DIR/rendered-report.md"
write_report "$REPORT_PATH" >/dev/null
if [ ! -f "$REPORT_PATH" ]; then
  echo "FAIL [10-write-report-exists]: $REPORT_PATH was not created" >&2
  FAILURES=$((FAILURES + 1))
else
  echo "ok [10-write-report-exists]"
fi
ROW_COUNT="$(grep -cE '^\| S(1|5|11) \|' "$REPORT_PATH" || true)"
check "10-write-report-row-count" "$ROW_COUNT" "3"
if grep -qF "| S5 | no | forgot to remove the secret |" "$REPORT_PATH"; then
  echo "ok [10-write-report-no-row-content]"
else
  echo "FAIL [10-write-report-no-row-content]: S5 row missing or malformed" >&2
  FAILURES=$((FAILURES + 1))
fi
if grep -qF "Assistant name used for S7: Ibrahim" "$REPORT_PATH"; then
  echo "ok [10-write-report-assistant-name]"
else
  echo "FAIL [10-write-report-assistant-name]: assistant name missing from header" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 11. write_report: never asked to write inside the repo in these tests -
case "$REPORT_PATH" in
  "$REPO_ROOT"/*)
    echo "FAIL [11-report-path-sane]: test itself pointed inside the repo" >&2
    FAILURES=$((FAILURES + 1))
    ;;
  *)
    echo "ok [11-report-path-sane]"
    ;;
esac

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 11/11 cases"
  exit 0
else
  echo "FAIL: $FAILURES cases"
  exit 1
fi
