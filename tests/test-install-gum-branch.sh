#!/usr/bin/env bash
# Mission 220: the interactive questionnaire is displayed by gum when a
# terminal is there and gum is found; the installer tries to install gum when
# it is missing (winget on Windows, brew on macOS; nothing on Linux) and falls
# back to the plain questionnaire otherwise. Same questions, same defaults,
# same validations, same files written.
#
# No test ever has a terminal and none may download: the gum branch is proved
# with a FAKE gum and a FAKE winget/brew placed under the test root, and the
# test-only variable SB_INSTALLER_TEST_FORCE_TTY=1, which the installers
# honour only in test mode and only for tools found under the test root.
#
#   (a) forced TTY + fake gum -> the gum branch is taken: nine `gum input`
#       calls, in the questionnaire's order;
#   (b) the same answers through gum and through the plain questionnaire
#       (its scripted replay) -> the same files, byte for byte after
#       normalising timestamps, the sandbox root and random identities --
#       the accented answer « La simplicité » included;
#   (c) forced TTY, no gum, fake installer failing -> one fallback line,
#       rc=0, the plain questionnaire answers; the fake installer was the
#       only one called (no network);
#   (d) answers file (forced TTY, fake gum and installer present) -> no call;
#   (e) no TTY (fake gum and installer present, no forcing) -> no call.
# Played through install.sh everywhere and through install.ps1 when a
# Windows PowerShell is present (SKIP of that half otherwise, said).
#
# usage: bash tests/test-install-gum-branch.sh [W|B]   (default: both)
#        CASES=c bash tests/test-install-gum-branch.sh B   (a subset of a..e;
#        (b) needs (a))
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ONLY="${1:-}"
CASES="${CASES:-abcde}"
want_case() { case "$CASES" in *"$1"*) return 0 ;; esac; return 1; }
# The fallback line, from any of the three catalogues: before the language
# question the installer speaks the machine's default language.
fallback_texts() { sed -n 's/^  "install\.gum\.fallback": "\(.*\)",\{0,1\}$/\1/p' "$REPO_ROOT"/i18n/catalog.*.json; }
FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m220-g-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

UNAME="$(uname -s 2>/dev/null)"
# HOST_OS, never OS: OS is an exported Windows variable (Windows_NT) that a
# child PowerShell would inherit.
case "$UNAME" in MINGW*|MSYS*|CYGWIN*) HOST_OS=win ;; Darwin) HOST_OS=mac ;; *) HOST_OS=linux ;; esac
BASH_EXE="$(command -v bash)"
BASH_WIN=""
[ "$HOST_OS" = win ] && BASH_WIN="$(cygpath -w "$BASH_EXE")"

# Nine answers, in the questionnaire's order: language, assistant name,
# workspace (blank = default), first name, activity, AI tools (blank),
# what matters (accented), first project yes, its name.
ANSWERS=("FR" "Brian" "" "Ana" "Construire un système personnel" "" "La simplicité" "o" "premier-projet")
ASCII_ANSWERS=("FR" "Brian" "" "Ana" "Construire un systeme personnel" "" "La simplicite" "o" "premier-projet")

# fakes <root> : fake gum and fake winget/brew under <root>/bin (shell) and
# <root>/bin-ps (Windows command wrappers of the same scripts).
fakes() {
  local r="$1"
  mkdir -p "$r/bin" "$r/bin-ps"
  cat > "$r/bin/gum" <<'EOF'
#!/usr/bin/env bash
sub="${1:-}"; shift || true
hdr=""
while [ $# -gt 0 ]; do
  case "$1" in
    --header) hdr="${2:-}"; shift 2 ;;
    --header=*) hdr="${1#--header=}"; shift ;;
    *) shift ;;
  esac
done
printf '%s\t%s\n' "$sub" "$hdr" >> "$FAKE_GUM_LOG"
case "$sub" in
  input)
    n="$(cat "$FAKE_GUM_ANSWERS.idx" 2>/dev/null || echo 0)"; n=$((n + 1))
    printf '%s' "$n" > "$FAKE_GUM_ANSWERS.idx"
    sed -n "${n}p" "$FAKE_GUM_ANSWERS" ;;
esac
exit 0
EOF
  cat > "$r/bin/winget" <<'EOF'
