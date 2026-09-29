#!/usr/bin/env bash
# Mission 221, batch J (A-220-1): under `curl ... | bash`, the standard input
# of bootstrap.sh is the pipe that carries the script itself; install.sh used
# to inherit it, so its questions read the rest of the script (or end of
# file) instead of the keyboard. bootstrap.sh now runs install.sh with the
# controlling terminal as its input when its own input is not a terminal and
# that terminal opens; without a terminal (CI, tests) the input is kept.
#
# Simulation (a real terminal cannot be opened by a test): the "keyboard" is a
# file named by SB_BOOTSTRAP_TTY (test-only override of /dev/tty); the source
# repository is a local throwaway one whose install.sh is a stub recording
# the first line it reads. macOS and Linux with a real terminal: HYPOTHESIS
# (door open-221-bootstrap-tty-unproven-macos-linux).
#
# Oracles (PASS expected):
#   (a) `cat bootstrap.sh | bash -s -- ...` (the published shape), keyboard
#       present: install.sh reads the keyboard line;
#   (b) standard input piped, keyboard present: install.sh reads the keyboard;
#   (c) witness: keyboard absent (no terminal): install.sh reads the pipe, as before;
#   (d) witness: with --answers-file, the input is kept as it is.
#
# Writes only in a temporary folder (prefix m221-tty).
#
# usage: bash tests/test-bootstrap-keyboard.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOOT="$REPO_ROOT/bootstrap.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m221-tty-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

# Throwaway source repository: install.sh records the first line it reads.
SRC="$TMP/src"
mkdir -p "$SRC"
cat > "$SRC/install.sh" <<'STUB'
#!/usr/bin/env bash
line=""
IFS= read -r line || true
printf '%s\n' "$line" > "$SB_TEST_STDIN_RECORD"
STUB
(
  cd "$SRC" && git init -q \
    && git config user.email t@t && git config user.name t && git config commit.gpgsign false \
    && git add install.sh && git commit -q -m stub && git tag v-test
) || { echo "FAIL : depot source jetable non construit"; exit 1; }

printf 'KEYBOARD-LINE\n' > "$TMP/keyboard"
export SB_TEST_STDIN_RECORD

N=0
# run_case <tty> <mode> [extra bootstrap args...]: prints the recorded line.
# Runs in a command substitution: the caller increments N before each call.
run_case() {
  local tty="$1" mode="$2"; shift 2
  SB_TEST_STDIN_RECORD="$TMP/record-$N"
  : > "$SB_TEST_STDIN_RECORD"
  if [ "$mode" = "script-on-stdin" ]; then
    tr -d '\r' < "$BOOT" | SB_BOOTSTRAP_TTY="$tty" bash -s -- --ref v-test --repo-url "$SRC" --target "$TMP/target-$N" "$@" >"$TMP/log-$N" 2>&1
  else
    printf 'PIPE-LINE\n' | SB_BOOTSTRAP_TTY="$tty" bash "$BOOT" --ref v-test --repo-url "$SRC" --target "$TMP/target-$N" "$@" >"$TMP/log-$N" 2>&1
  fi
  cat "$SB_TEST_STDIN_RECORD"
}

N=$((N + 1)); GOT="$(run_case "$TMP/keyboard" script-on-stdin)"
if [ "$GOT" = "KEYBOARD-LINE" ]; then
  pass "(a) cat bootstrap.sh | bash -s : install.sh lit le clavier"
else
  fail "(a) cat bootstrap.sh | bash -s : install.sh a lu '$GOT', pas le clavier ($(tail -n 2 "$TMP/log-$N" | tr '\n' ' '))"
fi

N=$((N + 1)); GOT="$(run_case "$TMP/keyboard" piped)"
if [ "$GOT" = "KEYBOARD-LINE" ]; then
  pass "(b) entree en tuyau, clavier present : install.sh lit le clavier"
else
  fail "(b) entree en tuyau, clavier present : install.sh a lu '$GOT'"
fi

N=$((N + 1)); GOT="$(run_case "$TMP/no-terminal-here" piped)"
if [ "$GOT" = "PIPE-LINE" ]; then
  pass "(c) temoin : sans terminal, l'entree courante est gardee"
else
  fail "(c) temoin : sans terminal, install.sh a lu '$GOT'"
fi

printf '{}\n' > "$TMP/answers.json"
N=$((N + 1)); GOT="$(run_case "$TMP/keyboard" piped --answers-file "$TMP/answers.json")"
if [ "$GOT" = "PIPE-LINE" ]; then
  pass "(d) temoin : avec --answers-file, l'entree courante est gardee"
else
  fail "(d) temoin : avec --answers-file, install.sh a lu '$GOT'"
fi

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
