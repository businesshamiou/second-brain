#!/usr/bin/env bash
# T5 (Mission 198, Decision 230758 B): the private-pattern check stands before
# EVERY push of tools/publish-from-laboratory.sh -- also when `publish` is
# already ahead of release/main and there is nothing new to commit (the path
# that used to push without the check). Played on a SIMULATED laboratory:
# two local bare repositories, `origin` and `release`, with unrelated histories
# (the setup of T1, tests/test-publish-from-laboratory.sh). Nothing real is
# ever pushed.
#
#   (a) witness, the path that commits: a private pattern outside projects/ in
#       the laboratory -> REFUSED, release unchanged (the behaviour that was
#       already there, not regressed);
#   (b) THE witness of the defect, the path that pushes: a commit lands on
#       `publish` by another path (hooks off), publish is ahead of release/main
#       with no new commit, the same private pattern in its tree -> REFUSED,
#       release unchanged, the commit stays on publish;
#   (c) control, no private pattern, the path that commits -> PUBLISHED, the
#       check called exactly once;
#   (d) control, the path that pushes (the push of (c) is rewound on release,
#       so publish is ahead with nothing to commit) -> PUBLISHED, the check
#       called exactly once, release = publish;
#   (e) idempotence: the laboratory already published -> NOTHING-TO-PUBLISH,
#       exit 0, nothing pushed, the check not called (the cost of a no-op does
#       not grow);
#   (f) structure: exactly one call of the check in the tool, before both
#       pushes -- a later edit cannot slip a push past it without this line
#       turning red.
# The private pattern is built at run time and written only in throwaway
# repositories, never in a tracked file of this repository. The tool under
# test is the working-tree one, or PUBLISH_TOOL_SRC=<file> (how the defect is
# replayed against the former version: (b) must then FAIL).
#
# usage: bash tests/test-publish-private-check-before-push.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TOOL_SRC="${PUBLISH_TOOL_SRC:-$REPO_ROOT/tools/publish-from-laboratory.sh}"
[ -f "$TOOL_SRC" ] || { echo "FAIL : outil a tester introuvable : $TOOL_SRC"; exit 1; }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m198-precheck-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
PRIVATE="aios-pro""duction"

echo "=== T5 : le controle des motifs prives precede toute poussee ==="
REF="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference"; exit 1; }

