#!/usr/bin/env bash
# Mission 244 (capture 121525, findings 4, 5, 13, 15, 20, 27): one line, then
# three gestures -- the installer's last screen, its starting profile, its
# language, on install.sh in --test-mode (nothing of the real profile touched:
# no sb install, no sb doctor, the clipboard simulated by SB_CLIPBOARD_FILE).
#
#   (A) French, the Claude path, questions 5, 6, 7 answered:
#       (1) standard output is the one verdict line;
#       (2) the step lines come from the French catalogue, no English Step: line;
#       (3) the last screen: three gestures, each starting with its place (the
#           Claude app, a terminal, a conversation); the welcome block on
#           the clipboard; Mission 245 (capture 105405, finding A3): the copy
#           command `sb pilot-prompt --accueil --copy` sits between « create the
#           Project » and « paste » (0 before, 1 after), and the clipboard line
#           no longer says it is enough;
#       (4) USER.md carries the starting-profile section with the three answers
#           (what I do, what matters to me, everyday tools);
#       (5) the Vault's porcelain is 0; Mission 245 (capture 105405, finding
#           C3): the workspace holds _orders/ and _archive/orders/, empty (0
#           before, 2 after), and its root guardian names no gap for them;
#   (B) English, the OpenAI path, questions 5 and 7 not answered:
#       (6) no hidden default: neither the former default sentence nor a
#           what-matters field; only the everyday-tools field;
#       (7) the gestures open Codex, said declared.
#
# usage: bash tests/test-install-final-screen.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }

sandbox_find_uv || { echo "FAIL: uv not found"; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m244-final-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
# The source: a clone of this repository's COMMITTED tree, like
# tests/test-install-leaves-vault-clean.sh -- a clone keeps the index modes (the
# execute bit of the guardians) that a copy of the working tree loses.
SOURCE="$TMP/source"
REF_CLONE="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL: reference clone not built"; exit 1; }
git clone --quiet -- "$REF_CLONE" "$SOURCE" >/dev/null 2>&1 || { echo "FAIL: source not built"; exit 1; }

answers() { # answers <file> <workspace> <language> <activity> <whatMatters> <aiTools json array>
  local extra=""
  [ -n "$4" ] && extra="$extra\"activity\": \"$4\", "
  [ -n "$5" ] && extra="$extra\"whatMatters\": \"$5\", "
  printf '{"language": "%s", "vaultName": "Brian", "workspacePath": "%s", "firstName": "Abde", %s"aiTools": %s, "firstProject": {"create": false}, "git": {"userName": "Second Brain Installer", "userEmail": "installer@example.invalid"}}\n' \
    "$3" "$2" "$extra" "$6" > "$1"
}

echo "=== Mission 244: one line, then three gestures ==="

# --- (A) French, the Claude path -----------------------------------------------------
RA="$TMP/a"
mkdir -p "$RA"
answers "$RA/answers.json" "$RA/workspace" FR "Media buyer freelance" "Des rapports clairs" '["claude-code", "claude-ai"]'
OUT="$(SB_CLIPBOARD_FILE="$RA/clipboard.txt" bash "$REPO_ROOT/install.sh" --source "$SOURCE" --answers-file "$RA/answers.json" \
  --test-mode --test-root "$RA" 2> "$RA/stderr.txt")"; RC=$?
ERR="$(cat "$RA/stderr.txt")"
check "(A) install.sh : exit 0" test "$RC" = 0
check "(1) standard output: the verdict line alone" sh -c "[ \"\$(printf '%s\n' \"\$1\" | grep -c .)\" = 1 ] && printf '%s' \"\$1\" | grep -q 'Installé, tout est en place'" _ "$OUT"
check "(2) step lines in French, no Step: line" sh -c "printf '%s' \"\$1\" | grep -q 'Étape : prérequis — OK' && printf '%s' \"\$1\" | grep -q 'Étape : clone — OK' && ! printf '%s' \"\$1\" | grep -q '^Step:'" _ "$ERR"
check "(3) three gestures, each with its place" sh -c "
  printf '%s' \"\$1\" | grep -q 'Installation terminée. Il reste trois gestes' &&
  printf '%s' \"\$1\" | grep -q \"^  1. Dans l'application Claude : crée un Project nommé « SB - Accueil »\" &&
  printf '%s' \"\$1\" | grep -q '^  2. Dans un terminal : sb pilot-prompt --accueil --copy, puis dans les instructions du Project : colle' &&
  printf '%s' \"\$1\" | grep -q '^  3. Dans une conversation de ce Project'" _ "$ERR"
