#!/usr/bin/env bash
# T10 (Mission 185-C01, porte 10 de la capture 2026-09-17-144137) :
# INSTALL.md et README.md portent l'invocation WINDOWS exacte des deux
# outils shell qu'un participant lance a la main.
#
# Defaut mesure sur le poste de l'Owner : la documentation ecrivait
# `bash tools/install-vault-mcp.sh ...`, et `bash` est absent du PATH de
# PowerShell. Git, lui, est present -- son bash vit a
# C:\Program Files\Git\bin\bash.exe. Une ligne qu'on ne peut pas coller
# n'est pas une instruction.
#
# Oracle : chacun des deux documents porte, pour chacun des deux outils, la
# ligne PowerShell qui appelle le bash de Git par son chemin complet.
# Temoin negatif : une copie du document privee de ces lignes echoue au
# meme controle, dans un dossier temporaire.
#
# usage: bash tests/test-install-doc-windows-invocation.sh
# Code 0 : tous les cas PASS. Code 1 sinon.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-doc-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# Le chemin exact de bash.exe fourni par Git sous Windows, tel qu'un
# participant le colle dans PowerShell. En dur ici parce que c'est
# precisement la chaine que les documents doivent porter (mesuree sur le
# poste de l'Owner, capture 2026-09-17-144137) ; tout le reste du depot
# resout bash par tools/resolve-bash-exe.ps1.
BASH_EXE_LITERAL='C:\Program Files\Git\bin\bash.exe'

TOOLS="install-vault-mcp.sh check-mcp-containment.sh"

# has_windows_invocation <fichier> <outil> : 0 si le fichier porte une
# ligne appelant <outil> par le bash.exe de Git.
has_windows_invocation() {
  tr -d '\r' < "$1" | grep -F "$BASH_EXE_LITERAL" | grep -qF "$2"
}

echo "=== T10 : invocation Windows dans INSTALL.md et README.md ==="

for DOC in INSTALL.md README.md; do
  DOC_PATH="$REPO_ROOT/$DOC"
  if [ ! -f "$DOC_PATH" ]; then
    fail "document introuvable : $DOC_PATH"
    continue
  fi
  for TOOL in $TOOLS; do
    if has_windows_invocation "$DOC_PATH" "$TOOL"; then
      pass "$DOC : invocation Windows de $TOOL par le bash.exe de Git"
    else
      fail "$DOC : aucune invocation Windows de $TOOL par le bash.exe de Git"
    fi
  done
done

# --- Temoin negatif : la meme mesure, sur une copie amputee ---------------
WITNESS="$TMP/INSTALL.md"
grep -vF "$BASH_EXE_LITERAL" "$REPO_ROOT/INSTALL.md" > "$WITNESS"
WITNESS_SEEN=0
for TOOL in $TOOLS; do
  has_windows_invocation "$WITNESS" "$TOOL" && WITNESS_SEEN=1
done
if [ "$WITNESS_SEEN" = "0" ]; then
  pass "temoin : une copie d'INSTALL.md sans ces lignes echoue au meme controle"
else
  fail "temoin : la copie amputee passe quand meme le controle"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
