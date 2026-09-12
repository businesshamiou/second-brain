#!/usr/bin/env bash
# Regression test for tools/check-private-patterns.sh (Mission 168, ticket
# 10). Written after a real bug found in code review: the script's own
# source file names all four P4 patterns in clear (pattern list, function
# calls, PASS message), so scanning the tree including itself made it
# refuse on its own lines every time -- never on anyone else's leak. Fixed
# by excluding the script's own path from its `git grep` calls (pathspec
# exclusion, not a content-based exception, so a real leak elsewhere is
# never masked).
#
# Also covers the reason `--tree-only` exists: this repo's own history
# already carries "aios-production" (a real pre-ticket-10 leak in commits
# 9d67391/39bfda0, ticket 01 before ticket 02's cleanup) -- immutable, not
# fixable by rewriting the checker. `--tree-only` must ignore history so CI
# can stay green on clean new content; full mode (no flag) must still catch
# it, so the signal is not silently lost.
#
# Cases:
#   1. self-exclusion -- a sandbox containing only a copy of the checker
#      itself (which necessarily contains all four pattern strings in its
#      own source) passes --tree-only. Reproduces the bug directly.
#   2. tree-leak -- a real forbidden pattern in another tracked file is
#      still caught by --tree-only (self-exclusion must not become a
#      blanket exemption).
#   3. hamio-exception -- "businesshamiou" alone, no bare "hamio" elsewhere,
#      still passes (the substring exception is preserved).
#   4. history-vs-tree-only -- a forbidden pattern committed once then
#      removed: --tree-only passes (current tree clean), full mode (no
#      flag) still refuses (history is immutable).
#
# usage: tests/test-check-private-patterns.sh
# sortie : "PASS: 4/4 cas conformes" (exit 0) ou "FAIL: <n> cas non
# conformes" (exit 1), meme convention que test-check-links-cross-repo.sh.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_SCRIPT="$SCRIPT_DIR/../tools/check-private-patterns.sh"

if [ ! -f "$REAL_SCRIPT" ]; then
  echo "FAIL: script cible introuvable : $REAL_SCRIPT" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0

# make_repo <chemin-workspace> : sandbox Git minimal, script cible copie
# dedans sous tools/ (meme patron que test-check-links-cross-repo.sh).
make_repo() {
  local ws="$1"
  local repo="$ws/canary"
  mkdir -p "$repo/tools"
  cp "$REAL_SCRIPT" "$repo/tools/check-private-patterns.sh"
  (
    cd "$repo" && git init -q -b main \
      && git config user.email t@t \
      && git config user.name t \
      && git config commit.gpgsign false
  )
  printf '%s\n' "$repo"
}

commit_all() {
  local repo="$1"
  local msg="$2"
  local log
  log="$(cd "$repo" && git add -A 2>&1 && git commit -q -m "$msg" 2>&1)" || {
    echo "FAIL: commit sandbox impossible dans $repo :" >&2
    printf '%s\n' "$log" >&2
    exit 1
  }
}

# --- 1. self-exclusion: only the checker itself in the tree -----------------
REPO_1="$(make_repo "$TMP/case-1")"
commit_all "$REPO_1" "checker only"
OUT_1="$(cd "$REPO_1" && bash tools/check-private-patterns.sh --tree-only 2>&1)"; RC_1=$?
if [ "$RC_1" -eq 0 ]; then
  echo "ok [1-self-exclusion]: --tree-only passe sur un arbre ne contenant que le script"
else
  echo "FAIL [1-self-exclusion]: exit=$RC_1, sortie:" >&2
  printf '%s\n' "$OUT_1" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 2. a real leak elsewhere is still caught --------------------------------
REPO_2="$(make_repo "$TMP/case-2")"
mkdir -p "$REPO_2/notes"
printf 'reference au depot glintbloom ici\n' > "$REPO_2/notes/leak.md"
commit_all "$REPO_2" "with leak"
OUT_2="$(cd "$REPO_2" && bash tools/check-private-patterns.sh --tree-only 2>&1)"; RC_2=$?
if [ "$RC_2" -ne 0 ] && printf '%s' "$OUT_2" | grep -q "motif prive 'glintbloom' dans l'arbre"; then
  echo "ok [2-tree-leak]: --tree-only refuse toujours une vraie fuite ailleurs dans l'arbre"
else
  echo "FAIL [2-tree-leak]: exit=$RC_2, sortie:" >&2
  printf '%s\n' "$OUT_2" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 3. "businesshamiou" alone is not a match --------------------------------
REPO_3="$(make_repo "$TMP/case-3")"
mkdir -p "$REPO_3/notes"
printf 'depot public de businesshamiou sur GitHub\n' > "$REPO_3/notes/host.md"
commit_all "$REPO_3" "host mention only"
OUT_3="$(cd "$REPO_3" && bash tools/check-private-patterns.sh --tree-only 2>&1)"; RC_3=$?
if [ "$RC_3" -eq 0 ]; then
  echo "ok [3-hamio-exception]: 'businesshamiou' seul reste hors P4"
else
  echo "FAIL [3-hamio-exception]: exit=$RC_3, sortie:" >&2
  printf '%s\n' "$OUT_3" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 4. a leak committed then removed: --tree-only passes, full mode refuses
REPO_4="$(make_repo "$TMP/case-4")"
mkdir -p "$REPO_4/notes"
printf 'chemin prive : WIN-AE600DJQCF6\n' > "$REPO_4/notes/old.md"
commit_all "$REPO_4" "introduce leak"
rm "$REPO_4/notes/old.md"
commit_all "$REPO_4" "remove leak"
OUT_4A="$(cd "$REPO_4" && bash tools/check-private-patterns.sh --tree-only 2>&1)"; RC_4A=$?
OUT_4B="$(cd "$REPO_4" && bash tools/check-private-patterns.sh 2>&1)"; RC_4B=$?
if [ "$RC_4A" -eq 0 ] && [ "$RC_4B" -ne 0 ] && printf '%s' "$OUT_4B" | grep -q "motif prive 'WIN-AE600DJQCF6' dans l'historique"; then
  echo "ok [4-history-vs-tree-only]: --tree-only propre, mode complet refuse toujours sur l'historique"
else
  echo "FAIL [4-history-vs-tree-only]: tree-only exit=$RC_4A, complet exit=$RC_4B" >&2
  printf '%s\n%s\n' "$OUT_4A" "$OUT_4B" >&2
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 4/4 cas conformes"
  exit 0
else
  echo "FAIL: $FAILURES cas non conformes"
  exit 1
fi
