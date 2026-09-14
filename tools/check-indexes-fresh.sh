#!/usr/bin/env bash
# Coquille de lancement (Mission 137-B) : le gardien vit desormais dans
# tools/check_indexes_fresh.py, execute en un seul processus. Le chemin est
# derive de la position de ce script -- jamais de `git rev-parse`, qui rendrait
# le depot appelant (un projet quelconque sous pre-commit) et non le vault.
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec uv run "$SCRIPT_DIR/check_indexes_fresh.py" "$@"
