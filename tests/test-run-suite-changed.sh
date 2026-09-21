#!/usr/bin/env bash
# Mission 209: `run-suite.sh --changed [<ref>]` plays only the manifest lines
# that the changed files call for, the two guardian lines always, and says so.
#
# Oracle (PASS expected), all in a throwaway Git repository holding a copy of
# the runner (bash and PowerShell) and a seven-line trial manifest, so nothing
# of the real Vault is touched:
#   1. clean tree: exactly the two guardian lines, message "2 ... sur 7", and
#      the witness -- the same manifest without --changed -- lists all seven;
#   2. a tool touched: the guardians, plus every line whose path OR origin
#      column contains the tool's name without extension, case-insensitively
#      (one line is reached through its origin only, spelled in capitals);
#      the witness: a tool no test names selects only the two guardians and
#      the message says that nothing names it;
#   3. the manifest or the runner touched: the whole suite (the tool that
#      tests is itself changed);
#   4. untracked files count as changed (arbitration, tested both ways: the
#      witness line is selected while its file is untracked, not once gone);
#      a generated index file names no test;
#   5. --shard combines with --changed as an intersection;
#   6. <ref> given (HEAD~1) selects what changed since it; an unknown ref is
#      refused (exit 2) and nothing is listed;
#   7. the PowerShell twin (run-suite.ps1 -Changed [-Ref <ref>] -List) lists
#      exactly what the bash runner lists, on the same states.
# Without --changed the runner is unchanged: that is the job of
# test-run-suite-reports-red.sh, test-shards-cover-suite.sh,
# test-suite-manifest-matches-ci.sh and test-suite-on-detached-head.sh.
#
# usage: bash tests/test-run-suite-changed.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m209-changed-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
R="$TMP/repo"

G1="tools/session-preflight.sh"
G2=".githooks/pre-commit"
T_MCP="tests/test-vault-mcp.sh"
T_INST="tests/test-install-vault-mcp-thing.sh"
T_ORIG="tests/test-covers-other.sh"
T_UNREL="tests/test-unrelated.sh"
T_WIT="tests/test-zz-witness.sh"

echo "=== M209 : run-suite.sh --changed ==="

# --- The throwaway repository ----------------------------------------------
mkdir -p "$R/tests" "$R/tools" "$R/.githooks"
cp "$REPO_ROOT/tests/run-suite.sh" "$REPO_ROOT/tests/run-suite.ps1" "$R/tests/"
for f in "$G1" "$G2" tools/vault-mcp.py tools/resolve-sibling-repo.sh "$T_MCP" "$T_INST" "$T_ORIG" "$T_UNREL" tests/index.md; do
  printf 'x\n' > "$R/$f"
done
{
  printf '# trial manifest\n'
  printf '%s\t-\tbash+uv\tWUM\tblocking\tM168 -- guardians\t1\n' "$G1"
  printf '%s\t-\tbash+uv\tWUM\tblocking\tM168 -- guardians\t1\n' "$G2"
  printf '%s\t-\tbash\tWUM\tblocking\tM184 -- embedded server\t1\n' "$T_MCP"
  printf '%s\t-\tbash\tWUM\tblocking\tM191 -- install\t2\n' "$T_INST"
  printf '%s\t-\tbash\tWUM\tblocking\tM200 -- covers the Vault-MCP server by its origin only\t2\n' "$T_ORIG"
  printf '%s\t-\tbash\tWUM\tblocking\tM201 -- something else\t3\n' "$T_UNREL"
  printf '%s\t-\tbash\tWUM\tblocking\tM209 -- witness line\t3\n' "$T_WIT"
} > "$R/tests/suite.tsv"
git -C "$R" init -q 2>/dev/null
G="git -C $R -c user.email=t@example.invalid -c user.name=t -c commit.gpgsign=false -c core.autocrlf=false"
$G add -A && $G commit -q -m base || { fail "throwaway repository not created"; exit 1; }

