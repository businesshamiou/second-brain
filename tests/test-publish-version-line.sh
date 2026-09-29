#!/usr/bin/env bash
# Mission 222, phase 1 (A-221-1): the published install line installs the tag
# it names. Measured defect: the published tag v0.1.14 carried the line
# ".../v0.1.9/bootstrap.sh" and REF="v0.1.9" / $Ref = 'v0.1.9' in the
# bootstraps -- nothing raised them when a tag was posed, so every tag since
# v0.1.10 installed v0.1.9 (the M187 defect, back).
#
# Now `tools/set-release-version.sh <tag> [<root>]` raises the four places to
# <tag>, and `tools/publish-from-laboratory.sh --version <tag>` runs it on the
# publication tree, so the commit that receives the tag names that tag. The
# laboratory's own main is never rewritten. `--dry-run` goes as far as the
# private-pattern check, then stops: nothing committed, nothing pushed.
#
# Played on a SIMULATED laboratory (two local bare repositories, as in T1/T5,
# tests/test-publish-private-check-before-push.sh). Nothing real is pushed.
#
#   (a) --version v9.9.9 -> PUBLISHED; on release/main the README and INSTALL
#       lines, REF= and $Ref all name v9.9.9;
#   (b) the laboratory's main is unchanged (its lines still name its own tag);
#   (c) an invalid tag -> REFUSED, release unchanged;
#   (d) a tag already on release -> REFUSED, release unchanged;
#   (e) --dry-run --version v9.9.8 -> DRY-RUN, release unchanged, the four
#       places announced at v9.9.8, the publication worktree left clean;
#   (f) set-release-version.sh on a tree whose line names one version and
#       whose bootstraps name another -> all four at the new tag, line
#       endings kept, and the check of test-published-line-ref.sh agrees;
#   (g) witness: set-release-version.sh refuses a tag that is not vX.Y.Z and
#       changes nothing.
# The tool under test is the working-tree one, or PUBLISH_TOOL_SRC=<file>.
#
# usage: bash tests/test-publish-version-line.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TOOL_SRC="${PUBLISH_TOOL_SRC:-$REPO_ROOT/tools/publish-from-laboratory.sh}"
SET_SRC="$REPO_ROOT/tools/set-release-version.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m222-version-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

# The four places, read the way tests/test-published-line-ref.sh reads them.
line_tags() {
  cat "$1/README.md" "$1/INSTALL.md" \
    | tr -d '\r' | sed -n -E 's#.*raw\.githubusercontent\.com/[^/]*/[^/]*/([^/]*)/bootstrap\.(sh|ps1).*#\1#p' | sort -u | paste -sd' ' -
}
sh_ref() { tr -d '\r' < "$1/bootstrap.sh" | sed -n 's/^REF="\([^"]*\)"$/\1/p' | head -n 1; }
ps1_ref() { tr -d '\r' < "$1/bootstrap.ps1" | sed -n "s/^[[:space:]]*\[string\] \$Ref = '\([^']*\)',*\$/\1/p" | head -n 1; }
four_at() { [ "$(line_tags "$1")" = "$2" ] && [ "$(sh_ref "$1")" = "$2" ] && [ "$(ps1_ref "$1")" = "$2" ]; }
four_of() { echo "lines=[$(line_tags "$1")] REF=[$(sh_ref "$1")] Ref=[$(ps1_ref "$1")]"; }

echo "=== (f)/(g) set-release-version.sh on a tree that disagrees with itself ==="
T="$TMP/tree"
mkdir -p "$T"
# Mission 230: a Git repository, as the real caller always is -- the tool runs
# on the publication worktree, never on a bare folder. Since Mission 226,
# set-release-version.sh carries the repository-root guard, which walks up from
# its target and refuses when it meets a workspace root first. A temporary
# folder is directly under the system's temporary directory, and that directory
# becomes a "workspace root" in the guard's sense as soon as it holds two Git
# repositories without being one. Measured on 2026-09-25: this case red on the
# starting commit a512848 as well, so the defect predates this Mission. The
# cause named then (the reference clones `sb-reference-<sha>.git`) was wrong:
# they are bare and the guard does not count them; six working repositories
# left in %TEMP% by other work did it (measured 2026-09-26, Mission 231). Since
# Mission 231 the guard never takes the system temporary folder for a
# workspace root; the fixture stays a repository, as its caller is.
git init -q "$T" 2>/dev/null
for f in README.md INSTALL.md bootstrap.sh bootstrap.ps1; do cp "$REPO_ROOT/$f" "$T/$f"; done
# The line names v0.1.9 (as the published v0.1.14 did); the bootstraps keep theirs.
sed -i 's#second-brain/v[0-9][0-9.]*/bootstrap#second-brain/v0.1.9/bootstrap#' "$T/README.md" "$T/INSTALL.md"
CR_BEFORE="$(grep -c $'\r' "$T/README.md")"
if [ ! -f "$SET_SRC" ]; then
  fail "(f) tools/set-release-version.sh introuvable"
