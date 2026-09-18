#!/usr/bin/env bash
# T5 (Mission 191-C01, Decision 152251 B3): `second-brain update <version>`
# on a SIMULATED installation carrying the participant's own commits.
#
# Fixture: a local source with two tags built from this repository's HEAD --
# v0.1.7 (no update tool, a sentinel file, older release notes) and v0.1.8
# (this tree). An installation is simulated the way the installer leaves
# one: clone detached at v0.1.7, guardians active (core.hooksPath), then
# local commits: identity, USER.md, a first project (registry, sheet),
# regenerated indexes. The update runs the v0.1.8 tool from a clone of the
# version (the bootstrap's temporary clone), with --vault.
#
#   (a) update v0.1.8: VERDICT UPDATED; HEAD = merge commit whose second
#       parent is v0.1.8; USER.md, VAULT-IDENTITY.md, projects/ identical
#       to before (diff 0); corpus (tools, rules, templates, skills) = v0.1.8;
#       sentinel gone, update tool present; indexes fresh (rebuilding
#       changes nothing); porcelain empty; vault_id identical; the project's
#       repository and its certificate's vault_ref untouched;
#   (b) second pass: VERDICT UP-TO-DATE, HEAD unchanged;
#   negative controls, each with HEAD and porcelain unchanged:
#   (c) conflict: a local commit on a corpus file the version also changes ->
#       REFUSED naming the file, merge aborted;
#   (d) identity altered (back to the skeleton) -> REFUSED;
#   (e) origin = the bootstrap's temporary clone (before Mission 185) ->
#       REFUSED with the reinstall explanation;
#   (f) the published line (bootstrap.sh) on the existing workspace -> it
#       names the update command instead of installing, nothing touched.
#
# usage: bash tests/test-update-installed-vault.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}
has() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m191-update-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

install_commit() {
  # install_commit <repo> <message>: what the installer does
  # (save_clone_pending_changes): indexes rebuilt, every change staged, then
  # a guarded commit.
  bash "$1/tools/build-indexes.sh" "$1" >/dev/null 2>&1
  git -C "$1" status --porcelain | cut -c4- | while IFS= read -r p; do git -C "$1" add -- "$p"; done
  quiet_commit "$1" "$2"
}
quiet_commit() {
  # quiet_commit <repo> <message>: preflight stamp, then a guarded commit.
  bash "$1/tools/session-preflight.sh" >/dev/null 2>&1 || true
  git -C "$1" commit -q -m "$2" >"$TMP/commit.log" 2>&1 || { sed "s/^/      /" "$TMP/commit.log" | tail -n 15; return 1; }
}

echo "=== T5 : second-brain update sur une installation simulee ==="

