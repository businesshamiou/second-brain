#!/usr/bin/env bash
# T4 (Mission 192, Decision 210904): the backup oracle
# (tools/check-backup-bundle.sh) proves a bundle by restoring it.
#
#   (a) a sound bundle of a small repository -> PASS, refs restored;
#   (b) the same bundle with its pack truncated -> FAIL;
#   control, measured: on that truncated bundle `git bundle verify` alone
#   still succeeds -- the gap this oracle closes (Mission 190, P1).
#
# usage: bash tests/test-backup-oracle.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORACLE="$REPO_ROOT/tools/check-backup-bundle.sh"
FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m192-bundle-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== T4 : oracle de sauvegarde (bundle restaure, pas seulement verifie) ==="
R="$TMP/repo"
git init -q "$R"
git -C "$R" config user.email t@example.invalid
git -C "$R" config user.name t
git -C "$R" config core.autocrlf false
# Enough incompressible content that truncating the bundle cuts the pack.
i=0
while [ "$i" -lt 20 ]; do
  od -An -N4096 -tx1 /dev/urandom > "$R/f$i.txt"
  git -C "$R" add "f$i.txt" && git -C "$R" commit -q -m "c$i"
  i=$((i + 1))
done
git -C "$R" bundle create -q "$TMP/sound.bundle" --all 2>/dev/null
SIZE="$(wc -c < "$TMP/sound.bundle" | tr -d ' ')"
head -c "$((SIZE / 2))" "$TMP/sound.bundle" > "$TMP/truncated.bundle"

OUT_A="$(bash "$ORACLE" "$TMP/sound.bundle" 2>&1)"; RC_A=$?
case "$RC_A:$OUT_A" in
  0:*PASS*) pass "(a) bundle sain ($SIZE octets) -> PASS" ;;
  *) fail "(a) bundle sain : sortie $RC_A -- $OUT_A" ;;
esac

OUT_B="$(bash "$ORACLE" "$TMP/truncated.bundle" 2>&1)"; RC_B=$?
case "$RC_B:$OUT_B" in
  1:*FAIL*) pass "(b) pack tronque -> FAIL ($OUT_B)" ;;
  *) fail "(b) pack tronque : sortie $RC_B -- $OUT_B" ;;
esac

git init -q "$TMP/v"
if git -C "$TMP/v" bundle verify -q "$TMP/truncated.bundle" >/dev/null 2>&1; then
  pass "controle : git bundle verify seul accepte le bundle tronque (l'ecart que l'oracle ferme)"
else
  fail "controle : git bundle verify seul refuse deja le bundle tronque -- le temoin ne mesure plus l'ecart"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
