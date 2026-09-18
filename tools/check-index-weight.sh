#!/usr/bin/env bash
# Launch shell (Mission 140): the index-weight guardian now lives
# in tools/check_index_weight.py, run in a single process. The path
# is derived from this script's location -- never from `git rev-parse`, which
# would return the calling repository (any project under pre-commit) and not the vault.
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec uv run "$SCRIPT_DIR/check_index_weight.py" "$@"
