#!/usr/bin/env bash
# Mission 218, lot 5: a baseline can no longer be engraved on a dirty tree,
# and it can be amended in a proved way -- never by hand.
#
# Incident: on 2026-09-22 a knowledge base was adopted while 532 of its
# INDEX.md were overwritten in the working tree; the baseline engraved the
# overwritten content, and once Git restored the files the guardians judged
# them as "touched".
#
#   (a) adopt on a Git tree with uncommitted changes -> BASELINE-DIRTY-TREE,
#       the count of porcelain lines named, nothing written (no certificate,
#       no baseline, no Pilot prompt);
#   (b) the same tree, adopted through an order carrying `Arbre sale :
#       accepté — <raison>` -> adopted, baseline written;
#   (c) vcs: none without Git -> the tool says it cannot measure the tree, and
#       adopts;
#   (d) amendment: N paths whose working-tree content equals the reference's
#       -> their fingerprints become the reference's, the header says who,
#       when, which reference and how many paths; the guardians then see them
#       as untouched;
#   (e) one path whose content differs from the reference -> refused, nothing
#       written (all or nothing);
#   (f) a path absent from the baseline -> refused (an amendment never widens it).
#
# usage: bash tests/test-baseline-dirty-tree-and-amend.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() { local n="$1"; shift; if "$@"; then pass "$n"; else fail "$n"; fi; }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m218-base-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/bin/pre-commit"
chmod +x "$TMP/bin/pre-commit"
PATH="$TMP/bin:$PATH"; export PATH

WS="$TMP/ws"; V="$WS/second-brain"
mkdir -p "$WS"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" --marker-only "$WS" >/dev/null || { echo "FAIL : marqueur"; exit 1; }
BOOT="$V/tools/project-bootstrap.sh"
VID="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"
VREF="$(git -C "$V" rev-parse HEAD)"
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -c1-64; else shasum -a 256 | cut -c1-64; fi; }
G() { git -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false "$@"; }

mkrepo() { # mkrepo <dir> : a committed repository with chan/INDEX.md and a.md
  mkdir -p "$1/chan"
  printf '# Archive chan\n' > "$1/chan/INDEX.md"
  printf '# A\n' > "$1/a.md"
  G -C "$1" init -q; G -C "$1" add -A; G -C "$1" commit -q -m init
}

# --- (a) dirty tree refused -------------------------------------------------------------------
P="$WS/dirty"
mkrepo "$P"
printf 'overwritten\n' > "$P/chan/INDEX.md"
bash "$BOOT" adopt "$P" "Dirty" --vcs none >"$TMP/a.out" 2>&1; RC=$?
check "(a) arbre sale : BASELINE-DIRTY-TREE nomme, rc!=0" sh -c "[ $RC != 0 ] && grep -q 'BASELINE-DIRTY-TREE : 1 porcelain line' '$TMP/a.out'"
check "(a) rien ecrit : ni acte, ni ligne de base, ni PILOT-PROMPT" \
  sh -c "[ ! -e '$P/.pre-commit-config.yaml' ] && [ -z \"\$(ls -a '$P' | grep vault-baseline)\" ] && [ ! -e '$P/state/PILOT-PROMPT.md' ]"

# --- (b) accepted by the order -------------------------------------------------------------------
cat > "$TMP/order.md" <<EOF
Ordre d'initiation
- Type : adopt
- Mode : answered
- Nom : dirty
- Emplacement : $WS
- Vault + construction : vault_id=$VID, vault_origin=x, vault_ref=$VREF
- Git : none
- Objet : test
- Autorisation Owner datée : « oui » 2026-09-23
- Arbre sale : accepté — test de la Mission 218
EOF
bash "$BOOT" --order "$TMP/order.md" >"$TMP/b.out" 2>&1; RC=$?
check "(b) ordre portant 'Arbre sale : accepte' : adopte, ligne de base ecrite (rc=$RC)" \
  sh -c "[ $RC = 0 ] && [ -n \"\$(ls -a '$P' | grep vault-baseline)\" ]"

