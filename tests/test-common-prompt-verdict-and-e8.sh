#!/usr/bin/env bash
# Mission 235 (report 234 §7, §10.1): a Pilot that has only the pasted common
# prompt must return its verdict on the first line, and apply scenario E8 of
# the entry matrix when the project carries no Pilot prompt. The headless
# evaluations of Mission 234 measured both gaps (P1: « # Ouverture Pilot —
# Demo : **PRÊT** » ; P2: no NOT-READY first, no order proposed): those rules
# lived in session-start, which a Pilot does not open before its verdict.
#
#   (1) the PROMPT:BEGIN/END block of the common prompt says the first line is
#       READY or NOT-READY (<reason>), nothing before it;
#   (2) it carries E8: no state/PILOT-PROMPT.md at the given path ->
#       NOT-READY (projet non adopté), then the initiation order proposed, by
#       its template;
#   (3) the welcome Pilot's block carries the first-line rule too;
#   (4) the block stays short (pasted in every Project): at most 20 lines;
#   (5) witness: the block without the two sentences fails (1) and (2);
#   (6) Mission 237: a path outside list_allowed_directories is told apart --
#       NOT-READY (chemin non autorisé : réinstaller le serveur MCP, sb install),
#       no order proposed -- from a project not adopted (E8).
#   (7) Mission 242: neither block names a tool prefix (`mcp__`) nor a product
#       for the role (the Claude desktop application, a Project): the canary
#       is the Vault server's list_allowed_directories tool "whatever prefix
#       the host gives it"; both blocks accept the block-as-first-message form.
#
# usage: bash tests/test-common-prompt-verdict-and-e8.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_ROOT/templates/session-opening-prompt-template.md"
ACCUEIL="$REPO_ROOT/templates/accueil-pilot-prompt-template.md"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

block() { tr -d '\r' < "$1" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p' | sed '1d;$d'; }

has_first_line() { printf '%s' "$1" | grep -i 'first line' | grep -q 'NOT-READY'; }
has_e8() {
  printf '%s' "$1" | grep 'PILOT-PROMPT.md' | grep -q 'NOT-READY (projet non adopté)' \
    && printf '%s' "$1" | grep -q 'initiation-order-template.md'
}

echo "=== Mission 235 : le tronc commun porte le verdict en premiere ligne et la conduite E8 ==="

B="$(block "$TEMPLATE")"
has_first_line "$B" && pass "(1) premiere ligne = READY ou NOT-READY (<motif>)" || fail "(1) regle de la premiere ligne absente du tronc commun"
has_e8 "$B" && pass "(2) E8 : sans PILOT-PROMPT, NOT-READY (projet non adopté) puis ordre d'initiation" || fail "(2) conduite E8 absente du tronc commun"

A="$(block "$ACCUEIL")"
printf '%s' "$A" | grep -qi 'first line of your answer: `READY` or `NOT-READY' \
  && pass "(3) le bloc d'accueil porte la regle de la premiere ligne" || fail "(3) bloc d'accueil sans regle de premiere ligne"

N="$(printf '%s\n' "$B" | grep -c .)"
[ "$N" -le 20 ] && pass "(4) tronc commun court : $N lignes non vides (plafond 20)" || fail "(4) tronc commun trop long : $N lignes"

W="$(printf '%s\n' "$B" | grep -v 'PILOT-PROMPT.md` does not exist' | grep -vi 'first line of your answer')"
if ! has_first_line "$W" && ! has_e8 "$W"; then
  pass "(5) temoin : sans les deux phrases, (1) et (2) echouent"
else
  fail "(5) temoin : les controles passent sans les deux phrases"
fi

printf '%s' "$B" | grep -F 'list_allowed_directories` returns' | grep -F 'NOT-READY (chemin non autorisé : réinstaller le serveur MCP, sb install)' | grep -qi 'no order' \
  && pass "(6) chemin non autorise : NOT-READY distinct, aucun ordre propose" || fail "(6) chemin non autorise non distingue de E8"

for pair in "tronc commun:$TEMPLATE" "accueil:$ACCUEIL"; do
  label="${pair%%:*}"; X="$(block "${pair#*:}")"
  if printf '%s' "$X" | grep -q 'mcp__'; then fail "(7) $label : le bloc nomme un prefixe mcp__"; else pass "(7) $label : aucun mcp__ dans le bloc"; fi
  if printf '%s' "$X" | grep -qE 'Claude|desktop application|Project'; then fail "(7) $label : le bloc nomme un produit pour le role"; else pass "(7) $label : aucun produit nomme pour le role"; fi
  { printf '%s' "$X" | grep 'list_allowed_directories' | grep -q 'whatever prefix'; }     && pass "(7) $label : canari decrit par l'outil, quel que soit le prefixe" || fail "(7) $label : canari lie a un nom"
  printf '%s' "$X" | grep -qi 'first message' && pass "(7) $label : forme « bloc en premier message » reconnue" || fail "(7) $label : forme premier message absente"
done

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
