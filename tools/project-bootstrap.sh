#!/usr/bin/env bash
# Cree un nouveau projet conforme au standard de structure de projet (sept
# fonctions, RULES-2026-08-26-142800-project-structure-standard.md) : squelette,
# README.md d'identite, amorce de journal, premiers index, fiche PROJECT-v2 et
# ligne de registre. Refuse si la cible existe deja : l'organisation du
# workspace est libre (232341 S1.6), ce script ne presume rien.
#
# usage: project-bootstrap.sh <chemin-cible> <display_name> [langue FR|EN|ES]
#
# Langue (Mission 177, etape 5) : troisieme parametre optionnel, defaut EN
# -- retrocompatible avec tout appelant qui ne le fournit pas encore (tests
# existants compris, qui attendent alors les messages "Note: ..." en
# anglais). install.sh/install.ps1 passent la langue choisie au
# questionnaire ; sans ce parametre, les messages destines au participant
# de ce script restaient codes en dur en anglais, y compris au milieu d'une
# installation francaise ou espagnole (defaut mesure a l'acceptation Owner
# du 2026-09-14).

set -u

TARGET="${1:-}"
DISPLAY_NAME="${2:-}"
LANGUAGE="${3:-EN}"

if [ -z "$TARGET" ] || [ -z "$DISPLAY_NAME" ]; then
  echo "usage: project-bootstrap.sh <chemin-cible> <display_name> [langue FR|EN|ES]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/relpath.sh"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
I18N_DIR="$VAULT_ROOT/i18n"
CATALOG_FILE="$I18N_DIR/catalog.$(printf '%s' "$LANGUAGE" | tr '[:upper:]' '[:lower:]').json"
if [ ! -e "$CATALOG_FILE" ]; then
  CATALOG_FILE="$I18N_DIR/catalog.en.json"
fi

