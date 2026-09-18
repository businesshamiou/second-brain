#!/usr/bin/env bash
# T2 (Mission 191-C01, Decision 152251 C): the containment check finds the
# server of the project's OWN Vault, by that Vault's identity.
#
# Two throwaway Vaults, one project in each workspace, configurations
# written by hand (no tool, no profile):
#   (a) configuration carrying Vault 1's server only: Vault 1's project PASS;
#       Vault 2's project FAIL -- its own server is absent, and the output
#       names the expected name (the other Vault's server does not count,
#       even when its allowed folder would contain the project);
#   (b) configuration carrying both servers: both projects PASS;
#   (c) negative control: a configuration carrying only the former fixed
#       name `second-brain-vault` -> FAIL naming the expected name.
#
# usage: bash tests/test-check-mcp-containment-per-vault.sh
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
has() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m191-contain-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
N() { sandbox_native_path "$1"; }
NW() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi
}

echo "=== T2 : contenance par identite du Vault ==="
for i in 1 2; do
  mkdir -p "$TMP/ws$i"
  sandbox_vault "$REPO_ROOT" "$TMP/ws$i/second-brain" || { echo "FAIL : Vault $i non construit"; exit 1; }
  bash "$TMP/ws$i/second-brain/tools/write-marker.sh" "$TMP/ws$i" >/dev/null
  bash "$TMP/ws$i/second-brain/tools/project-bootstrap.sh" create "$TMP/ws$i/projet" "Projet $i" --vcs none >/dev/null 2>&1 </dev/null
done
V1="$TMP/ws1/second-brain"
V2="$TMP/ws2/second-brain"
S1="$(bash "$V1/tools/vault-identity.sh" get server_name "$V1")"
S2="$(bash "$V2/tools/vault-identity.sh" get server_name "$V2")"
check "deux projets crees" sh -c "[ -f '$TMP/ws1/projet/.pre-commit-config.yaml' ] && [ -f '$TMP/ws2/projet/.pre-commit-config.yaml' ]"

# entry <name> <workspace>: one mcpServers entry allowed on <workspace> (and
# on the parent of both workspaces, so that containment alone never decides).
entry() {
  printf '"%s": {"command": "uv", "args": ["run", "x", "--vault", "v", "--allow", %s, "--allow", %s]}' \
    "$1" "$(printf '%s' "$(NW "$2")" | uv run --no-project python -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" \
    "$(printf '%s' "$(NW "$TMP")" | uv run --no-project python -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
}
printf '{"mcpServers": {%s}}\n' "$(entry "$S1" "$TMP/ws1")" > "$TMP/one.json"
printf '{"mcpServers": {%s, %s}}\n' "$(entry "$S1" "$TMP/ws1")" "$(entry "$S2" "$TMP/ws2")" > "$TMP/both.json"
printf '{"mcpServers": {%s}}\n' "$(entry "second-brain-vault" "$TMP/ws1")" > "$TMP/legacy.json"

OUT_A1="$(bash "$V1/tools/check-mcp-containment.sh" "$(N "$TMP/one.json")" "$TMP/ws1/projet" 2>&1)"
check "(a) serveur du Vault 1 seul : projet du Vault 1 PASS" sh -c "[ '$?' = '0' ] && case \"\$1\" in *'VERDICT: PASS'*) exit 0;; *) exit 1;; esac" _ "$OUT_A1"
OUT_A2="$(bash "$V1/tools/check-mcp-containment.sh" "$(N "$TMP/one.json")" "$TMP/ws2/projet" 2>&1)"
RC_A2=$?
check "(a) serveur du Vault 1 seul : projet du Vault 2 FAIL" sh -c "[ '$RC_A2' = '1' ] && case \"\$1\" in *'VERDICT: FAIL'*) exit 0;; *) exit 1;; esac" _ "$OUT_A2"
check "(a) ... nommant le serveur attendu ($S2)" has "$OUT_A2" "$S2"

OUT_B1="$(bash "$V1/tools/check-mcp-containment.sh" "$(N "$TMP/both.json")" "$TMP/ws1/projet" 2>&1)"
check "(b) deux serveurs : projet du Vault 1 PASS" has "$OUT_B1" "VERDICT: PASS"
OUT_B2="$(bash "$V2/tools/check-mcp-containment.sh" "$(N "$TMP/both.json")" "$TMP/ws2/projet" 2>&1)"
check "(b) deux serveurs : projet du Vault 2 PASS" has "$OUT_B2" "VERDICT: PASS"

OUT_C="$(bash "$V1/tools/check-mcp-containment.sh" "$(N "$TMP/legacy.json")" "$TMP/ws1/projet" 2>&1)"
RC_C=$?
check "(c) temoin : seul l'ancien nom fixe -> FAIL" [ "$RC_C" = "1" ]
check "(c) temoin : ... nommant le nom attendu ($S1)" has "$OUT_C" "$S1"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
