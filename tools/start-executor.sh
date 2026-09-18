#!/usr/bin/env bash
# Identity launcher (Mission 039, Block 2). Minimal V1: one role, one repository,
# no agent table, no glass clone.
# Sets VAULT_AGENT and VAULT_ROOT, recalls role and prohibitions in one line,
# launches claude from the Vault root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

export VAULT_AGENT="executor"
export VAULT_ROOT

echo "role: executor · interdits : git push, suppression sans human gate, appel modele hors mission"

if ! command -v claude >/dev/null 2>&1; then
  echo "ERREUR start-executor.sh : commande 'claude' introuvable dans PATH." >&2
  exit 1
fi

cd "$VAULT_ROOT"
exec claude "$@"
