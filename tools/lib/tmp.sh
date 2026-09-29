#!/usr/bin/env bash
# The declared temporary folder (Mission 234, rule on workspace hygiene §2):
# the one access function through which every tool and test of the Vault gets
# its throwaway files. To be sourced; defines functions, changes nothing on its
# own.
#
#   . "<Vault>/tools/lib/tmp.sh"
#   sb_tmp_root              # prints the declared folder, created if missing
#   sb_tmp_dir <use>         # prints <root>/<use>, created (use: m234, tests,
#                            #   reference-clones, tools, install...)
#   sb_tmp_export <use>      # exports SB_TMP=<root>, TMPDIR=<root>/<use> and,
#                            #   on Windows, TEMP/TMP (native form): every
#                            #   mktemp and child process then writes there
#
# Order, without exception:
#   1. the SB_TMP environment variable;
#   2. the line « Dossier temporaire déclaré : `<path>` » of the workspace
#      marker VAULT-ROOT.md, found by walking up from the Vault that holds this
#      file (written by tools/write-marker.sh);
#   3. the default: <system temporary folder>/second-brain -- documented
#      fallback when neither is there (a Vault outside any workspace, a marker
#      written before Mission 234).
# A root that lies below a folder carrying VAULT-ROOT.md is REFUSED (return 1,
# one line on stderr): a sandbox there would walk up to the real marker and
# resolve the real Vault.
#
# bash 3.2, POSIX tools only.

_sb_tmp_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SB_TMP_MARKER_LABEL="Dossier temporaire déclaré"

# _sb_tmp_posix <path>: a Windows path (C:\x or C:/x) in the form this shell
# reads, /c/x; any other path unchanged. Never `cygpath -u`: Git Bash mounts
# the user's temporary folder on /tmp and would answer /tmp/..., a form from
# which no relative path to the Vault (/c/...) can be computed (measured,
# Mission 234).
_sb_tmp_posix() {
  case "$1" in
    [A-Za-z]:[\\/]*|[A-Za-z]:)
      if command -v cygpath >/dev/null 2>&1; then
        printf '/%s%s\n' "$(printf '%s' "$1" | cut -c1 | tr 'A-Z' 'a-z')" "$(printf '%s' "$1" | cut -c3- | tr '\\' '/')"
        return 0
      fi ;;
  esac
  printf '%s\n' "$1"
}

# _sb_tmp_system: the system temporary folder, read from the platform, never
# from a TMPDIR that an earlier sb_tmp_export may have set.
_sb_tmp_system() {
  if [ -n "${LOCALAPPDATA:-}" ] && command -v cygpath >/dev/null 2>&1; then
    _sb_tmp_posix "$LOCALAPPDATA/Temp"
    return 0
  fi
  printf '%s\n' "${TMPDIR:-/tmp}" | sed 's#/*$##'
}

# _sb_tmp_marker_dir <folder>: first folder carrying VAULT-ROOT.md, walking up.
_sb_tmp_marker_dir() {
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

# sb_tmp_marker_value <marker file>: the declared path, empty when absent.
sb_tmp_marker_value() {
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | grep -oE "$SB_TMP_MARKER_LABEL : \`[^\`]*\`" | head -n 1 | sed -E 's/.*`([^`]*)`.*/\1/'
}

sb_tmp_root() {
  local root="" marker walk existing parent
  if [ -n "${SB_TMP:-}" ]; then
    root="$(_sb_tmp_posix "$SB_TMP")"
  else
    marker="$(_sb_tmp_marker_dir "$_sb_tmp_lib_dir/../.." || true)"
    if [ -n "$marker" ]; then
      root="$(sb_tmp_marker_value "$marker/VAULT-ROOT.md")"
      [ -n "$root" ] && root="$(_sb_tmp_posix "$root")"
    fi
  fi
  [ -n "$root" ] || root="$(_sb_tmp_system)/second-brain"
  # Refused BEFORE anything is created: walk up from the nearest existing
  # ancestor (a first version created the folder, then refused it -- measured,
  # Mission 234).
  existing="$root"
  while [ ! -d "$existing" ]; do
    parent="$(dirname "$existing")"
    [ "$parent" = "$existing" ] && break
    existing="$parent"
  done
  walk="$(_sb_tmp_marker_dir "$existing" || true)"
  if [ -n "$walk" ]; then
    echo "REFUS : dossier temporaire declare sous une racine d'espace ($walk porte VAULT-ROOT.md) : $root ; il doit vivre hors de l'espace de travail (regle 112218 §2.3)" >&2
    return 1
  fi
  mkdir -p "$root" 2>/dev/null || {
    echo "REFUS : dossier temporaire declare non cree : $root" >&2
    return 1
  }
  root="$(cd "$root" && pwd -P)"
  printf '%s\n' "$root"
}

sb_tmp_dir() {
  local use="${1:-}" root
  case "$use" in
    ''|*/*|*\\*|.|..|*[!A-Za-z0-9._-]*)
      echo "REFUS : usage du dossier temporaire invalide : '${use}' (un nom de dossier)" >&2
      return 1 ;;
  esac
  root="$(sb_tmp_root)" || return 1
  mkdir -p "$root/$use" 2>/dev/null || {
    echo "REFUS : sous-dossier temporaire non cree : $root/$use" >&2
    return 1
  }
  printf '%s\n' "$root/$use"
}

sb_tmp_export() {
  local root d
  root="$(sb_tmp_root)" || return 1
  d="$(sb_tmp_dir "${1:-}")" || return 1
  if command -v cygpath >/dev/null 2>&1; then
    # TMPDIR in the shell's own form (/c/...): a drive colon (C:/...) in the
    # paths mktemp returns broke the `file:line:` parsing of a test (measured,
    # Mission 234). Native programs read TEMP/TMP, in Windows form.
    SB_TMP="$(cygpath -m "$root")"
    TMPDIR="$d"
    TEMP="$(cygpath -w "$d")"
    TMP="$TEMP"
    export TEMP TMP
  else
    SB_TMP="$root"
    TMPDIR="$d"
  fi
  export SB_TMP TMPDIR
}
