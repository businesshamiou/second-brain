#!/usr/bin/env bash
# T2 (Mission 185-C01, door 2 of capture 2026-09-17-144137):
# the origin engraved by the installation is the REAL origin of the repository, never
# the temporary folder it passed through.
#
# Defect measured on the Owner's machine: `vault_origin` -- in
# VAULT-IDENTITY.md, in the VAULT-ROOT.md marker and in each project's birth
# certificate -- was
# C:\Users\...\AppData\Local\Temp\second-brain-install, like `origin` of the
# installed clone. Cause: the bootstrap clones into a temporary folder,
# the installer clones FROM that folder, and nobody spoke again of where
# everything comes from. A Vault that does not know where it comes from can neither
# update itself nor prove its provenance.
#
# Oracle (PASS expected): source carrying a remote -> `vault_origin` in
# VAULT-IDENTITY.md, in the marker and in the first project's certificate equals
# the URL of that remote; `git -C <installed clone> remote get-url origin` returns
# the same URL.
# Negative control (in this same file): source WITHOUT a remote -> fallback to
# the source's path, and the message is SHOWN to the participant, never
# set silently.
#
# Writes only in a temporary folder (prefix m185), with a simulated
# profile (--test-mode --test-root): nothing reaches the real profile. No
# network to GitHub -- the remote's URL is declared, never reached.
#
# usage: bash tests/test-install-vault-origin.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

# The source of each case is a CLONE of this repository, never a copy of
# the working tree: a clone keeps the index modes (the execute
# bit of the guardians, absent from NTFS) and carries VAULT-IDENTITY.md in its
# skeleton state -- the two conditions of an installation that goes all the
# way. This test therefore measures the COMMITTED tree, like
# tests/test-install-e2e.sh.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/vault-identity.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- l'installeur en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-origin-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== T2 : l'origine gravee est l'origine reelle ==="
echo "  TestRoot: $TMP"

# The URL declared as the source's remote. Never reached: `git remote add`
# opens no connection, and the installer clones from the FOLDER.
DECLARED_ORIGIN="https://github.com/businesshamiou/second-brain.git"

run_install() {
  # $1 = root of the case, $2 = source. Returns the full output (both
  # streams), the code in $LAST_RC.
  mkdir -p "$1"
  sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$1/workspace\"#" \
    "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$1/answers.json"
  LAST_OUT="$(bash "$REPO_ROOT/install.sh" --source "$2" --answers-file "$1/answers.json" \
    --test-mode --test-root "$1" 2>&1)"
  LAST_RC=$?
  # uv installed by the installer under its own test profile: put back on
  # this process's PATH for the measurements that follow (same reason as
  # tests/test-install-e2e.sh).
  [ -d "$1/profile/.local/bin" ] && PATH="$1/profile/.local/bin:$PATH" && export PATH
  return "$LAST_RC"
}

# =============================================================================
echo ""
echo "=== (a) oracle : source portant un remote ==="
SRC_A="$TMP/source-a"
# Mission 188: copy of the shared reference clone, at the same commit as this
# repository (HEAD re-measured by sandbox_reference_clone), instead of a clone
# made by this test alone. The remote is set again right after, as before.
REF_CLONE="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference non construit"; exit 1; }
if ! git clone --quiet -- "$REF_CLONE" "$SRC_A" >/dev/null 2>&1; then
  echo "FAIL : source (clone de ce depot) non construite"
  exit 1
fi
git -C "$SRC_A" remote set-url origin "$DECLARED_ORIGIN" >/dev/null 2>&1
READ_BACK="$(git -C "$SRC_A" config --get remote.origin.url)"
if [ "$READ_BACK" = "$DECLARED_ORIGIN" ]; then
  pass "(a) controle : la source porte bien le remote declare"
else
  fail "(a) controle : remote de la source = '$READ_BACK'"
fi

R_A="$TMP/a"
run_install "$R_A" "$SRC_A"
RC_A=$?
if [ "$RC_A" = "0" ]; then
  pass "(a) l'installation rend 0"
else
  fail "(a) l'installation rend $RC_A -- $(printf '%s' "$LAST_OUT" | tail -n 3)"
fi

CLONE_A="$R_A/workspace/second-brain"
GOT_REMOTE="$(git -C "$CLONE_A" config --get remote.origin.url 2>/dev/null || echo absent)"
if [ "$GOT_REMOTE" = "$DECLARED_ORIGIN" ]; then
  pass "(a) origin du clone installe = l'origine reelle"
