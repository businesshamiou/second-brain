#!/usr/bin/env bash
# Writes VAULT-ROOT.md at the work root from templates/vault-root-template.md.
# File name: the Pilot's choice, open to revision.
#
# usage: write-marker.sh [--marker-only] <work-root> [vault-name]
#
# --marker-only (Mission 203, report 202 A3): writes VAULT-ROOT.md and nothing
# else. Without it the script also writes the workspace-level CLAUDE.md and
# AGENTS.md at <work-root> -- right for a workspace root, wrong for a project
# root, whose own CLAUDE.md and AGENTS.md it would overwrite. Default unchanged.

set -u

MARKER_ONLY=0
if [ "${1:-}" = "--marker-only" ]; then
  MARKER_ONLY=1
  shift
fi

WORK_ROOT="${1:-}"
VAULT_NAME="${2:-Brian}"

if [ -z "$WORK_ROOT" ]; then
  echo "usage: write-marker.sh [--marker-only] <racine-de-travail> [nom-du-vault]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/relpath.sh"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$VAULT_ROOT/templates/vault-root-template.md"

if [ ! -f "$TEMPLATE" ]; then
  echo "REFUS : gabarit introuvable : $TEMPLATE" >&2
  exit 1
fi

mkdir -p "$WORK_ROOT"
WORK_ROOT_ABS="$(cd "$WORK_ROOT" && pwd)"
REL_PATH="$(rel_path "$WORK_ROOT_ABS" "$VAULT_ROOT")"

MARKER="$WORK_ROOT_ABS/VAULT-ROOT.md"

# Vault identity (Decision 2026-09-17-000545, A7): generated if missing,
# carried by the marker so that two Vaults on the same machine can be told apart.
. "$SCRIPT_DIR/vault-identity.sh"
vid_ensure "$VAULT_ROOT"
sed_escape() {
  printf '%s' "$1" | sed 's/[#&\\]/\\&/g'
}
VAULT_ID_ESC="$(sed_escape "$(vid_get "$VAULT_ROOT" vault_id)")"
VAULT_ORIGIN_ESC="$(sed_escape "$(vid_get "$VAULT_ROOT" vault_origin)")"

# The template is written and checked (check-links.sh) from templates/ at the
# Vault root, where its relative links (../decisions/...) are correct. Copied to the work
# root, those same links must point through the relative Vault path
# computed above: they are rewritten at generation time.
sed \
  -e "s#{{VAULT_NAME}}#$VAULT_NAME#g" \
  -e "s#{{VAULT_RELATIVE_PATH}}#$REL_PATH#g" \
  -e "s#{{VAULT_ID}}#$VAULT_ID_ESC#g" \
  -e "s#{{VAULT_ORIGIN}}#$VAULT_ORIGIN_ESC#g" \
  -e "s#](\.\./#]($REL_PATH/#g" \
  "$TEMPLATE" > "$MARKER"

# --- Workspace-level CLAUDE.md and AGENTS.md (Mission 173, Q17:
# three-level hierarchy). Placed here, never under 10 lines, next to
# VAULT-ROOT.md -- outside any Git repository (the workspace itself is
# not one), so never tracked, never subject to the guardians or to the link
# standard of second-brain. Identical content in both files (same
# instruction as the second-brain and project levels). Idempotent: rewritten at
# each installation (the assistant's name may change), never appended. ---
if [ "$MARKER_ONLY" = "0" ]; then
WORKSPACE_GUIDE_CONTENT="La méthode de ce workspace vit dans \`$REL_PATH/\` (Second Brain) : règles, skills, assistant.

Ouvrir une session : lire \`$REL_PATH/skills/session-start/SKILL.md\`.

Poser une question : « Demande à $VAULT_NAME : ... » — il cite ses sources par chemin. Sans le nommer, l'agent principal peut répondre à sa place, sans garantie de lecture seule."

printf '%s\n' "$WORKSPACE_GUIDE_CONTENT" > "$WORK_ROOT_ABS/CLAUDE.md"
printf '%s\n' "$WORKSPACE_GUIDE_CONTENT" > "$WORK_ROOT_ABS/AGENTS.md"
fi

echo "$MARKER"
