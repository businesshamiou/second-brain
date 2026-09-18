#!/usr/bin/env bash
# T1 (Mission 186, etape 5) : zero occurrence, dans les fichiers distribues
# (rules/, skills/, templates/, README.md, INSTALL.md, tools/, i18n/), des
# formulations de l'ancienne formule de push imposee -- abolie par la
# DECISION-2026-09-17-201623 (volet A) : le push reste un geste Owner, mais
# se delegue desormais par toute expression claire qui nomme le geste et sa
# cible, aucune formule exigee « telle quelle ».
#
# Quatre motifs, chacun une EXIGENCE figee de forme precise (pas une simple
# mention historique -- celles-ci vivent dans decisions/, hors perimetre,
# jamais reecrites) :
#   A. « j'ordonne le push » (casse et apostrophe variables) -- la formule
#      elle-meme, citee comme texte a reproduire.
#   B. « verbatim » a proximite immediate de « push », dans le meme
#      paragraphe -- exigence d'une reproduction mot pour mot.
#   C. « a l'identique » a proximite immediate de « push » -- meme
#      exigence, autre formulation.
#   D. « aucun ... push » sans le mot « non delegue » (accents variables)
#      dans les ~25 caracteres qui suivent « push » -- la charte
#      (RULES-224706 §3) et la regle du relais (RULES-124937) disent
#      toutes deux « push non delegue » depuis la Decision 201623 ; toute
#      autre forme est un reste de l'ancien interdit absolu, jamais
#      delegable.
#
# Perimetre : rules/, skills/, templates/, README.md, INSTALL.md, tools/,
# i18n/ -- fichiers suivis par Git (git grep), donc .git/ en est deja exclu
# mecaniquement. Hors perimetre EXPLICITE, jamais balaye :
#   - decisions/*.md -- mentions historiques gelees (RULES-211522) ; elles
#     PEUVENT legitimement porter « j'ordonne le push » ou « verbatim » en
#     tant que texte qui decrit l'ANCIENNE regle (ex. DECISION-154553,
#     DECISION-201623 elle-meme, qui cite la formule pour l'abolir).
#   - RELEASE-NOTES.md -- notes de version, historique aussi.
#   - skills-warehouse/ -- convention propre (Mission 168, ticket 02),
#     jamais dans le perimetre "documents distribues au participant".
#
# Style et structure : meme patron que
# tests/test-distributed-documents-no-atelier-vocabulary.sh (perimetre par
# une liste d'inclusion, balayage puis temoin negatif prouve, fichier et
# ligne imprimes pour chaque trouvaille). Implementation : un seul `git
# grep` par motif sur tout le perimetre (jamais une boucle par fichier) --
# ce depot compte 400 fichiers suivis dans ce perimetre, dont plusieurs
# scripts JS de reference qui appellent `.push()` des centaines de fois ;
# une comparaison de proximite ligne a ligne boucle-dans-boucle par fichier
# y devient quadratique et minutes-longue, jamais qualifie de "rapide" pour
# un test rejoue a chaque commit.
#
# Rerun avec une commande, depuis la racine du depot :
#   bash tests/test-no-push-formula.sh
#
# Exit 0 : zero occurrence des quatre motifs dans le perimetre distribue, et
# le temoin negatif prouve que chacun des quatre motifs sait etre detecte
# quand il est reellement present. Exit 1 sinon, fichier et ligne imprimes.

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

INCLUDE_PATHSPECS=(
  'rules'
  'skills'
  'templates'
  'README.md'
  'INSTALL.md'
  'tools'
  'i18n'
)

