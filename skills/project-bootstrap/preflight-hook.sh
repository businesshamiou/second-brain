#!/usr/bin/env bash
# executor-preflight -- PreToolUse hook laid down by the project-bootstrap skill
# (DECISION-2026-09-01-144931 S1: "executor-preflight n'est pas un skill,
# c'est un hook" ["executor-preflight is not a skill, it is a hook"]). Replays,
# before each writing tool, the three measurements (a)(b)(c) of the
# session-start canary, no more, no less. Read-only: writes nothing, corrects
# nothing. A gap = one refusal line + the verbatim of the gap on stderr,
# exit 2 (the only code that blocks a PreToolUse in Claude Code -- Owner
# arbitration of 2026-09-01); zero gap = exit 0, silence.
#
# usage: preflight-hook.sh            (invoked by .claude/settings.json, cf.
#                                      settings-hook.json; testable by hand)
# env  : PREFLIGHT_PROJECT_DIR  root of the project (default: CLAUDE_PROJECT_DIR,
#                               otherwise the current directory)
#        PREFLIGHT_VAULT_DIR    root of the Vault (default: read in VAULT-ROOT.md
#                               walking up from the project -- no hard-coded
#                               folder name, ticket 02 Mission 168)

set -u

REFUSE_EXIT=2

PROJECT_DIR="${PREFLIGHT_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  echo "REFUS executor-preflight : projet introuvable : ${PREFLIGHT_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}" >&2
  exit "$REFUSE_EXIT"
}

# --- Locating the Vault: VAULT-ROOT.md marker (workspace tier,
# DECISION-2026-08-31-210731 point 1) walking up from the project ---
find_vault() {
  local dir="$PROJECT_DIR" rel
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/VAULT-ROOT.md" ]; then
      rel="$(sed -n -E 's/^Chemin relatif du Vault depuis cette racine de travail : `([^`]+)`.*$/\1/p' "$dir/VAULT-ROOT.md" | head -n 1)"
      [ -n "$rel" ] && { echo "$dir/$rel"; return 0; }
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}
VAULT_DIR="${PREFLIGHT_VAULT_DIR:-}"
if [ -z "$VAULT_DIR" ]; then
  VAULT_DIR="$(find_vault)" || {
    echo "REFUS executor-preflight : marqueur VAULT-ROOT.md introuvable en remontant depuis $PROJECT_DIR" >&2
    exit "$REFUSE_EXIT"
  }
fi
VAULT_DIR="$(cd "$VAULT_DIR" 2>/dev/null && pwd)" || {
  echo "REFUS executor-preflight : Vault introuvable depuis $PROJECT_DIR (chemin lu dans VAULT-ROOT.md invalide)" >&2
  exit "$REFUSE_EXIT"
}

ECARTS=0
ecart() { ECARTS=$((ECARTS + 1)); echo "  ($1) $2" >&2; }

# --- (a) rev: of <projet>/.pre-commit-config.yaml compared with the pushed head
# of the Vault (origin/main; failing a remote, the local main head) ---
CONFIG="$PROJECT_DIR/.pre-commit-config.yaml"
if [ ! -f "$CONFIG" ]; then
  ecart a "epingle absente : $CONFIG introuvable"
elif grep -qE '^[[:space:]]*-?[[:space:]]*repo:[[:space:]]*local[[:space:]]*$' "$CONFIG"; then
  # repo: local pin (T01, ticket 02 Mission 168): form of the projects born
  # from project-bootstrap on this neighbouring Vault. No rev: to compare -- the
  # pin always follows the current content of the Vault found by the marker;
  # instead we check that each entry: cites a script that really exists.
  MISSING_ENTRIES=""
  while IFS= read -r ENTRY; do
    [ -z "$ENTRY" ] && continue
    case "$ENTRY" in
      /*|[A-Za-z]:\\*|[A-Za-z]:/*) ENTRY_ABS="$ENTRY" ;;
      *) ENTRY_ABS="$PROJECT_DIR/$ENTRY" ;;
    esac
    [ -f "$ENTRY_ABS" ] || MISSING_ENTRIES="$MISSING_ENTRIES${MISSING_ENTRIES:+, }$ENTRY"
  done < <(sed -n -E 's/^[[:space:]]*entry:[[:space:]]*(.*)$/\1/p' "$CONFIG")
  [ -n "$MISSING_ENTRIES" ] && ecart a "epingle repo: local, script(s) introuvable(s) : $MISSING_ENTRIES"
else
  REV="$(sed -n -E 's/^[[:space:]]*rev:[[:space:]]*"?([0-9a-fA-F]{7,40})"?[[:space:]]*$/\1/p' "$CONFIG" | head -n 1)"
  HEAD_REF="$(git -C "$VAULT_DIR" rev-parse --verify -q refs/remotes/origin/main 2>/dev/null \
           || git -C "$VAULT_DIR" rev-parse --verify -q refs/heads/main 2>/dev/null)"
  if [ -z "$REV" ]; then
    ecart a "aucune ligne rev: lisible dans $CONFIG"
  elif [ -z "$HEAD_REF" ]; then
    ecart a "tete du Vault illisible (ni origin/main ni main dans $VAULT_DIR)"
  elif [ "$REV" != "$HEAD_REF" ] && ! git -C "$VAULT_DIR" rev-parse --verify -q "${REV}^{commit}" >/dev/null 2>&1; then
    ecart a "rev: $REV inconnu du Vault (tete $HEAD_REF)"
  elif [ "$REV" != "$HEAD_REF" ]; then
    BEHIND="$(git -C "$VAULT_DIR" rev-list --count "${REV}..${HEAD_REF}" 2>/dev/null || echo '?')"
    ecart a "rev: $REV en retard de $BEHIND commit(s) sur la tete du Vault $HEAD_REF"
  fi
fi

# --- (b) the Vault's native hook present and core.hooksPath pointing to it ---
HOOK="$VAULT_DIR/.githooks/pre-commit"
if [ ! -f "$HOOK" ]; then
  ecart b "hook natif absent : $HOOK"
else
  HP="$(git -C "$VAULT_DIR" config --get core.hooksPath 2>/dev/null || true)"
  [ "$HP" = ".githooks" ] || ecart b "core.hooksPath du Vault = '${HP:-<vide>}' au lieu de '.githooks'"
fi

# --- (c) each guardian script named by the hook present in the Vault's tools/ ---
if [ -f "$HOOK" ]; then
  for S in $(grep -oE '\$VAULT_ROOT/tools/[A-Za-z0-9_.-]+\.sh' "$HOOK" | sed 's#^\$VAULT_ROOT/##' | sort -u); do
    [ -f "$VAULT_DIR/$S" ] || ecart c "gardien nomme par le hook, absent : $VAULT_DIR/$S"
  done
fi

if [ "$ECARTS" -gt 0 ]; then
  echo "REFUS executor-preflight : $ECARTS ecart(s) au canari (a)(b)(c) -- aucun outil d'ecriture tant que le poste n'est pas READY (session-start, Mission ou arbitrage Owner)" >&2
  exit "$REFUSE_EXIT"
fi
exit 0
