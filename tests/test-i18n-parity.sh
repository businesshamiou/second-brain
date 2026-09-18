#!/usr/bin/env bash
# T6 (Mission 186, step 3): bash twin of tests/test-catalog-key-parity.ps1
# -- same verification, played on macOS and Linux where PowerShell is not
# available. Loads the three catalogues i18n/catalog.{fr,en,es}.json and
# proves that they declare EXACTLY the same set of keys: an
# installer or a script launched in any of the three languages
# must be able to resolve every key the code looks for, never hit
# a key missing from a single language. The "_comment" key is excluded: it
# documents the file for a human reader, no code looks for it.
#
# jq if present on the PATH, otherwise a Python script played by
# `uv run --no-project` (same mechanism as tests/test-catalog-key-parity.sh
# and tools/sb_installer_helper.py to parse JSON in bash in this repository).
#
# Two negative controls:
#   - a key removed from a throwaway COPY of a catalogue (never the real
#     file of the repository) -- the comparison must return FAIL and name the key;
#   - the NEW keys of Task 2 of Mission 186
#     (projectBootstrap.consume.instructions*) are verified present in
#     the three REAL catalogues of the repository -- concrete proof that "nouvelles
#     clefs dans fr/en/es" ["new keys in fr/en/es"] is checked, not only the general parity.
#
# Writes only in a temporary folder (prefix m186). No
# modification of the real files of the repository.
#
# usage: bash tests/test-i18n-parity.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

echo "=== T6 : parite des clefs i18n (fr, en, es) ==="

HAVE_JQ=0
command -v jq >/dev/null 2>&1 && HAVE_JQ=1

if [ "$HAVE_JQ" = "0" ]; then
  if ! sandbox_find_uv; then
    echo "FAIL : ni jq ni uv (pour Python) ne sont disponibles -- ce test ne peut pas parser du JSON"
    exit 1
  fi
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m186-i18n-parity-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

# catalog_keys <fichier.json>: one key per line, sorted, "_comment" excluded.
catalog_keys() {
  if [ "$HAVE_JQ" = "1" ]; then
    jq -r 'keys[]' "$1" | grep -vxF '_comment' | LC_ALL=C sort
  else
    uv run --no-project python -c '
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
for k in sorted(k for k in d if k != "_comment"):
    print(k)
' "$(sandbox_native_path "$1")" | LC_ALL=C sort
  fi
}

# keys_differ <fichier_a> <fichier_b>: returns 0 (differs) if the key sets
# of the two files are not identical, prints the gaps on
# stdout.
keys_differ() {
  local a="$1" b="$2" ka kb missing extra bad=1
  ka="$(catalog_keys "$a")"
  kb="$(catalog_keys "$b")"
  missing="$(comm -23 <(printf '%s\n' "$ka") <(printf '%s\n' "$kb"))"
  extra="$(comm -13 <(printf '%s\n' "$ka") <(printf '%s\n' "$kb"))"
  if [ -z "$missing" ] && [ -z "$extra" ]; then
    bad=0
  fi
  [ -n "$missing" ] && printf 'absentes de %s : %s\n' "$b" "$(printf '%s' "$missing" | tr '\n' ' ')"
  [ -n "$extra" ] && printf 'en trop dans %s : %s\n' "$b" "$(printf '%s' "$extra" | tr '\n' ' ')"
  return "$bad"
}

# =============================================================================
echo ""
echo "=== (1) oracle : les trois catalogues reels du depot ont les memes clefs ==="
FR="$REPO_ROOT/i18n/catalog.fr.json"
EN="$REPO_ROOT/i18n/catalog.en.json"
ES="$REPO_ROOT/i18n/catalog.es.json"

for f in "$FR" "$EN" "$ES"; do
  [ -f "$f" ] && pass "catalogue present : $(basename "$f")" || fail "catalogue introuvable : $f"
done

N_FR="$(catalog_keys "$FR" | wc -l | tr -d ' ')"
N_EN="$(catalog_keys "$EN" | wc -l | tr -d ' ')"
N_ES="$(catalog_keys "$ES" | wc -l | tr -d ' ')"
echo "  fr : $N_FR clefs, en : $N_EN clefs, es : $N_ES clefs"

