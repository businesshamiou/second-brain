#!/usr/bin/env bash
# Ecrit VAULT-ROOT.md a la racine de travail depuis templates/vault-root-template.md.
# Nom de fichier : choix du Pilot, revisable.
#
# usage: write-marker.sh <racine-de-travail> [nom-du-vault]

set -u

WORK_ROOT="${1:-}"
VAULT_NAME="${2:-Brian}"

if [ -z "$WORK_ROOT" ]; then
  echo "usage: write-marker.sh <racine-de-travail> [nom-du-vault]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$VAULT_ROOT/templates/vault-root-template.md"

if [ ! -f "$TEMPLATE" ]; then
  echo "REFUS : gabarit introuvable : $TEMPLATE" >&2
  exit 1
fi

mkdir -p "$WORK_ROOT"
WORK_ROOT_ABS="$(cd "$WORK_ROOT" && pwd)"
REL_PATH="$(realpath --relative-to="$WORK_ROOT_ABS" "$VAULT_ROOT")"

MARKER="$WORK_ROOT_ABS/VAULT-ROOT.md"

# Le gabarit est ecrit et verifie (check-links.sh) depuis templates/ a la
# racine du Vault, ou ses liens relatifs (../decisions/...) sont corrects. Copie a la racine de
# travail, ces memes liens doivent pointer via le chemin relatif du Vault
# calcule ci-dessus : on les reecrit au moment de la generation.
sed \
  -e "s#{{VAULT_NAME}}#$VAULT_NAME#g" \
  -e "s#{{VAULT_RELATIVE_PATH}}#$REL_PATH#g" \
  -e "s#](\.\./#]($REL_PATH/#g" \
  "$TEMPLATE" > "$MARKER"

echo "$MARKER"
