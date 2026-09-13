#!/usr/bin/env bash
# End-to-end non-regression guardian (Mission 174, step 5, T21), shell
# parity with tests/test-nominal-flow-no-atelier-vocabulary.ps1: a fresh
# install, a session opening, and a trial commit in the resulting project
# must never show a participant any name or word of the atelier.
#
# Rerun this exact test with one command, from the repository root:
#
#   bash tests/test-nominal-flow-no-atelier-vocabulary.sh
#
# Replays the same three phases as the PowerShell version, no sibling
# repository declared anywhere (the nominal case for every real
# participant), capturing BOTH stdout and stderr of each phase (`2>&1`
# inside each command substitution -- install.sh's own step_line() writes
# to stderr by design, see its header comment; a stdout-only capture would
# miss it, the exact gap that let the old "depot frere introuvable in
# ../workshop-build" warning go unnoticed by every prior installer test).
#
# HYPOTHESIS notice (same reason as tests/test-install-e2e.sh, its sibling):
# this test is written to run on genuine Linux or WSL, measured absent on
# the Windows machine it was built on -- this repository's own Bash tool is
# Git Bash/MSYS, explicitly excluded by earlier Missions as not
# Linux-native. It is exercised there for real only in CI or on a
# participant's own Linux/macOS machine; until then its correctness carries
# the HYPOTHESIS mention the Vault's own rules require for an unmeasured
# claim.
#
# Exit code 0 means the nominal flow showed nothing but participant-
# relevant output. Exit code 1 means at least one forbidden string was
# found; the offending line(s) are printed.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0

assert_true() {
  if [ "$1" = "0" ]; then
    echo "  PASS - $2"
  else
    echo "  FAIL - $2"
    FAILURES=$((FAILURES + 1))
  fi
}

# Same list as the PowerShell version -- rule 2's own vocabulary, a bare
# "Mission NNN" citation in displayed output, and the exact defect strings
# this Mission's steps 3/4 removed.
FORBIDDEN_PATTERNS=(
  'workshop-build'
  'workshop-production'
  'aios-production'
  '\bworkshops\b'
  'glintbloom'
  '\bLegacy\b'
  'WIN-AE600DJQCF6'
  'businesshamiou'
  'Mission [0-9]{2,3}(-C[0-9]+)?'
  'depot frere introuvable'
  'Pre-vol agregateur vault'
  'AVERTI \(hors depot'
)

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sb-noatelier-XXXXXX")"
echo ""
echo "TestRoot: $TEST_ROOT"

ALL_OUTPUT_FILE="$TEST_ROOT/all-phases.log"
: > "$ALL_OUTPUT_FILE"

echo ""
echo "=== 1. Fresh install, no sibling repository declared ==="
WORKSPACE_PATH="$TEST_ROOT/workspace"
ANSWERS_PATH="$TEST_ROOT/answers.json"
sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$WORKSPACE_PATH\"#" \
  "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$ANSWERS_PATH"

uv run --no-project "$REPO_ROOT/tools/sb_installer_helper.py" field \
  "$ANSWERS_PATH" "firstProject.name" > "$TEST_ROOT/fpname.txt" 2>/dev/null || true
FIRST_PROJECT_NAME="$(cat "$TEST_ROOT/fpname.txt" 2>/dev/null)"
[ -z "$FIRST_PROJECT_NAME" ] && FIRST_PROJECT_NAME="premier-projet"

CLONE_PATH="$WORKSPACE_PATH/second-brain"
FIRST_PROJECT_PATH="$WORKSPACE_PATH/$FIRST_PROJECT_NAME"

# SECOND_BRAIN_SIBLING_REPO deliberately left unset: the nominal case for
# every real participant is no declaration at all (step 3 of this Mission).
INSTALL_OUTPUT="$(bash "$REPO_ROOT/install.sh" --source "$REPO_ROOT" --answers-file "$ANSWERS_PATH" --test-mode --test-root "$TEST_ROOT" 2>&1)"
INSTALL_EXIT=$?
assert_true "$([ "$INSTALL_EXIT" = "0" ]; echo $?)" "install.sh exits 0"
{ echo "### install.sh (fresh install)"; printf '%s\n' "$INSTALL_OUTPUT"; } >> "$ALL_OUTPUT_FILE"
echo "--- captured output: install.sh (fresh install) ---"
printf '%s\n' "$INSTALL_OUTPUT"

echo ""
echo "=== 2. Session opening: tools/session-preflight.sh in the fresh clone ==="
PREFLIGHT_OUTPUT="$(cd "$CLONE_PATH" && bash tools/session-preflight.sh 2>&1)"
PREFLIGHT_EXIT=$?
assert_true "$([ "$PREFLIGHT_EXIT" = "0" ]; echo $?)" "session-preflight.sh exits 0 (READY)"
{ echo "### session-preflight.sh (session opening)"; printf '%s\n' "$PREFLIGHT_OUTPUT"; } >> "$ALL_OUTPUT_FILE"
echo "--- captured output: session-preflight.sh (session opening) ---"
printf '%s\n' "$PREFLIGHT_OUTPUT"

echo ""
echo "=== 3. Trial commit in the first project ==="
COMMIT_OUTPUT="$(
  cd "$FIRST_PROJECT_PATH" 2>&1 || exit 1
  bash "$CLONE_PATH/tools/append-journal.sh" '.' 'STATE: trial commit, Mission 174 step 5 no-atelier-vocabulary test' 2>&1
  git add -- state/journal.md 2>&1
  git commit -q -m "Trial commit: no-atelier-vocabulary test" 2>&1
)"
COMMIT_EXIT=$?
assert_true "$([ "$COMMIT_EXIT" = "0" ]; echo $?)" "trial commit passes all project guardians (git commit exits 0)"
{ echo "### trial commit in the first project"; printf '%s\n' "$COMMIT_OUTPUT"; } >> "$ALL_OUTPUT_FILE"
echo "--- captured output: trial commit in the first project ---"
printf '%s\n' "$COMMIT_OUTPUT"

echo ""
echo "=== 4. Forbidden-vocabulary sweep across all three phases ==="
ANY_MATCH=0
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  HITS="$(grep -inE -- "$pattern" "$ALL_OUTPUT_FILE" || true)"
  if [ -n "$HITS" ]; then
    ANY_MATCH=1
    echo "  FAIL - forbidden pattern '$pattern' found:"
    printf '%s\n' "$HITS" | sed 's/^/      /'
  fi
done
assert_true "$ANY_MATCH" "no atelier name/word, Mission-number citation, or removed defect string appears anywhere in the nominal flow"

rm -rf -- "$TEST_ROOT"
echo ""
echo "TestRoot removed: $TEST_ROOT"

echo ""
if [ "$FAILURES" = "0" ]; then
  echo "=== RESULT: PASS (all checks green) ==="
  exit 0
else
  echo "=== RESULT: FAIL ($FAILURES check(s) failed) ==="
  exit 1
fi
