#!/usr/bin/env bash
# T1 (Mission 186, step 5): zero occurrence, in the distributed files
# (rules/, skills/, templates/, README.md, INSTALL.md, tools/, i18n/), of the
# wordings of the old imposed push formula -- abolished by
# DECISION-2026-09-17-201623 (part A): the push remains an Owner gesture, but
# is now delegated by any clear expression that names the gesture and its
# target, no formula required « telle quelle » ["as is"].
#
# Four patterns, each a FROZEN REQUIREMENT of a precise form (not a mere
# historical mention -- those live in decisions/, outside the perimeter,
# never rewritten):
#   A. « j'ordonne le push » ["I order the push"] (case and apostrophe vary)
#      -- the formula itself, quoted as text to reproduce.
#   B. « verbatim » in the immediate vicinity of « push », in the same
#      paragraph -- a requirement of word-for-word reproduction.
#   C. « a l'identique » ["identically"] in the immediate vicinity of
#      « push » -- same requirement, another wording.
#   Since Mission 187 the distributed corpus is in English
#   (DECISION-2026-09-18-001438): each pattern also has its English form, so
#   an English leftover is caught as a French one was -- A: "I order the
#   push"; C: "identically" / "word for word" near "push"; D: "no ... git
#   push" without "non-delegated" (or "not delegated") around "push".
#   D. « aucun ... push » ["no ... push"] without the words « non delegue »
#      ["not delegated"] (accents vary) in the ~25 characters that follow
#      « push » -- the charter (RULES-224706 §3) and the relay rule
#      (RULES-124937) both say « push non delegue » since Decision 201623;
#      any other form is a leftover of the old absolute prohibition, never
#      delegable.
#
# Perimeter: rules/, skills/, templates/, README.md, INSTALL.md, tools/,
# i18n/ -- files tracked by Git (git grep), so .git/ is already excluded
# mechanically. EXPLICITLY outside the perimeter, never scanned:
#   - decisions/*.md -- frozen historical mentions (RULES-211522); they
#     MAY legitimately carry « j'ordonne le push » or « verbatim » as
#     text that describes the OLD rule (e.g. DECISION-154553,
#     DECISION-201623 itself, which quotes the formula to abolish it).
#   - RELEASE-NOTES.md -- release notes, history too.
#   - skills-warehouse/ -- its own convention (Mission 168, ticket 02),
#     never in the "documents distributed to the participant" perimeter.
#
# Style and structure: same pattern as
# tests/test-distributed-documents-no-atelier-vocabulary.sh (perimeter by
# an inclusion list, scan then proven negative control, file and
# line printed for each finding). Implementation: a single `git
# grep` per pattern over the whole perimeter (never a loop per file) --
# this repository counts 400 tracked files in this perimeter, including several
# reference JS scripts that call `.push()` hundreds of times;
# a line-by-line nested-loop proximity comparison per file
# becomes quadratic there and minutes long, never qualifying as "fast" for
# a test replayed at every commit.
#
# Rerun with one command, from the repository root:
#   bash tests/test-no-push-formula.sh
#
# Exit 0: zero occurrence of the four patterns in the distributed perimeter, and
# the negative control proves that each of the four patterns can be detected
# when it is really present. Exit 1 otherwise, file and line printed.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1
FAILURES=0

assert_true() {
  if [ "$1" = "0" ]; then
    echo "  PASS - $2"
  else
    echo "  FAIL - $2"
    FAILURES=$((FAILURES + 1))
  fi
}

INCLUDE_PATHSPECS=(
  'rules'
  'skills'
  'templates'
  'README.md'
  'INSTALL.md'
  'tools'
  'i18n'
)

