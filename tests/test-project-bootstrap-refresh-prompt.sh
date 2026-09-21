#!/usr/bin/env bash
# Mission 206 (Decision 162812 B, step 4): `project-bootstrap.sh prompt <dossier>`
# regenerates state/PILOT-PROMPT.md of an ADOPTED project when the name of the
# Vault's MCP server changes. The tool never rewrote an existing prompt (adopt notes it
# as existing) and a prompt is "generated, do not edit by hand": without this
# subcommand the prompt of a project could only be edited by hand or deleted.
#
# Oracles (PASS expected), on two throwaway projects -- one in the old format (no
# `mcp_server`, empty links: the workshop's), one in the current format (the
# warehouse's):
#   (a) the prompt names the current server (`second-brain-vault-workspaces`), in the
#       front matter, the "Serveur MCP" line and the opening step; the former name is gone;
#   (b) what belongs to the project is kept: project_id, canary, title, path;
#   (c) the links are no longer empty and point to existing files; vault_ref is the
#       current commit of the Vault;
#   (d) played twice: the second result differs from the first by generated_at only;
#   (e) refusals: a folder with no prompt, a folder that does not exist -- rc 1,
#       nothing created; a Vault with no identity -- rc 1, prompt unchanged.
# Writes only in a temporary folder (m206).
#
# usage: bash tests/test-project-bootstrap-refresh-prompt.sh
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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m206-prompt-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== M206 : le prompt Pilot se regenere sans adopt ==="

mkdir -p "$TMP/ws"
if ! sandbox_vault "$REPO_ROOT" "$TMP/ws/vault"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
V="$TMP/ws/vault"
bash "$V/tools/vault-identity.sh" set-label workspaces "$V" >/dev/null
NAME="$(bash "$V/tools/vault-identity.sh" get server_name "$V")"
check "le Vault jetable porte le nom attendu ($NAME)" [ "$NAME" = "second-brain-vault-workspaces" ]
VAULT_REF="$(git -C "$V" rev-parse HEAD)"
VAULT_ID="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"

# Old format (the workshop's, 2026-09-18): no mcp_server, no "Serveur MCP" line, empty links.
mkdir -p "$TMP/ws/old/state"
cat > "$TMP/ws/old/state/PILOT-PROMPT.md" <<'EOF'
---
type: pilot-prompt
title: "Prompt Pilot — old-project"
description: "Personnalisation, sur le disque, du prompt Pilot commun pour ce projet : chemin, identité du Vault, canari d'ouverture."
status: generated
project_id: 2026-09-18-OLD-PROJECT
canary: "pp-aaaaaaaaaaaa"
vault_id: "sb-0000000000000000"
vault_ref: "0000000000000000000000000000000000000000"
generated_at: "2026-09-18T16:55:31-0400"
---

# PROMPT PILOT — old-project

Généré par `tools/project-bootstrap.sh`. Ne pas éditer à la main : le prompt commun vit dans le Vault, ce fichier ne porte que ce qui est propre à ce projet.

- Chemin du projet : `C:\Users\someone\Workspaces\old-project`
- Vault : `sb-0000000000000000`, construit au commit `0000000000000000000000000000000000000000`
- Canari : `pp-aaaaaaaaaaaa`

## Ouverture Pilot

1. Appelle `list_allowed_directories` du serveur `second-brain-vault` : la liste doit contenir le chemin du projet ci-dessus.
2. Lis ce fichier et rends le canari `pp-aaaaaaaaaaaa` : c'est la preuve que la lecture a eu lieu.
3. Applique le [prompt commun]() et la [charte des rôles]().

## Liens

- `see also` — [Prompt Pilot commun]() (hors Vault)
EOF
# Current format (the warehouse's): the old server name by identity.
mkdir -p "$TMP/ws/new/state"
cat > "$TMP/ws/new/state/PILOT-PROMPT.md" <<'EOF'
---
type: pilot-prompt
title: "Prompt Pilot — New Project"
description: "Personnalisation, sur le disque, du prompt Pilot commun pour ce projet : chemin, identité du Vault, canari d'ouverture."
status: generated
project_id: 2026-09-20-NEW-PROJECT
canary: "pp-bbbbbbbbbbbb"
vault_id: "sb-0000000000000000"
mcp_server: "second-brain-vault-00000000"
vault_ref: "0000000000000000000000000000000000000000"
generated_at: "2026-09-20T13:08:49-0400"
---

# PROMPT PILOT — New Project

Généré par `tools/project-bootstrap.sh`. Ne pas éditer à la main.

