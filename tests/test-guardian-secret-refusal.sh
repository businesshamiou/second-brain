#!/usr/bin/env bash
# Regression test for tools/check-secrets.sh, exercising the exact sequence
# the acceptance playbook calls S5 ("A guardian refuses, then accepts"):
# a commit carrying a fake secret is refused, and once the secret is removed
# the same commit is accepted. Mission 170, step 3 -- no existing suite under
# tests/ drives check-secrets.sh's own refusal path (measured: standalone.sh
# and test-check-private-patterns.sh each run a DIFFERENT guardian --
# check-secrets.sh only ever sees a clean tree in both), so this is new
# coverage rather than a duplicate of either.
#
# Sandbox, never the real second-brain checkout: a throwaway git repo gets
# only a copy of tools/check-secrets.sh and rules/patterns/secret-patterns.txt
# (the exact two files the guardian needs, laid out at the same relative
# paths check-secrets.sh expects -- it derives the patterns file from its own
# script location, never from `git rev-parse --show-toplevel`, see the
# guardian's own header comment). Same minimal-sandbox pattern as
# tests/test-check-private-patterns.sh. Never touches the Owner's real PATH,
# skill folders, or any tracked file in this repository.
#
# Cases:
#   1. clean-commit-passes   -- a plain file stages and passes the guardian.
#   2. secret-detected-refused -- a line matching one of
#      rules/patterns/secret-patterns.txt (a ghp_ GitHub token, the wizard's
#      own example) makes the guardian refuse, naming its refusal literally.
#   3. accepted-after-removal -- removing the secret and re-staging the same
#      path passes the guardian again, unattended.
#
# usage: tests/test-guardian-secret-refusal.sh
# output: "PASS: 3/3 cases" (exit 0) or "FAIL: <n> cases" (exit 1), same
# convention as test-check-private-patterns.sh.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_GUARDIAN="$REPO_ROOT/tools/check-secrets.sh"
REAL_PATTERNS="$REPO_ROOT/rules/patterns/secret-patterns.txt"

if [ ! -f "$REAL_GUARDIAN" ]; then
  echo "FAIL: target script not found: $REAL_GUARDIAN" >&2
  exit 1
fi
if [ ! -f "$REAL_PATTERNS" ]; then
  echo "FAIL: patterns file not found: $REAL_PATTERNS" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0
REPO="$TMP/sandbox"

mkdir -p "$REPO/tools" "$REPO/rules/patterns"
cp "$REAL_GUARDIAN" "$REPO/tools/check-secrets.sh"
# Mission 184 : le gardien source la ligne de base de projet et ses deux
# dependances depuis son propre dossier ; la copie les emporte.
for lib in project-baseline.sh resolve-vault.sh vault-identity.sh; do
  cp "$(dirname "$REAL_GUARDIAN")/$lib" "$REPO/tools/$lib"
done
cp "$REAL_PATTERNS" "$REPO/rules/patterns/secret-patterns.txt"
(
  cd "$REPO" && git init -q -b main \
    && git config user.email t@t \
    && git config user.name t \
    && git config commit.gpgsign false
) || { echo "FAIL: sandbox git init failed" >&2; exit 1; }

# --- 1. clean-commit-passes --------------------------------------------------
printf 'nothing sensitive here\n' > "$REPO/notes.md"
(cd "$REPO" && git add -- notes.md)
OUT_1="$(cd "$REPO" && bash tools/check-secrets.sh 2>&1)"; RC_1=$?
if [ "$RC_1" -eq 0 ]; then
  echo "ok [1-clean-commit-passes]: guardian accepts a clean staged file"
else
  echo "FAIL [1-clean-commit-passes]: exit=$RC_1, output:" >&2
  printf '%s\n' "$OUT_1" >&2
  FAILURES=$((FAILURES + 1))
fi
(cd "$REPO" && git commit -q -m "clean file")

# --- 2. secret-detected-refused ----------------------------------------------
# ghp_ + 20 alnum chars: the wizard's own S5 example, and a literal match for
# rules/patterns/secret-patterns.txt's `ghp_[0-9A-Za-z]{20,}` line. Built from
# two pieces, joined only at runtime inside the sandbox file below: this test
# script's own tracked source must never carry the contiguous string, or this
# very repository's real check-secrets.sh would refuse to let THIS FILE be
# committed the moment it landed here (measured directly while authoring this
# test -- exactly the behavior case 2 exists to prove, just one commit early).
FAKE_TOKEN_PREFIX='ghp_'
FAKE_TOKEN_SUFFIX='ABCDEFGHIJ0123456789ABCD'
printf 'token: %s%s\n' "$FAKE_TOKEN_PREFIX" "$FAKE_TOKEN_SUFFIX" > "$REPO/notes.md"
(cd "$REPO" && git add -- notes.md)
OUT_2="$(cd "$REPO" && bash tools/check-secrets.sh 2>&1)"; RC_2=$?
if [ "$RC_2" -ne 0 ] && printf '%s' "$OUT_2" | grep -q "REFUS : motif de secret detecte"; then
  echo "ok [2-secret-detected-refused]: guardian refuses a staged ghp_ token, names its refusal"
else
  echo "FAIL [2-secret-detected-refused]: exit=$RC_2, output:" >&2
  printf '%s\n' "$OUT_2" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 3. accepted-after-removal ------------------------------------------------
printf 'nothing sensitive here, secret removed\n' > "$REPO/notes.md"
(cd "$REPO" && git add -- notes.md)
OUT_3="$(cd "$REPO" && bash tools/check-secrets.sh 2>&1)"; RC_3=$?
if [ "$RC_3" -eq 0 ]; then
  echo "ok [3-accepted-after-removal]: guardian accepts once the secret is gone"
else
  echo "FAIL [3-accepted-after-removal]: exit=$RC_3, output:" >&2
  printf '%s\n' "$OUT_3" >&2
  FAILURES=$((FAILURES + 1))
fi
(cd "$REPO" && git commit -q -m "secret removed")

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 3/3 cases"
  exit 0
else
  echo "FAIL: $FAILURES cases"
  exit 1
fi
