#!/usr/bin/env bash
# The human acceptance wizard is retired, and the acceptance it stood for is
# mechanical (Mission 183-C01, Decision 142112 point 1).
#
# Until v0.1.0 this file unit-tested the functions of
# tools/acceptance-wizard.sh (Mission 168, ticket 11): a reply parser, a
# note sanitizer, a report-path guard and a report writer, all feeding the
# wizard's four stages (mechanical report, then S7, S8 and S9 judged by the
# Owner). Decision 142112 retires those stages: the dated report of
# tests/run-mechanical-acceptance.ps1 is the written acceptance, with S7, S8
# and S9 in its table. The wizard and its Windows launcher were moved to
# _trash/ with their SHA-256, never deleted. This test was rewritten, not
# removed, to hold that state:
#
#   1. wizard-gone-from-tools   -- tools/acceptance-wizard.sh and
#      acceptance.ps1 no longer exist where a participant would find them;
#   2. wizard-kept-with-print   -- both sit in _trash/ and match the SHA-256
#      recorded in _trash/acceptance-wizard-retired.md;
#   3. no-doc-sends-to-wizard   -- no distributed document tells anyone to
#      run the wizard;
#   4. runner-has-eleven-lines  -- the runner orders S1-S10 and T21, with S7,
#      S8 and S9 each delegated to a mechanical proof.
#
# usage: tests/test-acceptance-wizard-functions.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FAILURES=0

ok() { echo "ok [$1]"; }
ko() { echo "FAIL [$1]: $2" >&2; FAILURES=$((FAILURES + 1)); }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'  # portability: guarded by command -v
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# --- 1 --------------------------------------------------------------------------
if [ ! -e "$REPO_ROOT/tools/acceptance-wizard.sh" ] && [ ! -e "$REPO_ROOT/acceptance.ps1" ]; then
  ok "1-wizard-gone-from-tools"
else
  ko "1-wizard-gone-from-tools" "the wizard or its launcher is still in place"
fi

# --- 2 --------------------------------------------------------------------------
NOTE="$REPO_ROOT/_trash/acceptance-wizard-retired.md"
for name in acceptance-wizard.sh acceptance.ps1; do
  kept="$REPO_ROOT/_trash/$name"
  recorded="$(grep -F "| \`$name\` |" "$NOTE" 2>/dev/null | grep -oE '[0-9a-f]{64}' | head -n 1)"
  if [ -f "$kept" ] && [ -n "$recorded" ]; then
    # The recorded print is taken on the file as committed (LF endings).
    actual="$(git -C "$REPO_ROOT" show "HEAD:_trash/$name" 2>/dev/null > "${TMPDIR:-/tmp}/sb-wizard-kept.$$" && sha256_of "${TMPDIR:-/tmp}/sb-wizard-kept.$$")"
    rm -f "${TMPDIR:-/tmp}/sb-wizard-kept.$$"
    [ -n "$actual" ] || actual="$(sha256_of "$kept")"
    if [ "$actual" = "$recorded" ]; then
      ok "2-wizard-kept-with-print-$name"
    else
      ko "2-wizard-kept-with-print-$name" "SHA-256 $actual differs from the recorded $recorded"
    fi
  else
    ko "2-wizard-kept-with-print-$name" "missing from _trash/ or its print is not recorded in $NOTE"
  fi
done

# --- 3 --------------------------------------------------------------------------
HITS="$(git -C "$REPO_ROOT" grep -nE -e 'acceptance-wizard' -e '(^|[^-A-Za-z])acceptance\.ps1' -- \
  README.md INSTALL.md CONTEXT.md AGENTS.md CLAUDE.md USER.md skills rules templates knowledge assistant 2>/dev/null \
  | grep -v '^skills/external/' || true)"
if [ -z "$HITS" ]; then
  ok "3-no-doc-sends-to-wizard"
else
  ko "3-no-doc-sends-to-wizard" "$HITS"
fi

# --- 4 --------------------------------------------------------------------------
RUNNER="$REPO_ROOT/tests/run-mechanical-acceptance.ps1"
if grep -qF "\$order = 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'T21'" "$RUNNER" \
    && grep -q "tools/acceptance-harness.sh" "$RUNNER" \
    && grep -q "test-install-standard-user.ps1" "$RUNNER"; then
  ok "4-runner-has-eleven-lines"
else
  ko "4-runner-has-eleven-lines" "the runner does not order S1-S10 and T21 with S7/S8/S9 delegated"
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 5/5 cases"
  exit 0
fi
echo "FAIL: $FAILURES case(s)"
exit 1
