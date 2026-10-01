#!/usr/bin/env bash
# Mission 244 (capture 121525, findings 6, 7, 12): the Claude desktop application
# while it runs, the restart message, and the label committed.
#
# One throwaway Vault on a SIMULATED profile (HOME, USERPROFILE, APPDATA,
# LOCALAPPDATA redirected; `claude` and `codex` replaced by stand-ins at the head
# of the PATH), a SIMULATED process list (SB_TEST_PROCESS_LIST) and a stop log
# (SB_TEST_PROCESS_STOP_LOG) -- no real host configuration, no real process:
#   (1) the table tells the application from Claude Code by its path: of two
#       `claude` processes, only the application's is listed;
#   (2) application running, answer « n »: the warning (1), the question (1),
#       nothing ended (0), the file read back (1), the exact gesture to end it;
#   (3) answer « o »: the application's process alone is ended (the stop log
#       names it, never Claude Code's), then the file is written and read back;
#   (4) no terminal and no simulated answer: the question says « no », nothing
#       is ended;
#   (5) the restart message names the tools written and no longer says
#       « each tool detected above »;
#   (6) `sb install --mcp --label test`: VAULT-IDENTITY.md committed alone,
#       the Vault's porcelain 0;
#   (7) the default label of a workspace named second-brain-workspace is
#       `second-brain` (12), its longest tool name within 64.
#
# usage: bash tests/test-install-vault-mcp-desktop-running.sh
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

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
REAL_HOME="$HOME"
UV_PYTHON_INSTALL_DIR="$(uv python dir 2>/dev/null | tr -d '\r')"
UV_CACHE_DIR="$(uv cache dir 2>/dev/null | tr -d '\r')"
export UV_PYTHON_INSTALL_DIR UV_CACHE_DIR
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m244-desktop-XXXXXX")"
trap 'export HOME="$REAL_HOME"; [ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
N() { sandbox_native_path "$1"; }

WS="$TMP/second-brain-workspace"
V="$WS/second-brain"
mkdir -p "$WS"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
git -C "$V" add -A >/dev/null 2>&1; git -C "$V" commit -q -m "marker" >/dev/null 2>&1

# --- The simulated profile: the Claude application's folder is there. ---------------
PROFILE="$TMP/profile"
mkdir -p "$PROFILE/.codex" "$TMP/bin" "$PROFILE/AppData/Roaming/Claude" "$PROFILE/AppData/Local" "$PROFILE/.config/Claude" \
  "$PROFILE/Library/Application Support/Claude"
export HOME="$PROFILE"
export USERPROFILE="$(N "$PROFILE")"
export APPDATA="$(N "$PROFILE/AppData/Roaming")"
export LOCALAPPDATA="$(N "$PROFILE/AppData/Local")"
export XDG_CONFIG_HOME="$PROFILE/.config"
unset CODEX_HOME
printf '{}\n' > "$PROFILE/.claude.json"
: > "$PROFILE/.codex/config.toml"
for cfg in "$PROFILE/AppData/Roaming/Claude" "$PROFILE/.config/Claude" "$PROFILE/Library/Application Support/Claude"; do
  printf '{\n  "preferences": {"x": 1}\n}\n' > "$cfg/claude_desktop_config.json"
done
# claude and codex stand-ins: they log, never reach a real tool.
for tool in claude codex; do
  printf '#!/usr/bin/env bash\necho "%s $*" >> "%s/calls.log"\nexit 0\n' "$tool" "$TMP" > "$TMP/bin/$tool"
  chmod +x "$TMP/bin/$tool"
done
export PATH="$TMP/bin:$PATH"
for cmd in gemini cursor windsurf cline lms; do
  if command -v "$cmd" >/dev/null 2>&1; then echo "FAIL : $cmd est sur le PATH de ce poste ; le test suppose son absence"; exit 1; fi
done

# The simulated process list: the application, and Claude Code under the same name.
printf '4242\tC:\\Program Files\\WindowsApps\\Claude_2.1.0.0_x64__abcdefgh\\app\\Claude.exe\n5151\tC:\\Users\\x\\AppData\\Roaming\\Claude\\claude-code\\2.1.285\\claude.exe\n' > "$TMP/processes.tsv"
export SB_TEST_PROCESS_LIST="$(N "$TMP/processes.tsv")"
export SB_TEST_PROCESS_STOP_LOG="$(N "$TMP/stops.log")"
export SB_LANG=fr
SB="$V/tools/sb/bin/sb"

