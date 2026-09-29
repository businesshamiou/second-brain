#!/usr/bin/env bash
# Mission 234 (report 233 §3.10, amendment A-3): tools/resolve-vault.sh refuses
# a workspace marker WITHOUT identity. An old workspace kept a pre-identity
# marker; every tool launched below it resolved the old Vault, because the
# identity check was skipped when the marker carried none.
#
#   (a) marker without identity, a Vault at its path -> REFUS naming the
#       marker (RED before: the old Vault was resolved);
#   (b) the same marker, retired (renamed VAULT-ROOT.md.retired) below a
#       workspace whose marker carries an identity -> the walk goes on up and
#       resolves THAT workspace's Vault, never the old one;
#   (c) a marker with identity, the Vault carrying it -> resolved (unchanged);
#   (d) a marker with identity, the Vault carrying another -> refused
#       (unchanged).
#
# usage: bash tests/test-resolve-vault-marker-identity.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$REPO_ROOT/tools/resolve-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "$(sb_tmp_dir tests)/m234-rv-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"

fake_vault() { # <dir> <vault_id>
  mkdir -p "$1"
  printf -- '---\ntype: vault-identity\nstatus: generated\nvault_id: "%s"\n---\n' "$2" > "$1/VAULT-IDENTITY.md"
}
marker() { # <dir> <rel> [<id>]
  {
    printf 'Chemin relatif du Vault depuis cette racine de travail : `%s`\n\n' "$2"
    [ -n "${3:-}" ] && printf 'Identité du Vault : `%s`\n' "$3"
  } > "$1/VAULT-ROOT.md"
}

echo "=== Mission 234 : marqueur sans identite refuse par resolve-vault ==="

# Outer workspace with an identified Vault; an old workspace nested inside it.
fake_vault "$TMP/ws/vault" "sb-new"
marker "$TMP/ws" "vault" "sb-new"
fake_vault "$TMP/ws/old/vault" "sb-old"
marker "$TMP/ws/old" "vault"
mkdir -p "$TMP/ws/old/bootstrap"

OUT="$(bash "$TOOL" "$TMP/ws/old/bootstrap" 2>&1)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q 'marqueur sans identité du Vault' && ! printf '%s' "$OUT" | grep -q '/old/vault$'; then
  pass "(a) marqueur sans identite : refuse, marqueur nomme"
else
  fail "(a) marqueur sans identite : rc=$RC : $OUT"
fi

mv "$TMP/ws/old/VAULT-ROOT.md" "$TMP/ws/old/VAULT-ROOT.md.retired"
OUT="$(bash "$TOOL" "$TMP/ws/old/bootstrap" 2>&1)"; RC=$?
if [ "$RC" -ne 0 ]; then
  # Two candidate Vaults under the outer marker (vault and old/vault are not
  # both siblings: only ws/vault is) -- expected: ws/vault.
  fail "(b) marqueur retire : rc=$RC : $OUT"
elif [ "$OUT" = "$TMP/ws/vault" ]; then
  pass "(b) marqueur retire : la remontee resout le Vault de l'espace englobant, jamais l'ancien"
else
  fail "(b) marqueur retire : resolu $OUT"
fi

mkdir -p "$TMP/ws2/p"
fake_vault "$TMP/ws2/vault" "sb-two"
marker "$TMP/ws2" "vault" "sb-two"
OUT="$(bash "$TOOL" "$TMP/ws2/p" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && [ "$OUT" = "$TMP/ws2/vault" ]; then
  pass "(c) marqueur avec identite, Vault conforme : resolu (inchange)"
else
  fail "(c) marqueur avec identite : rc=$RC : $OUT"
fi

marker "$TMP/ws2" "vault" "sb-other"
OUT="$(bash "$TOOL" "$TMP/ws2/p" 2>&1)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q 'identité du Vault différente'; then
  pass "(d) marqueur avec une autre identite : refuse (inchange)"
else
  fail "(d) identite differente : rc=$RC : $OUT"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
