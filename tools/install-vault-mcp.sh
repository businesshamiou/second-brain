#!/usr/bin/env bash
# Installs the Vault MCP server in the machine's tools (Decision
# 2026-09-17-000545, A6) -- called by the first-install skill, never by
# the installer (which writes nothing in the profile).
#
# Detects what is present -- `claude` (Claude Code), `codex`, the Claude desktop
# application (configuration folder measured, never assumed) -- and
# injects the server `second-brain-vault`:
#   - Claude Code: `claude mcp add -s user`;
#   - Codex      : `codex mcp add`;
#   - application: merge into claude_desktop_config.json (other servers
#                  and other keys kept).
# Idempotent: a server already configured identically is not touched again;
# a second run leaves the files byte for byte.
# Authorized folder = root of the workspace. Python is checked through uv.
# Remaining gesture printed: restart the application.
#
# usage: install-vault-mcp.sh <workspace-root> [--vault <root>] [--lang FR|EN|ES]

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE=""
LANGUAGE="EN"
SERVER="second-brain-vault"

while [ $# -gt 0 ]; do
  case "$1" in
    --vault)
      [ $# -ge 2 ] || { echo "usage: install-vault-mcp.sh <espace-de-travail> [--vault <racine>] [--lang FR|EN|ES]" >&2; exit 1; }
      VAULT_ROOT="$(cd "$2" && pwd)" || exit 1
      shift 2 ;;
    --lang)
      [ $# -ge 2 ] || { echo "usage: install-vault-mcp.sh <espace-de-travail> [--vault <racine>] [--lang FR|EN|ES]" >&2; exit 1; }
      LANGUAGE="$2"
      shift 2 ;;
    *)
      WORKSPACE="$1"
      shift ;;
  esac
done

if [ -z "$WORKSPACE" ] || [ ! -d "$WORKSPACE" ]; then
  echo "usage: install-vault-mcp.sh <espace-de-travail> [--vault <racine>] [--lang FR|EN|ES]" >&2
  echo "REFUS : espace de travail introuvable : ${WORKSPACE:-(vide)}" >&2
  exit 1
fi
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

HELPER="$VAULT_ROOT/tools/sb_installer_helper.py"
MCP_SCRIPT="$VAULT_ROOT/tools/vault-mcp.py"
CATALOG_FILE="$VAULT_ROOT/i18n/catalog.$(printf '%s' "$LANGUAGE" | tr '[:upper:]' '[:lower:]').json"
[ -f "$CATALOG_FILE" ] || CATALOG_FILE="$VAULT_ROOT/i18n/catalog.en.json"

UV="$(command -v uv || true)"
if [ -z "$UV" ]; then
  echo "REFUS : uv introuvable : le serveur MCP du Vault se lance par uv." >&2
  exit 1
fi

PYRUN() {
  "$UV" run --no-project "$HELPER" "$@"
}
CATALOG() {
  PYRUN format-catalog "$CATALOG_FILE" "$@"
}

# Path read by a native program (Windows form under Git Bash).
native() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

PY_VERSION="$("$UV" run --no-project python -c 'import sys; print(sys.version.split()[0])' 2>/dev/null | tr -d '\r')"
if [ -z "$PY_VERSION" ]; then
  CATALOG "vaultMcp.pythonMissing"
  exit 1
fi
CATALOG "vaultMcp.pythonOk" "$PY_VERSION"

UV_N="$(native "$UV")"
MCP_N="$(native "$MCP_SCRIPT")"
VAULT_N="$(native "$VAULT_ROOT")"
WS_N="$(native "$WORKSPACE")"

# same_entry <config>: 0 if the server is already configured identically there.
same_entry() {
  local current wanted
  [ -f "$1" ] || return 1
  current="$(PYRUN mcp-server-args "$1" "$SERVER" 2>/dev/null | tr -d '\r')" || return 1
  wanted="$(printf '%s\n' "$UV_N" run --no-project "$MCP_N" --vault "$VAULT_N" --allow "$WS_N")"
  [ "$current" = "$wanted" ]
}

