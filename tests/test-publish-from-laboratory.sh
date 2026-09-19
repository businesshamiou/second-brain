#!/usr/bin/env bash
# T1 (Mission 192, Decision 210904 A): tools/publish-from-laboratory.sh on a
# SIMULATED laboratory -- two local bare repositories with unrelated
# histories: `origin` (the laboratory's history) and `release` (the
# publication's history, its own root commit).
#
#   (a) first publication: PUBLISHED; release/main = one commit whose parent
#       is release's previous head (fast-forward); outside the closed list
#       (VAULT-IDENTITY.md, projects/) and the rebuilt index.md files, the
#       published tree = the laboratory's main (diff 0); VAULT-IDENTITY.md
#       and projects/ = release's (the laboratory's identity and its project
#       sheet, carrying a private path, never leave it); the guardians ran
#       on the publication commit (it exists);
#   (b) second run: NOTHING-TO-PUBLISH, release unchanged;
#   negative controls, release unchanged each time:
#   (c) an argument naming a path -> REFUSED (the closed list does not grow);
#   (d) the tool run from the `publish` worktree -> REFUSED;
#   (e) release/main advanced by a third party -> REFUSED "not a
#       fast-forward", nothing pushed, never --force.
# The laboratory is built from this repository at HEAD (reference clone,
# Mission 188): commit before a local run.
#
# usage: bash tests/test-publish-from-laboratory.sh
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

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m192-publish-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
PRIVATE="C:\\Users\\ha""mio\\Workspaces\\atelier"

guarded_commit() {
  # guarded_commit <repo> <message>: indexes, preflight, every change staged,
  # a commit through the repository's guardians.
  bash "$1/tools/build-indexes.sh" "$1" >/dev/null 2>&1
  git -C "$1" status --porcelain | cut -c4- | while IFS= read -r p; do git -C "$1" add -- "$p"; done
  bash "$1/tools/session-preflight.sh" >/dev/null 2>&1 || true
  git -C "$1" commit -q -m "$2" >"$TMP/commit.log" 2>&1 || { tail -n 15 "$TMP/commit.log" | sed 's/^/      /'; return 1; }
}

echo "=== T1 : publication depuis un laboratoire simule ==="
REF="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference"; exit 1; }

# --- release: its own root commit, the published state ------------------------
RS="$TMP/release-src"
git -c core.longpaths=true clone -q -- "$REF" "$RS" 2>/dev/null || { echo "FAIL : clone"; exit 1; }
(
  cd "$RS" || exit 1
  git config core.longpaths true
  git config user.name release && git config user.email release@example.invalid
  git checkout -q --orphan rel
  git show HEAD:VAULT-IDENTITY.md >/dev/null 2>&1
  cat > VAULT-IDENTITY.md <<'EOF'
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
  for f in projects/PROJECT-20*.md; do [ -e "$f" ] && git rm -q -f -- "$f"; done
  grep -v '^| 20[0-9][0-9]-' projects/PROJECT-REGISTRY.md > .r && mv .r projects/PROJECT-REGISTRY.md
  bash tools/build-indexes.sh "$PWD" >/dev/null 2>&1
  git add -A && git commit -q -m "release root"
) >/dev/null 2>&1 || { echo "FAIL : racine de release non construite"; exit 1; }
git init -q --bare "$TMP/release.git"
git -C "$RS" push -q "$TMP/release.git" rel:main 2>/dev/null || { echo "FAIL : release non poussee"; exit 1; }
R0="$(git -C "$TMP/release.git" rev-parse main)"

# --- origin and the laboratory --------------------------------------------------
git clone -q --bare -- "$REF" "$TMP/origin.git" 2>/dev/null
WS="$TMP/ws"
LAB="$WS/vault"
mkdir -p "$WS"
git -c core.longpaths=true clone -q -- "$TMP/origin.git" "$LAB" 2>/dev/null
git -C "$LAB" checkout -q -B main 2>/dev/null
git -C "$LAB" config core.longpaths true
git -C "$LAB" config core.hooksPath .githooks
git -C "$LAB" config user.name lab && git -C "$LAB" config user.email lab@example.invalid
git -C "$LAB" remote add release "$TMP/release.git"
check "historiques sans rapport (aucune base commune)" sh -c "git -C '$LAB' fetch -q release && ! git -C '$LAB' merge-base HEAD release/main >/dev/null 2>&1"
bash "$LAB/tools/vault-identity.sh" ensure "$LAB" >/dev/null
printf -- '---\ntype: project\ntitle: "Atelier"\ndescription: "Fiche du laboratoire."\nstatus: active\nabsolute_path: "%s"\n---\n\n# ATELIER\n\n## Liens\n\n- `see also` — [Registre](./PROJECT-REGISTRY.md)\n' "$PRIVATE" > "$LAB/projects/PROJECT-2099-01-01-ATELIER.md"
sed '1s/.*/LAB CHANGE LINE/' "$LAB/RELEASE-NOTES.md" > "$LAB/.rn" && mv "$LAB/.rn" "$LAB/RELEASE-NOTES.md"
guarded_commit "$LAB" "laboratory change" || { echo "FAIL : commit du laboratoire"; exit 1; }
TOOL="$LAB/tools/publish-from-laboratory.sh"

