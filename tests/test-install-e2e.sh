#!/usr/bin/env bash
# Main end-to-end test of install.sh (Mission 168, ticket 08; spec, Testing
# Decisions -- "point de controle principal"), shell parity with
# tests/test-install-e2e.ps1 (tickets 03/04/07).
#
# Rerun this exact test with one command, from the repository root:
#
#   bash tests/test-install-e2e.sh
#
# What it proves, in a single fresh, blank temporary workspace:
#   1. install.sh accepts a local --source and an --answers-file and
#      reports a success verdict.
#   2. tools/session-preflight.sh is READY in the freshly cloned
#      second-brain (same tool test-install-e2e.ps1 checks, same reason:
#      the spec's own Testing Decisions literally name this vocabulary).
#   3. A trial commit in the first project passes all of its guardians.
#   4. Running the installer a second time, unchanged inputs, is a true
#      no-op: identical verdict, empty porcelain in both the second-brain
#      clone and the first project.
#   5. Throughout, the real environment is untouched: the PATH-persistence
#      file (real mode would be ~/.profile) and the three skill folders
#      (~/.claude/skills, ~/.codex/skills, ~/.agents/skills) are
#      fingerprinted before and after and asserted identical -- install.sh
#      is always invoked with --test-mode here, so nothing it does can
#      reach the real profile.
#
# HYPOTHESIS notice (Mission 168, ticket 08 report): this test is written
# to run on genuine Linux or WSL (measured absent on the Windows machine
# this ticket was built on -- `wsl --status` reports WSL not installed, and
# this repository's own Bash tool is Git Bash/MSYS, explicitly excluded by
# the Mission as not Linux-native). It is exercised there for real only in
# CI (ticket 10) or on a participant's own Linux/macOS machine; until then
# its PASS/FAIL here carries the HYPOTHESIS mention the Mission requires.
#
# Exit code 0 means every assertion above passed. Exit code 1 means at
# least one did not; details are printed to stdout as each check runs.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0

# shellcheck source=tools/environment-fingerprint.sh
. "$REPO_ROOT/tools/environment-fingerprint.sh"
. "$REPO_ROOT/tools/prerequisites.sh" 2>/dev/null || true

assert_true() {
  # $1 = 0/1 condition (shell truth: 0 = pass), $2 = message.
  if [ "$1" = "0" ]; then
    echo "  PASS - $2"
  else
    echo "  FAIL - $2"
    FAILURES=$((FAILURES + 1))
  fi
}

KEEP_TEMP=0
[ "${1:-}" = "--keep-temp" ] && KEEP_TEMP=1

echo "=== 1. Real-environment fingerprint (before) ==="
BEFORE="$(environment_fingerprint "$HOME/.profile")"
echo "$BEFORE" | sed 's/^/  /'

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sb-e2e-XXXXXX")"
echo ""
echo "=== 2. Fresh, blank temporary workspace ==="
echo "  TestRoot: $TEST_ROOT"

WORKSPACE_PATH="$TEST_ROOT/workspace"
ANSWERS_PATH="$TEST_ROOT/answers.json"
uv run --no-project "$REPO_ROOT/tools/sb_installer_helper.py" field \
  "$REPO_ROOT/tests/fixtures/install-answers.sample.json" "firstProject.name" > "$TEST_ROOT/fpname.txt"
FIRST_PROJECT_NAME="$(cat "$TEST_ROOT/fpname.txt")"
[ -z "$FIRST_PROJECT_NAME" ] && FIRST_PROJECT_NAME="premier-projet"
sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$WORKSPACE_PATH\"#" \
  "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$ANSWERS_PATH"

CLONE_PATH="$WORKSPACE_PATH/second-brain"
FIRST_PROJECT_PATH="$WORKSPACE_PATH/$FIRST_PROJECT_NAME"

echo ""
echo "=== 3. First run (installer) ==="
VERDICT1="$(bash "$REPO_ROOT/install.sh" --source "$REPO_ROOT" --answers-file "$ANSWERS_PATH" --test-mode --test-root "$TEST_ROOT")"
EXIT1=$?
echo "  verdict: $VERDICT1"
[ "$EXIT1" = "0" ]; assert_true "$?" "first run exits 0"
case "$VERDICT1" in *"Installation complete"*) r=0 ;; *) r=1 ;; esac
assert_true "$r" "first run verdict reports success"
LINE_COUNT="$(printf '%s\n' "$VERDICT1" | wc -l)"
[ "$LINE_COUNT" = "1" ]; assert_true "$?" "silent mode (--answers-file) prints exactly one line, never a question"
case "$VERDICT1" in *"first name"*|*"assistant"*|*"workspace live"*|*"Question"*) r=1 ;; *) r=0 ;; esac
assert_true "$r" "silent mode output contains no question-prompt text"

