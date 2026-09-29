#!/usr/bin/env bash
# Mission 219, lot D, A3 (report of Mission 218): project-bootstrap.sh looked a
# project up in the registry with `grep -F "| <path> |"`, a search that also
# matches the `vcs` column -- so a project whose relative path is `none` or
# `git` was refused as "already registered" as soon as any row carried that
# vcs. The lookup is now anchored on the path column.
#
#   (a) a registry row with vcs `none` exists -> `create <ws>/none` succeeds
#       and adds one row whose path column is `none`;
#   (b) a registry row with vcs `git` exists -> `create <ws>/git` succeeds;
#   (c) witness: `create <ws>/none` a second time is still refused as
#       already registered (the anchored lookup still finds the real row);
#   (d) the measure written after creation lands on the project's own row,
#       never on another row that merely carries `| none |` (the rewrite of the
#       row is anchored the same way).
#
# usage: bash tests/test-project-bootstrap-registry-path-column.sh
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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m219-a3-XXXXXX")"
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
REG="$V/projects/PROJECT-REGISTRY.md"
path_rows() { awk -F'|' -v p="$1" '{ c=$5; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == p) n++ } END { print n+0 }' "$REG"; }

bash "$BOOT" create "$WS/alpha" "Alpha" --vcs none >"$TMP/alpha.out" 2>&1
bash "$BOOT" create "$WS/beta" "Beta" --vcs git >"$TMP/beta.out" 2>&1
check "(setup) une ligne vcs none et une ligne vcs git au registre" \
  sh -c "grep -q '| alpha | none |' '$REG' && grep -q '| beta | git |' '$REG'"
ALPHA_BEFORE="$(grep '| alpha |' "$REG")"

# --- (a) path none -------------------------------------------------------------------------
bash "$BOOT" create "$WS/none" "None" --vcs none >"$TMP/none.out" 2>&1; RA=$?
check "(a) create <ws>/none accepte (rc=$RA) [$(grep -m1 REFUS "$TMP/none.out")]" [ "$RA" = 0 ]
check "(a) une ligne dont la colonne chemin vaut none" [ "$(path_rows none)" = 1 ]

# --- (b) path git ---------------------------------------------------------------------------
bash "$BOOT" create "$WS/git" "Git" --vcs none >"$TMP/git.out" 2>&1; RB=$?
check "(b) create <ws>/git accepte (rc=$RB) [$(grep -m1 REFUS "$TMP/git.out")]" [ "$RB" = 0 ]
check "(b) une ligne dont la colonne chemin vaut git" [ "$(path_rows git)" = 1 ]

# --- (c) witness: the real row is still found -------------------------------------------------
bash "$BOOT" create "$WS/none2-unused" "Unused" --vcs none >/dev/null 2>&1
rm -rf "$WS/none"
bash "$BOOT" create "$WS/none" "None again" --vcs none >"$TMP/none-again.out" 2>&1; RC2=$?
check "(c) temoin : create <ws>/none une seconde fois refuse, deja inscrit (rc=$RC2)" \
  sh -c "[ '$RC2' != 0 ] && grep -q 'deja inscrit' '$TMP/none-again.out'"

# --- (d) the measure lands on the project's own row ------------------------------------------
check "(d) la ligne d'alpha (vcs none) n'a pas ete reecrite par la creation de none" [ "$(grep '| alpha |' "$REG")" = "$ALPHA_BEFORE" ]

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
