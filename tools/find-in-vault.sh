#!/usr/bin/env bash
# Recherche par contenu dans les fichiers .md sous une racine.
# Renvoie les lignes trouvees, jamais les fichiers : un resultat par ligne,
# format "chemin:numero-de-ligne:texte", suffixe de " [REMPLACÉ]" quand le
# fichier source figure dans <racine>/superseded-files.txt (liste produite
# par tools/build-indexes.sh, objectif B, Mission 029). La ligne reste
# toujours renvoyee, jamais filtree. Liste absente => recherche sans marque,
# sans erreur. La marque n'est fraiche qu'a la derniere generation des index
# (build-indexes.sh) : un supersedes ajoute apres coup n'apparait qu'apres
# une regeneration.
#
# usage: find-in-vault.sh [--root <dir>] [--limit N] [--frontmatter-only] <motif>

set -u

ROOT="."
LIMIT=50
FM_ONLY=0
PATTERN=""
HAVE_PATTERN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      ROOT="${2:-.}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-50}"
      shift 2
      ;;
    --frontmatter-only)
      FM_ONLY=1
      shift
      ;;
    --)
      shift
      if [ "$#" -gt 0 ]; then PATTERN="$1"; HAVE_PATTERN=1; shift; fi
      ;;
    *)
      PATTERN="$1"
      HAVE_PATTERN=1
      shift
      ;;
  esac
done

if [ "$HAVE_PATTERN" -ne 1 ] || [ -z "$PATTERN" ]; then
  echo "usage: find-in-vault.sh [--root <dir>] [--limit N] [--frontmatter-only] <motif>" >&2
  exit 1
fi

if [ ! -d "$ROOT" ]; then
  echo "REFUS : racine introuvable : $ROOT" >&2
  exit 1
fi

EXCLUDE_RE='(^|/)(\.git|\.githooks|\.claude|\.codex|graphify-out|node_modules|\.venv|venv|__pycache__)(/|$)'

# --- Marquage des documents remplaces (objectif B, Mission 029) ---
# La liste superseded-files.txt est ecrite par build-indexes.sh a la racine
# qui lui a ete passee ; comme le defaut de racine de ce script reste le
# repertoire courant de l'appelant (OPEN 1, Mission 027, hors perimetre de
# la Mission 029), cette racine peut differer de celle de generation (ex.
# appel depuis workshop-build, liste ecrite sous workshop-production/). On
# cherche donc le fichier n'importe ou sous $ROOT, pas seulement a sa racine.
declare -A SUPERSEDED_BASENAMES=()
while IFS= read -r SUP_LIST_FILE; do
  [ -z "$SUP_LIST_FILE" ] && continue
  while IFS= read -r SUP_REL; do
    [ -z "$SUP_REL" ] && continue
    SUPERSEDED_BASENAMES["${SUP_REL##*/}"]=1
  done < "$SUP_LIST_FILE"
done < <(find "$ROOT" -type f -name 'superseded-files.txt' 2>/dev/null | grep -vE "$EXCLUDE_RE")

mark_superseded() {
  while IFS= read -r RESLINE; do
    RESPATH="${RESLINE%%:*}"
    RESFN="$(basename "$RESPATH")"
    if [ -n "${SUPERSEDED_BASENAMES[$RESFN]+x}" ]; then
      printf '%s [REMPLACÉ]\n' "$RESLINE"
    else
      printf '%s\n' "$RESLINE"
    fi
  done
}

if [ "$FM_ONLY" -eq 1 ]; then
  # Mode front-matter : les bornes "---" different par fichier (FNR), mais un
  # seul processus awk traite tous les fichiers passes en argument (rapide).
  FILES="$(find "$ROOT" -type f -name '*.md' | grep -vE "$EXCLUDE_RE")"
  if [ -n "$FILES" ]; then
    printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 awk -v pat="$PATTERN" '
      FNR==1 { infm=0 }
      FNR==1 && $0=="---" { infm=1; next }
      infm && $0=="---" { infm=0; next }
      infm && $0 ~ pat { print FILENAME ":" FNR ":" $0 }
    ' 2>/dev/null
  fi
else
  grep -rnE --include='*.md' -- "$PATTERN" "$ROOT" 2>/dev/null | grep -vE "$EXCLUDE_RE"
fi | mark_superseded | head -n "$LIMIT"