#!/usr/bin/env bash
printf 'winget %s\n' "$*" >> "$FAKE_INSTALLER_LOG"
exit 1
EOF
  cp "$r/bin/winget" "$r/bin/brew"
  sed -i 's/^printf .winget /printf '"'"'brew /' "$r/bin/brew"
  chmod +x "$r/bin/gum" "$r/bin/winget" "$r/bin/brew"
  if [ -n "$BASH_WIN" ]; then
    printf '@"%s" "%%~dp0..\\bin\\gum" %%*\r\n' "$BASH_WIN" > "$r/bin-ps/gum.cmd"
    printf '@"%s" "%%~dp0..\\bin\\winget" %%*\r\n' "$BASH_WIN" > "$r/bin-ps/winget.cmd"
  fi
}
nogum() { rm -f "$1/bin/gum" "$1/bin-ps/gum.cmd"; }

# run <W|B> <root> <mode: tty|notty|file> [stop-step] : one install, answers on
# stdin too (the plain questionnaire reads them there when gum is not used).
run() {
  local p="$1" r="$2" mode="$3" stop="${4:-}" force="" extra=()
  [ "$mode" = notty ] || force=1
  : > "$r/gum.log"; : > "$r/installer.log"
  if [ "$p" = B ]; then
    printf '%s\n' "${ANSWERS[@]}" > "$r/gum-answers.txt"
  else
    printf '%s\n' "${ANSWERS[@]}" > "$r/gum-answers.txt"
  fi
  rm -f "$r/gum-answers.txt.idx"
  if [ "$mode" = file ]; then
    printf '{"language":"fr","vaultName":"Brian","workspacePath":"%s","firstName":"Ana","activity":"x","aiTools":[],"whatMatters":"y","firstProject":{"create":false}}\n' \
      "$( [ "$p" = W ] && cygpath -m "$r/workspace" || printf '%s' "$r/workspace")" > "$r/answers.json"
  fi
  if [ "$p" = B ]; then
    [ "$mode" = file ] && extra+=(--answers-file "$r/answers.json")
    [ -n "$stop" ] && extra+=(--stop-after-step "$stop")
    printf '%s\n' "${ASCII_ANSWERS[@]}" | \
      PATH="$r/bin:$PATH" SB_INSTALLER_TEST_FORCE_TTY="$force" FAKE_GUM_LOG="$r/gum.log" \
      FAKE_GUM_ANSWERS="$r/gum-answers.txt" FAKE_INSTALLER_LOG="$r/installer.log" \
      timeout 900 bash "$REPO_ROOT/install.sh" --source "$REPO_ROOT" --test-mode --test-root "$r" "${extra[@]}" \
      > "$r/out.txt" 2>&1
  else
    [ "$mode" = file ] && extra+=(-AnswersFile "$(cygpath -w "$r/answers.json")")
    [ -n "$stop" ] && extra+=(-StopAfterStep "$stop")
    printf '%s\r\n' "${ASCII_ANSWERS[@]}" | \
      PATH="$r/bin-ps:$r/bin:$PATH" SB_INSTALLER_TEST_FORCE_TTY="$force" FAKE_GUM_LOG="$r/gum.log" \
      FAKE_GUM_ANSWERS="$r/gum-answers.txt" FAKE_INSTALLER_LOG="$r/installer.log" \
      timeout 900 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$REPO_ROOT/install.ps1")" \
      -Source "$(cygpath -w "$REPO_ROOT")" -TestMode -TestRoot "$(cygpath -w "$r")" "${extra[@]}" \
      > "$r/out.txt" 2>&1
  fi
  echo $?
}

# The reference: the plain questionnaire, through its scripted replay.
run_scripted() {
  local p="$1" r="$2"
  if [ "$p" = B ]; then
    local args=(); for a in "${ANSWERS[@]}"; do args+=(--scripted-answers "$a"); done
    timeout 900 bash "$REPO_ROOT/install.sh" --source "$REPO_ROOT" --test-mode --test-root "$r" "${args[@]}" </dev/null > "$r/out.txt" 2>&1
  else
    local q="" a
    for a in "${ANSWERS[@]}"; do q="$q'${a//\'/\'\'}',"; done
    timeout 900 powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
      "& '$(cygpath -w "$REPO_ROOT/install.ps1")' -Source '$(cygpath -w "$REPO_ROOT")' -TestMode -TestRoot '$(cygpath -w "$r")' -ScriptedAnswers @(${q%,}); exit \$LASTEXITCODE" \
      </dev/null > "$r/out.txt" 2>&1
  fi
  echo $?
}