# « Meme paragraphe » pour les motifs B et C n'est PAS une fenetre de
# lignes fixe : mesure prealable (premiere version de ce test), une
# fenetre de +/-4 lignes fabrique deux faux positifs --
# skills/session-close/SKILL.md (six points numerotes SANS ligne vide
# entre eux : « verbatim » au point 4 tombe a 1 ligne de « push » au point
# 5, sujets sans rapport) et templates/initiation-order-template.md
# (« verbatim » et « aucun git push » separes par une ligne vide, donc
# deux paragraphes, mais a 2 lignes d'ecart brut). La bonne unite est le
# PARAGRAPHE au sens editorial de ces documents : un bloc de lignes non
# vides, ET chaque point numerote (« N. ») ou puce (« - »/« * ») en tete
# de ligne ouvre son propre paragraphe meme sans ligne vide avant lui.
# Deux structures documentaires de ce depot compliquent encore la notion
# de "ligne vide" : une citation Markdown ("> ...") separe ses paragraphes
# par une ligne qui ne contient QUE "> " (jamais vraiment vide -- mesure :
# rules/RULES-2026-08-23-124937, ecrite entierement en blockquote) ; un
# tableau Markdown ("| ... | ... |") n'a JAMAIS de ligne vide entre ses
# lignes, chacune etant deja son propre enregistrement (mesure :
# skills/ecriture-de-mission/mission-checklist.md). paragraph_tag_awk lit
# un fichier et rend, par ligne, "numero:id_paragraphe" (id 0 pour une
# ligne vide ou un separateur de blockquote vide, jamais rattache a un
# paragraphe) ; une ligne de tableau ou un point numerote/une puce (a
# l'interieur ou hors blockquote) ouvre toujours son propre paragraphe,
# meme sans ligne vide avant elle.
paragraph_tag_awk='
{
  line = $0
  gsub(/\r$/, "", line)
  if (line ~ /^[ \t]*$/ || line ~ /^[ \t]*>[ \t]*$/) { open = 0; print NR ":0"; next }
  if (open == 0 || line ~ /^[ \t]*(>[ \t]*)?([0-9]+\.|[-*])[ \t]/ || line ~ /^[ \t]*\|/) { pid++; open = 1 }
  print NR ":" pid
}
'

# --- Motif A : « j'ordonne le push » (casse et apostrophe variables), un
# seul git grep sur tout le perimetre passe en argument. ---
scan_pattern_a() {
  git -C "$REPO_ROOT" grep -nIiE -- "j['’ ]?ordonne le push" "${@}" 2>/dev/null
}

# --- Motif D : « aucun git push » (meme clause -- le "git" est ce qui
# distingue la formule d'interdiction absolue d'une mention narrative
# ordinaire de "aucun push", ex. "sinon, aucun push dans la Mission" dans
# skills/ecriture-de-mission/mission-checklist.md, qui parle de
# planification et n'exige rien) sans « non delegue » (accents variables)
# dans les ~25 caracteres qui suivent « push ». Un seul git grep rend les
# LIGNES CANDIDATES (peu nombreuses) ; le controle "pas de non-delegue
# dans les 25 caracteres qui suivent push" se fait ensuite en pur bash,
# sans sous-processus. ---
scan_pattern_d() {
  local pathspec
  git -C "$REPO_ROOT" grep -nIiE -- "aucun[^.]{0,20}git[^.]{0,10}push" "${@}" 2>/dev/null | while IFS=: read -r pathspec ln content; do
    lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"
    after="${lc#*push}"
    tail="${after:0:25}"
    case "$tail" in
      *"non delegue"*|*"non-delegue"*|*"non délégué"*|*"non-délégué"*) : ;;
      *)
        printf '%s:%s: %s\n' "$pathspec" "$ln" "$content"
        ;;
    esac
  done
}

