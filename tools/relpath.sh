#!/usr/bin/env bash
# rel_path BASE CIBLE : chemin de CIBLE relatif a BASE, en shell pur.
#
# Motif (Mission 180) : `realpath --relative-to=` est une extension GNU. Le
# realpath livre par Apple ne la connait pas et refuse -- « realpath: illegal
# option -- - » -- ce qui rendait vide le chemin relatif calcule et ecrivait
# des entrees comme `/tools/check-secrets.sh` dans le fichier pre-commit d'un
# projet cree sur macOS. Une forme commune aux trois plateformes vaut mieux
# qu'une branche par systeme : ce fichier est cette forme, et bash 3.2 suffit
# a l'executer (tableaux indices seulement, aucun tableau associatif).
#
# BASE doit exister et etre un dossier. CIBLE peut etre un dossier ou un
# fichier ; seul son dossier parent doit exister. Sortie sans saut de ligne,
# comme `realpath --relative-to`. Retourne 1 sans rien ecrire si un chemin
# est introuvable, ce qui laisse aux appelants leur `2>/dev/null` habituel.
#
# usage: . "$(dirname "$0")/relpath.sh" ; rel_path /a/b /a/c/d  -> ../c/d

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
