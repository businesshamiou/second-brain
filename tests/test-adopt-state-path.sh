#!/usr/bin/env bash
# Mission 237, step 4 (report 236, anomaly 4): `project-bootstrap.sh adopt` on
# an adopted project whose Pilot prompt names another state sheet
# (state_path: wp/state/STATE.md) writes no second sheet under <project>/state/.
#
# Oracle, on a throwaway Vault: a project shaped like the workshop -- its Pilot
# prompt in state/, a legacy state/journal.md, its real sheet in wp/state/ --
# is adopted again:
#   (1) adopt exits 0;
#   (2) no state/STATE.md nor state/DIGEST.md appears at the project root;
#   (3) wp/state/STATE.md is left as it was (same fingerprint);
#   (4) a project with the default state_path still gets its missing sheet.
#
# usage: bash tests/test-adopt-state-path.sh [<source repo>]
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
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m237-statepath-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"
BOOT="$V/tools/project-bootstrap.sh"
mkdir -p "$WS"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" --marker-only "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }

echo "=== Mission 237 : adopt respecte state_path ($SRC) ==="

# A project shaped like the workshop.
P="$WS/atelier"
bash "$BOOT" create "$P" "Atelier" EN --vcs none >/dev/null 2>&1 || { echo "FAIL : projet jetable"; exit 1; }
mkdir -p "$P/wp/state"
cp "$P/state/journal.md" "$P/wp/state/journal.md"
bash "$V/tools/build-state.sh" "$P/wp" >/dev/null 2>&1 && bash "$V/tools/build-digest.sh" "$P/wp" >/dev/null 2>&1 \
  || { echo "FAIL : fiche wp/state"; exit 1; }
bash "$BOOT" prompt "$P" --state-path wp/state/STATE.md >/dev/null 2>&1 || { echo "FAIL : prompt --state-path"; exit 1; }
rm -f "$P/state/STATE.md" "$P/state/DIGEST.md"
grep -q '^state_path: "wp/state/STATE.md"' "$P/state/PILOT-PROMPT.md" || { echo "FAIL : state_path non pose"; exit 1; }
BEFORE="$(sha256sum "$P/wp/state/STATE.md" | cut -c1-16)"

OUT="$(bash "$BOOT" adopt "$P" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && pass "(1) adopt : exit 0" || fail "(1) adopt : exit $RC -- $(printf '%s' "$OUT" | tail -2)"
if [ ! -e "$P/state/STATE.md" ] && [ ! -e "$P/state/DIGEST.md" ]; then
  pass "(2) aucune fiche d'etat creee a la racine du projet"
else
  fail "(2) fiche(s) creee(s) a la racine : $(ls "$P/state" | tr '\n' ' ')"
fi
AFTER="$(sha256sum "$P/wp/state/STATE.md" | cut -c1-16)"
[ "$BEFORE" = "$AFTER" ] && pass "(3) wp/state/STATE.md laissee telle quelle" || fail "(3) wp/state/STATE.md modifiee"

# The default case still completes a missing sheet.
Q="$WS/plain"
bash "$BOOT" create "$Q" "Plain" EN --vcs none >/dev/null 2>&1 || { echo "FAIL : projet plain"; exit 1; }
rm -f "$Q/state/STATE.md" "$Q/state/DIGEST.md"
bash "$BOOT" adopt "$Q" >/dev/null 2>&1
{ [ -f "$Q/state/STATE.md" ] && [ -f "$Q/state/DIGEST.md" ]; } \
  && pass "(4) state_path par defaut : la fiche manquante est ecrite" || fail "(4) fiche par defaut non ecrite"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES, $PASSES PASS) ==="
exit 1
