#!/usr/bin/env bash
# T (Mission 201): the optional `## Fan-out` rubric of the Mission template and the instruction added to the
# ecriture-de-mission skill.
#
#   (a) the template carries exactly one `## Fan-out`, between `## Prior measurements` and `## Steps`, with the
#       four-column table and a comment that says it is OPTIONAL; every other rubric is still there, in its order;
#       relative to the previous template the change is additions only (skipped when that commit is not present);
#   (b) the skill carries the instruction in at most ten lines: it names the skill `dispatching-parallel-agents`,
#       says read only, says only the Executor writes, and gives the sequential fallback;
#   (c) the form of a filled rubric is checkable (fanout_form below; the refusal lives here, not in a guardian):
#       every batch has a name, targets, measures and an output file under a temporary folder, and no output
#       path inside a repository; the witnesses are a batch with no output, an output path inside the repository,
#       two batches with the same name, a batch with no targets -- all REFUSED; the twins are accepted;
#   (d) optional: a Mission with no rubric, an empty rubric, and the template's own placeholder row are all valid;
#       the template minus its Fan-out section keeps every other heading in order;
#   (e) the form checklist carries the line for the rubric.
#
# usage: bash tests/test-fan-out-rubric.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$REPO_ROOT/templates/mission-template.md"
SKILL="$REPO_ROOT/skills/ecriture-de-mission/SKILL.md"
CHECKLIST="$REPO_ROOT/skills/ecriture-de-mission/mission-checklist.md"
PASSES=0
FAILURES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m201-fanout-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

echo "=== T : la rubrique Fan-out du gabarit de Mission ==="

# --- (a) the template ---------------------------------------------------------------------------
HEADS="$(grep -n '^## ' "$TPL" | sed 's/^[0-9]*://')"
check "(a) exactly one '## Fan-out'" [ "$(printf '%s\n' "$HEADS" | grep -c '^## Fan-out$')" = "1" ]
pos() { printf '%s\n' "$HEADS" | grep -n "^## $1\$" | cut -d: -f1; }
check "(a) between '## Prior measurements' and '## Steps'" sh -c "[ '$(pos 'Prior measurements')' -lt '$(pos 'Fan-out')' ] && [ '$(pos 'Fan-out')' -lt '$(pos 'Steps')' ] && [ \$(( $(pos 'Steps') - $(pos 'Fan-out') )) = 1 ]"
EXPECTED="Measured existing state
Context
Objective
Scope
Preconditions
Sources
Applicable decisions
Constraints
Prior measurements
Steps
Gates
Validations
Exit contract
Resume contract
Doors
Liens"
GOT="$(printf '%s\n' "$HEADS" | sed 's/^## //' | grep -v '^Fan-out$')"
check "(a) the sixteen other rubrics are all still there, in their order" [ "$GOT" = "$EXPECTED" ]
FO="$(awk '/^## Fan-out$/{f=1;next} /^## /{f=0} f' "$TPL")"
check "(a) the comment says OPTIONAL" sh -c "printf '%s' \"\$1\" | grep -q 'OPTIONAL'" _ "$FO"
check "(a) the table has the four columns Batch | Targets | Measures | Output" sh -c "printf '%s\n' \"\$1\" | grep -q '^| Batch | Targets | Measures | Output |\$'" _ "$FO"
if git -C "$REPO_ROOT" cat-file -e a4b7e32:templates/mission-template.md 2>/dev/null; then
  DELS="$(git -C "$REPO_ROOT" diff --numstat a4b7e32 -- templates/mission-template.md | cut -f2)"
  if [ -z "$DELS" ] || [ "$DELS" = "0" ]; then pass "(a) against the previous template: additions only, no line removed"; else fail "(a) $DELS line(s) removed from the template"; fi
else
  pass "(a) previous template commit not present in this clone: additions-only check skipped"
fi

# --- (b) the skill ---------------------------------------------------------------------------------
SK="$(awk '/^### Fan-out \(optional rubric\)$/{f=1;next} /^## /{f=0} /^### /{f=0} f' "$SKILL")"
NL="$(printf '%s\n' "$SK" | grep -c '[^[:space:]]')"
check "(b) the instruction exists and holds at most ten lines ($NL)" sh -c "[ '$NL' -ge 1 ] && [ '$NL' -le 10 ]"
check "(b) it names the skill dispatching-parallel-agents" sh -c "printf '%s' \"\$1\" | grep -q 'dispatching-parallel-agents'" _ "$SK"
check "(b) it says read only" sh -c "printf '%s' \"\$1\" | grep -qi 'read only'" _ "$SK"
check "(b) it says only the Executor writes" sh -c "printf '%s' \"\$1\" | grep -q 'Only the Executor writes'" _ "$SK"
check "(b) it gives the sequential fallback" sh -c "printf '%s' \"\$1\" | grep -q 'one after the other'" _ "$SK"
check "(b) it does not copy the third-party skill (no gate text of its own)" sh -c "! printf '%s' \"\$1\" | grep -qi 'expose[sd]* a delegation capability'" _ "$SK"

