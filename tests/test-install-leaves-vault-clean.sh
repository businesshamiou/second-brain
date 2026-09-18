#!/usr/bin/env bash
# T3 (Mission 185-C01, door 8 of capture 2026-09-17-144137): a
# finished installation leaves the installed Vault with an EMPTY porcelain.
#
# Defect measured on the Owner's machine: after the installation, the first
# project's record stayed untracked and two indexes modified. The
# participant's very first commit would have carried files they did not write,
# and the index freshness guardian precisely refuses a modified index:
# the Vault was delivered in the state it forbids.
#
# Oracle (PASS expected): `git status --porcelain` of the installed clone is
# empty at the end of the installation -- and a second run produces
# no commit (the resume stays a no-op).
# Negative control (in this same file): an INTERRUPTED installation
# before the final commit (forced stop after the firstProject step) leaves a
# NON-empty porcelain, seen by the same measurement -- otherwise this test would
# also pass on a repository where nothing had been written.
#
# The source is a CLONE of this repository, never a copy of the working
# tree: a clone keeps the index modes (the execute bit of the
# guardians, absent from NTFS) and carries VAULT-IDENTITY.md in its
# skeleton state. This test therefore measures the COMMITTED tree, like
# tests/test-install-e2e.sh.
#
# Writes only in a temporary folder (prefix m185), simulated profile.
#
# usage: bash tests/test-install-leaves-vault-clean.sh
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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m185-clean-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== T3 : le Vault installe est rendu au porcelain vide ==="
echo "  TestRoot: $TMP"

SRC="$TMP/source"
# Mission 188: copy of the shared reference clone, at the same commit as this
# repository (HEAD re-measured by sandbox_reference_clone), instead of a clone
# made by this test alone.
REF_CLONE="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference non construit"; exit 1; }
if ! git clone --quiet -- "$REF_CLONE" "$SRC" >/dev/null 2>&1; then
  echo "FAIL : source (clone de ce depot) non construite"
  exit 1
fi

run_install() {
  # $1 = root of the case, $2... = extra arguments for install.sh.
  CASE_ROOT="$1"; shift
  mkdir -p "$CASE_ROOT"
  sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$CASE_ROOT/workspace\"#" \
    "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$CASE_ROOT/answers.json"
  LAST_OUT="$(bash "$REPO_ROOT/install.sh" --source "$SRC" --answers-file "$CASE_ROOT/answers.json" \
    --test-mode --test-root "$CASE_ROOT" "$@" 2>&1)"
  LAST_RC=$?
  [ -d "$CASE_ROOT/profile/.local/bin" ] && PATH="$CASE_ROOT/profile/.local/bin:$PATH" && export PATH
  return "$LAST_RC"
}

porcelain_of() {
  git -C "$1" status --porcelain 2>/dev/null
}

# =============================================================================
echo ""
echo "=== (a) oracle : installation complete ==="
R_A="$TMP/a"
run_install "$R_A"
RC_A=$?
if [ "$RC_A" = "0" ]; then
  pass "(a) l'installation rend 0"
else
  fail "(a) l'installation rend $RC_A -- $(printf '%s' "$LAST_OUT" | tail -n 3)"
fi

CLONE_A="$R_A/workspace/second-brain"
if [ -d "$CLONE_A/.git" ]; then
  pass "(a) le Vault est installe"
else
  fail "(a) aucun Vault installe"
  echo "=== RESULT: FAIL ($FAILURES) ==="
  exit 1
fi

PORC_A="$(porcelain_of "$CLONE_A")"
if [ -z "$PORC_A" ]; then
  pass "(a) git status --porcelain du Vault installe : vide"
else
  fail "(a) porcelain non vide :
$(printf '%s' "$PORC_A" | sed 's/^/      /')"
fi

