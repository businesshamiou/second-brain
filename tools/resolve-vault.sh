#!/usr/bin/env bash
# Resolution du Vault d'un projet (Decision 2026-09-17-000545, A1) -- fonction
# partagee, un seul fichier source par tout outil qui doit trouver le Vault
# (meme modele que tools/resolve-sibling-repo.sh : rien de presume).
#
# Ordre, sans exception :
#   (a) L'acte de naissance, trouve en remontant depuis le dossier donne
#       comme on trouve `.git` : le bloc de commentaires en tete de
#       `.pre-commit-config.yaml` (grammaire fixe, lignes `# <cle>: <valeur>`,
#       premiere ligne `# second-brain-birth-certificate: v1`). Il nomme le
#       Vault par son identite. Le Vault trouve -- chemin de l'epingle,
#       chemin du marqueur, Vault qui execute cet outil, dossiers voisins
#       du marqueur -- doit porter le meme `vault_id` ; aucun ne le porte :
#       refus nommant les deux identites.
#   (b) Sans acte : le marqueur `VAULT-ROOT.md` remonte. Il ne resout que
#       s'il n'y a qu'un candidat (son chemin, plus tout dossier voisin qui
#       porte une identite de Vault generee) ; deux candidats : refus, la
#       question revient a l'Owner. Si le marqueur porte une identite, le
#       candidat doit la porter aussi.
# La proximite (un dossier nomme `vault` a cote) n'est jamais un candidat.
#
# usage (source) :
#   . "$SCRIPT_DIR/resolve-vault.sh"
#   resolve_vault "<dossier>"
#   # RV_STATUS  : resolved | refused
#   # RV_VAULT   : chemin absolu du Vault (resolved seulement)
#   # RV_MODE    : certificate | marker
#   # RV_PROJECT : racine du projet qui porte l'acte (certificate seulement)
#   # RV_WORKSPACE : dossier du marqueur, vide si aucun
#   # RV_MESSAGE : cause du refus, nommee
# usage (execute) : resolve-vault.sh [<dossier>] -> chemin du Vault, ou REFUS
#   sur stderr et code 1.
#
# bash 3.2, outils POSIX seulement.

RV_CERT_HEADER="# second-brain-birth-certificate: v1"

_rv_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_rv_lib_dir/vault-identity.sh"

# bc_file_has_certificate <fichier> : 0 si le fichier porte l'acte.
bc_file_has_certificate() {
  [ -f "$1" ] || return 1
  tr -d '\r' < "$1" | grep -qxF -- "$RV_CERT_HEADER"
}

# bc_get <fichier> <cle> : valeur d'une ligne `# <cle>: <valeur>` de l'acte.
bc_get() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk -v k="$2" '
    index($0, "# " k ": ") == 1 { print substr($0, length(k) + 5); exit }
    /^[^#]/ { exit }'
}

# bc_find <dossier> : racine du projet qui porte l'acte, en remontant.
bc_find() {
  local dir
  dir="$(cd "$1" 2>/dev/null && pwd -P)" || return 1
  while [ -n "$dir" ]; do
    if bc_file_has_certificate "$dir/.pre-commit-config.yaml"; then
      printf '%s\n' "$dir"
      return 0
    fi
    [ "$dir" = "/" ] && break
    case "$dir" in [A-Za-z]:/|[A-Za-z]:) break ;; esac
    dir="$(dirname "$dir")"
  done
  return 1
}

# bc_pin_vault_rel <racine-projet> : chemin relatif du Vault lu dans l'epingle
# (entree du gardien de secrets), vide si absent.
bc_pin_vault_rel() {
  tr -d '\r' < "$1/.pre-commit-config.yaml" 2>/dev/null \
    | sed -n 's#^[[:space:]]*entry:[[:space:]]*\(.*\)/tools/check-secrets\.sh[[:space:]]*$#\1#p' \
    | head -n 1
}

# rv_find_marker <dossier> : dossier qui porte VAULT-ROOT.md, en remontant.
rv_find_marker() {
  local dir
  dir="$(cd "$1" 2>/dev/null && pwd -P)" || return 1
  while [ -n "$dir" ]; do
    if [ -f "$dir/VAULT-ROOT.md" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    [ "$dir" = "/" ] && break
    case "$dir" in [A-Za-z]:/|[A-Za-z]:) break ;; esac
    dir="$(dirname "$dir")"
  done
  return 1
}

# rv_marker_field <marqueur> <libelle> : valeur entre accents graves apres
# « <libelle> : ».
rv_marker_field() {
  tr -d '\r' < "$1" | grep -oE "$2 : \`[^\`]*\`" | head -n 1 | sed -E 's/.*`([^`]*)`.*/\1/'
}

rv_marker_vault_rel() {
  rv_marker_field "$1" 'racine de travail'
}

rv_marker_vault_id() {
  rv_marker_field "$1" 'Identité du Vault'
}

