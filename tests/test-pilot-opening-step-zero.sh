#!/usr/bin/env bash
# T (Mission 215): the Pilot opening proves that the file channel answers
# BEFORE it reads anything ("step zero").
#
# Defect measured on 2026-09-21: two fresh Pilot windows opened on a channel
# not linked to the computer (tools run on the client side). Reads hung for
# 4 min, 125 s and 132 s; a second opening then stopped on a criterion about
# the tool PREFIX that also forbade that channel when it did answer. The
# reading list and the opening prompt only tested that the server EXISTS.
#
# What is proven is the read that comes back, not the brand of the host:
# the step-zero line names a bounded delay and the client-side error, and
# names neither a tool prefix nor `get_device_info` as a condition.
#
# Four cases:
#   (1) the `## Pilot` section of the reading list carries a line beginning
#       `0. **Step zero`, BEFORE the line of point 1 (the digest), and that
#       line is well-formed (see step_zero_line_ok).
#   (2) the PROMPT:BEGIN/END block of the opening template carries a line
#       `0.` containing `Step zero`, before its point 1, well-formed.
#   (3) a `project-bootstrap.sh create` in a throwaway Vault (sandbox-vault.sh)
#       renders that same line, byte for byte the reading list's, in the
#       block it returns.
#   (4) negative control: copies of the template and of the reading list
#       deprived of the line fail (1) and (2).
#
# Writes only in a temporary folder (prefix m215). No model call.
# Portable: bash 3.2 (no mapfile, no associative array, no GNU-only option).
#
# usage: bash tests/test-pilot-opening-step-zero.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

READING_LIST="$REPO_ROOT/skills/session-start/reading-list.md"
TEMPLATE="$REPO_ROOT/templates/session-opening-prompt-template.md"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m215-stepzero-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

# pilot_section <fichier>: the `## Pilot` section of the reading list, up to
# the next level-2 heading (a `### ` sub-heading does not end it).
pilot_section() {
  tr -d '\r' < "$1" | awk '/^## Pilot[[:space:]]*$/{f=1;next} /^## /{f=0} f{print}'
}

# prompt_block <fichier>: the text between the two markers, markers excluded;
# empty if either is missing.
prompt_block() {
  tr -d '\r' < "$1" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p' | sed '1d;$d'
}

# step_zero_first <texte>: 0 if the first line beginning `0.` and containing
# `Step zero` comes before the first line beginning `1.`, and both exist.
step_zero_first() {
  printf '%s\n' "$1" | awk '
    /^0\. .*Step zero/ && !z { z = NR }
    /^1\. /            && !o { o = NR }
    END { exit !(z && o && z < o) }'
}

# step_zero_line <texte>: the step-zero line itself.
step_zero_line() {
  printf '%s\n' "$1" | grep -m 1 '^0\. .*Step zero'
}

# step_zero_line_ok <ligne>: the evidence criterion. The line must name the
# bounded delay (60 seconds), the client-side failure, and the READY-with-
# ANOMALY verdict for a channel that answers client-side; it must depend
# neither on a tool prefix nor on `get_device_info` (the host's brand is not
# the proof).
step_zero_line_ok() {
  [ -n "$1" ] || return 1
  printf '%s' "$1" | grep -q '60 seconds' || return 1
  printf '%s' "$1" | grep -q 'client-side' || return 1
  printf '%s' "$1" | grep -q 'NOT-READY' || return 1
  printf '%s' "$1" | grep -q 'ANOMALY' || return 1
  printf '%s' "$1" | grep -q 'get_device_info' && return 1
  printf '%s' "$1" | grep -q 'claude-device' && return 1
  return 0
}

# check_reading_list <fichier>: case (1) measurement.
check_reading_list() {
  local sec
  sec="$(pilot_section "$1")"
  [ -n "$sec" ] || return 1
  step_zero_first "$sec" || return 1
  step_zero_line_ok "$(step_zero_line "$sec")"
}

# check_template <fichier>: case (2) measurement.
check_template() {
  local blk
  blk="$(prompt_block "$1")"
  [ -n "$blk" ] || return 1
  step_zero_first "$blk" || return 1
  step_zero_line_ok "$(step_zero_line "$blk")"
}

echo "=== T (M215) : etape zero de l'ouverture Pilot ==="

for f in "$READING_LIST" "$TEMPLATE"; do
  if [ ! -f "$f" ]; then
    echo "FAIL : fichier introuvable : $f"
    exit 1
  fi
done

echo ""
echo "=== (1) liste de lecture : ligne 0 avant le point 1 ==="
if check_reading_list "$READING_LIST"; then
  pass "(1) la section Pilot porte l'etape zero avant le point 1, bien formee"
else
  fail "(1) la section Pilot ne porte pas l'etape zero avant le point 1, bien formee"
fi

echo ""
echo "=== (2) gabarit : ligne 0 dans le bloc PROMPT ==="
if check_template "$TEMPLATE"; then
  pass "(2) le bloc PROMPT porte l'etape zero avant le point 1, bien formee"
else
  fail "(2) le bloc PROMPT ne porte pas l'etape zero avant le point 1, bien formee"
fi

echo ""
echo "=== (3) rendu par project-bootstrap.sh create dans un Vault jetable ==="
if ! sandbox_find_uv; then
  fail "(3) uv introuvable -- project-bootstrap.sh en depend"
else
  WS="$TMP/ws"
  mkdir -p "$WS"
  V="$WS/second-brain"
  if ! sandbox_vault "$REPO_ROOT" "$V"; then
    fail "(3) Vault jetable non construit"
  else
    bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1
    OUT="$(bash "$V/tools/project-bootstrap.sh" create "$WS/proj-m215" "Projet M215" --vcs none --lang EN 2>&1 </dev/null)"
    RC=$?
    RENDERED="$(printf '%s\n' "$OUT" | tr -d '\r' | grep -m 1 '^0\. .*Step zero')"
    EXPECTED="$(step_zero_line "$(pilot_section "$READING_LIST")")"
    if [ "$RC" != "0" ]; then
      fail "(3) create rend $RC -- $(printf '%s' "$OUT" | tail -n 3)"
    elif [ -z "$RENDERED" ]; then
      fail "(3) le bloc rendu ne porte pas de ligne 0. Step zero"
    elif [ -z "$EXPECTED" ] || [ "$RENDERED" != "$EXPECTED" ]; then
      fail "(3) la ligne rendue n'est pas celle de la liste de lecture"
    else
      pass "(3) le bloc rendu porte la ligne de la liste de lecture, a l'octet pres"
    fi
  fi
fi

echo ""
echo "=== (4) temoin negatif : copies privees de la ligne ==="
WIT_RL="$TMP/reading-list.md"
WIT_TP="$TMP/session-opening-prompt-template.md"
grep -v 'Step zero' "$READING_LIST" > "$WIT_RL"
grep -v 'Step zero' "$TEMPLATE" > "$WIT_TP"
if check_reading_list "$WIT_RL"; then
  fail "(4) temoin : une liste de lecture sans la ligne passe quand meme (1)"
elif check_template "$WIT_TP"; then
  fail "(4) temoin : un gabarit sans la ligne passe quand meme (2)"
else
  pass "(4) temoin : les copies sans la ligne echouent a (1) et (2)"
fi

echo ""
echo "=== RESULT: $PASSES PASS, $FAILURES FAIL ==="
[ "$FAILURES" -eq 0 ] && exit 0
exit 1
