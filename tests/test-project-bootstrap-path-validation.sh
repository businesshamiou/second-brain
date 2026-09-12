#!/usr/bin/env bash
# Target-path validation test for tools/project-bootstrap.sh (Mission
# 171-C01, step 3 -- same-family defect named in the Mission: this tool
# accepted a relative target path, or one inside the Vault repository
# itself, with no validation at all).
#
# Rerun this exact test with one command, from the repository root:
#
#   bash tests/test-project-bootstrap-path-validation.sh
#
# Runs the script directly, in place, against THIS repository -- safe for
# the two refusal cases below because the target-path validation added by
# this ticket is the very first thing the script does (before any
# dependency check, before any `mkdir`, before touching projects/ or
# git-init'ing anything): a refused case is guaranteed to `exit 1` before
# a single byte is written anywhere. Never do this for an ACCEPTED case --
# that one genuinely writes a project fiche and a registry row, and must
# run against a disposable clone instead (see
# tests/standalone.sh's own step (a), which already covers exactly that:
# a valid absolute target path, a sibling of a cloned Vault, accepted and
# fully scaffolded -- not duplicated here). A prior version of this test
# tried to validate the accepted case with its own throwaway `git clone`;
# measured directly: a local `git clone` reads the SOURCE REPOSITORY'S
# COMMITTED HISTORY, not its working tree, so against an uncommitted fix
# it silently exercised the OLD, unfixed script and wrote a stray fiche
# into the clone's own projects/ -- worth naming here so nobody
# reintroduces it.
#
# Two cases, both run directly against this repository's own
# tools/project-bootstrap.sh (no clone, no write):
#   1. A relative target path is refused, with a cause-naming message.
#   2. A target path INSIDE this repository is refused the same way.
#
# Exit code 0 means every assertion passed. Exit code 1 means at least one
# did not; details are printed to stdout as each check runs.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP="$REPO_ROOT/tools/project-bootstrap.sh"
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

echo "=== 1. Relative target path: refused, before any write ==="
BEFORE_1="$(git -C "$REPO_ROOT" status --porcelain)"
OUTPUT_1="$(bash "$BOOTSTRAP" "relative/path" "Test Project" 2>&1)"
EXIT_1=$?
AFTER_1="$(git -C "$REPO_ROOT" status --porcelain)"
echo "$OUTPUT_1" | sed 's/^/  /'
[ "$EXIT_1" = "1" ]; assert_true "$?" "exits 1 for a relative target path"
case "$OUTPUT_1" in *"chemin cible non absolu"*) r=0 ;; *) r=1 ;; esac
assert_true "$r" "a cause-naming message is printed (chemin cible non absolu)"
[ "$BEFORE_1" = "$AFTER_1" ]; assert_true "$?" "this repository's own porcelain is unchanged (nothing was written)"

echo ""
echo "=== 2. Target path inside this repository: refused, before any write ==="
BEFORE_2="$(git -C "$REPO_ROOT" status --porcelain)"
OUTPUT_2="$(bash "$BOOTSTRAP" "$REPO_ROOT/projects/some-new-project" "Test Project" 2>&1)"
EXIT_2=$?
AFTER_2="$(git -C "$REPO_ROOT" status --porcelain)"
echo "$OUTPUT_2" | sed 's/^/  /'
[ "$EXIT_2" = "1" ]; assert_true "$?" "exits 1 for a target path inside this repository"
case "$OUTPUT_2" in *"a l'interieur du depot Vault"*) r=0 ;; *) r=1 ;; esac
assert_true "$r" "a cause-naming message is printed (a l'interieur du depot Vault)"
[ ! -e "$REPO_ROOT/projects/some-new-project" ]; assert_true "$?" "nothing was written for the refused target"
[ "$BEFORE_2" = "$AFTER_2" ]; assert_true "$?" "this repository's own porcelain is unchanged (nothing was written)"

echo ""
echo "Note: the accepted case (a valid absolute target path outside the"
echo "repository) is exercised by tests/standalone.sh's own step (a), which"
echo "already runs project-bootstrap.sh against a disposable clone and"
echo "asserts the project directory, README.md and guardian pin it creates."

echo ""
if [ "$FAILURES" = "0" ]; then
  echo "=== RESULT: PASS (all checks green) ==="
  exit 0
else
  echo "=== RESULT: FAIL ($FAILURES check(s) failed) ==="
  exit 1
fi
