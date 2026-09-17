#!/usr/bin/env bash
# T9 (Mission 185-C01, porte 6 de la capture 2026-09-17-144137) : le prompt
# Pilot commun dit que le serveur `second-brain-vault` est le SEUL outil de
# fichiers du Pilot.
#
# Defaut mesure a l'acceptation humaine de la 184 : le Pilot constate la
# borne de `second-brain-vault`, puis lit le meme fichier par un autre
# serveur de fichiers configure sur le poste. Le prompt commun ne disait
# nulle part « uniquement ce serveur » : la borne du serveur MCP n'est une
# borne que si le contrat le dit.
#
# Oracle : le bloc PROMPT:BEGIN/END du gabarit porte la phrase
# d'exclusivite -- le nom du serveur ET la mention « hors perimetre ».
# Temoin negatif : une copie du gabarit privee de cette phrase echoue au
# meme controle, dans un dossier temporaire.
#
# usage: bash tests/test-common-prompt-exclusivity.sh
# Code 0 : tous les cas PASS. Code 1 sinon.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_ROOT/templates/session-opening-prompt-template.md"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-prompt-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# prompt_block <fichier> : le bloc entre les deux marqueurs, vide si l'un
# des deux manque. sed sur les marqueurs plutot qu'un compte de lignes :
# le gabarit bouge, ses marqueurs non.
prompt_block() {
  tr -d '\r' < "$1" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p'
}

# check_exclusivity <fichier> : 0 si le bloc porte la phrase, 1 sinon.
check_exclusivity() {
  BLOCK="$(prompt_block "$1")"
  [ -n "$BLOCK" ] || return 1
  printf '%s' "$BLOCK" | grep -q 'second-brain-vault' || return 1
  printf '%s' "$BLOCK" | grep -q 'hors périmètre' || return 1
  # Les deux moities de la phrase doivent vivre sur la MEME ligne : le nom
  # du serveur apparait deja ailleurs dans le bloc, et « hors perimetre »
  # seul ne dit pas de quel outil on parle.
  printf '%s' "$BLOCK" | grep 'second-brain-vault' | grep -q 'hors périmètre' || return 1
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

# --- Temoin negatif : la meme mesure, sur une copie amputee ---------------
WITNESS="$TMP/session-opening-prompt-template.md"
grep -v 'hors périmètre' "$TEMPLATE" > "$WITNESS"
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
