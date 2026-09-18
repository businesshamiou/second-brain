#!/usr/bin/env bash
# rel_path BASE CIBLE: path of CIBLE (target) relative to BASE, in pure shell.
#
# Reason (Mission 180): `realpath --relative-to=` is a GNU extension. The
# realpath shipped by Apple does not know it and refuses -- « realpath: illegal
# option -- - » -- which left the computed relative path empty and wrote
# entries such as `/tools/check-secrets.sh` into the pre-commit file of a
# project created on macOS. One form common to the three platforms is better
# than one branch per system: this file is that form, and bash 3.2 is enough
# to run it (indexed arrays only, no associative array).
#
# BASE must exist and be a folder. CIBLE may be a folder or a
# file; only its parent folder must exist. Output without a newline,
# like `realpath --relative-to`. Returns 1 without writing anything if a path
# cannot be found, which leaves callers their usual `2>/dev/null`.
#
# usage: . "$(dirname "$0")/relpath.sh" ; rel_path /a/b /a/c/d  -> ../c/d

abs_path() {
  # Canonical absolute path of $1, whether or not the target exists: the equivalent
  # of `realpath -m`, a GNU option that the BSD (macOS) realpath refuses. A
  # branch "if realpath exists" was not enough -- on macOS it exists and
  # fails, so the fallback was never reached (Mission 180).
  # Normalisation by text, without touching the disk: a path to a
  # missing folder must come out normalised, not empty, otherwise the caller confuses
  # "outside the repository, repository missing" (warning) and "dead target"
  # (refusal). The form of the root is kept -- « / » or « C: » -- because
  # callers compare the result with a root obtained through
  # `git rev-parse`, which returns the Windows form under Git Bash: converting
  # one without the other would make every internal link look like an outgoing link.
  # This is exactly what the Git Bash realpath does: Windows form in,
  # Windows form out.
  local p="$1" c n i root rest norm
  case "$p" in
    /*) root=""; rest="${p#/}" ;;
    [A-Za-z]:/*) root="${p%%/*}"; rest="${p#*/}" ;;
    *) root=""; rest="${PWD#/}/$p" ;;
  esac

  local -a parts=() out=()
  local old_ifs="$IFS"
  IFS='/'
  read -r -a parts <<< "$rest"
  IFS="$old_ifs"

  n=0
  for c in ${parts[@]+"${parts[@]}"}; do
    case "$c" in
      ''|.)
        ;;
      ..)
        if [ "$n" -gt 0 ]; then n=$((n - 1)); fi
        ;;
      *)
        out[$n]="$c"
        n=$((n + 1))
        ;;
    esac
  done

  norm=""
  i=0
  while [ "$i" -lt "$n" ]; do
    norm="${norm}/${out[$i]}"
    i=$((i + 1))
  done
  [ -n "$norm" ] || norm="/"

  printf '%s%s' "$root" "$norm"
}

rel_path() {
  local base="$1" target="$2" b t leaf i j rel
  b="$(cd "$base" 2>/dev/null && pwd -P)" || return 1
  if [ -d "$target" ]; then
    t="$(cd "$target" 2>/dev/null && pwd -P)" || return 1
    leaf=""
  else
    t="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)" || return 1
    leaf="$(basename "$target")"
  fi

  local -a B=() T=()
  local old_ifs="$IFS"
  IFS='/'
  read -r -a B <<< "$b"
  read -r -a T <<< "$t"
  IFS="$old_ifs"

  i=0
  while [ "$i" -lt "${#B[@]}" ] && [ "$i" -lt "${#T[@]}" ] && [ "${B[$i]}" = "${T[$i]}" ]; do
    i=$((i + 1))
  done

  rel=""
  j="$i"
  while [ "$j" -lt "${#B[@]}" ]; do
    rel="${rel}../"
    j=$((j + 1))
  done
  j="$i"
  while [ "$j" -lt "${#T[@]}" ]; do
    rel="${rel}${T[$j]}/"
    j=$((j + 1))
  done
  rel="${rel}${leaf}"
  rel="${rel%/}"
  [ -n "$rel" ] || rel="."

  printf '%s' "$rel"
}
