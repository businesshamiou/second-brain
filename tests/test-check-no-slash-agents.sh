#!/usr/bin/env bash
# Regression test for tools/check-no-slash-agents.sh (Mission 171-C01, etape
# 9). Written for the same structural reason as
# tests/test-check-private-patterns.sh: the checker's own source names the
# pattern it looks for in clear (comments, the PATTERN variable), so a naive
# self-scan would refuse on its own lines forever. Fixed the same way --
# pathspec exclusion of the checker and this test, never a content-based
# exception.
#
# Cases:
#   1. self-exclusion -- a sandbox containing only a copy of the checker
#      passes (it necessarily contains "/agents" in its own source).
#   2. real-mention -- a genuine `/agents` command mention in another
#      tracked .md file is still caught.
#   3. folder-path-not-a-match -- a path like
#      `skills/external/ask-matt/agents/openai.yaml` (a directory literally
#      named "agents", real shape in this repo) is not a false positive,
#      because "/agents" there is followed by another "/".
#   4. uppercase-AGENTS-md-not-a-match -- a link to `./AGENTS.md` or
#      `../AGENTS.md` (the real project file) is not a false positive: the
#      checker is case-sensitive on purpose.
#
# usage: tests/test-check-no-slash-agents.sh
# sortie : "PASS: 4/4 cas conformes" (exit 0) ou "FAIL: <n> cas non
# conformes" (exit 1), meme convention que test-check-private-patterns.sh.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_SCRIPT="$SCRIPT_DIR/../tools/check-no-slash-agents.sh"

if [ ! -f "$REAL_SCRIPT" ]; then
  echo "FAIL: script cible introuvable : $REAL_SCRIPT" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0

make_repo() {
  local ws="$1"
  local repo="$ws/canary"
  mkdir -p "$repo/tools"
  cp "$REAL_SCRIPT" "$repo/tools/check-no-slash-agents.sh"
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
OUT_1="$(cd "$REPO_1" && bash tools/check-no-slash-agents.sh 2>&1)"; RC_1=$?
if [ "$RC_1" -eq 0 ]; then
  echo "ok [1-self-exclusion]: passe sur un arbre ne contenant que le script"
else
  echo "FAIL [1-self-exclusion]: exit=$RC_1, sortie:" >&2
  printf '%s\n' "$OUT_1" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 2. a real /agents command mention elsewhere is still caught ------------
REPO_2="$(make_repo "$TMP/case-2")"
mkdir -p "$REPO_2/notes"
printf 'Pour deleguer une tache : `/agents brian fais X`.\n' > "$REPO_2/notes/leak.md"
commit_all "$REPO_2" "with leak"
OUT_2="$(cd "$REPO_2" && bash tools/check-no-slash-agents.sh 2>&1)"; RC_2=$?
if [ "$RC_2" -ne 0 ] && printf '%s' "$OUT_2" | grep -q "notes/leak.md"; then
  echo "ok [2-real-mention]: une vraie mention de /agents est refusee"
else
  echo "FAIL [2-real-mention]: exit=$RC_2, sortie:" >&2
  printf '%s\n' "$OUT_2" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 3. a directory literally named "agents" is not a false positive -------
REPO_3="$(make_repo "$TMP/case-3")"
mkdir -p "$REPO_3/notes"
printf 'voir `skills/external/ask-matt/agents/openai.yaml`\n' > "$REPO_3/notes/path.md"
commit_all "$REPO_3" "folder path only"
OUT_3="$(cd "$REPO_3" && bash tools/check-no-slash-agents.sh 2>&1)"; RC_3=$?
if [ "$RC_3" -eq 0 ]; then
  echo "ok [3-folder-path-not-a-match]: un dossier 'agents/<fichier>' n'est pas un faux positif"
else
  echo "FAIL [3-folder-path-not-a-match]: exit=$RC_3, sortie:" >&2
  printf '%s\n' "$OUT_3" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 4. a link to ./AGENTS.md (uppercase, the real file) is not a match ----
REPO_4="$(make_repo "$TMP/case-4")"
mkdir -p "$REPO_4/notes"
printf -- '- `see also` — [Instructions pour les agents](./AGENTS.md)\n' > "$REPO_4/notes/link.md"
commit_all "$REPO_4" "uppercase AGENTS.md link only"
OUT_4="$(cd "$REPO_4" && bash tools/check-no-slash-agents.sh 2>&1)"; RC_4=$?
if [ "$RC_4" -eq 0 ]; then
  echo "ok [4-uppercase-AGENTS-md-not-a-match]: un lien vers ./AGENTS.md n'est pas un faux positif"
else
  echo "FAIL [4-uppercase-AGENTS-md-not-a-match]: exit=$RC_4, sortie:" >&2
  printf '%s\n' "$OUT_4" >&2
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 4/4 cas conformes"
  exit 0
else
  echo "FAIL: $FAILURES cas non conformes"
  exit 1
fi
