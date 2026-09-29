#!/usr/bin/env bash
# Mission 218, lot 6: the folder-mode guardians (check-links.sh,
# check-secrets.sh <projet>) read the baseline once, fingerprint by batch, launch
# no process per file, and say their progress on stderr -- with the same
# verdicts as before, byte for byte.
#
# Incident: on a knowledge base of 57 333 baseline entries (8.2 MB), both
# guardians ran 11 minutes without a word and were stopped: each file re-read
# the whole baseline with awk, twice or three times.
#
#   (a) verdicts: on a fixed corpus (untouched, touched, new, secret in a touched
#       file, broken link in a new file, forbidden file name, a file without a
#       final newline, a name with spaces, a binary file), in folder mode and
#       in repository mode, the tools of HEAD and the tools under test give the
#       same exit code, the same stdout and the same stderr -- progress lines
#       (`progress:`) left aside;
#   (b) time: check-secrets.sh in folder mode on a synthetic corpus of
#       FGP_FILES files (default 300) engraved in the baseline, a few touched,
#       finishes under FGP_MAX_SECONDS (default 20);
#   (c) progress: in folder mode, each guardian writes at least one
#       `progress:` line on stderr;
#   (d) negative control: a doctored output differs from the reference and the
#       comparison says so.
# The old tools are extracted from HEAD (`git archive`); the tools under test
# are this working tree's (TOOLS_UNDER_TEST=<folder> to test another copy).
#
# usage: bash tests/test-folder-guardians-one-pass.sh
# Exit 0: all cases PASS. Exit 1 otherwise; 77 when HEAD's tools cannot be read.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"
NEW="${TOOLS_UNDER_TEST:-$REPO_ROOT/tools}"
FGP_FILES="${FGP_FILES:-300}"
FGP_MAX_SECONDS="${FGP_MAX_SECONDS:-20}"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m218-fgp-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

mkdir -p "$TMP/old"
if ! git -C "$REPO_ROOT" archive HEAD tools rules/patterns | tar -x -C "$TMP/old" 2>/dev/null; then
  echo "SKIP : les outils de HEAD ne se lisent pas (git archive)"
  exit 77
fi
OLD="$TMP/old/tools"

G() { git -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false "$@"; }
FAKE="ghp_""ABCDEFGHIJ0123456789ABCD"
note() { printf -- '---\ntype: note\n---\n# %s\n\nVoir [a](./a.md).\n\n## Liens\n\n- [a](./a.md)\n' "$1"; }

# --- the fixed corpus -------------------------------------------------------------------------
build_corpus() { # build_corpus <dir>
  local d="$1"
  mkdir -p "$d/docs" "$d/sub dir"
  note a > "$d/a.md"
  note b > "$d/docs/b.md"
  note c > "$d/docs/c.md"
  note s > "$d/sub dir/with space.md"
  printf 'plain text\n' > "$d/docs/t.txt"
  { echo "# second-brain-birth-certificate: v1"; echo "# vault_id: sb-test-218"; echo "# vcs: none"; } > "$d/.pre-commit-config.yaml"
  uv run --no-project "$NEW/project_baseline.py" write "$d" "$d/.vault-baseline-t.tsv" >/dev/null
  echo "# baseline: .vault-baseline-t.tsv" >> "$d/.pre-commit-config.yaml"
  echo "repos: []" >> "$d/.pre-commit-config.yaml"
  # after the baseline: one touched file with a secret, one touched with a broken link,
  # one new file with a broken link, one new file without final newline, a binary
  printf 'token: %s\n' "$FAKE" >> "$d/docs/b.md"
  printf '\n[x](./missing.md)\n' >> "$d/docs/c.md"
  printf -- '---\ntype: note\n---\n# n\n\n[y](./nowhere.md)\n\n## Liens\n\n- [a](./a.md)\n' > "$d/docs/new.md"
  printf 'last line without newline' > "$d/docs/nonl.txt"
  printf 'bin\000ary %s\n' "$FAKE" > "$d/docs/blob.bin"
}

# run_guard <tools> <label> <mode: dir|repo> <guardian> <dir> : writes $TMP/<label>.{rc,out,err}
run_guard() {
  local tools="$1" label="$2" mode="$3" guard="$4" d="$5"
  if [ "$mode" = dir ]; then
    (cd "$TMP" && bash "$tools/$guard" "$d") >"$TMP/$label.out" 2>"$TMP/$label.err"
  else
    (cd "$d" && bash "$tools/$guard") >"$TMP/$label.out" 2>"$TMP/$label.err"
  fi
  echo $? > "$TMP/$label.rc"
  grep -v '^progress:' "$TMP/$label.err" > "$TMP/$label.verdict-err"
}
same() { # same <labelA> <labelB>
  cmp -s "$TMP/$1.rc" "$TMP/$2.rc" && cmp -s "$TMP/$1.out" "$TMP/$2.out" && cmp -s "$TMP/$1.verdict-err" "$TMP/$2.verdict-err"
}

