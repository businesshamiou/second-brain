#!/usr/bin/env bash
# Mission 229, step 2: tools/check-links.sh swept only the links written
# `](./x.md)` or `](../x.md)`, while the linking standard (§3) asks for a path
# relative to the file, which `](README.md)` is. A "## Liens" section whose
# only link was `README.md` drew "aucun lien interne", and a bare link to a
# missing file passed unseen. A bare link now resolves as `./<target>`.
#
#   (a) a "## Liens" holding only `[..](README.md)`, target present -> accepted,
#       counted as an internal link (no "aucun lien interne" warning);
#   (b) a bare link to a missing file -> refused, "cible introuvable";
#   (c) a bare sub-path, `docs/guide.md`, present -> counted;
#   (d) not counted and never refused: a URL, an anchor alone, a name without
#       extension, an absolute path, `<...>`, `~/...`;
#   (e) a bare link inside inline code or a fenced block is not swept;
#   (f) witness: `./README.md` counted and `./MISSING.md` refused, as before;
#   (g) a percent-encoded target, `docs/My%20File.md`, resolves decoded when the
#       raw path is missing; a missing one is still refused.
#
# The guardian is run where it lives (it finds its libraries from its own
# folder) in a throwaway Git repository; no file of the real corpus is touched.
#
# usage: bash tests/test-check-links-bare-relative.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$REPO_ROOT/tools/check-links.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m229-links-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

R="$TMP/repo"
mkdir -p "$R/docs"
git init -q "$R"
printf '# Readme\n\n## Liens\n\n- `see also` — [guide](./docs/guide.md)\n' > "$R/README.md"
printf '# Guide\n\n## Liens\n\n- `see also` — [readme](../README.md)\n' > "$R/docs/guide.md"
printf '# Spaced\n\n## Liens\n\n- `see also` — [readme](../README.md)\n' > "$R/docs/My File.md"
( cd "$R" && git add -- README.md docs/guide.md "docs/My File.md" \
  && git -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m base )

# judge BODY: note.md = BODY, staged alone; prints the exit code, output in $TMP/out.
judge() {
  printf '%s\n' "$1" > "$R/note.md"
  ( cd "$R" && git add -- note.md && bash "$GUARD" ) >"$TMP/out" 2>&1
  echo $?
  ( cd "$R" && git rm -q --cached -- note.md )
}
no_warning() { ! grep -q 'aucun lien interne' "$TMP/out"; }
warning()    { grep -q 'aucun lien interne' "$TMP/out"; }
not_found()  { grep -q "cible introuvable: note.md:[0-9]* -> $1\$" "$TMP/out"; }

LIENS=$'# Note\n\n## Liens\n\n'

RC="$(judge "${LIENS}- \`see also\` — [readme](README.md)")"
[ "$RC" = 0 ] && no_warning \
  && pass "(a) Liens avec seulement README.md : accepte, compte comme lien interne" \
  || fail "(a) Liens avec seulement README.md (rc=$RC) : $(tr '\n' '|' < "$TMP/out")"

RC="$(judge "${LIENS}- \`see also\` — [absent](MISSING.md)")"
[ "$RC" != 0 ] && not_found 'MISSING.md' \
  && pass "(b) lien nu vers un fichier absent : refuse, cible introuvable" \
  || fail "(b) lien nu mort non refuse (rc=$RC) : $(tr '\n' '|' < "$TMP/out")"

RC="$(judge "${LIENS}- \`see also\` — [guide](docs/guide.md)")"
[ "$RC" = 0 ] && no_warning \
  && pass "(c) sous-chemin nu docs/guide.md : compte" \
  || fail "(c) sous-chemin nu (rc=$RC) : $(tr '\n' '|' < "$TMP/out")"

for t in 'https://example.com/MISSING.md' '#liens' 'MISSING' '/MISSING.md' '<MISSING.md>' '~/MISSING.md' 'C:/MISSING.md'; do
  RC="$(judge "${LIENS}- \`see also\` — [x]($t)")"
  [ "$RC" = 0 ] && warning \
    && pass "(d) non compte, non refuse : $t" \
    || fail "(d) $t (rc=$RC) : $(tr '\n' '|' < "$TMP/out")"
done

RC="$(judge "${LIENS}- \`see also\` — [readme](./README.md)"$'\n\nInline: `[x](MISSING.md)`\n\n```\n[x](MISSING.md)\n```')"
[ "$RC" = 0 ] \
  && pass "(e) lien nu en code en ligne ou en bloc : non balaye" \
  || fail "(e) code balaye (rc=$RC) : $(tr '\n' '|' < "$TMP/out")"

RC="$(judge "${LIENS}- \`see also\` — [readme](./README.md)")"
[ "$RC" = 0 ] && no_warning \
  && pass "(f) temoin : ./README.md compte" \
  || fail "(f) temoin ./README.md (rc=$RC)"
RC="$(judge "${LIENS}- \`see also\` — [absent](./MISSING.md)")"
[ "$RC" != 0 ] && not_found './MISSING.md' \
  && pass "(f) temoin : ./MISSING.md refuse" \
  || fail "(f) temoin ./MISSING.md non refuse (rc=$RC)"

RC="$(judge "${LIENS}- \`see also\` — [spaced](docs/My%20File.md)")"
[ "$RC" = 0 ] && no_warning \
  && pass "(g) cible encodee docs/My%20File.md : resolue decodee" \
  || fail "(g) cible encodee (rc=$RC) : $(tr '\n' '|' < "$TMP/out")"
RC="$(judge "${LIENS}- \`see also\` — [spaced](docs/No%20File.md)")"
[ "$RC" != 0 ] && not_found 'docs/No%20File.md' \
  && pass "(g) cible encodee absente : refusee" \
  || fail "(g) cible encodee absente non refusee (rc=$RC)"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
