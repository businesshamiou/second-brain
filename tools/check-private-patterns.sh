#!/usr/bin/env bash
# Verifie qu'aucun motif prive (categorie P4, build history, ticket 01 --
# build history) ne subsiste dans l'arbre de travail et, en mode complet,
# dans l'historique de ce depot. Ticket 10 : "gardien hors ligne" secondaire
# manquant -- aucun outil existant (tools/check-secrets.sh ne couvre que les
# identifiants de service, jamais les chemins-machine ou les noms de depots
# prives) ne rejouait la verification manuelle faite une fois au ticket 01 ;
# ce script la rend repetable et l'attache a la CI (build history, Validation 2 :
# "Motifs P4 : -> 0 dans l'arbre et dans l'historique").
#
# Modes :
#   (par defaut)   scanne l'arbre suivi ET l'historique complet (--all).
#   --tree-only    scanne seulement l'arbre suivi, jamais l'historique.
#
# Motif du mode --tree-only (trouve en revue de code, ticket 10) : un
# historique Git est immuable, donc un motif prive une fois committe dans un
# fichier quelconque continue pour toujours a faire refuser le mode complet,
# meme si l'arbre courant est propre -- seule une reecriture d'historique (ou
# une republication depuis zero) l'efface, geste structurant reserve a
# l'Owner, jamais pris par un Executor de sa propre initiative. La CI (qui
# doit rester capable de reussir sur du contenu neuf propre) invoque donc
# --tree-only comme gardien bloquant ; le mode complet reste disponible ici
# pour mesurer l'historique separement.
#
# Exclusion (Mission 178, meme cause que le self-exclusion du mode arbre,
# trouve en relisant ce script apres reduction d'historique) : la recherche
# d'historique n'appliquait PAS EXCLUDE_PATHSPECS, contrairement a la
# recherche d'arbre -- ce script et son test nomment les quatre motifs en
# clair, donc tout commit qui les ajoute (y compris le tout premier commit
# d'un historique par ailleurs propre) faisait refuser le mode complet sur
# ses propres lignes, jamais sur la fuite de quelqu'un d'autre. Corrige en
# passant les memes exclusions de chemin aux deux recherches d'historique
# ci-dessous ; une vraie fuite ailleurs dans l'historique reste detectee
# (cas 2, 4 et 5 de tests/test-check-private-patterns.sh).
#
# Shell portable : aucune dependance a Python, aucune dependance a `grep -P`
# (PCRE) -- le cas "hamio" substring de "businesshamiou" (compte GitHub public
# qui heberge ce depot, hors P4) est exclu par un second grep plutot qu'un
# lookaround, pour rester compatible avec un grep POSIX minimal.
#
# usage: tools/check-private-patterns.sh [--tree-only]
# exit 0 si 0 occurrence hors exception ; exit 1 sinon, cause imprimee.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TREE_ONLY=0
if [ "${1:-}" = "--tree-only" ]; then
  TREE_ONLY=1
fi

git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}

# Ce script, et son test de non-regression, citent en clair les quatre
# motifs qu'ils verifient (liste de motifs, appels, message PASS pour l'un ;
# fixtures et assertions sur les messages de refus pour l'autre) -- les deux
# sont donc exclus de ce balayage d'arbre par pathspec, jamais par une
# exception de contenu (qui masquerait un vrai motif prive ecrit ailleurs).
# Trouve en revue de code (ticket 10) : sans l'exclusion du script lui-meme,
# le gardien se refusait toujours lui-meme ; en ajoutant son test de
# non-regression au depot, le meme defaut est apparu sur ce second fichier,
# pour la meme raison structurelle -- corrige de la meme facon, pas par une
# troisieme exception ad hoc. Toute fixture de test qui a besoin d'un motif
# litteral l'ecrit dans un fichier jetable sous un depot Git sandbox
# (`mktemp -d`), jamais dans un autre fichier suivi de ce depot -- seule la
# paire definition/test elle-meme est exemptee.
EXCLUDE_PATHS=(
  "tools/check-private-patterns.sh"
  "tests/test-check-private-patterns.sh"
)

# Motifs fixes, memes categories que le rapport 167 Table 3 / rapport Mission
# 168 S14 : chemin-machine (hamio, aios-production, WIN-AE600DJQCF6) et
# depot-prive (glintbloom). "businesshamiou" (identite/hote GitHub public de
# ce depot) n'est jamais un motif P4 -- seule exception, traitee a part.
PLAIN_PATTERNS=(
  "aios-production"
  "WIN-AE600DJQCF6"
  "glintbloom"
)

FAIL=0

EXCLUDE_PATHSPECS=()
for excluded in "${EXCLUDE_PATHS[@]}"; do
  EXCLUDE_PATHSPECS+=(":(exclude)$excluded")
done

check_plain() {
  local pattern="$1"
  local tree_hits hist_hits
  tree_hits="$(git -C "$REPO_ROOT" grep -Iin --no-color -- "$pattern" -- . "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null || true)"
  if [ -n "$tree_hits" ]; then
    echo "REFUS : motif prive '$pattern' dans l'arbre :" >&2
    printf '%s\n' "$tree_hits" >&2
    FAIL=1
  fi
  if [ "$TREE_ONLY" -eq 1 ]; then
    return
  fi
  hist_hits="$(git -C "$REPO_ROOT" log -p --all -i -S"$pattern" --pretty=format:'commit %H' -- . "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null | grep -i -- "$pattern" || true)"
  if [ -n "$hist_hits" ]; then
    echo "REFUS : motif prive '$pattern' dans l'historique :" >&2
    printf '%s\n' "$hist_hits" | head -20 >&2
    FAIL=1
  fi
}

check_plain "aios-production"
check_plain "WIN-AE600DJQCF6"
check_plain "glintbloom"

# "hamio" : exclusion de la sous-chaine "businesshamiou" par filtrage, jamais
# par PCRE (portabilite du grep du runner CI, Windows et Ubuntu).
tree_hamio="$(git -C "$REPO_ROOT" grep -Iin --no-color -- "hamio" -- . "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null | grep -vi -- "businesshamiou" || true)"
if [ -n "$tree_hamio" ]; then
  echo "REFUS : motif prive 'hamio' (hors businesshamiou) dans l'arbre :" >&2
  printf '%s\n' "$tree_hamio" >&2
  FAIL=1
fi
if [ "$TREE_ONLY" -eq 0 ]; then
  hist_hamio="$(git -C "$REPO_ROOT" log -p --all -i -S"hamio" --pretty=format:'commit %H' -- . "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null | grep -i -- "hamio" | grep -vi -- "businesshamiou" || true)"
  if [ -n "$hist_hamio" ]; then
    echo "REFUS : motif prive 'hamio' (hors businesshamiou) dans l'historique :" >&2
    printf '%s\n' "$hist_hamio" | head -20 >&2
    FAIL=1
  fi
fi

if [ "$FAIL" -ne 0 ]; then
  echo "REFUS : motif(s) prive(s) trouve(s)." >&2
  exit 1
fi

if [ "$TREE_ONLY" -eq 1 ]; then
  echo "PASS : 0 motif prive dans l'arbre (mode --tree-only, 4 motifs verifies)."
else
  echo "PASS : 0 motif prive dans l'arbre et l'historique (4 motifs verifies)."
fi
exit 0