changed_list() { # args passed to the runner after --changed ; prints paths, one per line
  ( cd "$R" && bash tests/run-suite.sh --platform W "$@" --list 2>"$TMP/err" | cut -f1 )
}
reset_tree() { $G checkout -q -- . ; $G clean -q -fd ; }
lines() { printf '%s\n' "$1" | sed '/^$/d' | wc -l | tr -d ' '; }
same_set() { [ "$(printf '%s\n' "$1" | sed '/^$/d' | sort)" = "$(printf '%s\n' "$2" | sed '/^$/d' | sort)" ]; }
nl='
'

# --- 1. clean tree ---------------------------------------------------------
out="$(changed_list --changed)"
if same_set "$out" "$G1$nl$G2"; then pass "clean tree: exactly the two guardian lines"; else fail "clean tree: expected the two guardians, got: $(echo "$out" | tr '\n' ' ')"; fi
if grep -q -- '--changed : 2 ligne(s) selectionnee(s) sur 7' "$TMP/err"; then pass "clean tree: the runner says '2 ... sur 7'"; else fail "clean tree: message missing: $(cat "$TMP/err")"; fi
out="$(changed_list)"
if [ "$(lines "$out")" = "7" ]; then pass "witness: without --changed the same manifest lists 7 lines"; else fail "witness: without --changed expected 7 lines, got $(lines "$out")"; fi

# --- 2. a tool touched -----------------------------------------------------
printf 'y\n' >> "$R/tools/vault-mcp.py"
out="$(changed_list --changed)"
if same_set "$out" "$G1$nl$G2$nl$T_MCP$nl$T_INST$nl$T_ORIG"; then
  pass "tool touched: guardians + the three lines naming vault-mcp (one by origin only, other case)"
else fail "tool touched: got: $(echo "$out" | tr '\n' ' ')"; fi
if grep -q -- '--changed : 5 ligne(s) selectionnee(s) sur 7' "$TMP/err"; then pass "tool touched: message '5 ... sur 7'"; else fail "tool touched: message: $(cat "$TMP/err")"; fi
reset_tree
printf 'y\n' >> "$R/tools/resolve-sibling-repo.sh"
out="$(changed_list --changed)"
if same_set "$out" "$G1$nl$G2"; then pass "witness: a tool no test names selects only the two guardians"; else fail "witness: got: $(echo "$out" | tr '\n' ' ')"; fi
if grep -q 'aucun test ne nomme les fichiers changes' "$TMP/err"; then pass "witness: the runner says that no test names the change"; else fail "witness: silent: $(cat "$TMP/err")"; fi
reset_tree

# --- 3. the manifest or the runner touched ---------------------------------
printf '# touched\n' >> "$R/tests/suite.tsv"
out="$(changed_list --changed)"
if [ "$(lines "$out")" = "7" ]; then pass "manifest touched: the whole suite (7 lines)"; else fail "manifest touched: got $(lines "$out") lines"; fi
if grep -q 'toute la suite est selectionnee' "$TMP/err"; then pass "manifest touched: the runner says the whole suite is selected"; else fail "manifest touched: message: $(cat "$TMP/err")"; fi
reset_tree
printf '# touched\n' >> "$R/tests/run-suite.sh"
out="$(changed_list --changed)"
if [ "$(lines "$out")" = "7" ]; then pass "runner touched: the whole suite (7 lines)"; else fail "runner touched: got $(lines "$out") lines"; fi
reset_tree

# --- 4. untracked files, generated index -----------------------------------
printf 'x\n' > "$R/$T_WIT"
out="$(changed_list --changed)"
if same_set "$out" "$G1$nl$G2$nl$T_WIT"; then pass "untracked file: counted as changed, its line is selected"; else fail "untracked file present: got: $(echo "$out" | tr '\n' ' ')"; fi
rm -f "$R/$T_WIT"
out="$(changed_list --changed)"
if same_set "$out" "$G1$nl$G2"; then pass "untracked file removed: not selected any more"; else fail "untracked file removed: got: $(echo "$out" | tr '\n' ' ')"; fi
printf 'y\n' >> "$R/tests/index.md"
out="$(changed_list --changed)"
if same_set "$out" "$G1$nl$G2"; then pass "generated index touched: names no test, two guardians only"; else fail "index touched: got: $(echo "$out" | tr '\n' ' ')"; fi
reset_tree

