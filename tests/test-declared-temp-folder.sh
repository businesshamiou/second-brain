#!/usr/bin/env bash
# Mission 234, step 2: the declared temporary folder (rule on workspace hygiene
# §2). Every throwaway file of the tooling goes through one access function,
# tools/lib/tmp.sh (tools/lib/tmp.ps1 for PowerShell).
#
# Static, on the code of <repo root> (default: this repository):
#   (a) every mktemp of tools/ and install.sh is given a template under
#       sb_tmp_dir -- named exception: tools/build-digest.sh (atomic rewrite in
#       the project's own state/);
#   (b) no /tmp path in tools/ and install.sh, not even ${TMPDIR:-/tmp} -- named
#       exceptions: tools/lib/tmp.sh itself, bootstrap.sh (runs before any
#       Vault, applies the rule inline); in tests/, only ${TMPDIR:-/tmp}, which
#       the runner points at <SB_TMP>/tests;
#   (c) no $env:TEMP, GetTempPath or GetTempFileName in tools/*.ps1 and
#       install.ps1 -- named exceptions: tools/lib/tmp.ps1, bootstrap.ps1;
#   (d) no test writes next to its repository (the workspace root: report 233
#       §7.3);
#   (e) both suite runners export the tests sub-folder; the reference clones
#       live under <SB_TMP>/reference-clones.
# Behaviour, in a throwaway folder under the declared one:
#   (f) sb_tmp_export tests: mktemp and Python land under <SB_TMP>/tests;
#   (g) a root below a folder carrying VAULT-ROOT.md is refused, and nothing is
#       created;
#   (h) write-marker.sh writes the line « Dossier temporaire déclaré », keeps
#       the organs and exceptions when it regenerates, and refuses a temporary
#       folder below the working root;
#   (i) the repository-root guard admits a throwaway folder below
#       <SB_TMP>/tests even when that folder holds two repositories.
#
# usage: bash tests/test-declared-temp-folder.sh [<repo root>]
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

SELF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="${1:-$SELF_ROOT}"
ROOT="$(cd "$ROOT" && pwd)"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

code_lines() { # <files...>: file:line:text of the non-comment lines
  grep -nH '' "$@" 2>/dev/null | awk -F: '{ t = $0; sub(/^[^:]*:[^:]*:/, "", t); if (t !~ /^[[:space:]]*#/) print }'
}

echo "=== Mission 234 : dossier temporaire declare ($ROOT) ==="

# --- (a) mktemp of the tools ---
A_FILES="$(cd "$ROOT" && ls tools/*.sh tools/lib/*.sh install.sh 2>/dev/null)"
A_BAD="$(cd "$ROOT" && code_lines $A_FILES | grep -E '(^|[^A-Za-z_])mktemp([^A-Za-z_]|$)' \
  | grep -v 'sb_tmp_dir' | grep -v 'SB_TOOLS_TMP' | grep -v '^tools/build-digest.sh:')"
if [ -z "$A_BAD" ]; then
  pass "(a) chaque mktemp des outils et d'install.sh passe par sb_tmp_dir (exception nommee : build-digest.sh)"
else
  fail "(a) mktemp hors de la fonction d'acces : $(printf '%s' "$A_BAD" | cut -d: -f1,2 | tr '\n' ' ')"
fi

# --- (b) /tmp literals ---
# A path /tmp, /tmp/... (never the /tmp of lib/tmp.sh in a file name).
B_TOOLS="$(cd "$ROOT" && code_lines $(ls tools/*.sh install.sh 2>/dev/null) | grep -E '(^|[^A-Za-z0-9_.])/tmp(/|"|}|$)' | grep -v '^tools/lib/tmp.sh:')"
# In tests, only a WRITE there (redirection, mkdir, mktemp): a /tmp inside a
# fixture string (a gesture a test asks a tool to judge) is data.
B_TESTS="$(cd "$ROOT" && code_lines $(ls tests/*.sh 2>/dev/null) | sed 's#\${TMPDIR:-/tmp}##g; s#\${RUNNER_TEMP:-\${TMPDIR:-/tmp}}##g' | grep -E '(>|mkdir -p |mktemp -d |mktemp )"?/tmp/' | grep -v '^tests/test-declared-temp-folder.sh:')"
if [ -z "$B_TOOLS" ] && [ -z "$B_TESTS" ]; then
  pass "(b) aucun chemin /tmp code en dur (outils : aucun ; tests : seulement \${TMPDIR:-/tmp}, pose par le lanceur)"
else
  fail "(b) /tmp code en dur : $(printf '%s\n%s' "$B_TOOLS" "$B_TESTS" | grep . | cut -d: -f1,2 | tr '\n' ' ')"
fi

# --- (c) PowerShell ---
C_BAD="$(cd "$ROOT" && code_lines $(ls tools/*.ps1 install.ps1 2>/dev/null) | grep -iE 'env:TEMP|env:TMP|GetTempPath|GetTempFileName')"
if [ -z "$C_BAD" ]; then
  pass "(c) PowerShell : aucun \$env:TEMP, GetTempPath ni GetTempFileName hors de tmp.ps1 et bootstrap.ps1"
else
  fail "(c) temporaire direct en PowerShell : $(printf '%s' "$C_BAD" | cut -d: -f1,2 | tr '\n' ' ')"
fi

