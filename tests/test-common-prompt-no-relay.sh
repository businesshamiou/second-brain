#!/usr/bin/env bash
# T3 (Mission 186, etape 5) : le bloc PROMPT:BEGIN/END du prompt Pilot
# commun (templates/session-opening-prompt-template.md) ne porte plus le
# mot « RELAY » -- DECISION-2026-09-17-201623, volet B4 : « Le RELAY est la
# sortie d'un relais A L'INTERIEUR D'UNE SESSION ; il ne porte jamais la
# portee d'un projet. Il ne figure dans AUCUNE instruction de Projet : le
# prompt commun perd ses deux lignes « blocs RELAY reçus». » Ce prompt
# commun est colle tel quel dans les instructions d'un Projet (application
# de bureau) : y laisser un mot RELAY reintroduirait la portee de session
# que la Decision retire.
#
# La phrase d'exclusivite du serveur MCP (« second-brain-vault » + « hors
# perimetre » sur la MEME ligne, deja testee par
# tests/test-common-prompt-exclusivity.sh -- T9 de la Mission 185-C01) doit
# rester presente : ce test ne verifie pas une regression sur elle,
# seulement qu'elle survit au retrait du mot RELAY dans le meme bloc.
#
# Rerun avec une commande, depuis la racine du depot :
#   bash tests/test-common-prompt-no-relay.sh
#
# Exit 0 : le bloc PROMPT:BEGIN/END est absent de "RELAY" (insensible a la
# casse) et porte toujours la phrase d'exclusivite ; le temoin negatif
# prouve que l'absence de RELAY sait etre detectee comme un echec quand
# RELAY est reinjecte. Exit 1 sinon.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1
TEMPLATE="$REPO_ROOT/templates/session-opening-prompt-template.md"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m186-prompt-no-relay-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# prompt_block <fichier> : le texte entre les deux marqueurs, vide si l'un
# des deux manque -- meme technique que
# tests/test-common-prompt-exclusivity.sh (sed sur les marqueurs, jamais un
# compte de lignes : le gabarit bouge, ses marqueurs non), et que
# extract_prompt_common_block() dans tools/project-bootstrap.sh.
prompt_block() {
  tr -d '\r' < "$1" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p'
}

# check_no_relay <fichier> : 0 si le bloc ne porte pas "RELAY" (insensible
# a la casse), 1 sinon (bloc absent compris).
check_no_relay() {
  BLOCK="$(prompt_block "$1")"
  [ -n "$BLOCK" ] || return 1
  printf '%s' "$BLOCK" | grep -qi 'relay' && return 1
  return 0
}

# check_exclusivity <fichier> : meme controle que T9
# (tests/test-common-prompt-exclusivity.sh), rejoue ici pour prouver qu'il
# survit au retrait de RELAY dans le meme bloc.
check_exclusivity() {
  BLOCK="$(prompt_block "$1")"
  [ -n "$BLOCK" ] || return 1
  printf '%s' "$BLOCK" | grep -q 'second-brain-vault' || return 1
  printf '%s' "$BLOCK" | grep -q 'hors périmètre' || return 1
  printf '%s' "$BLOCK" | grep 'second-brain-vault' | grep -q 'hors périmètre' || return 1
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

# --- Temoin negatif : une copie du gabarit ou RELAY est reinjecte dans le
# bloc -- la detection doit alors echouer (FAIL nomme), jamais dire PASS.
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

# La phrase d'exclusivite doit rester detectee independamment sur ce
# temoin (elle n'a pas ete touchee) : preuve que les deux controles sont
# bien independants l'un de l'autre.
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
