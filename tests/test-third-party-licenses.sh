#!/usr/bin/env bash
# Regression test for tools/generate-third-party-licenses.sh (Mission 168,
# ticket 09). Verifies the one invariant T20 actually asks for: "every
# adopted skill carries its licence" -- plus determinism and freshness of
# the committed root file, since the script's whole point is to be a
# generated, checkable artifact rather than a hand-maintained one.
#
# Cases:
#   1. every skill directory under skills-warehouse/skill-collections/*/skills/
#      has exactly one row in the generated output, under its own
#      collection section.
#   2. running the generator twice produces byte-identical output
#      (deterministic, safe to regenerate at any time).
#   3. the root THIRD-PARTY-LICENSES.md already committed in this repo is
#      not stale relative to the warehouse content on disk right now
#      (tools/generate-third-party-licenses.sh --check).
#
# usage: tests/test-third-party-licenses.sh
# inputs: none -- no arguments, no environment variables. Reads the
# generator script and the warehouse tree already on disk in this repo.
# output: "PASS: 3/3 cas conformes" (exit 0) or "FAIL: <n> cas non conformes"
# (exit 1), same reporting convention as the other tests/test-*.sh in this
# directory (e.g. test-check-links-cross-repo.sh).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERATOR="$REPO_ROOT/tools/generate-third-party-licenses.sh"
WAREHOUSE_DIR="$REPO_ROOT/skills-warehouse/skill-collections"

if [ ! -f "$GENERATOR" ]; then
  echo "FAIL: generator introuvable : $GENERATOR" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0

# --- 1. every adopted skill directory has exactly one row -------------------
OUT_1="$TMP/first-run.md"
if ! bash "$GENERATOR" --out "$OUT_1" >"$TMP/gen1.log" 2>&1; then
  echo "FAIL [1-couverture]: le generateur a echoue :" >&2
  cat "$TMP/gen1.log" >&2
  FAILURES=$((FAILURES + 1))
else
  MISSING=""
  DUP=""
  TOTAL_SKILLS=0
  for collection_dir in "$WAREHOUSE_DIR"/*/; do
    [ -d "$collection_dir" ] || continue
    collection="$(basename "$collection_dir")"
    [ -d "$collection_dir/skills" ] || continue
    for skill_dir in "$collection_dir/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      skill="$(basename "$skill_dir")"
      TOTAL_SKILLS=$((TOTAL_SKILLS + 1))
      COUNT="$(grep -cF "| \`$skill\` |" "$OUT_1")"
      if [ "$COUNT" -eq 0 ]; then
        MISSING="$MISSING${MISSING:+, }$collection/$skill"
      elif [ "$COUNT" -gt 1 ]; then
        DUP="$DUP${DUP:+, }$collection/$skill ($COUNT)"
      fi
    done
  done
  if [ "$TOTAL_SKILLS" -eq 0 ]; then
    echo "FAIL [1-couverture]: aucun skill trouve sous $WAREHOUSE_DIR -- mesure invalide" >&2
    FAILURES=$((FAILURES + 1))
  elif [ -n "$MISSING" ] || [ -n "$DUP" ]; then
    echo "FAIL [1-couverture]: manquants=[$MISSING] doublons=[$DUP]" >&2
    FAILURES=$((FAILURES + 1))
  else
    echo "ok [1-couverture]: $TOTAL_SKILLS/$TOTAL_SKILLS skills adoptes portent une ligne de licence"
  fi
fi

# --- 2. deterministic: two runs produce byte-identical output ---------------
OUT_2="$TMP/second-run.md"
if ! bash "$GENERATOR" --out "$OUT_2" >"$TMP/gen2.log" 2>&1; then
  echo "FAIL [2-determinisme]: le second passage a echoue :" >&2
  cat "$TMP/gen2.log" >&2
  FAILURES=$((FAILURES + 1))
elif ! cmp -s "$OUT_1" "$OUT_2"; then
  echo "FAIL [2-determinisme]: deux passages successifs different :" >&2
  diff -u "$OUT_1" "$OUT_2" >&2 || true
  FAILURES=$((FAILURES + 1))
else
  echo "ok [2-determinisme]: deux passages successifs, sortie identique"
fi

# --- 3. the committed root file is not stale -------------------------------
CHECK_LOG="$TMP/check.log"
if bash "$GENERATOR" --check >"$CHECK_LOG" 2>&1; then
  echo "ok [3-fraicheur]: THIRD-PARTY-LICENSES.md a jour contre le warehouse"
else
  echo "FAIL [3-fraicheur]: $(cat "$CHECK_LOG")" >&2
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 3/3 cas conformes"
  exit 0
else
  echo "FAIL: $FAILURES cas non conformes"
  exit 1
fi
