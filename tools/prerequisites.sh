#!/usr/bin/env bash
# Prerequisites for macOS/Linux (Mission 168, ticket 08 -- shell parity with
# tools/prerequisites.ps1, ticket 04). Sourced by install.sh; defines
# ensure_prerequisites and its helpers in the caller's shell.
#
# Detect-and-reuse first, same rule as Windows: a tool already on PATH is
# never reinstalled. Only a genuinely missing tool is installed into the
# profile (real $HOME, or $CTX_PROFILE_ROOT under -test-mode), never
# elevated (no sudo anywhere in this file).
#
# Git on Linux has no official portable/static distribution the way
# Windows has "Git for Windows portable" (measured, WebSearch 2026-09-11:
# only third-party community builds exist, e.g. darkvertex/static-git).
# This is named as a Class A finding in the ticket 08 report -- the
# pinned fallback below is independently downloaded and SHA-256-verified
# by the Executor, but it is not an official upstream artifact the way the
# Windows one is. On macOS, git ships with the Xcode Command Line Tools,
# installed via `xcode-select --install` (no sudo needed, but shows an
# interactive GUI prompt -- HYPOTHESIS, untested: this Windows machine has
# no macOS to run it on; every real CI macOS runner already has git
# preinstalled, so this path is not expected to be exercised there either).
#
# uv is installed via its own official install.sh (same pinned version and
# SHA-256 discipline as prerequisites.ps1's install.ps1 use); pre-commit is
# then installed via `uv tool install`, never downloaded directly (same
# Class B precedent as ticket 04: integrity delegated to uv/PyPI).

set -u

SB_PREREQ_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SB_PREREQ_LOCK_FILE="$SB_PREREQ_SCRIPT_DIR/prerequisites.lock.json"
SB_PREREQ_HELPER="$SB_PREREQ_SCRIPT_DIR/sb_installer_helper.py"

# Bootstrap-critical pins, duplicated from prerequisites.lock.json as plain
# shell constants (Class B, ticket 08 report): reading the lock file's JSON
# needs either uv or a real python3, neither of which is guaranteed present
# before ensure_git/ensure_uv have run -- a JSON-parsing read here would be
# a circular dependency on the very tool being bootstrapped. Only these two
# entries (needed before uv exists) are duplicated; everything read AFTER
# uv is confirmed present (pre-commit's pinned version) still goes through
# the lock file itself via sb_lock_field, one source of truth for the rest.
# Keep these three values byte-identical to prerequisites.lock.json's own
# git.linux64 / uv.installScriptUrlUnix / uv.installScriptShaUnix entries.
SB_GIT_LINUX64_ASSET="git-binaries.linux-64bit.tar.gz"
SB_GIT_LINUX64_URL="https://github.com/darkvertex/static-git/releases/download/2.55.0/git-binaries.linux-64bit.tar.gz"
SB_GIT_LINUX64_SHA256="8c34e40809b9ec271db4b344953f73c9c3a2c3de022be308d567adeee6eb770e"
SB_UV_INSTALL_SH_URL="https://astral.sh/uv/0.12.13/install.sh"
SB_UV_INSTALL_SH_SHA256="e7265962d703f3ca66b3e90fae8fcdc6d4e4b587027e9479ccc29b25c3f68d4e"

sb_lock_field() {
  # $1 = dotted path into prerequisites.lock.json. Only ever called once
  # uv is confirmed on PATH (see comment above) -- never for the two
  # bootstrap-critical entries duplicated as constants above.
  uv run --no-project "$SB_PREREQ_HELPER" field "$SB_PREREQ_LOCK_FILE" "$1"
}

sb_sha256() {
  # $1 = file path. Prefers sha256sum (Linux), falls back to
  # `shasum -a 256` (macOS, no sha256sum by default).
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

sb_download() {
  # $1 = url, $2 = destination path.
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$2" "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$2" "$1"
  else
    echo "Neither curl nor wget is available to download $1" >&2
    return 1
  fi
}

sb_lower() {
  # Portable lowercase (no ${var,,}: that is a bash-4-ism, and macOS still
  # ships bash 3.2 as /bin/bash by default).
  printf '%s' "$1" | tr 'A-Z' 'a-z'
}

sb_fetch_pinned() {
  # $1 = url, $2 = expected sha256, $3 = destination path. Refuses to keep
  # a file whose measured checksum does not match the pinned one -- same
  # "empreinte fausse = arret" rule as Windows (ticket 04 criterion 3).
  local url="$1" expected="$2" dest="$3"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ]; then
    local existing
    existing="$(sb_sha256 "$dest")"
    if [ "$(sb_lower "$existing")" = "$(sb_lower "$expected")" ]; then
      return 0
    fi
  fi
  sb_download "$url" "$dest"
  local actual
  actual="$(sb_sha256 "$dest")"
  if [ "$(sb_lower "$actual")" != "$(sb_lower "$expected")" ]; then
    echo "SHA-256 mismatch for '$dest' downloaded from $url (expected $expected, got $actual). Refusing to use a download that does not match the pinned fingerprint." >&2
    rm -f "$dest"
    return 1
  fi
}

