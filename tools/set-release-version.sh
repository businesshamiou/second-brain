#!/usr/bin/env bash
# Raises the four places that name the version a published install line
# installs, to one tag (Mission 222, A-221-1):
#   - README.md and INSTALL.md: every raw.githubusercontent.com/<owner>/<repo>/
#     <ref>/bootstrap.sh|ps1 URL;
#   - bootstrap.sh: REF="<ref>" and the URL of its usage comment;
#   - bootstrap.ps1: [string] $Ref = '<ref>' and the URL of its usage comment.
# Measured defect: nothing raised them when a tag was posed, so the published
# tag v0.1.14 still named v0.1.9 in all four and installed v0.1.9 (the M187
# defect, back). tools/publish-from-laboratory.sh --version <tag> runs this
# script on the publication tree, never on the laboratory's main.
#
# Only the matched text changes: line endings (CRLF or LF) and every other
# byte are kept. Fail-closed: a tag that is not vX.Y.Z, a missing file, or a
# place that does not read <tag> afterwards -- refused, and the files are
# left as they were.
#
# usage: set-release-version.sh <vX.Y.Z> [<root>]
# Last line: VERSION-SET <tag> | REFUSED

set -u
. "$(cd "$(dirname "$0")" && pwd)/lib/tmp.sh"  # declared temporary folder (Mission 234)

refuse() {
  echo "REFUS : $*" >&2
  echo "REFUSED"
  exit 1
}

TAG="${1:-}"
ROOT="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
printf '%s' "$TAG" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' \
  || refuse "etiquette invalide : '$TAG' (attendu vX.Y.Z)"
# Mission 226: the repository-root guard (tools/repo_root_guard.py), before
# anything is written -- never the workspace root, never a folder in no repository.
uv run --no-project "$(cd "$(dirname "$0")" && pwd)/repo_root_guard.py" "$ROOT" || refuse "racine refusee par le garde-fou : $ROOT"
FILES="README.md INSTALL.md bootstrap.sh bootstrap.ps1"
for f in $FILES; do
  [ -f "$ROOT/$f" ] || refuse "fichier introuvable : $ROOT/$f"
done

# Work on copies; the originals are replaced only once all four read <tag>.
WORK="$(mktemp -d "$(sb_tmp_dir tools)/set-version-XXXXXX")" || refuse "dossier temporaire non cree"
trap 'rm -rf "$WORK"' EXIT
URL_SED='s#(raw\.githubusercontent\.com/[^/[:space:]]+/[^/[:space:]]+/)[^/[:space:]]+(/bootstrap\.(sh|ps1))#\1'"$TAG"'\2#g'
for f in README.md INSTALL.md; do
  sed -E "$URL_SED" "$ROOT/$f" > "$WORK/$f" || refuse "reecriture de $f"
done
sed -E -e "$URL_SED" -e 's#^REF="[^"]*"(\r?)$#REF="'"$TAG"'"\1#' "$ROOT/bootstrap.sh" > "$WORK/bootstrap.sh" \
  || refuse "reecriture de bootstrap.sh"
sed -E -e "$URL_SED" -e "s#^([[:space:]]*\\[string\\] \\\$Ref = )'[^']*'(,?\r?)\$#\\1'$TAG'\\2#" "$ROOT/bootstrap.ps1" > "$WORK/bootstrap.ps1" \
  || refuse "reecriture de bootstrap.ps1"

# Read back the way tests/test-published-line-ref.sh reads.
LINES="$(cat "$WORK/README.md" "$WORK/INSTALL.md" | tr -d '\r' \
  | sed -n -E 's#.*raw\.githubusercontent\.com/[^/]*/[^/]*/([^/]*)/bootstrap\.(sh|ps1).*#\1#p' | sort -u | paste -sd' ' -)"
SH_REF="$(tr -d '\r' < "$WORK/bootstrap.sh" | sed -n 's/^REF="\([^"]*\)"$/\1/p' | head -n 1)"
PS1_REF="$(tr -d '\r' < "$WORK/bootstrap.ps1" | sed -n "s/^[[:space:]]*\[string\] \$Ref = '\([^']*\)',*\$/\1/p" | head -n 1)"
[ "$LINES" = "$TAG" ] && [ "$SH_REF" = "$TAG" ] && [ "$PS1_REF" = "$TAG" ] \
  || refuse "relecture en desaccord : lignes [$LINES], REF [$SH_REF], \$Ref [$PS1_REF] -- rien n'est ecrit"

for f in $FILES; do
  cat "$WORK/$f" > "$ROOT/$f" || refuse "ecriture de $f"
done
echo "set-release-version: README.md, INSTALL.md, bootstrap.sh, bootstrap.ps1 -> $TAG"
echo "VERSION-SET $TAG"
exit 0
