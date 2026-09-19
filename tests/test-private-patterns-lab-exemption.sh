#!/usr/bin/env bash
# T2 (Mission 192, Decision 210904 B): the private-pattern check exempts
# projects/ in a laboratory only -- a repository that declares a `release`
# remote, on a branch that does not follow it.
#
#   (a) simulated Vault WITH `release`, on main: a project sheet carrying a
#       private path under projects/ -> PASS;
#   (b) the same Vault WITHOUT `release` (every installation) -> FAIL naming
#       the file: the check is unchanged there;
#   (c) the branch `publish` (follows release/main) carrying the same sheet
#       -> FAIL: the exemption is not inherited by what gets published;
#   (d) negative control: a private pattern OUTSIDE projects/ in the
#       laboratory -> FAIL (the exemption does not leak).
# The private pattern is built at run time and written only in throwaway
# repositories, never in a tracked file of this repository.
#
# usage: bash tests/test-private-patterns-lab-exemption.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m192-exempt-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
PRIVATE="C:\\Users\\ha""mio\\Workspaces\\projet"

echo "=== T2 : exemption des fiches de projet au laboratoire seulement ==="
V="$TMP/vault"
mkdir -p "$V/tools" "$V/projects"
cp "$REPO_ROOT/tools/check-private-patterns.sh" "$V/tools/"
printf -- '---\ntype: project\n---\n\nabsolute_path: "%s"\n' "$PRIVATE" > "$V/projects/PROJECT-2026-01-01-X.md"
printf 'clean\n' > "$V/README.md"
(
  cd "$V" && git init -q -b main 2>/dev/null || git init -q
  git config user.email t@example.invalid && git config user.name t
  git add -A && git commit -q -m init
) >/dev/null 2>&1
CHECK="$V/tools/check-private-patterns.sh"

git init -q --bare "$TMP/release.git"
git -C "$V" remote add release "$TMP/release.git"
OUT_A="$(bash "$CHECK" --tree-only 2>&1)"; RC_A=$?
[ "$RC_A" = "0" ] && pass "(a) laboratoire (release declare, main) : fiche a chemin prive -> PASS" || fail "(a) laboratoire : sortie $RC_A -- $OUT_A"

git -C "$V" remote remove release
OUT_B="$(bash "$CHECK" --tree-only 2>&1)"; RC_B=$?
case "$RC_B:$OUT_B" in
  1:*PROJECT-2026-01-01-X.md*) pass "(b) sans release (installation) : FAIL nommant la fiche" ;;
  *) fail "(b) sans release : sortie $RC_B -- $OUT_B" ;;
esac

git -C "$V" remote add release "$TMP/release.git"
git -C "$V" push -q release main:main 2>/dev/null
git -C "$V" fetch -q release 2>/dev/null
git -C "$V" checkout -q -b publish --track release/main 2>/dev/null
OUT_C="$(bash "$CHECK" --tree-only 2>&1)"; RC_C=$?
case "$RC_C:$OUT_C" in
  1:*PROJECT-2026-01-01-X.md*) pass "(c) publish (suit release/main) : FAIL, exemption non heritee" ;;
  *) fail "(c) publish : sortie $RC_C -- $OUT_C" ;;
esac

git -C "$V" checkout -q main 2>/dev/null
printf 'note: %s\n' "$PRIVATE" > "$V/README.md"
git -C "$V" commit -q -am "private pattern outside projects" >/dev/null 2>&1
OUT_D="$(bash "$CHECK" --tree-only 2>&1)"; RC_D=$?
case "$RC_D:$OUT_D" in
  1:*README.md*) pass "(d) temoin : motif prive hors projects/ au laboratoire -> FAIL" ;;
  *) fail "(d) temoin : sortie $RC_D -- $OUT_D" ;;
esac

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
