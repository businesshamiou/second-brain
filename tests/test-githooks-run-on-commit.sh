#!/usr/bin/env bash
# A participant's commit really runs the guardians (Mission 181).
#
# Until this Mission the three hooks of .githooks/ were tracked at mode
# 100644. Git refuses to run a hook that is not executable ("hint: The
# '.githooks/pre-commit' hook was ignored because it's not set as
# executable"), so on macOS and Linux a participant's commit ran no
# guardian at all -- while every CI job stayed green, because CI calls the
# guardians directly (`bash .githooks/pre-commit`), never through Git. This
# test goes through Git, the way a participant does:
#
#   - a fresh clone of the COMMITTED tree (the index decides the mode a
#     checkout gets, never this machine's disk -- on Windows core.filemode
#     is false and a disk-only chmod never reaches a commit);
#   - core.hooksPath set with the very command install.sh runs;
#   - a real `git commit`.
#
# Cases:
#   1. pre-commit-runs -- a fresh clone has no preflight stamp, so the
#      guardians must refuse the commit and print their report. If Git
#      ignored the hook, the commit would succeed silently: FAIL.
#   2. commit-msg-runs -- `git hook run` (Git's own hook lookup, the same
#      executable check as a commit) on a message carrying a bypass pattern:
#      the hook must refuse it.
#   3. pre-push-runs -- `git hook run pre-push` fed a remote-branch deletion:
#      the hook must refuse it.
#   4. control-non-executable-hooks-ignored -- the same clone, rebuilt from a
#      commit where the hooks are back at 100644 (the tree before Mission
#      181): Git must NOT run them, and case 1's check must see it. This is
#      what proves the test can fail. Git for Windows ignores the execute
#      bit (core.filemode=false), so there this control is reported as
#      SKIP, never as a pass.
# Cases 2 and 3 are SKIP when this Git has no `git hook run --to-stdin`
# (a test-side limit, never a requirement placed on a participant).
#
# usage: tests/test-githooks-run-on-commit.sh [source-repo]
#   source-repo defaults to this repository; its HEAD commit is cloned.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0
SKIPS=0

fresh_clone() {
  # $1 = source, $2 = destination. core.longpaths: the tree carries paths
  # longer than Windows' historical limit; harmless elsewhere.
  git -c core.longpaths=true clone -q "$1" "$2" >/dev/null 2>&1 || return 1
  (
    cd "$2" \
      && git config core.longpaths true \
      && git config core.hooksPath .githooks \
      && git config user.email participant@example.invalid \
      && git config user.name participant \
      && git config commit.gpgsign false
  )
}

try_commit() {
  # $1 = clone. Stages one new file and commits it; output in COMMIT_OUT,
  # exit code in COMMIT_RC.
  printf 'probe\n' > "$1/probe-181.md"
  (cd "$1" && git add -- probe-181.md) >/dev/null 2>&1
  COMMIT_OUT="$(cd "$1" && git commit -m "probe: a participant commit" 2>&1)"
  COMMIT_RC=$?
}

P="$TMP/participant"
if ! fresh_clone "$SRC" "$P"; then
  echo "FAIL: clone impossible depuis $SRC" >&2
  exit 1
fi

# --- 1. pre-commit-runs ------------------------------------------------------
try_commit "$P"
if [ "$COMMIT_RC" -ne 0 ] \
    && printf '%s' "$COMMIT_OUT" | grep -q "=== Guardian suite ===" \
    && printf '%s' "$COMMIT_OUT" | grep -q "preflight absent"; then
  echo "ok [1-pre-commit-runs]: Git ran .githooks/pre-commit, the guardians refused the unstamped commit"
else
  echo "FAIL [1-pre-commit-runs]: exit=$COMMIT_RC, the guardians did not run on a participant commit. Output:" >&2
  printf '%s\n' "$COMMIT_OUT" >&2
  FAILURES=$((FAILURES + 1))
fi

HAS_HOOK_RUN=0
if git hook run -h 2>&1 | grep -q -- '--to-stdin'; then
  HAS_HOOK_RUN=1
fi

