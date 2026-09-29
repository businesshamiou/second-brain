#!/usr/bin/env bash
# P2 of report 227 (Mission 230): the tag of a published version reaches BOTH
# remotes of the laboratory, not `release` alone.
#
# Measured by the audit: docs/how-to/publish.md pushed the tag to `release`
# (second-brain.git) only, while the company's Vault updates from `origin`
# (vault.git) -- tags v0.1.8 to v0.1.14 got there by hand. A version whose tag
# is on `release` alone is invisible to that Vault.
#
# Fixture: the same simulated laboratory as T1 (tests/test-publish-from-
# laboratory.sh) -- two LOCAL BARE repositories with unrelated histories,
# `origin` and `release`. Nothing real is pushed, ever.
#
#   (a) before the publication: REFUSED -- release/main is not the head of
#       publish; nothing created, nothing pushed;
#   (b) after `publish-from-laboratory.sh --version v9.9.9`: --dry-run says
#       WOULD-TAG and puts no tag anywhere;
#   (c) the real run: TAGGED; `ls-remote --tags` of BOTH bare repositories
#       reads the published commit for v9.9.9; the annotated tag exists
#       locally on that same commit;
#   (d) run again: REFUSED -- the tag is already on a remote, a published
#       version is never republished;
#   (e) an invalid version -> REFUSED, nothing pushed;
#   (f) origin pushing somewhere other than the declared URL -> REFUSED,
#       nothing pushed;
#   (g) a repository with no `release` remote (an installation) -> REFUSED.
#
# usage: bash tests/test-publish-tag-both-remotes.sh
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
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m230-tag-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

guarded_commit() {
  bash "$1/tools/build-indexes.sh" "$1" >/dev/null 2>&1
  git -C "$1" status --porcelain | cut -c4- | while IFS= read -r p; do git -C "$1" add -- "$p"; done
  bash "$1/tools/session-preflight.sh" >/dev/null 2>&1 || true
  git -C "$1" commit -q -m "$2" >"$TMP/commit.log" 2>&1 || { tail -n 15 "$TMP/commit.log" | sed 's/^/      /'; return 1; }
}

echo "=== P2 : l'etiquette de publication atteint les deux depots ==="
REF="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference"; exit 1; }