ensure_git() {
  if command -v git >/dev/null 2>&1; then
    return 0
  fi

  local os_name
  os_name="$(uname -s)"
  local tools_root="$CTX_PROFILE_ROOT/.local/share/second-brain"

  if [ "$os_name" = "Darwin" ]; then
    # No sudo: the Command Line Tools installer runs as the current user
    # and only ever prompts its own GUI dialog (HYPOTHESIS: no macOS
    # available on this machine to exercise this branch for real).
    echo "Git not found -- requesting the Xcode Command Line Tools (macOS, no sudo)..."
    xcode-select --install >/dev/null 2>&1 || true
    if ! command -v git >/dev/null 2>&1; then
      echo "Git still not on PATH after requesting the Xcode Command Line Tools; finish that install, then run the installer line again." >&2
      return 1
    fi
    return 0
  fi

  # Linux: try an existing, already-bootstrapped non-privileged package
  # manager first (never installed by this script itself -- only used if
  # already present), then fall back to the pinned static build.
  if command -v brew >/dev/null 2>&1; then
    brew install git
    if command -v git >/dev/null 2>&1; then return 0; fi
  fi
  if command -v nix-env >/dev/null 2>&1; then
    nix-env -iA nixpkgs.git
    if command -v git >/dev/null 2>&1; then return 0; fi
  fi

  local asset url sha256 git_root
  asset="$SB_GIT_LINUX64_ASSET"
  url="$SB_GIT_LINUX64_URL"
  sha256="$SB_GIT_LINUX64_SHA256"
  git_root="$tools_root/git-linux64"
  local archive="$tools_root/downloads/$asset"

  if [ ! -x "$git_root/git" ]; then
    sb_fetch_pinned "$url" "$sha256" "$archive" || return 1
    mkdir -p "$git_root"
    tar -xzf "$archive" -C "$git_root"
    chmod +x "$git_root"/* 2>/dev/null || true
  fi
  if [ ! -x "$git_root/git" ]; then
    echo "Static Git extraction failed: $git_root/git is missing." >&2
    return 1
  fi
  export PATH="$git_root:$PATH"
  add_installer_path_entry "$git_root"
}

ensure_uv() {
  if command -v uv >/dev/null 2>&1; then
    return 0
  fi

  local url sha256 script bin_dir
  url="$SB_UV_INSTALL_SH_URL"
  sha256="$SB_UV_INSTALL_SH_SHA256"
  bin_dir="$CTX_PROFILE_ROOT/.local/bin"
  script="$CTX_PROFILE_ROOT/.local/share/second-brain/downloads/uv-install.sh"

  sb_fetch_pinned "$url" "$sha256" "$script" || return 1
  chmod +x "$script"
  UV_UNMANAGED_INSTALL="$bin_dir" UV_NO_MODIFY_PATH=1 sh "$script" >/dev/null
  if [ ! -x "$bin_dir/uv" ]; then
    echo "uv install script ran but uv is missing at the expected path: $bin_dir/uv" >&2
    return 1
  fi
  export PATH="$bin_dir:$PATH"
  add_installer_path_entry "$bin_dir"
}

ensure_pre_commit() {
  if command -v pre-commit >/dev/null 2>&1; then
    return 0
  fi
  local version bin_dir
  version="$(sb_lock_field "preCommit.version")"
  bin_dir="$CTX_PROFILE_ROOT/.local/bin"
  uv tool install "pre-commit==$version" >/dev/null
  if ! command -v pre-commit >/dev/null 2>&1; then
    export PATH="$bin_dir:$PATH"
  fi
  if ! command -v pre-commit >/dev/null 2>&1; then
    echo "uv tool install pre-commit ran but pre-commit is not on PATH." >&2
    return 1
  fi
  add_installer_path_entry "$bin_dir"
}

init_uv_environment_redirection() {
  # -test-mode ONLY: redirects uv's own tool/cache/managed-Python
  # directories under $CTX_PROFILE_ROOT for the rest of this process,
  # including every child process (the guardians' own `uv run` calls) --
  # same reasoning as prerequisites.ps1's Initialize-UvEnvironmentRedirection.
  export UV_NO_MODIFY_PATH=1
  export UV_SYSTEM_CERTS=1
  if [ "${CTX_TEST_MODE:-0}" = "1" ]; then
    local uv_data_root="$CTX_PROFILE_ROOT/.local/share/uv"
    local uv_bin_dir="$CTX_PROFILE_ROOT/.local/bin"
    export UV_TOOL_DIR="$uv_data_root/tools"
    export UV_TOOL_BIN_DIR="$uv_bin_dir"
    export UV_CACHE_DIR="$CTX_PROFILE_ROOT/.cache/uv"
    export UV_PYTHON_INSTALL_DIR="$uv_data_root/python"
    export UV_PYTHON_CACHE_DIR="$CTX_PROFILE_ROOT/.cache/uv/python"
    export UV_PYTHON_BIN_DIR="$uv_bin_dir/python-shims"
  fi
}

ensure_prerequisites() {
  # Entry point, called by install.sh before touching $SOURCE. Requires
  # add_installer_path_entry() and $CTX_PROFILE_ROOT / $CTX_TEST_MODE to
  # already be defined by the caller (install.sh's own context setup).
  init_uv_environment_redirection
  ensure_git || return 1
  ensure_uv || return 1
  ensure_pre_commit || return 1
}
