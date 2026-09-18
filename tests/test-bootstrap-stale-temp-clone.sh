#!/usr/bin/env bash
# T1 (Mission 185-C01, door 1 of capture 2026-09-17-144137): an
# ALREADY cloned temporary folder is brought to --ref, never installed as
# it stands.
#
# Defect measured on the Owner's machine, the gravest of the acceptance:
# `bootstrap.*` skipped clone AND checkout as soon as <cible>/.git existed.
# A forgotten %TEMP%\second-brain-install (2026-09-14, commit of 2026-09-13,
# older than every tag) therefore installed a stale version -- no
# identity, no birth certificate, no Pilot prompt -- with a clean
# verdict. Invisible in CI, where every scenario starts from an empty TestRoot.
#
# Oracle (PASS expected): a TestRoot whose `second-brain-install` is already
# cloned at an EARLIER commit, then the line; after it,
# `rev-parse HEAD` of the temporary folder = `<ref>^{commit}`, and the
# installed Vault is at the same commit.
# Negative controls (in this same file):
#   - nonexistent `--ref` -> refusal naming the ref, nothing installed;
#   - temporary folder whose `origin` is not `--repo-url` -> refusal naming
#     BOTH URLs, nothing installed, folder never deleted.
#
# The real bootstrap is replayed, with local `--repo-url`/`--raw-base` --
# same pattern as tests/test-bootstrap-no-git.ps1 -- and the install is
# stopped right after the clone step: this test measures the clone step,
# not the full install (measured by tests/test-install-e2e.sh).
#
# Writes only in a temporary folder (prefix m185). No network
# to GitHub, no model call.
#
# usage: bash tests/test-bootstrap-stale-temp-clone.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- l'installeur en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-stale-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== T1 : dossier temporaire deja clone, amene a --ref ==="
echo "  TestRoot: $TMP"

# --- A local source with TWO commits and a tag ---------------------------
# The tag is placed AFTER the commit of the stale clone: that is the
# exact situation of the Owner's machine -- the forgotten folder does not
# know the published version yet.
SRC="$TMP/source"
if ! sandbox_vault "$REPO_ROOT" "$SRC"; then
  echo "FAIL : source jetable non construite"
  exit 1
fi
OLD_REF="$(git -C "$SRC" rev-parse HEAD)"
printf '\nUne ligne de la version suivante.\n' >> "$SRC/USER.md"
git -C "$SRC" add -- USER.md >/dev/null 2>&1
git -C "$SRC" commit -q -m "version suivante" >/dev/null 2>&1
NEW_REF="$(git -C "$SRC" rev-parse HEAD)"
git -C "$SRC" tag v-test >/dev/null 2>&1
WANTED="$(git -C "$SRC" rev-parse 'v-test^{commit}')"

if [ "$OLD_REF" != "$NEW_REF" ] && [ "$WANTED" = "$NEW_REF" ]; then
  pass "controle : source a deux commits, etiquette v-test sur le second"
else
  fail "controle : source mal construite (old=$OLD_REF new=$NEW_REF tag=$WANTED)"
  echo "=== RESULT: FAIL ($FAILURES) ==="
  exit 1
fi

answers_file() {
  # $1 = TestRoot of the case. Returns the path of the answers file written.
  sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$1/workspace\"#" \
    "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$1/answers.json"
  printf '%s\n' "$1/answers.json"
}

stale_clone() {
  # $1 = TestRoot, $2 = commit to place. Stale clone, detached, like a
  # temporary folder forgotten by a previous install.
  mkdir -p "$1"
  git clone --quiet --no-checkout -- "$SRC" "$1/second-brain-install" >/dev/null 2>&1 || return 1
  git -C "$1/second-brain-install" -c advice.detachedHead=false checkout --quiet --detach "$2" >/dev/null 2>&1 || return 1
  # The forgotten folder on the Owner's machine dated from BEFORE publication: it
  # knew no tag. `git clone` always brings some along;
  # they are removed here to reproduce that state exactly, and it is
  # the line's `fetch --tags` that must bring them back.
  git -C "$1/second-brain-install" tag -d v-test >/dev/null 2>&1 || true
  return 0
}

# =============================================================================
echo ""
echo "=== (a) oracle : le dossier perime est amene a l'etiquette ==="
R_A="$TMP/a"
mkdir -p "$R_A"
if ! stale_clone "$R_A" "$OLD_REF"; then
  echo "FAIL : clone perime non construit"
  exit 1
fi
HEAD_BEFORE="$(git -C "$R_A/second-brain-install" rev-parse HEAD)"
if [ "$HEAD_BEFORE" = "$OLD_REF" ]; then
  pass "(a) controle : le dossier temporaire part bien d'un commit anterieur ($OLD_REF)"
else
  fail "(a) controle : le dossier temporaire n'est pas au commit anterieur"
fi
if git -C "$R_A/second-brain-install" rev-parse --verify --quiet 'refs/tags/v-test' >/dev/null; then
  fail "(a) controle : le dossier temporaire connait deja l'etiquette -- le cas n'est pas reproduit"
else
  pass "(a) controle : le dossier temporaire ne connait pas encore l'etiquette"
fi

A_ANSWERS="$(answers_file "$R_A")"
OUT_A="$(bash "$REPO_ROOT/bootstrap.sh" --ref v-test --repo-url "$SRC" --raw-base "$SRC" \
  --test-mode --test-root "$R_A" --answers-file "$A_ANSWERS" --stop-after-step clone 2>&1)"
