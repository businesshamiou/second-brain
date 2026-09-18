#!/usr/bin/env bash
# Installs the Vault MCP server in the machine's tools (Decision
# 2026-09-17-000545, A6) -- called by the first-install skill, never by
# the installer (which writes nothing in the profile).
#
# Detects what is present -- `claude` (Claude Code), `codex`, the Claude desktop
# application (configuration folder measured, never assumed) -- and
# injects THIS Vault's server, named after its identity (Decision 152251 C,
# Mission 191-C01): `second-brain-vault-<8 characters of vault_id>`, read
# from VAULT-IDENTITY.md by tools/vault-identity.sh, never from a path. Two
# Vaults on one machine therefore declare two servers side by side:
#   - Claude Code: `claude mcp add -s user`;
#   - Codex      : `codex mcp add`;
#   - application: merge into claude_desktop_config.json (other servers
#                  and other keys kept).
# Idempotent: a server already configured identically is not touched again;
# a second run leaves the files byte for byte.
# Never replaces another Vault's server: a server of this name that points
# to a Vault with another identity is refused, naming both, and that
# configuration is left untouched (exit 1 at the end). The former fixed name
# `second-brain-vault` (up to v0.1.7) is migrated when it points to THIS
# Vault (removed, replaced by the new name), left as it is otherwise.
# Authorized folder = root of the workspace. Python is checked through uv.
# Remaining gesture printed: restart the application.
#
# usage: install-vault-mcp.sh <workspace-root> [--vault <root>] [--lang FR|EN|ES]

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE=""
LANGUAGE="EN"
LEGACY_SERVER="second-brain-vault"
. "$SCRIPT_DIR/vault-identity.sh"

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

# Name of THIS Vault's server, from its identity (read after --vault).
SERVER="$(vid_server_name "$VAULT_ROOT" || true)"
MY_ID="$(vid_get "$VAULT_ROOT" vault_id)"

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

if [ -z "$SERVER" ]; then
  CATALOG "vaultMcp.noIdentity" "$(native "$VAULT_ROOT/VAULT-IDENTITY.md")"
  exit 1
fi

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

# entry_vault <config> <name>: the --vault argument of a declared server,
# in the shell's form; empty if the server is absent.
entry_vault() {
  local args v
  [ -f "$1" ] || return 0
  args="$(PYRUN mcp-server-args "$1" "$2" 2>/dev/null | tr -d '\r')" || return 0
  v="$(printf '%s\n' "$args" | awk 'prev == "--vault" { print; exit } { prev = $0 }')"
  [ -n "$v" ] || return 0
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$v"
  else
    printf '%s\n' "$v"
  fi
}

# cross_identity <label> <config>: 0 (refused, message printed) if a server
# of THIS name points to a Vault that carries another identity. A Vault path
# that no longer exists or has no identity is this Vault's own stale entry:
# it is replaced as usual.
REFUSED=0
cross_identity() {
  local v other
  v="$(entry_vault "$2" "$SERVER")"
  [ -n "$v" ] || return 1
  other="$(vid_get "$v" vault_id)"
  [ -n "$other" ] || return 1
  [ "$other" = "$MY_ID" ] && return 1
  CATALOG "vaultMcp.crossIdentity" "$1" "$SERVER" "$(native "$v")" "$other" "$MY_ID"
  REFUSED=1
  return 0
}

# legacy_points_here <config>: 0 if the former fixed-name server points to
# THIS Vault (same identity, or same folder); 1 otherwise. Sets LEGACY_VAULT.
LEGACY_VAULT=""
legacy_points_here() {
  local other
  LEGACY_VAULT="$(entry_vault "$1" "$LEGACY_SERVER")"
  [ -n "$LEGACY_VAULT" ] || return 1
  other="$(vid_get "$LEGACY_VAULT" vault_id)"
  if [ -n "$other" ] && [ "$other" = "$MY_ID" ]; then
    return 0
  fi
  [ "$(cd "$LEGACY_VAULT" 2>/dev/null && pwd -P)" = "$(cd "$VAULT_ROOT" && pwd -P)" ]
}

DETECTED=0

# --- Claude Code: user configuration (~/.claude.json) ---------------
if command -v claude >/dev/null 2>&1; then
  DETECTED=1
  CATALOG "vaultMcp.detected" "Claude Code"
  if ! cross_identity "Claude Code" "$HOME/.claude.json"; then
    if legacy_points_here "$HOME/.claude.json"; then
      claude mcp remove -s user "$LEGACY_SERVER" >/dev/null 2>&1 || true
      CATALOG "vaultMcp.legacyMigrated" "Claude Code" "$SERVER"
    elif [ -n "$LEGACY_VAULT" ]; then
      CATALOG "vaultMcp.legacyOtherVault" "Claude Code" "$(native "$LEGACY_VAULT")"
    fi
    if same_entry "$HOME/.claude.json"; then
      CATALOG "vaultMcp.alreadyPresent" "Claude Code" "$SERVER"
    else
      claude mcp remove -s user "$SERVER" >/dev/null 2>&1 || true
      if claude mcp add -s user "$SERVER" -- "$UV_N" run --no-project "$MCP_N" --vault "$VAULT_N" --allow "$WS_N" >/dev/null 2>&1; then
        CATALOG "vaultMcp.added" "Claude Code" "$WS_N" "$SERVER"
      else
        CATALOG "vaultMcp.failed" "Claude Code"
      fi
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
  if ! cross_identity "Codex" "$CODEX_CONFIG"; then
    if legacy_points_here "$CODEX_CONFIG"; then
      codex mcp remove "$LEGACY_SERVER" >/dev/null 2>&1 || true
      CATALOG "vaultMcp.legacyMigrated" "Codex" "$SERVER"
    elif [ -n "$LEGACY_VAULT" ]; then
      CATALOG "vaultMcp.legacyOtherVault" "Codex" "$(native "$LEGACY_VAULT")"
    fi
    if same_entry "$CODEX_CONFIG"; then
      CATALOG "vaultMcp.alreadyPresent" "Codex" "$SERVER"
    else
      codex mcp remove "$SERVER" >/dev/null 2>&1 || true
      if codex mcp add "$SERVER" -- "$UV_N" run --no-project "$MCP_N" --vault "$VAULT_N" --allow "$WS_N" >/dev/null 2>&1; then
        CATALOG "vaultMcp.added" "Codex" "$WS_N" "$SERVER"
      else
        CATALOG "vaultMcp.failed" "Codex"
      fi
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
    cross_identity "$(native "$CONFIG")" "$CONFIG" && continue
    if legacy_points_here "$CONFIG"; then
      PYRUN remove-mcp-json "$CONFIG" "$LEGACY_SERVER" >/dev/null
      CATALOG "vaultMcp.legacyMigrated" "$(native "$CONFIG")" "$SERVER"
    elif [ -n "$LEGACY_VAULT" ]; then
      CATALOG "vaultMcp.legacyOtherVault" "$(native "$CONFIG")" "$(native "$LEGACY_VAULT")"
    fi
    RESULT="$(PYRUN merge-mcp-json "$CONFIG" "$SERVER" "$UV_N" run --no-project "$MCP_N" --vault "$VAULT_N" --allow "$WS_N" | tr -d '\r')"
    case "$RESULT" in
      UNCHANGED) CATALOG "vaultMcp.alreadyPresent" "$(native "$CONFIG")" "$SERVER" ;;
      UPDATED) CATALOG "vaultMcp.added" "$(native "$CONFIG")" "$WS_N" "$SERVER" ;;
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
[ "$REFUSED" = "1" ] && exit 1
exit 0
