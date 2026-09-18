#!/usr/bin/env bash
# Non-regression trial (Mission 060) for the layer recognition of
# tools/check-links.sh: a teaching example inside a fenced code
# block (``` / ~~~) or an inline code span (paired backticks,
# single or double, even nested) is no longer scanned as a real Markdown
# link by rules 2/3. Rule 1 (mandatory "## Liens" section) and the
# resolution of targets for a real link remain unchanged -- verified here
# as non-regression guardrails, not only the new behaviour.
#
# Method: throwaway sandbox per case (no file of the real corpus touched),
# verbatim copy of the current script from tools/, minimal local Git repository,
# direct execution (the script reads `git diff --cached`).
#
# Five cases:
#   1. Fake link in a fenced code block, real link present elsewhere
#      -> PASS (the fake is ignored, the real one suffices).
#   2. Fake link in single-backtick inline code (pattern PROMPT-024, table
#      of test cases), real link present elsewhere -> PASS.
#   3. Fake link in nested double-backtick inline code (pattern PROMPT-026,
#      `` `type` — [texte](cible) ``), real link present elsewhere -> PASS.
#   4. Real broken link outside block/inline -> refused (the layer
#      recognition must swallow nothing real).
#   5. Missing "## Liens" section -> refused (rule 1 unchanged).
#
# usage: tests/test-check-links-code-block-scope.sh
# output: "PASS: 5/5 cas conformes" (exit 0) or "FAIL: <raison>" (exit 1)

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

# make_repo <nom>: minimal Git sandbox with the target script copied into it.
make_repo() {
  local repo="$TMP/$1"
  mkdir -p "$repo/tools"
  cp "$REAL_SCRIPT" "$repo/tools/check-links.sh"
  # The guardian sources tools/relpath.sh from its own folder (form
  # common to the three platforms, Mission 180): the sandbox copies it
  # too, otherwise it tests a truncated script.
  cp "$SCRIPT_DIR/../tools/relpath.sh" "$repo/tools/relpath.sh"
  # Mission 184: same pattern for the project baseline and its two
  # dependencies, sourced by the guardian from its folder.
  for lib in project-baseline.sh resolve-vault.sh vault-identity.sh; do
    cp "$SCRIPT_DIR/../tools/$lib" "$repo/tools/$lib"
  done
  (cd "$repo" && git init -q && git -c user.email=t@t -c user.name=t config commit.gpgsign false)
  printf '%s\n' "$repo"
}

# check <nom> <expect: pass|fail>: stages everything, runs the script, compares.
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

# --- Case 1: fake link in a fenced code block ---
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

# --- Case 2: fake link in single-backtick inline code (pattern PROMPT-024) ---
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

# --- Case 3: fake link in nested double-backtick inline code (pattern PROMPT-026) ---
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

# --- Case 4: real broken link outside block/inline -> always refused ---
REPO4="$(make_repo case4-real-broken)"
cat > "$REPO4/A.md" <<'EOF'
# Doc

Voir [Fantome](./does-not-exist.md).

## Liens

- `see also` — [Fantome](./does-not-exist.md)
EOF
check "case4-real-broken" "fail"

# --- Case 5: missing "## Liens" section -> always refused ---
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