printf '%s\n' "$OUT_A" | tail -n 3 | sed 's/^/    /'

case "$OUT_A" in
  *"after step: clone"*) pass "(a) l'installation a bien atteint l'etape de clone" ;;
  *) fail "(a) l'etape de clone n'a pas ete atteinte" ;;
esac
HEAD_AFTER="$(git -C "$R_A/second-brain-install" rev-parse HEAD 2>/dev/null || echo absent)"
if [ "$HEAD_AFTER" = "$WANTED" ]; then
  pass "(a) dossier temporaire : HEAD = v-test^{commit} ($WANTED)"
else
  fail "(a) dossier temporaire : HEAD = $HEAD_AFTER, attendu $WANTED"
fi
INSTALLED="$R_A/workspace/second-brain"
INSTALLED_HEAD="$(git -C "$INSTALLED" rev-parse HEAD 2>/dev/null || echo absent)"
if [ "$INSTALLED_HEAD" = "$WANTED" ]; then
  pass "(a) Vault installe : HEAD = v-test^{commit}"
else
  fail "(a) Vault installe : HEAD = $INSTALLED_HEAD, attendu $WANTED"
fi
# The content follows the commit, not only the reference.
if [ -f "$INSTALLED/USER.md" ] && grep -q 'Une ligne de la version suivante' "$INSTALLED/USER.md"; then
  pass "(a) le contenu installe est celui de v-test, pas celui du dossier perime"
else
  fail "(a) le contenu installe n'est pas celui de v-test"
fi

# =============================================================================
echo ""
echo "=== (b) temoin : --ref inexistant ==="
R_B="$TMP/b"
mkdir -p "$R_B"
stale_clone "$R_B" "$OLD_REF" || { echo "FAIL : clone perime non construit"; exit 1; }
B_ANSWERS="$(answers_file "$R_B")"
OUT_B="$(bash "$REPO_ROOT/bootstrap.sh" --ref v-inexistante --repo-url "$SRC" --raw-base "$SRC" \
  --test-mode --test-root "$R_B" --answers-file "$B_ANSWERS" --stop-after-step clone 2>&1)"
RC_B=$?
[ "$RC_B" != "0" ] && pass "(b) rend un code non nul ($RC_B)" || fail "(b) rend 0 alors que le ref n'existe pas"
case "$OUT_B" in
  *"v-inexistante"*) pass "(b) le refus nomme le ref demande" ;;
  *) fail "(b) le refus ne nomme pas le ref -- $OUT_B" ;;
esac
if [ -e "$R_B/workspace/second-brain" ]; then
  fail "(b) un Vault a quand meme ete installe"
else
  pass "(b) rien n'est installe"
fi
HEAD_B="$(git -C "$R_B/second-brain-install" rev-parse HEAD 2>/dev/null || echo absent)"
if [ "$HEAD_B" = "$OLD_REF" ]; then
  pass "(b) le dossier temporaire est laisse ou il etait, jamais supprime"
else
  fail "(b) le dossier temporaire a bouge ($HEAD_B)"
fi

# =============================================================================
echo ""
echo "=== (c) temoin : dossier temporaire d'une AUTRE origine ==="
R_C="$TMP/c"
mkdir -p "$R_C"
stale_clone "$R_C" "$OLD_REF" || { echo "FAIL : clone perime non construit"; exit 1; }
OTHER="$TMP/autre-depot"
mkdir -p "$OTHER"
git -C "$R_C/second-brain-install" remote set-url origin "$OTHER" >/dev/null 2>&1
C_ANSWERS="$(answers_file "$R_C")"
OUT_C="$(bash "$REPO_ROOT/bootstrap.sh" --ref v-test --repo-url "$SRC" --raw-base "$SRC" \
  --test-mode --test-root "$R_C" --answers-file "$C_ANSWERS" --stop-after-step clone 2>&1)"
RC_C=$?
[ "$RC_C" != "0" ] && pass "(c) rend un code non nul ($RC_C)" || fail "(c) rend 0 malgre l'origine differente"
# Both URLs are named as each source writes them: the folder's one
# comes from its .git/config (native form under Git Bash), the requested
# one comes from the line. That is exactly what must be shown to the
# participant -- so we compare the folders named, not a spelling.
NAMED_BOTH=0
case "$OUT_C" in
  *"$(basename "$OTHER")"*)
    case "$OUT_C" in *"$(basename "$SRC")"*) NAMED_BOTH=1 ;; esac ;;
esac
if [ "$NAMED_BOTH" = "1" ]; then
  pass "(c) le refus nomme les DEUX depots (celui du dossier et celui demande)"
else
  fail "(c) le refus ne nomme pas les deux depots -- $OUT_C"
fi
case "$OUT_C" in
  *"$R_C/second-brain-install"*) pass "(c) le refus nomme le dossier a ecarter" ;;
  *) fail "(c) le refus ne nomme pas le dossier a ecarter" ;;
esac
if [ -e "$R_C/workspace/second-brain" ]; then
  fail "(c) un Vault a quand meme ete installe"
else
  pass "(c) rien n'est installe"
fi
if [ -d "$R_C/second-brain-install/.git" ]; then
  pass "(c) le dossier temporaire n'est jamais supprime"
else
  fail "(c) le dossier temporaire a ete supprime"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
