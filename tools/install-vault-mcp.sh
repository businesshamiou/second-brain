#!/usr/bin/env bash
# Installs the Vault MCP server in the machine's tools (Decision
# 2026-09-17-000545, A6) -- called by the first-install skill, never by
# the installer (which writes nothing in the profile).
#
# Detects what is present -- `claude` (Claude Code), `codex`, the Claude desktop
# application (configuration folder measured, never assumed) -- and
# injects THIS Vault's server, named after its WORKSPACE (Decision 162812 A-B,
# Mission 206, which amends 152251 C): `second-brain-vault-<workspace_label>`, the
# label being the normalised name of the workspace folder, posed in
# VAULT-IDENTITY.md by this installer (the label already there wins; `--label` sets
# another). Without a label the name is by identity, `second-brain-vault-<8
# characters of vault_id>` -- the identity stays what the system checks, the label is
# what the Owner reads. Both are read by tools/vault-identity.sh, never from a path.
#   - Claude Code: `claude mcp add -s user`;
#   - Codex      : `codex mcp add`;
#   - application: merge into claude_desktop_config.json (other servers
#                  and other keys kept).
# Idempotent: a server already configured identically is not touched again;
# a second run leaves the files byte for byte.
# Never replaces another Vault's server: a server of this name that points
# to a Vault with another identity is refused, naming both, the suffixed name
# proposed (`second-brain-vault-<label>-<8 characters>`, accepted with `--label`),
# and NOTHING is written -- neither the identity nor any configuration (exit 1).
# The former names of THIS Vault are migrated when they point to it (removed,
# replaced by the new name), left as they are otherwise: the fixed name
# `second-brain-vault` (up to v0.1.7), the name by identity, the name under a
# former label.
# `--retire <key>` removes a generic server (`workshops`) from the configurations that
# hold it, citing what it was; a key that starts with `second-brain-vault` is a Vault's
# server and is never retired. `--skip-desktop` leaves the application's configuration
# as it is (Mission 206-C02, D0: an application that rewrites its own file).
# Authorized folder = root of the workspace. Python is checked through uv.
# Remaining gesture printed: restart the application.
#
# usage: install-vault-mcp.sh <workspace-root> [--vault <root>] [--lang FR|EN|ES]
#          [--label <label>] [--retire <key>]... [--skip-desktop]

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE=""
LANGUAGE="EN"
LEGACY_SERVER="second-brain-vault"
LABEL_OPT=""
RETIRE_KEYS=""
SKIP_DESKTOP=0
. "$SCRIPT_DIR/vault-identity.sh"

USAGE="usage: install-vault-mcp.sh <espace-de-travail> [--vault <racine>] [--lang FR|EN|ES] [--label <libelle>] [--retire <cle>]... [--skip-desktop]"
while [ $# -gt 0 ]; do
  case "$1" in
    --vault)
      [ $# -ge 2 ] || { echo "$USAGE" >&2; exit 1; }
      VAULT_ROOT="$(cd "$2" && pwd)" || exit 1
      shift 2 ;;
    --lang)
      [ $# -ge 2 ] || { echo "$USAGE" >&2; exit 1; }
      LANGUAGE="$2"
      shift 2 ;;
    --label)
      [ $# -ge 2 ] || { echo "$USAGE" >&2; exit 1; }
      LABEL_OPT="$2"
      shift 2 ;;
    --retire)
      [ $# -ge 2 ] || { echo "$USAGE" >&2; exit 1; }
      RETIRE_KEYS="${RETIRE_KEYS}${RETIRE_KEYS:+
}$2"
      shift 2 ;;
    --skip-desktop)
      SKIP_DESKTOP=1
      shift ;;
    *)
      WORKSPACE="$1"
      shift ;;
  esac
done

if [ -z "$WORKSPACE" ] || [ ! -d "$WORKSPACE" ]; then
  echo "$USAGE" >&2
  echo "REFUS : espace de travail introuvable : ${WORKSPACE:-(vide)}" >&2
  exit 1
fi
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

HELPER="$VAULT_ROOT/tools/sb_installer_helper.py"
MCP_SCRIPT="$VAULT_ROOT/tools/vault-mcp.py"
CATALOG_FILE="$VAULT_ROOT/i18n/catalog.$(printf '%s' "$LANGUAGE" | tr '[:upper:]' '[:lower:]').json"
[ -f "$CATALOG_FILE" ] || CATALOG_FILE="$VAULT_ROOT/i18n/catalog.en.json"

