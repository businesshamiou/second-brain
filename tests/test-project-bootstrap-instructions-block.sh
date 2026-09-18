#!/usr/bin/env bash
# T4 (Mission 186, etape 3 ; Decision 201623 volet C, amende 000545 A4) : le
# bloc "Instructions du Projet" rendu par tools/project-bootstrap.sh porte
# le texte COMPLET du tronc commun, pret a coller -- plus seulement un
# chemin vers le gabarit que le participant devait aller ouvrir lui-meme.
#
# Quatre familles de cas :
#   (1) create, sans --order : l'objet rendu retombe sur DISPLAY_NAME
#       (fallback ${ORDER_PURPOSE:-$DISPLAY_NAME}) ; le tronc commun exact,
#       le chemin natif, le vault_id et le canari sont tous presents, et le
#       canari rendu est identique a celui ecrit dans
#       <cible>/state/PILOT-PROMPT.md.
#   (2) --order avec un Objet renseigne : l'objet rendu est celui de
#       l'ordre, pas le nom du projet (Nom de l'ordre).
#   (3) trois langues : les libelles des nouveaux champs changent de langue
#       (FR/EN/ES) alors que le tronc commun -- texte francais canonique --
#       reste identique dans les trois cas (il n'est jamais traduit).
#   (4) temoin negatif : un gabarit jetable prive de <!-- PROMPT:BEGIN -->
#       fait echouer le script proprement (code de sortie non nul), avec un
#       message nommant le gabarit fautif, et SANS rendu partiel du bloc
#       d'instructions (aucune des lignes du bloc, meme son en-tete,
#       n'apparait dans la sortie).
#
# Ecrit seulement dans un dossier temporaire (prefixe m186). Aucun appel
# modele, aucune ecriture hors de ce dossier temporaire.
#
# usage: bash tests/test-project-bootstrap-instructions-block.sh
# Code 0 : tous les cas PASS. Code 1 sinon.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- tools/project-bootstrap.sh en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m186-instrblock-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== T4 : bloc d'instructions du Projet rendu tel quel ==="

# extract_expected_block <gabarit> : la meme extraction que celle du script
# (Decision 201623 volet C), rejouee ici independamment -- l'oracle de ce
# test, jamais une chaine recopiee a la main.
extract_expected_block() {
  tr -d '\r' < "$1" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p' | sed '1d;$d'
}

# contains_block <haystack> <needle> : substring, sauts de ligne compris --
# le pattern d'un `case` bash ne traite pas '\n' specialement.
contains_block() {
  case "$1" in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

native_path_test() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

# =============================================================================
echo ""
echo "=== Vault jetable (arbre de travail) ==="
WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
if ! sandbox_vault "$REPO_ROOT" "$V"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V/tools/write-marker.sh" "$WS" >/dev/null
BOOT="$V/tools/project-bootstrap.sh"
TEMPLATE="$V/templates/session-opening-prompt-template.md"
VID="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"
VREF="$(git -C "$V" rev-parse HEAD)"

EXPECTED_BLOCK="$(extract_expected_block "$TEMPLATE")"
if [ -n "$EXPECTED_BLOCK" ]; then
  pass "tronc commun extrait du gabarit jetable (non vide)"
else
  echo "FAIL : tronc commun vide -- le gabarit jetable n'est pas celui attendu"
  exit 1
fi

# =============================================================================
echo ""
echo "=== (1) create, sans --order : objet retombe sur DISPLAY_NAME ==="
P1="$WS/proj-create"
OUT1="$(bash "$BOOT" create "$P1" "Projet Un" --vcs none --lang FR 2>&1 </dev/null)"
RC1=$?
[ "$RC1" = "0" ] && pass "(1) create rend 0" || fail "(1) create rend $RC1 -- $(printf '%s' "$OUT1" | tail -n 5)"

if contains_block "$OUT1" "$EXPECTED_BLOCK"; then
  pass "(1) tronc commun exact present dans la sortie"
else
  fail "(1) tronc commun absent ou altere dans la sortie"
fi

P1_NATIVE="$(native_path_test "$(cd "$P1" && pwd)")"
case "$OUT1" in
  *"$P1_NATIVE"*) pass "(1) chemin natif du projet rendu" ;;
  *) fail "(1) chemin natif du projet absent (attendu : $P1_NATIVE)" ;;
