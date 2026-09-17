#!/usr/bin/env bash
# T1 (Mission 185-C01, porte 1 de la capture 2026-09-17-144137) : un
# dossier temporaire DEJA clone est amene a --ref, jamais installe tel
# qu'il est.
#
# Defaut mesure sur le poste de l'Owner, le plus grave de l'acceptation :
# `bootstrap.*` sautait clone ET checkout des que <cible>/.git existait.
# Un %TEMP%\second-brain-install oublie (2026-09-14, commit du 2026-09-13,
# anterieur a toute etiquette) a donc installe une version perimee -- sans
# identite, sans acte de naissance, sans prompt Pilot -- avec un verdict
# propre. Invisible en CI, ou chaque scenario part d'un TestRoot vide.
#
# Oracle (PASS attendu) : un TestRoot dont `second-brain-install` est deja
# clone a un commit ANTERIEUR, puis la ligne ; apres elle,
# `rev-parse HEAD` du dossier temporaire = `<ref>^{commit}`, et le Vault
# installe est au meme commit.
# Temoins negatifs (dans ce meme fichier) :
#   - `--ref` inexistant -> refus qui nomme le ref, rien d'installe ;
#   - dossier temporaire dont `origin` n'est pas `--repo-url` -> refus qui
#     nomme les DEUX URL, rien d'installe, dossier jamais supprime.
#
# Le vrai bootstrap est rejoue, avec `--repo-url`/`--raw-base` locaux --
# meme patron que tests/test-bootstrap-no-git.ps1 -- et l'installation est
# arretee juste apres l'etape de clone : ce test mesure l'etape de clone,
# pas l'installation complete (mesuree par tests/test-install-e2e.sh).
#
# Ecrit seulement dans un dossier temporaire (prefixe m185). Aucun reseau
# vers GitHub, aucun appel modele.
#
# usage: bash tests/test-bootstrap-stale-temp-clone.sh
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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-stale-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== T1 : dossier temporaire deja clone, amene a --ref ==="
echo "  TestRoot: $TMP"

# --- Une source locale a DEUX commits et une etiquette -------------------
# L'etiquette est posee APRES le commit du clone perime : c'est la
# situation exacte du poste de l'Owner -- le dossier oublie ne connait pas
# encore la version publiee.
SRC="$TMP/source"
if ! sandbox_vault "$REPO_ROOT" "$SRC"; then
  echo "FAIL : source jetable non construite"
  exit 1
fi
OLD_REF="$(git -C "$SRC" rev-parse HEAD)"
printf '\nUne ligne de la version suivante.\n' >> "$SRC/USER.md"
git -C "$SRC" add -- USER.md >/dev/null 2>&1
git -C "$SRC" commit -q -m "version suivante" >/dev/null 2>&1
NEW_REF="$(git -C "$SRC" rev-parse HEAD)"
git -C "$SRC" tag v-test >/dev/null 2>&1
WANTED="$(git -C "$SRC" rev-parse 'v-test^{commit}')"

if [ "$OLD_REF" != "$NEW_REF" ] && [ "$WANTED" = "$NEW_REF" ]; then
  pass "controle : source a deux commits, etiquette v-test sur le second"
else
  fail "controle : source mal construite (old=$OLD_REF new=$NEW_REF tag=$WANTED)"
  echo "=== RESULT: FAIL ($FAILURES) ==="
  exit 1
fi

answers_file() {
  # $1 = TestRoot du cas. Rend le chemin du fichier de reponses ecrit.
  sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$1/workspace\"#" \
    "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$1/answers.json"
  printf '%s\n' "$1/answers.json"
}

stale_clone() {
  # $1 = TestRoot, $2 = commit a poser. Clone perime, detache, comme un
  # dossier temporaire oublie par une installation precedente.
  mkdir -p "$1"
  git clone --quiet --no-checkout -- "$SRC" "$1/second-brain-install" >/dev/null 2>&1 || return 1
  git -C "$1/second-brain-install" -c advice.detachedHead=false checkout --quiet --detach "$2" >/dev/null 2>&1 || return 1
  # Le dossier oublie du poste de l'Owner datait d'AVANT la publication : il
  # ne connaissait aucune etiquette. `git clone` en rapporte toujours ;
  # elles sont retirees ici pour reproduire cet etat exactement, et c'est
  # `fetch --tags` de la ligne qui doit les ramener.
  git -C "$1/second-brain-install" tag -d v-test >/dev/null 2>&1 || true
  return 0
}

# =============================================================================
echo ""
echo "=== (a) oracle : le dossier perime est amene a l'etiquette ==="
R_A="$TMP/a"
mkdir -p "$R_A"
if ! stale_clone "$R_A" "$OLD_REF"; then
  echo "FAIL : clone perime non construit"
  exit 1
fi
HEAD_BEFORE="$(git -C "$R_A/second-brain-install" rev-parse HEAD)"
if [ "$HEAD_BEFORE" = "$OLD_REF" ]; then
  pass "(a) controle : le dossier temporaire part bien d'un commit anterieur ($OLD_REF)"
else
  fail "(a) controle : le dossier temporaire n'est pas au commit anterieur"
fi
if git -C "$R_A/second-brain-install" rev-parse --verify --quiet 'refs/tags/v-test' >/dev/null; then
  fail "(a) controle : le dossier temporaire connait deja l'etiquette -- le cas n'est pas reproduit"
else
  pass "(a) controle : le dossier temporaire ne connait pas encore l'etiquette"
fi

