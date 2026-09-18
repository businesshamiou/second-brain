#!/usr/bin/env bash
# T9 (Mission 185-C01, door 6 of capture 2026-09-17-144137): the common
# Pilot prompt says that the `second-brain-vault` server is the Pilot's ONLY
# file tool.
#
# Defect measured at the human acceptance of 184: the Pilot notices the
# bound of `second-brain-vault`, then reads the same file through another
# file server configured on the machine. The common prompt said
# nowhere « uniquement ce serveur » ["only this server"]: the MCP server's
# bound is a bound only if the contract says so.
#
# Oracle: the PROMPT:BEGIN/END block of the template carries the exclusivity
# sentence -- the server name AND the mention « hors perimetre » ["outside the perimeter"].
# Negative control: a copy of the template stripped of that sentence fails the
# same check, in a temporary folder.
#
# usage: bash tests/test-common-prompt-exclusivity.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_ROOT/templates/session-opening-prompt-template.md"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-prompt-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# prompt_block <fichier>: the block between the two markers, empty if either
# of them is missing. sed on the markers rather than a line count:
# the template moves, its markers do not.
prompt_block() {
  tr -d '\r' < "$1" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p'
}

# check_exclusivity <fichier>: 0 if the block carries the sentence, 1 otherwise.
check_exclusivity() {
  BLOCK="$(prompt_block "$1")"
  [ -n "$BLOCK" ] || return 1
  printf '%s' "$BLOCK" | grep -q 'second-brain-vault' || return 1
  printf '%s' "$BLOCK" | grep -q 'outside the perimeter' || return 1
  # Both halves of the sentence must live on the SAME line: the name
  # of the server already appears elsewhere in the block, and « hors perimetre »
  # alone does not say which tool is meant. Since Mission 187 the template
  # is in English: the sentence searched for is its exact translation.
  printf '%s' "$BLOCK" | grep 'second-brain-vault' | grep -q 'outside the perimeter' || return 1
  return 0
}

echo "=== T9 : phrase d'exclusivite du prompt Pilot commun ==="

if [ -f "$TEMPLATE" ]; then
  pass "le gabarit du prompt commun existe ($TEMPLATE)"
else
  fail "gabarit introuvable : $TEMPLATE"
  echo "=== RESULT: FAIL ($FAILURES) ==="
  exit 1
fi

if [ -n "$(prompt_block "$TEMPLATE")" ]; then
  pass "le bloc PROMPT:BEGIN/END est present"
else
  fail "le bloc PROMPT:BEGIN/END est absent ou incomplet"
fi

if check_exclusivity "$TEMPLATE"; then
  pass "le bloc porte la phrase d'exclusivite (second-brain-vault + hors perimetre, meme ligne)"
else
  fail "le bloc ne porte pas la phrase d'exclusivite"
fi

# --- Negative control: the same measurement, on a truncated copy ----------
WITNESS="$TMP/session-opening-prompt-template.md"
grep -v 'outside the perimeter' "$TEMPLATE" > "$WITNESS"
if check_exclusivity "$WITNESS"; then
  fail "temoin : une copie sans la phrase passe quand meme le controle"
else
  pass "temoin : une copie du gabarit sans la phrase echoue au meme controle"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
