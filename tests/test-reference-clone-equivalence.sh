#!/usr/bin/env bash
# Mission 188, T4: the shared reference clone (tests/sandbox-vault.sh,
# sandbox_reference_clone) changes how fast a test gets its source, never
# what gets installed.
#
# Oracle (PASS expected): the same install (install.sh, answers file, test
#   mode) played from a copy of the reference clone and from a clone made
#   without it gives the same verdict, the same installed history on top of
#   HEAD, and the same installed tree: same files, same contents once what
#   every install draws for itself is normalized (test root, timestamps,
#   random Vault identity and Pilot canary, hashes of the installer's own
#   commits; __pycache__ bytecode left out). In CI the second
#   source is a real network clone of this repository at the commit under
#   test; elsewhere it is `git clone --no-local` of this repository (no
#   network needed, said in the output).
# Negative control: a reference clone left at another commit is refused by
#   sandbox_reference_clone, both commits named; and an install from it
#   differs, the changed file named.
#
# Writes only under a temporary directory (prefix m188), simulated profile.
#
# usage: bash tests/test-reference-clone-equivalence.sh

set -u
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- l'installeur en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m188-refclone-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD)"
DECLARED_ORIGIN="https://github.com/businesshamiou/second-brain.git"

echo "=== T4 : reference clone = clone made without it ==="
echo "  TestRoot: $TMP   HEAD: $HEAD"

prepare_source() {
  # $1 = source dir. Same branch name, same commit, same remote and the
  # same main branch for every source, so only where the objects came from
  # differs. `main` matters: on a tag event CI checks out a detached HEAD
  # with no branch at all, so a clone of this checkout has no main while a
  # network clone has one, and the installed project's digest names
  # origin/main (measured on the v0.1.6 run 35343370838).
  git -C "$1" -c advice.detachedHead=false checkout --quiet -B sb-under-test "$HEAD" >/dev/null 2>&1 || return 1
  git -C "$1" branch --quiet -f main "$HEAD" >/dev/null 2>&1 || return 1
  git -C "$1" remote set-url origin "$DECLARED_ORIGIN" >/dev/null 2>&1 \
    || git -C "$1" remote add origin "$DECLARED_ORIGIN" >/dev/null 2>&1
}

install_from() {
  # $1 = case root, $2 = source. Sets RC.
  mkdir -p "$1"
  sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$1/workspace\"#" \
    "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$1/answers.json"
  bash "$REPO_ROOT/install.sh" --source "$2" --answers-file "$1/answers.json" \
    --test-mode --test-root "$1" > "$1.out" 2>&1
  RC=$?
}

windows_path_pattern() {
  # $1 = path. Its Windows spelling with backslashes (C:\x\y), escaped for
  # a sed pattern; the path itself elsewhere, where there is no such form.
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1" | sed 's#\\#\\\\#g'
  else
    printf '%s\n' "$1"
  fi
}

norm_file() {
  # $1 = case root, $2 = file under workspace/. Its content with what every
  # install draws for itself normalized: the case root (both spellings), the
  # timestamps, the random Vault identity (sb-<16 hex>) and the MCP server
  # name derived from it (Mission 191-C01), the Pilot canary
  # (pp-<12 hex>), and the hashes of the installer's own commits (they
  # carry a timestamp). HEAD of the source is marked first, so it is still
  # compared.
  sed -e "s#$1#<ROOT>#g" \
      -e "s#$(sandbox_native_path "$1")#<ROOT>#g" \
      -e "s#$(windows_path_pattern "$1")#<ROOT>#g" \
      -e "s#$HEAD#<HEAD>#g" -e "s#$(printf '%s' "$HEAD" | cut -c1-8)#<HEAD>#g" \
      -e 's#second-brain-vault-[0-9a-f]\{8\}#second-brain-vault-<VAULT_SHORT>#g' \
      -e 's#sb-[0-9a-f]\{16\}#<VAULT_ID>#g' \
      -e 's#pp-[0-9a-f]\{12\}#<CANARY>#g' \
      -e 's#[0-9a-f]\{40\}#<COMMIT>#g' \
      -e 's#HEAD [0-9a-f]\{7,12\}#HEAD <COMMIT>#g' \
      -e 's#[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[T ][0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}[^ "]*#<TS>#g' \
      "$1/workspace/$2"
}

tree_print() {
  # $1 = case root. One line per installed file under workspace/: path and
  # a checksum of its normalized content. Git's own internals are left out
  # (object packing is not content), and so are Python's __pycache__ files
  # (bytecode stamped with the source's path and time); the installed
  # history is compared separately.
  (cd "$1/workspace" && find . -type f ! -path '*/.git/*' ! -path '*/__pycache__/*' | sort) | while IFS= read -r f; do
    printf '%s %s\n' "$f" "$(norm_file "$1" "$f" | cksum | awk '{print $1 "-" $2}')"
  done
}

show_diff() {
  # $1, $2 = case roots, $3 = tree diff. Shows up to ten files, normalized.
  for f in $(printf '%s\n' "$3" | awk '/^[<>]/ { print $2 }' | sort -u | head -n 10); do
    echo "    --- $f ($(basename "$1") < > $(basename "$2"), normalized)"
    norm_file "$1" "$f" > "$TMP/x.1" 2>/dev/null
    norm_file "$2" "$f" > "$TMP/x.2" 2>/dev/null
    diff "$TMP/x.1" "$TMP/x.2" | head -n 8 | sed 's/^/    /'
  done
}

after_head() {
  # $1 = installed Vault. The installer commits its own files on top of
  # the source: prints how many commits sit after HEAD, or "none" when HEAD
  # is not in its history.
  git -C "$1" merge-base --is-ancestor "$HEAD" HEAD 2>/dev/null || { echo none; return; }
  git -C "$1" rev-list --count "$HEAD..HEAD"
}

