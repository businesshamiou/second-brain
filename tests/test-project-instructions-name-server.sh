#!/usr/bin/env bash
# T3 (Mission 191-C01, Decision 152251 C, amends 201623 C): the Project
# instructions and the project's Pilot prompt name the MCP server of THIS
# Vault, never the former fixed name.
#
#   (a) the common template names the server through its placeholder
#       `second-brain-vault-{{VAULT_SHORT_ID}}` at every mention, and carries
#       no bare `second-brain-vault`;
#   (b) `project-bootstrap.sh create` renders it: the instructions block names
#       second-brain-vault-<8 characters of vault_id>, the exclusivity
#       sentence (server + "outside the perimeter", same line) is intact, no
#       placeholder is left; state/PILOT-PROMPT.md carries the same name
#       (front matter `mcp_server` and the opening step);
#   (c) negative control: a copy of the template with the fixed name fails (a).
#
# usage: bash tests/test-project-instructions-name-server.sh
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
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m191-instr-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

prompt_block() {
  tr -d '\r' < "$1" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p'
}
# template_names_per_vault <template>: 0 if every server mention of the block
# carries the placeholder and no bare fixed name is left.
template_names_per_vault() {
  local block
  block="$(prompt_block "$1")"
  [ -n "$block" ] || return 1
  [ "$(printf '%s\n' "$block" | grep -o 'second-brain-vault-{{VAULT_SHORT_ID}}' | wc -l | tr -d ' ')" -ge 2 ] || return 1
  ! printf '%s\n' "$block" | grep -q 'second-brain-vault`'
}

echo "=== T3 : les instructions du projet nomment le serveur de ce Vault ==="
TEMPLATE="$REPO_ROOT/templates/session-opening-prompt-template.md"
check "(a) gabarit : nom par espace reserve a chaque mention, aucun nom fixe" template_names_per_vault "$TEMPLATE"

WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null
SERVER="$(bash "$V/tools/vault-identity.sh" get server_name "$V")"
OUT="$(bash "$V/tools/project-bootstrap.sh" create "$WS/projet" "Projet" --vcs none --lang FR 2>&1 </dev/null)"
check "(b) create rend 0" [ "$?" = "0" ]
BLOCK="$(printf '%s\n' "$OUT" | sed -n '/^  ---$/,/^  ---$/p')"
check "(b) bloc d'instructions rendu" [ -n "$BLOCK" ]
check "(b) le bloc nomme $SERVER (deux mentions)" [ "$(printf '%s\n' "$BLOCK" | grep -o "$SERVER" | wc -l | tr -d ' ')" -ge 2 ]
check "(b) aucun espace reserve restant" sh -c "! printf '%s\n' \"\$1\" | grep -q '{{VAULT_SHORT_ID}}'" _ "$BLOCK"
check "(b) aucun nom fixe restant" sh -c "! printf '%s\n' \"\$1\" | grep -q 'second-brain-vault\`'" _ "$BLOCK"
check "(b) exclusivite intacte ($SERVER + outside the perimeter, meme ligne)" sh -c "printf '%s\n' \"\$1\" | grep '$SERVER' | grep -q 'outside the perimeter'" _ "$BLOCK"
PP="$WS/projet/state/PILOT-PROMPT.md"
check "(b) PILOT-PROMPT.md : mcp_server = $SERVER" grep -qx "mcp_server: \"$SERVER\"" "$PP"
check "(b) PILOT-PROMPT.md : l'ouverture appelle $SERVER" sh -c "grep 'list_allowed_directories' '$PP' | grep -q '$SERVER'"
check "(b) PILOT-PROMPT.md : aucun nom fixe" sh -c "! grep -q 'second-brain-vault\`' '$PP'"

WITNESS="$TMP/fixed-name-template.md"
sed 's/second-brain-vault-{{VAULT_SHORT_ID}}/second-brain-vault/g' "$TEMPLATE" > "$WITNESS"
if template_names_per_vault "$WITNESS"; then
  fail "(c) temoin : un gabarit au nom fixe passe quand meme"
else
  pass "(c) temoin : un gabarit au nom fixe echoue"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
