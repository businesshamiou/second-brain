#!/usr/bin/env bash
# Essai de non-regression (Mission 118, DECISION-2026-09-02-005041) pour la
# distinction lien interne / lien sortant de tools/check-links.sh : un lien
# dont la cible resolue sort de la racine du depot courant est desormais
# controle seulement si le depot cible (premier segment sous la racine du
# workspace) est present sur disque -- absent -> avertissement, jamais un
# refus ; present -> controle ordinaire (absente = refus). Les liens internes
# au depot courant restent inchanges : absente = refus, comme avant.
#
# Methode : sandbox jetable par cas (aucun fichier du vrai corpus touche),
# copie verbatim du script courant de tools/, depot Git local minimal pour
# le "depot courant" (vaultcanary), workspace-parent controle par cas pour
# simuler la presence ou l'absence du depot cible.
#
# Quatre cas (memes lettres que le rapport de la Mission 118) :
#   (a) sortant vers un depot absent du workspace -> AVERTI, exit 0.
#   (b) sortant vers un depot present, cible absente -> refuse.
#   (c) sortant vers un depot present, cible presente -> PASS silencieux.
#   (d) interne au depot courant, cible absente -> refuse (comportement
#       inchange depuis avant cette Mission).
#
# usage: tests/test-check-links-cross-repo.sh
# sortie : "PASS: 4/4 cas conformes" (exit 0) ou "FAIL: <raison>" (exit 1)

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_SCRIPT="$SCRIPT_DIR/../tools/check-links.sh"

if [ ! -f "$REAL_SCRIPT" ]; then
  echo "FAIL: script cible introuvable : $REAL_SCRIPT" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0

# make_repo <chemin-workspace> : sandbox Git minimal (vaultcanary) sous le
# workspace donne, script cible copie dedans.
make_repo() {
  local ws="$1"
  local repo="$ws/vaultcanary"
  mkdir -p "$repo/tools" "$repo/decisions"
  cp "$REAL_SCRIPT" "$repo/tools/check-links.sh"
  (cd "$repo" && git init -q && git -c user.email=t@t -c user.name=t config commit.gpgsign false)
  printf '%s\n' "$repo"
}

# run <repo> : stage tout, lance le script, capture sortie + exit.
run() {
  local repo="$1"
  (cd "$repo" && git add -A >/dev/null 2>&1)
  (cd "$repo" && bash tools/check-links.sh 2>&1)
}

# --- (a) sortant vers depot absent -> AVERTI, exit 0 ---
WS_A="$TMP/case-a"
mkdir -p "$WS_A"
REPO_A="$(make_repo "$WS_A")"
cat > "$REPO_A/decisions/X.md" <<'EOF'
# X

Contenu.

## Liens

- `amended by` — [Cible absente](../../absentrepo/somefile.md) (hors dépôt)
EOF
OUT_A="$(run "$REPO_A")"; RC_A=$?
if [ "$RC_A" -eq 0 ] && printf '%s' "$OUT_A" | grep -q 'AVERTI (hors depot absent)'; then
  echo "ok [a-sortant-depot-absent]: exit 0, AVERTI present"
else
  echo "FAIL [a-sortant-depot-absent]: exit=$RC_A, sortie:" >&2
  printf '%s\n' "$OUT_A" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- (b) sortant vers depot present, cible absente -> refuse ---
WS_B="$TMP/case-b"
mkdir -p "$WS_B/presentrepo"
REPO_B="$(make_repo "$WS_B")"
cat > "$REPO_B/decisions/X.md" <<'EOF'
# X

Contenu.

## Liens

- `amended by` — [Cible absente](../../presentrepo/does-not-exist.md) (hors dépôt)
EOF
OUT_B="$(run "$REPO_B")"; RC_B=$?
if [ "$RC_B" -ne 0 ] && printf '%s' "$OUT_B" | grep -q 'cible introuvable'; then
  echo "ok [b-sortant-depot-present-cible-absente]: exit != 0, refus present"
else
  echo "FAIL [b-sortant-depot-present-cible-absente]: exit=$RC_B, sortie:" >&2
  printf '%s\n' "$OUT_B" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- (c) sortant vers depot present, cible presente -> PASS ---
WS_C="$TMP/case-c"
mkdir -p "$WS_C/presentrepo/target"
cat > "$WS_C/presentrepo/target/Y.md" <<'EOF'
# Y
EOF
REPO_C="$(make_repo "$WS_C")"
cat > "$REPO_C/decisions/X.md" <<'EOF'
# X

Contenu.

## Liens

- `amended by` — [Cible presente](../../presentrepo/target/Y.md) (hors dépôt)
EOF
OUT_C="$(run "$REPO_C")"; RC_C=$?
if [ "$RC_C" -eq 0 ] && ! printf '%s' "$OUT_C" | grep -q 'cible introuvable\|AVERTI'; then
  echo "ok [c-sortant-cible-presente]: exit 0, silencieux"
else
  echo "FAIL [c-sortant-cible-presente]: exit=$RC_C, sortie:" >&2
  printf '%s\n' "$OUT_C" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- (d) interne, cible absente -> refuse (comportement inchange) ---
WS_D="$TMP/case-d"
mkdir -p "$WS_D"
REPO_D="$(make_repo "$WS_D")"
cat > "$REPO_D/decisions/X.md" <<'EOF'
# X

Contenu.

## Liens

- `see also` — [Cible interne absente](./does-not-exist-internal.md)
EOF
OUT_D="$(run "$REPO_D")"; RC_D=$?
if [ "$RC_D" -ne 0 ] && printf '%s' "$OUT_D" | grep -q 'cible introuvable'; then
  echo "ok [d-interne-absent]: exit != 0, refus present"
else
  echo "FAIL [d-interne-absent]: exit=$RC_D, sortie:" >&2
  printf '%s\n' "$OUT_D" >&2
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 4/4 cas conformes"
  exit 0
else
  echo "FAIL: $FAILURES cas non conformes"
  exit 1
fi
