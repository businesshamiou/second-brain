#!/usr/bin/env bash
# Ajoute une ligne horodatee en fin de journal d'un projet.
# N'ouvre jamais le fichier en lecture ; ne reecrit jamais une ligne existante.
# Cree le fichier et son dossier s'ils n'existent pas.
#
# usage: append-journal.sh <chemin-projet> "<texte>"
#
# --- Cablage memoire externe : retire (Mission 147) ------------------------------
# Un cablage fail-open alimentait une banque memoire externe apres l'ecriture de
# la ligne (Mission 122). Il est retire : le benchmark de la Mission 146 a mesure
# l'outil sur dix questions et un corpus fige, la Decision 113850 a tranche le
# retrait. Le comportement de ce script est inchange par ce retrait : meme ligne
# ecrite, meme code de sortie -- invariance prouvee par diff a la Mission 147.
# L'ecriture memoire n'a jamais ete une source d'etat : le journal l'est.

set -u

PROJECT="${1:-}"
TEXT="${2:-}"

if [ -z "$PROJECT" ] || [ -z "$TEXT" ]; then
  echo "usage: append-journal.sh <chemin-projet> \"<texte>\"" >&2
  exit 1
fi

# --- Butee 300 caracteres (Decision 191407, Mission 123) ------------------------
# Fail-closed, avant toute ecriture : le texte fourni par l'appelant (hors
# horodatage, prefixe par ce script lui-meme plus bas) ne doit jamais depasser
# MAX_LINE_CHARS. Comptage en caracteres (wc -m), pas en octets -- coherent
# avec la convention deja mesuree aux Missions 121/122 sur la ligne STATE:.
# Refus sans rien ecrire.
MAX_LINE_CHARS=300

TEXT_LEN="$(printf '%s' "$TEXT" | wc -m)"
if [ "$TEXT_LEN" -gt "$MAX_LINE_CHARS" ]; then
  echo "REFUS append-journal.sh : ligne de $TEXT_LEN caracteres, plafond $MAX_LINE_CHARS (Decision 191407). Rien ecrit." >&2
  exit 1
fi

STATE_DIR="$PROJECT/state"
JOURNAL="$STATE_DIR/journal.md"

mkdir -p "$STATE_DIR"

if [ ! -f "$JOURNAL" ]; then
  # Mission 168, ticket 03 : section "## Liens" ajoutee des la creation --
  # tools/check-links.sh l'exige sur tout .md hors skills/external et
  # skills-warehouse (RULES-2026-08-21-115658-document-linking-standard.md).
  # Le lien pointe vers le README du projet lui-meme : toujours present (ecrit
  # par project-bootstrap.sh avant cet appel) et independant de la geometrie
  # du workspace (aucune hypothese sur un depot voisin).
  PROJECT_NAME="$(basename "$PROJECT")"
  printf '# Journal — %s\n\nJournal en ajout seul. Genere/alimente par tools/append-journal.sh, jamais edite a la main.\n\n## Liens\n\n- `see also` — [%s](../README.md)\n\n' "$PROJECT_NAME" "$PROJECT_NAME" > "$JOURNAL"
fi

TS="$(date +"%Y-%m-%dT%H:%M:%S%:z")"
printf '%s %s\n' "$TS" "$TEXT" >> "$JOURNAL"
APPEND_STATUS=$?

# Capture explicite du code de sortie de l'ecriture, pour ne pas laisser la
# derniere commande du fichier decider du code de sortie du script.
exit "$APPEND_STATUS"
