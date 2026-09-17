#!/usr/bin/env bash
# Controle de secrets sur les lignes ajoutees d un diff stage.
# Shell portable : aucune dependance a Python.
# Le refus est la position par defaut : toute condition anormale bloque.

set -u

# Mission 168, ticket 03 : plus de `git rev-parse --show-toplevel` pour
# localiser le fichier de motifs -- ce chemin doit toujours pointer vers CE
# depot (second-brain), jamais vers le depot appelant quand ce gardien est
# reutilise par un projet voisin (repo: local, tools/project-bootstrap.sh) :
# `--show-toplevel` y rend la racine du projet voisin, pas celle-ci. Meme
# cause et meme remede que tools/check-indexes-fresh.sh et
# tools/check-index-weight.sh (Mission 137-B / 140) : chemin derive de la
# position de ce script, jamais du depot appelant.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PATTERNS_FILE="$VAULT_ROOT/rules/patterns/secret-patterns.txt"
. "$SCRIPT_DIR/project-baseline.sh"

# usage: check-secrets.sh             (depot courant, diff stage)
#        check-secrets.sh <projet>    (mode dossier, sans Git : contenu entier
#                                      de chaque fichier -- vcs: none,
#                                      Decision 000545 A4)
DIR_MODE=0
if [ -n "${1:-}" ]; then
  if [ ! -d "$1" ]; then
    echo "REFUS : dossier de projet introuvable : $1" >&2
    exit 1
  fi
  DIR_MODE=1
  PROJECT_ROOT="$(cd "$1" && pwd)"
else
  # Garde Git (Mission 125) : hors d'un depot, `git diff --cached` plus bas
  # echouerait silencieusement (staged vide, un saut pris a tort pour un PASS).
  # Refus explicite ici, avant tout diff -- ne sert plus a localiser un chemin.
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "REFUS : hors d'un depot Git : gardien non executable." >&2
    exit 1
  }
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
fi

if [ ! -f "$PATTERNS_FILE" ]; then
  echo "REFUS : fichier de motifs introuvable : $PATTERNS_FILE" >&2
  echo "Le controle ne peut pas verifier, il refuse." >&2
  exit 1
fi

# --- 1. Noms de fichiers interdits ---
FORBIDDEN_NAMES='(^|/)\.env($|\.)|\.(key|pem|pfx|p12|crt|cer|der|jks|keystore)$|(^|/)(secrets?|credentials?)(/|$)|\.(sql|dump|sqlite|db|mdb)$'

if [ "$DIR_MODE" = "1" ]; then
  STAGED="$(pb_list_files "$PROJECT_ROOT")"
else
  STAGED="$(git diff --cached --name-only --diff-filter=ACM)"
fi

# Ligne de base (Decision 000545, A4) : un fichier grave a l'adoption et non
# touche n'est jamais juge ; un fichier grave puis touche est juge entier
# (TOUCHED, contenu complet lu plus bas) ; le fichier de ligne de base
# lui-meme n'est qu'une liste d'empreintes et de noms, jamais un contenu.
pb_load "$PROJECT_ROOT"
TOUCHED=""
if [ -n "$PB_NAME" ] && [ -n "$STAGED" ]; then
  KEPT=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    pb_is_baseline_file "$f" && continue
    if [ -n "$PB_FILE" ]; then
      pb_untouched "$f" && continue
      pb_touched "$f" && TOUCHED="${TOUCHED}${TOUCHED:+
}$f"
    fi
    KEPT="${KEPT}${KEPT:+
}$f"
  done <<PB_EOF
$STAGED
PB_EOF
  STAGED="$KEPT"
fi

if [ -n "$STAGED" ]; then
  BAD_NAMES="$(printf '%s\n' "$STAGED" | grep -E "$FORBIDDEN_NAMES" || true)"
  # .env.example est la seule exception : un modele sans valeur.
  BAD_NAMES="$(printf '%s\n' "$BAD_NAMES" | grep -v '\.env\.example$' || true)"
  if [ -n "$BAD_NAMES" ]; then
    echo "REFUS : fichier(s) au nom interdit dans le staging :" >&2
    printf '  %s\n' $BAD_NAMES >&2
    exit 1
  fi
fi

# --- 2. Motifs dans les lignes ajoutees ---
# full_content FICHIER... : contenu entier des fichiers texte (un fichier
# binaire -- octet nul dans son debut -- n'est jamais lu comme du texte).
full_content() {
  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$PROJECT_ROOT/$f" ] || continue
    if head -c 8000 "$PROJECT_ROOT/$f" | tr -d '\000' | cmp -s - <(head -c 8000 "$PROJECT_ROOT/$f"); then
      sed 's/^/+/' "$PROJECT_ROOT/$f"
    fi
  done
}

if [ "$DIR_MODE" = "1" ]; then
  ADDED="$(printf '%s\n' "$STAGED" | full_content || true)"
elif [ -n "$PB_NAME" ]; then
  # Mode depot avec ligne de base : diff des seuls fichiers retenus, plus le
  # contenu entier des fichiers graves puis touches (cliquet).
  ADDED=""
  if [ -n "$STAGED" ]; then
    ADDED="$(printf '%s\n' "$STAGED" | while IFS= read -r f; do
      [ -z "$f" ] && continue
      (cd "$PROJECT_ROOT" && GIT_LITERAL_PATHSPECS=1 git diff --cached -U0 --diff-filter=ACM -- "$f")
    done | grep -E '^\+' | grep -Ev '^\+\+\+' || true)"
  fi
  if [ -n "$TOUCHED" ]; then
    ADDED="${ADDED}
$(printf '%s\n' "$TOUCHED" | full_content || true)"
  fi
else
  ADDED="$(git diff --cached -U0 --diff-filter=ACM | grep -E '^\+' | grep -Ev '^\+\+\+' || true)"
fi

if [ -z "$ADDED" ]; then
  exit 0
fi

FOUND=0
while IFS= read -r pattern; do
  case "$pattern" in
    ''|'#'*) continue ;;
  esac
  MATCH="$(printf '%s\n' "$ADDED" | grep -E -- "$pattern" || true)"
  if [ -n "$MATCH" ]; then
    echo "REFUS : motif de secret detecte." >&2
    echo "  motif : $pattern" >&2
    echo "  (valeur non affichee)" >&2
    FOUND=1
  fi
done < "$PATTERNS_FILE"

if [ "$FOUND" -ne 0 ]; then
  echo "" >&2
  echo "Retire la valeur du fichier, place-la dans .env (non suivi)," >&2
  echo "et documente la cle attendue dans .env.example." >&2
  echo "Ne contourne pas ce controle." >&2
  exit 1
fi

exit 0
