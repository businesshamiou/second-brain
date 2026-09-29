#!/usr/bin/env bash
# Readability check before staging (Mission 231, step 4c).
#
# Why: on Windows, a file written by Codex's sandbox can carry an access
# control list that the Owner's own account cannot read (measured on the
# warehouse, 2026-09-25). `git add` then fails half-way with "Permission
# denied", after other paths were already staged. This check reads every
# file about to be staged first; a file it cannot read stops everything, and
# the remedy is named: take ownership back, then reset the ACL.
#
# usage: check-readable.sh <repo> [<path>...]
#   <repo>  : absolute path of the repository.
#   <path>  : paths relative to <repo>; without any, every path that
#             `git status --porcelain -uall` lists (modified or untracked).
# Exit 0: every file readable; last line `READABLE <n>`.
# Exit 1: at least one file unreadable -- one `UNREADABLE <path>` line per
# file, then the remedy lines, last line `REFUSED`. Exit 2: usage error.
# Reads only; writes nothing.
#
# Called by install.sh (stage_and_commit_clone_changes) before its staging;
# prescribed before `git add -- <path>` in docs/how-to/troubleshoot.md.

set -u
. "$(cd "$(dirname "$0")" && pwd)/lib/tmp.sh"  # declared temporary folder (Mission 234)

REPO="${1:-}"
[ -n "$REPO" ] || { echo "usage: check-readable.sh <repo> [<path>...]" >&2; exit 2; }
shift
[ -d "$REPO" ] || { echo "REFUS : depot introuvable : $REPO" >&2; exit 2; }
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || { echo "REFUS : pas un depot Git : $REPO" >&2; exit 2; }

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi
}

LIST="$(mktemp "$(sb_tmp_dir tools)/sb-readable-XXXXXX")" || exit 2
trap 'rm -f "$LIST"' EXIT
if [ $# -gt 0 ]; then
  for p in "$@"; do printf '%s\n' "$p"; done > "$LIST"
else
  git -C "$REPO" -c core.quotepath=off status --porcelain -uall 2>/dev/null \
    | cut -c4- | sed 's/^.* -> //' | sed 's/^"\(.*\)"$/\1/' > "$LIST"
fi

N=0
BAD=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  f="$REPO/$p"
  [ -f "$f" ] || continue
  N=$((N + 1))
  if ! head -c 1 -- "$f" >/dev/null 2>&1; then
    BAD="$BAD$p
"
  fi
done < "$LIST"

if [ -n "$BAD" ]; then
  printf '%s' "$BAD" | while IFS= read -r p; do [ -n "$p" ] && echo "UNREADABLE $p"; done
  echo "Remede (Windows, fichier ecrit par un autre compte ou un bac a sable) : reprendre la propriete puis remettre les droits herites, pour chaque fichier :"
  printf '%s' "$BAD" | while IFS= read -r p; do
    [ -n "$p" ] || continue
    w="$(native "$REPO/$p")"
    echo "  takeown /f \"$w\""
    echo "  icacls \"$w\" /reset"
  done
  echo "Remede (macOS, Linux) : chmod u+r <fichier>. Rien n'a ete indexe."
  echo "REFUSED"
  exit 1
fi
echo "READABLE $N"
exit 0