# --- Validation du chemin cible (Mission 171-C01, etape 3 : defaut de
# meme famille que install.sh/install.ps1 -- validation de chemin absente).
# Refuse un chemin cible relatif ou situe a l'interieur de ce depot Vault
# lui-meme : un projet cree dans le Vault casserait la frontiere
# Vault/projet qu'AGENTS.md impose ("Maintenir la frontiere entre le
# Vault et les projets externes"). ---
if [[ "$TARGET" != /* ]] && ! [[ "$TARGET" =~ ^[A-Za-z]:[/\\] ]]; then
  echo "REFUS : chemin cible non absolu : $TARGET" >&2
  exit 1
fi
TARGET_NORMALIZED="$(printf '%s' "$TARGET" | tr '\\' '/')"
case "$TARGET_NORMALIZED" in ?*/) TARGET_NORMALIZED="${TARGET_NORMALIZED%/}" ;; esac
VAULT_ROOT_NORMALIZED="$(printf '%s' "$VAULT_ROOT" | tr '\\' '/')"
TARGET_INSIDE_VAULT=0
if [ "$TARGET_NORMALIZED" = "$VAULT_ROOT_NORMALIZED" ]; then
  TARGET_INSIDE_VAULT=1
else
  case "$TARGET_NORMALIZED" in
    "$VAULT_ROOT_NORMALIZED"/*) TARGET_INSIDE_VAULT=1 ;;
  esac
fi
if [ "$TARGET_INSIDE_VAULT" = "1" ]; then
  echo "REFUS : chemin cible a l'interieur du depot Vault ($VAULT_ROOT) : $TARGET" >&2
  exit 1
fi

if [ -e "$TARGET" ]; then
  echo "REFUS : la cible existe deja : $TARGET" >&2
  exit 1
fi

CONFORMITY_CHECK="$VAULT_ROOT/tools/check-project-conformity.sh"
INDEXES_BUILD="$VAULT_ROOT/tools/build-indexes.sh"
JOURNAL_APPEND="$VAULT_ROOT/tools/append-journal.sh"
PROJECTS_DIR="$VAULT_ROOT/projects"
REGISTRY="$PROJECTS_DIR/PROJECT-REGISTRY.md"
STANDARD_RULE="$VAULT_ROOT/rules/RULES-2026-08-26-142800-project-structure-standard.md"
HELPER="$VAULT_ROOT/tools/sb_installer_helper.py"
MISSION_INDEX_TEMPLATE="$VAULT_ROOT/templates/mission-index-template.md"
BUILD_STATE="$VAULT_ROOT/tools/build-state.sh"
BUILD_DIGEST="$VAULT_ROOT/tools/build-digest.sh"

PYRUN() {
  uv run --no-project "$HELPER" "$@"
}

# CATALOG <cle> [args...] : message destine au participant, jamais ecrit en
# dur (Mission 177, etape 5, contrainte "messages par les catalogues i18n/").
CATALOG() {
  PYRUN format-catalog "$CATALOG_FILE" "$@"
}

for DEP in "$CONFORMITY_CHECK" "$INDEXES_BUILD" "$JOURNAL_APPEND" "$STANDARD_RULE" "$HELPER" "$MISSION_INDEX_TEMPLATE" "$BUILD_STATE" "$BUILD_DIGEST" "$CATALOG_FILE"; do
  if [ ! -e "$DEP" ]; then
    echo "REFUS : dependance introuvable : $DEP" >&2
    exit 1
  fi
done

# --- Registre absent : cree depuis le gabarit avant toute ecriture de ligne
# (Mission 118, lot 5). Le gabarit est a la meme profondeur que le registre
# sous VAULT_ROOT (templates/ et projects/) : ses liens relatifs restent
# corrects tels quels, copie verbatim. ---
if [ ! -e "$REGISTRY" ]; then
  REGISTRY_TEMPLATE="$VAULT_ROOT/templates/project-registry-template.md"
  if [ ! -e "$REGISTRY_TEMPLATE" ]; then
    echo "REFUS : registre absent et gabarit introuvable : $REGISTRY_TEMPLATE" >&2
    exit 1
  fi
  mkdir -p "$PROJECTS_DIR"
  cp "$REGISTRY_TEMPLATE" "$REGISTRY"
fi

TARGET_PARENT="$(dirname "$TARGET")"
mkdir -p "$TARGET_PARENT"
TARGET_PARENT_ABS="$(cd "$TARGET_PARENT" && pwd)"

find_workspace_root() {
  local dir="$1"
  while [ -n "$dir" ]; do
    if [ -f "$dir/VAULT-ROOT.md" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    [ "$dir" = "/" ] && break
    dir="$(dirname "$dir")"
  done
  return 1
}

WORKSPACE_ROOT="$(find_workspace_root "$TARGET_PARENT_ABS")"
if [ -z "$WORKSPACE_ROOT" ]; then
  echo "REFUS : marqueur VAULT-ROOT.md introuvable en remontant depuis $TARGET_PARENT_ABS" >&2
  exit 1
fi

# --- project_id (registry v1 D1b) : date reelle + code mnemonique derive du display_name ---
TODAY="$(date +"%Y-%m-%d")"
TS="$(date +"%Y-%m-%dT%H:%M:%S%:z")"

CODE="$(printf '%s' "$DISPLAY_NAME" | tr '[:lower:]' '[:upper:]' | tr -cs 'A-Z0-9' '-' | sed -E 's/^-+//; s/-+$//' | cut -d'-' -f1-3)"
if [ -z "$CODE" ]; then
  echo "REFUS : impossible de deriver un code depuis display_name : $DISPLAY_NAME" >&2
  exit 1
fi
PROJECT_ID="${TODAY}-${CODE}"
FICHE="$PROJECTS_DIR/PROJECT-${PROJECT_ID}.md"

if [ -e "$FICHE" ]; then
  echo "REFUS : fiche projet deja existante pour cet identifiant : $FICHE" >&2
  exit 1
fi

# --- Squelette des sept fonctions (RULES-2026-08-26-142800 S2) ---
mkdir -p "$TARGET"/rules "$TARGET"/state "$TARGET"/missions "$TARGET"/decisions "$TARGET"/proposals "$TARGET"/knowledge "$TARGET"/handoffs
TARGET_ABS="$(cd "$TARGET" && pwd)"
PROJECT_REL="$(rel_path "$WORKSPACE_ROOT" "$TARGET_ABS")"
REL_STANDARD="$(rel_path "$TARGET_ABS" "$STANDARD_RULE")"
REL_VAULT="$(rel_path "$TARGET_ABS" "$VAULT_ROOT")"
VAULT_HEAD="$(git -C "$VAULT_ROOT" rev-parse HEAD 2>/dev/null || echo inconnu)"

# --- Registre de Missions du projet (Mission 175, etape 2) : le squelette
# promet "missions/ = Missions ET leurs rapports" (standard S2) mais ne
# deposait jamais le registre lui-meme -- un projet cree restait sans
# MISSION-INDEX.md tant qu'aucune Mission n'etait ecrite a la main. Copie
# verbatim (front matter, en-tetes, ## Liens), jamais une chaine en dur ici,
# meme motif que le registre du Vault plus haut. build-indexes.sh (plus bas)
# indexe ce fichier des qu'il existe sur disque, avant tout premier commit.
cp "$MISSION_INDEX_TEMPLATE" "$TARGET_ABS/missions/MISSION-INDEX.md"

cat > "$TARGET_ABS/README.md" <<EOF
---
type: readme
title: "$DISPLAY_NAME"
description: "Identite et point d'entree du projet $DISPLAY_NAME."
project_id: $PROJECT_ID
status: ACTIVE
created_at: "$TS"
---

# $DISPLAY_NAME

Point d'entree du projet, cree par \`tools/project-bootstrap.sh\` (Mission 061), conforme au [Standard de structure de projet]($REL_STANDARD) (hors Vault).

## Liens

- \`prescribed by\` — [Standard de structure de projet]($REL_STANDARD) (hors Vault)
EOF

# --- CLAUDE.md et AGENTS.md de niveau projet (Mission 173, Q17 : hierarchie
# a trois niveaux). Sous 60 lignes ; nom, but, conventions minimales, puis
# import de la methode (le CLAUDE.md de second-brain lui-meme, qui remonte
# jusqu'a la charte des roles) -- rien de plus, la methode se lit par la
# chaine d'imports, jamais recopiee ici. Contenu identique dans les deux
# fichiers. Rubrique ## Liens obligatoire : ces deux fichiers sont suivis
# par le depot de CE projet (contrairement au niveau workspace, hors de
# tout depot) et son propre gardien check-links.sh la refuse sinon
# (mesure directement : "section manquante" au premier essai). ---
PROJECT_GUIDE_CONTENT="# $DISPLAY_NAME

But : à compléter.

## Conventions

Rédiger en français ; identifiants machine en anglais.

## Écriture

Tout changement produit dans ce projet part d'une Mission écrite dans \`missions/\`. L'assistant du projet est en lecture seule : il ne dépose jamais de fichier. L'agent qui ouvre ce projet n'écrit rien de sa propre initiative en dehors de ce cadre.

## Méthode

@$REL_VAULT/CLAUDE.md

## Liens

- \`see also\` — [Second Brain]($REL_VAULT/CLAUDE.md) (hors Vault)"

printf '%s\n' "$PROJECT_GUIDE_CONTENT" > "$TARGET_ABS/CLAUDE.md"
printf '%s\n' "$PROJECT_GUIDE_CONTENT" > "$TARGET_ABS/AGENTS.md"

# --- Epingle des gardiens, repo: local sur ce Vault voisin (T01, ticket 02
# de la Mission 168) : jamais une URL distante -- reservee a l'atelier de
# l'Owner -- un chemin relatif mesure vers ce Vault, entry par entry, aucun
# reseau ni cache pre-commit implique. L'empreinte (VAULT_HEAD) est tracee
# dans la fiche projet ci-dessous, pas dans l'epingle elle-meme (T01). ---
cat > "$TARGET_ABS/.pre-commit-config.yaml" <<EOF
repos:
  - repo: local
    hooks:
      - id: vault-check-secrets
        name: "Vault : contrôle de secrets"
        entry: $REL_VAULT/tools/check-secrets.sh
        language: script
        always_run: true
        pass_filenames: false
      - id: vault-check-indexes-fresh
        name: "Vault : contrôle de fraîcheur des index"
        entry: $REL_VAULT/tools/check-indexes-fresh.sh
        language: script
        always_run: true
        pass_filenames: false
      - id: vault-check-index-weight
        name: "Vault : contrôle de poids des index"
        entry: $REL_VAULT/tools/check-index-weight.sh
        language: script
        always_run: true
        pass_filenames: false
      - id: vault-check-links
        name: "Vault : contrôle de liens"
        entry: $REL_VAULT/tools/check-links.sh
        language: script
        always_run: true
        pass_filenames: false
EOF

# --- Amorce de journal (patron existant : tools/append-journal.sh) ---
bash "$JOURNAL_APPEND" "$TARGET_ABS" "OPEN:project-bootstrap -- projet $DISPLAY_NAME cree par tools/project-bootstrap.sh (Mission 061)"

# --- Ligne de registre, avant mesure de conformite (l'inscription fait partie du contrat) ---
NEW_ROW="| $PROJECT_ID | $DISPLAY_NAME | ACTIVE | $PROJECT_REL | (mesure ci-dessous) |"
awk -v row="$NEW_ROW" '
  { print }
  /^\|---\|---\|---\|---\|---\|$/ && !done { print row; done=1 }
' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"

# --- Conformite mesuree par appel du script de l'etape 4, jamais devinee ---
CONFORMITY="$(bash "$CONFORMITY_CHECK" "$TARGET_ABS")"
CONFORMITY_STATUS="${CONFORMITY%%:*}"

# Reecrit la ligne de registre avec la mesure reelle.
FINAL_ROW="| $PROJECT_ID | $DISPLAY_NAME | ACTIVE | $PROJECT_REL | $CONFORMITY_STATUS |"
awk -v old="$NEW_ROW" -v new="$FINAL_ROW" '{ if ($0==old) print new; else print }' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"

# --- Fiche PROJECT-<project_id>.md, schema v2 ---
cat > "$FICHE" <<EOF
---
type: project-record
title: "$DISPLAY_NAME"
description: "Fiche de projet : $DISPLAY_NAME."
project_id: $PROJECT_ID
display_name: "$DISPLAY_NAME"
status: ACTIVE
relative_path: $PROJECT_REL
purpose: "$DISPLAY_NAME"
canonical_context: "$PROJECT_REL/README.md"
entry_point: "$PROJECT_REL/README.md"
last_verified: $TODAY
stale_after: 90d
structure_standard: "../rules/RULES-2026-08-26-142800-project-structure-standard.md"
conformity: $CONFORMITY_STATUS
last_conformity_check: $TODAY
vault_head: $VAULT_HEAD
---

# PROJECT — $DISPLAY_NAME

## Identity

- \`project_id\` : \`$PROJECT_ID\`
- \`display_name\` : $DISPLAY_NAME
- \`status\` : \`ACTIVE\`

## Location

- \`relative_path\` : \`$PROJECT_REL\`, relatif au parent du Vault.

## Entry Points

- Point d'entree : [\`$PROJECT_REL/README.md\`](../../$PROJECT_REL/README.md) (hors Vault)

## Conformite (registre v2)

- \`structure_standard\` : [Standard de structure de projet](../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- \`conformity\` : \`$CONFORMITY\`, mesure le \`$TODAY\` par \`tools/check-project-conformity.sh\`.

## Épingle des gardiens

- \`.pre-commit-config.yaml\` : \`repo: local\` sur ce Vault voisin (chemin relatif \`$REL_VAULT\`), quatre hooks (T01, ticket 02 de la Mission 168).
- \`vault_head\` (empreinte, pas un pin) : \`$VAULT_HEAD\`, tête du Vault au moment de la création de ce projet.

## Notes

Projet cree par \`tools/project-bootstrap.sh\` (Mission 061).

## Liens

- \`source\` — [\`$PROJECT_REL/README.md\`](../../$PROJECT_REL/README.md) (hors Vault)
- \`source\` — [Standard de structure de projet](../rules/RULES-2026-08-26-142800-project-structure-standard.md)
EOF

# --- Premiers index (script uniquement, jamais a la main). VAULT_ROOT, pas
# PROJECTS_DIR seul : projects/ n'est pas une racine de balayage a elle seule,
# le superseded-files.txt du Vault reste unique, a sa racine. ---
bash "$INDEXES_BUILD" "$TARGET_ABS" "$VAULT_ROOT" >/dev/null

# --- Fiche d'etat et digest du projet (Mission 175, etape 3) : le standard
# de structure promet "state/ = journal + fiche generee" mais le squelette
# ne deposait que l'amorce de journal -- ni STATE.md ni DIGEST.md n'existaient
# avant la premiere Mission, laissant une ouverture de session sans rien a
# lire. Les deux outils prennent deja un dossier-projet generique en argument
# (aucun chemin d'atelier en dur) : appeles ici tels quels, jamais copies a
# la main. Apres la regeneration des index ci-dessus, pour que "Documents
# recents" (STATE.md) et l'index frais soient coherents des la premiere
# lecture. ---
bash "$BUILD_STATE" "$TARGET_ABS" >/dev/null
bash "$BUILD_DIGEST" "$TARGET_ABS" >/dev/null

# --- .gitignore pour les liens vers l'assistant et les skills, POSE AVANT
# de creer les liens : sans cela, le premier `git add -A` de ce projet (fait
# par l'installateur juste apres cet appel) suit chaque jonction/lien comme
# un dossier ordinaire et tente d'indexer tout le contenu du CLONE en tant
# que fichiers du projet -- mesure directement : "Permission denied" en
# ecrivant .git/objects, l'index Git de deux depots se disputant les memes
# fichiers sur disque. Seuls les TROIS chemins que link-project cree
# ci-dessous sont exclus (jamais tout .claude/ ou .agents/ : un participant
# reste libre de suivre son propre .claude/settings.json dans ce projet). ---
GITIGNORE="$TARGET_ABS/.gitignore"
{
  echo "# Second Brain (Mission 173, Q17) -- liens vers l'assistant et les skills"
  echo "# de la methode, poses par tools/project-bootstrap.sh. Jamais suivis par ce"
  echo "# depot : ce sont des jonctions/liens vers second-brain, pas le contenu de"
  echo "# ce projet."
  echo "/.claude/skills/"
  echo "/.claude/agents/"
  echo "/.agents/skills/"
} > "$GITIGNORE"

# --- Liens vers l'assistant et les skills de la methode (Mission 173,
# Q17 : "rien dans le profil"). Poses ici, pour TOUT projet cree par ce
# script -- au moment de l'installation comme des annees plus tard, via le
# skill first-install/project-bootstrap -- jamais dans le profil de
# l'utilisateur. Lecture seule sur le Vault ($VAULT_ROOT) ; ecriture
# uniquement sous $TARGET_ABS. ---
LINK_OUTPUT="$(PYRUN link-project "$VAULT_ROOT" "$TARGET_ABS")" \
  || { echo "REFUS : la creation des liens (assistant/skills) dans $TARGET_ABS a echoue" >&2; exit 1; }

CLAUDE_CONFLICTS="$(printf '%s\n' "$LINK_OUTPUT" | grep '^CONFLICT SKILL ' | sed 's/^CONFLICT SKILL //')"
ASSISTANT_CONFLICTS="$(printf '%s\n' "$LINK_OUTPUT" | grep '^CONFLICT ASSISTANT ' | sed 's/^CONFLICT ASSISTANT //')"
CONFLICT_COUNT="$(printf '%s\n' "$LINK_OUTPUT" | grep '^CONFLICT_COUNT ' | sed 's/^CONFLICT_COUNT //')"
if [ -n "$CONFLICT_COUNT" ] && [ "$CONFLICT_COUNT" != "0" ]; then
  CATALOG "projectBootstrap.linkConflicts.header" "$CONFLICT_COUNT"
  if [ -n "$CLAUDE_CONFLICTS" ]; then
    printf '%s\n' "$CLAUDE_CONFLICTS" | while IFS= read -r p; do
      [ -n "$p" ] && CATALOG "projectBootstrap.linkConflicts.skillLabel" "$p"
    done
  fi
  if [ -n "$ASSISTANT_CONFLICTS" ]; then
    printf '%s\n' "$ASSISTANT_CONFLICTS" | while IFS= read -r p; do
      [ -n "$p" ] && CATALOG "projectBootstrap.linkConflicts.assistantLabel" "$p"
    done
  fi
  CATALOG "projectBootstrap.linkConflicts.howToOverride"
fi
printf '%s\n' "$LINK_OUTPUT" | grep '^FALLBACK 1' >/dev/null \
  && CATALOG "projectBootstrap.codexBudgetFallback"
printf '%s\n' "$LINK_OUTPUT" | grep '^ASSISTANT_SLUG_MISSING' >/dev/null \
  && CATALOG "projectBootstrap.assistantSlugMissing"

# --- Annonce de l'approbation d'import externe (Mission 173, Q17, etape 6).
# Meme annonce que le README/INSTALL.md : la creation de projet est le
# geste qui pose les liens sortant du dossier de travail, donc l'endroit le
# plus utile pour prevenir avant que Claude Code ne pose la question.
# Par le catalogue i18n/, jamais code en dur en anglais (Mission 177,
# etape 5 : ce message s'affichait en anglais au milieu d'une installation
# francaise, mesure a l'acceptation Owner du 2026-09-14). ---
CATALOG "projectBootstrap.externalImportApproval"

echo "$FICHE"
