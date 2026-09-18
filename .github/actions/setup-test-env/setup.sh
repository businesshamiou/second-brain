#!/usr/bin/env bash
# Mission 188 -- the non-Windows half of the setup-test-env action, callable
# by hand too (tests/test-setup-test-env-offline.sh does, into an empty
# directory, to prove a cold cache gives the same result).
#
# usage: bash setup.sh <env-dir> <uv-bin> [python-version]
#
# Installs only what is missing: uv (version and install-script SHA-256 read
# from tools/prerequisites.lock.json, the pins the installer itself trusts),
# a uv-managed Python, and pre-commit as a uv tool. Everything lives under
# <env-dir> and <uv-bin>; nothing is put on PATH, nothing touches the
# profile. Writes <env-dir>/env.sh, the variables that point uv there.
# Apple's bash 3.2 and BSD tools are enough (the macOS job runs it after its
# PATH is cut down to /usr/bin:/bin:/usr/sbin:/sbin).

set -eu

ENV_DIR="$1"
UV_BIN="$2"
PY="${3:-3.12}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${SB_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"
LOCK="$REPO_ROOT/tools/prerequisites.lock.json"

lock_value() { sed -n "s/.*\"$1\": *\"\([^\"]*\)\".*/\1/p" "$LOCK" | head -n 1; }
UV_URL="$(lock_value installScriptUrlUnix)"
UV_SHA="$(lock_value installScriptShaUnix)"
UV_VERSION="$(printf '%s\n' "$UV_URL" | sed -n 's#.*/uv/\([^/]*\)/.*#\1#p')"
PC_VERSION="$(awk -F'"' '/"preCommit"/ { f = 1 } f && $2 == "version" { print $4; exit }' "$LOCK")"
if [ -z "$UV_URL" ] || [ -z "$UV_SHA" ] || [ -z "$UV_VERSION" ] || [ -z "$PC_VERSION" ]; then
  echo "REFUS : pins unreadable in $LOCK" >&2
  exit 1
fi

mkdir -p "$ENV_DIR" "$UV_BIN"
INSTALLED=""

# --- uv ---------------------------------------------------------------------
UV="$UV_BIN/uv"
if ! "$UV" --version 2>/dev/null | grep -q " $UV_VERSION"; then
  script="$ENV_DIR/install-uv.sh"
  curl -fsSL -o "$script" "$UV_URL"
  if command -v sha256sum >/dev/null 2>&1; then
    got="$(sha256sum "$script" | awk '{print $1}')"
  else
    got="$(shasum -a 256 "$script" | awk '{print $1}')"
  fi
  if [ "$got" != "$UV_SHA" ]; then
    echo "REFUS : uv install script hash $got, expected $UV_SHA" >&2
    exit 1
  fi
  UV_UNMANAGED_INSTALL="$UV_BIN" UV_NO_MODIFY_PATH=1 UV_SYSTEM_CERTS=1 sh "$script"
  rm -f "$script"
  INSTALLED="$INSTALLED uv"
fi

# --- where uv keeps everything else -----------------------------------------
{
  echo "export UV_CACHE_DIR=\"$ENV_DIR/cache\""
  echo "export UV_PYTHON_INSTALL_DIR=\"$ENV_DIR/python\""
  echo "export UV_PYTHON_BIN_DIR=\"$ENV_DIR/bin\""
  echo "export UV_TOOL_DIR=\"$ENV_DIR/tools\""
  echo "export UV_TOOL_BIN_DIR=\"$ENV_DIR/bin\""
  echo "export UV_PYTHON_PREFERENCE=only-managed"
  echo "export UV_PYTHON_INSTALL_REGISTRY=0"
  echo "export UV_SYSTEM_CERTS=1"
} > "$ENV_DIR/env.sh"
. "$ENV_DIR/env.sh"

# --- Python -----------------------------------------------------------------
if ! "$UV" python find "$PY" >/dev/null 2>&1; then
  "$UV" python install "$PY"
  INSTALLED="$INSTALLED python"
fi

# --- pre-commit -------------------------------------------------------------
PC="$ENV_DIR/bin/pre-commit"
if ! "$PC" --version 2>/dev/null | grep -q " $PC_VERSION"; then
  "$UV" tool install --force --python "$PY" "pre-commit==$PC_VERSION"
  INSTALLED="$INSTALLED pre-commit"
fi

echo "uv:         $("$UV" --version)"
echo "python:     $("$UV" python find "$PY")"
echo "pre-commit: $("$PC" --version)"
if [ -z "$INSTALLED" ]; then
  echo "setup-test-env: warm, nothing installed"
else
  echo "setup-test-env: installed$INSTALLED"
fi