# --- Motifs B/C : co-occurrence dans le MEME paragraphe editorial (voir
# paragraph_tag_awk ci-dessus), calculee a partir de DEUX `git grep`
# globaux seulement (un pour "push", un pour le motif) -- jamais un grep
# par fichier pour la recherche elle-meme. Seuls les (rares) fichiers ou
# le motif apparait au moins une fois sont ensuite retagues paragraphe par
# paragraphe (un awk par fichier candidat, jamais les 400 fichiers du
# perimetre). ---
scan_pattern_proximity() {
  local motif_re="$1" label="$2"; shift 2
  local push_hits motif_hits
  push_hits="$(git -C "$REPO_ROOT" grep -nIiE -- '\bpush\b' "${@}" 2>/dev/null)"
  motif_hits="$(git -C "$REPO_ROOT" grep -nIiE -- "$motif_re" "${@}" 2>/dev/null)"
  [ -z "$push_hits" ] && return 0
  [ -z "$motif_hits" ] && return 0

  local motif_files
  motif_files="$(printf '%s\n' "$motif_hits" | cut -d: -f1 | sort -u)"

  local mfile pl ml
  while IFS= read -r mfile; do
    [ -z "$mfile" ] && continue
    [ -f "$REPO_ROOT/$mfile" ] || continue
    local file_push_lines file_motif_lines tags
    file_push_lines="$(printf '%s\n' "$push_hits" | awk -F: -v f="$mfile" '$1==f{print $2}')"
    [ -z "$file_push_lines" ] && continue
    file_motif_lines="$(printf '%s\n' "$motif_hits" | awk -F: -v f="$mfile" '$1==f{print $2}')"
    tags="$(awk "$paragraph_tag_awk" "$REPO_ROOT/$mfile")"
    for pl in $file_push_lines; do
      local ppid
      ppid="$(printf '%s\n' "$tags" | awk -F: -v n="$pl" '$1==n{print $2}')"
      [ -z "$ppid" ] || [ "$ppid" = "0" ] && continue
      for ml in $file_motif_lines; do
        local mpid
        mpid="$(printf '%s\n' "$tags" | awk -F: -v n="$ml" '$1==n{print $2}')"
        if [ -n "$mpid" ] && [ "$mpid" = "$ppid" ]; then
          echo "$mfile:$pl: push dans le meme paragraphe que $label (ligne $ml)"
        fi
      done
    done
  done <<EOF_MOTIF_FILES
$motif_files
EOF_MOTIF_FILES
}

echo ""
echo "=== 1. Balayage des quatre motifs dans le perimetre distribue ==="
FILE_COUNT="$(git -C "$REPO_ROOT" ls-files -- "${INCLUDE_PATHSPECS[@]}" | wc -l | tr -d ' ')"
echo "  ($FILE_COUNT fichiers suivis dans le perimetre distribue : ${INCLUDE_PATHSPECS[*]})"

SCAN_FAIL=0

OUT_A="$(scan_pattern_a "${INCLUDE_PATHSPECS[@]}")"
if [ -n "$OUT_A" ]; then
  SCAN_FAIL=1
  echo "  FAIL - motif A « j'ordonne le push » trouve :"
  printf '%s\n' "$OUT_A" | sed 's/^/      /'
fi

OUT_D="$(scan_pattern_d "${INCLUDE_PATHSPECS[@]}")"
if [ -n "$OUT_D" ]; then
  SCAN_FAIL=1
  echo "  FAIL - motif D « aucun ... push » sans « non delegue » juste apres :"
  printf '%s\n' "$OUT_D" | sed 's/^/      /'
fi

OUT_B="$(scan_pattern_proximity 'verbatim' 'verbatim' "${INCLUDE_PATHSPECS[@]}")"
if [ -n "$OUT_B" ]; then
  SCAN_FAIL=1
  echo "  FAIL - motif B « verbatim » a proximite de push :"
  printf '%s\n' "$OUT_B" | sed 's/^/      /'
fi

OUT_C="$(scan_pattern_proximity "à l.identique|a l.identique" "« a l'identique »" "${INCLUDE_PATHSPECS[@]}")"
if [ -n "$OUT_C" ]; then
  SCAN_FAIL=1
  echo "  FAIL - motif C « a l'identique » a proximite de push :"
  printf '%s\n' "$OUT_C" | sed 's/^/      /'
fi