check "(3) the welcome block on the (simulated) clipboard" sh -c "grep -q 'You are the welcome Pilot' '$RA/clipboard.txt' && grep -q 'français (fr)' '$RA/clipboard.txt'"
check "(3) the output names the clipboard" sh -c "printf '%s' \"\$1\" | grep -q 'est dans ton presse-papiers'" _ "$ERR"
check "(3) Mission 245 : --copy entre « crée un Project » et « colle »" sh -c "
  printf '%s\n' \"\$1\" | awk '/crée un Project nommé/ { p = NR } /sb pilot-prompt --accueil --copy/ && p && index(substr(\$0, index(\$0, \"--copy\")), \"colle\") { ok = 1 } END { exit !ok }'" _ "$ERR"
check "(3) Mission 245 : la copie de fin n'est plus dite suffisante" sh -c "printf '%s' \"\$1\" | grep -q 'le geste 2 le recopie'" _ "$ERR"
U="$RA/workspace/second-brain/USER.md"
check "(4) the starting profile section: the three answers" sh -c "
  grep -qx '## Profil de départ' '$U' &&
  grep -q '^- \\*\\*Ce que je fais :\\*\\* Media buyer freelance' '$U' &&
  grep -q '^- \\*\\*Ce qui compte pour moi :\\*\\* Des rapports clairs' '$U' &&
  grep -q '^- \\*\\*Outils du quotidien :\\*\\* claude-code, claude-ai' '$U'"
check "(4) USER.md with LF line ends" sh -c "! grep -q \$'\\r' '$U'"
check "(5) Vault: porcelain 0" sh -c "[ \"\$(git -C '$RA/workspace/second-brain' status --porcelain | grep -c .)\" = 0 ]"
N_ORDERS="$(for d in _orders _archive/orders; do [ -d "$RA/workspace/$d" ] && echo "$d"; done | grep -c .)"
check "(5) Mission 245: _orders/ and _archive/orders/ made by the installer ($N_ORDERS/2), empty" sh -c "
  [ '$N_ORDERS' = 2 ] && [ -z \"\$(ls -A '$RA/workspace/_orders')\" ] && [ -z \"\$(ls -A '$RA/workspace/_archive/orders')\" ]"
check "(5) Mission 245: the root guardian names no gap for them" sh -c "
  ! bash '$RA/workspace/second-brain/tools/check-workspace-root.sh' '$RA/workspace' 2>&1 | grep -E '^(ÉCART|ECART)' | grep -q '_orders\|_archive'"

# --- (B) English, the OpenAI path, 5 and 7 not answered ---------------------------------
RB="$TMP/b"
mkdir -p "$RB"
answers "$RB/answers.json" "$RB/workspace" EN "" "" '["codex"]'
OUT="$(SB_CLIPBOARD_FILE="$RB/clipboard.txt" bash "$REPO_ROOT/install.sh" --source "$SOURCE" --answers-file "$RB/answers.json" \
  --test-mode --test-root "$RB" 2> "$RB/stderr.txt")"; RC=$?
ERR="$(cat "$RB/stderr.txt")"
U="$RB/workspace/second-brain/USER.md"
check "(B) install.sh : exit 0" test "$RC" = 0
check "(6) no hidden default: no simplicity, no what-matters field" sh -c "! grep -qi 'simplicity\\|simplicité' '$U' && ! grep -q 'Ce qui compte pour moi' '$U' && ! grep -q 'Ce que je fais' '$U'"
check "(6) only the field answered: everyday tools = codex" sh -c "grep -q '^- \\*\\*Outils du quotidien :\\*\\* codex' '$U'"
check "(7) the OpenAI path: Codex, said declared" sh -c "printf '%s' \"\$1\" | grep -q '^  1. In the terminal: go to .*, then run codex' && printf '%s' \"\$1\" | grep -q 'declared'" _ "$ERR"
check "(7) Mission 245: the copy just before the paste into Codex" sh -c "printf '%s' \"\$1\" | grep -q '^  2. In a terminal: sb pilot-prompt --accueil --copy, then in Codex, first message: paste'" _ "$ERR"

echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" -eq 0 ]
