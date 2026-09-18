#!/usr/bin/env bash
# T5 (Mission 186, etape 4) : README.md et INSTALL.md portent, dans cet
# ordre, les quatre etapes du parcours d'un participant qui decouvre le
# produit -- installer, le serveur MCP, ouvrir le Pilot, adopter un dossier
# existant -- et la FAQ nomme les quatre lecons tirees de la capture
# d'acceptation humaine de la Mission 184 (bash hors PATH sous Windows,
# dossier temporaire reutilise, deux emplacements possibles pour
# claude_desktop_config.json, exclusivite du serveur MCP
# `second-brain-vault`).
#
# Oracle : pour chaque document, les quatre titres de section se trouvent
# tous, a des numeros de ligne strictement croissants dans l'ordre attendu ;
# pour la FAQ (portee par README.md), un mot-cle par theme est present,
# insensible a la casse.
# Temoin negatif : une copie jetable de README.md, privee d'une section puis
# d'une entree FAQ, echoue au meme controle.
#
# usage: bash tests/test-install-doc-participant-path.sh
# Code 0 : tous les cas PASS. Code 1 sinon.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

echo "=== T5 : parcours participant en quatre etapes, et FAQ des lecons d'acceptation ==="

# --- 1. Ordre relatif des quatre sections, par fichier ---------------------
#
# Format d'une entree : "fichier|motif installer|motif MCP|motif Pilot|motif adopter"
CHECKS=(
  "README.md|## Ligne d'installation|## Le serveur MCP|## Ouvrir le Pilot d'un projet|## Adopter un dossier existant"
  "INSTALL.md|## 2. Ligne d'installation|## 4. Le serveur MCP|## 5. Ouvrir le Pilot|## 6. Adopter un dossier existant"
)

# section_order_ok <fichier> <motif1> <motif2> <motif3> <motif4> : 0 si les
# quatre motifs sont trouves chacun une fois, a des numeros de ligne
# strictement croissants dans cet ordre.
section_order_ok() {
  local SOO_DOC="$1"; shift
  local SOO_PREV=0
  local SOO_MOTIF SOO_LINE
  [ -f "$SOO_DOC" ] || return 1
  for SOO_MOTIF in "$@"; do
    SOO_LINE="$(grep -nF -- "$SOO_MOTIF" "$SOO_DOC" | head -n 1 | cut -d: -f1)"
    [ -n "$SOO_LINE" ] || return 1
    [ "$SOO_LINE" -gt "$SOO_PREV" ] || return 1
    SOO_PREV="$SOO_LINE"
  done
  return 0
}

for ENTRY in "${CHECKS[@]}"; do
  IFS='|' read -r DOC M1 M2 M3 M4 <<< "$ENTRY"
  DOC_PATH="$REPO_ROOT/$DOC"
  if section_order_ok "$DOC_PATH" "$M1" "$M2" "$M3" "$M4"; then
    pass "$DOC : installer < serveur MCP < ouvrir le Pilot < adopter, dans cet ordre"
  else
    fail "$DOC : les quatre sections du parcours ne sont pas toutes presentes, dans cet ordre"
  fi
done

# --- 2. La FAQ nomme les quatre themes --------------------------------------
#
# La FAQ vit dans README.md, section "## Questions frequentes" jusqu'au "## "
# suivant. Format d'une entree : "nom du theme|motif1|motif2"
FAQ_FILE="$REPO_ROOT/README.md"
FAQ_BLOCK="$(awk '/^## Questions fréquentes/{flag=1; next} /^## /{if (flag) exit} flag' "$FAQ_FILE" 2>/dev/null)"

FAQ_THEMES=(
  "bash hors PATH sous Windows|PATH|bash"
  "dossier temporaire reutilise|temporaire|second-brain-install"
  "deux emplacements de claude_desktop_config.json|Packages|APPDATA"
  "exclusivite du serveur second-brain-vault|second-brain-vault|exclusiv"
)

