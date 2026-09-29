#!/usr/bin/env bash
# Mission 237, step 1: the name of a Pilot Project is ASCII, `SB - <display
# name>` (rule 112218 D-A, separator amended by Mission 237).
#
# Oracle:
#   (a) no tracked file of the corpus (history excepted: tests/fixtures/,
#       skills-warehouse/) carries the first prefix, "SB" + middle dot;
#   (b) on a throwaway Vault, `project-bootstrap.sh create` writes
#       pilot_project_name "SB - <name>" and prints the same name in its block,
#       both pure ASCII; `accueil-prompt` names "SB - Accueil";
#       `identity --check` is CONCORDANT;
#   (c) every catalogue value that names a Project prefix uses "SB - ";
#   (d) negative control: a copy of a catalogue carrying the first prefix is
#       caught.
#
# usage: bash tests/test-project-name-ascii.sh [<source repo>]
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$REPO_ROOT}"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

OLD="$(printf 'SB \302\267')"
is_ascii() { LC_ALL=C grep -q '[^ -~]' <<<"$1" && return 1 || return 0; }

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m237-ascii-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"

echo "=== Mission 237 : nom des Projects en ASCII ($SRC) ==="

# (a) the corpus
HITS="$(git -C "$SRC" grep -n -F "$OLD" -- . ':!tests/fixtures' ':!skills-warehouse' 2>/dev/null | grep -v '^tests/test-project-name-ascii' || true)"
[ -z "$HITS" ] && pass "(a) aucun fichier suivi ne porte l'ancien prefixe" || fail "(a) ancien prefixe present : $(printf '%s' "$HITS" | head -3)"

# (c) the catalogues
catalog_old() { grep -n -F "$OLD" "$1" || true; }
BAD=""
for c in "$SRC"/i18n/catalog.fr.json "$SRC"/i18n/catalog.en.json "$SRC"/i18n/catalog.es.json; do
  [ -n "$(catalog_old "$c")" ] && BAD="$BAD $(basename "$c")"
done
[ -z "$BAD" ] && pass "(c) les trois catalogues nomment le prefixe en ASCII" || fail "(c) catalogues en defaut :$BAD"
cp "$SRC/i18n/catalog.en.json" "$TMP/witness.json"; printf '%s\n' "  \"x\": \"$OLD Demo\"" >> "$TMP/witness.json"
[ -n "$(catalog_old "$TMP/witness.json")" ] && pass "(d) temoin : une copie portant l'ancien prefixe est attrapee" || fail "(d) temoin non attrape"

# (b) the tools
mkdir -p "$WS"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" --marker-only "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
OUT="$(bash "$V/tools/project-bootstrap.sh" create "$WS/demo" "Demo Name" EN --vcs none 2>&1)"; RC=$?
NAME="$(sed -n 's/^pilot_project_name: "\(.*\)"$/\1/p' "$WS/demo/state/PILOT-PROMPT.md" 2>/dev/null | tr -d '\r')"
if [ "$RC" -eq 0 ] && [ "$NAME" = "SB - Demo Name" ] && is_ascii "$NAME"; then
  pass "(b) pilot_project_name = « SB - Demo Name », ASCII"
else
  fail "(b) create : rc=$RC, pilot_project_name=« $NAME »"
fi
LINE="$(printf '%s\n' "$OUT" | grep 'Project named' | head -1)"
{ printf '%s' "$LINE" | grep -qF '"SB - Demo Name"' && is_ascii "$LINE"; } \
  && pass "(b) le bloc de create nomme \"SB - Demo Name\" en ASCII" || fail "(b) bloc de create : $LINE"
ACC="$(bash "$V/tools/project-bootstrap.sh" accueil-prompt 2>&1 | grep -m1 'Accueil')"
{ printf '%s' "$ACC" | grep -qF 'SB - Accueil' && is_ascii "$(printf '%s' "$ACC" | grep -o 'SB - Accueil')"; } \
  && pass "(b) accueil-prompt nomme « SB - Accueil »" || fail "(b) accueil-prompt : $ACC"
ID="$(bash "$V/tools/project-bootstrap.sh" identity "$WS/demo" --check 2>&1)"; RC=$?
{ [ "$RC" -eq 0 ] && printf '%s' "$ID" | grep -q 'CONCORDANT'; } && pass "(b) identity --check CONCORDANT" || fail "(b) identity --check : rc=$RC"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES, $PASSES PASS) ==="
exit 1
