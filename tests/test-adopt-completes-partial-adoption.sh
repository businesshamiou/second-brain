#!/usr/bin/env bash
# Mission 231, step 4e: `adopt` on a PARTIALLY adopted project completes it
# without recreating anything.
#
# Measured on the warehouse (2026-09-25): missions/ and its register existed,
# the Vault's registry named it, but state/journal.md, state/STATE.md and
# state/DIGEST.md were missing. Replaying the adoption must add exactly those
# three, and leave every file that was there byte for byte.
#
# Fixture: a throwaway workspace and Vault (this working tree); a Git project
# adopted once, then brought back to the warehouse's state -- its journal,
# STATE.md and DIGEST.md moved out, a missions/ register with one line written
# by hand, a VAULT-ROOT.md marker of its own (the warehouse carries one) --
# and committed.
#
# Measured on 2026-09-26 (Mission 231): the current tool already completes
# such a project -- this test was green on its first run, and the same
# adoption replayed on a clone of the warehouse itself (a throwaway Vault
# given the real identity) added exactly journal, STATE.md, DIGEST.md and the
# link folders, and modified nothing. The warehouse's partial state is
# therefore put down to an adoption by an older tool (HYPOTHESIS: adopted by
# Mission 202, before STATE.md and DIGEST.md were laid down, Mission 218).
# The test engraves the property.
#   (1) adopt again: exit 0;
#   (2) state/journal.md, state/STATE.md, state/DIGEST.md exist again, and
#       the journal carries one birth line;
#   (3) every file that was there is unchanged (fingerprints of the whole
#       tracked tree, the hand-written register line included);
#   (4) the Vault's registry still names the project once, its sheet once;
#   (5) the adoption's own commit (Mission 244) and `git status --porcelain`
#       name only the three new state files (and the indexes of folders that
#       had none).
#
# usage: bash tests/test-adopt-completes-partial-adoption.sh
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
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m231-partial-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== Mission 231 : adopt complete une adoption partielle sans rien recreer ==="
WS="$TMP/ws"; V="$WS/second-brain"; P="$WS/entrepot"
mkdir -p "$WS" "$P"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null || { echo "FAIL : marqueur"; exit 1; }
printf '# Entrepot\n' > "$P/README.md"
( cd "$P" && { git init -q -b main 2>/dev/null || git init -q; } && git config user.email t@example.invalid && git config user.name t \
  && git add -A && git commit -q -m init ) >/dev/null 2>&1
bash "$V/tools/project-bootstrap.sh" adopt "$P" "Entrepot" --vcs git --lang FR >"$TMP/adopt1.out" 2>&1 </dev/null \
  || { echo "FAIL : premiere adoption"; tail -n 5 "$TMP/adopt1.out"; exit 1; }

# The warehouse's state: no journal, no STATE.md, no DIGEST.md; a register line by hand.
mkdir -p "$TMP/moved" "$P/missions"
for f in journal.md STATE.md DIGEST.md; do mv "$P/state/$f" "$TMP/moved/$f"; done
[ -f "$P/missions/MISSION-INDEX.md" ] || cp "$V/templates/mission-index-template.md" "$P/missions/MISSION-INDEX.md" 2>/dev/null \
  || printf '# Registre des Missions\n\n| ID | Statut | Date | Rapport |\n|---|---|---|---|\n' > "$P/missions/MISSION-INDEX.md"
printf '| `001` | `FAIT` | 2026-09-25 | REPORT-2026-09-25-000000-001-x.md |\n' >> "$P/missions/MISSION-INDEX.md"
bash "$V/tools/write-marker.sh" --marker-only "$P" >/dev/null 2>&1 || cp "$WS/VAULT-ROOT.md" "$P/VAULT-ROOT.md"
# Mission 244: the warehouse's state was committed through its guardians, so its
# indexes were fresh -- the replayed adoption now commits what it adds through
# those same guardians, and a stale index would (rightly) refuse it.
bash "$V/tools/build-indexes.sh" "$P" >/dev/null 2>&1
( cd "$P" && git add -A && git -c core.hooksPath=/dev/null commit -q -m "partial adoption, as measured" ) >/dev/null 2>&1
TRACKED_BEFORE="$(cd "$P" && git ls-files)"
fingerprint() { (cd "$P" && printf '%s\n' "$TRACKED_BEFORE" | tr '\n' '\0' | xargs -0 git hash-object 2>/dev/null | git hash-object --stdin); }
FP_BEFORE="$(fingerprint)"
REG="$V/projects/PROJECT-REGISTRY.md"
REG_N_BEFORE="$(grep -c '| entrepot |\|entrepot' "$REG")"
SHEETS_BEFORE="$(ls "$V"/projects/PROJECT-*-ENTREPOT.md 2>/dev/null | wc -l | tr -d ' ')"

OUT="$(bash "$V/tools/project-bootstrap.sh" adopt "$P" "Entrepot" --vcs git --lang FR 2>&1 </dev/null)"; RC=$?
[ "$RC" = 0 ] && pass "(1) adopt rejoue : sortie 0" || fail "(1) adopt rejoue : rc=$RC -- $(printf '%s' "$OUT" | tail -n 3 | tr '\n' ' ' | cut -c1-240)"
MISSING=""
for f in journal.md STATE.md DIGEST.md; do [ -f "$P/state/$f" ] || MISSING="$MISSING $f"; done
[ -z "$MISSING" ] && pass "(2) journal, STATE.md et DIGEST.md recrees" || fail "(2) toujours absents :$MISSING"
if [ -f "$P/state/journal.md" ] && [ "$(grep -c 'STATE:' "$P/state/journal.md")" = "1" ]; then
  pass "(2) le journal porte une ligne de naissance"
else
  fail "(2) journal sans ligne de naissance unique"
fi
[ "$(fingerprint)" = "$FP_BEFORE" ] && pass "(3) aucun fichier present n'a change (arbre suivi, registre fait main compris)" \
  || fail "(3) des fichiers presents ont change : $(cd "$P" && git diff --name-only | tr '\n' ' ')"
REG_N_AFTER="$(grep -c '| entrepot |\|entrepot' "$REG")"
SHEETS_AFTER="$(ls "$V"/projects/PROJECT-*-ENTREPOT.md 2>/dev/null | wc -l | tr -d ' ')"
if [ "$REG_N_AFTER" = "$REG_N_BEFORE" ] && [ "$SHEETS_AFTER" = "1" ] && [ "$SHEETS_BEFORE" = "1" ]; then
  pass "(4) registre du Vault et fiche : une seule fois"
else
  fail "(4) registre $REG_N_BEFORE -> $REG_N_AFTER lignes, fiches $SHEETS_BEFORE -> $SHEETS_AFTER"
fi
# Mission 244: the adoption commits what it added -- only the state pieces.
EXTRA="$( { git -C "$P" status --porcelain -uall | cut -c4-; git -C "$P" show --name-only --format= HEAD; } | grep . | grep -v -x -e 'state/journal.md' -e 'state/STATE.md' -e 'state/DIGEST.md' -e 'state/index.md' -e 'missions/index.md' || true)"
[ -z "$EXTRA" ] && pass "(5) le commit d'adoption et git status : seulement les pieces d'etat" || fail "(5) en plus : $(printf '%s' "$EXTRA" | tr '\n' ' ')"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