# Name of THIS Vault's server (read after --vault): by workspace label, else by
# identity. The label: --label, else the one already in VAULT-IDENTITY.md (the name
# stays stable from one run to the next), else the name of the workspace folder.
ID_NAME="$(vid_identity_name "$VAULT_ROOT" || true)"
MY_ID="$(vid_get "$VAULT_ROOT" vault_id)"
LABEL_CUR="$(vid_label_normalize "$(vid_get "$VAULT_ROOT" workspace_label)")"
if [ -n "$LABEL_OPT" ]; then
  LABEL="$(vid_label_normalize "$LABEL_OPT")"
  if [ -z "$LABEL" ]; then
    echo "REFUS : libelle vide apres normalisation : $LABEL_OPT" >&2
    exit 1
  fi
elif [ -n "$LABEL_CUR" ]; then
  LABEL="$LABEL_CUR"
else
  LABEL="$(vid_label_normalize "$(basename "$WORKSPACE")")"
fi
if [ -z "$ID_NAME" ]; then
  SERVER=""
elif [ -n "$LABEL" ]; then
  SERVER="$VID_SERVER_PREFIX-$LABEL"
else
  SERVER="$ID_NAME"
fi
# The names this Vault may have carried before: migrated when they point to it.
PREVIOUS_LABEL_NAME=""
[ -n "$LABEL_CUR" ] && [ "$LABEL_CUR" != "$LABEL" ] && PREVIOUS_LABEL_NAME="$VID_SERVER_PREFIX-$LABEL_CUR"

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

# legacy_points_here <config> <name>: 0 if the server of a former name points to
# THIS Vault (same identity, or same folder); 1 otherwise. Sets LEGACY_VAULT.
LEGACY_VAULT=""
legacy_points_here() {
  local other
  LEGACY_VAULT="$(entry_vault "$1" "$2")"
  [ -n "$LEGACY_VAULT" ] || return 1
  other="$(vid_get "$LEGACY_VAULT" vault_id)"
  if [ -n "$other" ] && [ "$other" = "$MY_ID" ]; then
    return 0
  fi
  [ "$(cd "$LEGACY_VAULT" 2>/dev/null && pwd -P)" = "$(cd "$VAULT_ROOT" && pwd -P)" ]
}

# remove_entry <kind: claude|codex|desktop> <config> <name>
remove_entry() {
  case "$1" in
    claude) claude mcp remove -s user "$3" >/dev/null 2>&1 || true ;;
    codex) codex mcp remove "$3" >/dev/null 2>&1 || true ;;
    desktop) PYRUN remove-mcp-json "$2" "$3" >/dev/null ;;
  esac
}

# former_names: the names to migrate, one per line, never the current one.
former_names() {
  local n
  for n in "$LEGACY_SERVER" "$ID_NAME" "$PREVIOUS_LABEL_NAME"; do
    [ -n "$n" ] && [ "$n" != "$SERVER" ] && printf '%s\n' "$n"
  done
}

# migrate_former <shown name> <kind> <config>: removes each former name of THIS
# Vault from one configuration, saying so; a former fixed name that points to
# another Vault is left as it is, and said.
migrate_former() {
  local shown="$1" kind="$2" cfg="$3" name
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if legacy_points_here "$cfg" "$name"; then
      remove_entry "$kind" "$cfg" "$name"
      if [ "$name" = "$LEGACY_SERVER" ]; then
        CATALOG "vaultMcp.legacyMigrated" "$shown" "$SERVER"
      else
        CATALOG "vaultMcp.renamedMigrated" "$shown" "$name" "$SERVER"
      fi
    elif [ "$name" = "$LEGACY_SERVER" ] && [ -n "$LEGACY_VAULT" ]; then
      CATALOG "vaultMcp.legacyOtherVault" "$shown" "$(native "$LEGACY_VAULT")"
    fi
  done <<FORMER_EOF
$(former_names)
FORMER_EOF
}

# retire_keys <shown name> <kind> <config>: --retire, one configuration. The entry is
# cited (command and arguments) before it goes; an absent key is not an event.
retire_keys() {
  local shown="$1" kind="$2" cfg="$3" key cur
  [ -n "$RETIRE_KEYS" ] || return 0
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    [ -f "$cfg" ] || continue
    cur="$(PYRUN mcp-server-args "$cfg" "$key" 2>/dev/null | tr -d '\r' | tr '\n' ' ')"
    [ -n "$cur" ] || continue
    remove_entry "$kind" "$cfg" "$key"
    CATALOG "vaultMcp.retired" "$shown" "$key" "$cur"
  done <<RETIRE_EOF
$RETIRE_KEYS
RETIRE_EOF
}

