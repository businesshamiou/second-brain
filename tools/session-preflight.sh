#!/usr/bin/env bash
# Preflight de session (Mission 039) : verifie sans rien modifier.
# Sortie stdout : une ligne READY ou NOT-READY: <n> issue(s). Detail sur stderr.
# Ecrit le tampon local .claude/.preflight_stamp.json (non verse a Git).
#
# usage: session-preflight.sh
#
# Nom du depot frere parametrable (Mission 069, douteux 6) :
# PREFLIGHT_SIBLING_NAME en variable d'environnement, defaut inchange
# "workshop-build". Son absence devient un avertissement (READY possible),
# plus un echec -- un detenteur du Vault seul (aucun projet frere encore
# clone) reste READY.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIBLING_NAME="${PREFLIGHT_SIBLING_NAME:-workshop-build}"
BUILD_ROOT="$(cd "$VAULT_ROOT/../$SIBLING_NAME" 2>/dev/null && pwd || true)"
STAMP="$VAULT_ROOT/.claude/.preflight_stamp.json"
CHARTER="$VAULT_ROOT/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"

ISSUES=()
WARNINGS=()

# --- 1. charte des roles presente ---
if [ ! -f "$CHARTER" ]; then
  ISSUES+=("charte des roles introuvable : $CHARTER")
fi

# --- 2. pointeurs presents dans AGENTS.md et CLAUDE.md des deux depots ---
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
else
  WARNINGS+=("depot frere introuvable en ../$SIBLING_NAME -- avertissement, pas un echec (detenteur du Vault seul)")
fi

# --- 3. .claude/settings.json present et JSON valide ---
SETTINGS="$VAULT_ROOT/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  ISSUES+=("settings.json introuvable : $SETTINGS")
else
  # node avant python3 : sur Windows, python3 peut n'etre qu'un alias-stub
  # du Windows Store qui echoue toujours sans etre un vrai interprete.
  JSON_OK=1
  if command -v node >/dev/null 2>&1 \
      && node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$SETTINGS" >/dev/null 2>&1; then
    JSON_OK=0
  elif command -v python3 >/dev/null 2>&1 \
      && python3 -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8'))" "$SETTINGS" >/dev/null 2>&1; then
    JSON_OK=0
  fi
  if [ "$JSON_OK" -ne 0 ]; then
    if command -v node >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
      ISSUES+=("settings.json invalide (JSON) : $SETTINGS")
    else
      ISSUES+=("aucun analyseur JSON disponible (node/python3) pour valider $SETTINGS")
    fi
  fi
fi

# --- 4. role par sonde de capacite (barreau 2 de la charte) ---
# Un shell bash capable d'executer ce script est la preuve meme de la capacite.
ROLE="executor"

# --- 5. outils attendus executables ---
for tool in git bash; do
  command -v "$tool" >/dev/null 2>&1 || ISSUES+=("outil introuvable dans PATH : $tool")
done

for script in tools/build-state.sh tools/build-indexes.sh tools/check-links.sh; do
  p="$VAULT_ROOT/$script"
  if [ ! -x "$p" ]; then
    ISSUES+=("script non executable ou absent : $p")
  fi
done

# --- 6. age du dernier evenement de hooks.log, s'il existe ---
HOOKS_LOG="$VAULT_ROOT/.claude/hooks.log"
if [ -f "$HOOKS_LOG" ]; then
  NOW="$(date +%s)"
  MTIME="$(date -r "$HOOKS_LOG" +%s 2>/dev/null || echo "$NOW")"
  AGE_H=$(( (NOW - MTIME) / 3600 ))
  if [ "$AGE_H" -gt 72 ]; then
    ISSUES+=("hooks.log silencieux depuis ${AGE_H}h (plafond 72h) : $HOOKS_LOG")
  fi
fi

# --- Ecriture du tampon (jamais versionne) ---
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
  for ISSUE in "${ISSUES[@]}"; do
    ESCAPED="${ISSUE//\\/\\\\}"
    ESCAPED="${ESCAPED//\"/\\\"}"
    if [ "$FIRST" -eq 0 ]; then printf ','; fi
    printf '"%s"' "$ESCAPED"
    FIRST=0
  done
  printf '],\n'
  printf '  "warnings": ['
  FIRST=1
  for WARNING in "${WARNINGS[@]}"; do
    ESCAPED="${WARNING//\\/\\\\}"
    ESCAPED="${ESCAPED//\"/\\\"}"
    if [ "$FIRST" -eq 0 ]; then printf ','; fi
    printf '"%s"' "$ESCAPED"
    FIRST=0
  done
  printf ']\n'
  echo "}"
} > "$STAMP"

# --- Sortie ---
for WARNING in "${WARNINGS[@]}"; do
  echo "  - avertissement : $WARNING" >&2
done

if [ "$N" -eq 0 ]; then
  echo "READY"
  exit 0
else
  echo "NOT-READY: $N issue(s)"
  for ISSUE in "${ISSUES[@]}"; do
    echo "  - $ISSUE" >&2
  done
  exit 1
fi
