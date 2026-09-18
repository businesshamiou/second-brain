#!/usr/bin/env bash
# Launch shell: the plan for repairing the broken links of an adopted project
# lives in tools/propose_link_repairs.py (Decision 2026-09-17-000545,
# A4). Returns a plan, applies nothing; --apply requires --mission <file>.
#
# usage: propose-link-repairs.sh <project> [--apply --mission <MISSION-... file>]
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec uv run --no-project "$SCRIPT_DIR/propose_link_repairs.py" "$@"
