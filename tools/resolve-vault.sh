#!/usr/bin/env bash
# Resolution of a project's Vault (Decision 2026-09-17-000545, A1) -- shared
# function, a single source file for every tool that must find the Vault
# (same model as tools/resolve-sibling-repo.sh: nothing presumed).
#
# Order, without exception:
#   (a) The birth certificate, found by walking up from the given folder
#       the way `.git` is found: the comment block at the top of
#       `.pre-commit-config.yaml` (fixed grammar, lines `# <key>: <value>`,
#       first line `# second-brain-birth-certificate: v1`). It names the
#       Vault by its identity. The Vault found -- path of the pin,
#       path of the marker, Vault that runs this tool, sibling folders
#       of the marker -- must carry the same `vault_id`; none carries it:
#       refusal naming both identities.
#   (b) No certificate: the `VAULT-ROOT.md` marker, walking up. It resolves only
#       if there is only one candidate (its path, plus any sibling folder that
#       carries a generated Vault identity); two candidates: refusal, the
#       question goes back to the Owner. If the marker carries an identity, the
#       candidate must carry it too.
# Proximity (a folder named `vault` next door) is never a candidate.
#
# usage (source):
#   . "$SCRIPT_DIR/resolve-vault.sh"
#   resolve_vault "<folder>"
#   # RV_STATUS  : resolved | refused
#   # RV_VAULT   : absolute path of the Vault (resolved only)
#   # RV_MODE    : certificate | marker
#   # RV_PROJECT : root of the project that carries the certificate (certificate only)
#   # RV_WORKSPACE : folder of the marker, empty if none
#   # RV_MESSAGE : cause of the refusal, named
# usage (execute): resolve-vault.sh [<folder>] -> Vault path, or REFUS
#   on stderr and code 1.
#
# bash 3.2, POSIX tools only.

RV_CERT_HEADER="# second-brain-birth-certificate: v1"

_rv_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_rv_lib_dir/vault-identity.sh"

# bc_file_has_certificate <file>: 0 if the file carries the certificate.
bc_file_has_certificate() {
  [ -f "$1" ] || return 1
  tr -d '\r' < "$1" | grep -qxF -- "$RV_CERT_HEADER"
}

# bc_get <file> <key>: value of a `# <key>: <value>` line of the certificate.
bc_get() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk -v k="$2" '
    index($0, "# " k ": ") == 1 { print substr($0, length(k) + 5); exit }
    /^[^#]/ { exit }'
}

# bc_find <folder>: root of the project that carries the certificate, walking up.
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

# bc_pin_vault_rel <project-root>: relative Vault path read from the pin
# (entry of the secrets guardian), empty if missing.
bc_pin_vault_rel() {
  tr -d '\r' < "$1/.pre-commit-config.yaml" 2>/dev/null \
    | sed -n 's#^[[:space:]]*entry:[[:space:]]*\(.*\)/tools/check-secrets\.sh[[:space:]]*$#\1#p' \
    | head -n 1
}

# rv_find_marker <folder>: folder that carries VAULT-ROOT.md, walking up.
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

# rv_marker_field <marker> <label>: value between backticks after
# « <label> : ».
rv_marker_field() {
  tr -d '\r' < "$1" | grep -oE "$2 : \`[^\`]*\`" | head -n 1 | sed -E 's/.*`([^`]*)`.*/\1/'
}

rv_marker_vault_rel() {
  rv_marker_field "$1" 'racine de travail'
}

rv_marker_vault_id() {
  rv_marker_field "$1" 'Identité du Vault'
}

# _rv_add_candidate <path>: adds an existing folder, canonical, without
# duplicate, to the RV_CANDIDATES list (one path per line).
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

# _rv_add_workspace_vaults <workspace>: sibling folders carrying a generated
# Vault identity.
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
