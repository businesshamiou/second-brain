#!/usr/bin/env bash
# Associative arrays in bash 3.2: kv_set, kv_get, kv_has, kv_keys.
#
# Reason (Mission 181): `declare -A` only exists from bash 4.0 on, and
# macOS ships /bin/bash 3.2. Under 3.2, `declare -A M=()` fails, M becomes an
# indexed array, and each path key (`rules/x.md`) is evaluated as an
# arithmetic expression: the tool refuses to run, or worse, runs without
# checking anything. One form common to the three platforms is better than one
# branch per system: this file is that form.
#
# Principle: each key is encoded into a unique variable name
# (KV_<map>__<encoded key>), then read through the indirection `${!name}`, available
# since bash 2. Lookup stays constant-time, like a real associative
# array, with no subprocess in the common case. The encoding is
# injective: `_` is escaped first (`_5f`), then `/`, `.`, `-` and
# the space. A key carrying any other character goes through a full hexadecimal
# encoding, under another prefix (KVX_), hence with no possible
# collision with the short form.
#
# The insertion order of the keys is kept (kv_keys); that of
# `${!M[@]}` was not, so no caller can depend on it.
#
# Map name: bash identifier (letters, digits, `_`).
#
# usage: . "$SCRIPT_DIR/kvmap.sh"
#   kv_set MAP KEY VALUE
#   kv_get MAP KEY            -> KV_VALUE; code 0 if the key exists, 1 otherwise
#   kv_has MAP KEY            -> code 0 if the key exists
#   kv_keys MAP               -> array KV_KEYS, insertion order

KV__ALNUM='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_'

kv__name() {
  # Variable name of key $2 in map $1, in KV_NAME.
  local k="$2"
  k="${k//_/_5f}"
  k="${k//\//_2f}"
  k="${k//./_2e}"
  k="${k//-/_2d}"
  k="${k// /_20}"
  case "$k" in
    *[!$KV__ALNUM]*)
      # Class spelled out in full, never [:alnum:]: depending on the locale,
      # an accented letter would fall into it and make an invalid variable name.
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
  # Guarded form: under `set -u`, bash 3.2 refuses the expansion of an empty
  # array (Mission 180).
  eval "KV_KEYS=(\${KVKEYS_$1[@]+\"\${KVKEYS_$1[@]}\"})"
}