# --- 2. commit-msg-runs ------------------------------------------------------
if [ "$HAS_HOOK_RUN" -eq 1 ]; then
  printf 'wip\n' > "$TMP/msg.txt"
  OUT_2="$(cd "$P" && git hook run commit-msg -- "$TMP/msg.txt" 2>&1)"; RC_2=$?
  if [ "$RC_2" -ne 0 ] && printf '%s' "$OUT_2" | grep -q "motif de contournement"; then
    echo "ok [2-commit-msg-runs]: Git ran .githooks/commit-msg, a bypass message was refused"
  else
    echo "FAIL [2-commit-msg-runs]: exit=$RC_2, output:" >&2
    printf '%s\n' "$OUT_2" >&2
    FAILURES=$((FAILURES + 1))
  fi
else
  echo "SKIP [2-commit-msg-runs]: this Git has no 'git hook run --to-stdin'"
  SKIPS=$((SKIPS + 1))
fi

# --- 3. pre-push-runs --------------------------------------------------------
if [ "$HAS_HOOK_RUN" -eq 1 ]; then
  HEAD_SHA="$(git -C "$P" rev-parse HEAD)"
  printf '(delete) 0000000000000000000000000000000000000000 refs/heads/main %s\n' "$HEAD_SHA" > "$TMP/push.txt"
  OUT_3="$(cd "$P" && VAULT_PUSH_GATE= git hook run --to-stdin="$TMP/push.txt" pre-push -- origin "$SRC" 2>&1)"; RC_3=$?
  if [ "$RC_3" -ne 0 ] && printf '%s' "$OUT_3" | grep -q "REFUS : suppression"; then
    echo "ok [3-pre-push-runs]: Git ran .githooks/pre-push, a remote branch deletion was refused"
  else
    echo "FAIL [3-pre-push-runs]: exit=$RC_3, output:" >&2
    printf '%s\n' "$OUT_3" >&2
    FAILURES=$((FAILURES + 1))
  fi
else
  echo "SKIP [3-pre-push-runs]: this Git has no 'git hook run --to-stdin'"
  SKIPS=$((SKIPS + 1))
fi

# --- 4. control-non-executable-hooks-ignored ---------------------------------
# Fixture commit made with hooks switched off for that one command (an
# empty hooks directory), so the fixture itself never needs the guardians.
FIXTURE="$TMP/fixture"
if ! fresh_clone "$SRC" "$FIXTURE"; then
  echo "FAIL: clone impossible pour le temoin" >&2
  exit 1
fi
mkdir -p "$TMP/no-hooks"
(
  cd "$FIXTURE" \
    && for h in $(git ls-files -- .githooks/); do git update-index --chmod=-x -- "$h"; done \
    && git -c core.hooksPath="$TMP/no-hooks" commit -q -m "fixture: hooks at 100644"
) >/dev/null 2>&1
MODES="$(git -C "$FIXTURE" ls-files -s -- .githooks/ | awk '{print $1}' | sort -u)"
C="$TMP/control"
if [ "$MODES" != "100644" ] || ! fresh_clone "$FIXTURE" "$C"; then
  echo "FAIL [4-control]: could not build the 100644 fixture (modes: $MODES)" >&2
  FAILURES=$((FAILURES + 1))
elif [ "$(git -C "$C" config --get core.filemode)" != "true" ]; then
  echo "SKIP [4-control]: core.filemode=false here -- this Git runs hooks whatever their mode, so the 100644 tree cannot be told apart"
  SKIPS=$((SKIPS + 1))
else
  try_commit "$C"
  if [ "$COMMIT_RC" -eq 0 ] && ! printf '%s' "$COMMIT_OUT" | grep -q "=== Guardian suite ==="; then
    echo "ok [4-control]: with the hooks at 100644 Git skips them and the commit goes through unguarded -- case 1 would FAIL on that tree"
  else
    echo "FAIL [4-control]: the 100644 tree still ran the guardians (exit=$COMMIT_RC); case 1 proves nothing. Output:" >&2
    printf '%s\n' "$COMMIT_OUT" >&2
    FAILURES=$((FAILURES + 1))
  fi
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 4 cases, 0 failure, $SKIPS skip(s)"
  exit 0
fi
echo "FAIL: $FAILURES case(s)"
exit 1
