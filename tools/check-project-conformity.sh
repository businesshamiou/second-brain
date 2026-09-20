#!/usr/bin/env bash
# Records the conformity of a project to the project structure standard
# (seven functions, RULES-2026-08-26-142800-project-structure-standard.md) and
# to the project tier of Vault awareness (DECISION-2026-08-31-
# 210731 point 4, Decision 2026-09-17-000545 A1): birth certificate,
# guardian pin, Git hook, consistency of the pointer files.
# Never blocking, never correcting: measures and reports, fixes nothing
# (registry v1 D4 point 3 and D6).
#
# usage: check-project-conformity.sh [chemin-projet]
# Default: current directory.
#
# The Vault is resolved by tools/resolve-vault.sh (certificate first, marker
# next, never proximity). Stdout output: "CONFORME" or
# "ÉCART: <missing1, missing2, ...>". Exit code: 0 in both cases of a
# verdict given; non-zero only if the measurement itself fails (project
# path does not exist, Vault not resolved).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/relpath.sh"
. "$SCRIPT_DIR/resolve-vault.sh"

PROJECT="${1:-.}"

if [ ! -d "$PROJECT" ]; then
  echo "REFUS : chemin de projet introuvable : $PROJECT" >&2
  exit 1
fi

PROJECT_ABS="$(cd "$PROJECT" && pwd -P)"

if ! resolve_vault "$PROJECT_ABS"; then
  echo "REFUS : $RV_MESSAGE" >&2
  exit 1
fi
VAULT_ABS="$RV_VAULT"
REGISTRY="$VAULT_ABS/projects/PROJECT-REGISTRY.md"
CONFIG="$PROJECT_ABS/.pre-commit-config.yaml"

MISSING=""
add_missing() {
  MISSING="$MISSING${MISSING:+, }$1"
}

# --- 1. Seven functions: skeleton of RULES-2026-08-26-142800, S2 ---
for ITEM in README.md rules state missions decisions proposals knowledge handoffs; do
  if [ ! -e "$PROJECT_ABS/$ITEM" ]; then
    add_missing "$ITEM"
  fi
done

# --- 2. Entry in the register (path relative to the marker's folder) ---
if [ ! -f "$REGISTRY" ]; then
  add_missing "registre introuvable ($REGISTRY)"
elif [ -z "$RV_WORKSPACE" ]; then
  add_missing "inscription au registre non vérifiable (projet hors de l'espace de travail du Vault)"
else
  PROJECT_REL="$(rel_path "$RV_WORKSPACE" "$PROJECT_ABS")"
  if ! grep -qF "| $PROJECT_REL |" "$REGISTRY"; then
    add_missing "inscription au registre ($PROJECT_REL)"
  fi
fi

# --- 3. Birth certificate (Decision 000545, A1) ---
VCS=""
if bc_file_has_certificate "$CONFIG"; then
  for KEY in vault_id vault_origin vault_ref; do
    [ -n "$(bc_get "$CONFIG" "$KEY")" ] || add_missing "acte de naissance sans $KEY"
  done
  VCS="$(bc_get "$CONFIG" vcs)"
  case "$VCS" in
    none|git) : ;;
    *) add_missing "acte de naissance : vcs invalide (${VCS:-absent})" ;;
  esac
  BASELINE_NAME="$(bc_get "$CONFIG" baseline)"
  if [ -n "$BASELINE_NAME" ] && [ ! -f "$PROJECT_ABS/$BASELINE_NAME" ]; then
    add_missing "ligne de base nommée par l'acte introuvable ($BASELINE_NAME)"
  fi
else
  add_missing "acte de naissance absent"
fi

