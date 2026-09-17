#!/usr/bin/env bash
# Coquille de lancement : le plan de reparation des liens casses d'un projet
# adopte vit dans tools/propose_link_repairs.py (Decision 2026-09-17-000545,
# A4). Rend un plan, n'applique rien ; --apply exige --mission <fichier>.
#
# usage: propose-link-repairs.sh <projet> [--apply --mission <fichier MISSION-...>]
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec uv run --no-project "$SCRIPT_DIR/propose_link_repairs.py" "$@"
