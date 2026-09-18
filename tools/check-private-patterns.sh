#!/usr/bin/env bash
# Checks that no private pattern (category P4, build history, ticket 01 --
# build history) remains in the working tree and, in full mode,
# in the history of this repository. Ticket 10: missing secondary "offline
# guardian" -- no existing tool (tools/check-secrets.sh covers only
# service credentials, never machine paths or the names of private
# repositories) replayed the manual check made once in ticket 01;
# this script makes it repeatable and attaches it to CI (build history, Validation 2:
# "Motifs P4 : -> 0 dans l'arbre et dans l'historique" ["P4 patterns: -> 0 in the tree and in the history"]).
#
# Modes:
#   (default)      scans the tracked tree AND the full history (--all).
#   --tree-only    scans only the tracked tree, never the history.
#
# Reason for the --tree-only mode (found in code review, ticket 10): a
# Git history is immutable, so a private pattern once committed in any
# file keeps making the full mode refuse forever,
# even if the current tree is clean -- only a history rewrite (or
# a republication from scratch) erases it, a structural gesture reserved to
# the Owner, never taken by an Executor on its own initiative. CI (which
# must remain able to succeed on clean new content) therefore invokes
# --tree-only as the blocking guardian; the full mode remains available here
# to measure the history separately.
#
# Exclusion (Mission 178, same cause as the tree mode's self-exclusion,
# found while rereading this script after history reduction): the history
# search did NOT apply EXCLUDE_PATHSPECS, unlike the
# tree search -- this script and its test name the four patterns in
# clear, so any commit that adds them (including the very first commit
# of an otherwise clean history) made the full mode refuse on
# its own lines, never on someone else's leak. Fixed by
# passing the same path exclusions to the two history searches
# below; a real leak elsewhere in the history is still detected
# (cases 2, 4 and 5 of tests/test-check-private-patterns.sh).
#
# Portable shell: no dependency on Python, no dependency on `grep -P`
# (PCRE) -- the case of "hamio" as a substring of "businesshamiou" (public GitHub account
# that hosts this repository, outside P4) is excluded by a second grep rather than a
# lookaround, to stay compatible with a minimal POSIX grep.
#
# usage: tools/check-private-patterns.sh [--tree-only]
# exit 0 if 0 occurrences outside the exception; exit 1 otherwise, cause printed.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TREE_ONLY=0
if [ "${1:-}" = "--tree-only" ]; then
  TREE_ONLY=1
fi

git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}

# This script, and its non-regression test, cite in clear the four
# patterns they check (pattern list, calls, PASS message for the one;
# fixtures and assertions on the refusal messages for the other) -- both
# are therefore excluded from this tree sweep by pathspec, never by a
# content exception (which would mask a real private pattern written elsewhere).
# Found in code review (ticket 10): without excluding the script itself,
# the guardian always refused itself; when its non-regression test was
# added to the repository, the same defect appeared on that second file,
# for the same structural reason -- fixed the same way, not by a
# third ad hoc exception. Any test fixture that needs a literal
# pattern writes it in a throwaway file under a sandbox Git repository
# (`mktemp -d`), never in another tracked file of this repository -- only the
# definition/test pair itself is exempted.
EXCLUDE_PATHS=(
  "tools/check-private-patterns.sh"
  "tests/test-check-private-patterns.sh"
)

# Fixed patterns, same categories as report 167 Table 3 / report of Mission
# 168 S14: machine path (hamio, aios-production, WIN-AE600DJQCF6) and
# private repository (glintbloom). "businesshamiou" (public GitHub identity/host of
# this repository) is never a P4 pattern -- the only exception, handled separately.
PLAIN_PATTERNS=(
  "aios-production"
  "WIN-AE600DJQCF6"
  "glintbloom"
)

FAIL=0

EXCLUDE_PATHSPECS=()
for excluded in "${EXCLUDE_PATHS[@]}"; do
  EXCLUDE_PATHSPECS+=(":(exclude)$excluded")
done

check_plain() {
  local pattern="$1"
  local tree_hits hist_hits
  tree_hits="$(git -C "$REPO_ROOT" grep -Iin --no-color -- "$pattern" -- . "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null || true)"
  if [ -n "$tree_hits" ]; then
    echo "REFUS : motif prive '$pattern' dans l'arbre :" >&2
    printf '%s\n' "$tree_hits" >&2
    FAIL=1
  fi
  if [ "$TREE_ONLY" -eq 1 ]; then
    return
  fi
  hist_hits="$(git -C "$REPO_ROOT" log -p --all -i -S"$pattern" --pretty=format:'commit %H' -- . "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null | grep -i -- "$pattern" || true)"
  if [ -n "$hist_hits" ]; then
    echo "REFUS : motif prive '$pattern' dans l'historique :" >&2
    printf '%s\n' "$hist_hits" | head -20 >&2
    FAIL=1
  fi
}

check_plain "aios-production"
check_plain "WIN-AE600DJQCF6"
check_plain "glintbloom"

# "hamio": the substring "businesshamiou" is excluded by filtering, never
# by PCRE (portability of the CI runner's grep, Windows and Ubuntu).
tree_hamio="$(git -C "$REPO_ROOT" grep -Iin --no-color -- "hamio" -- . "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null | grep -vi -- "businesshamiou" || true)"
if [ -n "$tree_hamio" ]; then
  echo "REFUS : motif prive 'hamio' (hors businesshamiou) dans l'arbre :" >&2
  printf '%s\n' "$tree_hamio" >&2
  FAIL=1
fi
if [ "$TREE_ONLY" -eq 0 ]; then
  hist_hamio="$(git -C "$REPO_ROOT" log -p --all -i -S"hamio" --pretty=format:'commit %H' -- . "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null | grep -i -- "hamio" | grep -vi -- "businesshamiou" || true)"
  if [ -n "$hist_hamio" ]; then
    echo "REFUS : motif prive 'hamio' (hors businesshamiou) dans l'historique :" >&2
    printf '%s\n' "$hist_hamio" | head -20 >&2
    FAIL=1
  fi
fi

if [ "$FAIL" -ne 0 ]; then
  echo "REFUS : motif(s) prive(s) trouve(s)." >&2
  exit 1
fi

if [ "$TREE_ONLY" -eq 1 ]; then
  echo "PASS : 0 motif prive dans l'arbre (mode --tree-only, 4 motifs verifies)."
else
  echo "PASS : 0 motif prive dans l'arbre et l'historique (4 motifs verifies)."
fi
exit 0