faq_has_theme() {
  # $1 = bloc FAQ (texte), $2 = motif1, $3 = motif2 -- les deux doivent
  # apparaitre (pas forcement sur la meme ligne), insensible a la casse.
  printf '%s\n' "$1" | grep -qi -- "$2" || return 1
  printf '%s\n' "$1" | grep -qi -- "$3" || return 1
  return 0
}

if [ -z "$FAQ_BLOCK" ]; then
  fail "README.md : section « Questions frequentes » introuvable"
else
  for ENTRY in "${FAQ_THEMES[@]}"; do
    IFS='|' read -r NOM MOTIF1 MOTIF2 <<< "$ENTRY"
    if faq_has_theme "$FAQ_BLOCK" "$MOTIF1" "$MOTIF2"; then
      pass "FAQ README.md : theme « $NOM » present ($MOTIF1 + $MOTIF2)"
    else
      fail "FAQ README.md : theme « $NOM » absent ($MOTIF1 + $MOTIF2)"
    fi
  done
fi

# --- 3. Temoin negatif : une copie amputee echoue au meme controle ---------
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m186-doc-participant-path-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

# 3a. Copie privee de la section "Le serveur MCP" (et de tout ce qui suit
# jusqu'au prochain "## ") : l'ordre des quatre sections doit alors echouer.
WITNESS_SECTION="$TMP/README-no-mcp-section.md"
awk '
  /^## Le serveur MCP/ { skip = 1; next }
  /^## / { if (skip) skip = 0 }
  !skip { print }
' "$FAQ_FILE" > "$WITNESS_SECTION"

if section_order_ok "$WITNESS_SECTION" "## Ligne d'installation" "## Le serveur MCP" "## Ouvrir le Pilot d'un projet" "## Adopter un dossier existant"; then
  fail "temoin : une copie de README.md privee de « Le serveur MCP » passe quand meme le controle d'ordre"
else
  pass "temoin : une copie de README.md privee de « Le serveur MCP » echoue au controle d'ordre"
fi

# 3b. Copie privee de l'entree FAQ sur l'exclusivite du serveur MCP : le
# theme correspondant doit alors echouer, les trois autres doivent tenir.
WITNESS_FAQ="$TMP/README-no-faq-entry.md"
grep -v "second-brain-vault" "$FAQ_FILE" > "$WITNESS_FAQ"
WITNESS_FAQ_BLOCK="$(awk '/^## Questions fréquentes/{flag=1; next} /^## /{if (flag) exit} flag' "$WITNESS_FAQ" 2>/dev/null)"

if faq_has_theme "$WITNESS_FAQ_BLOCK" "second-brain-vault" "exclusiv"; then
  fail "temoin : une copie de README.md privee des mentions « second-brain-vault » passe quand meme le controle FAQ"
else
  pass "temoin : une copie de README.md privee des mentions « second-brain-vault » echoue au controle FAQ"
fi
# Les trois autres themes doivent, eux, rester detectes dans cette meme copie
# amputee -- preuve que le controle FAQ cible bien le theme retire, pas tout
# le bloc.
OTHER_THEMES_OK=1
for ENTRY in "bash hors PATH sous Windows|PATH|bash" "dossier temporaire reutilise|temporaire|second-brain-install" "deux emplacements de claude_desktop_config.json|Packages|APPDATA"; do
  IFS='|' read -r NOM MOTIF1 MOTIF2 <<< "$ENTRY"
  faq_has_theme "$WITNESS_FAQ_BLOCK" "$MOTIF1" "$MOTIF2" || OTHER_THEMES_OK=0
done
if [ "$OTHER_THEMES_OK" = "1" ]; then
  pass "temoin : les trois autres themes FAQ restent detectes dans cette meme copie amputee"
else
  fail "temoin : le retrait cible a fait disparaitre plus que le theme vise"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
