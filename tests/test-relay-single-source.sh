#!/usr/bin/env bash
# T2 (Mission 186, etape 5) : le bloc RELAY a une SOURCE UNIQUE --
# DECISION-2026-09-17-201623, volet B1 : « Toute Mission, tout skill, tout
# gabarit, toute charte [renvoie a la regle 124937] et n'en redit ni les
# rubriques ni le nombre de lignes. Toute redite est une copie de doctrine
# a retirer. »
#
# Deux controles :
#   1. La grammaire exacte du bloc RELAY (l'en-tete « RELAY <NNN> » et les
#      sept rubriques litterales, avec leur espacement exact) est extraite
#      DEPUIS rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md
#      lui-meme -- jamais recopiee a la main ici, pour ne jamais diverger
#      silencieusement de la source si elle change. Elle ne doit apparaitre
#      NULLE PART ailleurs dans le corpus distribue (meme perimetre que
#      T1 : rules/, skills/, templates/, README.md, INSTALL.md, tools/,
#      i18n/, hors decisions/*.md historiques).
#   2. Les pieces qui PARLENT du RELAY sans en etre la source
#      (skills/session-close/SKILL.md, skills/ecriture-de-mission/SKILL.md)
#      portent un renvoi nominatif -- la chaine "124937" -- au lieu de
#      redire la grammaire.
#
# Rerun avec une commande, depuis la racine du depot :
#   bash tests/test-relay-single-source.sh
#
# Exit 0 : la grammaire RELAY n'apparait que dans sa source, les deux
# skills renvoient nommement a la regle 124937, et le temoin negatif
# prouve que la detection sait echouer sur une copie qui redit la
# grammaire. Exit 1 sinon, fichier et ligne imprimes.

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

SOURCE_FILE="rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"

INCLUDE_PATHSPECS=(
  'rules'
  'skills'
  'templates'
  'README.md'
  'INSTALL.md'
  'tools'
  'i18n'
)

if [ ! -f "$REPO_ROOT/$SOURCE_FILE" ]; then
  echo "REFUS : source de la grammaire RELAY introuvable : $SOURCE_FILE" >&2
  exit 1
fi

# extract_relay_labels <regle-124937> : rend, une ligne par rubrique,
# l'en-tete « RELAY <NNN> » puis chaque libelle exact (« Rapport   : »,
# « Verdict   : », etc., espacement inclus) tel qu'il vit DANS la source --
# jamais retape a la main. Le bloc source est le fencing ```text .. ```` a
# l'interieur de la citation Markdown (prefixe "> ") du sens retour.
extract_relay_labels() {
  awk '
    /^> ```text[[:space:]]*$/ { grab=1; next }
    grab && /^> ```[[:space:]]*$/ { grab=0; next }
    grab { sub(/^> ?/, ""); print }
  ' "$1" \
  | sed -E 's/^(RELAY <NNN>)$/\1/; s/^([^:]*:).*/\1/'
}

LABELS_FILE="$(mktemp "${TMPDIR:-/tmp}/m186-relay-labels-XXXXXX")"
extract_relay_labels "$REPO_ROOT/$SOURCE_FILE" > "$LABELS_FILE"
LABEL_COUNT="$(wc -l < "$LABELS_FILE" | tr -d ' ')"

echo ""
echo "=== 0. Grammaire extraite de la source ($SOURCE_FILE) ==="
if [ "$LABEL_COUNT" -lt 8 ]; then
  echo "  FAIL - extraction incomplete : $LABEL_COUNT ligne(s) au lieu de 8 (en-tete + sept rubriques) -- la source a-t-elle change de forme ?"
  rm -f "$LABELS_FILE"
  echo ""
  echo "=== RESULT: FAIL (extraction) ==="
  exit 1
fi
echo "  ($LABEL_COUNT motifs extraits, un par ligne) :"
sed 's/^/      /' "$LABELS_FILE"

echo ""
echo "=== 1. La grammaire RELAY n'apparait que dans sa source ==="
SCAN_FAIL=0
while IFS= read -r label; do
  [ -z "$label" ] && continue
  HITS="$(git -C "$REPO_ROOT" grep -nF -- "$label" "${INCLUDE_PATHSPECS[@]}" 2>/dev/null | grep -v "^${SOURCE_FILE}:")"
  if [ -n "$HITS" ]; then
    SCAN_FAIL=1
    echo "  FAIL - motif « $label » redit hors de $SOURCE_FILE :"
    printf '%s\n' "$HITS" | sed 's/^/      /'
  fi
done < "$LABELS_FILE"
assert_true "$SCAN_FAIL" "les $LABEL_COUNT motifs de la grammaire RELAY n'apparaissent que dans $SOURCE_FILE, nulle part ailleurs dans le corpus distribue"

echo ""
echo "=== 2. Renvoi nominatif (« 124937 ») dans les pieces qui parlent du RELAY sans en etre la source ==="
NAMED_FAIL=0
for f in skills/session-close/SKILL.md skills/ecriture-de-mission/SKILL.md; do
  if [ ! -f "$REPO_ROOT/$f" ]; then
    echo "  FAIL - fichier attendu introuvable : $f"
    NAMED_FAIL=1
    continue
  fi
  if grep -qF '124937' -- "$REPO_ROOT/$f"; then
    echo "  PASS - $f renvoie nommement a la regle 124937"
  else
    echo "  FAIL - $f ne porte pas la chaine « 124937 »"
    NAMED_FAIL=1
  fi
done
assert_true "$NAMED_FAIL" "skills/session-close/SKILL.md et skills/ecriture-de-mission/SKILL.md renvoient tous deux nommement a la regle 124937"

echo ""
echo "=== 3. Temoin negatif (FAIL prouve) : une copie de skill qui redit la grammaire ==="
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/m186-relay-source-XXXXXX")"
trap 'rm -rf -- "$SANDBOX"; rm -f "$LABELS_FILE"' EXIT
mkdir -p "$SANDBOX/skills/fake-skill"
WITNESS="$SANDBOX/skills/fake-skill/SKILL.md"
cat > "$WITNESS" <<'EOF_WITNESS'
---
name: fake-skill
description: "Temoin negatif du test T2 (Mission 186) -- redit la grammaire du bloc RELAY au lieu d'y renvoyer, ce que ce skill fabrique ne devrait jamais faire."
---

Ce skill redit a tort la grammaire RELAY au lieu d'y renvoyer :

```text
RELAY <NNN>
Verdict   : <FAIT | PARTIEL | BLOQUÉ> + une ligne
À trancher: <une ligne, ou « rien »>
```
EOF_WITNESS

WITNESS_DETECTED=0
while IFS= read -r label; do
  [ -z "$label" ] && continue
  if grep -qF -- "$label" "$WITNESS"; then
    echo "      motif « $label » detecte dans $WITNESS (attendu)"
    WITNESS_DETECTED=1
  fi
done < "$LABELS_FILE"

assert_true "$((1 - WITNESS_DETECTED))" "le meme balayage detecte (FAIL nomme) une copie de skill qui redit la grammaire RELAY, jamais ecrite dans ce depot"

echo ""
if [ "$FAILURES" = "0" ]; then
  echo "=== RESULT: PASS (all checks green) ==="
  exit 0
else
  echo "=== RESULT: FAIL ($FAILURES check(s) failed) ==="
  exit 1
fi