# --- source A: from the shared reference clone -------------------------------
export SB_REFERENCE_CLONE_DIR="$TMP/refs"
REF="$(sandbox_reference_clone "$REPO_ROOT")"
if [ -n "$REF" ] && [ "$(git -C "$REF" rev-parse HEAD)" = "$HEAD" ]; then
  pass "reference clone built at HEAD ($REF)"
else
  fail "reference clone not built at HEAD"
fi
REF_AGAIN="$(sandbox_reference_clone "$REPO_ROOT")"
[ "$REF_AGAIN" = "$REF" ] && pass "a second call reuses the same reference clone" || fail "a second call built another reference ($REF_AGAIN)"

git clone --quiet -- "$REF" "$TMP/src-a" >/dev/null 2>&1 && prepare_source "$TMP/src-a" \
  || { echo "FAIL : source A not built"; exit 1; }

# --- source B: without the reference clone -----------------------------------
if [ "${GITHUB_ACTIONS:-}" = "true" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
  B_KIND="network clone of ${GITHUB_SERVER_URL:-https://github.com}/$GITHUB_REPOSITORY"
  git clone --quiet -- "${GITHUB_SERVER_URL:-https://github.com}/$GITHUB_REPOSITORY.git" "$TMP/src-b" >/dev/null 2>&1
else
  B_KIND="git clone --no-local of this repository (outside CI: no network)"
  git clone --quiet --no-local -- "$REPO_ROOT" "$TMP/src-b" >/dev/null 2>&1
fi
prepare_source "$TMP/src-b" || { echo "FAIL : source B not built ($B_KIND)"; exit 1; }
echo "  source B: $B_KIND"

install_from "$TMP/a" "$TMP/src-a"; RC_A=$RC
install_from "$TMP/b" "$TMP/src-b"; RC_B=$RC
if [ "$RC_A" = "$RC_B" ] && [ "$RC_A" = "0" ]; then
  pass "same verdict: both installs return 0"
else
  fail "verdicts differ or fail: reference $RC_A, other $RC_B -- $(tail -n 3 "$TMP/a.out" "$TMP/b.out" | tr '\n' ' ')"
fi

C_A="$(after_head "$TMP/a/workspace/second-brain")"
C_B="$(after_head "$TMP/b/workspace/second-brain")"
if [ "$C_A" != "none" ] && [ "$C_A" = "$C_B" ]; then
  pass "both installed Vaults descend from HEAD, $C_A installer commit(s) on top"
else
  fail "installed history: reference '$C_A', other '$C_B' commit(s) after HEAD (none = HEAD absent)"
fi

tree_print "$TMP/a" > "$TMP/a.tree"
tree_print "$TMP/b" > "$TMP/b.tree"
N="$(wc -l < "$TMP/a.tree" | tr -d ' ')"
DIFF="$(diff "$TMP/a.tree" "$TMP/b.tree")"
if [ -z "$DIFF" ] && [ "$N" -gt 0 ]; then
  pass "same installed tree: $N files, 0 difference (roots, timestamps, Vault identity, canary and installer commits normalized)"
else
  fail "installed trees differ ($N files): $(printf '%s\n' "$DIFF" | grep -c '^<') file(s)"
  show_diff "$TMP/a" "$TMP/b" "$DIFF"
fi

# --- negative control: a reference clone at another commit -------------------
echo "=== negative control: stale reference clone ==="
export SB_REFERENCE_CLONE_DIR="$TMP/stale-refs"
mkdir -p "$SB_REFERENCE_CLONE_DIR"
STALE="$SB_REFERENCE_CLONE_DIR/sb-reference-$HEAD.git"
git clone --quiet --bare --no-local -- "$REPO_ROOT" "$STALE" >/dev/null 2>&1
git clone --quiet -- "$STALE" "$TMP/stale-work" >/dev/null 2>&1
(
  cd "$TMP/stale-work" \
    && git config user.email sandbox@example.invalid && git config user.name sandbox \
    && git config commit.gpgsign false \
    && printf '\nA line from another commit.\n' >> README.md \
    && git add README.md && git commit -q -m "another commit" \
    && git push -q origin HEAD:refs/heads/stale-tip >/dev/null 2>&1
)
# Move the bare repository's HEAD itself, whether it names a branch or, on a
# tag event in CI, is detached (a plain `push origin HEAD` cannot run there).
git -C "$STALE" update-ref --no-deref HEAD refs/heads/stale-tip >/dev/null 2>&1
STALE_HEAD="$(git -C "$STALE" rev-parse HEAD)"
if [ "$STALE_HEAD" = "$HEAD" ]; then
  fail "control not built: the stale reference still sits at HEAD"
else
  REFUSAL="$(sandbox_reference_clone "$REPO_ROOT" 2>&1 >/dev/null)"; R=$?
  case "$REFUSAL" in
    *"$STALE_HEAD"*"$HEAD"*) [ "$R" -ne 0 ] && pass "control: stale reference refused, both commits named" || fail "control: refusal text but exit 0" ;;
    *) fail "control: stale reference not refused (exit $R): $REFUSAL" ;;
  esac
  git clone --quiet -- "$STALE" "$TMP/src-c" >/dev/null 2>&1
  git -C "$TMP/src-c" remote set-url origin "$DECLARED_ORIGIN" >/dev/null 2>&1
  install_from "$TMP/c" "$TMP/src-c"
  tree_print "$TMP/c" > "$TMP/c.tree"
  if diff "$TMP/a.tree" "$TMP/c.tree" | grep -q 'README.md'; then
    pass "control: an install from the stale reference differs, README.md named"
  else
    fail "control: an install from the stale reference showed no README.md difference"
  fi
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
