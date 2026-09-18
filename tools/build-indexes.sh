#!/usr/bin/env bash
# Launch shell (Mission 140): the index generator now lives
# in tools/build_indexes.py, run in a single process. The path is
# derived from this script's location -- never from `git rev-parse`, which
# would return the calling repository and not the vault.
#
# usage: build-indexes.sh <racine...>
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec uv run "$SCRIPT_DIR/build_indexes.py" "$@"