# norm <root> <file> : timestamps, the sandbox root (three spellings), random
# identities and commit hashes normalised; BOM and CR removed.
norm() {
  local r="$1" f="$2" w m
  w="$(cygpath -w "$r" 2>/dev/null || printf '%s' "$r")"; m="$(cygpath -m "$r" 2>/dev/null || printf '%s' "$r")"
  sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' \
      -e "s#$(printf '%s' "$w" | sed 's/[\\.]/\\&/g')#<ROOT>#g" -e "s#$(printf '%s' "$m" | sed 's/[.]/\\&/g')#<ROOT>#g" -e "s#$r#<ROOT>#g" \
      -e 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[T ][0-9]\{2\}:[0-9]\{2\}\(:[0-9]\{2\}\)\{0,1\}\(\.[0-9]*\)\{0,1\}\([+-][0-9]\{2\}:\{0,1\}[0-9]\{2\}\|Z\)\{0,1\}/<TS>/g' \
      -e 's/sb-[0-9a-f]\{16\}/<VID>/g' -e 's/pp-[0-9a-f]\{12\}/<CANARY>/g' -e 's/\b[0-9a-f]\{7,40\}\b/<HEX>/g' \
      "$r/workspace/$f" | recent_unordered
}
# recent_unordered : the « Documents récents » section of STATE.md/DIGEST.md is
# ordered by modification time (tools/build-state.sh, `ls -t`), and two files
# written within the same few milliseconds swap places from run to run
# (measured, Mission 220: 0 ns apart in one run, 3.5 ms in the other). Its
# lines are compared as a set; every other line keeps its place.
recent_unordered() {
  awk '
    /^## / { sec = ($0 ~ /^## (Documents récents|Recent documents|Documentos recientes)/) ? NR : 0; printf "%08d\t%s\n", NR, $0; next }
    sec    { printf "%08d~%s\t%s\n", sec, $0, $0; next }
           { printf "%08d\t%s\n", NR, $0 }
  ' | LC_ALL=C sort -t "$(printf '\t')" -k1,1 | cut -f2-
}
files_of() { (cd "$1/workspace" && find . -path '*/.git' -prune -o -type f -print | grep -v -E '/\.git/|/\.install/|__pycache__|\.pyc$' | LC_ALL=C sort); }

