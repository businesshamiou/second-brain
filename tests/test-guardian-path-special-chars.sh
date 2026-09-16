#!/usr/bin/env bash
# A repository root containing `&` or a backslash reaches the guardians
# intact (Mission 181, step 6 resumed).
#
# check-asserted-paths.sh and check-distribution-manifest.sh used to prefix
# every tracked path with `sed "s#^#$VAULT_ROOT/#"`. sed reads that root as
# a replacement: an `&` becomes the matched text, a backslash an escape (GNU
# sed's `\U` upper-cases the rest). The front-matter table came out empty,
# so the asserted-paths guardian skipped every rules/decision document and
# the manifest guardian never compared front-matter with the manifest. The
# published install line hit it on Linux, whose sample answers file carries
# the path `C:\Users\example\...`; any participant whose path holds an `&`
# hits it on every platform.
#
# Both guardians run in a sandbox whose root carries the character. Each
# sandbox holds exactly one defect that only an intact table can see:
#   - rules/RULES-probe.md (type: rules) asserts a missing file: the
#     asserted-paths guardian must refuse and name it;
#   - doc/probe.md says `distributable: false` while the manifest calls it
#     DISTRIBUABLE: the manifest guardian must report the inconsistency.
# With a mangled table both guardians pass silently, so every case below
# fails on the tree before this fix.
#
# Cases:
#   1. ampersand-asserted-paths
#   2. ampersand-manifest
#   3. backslash-asserted-paths  (SKIP where the file system cannot hold a
#   4. backslash-manifest         backslash in a name: Windows)
#
# usage: tests/test-guardian-path-special-chars.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS="$SCRIPT_DIR/../tools"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0
SKIPS=0

make_sandbox() {
  # $1 = sandbox directory (its name carries the character under test).
  local repo="$1"
  mkdir -p "$repo/tools" "$repo/rules" "$repo/doc" || return 1
  local t
  for t in check-asserted-paths.sh check-distribution-manifest.sh kvmap.sh resolve-sibling-repo.sh; do
    cp "$TOOLS/$t" "$repo/tools/$t" || return 1
  done
  printf -- '---\ntype: rules\ntitle: "Probe"\nstatus: active\n---\n\nSee `rules/absent-probe-181.md` for details.\n' > "$repo/rules/RULES-probe.md"
  printf -- '---\ntitle: "Probe"\ndistributable: false\n---\n\nProbe.\n' > "$repo/doc/probe.md"
  (
    cd "$repo" \
      && git init -q -b main \
      && git config core.autocrlf false \
      && git add -A \
      && git ls-files | awk '{ print $0 "\tDISTRIBUABLE" }' > distribution-manifest.txt \
      && printf 'distribution-manifest.txt\tDISTRIBUABLE\n' >> distribution-manifest.txt \
      && git add distribution-manifest.txt
  ) >/dev/null 2>&1
}

check_pair() {
  # $1 = label, $2 = sandbox directory.
  local label="$1" repo="$2" out rc

  out="$(cd "$repo" && bash tools/check-asserted-paths.sh 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "rules/RULES-probe.md.*rules/absent-probe-181.md"; then
    echo "ok [$label-asserted-paths]: the rules document was checked, its dead path refused"
  else
    echo "FAIL [$label-asserted-paths]: exit=$rc, the rules document was not checked. Output:" >&2
    printf '%s\n' "$out" >&2
    FAILURES=$((FAILURES + 1))
  fi

  out="$(cd "$repo" && bash tools/check-distribution-manifest.sh 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "INCOHERENCE-DISTRIBUTABLE : doc/probe.md"; then
    echo "ok [$label-manifest]: the front-matter table was read, the inconsistency reported"
  else
    echo "FAIL [$label-manifest]: exit=$rc, the front-matter check saw nothing. Output:" >&2
    printf '%s\n' "$out" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

# --- 1-2. ampersand ----------------------------------------------------------
AMP="$TMP/R&D workspace/second-brain"
if make_sandbox "$AMP"; then
  check_pair "ampersand" "$AMP"
else
  echo "FAIL [ampersand]: sandbox could not be built under $AMP" >&2
  FAILURES=$((FAILURES + 2))
fi

# --- 3-4. backslash ----------------------------------------------------------
BS_PARENT="$TMP/C:\\Users\\example\\second-brain-workspace"
BS="$BS_PARENT/second-brain"
if mkdir -p "$BS_PARENT" 2>/dev/null \
    && case "$(cd "$BS_PARENT" 2>/dev/null && pwd)" in *\\*) true ;; *) false ;; esac; then
  if make_sandbox "$BS"; then
    check_pair "backslash" "$BS"
  else
    echo "FAIL [backslash]: sandbox could not be built under $BS" >&2
    FAILURES=$((FAILURES + 2))
  fi
else
  echo "SKIP [backslash]: this file system does not keep a backslash inside a name"
  SKIPS=$((SKIPS + 2))
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 4 cases, 0 failure, $SKIPS skip(s)"
  exit 0
fi
echo "FAIL: $FAILURES case(s)"
exit 1
