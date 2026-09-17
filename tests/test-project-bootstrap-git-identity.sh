#!/usr/bin/env bash
# T4 (Mission 185-C01, porte 4 de la capture 2026-09-17-144137) : tout
# depot Git cree ou repris par tools/project-bootstrap.sh porte une
# identite d'auteur, donc son premier commit aboutit.
#
# Defaut mesure sur le poste de l'Owner : `adopt` faisait `git init` sans
# identite. Sur un poste sans `user.email` global -- le cas de l'Owner --
# le premier commit du projet mourait sur « Author identity unknown ».
# L'installeur, lui, en posait une sur le clone : deux chemins, une seule
# des deux portes fermee.
#
# Oracle (PASS attendu) : `create` puis `adopt --git`, avec un HOME vide et
# AUCUN `user.*` global ni systeme, acceptent un `git commit` dans le
# projet ; l'identite posee est celle du Vault installe quand il en a une,
# sinon l'identite neutre de repli, jamais rien.
# Temoin negatif (dans ce meme fichier) : sur le MEME projet, l'identite
# locale retiree (`git config --unset`), le meme commit est refuse et le
# refus nomme « Author identity unknown ».
#
# Les gardiens ne sont pas le sujet ici : `pre-commit install` est un
# substitut enregistreur (meme patron que tests/test-project-initiation.sh)
# et les commits de mesure tournent avec un dossier de hooks vide. Ce que
# ce test mesure est l'identite d'auteur, rien d'autre ; les gardiens sont
# mesures par tests/test-githooks-run-on-commit.sh.
#
# Ecrit seulement dans un dossier temporaire (prefixe m185). Aucun appel
# modele, aucun reseau.
#
# usage: bash tests/test-project-bootstrap-git-identity.sh
# Code 0 : tous les cas PASS (ou SKIP nomme). Code 1 sinon.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
SKIPS=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
skip() { echo "  SKIP ($1) - $2"; SKIPS=$((SKIPS + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- tools/project-bootstrap.sh en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-ident-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

# --- Substitut de pre-commit : `install` pose un hook, rien d'autre. ------
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

# --- Un poste SANS identite Git globale ni systeme -----------------------
# GIT_CONFIG_GLOBAL/GIT_CONFIG_SYSTEM plutot que HOME seul : sous Windows,
# Git lit aussi %USERPROFILE% et une configuration systeme posee par
# l'installateur -- rediriger HOME ne suffit pas a prouver l'absence.
mkdir -p "$TMP/home" "$TMP/emptyhooks"
: > "$TMP/home/.gitconfig-empty"
export HOME="$TMP/home"
export USERPROFILE="$(sandbox_native_path "$TMP/home")"
export GIT_CONFIG_GLOBAL="$(sandbox_native_path "$TMP/home/.gitconfig-empty")"
export GIT_CONFIG_SYSTEM="$(sandbox_native_path "$TMP/home/.gitconfig-empty")"
export GIT_CONFIG_NOSYSTEM=1
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL 2>/dev/null || true

EMPTY_HOOKS="$TMP/emptyhooks"

# control_no_global_identity : sans ce controle, tout le test ne prouve
# rien -- il mesurerait un poste qui a deja une identite globale.
if [ -z "$(git config --global --get user.email 2>/dev/null || true)" ] \
   && [ -z "$(git config --global --get user.name 2>/dev/null || true)" ]; then
  pass "controle : ce test tourne bien sans identite Git globale"
else
  fail "controle : une identite Git globale est encore visible -- le test ne prouverait rien"
fi

# try_commit <projet> <message> : commit de mesure, gardiens ecartes.
# Rend le code de sortie et laisse la sortie complete dans $LAST_COMMIT_OUT.
LAST_COMMIT_OUT=""
try_commit() {
  LAST_COMMIT_OUT="$(cd "$1" && git -c core.hooksPath="$EMPTY_HOOKS" add -A >/dev/null 2>&1; cd "$1" && git -c core.hooksPath="$EMPTY_HOOKS" commit -q -m "$2" 2>&1)"
  return $?
}

build_vault() {
  # $1 = destination du Vault jetable, $2 = 1 pour lui retirer son identite
  sandbox_vault "$REPO_ROOT" "$1" || return 1
  if [ "$2" = "1" ]; then
    git -C "$1" config --unset user.name >/dev/null 2>&1 || true
    git -C "$1" config --unset user.email >/dev/null 2>&1 || true
  fi
  return 0
}

# =============================================================================
echo "=== (a) create : identite copiee du Vault installe ==="
WS_A="$TMP/a/ws"
mkdir -p "$WS_A"
V_A="$WS_A/second-brain"
if ! build_vault "$V_A" 0; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V_A/tools/write-marker.sh" "$WS_A" >/dev/null
VAULT_NAME_A="$(git -C "$V_A" config --local --get user.name)"
VAULT_MAIL_A="$(git -C "$V_A" config --local --get user.email)"

P_A="$WS_A/projet-a"
bash "$V_A/tools/project-bootstrap.sh" create "$P_A" "Projet A" --vcs git >/dev/null 2>&1
if [ -d "$P_A/.git" ]; then
  pass "(a) create --vcs git : le depot existe"
else
  fail "(a) create --vcs git : aucun depot cree"
fi
GOT_NAME="$(git -C "$P_A" config --local --get user.name 2>/dev/null || true)"
GOT_MAIL="$(git -C "$P_A" config --local --get user.email 2>/dev/null || true)"
if [ "$GOT_NAME" = "$VAULT_NAME_A" ] && [ "$GOT_MAIL" = "$VAULT_MAIL_A" ]; then
  pass "(a) identite LOCALE du projet = celle du Vault installe ($GOT_NAME <$GOT_MAIL>)"
else
  fail "(a) identite du projet ($GOT_NAME <$GOT_MAIL>) != celle du Vault ($VAULT_NAME_A <$VAULT_MAIL_A>)"
fi
if try_commit "$P_A" "premier commit du projet A"; then
  pass "(a) git commit dans le projet : accepte"
else
  fail "(a) git commit dans le projet : refuse -- $LAST_COMMIT_OUT"
fi

# =============================================================================
echo ""
echo "=== (b) adopt --git : meme identite sur un dossier existant ==="
P_B="$WS_A/projet-b"
mkdir -p "$P_B"
printf '# notes\n\nDu texte.\n' > "$P_B/notes.md"
bash "$V_A/tools/project-bootstrap.sh" adopt "$P_B" "Projet B" --git >/dev/null 2>&1
if [ -d "$P_B/.git" ]; then
  pass "(b) adopt --git : le depot existe"
else
  fail "(b) adopt --git : aucun depot cree"
fi
GOT_NAME_B="$(git -C "$P_B" config --local --get user.name 2>/dev/null || true)"
if [ -n "$GOT_NAME_B" ]; then
  pass "(b) identite LOCALE posee a l'adoption ($GOT_NAME_B)"
else
  fail "(b) aucune identite locale posee a l'adoption"
fi
if try_commit "$P_B" "premier commit du projet B"; then
  pass "(b) git commit dans le projet adopte : accepte"
else
  fail "(b) git commit dans le projet adopte : refuse -- $LAST_COMMIT_OUT"
fi

# =============================================================================
echo ""
echo "=== (c) Vault sans identite locale : repli neutre, jamais rien ==="
WS_C="$TMP/c/ws"
mkdir -p "$WS_C"
V_C="$WS_C/second-brain"
if build_vault "$V_C" 1; then
  bash "$V_C/tools/write-marker.sh" "$WS_C" >/dev/null
  P_C="$WS_C/projet-c"
  bash "$V_C/tools/project-bootstrap.sh" create "$P_C" "Projet C" --vcs git >/dev/null 2>&1
  GOT_NAME_C="$(git -C "$P_C" config --local --get user.name 2>/dev/null || true)"
  GOT_MAIL_C="$(git -C "$P_C" config --local --get user.email 2>/dev/null || true)"
  if [ "$GOT_NAME_C" = "Second Brain Installer" ] && [ "$GOT_MAIL_C" = "installer@example.invalid" ]; then
    pass "(c) repli neutre pose ($GOT_NAME_C <$GOT_MAIL_C>)"
  else
    fail "(c) repli neutre attendu, lu : '$GOT_NAME_C' <$GOT_MAIL_C>"
  fi
  if try_commit "$P_C" "premier commit du projet C"; then
    pass "(c) git commit dans le projet : accepte"
  else
    fail "(c) git commit dans le projet : refuse -- $LAST_COMMIT_OUT"
  fi
else
  skip "Vault jetable sans identite non construit" "(c) repli neutre"
fi

# =============================================================================
echo ""
echo "=== temoin negatif : identite locale retiree -> commit refuse ==="
# Le MEME projet, le MEME commit, la seule identite en moins.
printf '\nUne ligne de plus.\n' >> "$P_A/README.md"
git -C "$P_A" config --unset user.name >/dev/null 2>&1 || true
git -C "$P_A" config --unset user.email >/dev/null 2>&1 || true
if try_commit "$P_A" "commit temoin, sans identite"; then
  fail "temoin : le commit passe alors que l'identite a ete retiree"
else
  case "$LAST_COMMIT_OUT" in
    *"Author identity unknown"*|*"empty ident"*|*"unable to auto-detect email"*)
      pass "temoin : le commit est refuse et nomme l'identite manquante" ;;
    *)
      fail "temoin : commit refuse, mais pour une autre cause -- $LAST_COMMIT_OUT" ;;
  esac
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS, $SKIPS SKIP) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS, $SKIPS SKIP) ==="
exit 1
