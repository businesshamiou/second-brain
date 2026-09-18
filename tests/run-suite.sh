#!/usr/bin/env bash
# Plays the test suite listed in tests/suite.tsv, the same way on a
# participant's machine, on the Executor's and in CI (Mission 188). CI calls
# this runner (tests/run-suite.ps1 on Windows) instead of listing tests.
#
# usage: bash tests/run-suite.sh [--manifest <file>] [--platform W|U|M] [--shard k/n] [--list]
#
# --shard k/n (Mission 189) plays only the lines whose shard column is k;
# it refuses when the manifest's highest shard for this platform is not n,
# so a shard can never be left unplayed by a CI that runs fewer.
#
# Every line for this platform is played, even after a red one; the run ends
# with one verdict line per test, then
#   RESULT: <pass>/<total> PASS (<skip> SKIP, <n> FAIL blocking, <m> FAIL informational)
# Exit code: 1 if a blocking line is red, 0 otherwise. A test exiting 77
# reports SKIP. Portable to Apple's bash 3.2 (no bash-4 construct).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/tests/suite.tsv"
PLATFORM="${SB_SUITE_PLATFORM:-}"
LIST_ONLY=0
SHARD=""

while [ $# -gt 0 ]; do
  case "$1" in
    --manifest) MANIFEST="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --list) LIST_ONLY=1; shift ;;
    --shard) SHARD="$2"; shift 2 ;;
    *) echo "usage: bash tests/run-suite.sh [--manifest <file>] [--platform W|U|M] [--shard k/n] [--list]" >&2; exit 2 ;;
  esac
done

if [ -z "$PLATFORM" ]; then
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) PLATFORM=W ;;
    Darwin) PLATFORM=M ;;
    *) PLATFORM=U ;;
  esac
fi
case "$PLATFORM" in
  W|U|M) ;;
  *) echo "REFUS : platform '$PLATFORM' is not W, U or M" >&2; exit 2 ;;
esac
[ -f "$MANIFEST" ] || { echo "REFUS : manifest not found: $MANIFEST" >&2; exit 2; }
SHARD_K=""
if [ -n "$SHARD" ]; then
  SHARD_K="${SHARD%/*}"; SHARD_N="${SHARD#*/}"
  case "$SHARD_K$SHARD_N" in *[!0-9]*|"") echo "REFUS : --shard expects k/n, got '$SHARD'" >&2; exit 2 ;; esac
  MAX_SHARD="$(awk -F'	' -v p="$PLATFORM" '!/^#/ && NF && index($4, p) && $7 ~ /^[0-9]+$/ && $7 + 0 > m { m = $7 + 0 } END { print m + 0 }' "$MANIFEST")"
  if [ "$MAX_SHARD" != "$SHARD_N" ]; then
    echo "REFUS : --shard $SHARD, but the manifest splits platform $PLATFORM into $MAX_SHARD shard(s)" >&2
    exit 2
  fi
fi

cd "$REPO_ROOT" || exit 2

# The two helpers below keep PATH changes inside the line that needs them,
# exactly as the former CI steps did: only the guardians and the uv-run test
# ever saw uv prepended.
UV_PRELUDE='. tests/sandbox-vault.sh; sandbox_find_uv || { echo "REFUS : uv introuvable"; exit 1; }'

run_line() {
  # $1 = path, $2 = interpreter, rest = arguments
  local path="$1" interp="$2"
  shift 2
  case "$interp" in
    bash) bash "$path" "$@" ;;
    bash+uv) bash -c "$UV_PRELUDE; f=\"\$1\"; shift; bash \"\$f\" \"\$@\"" run-suite "$path" "$@" ;;
    uv-python) bash -c "$UV_PRELUDE; uv run --no-project \"\$@\"" run-suite "$path" "$@" ;;
    ps1)
      if [ "$PLATFORM" = W ]; then
        powershell -NoProfile -ExecutionPolicy Bypass -File "$path" "$@"
      else
        pwsh -NoProfile -File "$path" "$@"
      fi ;;
    *) echo "REFUS : unknown interpreter '$interp' for $path"; return 2 ;;
  esac
}

TAB="$(printf '\t')"
TOTAL=0
PASSED=0
SKIPPED=0
FAIL_BLOCKING=0
FAIL_INFO=0
VERDICTS=""
IN_CI=0
[ "${GITHUB_ACTIONS:-}" = "true" ] && IN_CI=1

while IFS="$TAB" read -r path args interp platforms severity origin shard <&3; do
  case "$path" in ''|'#'*) continue ;; esac
  case "$platforms" in *"$PLATFORM"*) ;; *) continue ;; esac
  [ -n "$SHARD_K" ] && [ "${shard:-}" != "$SHARD_K" ] && continue
  [ "$args" = "-" ] && args=""
  TOTAL=$((TOTAL + 1))
  label="$path${args:+ $args}"
  if [ "$LIST_ONLY" -eq 1 ]; then
    printf '%s\t%s\t%s\n' "$label" "$interp" "$severity"
    continue
  fi
  if [ "$IN_CI" -eq 1 ]; then
    echo "::group::[$TOTAL] $label ($severity)"
  else
    echo "=== [$TOTAL] $label ($interp, $severity) ==="
  fi
  echo "    $origin"
  start="$(date +%s)"
  # shellcheck disable=SC2086 -- args is a plain word list from the manifest
  run_line "$path" "$interp" $args < /dev/null
  rc=$?
  secs=$(( $(date +%s) - start ))
  [ "$IN_CI" -eq 1 ] && echo "::endgroup::"
  if [ "$rc" -eq 0 ]; then
    verdict=PASS
    PASSED=$((PASSED + 1))
  elif [ "$rc" -eq 77 ]; then
    verdict=SKIP
    SKIPPED=$((SKIPPED + 1))
  elif [ "$severity" = "informational" ]; then
    verdict="FAIL (informational)"
    FAIL_INFO=$((FAIL_INFO + 1))
  else
    verdict="FAIL"
    FAIL_BLOCKING=$((FAIL_BLOCKING + 1))
    [ "$IN_CI" -eq 1 ] && echo "::error::$label failed (exit $rc)"
  fi
  echo "--- $verdict ($rc) ${secs}s $label"
  VERDICTS="$VERDICTS$(printf '%-22s %5ss  %s' "$verdict" "$secs" "$label")
"
done 3< "$MANIFEST"

[ "$LIST_ONLY" -eq 1 ] && exit 0

echo ""
echo "=== SUITE ($PLATFORM${SHARD:+, shard $SHARD}, $(basename "$MANIFEST")) ==="
printf '%s' "$VERDICTS"
echo "RESULT: $PASSED/$TOTAL PASS ($SKIPPED SKIP, $FAIL_BLOCKING FAIL blocking, $FAIL_INFO FAIL informational)"
if [ "$TOTAL" -eq 0 ]; then
  echo "REFUS : no line for platform $PLATFORM in $MANIFEST"
  exit 1
fi
[ "$FAIL_BLOCKING" -eq 0 ]