# --- release: its own root commit -----------------------------------------------
RS="$TMP/release-src"
git -c core.longpaths=true clone -q -- "$REF" "$RS" 2>/dev/null || { echo "FAIL : clone"; exit 1; }
(
  cd "$RS" || exit 1
  git config core.longpaths true
  git config user.name release && git config user.email release@example.invalid
  git checkout -q --orphan rel
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

# --- origin and the laboratory ---------------------------------------------------
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
git -C "$LAB" tag -l | while IFS= read -r t; do git -C "$LAB" tag -d "$t" >/dev/null; done
# A throwaway laboratory is a new Vault: the identity that came with the
# reference clone declares the real vault.git as its origin, and publish-tag.sh
# refuses an origin that is not the declared one. Its own identity is
# generated here, and declares this fixture's bare origin.
rm -f "$LAB/VAULT-IDENTITY.md"
bash "$LAB/tools/vault-identity.sh" ensure "$LAB" >/dev/null
# The identity writes the path in its native form (C:/Users/.../Temp/... under
# Git Bash), the shell in its POSIX one: compared through the same physical
# form the tool's own norm_url uses.
same_folder() {
  local a b
  a="$(cd "${1%.git}.git" 2>/dev/null && { pwd -W 2>/dev/null || pwd; })" || return 1
  b="$(cd "${2%.git}.git" 2>/dev/null && { pwd -W 2>/dev/null || pwd; })" || return 1
  [ "$(printf '%s' "$a" | tr '\\' '/')" = "$(printf '%s' "$b" | tr '\\' '/')" ]
}
check "laboratoire simule : vault_origin declare = l'origin nu de la fixture" \
  same_folder "$(bash "$LAB/tools/vault-identity.sh" get vault_origin "$LAB")" "$TMP/origin.git"
sed '1s/.*/LAB CHANGE LINE/' "$LAB/RELEASE-NOTES.md" > "$LAB/.rn" && mv "$LAB/.rn" "$LAB/RELEASE-NOTES.md"
guarded_commit "$LAB" "laboratory change" || { echo "FAIL : commit du laboratoire"; exit 1; }
TAGTOOL="$LAB/tools/publish-tag.sh"
V="v9.9.9"

tags_on() {
  # tags_on <bare> <version>: the commit the bare repository reads for the tag.
  local got
  got="$(git -C "$1" rev-parse --verify --quiet "refs/tags/$2^{commit}" 2>/dev/null)" || got=""
  printf '%s' "$got"
}
no_tag_anywhere() {
  [ -z "$(tags_on "$TMP/release.git" "$V")" ] && [ -z "$(tags_on "$TMP/origin.git" "$V")" ]
}

# --- (a) before the publication ---------------------------------------------------
OUT_A="$(bash "$TAGTOOL" "$V" --repo "$LAB" 2>&1)"; RC_A=$?
printf '%s\n' "$OUT_A" | tail -n 2 | sed 's/^/    /'
check "(a) avant publication : REFUSED, sortie 1" sh -c "
  [ '$RC_A' = '1' ] && case \"\$1\" in *'REFUSED'*) exit 0;; *) exit 1;; esac" _ "$OUT_A"
check "(a) aucune etiquette sur aucun des deux depots" no_tag_anywhere

# --- the publication itself --------------------------------------------------------
OUT_P="$(bash "$LAB/tools/publish-from-laboratory.sh" --version "$V" 2>&1)"; RC_P=$?
printf '%s\n' "$OUT_P" | tail -n 2 | sed 's/^/    /'
PUBLISHED="$(git -C "$TMP/release.git" rev-parse main)"
check "publication : PUBLISHED, release/main avance" sh -c "
  [ '$RC_P' = '0' ] && case \"\$1\" in *'PUBLISHED '*) exit 0;; *) exit 1;; esac" _ "$OUT_P"

# --- (b) dry run --------------------------------------------------------------------
OUT_B="$(bash "$TAGTOOL" "$V" --repo "$LAB" --dry-run 2>&1)"; RC_B=$?
printf '%s\n' "$OUT_B" | tail -n 2 | sed 's/^/    /'
check "(b) --dry-run : WOULD-TAG sur le commit publie, sortie 0" sh -c "
  [ '$RC_B' = '0' ] && [ \"\$(printf '%s\n' \"\$1\" | tail -n 1)\" = 'WOULD-TAG $V $PUBLISHED' ]" _ "$OUT_B"
check "(b) --dry-run : aucune etiquette posee nulle part" sh -c "
  [ -z \"\$(git -C '$TMP/release.git' rev-parse -q --verify 'refs/tags/$V' 2>/dev/null)\" ] &&
  [ -z \"\$(git -C '$TMP/origin.git' rev-parse -q --verify 'refs/tags/$V' 2>/dev/null)\" ] &&
  [ -z \"\$(git -C '$LAB' rev-parse -q --verify 'refs/tags/$V' 2>/dev/null)\" ]"

# --- (c) the real run ----------------------------------------------------------------
OUT_C="$(bash "$TAGTOOL" "$V" --repo "$LAB" 2>&1)"; RC_C=$?
printf '%s\n' "$OUT_C" | sed 's/^/    /'
check "(c) TAGGED <version> <commit publie>, sortie 0" sh -c "
  [ '$RC_C' = '0' ] && [ \"\$(printf '%s\n' \"\$1\" | tail -n 1)\" = 'TAGGED $V $PUBLISHED' ]" _ "$OUT_C"
check "(c) release.git lit $V sur le commit publie" [ "$(tags_on "$TMP/release.git" "$V")" = "$PUBLISHED" ]
check "(c) origin.git lit $V sur le MEME commit (le blocage P2 leve)" [ "$(tags_on "$TMP/origin.git" "$V")" = "$PUBLISHED" ]
check "(c) l'etiquette locale est annotee, sur ce commit" sh -c "
  [ \"\$(git -C '$LAB' cat-file -t 'refs/tags/$V')\" = 'tag' ] &&
  [ \"\$(git -C '$LAB' rev-parse 'refs/tags/$V^{commit}')\" = '$PUBLISHED' ]"
check "(c) la ligne d'installation du commit publie nomme $V" sh -c "
  git -C '$TMP/release.git' show 'main:bootstrap.sh' | grep -q 'REF=\"$V\"'"

# --- (d) run again -------------------------------------------------------------------
OUT_D="$(bash "$TAGTOOL" "$V" --repo "$LAB" 2>&1)"; RC_D=$?
check "(d) deuxieme passage : REFUSED (deja sur un distant), sortie 1" sh -c "
  [ '$RC_D' = '1' ] && case \"\$1\" in *'already exists on'*) exit 0;; *) exit 1;; esac" _ "$OUT_D"

# --- (e) an invalid version ------------------------------------------------------------
OUT_E="$(bash "$TAGTOOL" 9.9.9 --repo "$LAB" 2>&1)"; RC_E=$?
check "(e) version invalide : REFUSED, sortie 1" sh -c "
  [ '$RC_E' = '1' ] && case \"\$1\" in *'invalid version'*) exit 0;; *) exit 1;; esac" _ "$OUT_E"

# --- (f) origin elsewhere than the declared URL ------------------------------------------
git init -q --bare "$TMP/elsewhere.git"
git -C "$LAB" remote set-url --push origin "$TMP/elsewhere.git"
OUT_F="$(bash "$TAGTOOL" v9.9.8 --repo "$LAB" 2>&1)"; RC_F=$?
git -C "$LAB" remote set-url --push origin "$TMP/origin.git"
check "(f) origin ailleurs que l'URL declaree : REFUSED, sortie 1" sh -c "
  [ '$RC_F' = '1' ] && case \"\$1\" in *'not to the declared'*) exit 0;; *) exit 1;; esac" _ "$OUT_F"
check "(f) rien n'a ete pousse ailleurs" sh -c "
  [ -z \"\$(git -C '$TMP/elsewhere.git' tag -l)\" ]"

# --- (g) a repository with no release remote ----------------------------------------------
INST="$TMP/installation"
git -c core.longpaths=true clone -q -- "$TMP/origin.git" "$INST" 2>/dev/null
OUT_G="$(bash "$TAGTOOL" v9.9.7 --repo "$INST" 2>&1)"; RC_G=$?
check "(g) sans distant release (une installation) : REFUSED, sortie 1" sh -c "
  [ '$RC_G' = '1' ] && case \"\$1\" in *'no release remote'*) exit 0;; *) exit 1;; esac" _ "$OUT_G"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