else
  fail "(a) origin du clone installe = '$GOT_REMOTE', attendu '$DECLARED_ORIGIN'"
fi

GOT_IDENTITY="$(vid_get "$CLONE_A" vault_origin)"
if [ "$GOT_IDENTITY" = "$DECLARED_ORIGIN" ]; then
  pass "(a) VAULT-IDENTITY.md : vault_origin = l'origine reelle"
else
  fail "(a) VAULT-IDENTITY.md : vault_origin = '$GOT_IDENTITY'"
fi

MARKER="$R_A/workspace/VAULT-ROOT.md"
if [ -f "$MARKER" ] && grep -qF -- "$DECLARED_ORIGIN" "$MARKER"; then
  pass "(a) marqueur VAULT-ROOT.md : vault_origin = l'origine reelle"
else
  fail "(a) marqueur VAULT-ROOT.md ne porte pas l'origine reelle"
fi

CERT="$(ls -1 "$R_A"/workspace/*/.pre-commit-config.yaml 2>/dev/null | head -n 1)"
if [ -n "$CERT" ]; then
  CERT_ORIGIN="$(tr -d '\r' < "$CERT" | sed -n 's/^# vault_origin: //p' | head -n 1)"
  if [ "$CERT_ORIGIN" = "$DECLARED_ORIGIN" ]; then
    pass "(a) acte de naissance du premier projet : vault_origin = l'origine reelle"
  else
    fail "(a) acte du premier projet : vault_origin = '$CERT_ORIGIN'"
  fi
else
  fail "(a) aucun acte de naissance trouve : le premier projet n'a pas ete cree"
fi

# The origin defect is named: the source folder's path must
# appear nowhere as an origin.
if [ -n "$(vid_get "$CLONE_A" vault_origin)" ] && ! printf '%s' "$GOT_IDENTITY" | grep -q 'second-brain-install'; then
  pass "(a) aucune trace du dossier temporaire dans vault_origin"
else
  fail "(a) vault_origin porte encore une trace de dossier temporaire"
fi

# =============================================================================
echo ""
echo "=== temoin negatif : source SANS remote ==="
SRC_B="$TMP/source-b"
if ! git clone --quiet -- "$REF_CLONE" "$SRC_B" >/dev/null 2>&1; then
  echo "FAIL : source (clone de ce depot) non construite"
  exit 1
fi
git -C "$SRC_B" remote remove origin >/dev/null 2>&1
if [ -z "$(git -C "$SRC_B" config --get remote.origin.url 2>/dev/null || true)" ]; then
  pass "temoin : controle -- la source n'a aucun remote"
else
  fail "temoin : controle -- la source a un remote, le temoin ne prouverait rien"
fi

R_B="$TMP/b"
run_install "$R_B" "$SRC_B"
RC_B=$?
[ "$RC_B" = "0" ] && pass "temoin : l'installation rend 0 quand meme" || fail "temoin : l'installation rend $RC_B"

CLONE_B="$R_B/workspace/second-brain"
ORIGIN_B="$(vid_get "$CLONE_B" vault_origin)"
SRC_B_REAL="$(cd "$SRC_B" && pwd)"
if [ -n "$ORIGIN_B" ]; then
  pass "temoin : vault_origin est renseigne malgre l'absence de remote ($ORIGIN_B)"
else
  fail "temoin : vault_origin est vide"
fi
# The fallback is the source's PATH, not an invention.
if printf '%s' "$ORIGIN_B" | grep -qF -- "$(basename "$SRC_B_REAL")"; then
  pass "temoin : le repli est bien le chemin de la source"
else
  fail "temoin : le repli ($ORIGIN_B) ne nomme pas la source ($SRC_B_REAL)"
fi
# ... and it is SAID, never set silently.
MESSAGE="$(uv run --no-project "$REPO_ROOT/tools/sb_installer_helper.py" format-catalog \
  "$REPO_ROOT/i18n/catalog.en.json" "install.vaultOrigin.fallback" "$SRC_B_REAL" 2>/dev/null | head -n 1)"
MARKER_WORDS="$(printf '%s' "$MESSAGE" | sed 's/[^A-Za-z ].*$//' | head -n 1)"
if [ -n "$MARKER_WORDS" ] && printf '%s' "$LAST_OUT" | grep -qF -- "$MARKER_WORDS"; then
  pass "temoin : le repli est dit au participant (\"$MARKER_WORDS...\")"
else
  fail "temoin : le repli est pose en silence -- attendu \"$MARKER_WORDS\" dans la sortie"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