# --- release's root, built once (as in T1): its own history, the published state
RS="$TMP/release-src"
git -c core.longpaths=true clone -q -- "$REF" "$RS" 2>/dev/null || { echo "FAIL : clone"; exit 1; }
(
  cd "$RS" || exit 1
  git config core.longpaths true
  git config user.name release && git config user.email release@example.invalid
  git checkout -q --orphan rel
  cat > VAULT-IDENTITY.md <<'EOF'
---
type: vault-identity
title: "Identity of this Vault — skeleton"
description: "Empty skeleton, replaced at installation by a generated identity (vault_id, vault_origin). No identity before installation."
status: template
vault_id: ""
vault_origin: ""
created_at: ""
---

# IDENTITY OF THIS VAULT

_(This file is generated at installation by `tools/vault-identity.sh ensure`. Before installation, it carries no identity: each installation generates its own.)_

## Liens

- `see also` — [Decision — Project initiation and adoption, birth certificate](./decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
EOF
  for f in projects/PROJECT-20*.md; do [ -e "$f" ] && git rm -q -f -- "$f"; done
  grep -v '^| 20[0-9][0-9]-' projects/PROJECT-REGISTRY.md > .r && mv .r projects/PROJECT-REGISTRY.md
  bash tools/build-indexes.sh "$PWD" >/dev/null 2>&1
  git add -A && git commit -q -m "release root"
) >/dev/null 2>&1 || { echo "FAIL : racine de release non construite"; exit 1; }
git clone -q --bare -- "$REF" "$TMP/origin.git" 2>/dev/null

# world <name> <leak 0|1>: a laboratory and its own `release`, the tool under
# test committed in the laboratory, the check counting its calls into $CNT.
# Sets W, LAB, REL, PUB, CNT, TOOL, R0.
world() {
  W="$TMP/$1"
  mkdir -p "$W/ws"
  REL="$W/release.git"
  git init -q --bare "$REL"
  git -C "$RS" push -q "$REL" rel:main 2>/dev/null || { echo "FAIL : release non poussee ($1)"; exit 1; }
  R0="$(git -C "$REL" rev-parse main)"
  LAB="$W/ws/vault"
  git -c core.longpaths=true clone -q -- "$TMP/origin.git" "$LAB" 2>/dev/null
  git -C "$LAB" checkout -q -B main 2>/dev/null
  git -C "$LAB" config core.longpaths true
  git -C "$LAB" config core.hooksPath .githooks
  git -C "$LAB" config user.name lab && git -C "$LAB" config user.email lab@example.invalid
  git -C "$LAB" remote add release "$REL"
  bash "$LAB/tools/vault-identity.sh" ensure "$LAB" >/dev/null
  cp "$TOOL_SRC" "$LAB/tools/publish-from-laboratory.sh"
  cp "$REPO_ROOT/tools/check-private-patterns.sh" "$LAB/tools/check-private-patterns.sh"
  CNT="$W/check-calls"
  : > "$CNT"
  {
    head -n 1 "$LAB/tools/check-private-patterns.sh"
    echo '[ -z "${M198_COUNT_FILE:-}" ] || echo call >> "$M198_COUNT_FILE"'
    tail -n +2 "$LAB/tools/check-private-patterns.sh"
  } > "$W/check.new" && mv "$W/check.new" "$LAB/tools/check-private-patterns.sh"
  if [ "$2" = "1" ]; then
    mkdir -p "$LAB/notes"
    printf 'a machine path: %s\n' "$PRIVATE" > "$LAB/notes/leak-witness.md"
  fi
  git -C "$LAB" add -A
  git -C "$LAB" -c core.hooksPath=/dev/null commit -q -m "throwaway laboratory state" || { echo "FAIL : etat du laboratoire ($1)"; exit 1; }
  TOOL="$LAB/tools/publish-from-laboratory.sh"
  PUB="$W/ws/m-publish/second-brain"
}
run_tool() { M198_COUNT_FILE="$CNT" bash "$TOOL" 2>&1; }
last() { printf '%s\n' "$1" | tail -n 1; }
rel_head() { git -C "$REL" rev-parse main; }
calls() { wc -l < "$CNT" | tr -d ' '; }

# --- (a) + (b) : a private pattern in the tree ---------------------------------
world leak 1
OUT_A="$(run_tool)"; RC_A=$?
check "(a) temoin, chemin qui commite : motif prive -> REFUSED, release inchangee" sh -c "[ '$RC_A' = '1' ] && [ \"\$1\" = 'REFUSED' ] && [ \"\$(git -C '$REL' rev-parse main)\" = '$R0' ]" _ "$(last "$OUT_A")"
git -C "$PUB" -c core.hooksPath=/dev/null commit -q -m "other path" 2>/dev/null
AHEAD="$(git -C "$LAB" rev-parse publish)"
check "(b) amorce : publish est en avance sur release sans commit neuf a faire" sh -c "[ '$AHEAD' != '$R0' ] && git -C '$LAB' merge-base --is-ancestor '$R0' '$AHEAD'"
: > "$CNT"
OUT_B="$(run_tool)"; RC_B=$?
printf '%s\n' "$OUT_B" | grep '^PUBLISH\|^REFUS' | sed 's/^/    /'
check "(b) TEMOIN de la porte : publish en avance, motif prive -> REFUSED (sortie 1)" sh -c "[ '$RC_B' = '1' ] && [ \"\$1\" = 'REFUSED' ]" _ "$(last "$OUT_B")"
check "(b) rien n'atteint release, le commit reste sur publish" sh -c "[ \"\$(git -C '$REL' rev-parse main)\" = '$R0' ] && [ \"\$(git -C '$LAB' rev-parse publish)\" = '$AHEAD' ]"
check "(b) le controle a ete appele une fois" [ "$(calls)" = "1" ]

# --- (c) + (d) + (e) : no private pattern ---------------------------------------
world clean 0
OUT_C="$(run_tool)"; RC_C=$?
R1="$(rel_head)"
check "(c) chemin qui commite, arbre propre -> PUBLISHED, sortie 0" sh -c "[ '$RC_C' = '0' ] && [ \"\$1\" = 'PUBLISHED $R1' ] && [ '$R1' != '$R0' ]" _ "$(last "$OUT_C")"
check "(c) le controle a ete appele une seule fois" [ "$(calls)" = "1" ]
git -C "$REL" update-ref refs/heads/main "$R0"
: > "$CNT"
OUT_D="$(run_tool)"; RC_D=$?
check "(d) chemin qui pousse (publish en avance), arbre propre -> PUBLISHED, release = publish" sh -c "[ '$RC_D' = '0' ] && [ \"\$1\" = 'PUBLISHED $R1' ] && [ \"\$(git -C '$REL' rev-parse main)\" = '$R1' ]" _ "$(last "$OUT_D")"
check "(d) le controle a ete appele une seule fois" [ "$(calls)" = "1" ]
: > "$CNT"
OUT_E="$(run_tool)"; RC_E=$?
check "(e) deja publie -> NOTHING-TO-PUBLISH, sortie 0, release inchangee" sh -c "[ '$RC_E' = '0' ] && [ \"\$1\" = 'NOTHING-TO-PUBLISH' ] && [ \"\$(git -C '$REL' rev-parse main)\" = '$R1' ]" _ "$(last "$OUT_E")"
check "(e) le controle n'est pas appele quand il n'y a rien a publier" [ "$(calls)" = "0" ]

# --- (f) structure: one call, before both pushes ----------------------------------
CALL_LINES="$(grep -n 'check-private-patterns.sh" --tree-only' "$TOOL_SRC" | grep -v '^[0-9]*:[[:space:]]*#' | cut -d: -f1)"
FIRST_PUSH="$(grep -n 'P push .*release publish:main' "$TOOL_SRC" | head -n 1 | cut -d: -f1)"
check "(f) un seul appel du controle dans l'outil" [ "$(printf '%s\n' "$CALL_LINES" | grep -c .)" = "1" ]
check "(f) l'appel precede toute poussee" sh -c "[ -n '$CALL_LINES' ] && [ -n '$FIRST_PUSH' ] && [ '$CALL_LINES' -lt '$FIRST_PUSH' ]"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
