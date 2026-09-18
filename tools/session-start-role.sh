#!/usr/bin/env bash
# SessionStart hook (native, not a plugin): injects the executor role for
# CLI sessions opened in the Vault. See RULES-2026-08-23-224706, rung 1.
# Mission 039: wired to the preflight (silent if READY, one line otherwise).
# Mission 069 (doubtful item 7): the Vault path injected into context is
# now computed from the script's position (same technique as
# VAULT_ROOT elsewhere in the tooling), no more hard-coded personal path.
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
