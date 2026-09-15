#!/usr/bin/env bash
# SessionStart hook (native, not a plugin): injects the executor role for
# CLI sessions opened in the Vault. See RULES-2026-08-23-224706, barreau 1.
# Mission 039 : cable au preflight (silence si READY, une ligne sinon).
# Mission 069 (douteux 7) : le chemin du Vault injecte en contexte se
# calcule desormais depuis la position du script (meme technique que
# VAULT_ROOT ailleurs dans l'outillage), plus de chemin personnel en dur.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREFLIGHT="$SCRIPT_DIR/session-preflight.sh"
VAULT_ROOT_DISPLAY="$(cd "$SCRIPT_DIR/.." && { pwd -W 2>/dev/null || pwd; })"

CONTEXT="role: executor\nvault root: ${VAULT_ROOT_DISPLAY}\ncharter: rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md\nforbidden: git push - announce role in first message"

if [ -x "$PREFLIGHT" ]; then
  PREFLIGHT_OUT="$(bash "$PREFLIGHT" 2>/dev/null || true)"
  case "$PREFLIGHT_OUT" in
    NOT-READY*)
      CONTEXT="${CONTEXT}\nPreflight ${PREFLIGHT_OUT}, see .claude/.preflight_stamp.json"
      ;;
  esac
fi

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$CONTEXT"
