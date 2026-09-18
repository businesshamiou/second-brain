#!/usr/bin/env bash
# Shared helper for the initiation tests (Mission 184): builds a throwaway
# Vault from the WORKING TREE of this repository -- never a clone, which
# would read the committed history and exercise the old code
# (tests/test-project-bootstrap-path-validation.sh measured it). To be sourced.
#
#   . "$REPO_ROOT/tests/sandbox-vault.sh"
#   sandbox_find_uv                       # puts uv on the PATH (CI runners)
#   sandbox_vault <source> <destination>  # copy, git init, identity, commit
#   sandbox_native_path <path>            # form read by a native Python
#   sandbox_reference_clone <source>      # shared bare repository, at HEAD (Mission 188)
#
# The warehouse (skills-warehouse/) is not copied: no initiation test
# reads it. No writing outside the destination.

sandbox_find_uv() {
  command -v uv >/dev/null 2>&1 && return 0
  local d
  for d in "${RUNNER_TEMP:-}/uv-bin" "$HOME/.local/bin" "$HOME/.cargo/bin"; do
    [ -n "$d" ] || continue
    if command -v cygpath >/dev/null 2>&1; then
      d="$(cygpath -u "$d" 2>/dev/null || printf '%s' "$d")"
    fi
    if [ -x "$d/uv" ] || [ -x "$d/uv.exe" ]; then
      PATH="$d:$PATH"
      export PATH
      return 0
    fi
  done
  return 1
}

# Reference clone (Mission 188): a bare repository of <source> at its HEAD,
# made only once per run and per commit, shared by the tests that used to
# clone this repository each on its own. Returns its path. The name carries
# the commit, and the HEAD of the bare repository is re-measured on each call:
# a reference at another commit is refused, never served. It never replaces
# the test that plays the real published line (smoke-from-github, S1-S11),
# which clones from the network by definition.
#   SRC="$(sandbox_reference_clone "$REPO_ROOT")" || exit 1
#   git clone --quiet -- "$SRC" "$dest"
sandbox_reference_clone() {
  local src="$1" head base dir got tmp
  head="$(git -C "$src" rev-parse HEAD 2>/dev/null)" || {
    echo "REFUS : clone de reference : $src n'est pas un depot Git" >&2
    return 1
  }
  base="${SB_REFERENCE_CLONE_DIR:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}}"
  dir="$base/sb-reference-$head.git"
  if [ ! -d "$dir" ]; then
    mkdir -p "$base" || return 1
    tmp="$dir.tmp.$$"
    git clone --quiet --bare --no-local -- "$src" "$tmp" >/dev/null 2>&1 || {
      rm -rf "$tmp"
      echo "REFUS : clone de reference non construit depuis $src" >&2
      return 1
    }
    # Another test may have placed it meanwhile: the first to arrive keeps its own.
    mv "$tmp" "$dir" 2>/dev/null || rm -rf "$tmp"
  fi
  got="$(git -C "$dir" rev-parse HEAD 2>/dev/null)"
  if [ "$got" != "$head" ]; then
    echo "REFUS : clone de reference $dir a $got, la source est a $head" >&2
    return 1
  fi
  printf '%s\n' "$dir"
}

sandbox_native_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  else
    printf '%s\n' "$1"
  fi
}

sandbox_vault() {
  local src="$1" dest="$2"
  mkdir -p "$dest" || return 1
  (
    cd "$src" || exit 1
    git -c core.quotepath=off ls-files -co --exclude-standard -z \
      | tr '\0' '\n' \
      | grep -v '^skills-warehouse/' \
      | while IFS= read -r f; do
          [ -f "$f" ] || continue
          printf '%s\n' "$f"
        done > "$dest/.sandbox-files"
    tar -cf - -T "$dest/.sandbox-files" | (cd "$dest" && tar -xf -)
  ) || return 1
  rm -f "$dest/.sandbox-files"
  (
    cd "$dest" || exit 1
    git init -q -b main 2>/dev/null || git init -q
    git config user.email sandbox@example.invalid
    git config user.name sandbox
    git config commit.gpgsign false
    git config core.longpaths true
    bash tools/vault-identity.sh ensure "$dest" >/dev/null
    # On Windows, writing a Git object is sometimes refused
    # (« Permission denied » on .git/objects, measured twice in Mission
    # 184) then accepted on the next attempt: we retry, never more
    # than five times.
    n=0
    until git add -A >/dev/null 2>&1; do
      n=$((n + 1))
      [ "$n" -ge 5 ] && exit 1
      sleep 1
    done
    git commit -q -m "sandbox vault" >/dev/null 2>&1
  ) || return 1
}
