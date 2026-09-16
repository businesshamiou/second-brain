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

# Mission 176: the three P4 (privacy) patterns are never written a second
# time into a tracked file -- tools/check-private-patterns.sh's own
# PLAIN_PATTERNS array is the sole source that already catalogs them
# (already exempted from its own sweep by pathspec). Derived here at
# runtime instead of duplicated as a literal; a missing source or an empty
# derived list fails loudly (exit 1) rather than silently running this
# sweep blind. The atelier words, the "Mission NNN" citation, and the
# Mission 174 defect strings below are NOT P4 (rule 2) -- they stay literal.
GUARDIAN_SCRIPT="$REPO_ROOT/tools/check-private-patterns.sh"
if [ ! -f "$GUARDIAN_SCRIPT" ]; then
  echo "FATAL: cannot derive P4 patterns -- guardian script not found: $GUARDIAN_SCRIPT" >&2
  exit 1
fi
# Boucle de lecture plutot que `mapfile` : celui-ci n'existe qu'a partir de
# bash 4.0, et macOS livre le bash 3.2 -- « mapfile: command not found »
# (Mission 180, tour 4). Meme resultat, une entree par ligne lue.
PRIVATE_PATTERNS=()
while IFS= read -r pattern; do
  if [ -n "$pattern" ]; then
    PRIVATE_PATTERNS+=("$pattern")
  fi
done < <(sed -n '/^PLAIN_PATTERNS=(/,/^)/p' "$GUARDIAN_SCRIPT" | grep -oE '"[^"]+"' | tr -d '"')
if [ "${#PRIVATE_PATTERNS[@]}" -eq 0 ]; then
  echo "FATAL: derived P4 pattern list is empty -- PLAIN_PATTERNS not found or empty in $GUARDIAN_SCRIPT" >&2
  exit 1
fi

# Same list as the PowerShell version -- rule 2's own vocabulary, a bare
# "Mission NNN" citation in displayed output, and the exact defect strings
# this Mission's steps 3/4 removed, plus the derived P4 patterns above.
FORBIDDEN_PATTERNS=(
  'workshop-build'
  'workshop-production'
  '\bworkshops\b'
  '\bLegacy\b'
  'businesshamiou'
  'Mission [0-9]{2,3}(-C[0-9]+)?'
  'depot frere introuvable'
  'Pre-vol agregateur vault'
  'AVERTI \(hors depot'
  "${PRIVATE_PATTERNS[@]}"
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

# Same fix as tests/test-install-e2e.sh, same reason: install.sh above
# bootstraps uv under its own --test-root profile inside a genuine child
# process (`bash install.sh` in a `$(...)` command substitution), so that
# PATH update dies with it on a runner with no uv preinstalled. Step 3
# below (trial commit) then fails with "exec: uv: not found" at guardians
# `vault-check-indexes-fresh`/`vault-check-index-weight` -- same mechanism
# already fixed on the Windows/PowerShell mirror of this exact test
# (tests/test-nominal-flow-no-atelier-vocabulary.ps1, Start-Process).
TEST_PROFILE_UV_BIN="$TEST_ROOT/profile/.local/bin"
[ -d "$TEST_PROFILE_UV_BIN" ] && PATH="$TEST_PROFILE_UV_BIN:$PATH"

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

# Reusable so the same detection logic backs both the real sweep (step 4)
# and the negative case (step 5, Mission 176 rule 4: a green suite that
# detects nothing is worse than the defect it fixed).
sweep_forbidden_patterns() {
  local text="$1"
  SWEEP_ANY_MATCH=0
  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    local hits
    hits="$(printf '%s\n' "$text" | grep -inE -- "$pattern" || true)"
    if [ -n "$hits" ]; then
      SWEEP_ANY_MATCH=1
      echo "  FAIL - forbidden pattern '$pattern' found:"
      printf '%s\n' "$hits" | sed 's/^/      /'
    fi
  done
}

echo ""
echo "=== 4. Forbidden-vocabulary sweep across all three phases ==="
sweep_forbidden_patterns "$(cat "$ALL_OUTPUT_FILE")"
assert_true "$SWEEP_ANY_MATCH" "no atelier name/word, Mission-number citation, or removed defect string appears anywhere in the nominal flow"

echo ""
echo "=== 5. Negative case: the sweep still detects a P4 pattern when present ==="
# Built at runtime from the derived array (never a literal P4 string in this
# tracked file) and fed only to the in-memory sweep, never written to disk.
SYNTHETIC_LEAK="some diagnostic line mentions ${PRIVATE_PATTERNS[0]} in passing"
sweep_forbidden_patterns "$SYNTHETIC_LEAK"
assert_true "$([ "$SWEEP_ANY_MATCH" = "1" ]; echo $?)" "sweep detects a fabricated P4 pattern (${PRIVATE_PATTERNS[0]}) built at runtime, never written to disk"

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
