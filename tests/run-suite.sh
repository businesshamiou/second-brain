#!/usr/bin/env bash
# Plays the test suite listed in tests/suite.tsv, the same way on a
# participant's machine, on the Executor's and in CI (Mission 188). CI calls
# this runner (tests/run-suite.ps1 on Windows) instead of listing tests.
#
# usage: bash tests/run-suite.sh [--manifest <file>] [--platform W|U|M] [--shard k/n] [--changed [<ref>]] [--list]
#
# --shard k/n (Mission 189) plays only the lines whose shard column is k;
# it refuses when the manifest's highest shard for this platform is not n,
# so a shard can never be left unplayed by a CI that runs fewer.
#
# --changed [<ref>] (Mission 209) plays only the lines that the files changed
# since <ref> (default origin/main, or HEAD when there is no origin/main)
# call for: "changed" is `git diff --name-only <ref>` (working tree included)
# plus the untracked files. A line is selected when
#   - it is one of the two guardian lines (always played), or
#   - its path is a changed file, or
#   - its path or its origin column contains, case-insensitively, the name
#     without extension of a changed file under tools/, tests/ or .githooks/
#     (generated index files excepted: they name no test), or
#   - tests/suite.tsv, tests/run-suite.sh or tests/run-suite.ps1 changed: the
#     tool that tests is itself touched, so the whole suite is selected.
# It combines with --shard as an intersection. A file no test names selects
# nothing: the runner says so, it never plays the whole suite to be safe. The
# selection is announced on standard error before anything is played.
# Without --changed the behaviour is unchanged.
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
CHANGED=0
CHANGED_REF=""

while [ $# -gt 0 ]; do
  case "$1" in
    --manifest) MANIFEST="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --list) LIST_ONLY=1; shift ;;
    --shard) SHARD="$2"; shift 2 ;;
    --changed)
      CHANGED=1
      # The ref is optional: the next word is one unless it is another option.
      case "${2:-}" in
        ''|--*) shift ;;
        *) CHANGED_REF="$2"; shift 2 ;;
      esac ;;
    *) echo "usage: bash tests/run-suite.sh [--manifest <file>] [--platform W|U|M] [--shard k/n] [--changed [<ref>]] [--list]" >&2; exit 2 ;;
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

# --- --changed (Mission 209): which files changed, which lines they call for ---
GUARDIANS="tools/session-preflight.sh .githooks/pre-commit"
CHANGED_FILES=""
CHANGED_BASES=""
SELECT_ALL=0

if [ "$CHANGED" -eq 1 ]; then
  git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1 \
    || { echo "REFUS : --changed needs a Git checkout: $REPO_ROOT" >&2; exit 2; }
  if [ -z "$CHANGED_REF" ]; then
    if git -C "$REPO_ROOT" rev-parse --verify -q "origin/main^{commit}" >/dev/null 2>&1; then
      CHANGED_REF="origin/main"
    else
      CHANGED_REF="HEAD"
    fi
  fi
  git -C "$REPO_ROOT" rev-parse --verify -q "$CHANGED_REF^{commit}" >/dev/null 2>&1 \
    || { echo "REFUS : --changed: unknown ref '$CHANGED_REF'" >&2; exit 2; }
  # Tracked files that differ from the ref (staged or not), then untracked ones.
  CHANGED_FILES="$( { git -C "$REPO_ROOT" -c core.quotepath=off diff --name-only "$CHANGED_REF" -- ; \
    git -C "$REPO_ROOT" -c core.quotepath=off ls-files --others --exclude-standard; } 2>/dev/null )"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in
      tests/suite.tsv|tests/run-suite.sh|tests/run-suite.ps1) SELECT_ALL=1 ;;
    esac
    case "$f" in
      tools/*|tests/*|.githooks/*)
        b="${f##*/}"
        b="${b%.*}"
        case "$b" in ''|index|index-archive*) continue ;; esac
        CHANGED_BASES="$CHANGED_BASES$(printf '%s' "$b" | tr 'A-Z' 'a-z')
" ;;
    esac
  done <<EOF
$CHANGED_FILES
EOF
fi

is_guardian() {
  local g
  for g in $GUARDIANS; do [ "$1" = "$g" ] && return 0; done
  return 1
}

# changed_selects <path> <origin>: 0 when the line is called for by the change.
changed_selects() {
  local p="$1" o="$2" lc b
  [ "$SELECT_ALL" -eq 1 ] && return 0
  is_guardian "$p" && return 0
  case "
$CHANGED_FILES
" in *"
$p
"*) return 0 ;; esac
  lc="$(printf '%s %s' "$p" "$o" | tr 'A-Z' 'a-z')"
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    case "$lc" in *"$b"*) return 0 ;; esac
  done <<EOF
$CHANGED_BASES
EOF
  return 1
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

# Announce the selection before anything is played: "N sur M" counts the lines
# of this platform (and shard); a change no test names is said, not hidden.
if [ "$CHANGED" -eq 1 ]; then
  SEL_N=0; SEL_M=0; SEL_TESTS=0
  while IFS="$TAB" read -r path args interp platforms severity origin shard <&4; do
    case "$path" in ''|'#'*) continue ;; esac
    case "$platforms" in *"$PLATFORM"*) ;; *) continue ;; esac
    [ -n "$SHARD_K" ] && [ "${shard:-}" != "$SHARD_K" ] && continue
    SEL_M=$((SEL_M + 1))
    if changed_selects "$path" "$origin"; then
      SEL_N=$((SEL_N + 1))
      is_guardian "$path" || SEL_TESTS=$((SEL_TESTS + 1))
    fi
  done 4< "$MANIFEST"
  echo "--changed : $SEL_N ligne(s) selectionnee(s) sur $SEL_M (ref $CHANGED_REF)" >&2
  if [ "$SELECT_ALL" -eq 1 ]; then
    echo "--changed : le lanceur ou le manifeste a change : toute la suite est selectionnee" >&2
  elif [ "$SEL_TESTS" -eq 0 ]; then
    echo "--changed : aucun test ne nomme les fichiers changes ; seuls les gardiens jouent" >&2
  fi
fi

while IFS="$TAB" read -r path args interp platforms severity origin shard <&3; do
  case "$path" in ''|'#'*) continue ;; esac
  case "$platforms" in *"$PLATFORM"*) ;; *) continue ;; esac
  [ -n "$SHARD_K" ] && [ "${shard:-}" != "$SHARD_K" ] && continue
  if [ "$CHANGED" -eq 1 ]; then changed_selects "$path" "$origin" || continue; fi
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
