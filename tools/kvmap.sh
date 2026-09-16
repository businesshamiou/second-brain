#!/usr/bin/env bash
# Tableaux associatifs en bash 3.2 : kv_set, kv_get, kv_has, kv_keys.
#
# Motif (Mission 181) : `declare -A` n'existe qu'a partir de bash 4.0, et
# macOS livre /bin/bash 3.2. Sous 3.2, `declare -A M=()` echoue, M devient un
# tableau indice, et chaque cle chemin (`rules/x.md`) est evaluee comme une
# expression arithmetique : l'outil refuse de tourner, ou pire, tourne sans
# rien verifier. Une forme commune aux trois plateformes vaut mieux qu'une
# branche par systeme : ce fichier est cette forme.
#
# Principe : chaque cle est encodee en un nom de variable unique
# (KV_<carte>__<cle encodee>), puis lue par indirection `${!nom}`, disponible
# depuis bash 2. La recherche reste en temps constant, comme un vrai tableau
# associatif, sans sous-processus dans le cas courant. L'encodage est
# injectif : `_` est echappe en premier (`_5f`), puis `/`, `.`, `-` et
# l'espace. Une cle portant tout autre caractere passe par un encodage
# hexadecimal complet, sous un autre prefixe (KVX_), donc sans collision
# possible avec la forme courte.
#
# L'ordre d'insertion des cles est conserve (kv_keys) ; celui de
# `${!M[@]}` ne l'etait pas, donc aucun appelant ne peut en dependre.
#
# Nom de carte : identifiant bash (lettres, chiffres, `_`).
#
# usage: . "$SCRIPT_DIR/kvmap.sh"
#   kv_set CARTE CLE VALEUR
#   kv_get CARTE CLE          -> KV_VALUE ; code 0 si la cle existe, 1 sinon
#   kv_has CARTE CLE          -> code 0 si la cle existe
#   kv_keys CARTE             -> tableau KV_KEYS, ordre d'insertion

KV__ALNUM='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_'

kv__name() {
  # Nom de variable de la cle $2 dans la carte $1, dans KV_NAME.
  local k="$2"
  k="${k//_/_5f}"
  k="${k//\//_2f}"
  k="${k//./_2e}"
  k="${k//-/_2d}"
  k="${k// /_20}"
  case "$k" in
    *[!$KV__ALNUM]*)
      # Classe ecrite en toutes lettres, jamais [:alnum:] : selon la locale,
      # une lettre accentuee y entrerait et ferait un nom de variable invalide.
      k="$(printf '%s' "$2" | od -An -v -tx1 | tr -d ' \n')"
      KV_NAME="KVX_${1}__${k}"
      return 0
      ;;
  esac
  KV_NAME="KV_${1}__${k}"
}

kv_set() {
  kv__name "$1" "$2"
  if [ -z "${!KV_NAME+x}" ]; then
    eval "KVKEYS_$1+=(\"\$2\")"
  fi
  printf -v "$KV_NAME" '%s' "$3"
}

kv_get() {
  kv__name "$1" "$2"
  if [ -n "${!KV_NAME+x}" ]; then
    KV_VALUE="${!KV_NAME}"
    return 0
  fi
  KV_VALUE=""
  return 1
}

kv_has() {
  kv__name "$1" "$2"
  [ -n "${!KV_NAME+x}" ]
}

kv_keys() {
  # Forme gardee : sous `set -u`, bash 3.2 refuse l'expansion d'un tableau
  # vide (Mission 180).
  eval "KV_KEYS=(\${KVKEYS_$1[@]+\"\${KVKEYS_$1[@]}\"})"
}