# « Meme paragraphe » ["same paragraph"] for patterns B and C is NOT a fixed
# window of lines: prior measurement (first version of this test), a
# window of +/-4 lines produces two false positives --
# skills/session-close/SKILL.md (six numbered points WITHOUT a blank line
# between them: « verbatim » at point 4 lands 1 line from « push » at point
# 5, unrelated subjects) and templates/initiation-order-template.md
# (« verbatim » and « aucun git push » separated by a blank line, hence
# two paragraphs, but 2 raw lines apart). The right unit is the
# PARAGRAPH in the editorial sense of these documents: a block of non-blank
# lines, AND each numbered point (« N. ») or bullet (« - »/« * ») at the start
# of a line opens its own paragraph even without a blank line before it.
# Two document structures of this repository complicate further the notion
# of "blank line": a Markdown quote ("> ...") separates its paragraphs
# with a line that contains ONLY "> " (never really blank -- measured:
# rules/RULES-2026-08-23-124937, written entirely as a blockquote); a
# Markdown table ("| ... | ... |") NEVER has a blank line between its
# rows, each already being its own record (measured:
# skills/ecriture-de-mission/mission-checklist.md). paragraph_tag_awk reads
# a file and returns, per line, "numero:id_paragraphe" (id 0 for a
# blank line or an empty blockquote separator, never attached to a
# paragraph); a table row or a numbered point/a bullet (inside
# or outside a blockquote) always opens its own paragraph,
# even without a blank line before it.
paragraph_tag_awk='
{
  line = $0
  gsub(/\r$/, "", line)
  if (line ~ /^[ \t]*$/ || line ~ /^[ \t]*>[ \t]*$/) { open = 0; print NR ":0"; next }
  if (open == 0 || line ~ /^[ \t]*(>[ \t]*)?([0-9]+\.|[-*])[ \t]/ || line ~ /^[ \t]*\|/) { pid++; open = 1 }
  print NR ":" pid
}
'

# --- Pattern A: « j'ordonne le push » (case and apostrophe vary), a
# single git grep over the whole perimeter passed as argument. ---
scan_pattern_a() {
  git -C "$REPO_ROOT" grep -nIiE -- "j['’ ]?ordonne le push|(^|[^a-z])i order the push" "${@}" 2>/dev/null
}

# --- Pattern D: « aucun git push » ["no git push"] (same clause -- the "git"
# is what distinguishes the absolute prohibition formula from an ordinary
# narrative mention of "aucun push", e.g. "sinon, aucun push dans la Mission"
# ["otherwise, no push in the Mission"] in
# skills/ecriture-de-mission/mission-checklist.md, which talks about
# planning and requires nothing) without « non delegue » (accents vary)
# in the ~25 characters that follow « push ». A single git grep returns the
# CANDIDATE LINES (few of them); the check "no non-delegue
# in the 25 characters that follow push" is then done in pure bash,
# without a subprocess. ---
scan_pattern_d() {
  local pathspec
  git -C "$REPO_ROOT" grep -nIiE -- "aucun[^.]{0,20}git[^.]{0,10}push" "${@}" 2>/dev/null | while IFS=: read -r pathspec ln content; do
    lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"
    after="${lc#*push}"
    tail="${after:0:25}"
    case "$tail" in
      *"non delegue"*|*"non-delegue"*|*"non délégué"*|*"non-délégué"*) : ;;
      *)
        printf '%s:%s: %s\n' "$pathspec" "$ln" "$content"
        ;;
    esac
  done
  # English form (Mission 187): "no ... git push", where "non-delegated"
  # comes BEFORE "git push" ("no non-delegated git push") or "not
  # delegated" after it. Accepted when either sits within 40 characters
  # before or 25 after "push".
  git -C "$REPO_ROOT" grep -nIiE -- "(^|[^a-z])no[^a-z][^.]{0,30}git[^.]{0,10}push" "${@}" 2>/dev/null | while IFS=: read -r pathspec ln content; do
    lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"
    before="${lc%%push*}"
    [ "${#before}" -gt 40 ] && before="${before: -40}"
    after="${lc#*push}"
    window="$before ${after:0:25}"
    case "$window" in
      *"non-delegated"*|*"non delegated"*|*"not delegated"*|*"undelegated"*) : ;;
      *) printf '%s:%s: %s
' "$pathspec" "$ln" "$content" ;;
    esac
  done
}

