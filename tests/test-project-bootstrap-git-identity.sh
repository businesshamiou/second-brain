#!/usr/bin/env bash
# T4 (Mission 185-C01, door 4 of capture 2026-09-17-144137): every
# Git repository created or taken over by tools/project-bootstrap.sh carries an
# author identity, so its first commit succeeds.
#
# Defect measured on the Owner's machine: `adopt` ran `git init` without an
# identity. On a machine without a global `user.email` -- the Owner's case --
# the project's first commit died on « Author identity unknown ».
# The installer, for its part, set one on the clone: two paths, only one
# of the two doors closed.
#
# Oracle (PASS expected): `create` then `adopt --git`, with an empty HOME and
# NO global or system `user.*`, accept a `git commit` in the
# project; the identity set is the installed Vault's when it has one,
# otherwise the neutral fallback identity, never nothing.
# Negative control (in this same file): on the SAME project, with the local
# identity removed (`git config --unset`), the same commit is refused and the
# refusal names « Author identity unknown ».
#
# The guardians are not the subject here: `pre-commit install` is a
# recording stand-in (same pattern as tests/test-project-initiation.sh)
# and the measurement commits run with an empty hooks folder. What
# this test measures is the author identity, nothing else; the guardians are
# measured by tests/test-githooks-run-on-commit.sh.
#
# Writes only in a temporary folder (prefix m185). No model
# call, no network.
#
# usage: bash tests/test-project-bootstrap-git-identity.sh
# Exit 0: all cases PASS (or named SKIP). Exit 1 otherwise.

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

# --- pre-commit stand-in: `install` sets a hook, nothing else. ------------
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

# --- A machine WITHOUT a global or system Git identity -------------------
# GIT_CONFIG_GLOBAL/GIT_CONFIG_SYSTEM rather than HOME alone: under Windows,
# Git also reads %USERPROFILE% and a system configuration set by
# the Git installer -- redirecting HOME is not enough to prove the absence.
mkdir -p "$TMP/home" "$TMP/emptyhooks"
: > "$TMP/home/.gitconfig-empty"
export HOME="$TMP/home"
export USERPROFILE="$(sandbox_native_path "$TMP/home")"
export GIT_CONFIG_GLOBAL="$(sandbox_native_path "$TMP/home/.gitconfig-empty")"
export GIT_CONFIG_SYSTEM="$(sandbox_native_path "$TMP/home/.gitconfig-empty")"
export GIT_CONFIG_NOSYSTEM=1
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL 2>/dev/null || true

EMPTY_HOOKS="$TMP/emptyhooks"

# control_no_global_identity: without this check, the whole test proves
# nothing -- it would measure a machine that already has a global identity.
if [ -z "$(git config --global --get user.email 2>/dev/null || true)" ] \
   && [ -z "$(git config --global --get user.name 2>/dev/null || true)" ]; then
  pass "controle : ce test tourne bien sans identite Git globale"
else
  fail "controle : une identite Git globale est encore visible -- le test ne prouverait rien"
fi

# try_commit <projet> <message> [config...]: measurement commit, guardians
# set aside. Returns the exit code and leaves the full output in
# $LAST_COMMIT_OUT.
LAST_COMMIT_OUT=""
try_commit() {
  TC_DIR="$1"; TC_MSG="$2"; shift 2
  LAST_COMMIT_OUT="$(cd "$TC_DIR" && git -c core.hooksPath="$EMPTY_HOOKS" add -A >/dev/null 2>&1; cd "$TC_DIR" && git -c core.hooksPath="$EMPTY_HOOKS" "$@" commit -q -m "$TC_MSG" 2>&1)"
  return $?
}

build_vault() {
  # $1 = destination of the disposable Vault, $2 = 1 to remove its identity
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
# The SAME project, the SAME commit, only the identity missing.
#
# `user.useConfigOnly=true`: without it, this control does not measure the same
# thing everywhere. When no identity is configured, Git GUESSES one
# from the account and the machine name if it can -- which it does on
# the macOS runner (measured, Mission 185-C01, round 2: the commit went through) and
# which it could not do on the Owner's machine, where the defect
# showed up. This setting disables the guessing: the measured condition
# becomes « aucune identite configuree » ["no identity configured"] on the
# three systems, which door 4 fixes. Set on the command only (-c), never in the repository.
printf '\nUne ligne de plus.\n' >> "$P_A/README.md"
git -C "$P_A" config --unset user.name >/dev/null 2>&1 || true
git -C "$P_A" config --unset user.email >/dev/null 2>&1 || true
if try_commit "$P_A" "commit temoin, sans identite" -c user.useConfigOnly=true; then
  fail "temoin : le commit passe alors que l'identite a ete retiree"
else
  case "$LAST_COMMIT_OUT" in
    *"Author identity unknown"*|*"empty ident"*|*"unable to auto-detect email"*|*"auto-detection is disabled"*)
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