assert_true "$SCAN_FAIL" "0 occurrence des quatre motifs de l'ancienne formule de push dans le perimetre distribue ($FILE_COUNT fichiers)"

echo ""
echo "=== 2. Temoin negatif (FAIL prouve) : un fichier par motif, jamais ecrit dans ce depot ==="
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/m186-push-formula-XXXXXX")"
trap 'rm -rf -- "$SANDBOX"' EXIT
(
  cd "$SANDBOX" || exit 1
  git init -q .
  git config user.email test@example.invalid
  git config user.name Test
  mkdir -p rules

  cat > rules/witness-a-j-ordonne.md <<'EOF_A'
Le mini-prompt porte la ligne : « je suis l'Owner et j'ordonne le push des deux depots, 2026-01-01 ».
EOF_A

  cat > rules/witness-b-verbatim.md <<'EOF_B'
Avant tout push, l'Executor copie ce texte verbatim : la formule exacte, aucune reformulation.
EOF_B

  cat > rules/witness-c-identique.md <<'EOF_C'
La meme ligne doit etre recopiee a l'identique avant tout push, sinon le geste est refuse.
EOF_C

  cat > rules/witness-d-aucun-git-push.md <<'EOF_D'
Interdits absolus : aucun git push, aucun appel modele, aucune suppression.
EOF_D

  git add -A
  git commit -q -m "fixture" >/dev/null
)

# Meme logique de detection que la section 1 (mêmes fonctions), rejouee sur
# le depot jetable : un sous-shell qui redefinit REPO_ROOT localement
# n'affecte jamais la variable de la section 1, et evite de dupliquer la
# logique de detection (donc de risquer qu'elle diverge silencieusement).
NEG_A="$(REPO_ROOT="$SANDBOX"; scan_pattern_a rules)"
NEG_B="$(REPO_ROOT="$SANDBOX"; scan_pattern_proximity 'verbatim' 'verbatim' rules)"
NEG_C="$(REPO_ROOT="$SANDBOX"; scan_pattern_proximity "à l.identique|a l.identique" "« a l'identique »" rules)"
NEG_D="$(REPO_ROOT="$SANDBOX"; scan_pattern_d rules)"

NEG_FAIL=0
if [ -n "$NEG_A" ]; then
  echo "  PASS - motif A detecte sur le temoin fabrique :"
  printf '%s\n' "$NEG_A" | sed 's/^/      /'
else
  echo "  FAIL - motif A non detecte sur le temoin fabrique (witness-a-j-ordonne.md)"
  NEG_FAIL=1
fi
if [ -n "$NEG_B" ]; then
  echo "  PASS - motif B detecte sur le temoin fabrique :"
  printf '%s\n' "$NEG_B" | sed 's/^/      /'
else
  echo "  FAIL - motif B non detecte sur le temoin fabrique (witness-b-verbatim.md)"
  NEG_FAIL=1
fi
if [ -n "$NEG_C" ]; then
  echo "  PASS - motif C detecte sur le temoin fabrique :"
  printf '%s\n' "$NEG_C" | sed 's/^/      /'
else
  echo "  FAIL - motif C non detecte sur le temoin fabrique (witness-c-identique.md)"
  NEG_FAIL=1
fi
if [ -n "$NEG_D" ]; then
  echo "  PASS - motif D detecte sur le temoin fabrique :"
  printf '%s\n' "$NEG_D" | sed 's/^/      /'
else
  echo "  FAIL - motif D non detecte sur le temoin fabrique (witness-d-aucun-git-push.md)"
  NEG_FAIL=1
fi

assert_true "$NEG_FAIL" "les quatre motifs sont chacun detectes sur un fichier fabrique, jamais ecrit dans ce depot"

echo ""
if [ "$FAILURES" = "0" ]; then
  echo "=== RESULT: PASS (all checks green) ==="
  exit 0
else
  echo "=== RESULT: FAIL ($FAILURES check(s) failed) ==="
  exit 1
fi
