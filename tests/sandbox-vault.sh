#!/usr/bin/env bash
# Aide partagee des tests d'initiation (Mission 184) : fabrique un Vault
# jetable a partir de l'ARBRE DE TRAVAIL de ce depot -- jamais un clone, qui
# lirait l'historique committe et exercerait l'ancien code
# (tests/test-project-bootstrap-path-validation.sh l'a mesure). A sourcer.
#
#   . "$REPO_ROOT/tests/sandbox-vault.sh"
#   sandbox_find_uv                       # met uv sur le PATH (runners CI)
#   sandbox_vault <source> <destination>  # copie, git init, identite, commit
#   sandbox_native_path <chemin>          # forme lue par un Python natif
#   sandbox_reference_clone <source>      # depot nu partage, a HEAD (Mission 188)
#
# Le warehouse (skills-warehouse/) n'est pas copie : aucun test d'initiation
# ne le lit. Aucune ecriture hors de la destination.

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

# Clone de reference (Mission 188) : un depot nu de <source> a son HEAD, fait
# une seule fois par execution et par commit, partage par les tests qui
# clonaient ce depot chacun pour soi. Rend son chemin. Le nom porte le
# commit, et le HEAD du depot nu est remesure a chaque appel : une reference
# a un autre commit est refusee, jamais servie. Il ne remplace jamais le
# test qui joue la vraie ligne publiee (smoke-from-github, S1-S11), qui
# clone le reseau par definition.
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
    # Un autre test a pu le poser entre-temps : le premier arrive garde le sien.
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
    # Sous Windows, l'ecriture d'un objet Git est parfois refusee
    # (« Permission denied » sur .git/objects, mesure deux fois a la Mission
    # 184) puis acceptee a la tentative suivante : on reessaie, jamais plus
    # de cinq fois.
    n=0
    until git add -A >/dev/null 2>&1; do
      n=$((n + 1))
      [ "$n" -ge 5 ] && exit 1
      sleep 1
    done
    git commit -q -m "sandbox vault" >/dev/null 2>&1
  ) || return 1
}
