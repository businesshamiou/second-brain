#!/usr/bin/env bash
# Shared helper: resolve a declared sibling repository (Mission 174, step 3,
# T21 -- no tool assumes a neighbouring repository by default). Source this
# file from a guardian or tool that wants to check cross-repo state; never
# execute it directly.
#
# Declaration is explicit only, two forms, first one found wins:
#   1. Environment variable SECOND_BRAIN_SIBLING_REPO (a repo NAME, e.g.
#      "workshop-build" -- not a path).
#   2. A one-line text file SIBLING-REPO.txt at the workspace root (the
#      directory that holds this repository's own parent folder -- same
#      root VAULT-ROOT.md lives at for an installed Second Brain workspace).
# Neither present: no sibling is declared. A caller must then search
# nothing, warn nothing, and pass -- exactly as if no such tool existed.
#
# usage (from another script, after `set -u`):
#   . "$(dirname "$0")/resolve-sibling-repo.sh"
#   resolve_declared_sibling "$WORKSPACE_ROOT"
#   # sets: SIBLING_DECLARED (0 or 1), SIBLING_NAME, SIBLING_ROOT (path, only
#   # if the declared folder actually exists -- empty otherwise), and prints
#   # nothing itself: the caller decides what a missing declared sibling
#   # means for it (session-preflight.sh warns once; other callers may just
#   # skip their own cross-repo checks the same way).

resolve_declared_sibling() {
  local workspace_root="$1"
  SIBLING_DECLARED=0
  SIBLING_NAME=""
  SIBLING_ROOT=""

  if [ -n "${SECOND_BRAIN_SIBLING_REPO:-}" ]; then
    SIBLING_NAME="$SECOND_BRAIN_SIBLING_REPO"
    SIBLING_DECLARED=1
  elif [ -f "$workspace_root/SIBLING-REPO.txt" ]; then
    SIBLING_NAME="$(head -n 1 "$workspace_root/SIBLING-REPO.txt" | tr -d '\r\n')"
    [ -n "$SIBLING_NAME" ] && SIBLING_DECLARED=1
  fi

  [ "$SIBLING_DECLARED" -eq 1 ] || return 0

  if [ -d "$workspace_root/$SIBLING_NAME" ]; then
    SIBLING_ROOT="$workspace_root/$SIBLING_NAME"
  fi
}
