#!/usr/bin/env bash
# A-226-20 (Mission 230): running install.sh again on an installation that is
# already complete must reach update mode, not die on an unbound variable.
#
# install.sh runs under `set -u`. Its update-mode gate required
# `$STEP_ASSISTANTDEPLOYED` and `$STEP_SKILLSDEPLOYED`, two carnet flags
# Mission 173 retired outright (nothing is deployed to the profile any more:
# the assistant and the method skills are linked into each project instead).
# `sb_installer_helper.py load-carnet` has not exported them since, so those
# two names are never set -- and `set -u` kills the script the moment the gate
# reaches them. The `&&` chain short-circuits before them unless every earlier
# step is "true", which is exactly what a COMPLETE installation looks like: the
# defect only bites the participant who re-runs the installer, which is the
# one thing the published line tells them to do.
#
# install.ps1 does not have it: its own gate (`Test-InstallComplete`,
# tools/questionnaire.ps1) dropped both names when Mission 173 retired them.
#
#   (a) a complete installation, made with --answers-file at the default
#       workspace of --test-root;
#   (b) the carnet records the six steps the gate reads, and neither of the
#       two retired ones;
#   (c) the re-run, interactive (scripted answers, so gum stays out of it):
#       exit 0, update mode reached, the "nothing changed" answer touches
#       nothing -- and no "unbound variable" anywhere in the output;
#   (d) the clone is left clean by the re-run.
#
# Everything lives under --test-root: the real profile is never touched.
#
# usage: bash tests/test-install-rerun-after-complete.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}
has() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m230-rerun-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

echo "=== A-226-20 : relancer l'installateur sur une installation terminee ==="

TEST_ROOT="$TMP/root"
mkdir -p "$TEST_ROOT"
WS="$TEST_ROOT/workspace"
CLONE="$WS/second-brain"
CARNET="$CLONE/.install/state.json"

# --- (a) a complete installation at the default workspace of --test-root -------
ANSWERS="$TMP/answers.json"
uv run --no-project - "$REPO_ROOT/tests/fixtures/install-answers.sample.json" "$ANSWERS" "$WS" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
data["workspacePath"] = sys.argv[3]
json.dump(data, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY
OUT_A="$(bash "$REPO_ROOT/install.sh" --source "$REPO_ROOT" --answers-file "$ANSWERS" \
  --test-mode --test-root "$TEST_ROOT" 2>&1)"
RC_A=$?
if [ "$RC_A" != "0" ]; then
  printf '%s\n' "$OUT_A" | tail -n 20 | sed 's/^/    /'
fi
check "(a) installation : sortie 0" [ "$RC_A" = "0" ]
check "(a) installation : le clone et le carnet sont la" sh -c "[ -d '$CLONE/.git' ] && [ -f '$CARNET' ]"

# --- (b) the carnet: the six steps the gate reads, and neither retired one -----
if [ -f "$CARNET" ]; then
  STEPS="$(uv run --no-project "$REPO_ROOT/tools/sb_installer_helper.py" load-carnet "$CARNET" | grep '^STEP_')"
  printf '%s\n' "$STEPS" | sed 's/^/    /'
  check "(b) les six etapes du verrou sont a true" sh -c "
    for s in WORKSPACECREATED CLONED GUARDIANSCONFIGURED MARKERWRITTEN ASSISTANTGENERATED PROFILEWRITTEN; do
      printf '%s\n' \"\$1\" | grep -q \"^STEP_\$s='true'\" || exit 1
    done" _ "$STEPS"
  check "(b) aucune des deux etapes retirees par la Mission 173 n'est exportee" sh -c "
    ! printf '%s\n' \"\$1\" | grep -qE '^STEP_(ASSISTANTDEPLOYED|SKILLSDEPLOYED)='" _ "$STEPS"
else
  fail "(b) carnet absent"
fi

# --- (c) the re-run, interactive ------------------------------------------------
# Scripted answers keep gum out of it (sb_gum_init returns at once when any is
# given): the language, then "no, nothing changed".
OUT_C="$(bash "$REPO_ROOT/install.sh" --source "$REPO_ROOT" --test-mode --test-root "$TEST_ROOT" \
  --scripted-answers "FR" --scripted-answers "n" 2>&1)"
RC_C=$?
printf '%s\n' "$OUT_C" | tail -n 6 | sed 's/^/    /'
check "(c) relance : sortie 0" [ "$RC_C" = "0" ]
check "(c) relance : aucune « unbound variable »" sh -c "
  ! printf '%s\n' \"\$1\" | grep -qi 'unbound variable'" _ "$OUT_C"
check "(c) relance : le mode mise a jour est atteint (reponses rappelees)" sh -c "
  printf '%s\n' \"\$1\" | grep -q 'workspacePath='" _ "$OUT_C"

# --- (d) nothing left behind ------------------------------------------------------
check "(d) le clone est propre apres la relance" sh -c "
  [ -z \"\$(git -C '$CLONE' status --porcelain 2>/dev/null)\" ]"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
