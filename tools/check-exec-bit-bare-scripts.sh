#!/usr/bin/env bash
# Refuse tout .sh suivi dont le bit d'execution est absent de l'INDEX GIT
# alors qu'il est invoque nu (sans `bash`/`sh` devant) quelque part dans
# ce depot. Trois causes de CI rouge distinctes ont partage exactement ce
# defaut, jamais visible sur NTFS
# (ce poste, tout poste Windows -- le bit n'existe pas sur ce systeme de
# fichiers) : chaque fois decouvert un run Ubuntu a la fois, plutot que
# tous ensemble. Ce gardien balaie la famille entiere au lieu d'attendre
# le prochain script que la CI atteindra pour la premiere fois.
#
# Deux sites de bare-invocation mesures sur ce depot (aucun autre trouve
# par balayage complet, Mission 177 etape 2, 4e reprise) :
#   1. un jeton `"$VAR/.../nom.sh"` en tete de commande (debut de ligne,
#      apres `(`, `$(`, `&&`, `||` ou `;`) dans un .sh suivi -- la forme
#      exacte de install.sh:410/413/722/803.
#   2. `entry: chemin.sh` sous `language: script` dans
#      .pre-commit-hooks.yaml -- le framework pre-commit invoque ce
#      chemin nu (meme raison que check-links.sh, premiere reprise).
#
# usage: tools/check-exec-bit-bare-scripts.sh

set -u

VAULT_ROOT="$(git rev-parse --show-toplevel)" || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}

PATTERN='(^|[($]|&&|\|\||;)[[:space:]]*"\$[A-Za-z_]+(_PATH|_ROOT|_DIR)?/[^"]*\.sh"'
CANDIDATES="$(git -C "$VAULT_ROOT" grep -hoE -- "$PATTERN" -- '*.sh' 2>/dev/null \
  | grep -oE '"\$[A-Za-z_]+(_PATH|_ROOT|_DIR)?/[^"]*\.sh"' \
  | sed -E 's/^"\$[A-Za-z_]+(_PATH|_ROOT|_DIR)?\///; s/"$//')"

if [ -f "$VAULT_ROOT/.pre-commit-hooks.yaml" ]; then
  ENTRIES="$(grep -oE 'entry:[[:space:]]*[A-Za-z0-9_./-]+\.sh' "$VAULT_ROOT/.pre-commit-hooks.yaml" \
    | sed -E 's/^entry:[[:space:]]*//')"
  CANDIDATES="$(printf '%s\n%s\n' "$CANDIDATES" "$ENTRIES")"
fi

CANDIDATES="$(printf '%s\n' "$CANDIDATES" | sort -u | grep -v '^$')"

FAIL=0
CHECKED=0
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  mode="$(git -C "$VAULT_ROOT" ls-files -s -- "$rel" | awk '{print $1}')"
  [ -z "$mode" ] && continue
  CHECKED=$((CHECKED + 1))
  if [ "$mode" != "100755" ]; then
    echo "REFUS : $rel invoque nu (bare) mais mode $mode (bit d'execution absent de l'index)." >&2
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
