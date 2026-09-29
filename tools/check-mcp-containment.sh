#!/usr/bin/env bash
# Containment check for the Vault's MCP server (Decision 2026-09-17-000545,
# A6): the project AND its Vault must lie under an allowed folder of THAT
# Vault's server -- `second-brain-vault-<workspace_label>`, or the first 8
# characters of vault_id when no label is recorded (vid_server_name, Decision
# 162812 A, which amends 152251 C), found through the Vault the project
# resolves to, never by a fixed name -- declared in a tool configuration
# (claude_desktop_config.json, ~/.claude.json, ~/.codex/config.toml). The
# server of another Vault does not count: FAIL naming the expected name.
#
# usage: check-mcp-containment.sh <configuration> <projet>
#        check-mcp-containment.sh --all <projet>
# Output: one PASS/FAIL line per path, then the verdict. Exit 0 = PASS,
# 1 = FAIL (including unreadable configuration, server absent, Vault not
# resolved). Read-only.
# --all (Mission 242): every configuration of a host PRESENT on this machine
# (tools/lib/mcp-hosts.sh: Claude Desktop, Claude Code, Codex, Gemini CLI,
# Cursor, Windsurf, Cline, LM Studio), each checked the same way, its lines
# prefixed by the host's name; an absent host is said, never a FAIL.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/resolve-vault.sh"
. "$SCRIPT_DIR/lib/mcp-hosts.sh"
HELPER="$SCRIPT_DIR/sb_installer_helper.py"

CONFIG="${1:-}"
PROJECT="${2:-}"
if [ -z "$CONFIG" ] || [ -z "$PROJECT" ]; then
  echo "usage: check-mcp-containment.sh <configuration> <projet> | --all <projet>" >&2
  exit 1
fi
if [ ! -d "$PROJECT" ]; then
  echo "FAIL projet introuvable : $PROJECT"
  echo "VERDICT: FAIL"
  exit 1
fi
PROJECT_ABS="$(cd "$PROJECT" && pwd -P)"

if ! resolve_vault "$PROJECT_ABS"; then
  echo "FAIL Vault non résolu : $RV_MESSAGE"
  echo "VERDICT: FAIL"
  exit 1
fi

native() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

SERVER="$(vid_server_name "$RV_VAULT" || true)"
if [ -z "$SERVER" ]; then
  echo "FAIL Vault sans identité générée : $(native "$RV_VAULT")/VAULT-IDENTITY.md"
  echo "VERDICT: FAIL"
  exit 1
fi

if [ "$CONFIG" = "--all" ]; then
  RC=0
  SEEN=0
  while IFS="$(printf '	')" read -r h_id h_name h_fmt h_cfg h_present; do
    [ -n "$h_id" ] || continue
    if [ "$h_present" != "1" ]; then
      echo "ABSENT $h_name"
      continue
    fi
    SEEN=1
    OUT="$(uv run --no-project "$HELPER" mcp-containment "$(native "$h_cfg")" "$SERVER" "$(native "$PROJECT_ABS")" "$(native "$RV_VAULT")")" || RC=1
    printf '%s
' "$OUT" | sed "s/^/$h_name: /"
  done <<HOSTS_EOF
$(mcp_hosts)
HOSTS_EOF
  [ "$SEEN" = 1 ] || { echo "FAIL aucun hôte présent"; RC=1; }
  if [ "$RC" -eq 0 ]; then echo "VERDICT: PASS"; exit 0; fi
  echo "VERDICT: FAIL"
  exit 1
fi

OUT="$(uv run --no-project "$HELPER" mcp-containment "$CONFIG" "$SERVER" "$(native "$PROJECT_ABS")" "$(native "$RV_VAULT")")"
RC=$?
printf '%s\n' "$OUT"
if [ "$RC" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
