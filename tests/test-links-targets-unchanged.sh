#!/usr/bin/env bash
# Mission 187, T2: translating the corpus changed the text of links, never
# where they point.
#
# Oracle (PASS expected): the set of {file, link target} pairs of the
#   distributed Markdown corpus (outside fenced code blocks, inline code
#   removed; same exclusions as test-corpus-language-english.sh) equals the
#   set frozen before the translation in
#   tests/fixtures/corpus-link-targets-653910c.tsv: 0 target lost, 0 added.
#   Files added to the corpus after that commit are listed, not compared.
# Negative control: a copy of the fixture with one pair removed makes the
#   comparison fail and name the pair.
#
# usage: bash tests/test-links-targets-unchanged.sh [--write-fixture]
#   --write-fixture  (re)write the fixture from the current tree -- used once,
#                    before the translation; never to make this test pass

set -u
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE="$REPO_ROOT/tests/fixtures/corpus-link-targets-653910c.tsv"
# Changes made on purpose after the fixture, each declared with its Mission
# (Mission 189): the reference is the frozen fixture plus these lines, so an
# undeclared change still fails and the fixture itself is never rewritten.
CHANGES="$REPO_ROOT/tests/fixtures/corpus-link-targets-changes.tsv"

FAILURES=0
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m187-links-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

corpus_md() {
  awk -F'\t' '$2 == "DISTRIBUABLE" { print $1 }' "$REPO_ROOT/distribution-manifest.txt" \
    | grep '\.md$' | grep -v -e '^i18n/' -e '^tests/fixtures/' -e '^skills/external/' -e '^USER\.md$'
}

pairs() {
  # One "file<TAB>target" line per link, sorted, unique.
  corpus_md | while IFS= read -r f; do
    [ -f "$REPO_ROOT/$f" ] || continue
    awk -v F="$f" '
      /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
      !fence {
        s = $0; gsub(/`[^`]*`/, "", s)
        while (match(s, /\]\([^)]*\)/)) { print F "\t" substr(s, RSTART + 2, RLENGTH - 3); s = substr(s, RSTART + RLENGTH) }
      }' "$REPO_ROOT/$f"
  done | sort -u
}

if [ "${1:-}" = "--write-fixture" ]; then
  pairs > "$FIXTURE"
  echo "fixture written: $(wc -l < "$FIXTURE" | tr -d ' ') pairs"
  exit 0
fi

echo "=== T2 : link targets unchanged by the translation ==="
[ -f "$FIXTURE" ] || { echo "FAIL : fixture not found"; exit 1; }
pairs > "$TMP/now"
cut -f1 "$FIXTURE" | sort -u > "$TMP/files-then"
# Files that entered the corpus after the fixture are listed, not compared.
awk -F'\t' 'NR == FNR { then[$1] = 1; next } ($1 in then)' "$TMP/files-then" "$TMP/now" > "$TMP/now-compared"
awk -F'\t' 'NR == FNR { then[$1] = 1; next } !($1 in then) { print $1 }' "$TMP/files-then" "$TMP/now" | sort -u > "$TMP/new-files"

compare() {
  # $1 = reference, $2 = current. Sets LOST and ADDED.
  LOST="$(comm -23 "$1" "$2")"
  ADDED="$(comm -13 "$1" "$2")"
}
reference() {
  # $1 = fixture. Prints the fixture with the declared changes applied.
  { cat "$1"
    [ -f "$CHANGES" ] && awk -F'	' '!/^#/ && $1 == "+" { print $2 "	" $3 }' "$CHANGES"
  } | sort -u > "$TMP/ref.add"
  if [ -f "$CHANGES" ]; then
    awk -F'	' '!/^#/ && $1 == "-" { print $2 "	" $3 }' "$CHANGES" | sort -u > "$TMP/ref.del"
    comm -23 "$TMP/ref.add" "$TMP/ref.del"
  else
    cat "$TMP/ref.add"
  fi
}
reference "$FIXTURE" > "$TMP/reference"
DECLARED="$(grep -vc '^#' "$CHANGES" 2>/dev/null || echo 0)"
compare "$TMP/reference" "$TMP/now-compared"
N="$(wc -l < "$FIXTURE" | tr -d ' ')"
if [ -z "$LOST" ] && [ -z "$ADDED" ]; then
  echo "  PASS - $N {file, target} pairs frozen, $DECLARED declared change(s), 0 lost, 0 added"
else
  [ -n "$LOST" ] && { echo "  FAIL - lost:"; printf '%s\n' "$LOST" | sed 's/^/    /'; }
  [ -n "$ADDED" ] && { echo "  FAIL - added:"; printf '%s\n' "$ADDED" | sed 's/^/    /'; }
  FAILURES=$((FAILURES + 1))
fi
if [ -s "$TMP/new-files" ]; then
  echo "  files added to the corpus since the fixture (not compared):"
  sed 's/^/    /' "$TMP/new-files"
fi

echo "=== negative control ==="
VICTIM="$(sed -n '1p' "$FIXTURE")"
sed '1d' "$FIXTURE" > "$TMP/fixture-cut"
compare "$TMP/fixture-cut" "$TMP/now-compared"
if printf '%s\n' "$ADDED" | grep -qxF "$VICTIM"; then
  echo "  PASS - control: a pair missing from the reference is caught and named ($(printf '%s' "$VICTIM" | tr '\t' ' '))"
else
  echo "  FAIL - control: a pair missing from the reference went unnoticed"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
