#!/usr/bin/env bash
# Mission 221, batch C (A-219-2): tools/check-project-conformity.sh, section 2
# (entry in the register). The lookup is anchored on the path column
# (relative_path, fifth field), as project-bootstrap.sh does since Mission 219
# (A3) -- never "| <path> |" anywhere on the line, which a display name or any
# other field equal to the path used to satisfy.
#
# Oracles (PASS expected):
#   (a) witness: the adopted project, registered at its path, has no register gap;
#   (b) the register holds the project's path only in ANOTHER field (display
#       name) and its path column names another folder: the register gap is named;
#   (c) red witness: the script before this fix (commit fa54e9f) names no gap on
#       (b), the defect reproduced, when that history is available.
#
# Writes only in a temporary folder (prefix m221-registry).
#
# usage: bash tests/test-conformity-registry-anchored.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- tools/project-bootstrap.sh en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m221-registry-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
if ! sandbox_vault "$REPO_ROOT" "$V"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V/tools/write-marker.sh" "$WS" >/dev/null
P="$WS/projet"
mkdir -p "$P"
printf '# notes\n' > "$P/notes.md"
bash "$V/tools/project-bootstrap.sh" adopt "$P" "Projet" FR --vcs none >/dev/null 2>&1 </dev/null

REGISTRY="$V/projects/PROJECT-REGISTRY.md"
GAP='inscription au registre'

# --- (a) witness: registered at its path -----------------------------------------------------
OUT="$(bash "$V/tools/check-project-conformity.sh" "$P" 2>&1)"
if ! grep -qE '^\| [^|]* \| Projet \| [^|]* \| projet \|' "$REGISTRY"; then
  fail "(a) temoin : la ligne du projet n'est pas au registre sous le chemin projet"
elif printf '%s' "$OUT" | grep -q "$GAP"; then
  fail "(a) temoin : un ecart de registre est nomme pour un projet inscrit : $OUT"
else
  pass "(a) temoin : projet inscrit a son chemin, aucun ecart de registre"
fi

# --- (b) the path only in the display-name field -----------------------------------------------
# The row keeps "projet" in the display_name field; its relative_path names
# another folder. The unanchored lookup still finds "| projet |" on the line.
awk -F'|' 'BEGIN { OFS = "|" } { c = $5; gsub(/^[ \t]+|[ \t]+$/, "", c); if (NF >= 6 && c == "projet") { $3 = " projet "; $5 = " ailleurs " } print }' \
  "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
if ! grep -qE '^\| [^|]* \| projet \| [^|]* \| ailleurs \|' "$REGISTRY"; then
  fail "(b) fixture : la ligne modifiee est introuvable au registre"
else
  OUT="$(bash "$V/tools/check-project-conformity.sh" "$P" 2>&1)"
  if printf '%s' "$OUT" | grep -q "$GAP (projet)"; then
    pass "(b) chemin present seulement dans le nom affiche : l'ecart de registre est nomme"
  else
    fail "(b) chemin present seulement dans le nom affiche : aucun ecart de registre : $OUT"
  fi

  # --- (c) red witness: the script before the fix --------------------------------------------
  if git -C "$REPO_ROOT" cat-file -e 'fa54e9f^{commit}' 2>/dev/null; then
    git -C "$REPO_ROOT" show fa54e9f:tools/check-project-conformity.sh > "$V/tools/check-project-conformity-before.sh"
    OUT="$(bash "$V/tools/check-project-conformity-before.sh" "$P" 2>&1)"
    if printf '%s' "$OUT" | grep -q "$GAP"; then
      fail "(c) temoin rouge : l'ancien script nomme deja l'ecart : $OUT"
    else
      pass "(c) temoin rouge : l'ancien script ne nomme aucun ecart de registre sur (b)"
    fi
  else
    echo "  SKIP - (c) l'historique fa54e9f est absent de ce clone : temoin rouge non joue"
  fi
fi

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
