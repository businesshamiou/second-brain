#!/usr/bin/env bash
# T2 (Mission 185-C01, porte 2 de la capture 2026-09-17-144137) :
# l'origine gravee par l'installation est l'origine REELLE du depot, jamais
# le dossier temporaire par lequel il est passe.
#
# Defaut mesure sur le poste de l'Owner : `vault_origin` -- dans
# VAULT-IDENTITY.md, dans le marqueur VAULT-ROOT.md et dans l'acte de
# naissance de chaque projet -- valait
# C:\Users\...\AppData\Local\Temp\second-brain-install, comme `origin` du
# clone installe. Cause : le bootstrap clone dans un dossier temporaire,
# l'installeur clone DEPUIS ce dossier, et personne ne reparlait de l'ou
# tout vient. Un Vault qui ne sait pas d'ou il vient ne peut ni se mettre a
# jour ni prouver sa provenance.
#
# Oracle (PASS attendu) : source portant un remote -> `vault_origin` dans
# VAULT-IDENTITY.md, dans le marqueur et dans l'acte du premier projet vaut
# l'URL de ce remote ; `git -C <clone installe> remote get-url origin` rend
# la meme URL.
# Temoin negatif (dans ce meme fichier) : source SANS remote -> repli sur
# le chemin de la source, et le message est RENDU au participant, jamais
# pose en silence.
#
# Ecrit seulement dans un dossier temporaire (prefixe m185), avec un profil
# simule (--test-mode --test-root) : rien n'atteint le profil reel. Aucun
# reseau vers GitHub -- l'URL du remote est declaree, jamais jointe.
#
# usage: bash tests/test-install-vault-origin.sh
# Code 0 : tous les cas PASS. Code 1 sinon.

# La source de chaque cas est un CLONE de ce depot, jamais une copie de
# l'arbre de travail : un clone conserve les modes de l'index (le bit
# d'execution des gardiens, absent de NTFS) et porte VAULT-IDENTITY.md a son
# etat de squelette -- les deux conditions d'une installation qui va au
# bout. Ce test mesure donc l'arbre COMMITTE, comme
# tests/test-install-e2e.sh.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/vault-identity.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- l'installeur en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-origin-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== T2 : l'origine gravee est l'origine reelle ==="
echo "  TestRoot: $TMP"

# L'URL declaree comme remote de la source. Jamais jointe : `git remote add`
# n'ouvre aucune connexion, et l'installeur clone depuis le DOSSIER.
DECLARED_ORIGIN="https://github.com/businesshamiou/second-brain.git"

run_install() {
  # $1 = racine du cas, $2 = source. Rend la sortie complete (les deux
  # flux), le code dans $LAST_RC.
  mkdir -p "$1"
  sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$1/workspace\"#" \
    "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$1/answers.json"
  LAST_OUT="$(bash "$REPO_ROOT/install.sh" --source "$2" --answers-file "$1/answers.json" \
    --test-mode --test-root "$1" 2>&1)"
  LAST_RC=$?
  # uv pose par l'installeur sous son propre profil de test : remis sur le
  # PATH de ce processus pour les mesures qui suivent (meme motif que
  # tests/test-install-e2e.sh).
  [ -d "$1/profile/.local/bin" ] && PATH="$1/profile/.local/bin:$PATH" && export PATH
  return "$LAST_RC"
}

# =============================================================================
echo ""
echo "=== (a) oracle : source portant un remote ==="
SRC_A="$TMP/source-a"
# Mission 188 : copie du clone de reference partage, au meme commit que ce
# depot (HEAD remesure par sandbox_reference_clone), au lieu d'un clone
# fait par ce seul test. Le remote est repose juste apres, comme avant.
REF_CLONE="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference non construit"; exit 1; }
if ! git clone --quiet -- "$REF_CLONE" "$SRC_A" >/dev/null 2>&1; then
  echo "FAIL : source (clone de ce depot) non construite"
  exit 1
fi
git -C "$SRC_A" remote set-url origin "$DECLARED_ORIGIN" >/dev/null 2>&1
READ_BACK="$(git -C "$SRC_A" config --get remote.origin.url)"
if [ "$READ_BACK" = "$DECLARED_ORIGIN" ]; then
  pass "(a) controle : la source porte bien le remote declare"
else
  fail "(a) controle : remote de la source = '$READ_BACK'"
fi

R_A="$TMP/a"
run_install "$R_A" "$SRC_A"
RC_A=$?
if [ "$RC_A" = "0" ]; then
  pass "(a) l'installation rend 0"
else
  fail "(a) l'installation rend $RC_A -- $(printf '%s' "$LAST_OUT" | tail -n 3)"
fi