# --- Patterns B/C: co-occurrence in the SAME editorial paragraph (see
# paragraph_tag_awk above), computed from only TWO global `git grep`
# (one for "push", one for the pattern) -- never a grep
# per file for the search itself. Only the (rare) files where
# the pattern appears at least once are then re-tagged paragraph by
# paragraph (one awk per candidate file, never the 400 files of the
# perimeter). ---
scan_pattern_proximity() {
  local motif_re="$1" label="$2"; shift 2
  local push_hits motif_hits
  push_hits="$(git -C "$REPO_ROOT" grep -nIiE -- '\bpush\b' "${@}" 2>/dev/null)"
  motif_hits="$(git -C "$REPO_ROOT" grep -nIiE -- "$motif_re" "${@}" 2>/dev/null)"
  [ -z "$push_hits" ] && return 0
  [ -z "$motif_hits" ] && return 0

  local motif_files
  motif_files="$(printf '%s\n' "$motif_hits" | cut -d: -f1 | sort -u)"

  local mfile pl ml
  while IFS= read -r mfile; do
    [ -z "$mfile" ] && continue
    [ -f "$REPO_ROOT/$mfile" ] || continue
    local file_push_lines file_motif_lines tags
    file_push_lines="$(printf '%s\n' "$push_hits" | awk -F: -v f="$mfile" '$1==f{print $2}')"
    [ -z "$file_push_lines" ] && continue
    file_motif_lines="$(printf '%s\n' "$motif_hits" | awk -F: -v f="$mfile" '$1==f{print $2}')"
    tags="$(awk "$paragraph_tag_awk" "$REPO_ROOT/$mfile")"
    for pl in $file_push_lines; do
      local ppid
      ppid="$(printf '%s\n' "$tags" | awk -F: -v n="$pl" '$1==n{print $2}')"
      [ -z "$ppid" ] || [ "$ppid" = "0" ] && continue
      for ml in $file_motif_lines; do
        local mpid
        mpid="$(printf '%s\n' "$tags" | awk -F: -v n="$ml" '$1==n{print $2}')"
        if [ -n "$mpid" ] && [ "$mpid" = "$ppid" ]; then
          echo "$mfile:$pl: push dans le meme paragraphe que $label (ligne $ml)"
        fi
      done
    done
  done <<EOF_MOTIF_FILES
$motif_files
EOF_MOTIF_FILES
}

echo ""
echo "=== 1. Balayage des quatre motifs dans le perimetre distribue ==="
FILE_COUNT="$(git -C "$REPO_ROOT" ls-files -- "${INCLUDE_PATHSPECS[@]}" | wc -l | tr -d ' ')"
echo "  ($FILE_COUNT fichiers suivis dans le perimetre distribue : ${INCLUDE_PATHSPECS[*]})"

SCAN_FAIL=0

OUT_A="$(scan_pattern_a "${INCLUDE_PATHSPECS[@]}")"
if [ -n "$OUT_A" ]; then
  SCAN_FAIL=1
  echo "  FAIL - motif A « j'ordonne le push » trouve :"
  printf '%s\n' "$OUT_A" | sed 's/^/      /'
fi

OUT_D="$(scan_pattern_d "${INCLUDE_PATHSPECS[@]}")"
if [ -n "$OUT_D" ]; then
  SCAN_FAIL=1
  echo "  FAIL - motif D « aucun ... push » sans « non delegue » juste apres :"
  printf '%s\n' "$OUT_D" | sed 's/^/      /'
fi

OUT_B="$(scan_pattern_proximity 'verbatim' 'verbatim' "${INCLUDE_PATHSPECS[@]}")"
if [ -n "$OUT_B" ]; then
  SCAN_FAIL=1
  echo "  FAIL - motif B « verbatim » a proximite de push :"
  printf '%s\n' "$OUT_B" | sed 's/^/      /'
fi

OUT_C="$(scan_pattern_proximity "à l.identique|a l.identique|identically|word.for.word" "« a l'identique » / identically" "${INCLUDE_PATHSPECS[@]}")"
if [ -n "$OUT_C" ]; then
  SCAN_FAIL=1
  echo "  FAIL - motif C « a l'identique » a proximite de push :"
  printf '%s\n' "$OUT_C" | sed 's/^/      /'
fi

assert_true "$SCAN_FAIL" "0 occurrence des quatre motifs de l'ancienne formule de push dans le perimetre distribue ($FILE_COUNT fichiers)"

