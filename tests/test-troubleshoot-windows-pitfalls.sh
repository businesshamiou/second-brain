#!/usr/bin/env bash
# Mission 231, step 4d: the Windows pitfalls met on 2026-09-25 are written in
# docs/how-to/troubleshoot.md, each with its way out, and the tools do not
# fall into the first one themselves.
#   (1) `python` is the Microsoft Store alias: the page says so and gives the
#       `uv run --no-project` form and the App execution aliases setting;
#   (2) no tool of tools/ calls a bare `python` or `python3` (they go through
#       uv), so the alias never answers in their place;
#   (3) reading from another window: GIT_OPTIONAL_LOCKS=0 given with a command;
#   (4) an unreadable file before `git add`: check-readable.sh, takeown and
#       icacls /reset named.
#
# usage: bash tests/test-troubleshoot-windows-pitfalls.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PAGE="$REPO_ROOT/docs/how-to/troubleshoot.md"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
says() { tr -d '\r' < "$PAGE" | grep -qF -- "$1"; }

echo "=== Mission 231 : pieges Windows ecrits dans le depannage ==="
if says "Microsoft Store" && says "App execution aliases" && says "uv run --no-project"; then
  pass "(1) alias python du Windows Store : dit, avec uv run --no-project et le reglage"
else
  fail "(1) alias python du Windows Store absent de troubleshoot.md"
fi
BARE="$(cd "$REPO_ROOT" && grep -nE '(^|[;&|(`[:space:]])(python3?)([[:space:]]|$)' tools/*.sh 2>/dev/null \
  | grep -vE ':[0-9]+:[[:space:]]*#' | grep -v -e 'uv run' -e 'UV" run' || true)"
if [ -z "$BARE" ]; then
  pass "(2) aucun outil de tools/ n'appelle python nu"
else
  fail "(2) appel nu de python : $(printf '%s' "$BARE" | head -n 3 | tr '\n' ' ')"
fi
says "GIT_OPTIONAL_LOCKS=0 git -C" && pass "(3) GIT_OPTIONAL_LOCKS=0 donne avec une commande" \
  || fail "(3) GIT_OPTIONAL_LOCKS=0 absent"
if says "check-readable.sh" && says "takeown /f" && says "/reset"; then
  pass "(4) fichier illisible : check-readable.sh, takeown et icacls /reset nommes"
else
  fail "(4) remede du fichier illisible absent"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
