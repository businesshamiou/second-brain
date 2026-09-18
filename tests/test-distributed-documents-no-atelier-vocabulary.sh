#!/usr/bin/env bash
# Scans the CONTENT of the tracked documents that are distributed and meant
# for a participant -- words (same list as
# tests/test-nominal-flow-no-atelier-vocabulary.sh, Mission 174) and paths
# prefixed `vault/` cited as if they resolved on a participant's machine
# (Mission 177, step 4b).
#
# Complement to Mission 174: that one scans only the CONSOLE OUTPUT
# of a nominal flow, never the CONTENT of the documents themselves -- that is
# the way the citation `vault/skills/session-start/reading-list.md`
# of the role charter (RULES-2026-08-23-224706-role-charter-and-session-
# determination.md) slipped through, invisible on an install's console but read by
# any participant who opens that file.
#
# SCOPE: an inclusion list, not an exclusion list -- the folders and
# files a participant actually reads as documentation or as a
# guide (rules/, knowledge/, templates/, skills/ except external/, assistant/,
# i18n/, AGENTS.md, CLAUDE.md, README.md, INSTALL.md). Prior measurement
# (Mission 177, step 1): these folders carry no occurrence
# today. The source code (tools/, tests/) legitimately cites these same
# words in its fixtures, its history comments or its own
# definition (same pattern as the definition/test pair of
# tools/check-private-patterns.sh) -- including it would have required a
# file-by-file exclusion list as long as it is arbitrary, for a risk
# much smaller than a document the participant opens directly.
#
# Rerun with one command, from the repository root:
#   bash tests/test-distributed-documents-no-atelier-vocabulary.sh
#
# Exit 0: no occurrence in the included documents, and the negative case
# proves that the scan still detects a present pattern. Exit 1 otherwise,
# file and line printed.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1
FAILURES=0

assert_true() {
  if [ "$1" = "0" ]; then
    echo "  PASS - $2"
  else
    echo "  FAIL - $2"
    FAILURES=$((FAILURES + 1))
  fi
}

# Patterns: the four workshop words already catalogued by Mission 174,
# plus any path cited between backticks that starts with `vault/` --
# the only alias that tools/check-asserted-paths.sh still resolves to this
# repository itself (history: this repository was called "vault" before its
# distribution as a product), hence the only path of this kind that the
# asserted-paths guardian can NOT tell apart from a real subfolder
# on a participant's machine -- this repository never had a real `vault/`
# subfolder.
WORD_PATTERNS=(
  'workshop-build'
  'workshop-production'
  '\bworkshops\b'
  '\bLegacy\b'
)
PATH_PATTERN='`vault/'

# Scope: living folders read by a participant, plus the root files
# addressed to them. `skills/external/` is excluded inside
# `skills/`: third-party material adopted verbatim, body guaranteed
# by SHA-256 fingerprint (DECISION-171209) -- never rewritten, even for a
# vocabulary reason (measured: its occurrences of "Legacy" are a script
# name of the plugin, unrelated to the workshop).
INCLUDE_PATHSPECS=(
  'rules'
  'knowledge'
  'templates'
  'skills'
  ':(exclude)skills/external'
  'assistant'
  'i18n'
  'AGENTS.md'
  'CLAUDE.md'
  'README.md'
  'INSTALL.md'
)

echo ""
echo "=== 1. Balayage des documents distribues destines au participant ==="
TREE_FAIL=0
for pattern in "${WORD_PATTERNS[@]}"; do
  HITS="$(git -C "$REPO_ROOT" grep -Iin -E -- "$pattern" -- "${INCLUDE_PATHSPECS[@]}" 2>/dev/null || true)"
  if [ -n "$HITS" ]; then
    TREE_FAIL=1
    echo "  FAIL - mot d'atelier '$pattern' trouve :"
    printf '%s\n' "$HITS" | sed 's/^/      /'
  fi
done
PATH_HITS="$(git -C "$REPO_ROOT" grep -Iin -F -- "$PATH_PATTERN" -- "${INCLUDE_PATHSPECS[@]}" 2>/dev/null || true)"
if [ -n "$PATH_HITS" ]; then
  TREE_FAIL=1
  echo "  FAIL - chemin d'atelier '${PATH_PATTERN}...' trouve :"
  printf '%s\n' "$PATH_HITS" | sed 's/^/      /'
fi
assert_true "$TREE_FAIL" "0 mot ni chemin d'atelier dans les documents distribues destines au participant"

echo ""
echo "=== 2. Cas negatif : le balayage detecte toujours un motif present ==="
# Throwaway sandbox repository, never a tracked file of THIS repository -- same
# discipline as tools/check-private-patterns.sh and Mission 176.
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sb-atelier-doc-sweep-XXXXXX")"
trap 'rm -rf -- "$SANDBOX"' EXIT
(
  cd "$SANDBOX" || exit 1
  git init -q .
  git config user.email test@example.invalid
  git config user.name Test
  mkdir -p rules
  printf 'Un document qui cite %s par erreur, et un chemin `vault/skills/x.md`.\n' 'workshop-build' > rules/example.md
  git add -A
  git commit -q -m "fixture" >/dev/null
)
SANDBOX_WORD_HITS="$(git -C "$SANDBOX" grep -Iin -E -- 'workshop-build' -- rules 2>/dev/null || true)"
SANDBOX_PATH_HITS="$(git -C "$SANDBOX" grep -Iin -F -- '`vault/' -- rules 2>/dev/null || true)"
NEGATIVE_OK=1
[ -n "$SANDBOX_WORD_HITS" ] && [ -n "$SANDBOX_PATH_HITS" ] && NEGATIVE_OK=0
assert_true "$NEGATIVE_OK" "le meme balayage detecte un mot ET un chemin d'atelier fabriques dans un depot jetable, jamais ecrits dans ce depot"

echo ""
if [ "$FAILURES" = "0" ]; then
  echo "=== RESULT: PASS (all checks green) ==="
  exit 0
else
  echo "=== RESULT: FAIL ($FAILURES check(s) failed) ==="
  exit 1
fi