# _rv_add_candidate <chemin> : ajoute un dossier existant, canonique, sans
# doublon, a la liste RV_CANDIDATES (un chemin par ligne).
_rv_add_candidate() {
  local c
  c="$(cd "$1" 2>/dev/null && pwd -P)" || return 0
  case "
$RV_CANDIDATES
" in
    *"
$c
"*) return 0 ;;
  esac
  RV_CANDIDATES="${RV_CANDIDATES}${RV_CANDIDATES:+
}$c"
}

# _rv_add_workspace_vaults <workspace> : dossiers voisins portant une identite
# de Vault generee.
_rv_add_workspace_vaults() {
  local ws="$1" d
  [ -d "$ws" ] || return 0
  for d in "$ws"/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    if [ "$(vid_get "$d" status)" = "generated" ] && [ -n "$(vid_get "$d" vault_id)" ]; then
      _rv_add_candidate "$d"
    fi
  done
}

resolve_vault() {
  local start="${1:-.}" cert_root expected rel marker_dir marker_rel marker_id c found_ids id count
  RV_STATUS="refused"
  RV_VAULT=""
  RV_MODE=""
  RV_PROJECT=""
  RV_WORKSPACE=""
  RV_MESSAGE=""
  RV_CANDIDATES=""

  if [ ! -d "$start" ]; then
    RV_MESSAGE="dossier introuvable : $start"
    return 1
  fi

  marker_dir="$(rv_find_marker "$start" || true)"
  RV_WORKSPACE="$marker_dir"

  cert_root="$(bc_find "$start" || true)"
  if [ -n "$cert_root" ]; then
    RV_MODE="certificate"
    RV_PROJECT="$cert_root"
    expected="$(bc_get "$cert_root/.pre-commit-config.yaml" vault_id)"
    if [ -z "$expected" ]; then
      RV_MESSAGE="acte de naissance sans vault_id : $cert_root/.pre-commit-config.yaml"
      return 1
    fi
    rel="$(bc_pin_vault_rel "$cert_root")"
    [ -n "$rel" ] && _rv_add_candidate "$cert_root/$rel"
    if [ -n "$marker_dir" ]; then
      marker_rel="$(rv_marker_vault_rel "$marker_dir/VAULT-ROOT.md")"
      [ -n "$marker_rel" ] && _rv_add_candidate "$marker_dir/$marker_rel"
    fi
    _rv_add_candidate "$_rv_lib_dir/.."
    [ -n "$marker_dir" ] && _rv_add_workspace_vaults "$marker_dir"

    found_ids=""
    while IFS= read -r c; do
      [ -z "$c" ] && continue
      id="$(vid_get "$c" vault_id)"
      if [ -n "$id" ] && [ "$id" = "$expected" ]; then
        RV_STATUS="resolved"
        RV_VAULT="$c"
        return 0
      fi
      found_ids="${found_ids}${found_ids:+, }${id:-(identité absente)} ($c)"
    done <<RV_EOF
$RV_CANDIDATES
RV_EOF
    RV_MESSAGE="identité du Vault différente : l'acte nomme $expected, trouvé : ${found_ids:-aucun Vault}"
    return 1
  fi

  RV_MODE="marker"
  if [ -z "$marker_dir" ]; then
    RV_MESSAGE="ni acte de naissance ni marqueur VAULT-ROOT.md en remontant depuis $start"
    return 1
  fi
  marker_rel="$(rv_marker_vault_rel "$marker_dir/VAULT-ROOT.md")"
  marker_id="$(rv_marker_vault_id "$marker_dir/VAULT-ROOT.md")"
  [ -n "$marker_rel" ] && _rv_add_candidate "$marker_dir/$marker_rel"
  _rv_add_workspace_vaults "$marker_dir"

  count=0
  while IFS= read -r c; do
    [ -n "$c" ] && count=$((count + 1))
  done <<RV_EOF
$RV_CANDIDATES
RV_EOF

  if [ "$count" -eq 0 ]; then
    RV_MESSAGE="marqueur $marker_dir/VAULT-ROOT.md : aucun Vault à son chemin"
    return 1
  fi
  if [ "$count" -gt 1 ]; then
    RV_MESSAGE="plusieurs Vaults candidats sans acte de naissance, question à l'Owner : $(printf '%s' "$RV_CANDIDATES" | tr '\n' ',' | sed 's/,/, /g')"
    return 1
  fi
  c="$RV_CANDIDATES"
  if [ -n "$marker_id" ]; then
    id="$(vid_get "$c" vault_id)"
    if [ "$id" != "$marker_id" ]; then
      RV_MESSAGE="identité du Vault différente : le marqueur nomme $marker_id, trouvé : ${id:-(identité absente)} ($c)"
      return 1
    fi
  fi
  RV_STATUS="resolved"
  RV_VAULT="$c"
  return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -u
  if resolve_vault "${1:-.}"; then
    printf '%s\n' "$RV_VAULT"
    exit 0
  fi
  echo "REFUS : $RV_MESSAGE" >&2
  exit 1
fi