echo ""
echo "=== 2. Temoin negatif (FAIL prouve) : un fichier par motif, jamais ecrit dans ce depot ==="
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/m186-push-formula-XXXXXX")"
trap 'rm -rf -- "$SANDBOX"' EXIT
(
  cd "$SANDBOX" || exit 1
  git init -q .
  git config user.email test@example.invalid
  git config user.name Test
  mkdir -p rules

  cat > rules/witness-a-j-ordonne.md <<'EOF_A'
Le mini-prompt porte la ligne : « je suis l'Owner et j'ordonne le push des deux depots, 2026-01-01 ».
EOF_A

  cat > rules/witness-b-verbatim.md <<'EOF_B'
Avant tout push, l'Executor copie ce texte verbatim : la formule exacte, aucune reformulation.
EOF_B

  cat > rules/witness-c-identique.md <<'EOF_C'
La meme ligne doit etre recopiee a l'identique avant tout push, sinon le geste est refuse.
EOF_C

  cat > rules/witness-d-aucun-git-push.md <<'EOF_D'
Interdits absolus : aucun git push, aucun appel modele, aucune suppression.
EOF_D

  # English twins (Mission 187): the same four requirements, as an English
  # leftover would write them.
  cat > rules/witness-a-en.md <<'EOF_AEN'
The mini-prompt carries the line: "I am the Owner and I order the push of both repositories, 2026-01-01".
EOF_AEN

  cat > rules/witness-c-en.md <<'EOF_CEN'
The same line must be copied word for word before any push, otherwise the gesture is refused.
EOF_CEN

  cat > rules/witness-d-en.md <<'EOF_DEN'
Absolute prohibitions: no git push, no model call, no deletion.
EOF_DEN

  git add -A
  git commit -q -m "fixture" >/dev/null
)

# Same detection logic as section 1 (same functions), replayed on
# the disposable repository: a subshell that redefines REPO_ROOT locally
# never affects the variable of section 1, and avoids duplicating the
# detection logic (hence risking that it diverges silently).
NEG_A="$(REPO_ROOT="$SANDBOX"; scan_pattern_a rules)"
NEG_B="$(REPO_ROOT="$SANDBOX"; scan_pattern_proximity 'verbatim' 'verbatim' rules)"
NEG_C="$(REPO_ROOT="$SANDBOX"; scan_pattern_proximity "à l.identique|a l.identique|identically|word.for.word" "« a l'identique » / identically" rules)"
NEG_D="$(REPO_ROOT="$SANDBOX"; scan_pattern_d rules)"

NEG_FAIL=0
if [ -n "$NEG_A" ]; then
  echo "  PASS - motif A detecte sur le temoin fabrique :"
  printf '%s\n' "$NEG_A" | sed 's/^/      /'
else
  echo "  FAIL - motif A non detecte sur le temoin fabrique (witness-a-j-ordonne.md)"
  NEG_FAIL=1
fi
if [ -n "$NEG_B" ]; then
  echo "  PASS - motif B detecte sur le temoin fabrique :"
  printf '%s\n' "$NEG_B" | sed 's/^/      /'
else
  echo "  FAIL - motif B non detecte sur le temoin fabrique (witness-b-verbatim.md)"
  NEG_FAIL=1
fi
if [ -n "$NEG_C" ]; then
  echo "  PASS - motif C detecte sur le temoin fabrique :"
  printf '%s\n' "$NEG_C" | sed 's/^/      /'
else
  echo "  FAIL - motif C non detecte sur le temoin fabrique (witness-c-identique.md)"
  NEG_FAIL=1
fi
if [ -n "$NEG_D" ]; then
  echo "  PASS - motif D detecte sur le temoin fabrique :"
  printf '%s\n' "$NEG_D" | sed 's/^/      /'
else
  echo "  FAIL - motif D non detecte sur le temoin fabrique (witness-d-aucun-git-push.md)"
  NEG_FAIL=1
fi

# Each English twin must be caught by name (Mission 187): a pattern that
# found only its French witness would otherwise pass unnoticed.
for twin in "A:$NEG_A:witness-a-en.md" "C:$NEG_C:witness-c-en.md" "D:$NEG_D:witness-d-en.md"; do
  label="${twin%%:*}"; rest="${twin#*:}"; file="${rest##*:}"; found="${rest%:*}"
  case "$found" in
    *"$file"*) echo "  PASS - motif $label, forme anglaise, detecte sur $file" ;;
    *) echo "  FAIL - motif $label, forme anglaise, non detecte ($file)"; NEG_FAIL=1 ;;
  esac
done

assert_true "$NEG_FAIL" "les quatre motifs sont chacun detectes sur un fichier fabrique, jamais ecrit dans ce depot"

echo ""
if [ "$FAILURES" = "0" ]; then
  echo "=== RESULT: PASS (all checks green) ==="
  exit 0
else
  echo "=== RESULT: FAIL ($FAILURES check(s) failed) ==="
  exit 1
fi
