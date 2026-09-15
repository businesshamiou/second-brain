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
#   4/5/6. --out path validation (audit defect, same family as
#      acceptance-wizard.sh's resolve_report_path, Mission 171-C01 step 9):
#      a Bash-absolute path outside the repo is accepted unprefixed (4), a
#      Windows-absolute path outside the repo is accepted unprefixed and
#      uncorrupted (5), and a path inside the repo -- either notation -- is
#      refused (6).
#
# usage: tests/test-third-party-licenses.sh
# inputs: none -- no arguments, no environment variables. Reads the
# generator script and the warehouse tree already on disk in this repo.
# output: "PASS: 6/6 cas conformes" (exit 0) or "FAIL: <n> cas non conformes"
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
# WIN_TMP is a second scratch directory, deliberately created as a sibling
# of REPO_ROOT rather than via a bare `mktemp -d`: MSYS/Git Bash's own
# `mktemp -d` (and $TMPDIR) resolve under its separate "/tmp" overlay,
# which is not itself a drive-letter path -- case 5 below needs a real
# drive-mounted directory to convert to genuine Windows notation.
WIN_TMP="$(mktemp -d "$(dirname "$REPO_ROOT")/sb-tplicenses-win-test-XXXXXX")"
# Cases 6a/6b deliberately ask the generator to write inside REPO_ROOT to
# prove it refuses; this cleanup runs regardless of pass/fail so a
# not-yet-fixed regression never leaves a stray file in the working tree.
trap 'rm -rf "$TMP" "$WIN_TMP"; rm -f "$REPO_ROOT/leaked-licenses.md" "$REPO_ROOT/leaked-licenses-win.md"' EXIT

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

# --- 4/5/6. --out path validation (audit defect, same family as ------------
# acceptance-wizard.sh's resolve_report_path, Mission 171-C01 step 9):
# --out accepts a Windows path the same way it accepts a Bash path, an
# already-absolute path (either notation) is never glued behind the
# current directory, and a path inside this repository is refused.
# _win_form POSIX_PATH converts an MSYS mount path ("/c/foo/bar") to its
# Windows drive-letter, backslash spelling ("C:\foo\bar") -- a genuine
# Windows path for this machine's own drive mapping, not a hand-typed
# guess. Skips gracefully (does not fail) when TMP/REPO_ROOT is not itself
# under a drive mount (e.g. a real Linux CI box): the defect is
# Windows-specific and cannot occur there.
_win_form() {
  local p="$1" drive rest
  if [[ "$p" =~ ^/([A-Za-z])(/.*)?$ ]]; then
    drive="$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')"
    rest="${BASH_REMATCH[2]:-/}"
    rest="${rest//\//\\}"
    printf '%s:%s' "$drive" "$rest"
  fi
}

# --- 4. a Bash-absolute path outside the repo is accepted, unprefixed ------
OUT_4="$TMP/out-bash-absolute.md"
if bash "$GENERATOR" --out "$OUT_4" >"$TMP/gen4.log" 2>&1 && [ -f "$OUT_4" ]; then
  echo "ok [4-bash-absolu-hors-depot]: $OUT_4 ecrit tel quel"
else
  echo "FAIL [4-bash-absolu-hors-depot]: $(cat "$TMP/gen4.log")" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 5. a Windows-absolute path outside the repo is accepted, unprefixed ---
WIN_OUT_5="$(_win_form "$WIN_TMP")"
if [ -z "$WIN_OUT_5" ]; then
  echo "ok [5-windows-absolu-hors-depot]: ignore, pas de montage lettre-lecteur"
else
  WIN_OUT_5="$WIN_OUT_5\out-windows-absolute.md"
  EXPECTED_5="$WIN_TMP/out-windows-absolute.md"
  if bash "$GENERATOR" --out "$WIN_OUT_5" >"$TMP/gen5.log" 2>&1 && [ -f "$EXPECTED_5" ]; then
    echo "ok [5-windows-absolu-hors-depot]: --out '$WIN_OUT_5' ecrit sans corruption ni collage du dossier courant"
  else
    echo "FAIL [5-windows-absolu-hors-depot]: $(cat "$TMP/gen5.log")" >&2
    FAILURES=$((FAILURES + 1))
  fi
fi

# --- 6. a path (either notation) inside the repo is refused ----------------
INSIDE_BASH="$REPO_ROOT/leaked-licenses.md"
if OUT="$(bash "$GENERATOR" --out "$INSIDE_BASH" 2>&1)"; then
  echo "FAIL [6a-bash-dans-depot-refuse]: accepte un chemin Bash dans le depot : $OUT" >&2
  FAILURES=$((FAILURES + 1))
else
  echo "ok [6a-bash-dans-depot-refuse]"
fi
[ ! -e "$INSIDE_BASH" ]; rc=$?
if [ "$rc" -ne 0 ]; then
  echo "FAIL [6a-bash-dans-depot-refuse]: le fichier a quand meme ete cree : $INSIDE_BASH" >&2
  FAILURES=$((FAILURES + 1))
fi

WIN_INSIDE="$(_win_form "$REPO_ROOT")"
if [ -z "$WIN_INSIDE" ]; then
  echo "ok [6b-windows-dans-depot-refuse]: ignore, pas de montage lettre-lecteur"
else
  WIN_INSIDE="$WIN_INSIDE\leaked-licenses-win.md"
  if OUT="$(bash "$GENERATOR" --out "$WIN_INSIDE" 2>&1)"; then
    echo "FAIL [6b-windows-dans-depot-refuse]: accepte un chemin Windows dans le depot : $OUT" >&2
    FAILURES=$((FAILURES + 1))
  else
    echo "ok [6b-windows-dans-depot-refuse]"
  fi
  [ ! -e "$REPO_ROOT/leaked-licenses-win.md" ]; rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL [6b-windows-dans-depot-refuse]: le fichier a quand meme ete cree sous $REPO_ROOT" >&2
    FAILURES=$((FAILURES + 1))
  fi
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 6/6 cas conformes"
  exit 0
else
  echo "FAIL: $FAILURES cas non conformes"
  exit 1
fi
