#!/usr/bin/env bash
# Refuse toute mention, dans la documentation suivie de ce depot, de la
# commande Claude Code `/agents`. Corrigee au defaut 4 de l'audit (Mission
# 171-C01, etape 9) : la doctrine du Vault est d'appeler l'assistant en le
# nommant ("demande a Brian : ...") plutot que par cette commande, qui n'a
# pas de sens hors de l'outil Claude Code lui-meme. Ce gardien evite qu'une
# future edition la reintroduise sans le remarquer.
#
# Perimetre : tous les fichiers *.md suivis par Git (git ls-files), y compris
# skills-warehouse/ et skills/external/ -- une mention de cette commande y
# serait tout aussi fausse. Ce script et son test de non-regression sont
# exclus du balayage (meme raison qu'a check-private-patterns.sh : ils citent
# le motif en clair pour le definir et le tester).
#
# Distinction avec un chemin de fichier legitime (ex.
# `skills/external/ask-matt/agents/openai.yaml`, un DOSSIER nomme "agents") :
# une vraie mention de commande n'est jamais suivie d'un autre "/" -- c'est
# le seul critere retenu, mesure sur le corpus reel (aucun dossier "agents"
# suivi d'autre chose qu'un "/" dans ce depot).
#
# usage: tools/check-no-slash-agents.sh
# exit 0 si 0 occurrence hors exception ; exit 1 sinon, cause imprimee.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}

# Meme principe d'auto-exclusion que check-private-patterns.sh : la paire
# definition/test cite le motif en clair, jamais un vrai document livre.
EXCLUDE_PATHSPECS=(
  ":(exclude)tools/check-no-slash-agents.sh"
  ":(exclude)tests/test-check-no-slash-agents.sh"
)

# `/agents` suivi d'un caractere qui n'est ni un mot ni un "/" (espace, fin de
# ligne, backtick, ponctuation) : couvre l'invocation nue et son usage entre
# backticks ; exclut le segment de chemin `.../agents/<fichier>`.
PATTERN='/agents([^A-Za-z0-9_/]|$)'

# Case sensible a dessein : la commande Claude Code s'ecrit en minuscules
# ("/agents"), distincte du fichier `AGENTS.md` (majuscules) cite partout en
# lien -- un balayage insensible a la casse confondrait les deux (mesure sur
# ce depot : premiere version de ce script refusait a tort sur `./AGENTS.md`).
HITS="$(git -C "$REPO_ROOT" grep -In --no-color -E -- "$PATTERN" -- '*.md' "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null || true)"

if [ -n "$HITS" ]; then
  echo "REFUS : mention de la commande Claude Code '/agents' trouvee dans la documentation :" >&2
  printf '%s\n' "$HITS" >&2
  echo "Remede : remplacer par la facon d'appeler l'assistant en le nommant, avec un exemple (ex. \"demande a Brian : ...\")." >&2
  exit 1
fi

echo "PASS : 0 mention de '/agents' dans la documentation suivie."
exit 0
