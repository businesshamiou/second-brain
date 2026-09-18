#!/usr/bin/env bash
# T4 (Mission 191-C01, Decision 001438, RELAY 189): AGENTS.md and CLAUDE.md at
# the root say the corpus is English and the participant is spoken to in the
# language of USER.md -- the line « Write prose in French » is gone.
#
#   (a) the exact sentence is in AGENTS.md and in CLAUDE.md;
#   (b) no line of either file asks for French prose;
#   (c) the formula test (Mission 186) and the corpus-language test (Mission
#       187) stay green with the new line;
#   (d) negative control: a copy of AGENTS.md carrying the former French line
#       fails (a)+(b).
#
# usage: bash tests/test-agents-language-line.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SENTENCE="Files in this repository are written in English. Speak to the participant in the language of USER.md."

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m191-lang-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# language_line_ok <file>: 0 if the sentence is there and no French-prose line.
language_line_ok() {
  tr -d '\r' < "$1" | grep -qF -- "$SENTENCE" || return 1
  ! tr -d '\r' < "$1" | grep -qiE 'prose in French|Rédiger en français|Write .*in French'
}

echo "=== T4 : ligne de langue d'AGENTS.md et CLAUDE.md ==="
for f in AGENTS.md CLAUDE.md; do
  if language_line_ok "$REPO_ROOT/$f"; then
    pass "(a)(b) $f : phrase presente, aucune consigne de prose francaise"
  else
    fail "(a)(b) $f : phrase absente ou consigne francaise restante"
  fi
done

for t in test-no-push-formula.sh test-corpus-language-english.sh; do
  if bash "$REPO_ROOT/tests/$t" >"$TMP/$t.log" 2>&1; then
    pass "(c) $t vert"
  else
    fail "(c) $t rouge -- $(tail -n 3 "$TMP/$t.log" | tr '\n' ' ')"
  fi
done

sed "s|$SENTENCE|Write prose in French.|" "$REPO_ROOT/AGENTS.md" > "$TMP/AGENTS.md"
if language_line_ok "$TMP/AGENTS.md"; then
  fail "(d) temoin : une copie portant la ligne francaise passe quand meme"
else
  pass "(d) temoin : une copie portant la ligne francaise echoue"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
