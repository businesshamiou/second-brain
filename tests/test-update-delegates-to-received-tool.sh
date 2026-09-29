#!/usr/bin/env bash
# Mission 231, step 3 (D3 of Mission 230): the update tool hands over to the
# tool of the version it receives.
#
# An installation runs its OWN update tool; when a version changes that tool
# (Mission 230: the USER.md resolution lived in the new tool only), the old
# one kept the old behaviour and refused. Since this Mission, once the version
# is fetched and before merging, the tool compares its own text with the
# version's tools/second-brain-update.sh; when they differ it runs the
# version's tool (extracted from the tag, with --vault) once, and exits with
# its code. It never repairs an installation whose tool predates this change:
# only the NEXT updates are autonomous.
#
# Fixture: a throwaway published source built from this WORKING TREE
# (tests/sandbox-vault.sh, its identity already generated), with five tags:
#   v9.0.0 -- this tree; v9.0.1 -- the update tool gains one marker line;
#   v9.0.2 -- same tool as v9.0.1, one more file; v9.0.3 -- no update tool;
#   v9.0.4 -- a tool that always believes the received tool differs.
# An installation is a clone detached at the tag, its identity generated
# (committed when ensure changes it); each case runs the INSTALLED Vault's own tool.
#   (a) at v9.0.0, update v9.0.1: the received tool runs (its marker is
#       printed), the handover is said once, VERDICT UPDATED, HEAD merges v9.0.1
#       (RED before the fix: the installed tool merged by itself, no marker);
#   (b) witness, same tool: at v9.0.1, update v9.0.2 -- no handover, UPDATED;
#       and update v9.0.1 again -- UP-TO-DATE, no handover;
#   (c) witness, received tool absent: at v9.0.0, update v9.0.3 -- REFUSED,
#       the message names the missing tool, HEAD and porcelain unchanged;
#   (d) witness, no loop: at v9.0.0, update v9.0.4 -- the handover happens
#       once, the received tool (which would hand over again) does not,
#       VERDICT UPDATED.
#
# usage: bash tests/test-update-delegates-to-received-tool.sh
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
has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }
count_of() { printf '%s\n' "$1" | grep -c -- "$2"; }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m231-delegate-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
unset SB_UPDATE_TMP SB_UPDATE_DELEGATED

MARK="MARK-RECEIVED-UPDATE-TOOL"
TOOL=tools/second-brain-update.sh

echo "=== Mission 231 : l'outil de mise a jour passe la main a celui de la version recue ==="
SRC="$TMP/source"
# The working tree, not a clone of HEAD: the test is red, then green, on the
# tool as it is on disk (tests/sandbox-vault.sh).
sandbox_vault "$REPO_ROOT" "$SRC" || { echo "FAIL : source non construite"; exit 1; }
(
  cd "$SRC" || exit 1
  git tag -a v9.0.0 -m v9.0.0
  # v9.0.1: one line printed by the tool, right after `set -u`.
  awk -v m="$MARK" '{print} /^set -u$/ && !d {print "echo \"" m "\""; d=1}' "$TOOL" > .t && cat .t > "$TOOL" && rm -f .t
  git commit -q -am "fixture v9.0.1: the update tool changes" && git tag -a v9.0.1 -m v9.0.1
  printf 'v9.0.2\n' > FIXTURE-v902.txt
  printf 'FIXTURE-v902.txt\tDISTRIBUABLE\n' >> distribution-manifest.txt
  git add -- FIXTURE-v902.txt distribution-manifest.txt && git commit -q -m "fixture v9.0.2: same tool" && git tag -a v9.0.2 -m v9.0.2
  git checkout -q v9.0.0 2>/dev/null
  git rm -q -- "$TOOL" && git commit -q -m "fixture v9.0.3: no update tool" && git tag -a v9.0.3 -m v9.0.3
  git checkout -q v9.0.0 2>/dev/null
  # v9.0.4: the handover test always says "differs" -- the loop guard alone stops it.
  sed 's/^  if \[ "\$RECEIVED_SUM" != "\$OWN_SUM" \]; then$/  if true; then/' "$TOOL" > .t && cat .t > "$TOOL" && rm -f .t
  awk -v m="$MARK-LOOP" '{print} /^set -u$/ && !d {print "echo \"" m "\""; d=1}' "$TOOL" > .t && cat .t > "$TOOL" && rm -f .t
  git commit -q -am "fixture v9.0.4: a tool that would always hand over" && git tag -a v9.0.4 -m v9.0.4
) >/dev/null 2>&1 || { echo "FAIL : etiquettes de la source non posees"; exit 1; }
check "source : cinq etiquettes" [ "$(git -C "$SRC" tag -l 'v9.0.*' | wc -l | tr -d ' ')" = "5" ]
check "source : v9.0.4 force la difference (sinon le temoin (d) ne prouve rien)" \
  sh -c "git -C '$SRC' show v9.0.4:$TOOL | grep -q '^  if true; then\$'"

# install <dir> <tag>: a clone detached at <tag>, its identity generated and committed.
install() {
  git clone -q -- "$SRC" "$1" 2>/dev/null || return 1
  git -C "$1" -c advice.detachedHead=false checkout -q --detach "$2" || return 1
  git -C "$1" config user.name Participant
  git -C "$1" config user.email participant@example.invalid
  git -C "$1" config core.longpaths true
  bash "$1/tools/vault-identity.sh" ensure "$1" >/dev/null 2>&1 || return 1
  [ -z "$(git -C "$1" status --porcelain)" ] && return 0
  git -C "$1" add -- VAULT-IDENTITY.md && git -C "$1" commit -q -m "Generate vault identity" >/dev/null 2>&1
}
same_state() { [ "$(git -C "$1" rev-parse HEAD)" = "$2" ] && [ -z "$(git -C "$1" status --porcelain)" ]; }
merged() { git -C "$1" merge-base --is-ancestor "$2^{commit}" HEAD; }
HANDOVER="second-brain-update.sh"

