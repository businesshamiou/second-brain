#!/usr/bin/env bash
# Mission 231, step 5: verified-push.sh reads the address a repository that is
# not a Vault declares -- the `# push_url:` key of its birth certificate (the
# comment block at the head of .pre-commit-config.yaml) -- so a project's push
# no longer needs --url. Local bare repositories only, never the network.
#
#   (a) a project whose certificate declares push_url, no --url:
#       --dry-run -> WOULD-PUSH, nothing pushed (RED before: refused);
#   (b) the same, pushed: PUSHED, ls-remote reads <to>;
#   (c) --url stays first: a wrong --url is refused even when the certificate
#       declares the right address; a right --url passes over a wrong
#       certificate;
#   (d) a certificate that declares another address -> refused, remote unchanged;
#   (e) a push_url line outside a birth certificate (no certificate header)
#       declares nothing -> refused;
#   (f) nothing declared at all -> refused (unchanged).
#
# usage: bash tests/test-verified-push-declared-url.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$REPO_ROOT/tools/verified-push.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m231-pushurl-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

mkrepo() {
  # mkrepo <name> <certificate-text or ->: a bare remote <name>.git and its
  # clone <name>, one commit pushed; the clone's .pre-commit-config.yaml
  # carries <certificate-text> when given.
  git init -q --bare -b main "$TMP/$1.git" 2>/dev/null || git init -q --bare "$TMP/$1.git"
  git clone -q "$TMP/$1.git" "$TMP/$1" 2>/dev/null
  git -C "$TMP/$1" config user.email t@example.invalid
  git -C "$TMP/$1" config user.name t
  git -C "$TMP/$1" checkout -q -b main 2>/dev/null || true
  [ "$2" = "-" ] || printf '%s\nrepos: []\n' "$2" > "$TMP/$1/.pre-commit-config.yaml"
  echo one > "$TMP/$1/f.txt"
  git -C "$TMP/$1" add -A && git -C "$TMP/$1" commit -q -m one
  git -C "$TMP/$1" push -q origin main 2>/dev/null
}
commit() { echo "$2" >> "$TMP/$1/f.txt"; git -C "$TMP/$1" commit -q -am "$2"; git -C "$TMP/$1" rev-parse HEAD; }
bare_head() { git --git-dir="$TMP/$1.git" rev-parse refs/heads/main 2>/dev/null; }
cert() {
  # cert <push_url>: a birth certificate header carrying push_url.
  printf '# second-brain-birth-certificate: v1\n# vault_id: sb-0000000000000000\n# vault_origin: https://example.invalid/vault.git\n# vault_ref: 0000000\n# vcs: git\n# push_url: %s' "$1"
}
refused() {
  local label="$1" name="$2"; shift 2
  local before after out rc
  before="$(bare_head "$name")"
  out="$(bash "$TOOL" "$@" 2>&1)"; rc=$?
  after="$(bare_head "$name")"
  if [ "$rc" != 0 ] && printf '%s' "$out" | grep -q 'VERIFIED-PUSH-REFUSED' && [ "$before" = "$after" ]; then
    pass "$label : refus, distant inchange"
  else
    fail "$label : rc=$rc -- $(printf '%s' "$out" | tail -n 1 | cut -c1-200)"
  fi
}

echo "=== Mission 231 : adresse declaree dans l'acte de naissance ==="
mkrepo p "$(cert "$TMP/p.git")"
P0="$(git -C "$TMP/p" rev-parse HEAD)"; P1="$(commit p two)"
out="$(bash "$TOOL" "$TMP/p" "$P0..$P1" --dry-run 2>&1)"; rc=$?
if [ "$rc" = 0 ] && printf '%s' "$out" | grep -q '^WOULD-PUSH origin main' && [ "$(bare_head p)" = "$P0" ]; then
  pass "(a) push_url de l'acte, sans --url : WOULD-PUSH, rien pousse"
else
  fail "(a) sans --url : rc=$rc -- $(printf '%s' "$out" | tail -n 1 | cut -c1-200)"
fi
refused "(c) --url faux, acte juste : --url d'abord" p "$TMP/p" "$P0..$P1" --url "$TMP/other.git"
out="$(bash "$TOOL" "$TMP/p" "$P0..$P1" 2>&1)"; rc=$?
if [ "$rc" = 0 ] && printf '%s' "$out" | grep -q '^PUSHED origin main' && [ "$(bare_head p)" = "$P1" ]; then
  pass "(b) pousse sans --url : PUSHED, ls-remote = <to>"
else
  fail "(b) poussee : rc=$rc -- $(printf '%s' "$out" | tail -n 1 | cut -c1-200)"
fi

mkrepo w "$(cert "$TMP/elsewhere.git")"
W0="$(git -C "$TMP/w" rev-parse HEAD)"; W1="$(commit w two)"
refused "(d) acte qui declare une autre adresse" w "$TMP/w" "$W0..$W1"
out="$(bash "$TOOL" "$TMP/w" "$W0..$W1" --url "$TMP/w.git" --dry-run 2>&1)"; rc=$?
[ "$rc" = 0 ] && printf '%s' "$out" | grep -q '^WOULD-PUSH' && pass "(c) --url juste l'emporte sur un acte faux" \
  || fail "(c) --url juste : rc=$rc -- $(printf '%s' "$out" | tail -n 1)"

mkrepo n "# push_url: $TMP/n.git"
N0="$(git -C "$TMP/n" rev-parse HEAD)"; N1="$(commit n two)"
refused "(e) push_url hors d'un acte de naissance" n "$TMP/n" "$N0..$N1"

mkrepo z -
Z0="$(git -C "$TMP/z" rev-parse HEAD)"; Z1="$(commit z two)"
refused "(f) rien de declare, pas de --url" z "$TMP/z" "$Z0..$Z1"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