# --- (c) witness: an argument cannot widen the list ---------------------------
OUT_C="$(bash "$TOOL" USER.md 2>&1)"; RC_C=$?
check "(c) temoin : un chemin en argument -> REFUSED, release inchangee" sh -c "[ '$RC_C' = '1' ] && case \"\$1\" in *'liste close'*REFUSED*) exit 0;; *) exit 1;; esac && [ \"\$(git -C '$TMP/release.git' rev-parse main)\" = '$R0' ]" _ "$OUT_C"

# --- (a) first publication -------------------------------------------------------
OUT_A="$(bash "$TOOL" 2>&1)"; RC_A=$?
printf '%s\n' "$OUT_A" | grep '^PUBLISH' | sed 's/^/    /'
R1="$(git -C "$TMP/release.git" rev-parse main)"
check "(a) PUBLISHED, sortie 0" sh -c "[ '$RC_A' = '0' ] && [ \"\$(printf '%s\n' \"\$1\" | tail -n 1)\" = 'PUBLISHED $R1' ]" _ "$OUT_A"
check "(a) avance rapide : un commit, parent = release precedente" [ "$(git -C "$TMP/release.git" rev-parse "$R1^")" = "$R0" ]
git -C "$LAB" fetch -q release
check "(a) hors liste close et index : arbre publie = main du laboratoire (diff 0)" git -C "$LAB" diff --quiet main release/main -- . ':(exclude)VAULT-IDENTITY.md' ':(exclude)projects' ':(exclude,glob)**/index.md' ':(exclude)index.md'
check "(a) VAULT-IDENTITY.md et projects/ = ceux de release" git -C "$LAB" diff --quiet "$R0" release/main -- VAULT-IDENTITY.md projects
check "(a) la fiche du laboratoire (chemin prive) n'est pas publiee" sh -c "! git -C '$LAB' cat-file -e release/main:projects/PROJECT-2099-01-01-ATELIER.md 2>/dev/null"
check "(a) le changement du laboratoire est publie" sh -c "[ \"\$(git -C '$LAB' show release/main:RELEASE-NOTES.md | head -n 1)\" = 'LAB CHANGE LINE' ]"

# --- (b) second run --------------------------------------------------------------
OUT_B="$(bash "$TOOL" 2>&1)"; RC_B=$?
check "(b) second passage : NOTHING-TO-PUBLISH, release inchangee" sh -c "[ '$RC_B' = '0' ] && [ \"\$(printf '%s\n' \"\$1\" | tail -n 1)\" = 'NOTHING-TO-PUBLISH' ] && [ \"\$(git -C '$TMP/release.git' rev-parse main)\" = '$R1' ]" _ "$OUT_B"

# --- (d) witness: never from publish itself --------------------------------------
OUT_D="$(bash "$WS/m-publish/second-brain/tools/publish-from-laboratory.sh" 2>&1)"; RC_D=$?
check "(d) temoin : lance depuis le worktree publish -> REFUSED" sh -c "[ '$RC_D' = '1' ] && [ \"\$(git -C '$TMP/release.git' rev-parse main)\" = '$R1' ]"

# --- (e) witness: release advanced by a third party --------------------------------
git clone -q --branch main -- "$TMP/release.git" "$TMP/third" 2>/dev/null
git -C "$TMP/third" config user.name third && git -C "$TMP/third" config user.email t@example.invalid && git -C "$TMP/third" config core.autocrlf false
printf 'third party\n' > "$TMP/third/THIRD.txt"
git -C "$TMP/third" add THIRD.txt && git -C "$TMP/third" commit -q -m "third party" && git -C "$TMP/third" push -q origin HEAD:main 2>/dev/null
R2="$(git -C "$TMP/release.git" rev-parse main)"
sed '1s/.*/LAB SECOND CHANGE/' "$LAB/RELEASE-NOTES.md" > "$LAB/.rn" && mv "$LAB/.rn" "$LAB/RELEASE-NOTES.md"
guarded_commit "$LAB" "second laboratory change" || fail "(e) commit du laboratoire"
OUT_E="$(bash "$TOOL" 2>&1)"; RC_E=$?
check "(e) temoin : release avancee par un tiers -> REFUSED « pas une avance rapide »" sh -c "[ '$RC_E' = '1' ] && case \"\$1\" in *'pas une avance rapide'*REFUSED*) exit 0;; *) exit 1;; esac" _ "$OUT_E"
check "(e) temoin : rien pousse (release reste au commit du tiers)" [ "$(git -C "$TMP/release.git" rev-parse main)" = "$R2" ]

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