esac
case "$OUT1" in
  *"$VID"*) pass "(1) vault_id rendu" ;;
  *) fail "(1) vault_id absent" ;;
esac

CANARY1="$(sed -n 's/^canary: "\(.*\)"$/\1/p' "$P1/state/PILOT-PROMPT.md" 2>/dev/null)"
if [ -n "$CANARY1" ]; then
  pass "(1) canari trouve dans state/PILOT-PROMPT.md ($CANARY1)"
else
  fail "(1) canari absent de state/PILOT-PROMPT.md"
fi
case "$OUT1" in
  *"$CANARY1"*) pass "(1) canari rendu dans la sortie, identique a state/PILOT-PROMPT.md" ;;
  *) fail "(1) canari rendu different de state/PILOT-PROMPT.md" ;;
esac

case "$OUT1" in
  *"Objet : Projet Un"*) pass "(1) objet retombe sur DISPLAY_NAME (« Objet : Projet Un »)" ;;
  *) fail "(1) objet ne retombe pas sur DISPLAY_NAME (attendu « Objet : Projet Un »)" ;;
esac

# =============================================================================
echo ""
echo "=== (2) --order, avec Objet renseigne : objet rendu = celui de l'ordre ==="
ORDER_OBJET="Objet distinct de l'ordre, T4 Mission 186"
ORDER_FILE="$TMP/order-t4.md"
cat > "$ORDER_FILE" <<ORDEREOF
Session Executor — initiation (proj-order)

Ordre d'initiation
- Type : create
- Mode : answered
- Nom : proj-order
- Emplacement : $WS
- Vault + construction : vault_id=$VID, vault_origin=$V, vault_ref=$VREF
- Git : none
- Objet : $ORDER_OBJET
- Autorisation Owner datée : Je suis l'Owner et j'autorise, 2026-09-17
ORDEREOF
OUT2="$(bash "$BOOT" --order "$ORDER_FILE" FR 2>&1 </dev/null)"
RC2=$?
[ "$RC2" = "0" ] && pass "(2) --order rend 0" || fail "(2) --order rend $RC2 -- $(printf '%s' "$OUT2" | tail -n 5)"

case "$OUT2" in
  *"Objet : $ORDER_OBJET"*) pass "(2) objet rendu = celui de l'ordre" ;;
  *) fail "(2) objet rendu different de celui de l'ordre (attendu « Objet : $ORDER_OBJET »)" ;;
esac
case "$OUT2" in
  *"Objet : proj-order"*) fail "(2) temoin : l'objet est retombe a tort sur le Nom du projet" ;;
  *) pass "(2) l'objet n'est pas retombe sur le Nom du projet" ;;
esac
if contains_block "$OUT2" "$EXPECTED_BLOCK"; then
  pass "(2) tronc commun exact present dans la sortie (--order)"
else
  fail "(2) tronc commun absent ou altere dans la sortie (--order)"
fi