# On a runner with no uv preinstalled (every GitHub-hosted Ubuntu runner),
# install.sh above bootstraps uv under its own --test-root profile, but as
# a genuine child process (`bash install.sh` in a `$(...)` command
# substitution) -- so that PATH update dies with it, exactly the same
# shape already fixed on the Windows/PowerShell side of this Mission
# (tests/test-nominal-flow-no-atelier-vocabulary.ps1, Start-Process). This
# script's own later trial commit (step 5) then fails with "exec: uv: not
# found" at guardians `vault-check-indexes-fresh`/`vault-check-index-weight`
# (measured, CI run 34922227006, job Ubuntu -- install.sh, full suite).
# Fixed by reusing the profile bin install.sh already made, on this
# process's own PATH.
TEST_PROFILE_UV_BIN="$TEST_ROOT/profile/.local/bin"
[ -d "$TEST_PROFILE_UV_BIN" ] && PATH="$TEST_PROFILE_UV_BIN:$PATH"

echo ""
echo "=== 4. Workspace conformity tool: tools/session-preflight.sh -> READY ==="
PREFLIGHT_OUTPUT="$(cd "$CLONE_PATH" && bash tools/session-preflight.sh)"
PREFLIGHT_EXIT=$?
echo "  output: $PREFLIGHT_OUTPUT"
[ "$PREFLIGHT_EXIT" = "0" ]; assert_true "$?" "session-preflight.sh exits 0"
case "$PREFLIGHT_OUTPUT" in *READY*) r=0 ;; *) r=1 ;; esac
assert_true "$r" "session-preflight.sh reports READY"

echo ""
echo "=== 5. Trial commit in the first project passes all guardians ==="
(
  cd "$FIRST_PROJECT_PATH" || exit 1
  bash "$CLONE_PATH/tools/append-journal.sh" '.' 'STATE: trial commit for Mission 168 ticket 08 main test' >/dev/null
  git add -- state/journal.md
  git commit -q -m "Trial commit: ticket 08 main test"
)
COMMIT_EXIT=$?
[ "$COMMIT_EXIT" = "0" ]; assert_true "$?" "trial commit passes guardians (git commit exits 0)"

echo ""
echo "=== 6. Second run (installer) is a true no-op ==="
VERDICT2="$(bash "$REPO_ROOT/install.sh" --source "$REPO_ROOT" --answers-file "$ANSWERS_PATH" --test-mode --test-root "$TEST_ROOT")"
EXIT2=$?
echo "  verdict: $VERDICT2"
[ "$EXIT2" = "0" ]; assert_true "$?" "second run exits 0"
[ "$VERDICT2" = "$VERDICT1" ]; assert_true "$?" "second run verdict is identical to the first"

CLONE_PORCELAIN="$(git -C "$CLONE_PATH" status --porcelain)"
PROJECT_PORCELAIN="$(git -C "$FIRST_PROJECT_PATH" status --porcelain)"
[ -z "$CLONE_PORCELAIN" ]; assert_true "$?" "second-brain clone porcelain is empty after the second run"
[ -z "$PROJECT_PORCELAIN" ]; assert_true "$?" "first project porcelain is empty after the second run"

echo ""
echo "=== 7. Real-environment fingerprint (after) ==="
AFTER="$(environment_fingerprint "$HOME/.profile")"
echo "$AFTER" | sed 's/^/  /'
[ "$BEFORE" = "$AFTER" ]; assert_true "$?" "real environment fingerprint (PATH file, skill folders) is identical before/after"

if [ "$KEEP_TEMP" = "0" ]; then
  rm -rf -- "$TEST_ROOT"
  echo ""
  echo "TestRoot removed: $TEST_ROOT"
else
  echo ""
  echo "TestRoot kept (--keep-temp): $TEST_ROOT"
fi

echo ""
if [ "$FAILURES" = "0" ]; then
  echo "=== RESULT: PASS (all checks green) ==="
  exit 0
else
  echo "=== RESULT: FAIL ($FAILURES check(s) failed) ==="
  exit 1
fi
