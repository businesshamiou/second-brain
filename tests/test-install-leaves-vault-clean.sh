#!/usr/bin/env bash
# T3 (Mission 185-C01, porte 8 de la capture 2026-09-17-144137) : une
# installation terminee laisse le Vault installe au porcelain VIDE.
#
# Defaut mesure sur le poste de l'Owner : apres l'installation, la fiche du
# premier projet restait non suivie et deux index modifies. Le tout premier
# commit du participant aurait emporte des fichiers qu'il n'a pas ecrits,
# et le gardien de fraicheur des index refuse justement un index modifie :
# le Vault etait livre dans l'etat qu'il interdit.
#
# Oracle (PASS attendu) : `git status --porcelain` du clone installe est
# vide a la fin de l'installation -- et une seconde execution ne fabrique
# aucun commit (la reprise reste un no-op).
# Temoin negatif (dans ce meme fichier) : une installation INTERROMPUE
# avant le commit de fin (arret force apres l'etape firstProject) laisse un
# porcelain NON vide, vu par la meme mesure -- sans quoi ce test passerait
# aussi sur un depot ou rien ne se serait ecrit.
#
# La source est un CLONE de ce depot, jamais une copie de l'arbre de
# travail : un clone conserve les modes de l'index (le bit d'execution des
# gardiens, absent de NTFS) et porte VAULT-IDENTITY.md a son etat de
# squelette. Ce test mesure donc l'arbre COMMITTE, comme
# tests/test-install-e2e.sh.
#
# Ecrit seulement dans un dossier temporaire (prefixe m185), profil simule.
#
# usage: bash tests/test-install-leaves-vault-clean.sh
# Code 0 : tous les cas PASS. Code 1 sinon.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- l'installeur en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-clean-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== T3 : le Vault installe est rendu au porcelain vide ==="
echo "  TestRoot: $TMP"

SRC="$TMP/source"
if ! git clone --quiet -- "$REPO_ROOT" "$SRC" >/dev/null 2>&1; then
  echo "FAIL : source (clone de ce depot) non construite"
  exit 1
fi

run_install() {
  # $1 = racine du cas, $2... = arguments supplementaires pour install.sh.
  CASE_ROOT="$1"; shift
  mkdir -p "$CASE_ROOT"
  sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$CASE_ROOT/workspace\"#" \
    "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$CASE_ROOT/answers.json"
  LAST_OUT="$(bash "$REPO_ROOT/install.sh" --source "$SRC" --answers-file "$CASE_ROOT/answers.json" \
    --test-mode --test-root "$CASE_ROOT" "$@" 2>&1)"
  LAST_RC=$?
  [ -d "$CASE_ROOT/profile/.local/bin" ] && PATH="$CASE_ROOT/profile/.local/bin:$PATH" && export PATH
  return "$LAST_RC"
}

porcelain_of() {
  git -C "$1" status --porcelain 2>/dev/null
}

# =============================================================================
echo ""
echo "=== (a) oracle : installation complete ==="
R_A="$TMP/a"
run_install "$R_A"
RC_A=$?
if [ "$RC_A" = "0" ]; then
  pass "(a) l'installation rend 0"
else
  fail "(a) l'installation rend $RC_A -- $(printf '%s' "$LAST_OUT" | tail -n 3)"
fi

CLONE_A="$R_A/workspace/second-brain"
if [ -d "$CLONE_A/.git" ]; then
  pass "(a) le Vault est installe"
else
  fail "(a) aucun Vault installe"
  echo "=== RESULT: FAIL ($FAILURES) ==="
  exit 1
fi

PORC_A="$(porcelain_of "$CLONE_A")"
if [ -z "$PORC_A" ]; then
  pass "(a) git status --porcelain du Vault installe : vide"
else
  fail "(a) porcelain non vide :
$(printf '%s' "$PORC_A" | sed 's/^/      /')"
fi

# Le premier projet existe bien : sans lui, le porcelain serait vide pour
# une mauvaise raison et cette mesure ne prouverait rien.
FIRST_PROJECT="$(ls -1d "$R_A"/workspace/*/ 2>/dev/null | grep -v '/second-brain/$' | head -n 1)"
if [ -n "$FIRST_PROJECT" ]; then
  pass "(a) controle : un premier projet a bien ete cree ($(basename "${FIRST_PROJECT%/}"))"
else
  fail "(a) controle : aucun premier projet -- la mesure ne prouverait rien"
fi

# La fiche du projet est SUIVIE, pas laissee de cote.
UNTRACKED_RECORD="$(git -C "$CLONE_A" ls-files --others --exclude-standard -- projects/ 2>/dev/null)"
if [ -z "$UNTRACKED_RECORD" ]; then
  pass "(a) aucune fiche de projet non suivie"
else
  fail "(a) fiche(s) de projet non suivie(s) : $UNTRACKED_RECORD"
fi

# Une seconde execution reste un no-op : aucun commit fabrique.
HEAD_BEFORE="$(git -C "$CLONE_A" rev-parse HEAD)"
run_install "$R_A"
RC_A2=$?
HEAD_AFTER="$(git -C "$CLONE_A" rev-parse HEAD)"
[ "$RC_A2" = "0" ] && pass "(a) seconde execution : rend 0" || fail "(a) seconde execution : rend $RC_A2"
if [ "$HEAD_BEFORE" = "$HEAD_AFTER" ]; then
  pass "(a) seconde execution : aucun commit fabrique"
else
  fail "(a) seconde execution : un commit a ete fabrique ($HEAD_BEFORE -> $HEAD_AFTER)"
fi
if [ -z "$(porcelain_of "$CLONE_A")" ]; then
  pass "(a) seconde execution : porcelain toujours vide"
else
  fail "(a) seconde execution : porcelain devenu non vide"
fi

# =============================================================================
echo ""
echo "=== temoin negatif : installation interrompue avant le commit de fin ==="
R_B="$TMP/b"
run_install "$R_B" --stop-after-step firstProject
RC_B=$?
[ "$RC_B" != "0" ] && pass "temoin : l'arret force rend un code non nul ($RC_B)" \
  || fail "temoin : l'arret force rend 0"
CLONE_B="$R_B/workspace/second-brain"
PORC_B="$(porcelain_of "$CLONE_B")"
if [ -n "$PORC_B" ]; then
  pass "temoin : la meme mesure voit un porcelain NON vide ($(printf '%s\n' "$PORC_B" | grep -c .) ligne(s))"
  printf '%s\n' "$PORC_B" | head -n 4 | sed 's/^/      /'
else
  fail "temoin : porcelain vide alors que l'installation a ete interrompue -- la mesure ne prouverait rien"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
