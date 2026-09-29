#!/usr/bin/env bash
# Mission 231, step 4b: the bootstrap's .gitignore no longer hides the skills
# a project installs for itself.
#
# Until now project-bootstrap.sh wrote three folder-wide lines
# (/.claude/skills/, /.claude/agents/, /.agents/skills/) to keep the links to
# the Vault's skills and assistant out of Git; they also hid every skill a
# project installed in those folders (measured on the warehouse, 2026-09-25).
# Now link-project writes, in each of the three folders and BEFORE placing a
# link, a .gitignore of its own that names the links one by one; the project's
# .gitignore carries no folder-wide line.
#
# Fixture: a throwaway workspace and Vault (this working tree); a Git project
# created by project-bootstrap.sh, then a skill of its own in .claude/skills
# and in .agents/skills.
#   (1) the project's own skills are NOT ignored (RED before the fix);
#   (2) the links placed are ignored, one by one (a junction/link never shows);
#   (3) `git status --porcelain -uall` lists the project's skills and the
#       folders' .gitignore files, and no link;
#   (4) the project's .gitignore carries none of the three folder-wide lines;
#   (5) adopt on a Git folder whose .gitignore lacks any exclusion: the links
#       are placed (the folders' own .gitignore protect them) and none shows;
#   (6) a folder-wide line already in a project's .gitignore is reported by
#       adopt, never removed (an existing file is never modified);
#   (7) a .gitignore of the project's own in one of the folders is never
#       overwritten: its links are not placed and adopt says so.
#
# usage: bash tests/test-bootstrap-gitignore-installed-skills.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m231-gitignore-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== Mission 231 : le .gitignore du bootstrap ne cache plus les skills installes ==="
WS="$TMP/ws"; V="$WS/second-brain"; P="$WS/projet"
mkdir -p "$WS"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null || { echo "FAIL : marqueur"; exit 1; }
# A named assistant, so .claude/agents gets its link too.
mkdir -p "$V/.install"
printf '{"schemaVersion": 1, "answers": {"language": "FR", "vaultName": "Ibrahim"}, "assistant": {"name": "Ibrahim", "slug": "ibrahim"}}\n' > "$V/.install/state.json"
uv run --no-project "$V/tools/sb_installer_helper.py" render-assistant "$V" "Ibrahim" --language FR >/dev/null 2>&1

bash "$V/tools/project-bootstrap.sh" create "$P" "Projet" --vcs git --lang FR >"$TMP/create.out" 2>&1 </dev/null \
  || { echo "FAIL : projet non cree"; tail -n 5 "$TMP/create.out"; exit 1; }
mkdir -p "$P/.claude/skills/own-skill" "$P/.agents/skills/own-codex-skill"
printf -- '---\nname: own-skill\n---\n' > "$P/.claude/skills/own-skill/SKILL.md"
printf -- '---\nname: own-codex-skill\n---\n' > "$P/.agents/skills/own-codex-skill/SKILL.md"

ignored() { git -C "$P" check-ignore -q -- "$1"; }
LINK_C="$(ls "$P/.claude/skills" | grep -v -e '^own-skill$' -e '^\.gitignore$' | head -n 1)"
LINK_A="$(ls "$P/.agents/skills" | grep -v -e '^own-codex-skill$' -e '^\.gitignore$' | head -n 1)"

ignored ".claude/skills/own-skill/SKILL.md" && fail "(1) le skill du projet (.claude/skills) est ignore" \
  || pass "(1) le skill du projet (.claude/skills) est suivi"
ignored ".agents/skills/own-codex-skill/SKILL.md" && fail "(1) le skill du projet (.agents/skills) est ignore" \
  || pass "(1) le skill du projet (.agents/skills) est suivi"
if [ -n "$LINK_C" ] && [ -n "$LINK_A" ] && ignored ".claude/skills/$LINK_C" && ignored ".agents/skills/$LINK_A"; then
  pass "(2) les liens sont ignores ($LINK_C, $LINK_A)"
else
  fail "(2) liens non ignores ou absents (claude: '${LINK_C}', codex: '${LINK_A}')"
fi
if [ -e "$P/.claude/agents/ibrahim.md" ]; then
  ignored ".claude/agents/ibrahim.md" && pass "(2) le lien de l'assistant est ignore" || fail "(2) le lien de l'assistant n'est pas ignore"
else
  fail "(2) lien de l'assistant absent (.claude/agents/ibrahim.md)"