echo "=== Mission 244 : l'application Claude pendant l'installation du serveur ==="

OUT="$(bash -c ". '$V/tools/lib/mcp-hosts.sh'; mcp_desktop_running")"
check "(1) une seule ligne : l'application, jamais Claude Code" sh -c "[ \"\$(printf '%s\n' \"\$1\" | grep -c .)\" = 1 ] && printf '%s' \"\$1\" | grep -q '^4242'" _ "$OUT"

OUT="$(cd "$WS" && SB_TEST_TTY_ANSWER=n "$SB" install --mcp 2>&1 < /dev/null)"; RC=$?
check "(2) exit 0" test "$RC" = 0
check "(2) l'avertissement : l'application est ouverte" sh -c "printf '%s' \"\$1\" | grep -q \"L'application Claude est ouverte (1 processus)\"" _ "$OUT"
check "(2) la question posee, une fois" sh -c "[ \"\$(printf '%s\n' \"\$1\" | grep -c 'je la ferme pour que le serveur soit pris en compte')\" = 1 ]" _ "$OUT"
check "(2) « n » : rien arrete" test ! -s "$TMP/stops.log"
check "(2) le fichier relu : le serveur y est declare" sh -c "printf '%s' \"\$1\" | grep -q 'relu, le serveur second-brain-vault-second-brain y est déclaré'" _ "$OUT"
check "(2) le geste exact pour terminer l'application" sh -c "printf '%s' \"\$1\" | grep -Eq 'Options avancées → Terminer|Cmd\\+Q|Quitter'" _ "$OUT"
check "(5) le message de redemarrage nomme les outils ecrits" sh -c "printf '%s' \"\$1\" | grep -q 'Geste restant : redémarre .*Claude Desktop'" _ "$OUT"
check "(5) plus de « détecté ci-dessus »" sh -c "! printf '%s' \"\$1\" | grep -q 'ci-dessus (application Claude'" _ "$OUT"

OUT="$(cd "$WS" && SB_TEST_TTY_ANSWER=o "$SB" install --mcp 2>&1 < /dev/null)"; RC=$?
check "(3) « o » : exit 0" test "$RC" = 0
check "(3) seul le processus de l'application est arrete" sh -c "[ \"\$(cat '$TMP/stops.log')\" = 'stop 4242' ]"
check "(3) arret dit, puis ecriture et relecture" sh -c "printf '%s' \"\$1\" | grep -q 'Application Claude fermée' && printf '%s' \"\$1\" | grep -q 'relu, le serveur'" _ "$OUT"

: > "$TMP/stops.log"
OUT="$(cd "$WS" && "$SB" install --mcp 2>&1 < /dev/null)"; RC=$?
check "(4) sans terminal : la question repond non, rien arrete" sh -c "[ '$RC' = 0 ] && printf '%s' \"\$1\" | grep -q 'sans terminal : non' && [ ! -s '$TMP/stops.log' ]" _ "$OUT"

check "(7) libelle par defaut de second-brain-workspace : second-brain" test "$(bash "$V/tools/vault-identity.sh" get workspace_label "$V")" = "second-brain"
check "(7) nom d'outil le plus long <= 64" sh -c "[ \"\$(bash -c \". '$V/tools/lib/mcp-hosts.sh'; mcp_tool_name_length second-brain-vault-second-brain\")\" -le 64 ]"
check "(7) le libelle pose est commite, Vault propre" sh -c "[ \"\$(git -C '$V' status --porcelain | grep -c .)\" = 0 ] && git -C '$V' log -1 --format=%s -- VAULT-IDENTITY.md | grep -q 'Workspace label'"

BEFORE="$(git -C "$V" rev-list --count HEAD)"
OUT="$(cd "$WS" && "$SB" install --mcp --label test 2>&1 < /dev/null)"; RC=$?
check "(6) --label test : exit 0" test "$RC" = 0
check "(6) VAULT-IDENTITY.md commite seul, un commit" sh -c "[ \"\$(git -C '$V' rev-list --count HEAD)\" = $((BEFORE + 1)) ] && [ \"\$(git -C '$V' show --name-only --format= HEAD)\" = VAULT-IDENTITY.md ]"
check "(6) Vault : porcelain 0 apres --label" sh -c "[ \"\$(git -C '$V' status --porcelain | grep -c .)\" = 0 ]"

echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" -eq 0 ]
