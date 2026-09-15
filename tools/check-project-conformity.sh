#!/usr/bin/env bash
# Constate la conformite d'un projet au standard de structure de projet
# (sept fonctions, RULES-2026-08-26-142800-project-structure-standard.md).
# Jamais bloquant, jamais correcteur : mesure et rapporte, ne corrige rien
# (registry v1 D4 point 3 et D6).
#
# usage: check-project-conformity.sh [chemin-projet]
# Par defaut : repertoire courant.
#
# Localise la racine de travail par marqueur remonte (VAULT-ROOT.md, proposal
# 122144 S2.1) : aucune racine en dur. Sortie stdout : "CONFORME" ou
# "ECART: <manque1, manque2, ...>". Code retour : 0 dans les deux cas de
# verdict rendu ; non nul seulement si la mesure elle-meme echoue (marqueur
# introuvable, chemin projet inexistant).

set -u

PROJECT="${1:-.}"

if [ ! -d "$PROJECT" ]; then
  echo "REFUS : chemin de projet introuvable : $PROJECT" >&2
  exit 1
fi

PROJECT_ABS="$(cd "$PROJECT" && pwd)"

find_workspace_root() {
  local dir="$1"
  while [ -n "$dir" ]; do
    if [ -f "$dir/VAULT-ROOT.md" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    [ "$dir" = "/" ] && break
    dir="$(dirname "$dir")"
  done
  return 1
}

WORKSPACE_ROOT="$(find_workspace_root "$PROJECT_ABS")"
if [ -z "$WORKSPACE_ROOT" ]; then
  echo "REFUS : marqueur VAULT-ROOT.md introuvable en remontant depuis $PROJECT_ABS" >&2
  exit 1
fi

MARKER="$WORKSPACE_ROOT/VAULT-ROOT.md"
VAULT_REL="$(grep -oE 'racine de travail : `[^`]+`' "$MARKER" | sed -E 's/.*`([^`]+)`.*/\1/')"
if [ -z "$VAULT_REL" ]; then
  echo "REFUS : chemin du Vault illisible dans $MARKER" >&2
  exit 1
fi
REGISTRY="$WORKSPACE_ROOT/$VAULT_REL/projects/PROJECT-REGISTRY.md"

# --- 1. Sept fonctions : squelette de la RULES-2026-08-26-142800, S2 ---
MISSING=""
for ITEM in README.md rules state missions decisions proposals knowledge handoffs; do
  if [ ! -e "$PROJECT_ABS/$ITEM" ]; then
    MISSING="$MISSING${MISSING:+, }$ITEM"
  fi
done

# --- 2. Inscription au registre (chemin relatif au parent du Vault) ---
PROJECT_REL="$(realpath --relative-to="$WORKSPACE_ROOT" "$PROJECT_ABS")"
if [ -f "$REGISTRY" ]; then
  if ! grep -qF "$PROJECT_REL" "$REGISTRY"; then
    MISSING="$MISSING${MISSING:+, }inscription au registre ($PROJECT_REL)"
  fi
else
  MISSING="$MISSING${MISSING:+, }registre introuvable ($REGISTRY)"
fi

if [ -z "$MISSING" ]; then
  echo "CONFORME"
else
  echo "ÉCART: $MISSING"
fi

exit 0