# --- (d) next to the repository ---
D_BAD="$(cd "$ROOT" && code_lines $(ls tests/*.sh 2>/dev/null) | grep 'mktemp' | grep -E 'dirname "\$(REPO_ROOT|VAULT_ROOT|SCRIPT_DIR/\.\.)"')"
if [ -z "$D_BAD" ]; then
  pass "(d) aucun test n'ecrit a cote de son depot (racine de l'espace)"
else
  fail "(d) ecriture a cote du depot : $(printf '%s' "$D_BAD" | cut -d: -f1,2 | tr '\n' ' ')"
fi

# --- (e) runners and reference clones ---
if grep -q 'sb_tmp_export tests' "$ROOT/tests/run-suite.sh" 2>/dev/null \
   && grep -q 'Get-SbTmpDir -Use tests' "$ROOT/tests/run-suite.ps1" 2>/dev/null \
   && grep -q 'sb_tmp_dir reference-clones' "$ROOT/tests/sandbox-vault.sh" 2>/dev/null; then
  pass "(e) les deux lanceurs exportent <SB_TMP>/tests ; clones de reference sous <SB_TMP>/reference-clones"
else
  fail "(e) lanceurs ou clones de reference hors du dossier declare"
fi

# --- behaviour: needs the access function of THIS repository ---
if [ ! -f "$SELF_ROOT/tools/lib/tmp.sh" ]; then
  fail "(f-i) tools/lib/tmp.sh absent : comportement non mesurable"
else
  . "$SELF_ROOT/tools/lib/tmp.sh"
  BASE="$(sb_tmp_dir tests)" || { fail "(f) sb_tmp_dir tests"; BASE=""; }
  if [ -n "$BASE" ]; then
    TMP="$(mktemp -d "$BASE/m234-tmp-XXXXXX")"
    trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT

    # (f)
    GOT="$( (sb_tmp_export tests && mktemp -d) 2>&1)"
    PYGOT="$( (sb_tmp_export tests && uv run --no-project python -c 'import tempfile; print(tempfile.gettempdir())') 2>&1)"
    ROOT_TMP="$(sb_tmp_root)"
    norm() { printf '%s' "$1" | tr '\\' '/' | tr 'A-Z' 'a-z' | sed 's#^\([a-z]\):/#/\1/#'; }
    case "$(norm "$GOT")" in
      "$(norm "$ROOT_TMP")"/tests/*) F1=1 ;; *) F1=0 ;;
    esac
    case "$(norm "$PYGOT")" in
      "$(norm "$ROOT_TMP")"/tests*) F2=1 ;; *) F2=0 ;;
    esac
    if [ "$F1" = 1 ] && [ "$F2" = 1 ]; then
      pass "(f) sb_tmp_export tests : mktemp et Python ecrivent sous <SB_TMP>/tests"
    else
      fail "(f) export : mktemp=$GOT python=$PYGOT racine=$ROOT_TMP"
    fi
    rmdir "$GOT" 2>/dev/null

    # (g)
    mkdir -p "$TMP/ws"
    printf 'marker\n' > "$TMP/ws/VAULT-ROOT.md"
    OUT="$(SB_TMP="$TMP/ws/inside/tmp" sb_tmp_root 2>&1)"; RC=$?
    if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q "sous une racine d'espace" && [ ! -e "$TMP/ws/inside" ]; then
      pass "(g) racine sous un VAULT-ROOT.md : refusee, rien cree"
    else
      fail "(g) racine sous un marqueur : rc=$RC, cree=$([ -e "$TMP/ws/inside" ] && echo oui || echo non) : $OUT"
    fi

    # (h)
    WM="$ROOT/tools/write-marker.sh"
    mkdir -p "$TMP/ws2"
    if bash "$WM" --marker-only --organs "m-publish" --exceptions "old-space" "$TMP/ws2" Test >/dev/null 2>&1 \
       && grep -q "^Dossier temporaire déclaré : \`" "$TMP/ws2/VAULT-ROOT.md" \
       && bash "$WM" --marker-only "$TMP/ws2" Test >/dev/null 2>&1 \
       && grep -q "^Organes déclarés à cette racine : \`m-publish\`" "$TMP/ws2/VAULT-ROOT.md" \
       && grep -q "^Exceptions provisoires à cette racine : \`old-space\`" "$TMP/ws2/VAULT-ROOT.md"; then
      if bash "$WM" --marker-only --tmp "$TMP/ws2/tmp" "$TMP/ws2" Test >/dev/null 2>&1; then
        fail "(h) write-marker accepte un temporaire sous la racine de travail"
      else
        pass "(h) write-marker : ligne du temporaire ecrite, organes et exceptions gardes a la regeneration, temporaire sous la racine refuse"
      fi
    else
      fail "(h) write-marker n'ecrit pas ou ne garde pas les trois lignes"
    fi

    # (i)
    for r in r1 r2; do mkdir -p "$TMP/$r" && git -C "$TMP/$r" init -q 2>/dev/null; done
    GUARD="$ROOT/tools/repo_root_guard.py"
    if [ -f "$GUARD" ] && (sb_tmp_export tests && uv run --no-project "$GUARD" "$TMP/throwaway/x") >/dev/null 2>&1; then
      pass "(i) garde-fou : dossier jetable sous <SB_TMP>/tests admis, meme a cote de deux depots"
    else
      fail "(i) garde-fou : dossier jetable sous <SB_TMP>/tests refuse"
    fi
  fi
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