DIFF_FR_EN="$(keys_differ "$FR" "$EN")"
if [ $? -eq 0 ]; then pass "fr/en : memes clefs"; else fail "fr/en different -- $DIFF_FR_EN"; fi
DIFF_FR_ES="$(keys_differ "$FR" "$ES")"
if [ $? -eq 0 ]; then pass "fr/es : memes clefs"; else fail "fr/es different -- $DIFF_FR_ES"; fi
DIFF_EN_ES="$(keys_differ "$EN" "$ES")"
if [ $? -eq 0 ]; then pass "en/es : memes clefs"; else fail "en/es different -- $DIFF_EN_ES"; fi

# =============================================================================
echo ""
echo "=== (2) clefs neuves de la Mission 186, Tache 2 : presentes en fr, en, es ==="
NEW_KEYS="projectBootstrap.consume.instructionsHeader projectBootstrap.consume.instructionsPath projectBootstrap.consume.instructionsVault projectBootstrap.consume.instructionsCanary projectBootstrap.consume.instructionsPurpose"
for K in $NEW_KEYS; do
  MISSING=""
  for LANG_FILE in "$FR" "$EN" "$ES"; do
    if catalog_keys "$LANG_FILE" | grep -qxF "$K"; then
      :
    else
      MISSING="$MISSING $(basename "$LANG_FILE")"
    fi
  done
  if [ -z "$MISSING" ]; then
    pass "clef neuve presente en fr, en, es : $K"
  else
    fail "clef neuve absente de :$MISSING ($K)"
  fi
done

# --- Old key removed (Task 2): must no longer exist anywhere ---------------
if catalog_keys "$FR" | grep -qxF 'projectBootstrap.consume.instructions' \
  || catalog_keys "$EN" | grep -qxF 'projectBootstrap.consume.instructions' \
  || catalog_keys "$ES" | grep -qxF 'projectBootstrap.consume.instructions'; then
  fail "l'ancienne clef projectBootstrap.consume.instructions (avec chemin {0}) est encore presente quelque part"
else
  pass "l'ancienne clef projectBootstrap.consume.instructions a bien ete retiree des trois catalogues"
fi

# =============================================================================
echo ""
echo "=== (3) temoin negatif : une clef retiree d'une copie jetable -> FAIL detecte ==="
mkdir -p "$TMP/i18n-broken"
cp "$FR" "$TMP/i18n-broken/catalog.fr.json"
cp "$EN" "$TMP/i18n-broken/catalog.en.json"
cp "$ES" "$TMP/i18n-broken/catalog.es.json"

REMOVED_KEY="projectBootstrap.consume.instructionsCanary"
if [ "$HAVE_JQ" = "1" ]; then
  jq "del(.\"$REMOVED_KEY\")" "$TMP/i18n-broken/catalog.es.json" > "$TMP/i18n-broken/catalog.es.json.tmp" \
    && mv "$TMP/i18n-broken/catalog.es.json.tmp" "$TMP/i18n-broken/catalog.es.json"
else
  uv run --no-project python -c '
import json, sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
d.pop(sys.argv[2], None)
json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
' "$(sandbox_native_path "$TMP/i18n-broken/catalog.es.json")" "$REMOVED_KEY"
fi

if catalog_keys "$TMP/i18n-broken/catalog.es.json" | grep -qxF "$REMOVED_KEY"; then
  fail "temoin : sabotage inefficace -- la clef retiree est encore la (fixture invalide)"
else
  pass "temoin : sabotage confirme -- la clef a bien disparu de la copie jetable"
fi

NEG_OUT="$(keys_differ "$TMP/i18n-broken/catalog.fr.json" "$TMP/i18n-broken/catalog.es.json")"
NEG_RC=$?
if [ "$NEG_RC" -ne 0 ] && printf '%s' "$NEG_OUT" | grep -qF "$REMOVED_KEY"; then
  pass "temoin : la clef retiree de la copie jetable es est detectee et nommee"
else
  fail "temoin : la clef retiree n'a pas ete detectee ($NEG_OUT)"
fi
# the throwaway fr/en copy, for its part, lost nothing -> no gap between them.
NEG_OK="$(keys_differ "$TMP/i18n-broken/catalog.fr.json" "$TMP/i18n-broken/catalog.en.json")"
if [ $? -eq 0 ]; then
  pass "temoin : les deux copies jetables non touchees (fr/en) restent en parite"
else
  fail "temoin : fr/en jetables ne devraient pas differer -- $NEG_OK"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
