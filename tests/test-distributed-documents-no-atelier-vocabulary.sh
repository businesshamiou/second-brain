#!/usr/bin/env bash
# Balaie le CONTENU des documents suivis, distribues et destines a un
# participant -- mots (meme liste que
# tests/test-nominal-flow-no-atelier-vocabulary.sh, Mission 174) et chemins
# prefixes `vault/` cites comme s'ils resolvaient chez un participant
# (Mission 177, etape 4b).
#
# Complement de la Mission 174 : celle-ci ne balaie que la SORTIE CONSOLE
# d'un flux nominal, jamais le CONTENU des documents eux-memes -- c'est par
# la qu'est passee la citation `vault/skills/session-start/reading-list.md`
# de la charte des roles (RULES-2026-08-23-224706-role-charter-and-session-
# determination.md), invisible a la console d'une installation mais lue par
# tout participant qui ouvre ce fichier.
#
# PORTEE : une liste d'inclusion, pas d'exclusion -- les dossiers et
# fichiers qu'un participant lit reellement comme documentation ou comme
# guide (rules/, knowledge/, templates/, skills/ hors external/, assistant/,
# i18n/, AGENTS.md, CLAUDE.md, README.md, INSTALL.md). Mesure prealable
# (Mission 177, etape 1) : ces dossiers ne portent aujourd'hui aucune
# occurrence. Le code source (tools/, tests/) cite legitimement ces memes
# mots dans ses fixtures, ses commentaires d'historique ou sa propre
# definition (meme motif que la paire definition/test de
# tools/check-private-patterns.sh) -- l'inclure aurait exige une liste
# d'exclusion fichier par fichier aussi longue qu'arbitraire, pour un risque
# bien moindre qu'un document que le participant ouvre directement.
#
# Rerun avec une commande, depuis la racine du depot :
#   bash tests/test-distributed-documents-no-atelier-vocabulary.sh
#
# Exit 0 : aucune occurrence dans les documents inclus, et le cas negatif
# prouve que le balayage detecte toujours un motif present. Exit 1 sinon,
# fichier et ligne imprimes.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1
FAILURES=0

assert_true() {
  if [ "$1" = "0" ]; then
    echo "  PASS - $2"
  else
    echo "  FAIL - $2"
    FAILURES=$((FAILURES + 1))
  fi
}

# Motifs : les quatre mots d'atelier deja catalogues par la Mission 174,
# plus tout chemin cite entre accents graves qui commence par `vault/` --
# le seul alias que tools/check-asserted-paths.sh resout encore vers ce
# depot lui-meme (historique : ce depot s'appelait "vault" avant sa
# distribution comme produit), donc le seul chemin de ce type que le
# gardien de chemins affirmes ne peut PAS distinguer d'un vrai sous-dossier
# chez un participant -- ce depot n'a jamais eu de sous-dossier `vault/`
# reel.
WORD_PATTERNS=(
  'workshop-build'
  'workshop-production'
  '\bworkshops\b'
  '\bLegacy\b'
)
PATH_PATTERN='`vault/'

# Portee : dossiers vivants lus par un participant, plus les fichiers
# racine qui s'adressent a lui. `skills/external/` est exclu a l'interieur
# de `skills/` : materiel d'auteurs tiers adopte verbatim, corps garanti
# par empreinte SHA-256 (DECISION-171209) -- jamais reecrit, meme pour une
# raison de vocabulaire (mesure : ses occurrences de "Legacy" sont un nom
# de script du plugin, sans rapport avec l'atelier).
INCLUDE_PATHSPECS=(
  'rules'
  'knowledge'
  'templates'
  'skills'
  ':(exclude)skills/external'
  'assistant'
  'i18n'
  'AGENTS.md'
  'CLAUDE.md'
  'README.md'
  'INSTALL.md'
)

echo ""
echo "=== 1. Balayage des documents distribues destines au participant ==="
TREE_FAIL=0
for pattern in "${WORD_PATTERNS[@]}"; do
  HITS="$(git -C "$REPO_ROOT" grep -Iin -E -- "$pattern" -- "${INCLUDE_PATHSPECS[@]}" 2>/dev/null || true)"
  if [ -n "$HITS" ]; then
    TREE_FAIL=1
    echo "  FAIL - mot d'atelier '$pattern' trouve :"
    printf '%s\n' "$HITS" | sed 's/^/      /'
  fi
done
PATH_HITS="$(git -C "$REPO_ROOT" grep -Iin -F -- "$PATH_PATTERN" -- "${INCLUDE_PATHSPECS[@]}" 2>/dev/null || true)"
if [ -n "$PATH_HITS" ]; then
  TREE_FAIL=1
  echo "  FAIL - chemin d'atelier '${PATH_PATTERN}...' trouve :"
  printf '%s\n' "$PATH_HITS" | sed 's/^/      /'
fi
assert_true "$TREE_FAIL" "0 mot ni chemin d'atelier dans les documents distribues destines au participant"

echo ""
echo "=== 2. Cas negatif : le balayage detecte toujours un motif present ==="
# Depot bac a sable jetable, jamais un fichier suivi de CE depot -- meme
# discipline que tools/check-private-patterns.sh et la Mission 176.
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sb-atelier-doc-sweep-XXXXXX")"
trap 'rm -rf -- "$SANDBOX"' EXIT
(
  cd "$SANDBOX" || exit 1
  git init -q .
  git config user.email test@example.invalid
  git config user.name Test
  mkdir -p rules
  printf 'Un document qui cite %s par erreur, et un chemin `vault/skills/x.md`.\n' 'workshop-build' > rules/example.md
  git add -A
  git commit -q -m "fixture" >/dev/null
)
SANDBOX_WORD_HITS="$(git -C "$SANDBOX" grep -Iin -E -- 'workshop-build' -- rules 2>/dev/null || true)"
SANDBOX_PATH_HITS="$(git -C "$SANDBOX" grep -Iin -F -- '`vault/' -- rules 2>/dev/null || true)"
NEGATIVE_OK=1
[ -n "$SANDBOX_WORD_HITS" ] && [ -n "$SANDBOX_PATH_HITS" ] && NEGATIVE_OK=0
assert_true "$NEGATIVE_OK" "le meme balayage detecte un mot ET un chemin d'atelier fabriques dans un depot jetable, jamais ecrits dans ce depot"

echo ""
if [ "$FAILURES" = "0" ]; then
  echo "=== RESULT: PASS (all checks green) ==="
  exit 0
else
  echo "=== RESULT: FAIL ($FAILURES check(s) failed) ==="
  exit 1
fi
