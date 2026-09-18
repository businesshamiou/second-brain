#!/usr/bin/env bash
# Refuses any tracked .sh whose execute bit is missing from the GIT INDEX
# while it is invoked bare (without `bash`/`sh` in front) somewhere in
# this repository. Three distinct causes of red CI shared exactly this
# defect, never visible on NTFS
# (this machine, any Windows machine -- the bit does not exist on that file
# system): each time discovered one Ubuntu run at a time, rather than
# all together. This guardian sweeps the whole family instead of waiting for
# the next script that CI will reach for the first time.
#
# Two bare-invocation sites measured in this repository (no other found
# by a complete sweep, Mission 177 step 2, 4th resumption):
#   1. a `"$VAR/.../name.sh"` token at the head of a command (start of line,
#      after `(`, `$(`, `&&`, `||` or `;`) in a tracked .sh -- the exact
#      form of install.sh:410/413/722/803.
#   2. `entry: path.sh` under `language: script` in
#      .pre-commit-hooks.yaml -- the pre-commit framework invokes that
#      path bare (same reason as check-links.sh, first resumption).
#
# Third family (Mission 181): every tracked file under .githooks/,
# whatever its extension -- a hook is not called bare by a
# script of the repository, it is called by Git, which refuses to execute a hook
# without the execute bit (« hint: The '.githooks/pre-commit' hook was ignored
# because it's not set as executable »). The product's three hooks were
# tracked as 100644: for a macOS or Linux participant, no guardian
# ran at commit, and nothing reported it. Covered by their role (the
# folder that core.hooksPath designates), never by their extension.
#
# usage: tools/check-exec-bit-bare-scripts.sh

set -u

VAULT_ROOT="$(git rev-parse --show-toplevel)" || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}

PATTERN='(^|[($]|&&|\|\||;)[[:space:]]*"\$[A-Za-z_]+(_PATH|_ROOT|_DIR)?/[^"]*\.sh"' # portability: regex text, not a pipe
CANDIDATES="$(git -C "$VAULT_ROOT" grep -hoE -- "$PATTERN" -- '*.sh' 2>/dev/null \
  | grep -oE '"\$[A-Za-z_]+(_PATH|_ROOT|_DIR)?/[^"]*\.sh"' \
  | sed -E 's/^"\$[A-Za-z_]+(_PATH|_ROOT|_DIR)?\///; s/"$//')"

if [ -f "$VAULT_ROOT/.pre-commit-hooks.yaml" ]; then
  ENTRIES="$(grep -oE 'entry:[[:space:]]*[A-Za-z0-9_./-]+\.sh' "$VAULT_ROOT/.pre-commit-hooks.yaml" \
    | sed -E 's/^entry:[[:space:]]*//')"
  CANDIDATES="$(printf '%s\n%s\n' "$CANDIDATES" "$ENTRIES")"
fi

HOOKS="$(git -C "$VAULT_ROOT" ls-files -- .githooks/ 2>/dev/null)"
CANDIDATES="$(printf '%s\n%s\n' "$CANDIDATES" "$HOOKS")"

CANDIDATES="$(printf '%s\n' "$CANDIDATES" | sort -u | grep -v '^$')"

FAIL=0
CHECKED=0
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  mode="$(git -C "$VAULT_ROOT" ls-files -s -- "$rel" | awk '{print $1}')"
  [ -z "$mode" ] && continue
  CHECKED=$((CHECKED + 1))
  if [ "$mode" != "100755" ]; then
    case "$rel" in
      .githooks/*) role="hook Git (execute par Git, qui ignore un hook non executable)" ;;
      *) role="invoque nu (bare)" ;;
    esac
    echo "REFUS : $rel $role mais mode $mode (bit d'execution absent de l'index)." >&2
    FAIL=1
  fi
done <<EOF_CANDIDATES
$CANDIDATES
EOF_CANDIDATES

if [ "$FAIL" -ne 0 ]; then
  echo "Remede : git update-index --chmod=+x <chemin(s) ci-dessus>." >&2
  exit 1
fi

echo "PASS : $CHECKED script(s) nu(s) verifie(s), tous executables dans l'index Git."
exit 0
