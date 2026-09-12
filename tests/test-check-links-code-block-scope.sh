#!/usr/bin/env bash
# Essai de non-regression (Mission 060) pour la reconnaissance de couches de
# tools/check-links.sh : un exemple pedagogique a l'interieur d'un bloc de
# code cloture (``` / ~~~) ou d'un span de code inline (backticks apparies,
# simple ou double, meme imbrique) n'est plus balaye comme un lien Markdown
# reel par les regles 2/3. La regle 1 (section "## Liens" obligatoire) et la
# resolution de cibles pour un vrai lien restent inchangees -- verifiees ici
# comme garde-fous de non-regression, pas seulement le nouveau comportement.
#
# Methode : sandbox jetable par cas (aucun fichier du vrai corpus touche),
# copie verbatim du script courant de tools/, depot Git local minimal,
# execution directe (le script lit `git diff --cached`).
#
# Cinq cas :
#   1. Faux lien dans un bloc de code cloture, vrai lien present ailleurs
#      -> PASS (le faux est ignore, le vrai suffit).
#   2. Faux lien en code inline simple backtick (patron PROMPT-024, tableau
#      de cas de test), vrai lien present ailleurs -> PASS.
#   3. Faux lien en code inline double backtick imbrique (patron PROMPT-026,
#      `` `type` — [texte](cible) ``), vrai lien present ailleurs -> PASS.
#   4. Vrai lien casse hors bloc/inline -> refuse (la reconnaissance de
#      couches ne doit rien avaler de reel).
#   5. Section "## Liens" manquante -> refuse (regle 1 inchangee).
#
# usage: tests/test-check-links-code-block-scope.sh
# sortie : "PASS: 5/5 cas conformes" (exit 0) ou "FAIL: <raison>" (exit 1)

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

# make_repo <nom> : sandbox Git minimal avec le script cible copie dedans.
make_repo() {
  local repo="$TMP/$1"
  mkdir -p "$repo/tools"
  cp "$REAL_SCRIPT" "$repo/tools/check-links.sh"
  (cd "$repo" && git init -q && git -c user.email=t@t -c user.name=t config commit.gpgsign false)
  printf '%s\n' "$repo"
}

# check <nom> <expect: pass|fail> : stage tout, lance le script, compare.
check() {
  local name="$1" expect="$2" repo="$TMP/$1"
  (cd "$repo" && git add -A)
  local out rc
  out="$(cd "$repo" && bash tools/check-links.sh 2>&1)"
  rc=$?
  if [ "$expect" = "pass" ] && [ "$rc" -ne 0 ]; then
    echo "FAIL [$name]: attendu PASS (exit 0), obtenu exit $rc" >&2
    printf '%s\n' "$out" >&2
    FAILURES=$((FAILURES + 1))
  elif [ "$expect" = "fail" ] && [ "$rc" -eq 0 ]; then
    echo "FAIL [$name]: attendu FAIL (exit != 0), obtenu exit 0" >&2
    FAILURES=$((FAILURES + 1))
  else
    echo "ok [$name]: exit $rc conforme (attendu $expect)"
  fi
}

# --- Cas 1 : faux lien dans un bloc de code cloture ---
REPO1="$(make_repo case1-fenced)"
cat > "$REPO1/B.md" <<'EOF'
# B

contenu reel

## Liens

EOF
cat > "$REPO1/A.md" <<'EOF'
# Doc

Exemple pedagogique :

```markdown
## Liens

- `see also` — [Fantome](./does-not-exist.md)
```

## Liens

- `see also` — [Reel](./B.md)
EOF
check "case1-fenced" "pass"

# --- Cas 2 : faux lien en code inline simple backtick (patron PROMPT-024) ---
REPO2="$(make_repo case2-inline-single)"
cat > "$REPO2/B.md" <<'EOF'
# B

contenu reel

## Liens

EOF
cat > "$REPO2/A.md" <<'EOF'
# Doc

| Cas | Contenu |
|---|---|
| 1 | `Voir [B](./b.md).` |

## Liens

- `see also` — [Reel](./B.md)
EOF
check "case2-inline-single" "pass"

# --- Cas 3 : faux lien en code inline double backtick imbrique (patron PROMPT-026) ---
REPO3="$(make_repo case3-inline-double)"
cat > "$REPO3/B.md" <<'EOF'
# B

contenu reel

## Liens

EOF
cat > "$REPO3/A.md" <<'EOF'
# Doc

Ajoute a sa section : `` `amended by` — [<titre>](./DECISION-<ts>-amendment.md) `` (seule modification).

## Liens

- `see also` — [Reel](./B.md)
EOF
check "case3-inline-double" "pass"

# --- Cas 4 : vrai lien casse hors bloc/inline -> toujours refuse ---
REPO4="$(make_repo case4-real-broken)"
cat > "$REPO4/A.md" <<'EOF'
# Doc

Voir [Fantome](./does-not-exist.md).

## Liens

- `see also` — [Fantome](./does-not-exist.md)
EOF
check "case4-real-broken" "fail"

# --- Cas 5 : section "## Liens" manquante -> toujours refuse ---
REPO5="$(make_repo case5-missing-section)"
cat > "$REPO5/A.md" <<'EOF'
# Doc

Rien ici.
EOF
check "case5-missing-section" "fail"

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 5/5 cas conformes"
  exit 0
else
  echo "FAIL: $FAILURES cas non conformes"
  exit 1
fi