# --- (c) no Git: the tool says it cannot measure --------------------------------------------------
P="$WS/nogit"
mkdir -p "$P"; printf '# N\n' > "$P/n.md"
bash "$BOOT" adopt "$P" "Nogit" --vcs none >"$TMP/c.out" 2>&1; RC=$?
check "(c) sans Git : BASELINE-TREE-UNMEASURED dit, adoption faite (rc=$RC)" \
  sh -c "[ $RC = 0 ] && grep -q 'BASELINE-TREE-UNMEASURED' '$TMP/c.out' && [ -e '$P/.pre-commit-config.yaml' ]"

# --- (d) amendment ----------------------------------------------------------------------------------
P="$WS/dirty"
BASE="$P/$(tr -d '\r' < "$P/.pre-commit-config.yaml" | sed -n 's/^# baseline: //p')"
G -C "$P" checkout -q -- chan/INDEX.md          # the restore that Git made possible
printf 'chan/INDEX.md\n' > "$TMP/paths.txt"
untouched() { (cd "$P" && . "$V/tools/project-baseline.sh" && pb_load "$P" && pb_untouched "$1"); }
check "(d) avant : chan/INDEX.md restaure est vu comme touche" sh -c "! (cd '$P' && . '$V/tools/project-baseline.sh' && pb_load '$P' && pb_untouched chan/INDEX.md)"
B0="$(cksum < "$BASE")"
uv run --no-project "$V/tools/project_baseline.py" amend "$P" --ref HEAD --paths "$TMP/paths.txt" --by "Executor M218 test" --reason "restored by Git" >"$TMP/d.out" 2>&1; RC=$?
check "(d) amendement : rc=0, en-tete (qui, quand, reference, nombre)" \
  sh -c "[ $RC = 0 ] && grep -Eq '^# amended_at: [0-9T:+-]+ by: Executor M218 test ref: [0-9a-f]{40} paths: 1 reason: restored by Git\$' '$BASE'"
check "(d) apres : chan/INDEX.md vu comme non touche par le gardien" untouched chan/INDEX.md
A_SHA="$(printf '# A\n' | sha)"
check "(d) a.md, hors amendement : empreinte inchangee" grep -q "^$A_SHA	a.md\$" "$BASE"

# --- (e) content differs from the reference -> refused, all or nothing ----------------------------------
printf 'changed again\n' > "$P/a.md"
printf 'chan/INDEX.md\na.md\n' > "$TMP/paths2.txt"
B1="$(cksum < "$BASE")"
uv run --no-project "$V/tools/project_baseline.py" amend "$P" --ref HEAD --paths "$TMP/paths2.txt" --by t --reason r >"$TMP/e.out" 2>&1; RC=$?
check "(e) empreinte differente de la reference : refus nomme, rien ecrit" \
  sh -c "[ $RC != 0 ] && grep -q 'BASELINE-AMEND-REFUSED : a.md' '$TMP/e.out' && [ \"\$(cksum < '$BASE')\" = '$B1' ]"

# --- (f) a path absent from the baseline -------------------------------------------------------------------
G -C "$P" checkout -q -- a.md
printf 'new\n' > "$P/new.md"; G -C "$P" add new.md; G -C "$P" commit -q -m new
printf 'new.md\n' > "$TMP/paths3.txt"
uv run --no-project "$V/tools/project_baseline.py" amend "$P" --ref HEAD --paths "$TMP/paths3.txt" --by t --reason r >"$TMP/f.out" 2>&1; RC=$?
check "(f) chemin absent de la ligne de base : refuse (jamais d'elargissement)" \
  sh -c "[ $RC != 0 ] && grep -q 'BASELINE-AMEND-REFUSED : new.md' '$TMP/f.out' && [ \"\$(cksum < '$BASE')\" = '$B1' ]"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
