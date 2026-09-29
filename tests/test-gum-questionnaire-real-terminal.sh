#!/usr/bin/env bash
# Mission 230, step 7 (Owner, 2026-09-25 13:35): the gum questionnaire, run for
# real, in a REAL terminal, and recorded.
#
# tests/test-install-gum-branch.sh proves the gum branch with a FAKE gum and a
# forced TTY, because no test in this suite has a terminal. This one opens one:
# @microsoft/tui-test (Microsoft, MIT) drives a pseudo-terminal, so the real
# `gum input` draws its nine screens and the real installer reads them back.
#
# It runs ONLY when gum AND tui-test are both there, and it downloads nothing:
#   - gum: on the PATH, or winget's package folder (where the installer itself
#     looks on Windows), or $SB_GUM;
#   - tui-test: $SB_TUI_TEST (the `tui-test` executable of a pinned install),
#     else <profile>/.local/share/second-brain/tui-test (Mission 237: the
#     durable default, next to the other tools of the participant), else a
#     `tui-test` on the PATH.
# Missing either one: SKIP, exit 77, cause printed. A participant has neither,
# and CI installs neither: this test is the maintainer's, run on a machine
# that carries them.
#
# What it proves:
#   (a) the nine screens are drawn by gum, in the questionnaire's order --
#       measured by waiting for each one before answering it, never by
#       replaying a script;
#   (b) the accented answer « La simplicité » reaches USER.md BYTE FOR BYTE
#       (the bytes are compared, not a normalised form);
#   (c) the last sentence of the installer is there, with the assistant's
#       signature;
#   (d) a recording is left for the Owner to watch, and its path is printed.
#
# Everything is written under $SB_GUM_WORKDIR (default: %TEMP%/m230/gum-run):
# the sandbox, the tui-test project, the recording. The real profile is never
# touched -- the installer runs with --test-mode --test-root.
#
# usage: bash tests/test-gum-questionnaire-real-terminal.sh
#        SB_TUI_TEST=<path to tui-test> bash tests/...
# Exit 0: PASS. Exit 77: SKIP (gum or tui-test absent). Exit 1: FAIL.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}
skip_out() {
  echo "  SKIP - $1"
  echo ""
  echo "=== RESULT: SKIP ==="
  exit 77
}

echo "=== M230 : le questionnaire gum dans un vrai terminal ==="

