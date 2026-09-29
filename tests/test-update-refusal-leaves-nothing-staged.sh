#!/usr/bin/env bash
# P5 of report 227 (Mission 230): a refused update leaves NOTHING staged.
#
# Measured in the audit on the v0.1.9 tool: refused, it said "nothing was
# changed" while `index.md` stayed staged (`M  index.md`) -- the participant
# who then ran `git status` saw work they never did. The audit did not measure
# the current tool. This test measures it, on every refusal that happens after
# the merge has started, and keeps the property nailed down for the versions
# to come.
#
# Fixture: a throwaway source with two tags built from this repository's HEAD.
#   v-old : this tree, plus a sentinel file;
#   v-new : this tree, the sentinel gone -- and, for case (a) only, a
#           `.githooks/pre-commit` that refuses everything, which is how a
#           guardian's refusal at the merge commit is played without breaking
#           anything real.
#
#   (a) a guardian refuses the merge commit -> REFUSED; `git diff --cached`
#       empty, porcelain empty, HEAD where it was, index.md untouched;
#   (b) same with the v0.1.9 tool: the RED witness of the audit. Reported,
#       never failed -- it measures an old tool, not this tree. Skipped when
#       that tag is absent from the history.
#   (c) another corpus file in conflict -> REFUSED, nothing staged;
#   (d) the identity would change -> REFUSED, nothing staged.
#
# usage: bash tests/test-update-refusal-leaves-nothing-staged.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
SKIPS=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
skip() { echo "  SKIP - $1"; SKIPS=$((SKIPS + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m230-staged-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

install_commit() {
  bash "$1/tools/build-indexes.sh" "$1" >/dev/null 2>&1
  git -C "$1" status --porcelain | cut -c4- | while IFS= read -r p; do git -C "$1" add -- "$p"; done
  bash "$1/tools/session-preflight.sh" >/dev/null 2>&1 || true
  git -C "$1" commit -q -m "$2" >"$TMP/commit.log" 2>&1 || { sed "s/^/      /" "$TMP/commit.log" | tail -n 15; return 1; }
}

echo "=== P5 : un refus de mise a jour ne laisse rien d'indexe ==="

# --- Source with two tags ------------------------------------------------------
SRC="$TMP/source"
REF_CLONE="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference non construit"; exit 1; }
git -c core.longpaths=true clone -q -- "$REF_CLONE" "$SRC" 2>/dev/null || { echo "FAIL : source non construite"; exit 1; }
git -C "$SRC" config core.longpaths true
git -C "$SRC" config user.name fixture
git -C "$SRC" config user.email fixture@example.invalid
git -C "$SRC" tag -l | while IFS= read -r t; do git -C "$SRC" tag -d "$t" >/dev/null; done
cat > "$SRC/VAULT-IDENTITY.md" <<'EOF'
---
type: vault-identity
title: "Identity of this Vault — skeleton"
description: "Empty skeleton, replaced at installation by a generated identity (vault_id, vault_origin). No identity before installation."
status: template
vault_id: ""
vault_origin: ""
created_at: ""
---

# IDENTITY OF THIS VAULT

_(This file is generated at installation by `tools/vault-identity.sh ensure`. Before installation, it carries no identity: each installation generates its own.)_

## Liens

- `see also` — [Decision — Project initiation and adoption, birth certificate](./decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
EOF
(
  cd "$SRC" || exit 1
  printf 'Sentinel of the old version.\n' > SENTINEL-old.txt
  printf 'SENTINEL-old.txt\tDISTRIBUABLE\n' >> distribution-manifest.txt
  bash tools/build-indexes.sh "$PWD" >/dev/null 2>&1
  git add -A && git commit -q -m "fixture v-old" && git tag -a v-old -m v-old
  git rm -q SENTINEL-old.txt
  grep -v '^SENTINEL-old\.txt' distribution-manifest.txt > .m && mv .m distribution-manifest.txt
  sed '1s/.*/NEW RELEASE LINE/' RELEASE-NOTES.md > .rn && mv .rn RELEASE-NOTES.md
  bash tools/build-indexes.sh "$PWD" >/dev/null 2>&1
  git add -A && git commit -q -m "fixture v-new" && git tag -a v-new -m v-new
) >/dev/null 2>&1 || { echo "FAIL : etiquettes non posees"; exit 1; }
# v-refuse: v-new plus a pre-commit hook that refuses. Its own tag, so cases
# (c) and (d) keep a version whose guardians work.
(
  cd "$SRC" || exit 1
  printf '#!/usr/bin/env bash\necho "REFUS : gardien de la fixture" >&2\nexit 1\n' > .githooks/pre-commit
  git add -A && git commit -q -m "fixture v-refuse" && git tag -a v-refuse -m v-refuse
) >/dev/null 2>&1 || { echo "FAIL : etiquette v-refuse non posee"; exit 1; }
check "source : trois etiquettes (v-old, v-new, v-refuse)" sh -c "
  git -C '$SRC' rev-parse -q --verify 'v-old^{commit}' >/dev/null &&
  git -C '$SRC' rev-parse -q --verify 'v-new^{commit}' >/dev/null &&
  git -C '$SRC' rev-parse -q --verify 'v-refuse^{commit}' >/dev/null"

# --- A simulated installation at v-old ------------------------------------------
make_installation() {
  local V="$1" ws
  ws="$(dirname "$V")"
  mkdir -p "$ws"
  git clone -q -- "$SRC" "$V" 2>/dev/null || return 1
  git -C "$V" -c advice.detachedHead=false checkout -q --detach v-old || return 1
  git -C "$V" config user.name "Participant"
  git -C "$V" config user.email participant@example.invalid
  git -C "$V" config core.longpaths true
  git -C "$V" config core.hooksPath .githooks
  bash "$V/tools/vault-identity.sh" ensure "$V" >/dev/null
  install_commit "$V" "Generate vault identity" || return 1
  printf -- '---\ntype: profile\ntitle: "Fiche utilisateur — Test"\ndescription: "Fiche de test."\nstatus: active\n---\n\n# FICHE UTILISATEUR\n\n- **Prenom :** Test\n\n## Liens\n\n- `see also` — [Agents](./AGENTS.md)\n' > "$V/USER.md"
  install_commit "$V" "Write user profile from installer answers" || return 1
  [ -z "$(git -C "$V" status --porcelain)" ]
}

NEWV="$TMP/new-version"
git clone -q -- "$SRC" "$NEWV" 2>/dev/null && git -C "$NEWV" -c advice.detachedHead=false checkout -q --detach v-new
UPDATE="$NEWV/tools/second-brain-update.sh"

# nothing_staged <vault> <head>: the three things a participant would see.
nothing_staged() {
  [ "$(git -C "$1" rev-parse HEAD)" = "$2" ] \
    && [ -z "$(git -C "$1" diff --cached --name-only)" ] \
    && [ -z "$(git -C "$1" status --porcelain)" ]
}

refusal_case() {
  # refusal_case <label> <tool> <target-tag> <prepare-fn>
  local label="$1" tool="$2" target="$3" prepare="$4" V head0 out rc staged
  V="$TMP/ws-$label/second-brain"
  make_installation "$V" || { fail "($label) installation non construite"; return 1; }
  "$prepare" "$V" || { fail "($label) preparation non faite"; return 1; }
  head0="$(git -C "$V" rev-parse HEAD)"
  out="$(bash "$tool" "$target" --vault "$V" --lang FR 2>&1)"
  rc=$?
  staged="$(git -C "$V" diff --cached --name-only | tr '\n' ' ')"
  printf '%s\n' "$out" | grep -E 'VERDICT|REFUS' | tail -n 2 | sed 's/^/    /'
  [ -n "$staged" ] && echo "    indexe apres le refus : $staged"
  REFUSAL_RC="$rc"
  REFUSAL_OUT="$out"
  REFUSAL_STAGED="$staged"
  REFUSAL_VAULT="$V"
  REFUSAL_HEAD="$head0"
  return 0
}
prepare_nothing() { :; }
prepare_conflict() {
  printf 'LOCAL EDIT OF THE FIRST LINE\n' > "$1/.l" && tail -n +2 "$1/RELEASE-NOTES.md" >> "$1/.l" && mv "$1/.l" "$1/RELEASE-NOTES.md"
  install_commit "$1" "local edit of a corpus file"
}
prepare_identity() {
  git -C "$1" show v-old:VAULT-IDENTITY.md > "$1/VAULT-IDENTITY.md"
  install_commit "$1" "identity back to the skeleton"
}

# --- (a) a guardian refuses the merge commit -----------------------------------
refusal_case a "$UPDATE" v-refuse prepare_nothing
check "(a) gardien refusant : VERDICT REFUSED, sortie 1" sh -c "
  [ '$REFUSAL_RC' = '1' ] && case \"\$1\" in *'VERDICT: REFUSED'*) exit 0;; *) exit 1;; esac" _ "$REFUSAL_OUT"
check "(a) rien d'indexe, arbre propre, HEAD inchange" nothing_staged "$REFUSAL_VAULT" "$REFUSAL_HEAD"

# --- (b) RED witness: the v0.1.9 tool in the same case --------------------------
OLD="$TMP/old-tool"
if git -C "$REPO_ROOT" cat-file -e 'v0.1.9^{commit}' 2>/dev/null \
  && mkdir -p "$OLD" && git -C "$REPO_ROOT" archive v0.1.9 tools i18n 2>/dev/null | tar -x -C "$OLD"; then
  refusal_case b "$OLD/tools/second-brain-update.sh" v-refuse prepare_nothing
  if nothing_staged "$REFUSAL_VAULT" "$REFUSAL_HEAD"; then
    pass "(b) temoin v0.1.9 : ne laisse rien d'indexe non plus (P5 non reproduit ici)"
  else
    pass "(b) temoin v0.1.9 : laisse « $REFUSAL_STAGED » indexe -- le rouge de l'audit 227"
  fi
else
  skip "(b) temoin : l'etiquette v0.1.9 n'est pas dans cet historique"
fi

# --- (c) another corpus file in conflict ----------------------------------------
refusal_case c "$UPDATE" v-new prepare_conflict
check "(c) conflit : VERDICT REFUSED, sortie 1" sh -c "
  [ '$REFUSAL_RC' = '1' ] && case \"\$1\" in *'VERDICT: REFUSED'*) exit 0;; *) exit 1;; esac" _ "$REFUSAL_OUT"
check "(c) rien d'indexe, arbre propre, HEAD inchange" nothing_staged "$REFUSAL_VAULT" "$REFUSAL_HEAD"

# --- (d) the identity would change -----------------------------------------------
refusal_case d "$UPDATE" v-new prepare_identity
check "(d) identite alteree : VERDICT REFUSED, sortie 1" sh -c "
  [ '$REFUSAL_RC' = '1' ] && case \"\$1\" in *'VERDICT: REFUSED'*) exit 0;; *) exit 1;; esac" _ "$REFUSAL_OUT"
check "(d) rien d'indexe, arbre propre, HEAD inchange" nothing_staged "$REFUSAL_VAULT" "$REFUSAL_HEAD"

# --- (e) the very case the audit measured: no Git identity at all ----------------
# Report 227 ran the update on a COPY of a Vault -- `git clone` does not carry
# the local user.name/user.email, and the audit's shell had none either. The
# commit then fails on "Please tell me who you are". This is where `M index.md`
# was seen staged after the refusal.
E="$TMP/ws-e/second-brain"
if make_installation "$E"; then
  git -C "$E" config --unset user.name
  git -C "$E" config --unset user.email
  : > "$TMP/empty-gitconfig"
  E_HEAD="$(git -C "$E" rev-parse HEAD)"
  OUT_E="$(GIT_CONFIG_GLOBAL="$TMP/empty-gitconfig" GIT_CONFIG_SYSTEM="$TMP/empty-gitconfig" \
    EMAIL= GIT_AUTHOR_NAME= GIT_AUTHOR_EMAIL= GIT_COMMITTER_NAME= GIT_COMMITTER_EMAIL= \
    bash "$UPDATE" v-new --vault "$E" --lang FR 2>&1)"
  RC_E=$?
  STAGED_E="$(git -C "$E" diff --cached --name-only | tr '\n' ' ')"
  printf '%s\n' "$OUT_E" | grep -E 'VERDICT' | tail -n 1 | sed 's/^/    /'
  [ -n "$STAGED_E" ] && echo "    indexe apres le refus : $STAGED_E"
  check "(e) sans identite Git : VERDICT REFUSED, sortie 1" sh -c "
    [ '$RC_E' = '1' ] && case \"\$1\" in *'VERDICT: REFUSED'*) exit 0;; *) exit 1;; esac" _ "$OUT_E"
  check "(e) rien d'indexe, arbre propre, HEAD inchange" nothing_staged "$E" "$E_HEAD"
else
  fail "(e) installation non construite"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS, $SKIPS SKIP) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS, $SKIPS SKIP) ==="
exit 1
