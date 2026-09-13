#!/usr/bin/env bash
# Sibling-repository declaration test (Mission 174, step 3, T21).
#
# Rerun with one command, from the repository root:
#
#   bash tests/test-sibling-repo-declaration.sh
#
# Proves tools/resolve-sibling-repo.sh's contract, exercised through
# tools/session-preflight.sh (the guardian that actually displays a
# sibling-related message to a participant):
#   1. No declaration -- silence, even when a same-named folder happens to
#      exist next to the workspace (never searched unless declared).
#   2. Declared (env var) and present -- full check against the sibling's
#      own AGENTS.md/CLAUDE.md pointers, no sibling-related warning.
#   3. Declared (env var) and absent -- exactly one clear warning, READY
#      still reported (a warning is never a failure).
#   4. Declared via the workspace-root SIBLING-REPO.txt file (no env var)
#      and present -- same full check as case 2, proving the second
#      declaration form works identically.
#
# Sandbox only: builds a disposable fake workspace per case, touches
# nothing under the real repository or the real profile.
#
# Exit code 0 means every assertion passed. Exit code 1 means at least one
# did not; details are printed to stdout as each check runs.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FAILURES=0

assert_true() {
  local condition="$1" message="$2"
  if [ "$condition" -eq 0 ]; then
    echo "  PASS - $message"
  else
    echo "  FAIL - $message"
    FAILURES=$((FAILURES + 1))
  fi
}

make_fake_clone() {
  # $1 = path to create a minimal fake second-brain clone at
  local clone="$1"
  mkdir -p "$clone/tools" "$clone/rules"
  cp "$REPO_ROOT/tools/session-preflight.sh" "$clone/tools/session-preflight.sh"
  cp "$REPO_ROOT/tools/resolve-sibling-repo.sh" "$clone/tools/resolve-sibling-repo.sh"
  cp "$REPO_ROOT/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md" \
     "$clone/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  cat > "$clone/AGENTS.md" <<'EOF'
See rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md
EOF
  cp "$clone/AGENTS.md" "$clone/CLAUDE.md"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo ""
echo "=== 1. No declaration: silence, even with a same-named folder present ==="
WS1="$TMP/case1"
mkdir -p "$WS1"
make_fake_clone "$WS1/second-brain"
mkdir -p "$WS1/workshop-build"   # present on disk, never declared
OUT1="$(cd "$WS1/second-brain" && bash tools/session-preflight.sh 2>&1)"
case "$OUT1" in
  *sibling*|*"depot frere"*) assert_true 1 "no sibling-related line appears without a declaration" ;;
  *) assert_true 0 "no sibling-related line appears without a declaration" ;;
esac
case "$OUT1" in *READY*) assert_true 0 "still READY with no declaration" ;; *) assert_true 1 "still READY with no declaration" ;; esac

echo ""
echo "=== 2. Declared (env var) and present: full check ==="
WS2="$TMP/case2"
mkdir -p "$WS2"
make_fake_clone "$WS2/second-brain"
make_fake_clone "$WS2/workshop-build"
OUT2="$(cd "$WS2/second-brain" && SECOND_BRAIN_SIBLING_REPO=workshop-build bash tools/session-preflight.sh 2>&1)"
case "$OUT2" in
  *"warning:"*) assert_true 1 "no warning when the declared sibling is present and valid" ;;
  *) assert_true 0 "no warning when the declared sibling is present and valid" ;;
esac
case "$OUT2" in *READY*) assert_true 0 "READY with a present, valid declared sibling" ;; *) assert_true 1 "READY with a present, valid declared sibling" ;; esac

echo ""
echo "=== 3. Declared (env var) and absent: exactly one clear warning ==="
WS3="$TMP/case3"
mkdir -p "$WS3"
make_fake_clone "$WS3/second-brain"
OUT3="$(cd "$WS3/second-brain" && SECOND_BRAIN_SIBLING_REPO=workshop-build bash tools/session-preflight.sh 2>&1)"
WARNING_COUNT="$(printf '%s\n' "$OUT3" | grep -c '^  - warning:')"
[ "$WARNING_COUNT" -eq 1 ]; assert_true "$?" "exactly one warning line (got $WARNING_COUNT)"
case "$OUT3" in
  *"workshop-build"*"not found"*) assert_true 0 "the warning names the declared sibling and says it was not found" ;;
  *) assert_true 1 "the warning names the declared sibling and says it was not found" ;;
esac
case "$OUT3" in *READY*) assert_true 0 "still READY: a warning is never a failure" ;; *) assert_true 1 "still READY: a warning is never a failure" ;; esac

echo ""
echo "=== 4. Declared via workspace-root SIBLING-REPO.txt (no env var), present ==="
WS4="$TMP/case4"
mkdir -p "$WS4"
make_fake_clone "$WS4/second-brain"
make_fake_clone "$WS4/workshop-build"
printf 'workshop-build\n' > "$WS4/SIBLING-REPO.txt"
OUT4="$(cd "$WS4/second-brain" && bash tools/session-preflight.sh 2>&1)"
case "$OUT4" in
  *"warning:"*) assert_true 1 "no warning when SIBLING-REPO.txt declares a present, valid sibling" ;;
  *) assert_true 0 "no warning when SIBLING-REPO.txt declares a present, valid sibling" ;;
esac
case "$OUT4" in *READY*) assert_true 0 "READY with a file-declared, present sibling" ;; *) assert_true 1 "READY with a file-declared, present sibling" ;; esac

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "=== FAILURES ($FAILURES) ==="
  exit 1
fi
echo "All assertions passed."
exit 0
