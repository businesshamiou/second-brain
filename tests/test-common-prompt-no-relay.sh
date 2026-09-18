#!/usr/bin/env bash
# T3 (Mission 186, step 5): the PROMPT:BEGIN/END block of the common Pilot
# prompt (templates/session-opening-prompt-template.md) no longer carries the
# word « RELAY » -- DECISION-2026-09-17-201623, part B4: "The RELAY is the
# output of a relay INSIDE A SESSION; it never carries the scope of a
# project. It appears in NO Project instruction: the common prompt loses
# its two « blocs RELAY reçus » lines." (translated from French) This common
# prompt is pasted as is into the instructions of a Project (desktop
# application): leaving a word RELAY there would reintroduce the session scope
# that the Decision removes.
#
# The MCP server exclusivity sentence (« second-brain-vault » + « hors
# perimetre » ["outside the perimeter"] on the SAME line, already tested by
# tests/test-common-prompt-exclusivity.sh -- T9 of Mission 185-C01) must
# remain present: this test does not check a regression on it,
# only that it survives the removal of the word RELAY in the same block.
#
# Rerun with one command, from the repository root:
#   bash tests/test-common-prompt-no-relay.sh
#
# Exit 0: the PROMPT:BEGIN/END block is free of "RELAY" (case-
# insensitive) and still carries the exclusivity sentence; the negative control
# proves that the absence of RELAY can be detected as a failure when
# RELAY is reinjected. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1
TEMPLATE="$REPO_ROOT/templates/session-opening-prompt-template.md"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m186-prompt-no-relay-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# prompt_block <fichier>: the text between the two markers, empty if either
# of them is missing -- same technique as
# tests/test-common-prompt-exclusivity.sh (sed on the markers, never a
# line count: the template moves, its markers do not), and as
# extract_prompt_common_block() in tools/project-bootstrap.sh.
prompt_block() {
  tr -d '\r' < "$1" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p'
}

# check_no_relay <fichier>: 0 if the block does not carry "RELAY" (case-
# insensitive), 1 otherwise (missing block included).
check_no_relay() {
  BLOCK="$(prompt_block "$1")"
  [ -n "$BLOCK" ] || return 1
  printf '%s' "$BLOCK" | grep -qi 'relay' && return 1
  return 0
}

# check_exclusivity <fichier>: same check as T9
# (tests/test-common-prompt-exclusivity.sh), replayed here to prove that it
# survives the removal of RELAY in the same block.
check_exclusivity() {
  BLOCK="$(prompt_block "$1")"
  [ -n "$BLOCK" ] || return 1
  printf '%s' "$BLOCK" | grep -q 'second-brain-vault' || return 1
  printf '%s' "$BLOCK" | grep -q 'outside the perimeter' || return 1
  printf '%s' "$BLOCK" | grep 'second-brain-vault' | grep -q 'outside the perimeter' || return 1
  return 0
}

echo "=== T3 : le prompt Pilot commun ne porte pas RELAY, garde son exclusivite ==="

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

if check_no_relay "$TEMPLATE"; then
  pass "le bloc PROMPT:BEGIN/END ne porte pas le mot RELAY"
else
  fail "le bloc PROMPT:BEGIN/END porte encore le mot RELAY"
  printf '%s\n' "$(prompt_block "$TEMPLATE")" | grep -in 'relay' | sed 's/^/      /'
fi

if check_exclusivity "$TEMPLATE"; then
  pass "la phrase d'exclusivite (second-brain-vault + hors perimetre, meme ligne) est toujours presente"
else
  fail "la phrase d'exclusivite a disparu du bloc"
fi

# --- Negative control: a copy of the template where RELAY is reinjected into the
# block -- detection must then fail (FAIL named), never say PASS.
echo ""
echo "=== Temoin negatif (FAIL prouve) : RELAY reinjecte dans une copie jetable ==="
WITNESS="$TMP/session-opening-prompt-template.md"
awk '
  { print }
  /<!-- PROMPT:BEGIN -->/ { print "Les blocs RELAY recus depuis la derniere session sont a relire avant toute autre lecture." }
' "$TEMPLATE" > "$WITNESS"

if check_no_relay "$WITNESS"; then
  fail "temoin : une copie avec RELAY reinjecte passe quand meme le controle"
else
  pass "temoin : une copie du gabarit avec RELAY reinjecte echoue au meme controle"
  printf '%s\n' "$(prompt_block "$WITNESS")" | grep -in 'relay' | sed 's/^/      /'
fi

# The exclusivity sentence must remain detected independently on this
# control (it was not touched): proof that the two checks are
# indeed independent of each other.
if check_exclusivity "$WITNESS"; then
  pass "temoin : la phrase d'exclusivite reste detectee sur la meme copie (les deux controles sont independants)"
else
  fail "temoin : la phrase d'exclusivite a disparu de la copie -- le fabricant du temoin l'a abimee par erreur"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
