#!/usr/bin/env bash
# T3 (Mission 192, Decision 210904): an adopted folder whose .gitignore
# already existed receives its links to the assistant and the skills once
# the three exclusions are added -- the recipe applied to second-brain-build.
#
#   control (behaviour of Mission 190): adoption of a Git folder whose
#   .gitignore lacks the three lines -> no link placed, the lines returned;
#   (a) the three lines appended (nothing removed), adoption replayed
#       (idempotent): the links exist (.claude/skills, .agents/skills), and
#       `git status --porcelain` shows none of them.
#
# usage: bash tests/test-workshop-gitignore-links.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m192-gitignore-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== T3 : exclusions de liens ajoutees a un .gitignore existant ==="
WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null
P="$WS/atelier"
mkdir -p "$P"
printf '# the folder'"'"'s own ignores\n*.tmp\n' > "$P/.gitignore"
printf 'hello\n' > "$P/README.md"
(
  cd "$P" && git init -q -b main 2>/dev/null || git init -q
  git config user.email t@example.invalid && git config user.name t
  git add -A && git commit -q -m init
) >/dev/null 2>&1

OUT0="$(bash "$V/tools/project-bootstrap.sh" adopt "$P" --vcs git --lang EN 2>&1 </dev/null)"
case "$OUT0" in
  *"/.claude/skills/"*) pass "controle : .gitignore sans les lignes -> lignes rendues" ;;
  *) fail "controle : les lignes ne sont pas rendues" ;;
esac
if [ ! -e "$P/.claude/skills" ] && [ ! -e "$P/.agents/skills" ]; then
  pass "controle : aucun lien pose"
else
  fail "controle : des liens ont ete poses malgre l'absence des lignes"
fi

BEFORE="$(cat "$P/.gitignore")"
printf '/.claude/skills/\n/.claude/agents/\n/.agents/skills/\n' >> "$P/.gitignore"
case "$(cat "$P/.gitignore")" in
  "$BEFORE"*) pass "(a) les trois lignes ajoutees, rien retire" ;;
  *) fail "(a) le .gitignore d'origine a change" ;;
esac
bash "$V/tools/project-bootstrap.sh" adopt "$P" --vcs git --lang EN >/dev/null 2>&1 </dev/null
if [ -e "$P/.claude/skills" ] && [ -e "$P/.agents/skills" ] && [ -n "$(ls "$P/.claude/skills" 2>/dev/null)" ]; then
  pass "(a) adoption rejouee : liens poses (.claude/skills, .agents/skills)"
else
  fail "(a) liens absents apres ajout des lignes"
fi
LEAK="$(git -C "$P" status --porcelain | grep -E '\.claude/skills|\.claude/agents|\.agents/skills' || true)"
if [ -z "$LEAK" ]; then
  pass "(a) git status ne montre aucun lien"
else
  fail "(a) git status montre des liens : $LEAK"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
