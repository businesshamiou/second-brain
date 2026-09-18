#!/usr/bin/env bash
# T7, shell half (Mission 185-C01, door 9 of capture
# 2026-09-17-144137): the paths handed to the Pilot and to the participant are
# in the form THEIR system understands.
#
# Defect measured on the Owner's machine: `state/PILOT-PROMPT.md` carried
# the project path in Git Bash form -- drive letter at the
# start and forward slashes -- while
# the MCP server, the desktop application and the participant read
# `C:\Users\...`. The Pilot had to reason « dossier parent » ["parent folder"]
# to get by; nothing guaranteed it would manage.
#
# This file is the shell twin of
# tests/test-project-bootstrap-native-paths.ps1: it carries the CONTROL on
# macOS and Linux -- where `cygpath` does not exist, the POSIX path must
# stay rigorously unchanged (no transformation, no invention)
# -- and replays the oracle under Git Bash, where `cygpath` exists.
#
# Three surfaces measured, those of door 9: `state/PILOT-PROMPT.md`,
# the record `projects/PROJECT-*.md`, and the block to consume printed on the
# output.
#
# Writes only in a temporary folder (prefix m185).
#
# usage: bash tests/test-project-bootstrap-native-paths.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- tools/project-bootstrap.sh en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-native-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

if command -v cygpath >/dev/null 2>&1; then
  HAS_CYGPATH=1
else
  HAS_CYGPATH=0
fi
echo "=== T7 (shell) : cygpath $([ "$HAS_CYGPATH" = "1" ] && echo present || echo absent) sur $(uname -s) ==="

WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
if ! sandbox_vault "$REPO_ROOT" "$V"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V/tools/write-marker.sh" "$WS" >/dev/null

P="$WS/projet"
OUT="$(bash "$V/tools/project-bootstrap.sh" create "$P" "Projet" --vcs none 2>&1 </dev/null)"
RC=$?
[ "$RC" = "0" ] && pass "create rend 0" || fail "create rend $RC -- $(printf '%s' "$OUT" | tail -n 3)"

PILOT_PROMPT="$P/state/PILOT-PROMPT.md"
FICHE="$(printf '%s\n' "$OUT" | tail -n 1)"
[ -f "$PILOT_PROMPT" ] && pass "state/PILOT-PROMPT.md existe" || fail "state/PILOT-PROMPT.md absent"
[ -f "$FICHE" ] && pass "la fiche existe ($(basename "$FICHE"))" || fail "fiche introuvable : $FICHE"

SURFACES="$PILOT_PROMPT $FICHE"

# posix_drive_form: the Git Bash form of a Windows path, /c/... . This is
# exactly what must never come out under Windows.
POSIX_DRIVE='/[a-zA-Z]/'

if [ "$HAS_CYGPATH" = "1" ]; then
  # --- Oracle, under Git Bash -----------------------------------------
  NATIVE="$(cygpath -w "$(cd "$P" && pwd)")"
  for F in $SURFACES; do
    if grep -qF -- "$NATIVE" "$F"; then
      pass "$(basename "$F") porte le chemin natif ($NATIVE)"
    else
      fail "$(basename "$F") ne porte pas le chemin natif ($NATIVE)"
    fi
    if grep -qE -- "$POSIX_DRIVE"'Users|'"$POSIX_DRIVE"'Windows|'"$POSIX_DRIVE"'Temp' "$F"; then
      fail "$(basename "$F") porte encore un chemin /c/..."
    else
      pass "$(basename "$F") ne porte aucun chemin /c/..."
    fi
  done
  if printf '%s' "$OUT" | grep -qF -- "$NATIVE"; then
    pass "bloc a consommer : chemin natif"
  else
    fail "bloc a consommer : chemin non natif"
  fi
else
  # --- Control, on macOS and Linux -------------------------------------
  # Without cygpath, native_path returns its argument as is: the POSIX path
  # must be found identically, neither transformed nor rewritten.
  POSIX="$(cd "$P" && pwd)"
  case "$POSIX" in
    /*) pass "controle : le chemin du projet est POSIX ($POSIX)" ;;
    *) fail "controle : chemin inattendu ($POSIX)" ;;
  esac
  for F in $SURFACES; do
    if grep -qF -- "$POSIX" "$F"; then
      pass "$(basename "$F") porte le chemin POSIX inchange"
    else
      fail "$(basename "$F") ne porte pas le chemin POSIX inchange"
    fi
    if grep -q '[A-Za-z]:\\' "$F"; then
      fail "$(basename "$F") porte une forme Windows sur un systeme Unix"
    else
      pass "$(basename "$F") ne porte aucune forme Windows"
    fi
  done
  if printf '%s' "$OUT" | grep -qF -- "$POSIX"; then
    pass "bloc a consommer : chemin POSIX inchange"
  else
    fail "bloc a consommer : chemin POSIX altere"
  fi
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