# --- 4. Guardian pin: repo: local, four ids, entries resolved ---
if [ -f "$CONFIG" ] && tr -d '\r' < "$CONFIG" | grep -qE '^[[:space:]]*-?[[:space:]]*repo:[[:space:]]*local[[:space:]]*$'; then
  PIN_MISSING=""
  for ID in vault-check-secrets vault-check-indexes-fresh vault-check-index-weight vault-check-links; do
    tr -d '\r' < "$CONFIG" | grep -qE "id:[[:space:]]*$ID[[:space:]]*$" || PIN_MISSING="$PIN_MISSING${PIN_MISSING:+ }$ID"
  done
  [ -z "$PIN_MISSING" ] || add_missing "épingle incomplète ($PIN_MISSING)"
  PIN_REL="$(bc_pin_vault_rel "$PROJECT_ABS")"
  PIN_ABS="$(cd "$PROJECT_ABS/$PIN_REL" 2>/dev/null && pwd -P || true)"
  if [ -z "$PIN_REL" ] || [ "$PIN_ABS" != "$VAULT_ABS" ]; then
    add_missing "épingle hors du Vault résolu (${PIN_REL:-entrée absente})"
  fi
else
  add_missing "épingle des gardiens absente"
fi

# --- 5. Git hook: required if vcs: git, never installed if vcs: none ---
if [ "$VCS" = "git" ]; then
  if [ ! -e "$PROJECT_ABS/.git" ]; then
    add_missing "dépôt Git absent (vcs: git)"
  else
    HOOK="$(git -C "$PROJECT_ABS" rev-parse --git-path hooks/pre-commit 2>/dev/null || true)"
    case "$HOOK" in
      /*|[A-Za-z]:*) : ;;
      ?*) HOOK="$PROJECT_ABS/$HOOK" ;;
    esac
    if [ -z "$HOOK" ] || [ ! -f "$HOOK" ]; then
      add_missing "hook Git absent (pre-commit install)"
    fi
  fi
fi

# --- 6. Pointer files: present, and any path to the Vault that they
# carry is the certificate's (never an assumed proximity) ---
for GUIDE in AGENTS.md CLAUDE.md; do
  if [ ! -f "$PROJECT_ABS/$GUIDE" ]; then
    add_missing "fichier de pointage absent ($GUIDE)"
    continue
  fi
  POINTERS="$(tr -d '\r' < "$PROJECT_ABS/$GUIDE" | grep -oE '(@|\]\()\.\.[^ )]*/(CLAUDE|AGENTS)\.md' | sed -E 's/^(@|\]\()//; s#/(CLAUDE|AGENTS)\.md$##' | sort -u)"
  # Mission 203 (report 202, A5): a link to the role charter of the Vault also
  # names the Vault -- accepted IN ADDITION to CLAUDE.md / AGENTS.md, never in
  # their place. The folder it names is checked against the certificate's like the others.
  CHARTER_POINTERS="$(tr -d '\r' < "$PROJECT_ABS/$GUIDE" | grep -oE '(@|\]\()\.\.[^ )]*/rules/RULES-2026-08-23-224706-role-charter-and-session-determination\.md' | sed -E 's/^(@|\]\()//; s#/rules/RULES-2026-08-23-224706-role-charter-and-session-determination\.md$##' | sort -u)"
  POINTERS="$(printf '%s\n%s\n' "$POINTERS" "$CHARTER_POINTERS" | grep -v '^$' | sort -u || true)"
  if [ -z "$POINTERS" ]; then
    add_missing "fichier de pointage sans chemin vers le Vault ($GUIDE)"
    continue
  fi
  while IFS= read -r P; do
    [ -z "$P" ] && continue
    P_ABS="$(cd "$PROJECT_ABS/$P" 2>/dev/null && pwd -P || true)"
    if [ "$P_ABS" != "$VAULT_ABS" ]; then
      add_missing "fichier de pointage incohérent avec l'acte ($GUIDE : $P)"
    fi
  done <<POINTERS_EOF
$POINTERS
POINTERS_EOF
done

if [ -z "$MISSING" ]; then
  echo "CONFORME"
else
  echo "ÉCART: $MISSING"
fi

exit 0
