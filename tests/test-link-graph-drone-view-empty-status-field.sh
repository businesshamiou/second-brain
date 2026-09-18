#!/usr/bin/env bash
# Non-regression test (build history) for the front-matter reading defect
# in tools/link-graph-drone-view.sh: a `status:` field
# present but empty shifted the columns read afterwards (see the correction
# note at the top of the repaired script).
#
# Method: disposable sandbox (no file of the real corpus touched), verbatim
# copy of the current script from tools/, run on a synthetic mini corpus
# containing exactly the faulty entry described (build history)
# (`status:` present, empty). The observed signal is the title displayed by
# the complete Mermaid view for the faulty document: before the fix, the
# column shift empties the title field read (fallback to the file name,
# "DOC-A"); after the fix, the real title ("Test Doc A") is read.
#
# usage: tests/test-link-graph-drone-view-empty-status-field.sh
# output: "PASS" (exit 0) or "FAIL: <raison>" (exit 1)

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
# Same reason: the tool sources tools/relpath.sh from its own folder.
cp "$SCRIPT_DIR/../tools/relpath.sh" "$TMP/vault/tools/relpath.sh"
# And tools/kvmap.sh, its portable associative arrays (Mission 181).
cp "$SCRIPT_DIR/../tools/kvmap.sh" "$TMP/vault/tools/kvmap.sh"
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

# Faulty document: `status:` present, without a value (exact entry required
# by Mission 043, step 4).
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

# The hardcoded "../workshop-build" default was retired (build history): the
# sibling must now be declared explicitly, same mechanism as every other
# tool (tools/resolve-sibling-repo.sh). Declared here via the environment
# variable so this fixture keeps exercising the two-corpus code path.
cp "$SCRIPT_DIR/../tools/resolve-sibling-repo.sh" "$TMP/vault/tools/resolve-sibling-repo.sh"
OUTPUT="$(cd "$TMP/vault/tools" && SECOND_BRAIN_SIBLING_REPO=workshop-build bash link-graph-drone-view.sh 2>/tmp/test-lgdv-stderr.$$)"
STDERR_CONTENT="$(cat /tmp/test-lgdv-stderr.$$ 2>/dev/null)"
rm -f /tmp/test-lgdv-stderr.$$

# The Mermaid label of DOC-A, in the complete view: node_label() prints
# the title if it is non-empty, otherwise the file name without extension.
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