else
  OUT_G="$(bash "$SET_SRC" 9.9 "$T" 2>&1)"; RC_G=$?
  check "(g) temoin : une etiquette hors vX.Y.Z est refusee, rien ne change ($(printf '%s' "$OUT_G" | tail -n 1))" \
    sh -c "[ '$RC_G' != '0' ] && [ \"\$(printf '%s' \"\$1\" | tail -n 1)\" != 'VERSION-SET 9.9' ]" _ "$OUT_G"
  check "(g) l'arbre reste en desaccord apres le refus : $(four_of "$T")" sh -c "[ \"\$1\" = 'v0.1.9' ]" _ "$(line_tags "$T")"
  OUT_F="$(bash "$SET_SRC" v7.7.7 "$T" 2>&1)"; RC_F=$?
  check "(f) set-release-version.sh v7.7.7 rend 0 et VERSION-SET ($(printf '%s' "$OUT_F" | tail -n 1))" \
    sh -c "[ '$RC_F' = '0' ] && [ \"\$(printf '%s' \"\$1\" | tail -n 1)\" = 'VERSION-SET v7.7.7' ]" _ "$OUT_F"
  check "(f) les quatre places a v7.7.7 : $(four_of "$T")" four_at "$T" v7.7.7
  check "(f) fins de ligne gardees (README : $CR_BEFORE CR avant, $(grep -c $'\r' "$T/README.md") apres)" \
    [ "$(grep -c $'\r' "$T/README.md")" = "$CR_BEFORE" ]
  check "(f) seules les lignes visees changent (README : 2 lignes de diff)" \
    sh -c "[ \"\$(diff <(tr -d '\r' < '$REPO_ROOT/README.md') <(tr -d '\r' < '$T/README.md') | grep -c '^>')\" = '2' ]"
fi

echo "=== (a)-(e) publish-from-laboratory.sh --version / --dry-run ==="
REF="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference"; exit 1; }
RS="$TMP/release-src"
git -c core.longpaths=true clone -q -- "$REF" "$RS" 2>/dev/null || { echo "FAIL : clone"; exit 1; }
(
  cd "$RS" || exit 1
  git config core.longpaths true
  git config user.name release && git config user.email release@example.invalid
  git checkout -q --orphan rel
  for f in projects/PROJECT-20*.md; do [ -e "$f" ] && git rm -q -f -- "$f"; done
  grep -v '^| 20[0-9][0-9]-' projects/PROJECT-REGISTRY.md > .r && mv .r projects/PROJECT-REGISTRY.md
  bash tools/build-indexes.sh "$PWD" >/dev/null 2>&1
  git add -A && git commit -q -m "release root"
) >/dev/null 2>&1 || { echo "FAIL : racine de release non construite"; exit 1; }
git clone -q --bare -- "$REF" "$TMP/origin.git" 2>/dev/null