# --- Source with two tags -----------------------------------------------------
# A clone, never a copy: a published repository keeps its execution bits and
# its whole tree (manifest), which the installation's guardians check. The
# reference clone is this repository at HEAD (Mission 188): commit before a
# local run.
SRC="$TMP/source"
REF_CLONE="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference non construit"; exit 1; }
git -c core.longpaths=true clone -q -- "$REF_CLONE" "$SRC" 2>/dev/null || { echo "FAIL : source non construite"; exit 1; }
git -C "$SRC" config core.longpaths true
git -C "$SRC" config user.name fixture
git -C "$SRC" config user.email fixture@example.invalid
# The clone brings this repository's own tags, the real v0.1.7 among them:
# in this throwaway source, only the fixture's two tags exist.
git -C "$SRC" tag -l | while IFS= read -r t; do git -C "$SRC" tag -d "$t" >/dev/null; done
S0="$(git -C "$SRC" rev-parse HEAD)"
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
  git rm -q -r -- tools/second-brain-update.sh tools/second-brain-update.ps1 skills/update
  printf 'Sentinel of the old version.\n' > SENTINEL-v017.txt
  # The version's manifest matches its tree (the manifest guardian checks it).
  grep -v -e '^skills/update/' -e '^tools/second-brain-update\.' distribution-manifest.txt > .m && mv .m distribution-manifest.txt
  printf 'SENTINEL-v017.txt\tDISTRIBUABLE\n' >> distribution-manifest.txt
  printf 'OLD RELEASE LINE\n' > .release-head.txt
  cat .release-head.txt RELEASE-NOTES.md > .rn && mv .rn RELEASE-NOTES.md && rm -f .release-head.txt
  bash tools/build-indexes.sh "$PWD" >/dev/null 2>&1
  git add -A && git commit -q -m "fixture v0.1.7" && git tag -a v0.1.7 -m v0.1.7
  git checkout -q "$S0" -- tools/second-brain-update.sh tools/second-brain-update.ps1 skills/update distribution-manifest.txt
  git rm -q SENTINEL-v017.txt
  sed '1s/.*/NEW RELEASE LINE/' RELEASE-NOTES.md > .rn && mv .rn RELEASE-NOTES.md
  bash tools/build-indexes.sh "$PWD" >/dev/null 2>&1
  git add -A && git commit -q -m "fixture v0.1.8" && git tag -a v0.1.8 -m v0.1.8
) >/dev/null 2>&1 || { echo "FAIL : etiquettes de la source non posees"; exit 1; }
V8="$(git -C "$SRC" rev-parse 'v0.1.8^{commit}')"
check "source : deux etiquettes (v0.1.7, v0.1.8)" sh -c "git -C '$SRC' rev-parse -q --verify 'v0.1.7^{commit}' >/dev/null && [ -n '$V8' ]"

# --- Simulated installation at v0.1.7 ------------------------------------------
WS="$TMP/ws"
V="$WS/second-brain"
mkdir -p "$WS"
git clone -q -- "$SRC" "$V" 2>/dev/null && git -C "$V" -c advice.detachedHead=false checkout -q --detach v0.1.7
git -C "$V" config user.name "Participant"
git -C "$V" config user.email participant@example.invalid
git -C "$V" config core.longpaths true
git -C "$V" config core.hooksPath .githooks
bash "$V/tools/vault-identity.sh" ensure "$V" >/dev/null
install_commit "$V" "Generate vault identity"
check "installation : identite commitee (gardiens actifs)" sh -c "[ -z \"\$(git -C '$V' status --porcelain)\" ]"
printf -- '---\ntype: profile\ntitle: "Fiche utilisateur — Test"\ndescription: "Fiche de test."\nstatus: active\n---\n\n# FICHE UTILISATEUR\n\n- **Prenom :** Test\n\n## Liens\n\n- `see also` — [Agents](./AGENTS.md)\n' > "$V/USER.md"
install_commit "$V" "Write user profile from installer answers"
bash "$V/tools/write-marker.sh" "$WS" >/dev/null
bash "$V/tools/project-bootstrap.sh" create "$WS/projet" "Projet" --vcs git >/dev/null 2>&1 </dev/null
install_commit "$V" "Register first project: projet"
check "installation : fiche projet, registre et index commites" sh -c "[ -z \"\$(git -C '$V' status --porcelain)\" ] && ls '$V'/projects/PROJECT-*-PROJET.md >/dev/null 2>&1"
check "installation : HEAD detache, v0.1.7 + commits locaux" sh -c "[ -z \"\$(git -C '$V' branch --show-current)\" ] && [ \"\$(git -C '$V' rev-list --count v0.1.7..HEAD)\" -ge 3 ]"

