#!/usr/bin/env bash
# T7, moitie shell (Mission 185-C01, porte 9 de la capture
# 2026-09-17-144137) : les chemins rendus au Pilot et au participant sont
# dans la forme que LEUR systeme comprend.
#
# Defaut mesure sur le poste de l'Owner : `state/PILOT-PROMPT.md` portait
# `/c/Users/hamio/Workspaces/sb6/test-184` -- la forme de Git Bash -- alors
# que le serveur MCP, l'application de bureau et le participant lisent
# `C:\Users\...`. Le Pilot a du raisonner « dossier parent » pour s'en
# sortir ; rien ne garantissait qu'il y arrive.
#
# Ce fichier est le jumeau shell de
# tests/test-project-bootstrap-native-paths.ps1 : il porte le TEMOIN sur
# macOS et Linux -- la ou `cygpath` n'existe pas, le chemin POSIX doit
# rester rigoureusement inchange (aucune transformation, aucune invention)
# -- et rejoue l'oracle sous Git Bash, ou `cygpath` existe.
#
# Trois surfaces mesurees, celles de la porte 9 : `state/PILOT-PROMPT.md`,
# la fiche `projects/PROJECT-*.md`, et le bloc a consommer rendu sur la
# sortie.
#
# Ecrit seulement dans un dossier temporaire (prefixe m185).
#
# usage: bash tests/test-project-bootstrap-native-paths.sh
# Code 0 : tous les cas PASS. Code 1 sinon.

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

# posix_drive_form : la forme Git Bash d'un chemin Windows, /c/... . C'est
# exactement ce qui ne doit jamais sortir sous Windows.
POSIX_DRIVE='/[a-zA-Z]/'

if [ "$HAS_CYGPATH" = "1" ]; then
  # --- Oracle, sous Git Bash ------------------------------------------
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
  # --- Temoin, sur macOS et Linux --------------------------------------
  # Sans cygpath, native_path rend son argument tel quel : le chemin POSIX
  # doit se retrouver a l'identique, ni transforme ni reecrit.
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