# --- (a) the received tool runs ----------------------------------------------
A="$TMP/ws-a/second-brain"; mkdir -p "$TMP/ws-a"
install "$A" v9.0.0 || { echo "FAIL : installation (a)"; exit 1; }
OUT_A="$(bash "$A/tools/second-brain-update.sh" v9.0.1 --lang FR 2>&1)"; RC_A=$?
check "(a) l'outil recu a tourne (son marqueur est affiche)" has "$OUT_A" "$MARK"
check "(a) la passation est dite une fois ($(count_of "$OUT_A" 'SB-UPDATE-HANDOVER'))" [ "$(count_of "$OUT_A" 'SB-UPDATE-HANDOVER')" = "1" ]
check "(a) VERDICT: UPDATED, sortie 0 (rc=$RC_A)" sh -c "[ '$RC_A' = 0 ] && [ \"\$(printf '%s\n' \"\$1\" | tail -n 1)\" = 'VERDICT: UPDATED' ]" _ "$OUT_A"
check "(a) HEAD contient v9.0.1, porcelain vide" sh -c "git -C '$A' merge-base --is-ancestor 'v9.0.1^{commit}' HEAD && [ -z \"\$(git -C '$A' status --porcelain)\" ]"
check "(a) l'outil installe est maintenant celui de v9.0.1" sh -c "grep -q '$MARK' '$A/$TOOL'"
[ "$RC_A" = 0 ] || printf '%s\n' "$OUT_A" | tail -n 8 | sed 's/^/      /'

# --- (b) same tool: no handover ------------------------------------------------
B="$TMP/ws-b/second-brain"; mkdir -p "$TMP/ws-b"
install "$B" v9.0.1 || { echo "FAIL : installation (b)"; exit 1; }
OUT_B="$(bash "$B/tools/second-brain-update.sh" v9.0.2 --lang FR 2>&1)"; RC_B=$?
check "(b) meme outil : aucune passation" [ "$(count_of "$OUT_B" 'SB-UPDATE-HANDOVER')" = "0" ]
check "(b) meme outil : VERDICT: UPDATED (rc=$RC_B)" sh -c "[ '$RC_B' = 0 ] && [ \"\$(printf '%s\n' \"\$1\" | tail -n 1)\" = 'VERDICT: UPDATED' ]" _ "$OUT_B"
OUT_B2="$(bash "$B/tools/second-brain-update.sh" v9.0.1 --lang FR 2>&1)"
check "(b) meme version : UP-TO-DATE, aucune passation" sh -c "[ \"\$(printf '%s\n' \"\$1\" | tail -n 1)\" = 'VERDICT: UP-TO-DATE' ] && ! printf '%s' \"\$1\" | grep -q SB-UPDATE-HANDOVER" _ "$OUT_B2"

# --- (c) received tool absent: clear refusal -------------------------------------
C="$TMP/ws-c/second-brain"; mkdir -p "$TMP/ws-c"
install "$C" v9.0.0 || { echo "FAIL : installation (c)"; exit 1; }
C_HEAD="$(git -C "$C" rev-parse HEAD)"
OUT_C="$(bash "$C/tools/second-brain-update.sh" v9.0.3 --lang FR 2>&1)"; RC_C=$?
check "(c) outil recu absent : REFUSED, sortie 1 (rc=$RC_C)" sh -c "[ '$RC_C' = 1 ] && [ \"\$(printf '%s\n' \"\$1\" | tail -n 1)\" = 'VERDICT: REFUSED' ]" _ "$OUT_C"
check "(c) le refus nomme l'outil manquant et la version" sh -c "printf '%s' \"\$1\" | grep -q 'tools/second-brain-update.sh' && printf '%s' \"\$1\" | grep -q 'v9.0.3'" _ "$OUT_C"
check "(c) HEAD et arbre inchanges" same_state "$C" "$C_HEAD"

# --- (d) no loop -------------------------------------------------------------
D="$TMP/ws-d/second-brain"; mkdir -p "$TMP/ws-d"
install "$D" v9.0.0 || { echo "FAIL : installation (d)"; exit 1; }
OUT_D="$(bash "$D/tools/second-brain-update.sh" v9.0.4 --lang FR 2>&1)"; RC_D=$?
check "(d) l'outil recu a tourne une fois ($(count_of "$OUT_D" "$MARK-LOOP") marqueur)" [ "$(count_of "$OUT_D" "$MARK-LOOP")" = "1" ]
check "(d) une seule passation ($(count_of "$OUT_D" 'SB-UPDATE-HANDOVER'))" [ "$(count_of "$OUT_D" 'SB-UPDATE-HANDOVER')" = "1" ]
check "(d) VERDICT: UPDATED (rc=$RC_D)" sh -c "[ '$RC_D' = 0 ] && [ \"\$(printf '%s\n' \"\$1\" | tail -n 1)\" = 'VERDICT: UPDATED' ]" _ "$OUT_D"
[ "$RC_D" = 0 ] || printf '%s\n' "$OUT_D" | tail -n 8 | sed 's/^/      /'

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
