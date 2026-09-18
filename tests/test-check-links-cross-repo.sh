#!/usr/bin/env bash
# Non-regression trial (build history, DECISION-2026-09-02-005041) for the
# internal link / outgoing link distinction of tools/check-links.sh: a link
# whose resolved target leaves the root of the current repository is now
# checked only if the target repository (first segment under the workspace
# root) is present on disk -- absent -> warning, never a
# refusal; present -> ordinary check (missing = refusal). Links internal
# to the current repository remain unchanged: missing = refusal, as before.
#
# Method: throwaway sandbox per case (no file of the real corpus touched),
# verbatim copy of the current script from tools/, minimal local Git repository for
# the "current repository" (vaultcanary), parent workspace controlled per case to
# simulate the presence or absence of the target repository.
#
# Four cases (same letters as the original report, build history):
#   (a) outgoing to a repository absent from the workspace -> warning, exit 0.
#   (b) outgoing to a present repository, target missing -> refused.
#   (c) outgoing to a present repository, target present -> silent PASS.
#   (d) internal to the current repository, target missing -> refused (behaviour
#       unchanged since before this Mission).
#
# usage: tests/test-check-links-cross-repo.sh
# output: "PASS: 4/4 cas conformes" (exit 0) or "FAIL: <raison>" (exit 1)

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_SCRIPT="$SCRIPT_DIR/../tools/check-links.sh"

if [ ! -f "$REAL_SCRIPT" ]; then
  echo "FAIL: script cible introuvable : $REAL_SCRIPT" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0

# make_repo <chemin-workspace>: minimal Git sandbox (vaultcanary) under the
# given workspace, target script copied into it.
make_repo() {
  local ws="$1"
  local repo="$ws/vaultcanary"
  mkdir -p "$repo/tools" "$repo/decisions"
  cp "$REAL_SCRIPT" "$repo/tools/check-links.sh"
  # The guardian sources tools/relpath.sh from its own folder (form
  # common to the three platforms, Mission 180): the sandbox copies it
  # too, otherwise it tests a truncated script.
  cp "$SCRIPT_DIR/../tools/relpath.sh" "$repo/tools/relpath.sh"
  # Mission 184: same pattern for the project baseline and its two
  # dependencies, sourced by the guardian from its folder.
  for lib in project-baseline.sh resolve-vault.sh vault-identity.sh; do
    cp "$SCRIPT_DIR/../tools/$lib" "$repo/tools/$lib"
  done
  (cd "$repo" && git init -q && git -c user.email=t@t -c user.name=t config commit.gpgsign false)
  printf '%s\n' "$repo"
}

# run <repo>: stages everything, runs the script, captures output + exit.
run() {
  local repo="$1"
  (cd "$repo" && git add -A >/dev/null 2>&1)
  (cd "$repo" && bash tools/check-links.sh 2>&1)
}

# --- (a) outgoing to absent repository -> warning, exit 0 ---
WS_A="$TMP/case-a"
mkdir -p "$WS_A"
REPO_A="$(make_repo "$WS_A")"
cat > "$REPO_A/decisions/X.md" <<'EOF'
# X

Contenu.

## Liens

- `amended by` — [Cible absente](../../absentrepo/somefile.md) (hors dépôt)
EOF
OUT_A="$(run "$REPO_A")"; RC_A=$?
if [ "$RC_A" -eq 0 ] && printf '%s' "$OUT_A" | grep -q 'avertissement (depot cible absent du disque'; then
  echo "ok [a-sortant-depot-absent]: exit 0, avertissement present"
else
  echo "FAIL [a-sortant-depot-absent]: exit=$RC_A, sortie:" >&2
  printf '%s\n' "$OUT_A" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- (b) outgoing to present repository, target missing -> refused ---
WS_B="$TMP/case-b"
mkdir -p "$WS_B/presentrepo"
REPO_B="$(make_repo "$WS_B")"
cat > "$REPO_B/decisions/X.md" <<'EOF'
# X

Contenu.

## Liens

- `amended by` — [Cible absente](../../presentrepo/does-not-exist.md) (hors dépôt)
EOF
OUT_B="$(run "$REPO_B")"; RC_B=$?
if [ "$RC_B" -ne 0 ] && printf '%s' "$OUT_B" | grep -q 'cible introuvable'; then
  echo "ok [b-sortant-depot-present-cible-absente]: exit != 0, refus present"
else
  echo "FAIL [b-sortant-depot-present-cible-absente]: exit=$RC_B, sortie:" >&2
  printf '%s\n' "$OUT_B" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- (c) outgoing to present repository, target present -> PASS ---
WS_C="$TMP/case-c"
mkdir -p "$WS_C/presentrepo/target"
cat > "$WS_C/presentrepo/target/Y.md" <<'EOF'
# Y
EOF
REPO_C="$(make_repo "$WS_C")"
cat > "$REPO_C/decisions/X.md" <<'EOF'
# X

Contenu.

## Liens

- `amended by` — [Cible presente](../../presentrepo/target/Y.md) (hors dépôt)
EOF
OUT_C="$(run "$REPO_C")"; RC_C=$?
if [ "$RC_C" -eq 0 ] && ! printf '%s' "$OUT_C" | grep -q 'cible introuvable\|avertissement (depot cible'; then
  echo "ok [c-sortant-cible-presente]: exit 0, silencieux"
else
  echo "FAIL [c-sortant-cible-presente]: exit=$RC_C, sortie:" >&2
  printf '%s\n' "$OUT_C" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- (d) internal, target missing -> refused (behaviour unchanged) ---
WS_D="$TMP/case-d"
mkdir -p "$WS_D"
REPO_D="$(make_repo "$WS_D")"
cat > "$REPO_D/decisions/X.md" <<'EOF'
# X

Contenu.

## Liens

- `see also` — [Cible interne absente](./does-not-exist-internal.md)
EOF
OUT_D="$(run "$REPO_D")"; RC_D=$?
if [ "$RC_D" -ne 0 ] && printf '%s' "$OUT_D" | grep -q 'cible introuvable'; then
  echo "ok [d-interne-absent]: exit != 0, refus present"
else
  echo "FAIL [d-interne-absent]: exit=$RC_D, sortie:" >&2
  printf '%s\n' "$OUT_D" >&2
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 4/4 cas conformes"
  exit 0
else
  echo "FAIL: $FAILURES cas non conformes"
  exit 1
fi