# --- (c)/(d) the form of a filled rubric -------------------------------------------------------------
# fanout_form <mission.md> : prints REFUSED <why> / ACCEPTED, exit 1 / 0. An absent rubric, an empty one and the
# template's own placeholder row (cells that begin with '<') are valid.
fanout_form() {
  local f="$1" sec rows names row n cells b t m o
  sec="$(awk '/^## Fan-out$/{f=1;next} /^## /{f=0} f' "$f")"
  [ -n "$(printf '%s' "$sec" | tr -d '[:space:]')" ] || { echo "ACCEPTED (no rubric)"; return 0; }
  rows="$(printf '%s\n' "$sec" | grep '^|' | grep -v '^|[- |]*$' | grep -v '^| Batch |')"
  names=""
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    cells="$(printf '%s' "$row" | sed 's/^|//; s/|$//')"
    b="$(printf '%s' "$cells" | cut -d'|' -f1 | sed 's/^ *//; s/ *$//')"
    t="$(printf '%s' "$cells" | cut -d'|' -f2 | sed 's/^ *//; s/ *$//')"
    m="$(printf '%s' "$cells" | cut -d'|' -f3 | sed 's/^ *//; s/ *$//')"
    o="$(printf '%s' "$cells" | cut -d'|' -f4 | sed 's/^ *//; s/ *$//')"
    case "$b" in "<"*) continue ;; esac
    [ -n "$b" ] || { echo "REFUSED a batch with no name"; return 1; }
    [ -n "$t" ] || { echo "REFUSED batch $b has no targets"; return 1; }
    [ -n "$m" ] || { echo "REFUSED batch $b has no measures"; return 1; }
    [ -n "$o" ] || { echo "REFUSED batch $b has no output file"; return 1; }
    printf '%s' "$o" | grep -Eiq '%TEMP%|\$TEMP|\$TMP|/tmp/|\\Temp\\' || { echo "REFUSED batch $b: output '$o' is not under a temporary folder"; return 1; }
    case " $names " in *" $b "*) echo "REFUSED batch name $b used twice"; return 1 ;; esac
    names="$names $b"
  done <<EOF
$rows
EOF
  echo "ACCEPTED"
  return 0
}
mission_with() { # mission_with <file> <rows...> : a Mission stub with a filled rubric
  local f="$1"; shift
  { printf -- '---\ntype: mission\n---\n\n# M\n\n## Prior measurements\n\nx\n\n## Fan-out\n\n| Batch | Targets | Measures | Output |\n|---|---|---|---|\n'
    for r in "$@"; do printf '%s\n' "$r"; done
    printf '\n## Steps\n\n1. x\n'; } > "$f"
}
verdict() { OUT="$(fanout_form "$1")"; RC=$?; }
G1='| L1 | dir a, dir b | rev-list --count, porcelain | %TEMP%\m201\L1\measures.tsv |'
G2='| L2 | dir c | file count, bytes | %TEMP%\m201\L2\measures.tsv |'
mission_with "$TMP/ok.md" "$G1" "$G2";                                              verdict "$TMP/ok.md"
check "(c) a well-formed rubric with two batches -> accepted" [ "$RC" = 0 ]
mission_with "$TMP/noout.md" "$G1" '| L2 | dir c | file count, bytes | |';           verdict "$TMP/noout.md"
check "(c) witness: a batch with no output file -> REFUSED" sh -c "[ '$RC' = 1 ] && case \"\$1\" in *'no output file'*) exit 0;; *) exit 1;; esac" _ "$OUT"
mission_with "$TMP/inrepo.md" '| L1 | dir a | porcelain | tests/out.tsv |';         verdict "$TMP/inrepo.md"
check "(c) witness: an output path inside the repository -> REFUSED" sh -c "[ '$RC' = 1 ] && case \"\$1\" in *'not under a temporary folder'*) exit 0;; *) exit 1;; esac" _ "$OUT"
mission_with "$TMP/dup.md" "$G1" "$G1";                                             verdict "$TMP/dup.md"
check "(c) witness: two batches with the same name -> REFUSED" sh -c "[ '$RC' = 1 ] && case \"\$1\" in *'used twice'*) exit 0;; *) exit 1;; esac" _ "$OUT"
mission_with "$TMP/notarget.md" '| L1 |  | porcelain | %TEMP%\m201\L1\m.tsv |';     verdict "$TMP/notarget.md"
check "(c) witness: a batch with no targets -> REFUSED" sh -c "[ '$RC' = 1 ] && case \"\$1\" in *'no targets'*) exit 0;; *) exit 1;; esac" _ "$OUT"
mission_with "$TMP/twin.md" '| L1 | dir a | porcelain | $TMP/m201/L1/m.tsv |';         verdict "$TMP/twin.md"
check "(c) twin: the same batch with its output under a temporary folder -> accepted" [ "$RC" = 0 ]

printf -- '---\ntype: mission\n---\n\n# M\n\n## Prior measurements\n\nx\n\n## Steps\n\n1. x\n' > "$TMP/none.md"; verdict "$TMP/none.md"
check "(d) a Mission with no Fan-out rubric -> valid (the rubric is optional)" sh -c "[ '$RC' = 0 ] && case \"\$1\" in *'no rubric'*) exit 0;; *) exit 1;; esac" _ "$OUT"
printf -- '---\ntype: mission\n---\n\n# M\n\n## Fan-out\n\n## Steps\n\n1. x\n' > "$TMP/empty.md"; verdict "$TMP/empty.md"
check "(d) an empty rubric -> valid" [ "$RC" = 0 ]
verdict "$TPL"
check "(d) the template's own placeholder row -> valid" [ "$RC" = 0 ]
awk '/^## Fan-out$/{skip=1;next} /^## /{skip=0} !skip{print}' "$TPL" > "$TMP/tpl-minus.md"
check "(d) the template minus its Fan-out section keeps every other heading, in order" [ "$(grep '^## ' "$TMP/tpl-minus.md" | sed 's/^## //')" = "$EXPECTED" ]

# --- (e) the form checklist ---------------------------------------------------------------------------
check "(e) the form checklist carries the line for the rubric" sh -c "grep -q '^| 28 | \`## Fan-out\`' '$CHECKLIST'"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
