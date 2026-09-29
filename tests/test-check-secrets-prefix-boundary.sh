#!/usr/bin/env bash
# Mission 229, step 1: the `sk-` pattern of rules/patterns/secret-patterns.txt
# took an ordinary word -- `risk-assessment-2026-09-20`, `task-based-...` --
# and refused a legitimate commit in skills-warehouse. The pattern now needs a
# word boundary before its prefix: start of line or a character that is not a
# letter or a digit. It must lose no real secret.
#
#   (p) true positives, each refused and refused BY the sk- line: the key at
#       the start of a line, after =, ", ', :, a space, and in folder mode
#       (whole content, a real start of line, no "+" from the diff);
#   (n) true negatives, each accepted: the prefix inside a word (risk-, task-,
#       disk-, desk-, ask-);
#   (w) witness: the same negative lines are refused by the old pattern
#       (without the boundary), so this test can fail.
#
# The positive keys are built at run time from two pieces: the contiguous
# string must never sit in this tracked file, or the real guardian would
# refuse this very file (same device as test-guardian-secret-refusal.sh).
#
# usage: bash tests/test-check-secrets-prefix-boundary.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$REPO_ROOT/tools/check-secrets.sh"
PATTERNS="$REPO_ROOT/rules/patterns/secret-patterns.txt"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m229-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

R="$TMP/repo"
mkdir -p "$R"
git init -q "$R"

KEY_PREFIX='sk-'
KEY="${KEY_PREFIX}proj0123456789ABCDEFghij"
ANT="${KEY_PREFIX}ant-api03-0123456789abcdefABCDEF"

# judge LINE: stage LINE alone in note.md, run the guardian; prints its exit
# code and keeps its output in $TMP/out.
judge() {
  printf '%s\n' "$1" > "$R/note.md"
  ( cd "$R" && git add -- note.md && bash "$GUARD" ) >"$TMP/out" 2>&1
  echo $?
  ( cd "$R" && git rm -q --cached -- note.md )
}

refused_by_sk() { grep -q '^  motif : .*sk-' "$TMP/out"; }

# --- (p) true positives --------------------------------------------------------
for line in \
  "$KEY" \
  "OPENAI_KEY=$KEY" \
  "\"key\": \"$KEY\"" \
  "key='$KEY'" \
  "key:$KEY" \
  "export the key $KEY now" \
  "ANTHROPIC_KEY=$ANT"; do
  label="$(printf '%s' "$line" | sed "s/${KEY_PREFIX}[0-9A-Za-z_-]*/<key>/")"
  RC="$(judge "$line")"
  if [ "$RC" != 0 ] && refused_by_sk; then
    pass "(p) refuse par la ligne sk- : $label"
  else
    fail "(p) vrai positif perdu (rc=$RC) : $label"
  fi
done

# Folder mode: whole content, the key at a real start of line.
D="$TMP/folder"
mkdir -p "$D"
printf '%s\n' "$KEY" > "$D/note.md"
bash "$GUARD" "$D" >"$TMP/out" 2>&1
RC=$?
if [ "$RC" != 0 ] && refused_by_sk; then
  pass "(p) mode dossier : cle en debut de ligne refusee"
else
  fail "(p) mode dossier : vrai positif perdu (rc=$RC)"
fi

# --- (n) true negatives, (w) witness -------------------------------------------
OLD='sk-[0-9A-Za-z_-]{16,}'
for line in \
  "providers/risk-assessment-2026-09-20-collection-decision" \
  "learning/task-based-asynchronous-programming" \
  "tools/disk-management-utilities-and-tools" \
  "notes/desk-research-for-the-2026-workshop" \
  "always ask-the-owner-before-any-push-gesture"; do
  RC="$(judge "$line")"
  if [ "$RC" = 0 ]; then
    pass "(n) mot ordinaire accepte : $line"
  else
    fail "(n) mot ordinaire refuse (rc=$RC) : $line"
  fi
  if printf '%s\n' "$line" | grep -qE -- "$OLD"; then
    pass "(w) temoin : l'ancien motif prenait : $line"
  else
    fail "(w) temoin : l'ancien motif ne prend pas : $line"
  fi
done

# The patterns file carries the boundary on the sk- line (not a second line).
if grep -qxF '(^|[^0-9A-Za-z])sk-[0-9A-Za-z_-]{16,}' "$PATTERNS" \
  && ! grep -qxF "$OLD" "$PATTERNS"; then
  pass "motifs : la ligne sk- porte la frontiere, l'ancienne ligne est retiree"
else
  fail "motifs : ligne sk- sans frontiere ou ancienne ligne encore presente"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
