#!/usr/bin/env bash
# Key parity of the three i18n catalogues (fr, en, es) -- shell twin of
# tests/test-catalog-key-parity.ps1, played on the three systems (Mission
# 184): every message meant for the participant, including those of the
# initiation and of the MCP server, exists in the three languages.
#
# Negative control: a catalogue stripped of one key, in a temporary
# folder, is detected by the same comparison.
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

# --- T11 (Mission 185-C01): the NEW keys of this Mission exist
# in the three languages. Parity alone is not enough -- three catalogues
# that all lack the same key are perfectly at parity. Each key
# added by a Mission is therefore named here, once, and the control
# below removes it to prove the measurement can fail. ---
NEW_KEYS="install.vaultOrigin.fallback"
for K in $NEW_KEYS; do
  MISSING=""
  for LANG in en fr es; do
    uv run --no-project python -c "import json,sys; d=json.load(open(sys.argv[1],encoding='utf-8')); sys.exit(0 if sys.argv[2] in d else 1)" \
      "$(sandbox_native_path "$REPO_ROOT/i18n/catalog.$LANG.json")" "$K" \
      || MISSING="$MISSING $LANG"
  done
  if [ -z "$MISSING" ]; then
    echo "  PASS - clef neuve presente en fr, en, es : $K"
  else
    echo "  FAIL - clef neuve absente de :$MISSING ($K)"
    FAILURES=$((FAILURES + 1))
  fi
done

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

# Control of the T11 measurement itself: a NEW key removed from a
# catalogue is seen by the presence check above.
mkdir -p "$TMP/i18n-new"
cp "$REPO_ROOT/i18n/catalog.fr.json" "$TMP/i18n-new/catalog.fr.json"
for K in $NEW_KEYS; do
  uv run --no-project python -c "import json,sys; p=sys.argv[1]; d=json.load(open(p,encoding='utf-8')); d.pop(sys.argv[2],None); json.dump(d,open(p,'w',encoding='utf-8'),ensure_ascii=False)" \
    "$(sandbox_native_path "$TMP/i18n-new/catalog.fr.json")" "$K"
  if uv run --no-project python -c "import json,sys; d=json.load(open(sys.argv[1],encoding='utf-8')); sys.exit(0 if sys.argv[2] in d else 1)" \
      "$(sandbox_native_path "$TMP/i18n-new/catalog.fr.json")" "$K"; then
    echo "  FAIL - temoin : la clef neuve retiree ($K) est encore vue presente"
    FAILURES=$((FAILURES + 1))
  else
    echo "  PASS - temoin : une clef neuve retiree de catalog.fr.json est detectee ($K)"
  fi
done

if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