compare_case() { # compare_case <label> <mode> <guardian> <dir>
  run_guard "$OLD" "$1-old" "$2" "$3" "$4"
  run_guard "$NEW" "$1-new" "$2" "$3" "$4"
  if same "$1-old" "$1-new"; then
    pass "(a) $1 : verdict identique (rc=$(cat "$TMP/$1-old.rc"))"
  else
    fail "(a) $1 : verdicts differents -- ancien rc=$(cat "$TMP/$1-old.rc") nouveau rc=$(cat "$TMP/$1-new.rc") ; diff stderr : $(diff "$TMP/$1-old.verdict-err" "$TMP/$1-new.verdict-err" | head -5 | tr '\n' ' ')"
  fi
}

D="$TMP/corpus"
build_corpus "$D"
compare_case "dossier-secrets" dir check-secrets.sh "$D"
compare_case "dossier-liens" dir check-links.sh "$D"

# the same corpus, the forbidden name removed then added: the name check first
D2="$TMP/corpus-env"
build_corpus "$D2"
printf 'X=1\n' > "$D2/.env"
compare_case "dossier-secrets-nom-interdit" dir check-secrets.sh "$D2"

# a clean corpus: the secret and broken links removed
D3="$TMP/corpus-clean"
build_corpus "$D3"
note b > "$D3/docs/b.md"; note c > "$D3/docs/c.md"; rm -f "$D3/docs/new.md" "$D3/docs/blob.bin"
compare_case "dossier-secrets-propre" dir check-secrets.sh "$D3"
compare_case "dossier-liens-propre" dir check-links.sh "$D3"

# repository mode: the same corpus under Git, everything staged
R="$TMP/repo"
build_corpus "$R"
G -C "$R" init -q; (cd "$R" && G add -A >/dev/null 2>&1)
compare_case "depot-secrets" repo check-secrets.sh "$R"
compare_case "depot-liens" repo check-links.sh "$R"

# --- (d) negative control -----------------------------------------------------------------------
cp "$TMP/dossier-liens-new.rc" "$TMP/doctored.rc"; cp "$TMP/dossier-liens-new.out" "$TMP/doctored.out"
{ cat "$TMP/dossier-liens-new.verdict-err"; echo "LIENS: extra"; } > "$TMP/doctored.verdict-err"
if same "dossier-liens-old" doctored; then
  fail "(d) temoin : une sortie alteree passe pour identique"
else
  pass "(d) temoin : une sortie alteree est vue differente"
fi

# --- (c) progress lines -----------------------------------------------------------------------------
grep -q '^progress:' "$TMP/dossier-secrets-new.err" && pass "(c) check-secrets : ligne de progression sur stderr" || fail "(c) check-secrets : aucune ligne de progression"
grep -q '^progress:' "$TMP/dossier-liens-new.err" && pass "(c) check-links : ligne de progression sur stderr" || fail "(c) check-links : aucune ligne de progression"

# --- (b) time on a synthetic corpus -----------------------------------------------------------------
S="$TMP/synthetic"
mkdir -p "$S/d"
i=0
while [ "$i" -lt "$FGP_FILES" ]; do
  printf 'file %s\n' "$i" > "$S/d/f$i.txt"
  i=$((i + 1))
done
{ echo "# second-brain-birth-certificate: v1"; echo "# vault_id: sb-test-218"; echo "# vcs: none"; } > "$S/.pre-commit-config.yaml"
uv run --no-project "$NEW/project_baseline.py" write "$S" "$S/.vault-baseline-s.tsv" >/dev/null
echo "# baseline: .vault-baseline-s.tsv" >> "$S/.pre-commit-config.yaml"
printf 'touched\n' >> "$S/d/f1.txt"; printf 'touched\n' >> "$S/d/f2.txt"
T0="$(date +%s)"
(cd "$TMP" && bash "$NEW/check-secrets.sh" "$S") >/dev/null 2>&1
T1="$(date +%s)"
DT=$((T1 - T0))
if [ "$DT" -le "$FGP_MAX_SECONDS" ]; then
  pass "(b) check-secrets, $FGP_FILES fichiers de ligne de base : ${DT} s (seuil ${FGP_MAX_SECONDS} s)"
else
  fail "(b) check-secrets, $FGP_FILES fichiers de ligne de base : ${DT} s, au-dessus du seuil ${FGP_MAX_SECONDS} s"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