A_ANSWERS="$(answers_file "$R_A")"
OUT_A="$(bash "$REPO_ROOT/bootstrap.sh" --ref v-test --repo-url "$SRC" --raw-base "$SRC" \
  --test-mode --test-root "$R_A" --answers-file "$A_ANSWERS" --stop-after-step clone 2>&1)"
printf '%s\n' "$OUT_A" | tail -n 3 | sed 's/^/    /'

case "$OUT_A" in
  *"after step: clone"*) pass "(a) l'installation a bien atteint l'etape de clone" ;;
  *) fail "(a) l'etape de clone n'a pas ete atteinte" ;;
esac
HEAD_AFTER="$(git -C "$R_A/second-brain-install" rev-parse HEAD 2>/dev/null || echo absent)"
if [ "$HEAD_AFTER" = "$WANTED" ]; then
  pass "(a) dossier temporaire : HEAD = v-test^{commit} ($WANTED)"
else
  fail "(a) dossier temporaire : HEAD = $HEAD_AFTER, attendu $WANTED"
fi
INSTALLED="$R_A/workspace/second-brain"
INSTALLED_HEAD="$(git -C "$INSTALLED" rev-parse HEAD 2>/dev/null || echo absent)"
if [ "$INSTALLED_HEAD" = "$WANTED" ]; then
  pass "(a) Vault installe : HEAD = v-test^{commit}"
else
  fail "(a) Vault installe : HEAD = $INSTALLED_HEAD, attendu $WANTED"
fi
# Le contenu suit le commit, pas seulement la reference.
if [ -f "$INSTALLED/USER.md" ] && grep -q 'Une ligne de la version suivante' "$INSTALLED/USER.md"; then
  pass "(a) le contenu installe est celui de v-test, pas celui du dossier perime"
else
  fail "(a) le contenu installe n'est pas celui de v-test"
fi

# =============================================================================
echo ""
echo "=== (b) temoin : --ref inexistant ==="
R_B="$TMP/b"
mkdir -p "$R_B"
stale_clone "$R_B" "$OLD_REF" || { echo "FAIL : clone perime non construit"; exit 1; }
B_ANSWERS="$(answers_file "$R_B")"
OUT_B="$(bash "$REPO_ROOT/bootstrap.sh" --ref v-inexistante --repo-url "$SRC" --raw-base "$SRC" \
  --test-mode --test-root "$R_B" --answers-file "$B_ANSWERS" --stop-after-step clone 2>&1)"
RC_B=$?
[ "$RC_B" != "0" ] && pass "(b) rend un code non nul ($RC_B)" || fail "(b) rend 0 alors que le ref n'existe pas"
case "$OUT_B" in
  *"v-inexistante"*) pass "(b) le refus nomme le ref demande" ;;
  *) fail "(b) le refus ne nomme pas le ref -- $OUT_B" ;;
esac
if [ -e "$R_B/workspace/second-brain" ]; then
  fail "(b) un Vault a quand meme ete installe"
else
  pass "(b) rien n'est installe"
fi
HEAD_B="$(git -C "$R_B/second-brain-install" rev-parse HEAD 2>/dev/null || echo absent)"
if [ "$HEAD_B" = "$OLD_REF" ]; then
  pass "(b) le dossier temporaire est laisse ou il etait, jamais supprime"
else
  fail "(b) le dossier temporaire a bouge ($HEAD_B)"
fi

# =============================================================================
echo ""
echo "=== (c) temoin : dossier temporaire d'une AUTRE origine ==="
R_C="$TMP/c"
mkdir -p "$R_C"
stale_clone "$R_C" "$OLD_REF" || { echo "FAIL : clone perime non construit"; exit 1; }
OTHER="$TMP/autre-depot"
mkdir -p "$OTHER"
git -C "$R_C/second-brain-install" remote set-url origin "$OTHER" >/dev/null 2>&1
C_ANSWERS="$(answers_file "$R_C")"
OUT_C="$(bash "$REPO_ROOT/bootstrap.sh" --ref v-test --repo-url "$SRC" --raw-base "$SRC" \
  --test-mode --test-root "$R_C" --answers-file "$C_ANSWERS" --stop-after-step clone 2>&1)"
RC_C=$?
[ "$RC_C" != "0" ] && pass "(c) rend un code non nul ($RC_C)" || fail "(c) rend 0 malgre l'origine differente"
# Les deux URL sont nommees telles que chaque source les ecrit : celle du
# dossier vient de son .git/config (forme native sous Git Bash), celle
# demandee vient de la ligne. C'est justement ce qu'il faut montrer au
# participant -- on compare donc les dossiers nommes, pas une orthographe.
NAMED_BOTH=0
case "$OUT_C" in
  *"$(basename "$OTHER")"*)
    case "$OUT_C" in *"$(basename "$SRC")"*) NAMED_BOTH=1 ;; esac ;;
esac
if [ "$NAMED_BOTH" = "1" ]; then
  pass "(c) le refus nomme les DEUX depots (celui du dossier et celui demande)"
else
  fail "(c) le refus ne nomme pas les deux depots -- $OUT_C"
fi
case "$OUT_C" in
  *"$R_C/second-brain-install"*) pass "(c) le refus nomme le dossier a ecarter" ;;
  *) fail "(c) le refus ne nomme pas le dossier a ecarter" ;;
esac
if [ -e "$R_C/workspace/second-brain" ]; then
  fail "(c) un Vault a quand meme ete installe"
else
  pass "(c) rien n'est installe"
fi
if [ -d "$R_C/second-brain-install/.git" ]; then
  pass "(c) le dossier temporaire n'est jamais supprime"
else
  fail "(c) le dossier temporaire a ete supprime"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
