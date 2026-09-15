#!/usr/bin/env bash
# Workspace-path validation test for install.sh (Mission 171-C01, step 3;
# spec -- "L'espace de travail n'est accepte que si le chemin est absolu et
# hors du depot source ; sinon message qui nomme la cause, propose un
# chemin valide, et repose la question. oui, non, y, n et une chaine vide
# sont refuses comme chemins.").
#
# Rerun this exact test with one command, from the repository root:
#
#   bash tests/test-install-workspace-path-validation.sh
#
# Drives install.sh's INTERACTIVE questionnaire via --scripted-answers
# (its own test-only replay queue -- never a real terminal), stopped right
# after the 'workspace' step (--stop-after-step, the same forced-stop
# mechanism tests/test-questionnaire-resume.ps1 uses on the Windows side)
# so each case runs in a couple of seconds: no git clone, no uv, no
# pre-commit involved, only the language/assistant-name/workspace-path
# questions and the workspace `mkdir`.
#
# Four cases, each in its own fresh --test-root (Mission constraint: never
# the real $HOME):
#   1. A relative path is refused (a cause-naming message is printed, the
#      question is asked again), then a valid absolute path outside the
#      source repository is accepted.
#   2. 'oui' is refused the same way, then a valid path is accepted --
#      this is Defect 2's own physical proof: the literal 'oui' folder
#      found under _trash-oui-20260912 (out of this Mission's scope,
#      never touched here) is exactly what this case exists to prevent.
#   3. A path INSIDE the source repository (the repository this test
#      itself runs from) is refused, then a valid path outside it is
#      accepted.
#   4. A valid absolute path outside the source repository is accepted on
#      the very first try -- no error message, no re-ask.
#
# Exit code 0 means every assertion passed. Exit code 1 means at least one
# did not; details are printed to stdout as each check runs.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$REPO_ROOT/install.sh"
FAILURES=0

assert_true() {
  # $1 = 0/1 condition (shell truth: 0 = pass), $2 = message.
  if [ "$1" = "0" ]; then
    echo "  PASS - $2"
  else
    echo "  FAIL - $2"
    FAILURES=$((FAILURES + 1))
  fi
}

run_workspace_case() {
  # $1 = test-root, remaining = the --scripted-answers values for the
  # language/assistant-name/workspace-path questions, in order. Always
  # stops right after the 'workspace' step (a forced stop, never a real
  # failure) -- so a workspace directory existing at $1/workspace is this
  # function's own proof that the loop eventually accepted an answer.
  local test_root="$1"; shift
  local args=(--source "$REPO_ROOT" --test-mode --test-root "$test_root")
  local answer
  for answer in "$@"; do
    args+=(--scripted-answers "$answer")
  done
  args+=(--stop-after-step workspace)
  OUTPUT="$(timeout 60 bash "$INSTALL_SCRIPT" "${args[@]}" 2>&1)"
  EXIT_CODE=$?
}

echo "=== 1. Relative path: refused, then a valid absolute path is accepted ==="
TEST_ROOT_1="$(mktemp -d "${TMPDIR:-/tmp}/sb-wksp-XXXXXX")"
run_workspace_case "$TEST_ROOT_1" "EN" "TestBrian" "relative/path" "$TEST_ROOT_1/workspace"
echo "$OUTPUT" | sed 's/^/  /'
[ "$EXIT_CODE" = "1" ]; assert_true "$?" "forced stop still reached (exit 1) -- the loop did not hang or crash"
case "$OUTPUT" in *"'relative/path' is not an absolute path"*) r=0 ;; *) r=1 ;; esac
assert_true "$r" "a cause-naming message is printed for the relative path"
case "$OUTPUT" in *"Forced stop for testing, after step: workspace"*) r=0 ;; *) r=1 ;; esac
assert_true "$r" "the question was re-asked and eventually reached the workspace step"
[ -d "$TEST_ROOT_1/workspace" ]; assert_true "$?" "the second, valid answer was accepted (workspace directory created)"
rm -rf -- "$TEST_ROOT_1"

echo ""
echo "=== 2. 'oui': refused, then a valid absolute path is accepted (Defect 2) ==="
TEST_ROOT_2="$(mktemp -d "${TMPDIR:-/tmp}/sb-wksp-XXXXXX")"
run_workspace_case "$TEST_ROOT_2" "EN" "TestBrian" "oui" "$TEST_ROOT_2/workspace"
echo "$OUTPUT" | sed 's/^/  /'
[ "$EXIT_CODE" = "1" ]; assert_true "$?" "forced stop still reached (exit 1)"
case "$OUTPUT" in *"'oui' is not a workspace path"*) r=0 ;; *) r=1 ;; esac
assert_true "$r" "a cause-naming message is printed for 'oui' (never silently accepted as a path)"
[ -d "$TEST_ROOT_2/workspace" ]; assert_true "$?" "the second, valid answer was accepted (workspace directory created)"
[ ! -e "$TEST_ROOT_2/oui" ]; assert_true "$?" "no folder literally named 'oui' was ever created (the _trash-oui-20260912 defect, reproduced and closed)"
rm -rf -- "$TEST_ROOT_2"

echo ""
echo "=== 3. Path inside the source repository: refused, then a valid path is accepted ==="
TEST_ROOT_3="$(mktemp -d "${TMPDIR:-/tmp}/sb-wksp-XXXXXX")"
run_workspace_case "$TEST_ROOT_3" "EN" "TestBrian" "$REPO_ROOT" "$TEST_ROOT_3/workspace"
echo "$OUTPUT" | sed 's/^/  /'
[ "$EXIT_CODE" = "1" ]; assert_true "$?" "forced stop still reached (exit 1)"
case "$OUTPUT" in *"is inside the source repository"*) r=0 ;; *) r=1 ;; esac
assert_true "$r" "a cause-naming message is printed for a path inside the source repository"
[ -d "$TEST_ROOT_3/workspace" ]; assert_true "$?" "the second, valid answer was accepted (workspace directory created)"
rm -rf -- "$TEST_ROOT_3"

echo ""
echo "=== 4. Valid absolute path outside the source: accepted on the first try ==="
TEST_ROOT_4="$(mktemp -d "${TMPDIR:-/tmp}/sb-wksp-XXXXXX")"
run_workspace_case "$TEST_ROOT_4" "EN" "TestBrian" "$TEST_ROOT_4/workspace"
echo "$OUTPUT" | sed 's/^/  /'
[ "$EXIT_CODE" = "1" ]; assert_true "$?" "forced stop reached (exit 1) -- the only failure this run should hit"
case "$OUTPUT" in *"is not an absolute path"*|*"is not a workspace path"*|*"is inside the source repository"*) r=1 ;; *) r=0 ;; esac
assert_true "$r" "no validation error is printed for an already-valid path"
[ -d "$TEST_ROOT_4/workspace" ]; assert_true "$?" "the workspace directory was created at the given valid path"
rm -rf -- "$TEST_ROOT_4"

echo ""
if [ "$FAILURES" = "0" ]; then
  echo "=== RESULT: PASS (all checks green) ==="
  exit 0
else
  echo "=== RESULT: FAIL ($FAILURES check(s) failed) ==="
  exit 1
fi