- Chemin du projet : `C:\Users\someone\Workspaces\new-project`
- Vault : `sb-0000000000000000`, construit au commit `0000000000000000000000000000000000000000`
- Serveur MCP de ce Vault : `second-brain-vault-00000000`
- Canari : `pp-bbbbbbbbbbbb`

## Ouverture Pilot

1. Appelle `list_allowed_directories` du serveur `second-brain-vault-00000000` : la liste doit contenir le chemin du projet ci-dessus.
2. Lis ce fichier et rends le canari `pp-bbbbbbbbbbbb`.
3. Applique le [prompt commun](../../vault/templates/session-opening-prompt-template.md).
EOF

for p in old new; do
  OUT="$(bash "$V/tools/project-bootstrap.sh" prompt "$TMP/ws/$p" 2>&1)"
  RC=$?
  F="$TMP/ws/$p/state/PILOT-PROMPT.md"
  check "($p) sortie 0" [ "$RC" = "0" ]
  check "($p) (a) front matter : mcp_server: \"$NAME\"" has "$(cat "$F")" "mcp_server: \"$NAME\""
  check "($p) (a) ligne « Serveur MCP de ce Vault » : $NAME" has "$(cat "$F")" "Serveur MCP de ce Vault : \`$NAME\`"
  check "($p) (a) ouverture : serveur \`$NAME\`" has "$(cat "$F")" "du serveur \`$NAME\`"
  check "($p) (a) l'ancien nom a disparu" sh -c "! grep -q 'second-brain-vault-00000000' '$F' && ! grep -q 'serveur \`second-brain-vault\`' '$F'"
  check "($p) (b) canari conserve" has "$(cat "$F")" "canary: \"pp-$([ "$p" = old ] && echo aaaaaaaaaaaa || echo bbbbbbbbbbbb)\""
  check "($p) (b) project_id conserve" has "$(cat "$F")" "project_id: 2026-09-$([ "$p" = old ] && echo 18-OLD-PROJECT || echo 20-NEW-PROJECT)"
  check "($p) (b) chemin du projet conserve" has "$(cat "$F")" "Chemin du projet : \`C:\\Users\\someone\\Workspaces\\$([ "$p" = old ] && echo old-project || echo new-project)\`"
  check "($p) (c) vault_ref = commit courant du Vault" has "$(cat "$F")" "vault_ref: \"$VAULT_REF\""
  check "($p) (c) vault_id = identite courante" has "$(cat "$F")" "vault_id: \"$VAULT_ID\""
  check "($p) (c) aucun lien vide" sh -c "! grep -q '\]()' '$F'"
  LINK="$(sed -n 's/^3\. Applique le \[prompt commun\](\([^)]*\)).*/\1/p' "$F" | head -n 1)"
  check "($p) (c) le lien du prompt commun existe : $LINK" sh -c "[ -n '$LINK' ] && [ -f '$TMP/ws/$p/state/$LINK' ]"
  cp "$F" "$TMP/first-$p.md"
  bash "$V/tools/project-bootstrap.sh" prompt "$TMP/ws/$p" >/dev/null 2>&1
  grep -v '^generated_at:' "$TMP/first-$p.md" > "$TMP/f1-$p.txt"
  grep -v '^generated_at:' "$F" > "$TMP/f2-$p.txt"
  check "($p) (d) second passage : seul generated_at differe" cmp -s "$TMP/f1-$p.txt" "$TMP/f2-$p.txt"
done

# (e) refusals
mkdir -p "$TMP/ws/empty/state"
bash "$V/tools/project-bootstrap.sh" prompt "$TMP/ws/empty" >/dev/null 2>&1
check "(e) dossier sans prompt : sortie 1, rien cree" sh -c "[ '$?' = '1' ] && [ ! -e '$TMP/ws/empty/state/PILOT-PROMPT.md' ]"
bash "$V/tools/project-bootstrap.sh" prompt "$TMP/ws/absent" >/dev/null 2>&1
check "(e) dossier absent : sortie 1" [ "$?" = "1" ]
cp "$TMP/ws/new/state/PILOT-PROMPT.md" "$TMP/before-noid.md"
: > "$V/VAULT-IDENTITY.md"
bash "$V/tools/project-bootstrap.sh" prompt "$TMP/ws/new" >/dev/null 2>&1
RC_NOID=$?
check "(e) Vault sans identite : sortie 1, prompt inchange" sh -c "[ '$RC_NOID' = '1' ] && cmp -s '$TMP/before-noid.md' '$TMP/ws/new/state/PILOT-PROMPT.md'"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