# The first project does exist: without it, the porcelain would be empty for
# the wrong reason and this measurement would prove nothing.
FIRST_PROJECT="$(ls -1d "$R_A"/workspace/*/ 2>/dev/null | grep -v '/second-brain/$' | head -n 1)"
if [ -n "$FIRST_PROJECT" ]; then
  pass "(a) controle : un premier projet a bien ete cree ($(basename "${FIRST_PROJECT%/}"))"
else
  fail "(a) controle : aucun premier projet -- la mesure ne prouverait rien"
fi

# The project's record is TRACKED, not left aside.
UNTRACKED_RECORD="$(git -C "$CLONE_A" ls-files --others --exclude-standard -- projects/ 2>/dev/null)"
if [ -z "$UNTRACKED_RECORD" ]; then
  pass "(a) aucune fiche de projet non suivie"
else
  fail "(a) fiche(s) de projet non suivie(s) : $UNTRACKED_RECORD"
fi

# A second run stays a no-op: no commit produced.
HEAD_BEFORE="$(git -C "$CLONE_A" rev-parse HEAD)"
run_install "$R_A"
RC_A2=$?
HEAD_AFTER="$(git -C "$CLONE_A" rev-parse HEAD)"
[ "$RC_A2" = "0" ] && pass "(a) seconde execution : rend 0" || fail "(a) seconde execution : rend $RC_A2"
if [ "$HEAD_BEFORE" = "$HEAD_AFTER" ]; then
  pass "(a) seconde execution : aucun commit fabrique"
else
  fail "(a) seconde execution : un commit a ete fabrique ($HEAD_BEFORE -> $HEAD_AFTER)"
fi
if [ -z "$(porcelain_of "$CLONE_A")" ]; then
  pass "(a) seconde execution : porcelain toujours vide"
else
  fail "(a) seconde execution : porcelain devenu non vide"
fi

# =============================================================================
echo ""
echo "=== temoin negatif : l'etat exact de la porte 8, reproduit ==="
# A `--stop-after-step` is NOT enough to produce this control: each step
# of the installer commits before its stopping point, and the measurement would
# land on an empty porcelain for the wrong reason (measured right here, Mission
# 185-C01). The state of door 8 is therefore reproduced as it was
# observed: a project record written in the Vault and the indexes touched,
# without the commit that records them -- which is what any call to
# project-bootstrap.sh outside the installer does.
if bash "$CLONE_A/tools/project-bootstrap.sh" create "$R_A/workspace/second-projet" "Second projet" --vcs none >/dev/null 2>&1; then
  pass "temoin : un second projet est cree contre le Vault installe"
else
  fail "temoin : le second projet n'a pas pu etre cree"
fi
PORC_B="$(porcelain_of "$CLONE_A")"
if [ -n "$PORC_B" ]; then
  pass "temoin : la meme mesure voit un porcelain NON vide ($(printf '%s\n' "$PORC_B" | grep -c .) ligne(s))"
  printf '%s\n' "$PORC_B" | head -n 4 | sed 's/^/      /'
else
  fail "temoin : porcelain vide alors que le Vault vient d'etre touche -- la mesure ne prouverait rien"
fi

# ... and the end-of-installation pass is indeed what closes this state:
# one more run cleans it, and this time it produces a commit.
HEAD_DIRTY="$(git -C "$CLONE_A" rev-parse HEAD)"
run_install "$R_A"
RC_A3=$?
HEAD_CLEAN="$(git -C "$CLONE_A" rev-parse HEAD)"
[ "$RC_A3" = "0" ] && pass "temoin : l'installation rend 0 sur un Vault sali" || fail "temoin : l'installation rend $RC_A3"
if [ -z "$(porcelain_of "$CLONE_A")" ]; then
  pass "temoin : le passage de fin d'installation ramene le porcelain a vide"
else
  fail "temoin : le porcelain reste non vide apres le passage de fin"
fi
if [ "$HEAD_DIRTY" != "$HEAD_CLEAN" ]; then
  pass "temoin : ce passage a bien fabrique un commit -- il n'est pas decoratif"
else
  fail "temoin : aucun commit fabrique alors que le Vault etait sali"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
