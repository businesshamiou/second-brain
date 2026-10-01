#!/usr/bin/env bash
# Mission 244 (capture 121525, findings 1, 27, 28; trap h): `sb` from outside
# any workspace, and the Pilot's block delivered without a terminal selection.
#
# Oracle, on two throwaway workspaces built from the working tree:
#   (1) from a folder outside any workspace (a PowerShell opens in system32),
#       `sb doctor` gives the report of its own Vault's workspace -- exit 0, one
#       line saying so -- instead of a refusal;
#   (2) `sb pilot-prompt --accueil` does the same; `sb pilot-prompt <folder>`
#       with a bare folder name finds the project in the workspace;
#   (3) a verb that needs a project (`sb open`) still refuses there (exit 3);
#   (4) from inside ANOTHER workspace, sb never serves its own: refused (exit 3);
#   (5) `sb pilot-prompt <folder> --copy` puts the block between the two lines
#       on the clipboard (simulated) byte for byte; `--out <file>` writes it;
#       without a terminal and without --copy, the command to copy is named.
#
# usage: bash tests/test-sb-outside-workspace.sh [<source repo>]
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
check() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m244-outside-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"
mkdir -p "$WS" "$TMP/outside" "$TMP/other"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
bash "$V/tools/project-bootstrap.sh" create "$WS/rapports" "Rapports" EN --vcs none >/dev/null 2>&1 || { echo "FAIL : projet"; exit 1; }
# A second workspace: its own marker, its own (copied) Vault.
sandbox_vault "$SRC" "$TMP/other/vault" >/dev/null 2>&1 && bash "$TMP/other/vault/tools/write-marker.sh" "$TMP/other" >/dev/null 2>&1
export SB_LANG=en
SB="$V/tools/sb/bin/sb"

echo "=== Mission 244 : sb hors de tout espace, et le bloc sans selection ==="

OUT="$(cd "$TMP/outside" && "$SB" doctor 2>&1)"; RC=$?
check "(1) sb doctor hors espace : exit 0 (bilan, plus de refus)" test "$RC" = 0
check "(1) une ligne le dit, avec l'espace de son Vault" sh -c "printf '%s' \"\$1\" | grep -q 'Outside any workspace: sb works in its Vault' && printf '%s' \"\$1\" | grep -q 'Second Brain'" _ "$OUT"
OUT="$(cd "$TMP/outside" && "$SB" pilot-prompt --accueil 2>&1 < /dev/null)"; RC=$?
check "(2) pilot-prompt --accueil hors espace : exit 0, le bloc d'accueil" sh -c "[ '$RC' = 0 ] && printf '%s' \"\$1\" | grep -q 'You are the welcome Pilot'" _ "$OUT"
OUT="$(cd "$TMP/outside" && "$SB" pilot-prompt rapports 2>&1 < /dev/null)"; RC=$?
check "(2) pilot-prompt rapports (nom nu) hors espace : le projet trouve" sh -c "[ '$RC' = 0 ] && printf '%s' \"\$1\" | grep -q 'SB - Rapports'" _ "$OUT"
OUT="$(cd "$TMP/outside" && "$SB" open 2>&1)"; RC=$?
check "(3) sb open hors espace : toujours refuse (exit 3)" test "$RC" = 3
OUT="$(cd "$TMP/other" && "$SB" doctor 2>&1)"; RC=$?
check "(4) dans un autre espace : refuse (exit 3), jamais servi" sh -c "[ '$RC' = 3 ] && printf '%s' \"\$1\" | grep -q 'another Second Brain workspace'" _ "$OUT"

export SB_CLIPBOARD_FILE="$TMP/clipboard.txt"
OUT="$(cd "$WS/rapports" && "$SB" pilot-prompt --copy --out "$TMP/block.txt" 2>&1 < /dev/null)"; RC=$?
printf '%s\n' "$OUT" | tr -d '\r' | awk '/^---$/ { n++; next } n == 1 { print }' > "$TMP/printed.txt"
check "(5) --copy : exit 0, le presse-papiers recoit le bloc imprime, a l'octet" sh -c "[ '$RC' = 0 ] && cmp -s '$TMP/printed.txt' '$TMP/clipboard.txt'"
check "(5) --out : le fichier recoit le meme bloc" cmp -s "$TMP/printed.txt" "$TMP/block.txt"
check "(5) la sortie dit le presse-papiers et le fichier" sh -c "printf '%s' \"\$1\" | grep -q 'The block is on your clipboard' && printf '%s' \"\$1\" | grep -q 'Block written to'" _ "$OUT"
unset SB_CLIPBOARD_FILE
OUT="$(cd "$WS/rapports" && "$SB" pilot-prompt 2>&1 < /dev/null)"
check "(5) sans terminal ni --copy : la commande a taper est nommee" sh -c "printf '%s' \"\$1\" | grep -q 'add --copy'" _ "$OUT"

echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" -eq 0 ]
