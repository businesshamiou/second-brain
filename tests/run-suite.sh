#!/usr/bin/env bash
# Plays the test suite listed in tests/suite.tsv, the same way on a
# participant's machine, on the Executor's and in CI (Mission 188). CI calls
# this runner (tests/run-suite.ps1 on Windows) instead of listing tests.
#
# usage: bash tests/run-suite.sh [--manifest <file>] [--platform W|U|M] [--shard k/n] [--changed [<ref>]] [--list] [--on-demand]
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
#   (a change to tests/suite.tsv, tests/run-suite.sh or tests/run-suite.ps1 is
#   an ordinary change: it selects the lines whose path or origin carries the
#   name of the file -- `suite`, `run-suite` -- and the lines it adds.)
# --changed NEVER selects the whole suite: the whole suite is played explicitly
# (without --changed), when a Mission prescribes it (Decision 170838); the workstation plays what
# the change touches. It combines with --shard as an intersection. A file no
# test names selects nothing: the runner says so, it never plays the whole
# suite to be safe. The
# selection is announced on standard error before anything is played.
# Without --changed the behaviour is unchanged.
#
# Every line for this platform is played, even after a red one; the run ends
# with one verdict line per test, then
#   RESULT: <pass>/<total> PASS (<skip> SKIP, <n> FAIL blocking, <m> FAIL informational)
# Exit code: 1 if a blocking line is red, 0 otherwise. A test exiting 77
# reports SKIP. Mission 237: every SKIP is then named under the RESULT line,
# with its reason (the test's last line that says SKIP, else its last line);
# a platform letter followed by `!` in the platforms column (`W!UM`) marks the
# test REQUIRED there: its SKIP on that platform is a blocking FAIL.
# Portable to Apple's bash 3.2 (no bash-4 construct).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/tests/suite.tsv"
PLATFORM="${SB_SUITE_PLATFORM:-}"
LIST_ONLY=0
ON_DEMAND=0
SHARD=""
CHANGED=0
CHANGED_REF=""

while [ $# -gt 0 ]; do
  case "$1" in
    --manifest) MANIFEST="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --list) LIST_ONLY=1; shift ;;
    --on-demand) ON_DEMAND=1; shift ;;
    --shard) SHARD="$2"; shift 2 ;;
    --changed)
      CHANGED=1
      # The ref is optional: the next word is one unless it is another option.
      case "${2:-}" in
        ''|--*) shift ;;
        *) CHANGED_REF="$2"; shift 2 ;;
      esac ;;
    *) echo "usage: bash tests/run-suite.sh [--manifest <file>] [--platform W|U|M] [--shard k/n] [--changed [<ref>]] [--list] [--on-demand]" >&2; exit 2 ;;
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

# Declared temporary folder (Mission 234): every test this runner plays writes
# its throwaway files under <SB_TMP>/tests -- TMPDIR for mktemp and Python,
# TEMP/TMP for the PowerShell tests on Windows, SB_TMP for the access function.
# A manifest played from another checkout (the fixture repositories of
# tests/test-run-suite-changed.sh) may carry no tools/lib: the tests then keep
# the TMPDIR they were given.
if [ -f "$REPO_ROOT/tools/lib/tmp.sh" ]; then
  . "$REPO_ROOT/tools/lib/tmp.sh"
  sb_tmp_export tests || exit 2
fi

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

# on_demand_skips <severity> (Mission 234): a line of severity on-demand is
# played only with --on-demand, and --on-demand plays those lines alone --
# never by default, never by CI (the headless agent evaluations call a model).
on_demand_skips() {
  if [ "$1" = "on-demand" ]; then
    [ "$ON_DEMAND" -eq 1 ] && return 1
    return 0
  fi
  [ "$ON_DEMAND" -eq 1 ] && return 0
  return 1
}

is_guardian() {
  local g
  for g in $GUARDIANS; do [ "$1" = "$g" ] && return 0; done
  return 1
}

# changed_selects <path> <origin>: 0 when the line is called for by the change.
changed_selects() {
  local p="$1" o="$2" lc b
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
SKIP_LINES=""
# The output of the line being played, kept to name the reason of a SKIP.
LINE_LOG="$(mktemp "${TMPDIR:-/tmp}/sb-suite-line-XXXXXX")"
trap 'rm -f "$LINE_LOG"' EXIT
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
    on_demand_skips "$severity" && continue
    SEL_M=$((SEL_M + 1))
    if changed_selects "$path" "$origin"; then
      SEL_N=$((SEL_N + 1))
      is_guardian "$path" || SEL_TESTS=$((SEL_TESTS + 1))
    fi
  done 4< "$MANIFEST"
  echo "--changed : $SEL_N ligne(s) selectionnee(s) sur $SEL_M (ref $CHANGED_REF)" >&2
  if [ "$SEL_TESTS" -eq 0 ]; then
    echo "--changed : aucun test ne nomme les fichiers changes ; seuls les gardiens jouent" >&2
  fi
fi

while IFS="$TAB" read -r path args interp platforms severity origin shard <&3; do
  case "$path" in ''|'#'*) continue ;; esac
  case "$platforms" in *"$PLATFORM"*) ;; *) continue ;; esac
  [ -n "$SHARD_K" ] && [ "${shard:-}" != "$SHARD_K" ] && continue
  on_demand_skips "$severity" && continue
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
  run_line "$path" "$interp" $args < /dev/null 2>&1 | tee "$LINE_LOG"
  rc=${PIPESTATUS[0]}
  secs=$(( $(date +%s) - start ))
  [ "$IN_CI" -eq 1 ] && echo "::endgroup::"
  if [ "$rc" -eq 0 ]; then
    verdict=PASS
    PASSED=$((PASSED + 1))
  elif [ "$rc" -eq 77 ]; then
    reason="$(tr -d '\r' < "$LINE_LOG" | grep -i 'skip' | grep -v '^--- ' | tail -n 1)"
    [ -n "$reason" ] || reason="$(tr -d '\r' < "$LINE_LOG" | sed '/^[[:space:]]*$/d' | tail -n 1)"
    reason="$(printf '%s' "$reason" | sed 's/^[[:space:]]*//' | cut -c1-200)"
    # The requirement is enforced on a workstation; the CI runners carry
    # neither gum pinned nor tui-test (the gum test downloads nothing), so in
    # CI a required SKIP stays a SKIP, named as such.
    req="$platforms"
    [ "$IN_CI" -eq 1 ] && req=""
    case "$platforms" in
      *"$PLATFORM!"*) [ -z "$req" ] && reason="$reason (required on $PLATFORM, not enforced in CI)" ;;
    esac
    case "$req" in
      *"$PLATFORM!"*)
        verdict="FAIL (required, skipped)"
        FAIL_BLOCKING=$((FAIL_BLOCKING + 1))
        SKIP_LINES="${SKIP_LINES}SKIP (required on $PLATFORM, counted FAIL): $label -- $reason
"
        [ "$IN_CI" -eq 1 ] && echo "::error::$label is required on $PLATFORM and skipped" ;;
      *)
        verdict=SKIP
        SKIPPED=$((SKIPPED + 1))
        SKIP_LINES="${SKIP_LINES}SKIP: $label -- $reason
" ;;
    esac
  elif [ "$severity" = "informational" ] || [ "$severity" = "on-demand" ]; then
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
[ -n "$SKIP_LINES" ] && printf '%s' "$SKIP_LINES"
if [ "$TOTAL" -eq 0 ]; then
  echo "REFUS : no line for platform $PLATFORM in $MANIFEST"
  exit 1
fi
[ "$FAIL_BLOCKING" -eq 0 ]
