#!/usr/bin/env bash
# Mission 188, T3: what the setup-test-env action leaves behind answers
# without the network, and a missing cache changes only the time it takes.
#
# Oracle (PASS expected, CI only): after the action ran in this job, with
#   uv offline (UV_OFFLINE=1) and every proxy pointed at a closed port, uv
#   answers at the version pinned in tools/prerequisites.lock.json, the
#   managed Python answers, and pre-commit answers at its pinned version.
# Negative control: the action's own setup script, played into an EMPTY
#   directory while offline, fails -- the offline check above is not
#   vacuous. Then, with the network, the same script into that empty
#   directory (a cold cache) installs and gives the same three versions.
#
# Outside CI there is no action to check: the test reports SKIP (exit 77).
#
# usage: bash tests/test-setup-test-env-offline.sh

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETUP="$REPO_ROOT/.github/actions/setup-test-env/setup.sh"
PY=3.12

if [ "${GITHUB_ACTIONS:-}" != "true" ] || [ -z "${RUNNER_TEMP:-}" ]; then
  echo "SKIP (outside CI: the setup-test-env action did not run here)"
  exit 77
fi

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

LOCK="$REPO_ROOT/tools/prerequisites.lock.json"
UV_VERSION="$(sed -n 's#.*"installScriptUrlUnix": *"[^"]*/uv/\([^/]*\)/.*#\1#p' "$LOCK")"
PC_VERSION="$(awk -F'"' '/"preCommit"/ { f = 1 } f && $2 == "version" { print $4; exit }' "$LOCK")"

versions() {
  # $1 = env dir, $2 = uv bin dir. Prints "uv=<v> python=<v> pre-commit=<v>"
  # with the network cut: uv offline and every proxy on a closed port.
  (
    . "$1/env.sh" || exit 1
    export UV_OFFLINE=1
    export HTTP_PROXY=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 ALL_PROXY=http://127.0.0.1:9
    export http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY all_proxy=$ALL_PROXY
    uv_v="$("$2/uv" --version 2>/dev/null | awk '{print $2}')"
    py="$("$2/uv" python find "$PY" 2>/dev/null)"
    py_v="$([ -n "$py" ] && "$py" --version 2>/dev/null | awk '{print $2}')"
    pc_v="$("$1/bin/pre-commit" --version 2>/dev/null | awk '{print $2}')"
    printf 'uv=%s python=%s pre-commit=%s\n' "${uv_v:-none}" "${py_v:-none}" "${pc_v:-none}"
  )
}

echo "=== T3 : the test environment answers offline ==="
WARM="$(versions "$RUNNER_TEMP/sb-test-env" "$RUNNER_TEMP/uv-bin")"
echo "  after the action, offline: $WARM"
case "$WARM" in
  "uv=$UV_VERSION python=$PY."*" pre-commit=$PC_VERSION") pass "uv $UV_VERSION, Python $PY, pre-commit $PC_VERSION answer offline" ;;
  *) fail "offline answers are not the pinned versions (uv $UV_VERSION, Python $PY.x, pre-commit $PC_VERSION): $WARM" ;;
esac

echo "=== negative control: an empty cache ==="
TMP="$(mktemp -d "$RUNNER_TEMP/m188-cold-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

if (
  export HTTP_PROXY=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 ALL_PROXY=http://127.0.0.1:9
  export http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY all_proxy=$ALL_PROXY
  bash "$SETUP" "$TMP/offline-env" "$TMP/offline-uv" "$PY"
) > "$TMP/offline.out" 2>&1; then
  fail "control: setup into an empty directory succeeded with the network cut -- the offline check proves nothing"
else
  pass "control: setup into an empty directory fails with the network cut"
fi

if bash "$SETUP" "$TMP/cold-env" "$TMP/cold-uv" "$PY" > "$TMP/cold.out" 2>&1; then
  COLD="$(versions "$TMP/cold-env" "$TMP/cold-uv")"
  echo "  cold cache, reinstalled: $COLD"
  if [ "$COLD" = "$WARM" ]; then
    pass "control: a cold cache reinstalls the same versions ($COLD)"
  else
    fail "control: cold cache gave '$COLD', warm gave '$WARM'"
  fi
else
  fail "control: setup into an empty directory failed with the network: $(tail -n 3 "$TMP/cold.out" | tr '\n' ' ')"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
