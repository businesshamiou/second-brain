#!/usr/bin/env bash
# Mission 189, T2: the suite holds on the checkout a tag event gives CI -- a
# detached HEAD with no branch at all. The v0.1.6 tag run went red on a test
# that assumed a main branch (report 187); this plays the whole suite in
# that state so any other such test shows up.
#
# Oracle (PASS expected): a clone of this commit with a detached HEAD and no
#   local branch (git init + fetch HEAD + checkout --detach, as
#   actions/checkout does for a tag) plays the suite of this platform
#   through tests/run-suite.sh with no blocking red.
# Negative control: in the same clone, a trial manifest holding one test
#   that requires HEAD to be on main makes the runner fail, and names it.
#
# The inner run sets SB_DETACHED_RUN=1: this test then reports SKIP instead
# of starting itself again. SB_T2_MANIFEST (optional) replaces the suite
# played inside, for a quick local check of the mechanism.
#
# usage: bash tests/test-suite-on-detached-head.sh

set -u

if [ "${SB_DETACHED_RUN:-}" = "1" ]; then
  echo "SKIP (inside the detached-HEAD run of this same test)"
  exit 77
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m189-detached-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD)"

echo "=== T2 : the suite on a detached HEAD with no branch ==="
C="$TMP/clone"
git init -q "$C" \
  && git -C "$C" config core.longpaths true \
  && git -C "$C" fetch -q --no-tags "$REPO_ROOT" HEAD \
  && git -C "$C" -c advice.detachedHead=false checkout -q --detach FETCH_HEAD \
  || { echo "FAIL : detached clone not built"; exit 1; }
BRANCHES="$(git -C "$C" for-each-ref refs/heads | wc -l | tr -d ' ')"
if [ "$(git -C "$C" rev-parse HEAD)" = "$HEAD" ] && ! git -C "$C" symbolic-ref -q HEAD >/dev/null && [ "$BRANCHES" = "0" ]; then
  pass "clone at $HEAD, HEAD detached, $BRANCHES local branch"
else
  fail "clone not in the tag-event state (branches: $BRANCHES)"
fi

MANIFEST_ARGS=""
[ -n "${SB_T2_MANIFEST:-}" ] && MANIFEST_ARGS="--manifest $SB_T2_MANIFEST"
# shellcheck disable=SC2086 -- optional, plain word list
( cd "$C" && SB_DETACHED_RUN=1 bash tests/run-suite.sh $MANIFEST_ARGS ) > "$TMP/run.out" 2>&1
RC=$?
RESULT="$(grep '^RESULT:' "$TMP/run.out" | tail -n 1)"
if [ "$RC" -eq 0 ] && [ -n "$RESULT" ]; then
  pass "the suite plays with no blocking red on the detached clone -- $RESULT"
else
  fail "the suite on the detached clone: exit $RC -- $RESULT"
  grep -E '^FAIL ' "$TMP/run.out" | sed 's/^/    /'
fi

echo "=== negative control ==="
cat > "$TMP/needs-main.sh" <<'EOF'
#!/usr/bin/env bash
# Trial test: requires the checkout to be on main.
[ "$(git symbolic-ref -q --short HEAD)" = "main" ] || { echo "not on main"; exit 1; }
EOF
printf '%s\t-\tbash\tWUM\tblocking\ttrial -- requires main\t1\n' "$TMP/needs-main.sh" > "$TMP/trial.tsv"
( cd "$C" && SB_DETACHED_RUN=1 bash tests/run-suite.sh --manifest "$TMP/trial.tsv" ) > "$TMP/trial.out" 2>&1
TRC=$?
if [ "$TRC" -ne 0 ] && grep -E '^FAIL ' "$TMP/trial.out" | grep -q 'needs-main.sh'; then
  pass "control: a test that requires main fails on the detached clone, named"
else
  fail "control: a test that requires main was not caught (exit $TRC)"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
