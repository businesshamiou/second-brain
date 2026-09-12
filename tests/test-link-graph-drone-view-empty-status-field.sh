#!/usr/bin/env bash
# Essai de non-regression (Mission 043) pour le defaut de lecture du
# front-matter dans tools/link-graph-drone-view.sh : un champ `status:`
# present mais vide decalait les colonnes lues ensuite (voir la note de
# correction en tete du script reparé).
#
# Methode : sandbox jetable (aucun fichier du vrai corpus touche), copie
# verbatim du script courant de tools/, executee sur un mini corpus
# synthetique contenant exactement l'entree fautive decrite par la Mission
# 043 (`status:` present, vide). Le signal observe est le titre affiche par
# la vue Mermaid complete pour le document fautif : avant correction, le
# decalage de colonnes vide le champ titre lu (repli sur le nom de fichier,
# "DOC-A") ; apres correction, le vrai titre ("Test Doc A") est lu.
#
# usage: tests/test-link-graph-drone-view-empty-status-field.sh
# sortie : "PASS" (exit 0) ou "FAIL: <raison>" (exit 1)

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_SCRIPT="$SCRIPT_DIR/../tools/link-graph-drone-view.sh"

if [ ! -f "$REAL_SCRIPT" ]; then
  echo "FAIL: script cible introuvable : $REAL_SCRIPT" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/vault/tools" "$TMP/workshop-build/workshop-production/state"

cp "$REAL_SCRIPT" "$TMP/vault/tools/link-graph-drone-view.sh"
chmod +x "$TMP/vault/tools/link-graph-drone-view.sh"

cat > "$TMP/workshop-build/workshop-production/state/STATE.md" <<'EOF'
---
type: index
status: active
title: STATE test
---
# STATE test

Fiche d'etat minimale du bac a sable, sans lien (le point de depart de la
mesure 3 n'a pas besoin d'atteindre le mini-corpus pour cet essai).

## Liens

EOF

# Document fautif : `status:` present, sans valeur (entree exacte demandee
# par la Mission 043, etape 4).
cat > "$TMP/vault/DOC-A.md" <<'EOF'
---
type: rules
status:
title: "Test Doc A"
---
# Test Doc A

## Liens

- `voir aussi` — [Doc B](./DOC-B.md)
EOF

cat > "$TMP/vault/DOC-B.md" <<'EOF'
---
type: rules
status: active
title: "Test Doc B"
---
# Test Doc B

## Liens

- `voir aussi` — [Doc A](./DOC-A.md)
EOF

(cd "$TMP/vault" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -q -m init)
(cd "$TMP/workshop-build" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -q -m init)

OUTPUT="$(cd "$TMP/vault/tools" && bash link-graph-drone-view.sh 2>/tmp/test-lgdv-stderr.$$)"
STDERR_CONTENT="$(cat /tmp/test-lgdv-stderr.$$ 2>/dev/null)"
rm -f /tmp/test-lgdv-stderr.$$

# Le libelle Mermaid de DOC-A, dans la vue complete : node_label() imprime
# le titre s'il est non vide, sinon le nom de fichier sans extension.
COMPLETE_BLOCK="$(printf '%s\n' "$OUTPUT" | awk '/=== VUE MERMAID — COMPLETE ===/{f=1} f{print} /=== VUE MERMAID — DOCUMENTS ACTIFS/{exit}')"
DOC_A_LINE="$(printf '%s\n' "$COMPLETE_BLOCK" | grep -m1 'DOC_A\[')"

if [ -z "$DOC_A_LINE" ]; then
  echo "FAIL: aucun noeud DOC_A trouve dans la vue Mermaid complete — sortie inattendue" >&2
  printf '%s\n' "$OUTPUT" | tail -40 >&2
  exit 1
fi

EXPECTED='DOC_A["Test Doc A"]'
case "$DOC_A_LINE" in
  *"$EXPECTED"*)
    echo "PASS: libelle DOC-A correct (\"Test Doc A\" lu malgre status: vide) — ligne : $DOC_A_LINE"
    exit 0
    ;;
  *)
    echo "FAIL: libelle DOC-A errone (defaut de decalage de colonnes present) — ligne obtenue : $DOC_A_LINE"
    echo "      attendu un noeud contenant : $EXPECTED"
    exit 1
    ;;
esac
