#!/usr/bin/env bash
# Controle de contenance du serveur MCP du Vault (Decision 2026-09-17-000545,
# A6) : le projet ET son Vault doivent se trouver sous un dossier autorise du
# serveur `second-brain-vault` declare dans une configuration d'outil
# (claude_desktop_config.json, ~/.claude.json, ~/.codex/config.toml).
#
# usage: check-mcp-containment.sh <configuration> <projet>
# Sortie : une ligne PASS/FAIL par chemin, puis le verdict. Code 0 = PASS,
# 1 = FAIL (y compris configuration illisible, serveur absent, Vault non
# resolu). Lecture seule.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/resolve-vault.sh"
HELPER="$SCRIPT_DIR/sb_installer_helper.py"

CONFIG="${1:-}"
PROJECT="${2:-}"
if [ -z "$CONFIG" ] || [ -z "$PROJECT" ]; then
  echo "usage: check-mcp-containment.sh <configuration> <projet>" >&2
  exit 1
fi
if [ ! -d "$PROJECT" ]; then
  echo "FAIL projet introuvable : $PROJECT"
  echo "VERDICT: FAIL"
  exit 1
fi
PROJECT_ABS="$(cd "$PROJECT" && pwd -P)"

if ! resolve_vault "$PROJECT_ABS"; then
  echo "FAIL Vault non résolu : $RV_MESSAGE"
  echo "VERDICT: FAIL"
  exit 1
fi

native() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

OUT="$(uv run --no-project "$HELPER" mcp-containment "$CONFIG" second-brain-vault "$(native "$PROJECT_ABS")" "$(native "$RV_VAULT")")"
RC=$?
printf '%s\n' "$OUT"
if [ "$RC" -eq 0 ]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
