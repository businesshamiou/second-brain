#!/usr/bin/env bash
# Mission 219, lot D, A8 (report of Mission 218): the index-weight guardian
# judged only `missions/MISSION-INDEX.md` at the root of the committing
# repository, so the workshop's register, `workshop-production/missions/
# MISSION-INDEX.md`, grew to 9 007 bytes past its 8 000 cap unseen. The
# guardian now judges every staged path ending in `missions/MISSION-INDEX.md`.
#
#   (a) a staged workshop-production/missions/MISSION-INDEX.md of 9 000
#       bytes -> refused, the path named;
#   (b) the same register at 7 000 bytes -> accepted;
#   (c) a line of Mission 219 over 300 characters in the nested register
#       -> refused (the line cap follows the register wherever it lives);
#   (d) witness: the root missions/MISSION-INDEX.md at 9 000 bytes is still
#       refused;
#   (e) witness: a file merely named like the register elsewhere
#       (notes/MISSION-INDEX.md.bak) is not judged.
#
# usage: bash tests/test-index-weight-nested-mission-index.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$REPO_ROOT/tools/check-index-weight.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m219-a8-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

register() { # register <file> <bytes> [long-line]
  mkdir -p "$(dirname "$1")"
  {
    printf '# Registre\n\n| ID | Statut | Date | Rapport |\n|---|---|---|---|\n'
    [ -n "${3:-}" ] && printf '| `219` | `COMPLETED` | 2026-09-23 | %s |\n' "$(head -c 320 /dev/zero | tr '\0' 'r')"
  } > "$1"
  local have; have="$(wc -c < "$1" | tr -d ' ')"
  [ "$have" -lt "$2" ] && head -c $(( $2 - have )) /dev/zero | tr '\0' 'x' >> "$1"
  return 0
}
repo() { local r="$TMP/$1"; mkdir -p "$r"; git init -q "$r"; printf '%s' "$r"; }
judge() { ( cd "$1" && git add -A >/dev/null 2>&1 && bash "$GUARD" ) >"$TMP/out" 2>&1; echo $?; }

R="$(repo a)"; register "$R/workshop-production/missions/MISSION-INDEX.md" 9000
RC="$(judge "$R")"
if [ "$RC" != 0 ] && grep -q 'workshop-production/missions/MISSION-INDEX.md' "$TMP/out"; then
  pass "(a) registre imbrique de 9000 octets refuse, chemin nomme"
else
  fail "(a) registre imbrique de 9000 octets : rc=$RC [$(head -c 200 "$TMP/out" | tr '\n' ' ')]"
fi

R="$(repo b)"; register "$R/workshop-production/missions/MISSION-INDEX.md" 7000
RC="$(judge "$R")"; [ "$RC" = 0 ] && pass "(b) registre imbrique de 7000 octets accepte" || fail "(b) 7000 octets refuse : rc=$RC [$(head -c 200 "$TMP/out" | tr '\n' ' ')]"

R="$(repo c)"; register "$R/workshop-production/missions/MISSION-INDEX.md" 1000 long
RC="$(judge "$R")"
if [ "$RC" != 0 ] && grep -q 'Mission 219' "$TMP/out"; then
  pass "(c) ligne de la Mission 219 > 300 caracteres dans le registre imbrique refusee"
else
  fail "(c) ligne longue non refusee : rc=$RC [$(head -c 200 "$TMP/out" | tr '\n' ' ')]"
fi

R="$(repo d)"; register "$R/missions/MISSION-INDEX.md" 9000
RC="$(judge "$R")"; [ "$RC" != 0 ] && pass "(d) temoin : registre racine de 9000 octets refuse" || fail "(d) temoin : registre racine accepte"

R="$(repo e)"; register "$R/notes/MISSION-INDEX.md.bak" 9000
RC="$(judge "$R")"; [ "$RC" = 0 ] && pass "(e) temoin : un fichier au nom voisin n'est pas juge" || fail "(e) temoin : fichier voisin juge (rc=$RC)"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
