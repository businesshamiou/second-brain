#!/usr/bin/env bash
# Mission 244 (capture 121525, findings 17, 18, 19): `sb profile --order`
# commits USER.md on its own, with LF line ends, and speaks the reader's
# language when it refuses.
#
# Oracle, on a throwaway workspace built from the working tree:
#   (1) an installed profile (byte-order mark, CRLF, as PowerShell 5.1 wrote
#       it), committed; `sb profile --order` applies the order, commits USER.md
#       alone (one commit, the only file in it), porcelain 0 in the Vault;
#   (2) the committed USER.md has LF line ends and keeps its byte-order mark;
#       Git gives no « CRLF will be replaced » warning at that commit;
#   (3) in French, an order that does not exist is refused in French
#       (« ordre introuvable »), exit 1, and no English « REFUSED order not
#       found » reaches the reader; the same in Spanish.
#
# usage: bash tests/test-sb-profile-commit.sh [<source repo>]
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
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m244-profile-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"
mkdir -p "$WS/_orders"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
SB="$V/tools/sb/bin/sb"

echo "=== Mission 244 : sb profile --order commite USER.md seul ($SRC) ==="

{
  printf '\xef\xbb\xbf'
  printf -- '---\r\ntype: profile\r\ntitle: "Fiche utilisateur — Abde"\r\ndescription: "Rédigée par le questionnaire."\r\nstatus: active\r\nlanguage: fr\r\n---\r\n\r\n# FICHE UTILISATEUR\r\n\r\n## Qui\r\n\r\n- **Prénom :** Abde\r\n\r\n## Liens\r\n\r\n- `see also` — [AGENTS.md](./AGENTS.md)\r\n'
} > "$V/USER.md"
(cd "$V" && bash tools/build-indexes.sh "$V" >/dev/null 2>&1)
git -C "$V" add -A >/dev/null 2>&1
git -C "$V" commit -q -m "installed profile" >/dev/null 2>&1
BEFORE="$(git -C "$V" rev-list --count HEAD)"

O="$WS/_orders/PROFILE-2026-09-30-111500.md"
{
  echo "Session Executor — profil de départ"
  echo ""
  echo "Ordre de profil"
  echo "- Ce que je fais : media buyer freelance"
  echo "- Ce qui compte pour moi : des rapports clairs"
  echo "- Outils du quotidien : Meta Ads, Sheets"
  echo "- Autorisation Owner datée : oui, c'est mon profil, 2026-09-30"
} > "$O"
OUT="$(cd "$WS" && SB_LANG=fr "$SB" profile --order "$O" 2>&1)"; RC=$?
check "(1) sb profile --order : exit 0" test "$RC" = 0
check "(1) un commit de plus, USER.md seul dedans" sh -c "[ \"\$(git -C '$V' rev-list --count HEAD)\" = $((BEFORE + 1)) ] && [ \"\$(git -C '$V' show --name-only --format= HEAD)\" = USER.md ]"
check "(1) Vault : porcelain 0" sh -c "[ \"\$(git -C '$V' status --porcelain | grep -c .)\" = 0 ]"
check "(1) la sortie dit le commit, en francais" sh -c "printf '%s' \"\$1\" | grep -q 'USER.md commité seul'" _ "$OUT"
check "(2) USER.md en fins de ligne LF, sa marque d'ordre gardee" sh -c "! grep -q \$'\\r' '$V/USER.md' && [ \"\$(head -c 3 '$V/USER.md' | od -An -tx1 | tr -d ' ')\" = efbbbf ]"
check "(2) aucun avertissement CRLF montre" sh -c "! printf '%s' \"\$1\" | grep -q 'CRLF'" _ "$OUT"
check "(2) la section ecrite porte les trois champs" sh -c "grep -q 'Ce que je fais :\\*\\* media buyer freelance' '$V/USER.md' && grep -q 'Outils du quotidien :\\*\\* Meta Ads, Sheets' '$V/USER.md'"

OUT="$(cd "$WS" && SB_LANG=fr "$SB" profile --order "$WS/_orders/PROFILE-absent.md" 2>&1)"; RC=$?
check "(3) ordre absent (fr) : exit 1" test "$RC" = 1
check "(3) refus en francais : « REFUS : ordre introuvable »" sh -c "printf '%s' \"\$1\" | grep -q 'REFUS : ordre introuvable'" _ "$OUT"
check "(3) aucune chaine anglaise « REFUSED order not found »" sh -c "! printf '%s' \"\$1\" | grep -qi 'order not found'" _ "$OUT"
OUT="$(cd "$WS" && SB_LANG=es "$SB" profile --order "$WS/_orders/PROFILE-absent.md" 2>&1)"
check "(3) refus en espagnol : « orden no encontrada »" sh -c "printf '%s' \"\$1\" | grep -q 'orden no encontrada'" _ "$OUT"

echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" -eq 0 ]
