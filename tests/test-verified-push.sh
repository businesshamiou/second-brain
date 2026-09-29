#!/usr/bin/env bash
# Mission 226: tools/verified-push.sh pushes exactly the range it is given,
# and refuses everything else before anything is pushed. Local bare
# repositories only, never the network.
#
#   (a) a relative repository path -> refused;
#   (b) a sub-folder of the repository -> refused;
#   (c) a workspace-like folder in no repository -> refused;
#   (d) HEAD is not <to> -> refused;
#   (e) the remote's head is not <from> (someone pushed) -> refused;
#   (f) the remote's URL is not the declared one (--url) -> refused;
#   (g) no declared remote and no --url -> refused;
#   (h) <to> does not descend from <from> -> refused;
#   (i) --force -> refused;
#   each refusal leaves the bare repository's head where it was;
#   (j) --dry-run: WOULD-PUSH, nothing pushed;
#   (k) a valid range: PUSHED, ls-remote reads <to>;
#   (l) a Vault's declared remote is its VAULT-IDENTITY.md vault_origin (no --url);
#   (m) the tool's source carries no --force, no `+` refspec.
#
# VERIFIED_PUSH_TOOL=<file> replaces the tool under test (a naive pusher must
# fail this test -- the red of Mission 226).
#
# usage: bash tests/test-verified-push.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="${VERIFIED_PUSH_TOOL:-$REPO_ROOT/tools/verified-push.sh}"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m226-push-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

mkrepo() {
  # mkrepo <name>: a bare remote <name>.git and its clone <name>, one commit pushed.
  git init -q --bare -b main "$TMP/$1.git" 2>/dev/null || git init -q --bare "$TMP/$1.git"
  git clone -q "$TMP/$1.git" "$TMP/$1" 2>/dev/null
  git -C "$TMP/$1" config user.email t@example.invalid
  git -C "$TMP/$1" config user.name t
  git -C "$TMP/$1" checkout -q -b main 2>/dev/null || true
  mkdir -p "$TMP/$1/sub"; echo one > "$TMP/$1/sub/f.txt"
  git -C "$TMP/$1" add -A && git -C "$TMP/$1" commit -q -m one
  git -C "$TMP/$1" push -q origin main 2>/dev/null
}
commit() { echo "$2" >> "$TMP/$1/sub/f.txt"; git -C "$TMP/$1" commit -q -am "$2"; git -C "$TMP/$1" rev-parse HEAD; }
bare_head() { git --git-dir="$TMP/$1.git" rev-parse refs/heads/main 2>/dev/null; }

# refused <label> <repo-name> <args...>: exit != 0, VERIFIED-PUSH-REFUSED, bare head unchanged.
refused() {
  local label="$1" name="$2"; shift 2
  local before after out rc
  before="$(bare_head "$name")"
  out="$(bash "$TOOL" "$@" 2>&1)"; rc=$?
  after="$(bare_head "$name")"
  if [ "$rc" != 0 ] && printf '%s' "$out" | grep -q 'VERIFIED-PUSH-REFUSED' && [ "$before" = "$after" ]; then
    pass "$label : refus, distant inchange"
  else
    fail "$label : rc=$rc, distant $( [ "$before" = "$after" ] && echo inchange || echo DEPLACE ) -- $(printf '%s' "$out" | tail -n 1 | cut -c1-160)"
  fi
}

echo "=== Mission 226 : poussee verifiee ==="
mkrepo r
R="$TMP/r"; URL="$TMP/r.git"
A="$(git -C "$R" rev-parse HEAD)"
B="$(commit r two)"

refused "(a) chemin relatif" r "r" "$A..$B" origin --url "$URL"
refused "(b) sous-dossier du depot" r "$R/sub" "$A..$B" origin --url "$URL"
mkdir -p "$TMP/ws"; refused "(c) dossier hors de tout depot" r "$TMP/ws" "$A..$B" origin --url "$URL"
C="$(commit r three)"; git -C "$R" reset -q --hard "$B"
refused "(d) HEAD n'est pas <to>" r "$R" "$A..$C" origin --url "$URL"
refused "(f) URL du distant differente de la declaree" r "$R" "$A..$B" origin --url "$TMP/other.git"
refused "(g) aucun distant declare, pas de --url" r "$R" "$A..$B"
refused "(i) --force" r "$R" "$A..$B" origin --url "$URL" --force

