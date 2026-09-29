#!/usr/bin/env bash
# Session preflight (build history) : verifies without modifying anything.
# Stdout: one line, READY or NOT-READY: <n> issue(s). Detail on stderr.
# Writes the local stamp .claude/.preflight_stamp.json (never committed).
#
# usage: session-preflight.sh
#
# Sibling repository (build history; Mission 174 step 3, T21): no name is
# assumed by default any more. See tools/resolve-sibling-repo.sh -- without
# an explicit declaration (SECOND_BRAIN_SIBLING_REPO or a workspace-root
# SIBLING-REPO.txt), this check is skipped entirely: no search, no warning.
# Declared but not found on disk: one clear warning (READY still possible,
# never a failure -- a participant with no second repository is a normal,
# complete setup).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$VAULT_ROOT/.." && pwd)"
. "$SCRIPT_DIR/resolve-sibling-repo.sh"
resolve_declared_sibling "$WORKSPACE_ROOT"
BUILD_ROOT="$SIBLING_ROOT"
STAMP="$VAULT_ROOT/.claude/.preflight_stamp.json"
CHARTER="$VAULT_ROOT/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"

# Both arrays are expanded further down in the guarded form
# ${ARRAY[@]+"${ARRAY[@]}"}: under `set -u`, the bash 3.2 shipped by Apple
# treats the expansion of an EMPTY array as an unbound variable and stops
# (fixed in bash 4.4, hence invisible under Linux and Git Bash). The nominal
# path -- no defect to report -- is precisely the one where both
# arrays are empty: macOS therefore failed when everything was fine.
ISSUES=()
WARNINGS=()

# --- 1. role charter present ---
if [ ! -f "$CHARTER" ]; then
  ISSUES+=("charte des roles introuvable : $CHARTER")
fi

# --- 2. pointers present in AGENTS.md and CLAUDE.md of both repositories ---
check_pointer() {
  local f="$1"
  if [ ! -f "$f" ]; then
    ISSUES+=("fichier absent : $f")
    return
  fi
  grep -q "role-charter-and-session-determination" "$f" || ISSUES+=("pointeur vers la charte absent : $f")
}

check_pointer "$VAULT_ROOT/AGENTS.md"
check_pointer "$VAULT_ROOT/CLAUDE.md"

if [ -n "$BUILD_ROOT" ]; then
  check_pointer "$BUILD_ROOT/AGENTS.md"
  check_pointer "$BUILD_ROOT/CLAUDE.md"
elif [ "$SIBLING_DECLARED" -eq 1 ]; then
  WARNINGS+=("declared sibling repository '$SIBLING_NAME' not found next to this workspace -- warning, not a failure")
fi

# --- 3. .claude/settings.json present and valid JSON ---
SETTINGS="$VAULT_ROOT/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  ISSUES+=("settings.json introuvable : $SETTINGS")
else
  # node first, then Python through uv -- never a bare python3: on Windows,
  # python3 may be only the Windows Store alias, which "is found" by
  # `command -v` and always fails (Mission 231, docs/how-to/troubleshoot.md).
  JSON_OK=1
  if command -v node >/dev/null 2>&1 \
      && node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$SETTINGS" >/dev/null 2>&1; then
    JSON_OK=0
  elif command -v uv >/dev/null 2>&1 \
      && uv run --no-project python -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8'))" "$SETTINGS" >/dev/null 2>&1; then
    JSON_OK=0
  fi
  if [ "$JSON_OK" -ne 0 ]; then
    if command -v node >/dev/null 2>&1 || command -v uv >/dev/null 2>&1; then
      ISSUES+=("settings.json invalide (JSON) : $SETTINGS")
    else
      ISSUES+=("aucun analyseur JSON disponible (node/uv) pour valider $SETTINGS")
    fi
  fi
fi

# --- 4. role by capability probe (rung 2 of the charter) ---
# A bash shell able to run this script is itself the proof of capability.
ROLE="executor"

# --- 5. expected tools executable ---
for tool in git bash; do
  command -v "$tool" >/dev/null 2>&1 || ISSUES+=("outil introuvable dans PATH : $tool")
done

for script in tools/build-state.sh tools/build-indexes.sh tools/check-links.sh; do
  p="$VAULT_ROOT/$script"
  if [ ! -x "$p" ]; then
    ISSUES+=("script non executable ou absent : $p")
  fi
done

# --- 6. age of the last event in hooks.log, if it exists ---
HOOKS_LOG="$VAULT_ROOT/.claude/hooks.log"
# Age measured with `find -mmin`, common to GNU and BSD, and no longer with
# `date -r FILE`: on macOS, `date -r` expects a number of seconds, the
# command failed, the fallback took "now" and this check never
# bit (Mission 181). 4320 minutes = 72 hours, same ceiling.
if [ -f "$HOOKS_LOG" ]; then
  if [ -n "$(find "$HOOKS_LOG" -mmin +4320 2>/dev/null)" ]; then
    ISSUES+=("hooks.log silencieux depuis plus de 72h (plafond 72h) : $HOOKS_LOG")
  fi
fi

# --- 7. root of the workspace against the computed whitelist (Mission 234,
# rule on workspace hygiene §3): a WARNING, never an issue -- the preflight
# never blocks on it. Only when the parent of this Vault carries the marker. ---
ROOT_GUARD="$VAULT_ROOT/tools/check-workspace-root.sh"
if [ -f "$WORKSPACE_ROOT/VAULT-ROOT.md" ] && [ -f "$ROOT_GUARD" ]; then
  ROOT_OUT="$(bash "$ROOT_GUARD" "$WORKSPACE_ROOT" 2>&1)"
  while IFS= read -r ROOT_LINE; do
    case "$ROOT_LINE" in
      ÉCART:*|EXCEPTION-PROVISOIRE:*|SIGNALÉ:*) WARNINGS+=("racine de l'espace : $ROOT_LINE") ;;
    esac
  done <<ROOT_EOF
$ROOT_OUT
ROOT_EOF
fi

# --- Writing the stamp (never versioned) ---
N=${#ISSUES[@]}
if [ "$N" -eq 0 ]; then
  READY_JSON=true
else
  READY_JSON=false
fi

mkdir -p "$(dirname "$STAMP")"
{
  echo "{"
  printf '  "role": "%s",\n' "$ROLE"
  printf '  "checked_at": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '  "ready": %s,\n' "$READY_JSON"
  printf '  "issues": ['
  FIRST=1
  for ISSUE in ${ISSUES[@]+"${ISSUES[@]}"}; do
    ESCAPED="${ISSUE//\\/\\\\}"
    ESCAPED="${ESCAPED//\"/\\\"}"
    if [ "$FIRST" -eq 0 ]; then printf ','; fi
    printf '"%s"' "$ESCAPED"
    FIRST=0
  done
  printf '],\n'
  printf '  "warnings": ['
  FIRST=1
  for WARNING in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
    ESCAPED="${WARNING//\\/\\\\}"
    ESCAPED="${ESCAPED//\"/\\\"}"
    if [ "$FIRST" -eq 0 ]; then printf ','; fi
    printf '"%s"' "$ESCAPED"
    FIRST=0
  done
  printf ']\n'
  echo "}"
} > "$STAMP"

# --- Output ---
for WARNING in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
  echo "  - warning: $WARNING" >&2
done

if [ "$N" -eq 0 ]; then
  echo "READY"
  exit 0
else
  echo "NOT-READY: $N issue(s)"
  for ISSUE in ${ISSUES[@]+"${ISSUES[@]}"}; do
    echo "  - $ISSUE" >&2
  done
  exit 1
fi
