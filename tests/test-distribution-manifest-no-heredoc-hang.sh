#!/usr/bin/env bash
# Regression test for tools/check-distribution-manifest.sh: the guardian must
# finish on a repository whose front-matter table lands in the byte window
# where Git Bash's bash 5.3 deadlocks on a here-document (65537 to ~65690
# bytes, measured). The table holds one line per manifest file, prefixed by
# the absolute install path, so an install path of about 71 characters was
# enough to freeze every commit for good.
#
# The sandbox is sized on purpose: bulk files, then one padding file whose
# name length brings the table to TARGET_BYTES. Each file holds one line:
# since Mission 181 the table has no line for an empty file. The test
# refuses to conclude if the table is not inside the window, so it never
# passes without biting.
# On a bash without the defect (Linux CI) it still passes, without proving
# anything more than "the guardian completes".
#
# usage: tests/test-distribution-manifest-no-heredoc-hang.sh
# output: "PASS: 1/1 cases" (exit 0) or "FAIL: ..." (exit 1).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_SCRIPT="$SCRIPT_DIR/../tools/check-distribution-manifest.sh"
TARGET_BYTES=65600
WINDOW_LOW=65540
WINDOW_HIGH=65680

if [ ! -f "$REAL_SCRIPT" ]; then
  echo "FAIL: script under test not found: $REAL_SCRIPT" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"
mkdir -p "$REPO/tools" "$REPO/d" "$REPO/p"
cp "$REAL_SCRIPT" "$REPO/tools/check-distribution-manifest.sh"
# The guardian sources its portable maps from its own folder (Mission 181).
cp "$SCRIPT_DIR/../tools/kvmap.sh" "$REPO/tools/kvmap.sh"
( cd "$REPO" && git init -q -b main && git config core.autocrlf false ) || { echo "FAIL: git init" >&2; exit 1; }
VAULT_ROOT="$(git -C "$REPO" rev-parse --show-toplevel)"
L=${#VAULT_ROOT}

# Same pipeline as the guardian, measured with wc -c instead of a here-doc.
table_bytes() {
  local paths=""
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    [ -f "$VAULT_ROOT/$p" ] && paths="$paths
$p"
  done < <(cut -f1 "$REPO/distribution-manifest.txt")
  # One line per file, flushed on file change and at END: the guardian's own
  # form since Mission 181 (ENDFILE is gawk-only). Empty files emit nothing
  # there, so they count for nothing here either.
  printf '%s\n' "$paths" | sed "s#^#$VAULT_ROOT/#" | tr '\n' '\0' | xargs -0 awk '
    function flush() { if (cur != "") print cur "\t" }
    FNR==1 { flush(); cur=FILENAME }
    END { flush() }
  ' 2>/dev/null | wc -c
}

write_manifest() {
  ( cd "$REPO" && git add -A && git ls-files ) \
    | awk '{ print $0 "\tDISTRIBUABLE" }' > "$TMP/manifest.new"
  mv "$TMP/manifest.new" "$REPO/distribution-manifest.txt"
  ( cd "$REPO" && git add distribution-manifest.txt )
}

# Bulk: each line is L + 1 + len("d/fNNNNN.md") + 2 bytes.
: > "$REPO/distribution-manifest.txt"
BULK_LINE=$((L + 1 + 11 + 2))
BULK_COUNT=$(( (TARGET_BYTES - 400) / BULK_LINE ))
i=0
while [ "$i" -lt "$BULK_COUNT" ]; do
  printf -v name 'd/f%05d.md' "$i"
  printf 'x\n' > "$REPO/$name"
  i=$((i + 1))
done
write_manifest

CURRENT="$(table_bytes)"
PAD_NAME_LEN=$(( TARGET_BYTES - CURRENT - (L + 1 + 2 + 2) ))
if [ "$PAD_NAME_LEN" -lt 1 ] || [ "$PAD_NAME_LEN" -gt 180 ]; then
  echo "FAIL: cannot size the sandbox (table $CURRENT bytes, pad $PAD_NAME_LEN)" >&2
  exit 1
fi
PAD_NAME="$(printf '%*s' "$PAD_NAME_LEN" '' | tr ' ' 'x')"
printf 'x\n' > "$REPO/p/$PAD_NAME"
write_manifest

SIZE="$(table_bytes)"
if [ "$SIZE" -lt "$WINDOW_LOW" ] || [ "$SIZE" -gt "$WINDOW_HIGH" ]; then
  echo "FAIL: sandbox table is $SIZE bytes, outside the deadlock window [$WINDOW_LOW, $WINDOW_HIGH] -- the test would not bite" >&2
  exit 1
fi

OUT="$(cd "$REPO" && timeout 60 bash tools/check-distribution-manifest.sh 2>&1)"; RC=$?
if [ "$RC" -eq 0 ]; then
  echo "ok [1-table-in-deadlock-window]: guardian completed on a $SIZE-byte table"
  echo "PASS: 1/1 cases"
  exit 0
fi
if [ "$RC" -eq 124 ]; then
  echo "FAIL [1-table-in-deadlock-window]: guardian still running after 60 s on a $SIZE-byte table (here-document deadlock)" >&2
else
  echo "FAIL [1-table-in-deadlock-window]: exit=$RC on a $SIZE-byte table, output:" >&2
  printf '%s\n' "$OUT" >&2
fi
exit 1
