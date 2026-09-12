#!/usr/bin/env bash
# Coquille de lancement (Mission 140) : le generateur d'index vit desormais
# dans tools/build_indexes.py, execute en un seul processus. Le chemin est
# derive de la position de ce script -- jamais de `git rev-parse`, qui
# rendrait le depot appelant et non le vault.
#
# usage: build-indexes.sh <racine...>
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec uv run "$SCRIPT_DIR/build_indexes.py" "$@"