# world <name>: a laboratory and its own `release`, the tools under test
# committed in the laboratory. Sets LAB, REL, PUB, TOOL, R0.
world() {
  local w="$TMP/$1"
  mkdir -p "$w/ws"
  REL="$w/release.git"
  git init -q --bare "$REL"
  git -C "$RS" push -q "$REL" rel:main 2>/dev/null || { echo "FAIL : release non poussee ($1)"; exit 1; }
  R0="$(git -C "$REL" rev-parse main)"
  LAB="$w/ws/vault"
  git -c core.longpaths=true clone -q -- "$TMP/origin.git" "$LAB" 2>/dev/null
  git -C "$LAB" checkout -q -B main 2>/dev/null
  git -C "$LAB" config core.longpaths true
  git -C "$LAB" config core.hooksPath .githooks
  git -C "$LAB" config user.name lab && git -C "$LAB" config user.email lab@example.invalid
  git -C "$LAB" remote add release "$REL"
  bash "$LAB/tools/vault-identity.sh" ensure "$LAB" >/dev/null
  cp "$TOOL_SRC" "$LAB/tools/publish-from-laboratory.sh"
  if [ -f "$SET_SRC" ]; then
    cp "$SET_SRC" "$LAB/tools/set-release-version.sh"
    # The manifest guardian of the throwaway laboratory must know the tool
    # even when the reference clone predates it.
    grep -q '^tools/set-release-version.sh' "$LAB/distribution-manifest.txt" \
      || printf 'tools/set-release-version.sh\tDISTRIBUABLE\n' >> "$LAB/distribution-manifest.txt"
  fi
  cp "$REPO_ROOT/tools/check-private-patterns.sh" "$LAB/tools/check-private-patterns.sh"
  git -C "$LAB" add -A
  git -C "$LAB" -c core.hooksPath=/dev/null commit -q --allow-empty -m "throwaway laboratory state" || { echo "FAIL : etat du laboratoire ($1)"; exit 1; }
  TOOL="$LAB/tools/publish-from-laboratory.sh"
  PUB="$w/ws/m-publish/second-brain"
}
last() { printf '%s\n' "$1" | tail -n 1; }

world one
LAB_TAG="$(line_tags "$LAB")"
OUT_C="$(bash "$TOOL" --version 9.9 2>&1)"; RC_C=$?
check "(c) etiquette invalide -> REFUSED, release inchangee ($(last "$OUT_C"))" \
  sh -c "[ '$RC_C' = '1' ] && [ \"\$1\" = 'REFUSED' ] && [ \"\$(git -C '$REL' rev-parse main)\" = '$R0' ]" _ "$(last "$OUT_C")"
git -C "$REL" tag v8.8.8 main
OUT_D="$(bash "$TOOL" --version v8.8.8 2>&1)"; RC_D=$?
check "(d) etiquette deja sur release -> REFUSED, release inchangee ($(last "$OUT_D"))" \
  sh -c "[ '$RC_D' = '1' ] && [ \"\$1\" = 'REFUSED' ] && [ \"\$(git -C '$REL' rev-parse main)\" = '$R0' ]" _ "$(last "$OUT_D")"
OUT_E="$(bash "$TOOL" --dry-run --version v9.9.8 2>&1)"; RC_E=$?
check "(e) --dry-run -> DRY-RUN, sortie 0, release inchangee ($(last "$OUT_E"))" \
  sh -c "[ '$RC_E' = '0' ] && [ \"\$1\" = 'DRY-RUN' ] && [ \"\$(git -C '$REL' rev-parse main)\" = '$R0' ]" _ "$(last "$OUT_E")"
check "(e) l'essai annonce les quatre places a v9.9.8" sh -c "printf '%s' \"\$1\" | grep -q 'VERSION-SET v9.9.8'" _ "$OUT_E"
check "(e) le worktree de publication reste propre et publish n'a pas bouge" \
  sh -c "[ -z \"\$(git -C '$PUB' status --porcelain)\" ] && [ \"\$(git -C '$LAB' rev-parse publish)\" = '$R0' ]"
OUT_A="$(bash "$TOOL" --version v9.9.9 2>&1)"; RC_A=$?
R1="$(git -C "$REL" rev-parse main)"
check "(a) --version v9.9.9 -> PUBLISHED, sortie 0 ($(last "$OUT_A"))" \
  sh -c "[ '$RC_A' = '0' ] && [ \"\$1\" = 'PUBLISHED $R1' ] && [ '$R1' != '$R0' ]" _ "$(last "$OUT_A")"
PT="$TMP/published"
mkdir -p "$PT"
for f in README.md INSTALL.md bootstrap.sh bootstrap.ps1; do git -C "$REL" show "main:$f" > "$PT/$f" 2>/dev/null; done
check "(a) sur release/main, les quatre places a v9.9.9 : $(four_of "$PT")" four_at "$PT" v9.9.9
check "(b) le main du laboratoire est inchange (lignes : $(line_tags "$LAB"), avant : $LAB_TAG)" \
  sh -c "[ \"\$1\" = '$LAB_TAG' ] && [ -z \"\$(git -C '$LAB' status --porcelain)\" ]" _ "$(line_tags "$LAB")"

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
