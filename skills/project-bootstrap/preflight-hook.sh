#!/usr/bin/env bash
# executor-preflight -- hook PreToolUse pose par le skill project-bootstrap
# (DECISION-2026-09-01-144931 S1 : "executor-preflight n'est pas un skill,
# c'est un hook"). Rejoue, avant chaque outil d'ecriture, les trois mesures
# (a)(b)(c) du canari de session-start, ni plus ni moins. Lecture seule :
# n'ecrit rien, ne corrige rien. Un ecart = une ligne de refus + le verbatim
# de l'ecart sur stderr, exit 2 (le seul code qui bloque un PreToolUse dans
# Claude Code -- arbitrage Owner du 2026-09-01) ; zero ecart = exit 0, silence.
#
# usage: preflight-hook.sh            (invoque par .claude/settings.json, cf.
#                                      settings-hook.json ; testable a la main)
# env  : PREFLIGHT_PROJECT_DIR  racine du projet (defaut : CLAUDE_PROJECT_DIR,
#                               sinon le repertoire courant)
#        PREFLIGHT_VAULT_DIR    racine du Vault (defaut : lue dans VAULT-ROOT.md
#                               en remontant depuis le projet -- aucun nom de
#                               dossier en dur, ticket 02 Mission 168)

set -u

REFUSE_EXIT=2

PROJECT_DIR="${PREFLIGHT_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  echo "REFUS executor-preflight : projet introuvable : ${PREFLIGHT_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}" >&2
  exit "$REFUSE_EXIT"
}

# --- Localisation du Vault : marqueur VAULT-ROOT.md (etage workspace,
# DECISION-2026-08-31-210731 point 1) en remontant depuis le projet ---
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

# --- (a) rev: de <projet>/.pre-commit-config.yaml compare a la tete poussee
# du Vault (origin/main ; a defaut de remote, la tete locale main) ---
CONFIG="$PROJECT_DIR/.pre-commit-config.yaml"
if [ ! -f "$CONFIG" ]; then
  ecart a "epingle absente : $CONFIG introuvable"
elif grep -qE '^[[:space:]]*-?[[:space:]]*repo:[[:space:]]*local[[:space:]]*$' "$CONFIG"; then
  # Epingle repo: local (T01, ticket 02 Mission 168) : forme des projets nes
  # de project-bootstrap sur ce Vault voisin. Aucun rev: a comparer -- le pin
  # suit toujours le contenu courant du Vault trouve par le marqueur ; on
  # verifie a la place que chaque entry: cite un script qui existe reellement.
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

# --- (b) hook natif du Vault present et core.hooksPath pointant dessus ---
HOOK="$VAULT_DIR/.githooks/pre-commit"
if [ ! -f "$HOOK" ]; then
  ecart b "hook natif absent : $HOOK"
else
  HP="$(git -C "$VAULT_DIR" config --get core.hooksPath 2>/dev/null || true)"
  [ "$HP" = ".githooks" ] || ecart b "core.hooksPath du Vault = '${HP:-<vide>}' au lieu de '.githooks'"
fi

# --- (c) chaque script gardien nomme par le hook present dans tools/ du Vault ---
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