# (e) someone else pushed: the remote's head moves to X, not <from>.
git clone -q "$URL" "$TMP/other" 2>/dev/null
git -C "$TMP/other" config user.email o@example.invalid; git -C "$TMP/other" config user.name o
echo other > "$TMP/other/o.txt"; git -C "$TMP/other" add -A; git -C "$TMP/other" commit -q -m other; git -C "$TMP/other" push -q origin HEAD:main 2>/dev/null
refused "(e) tete distante differente de <from>" r "$R" "$A..$B" origin --url "$URL"

# (h) <to> does not descend from <from>: a fresh repo, remote at X, local rewritten.
mkrepo h
H0="$(git -C "$TMP/h" rev-parse HEAD)"
H1="$(commit h two)"; git -C "$TMP/h" push -q origin main 2>/dev/null
git -C "$TMP/h" reset -q --hard "$H0"; H2="$(commit h rewritten)"
refused "(h) <to> ne descend pas de <from>" h "$TMP/h" "$H1..$H2" origin --url "$TMP/h.git"

# (j), (k): a clean repository.
mkrepo k
K0="$(git -C "$TMP/k" rev-parse HEAD)"; K1="$(commit k two)"
out="$(bash "$TOOL" "$TMP/k" "$K0..$K1" origin --url "$TMP/k.git" --dry-run 2>&1)"; rc=$?
if [ "$rc" = 0 ] && printf '%s' "$out" | grep -q '^WOULD-PUSH' && [ "$(bare_head k)" = "$K0" ]; then pass "(j) --dry-run : WOULD-PUSH, rien pousse"; else fail "(j) --dry-run : rc=$rc -- $out"; fi
out="$(bash "$TOOL" "$TMP/k" "$K0..$K1" origin --url "$TMP/k.git" 2>&1)"; rc=$?
if [ "$rc" = 0 ] && printf '%s' "$out" | grep -q '^PUSHED origin main' && [ "$(bare_head k)" = "$K1" ] \
   && [ "$(git -C "$TMP/k" ls-remote origin refs/heads/main | awk '{print $1}')" = "$K1" ]; then
  pass "(k) plage valide : PUSHED, ls-remote = <to>"
else
  fail "(k) plage valide : rc=$rc -- $(printf '%s' "$out" | tail -n 2 | tr '\n' ' ')"
fi

# (l) a Vault: the declared remote is vault_origin.
mkrepo v
V0="$(git -C "$TMP/v" rev-parse HEAD)"
printf -- '---\ntype: vault-identity\nstatus: generated\nvault_id: "sb-0000000000000000"\nvault_origin: "%s"\n---\n' "$TMP/v.git" > "$TMP/v/VAULT-IDENTITY.md"
git -C "$TMP/v" add -A; git -C "$TMP/v" commit -q -m identity; V1="$(git -C "$TMP/v" rev-parse HEAD)"
out="$(bash "$TOOL" "$TMP/v" "$V0..$V1" 2>&1)"; rc=$?
if [ "$rc" = 0 ] && [ "$(bare_head v)" = "$V1" ]; then pass "(l) Vault : distant declare = vault_origin, pousse sans --url"; else fail "(l) Vault : rc=$rc -- $(printf '%s' "$out" | tail -n 1)"; fi

# (m) the source never forces.
if [ -f "$TOOL" ] && ! grep -v '^[[:space:]]*#' "$TOOL" | grep -v 'refuse "--force is never accepted"' | grep -Eq 'push[^|]*(--force|-f[[:space:]]| \+)|:\+|"\+'; then
  pass "(m) la source ne force jamais (ni --force, ni refspec +)"
else
  fail "(m) la source contient un forcage, ou l'outil est absent"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