snapshot() {
  # snapshot <vault>: fingerprint of what the participant owns.
  (cd "$1" && cat USER.md VAULT-IDENTITY.md projects/*.md 2>/dev/null | git hash-object --stdin)
}
LOCAL_BEFORE="$(snapshot "$V")"
ID_BEFORE="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"
PROJ_HEAD="$(git -C "$WS/projet" rev-parse HEAD)"
PROJ_CFG="$(git hash-object "$WS/projet/.pre-commit-config.yaml")"
REF_BEFORE="$(sed -n 's/^# vault_ref: //p' "$WS/projet/.pre-commit-config.yaml")"

# The version's tool, from a clone of the version (the bootstrap's temp clone).
NEWV="$TMP/new-version"
git clone -q -- "$SRC" "$NEWV" 2>/dev/null && git -C "$NEWV" -c advice.detachedHead=false checkout -q --detach v0.1.8
UPDATE="$NEWV/tools/second-brain-update.sh"

# --- Negative controls first (the installation is still at v0.1.7) ------------
witness_clone() {
  # witness_clone <dir>: a copy of the installation, same history and tags.
  # The installation is on a detached HEAD: its local commits are reachable
  # from no branch, so they are fetched by name.
  git clone -q -- "$V" "$1" 2>/dev/null
  git -C "$1" fetch -q "$V" HEAD 2>/dev/null
  git -C "$1" -c advice.detachedHead=false checkout -q --detach FETCH_HEAD
  git -C "$1" config user.name w && git -C "$1" config user.email w@example.invalid
}
same_state() {
  # same_state <repo> <head>: HEAD unchanged and porcelain empty.
  [ "$(git -C "$1" rev-parse HEAD)" = "$2" ] && [ -z "$(git -C "$1" status --porcelain)" ]
}

C="$TMP/w-conflict"
witness_clone "$C"
printf 'LOCAL EDIT OF THE FIRST LINE\n' > "$C/.l" && tail -n +2 "$C/RELEASE-NOTES.md" >> "$C/.l" && mv "$C/.l" "$C/RELEASE-NOTES.md"
git -C "$C" commit -q -am "local edit of a corpus file"
C_HEAD="$(git -C "$C" rev-parse HEAD)"
OUT_C="$(bash "$UPDATE" v0.1.8 --vault "$C" --lang FR 2>&1)"
RC_C=$?
check "(c) temoin conflit : REFUSED, sortie 1" sh -c "[ '$RC_C' = '1' ] && case \"\$1\" in *'VERDICT: REFUSED'*) exit 0;; *) exit 1;; esac" _ "$OUT_C"
check "(c) temoin conflit : le fichier est nomme (RELEASE-NOTES.md)" has "$OUT_C" "RELEASE-NOTES.md"
check "(c) temoin conflit : fusion abandonnee, HEAD et arbre inchanges" same_state "$C" "$C_HEAD"

D="$TMP/w-identity"
witness_clone "$D"
git -C "$D" show v0.1.7:VAULT-IDENTITY.md > "$D/VAULT-IDENTITY.md"
git -C "$D" commit -q -am "identity back to the skeleton"
D_HEAD="$(git -C "$D" rev-parse HEAD)"
OUT_D="$(bash "$UPDATE" v0.1.8 --vault "$D" --lang FR 2>&1)"
check "(d) temoin identite alteree : REFUSED" sh -c "[ '$?' = '1' ] && case \"\$1\" in *'VERDICT: REFUSED'*\"identité\"*|*\"identité\"*'VERDICT: REFUSED'*) exit 0;; *) exit 1;; esac" _ "$OUT_D"
check "(d) temoin identite alteree : HEAD et arbre inchanges" same_state "$D" "$D_HEAD"

E="$TMP/w-origin"
witness_clone "$E"
git clone -q -- "$SRC" "$TMP/tmpdir/second-brain-install" 2>/dev/null
git -C "$E" remote set-url origin "$TMP/tmpdir/second-brain-install"
E_HEAD="$(git -C "$E" rev-parse HEAD)"
OUT_E="$(bash "$UPDATE" v0.1.8 --vault "$E" --lang FR 2>&1)"
check "(e) temoin origine temporaire : REFUSED expliquant la reinstallation" sh -c "[ '$?' = '1' ] && case \"\$1\" in *'avant la v0.1.4'*'Réinstalle'*) exit 0;; *) exit 1;; esac" _ "$OUT_E"
check "(e) temoin origine temporaire : HEAD et arbre inchanges" same_state "$E" "$E_HEAD"

V_HEAD0="$(git -C "$V" rev-parse HEAD)"
R="$TMP/boot"
mkdir -p "$R"
sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$WS\"#" "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$R/answers.json"
OUT_F="$(bash "$NEWV/bootstrap.sh" --ref v0.1.8 --repo-url "$SRC" --raw-base "$SRC" \
  --test-mode --test-root "$R" --answers-file "$R/answers.json" --stop-after-step clone 2>&1)"
RC_F=$?
check "(f) ligne publiee sur un espace existant : renvoi vers update (commande nommee)" sh -c "[ '$RC_F' != '0' ] && case \"\$1\" in *'second-brain-update.sh v0.1.8 --vault'*) exit 0;; *) exit 1;; esac" _ "$OUT_F"
check "(f) ... rien n'est touche (HEAD, arbre)" same_state "$V" "$V_HEAD0"

# --- (a) the update ------------------------------------------------------------
OUT_A="$(bash "$UPDATE" v0.1.8 --vault "$V" --lang FR 2>&1)"
RC_A=$?
printf '%s\n' "$OUT_A" | tail -n 4 | sed 's/^/    /'
check "(a) VERDICT: UPDATED, sortie 0" sh -c "[ '$RC_A' = '0' ] && case \"\$1\" in *'VERDICT: UPDATED'*) exit 0;; *) exit 1;; esac" _ "$OUT_A"
check "(a) HEAD = fusion, second parent = v0.1.8" sh -c "[ \"\$(git -C '$V' rev-parse HEAD^2 2>/dev/null)\" = '$V8' ] && [ \"\$(git -C '$V' rev-parse HEAD^1)\" = '$V_HEAD0' ]"
check "(a) USER.md, identite, projects/ : diff 0" [ "$(snapshot "$V")" = "$LOCAL_BEFORE" ]
check "(a) corpus = v0.1.8 (tools, rules, templates, skills, tests)" git -C "$V" diff --quiet v0.1.8 HEAD -- tools rules templates skills tests
check "(a) sentinelle de v0.1.7 retiree, outil de mise a jour present" sh -c "[ ! -e '$V/SENTINEL-v017.txt' ] && [ -f '$V/tools/second-brain-update.sh' ]"
check "(a) premiere ligne des notes = celle de v0.1.8" sh -c "[ \"\$(head -n 1 '$V/RELEASE-NOTES.md')\" = 'NEW RELEASE LINE' ]"
check "(a) porcelain vide" sh -c "[ -z \"\$(git -C '$V' status --porcelain)\" ]"
bash "$V/tools/build-indexes.sh" "$V" >/dev/null 2>&1
check "(a) index frais (les reconstruire ne change rien)" sh -c "[ -z \"\$(git -C '$V' status --porcelain)\" ]"
check "(a) vault_id identique ($ID_BEFORE)" [ "$(bash "$V/tools/vault-identity.sh" get vault_id "$V")" = "$ID_BEFORE" ]
check "(a) projet intact : HEAD et acte inchanges, vault_ref = naissance ($REF_BEFORE)" sh -c "[ \"\$(git -C '$WS/projet' rev-parse HEAD)\" = '$PROJ_HEAD' ] && [ \"\$(git hash-object '$WS/projet/.pre-commit-config.yaml')\" = '$PROJ_CFG' ] && [ -n '$REF_BEFORE' ]"

# --- (b) second pass -------------------------------------------------------------
V_HEAD1="$(git -C "$V" rev-parse HEAD)"
OUT_B="$(bash "$V/tools/second-brain-update.sh" v0.1.8 --lang FR 2>&1)"
check "(b) second passage : UP-TO-DATE, « déjà à jour »" sh -c "case \"\$1\" in *'Déjà à jour'*'VERDICT: UP-TO-DATE'*) exit 0;; *) exit 1;; esac" _ "$OUT_B"
check "(b) second passage : HEAD et arbre inchanges" same_state "$V" "$V_HEAD1"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