# --- gum: the very lookup the installer does ------------------------------------
find_gum() {
  local p
  if [ -n "${SB_GUM:-}" ] && [ -x "${SB_GUM}" ]; then printf '%s' "$SB_GUM"; return 0; fi
  p="$(command -v gum 2>/dev/null)" && { printf '%s' "$p"; return 0; }
  if [ -n "${LOCALAPPDATA:-}" ] && command -v cygpath >/dev/null 2>&1; then
    for p in "$(cygpath -u "$LOCALAPPDATA")"/Microsoft/WinGet/Packages/charmbracelet.gum_*/*/gum.exe; do
      [ -f "$p" ] && { printf '%s' "$p"; return 0; }
    done
  fi
  return 1
}
GUM="$(find_gum)" || skip_out "gum est absent de ce poste : le questionnaire gum ne peut pas etre joue (aucun telechargement n'est fait ici)"
echo "  gum      : $GUM ($("$GUM" --version 2>/dev/null | head -n 1))"

# --- tui-test: pinned, never installed by this test --------------------------------
find_tui_test() {
  local p
  if [ -n "${SB_TUI_TEST:-}" ] && [ -f "${SB_TUI_TEST}" ]; then printf '%s' "$SB_TUI_TEST"; return 0; fi
  # Mission 237: the durable default, in the tools folder the prerequisites
  # already use (<profile>/.local/share/second-brain), never under SB_TMP.
  p="${USERPROFILE:-$HOME}/.local/share/second-brain/tui-test/node_modules/.bin/tui-test"
  p="$(printf '%s' "$p" | tr '\\' '/')"
  [ -f "$p" ] && { printf '%s' "$p"; return 0; }
  p="$(command -v tui-test 2>/dev/null)" && { printf '%s' "$p"; return 0; }
  return 1
}
TUI="$(find_tui_test)" || skip_out "tui-test est absent : pose SB_TUI_TEST=<chemin de tui-test> (version figee, installee hors de ce test) -- rien n'est telecharge ici"
command -v node >/dev/null 2>&1 || skip_out "node est absent : tui-test ne peut pas tourner"
echo "  tui-test : $TUI ($("$TUI" --version 2>/dev/null | tr -d '\r' | head -n 1))"

BASH_EXE="$(command -v bash)"
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*) BASH_FOR_PTY="$(cygpath -w "$BASH_EXE")" ;;
  *) BASH_FOR_PTY="$BASH_EXE" ;;
esac

# --- Work folder ----------------------------------------------------------------------
if [ -n "${SB_GUM_WORKDIR:-}" ]; then
  WORK="$SB_GUM_WORKDIR"
else
  # Mission 234: under the declared temporary folder (tools/lib/tmp.sh).
  . "$REPO_ROOT/tools/lib/tmp.sh"
  WORK="$(sb_tmp_dir tests)/m230-gum-run"
fi
rm -rf "$WORK/sandbox" "$WORK/recording" 2>/dev/null
mkdir -p "$WORK/sandbox" "$WORK/recording" || { echo "FAIL : dossier de travail non cree : $WORK"; exit 1; }
WORK="$(cd "$WORK" && pwd)"
TEST_ROOT="$WORK/sandbox/root"
mkdir -p "$TEST_ROOT"
echo "  travail  : $WORK"

# The tui-test project lives INSIDE the pinned install's own folder, next to
# its node_modules: Node resolves `@microsoft/tui-test` by walking up from the
# test file, so nothing is linked and nothing is copied (a junction under
# %TEMP% could not be removed afterwards -- measured). Only the recording and
# the sandbox live under the work folder; nothing is ever written into this
# repository.
TUI_HOME="$(cd "$(dirname "$TUI")/../.." 2>/dev/null && pwd)"
[ -n "$TUI_HOME" ] && [ -d "$TUI_HOME/node_modules/@microsoft/tui-test" ] \
  || skip_out "les modules de tui-test sont introuvables au-dessus de $TUI : pose SB_TUI_TEST sur le tui-test d'une installation npm (node_modules/.bin/tui-test)"
PROJECT="$TUI_HOME/m230-gum-run"
rm -rf "$PROJECT" 2>/dev/null
mkdir -p "$PROJECT" || skip_out "le dossier de l'installation tui-test n'est pas inscriptible : $TUI_HOME"
# The versioned fixture keeps its explicit name; the copy takes the one
# tui-test's default testMatch expects (`*.test.mjs`).
cp "$REPO_ROOT/tests/fixtures/gum-questionnaire.tui-test.mjs" "$PROJECT/gum-questionnaire.test.mjs"
printf '{ "name": "m230-gum-run", "private": true, "type": "module" }\n' > "$PROJECT/package.json"
cat > "$PROJECT/tui-test.config.js" <<'CONFIG'
// Mission 230: one test, one try, generous timeouts -- the installer checks
// its prerequisites (~45 s measured), clones a Vault and creates a project
// between two screens.
export default {
  timeout: 1200000,
  expect: { timeout: 300000 },
  retries: 0,
  trace: true,
  workers: 1,
};
CONFIG

# --- The run -----------------------------------------------------------------------------
export SB_GUM_BASH="$BASH_FOR_PTY"
export SB_GUM_REPO="$REPO_ROOT"
export SB_GUM_TEST_ROOT="$TEST_ROOT"
export SB_GUM_OUT="$WORK/recording"
echo "  lancement de tui-test (l'installation complete tourne dans le pseudo-terminal)..."
OUT="$(cd "$PROJECT" && "$TUI" 2>&1)"
RC=$?
printf '%s\n' "$OUT" | tail -n 25 | sed 's/^/    /'

check "(a) tui-test : sortie 0" [ "$RC" = "0" ]
SEEN="$WORK/recording/screens-seen.json"
# node reads a native path, never the shell's POSIX one: the file is handed to
# it on stdin, so no conversion is needed and nothing depends on the spelling.
seen_in_order() {
  [ -f "$SEEN" ] || return 1
  node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const d=JSON.parse(s);process.exit(JSON.stringify(d.seen)===JSON.stringify(d.expected)&&d.seen.length===9?0:1)})' < "$SEEN"
}
check "(a) les neuf ecrans ont ete vus, dans l'ordre du questionnaire" seen_in_order
if [ -f "$SEEN" ]; then
  echo "    ecrans : $(node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).seen.join(" -> ")))' < "$SEEN" 2>/dev/null)"
fi

# --- (b) the accented answer, byte for byte in USER.md --------------------------------------
USER_MD="$TEST_ROOT/workspace/second-brain/USER.md"
check "(b) USER.md a ete ecrit par le questionnaire" sh -c "[ -f '$USER_MD' ]"
if [ -f "$USER_MD" ]; then
  # The bytes of « La simplicité » in UTF-8, written here as bytes, so the
  # comparison cannot be softened by anything this shell does to the string.
  printf 'La simplicit\303\251' > "$WORK/expected-accented.bin"
  check "(b) « La simplicité » est dans USER.md, a l'octet (UTF-8, pas une forme normalisee)" sh -c "
    grep -F -q -f '$WORK/expected-accented.bin' '$USER_MD'"
  check "(b) aucune forme abimee (« simplicitÃ© », « simplicit? », « simplicite »)" sh -c "
    ! grep -q -e 'simplicitÃ' -e 'simplicit?' '$USER_MD' && ! grep -q 'La simplicite' '$USER_MD'"
  check "(b) les autres reponses du questionnaire sont dans USER.md" sh -c "
    grep -q 'Ana' '$USER_MD' && grep -q 'Construire un syst' '$USER_MD' && grep -q 'Brian' '$USER_MD'"
  echo "    USER.md : $(sed -n 's/^- \*\*Ce qui compte :\*\* //p' "$USER_MD" | head -n 1)"
fi

# --- (c) the last sentence ------------------------------------------------------------------
SCREENS="$WORK/recording/screens.txt"
check "(c) la phrase finale et la signature sont a l'ecran" sh -c "
  [ -f '$SCREENS' ] && grep -q 'Installé, tout est en place.' '$SCREENS' && grep -q '— Brian' '$SCREENS'"

# --- (d) the recording ------------------------------------------------------------------------
CAST="$WORK/recording/gum-questionnaire.cast"
check "(d) l'enregistrement asciinema est depose" sh -c "[ -s '$CAST' ]"
check "(d) l'enregistrement est un asciinema v2 lisible" sh -c "
  head -n 1 '$CAST' | node -e \"let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const h=JSON.parse(s);process.exit(h.version===2&&h.width>0?0:1)})\""
nat() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1" 2>/dev/null || printf '%s' "$1"; else printf '%s' "$1"; fi
}
if [ -s "$CAST" ]; then
  echo ""
  echo "  Enregistrement a regarder : $(nat "$CAST")"
  echo "    asciinema play \"$CAST\"   (ou un lecteur asciinema)"
  echo "  Ecrans en texte           : $(nat "$SCREENS")"
  echo "  Trace tui-test            : $(nat "$PROJECT/tui-traces") (tui-test show-trace)"
fi

# --- SKIP proved without gum --------------------------------------------------------------------
# The same script, with gum hidden: it must SKIP (77) and run nothing.
EMPTY_BIN="$WORK/no-gum-bin"
mkdir -p "$EMPTY_BIN"
SKIP_OUT="$(PATH="$EMPTY_BIN" LOCALAPPDATA= SB_GUM= SB_TUI_TEST="$TUI" \
  "$BASH_EXE" "$REPO_ROOT/tests/test-gum-questionnaire-real-terminal.sh" 2>&1)"
SKIP_RC=$?
check "(e) sans gum : SKIP explicite, sortie 77" sh -c "
  [ '$SKIP_RC' = '77' ] || exit 1
  case \"\$1\" in *'RESULT: SKIP'*) exit 0 ;; *) exit 1 ;; esac" _ "$SKIP_OUT"
check "(e) sans gum : la cause est dite" sh -c "
  case \"\$1\" in *'gum est absent'*) exit 0;; *) exit 1;; esac" _ "$SKIP_OUT"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
