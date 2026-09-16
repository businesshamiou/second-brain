#!/usr/bin/env bash
# No bash 4+ or GNU-only construct on the path a participant walks
# (Mission 181).
#
# macOS ships /bin/bash 3.2 and BSD tools. The CI macOS runner also carried
# Homebrew's bash 5, so constructs such as `declare -A`, `mapfile`, awk's
# ENDFILE or `xargs -d` passed in CI and would break -- or worse, silently
# check nothing -- on a participant's new Mac. The macOS job now runs with
# Apple's own tools first on PATH (dynamic proof); this test is the static
# half: it reads every shell file of the participant's path and refuses any
# construct from the list below, on every platform, before a Mac ever sees
# it.
#
# Participant's path (tracked files): install.sh, everything under
# .githooks/, tools/*.sh, and shell files under skills/ -- except
# skills/external/, a provenance boundary of third-party material copied
# verbatim (its findings are recorded in the Mission 181 report, not
# rewritten here). Tests are not on that path; the macOS job runs them under
# Apple's bash anyway.
#
# A line may opt out with a trailing `# portability: <reason>` comment,
# for a construct that is guarded (e.g. a GNU tool used only after
# `command -v` found it). Comment lines are never scanned.
#
# Cases:
#   1. rules-bite -- a fixture carrying one instance of every rule: each
#      rule must report its own line (proves the scanner can fail).
#   2. portable-forms-pass -- a fixture carrying the portable replacements
#      used in this repository: nothing reported.
#   3. participant-path-clean -- the real participant path: nothing
#      reported.
#
# usage: tests/test-participant-shell-portability.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# One rule per line: <id> <TAB> <extended regex>. Indexed arrays and a plain
# read loop only -- this test itself runs under bash 3.2 on macOS.
RULES_FILE="$TMP/rules.tsv"
cat > "$RULES_FILE" <<'EOF_RULES'
bash4-assoc-array	(declare|local|typeset)[[:space:]]+-[a-zA-Z]*A
bash4-nameref-case-global	(declare|local|typeset)[[:space:]]+-[a-zA-Z]*[nlug]([[:space:]]|$)
bash4-mapfile	(^|[^A-Za-z_])(mapfile|readarray)([^A-Za-z_]|$)
bash4-case-modification	\$\{[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?(\^|,)
bash4-negative-index	\$\{[A-Za-z_][A-Za-z0-9_]*\[-[0-9]+\]\}
bash4-transformation	\$\{[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?@[QEPAKaUuLk]\}
bash4-pipe-stderr	(^|[^|])\|&|&>>
bash4-case-fallthrough	;;&|;&[[:space:]]*($|#)
bash4-coproc	(^|[[:space:];])coproc[[:space:]]
bash4-shopt	shopt[[:space:]]+-s[[:space:]].*(globstar|lastpipe|autocd|inherit_errexit|direxpand|globasciiranges)
bash4-variables	\$\{?(EPOCHSECONDS|EPOCHREALTIME|BASHPID|SRANDOM|BASH_ARGV0)([^A-Za-z0-9_]|$)
bash4-test-v	(\[\[?|test)[[:space:]]+-v[[:space:]]
bash4-wait-n	(^|[[:space:];])wait[[:space:]]+-[a-zA-Z]*[nf]
bash4-fd-allocation	\{[A-Za-z_][A-Za-z0-9_]*\}[<>]
bash4-printf-time	printf.*%\([^)]*\)T
bash4-read-flags	(^|[[:space:];])read[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-[a-zA-Z]*[Ni]
bash4-read-fractional-timeout	(^|[[:space:];])read[[:space:]].*-t[[:space:]]*[0-9]*\.[0-9]
bash4-unicode-escape	(\$'|printf[[:space:]]+['"])[^'"]*\\[uU][0-9a-fA-F]
bash4-local-dash	(^|[[:space:];])local[[:space:]]+-([[:space:]]|$)
gawk-extension	(^|[^A-Za-z_])(ENDFILE|BEGINFILE|PROCINFO|IGNORECASE|FPAT|ARGIND)([^A-Za-z_]|$)|(^|[^A-Za-z_])(gensub|strftime|systime|mktime|asort|asorti|patsplit|isarray|typeof)\(
gnu-xargs	(^|[^A-Za-z_])xargs[[:space:]]([^|]*[[:space:]])?(-d|--[a-z])
gnu-find	(^|[^A-Za-z_])find[[:space:]][^|]*-(printf|fprintf|regextype|readable|writable|executable|xtype)([[:space:]]|$)
gnu-sed-inplace	(^|[^A-Za-z_])sed[[:space:]]([^|]*[[:space:]])?(-i|--in-place)([[:space:]]|$)
gnu-sed-options	(^|[^A-Za-z_])sed[[:space:]]([^|]*[[:space:]])?(-r|--regexp-extended|-z|--null-data|-s|--separate)([[:space:]]|$)
gnu-hex-escape	(^|[^A-Za-z_])(sed|grep)[[:space:]].*\\x[0-9a-fA-F][0-9a-fA-F]
gnu-grep-perl	(^|[^A-Za-z_])grep[[:space:]]([^|]*[[:space:]])?-[a-zA-Z]*P
gnu-realpath-options	(^|[^A-Za-z_])realpath[[:space:]]+-
gnu-readlink-options	(^|[^A-Za-z_])readlink[[:space:]]+-[a-zA-Z]*[fem]
gnu-date	(^|[^A-Za-z_])date[[:space:]]([^|;]*[[:space:]])?(-d|-r|--date|--reference|--iso-8601|--rfc-[a-z0-9]*|-I[a-z]*)([[:space:]=]|$)
gnu-stat	(^|[^A-Za-z_])stat[[:space:]]+(-c|--format|--printf)
gnu-head-tail-negative	(^|[^A-Za-z_])(head|tail)[[:space:]]+-[nc][[:space:]]*-[0-9]
gnu-absent-tool	(^[[:space:]]*|[;|&(`][[:space:]]*|(then|do|else)[[:space:]]+)(tac|timeout|nproc|numfmt|sha256sum|sha1sum|md5sum|wget)[[:space:]]
gnu-coreutils-options	(^|[^A-Za-z_])(cp|mv|ln|install)[[:space:]]([^|]*[[:space:]])?(--parents|--no-target-directory|--reflink|-[a-zA-Z]*T|-D)([[:space:]]|$)
gnu-mktemp-options	(^|[^A-Za-z_])mktemp[[:space:]]([^|]*[[:space:]])?(--suffix|--tmpdir|-p)([[:space:]=]|$)
gnu-du-ls-base64	(^|[^A-Za-z_])(du[[:space:]]+-[a-zA-Z]*b|du[[:space:]].*--apparent-size|ls[[:space:]].*--(time-style|full-time|group-directories-first)|base64[[:space:]].*(-w|--wrap))
EOF_RULES

# scan FILE... : prints "<rule> <file>:<line>: <text>" for every hit, on
# non-comment lines without a `# portability:` opt-out.
scan() {
  local id re
  while IFS="$(printf '\t')" read -r id re; do
    [ -z "$id" ] && continue
    grep -nHE -- "$re" "$@" 2>/dev/null \
      | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' \
      | grep -v '# portability:' \
      | sed "s/^/$id /"
  done < "$RULES_FILE"
}

FAILURES=0

# --- 1. rules-bite -------------------------------------------------------------
BAD="$TMP/bad.sh"
cat > "$BAD" <<'EOF_BAD'
declare -A MAP=()
local -n ref=target
mapfile -t LINES < file
echo "${name,,}"
echo "${ARR[-1]}"
echo "${name@Q}"
cmd |& other
case x in a) echo a ;;& esac
coproc worker { cat; }
shopt -s globstar
echo "$EPOCHSECONDS"
[[ -v name ]]
wait -n
exec {fd}>file
printf '%(%F)T\n' -1
read -N 3 chunk
read -r -t 0.5 answer
printf '\u00e9\n'
local -
awk 'ENDFILE { print FILENAME }' a b
printf '%s\n' "$FILES" | xargs -d '\n' cat
find . -type f -printf '%T@ %p\n'
sed -i 's/a/b/' file
sed -r 's/(a)/\1/' file
sed 's/"/\x27/g' file
grep -P '\d+' file
realpath --relative-to=/a /a/b
readlink -f link
MTIME="$(date -r file +%s)"
stat -c %Y file
head -n -1 file
tac file
cp --parents a b
mktemp -p /tmp
du -sb dir
EOF_BAD
OUT_1="$(scan "$BAD")"
MISSING=""
while IFS="$(printf '\t')" read -r id re; do
  [ -z "$id" ] && continue
  printf '%s\n' "$OUT_1" | grep -q "^$id " || MISSING="$MISSING $id"
done < "$RULES_FILE"
if [ -z "$MISSING" ]; then
  echo "ok [1-rules-bite]: every rule reports its fixture line ($(printf '%s\n' "$OUT_1" | grep -c .) hit(s))"
else
  echo "FAIL [1-rules-bite]: rule(s) that saw nothing:$MISSING" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 2. portable-forms-pass ----------------------------------------------------
GOOD="$TMP/good.sh"
cat > "$GOOD" <<'EOF_GOOD'
# declare -A in a comment is never scanned
declare -a LIST=()
local -a parts=()
kv_set MAP "$key" "$value"
for i in ${LIST[@]+"${LIST[@]}"}; do :; done
echo "${#LIST[@]}" "${LIST[${#LIST[@]}-1]}" "${name:-default}" "${name#prefix}"
cmd 2>&1 | other
awk 'function flush() { print cur } FNR==1 { flush(); cur=FILENAME } END { flush() }' a b
printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 cat
find "$stamp" -mmin +1440
sed -E 's/(a)/\1/' file
sed "s/\"/'/g" file
sed '$d' file
grep -qE '^[[:space:]]*x' file
tr '[:upper:]' '[:lower:]'
while IFS= read -r line; do :; done < file
read -r -d '' value
if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; fi # portability: guarded by command -v
shasum -a 256 file
date -u +%Y-%m-%dT%H:%M:%SZ
date +%s
mktemp -d
cp -R a b
ln -s a b
realpath_like="$(abs_path "$p")"
timeouts=3
echo "Neither curl nor wget is available" >&2
if command -v wget >/dev/null 2>&1; then :; fi
EOF_GOOD
OUT_2="$(scan "$GOOD")"
if [ -z "$OUT_2" ]; then
  echo "ok [2-portable-forms-pass]: the portable forms used in this repository are not reported"
else
  echo "FAIL [2-portable-forms-pass]: false positive(s):" >&2
  printf '%s\n' "$OUT_2" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 3. participant-path-clean -------------------------------------------------
FILES=()
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  case "$rel" in
    skills/external/*) continue ;;
    install.sh|.githooks/*|tools/*.sh) FILES+=("$REPO_ROOT/$rel") ;;
    skills/*)
      case "$rel" in
        *.sh) FILES+=("$REPO_ROOT/$rel") ;;
        *) head -n 1 "$REPO_ROOT/$rel" 2>/dev/null | grep -qE '^#!.*(bash|sh)' && FILES+=("$REPO_ROOT/$rel") ;;
      esac
      ;;
  esac
done <<EOF_FILES
$(git -C "$REPO_ROOT" ls-files -- install.sh .githooks tools skills)
EOF_FILES

if [ "${#FILES[@]}" -lt 30 ]; then
  echo "FAIL [3-participant-path-clean]: only ${#FILES[@]} file(s) found on the participant path -- the file list is broken, nothing was really checked" >&2
  FAILURES=$((FAILURES + 1))
else
  OUT_3="$(scan "${FILES[@]}")"
  if [ -z "$OUT_3" ]; then
    echo "ok [3-participant-path-clean]: ${#FILES[@]} file(s) on the participant path, no bash 4+ or GNU-only construct"
  else
    echo "FAIL [3-participant-path-clean]: construct(s) that /bin/bash 3.2 or Apple's tools would not run as intended:" >&2
    printf '%s\n' "$OUT_3" | sed "s#$REPO_ROOT/##" >&2
    FAILURES=$((FAILURES + 1))
  fi
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 3/3 cases"
  exit 0
fi
echo "FAIL: $FAILURES case(s)"
exit 1
