#!/usr/bin/env bash
# Parite des clefs des trois catalogues i18n (fr, en, es) -- jumeau shell de
# tests/test-catalog-key-parity.ps1, joue sur les trois systemes (Mission
# 184) : tout message destine au participant, dont ceux de l'initiation et
# du serveur MCP, existe dans les trois langues.
#
# Temoin negatif : un catalogue ampute d'une clef, dans un dossier
# temporaire, est detecte par la meme comparaison.
#
# usage: bash tests/test-catalog-key-parity.sh

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"
sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m184-parity-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/parity.py" <<'PY'
import json, sys
d = sys.argv[1]
keys = {}
for lang in ("en", "fr", "es"):
    data = json.load(open("%s/catalog.%s.json" % (d, lang), encoding="utf-8"))
    keys[lang] = {k for k in data if k != "_comment"}
ref = keys["en"]
bad = 0
for lang in ("fr", "es"):
    missing = sorted(ref - keys[lang])
    extra = sorted(keys[lang] - ref)
    if missing or extra:
        bad = 1
        print("%s: manquantes %s, en trop %s" % (lang, missing, extra))
print("clefs: %d" % len(ref))
sys.exit(bad)
PY

FAILURES=0
OUT="$(uv run --no-project "$TMP/parity.py" "$(sandbox_native_path "$REPO_ROOT/i18n")" 2>&1)"
if [ $? -eq 0 ]; then
  echo "  PASS - fr, en, es : memes clefs ($OUT)"
else
  echo "  FAIL - parite rompue : $OUT"
  FAILURES=$((FAILURES + 1))
fi

mkdir -p "$TMP/i18n"
cp "$REPO_ROOT/i18n/catalog.en.json" "$REPO_ROOT/i18n/catalog.fr.json" "$TMP/i18n/"
cp "$REPO_ROOT/i18n/catalog.es.json" "$TMP/i18n/catalog.es.json"
uv run --no-project python -c "import json,sys; p=sys.argv[1]; d=json.load(open(p,encoding='utf-8')); d.pop('projectBootstrap.consume.header'); json.dump(d,open(p,'w',encoding='utf-8'),ensure_ascii=False)" "$(sandbox_native_path "$TMP/i18n/catalog.es.json")"
NEG="$(uv run --no-project "$TMP/parity.py" "$(sandbox_native_path "$TMP/i18n")" 2>&1)"
if [ $? -ne 0 ] && printf '%s' "$NEG" | grep -q 'projectBootstrap.consume.header'; then
  echo "  PASS - temoin : une clef retiree de catalog.es.json est detectee"
else
  echo "  FAIL - temoin : la clef retiree n'a pas ete vue ($NEG)"
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
