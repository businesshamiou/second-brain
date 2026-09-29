#!/usr/bin/env bash
# Mission 231, step 2: the system temporary folder is never a workspace root.
#
# The repository-root guard (tools/repo_root_guard.py, Mission 226) refused
# every throwaway folder of %TEMP% as soon as %TEMP% held two Git
# repositories -- on the Owner's workstation it holds six, left by other work
# (measured 2026-09-26) -- so a guarded tool launched in a scratch folder the
# suite had just made was refused (Mission 230, test-publish-version-line.sh).
#
# The system temporary folder is simulated: TMPDIR, TEMP and TMP name a fake
# one, FAKE, which holds two repositories and a scratch folder. Cases:
#   (1) the guard admits FAKE/scratch (RED before the fix: FAKE was taken for
#       a workspace root);
#   (2) build-indexes.sh writes FAKE/scratch/index.md (the tool, end to end);
# witnesses, which must stay refused:
#   (3) FAKE itself (the temporary folder is not a repository), in both modes;
#   (4) a workspace root BELOW the temporary folder (FAKE/ws holds two
#       repositories): FAKE/ws/plain is refused, descendants are judged as
#       anywhere else;
#   (5) a temporary folder that carries VAULT-ROOT.md (an accident: TMPDIR
#       pointing to a workspace) is still a workspace root;
#   (6) the incident witness: the real workspace root that holds this
#       repository (it carries VAULT-ROOT.md) is refused -- the guard is
#       called directly, read-only; build-indexes.sh is never run on it.
#       Without that marker (a CI checkout), a throwaway workspace stands in.
# No writing outside this test's own throwaway folder.
#
# usage: bash tests/test-repo-root-guard-system-temp.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m231-systemp-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
N() { sandbox_native_path "$1"; }
GUARD="$REPO_ROOT/tools/repo_root_guard.py"

FAKE="$TMP/systemp"
mkdir -p "$FAKE/scratch" "$FAKE/ws/plain"
for r in sib-a sib-b ws/x ws/y; do mkdir -p "$FAKE/$r" && git init -q "$FAKE/$r"; done
printf -- '---\ntype: note\nstatus: active\n---\n# scratch\n' > "$FAKE/scratch/note.md"

MARKED="$TMP/marked"
mkdir -p "$MARKED/scratch"
for r in one two; do mkdir -p "$MARKED/$r" && git init -q "$MARKED/$r"; done
printf 'marker\n' > "$MARKED/VAULT-ROOT.md"

# with_temp <dir> <command...>: the command sees <dir> as the system temporary folder.
with_temp() {
  local d; d="$(N "$1")"; shift
  TMPDIR="$d" TEMP="$d" TMP="$d" "$@"
}
guard() { uv run --no-project "$GUARD" "$@" 2>&1; }

echo "=== Mission 231 : le dossier temporaire du systeme n'est jamais une racine d'espace ==="
out="$(with_temp "$FAKE" uv run --no-project "$GUARD" "$(N "$FAKE/scratch")" 2>&1)"; rc=$?
[ "$rc" = 0 ] && pass "(1) dossier jetable sous le temporaire (qui porte 2 depots) : admis" \
  || fail "(1) dossier jetable sous le temporaire : rc=$rc -- $(printf '%s' "$out" | cut -c1-220)"

out="$(with_temp "$FAKE" bash "$REPO_ROOT/tools/build-indexes.sh" "$(N "$FAKE/scratch")" 2>&1)"; rc=$?
if [ "$rc" = 0 ] && [ -f "$FAKE/scratch/index.md" ]; then
  pass "(2) build-indexes.sh sur le dossier jetable : index.md ecrit"
else
  fail "(2) build-indexes.sh sur le dossier jetable : rc=$rc -- $(printf '%s' "$out" | tail -n 2 | tr '\n' ' ' | cut -c1-220)"
fi

out="$(with_temp "$FAKE" uv run --no-project "$GUARD" "$(N "$FAKE")" 2>&1)"; rc=$?
[ "$rc" = 2 ] && printf '%s' "$out" | grep -q REPO-ROOT-REFUSED && pass "(3) le temporaire lui-meme : refuse" \
  || fail "(3) le temporaire lui-meme : rc=$rc -- $out"
out="$(with_temp "$FAKE" uv run --no-project "$GUARD" --new-project "$(N "$FAKE")" 2>&1)"; rc=$?
[ "$rc" = 2 ] && printf '%s' "$out" | grep -q REPO-ROOT-REFUSED && pass "(3) le temporaire lui-meme, mode --new-project : refuse" \
  || fail "(3) le temporaire lui-meme, mode --new-project : rc=$rc -- $out"

out="$(with_temp "$FAKE" uv run --no-project "$GUARD" "$(N "$FAKE/ws/plain")" 2>&1)"; rc=$?
[ "$rc" = 2 ] && printf '%s' "$out" | grep -q 'is a workspace root' && pass "(4) racine d'espace sous le temporaire : son sous-dossier refuse" \
  || fail "(4) racine d'espace sous le temporaire : rc=$rc -- $out"

out="$(with_temp "$MARKED" uv run --no-project "$GUARD" "$(N "$MARKED/scratch")" 2>&1)"; rc=$?
[ "$rc" = 2 ] && printf '%s' "$out" | grep -q 'VAULT-ROOT.md' && pass "(5) temporaire qui porte VAULT-ROOT.md : reste une racine d'espace" \
  || fail "(5) temporaire qui porte VAULT-ROOT.md : rc=$rc -- $out"

WSROOT="$(cd "$REPO_ROOT/.." && pwd)"
if [ -f "$WSROOT/VAULT-ROOT.md" ]; then
  label="(6) temoin de l'incident : l'espace reel ($(N "$WSROOT")) refuse, lecture seule"
else
  WSROOT="$MARKED"
  label="(6) temoin de l'incident : un espace jetable a marqueur refuse (pas d'espace reel ici)"
fi
out="$(guard "$(N "$WSROOT")")"; rc=$?
[ "$rc" = 2 ] && printf '%s' "$out" | grep -q 'is a workspace root' && pass "$label" || fail "$label : rc=$rc -- $out"
out="$(with_temp "$FAKE" uv run --no-project "$GUARD" "$(N "$WSROOT")" 2>&1)"; rc=$?
[ "$rc" = 2 ] && pass "(6) ... et encore refuse quand le temporaire est ailleurs" || fail "(6) ... temporaire ailleurs : rc=$rc -- $out"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