DETECTED=0

# --- Claude Code: user configuration (~/.claude.json) ---------------
if command -v claude >/dev/null 2>&1; then
  DETECTED=1
  CATALOG "vaultMcp.detected" "Claude Code"
  if same_entry "$HOME/.claude.json"; then
    CATALOG "vaultMcp.alreadyPresent" "Claude Code"
  else
    claude mcp remove -s user "$SERVER" >/dev/null 2>&1 || true
    if claude mcp add -s user "$SERVER" -- "$UV_N" run --no-project "$MCP_N" --vault "$VAULT_N" --allow "$WS_N" >/dev/null 2>&1; then
      CATALOG "vaultMcp.added" "Claude Code" "$WS_N"
    else
      CATALOG "vaultMcp.failed" "Claude Code"
    fi
  fi
else
  CATALOG "vaultMcp.notDetected" "Claude Code"
fi

# --- Codex: ~/.codex/config.toml (or $CODEX_HOME) --------------------------
if command -v codex >/dev/null 2>&1; then
  DETECTED=1
  CATALOG "vaultMcp.detected" "Codex"
  CODEX_CONFIG="${CODEX_HOME:-$HOME/.codex}/config.toml"
  if same_entry "$CODEX_CONFIG"; then
    CATALOG "vaultMcp.alreadyPresent" "Codex"
  else
    codex mcp remove "$SERVER" >/dev/null 2>&1 || true
    if codex mcp add "$SERVER" -- "$UV_N" run --no-project "$MCP_N" --vault "$VAULT_N" --allow "$WS_N" >/dev/null 2>&1; then
      CATALOG "vaultMcp.added" "Codex" "$WS_N"
    else
      CATALOG "vaultMcp.failed" "Codex"
    fi
  fi
else
  CATALOG "vaultMcp.notDetected" "Codex"
fi

# --- Claude desktop application: measured configuration folders -------
to_unix() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$1"
  else
    printf '%s\n' "$1"
  fi
}
DESKTOP_DIRS=""
add_desktop_dir() {
  [ -d "$1" ] || return 0
  DESKTOP_DIRS="${DESKTOP_DIRS}${DESKTOP_DIRS:+
}$1"
}
case "$(uname -s 2>/dev/null)" in
  Darwin)
    add_desktop_dir "$HOME/Library/Application Support/Claude"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    [ -n "${APPDATA:-}" ] && add_desktop_dir "$(to_unix "$APPDATA")/Claude"
    if [ -n "${LOCALAPPDATA:-}" ]; then
      for d in "$(to_unix "$LOCALAPPDATA")"/Packages/Claude_*/LocalCache/Roaming/Claude; do
        add_desktop_dir "$d"
      done
    fi
    ;;
  *)
    add_desktop_dir "${XDG_CONFIG_HOME:-$HOME/.config}/Claude"
    ;;
esac

if [ -n "$DESKTOP_DIRS" ]; then
  DETECTED=1
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    CONFIG="$d/claude_desktop_config.json"
    CATALOG "vaultMcp.detected" "$(native "$CONFIG")"
    RESULT="$(PYRUN merge-mcp-json "$CONFIG" "$SERVER" "$UV_N" run --no-project "$MCP_N" --vault "$VAULT_N" --allow "$WS_N" | tr -d '\r')"
    case "$RESULT" in
      UNCHANGED) CATALOG "vaultMcp.alreadyPresent" "$(native "$CONFIG")" ;;
      UPDATED) CATALOG "vaultMcp.added" "$(native "$CONFIG")" "$WS_N" ;;
      *) CATALOG "vaultMcp.failed" "$(native "$CONFIG")" ;;
    esac
  done <<DESKTOP_EOF
$DESKTOP_DIRS
DESKTOP_EOF
else
  CATALOG "vaultMcp.notDetected" "Claude Desktop"
fi

if [ "$DETECTED" = "0" ]; then
  CATALOG "vaultMcp.nothingDetected"
else
  CATALOG "vaultMcp.restart"
fi
exit 0
