#!/usr/bin/env bash
# Lanceur d'identite (Mission 039, Bloc 2). V1 minimal : un role, un depot,
# aucune table d'agents, aucun clone-vitre.
# Pose VAULT_AGENT et VAULT_ROOT, rappelle role et interdits en une ligne,
# lance claude depuis la racine du Vault.

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
