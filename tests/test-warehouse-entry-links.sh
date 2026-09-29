#!/usr/bin/env bash
# Mission 231, step 4f: the entry files of the Vault's skills-warehouse/
# (AGENTS.md, README.md) carry no dead relative link.
#
# Report 229 named six dead links there (sources/COLLECTION-OPERATIONS.md,
# sources/INCREMENTAL-INGESTION.md, sources/registry.md, compatibility-report.md:
# files that left the thin checkout, logs/migrations/2026-09-02-thin-repository.md).
# The folder is exempt from the Vault's link guardian (Mission 229), so nothing
# caught them. This test reads every relative Markdown link of the two files
# and checks that its target exists -- the same reading as tools/check-links.sh
# for these two files, without its minutes-long sweep of the collections.
#
# usage: bash tests/test-warehouse-entry-links.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
W="$REPO_ROOT/skills-warehouse"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

echo "=== Mission 231 : liens des fichiers d'entree du warehouse du Vault ==="
for f in AGENTS.md README.md; do
  [ -f "$W/$f" ] || { fail "$f absent"; continue; }
  N=0; DEAD=""
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    case "$t" in *://*|mailto:*|/*|'#'*) continue ;; esac
    t="${t%%#*}"
    [ -n "$t" ] || continue
    N=$((N + 1))
    [ -e "$W/$t" ] || DEAD="$DEAD $t"
  done <<EOF
$(tr -d '\r' < "$W/$f" | grep -oE '\]\([^) ]+\)' | sed -E 's/^\]\(//; s/\)$//')
EOF
  if [ -z "$DEAD" ]; then
    pass "$f : $N lien(s) relatif(s), aucun mort"
  else
    fail "$f : lien(s) mort(s) :$DEAD"
  fi
done

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