CLONE_A="$R_A/workspace/second-brain"
GOT_REMOTE="$(git -C "$CLONE_A" config --get remote.origin.url 2>/dev/null || echo absent)"
if [ "$GOT_REMOTE" = "$DECLARED_ORIGIN" ]; then
  pass "(a) origin du clone installe = l'origine reelle"
else
  fail "(a) origin du clone installe = '$GOT_REMOTE', attendu '$DECLARED_ORIGIN'"
fi

GOT_IDENTITY="$(vid_get "$CLONE_A" vault_origin)"
if [ "$GOT_IDENTITY" = "$DECLARED_ORIGIN" ]; then
  pass "(a) VAULT-IDENTITY.md : vault_origin = l'origine reelle"
else
  fail "(a) VAULT-IDENTITY.md : vault_origin = '$GOT_IDENTITY'"
fi

MARKER="$R_A/workspace/VAULT-ROOT.md"
if [ -f "$MARKER" ] && grep -qF -- "$DECLARED_ORIGIN" "$MARKER"; then
  pass "(a) marqueur VAULT-ROOT.md : vault_origin = l'origine reelle"
else
  fail "(a) marqueur VAULT-ROOT.md ne porte pas l'origine reelle"
fi

CERT="$(ls -1 "$R_A"/workspace/*/.pre-commit-config.yaml 2>/dev/null | head -n 1)"
if [ -n "$CERT" ]; then
  CERT_ORIGIN="$(tr -d '\r' < "$CERT" | sed -n 's/^# vault_origin: //p' | head -n 1)"
  if [ "$CERT_ORIGIN" = "$DECLARED_ORIGIN" ]; then
    pass "(a) acte de naissance du premier projet : vault_origin = l'origine reelle"
  else
    fail "(a) acte du premier projet : vault_origin = '$CERT_ORIGIN'"
  fi
else
  fail "(a) aucun acte de naissance trouve : le premier projet n'a pas ete cree"
fi

# Le defaut d'origine est nomme : le chemin du dossier source ne doit
# apparaitre nulle part comme origine.
if [ -n "$(vid_get "$CLONE_A" vault_origin)" ] && ! printf '%s' "$GOT_IDENTITY" | grep -q 'second-brain-install'; then
  pass "(a) aucune trace du dossier temporaire dans vault_origin"
else
  fail "(a) vault_origin porte encore une trace de dossier temporaire"
fi

# =============================================================================
echo ""
echo "=== temoin negatif : source SANS remote ==="
SRC_B="$TMP/source-b"
if ! git clone --quiet -- "$REF_CLONE" "$SRC_B" >/dev/null 2>&1; then
  echo "FAIL : source (clone de ce depot) non construite"
  exit 1
fi
git -C "$SRC_B" remote remove origin >/dev/null 2>&1
if [ -z "$(git -C "$SRC_B" config --get remote.origin.url 2>/dev/null || true)" ]; then
  pass "temoin : controle -- la source n'a aucun remote"
else
  fail "temoin : controle -- la source a un remote, le temoin ne prouverait rien"
fi

R_B="$TMP/b"
run_install "$R_B" "$SRC_B"
RC_B=$?
[ "$RC_B" = "0" ] && pass "temoin : l'installation rend 0 quand meme" || fail "temoin : l'installation rend $RC_B"

CLONE_B="$R_B/workspace/second-brain"
ORIGIN_B="$(vid_get "$CLONE_B" vault_origin)"
SRC_B_REAL="$(cd "$SRC_B" && pwd)"
if [ -n "$ORIGIN_B" ]; then
  pass "temoin : vault_origin est renseigne malgre l'absence de remote ($ORIGIN_B)"
else
  fail "temoin : vault_origin est vide"
fi
# Le repli est le CHEMIN de la source, pas une invention.
if printf '%s' "$ORIGIN_B" | grep -qF -- "$(basename "$SRC_B_REAL")"; then
  pass "temoin : le repli est bien le chemin de la source"
else
  fail "temoin : le repli ($ORIGIN_B) ne nomme pas la source ($SRC_B_REAL)"
fi
# ... et il est DIT, jamais pose en silence.
MESSAGE="$(uv run --no-project "$REPO_ROOT/tools/sb_installer_helper.py" format-catalog \
  "$REPO_ROOT/i18n/catalog.en.json" "install.vaultOrigin.fallback" "$SRC_B_REAL" 2>/dev/null | head -n 1)"
MARKER_WORDS="$(printf '%s' "$MESSAGE" | sed 's/[^A-Za-z ].*$//' | head -n 1)"
if [ -n "$MARKER_WORDS" ] && printf '%s' "$LAST_OUT" | grep -qF -- "$MARKER_WORDS"; then
  pass "temoin : le repli est dit au participant (\"$MARKER_WORDS...\")"
else
  fail "temoin : le repli est pose en silence -- attendu \"$MARKER_WORDS\" dans la sortie"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
