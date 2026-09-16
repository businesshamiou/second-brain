#!/usr/bin/env bash
# Offline-commit test for the acceptance playbook's S10 ("Disconnect the
# network, then make a commit inside the project. Expected: the guardians
# still run and still decide -- accept or refuse -- with no network call.").
# Mission 170, step 3: no existing suite exercises this (measured --
# tests/test-questionnaire-network-failure.ps1 is a DIFFERENT scenario, the
# installer's own prerequisites download going dark, not a project commit's
# guardians; grep across tests/ for "check-secrets|ghp_|secret-patterns"
# turned up nothing else offline-commit shaped either), so this is new
# coverage, built by reusing tests/standalone.sh rather than duplicating its
# clone-and-commit machinery.
#
# Two cases:
#   1. static-no-network-call -- none of the tools/*.sh|py paths named in
#      .githooks/pre-commit (read from that file itself, never a hand-kept
#      copy that could drift) contains an obvious network primitive (curl,
#      wget, Invoke-WebRequest, or a Python HTTP client). That set is a
#      superset of the 7 guardian scripts the dispatcher actually runs at
#      commit time (the 8th guardian, "preflight", is an inline function
#      there that only reads a local stamp file) -- it also catches
#      tools/session-preflight.sh, which the same file names only inside a
#      remedy message, never invokes live. Scanning the superset costs
#      nothing and never under-checks.
#   2. dynamic-commit-survives-poisoned-network -- tests/standalone.sh (its
#      own clone-install-commit-through-all-8-guardians proof, Mission 142)
#      is re-run with HTTP(S)_PROXY pointed at an unreachable local port
#      (127.0.0.1:1 -- nothing listens there, so any attempted HTTP call
#      fails immediately instead of silently succeeding or hanging) for that
#      child process only. It still has to pass end to end: the guardians'
#      verdict cannot depend on reaching the network. The proxy variables are
#      exported only into that one subprocess, never into the real user
#      environment, and are unset again once it returns either way.
#
# usage: tests/test-guardian-offline-commit.sh
# output: "PASS: 2/2 cases" (exit 0) or "FAIL: <n> cases" (exit 1), same
# convention as test-check-private-patterns.sh and
# test-guardian-secret-refusal.sh.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRE_COMMIT="$REPO_ROOT/.githooks/pre-commit"
STANDALONE="$SCRIPT_DIR/standalone.sh"

if [ ! -f "$PRE_COMMIT" ]; then
  echo "FAIL: pre-commit dispatcher not found: $PRE_COMMIT" >&2
  exit 1
fi
if [ ! -f "$STANDALONE" ]; then
  echo "FAIL: tests/standalone.sh not found: $STANDALONE" >&2
  exit 1
fi

FAILURES=0

# --- 1. static-no-network-call -----------------------------------------------
# Extract the guardian script paths the dispatcher itself declares
# (add_guardian lines reference tools/<name>.{sh,py} under $VAULT_ROOT) --
# read from .githooks/pre-commit, never hand-copied, so a future guardian
# added there is picked up automatically instead of silently unchecked here.
# Boucle de lecture plutot que `mapfile`, absent du bash 3.2 de macOS
# (Mission 180, meme famille que le test de flux nominal).
GUARDIAN_SCRIPTS=()
while IFS= read -r guardian_path; do
  if [ -n "$guardian_path" ]; then
    GUARDIAN_SCRIPTS+=("$guardian_path")
  fi
done < <(grep -oE 'tools/[A-Za-z0-9_.-]+\.(sh|py)' "$PRE_COMMIT" | sort -u)

if [ "${#GUARDIAN_SCRIPTS[@]}" -eq 0 ]; then
  echo "FAIL [1-static-no-network-call]: no guardian scripts parsed out of $PRE_COMMIT" >&2
  FAILURES=$((FAILURES + 1))
else
  NETWORK_HITS=""
  for rel in "${GUARDIAN_SCRIPTS[@]}"; do
    abs="$REPO_ROOT/$rel"
    if [ ! -f "$abs" ]; then
      NETWORK_HITS="${NETWORK_HITS}${rel}: file missing\n"
      continue
    fi
    hit="$(grep -nE 'curl|wget|Invoke-WebRequest|urllib|requests\.(get|post)|http\.client|socket\.connect' "$abs" || true)"
    if [ -n "$hit" ]; then
      NETWORK_HITS="${NETWORK_HITS}${rel}:\n${hit}\n"
    fi
  done
  if [ -z "$NETWORK_HITS" ]; then
    echo "ok [1-static-no-network-call]: ${#GUARDIAN_SCRIPTS[@]} script(s) named in .githooks/pre-commit checked, none call the network"
  else
    echo "FAIL [1-static-no-network-call]: possible network call(s) found:" >&2
    printf '%b' "$NETWORK_HITS" >&2
    FAILURES=$((FAILURES + 1))
  fi
fi

# --- 2. dynamic-commit-survives-poisoned-network -----------------------------
# 127.0.0.1:1 is a loopback port no service binds to -- a real HTTP attempt
# fails (connection refused) immediately rather than hanging on a timeout.
# Exported for this one subprocess only via env-prefix assignment, never
# written to the real user environment, and never touching the real network
# adapter or proxy settings.
TMP_WORKDIR="$(mktemp -d -t sb-offline-commit-XXXXXX)"
OUT_2="$(HTTP_PROXY='http://127.0.0.1:1' HTTPS_PROXY='http://127.0.0.1:1' \
  http_proxy='http://127.0.0.1:1' https_proxy='http://127.0.0.1:1' \
  bash "$STANDALONE" "$TMP_WORKDIR" 2>&1)"
RC_2=$?
rm -rf "$TMP_WORKDIR"
if [ "$RC_2" -eq 0 ] && printf '%s' "$OUT_2" | grep -q "PASS"; then
  echo "ok [2-dynamic-commit-survives-poisoned-network]: standalone.sh's full guardian-gated commit still passes with outbound HTTP forced to fail"
else
  echo "FAIL [2-dynamic-commit-survives-poisoned-network]: exit=$RC_2, output:" >&2
  printf '%s\n' "$OUT_2" >&2
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 2/2 cases"
  exit 0
else
  echo "FAIL: $FAILURES cases"
  exit 1
fi
