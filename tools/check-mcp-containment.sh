#!/usr/bin/env bash
# Containment check for the Vault's MCP server (Decision 2026-09-17-000545,
# A6): the project AND its Vault must lie under an allowed folder of THAT
# Vault's server -- `second-brain-vault-<8 characters of vault_id>`, found by
# the identity of the Vault the project resolves to (Decision 152251 C,
# Mission 191-C01), never by a fixed name -- declared in a tool configuration
# (claude_desktop_config.json, ~/.claude.json, ~/.codex/config.toml). The
# server of another Vault does not count: FAIL naming the expected name.
#
# usage: check-mcp-containment.sh <configuration> <projet>
# Output: one PASS/FAIL line per path, then the verdict. Exit 0 = PASS,
# 1 = FAIL (including unreadable configuration, server absent, Vault not
# resolved). Read-only.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/resolve-vault.sh"
HELPER="$SCRIPT_DIR/sb_installer_helper.py"

CONFIG="${1:-}"
PROJECT="${2:-}"
if [ -z "$CONFIG" ] || [ -z "$PROJECT" ]; then
  echo "usage: check-mcp-containment.sh <configuration> <projet>" >&2
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

OUT="$(uv run --no-project "$HELPER" mcp-containment "$CONFIG" "$SERVER" "$(native "$PROJECT_ABS")" "$(native "$RV_VAULT")")"
RC=$?
printf '%s\n' "$OUT"
if [ "$RC" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
