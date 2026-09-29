#!/usr/bin/env bash
# Bench of the folder-mode guardians (Mission 218, lot 6). Outside the test
# suite by default: it writes tens of thousands of files and runs for minutes.
#
# Builds, in a throwaway folder, a project of FILES files of which MD are
# Markdown, engraves them in a baseline (tools/project_baseline.py write),
# touches TOUCHED of them and adds NEW files, then times:
#   - after : this Vault's check-secrets.sh and check-links.sh in folder mode,
#             on the whole corpus;
#   - before: the same guardians taken from OLD_REF (git archive), on a SAMPLE
#             of the corpus only -- on the whole of it they ran for hours (11
#             minutes without a word on a knowledge base, then stopped) --, and
#             the per-file rate projected on FILES, printed as a projection.
# Prints one line per measure, in seconds. Nothing outside the throwaway
# folder is written; it is removed at the end unless --keep.
#
# usage: bench-folder-guardians.sh [--files N] [--md M] [--sample S]
#                                  [--old-ref REF] [--no-before] [--keep]
#   defaults: --files 60000 --md 4000 --sample 300 --old-ref HEAD

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/tmp.sh"  # declared temporary folder (Mission 234)
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FILES=60000
MD=4000
SAMPLE=300
OLD_REF="HEAD"
BEFORE=1
KEEP=0
while [ $# -gt 0 ]; do
  case "$1" in
    --files) FILES="$2"; shift 2 ;;
    --md) MD="$2"; shift 2 ;;
    --sample) SAMPLE="$2"; shift 2 ;;
    --old-ref) OLD_REF="$2"; shift 2 ;;
    --no-before) BEFORE=0; shift ;;
    --keep) KEEP=1; shift ;;
    *) echo "usage: bench-folder-guardians.sh [--files N] [--md M] [--sample S] [--old-ref REF] [--no-before] [--keep]" >&2; exit 2 ;;
  esac
done
command -v uv >/dev/null 2>&1 || { echo "REFUS : uv introuvable" >&2; exit 1; }

TMP="$(mktemp -d "$(sb_tmp_dir tools)/bench-fg-XXXXXX")"
TMP="$(cd "$TMP" && pwd)"
[ "$KEEP" = "1" ] || trap 'rm -rf "$TMP"' EXIT

now() { date +%s; }

# make_corpus <dir> <files> <md>: the files spread over 100 folders; a Markdown
# file carries a "## Liens" section and one relative link, like a transcript
# of the knowledge base; one Python process writes them all.
make_corpus() {
  uv run --no-project python - "$1" "$2" "$3" <<'PY'
import os, sys
root, n, md = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
for i in range(n):
    d = os.path.join(root, "chan%02d" % (i % 100), "videos")
    os.makedirs(d, exist_ok=True)
    if i < md:
        p = os.path.join(d, "v%06d.md" % i)
        body = "---\ntitle: v%d\n---\n# Video %d\n\nTranscript line.\n\n## Liens\n\n- [index](../../README.md)\n" % (i, i)
    else:
        p = os.path.join(d, "f%06d.json" % i)
        body = '{"id": %d, "ok": true}\n' % i
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        f.write(body)
with open(os.path.join(root, "README.md"), "w", encoding="utf-8", newline="\n") as f:
    f.write("# Corpus\n\n## Liens\n\n- [self](./README.md)\n")
PY
  { echo "# second-brain-birth-certificate: v1"; echo "# vault_id: sb-bench"; echo "# vcs: none"; } > "$1/.pre-commit-config.yaml"
  uv run --no-project "$VAULT_ROOT/tools/project_baseline.py" write "$1" "$1/.vault-baseline-bench.tsv" >/dev/null
  echo "# baseline: .vault-baseline-bench.tsv" >> "$1/.pre-commit-config.yaml"
  printf '\nTouched.\n' >> "$1/chan00/videos/v000000.md"
  printf '\nTouched.\n' >> "$1/chan01/videos/v000001.md"
  printf -- '---\ntitle: new\n---\n# New\n\n## Liens\n\n- [r](../../README.md)\n' > "$1/chan02/videos/new.md"
}

time_guard() { # time_guard <tools> <guardian> <dir> : prints "<seconds> <rc>"
  local t0 t1 rc
  t0="$(now)"
  (cd "$TMP" && bash "$1/$2" "$3") >/dev/null 2>"$TMP/last.err"
  rc=$?
  t1="$(now)"
  echo "$((t1 - t0)) $rc"
}

echo "bench-folder-guardians: $FILES files, $MD Markdown, baseline engraved, 2 touched, 1 new"
T0="$(now)"; make_corpus "$TMP/corpus" "$FILES" "$MD"; T1="$(now)"
echo "corpus: $((T1 - T0)) s to write, baseline $(grep -vc '^#' "$TMP/corpus/.vault-baseline-bench.tsv") entries"

set -- $(time_guard "$VAULT_ROOT/tools" check-secrets.sh "$TMP/corpus")
echo "after  check-secrets.sh <projet>: $1 s (rc=$2, whole corpus)"
set -- $(time_guard "$VAULT_ROOT/tools" check-links.sh "$TMP/corpus")
echo "after  check-links.sh <projet>  : $1 s (rc=$2, whole corpus)"

if [ "$BEFORE" = "1" ]; then
  mkdir -p "$TMP/old"
  if git -C "$VAULT_ROOT" archive "$OLD_REF" tools rules/patterns 2>/dev/null | tar -x -C "$TMP/old"; then
    make_corpus "$TMP/sample" "$SAMPLE" "$(( SAMPLE * MD / FILES + 1 ))"
    set -- $(time_guard "$TMP/old/tools" check-secrets.sh "$TMP/sample"); BS="$1"; BSR="$2"
    set -- $(time_guard "$TMP/old/tools" check-links.sh "$TMP/sample"); BL="$1"; BLR="$2"
    echo "before check-secrets.sh <projet>: $BS s on a sample of $SAMPLE files ($OLD_REF, rc=$BSR); projected on $FILES: $(( BS * FILES / SAMPLE )) s"
    echo "before check-links.sh <projet>  : $BL s on a sample of $SAMPLE files ($OLD_REF, rc=$BLR); projected on $FILES: $(( BL * FILES / SAMPLE )) s"
  else
    echo "before: $OLD_REF unreadable (git archive): not measured"
  fi
fi
[ "$KEEP" = "1" ] && echo "kept: $TMP"
exit 0