fi
ST="$(git -C "$P" status --porcelain -uall)"
if has "$ST" ".claude/skills/own-skill/SKILL.md" && has "$ST" ".agents/skills/own-codex-skill/SKILL.md" \
  && ! printf '%s\n' "$ST" | grep -q -e "skills/$LINK_C" -e "skills/$LINK_A" -e "agents/ibrahim.md"; then
  pass "(3) git status : les skills du projet, aucun lien"
else
  fail "(3) git status inattendu : $(printf '%s' "$ST" | tr '\n' ' ' | cut -c1-300)"
fi
if tr -d '\r' < "$P/.gitignore" | grep -qx -e '/.claude/skills/' -e '/.claude/agents/' -e '/.agents/skills/'; then
  fail "(4) le .gitignore du projet porte encore une ligne qui cache un dossier entier"
else
  pass "(4) le .gitignore du projet ne cache aucun dossier entier"
fi

# --- adopt ------------------------------------------------------------------
Q="$WS/dossier"
mkdir -p "$Q"
printf '*.tmp\n' > "$Q/.gitignore"
printf 'hello\n' > "$Q/README.md"
( cd "$Q" && { git init -q -b main 2>/dev/null || git init -q; } && git config user.email t@example.invalid && git config user.name t \
  && git add -A && git commit -q -m init ) >/dev/null 2>&1
OUT_Q="$(bash "$V/tools/project-bootstrap.sh" adopt "$Q" --vcs git --lang FR 2>&1 </dev/null)"
if [ -n "$(ls "$Q/.claude/skills" 2>/dev/null | grep -v '^\.gitignore$')" ]; then
  pass "(5) adopt sans exclusion : liens poses"
else
  fail "(5) adopt sans exclusion : aucun lien pose -- $(printf '%s' "$OUT_Q" | tail -n 3 | tr '\n' ' ' | cut -c1-200)"
fi
LEAK="$(git -C "$Q" status --porcelain -uall | grep -E '(\.claude|\.agents)/' | grep -v '/\.gitignore$' || true)"
[ -z "$LEAK" ] && pass "(5) adopt : git status ne montre aucun lien" || fail "(5) adopt : liens visibles : $(printf '%s' "$LEAK" | head -n 3 | tr '\n' ' ')"

R="$WS/ancien"
mkdir -p "$R"
printf '/.claude/skills/\n/.claude/agents/\n/.agents/skills/\n' > "$R/.gitignore"
printf 'hello\n' > "$R/README.md"
( cd "$R" && { git init -q -b main 2>/dev/null || git init -q; } && git config user.email t@example.invalid && git config user.name t \
  && git add -A && git commit -q -m init ) >/dev/null 2>&1
GI_BEFORE="$(git hash-object "$R/.gitignore")"
OUT_R="$(bash "$V/tools/project-bootstrap.sh" adopt "$R" --vcs git --lang FR 2>&1 </dev/null)"
if has "$OUT_R" "/.claude/skills/" && [ "$(git hash-object "$R/.gitignore")" = "$GI_BEFORE" ]; then
  pass "(6) ligne qui cache un dossier : signalee, .gitignore inchange"
else
  fail "(6) ligne non signalee ou .gitignore modifie -- $(printf '%s' "$OUT_R" | grep -i gitignore | head -n 2 | tr '\n' ' ')"
fi

F="$WS/propre"
mkdir -p "$F/.claude/skills"
printf 'my-own-rules\n' > "$F/.claude/skills/.gitignore"
printf 'hello\n' > "$F/README.md"
( cd "$F" && { git init -q -b main 2>/dev/null || git init -q; } && git config user.email t@example.invalid && git config user.name t \
  && git add -A && git commit -q -m init ) >/dev/null 2>&1
OUT_F="$(bash "$V/tools/project-bootstrap.sh" adopt "$F" --vcs git --lang FR 2>&1 </dev/null)"
if [ "$(cat "$F/.claude/skills/.gitignore")" = "my-own-rules" ] && [ -z "$(ls "$F/.claude/skills" | grep -v '^\.gitignore$')" ] \
  && has "$(printf '%s' "$OUT_F" | tr '\\' '/')" ".claude/skills/.gitignore"; then
  pass "(7) .gitignore propre au projet : jamais ecrase, aucun lien pose, dit"
else
  fail "(7) .gitignore propre : $(cat "$F/.claude/skills/.gitignore" | head -n 1) ; liens : $(ls "$F/.claude/skills" | wc -l) -- $(printf '%s' "$OUT_F" | grep -i gitignore | head -n 1)"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
