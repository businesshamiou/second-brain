#!/usr/bin/env bash
# T8 (Mission 185-C01, porte 11 de la capture 2026-09-17-144137) : le plan
# de reorganisation propose par `adopt` ne parle que de L'EXISTANT.
#
# Defaut mesure sur le poste de l'Owner : le plan proposait « deplacer
# index.md vers knowledge/index.md » -- pour l'index que le meme appel
# venait d'ecrire. Un plan qui propose de ranger ce qu'il vient de poser
# apprend au participant a ne plus le lire.
#
# Oracle (PASS attendu) : aucun fichier ajoute par CET appel (ceux que le
# script annonce lui-meme comme ajoutes : index.md, CLAUDE.md, AGENTS.md,
# README.md...) n'apparait dans le plan.
# Temoin negatif (dans ce meme fichier) : un fichier qui existait AVANT et
# n'est pas a sa place (MISSION-*.md a la racine) est, lui, toujours
# propose au deplacement -- sans quoi ce test passerait aussi sur un plan
# devenu muet.
#
# Ecrit seulement dans un dossier temporaire (prefixe m185).
#
# usage: bash tests/test-project-bootstrap-adopt-plan.sh
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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-plan-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

mkdir -p "$TMP/bin"
cat > "$TMP/bin/pre-commit" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "install" ]; then
  hooks="$(git rev-parse --git-path hooks)" || exit 1
  mkdir -p "$hooks"
  printf '#!/usr/bin/env bash\n# substitut de test\nexit 0\n' > "$hooks/pre-commit"
  exit 0
fi
exit 0
STUB
chmod +x "$TMP/bin/pre-commit"
PATH="$TMP/bin:$PATH"
export PATH

WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
if ! sandbox_vault "$REPO_ROOT" "$V"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V/tools/write-marker.sh" "$WS" >/dev/null
BOOTSTRAP="$V/tools/project-bootstrap.sh"
CATALOG="$V/i18n/catalog.en.json"

# Les bornes du plan, lues au catalogue : le plan est ce qui vit entre
# elles, jamais un compte de lignes.
PLAN_HEADER="$(uv run --no-project "$V/tools/sb_installer_helper.py" format-catalog "$CATALOG" "projectBootstrap.adopt.planHeader" 2>/dev/null | head -n 1)"
PLAN_FOOTER="$(uv run --no-project "$V/tools/sb_installer_helper.py" format-catalog "$CATALOG" "projectBootstrap.adopt.planFooter" 2>/dev/null | head -n 1)"
if [ -n "$PLAN_HEADER" ] && [ -n "$PLAN_FOOTER" ]; then
  pass "controle : les bornes du plan sont lues au catalogue"
else
  fail "controle : bornes du plan illisibles -- le test ne prouverait rien"
fi

# --- Un dossier existant : deux fichiers, dont un mal range --------------
P="$WS/projet"
mkdir -p "$P"
printf '# notes\n\nDu texte.\n' > "$P/notes.md"
printf '# MISSION 001\n\nUne Mission restee a la racine.\n' > "$P/MISSION-001-essai.md"
BEFORE_LIST="$(cd "$P" && ls -1)"

OUT="$(bash "$BOOTSTRAP" adopt "$P" "Projet" --vcs none 2>&1 </dev/null)"
RC=$?
[ "$RC" = "0" ] && pass "adopt rend 0" || fail "adopt rend $RC"

PLAN="$(printf '%s\n' "$OUT" | sed -n "/$(printf '%s' "$PLAN_HEADER" | sed 's/[][\\.*^$\/&]/\\&/g')/,/$(printf '%s' "$PLAN_FOOTER" | sed 's/[][\\.*^$\/&]/\\&/g')/p")"
if [ -n "$PLAN" ]; then
  pass "le plan de reorganisation est rendu"
else
  fail "aucun plan rendu -- $(printf '%s' "$OUT" | tail -n 5)"
fi

# --- Oracle : rien de ce que cet appel vient d'ajouter dans le plan ------
# La liste des ajouts est celle que le script annonce lui-meme, plus les
# fichiers que ce test a vus apparaitre a la racine. Les deux sources sont
# croisees : le plan ne parle d'aucun des deux.
AFTER_LIST="$(cd "$P" && ls -1)"
ADDED_AT_ROOT=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "
$BEFORE_LIST
" in
    *"
$f
"*) : ;;
    *) ADDED_AT_ROOT="$ADDED_AT_ROOT $f" ;;
  esac
done <<EOF
$AFTER_LIST
EOF

if [ -n "$ADDED_AT_ROOT" ]; then
  pass "controle : cet appel a bien ajoute des fichiers a la racine ($ADDED_AT_ROOT )"
else
  fail "controle : cet appel n'a rien ajoute a la racine -- le test ne prouverait rien"
fi

OFFENDERS=""
for f in $ADDED_AT_ROOT; do
  [ -f "$P/$f" ] || continue
  if printf '%s' "$PLAN" | grep -qF -- "$f"; then
    OFFENDERS="$OFFENDERS $f"
  fi
done
if [ -z "$OFFENDERS" ]; then
  pass "aucun fichier ajoute par cet appel n'apparait dans le plan"
else
  fail "le plan propose de ranger ce que cet appel vient d'ecrire :$OFFENDERS"
fi

# index.md est le cas exact de la porte 11 : nomme, en plus du balayage.
if printf '%s' "$PLAN" | grep -q 'index.md'; then
  fail "le plan parle encore de index.md (porte 11)"
else
  pass "le plan ne parle plus de index.md (porte 11)"
fi

# --- Temoin negatif : l'existant mal range reste propose ----------------
if printf '%s' "$PLAN" | grep -qF 'MISSION-001-essai.md'; then
  pass "temoin : un fichier existant mal range (MISSION-001-essai.md) est toujours propose au deplacement"
else
  fail "temoin : le plan ne propose plus MISSION-001-essai.md -- il est devenu muet"
fi

# Rien n'est applique : le fichier est toujours a la racine.
if [ -f "$P/MISSION-001-essai.md" ] && [ ! -e "$P/missions/MISSION-001-essai.md" ]; then
  pass "temoin : le plan est propose, jamais applique"
else
  fail "temoin : le plan a ete applique"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
