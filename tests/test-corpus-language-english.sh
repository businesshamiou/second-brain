#!/usr/bin/env bash
# Mission 187, T1 (DECISION-2026-09-18-001438): the distributed corpus is
# written in English; only what speaks to the participant stays in the
# participant's language.
#
# Corpus: every DISTRIBUABLE line of distribution-manifest.txt that is a
# text file, minus a CLOSED list of exclusions written below -- named
# prefixes and files, never a pattern:
#   i18n/            the message catalogues, fr/en/es by design (Mission 177)
#   tests/fixtures/  files that simulate a participant's answers
#   skills/external/ third-party skills, carried as their authors wrote them
#   USER.md          generated for the participant, in the participant's language
# What is read in each file is the prose written for its reader:
#   Markdown         everything outside fenced code blocks, inline code removed
#                    (commands, script output and literals a tool reads stay as
#                    they are, in any language)
#   scripts          comment lines (.sh, .ps1, .py, Git hooks): code, messages
#                    and generated content are interfaces, not prose
#   other text       the whole file
# Measure: the share of French function words among all words, per mille.
# A file fails when it holds at least MIN_HITS French function words AND its
# share reaches THRESHOLD. The list holds no word that is also common
# English, so English prose scores near 0; the few French words that stay on
# purpose (a skill's French trigger phrases, the Owner's words quoted with
# their translation) stay far below the threshold.
#
# Oracle (PASS expected): no corpus file fails; --report prints every file
#   and its score, highest first.
# Negative controls, in a throwaway tree, never in this repository: a French
#   file listed as distributed fails, named with its score; the same file
#   listed under i18n/ is ignored -- the exclusion is proven, not assumed.
#
# usage: bash tests/test-corpus-language-english.sh [--report]

set -u
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
THRESHOLD=15   # per mille
MIN_HITS=8
REPORT=0
[ "${1:-}" = "--report" ] && REPORT=1

EXCLUDED_PREFIXES="i18n/ tests/fixtures/ skills/external/"
EXCLUDED_FILES="USER.md"

# French function words that are not also ordinary English words.
FR_WORDS="le la les des du une et est sont dans pour avec sur qui que ne pas au aux ce cette ces il elle ils elles nous vous leur leurs mais ou sans être fait tout tous toute doit peut chaque aucun aucune ainsi donc selon entre vers chez lorsque quand où déjà très son sa ses notre votre"

is_excluded() {
  local f="$1" p
  for p in $EXCLUDED_PREFIXES; do
    case "$f" in "$p"*) return 0 ;; esac
  done
  for p in $EXCLUDED_FILES; do
    [ "$f" = "$p" ] && return 0
  done
  return 1
}

kind_of() {
  # $1 = path. Prints md, script, text or nothing (not a text file).
  case "$1" in
    *.md) echo md ;;
    *.sh|*.ps1|*.psm1|*.py|.githooks/*) echo script ;;
    *.yml|*.yaml|*.json|*.txt|*.toml|*.example|.gitattributes|.gitignore) echo text ;;
  esac
}

prose() {
  # $1 = file, $2 = kind. The part of the file that is prose for its reader.
  case "$2" in
    md) awk '/^[[:space:]]*(```|~~~)/ { fence = !fence; next } !fence { gsub(/`[^`]*`/, " "); print }' "$1" ;;
    script) grep -E '^[[:space:]]*#' "$1" | grep -v '^#!' ;;
    *) cat "$1" ;;
  esac
}

score() {
  # stdin = text. Prints "<per mille> <French words> <words>".
  awk -v words="$FR_WORDS" '
    BEGIN { n = split(words, w, " "); for (i = 1; i <= n; i++) fr[w[i]] = 1 }
    {
      line = tolower($0)
      gsub(/[^a-z\200-\377]+/, " ", line)
      k = split(line, t, " ")
      for (i = 1; i <= k; i++) { total++; if (t[i] in fr) hits++ }
    }
    END { printf "%d %d %d\n", (total ? int(1000 * hits / total) : 0), hits + 0, total + 0 }'
}

scan() {
  # $1 = root, $2 = manifest, $3 = scores file. Prints one FAIL line per
  # failing file; sets SCANNED and RED.
  SCANNED=0; RED=0
  : > "$3"
  awk -F'\t' '$2 == "DISTRIBUABLE" { print $1 }' "$2" > "$3.list"
  while IFS= read -r f; do
    is_excluded "$f" && continue
    k="$(kind_of "$f")"
    [ -n "$k" ] || continue
    [ -f "$1/$f" ] || continue
    SCANNED=$((SCANNED + 1))
    set -- "$1" "$2" "$3" $(prose "$1/$f" "$k" | score)
    printf '%s %s %s %s\n' "$4" "$5" "$6" "$f" >> "$3"
    if [ "$5" -ge "$MIN_HITS" ] && [ "$4" -ge "$THRESHOLD" ]; then
      RED=$((RED + 1))
      echo "  FAIL - $f : $4 per mille ($5 French function words of $6)"
    fi
  done < "$3.list"
}

FAILURES=0
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m187-lang-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

echo "=== T1 : the distributed corpus is in English (threshold $THRESHOLD per mille, at least $MIN_HITS words) ==="
scan "$REPO_ROOT" "$REPO_ROOT/distribution-manifest.txt" "$TMP/scores"
if [ "$REPORT" -eq 1 ]; then
  echo "  scores (per mille, French words, words, file), highest first:"
  sort -rn "$TMP/scores" | sed 's/^/    /'
fi
if [ "$SCANNED" -gt 0 ] && [ "$RED" -eq 0 ]; then
  echo "  PASS - $SCANNED corpus files, 0 above the threshold"
else
  echo "  FAIL - $RED of $SCANNED corpus files above the threshold"
  FAILURES=$((FAILURES + 1))
fi

# --- negative controls -------------------------------------------------------
echo "=== negative controls (throwaway tree) ==="
T="$TMP/trial"
mkdir -p "$T/docs" "$T/i18n"
cat > "$T/docs/essai.md" <<'EOF'
# Règle d'essai

Le Pilot ne décide jamais seul : il propose, et l'Owner tranche. Chaque
Mission porte ses propres portes, et aucune ne se ferme sans une preuve
mesurée dans le dépôt. Les rapports sont déposés par l'Executor, qui ne
pousse jamais sans une expression claire de l'Owner pour ce geste.
EOF
cp "$T/docs/essai.md" "$T/i18n/essai.md"
printf 'docs/essai.md\tDISTRIBUABLE\n' > "$T/manifest-docs.txt"
printf 'i18n/essai.md\tDISTRIBUABLE\n' > "$T/manifest-i18n.txt"

OUT="$(scan "$T" "$T/manifest-docs.txt" "$T/scores-docs")"
case "$OUT" in
  *"FAIL - docs/essai.md : "*" per mille"*) pass_msg="control: a French distributed file fails, named with its score -- ${OUT#  FAIL - }"; echo "  PASS - $pass_msg" ;;
  *) echo "  FAIL - control: a French distributed file was not caught"; FAILURES=$((FAILURES + 1)) ;;
esac
OUT="$(scan "$T" "$T/manifest-i18n.txt" "$T/scores-i18n"; echo "scanned=$SCANNED")"
case "$OUT" in
  "scanned=0") echo "  PASS - control: the same file under i18n/ is ignored (0 file scanned)" ;;
  *) echo "  FAIL - control: a file under i18n/ was scanned: $OUT"; FAILURES=$((FAILURES + 1)) ;;
esac

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
