#!/usr/bin/env bash
# Shared helper: fingerprint the Owner's real environment on macOS/Linux
# (Mission 168, ticket 08 -- shell parity with
# tools/environment-fingerprint.ps1, tickets 03/04/07). Sourced by
# tests/test-install-e2e.sh so a before/after comparison uses the exact
# same measurement on both sides.
#
# Unix has no HKCU\Environment registry key; the closest equivalent is the
# PATH-persistence file this installer's own add_installer_path_entry
# would edit in real (non -test-mode) runs. Its own path is passed in via
# $1 so this file never has to guess -- tests/test-install-e2e.sh and
# install.sh must both agree on it.
#
# usage: environment_fingerprint <path-persistence-file>
# Prints six lines: PATH_FILE_HASH=... (sha256 of the file, or "none" if it
# does not exist), CLAUDE_SKILLS=..., CODEX_SKILLS=..., CODEX_AGENTS_SKILLS=...,
# LOCAL_BIN=..., UV_TOOLS=... -- the last five are each a sorted,
# comma-joined listing of that folder's entries (plain text, not encoded).

set -u

environment_fingerprint() {
  local path_file="$1"
  local path_hash="none"
  if [ -f "$path_file" ]; then
    # Repli choisi par `command -v`, jamais un `sha256sum` appele a
    # l'aveugle : macOS n'en livre pas, seulement `shasum` (Mission 181).
    if command -v sb_sha256 >/dev/null 2>&1; then
      path_hash="$(sb_sha256 "$path_file")"
    elif command -v sha256sum >/dev/null 2>&1; then
      path_hash="$(sha256sum "$path_file" | awk '{print $1}')"  # portability: guarded by command -v
    else
      path_hash="$(shasum -a 256 "$path_file" | awk '{print $1}')"
    fi
  fi
  local claude_skills codex_skills codex_agents_skills
  claude_skills="$(ls -1 "$HOME/.claude/skills" 2>/dev/null | sort | tr '\n' ',')"
  codex_skills="$(ls -1 "$HOME/.codex/skills" 2>/dev/null | sort | tr '\n' ',')"
  codex_agents_skills="$(ls -1 "$HOME/.agents/skills" 2>/dev/null | sort | tr '\n' ',')"
  # uv's own write targets (Mission 181): its tool executables and its tool
  # environments. A test-mode install that is not redirected writes here --
  # it did, unseen, until this fingerprint looked.
  local local_bin uv_tools
  local_bin="$(ls -1 "$HOME/.local/bin" 2>/dev/null | sort | tr '\n' ',')"
  uv_tools="$(ls -1 "${XDG_DATA_HOME:-$HOME/.local/share}/uv/tools" 2>/dev/null | sort | tr '\n' ',')"
  echo "PATH_FILE_HASH=$path_hash"
  echo "CLAUDE_SKILLS=$claude_skills"
  echo "CODEX_SKILLS=$codex_skills"
  echo "CODEX_AGENTS_SKILLS=$codex_agents_skills"
  echo "LOCAL_BIN=$local_bin"
  echo "UV_TOOLS=$uv_tools"
}