check_platform() {
  local p="$1" R="$TMP/$1" rc log n
  echo "=== $p ($( [ "$p" = W ] && echo install.ps1 || echo install.sh)) ==="

  if want_case a; then
  # (a) gum branch
  mkdir -p "$R/a"; fakes "$R/a"
  rc="$(run "$p" "$R/a" tty)"
  n="$(grep -c '^input	' "$R/a/gum.log")"
  if [ "$rc" = 0 ] && [ "$n" = 9 ]; then
    pass "(a) $p : forced TTY + fake gum -> gum branch, 9 'gum input' calls (rc=$rc)"
  else
    fail "(a) $p : rc=$rc, $n 'gum input' call(s) [$(tail -3 "$R/a/out.txt" | tr '\n' ' ' | cut -c1-240)]"
  fi
  local want=("Language / Langue / Idioma" "$(sed -n 's/^  "questionnaire.assistantName.prompt": "\(.*\)",$/\1/p' "$REPO_ROOT/i18n/catalog.fr.json")" \
    "$(sed -n 's/^  "questionnaire.workspace.prompt": "\(.*\)",$/\1/p' "$REPO_ROOT/i18n/catalog.fr.json")" \
    "$(sed -n 's/^  "questionnaire.firstName.prompt": "\(.*\)",$/\1/p' "$REPO_ROOT/i18n/catalog.fr.json")" \
    "$(sed -n 's/^  "questionnaire.activity.prompt": "\(.*\)",$/\1/p' "$REPO_ROOT/i18n/catalog.fr.json")" \
    "Comment travailles-tu avec l'IA" \
    "$(sed -n 's/^  "questionnaire.whatMatters.prompt": "\(.*\)",$/\1/p' "$REPO_ROOT/i18n/catalog.fr.json")" \
    "$(sed -n 's/^  "questionnaire.firstProject.prompt": "\(.*\)",$/\1/p' "$REPO_ROOT/i18n/catalog.fr.json")" \
    "$(sed -n 's/^  "questionnaire.firstProject.namePrompt": "\(.*\)",$/\1/p' "$REPO_ROOT/i18n/catalog.fr.json")")
  local i=0 ok=1 line
  while IFS= read -r line; do
    case "$line" in input*) ;; *) continue ;; esac
    case "$line" in *"${want[$i]}"*) ;; *) ok=0; echo "    order: call $((i + 1)) '$(printf '%s' "$line" | cut -c1-80)' lacks '${want[$i]}'" ;; esac
    i=$((i + 1))
  done < "$R/a/gum.log"
  [ "$ok" = 1 ] && [ "$i" = 9 ] && pass "(a) $p : the nine questions, in the questionnaire's order" || fail "(a) $p : order of the gum calls"

  fi
  if want_case b; then
  # (b) the same files through gum and through the plain questionnaire
  mkdir -p "$R/b"
  rc="$(run_scripted "$p" "$R/b")"
  local diffs=0 same=0 f
  if [ "$rc" = 0 ]; then
    if ! diff <(files_of "$R/a") <(files_of "$R/b") > "$TMP/list.diff"; then diffs=$((diffs + 1)); echo "    file lists differ: $(head -4 "$TMP/list.diff" | tr '\n' ' ')"; fi
    while IFS= read -r f; do
      if cmp -s <(norm "$R/a" "$f") <(norm "$R/b" "$f"); then same=$((same + 1))
      else diffs=$((diffs + 1)); echo "    DIFF $f: $(diff <(norm "$R/a" "$f") <(norm "$R/b" "$f") | head -3 | tr '\n' ' ' | cut -c1-200)"; fi
    done < <(comm -12 <(files_of "$R/a") <(files_of "$R/b"))
  fi
  [ "$rc" = 0 ] && [ "$diffs" = 0 ] && pass "(b) $p : gum and plain questionnaire write the same files ($same identical after normalisation, 0 different)" \
    || fail "(b) $p : plain run rc=$rc, $diffs file(s) different ($same identical)"
  grep -q "La simplicité" "$R/a/workspace/second-brain/USER.md" && grep -q "La simplicité" "$R/b/workspace/second-brain/USER.md" \
    && pass "(b) $p : « La simplicité » written with its accent by both branches" \
    || fail "(b) $p : accented answer not written as is [$(grep -a 'compte' "$R/a/workspace/second-brain/USER.md" | head -1)]"

  fi
  if want_case c; then
  # (c) no gum, installer fails -> fallback
  mkdir -p "$R/c"; fakes "$R/c"; nogum "$R/c"
  rc="$(run "$p" "$R/c" tty)"
  log="$(cat "$R/c/installer.log")"
  local expect_inst="winget"; [ "$HOST_OS" = mac ] && [ "$p" = B ] && expect_inst="brew"
  if [ "$HOST_OS" = linux ] && [ "$p" = B ]; then
    [ -z "$log" ] && pass "(c) $p : Linux, no installer tried" || fail "(c) $p : an installer was called on Linux: $log"
  else
    printf '%s' "$log" | grep -q "^$expect_inst install.*charmbracelet.gum\|^$expect_inst install gum" \
      && pass "(c) $p : the fake $expect_inst was tried (and only it: fake, under the test root)" \
      || fail "(c) $p : installer log '$log'"
  fi
  [ "$rc" = 0 ] && pass "(c) $p : rc=0 after the fallback" || fail "(c) $p : rc=$rc [$(tail -3 "$R/c/out.txt" | tr '\n' ' ' | cut -c1-240)]"
  local fb n_fb=0 t_fb
  fb="$(fallback_texts)"
  if [ -n "$fb" ]; then
    while IFS= read -r t_fb; do
      [ -n "$t_fb" ] && n_fb=$((n_fb + $(grep -cF -- "$t_fb" "$R/c/out.txt")))
    done <<EOF_FB
$fb
EOF_FB
  fi
  [ "$n_fb" = 1 ] && [ ! -s "$R/c/gum.log" ] \
    && pass "(c) $p : exactly one fallback line (catalogue install.gum.fallback), no gum call" \
    || fail "(c) $p : $n_fb fallback line(s) from the catalogue, gum log '$(head -c 80 "$R/c/gum.log")'"

  fi
  if want_case d; then
  # (d) answers file -> no call
  mkdir -p "$R/d"; fakes "$R/d"
  run "$p" "$R/d" file workspace >/dev/null
  [ ! -s "$R/d/gum.log" ] && [ ! -s "$R/d/installer.log" ] && pass "(d) $p : answers file -> no gum, no installer call" \
    || fail "(d) $p : gum='$(cat "$R/d/gum.log")' installer='$(cat "$R/d/installer.log")'"

  fi
  if want_case e; then
  # (e) no TTY -> no call
  mkdir -p "$R/e"; fakes "$R/e"
  run "$p" "$R/e" notty workspace >/dev/null
  [ ! -s "$R/e/gum.log" ] && [ ! -s "$R/e/installer.log" ] && pass "(e) $p : no TTY -> no gum, no installer call" \
    || fail "(e) $p : gum='$(cat "$R/e/gum.log")' installer='$(cat "$R/e/installer.log")'"
  fi
}

if [ "$ONLY" != W ]; then check_platform B; fi
if [ "$ONLY" != B ]; then
  if [ "$HOST_OS" = win ] && command -v powershell.exe >/dev/null 2>&1; then check_platform W
  else echo "  SKIP - install.ps1 half: no Windows PowerShell here"; fi
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
