#!/usr/bin/env bash
# Mission 187: the published install line installs the version it names.
#
# Measured defect: the v0.1.5 line downloaded bootstrap.sh/.ps1 from the
# v0.1.5 tag, but their default ref was still v0.1.4 -- the line does not
# pass --ref/-Ref, so it installed v0.1.4.
#
# Oracle (PASS expected): every published line in README.md and INSTALL.md
#   (raw.githubusercontent.com/.../<tag>/bootstrap.sh or .ps1) names one and
#   the same tag, and that tag is the default ref of bootstrap.sh (REF=) and
#   of bootstrap.ps1 ($Ref =).
# Negative control: a throwaway copy of bootstrap.sh whose default ref is
#   another tag fails, both tags named.
#
# usage: bash tests/test-published-line-ref.sh

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m187-ref-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

line_tags() {
  cat "$REPO_ROOT/README.md" "$REPO_ROOT/INSTALL.md" \
    | sed -n -E 's#.*raw\.githubusercontent\.com/[^/]*/[^/]*/([^/]*)/bootstrap\.(sh|ps1).*#\1#p' | sort -u
}
sh_ref() { sed -n 's/^REF="\([^"]*\)"$/\1/p' "$1" | head -n 1; }
ps1_ref() { sed -n "s/^[[:space:]]*\[string\] \$Ref = '\([^']*\)',*\$/\1/p" "$1" | head -n 1; }

check() {
  # $1 = bootstrap.sh, $2 = bootstrap.ps1. Prints the verdict; returns 0 if agreed.
  local tags n s p
  tags="$(line_tags)"
  n="$(printf '%s\n' "$tags" | grep -c .)"
  s="$(sh_ref "$1")"; p="$(ps1_ref "$2")"
  if [ "$n" -ne 1 ]; then echo "published lines name $n tags: $(printf '%s' "$tags" | tr '\n' ' ')"; return 1; fi
  if [ "$s" != "$tags" ] || [ "$p" != "$tags" ]; then
    echo "published line $tags, bootstrap.sh default $s, bootstrap.ps1 default $p"; return 1
  fi
  echo "published line, bootstrap.sh and bootstrap.ps1 all at $tags"
}

echo "=== the published line installs the version it names ==="
if OUT="$(check "$REPO_ROOT/bootstrap.sh" "$REPO_ROOT/bootstrap.ps1")"; then
  echo "  PASS - $OUT"
else
  echo "  FAIL - $OUT"; FAILURES=$((FAILURES + 1))
fi

echo "=== negative control ==="
sed 's/^REF="[^"]*"$/REF="v0.0.0"/' "$REPO_ROOT/bootstrap.sh" > "$TMP/bootstrap.sh"
if OUT="$(check "$TMP/bootstrap.sh" "$REPO_ROOT/bootstrap.ps1")"; then
  echo "  FAIL - control: a bootstrap.sh defaulting to v0.0.0 passed"; FAILURES=$((FAILURES + 1))
else
  case "$OUT" in
    *"default v0.0.0"*) echo "  PASS - control: a bootstrap.sh defaulting to v0.0.0 fails ($OUT)" ;;
    *) echo "  FAIL - control failed for another reason: $OUT"; FAILURES=$((FAILURES + 1)) ;;
  esac
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
