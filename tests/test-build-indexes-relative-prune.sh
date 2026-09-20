#!/usr/bin/env bash
# Mission 203, fix 2 (report 202, A7): tools/build_indexes.py prunes on the
# folder names BELOW the root it is given, never on the absolute path of that
# root. Before, a project living under a folder named `tools`, `state` or
# `skills-warehouse` was pruned whole: zero indexes, and the freshness guardian's
# own hint (`bash tools/build-indexes.sh <root>`) a dead end.
#
# Oracles (PASS expected):
#   (a) a root whose ABSOLUTE path holds pruned names (state/, tools/, skills-warehouse/)
#       gets its indexes (root and a sub-folder);
#   (b) names in the pruned list are still pruned at any depth BELOW the root;
#   (c) the certificate's `# exempt:` prefixes are pruned too: no index is
#       written under them, and the third-party files there stay byte-identical;
#   (d) a second run changes nothing (idempotent);
#   (e) a copy of this repository's Markdown: the new tool writes byte for byte
#       what the old one wrote (same folder name, so the same titles) -- the
#       change is invisible on the Vault itself;
#   (f) the old tool (commit f34b405) writes ZERO index under case (a): the
#       defect reproduced, when that history is available.
#
# Writes only in a temporary folder (prefix m203-prune).
#
# usage: bash tests/test-build-indexes-relative-prune.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- build_indexes.py en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m203-prune-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

note() { printf -- '---\ntype: note\nstatus: active\n---\n# %s\n' "$1"; }

# The project: root a.md, docs/b.md, state/s.md and tools/t.md (pruned names below
# the root), skill-collections/web/skills/x/SKILL.md (third party, exempt by key).
make_tree() {
  local root="$1" exempt="$2"
  mkdir -p "$root/docs" "$root/state" "$root/tools" "$root/skill-collections/web/skills/x"
  note a > "$root/a.md"; note b > "$root/docs/b.md"; note s > "$root/state/s.md"
  note t > "$root/tools/t.md"; note x > "$root/skill-collections/web/skills/x/SKILL.md"
  if [ -n "$exempt" ]; then
    { echo "# second-brain-birth-certificate: v1"; echo "# vault_id: sb-test-203"; echo "# exempt: $exempt"; echo "repos: []"; } > "$root/.pre-commit-config.yaml"
  fi
}

count_indexes() { find "$1" -name index.md | wc -l | tr -d ' '; }

# --- (a) a root whose absolute path holds pruned names -----------------------------
ROOT="$TMP/state/tools/skills-warehouse"
make_tree "$ROOT" ""
bash "$REPO_ROOT/tools/build-indexes.sh" "$ROOT" >/dev/null 2>&1
if [ -f "$ROOT/index.md" ] && [ -f "$ROOT/docs/index.md" ]; then
  pass "(a) racine sous state/tools/skills-warehouse : index a la racine et dans docs/"
else
  fail "(a) racine sous state/tools/skills-warehouse : $(count_indexes "$ROOT") index (attendu la racine et docs/)"
fi

# --- (b) pruned names still pruned below the root ------------------------------------
if [ ! -e "$ROOT/state/index.md" ] && [ ! -e "$ROOT/tools/index.md" ]; then
  pass "(b) state/ et tools/ sous la racine restent elagues"
else
  fail "(b) un index a ete ecrit sous state/ ou tools/ de la racine"
fi

# --- (c) exempt prefixes pruned, third-party file byte-identical -----------------------
ROOT="$TMP/plain/project"
make_tree "$ROOT" "skill-collections/"
BEFORE="$(cksum < "$ROOT/skill-collections/web/skills/x/SKILL.md")"
bash "$REPO_ROOT/tools/build-indexes.sh" "$ROOT" >/dev/null 2>&1
AFTER="$(cksum < "$ROOT/skill-collections/web/skills/x/SKILL.md")"
if [ -f "$ROOT/index.md" ] && [ -z "$(find "$ROOT/skill-collections" -name index.md)" ] && [ "$BEFORE" = "$AFTER" ]; then
  pass "(c) la cle '# exempt: skill-collections/' : aucun index dessous, fichier tiers inchange"
else
  fail "(c) cle d'exemption : index racine=$([ -f "$ROOT/index.md" ] && echo oui || echo non), sous skill-collections=$(find "$ROOT/skill-collections" -name index.md | wc -l | tr -d ' ')"
fi
SNAP1="$(cd "$ROOT" && find . -name index.md -print0 | sort -z | xargs -0 cat | cksum)"

# --- (d) idempotent ---------------------------------------------------------------------
bash "$REPO_ROOT/tools/build-indexes.sh" "$ROOT" >/dev/null 2>&1
SNAP2="$(cd "$ROOT" && find . -name index.md -print0 | sort -z | xargs -0 cat | cksum)"
[ "$SNAP1" = "$SNAP2" ] && pass "(d) un second passage ne change rien" || fail "(d) le second passage a change les index"

# --- (e) invisible on this repository's own Markdown --------------------------------------
# Both tools are run from a Vault-shaped folder of the same depth and the same name
# length (vold / vnew): the generated `prescribed by` link is relative to the tool's own
# location, and its length decides when an index is split at the weight cap -- it must
# not differ between the two runs. That one line is then left out of the comparison.
if sandbox_before_203 "$TMP/vold"; then
  mkdir -p "$TMP/vnew" && cp -r "$REPO_ROOT/tools" "$TMP/vnew/tools"
  for side in old new; do
    mkdir -p "$TMP/$side/tree"
    (cd "$REPO_ROOT" && git ls-files -z -- '*.md' 'superseded-files.txt' | xargs -0 -I{} cp --parents {} "$TMP/$side/tree/" 2>/dev/null)
  done
  bash "$TMP/vold/tools/build-indexes.sh" "$TMP/old/tree" >/dev/null 2>&1
  bash "$TMP/vnew/tools/build-indexes.sh" "$TMP/new/tree" >/dev/null 2>&1
  N="$(count_indexes "$TMP/new/tree")"
  if diff -r -I 'prescribed by' "$TMP/old/tree" "$TMP/new/tree" >/dev/null 2>&1 && [ "$N" -gt 5 ]; then
    pass "(e) copie du depot : $N index, sortie de l'ancien outil et du nouveau identiques (diff vide)"
  else
    fail "(e) copie du depot : $N index, diff non vide avec l'ancien outil ($(diff -r -I 'prescribed by' "$TMP/old/tree" "$TMP/new/tree" 2>&1 | wc -l | tr -d ' ') lignes)"
  fi
else
  echo "  SKIP - (e) et (f) : l'historique f34b405 est absent de ce clone"
fi

# --- (f) the old tool: the defect reproduced -----------------------------------------------
if [ -d "$TMP/vold/tools" ]; then
  ROOT="$TMP/state/tools/old-check/skills-warehouse"
  make_tree "$ROOT" ""
  bash "$TMP/vold/tools/build-indexes.sh" "$ROOT" >/dev/null 2>&1
  N="$(count_indexes "$ROOT")"
  [ "$N" = "0" ] && pass "(f) temoin rouge : l'ancien outil ecrit 0 index sous ce chemin" \
    || fail "(f) temoin rouge : l'ancien outil ecrit $N index (attendu 0)"
fi

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
