#!/usr/bin/env bash
# T5 (Mission 185-C01, door 5 of capture 2026-09-17-144137): `--git`
# IS the answer to the Git question -- it is no longer asked.
#
# Defect measured on the Owner's machine: `adopt <projet> --git` still asked
# « Suivre ce projet avec Git ? » ["Track this project with Git?"] before
# handling `--git`, and so
# blocked any caller without a terminal (an agent, a script, an installation
# session). Cause read in the code: `--git` only set ADD_GIT,
# consumed much further on; the VCS variable was still empty at the time of the
# question.
#
# Oracle (PASS expected):
#   - `adopt <p> --git` with standard input CLOSED returns 0;
#   - `.git` and the hook are set, the certificate carries `# vcs: git`;
#   - standard input is NOT read: the same command, fed the
#     word « none », still returns `# vcs: git` -- if it read the input,
#     it would write `# vcs: none`;
#   - the Git question is not displayed.
# Negative control (in this same file): `adopt <p>` WITHOUT `--git` or
# `--vcs`, fed « none », does ask the question and writes
# `# vcs: none` -- the question still exists when nothing settles it.
#
# `pre-commit install` is a recording stand-in (same pattern as
# tests/test-project-initiation.sh): this test measures the question, not the
# guardians.
#
# Writes only in a temporary folder (prefix m185).
#
# usage: bash tests/test-project-bootstrap-adopt-git-no-question.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- tools/project-bootstrap.sh en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-askgit-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

mkdir -p "$TMP/bin"
cat > "$TMP/bin/pre-commit" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "install" ]; then
  hooks="$(git rev-parse --git-path hooks)" || exit 1
  mkdir -p "$hooks"
  printf '#!/usr/bin/env bash\n# substitut de test\nexit 0\n' > "$hooks/pre-commit"
  exit 0
fi
exit 0
STUB
chmod +x "$TMP/bin/pre-commit"
PATH="$TMP/bin:$PATH"
export PATH

WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
if ! sandbox_vault "$REPO_ROOT" "$V"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V/tools/write-marker.sh" "$WS" >/dev/null
BOOTSTRAP="$V/tools/project-bootstrap.sh"

# The Git question, in the language of the default catalogue (EN): read from
# the catalogue, never copied here -- a translated question remains the same
# question.
QUESTION="$(uv run --no-project "$V/tools/sb_installer_helper.py" format-catalog \
  "$V/i18n/catalog.en.json" "projectBootstrap.question.git" "none" 2>/dev/null | head -n 1)"
if [ -n "$QUESTION" ]; then
  pass "controle : la question Git est lue au catalogue (\"$QUESTION\")"
else
  fail "controle : question Git illisible au catalogue -- le temoin ne prouverait rien"
fi

new_folder() {
  mkdir -p "$1"
  printf '# notes\n\nDu texte.\n' > "$1/notes.md"
}

cert_vcs() {
  tr -d '\r' < "$1/.pre-commit-config.yaml" | sed -n 's/^# vcs: //p' | head -n 1
}

# =============================================================================
echo "=== (a) adopt --git, entree standard FERMEE ==="
P_A="$WS/projet-a"
new_folder "$P_A"
OUT_A="$(bash "$BOOTSTRAP" adopt "$P_A" "Projet A" --git 2>&1 </dev/null)"
RC_A=$?
if [ "$RC_A" = "0" ]; then
  pass "(a) rend 0 sans entree standard"
else
  fail "(a) rend $RC_A -- $(printf '%s' "$OUT_A" | tail -n 3)"
fi
[ -d "$P_A/.git" ] && pass "(a) le depot .git est pose" || fail "(a) aucun depot .git"
if [ -f "$P_A/.git/hooks/pre-commit" ]; then
  pass "(a) le hook pre-commit est pose"
else
  fail "(a) aucun hook pre-commit"
fi
VCS_A="$(cert_vcs "$P_A")"
if [ "$VCS_A" = "git" ]; then
  pass "(a) l'acte de naissance porte # vcs: git"
else
  fail "(a) l'acte porte '# vcs: $VCS_A'"
fi
case "$OUT_A" in
  *"$QUESTION"*) fail "(a) la question Git a quand meme ete posee" ;;
  *) pass "(a) la question Git n'est pas posee" ;;
esac

# =============================================================================
echo ""
echo "=== (b) adopt --git, entree standard qui dirait « none » ==="
# If the script read standard input, this word would become the answer and
# the certificate would carry # vcs: none. This is the heart of door 5.
P_B="$WS/projet-b"
new_folder "$P_B"
OUT_B="$(printf 'none\n' | bash "$BOOTSTRAP" adopt "$P_B" "Projet B" --git 2>&1)"
VCS_B="$(cert_vcs "$P_B")"
if [ "$VCS_B" = "git" ]; then
  pass "(b) l'entree standard n'est pas lue : # vcs: git malgre « none » en entree"
else
  fail "(b) l'entree standard a ete lue : # vcs: $VCS_B"
fi
[ -d "$P_B/.git" ] && pass "(b) le depot .git est pose" || fail "(b) aucun depot .git"
case "$OUT_B" in
  *"$QUESTION"*) fail "(b) la question Git a quand meme ete posee" ;;
  *) pass "(b) la question Git n'est pas posee" ;;
esac

# =============================================================================
echo ""
echo "=== temoin negatif : adopt SANS --git ni --vcs ==="
P_C="$WS/projet-c"
new_folder "$P_C"
OUT_C="$(printf 'none\n' | bash "$BOOTSTRAP" adopt "$P_C" "Projet C" 2>&1)"
VCS_C="$(cert_vcs "$P_C")"
case "$OUT_C" in
  *"$QUESTION"*) pass "temoin : la question Git est posee quand rien ne la tranche" ;;
  *) fail "temoin : la question Git n'a pas ete posee -- le controle (a)/(b) ne prouverait rien" ;;
esac
if [ "$VCS_C" = "none" ]; then
  pass "temoin : la reponse lue sur l'entree standard est appliquee (# vcs: none)"
else
  fail "temoin : l'acte porte '# vcs: $VCS_C' au lieu de none"
fi
if [ -e "$P_C/.git" ]; then
  fail "temoin : un depot a ete cree alors que la reponse etait none"
else
  pass "temoin : aucun depot cree (vcs: none)"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
