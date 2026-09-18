#!/usr/bin/env bash
# T10 (Mission 185-C01, door 10 of capture 2026-09-17-144137):
# INSTALL.md and README.md carry the exact WINDOWS invocation of the two
# shell tools a participant launches by hand.
#
# Defect measured on the Owner's machine: the documentation wrote
# `bash tools/install-vault-mcp.sh ...`, and `bash` is absent from the PATH of
# PowerShell. Git, for its part, is present -- its bash lives at
# C:\Program Files\Git\bin\bash.exe. A line that cannot be pasted
# is not an instruction.
#
# Oracle: each of the two documents carries, for each of the two tools, the
# PowerShell line that calls Git's bash by its full path.
# Negative control: a copy of the document stripped of these lines fails the
# same check, in a temporary folder.
#
# usage: bash tests/test-install-doc-windows-invocation.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-doc-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# The exact path of the bash.exe provided by Git on Windows, as a
# participant pastes it into PowerShell. Hard-coded here because it is
# precisely the string the documents must carry (measured on the
# Owner's machine, capture 2026-09-17-144137); the whole rest of the repository
# resolves bash through tools/resolve-bash-exe.ps1.
BASH_EXE_LITERAL='C:\Program Files\Git\bin\bash.exe'

TOOLS="install-vault-mcp.sh check-mcp-containment.sh"

# has_windows_invocation <fichier> <outil>: 0 if the file carries a
# line calling <outil> through Git's bash.exe.
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

# --- Negative control: the same measurement, on a truncated copy ----------
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