# The configurations, measured once: what the pre-pass checks and what the blocks write.
to_unix() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$1"
  else
    printf '%s\n' "$1"
  fi
}
HAVE_CLAUDE=0; command -v claude >/dev/null 2>&1 && HAVE_CLAUDE=1
HAVE_CODEX=0; command -v codex >/dev/null 2>&1 && HAVE_CODEX=1
CODEX_CONFIG="${CODEX_HOME:-$HOME/.codex}/config.toml"
DESKTOP_DIRS=""
add_desktop_dir() {
  [ -d "$1" ] || return 0
  DESKTOP_DIRS="${DESKTOP_DIRS}${DESKTOP_DIRS:+
}$1"
}
if [ "$SKIP_DESKTOP" = "0" ]; then
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
fi

# --- Pre-pass: refusals BEFORE any write (Mission 206, P3) --------------------------
# A key that is a Vault's server is never retired. A server of this very name that
# points to another Vault is refused in every configuration at once: the second Vault
# of a same label writes nothing -- not its label, not a configuration -- and the
# suffixed name is proposed. Two Vaults that announce one name are one server.
if [ -n "$RETIRE_KEYS" ]; then
  while IFS= read -r key; do
    case "$key" in
      "$LEGACY_SERVER"|"$LEGACY_SERVER"-*)
        CATALOG "vaultMcp.retireRefused" "$key"
        exit 1 ;;
    esac
  done <<RETIRE_CHECK_EOF
$RETIRE_KEYS
RETIRE_CHECK_EOF
fi
[ "$HAVE_CLAUDE" = "1" ] && cross_identity "Claude Code" "$HOME/.claude.json"
[ "$HAVE_CODEX" = "1" ] && cross_identity "Codex" "$CODEX_CONFIG"
if [ -n "$DESKTOP_DIRS" ]; then
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    cross_identity "$(native "$d/claude_desktop_config.json")" "$d/claude_desktop_config.json"
  done <<PREPASS_EOF
$DESKTOP_DIRS
PREPASS_EOF
fi
if [ "$REFUSED" = "1" ]; then
  SUFFIX_LABEL="${LABEL:+$LABEL-}$(printf '%s' "${MY_ID#sb-}" | cut -c1-8)"
  CATALOG "vaultMcp.suffixProposal" "$VID_SERVER_PREFIX-$SUFFIX_LABEL" "$SUFFIX_LABEL"
  exit 1
fi

# --- The label, posed once the pre-pass is clear ------------------------------------------
if [ -n "$LABEL" ] && [ "$LABEL" != "$LABEL_CUR" ]; then
  if vid_set_label "$VAULT_ROOT" "$LABEL"; then
    CATALOG "vaultMcp.labelSet" "$LABEL" "$SERVER"
  else
    echo "REFUS : libelle non pose dans $(native "$VAULT_ROOT/VAULT-IDENTITY.md")" >&2
    exit 1
  fi
fi

DETECTED=0

# --- Claude Code: user configuration (~/.claude.json) ---------------
if [ "$HAVE_CLAUDE" = "1" ]; then
  DETECTED=1
  CATALOG "vaultMcp.detected" "Claude Code"
  migrate_former "Claude Code" claude "$HOME/.claude.json"
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
  retire_keys "Claude Code" claude "$HOME/.claude.json"
else
  CATALOG "vaultMcp.notDetected" "Claude Code"
fi

# --- Codex: ~/.codex/config.toml (or $CODEX_HOME) --------------------------
if [ "$HAVE_CODEX" = "1" ]; then
  DETECTED=1
  CATALOG "vaultMcp.detected" "Codex"
  migrate_former "Codex" codex "$CODEX_CONFIG"
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
  retire_keys "Codex" codex "$CODEX_CONFIG"
else
  CATALOG "vaultMcp.notDetected" "Codex"
fi

# --- Claude desktop application: measured configuration folders -------
if [ "$SKIP_DESKTOP" = "1" ]; then
  CATALOG "vaultMcp.desktopSkipped"
elif [ -n "$DESKTOP_DIRS" ]; then
  DETECTED=1
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    CONFIG="$d/claude_desktop_config.json"
    CATALOG "vaultMcp.detected" "$(native "$CONFIG")"
    migrate_former "$(native "$CONFIG")" desktop "$CONFIG"
    RESULT="$(PYRUN merge-mcp-json "$CONFIG" "$SERVER" "$UV_N" run --no-project "$MCP_N" --vault "$VAULT_N" --allow "$WS_N" | tr -d '\r')"
    case "$RESULT" in
      UNCHANGED) CATALOG "vaultMcp.alreadyPresent" "$(native "$CONFIG")" "$SERVER" ;;
      UPDATED) CATALOG "vaultMcp.added" "$(native "$CONFIG")" "$WS_N" "$SERVER" ;;
      *) CATALOG "vaultMcp.failed" "$(native "$CONFIG")" ;;
    esac
    retire_keys "$(native "$CONFIG")" desktop "$CONFIG"
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
