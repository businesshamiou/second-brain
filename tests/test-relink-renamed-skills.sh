#!/usr/bin/env bash
# Mission 237, step 3: a participant who updates keeps working skill links when
# the version renamed a skill (tools/skill-renames.tsv).
#
# Oracle, on a throwaway workspace built from the working tree: a project linked
# before the rename carries, in .claude/skills and .agents/skills, links named
# ecriture-de-mission and recherche-interne that point nowhere, plus a dead link
# of an unknown skill.
#   (1) `second-brain-update.sh <version>` (the version already in the Vault's
#       history: UP-TO-DATE path) replaces each renamed link by the link under
#       its new name, alive; the old ones are gone;
#   (2) the unknown dead link is named and left as it is;
#   (3) the project's journal gains one APPLY line;
#   (4) `project-bootstrap.sh adopt` does the same on a second project;
#   (5) a second run changes nothing (idempotent).
#
# usage: bash tests/test-relink-renamed-skills.sh [<source repo>]
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$REPO_ROOT}"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m237-relink-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"
BOOT="$V/tools/project-bootstrap.sh"
mkdir -p "$WS"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" --marker-only "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }

# old_links <project>: links under the former names (and one unknown), dead.
old_links() {
  local p="$1" d name
  for name in ecriture-de-mission recherche-interne gone-skill; do
    mkdir -p "$TMP/old/$name"
    for d in .claude/skills .agents/skills; do
      mkdir -p "$p/$d"
      uv run --no-project python -c "import sys; sys.path.insert(0, sys.argv[1]); import sb_installer_helper as h; h._publish_skill_link(sys.argv[2], sys.argv[3])" \
        "$(sandbox_native_path "$V/tools")" "$(sandbox_native_path "$p/$d/$name")" "$(sandbox_native_path "$TMP/old/$name")" >/dev/null
    done
  done
  rm -rf "$TMP/old"
}
is_link() { [ -L "$1" ] || uv run --no-project python -c "import os,sys; sys.exit(0 if os.lstat(sys.argv[1]).st_file_attributes & 0x400 else 1)" "$(sandbox_native_path "$1")" 2>/dev/null; }
alive() { [ -e "$1/SKILL.md" ]; }

echo "=== Mission 237 : liens des skills renommees ($SRC) ==="

P="$WS/proj-a"
bash "$BOOT" create "$P" "Proj A" EN --vcs none >/dev/null 2>&1 || { echo "FAIL : projet A"; exit 1; }
old_links "$P"
is_link "$P/.claude/skills/ecriture-de-mission" && [ ! -e "$P/.claude/skills/ecriture-de-mission/SKILL.md" ] \
  || { echo "FAIL : montage des liens morts"; exit 1; }
for l in "$P/.claude/skills/mission-writing" "$P/.agents/skills/mission-writing"; do is_link "$l" && { cmd //c rmdir "$(sandbox_native_path "$l")" 2>/dev/null || rm -f "$l"; }; done
JOURNAL_BEFORE="$(wc -l < "$P/state/journal.md")"

# The Vault as an installed one: committed, an origin, a tag at its head.
git -C "$V" add -A >/dev/null 2>&1 && git -C "$V" commit -q -m "registry" >/dev/null 2>&1
git clone -q --bare "$V" "$TMP/origin.git" && git -C "$V" remote add origin "$TMP/origin.git"
git -C "$V" tag -a v9.9.9 -m v9.9.9 && git -C "$V" push -q origin v9.9.9 2>/dev/null
OUT="$(bash "$V/tools/second-brain-update.sh" v9.9.9 --vault "$V" --lang EN 2>&1)"; RC=$?
LAST="$(printf '%s\n' "$OUT" | tail -1)"

ok=1
for d in .claude/skills .agents/skills; do
  alive "$P/$d/mission-writing" && alive "$P/$d/internal-search" || ok=0
  [ -e "$P/$d/ecriture-de-mission" ] || is_link "$P/$d/ecriture-de-mission" && ok=0
  [ -e "$P/$d/recherche-interne" ] || is_link "$P/$d/recherche-interne" && ok=0
done
{ [ "$RC" -eq 0 ] && [ "$ok" = 1 ]; } && pass "(1) update ($LAST) : liens refaits sous mission-writing et internal-search, anciens retires" \
  || fail "(1) update rc=$RC ($LAST) : liens non refaits -- $(printf '%s' "$OUT" | grep -i 'relink\|mort\|dead' | head -2)"
{ is_link "$P/.claude/skills/gone-skill" && printf '%s' "$OUT" | grep -q "gone-skill"; } \
  && pass "(2) lien mort inconnu nomme et laisse" || fail "(2) lien inconnu : $(printf '%s' "$OUT" | grep -c gone-skill) mention(s)"
JOURNAL_AFTER="$(wc -l < "$P/state/journal.md")"
{ [ "$JOURNAL_AFTER" -eq $((JOURNAL_BEFORE + 1)) ] && tail -1 "$P/state/journal.md" | grep -q "APPLY:update"; } \
  && pass "(3) une ligne APPLY au journal du projet" || fail "(3) journal : $JOURNAL_BEFORE -> $JOURNAL_AFTER lignes"

Q="$WS/proj-b"
bash "$BOOT" create "$Q" "Proj B" EN --vcs none >/dev/null 2>&1 || { echo "FAIL : projet B"; exit 1; }
old_links "$Q"
for l in "$Q/.claude/skills/mission-writing" "$Q/.agents/skills/mission-writing" "$Q/.claude/skills/internal-search" "$Q/.agents/skills/internal-search"; do
  is_link "$l" && { cmd //c rmdir "$(sandbox_native_path "$l")" 2>/dev/null || rm -f "$l"; }
done
bash "$BOOT" adopt "$Q" >/dev/null 2>&1
{ alive "$Q/.claude/skills/mission-writing" && ! is_link "$Q/.claude/skills/ecriture-de-mission" && tail -1 "$Q/state/journal.md" | grep -q "APPLY:adopt"; } \
  && pass "(4) adopt refait les liens et trace au journal" || fail "(4) adopt : liens ou journal non refaits"

OUT2="$(uv run --no-project "$V/tools/sb_installer_helper.py" relink-renamed "$(sandbox_native_path "$V")" "$(sandbox_native_path "$P")" "$(sandbox_native_path "$Q")" 2>&1)"
printf '%s' "$OUT2" | grep -q "RELINKED" && fail "(5) second passage : $OUT2" || pass "(5) second passage : rien a refaire"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES, $PASSES PASS) ==="
exit 1