# =============================================================================
echo ""
echo "=== (3) trois langues : libelles traduits, tronc commun inchange ==="
declare_lang_case() {
  # $1 = code langue (FR|EN|ES), $2 = mot distinctif attendu dans le nouveau
  # champ "chemin du projet" pour cette langue (verifie la Tache 2).
  local lang="$1" needle="$2" dir="$WS/proj-lang-$1" out rc
  out="$(bash "$BOOT" create "$dir" "Projet $1" --vcs none --lang "$lang" 2>&1 </dev/null)"
  rc=$?
  [ "$rc" = "0" ] && pass "(3-$lang) create rend 0" || fail "(3-$lang) create rend $rc -- $(printf '%s' "$out" | tail -n 5)"
  if contains_block "$out" "$EXPECTED_BLOCK"; then
    pass "(3-$lang) tronc commun francais canonique inchange"
  else
    fail "(3-$lang) tronc commun altere ou absent"
  fi
  case "$out" in
    *"$needle"*) pass "(3-$lang) libelle traduit present ($needle)" ;;
    *) fail "(3-$lang) libelle traduit absent (attendu : $needle)" ;;
  esac
}
declare_lang_case FR "Chemin du projet :"
declare_lang_case EN "Project path:"
declare_lang_case ES "Ruta del proyecto:"

# =============================================================================
echo ""
echo "=== (4) temoin negatif : gabarit jetable sans <!-- PROMPT:BEGIN --> ==="
WS2="$TMP/ws2"
mkdir -p "$WS2"
V2="$WS2/second-brain"
if ! sandbox_vault "$REPO_ROOT" "$V2"; then
  echo "FAIL : deuxieme Vault jetable non construit"
  exit 1
fi
bash "$V2/tools/write-marker.sh" "$WS2" >/dev/null
BOOT2="$V2/tools/project-bootstrap.sh"
TEMPLATE2="$V2/templates/session-opening-prompt-template.md"

grep -qF '<!-- PROMPT:BEGIN -->' "$TEMPLATE2" && grep -qF '<!-- PROMPT:END -->' "$TEMPLATE2" \
  && pass "(4) avant sabotage : les deux marqueurs sont presents dans le gabarit jetable" \
  || fail "(4) avant sabotage : marqueur(s) deja absent(s) -- fixture invalide"

# Retire uniquement la ligne du marqueur BEGIN (sabotage du gabarit jetable
# seulement -- jamais le gabarit du depot reel).
sed -i.bak '/<!-- PROMPT:BEGIN -->/d' "$TEMPLATE2"
rm -f "$TEMPLATE2.bak"
grep -qF '<!-- PROMPT:BEGIN -->' "$TEMPLATE2" && fail "(4) sabotage inefficace : PROMPT:BEGIN toujours present" \
  || pass "(4) sabotage confirme : PROMPT:BEGIN absent du gabarit jetable"

P4="$WS2/proj-broken"
OUT4="$(bash "$BOOT2" create "$P4" "Projet Casse" --vcs none --lang FR 2>&1 </dev/null)"
RC4=$?
[ "$RC4" != "0" ] && pass "(4) code de sortie non nul ($RC4)" || fail "(4) code de sortie 0 -- l'echec fail-closed n'a pas ete detecte"

case "$OUT4" in
  *"REFUS"*"$TEMPLATE2"*) pass "(4) message nommant le gabarit fautif" ;;
  *) fail "(4) message ne nomme pas le gabarit fautif (sortie : $(printf '%s' "$OUT4" | tail -n 3))" ;;
esac

case "$OUT4" in
  *"Objet :"*|*"Purpose:"*|*"Objeto:"*) fail "(4) temoin : une ligne « Objet » partielle a quand meme ete rendue" ;;
  *) pass "(4) aucune ligne de champ (Objet) rendue" ;;
esac
case "$OUT4" in
  *"Pour ouvrir le Pilot"*|*"To open this project's Pilot"*|*"Para abrir el Pilot"*) fail "(4) temoin : l'en-tete du bloc a ete rendu malgre l'echec" ;;
  *) pass "(4) aucun en-tete du bloc a consommer rendu" ;;
esac
if contains_block "$OUT4" "$EXPECTED_BLOCK"; then
  fail "(4) temoin : le tronc commun a quand meme ete rendu malgre le gabarit sabote"
else
  pass "(4) le tronc commun n'a pas ete rendu"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
