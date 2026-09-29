#!/usr/bin/env bash
# executor-preflight launcher (Mission 231) -- the file a project keeps as
# .claude/hooks/preflight-hook.sh. It holds no check of its own: it finds the
# Vault by walking up to VAULT-ROOT.md, the same reading as the hook, and runs
# the Vault's own skills/project-bootstrap/preflight-hook.sh. A project thus
# never keeps a copy of the checks that ages behind the Vault (the warehouse's
# RELAY 001 was BLOCKED by one, 2026-09-25).
# tools/check-project-conformity.sh reports a project copy that differs from
# this file.
#
# usage: preflight-hook.sh            (in the project, invoked by
#                                      .claude/settings.json, cf. settings-hook.json)
# env  : PREFLIGHT_PROJECT_DIR, PREFLIGHT_VAULT_DIR -- as for the hook; the
#        launcher passes both on.
# Exit: the hook's own (0 = no gap, 2 = refusal); 2 when the Vault's hook
# cannot be found.

set -u

PROJECT_DIR="${PREFLIGHT_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  echo "REFUS executor-preflight : projet introuvable : ${PREFLIGHT_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}" >&2
  exit 2
}
HOOK_REL="skills/project-bootstrap/preflight-hook.sh"

VAULT_DIR="${PREFLIGHT_VAULT_DIR:-}"
if [ -z "$VAULT_DIR" ]; then
  dir="$PROJECT_DIR"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/VAULT-ROOT.md" ]; then
      rel="$(sed -n -E 's/^Chemin relatif du Vault depuis cette racine de travail : `([^`]+)`.*$/\1/p' "$dir/VAULT-ROOT.md" | head -n 1)"
      [ -n "$rel" ] && { VAULT_DIR="$dir/$rel"; break; }
    fi
    dir="$(dirname "$dir")"
  done
fi
if [ -z "$VAULT_DIR" ] || [ ! -f "$VAULT_DIR/$HOOK_REL" ]; then
  echo "REFUS executor-preflight : hook du Vault introuvable (marqueur VAULT-ROOT.md, puis <vault>/$HOOK_REL) en remontant depuis $PROJECT_DIR" >&2
  exit 2
fi
PREFLIGHT_PROJECT_DIR="$PROJECT_DIR" PREFLIGHT_VAULT_DIR="$VAULT_DIR" exec bash "$VAULT_DIR/$HOOK_REL"
