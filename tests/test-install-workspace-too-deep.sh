#!/usr/bin/env bash
# Mission 221, batch D (A-219-1): an installation in a workspace folder so deep
# that its deepest file passes the Windows path limit (259 characters) used to
# fail half-way, at the marker step (report 219: Python does not read the
# longest paths, the regenerated index loses them, the freshness guardian
# refuses). install.sh now refuses such a root at once, before writing
# anything in it, with the catalogue message that gives the measured length
# and the maximum. The maximum is 259 - 1 - (second-brain/ + the longest
# tracked Markdown file outside skills-warehouse/): 118 characters on the
# tree measured by Mission 221 (118 installs, 119 stops at the marker step).
# macOS and Linux have no such limit: there the deep root is
# accepted (witness of the Windows-only scope).
#
# Oracles (PASS expected):
#   (a) Windows: a root longer than the maximum is refused, exit non-zero, the
#       message names the length and the maximum, the workspace folder is
#       not created;
#   (b) witness: a short root passes the workspace step (--stop-after-step
#       workspace), the folder is created;
#   (c) macOS / Linux: the deep root of (a) is not refused;
#   (d)/(e) Windows, boundary: a root of exactly the maximum passes the
#       workspace step; one character more is refused, nothing written.
#
# Writes only in a temporary folder (prefix m221-deep), simulated profile.
#
# usage: bash tests/test-install-workspace-too-deep.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- l'installeur en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m221-deep-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

IS_WINDOWS=0
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WINDOWS=1 ;; esac

SRC="$TMP/source"
REF_CLONE="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference non construit"; exit 1; }
git clone --quiet -- "$REF_CLONE" "$SRC" >/dev/null 2>&1 || { echo "FAIL : source non construite"; exit 1; }
# The installer under test is this working tree's; the source it clones is the
# committed tree (same arrangement as test-install-leaves-vault-clean.sh).

native_len() {
  local p="$1"
  command -v cygpath >/dev/null 2>&1 && p="$(cygpath -w "$p")"
  printf '%s' "${#p}"
}

run_install() {
  # $1 = test root, $2 = workspace path, $3... = extra install.sh arguments.
  local root="$1" ws="$2"; shift 2
  mkdir -p "$root"
  sed "s#\"workspacePath\": \"[^\"]*\"#\"workspacePath\": \"$ws\"#" \
    "$REPO_ROOT/tests/fixtures/install-answers.sample.json" > "$root/answers.json"
  LAST_OUT="$(bash "$REPO_ROOT/install.sh" --source "$SRC" --answers-file "$root/answers.json" \
    --test-mode --test-root "$root" "$@" 2>&1)"
  LAST_RC=$?
}

# A workspace path well past the maximum, whatever TMP is.
PAD="dossier-tres-profond-pour-mesurer-la-limite-de-chemin-de-windows"
DEEP_WS="$TMP/d/$PAD/$PAD/workspace"
DEEP_LEN="$(native_len "$DEEP_WS")"
# Expected maximum, computed as the installer must: 259 - 1 - len("second-brain/")
# - the longest tracked Markdown file outside skills-warehouse/.
LONGEST="$(git -C "$SRC" ls-files -z -- '*.md' ':(exclude)skills-warehouse' | tr '\0' '\n' | awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }')"
EXPECTED_MAX=$((259 - 1 - 13 - LONGEST))

echo "=== (a)/(c) racine profonde ($DEEP_LEN caracteres) ==="
run_install "$TMP/d" "$DEEP_WS" --stop-after-step workspace
if [ "$IS_WINDOWS" = "1" ]; then
  if [ "$LAST_RC" != "0" ] && printf '%s' "$LAST_OUT" | grep -q "is $DEEP_LEN characters long; on Windows it can be at most $EXPECTED_MAX"; then
    pass "(a) racine de $DEEP_LEN caracteres refusee, longueur et maximum ($EXPECTED_MAX) nommes"
  else
    fail "(a) racine profonde non refusee comme attendu (rc=$LAST_RC) : $(printf '%s' "$LAST_OUT" | tail -n 2 | tr '\n' ' ')"
  fi
  if [ ! -e "$DEEP_WS" ]; then
    pass "(a) rien d'ecrit : le dossier d'espace de travail n'existe pas"
  else
    fail "(a) le dossier d'espace de travail a ete cree malgre le refus"
  fi
else
  # --stop-after-step exits 1 by design: the folder and the absence of the
  # refusal are what is measured.
  if [ -d "$DEEP_WS" ] && ! printf '%s' "$LAST_OUT" | grep -q 'characters long; on Windows'; then
    pass "(c) hors Windows : la racine profonde n'est pas refusee"
  else
    fail "(c) hors Windows : racine profonde refusee ou echec (rc=$LAST_RC) : $(printf '%s' "$LAST_OUT" | tail -n 2 | tr '\n' ' ')"
  fi
fi

echo "=== (b) temoin : racine courte ==="
SHORT_WS="$TMP/s/workspace"
run_install "$TMP/s" "$SHORT_WS" --stop-after-step workspace
if [ -d "$SHORT_WS" ] && ! printf '%s' "$LAST_OUT" | grep -q 'characters long; on Windows'; then
  pass "(b) racine courte ($(native_len "$SHORT_WS") caracteres) : etape workspace passee, dossier cree"
else
  fail "(b) racine courte refusee ou non creee (rc=$LAST_RC) : $(printf '%s' "$LAST_OUT" | tail -n 2 | tr '\n' ' ')"
fi

if [ "$IS_WINDOWS" = "1" ]; then
  echo "=== (d)/(e) frontiere : $EXPECTED_MAX accepte, $((EXPECTED_MAX + 1)) refuse ==="
  # boundary_ws <case> <target native length>: a workspace path of exactly that length.
  boundary_ws() {
    local base="$TMP/$1" n
    n=$(( $2 - $(native_len "$base") - 1 - 10 ))
    printf '%s/%s/workspace' "$base" "$(printf 'x%.0s' $(seq 1 "$n"))"
  }
  WS_D="$(boundary_ws e1 "$EXPECTED_MAX")"
  run_install "$TMP/e1" "$WS_D" --stop-after-step workspace
  if [ "$(native_len "$WS_D")" = "$EXPECTED_MAX" ] && [ -d "$WS_D" ] && ! printf '%s' "$LAST_OUT" | grep -q 'characters long; on Windows'; then
    pass "(d) racine d'exactement $EXPECTED_MAX caracteres : acceptee"
  else
    fail "(d) racine de $(native_len "$WS_D") caracteres (attendu $EXPECTED_MAX) refusee ou non creee : $(printf '%s' "$LAST_OUT" | tail -n 2 | tr '\n' ' ')"
  fi
  WS_E="$(boundary_ws e2 "$((EXPECTED_MAX + 1))")"
  run_install "$TMP/e2" "$WS_E" --stop-after-step workspace
  if [ ! -e "$WS_E" ] && printf '%s' "$LAST_OUT" | grep -q "is $((EXPECTED_MAX + 1)) characters long; on Windows it can be at most $EXPECTED_MAX"; then
    pass "(e) racine de $((EXPECTED_MAX + 1)) caracteres : refusee, rien d'ecrit"
  else
    fail "(e) racine de $(native_len "$WS_E") caracteres non refusee : $(printf '%s' "$LAST_OUT" | tail -n 2 | tr '\n' ' ')"
  fi
fi

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
