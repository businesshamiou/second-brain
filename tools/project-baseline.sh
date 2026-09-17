#!/usr/bin/env bash
# Ligne de base datee et cliquet (Decision 2026-09-17-000545, A4) -- fonctions
# partagees par les gardiens ecrits en shell (check-links.sh,
# check-secrets.sh). Jumeau Python : tools/project_baseline.py, meme format,
# meme verdict.
#
# A l'adoption d'un dossier existant, tools/project-bootstrap.sh grave la
# liste de ses fichiers, avec l'empreinte SHA-256 de chacun, dans un fichier
# date que l'acte de naissance nomme (`# baseline: <fichier>`). Les gardiens
# ne jugent alors que le nouveau et le touche :
#   - un fichier de la ligne de base, contenu identique : jamais rouge ;
#   - un fichier de la ligne de base touche : juge entier, doit devenir
#     conforme (cliquet) ;
#   - un fichier absent de la ligne de base : juge comme d'habitude.
# Sans acte, ou acte sans ligne de base : aucun changement de comportement.
#
# Le contenu compare est celui de l'arbre de travail.
#
# usage (source) :
#   . "$SCRIPT_DIR/project-baseline.sh"
#   pb_load "<racine-projet>"
#   pb_untouched "<chemin relatif>" && continue
#   pb_list_files "<racine-projet>"   # mode dossier (vcs: none)

_pb_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_pb_lib_dir/resolve-vault.sh"

PB_ROOT=""
PB_FILE=""
PB_NAME=""

# pb_sha256 <fichier> : empreinte SHA-256 du contenu sans retours chariot --
# une reecriture des fins de ligne par Git (core.autocrlf) ne compte pas
# comme une modification (mesure a la Mission 184 sous Windows).
pb_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    tr -d '\r' < "$1" | sha256sum | awk '{print $1}'  # portability: guarded by command -v
  elif command -v shasum >/dev/null 2>&1; then
    tr -d '\r' < "$1" | shasum -a 256 | awk '{print $1}'
  else
    tr -d '\r' < "$1" | openssl dgst -sha256 | awk '{print $NF}'
  fi
}

# pb_load <racine-projet> : PB_FILE = ligne de base nommee par l'acte, vide
# sinon.
pb_load() {
  local cfg="$1/.pre-commit-config.yaml"
  PB_ROOT="$1"
  PB_FILE=""
  PB_NAME=""
  bc_file_has_certificate "$cfg" || return 0
  PB_NAME="$(bc_get "$cfg" baseline)"
  [ -n "$PB_NAME" ] || return 0
  [ -f "$1/$PB_NAME" ] && PB_FILE="$1/$PB_NAME"
  return 0
}

# pb_is_baseline_file <chemin relatif> : 0 pour le fichier de ligne de base
# lui-meme (une donnee generee : empreintes et noms, jamais un contenu).
pb_is_baseline_file() {
  [ -n "$PB_NAME" ] && [ "$1" = "$PB_NAME" ]
}

# pb_listed_hash <chemin relatif> : empreinte gravee, vide si non listee.
pb_listed_hash() {
  [ -n "$PB_FILE" ] || return 0
  tr -d '\r' < "$PB_FILE" | awk -F '\t' -v p="$1" '$2 == p { print $1; exit }'
}

# pb_untouched <chemin relatif> : 0 si le fichier est dans la ligne de base
# et que son contenu n'a pas change.
pb_untouched() {
  local want have
  [ -n "$PB_FILE" ] || return 1
  want="$(pb_listed_hash "$1")"
  [ -n "$want" ] || return 1
  [ -f "$PB_ROOT/$1" ] || return 1
  have="$(pb_sha256 "$PB_ROOT/$1")"
  [ "$want" = "$have" ]
}

# pb_touched <chemin relatif> : 0 si le fichier est dans la ligne de base et
# que son contenu a change (le cliquet : juge entier).
pb_touched() {
  local want
  [ -n "$PB_FILE" ] || return 1
  want="$(pb_listed_hash "$1")"
  [ -n "$want" ] || return 1
  ! pb_untouched "$1"
}

# pb_list_files <racine-projet> : tous les fichiers du projet, chemins
# relatifs, hors .git, dependances et liens poses vers le Vault.
pb_list_files() {
  (
    cd "$1" || exit 1
    find . \( -name .git -o -name node_modules -o -path ./.claude/skills -o -path ./.claude/agents -o -path ./.agents/skills \) -prune -o -type f -print
  ) | sed 's#^\./##' | LC_ALL=C sort
}
