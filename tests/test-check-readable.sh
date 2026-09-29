#!/usr/bin/env bash
# Mission 231, step 4c: a file that cannot be read stops the staging, with its
# remedy named (tools/check-readable.sh).
#
# Fixture: a throwaway repository with two new files; one is made unreadable
# to the current account -- on Windows by an access control entry that denies
# reading (icacls, on this throwaway file only, removed at the end), elsewhere
# by chmod 000. When the platform does not make it unreadable (root on Linux,
# icacls absent), the test says so and exits 77 (SKIP).
#   (1) the file really is unreadable: `git add` of it fails (the witness of
#       the incident, 2026-09-25);
#   (2) check-readable.sh refuses: exit 1, UNREADABLE names that file only,
#       the remedy names takeown and icacls /reset with its native path,
#       last line REFUSED;
#   (3) with explicit paths: the readable file alone -> READABLE 1, exit 0;
#   (4) the ACL back: READABLE 2, exit 0;
#   (5) install.sh and install.ps1 run the check before their own staging.
#
# usage: bash tests/test-check-readable.sh
# Exit 0: all cases PASS. Exit 1 otherwise. Exit 77: SKIP (cause printed).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$REPO_ROOT/tools/check-readable.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m231-readable-XXXXXX")"
TMP="$(cd "$TMP" && pwd)"
R="$TMP/repo"
mkdir -p "$R"
git init -q "$R"
printf 'lisible\n' > "$R/a.txt"
printf 'illisible\n' > "$R/b.txt"
B_NATIVE="$R/b.txt"
command -v cygpath >/dev/null 2>&1 && B_NATIVE="$(cygpath -w "$R/b.txt")"

MODE=""
lock() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      command -v icacls >/dev/null 2>&1 || return 1
      MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" icacls "$B_NATIVE" /deny "${USERNAME}:(R)" >/dev/null 2>&1 && MODE=acl ;;
    *) chmod 000 "$R/b.txt" && MODE=chmod ;;
  esac
}
unlock() {
  case "$MODE" in
    acl) MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" icacls "$B_NATIVE" /remove:d "${USERNAME}" >/dev/null 2>&1 ;;
    chmod) chmod 644 "$R/b.txt" ;;
  esac
  MODE=""
}
trap 'unlock; [ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT

echo "=== Mission 231 : un fichier illisible arrete la mise en scene, remede nomme ==="
if [ ! -f "$TOOL" ]; then
  fail "outil absent : tools/check-readable.sh"
else
  lock
  if [ -z "$MODE" ] || head -c 1 -- "$R/b.txt" >/dev/null 2>&1; then
    unlock
    echo "SKIP : ce poste ne rend pas un fichier illisible a son propre compte (root, ou icacls absent)"
    exit 77
  fi
  if git -C "$R" add -- b.txt >/dev/null 2>&1; then
    fail "(1) temoin : git add d'un fichier illisible a reussi (rien a prouver)"
  else
    pass "(1) temoin : git add du fichier illisible echoue (mode $MODE)"
  fi
  git -C "$R" reset -q >/dev/null 2>&1
  OUT="$(bash "$TOOL" "$R" 2>&1)"; RC=$?
  if [ "$RC" = 1 ] && has "$OUT" "UNREADABLE b.txt" && ! has "$OUT" "UNREADABLE a.txt" \
    && [ "$(printf '%s\n' "$OUT" | tail -n 1)" = "REFUSED" ]; then
    pass "(2) refus : b.txt seul nomme, derniere ligne REFUSED"
  else
    fail "(2) refus attendu : rc=$RC -- $(printf '%s' "$OUT" | tr '\n' ' ' | cut -c1-240)"
  fi
  if has "$OUT" "takeown /f \"$B_NATIVE\"" && has "$OUT" "icacls \"$B_NATIVE\" /reset"; then
    pass "(2) remede nomme : takeown puis icacls /reset, chemin natif"
  else
    fail "(2) remede absent ou chemin faux -- $(printf '%s' "$OUT" | grep -i -e takeown -e icacls | head -n 2 | tr '\n' ' ')"
  fi
  [ -z "$(git -C "$R" diff --cached --name-only)" ] && pass "(2) rien d'indexe" || fail "(2) des chemins sont indexes"
  OUT="$(bash "$TOOL" "$R" a.txt 2>&1)"; RC=$?
  [ "$RC" = 0 ] && [ "$(printf '%s\n' "$OUT" | tail -n 1)" = "READABLE 1" ] && pass "(3) chemins nommes : a.txt seul, READABLE 1" \
    || fail "(3) rc=$RC -- $OUT"
  unlock
  OUT="$(bash "$TOOL" "$R" 2>&1)"; RC=$?
  [ "$RC" = 0 ] && [ "$(printf '%s\n' "$OUT" | tail -n 1)" = "READABLE 2" ] && pass "(4) droits rendus : READABLE 2" \
    || fail "(4) rc=$RC -- $OUT"
fi

BODY="$(awk '/^stage_and_commit_clone_changes\(\) \{/,/^\}/' "$REPO_ROOT/install.sh")"
if has "$BODY" "check-readable.sh"; then
  pass "(5) install.sh verifie la lisibilite avant sa mise en scene"
else
  fail "(5) install.sh indexe sans verifier la lisibilite"
fi
BODY_PS="$(awk '/^function Save-ClonePendingChanges \{/,/^\}/' "$REPO_ROOT/install.ps1")"
if has "$BODY_PS" "check-readable.sh"; then
  pass "(5) install.ps1 aussi (Save-ClonePendingChanges)"
else
  fail "(5) install.ps1 indexe sans verifier la lisibilite"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