# --- 5. --shard + --changed: intersection ----------------------------------
printf 'y\n' >> "$R/tools/vault-mcp.py"
out="$(changed_list --shard 1/3 --changed)"
if same_set "$out" "$G1$nl$G2$nl$T_MCP"; then pass "--shard 1/3 --changed: the intersection (3 lines)"; else fail "shard intersection: got: $(echo "$out" | tr '\n' ' ')"; fi
if grep -q -- '--changed : 3 ligne(s) selectionnee(s) sur 3' "$TMP/err"; then pass "--shard 1/3 --changed: '3 ... sur 3' counts the shard"; else fail "shard message: $(cat "$TMP/err")"; fi
reset_tree

# --- 6. <ref>, unknown ref -------------------------------------------------
printf 'y\n' >> "$R/tools/vault-mcp.py"
$G add -A && $G commit -q -m touch-tool
out="$(changed_list --changed)"
if same_set "$out" "$G1$nl$G2"; then pass "committed change, default ref HEAD (no origin/main): nothing new, two guardians"; else fail "default ref: got: $(echo "$out" | tr '\n' ' ')"; fi
out="$(changed_list --changed HEAD~1)"
if same_set "$out" "$G1$nl$G2$nl$T_MCP$nl$T_INST$nl$T_ORIG"; then pass "--changed HEAD~1: what changed since that commit"; else fail "--changed HEAD~1: got: $(echo "$out" | tr '\n' ' ')"; fi
out="$( cd "$R" && bash tests/run-suite.sh --platform W --changed no-such-ref --list 2>"$TMP/err"; echo "exit=$?" )"
if [ "$out" = "exit=2" ] && grep -q "unknown ref 'no-such-ref'" "$TMP/err"; then pass "unknown ref: refused, exit 2, nothing listed"; else fail "unknown ref: out='$out' err=$(cat "$TMP/err")"; fi

# --- 7. the PowerShell twin gives the same selection -----------------------
PS=""
if command -v powershell >/dev/null 2>&1; then PS="powershell -NoProfile -ExecutionPolicy Bypass -File"
elif command -v pwsh >/dev/null 2>&1; then PS="pwsh -NoProfile -File"; fi
if [ -z "$PS" ]; then
  echo "  SKIP (no PowerShell here) - parity of run-suite.ps1 -Changed"
else
  PS1="$R/tests/run-suite.ps1"
  command -v cygpath >/dev/null 2>&1 && PS1="$(cygpath -w "$PS1")"
  parity() { # $1 = label, $2 = bash extra args, $3 = powershell extra args
    b="$(cd "$R" && bash tests/run-suite.sh --platform W $2 --list 2>/dev/null | tr -d '\r')"
    # shellcheck disable=SC2086
    p="$(cd "$R" && $PS "$PS1" $3 -List 2>/dev/null | tr -d '\r')"
    if [ -n "$b" ] && [ "$b" = "$p" ]; then pass "parity .sh/.ps1: $1 ($(lines "$b") lines, diff empty)"; else fail "parity .sh/.ps1: $1 differs: bash=[$(echo "$b" | tr '\n' ' ')] ps1=[$(echo "$p" | tr '\n' ' ')]"; fi
  }
  reset_tree
  parity "clean tree" "--changed" "-Changed"
  printf 'y\n' >> "$R/tools/vault-mcp.py"
  parity "tool touched" "--changed" "-Changed"
  parity "tool touched, shard 1/3" "--shard 1/3 --changed" "-Shard 1/3 -Changed"
  reset_tree
  printf 'y\n' >> "$R/tools/resolve-sibling-repo.sh"
  parity "a tool no test names" "--changed" "-Changed"
  reset_tree
  printf '# touched\n' >> "$R/tests/suite.tsv"
  parity "manifest touched" "--changed" "-Changed"
  reset_tree
  printf 'x\n' > "$R/$T_WIT"
  parity "untracked file" "--changed" "-Changed"
  reset_tree
  parity "explicit ref" "--changed HEAD~1" "-Changed -Ref HEAD~1"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
