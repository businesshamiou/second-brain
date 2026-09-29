#!/usr/bin/env bash
# Mission 234, step 3: tools/check-workspace-root.sh compares the root of a
# workspace with the computed whitelist (rule on workspace hygiene §3). A
# throwaway workspace under the declared temporary folder, never the real one.
#
#   (a) a conforming root -- marker, Vault, a project, a group holding a
#       project, a declared organ, _trash, _archive, _orders -> CONFORME, exit 0;
#   (b) a stray file at the root -> ÉCART named, exit 1;
#   (c) a stray folder inside a group -> ÉCART <group>/<entry>;
#   (d) a provisional exception named by the marker -> EXCEPTION-PROVISOIRE,
#       not a gap, exit 0;
#   (e) witness: a folder that was tidied away comes back -> ÉCART;
#   (f) an organ removed from the marker line -> its folder becomes a gap;
#   (g) a folder without marker -> refused, exit 2;
#   (h) the Executor's session preflight calls the guardian as a warning.
#
# usage: bash tests/test-check-workspace-root.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$REPO_ROOT/tools/check-workspace-root.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

BASE="$(sb_tmp_dir tests)" || exit 1
TMP="$(mktemp -d "$BASE/m234-root-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
WS="$TMP/ws"
mkdir -p "$WS/vault/projects" "$WS/proj-a" "$WS/grp/proj-b" "$WS/m-publish" "$WS/_trash" "$WS/_archive" "$WS/_orders"

marker() { # marker <organs> <exceptions>
  cat > "$WS/VAULT-ROOT.md" <<EOF
# Test

Chemin relatif du Vault depuis cette racine de travail : \`vault\`

Identité du Vault : \`sb-test\`

Dossier temporaire déclaré : \`$BASE\`

Organes déclarés à cette racine : \`$1\`

Exceptions provisoires à cette racine : \`$2\`
EOF
}
marker "m-publish" "-"
cat > "$WS/vault/projects/PROJECT-REGISTRY.md" <<'EOF'
# PROJECT REGISTRY

| project_id | display_name | status | relative_path | vcs | conformity |
|---|---|---|---|---|---|
| 2026-09-26-PROJ-A | Proj A | ACTIVE | proj-a | git | CONFORME |
| 2026-09-26-PROJ-B | Proj B | ACTIVE | grp/proj-b | none | CONFORME |
EOF

echo "=== Mission 234 : gardien de la racine de l'espace ==="

OUT="$(bash "$TOOL" "$WS" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q '^VERDICT: CONFORME (0 ' && ! printf '%s\n' "$OUT" | grep -q '^ÉCART'; then
  pass "(a) racine conforme (Vault, projet, groupe, organe, _trash, _archive, _orders) : CONFORME, code 0"
else
  fail "(a) racine conforme non reconnue (rc=$RC) : $OUT"
fi

printf 'x\n' > "$WS/superseded-files.txt"
OUT="$(bash "$TOOL" "$WS" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -q '^ÉCART: superseded-files.txt — fichier'; then
  pass "(b) fichier parasite a la racine : ECART nomme, code 1"
else
  fail "(b) fichier parasite non signale (rc=$RC) : $OUT"
fi
mv "$WS/superseded-files.txt" "$TMP/"

mkdir -p "$WS/grp/stray"
OUT="$(bash "$TOOL" "$WS" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -q '^ÉCART: grp/stray — dans un dossier de groupe'; then
  pass "(c) dossier hors registre dans un groupe : ECART grp/stray"
else
  fail "(c) dossier parasite du groupe non signale (rc=$RC) : $OUT"
fi
mv "$WS/grp/stray" "$TMP/"

mkdir -p "$WS/workshops"
marker "m-publish" "workshops"
OUT="$(bash "$TOOL" "$WS" 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q '^EXCEPTION-PROVISOIRE: workshops' && printf '%s\n' "$OUT" | grep -q '^VERDICT: CONFORME (1 '; then
  pass "(d) exception provisoire nommee par le marqueur : EXCEPTION-PROVISOIRE, pas un ecart"
else
  fail "(d) exception provisoire mal traitee (rc=$RC) : $OUT"
fi

mkdir -p "$WS/skills-folder/runs"
OUT="$(bash "$TOOL" "$WS" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -q '^ÉCART: skills-folder — dossier'; then
  pass "(e) temoin : un dossier range qui revient est un ecart"
else
  fail "(e) retour d'un dossier range non signale (rc=$RC) : $OUT"
fi
mv "$WS/skills-folder" "$TMP/"

marker "-" "workshops"
OUT="$(bash "$TOOL" "$WS" 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -q '^ÉCART: m-publish'; then
  pass "(f) organe retire du marqueur : son dossier devient un ecart"
else
  fail "(f) organe non declare accepte (rc=$RC) : $OUT"
fi

# (i) Mission 235: the workspace guides CLAUDE.md and AGENTS.md, written by
# tools/write-marker.sh next to the marker, are admitted; another file is not.
printf 'guide\n' > "$WS/CLAUDE.md"; cp "$WS/CLAUDE.md" "$WS/AGENTS.md"; printf 'x\n' > "$WS/NOTES.md"
OUT="$(bash "$TOOL" "$WS" 2>&1)"; RC=$?
if printf '%s\n' "$OUT" | grep -q '^ÉCART: NOTES.md' && ! printf '%s\n' "$OUT" | grep -q '^ÉCART: CLAUDE.md\|^ÉCART: AGENTS.md'; then
  pass "(i) CLAUDE.md et AGENTS.md de l'espace (write-marker.sh) admis ; un autre fichier reste un ecart"
else
  fail "(i) guides de l'espace : rc=$RC : $OUT"
fi
mv "$WS/CLAUDE.md" "$WS/AGENTS.md" "$WS/NOTES.md" "$TMP/"

mkdir -p "$TMP/nomarker"
bash "$TOOL" "$TMP/nomarker" >/dev/null 2>&1; RC=$?
if [ "$RC" -eq 2 ]; then
  pass "(g) dossier sans marqueur : refuse, code 2"
else
  fail "(g) dossier sans marqueur : code $RC"
fi

if grep -q 'check-workspace-root.sh' "$REPO_ROOT/tools/session-preflight.sh" \
   && grep -q 'WARNINGS+=("racine de l' "$REPO_ROOT/tools/session-preflight.sh"; then
  pass "(h) le pre-vol de session appelle le gardien, en avertissement"
else
  fail "(h) le pre-vol de session n'appelle pas le gardien en avertissement"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
