#!/usr/bin/env bash
# Rend un projet conscient du Vault, en deux modes additifs (DECISION-2026-
# 08-31-210731 point 3, Decision 2026-09-17-000545 A2-A5) :
#
#   create : cree un nouveau projet conforme au standard de structure de
#            projet (sept fonctions, RULES-2026-08-26-142800-project-
#            structure-standard.md) : squelette, README.md d'identite, amorce
#            de journal, premiers index, fiche PROJECT-v2 et ligne de
#            registre. Refuse si la cible existe deja : l'organisation du
#            workspace est libre (232341 S1.6), ce script ne presume rien.
#   adopt  : sur un dossier existant, n'ecrit que ce qui manque (acte de
#            naissance et epingle, fichiers de pointage, prompt Pilot, ligne
#            de registre, fiche), grave la ligne de base datee, signale
#            l'existant, propose le plan de reorganisation et n'applique rien.
#            `adopt --git` sur un projet adopte sans Git ajoute le depot, le
#            hook et l'epingle active.
#   order  : sans ordre d'initiation, n'ecrit rien et rend l'ordre a remplir.
#
# Dans les deux modes, le projet recoit son acte de naissance : le bloc de
# commentaires en tete de .pre-commit-config.yaml (vault_id, vault_origin,
# vault_ref, vcs, et baseline a l'adoption), grammaire fixe lue par
# tools/resolve-vault.sh. Forme choisie par mesure : une cle de premier
# niveau fait avertir `pre-commit validate-config`, un bloc de commentaires
# non (Mission 184, mesure prealable).
#
# usage:
#   project-bootstrap.sh <chemin-cible> <display_name> [langue FR|EN|ES]
#       (appel historique : create, reponses portees par les arguments)
#   project-bootstrap.sh create <chemin-cible> <display_name> [langue] [--vcs none|git] [--ask]
#   project-bootstrap.sh adopt  <chemin-cible> [display_name] [langue] [--vcs none|git] [--ask] [--git]
#   (toute forme accepte aussi --lang FR|EN|ES)
#   project-bootstrap.sh --order <fichier-ordre> [langue]
#   project-bootstrap.sh order <dossier> [langue]
#
# --ask : pose nom, emplacement et Git avant d'ecrire (reponses lues sur
# l'entree standard, Entree = garder la proposition). Sans --ask, les
# reponses sont portees par les arguments ou par l'ordre (Mode: answered) ;
# si Git n'est porte par rien, la question Git est posee.
#
# Langue (Mission 177, etape 5) : parametre optionnel, defaut EN --
# retrocompatible avec tout appelant qui ne le fournit pas encore (tests
# existants compris, qui attendent alors les messages "Note: ..." en
# anglais). install.sh/install.ps1 passent la langue choisie au
# questionnaire ; sans ce parametre, les messages destines au participant
# de ce script restaient codes en dur en anglais, y compris au milieu d'une
# installation francaise ou espagnole (defaut mesure a l'acceptation Owner
# du 2026-09-14).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/relpath.sh"
. "$SCRIPT_DIR/resolve-vault.sh"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
I18N_DIR="$VAULT_ROOT/i18n"
HELPER="$VAULT_ROOT/tools/sb_installer_helper.py"
BASELINE_TOOL="$VAULT_ROOT/tools/project_baseline.py"
PILOT_PROMPT_TEMPLATE="$VAULT_ROOT/templates/session-opening-prompt-template.md"
CHARTER="$VAULT_ROOT/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"

usage() {
  echo "usage: project-bootstrap.sh [create|adopt] <chemin-cible> <display_name> [langue FR|EN|ES] [--vcs none|git] [--ask] [--git]" >&2
  echo "       project-bootstrap.sh --order <fichier-ordre> [langue]" >&2
  echo "       project-bootstrap.sh order <dossier> [langue]" >&2
}

# --- Arguments ---------------------------------------------------------------
SUBCOMMAND=""
case "${1:-}" in
  create|adopt|order) SUBCOMMAND="$1"; shift ;;
esac
EXPLICIT=0
[ -n "$SUBCOMMAND" ] && EXPLICIT=1
MODE="${SUBCOMMAND:-create}"
VCS=""
ASK=0
ORDER_FILE=""
ADD_GIT=0
LANG_OPT=""
P1=""
P2=""
P3=""
NPOS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --vcs)
      [ $# -ge 2 ] || { usage; exit 1; }
      VCS="$2"; shift 2 ;;
    --vcs=*) VCS="${1#--vcs=}"; shift ;;
    --ask) ASK=1; shift ;;
    --order)
      [ $# -ge 2 ] || { usage; exit 1; }
      ORDER_FILE="$2"; EXPLICIT=1; shift 2 ;;
    --git) ADD_GIT=1; shift ;;
    --lang)
      [ $# -ge 2 ] || { usage; exit 1; }
      LANG_OPT="$2"; shift 2 ;;
    -*) echo "REFUS : option inconnue : $1" >&2; usage; exit 1 ;;
    *)
      NPOS=$((NPOS + 1))
      case "$NPOS" in
        1) P1="$1" ;;
        2) P2="$1" ;;
        3) P3="$1" ;;
        *) echo "REFUS : argument en trop : $1" >&2; usage; exit 1 ;;
      esac
      shift ;;
  esac
done

if [ -n "$ORDER_FILE" ]; then
  # --order <fichier> [langue] : la langue est le seul positionnel admis.
  LANGUAGE="${P1:-EN}"
  TARGET=""
  DISPLAY_NAME=""
elif [ "$MODE" = "order" ]; then
  TARGET="$P1"
  DISPLAY_NAME=""
  LANGUAGE="${P2:-EN}"
elif [ "$MODE" = "adopt" ] && [ -z "$P3" ] && printf '%s' "$P2" | grep -qixE 'fr|en|es'; then
  # adopt <cible> <langue> : le nom est optionnel en adoption.
  TARGET="$P1"
  DISPLAY_NAME=""
  LANGUAGE="$P2"
else
  TARGET="$P1"
  DISPLAY_NAME="$P2"
  LANGUAGE="${P3:-EN}"
fi
[ -n "$LANG_OPT" ] && LANGUAGE="$LANG_OPT"

CATALOG_FILE="$I18N_DIR/catalog.$(printf '%s' "$LANGUAGE" | tr '[:upper:]' '[:lower:]').json"
if [ ! -e "$CATALOG_FILE" ]; then
  CATALOG_FILE="$I18N_DIR/catalog.en.json"
fi

PYRUN() {
  uv run --no-project "$HELPER" "$@"
}

# CATALOG <cle> [args...] : message destine au participant, jamais ecrit en
# dur (Mission 177, etape 5, contrainte "messages par les catalogues i18n/").
CATALOG() {
  PYRUN format-catalog "$CATALOG_FILE" "$@"
}

# ask_value <cle-catalogue> <defaut> : question posee sur stderr, reponse lue
# sur l'entree standard ; Entree ou fin d'entree = defaut.
ask_value() {
  local answer=""
  CATALOG "$1" "$2" >&2
  IFS= read -r answer || answer=""
  answer="$(printf '%s' "$answer" | tr -d '\r')"
  if [ -n "$answer" ]; then printf '%s\n' "$answer"; else printf '%s\n' "$2"; fi
}

vid_ensure "$VAULT_ROOT"
VAULT_ID="$(vid_get "$VAULT_ROOT" vault_id)"
VAULT_ORIGIN="$(vid_get "$VAULT_ROOT" vault_origin)"
VAULT_REF="$(vid_ref "$VAULT_ROOT")"

# --- order : l'ordre d'initiation a remplir, rien d'ecrit (Decision 000545,
# A3 : sans ordre, l'agent s'arrete et propose l'adoption) ---------------------
if [ "$MODE" = "order" ]; then
  if [ -z "$TARGET" ]; then
    usage
    exit 1
  fi
  ORDER_DIR="$(cd "$TARGET" 2>/dev/null && pwd || printf '%s' "$TARGET")"
  ORDER_TYPE="create"
  [ -d "$TARGET" ] && ORDER_TYPE="adopt"
  ORDER_GIT="none | git"
  [ -e "$TARGET/.git" ] && ORDER_GIT="git"
  CATALOG "projectBootstrap.order.header"
  echo ""
  echo "Ordre d'initiation"
  echo "- Type : $ORDER_TYPE"
  echo "- Mode : answered"
  echo "- Nom : $(basename "$ORDER_DIR")"
  echo "- Emplacement : $(dirname "$ORDER_DIR")"
  echo "- Vault + construction : vault_id=$VAULT_ID, vault_origin=$VAULT_ORIGIN, vault_ref=$VAULT_REF"
  echo "- Git : $ORDER_GIT"
  echo "- Objet : <à remplir>"
  echo "- Autorisation Owner datée : <verbatim de l'Owner, avec sa date AAAA-MM-JJ>"
  echo ""
  CATALOG "projectBootstrap.order.footer"
  exit 0
fi

# --- --order <fichier> : l'ordre est la source (Decision 000545, A5) -----------
ORDER_PURPOSE=""
ORDER_AUTH=""
if [ -n "$ORDER_FILE" ]; then
  if [ ! -f "$ORDER_FILE" ]; then
    echo "REFUS : ordre d'initiation introuvable : $ORDER_FILE" >&2
    exit 1
  fi
  order_field() {
    tr -d '\r' < "$ORDER_FILE" \
      | sed -n "s/^[-*[:space:]]*$1[[:space:]]*:[[:space:]]*//p" \
      | head -n 1 | sed 's/[[:space:]]*$//; s/^`//; s/`$//'
  }
  O_TYPE="$(order_field 'Type')"
  O_MODE="$(order_field 'Mode')"
  O_NAME="$(order_field 'Nom')"
  O_PLACE="$(order_field 'Emplacement')"
  O_VAULT="$(order_field 'Vault + construction')"
  O_GIT="$(order_field 'Git')"
  ORDER_PURPOSE="$(order_field 'Objet')"
  ORDER_AUTH="$(order_field 'Autorisation Owner datée')"
  case "$O_TYPE" in
    create|adopt) MODE="$O_TYPE" ;;
    *) echo "REFUS : ordre d'initiation : Type doit valoir create ou adopt (lu : ${O_TYPE:-absent})" >&2; exit 1 ;;
  esac
  case "$O_MODE" in
    answered) ASK=0 ;;
    ask) ASK=1 ;;
    *) echo "REFUS : ordre d'initiation : Mode doit valoir answered ou ask (lu : ${O_MODE:-absent})" >&2; exit 1 ;;
  esac
  if ! printf '%s' "$ORDER_AUTH" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
    echo "REFUS : ordre d'initiation sans autorisation Owner datée (AAAA-MM-JJ)" >&2
    exit 1
  fi
  O_VAULT_ID="$(printf '%s' "$O_VAULT" | sed -n 's/.*vault_id=\([^ ,;]*\).*/\1/p')"
  if [ "$O_VAULT_ID" != "$VAULT_ID" ]; then
    echo "REFUS : l'ordre nomme le Vault ${O_VAULT_ID:-(aucun)}, ce Vault est $VAULT_ID" >&2
    exit 1
  fi
  case "$O_GIT" in
    none|git) VCS="$O_GIT" ;;
    *) VCS="" ;;
  esac
  if [ "$ASK" = "0" ] && { [ -z "$O_NAME" ] || [ -z "$O_PLACE" ]; }; then
    echo "REFUS : ordre d'initiation en mode answered sans Nom ou sans Emplacement" >&2
    exit 1
  fi
  TARGET="${O_PLACE%/}/$O_NAME"
  DISPLAY_NAME="$O_NAME"
fi

if [ -z "$TARGET" ]; then
  usage
  exit 1
fi
if [ "$MODE" = "adopt" ] && [ -z "$DISPLAY_NAME" ]; then
  DISPLAY_NAME="$(basename "$TARGET")"
fi
if [ -z "$DISPLAY_NAME" ]; then
  usage
  exit 1
fi

# --- Question avant d'ecrire (Decision 000545, A4) : nom et emplacement
# proposes, l'Owner confirme ou change. ---------------------------------------
if [ "$ASK" = "1" ]; then
  ASK_NAME="$(ask_value "projectBootstrap.question.name" "$(basename "$TARGET")")"
  ASK_PLACE="$(ask_value "projectBootstrap.question.location" "$(dirname "$TARGET")")"
  if [ "$DISPLAY_NAME" = "$(basename "$TARGET")" ]; then
    DISPLAY_NAME="$ASK_NAME"
  fi
  TARGET="${ASK_PLACE%/}/$ASK_NAME"
fi

# --- Question Git si rien ne la porte (Decision 000545, A4) ------------------
if [ -z "$VCS" ]; then
  if [ "$EXPLICIT" = "0" ]; then
    # Appel historique (installeurs) : le depot Git est toujours cree.
    VCS="git"
  else
    VCS_DEFAULT="none"
    [ -e "$TARGET/.git" ] && VCS_DEFAULT="git"
    VCS="$(ask_value "projectBootstrap.question.git" "$VCS_DEFAULT")"
  fi
fi
case "$VCS" in
  none|git) : ;;
  *) echo "REFUS : vcs doit valoir none ou git (lu : $VCS)" >&2; exit 1 ;;
esac

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

if [ "$MODE" = "create" ] && [ -e "$TARGET" ]; then
  echo "REFUS : la cible existe deja : $TARGET" >&2
  exit 1
fi
if [ "$MODE" = "adopt" ] && [ ! -d "$TARGET" ]; then
  echo "REFUS : la cible a adopter n'existe pas (mode create) : $TARGET" >&2
  exit 1
fi

CONFORMITY_CHECK="$VAULT_ROOT/tools/check-project-conformity.sh"
INDEXES_BUILD="$VAULT_ROOT/tools/build-indexes.sh"
JOURNAL_APPEND="$VAULT_ROOT/tools/append-journal.sh"
PROJECTS_DIR="$VAULT_ROOT/projects"
REGISTRY="$PROJECTS_DIR/PROJECT-REGISTRY.md"
STANDARD_RULE="$VAULT_ROOT/rules/RULES-2026-08-26-142800-project-structure-standard.md"
MISSION_INDEX_TEMPLATE="$VAULT_ROOT/templates/mission-index-template.md"
BUILD_STATE="$VAULT_ROOT/tools/build-state.sh"
BUILD_DIGEST="$VAULT_ROOT/tools/build-digest.sh"

for DEP in "$CONFORMITY_CHECK" "$INDEXES_BUILD" "$JOURNAL_APPEND" "$STANDARD_RULE" "$HELPER" "$BASELINE_TOOL" "$MISSION_INDEX_TEMPLATE" "$BUILD_STATE" "$BUILD_DIGEST" "$CATALOG_FILE" "$PILOT_PROMPT_TEMPLATE" "$CHARTER"; do
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

WORKSPACE_ROOT="$(rv_find_marker "$TARGET_PARENT_ABS" || true)"
if [ -z "$WORKSPACE_ROOT" ]; then
  echo "REFUS : marqueur VAULT-ROOT.md introuvable en remontant depuis $TARGET_PARENT_ABS" >&2
  exit 1
fi

TODAY="$(date +"%Y-%m-%d")"
TS="$(date +"%Y-%m-%dT%H:%M:%S%z")"
STAMP="$(date +"%Y-%m-%d-%H%M%S")"

# --- Ligne de base datee (adopt) : gravee AVANT toute ecriture, pour ne
# lister que l'existant. Deposee apres, sous le nom que l'acte porte. ---
BASELINE_NAME=""
BASELINE_TMP=""
CONFIG_EXISTED=0
[ -e "$TARGET/.pre-commit-config.yaml" ] && CONFIG_EXISTED=1
if [ "$MODE" = "adopt" ] && [ "$CONFIG_EXISTED" = "0" ]; then
  BASELINE_NAME=".vault-baseline-$STAMP.tsv"
  BASELINE_TMP="$(mktemp)"
  BASELINE_COUNT="$(uv run --no-project "$BASELINE_TOOL" write "$TARGET" "$BASELINE_TMP")" \
    || { echo "REFUS : ligne de base non ecrite pour $TARGET" >&2; rm -f "$BASELINE_TMP"; exit 1; }
fi

if [ "$MODE" = "create" ]; then
  # --- Squelette des sept fonctions (RULES-2026-08-26-142800 S2) ---
  mkdir -p "$TARGET"/rules "$TARGET"/state "$TARGET"/missions "$TARGET"/decisions "$TARGET"/proposals "$TARGET"/knowledge "$TARGET"/handoffs
fi
TARGET_ABS="$(cd "$TARGET" && pwd)"
PROJECT_REL="$(rel_path "$WORKSPACE_ROOT" "$TARGET_ABS")"
REL_STANDARD="$(rel_path "$TARGET_ABS" "$STANDARD_RULE")"
REL_VAULT="$(rel_path "$TARGET_ABS" "$VAULT_ROOT")"
REL_CHARTER="$(rel_path "$TARGET_ABS" "$CHARTER")"

ADDED=""
EXISTING=""
note_added() { ADDED="${ADDED}${ADDED:+
}$1"; }
note_existing() { EXISTING="${EXISTING}${EXISTING:+
}$1"; }

# --- Identite du projet : reprise si deja inscrit (adopt idempotent) ---
REGISTERED=0
PROJECT_ID=""
if grep -qF "| $PROJECT_REL |" "$REGISTRY"; then
  REGISTERED=1
  PROJECT_ID="$(grep -F "| $PROJECT_REL |" "$REGISTRY" | head -n 1 | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
fi
if [ "$MODE" = "create" ] && [ "$REGISTERED" = "1" ]; then
  echo "REFUS : chemin deja inscrit au registre : $PROJECT_REL" >&2
  exit 1
fi

if [ -z "$PROJECT_ID" ]; then
  # project_id (registry v1 D1b) : date reelle + code mnemonique derive du display_name
  CODE="$(printf '%s' "$DISPLAY_NAME" | tr '[:lower:]' '[:upper:]' | tr -cs 'A-Z0-9' '-' | sed -E 's/^-+//; s/-+$//' | cut -d'-' -f1-3)"
  if [ -z "$CODE" ]; then
    echo "REFUS : impossible de deriver un code depuis display_name : $DISPLAY_NAME" >&2
    exit 1
  fi
  PROJECT_ID="${TODAY}-${CODE}"
fi
FICHE="$PROJECTS_DIR/PROJECT-${PROJECT_ID}.md"

if [ "$REGISTERED" = "0" ] && [ -e "$FICHE" ]; then
  echo "REFUS : fiche projet deja existante pour cet identifiant : $FICHE" >&2
  exit 1
fi

# --- Acte de naissance et epingle des gardiens (Decision 000545, A1) ; repo:
# local sur ce Vault (T01, ticket 02 de la Mission 168) : jamais une URL
# distante, un chemin relatif mesure vers ce Vault, entry par entry, aucun
# reseau ni cache pre-commit implique. vault_ref remplace l'empreinte
# vault_head que la fiche portait. ---
write_certificate_config() {
  {
    echo "$RV_CERT_HEADER"
    echo "# vault_id: $VAULT_ID"
    echo "# vault_origin: $VAULT_ORIGIN"
    echo "# vault_ref: $VAULT_REF"
    echo "# vcs: $VCS"
    [ -n "$BASELINE_NAME" ] && echo "# baseline: $BASELINE_NAME"
    cat <<EOF
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
  } > "$TARGET_ABS/.pre-commit-config.yaml"
}

CONFIG="$TARGET_ABS/.pre-commit-config.yaml"
VCS_SWITCHED=0
if [ "$CONFIG_EXISTED" = "0" ]; then
  write_certificate_config
  note_added ".pre-commit-config.yaml"
  if [ -n "$BASELINE_NAME" ]; then
    mv "$BASELINE_TMP" "$TARGET_ABS/$BASELINE_NAME"
    note_added "$BASELINE_NAME ($BASELINE_COUNT)"
  fi
elif bc_file_has_certificate "$CONFIG"; then
  note_existing ".pre-commit-config.yaml"
  CURRENT_VCS="$(bc_get "$CONFIG" vcs)"
  if [ "$ADD_GIT" = "1" ] && [ "$CURRENT_VCS" = "none" ]; then
    # adopt --git : seul geste qui retouche un fichier deja ecrit par ce
    # script -- la ligne vcs de l'acte, la fiche et la ligne de registre.
    VCS="git"
    CONFIG_TMP="$(mktemp)"
    sed 's/^# vcs: none$/# vcs: git/' "$CONFIG" > "$CONFIG_TMP" && cat "$CONFIG_TMP" > "$CONFIG"
    rm -f "$CONFIG_TMP"
    VCS_SWITCHED=1
  elif [ -n "$CURRENT_VCS" ]; then
    VCS="$CURRENT_VCS"
  fi
else
  note_existing ".pre-commit-config.yaml"
  CATALOG "projectBootstrap.adopt.pinWithoutCertificate" ".pre-commit-config.yaml"
  echo "$RV_CERT_HEADER"
  echo "# vault_id: $VAULT_ID"
  echo "# vault_origin: $VAULT_ORIGIN"
  echo "# vault_ref: $VAULT_REF"
  echo "# vcs: $VCS"
  [ -n "$BASELINE_TMP" ] && rm -f "$BASELINE_TMP"
fi

if [ "$MODE" = "create" ]; then
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
fi

# --- CLAUDE.md et AGENTS.md de niveau projet (Mission 173, Q17 : hierarchie
# a trois niveaux). Sous 60 lignes ; nom, but, conventions minimales, puis
# import de la methode (le CLAUDE.md de second-brain lui-meme, qui remonte
# jusqu'a la charte des roles) -- rien de plus, la methode se lit par la
# chaine d'imports, jamais recopiee ici. Contenu identique dans les deux
# fichiers. Le chemin du Vault est celui de l'acte (mesure ci-dessus), jamais
# une proximite supposee (Decision 000545, A1). Rubrique ## Liens
# obligatoire : ces deux fichiers sont suivis par le depot de CE projet et
# son propre gardien check-links.sh la refuse sinon. En adoption, un fichier
# present est laisse tel quel. ---
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

for GUIDE in CLAUDE.md AGENTS.md; do
  if [ -e "$TARGET_ABS/$GUIDE" ]; then
    note_existing "$GUIDE"
  else
    printf '%s\n' "$PROJECT_GUIDE_CONTENT" > "$TARGET_ABS/$GUIDE"
    note_added "$GUIDE"
  fi
done

# --- Prompt Pilot du projet (Decision 000545, A4/A6) : le prompt commun vit
# dans le Vault (source unique) ; ce fichier le personnalise sur le disque --
# chemin du projet, identite du Vault, canari a rendre a l'ouverture. ---
PILOT_PROMPT="$TARGET_ABS/state/PILOT-PROMPT.md"
CANARY="pp-$(od -An -N6 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
REL_PROMPT_TEMPLATE="$(rel_path "$TARGET_ABS/state" "$PILOT_PROMPT_TEMPLATE")"
REL_CHARTER_FROM_STATE="$(rel_path "$TARGET_ABS/state" "$CHARTER")"
if [ -e "$PILOT_PROMPT" ]; then
  note_existing "state/PILOT-PROMPT.md"
  CANARY="$(tr -d '\r' < "$PILOT_PROMPT" | sed -n 's/^canary: "\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' | head -n 1)"
else
  mkdir -p "$TARGET_ABS/state"
  cat > "$PILOT_PROMPT" <<EOF
---
type: pilot-prompt
title: "Prompt Pilot — $DISPLAY_NAME"
description: "Personnalisation, sur le disque, du prompt Pilot commun pour ce projet : chemin, identité du Vault, canari d'ouverture."
status: generated
project_id: $PROJECT_ID
canary: "$CANARY"
vault_id: "$VAULT_ID"
vault_ref: "$VAULT_REF"
generated_at: "$TS"
---

# PROMPT PILOT — $DISPLAY_NAME

Généré par \`tools/project-bootstrap.sh\`. Ne pas éditer à la main : le prompt commun vit dans le Vault, ce fichier ne porte que ce qui est propre à ce projet.

- Chemin du projet : \`$TARGET_ABS\`
- Vault : \`$VAULT_ID\`, construit au commit \`$VAULT_REF\`
- Canari : \`$CANARY\`

## Ouverture Pilot

Le rôle Pilot exige l'application de bureau : le serveur MCP du Vault n'existe pas dans le navigateur.

1. Appelle \`list_allowed_directories\` du serveur \`second-brain-vault\` : la liste doit contenir le chemin du projet ci-dessus. Compare le commit du Vault qu'il rend à celui ci-dessus ; un écart se dit, il ne bloque pas.
2. Lis ce fichier et rends le canari \`$CANARY\` : c'est la preuve que la lecture a eu lieu.
3. Applique le [prompt commun]($REL_PROMPT_TEMPLATE) et la [charte des rôles]($REL_CHARTER_FROM_STATE).

## Liens

- \`see also\` — [Prompt Pilot commun]($REL_PROMPT_TEMPLATE) (hors Vault)
- \`see also\` — [Charte des rôles et détermination de session]($REL_CHARTER_FROM_STATE) (hors Vault)
EOF
  note_added "state/PILOT-PROMPT.md"
fi

# --- .gitignore pour les liens vers l'assistant et les skills, POSE AVANT
# de creer les liens : sans cela, le premier `git add -A` de ce projet (fait
# par l'installateur juste apres cet appel) suit chaque jonction/lien comme
# un dossier ordinaire et tente d'indexer tout le contenu du CLONE en tant
# que fichiers du projet -- mesure directement : "Permission denied" en
# ecrivant .git/objects, l'index Git de deux depots se disputant les memes
# fichiers sur disque. Seuls les TROIS chemins que link-project cree
# ci-dessous sont exclus (jamais tout .claude/ ou .agents/ : un participant
# reste libre de suivre son propre .claude/settings.json dans ce projet).
# En adoption, un .gitignore existant n'est jamais modifie : sans les trois
# exclusions, les liens ne sont pas poses et les lignes sont rendues. ---
GITIGNORE="$TARGET_ABS/.gitignore"
LINKS_OK=1
if [ -e "$GITIGNORE" ]; then
  note_existing ".gitignore"
  for LINE in "/.claude/skills/" "/.claude/agents/" "/.agents/skills/"; do
    tr -d '\r' < "$GITIGNORE" | grep -qxF -- "$LINE" || LINKS_OK=0
  done
  if [ "$LINKS_OK" = "0" ]; then
    CATALOG "projectBootstrap.adopt.gitignoreMissingEntries"
    echo "/.claude/skills/"
    echo "/.claude/agents/"
    echo "/.agents/skills/"
  fi
else
  {
    echo "# Second Brain (Mission 173, Q17) -- liens vers l'assistant et les skills"
    echo "# de la methode, poses par tools/project-bootstrap.sh. Jamais suivis par ce"
    echo "# depot : ce sont des jonctions/liens vers second-brain, pas le contenu de"
    echo "# ce projet."
    echo "/.claude/skills/"
    echo "/.claude/agents/"
    echo "/.agents/skills/"
  } > "$GITIGNORE"
  note_added ".gitignore"
fi

if [ "$MODE" = "create" ]; then
  # --- Amorce de journal (patron existant : tools/append-journal.sh) ---
  bash "$JOURNAL_APPEND" "$TARGET_ABS" "OPEN:project-bootstrap -- projet $DISPLAY_NAME cree par tools/project-bootstrap.sh (Mission 061)"
fi

# --- Depot Git et hook (vcs: git) : le hook n'est jamais pose si vcs: none
# (Decision 000545, A4 -- controles par commande). ---
HOOK_NOTE=0
if [ "$VCS" = "git" ]; then
  if [ ! -e "$TARGET_ABS/.git" ] && command -v git >/dev/null 2>&1; then
    git -C "$TARGET_ABS" init -q -b main >/dev/null 2>&1 \
      || { git -C "$TARGET_ABS" init -q >/dev/null 2>&1 && git -C "$TARGET_ABS" symbolic-ref HEAD refs/heads/main; }
    [ -e "$TARGET_ABS/.git" ] && note_added ".git"
  fi
  if [ -e "$TARGET_ABS/.git" ] && command -v pre-commit >/dev/null 2>&1; then
    (cd "$TARGET_ABS" && pre-commit install >/dev/null 2>&1) || HOOK_NOTE=1
  else
    HOOK_NOTE=1
  fi
fi

# --- Ligne de registre, avant mesure de conformite (l'inscription fait
# partie du contrat). Colonne vcs (Decision 000545, A2) si le registre la
# porte ; un registre anterieur a cinq colonnes garde sa forme. ---
REGISTRY_HAS_VCS=0
grep -qxF '|---|---|---|---|---|---|' "$REGISTRY" && REGISTRY_HAS_VCS=1
registry_row() {
  if [ "$REGISTRY_HAS_VCS" = "1" ]; then
    printf '| %s | %s | ACTIVE | %s | %s | %s |' "$PROJECT_ID" "$DISPLAY_NAME" "$PROJECT_REL" "$VCS" "$1"
  else
    printf '| %s | %s | ACTIVE | %s | %s |' "$PROJECT_ID" "$DISPLAY_NAME" "$PROJECT_REL" "$1"
  fi
}
replace_registry_row() {
  # remplace la ligne du chemin PROJECT_REL par $1
  awk -v rel="| $PROJECT_REL |" -v new="$1" '{ if (index($0, rel) > 0 && !done) { print new; done=1 } else print }' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
}
if [ "$REGISTERED" = "0" ]; then
  NEW_ROW="$(registry_row "(mesure ci-dessous)")"
  if [ "$REGISTRY_HAS_VCS" = "1" ]; then
    SEPARATOR='|---|---|---|---|---|---|'
  else
    SEPARATOR='|---|---|---|---|---|'
  fi
  awk -v row="$NEW_ROW" -v sep="$SEPARATOR" '
    { print }
    $0 == sep && !done { print row; done=1 }
  ' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
fi

# --- Conformite mesuree par appel du script de l'etape 4, jamais devinee ---
CONFORMITY="$(bash "$CONFORMITY_CHECK" "$TARGET_ABS")"
CONFORMITY_STATUS="${CONFORMITY%%:*}"

# Reecrit la ligne de registre avec la mesure reelle.
if [ "$REGISTERED" = "0" ] || [ "$VCS_SWITCHED" = "1" ]; then
  replace_registry_row "$(registry_row "$CONFORMITY_STATUS")"
fi

# --- Fiche PROJECT-<project_id>.md, schema v2 ---
if [ "$REGISTERED" = "1" ]; then
  if [ "$VCS_SWITCHED" = "1" ] && [ -f "$FICHE" ]; then
    FICHE_TMP="$(mktemp)"
    sed 's/^vcs: none$/vcs: git/' "$FICHE" > "$FICHE_TMP" && cat "$FICHE_TMP" > "$FICHE"
    rm -f "$FICHE_TMP"
  fi
else
  if [ "$MODE" = "adopt" ]; then
    ORIGIN_NOTE="Projet adopté par \`tools/project-bootstrap.sh adopt\` : fichiers existants laissés tels quels, réorganisation en sept fonctions proposée, non appliquée."
    ENTRY_POINT="$PROJECT_REL"
  else
    ORIGIN_NOTE="Projet cree par \`tools/project-bootstrap.sh\` (Mission 061)."
    ENTRY_POINT="$PROJECT_REL/README.md"
  fi
  {
    cat <<EOF
---
type: project-record
title: "$DISPLAY_NAME"
description: "Fiche de projet : $DISPLAY_NAME."
project_id: $PROJECT_ID
display_name: "$DISPLAY_NAME"
status: ACTIVE
relative_path: $PROJECT_REL
purpose: "${ORDER_PURPOSE:-$DISPLAY_NAME}"
canonical_context: "$ENTRY_POINT"
entry_point: "$ENTRY_POINT"
last_verified: $TODAY
stale_after: 90d
structure_standard: "../rules/RULES-2026-08-26-142800-project-structure-standard.md"
conformity: $CONFORMITY_STATUS
last_conformity_check: $TODAY
vcs: $VCS
vault_id: $VAULT_ID
vault_ref: $VAULT_REF
bootstrap_mode: $MODE
EOF
    [ -n "$BASELINE_NAME" ] && echo "baseline: $BASELINE_NAME"
    [ -n "$ORDER_AUTH" ] && printf 'initiation_order: "%s"\n' "$(printf '%s' "$ORDER_AUTH" | tr '"' "'")"
    [ "$MODE" = "adopt" ] && echo "reorganisation: proposed-not-applied"
    cat <<EOF
---

# PROJECT — $DISPLAY_NAME

## Identity

- \`project_id\` : \`$PROJECT_ID\`
- \`display_name\` : $DISPLAY_NAME
- \`status\` : \`ACTIVE\`
- \`vcs\` : \`$VCS\`

## Location

- \`relative_path\` : \`$PROJECT_REL\`, relatif au parent du Vault.

## Entry Points

- Point d'entree : \`$ENTRY_POINT\` (hors Vault)

## Conformite (registre v2)

- \`structure_standard\` : [Standard de structure de projet](../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- \`conformity\` : \`$CONFORMITY\`, mesure le \`$TODAY\` par \`tools/check-project-conformity.sh\`.

## Acte de naissance

- \`.pre-commit-config.yaml\` : acte (\`vault_id\` \`$VAULT_ID\`, \`vault_ref\` \`$VAULT_REF\`, \`vcs\` \`$VCS\`) et épingle \`repo: local\` sur ce Vault (chemin relatif \`$REL_VAULT\`), quatre hooks (T01, ticket 02 de la Mission 168).

## Notes

$ORIGIN_NOTE

## Liens

- \`source\` — [Standard de structure de projet](../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- \`source\` — [Décision — Initiation et adoption de projet, acte de naissance](../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
EOF
  } > "$FICHE"
fi

# --- Premiers index (script uniquement, jamais a la main). VAULT_ROOT, pas
# PROJECTS_DIR seul : projects/ n'est pas une racine de balayage a elle seule,
# le superseded-files.txt du Vault reste unique, a sa racine. En adoption,
# seuls les index absents sont ecrits (--only-missing) : un index existant
# n'est jamais reecrit, et les fichiers ajoutes ci-dessus passent le gardien
# de fraicheur des leur premier commit. ---
if [ "$MODE" = "create" ]; then
  bash "$INDEXES_BUILD" "$TARGET_ABS" "$VAULT_ROOT" >/dev/null
else
  INDEXES_BEFORE="$(cd "$TARGET_ABS" && find . -name index.md -not -path './.git/*' 2>/dev/null | LC_ALL=C sort)"
  bash "$INDEXES_BUILD" --only-missing "$TARGET_ABS" >/dev/null
  bash "$INDEXES_BUILD" "$VAULT_ROOT" >/dev/null
  INDEXES_AFTER="$(cd "$TARGET_ABS" && find . -name index.md -not -path './.git/*' 2>/dev/null | LC_ALL=C sort)"
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    case "
$INDEXES_BEFORE
" in
      *"
$p
"*) : ;;
      *) note_added "${p#./}" ;;
    esac
  done <<INDEXES_EOF
$INDEXES_AFTER
INDEXES_EOF
fi

if [ "$MODE" = "create" ]; then
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
fi

# --- Liens vers l'assistant et les skills de la methode (Mission 173,
# Q17 : "rien dans le profil"). Poses ici, pour TOUT projet cree par ce
# script -- au moment de l'installation comme des annees plus tard, via le
# skill first-install/project-bootstrap -- jamais dans le profil de
# l'utilisateur. Lecture seule sur le Vault ($VAULT_ROOT) ; ecriture
# uniquement sous $TARGET_ABS. ---
if [ "$LINKS_OK" = "1" ]; then
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
fi

# --- Compte rendu des modes explicites (create/adopt/--order) : l'appel
# historique des installeurs reste muet ici, son journal est plafonne. ---
if [ "$EXPLICIT" = "1" ]; then
  if [ "$HOOK_NOTE" = "1" ]; then
    CATALOG "projectBootstrap.hookMissing" "$TARGET_ABS"
  fi
  if [ "$VCS_SWITCHED" = "1" ]; then
    CATALOG "projectBootstrap.adopt.gitSwitched"
  fi
  if [ "$MODE" = "adopt" ]; then
    if [ -n "$EXISTING" ]; then
      printf '%s\n' "$EXISTING" | while IFS= read -r p; do
        [ -n "$p" ] && CATALOG "projectBootstrap.adopt.existing" "$p"
      done
    fi
    if [ -n "$ADDED" ]; then
      printf '%s\n' "$ADDED" | while IFS= read -r p; do
        [ -n "$p" ] && CATALOG "projectBootstrap.adopt.added" "$p"
      done
    fi

    # --- Plan de reorganisation en sept fonctions : propose, jamais applique
    # (210731 point 3, Decision 000545 A4). ---
    CATALOG "projectBootstrap.adopt.planHeader"
    PLAN_COUNT=0
    for FN in rules state missions decisions proposals knowledge handoffs; do
      if [ ! -d "$TARGET_ABS/$FN" ]; then
        CATALOG "projectBootstrap.adopt.planCreate" "$FN"
        PLAN_COUNT=$((PLAN_COUNT + 1))
      fi
    done
    if [ ! -e "$TARGET_ABS/README.md" ]; then
      CATALOG "projectBootstrap.adopt.planCreate" "README.md"
      PLAN_COUNT=$((PLAN_COUNT + 1))
    fi
    for F in "$TARGET_ABS"/*; do
      [ -f "$F" ] || continue
      B="$(basename "$F")"
      DEST=""
      case "$B" in
        README.md|AGENTS.md|CLAUDE.md|LICENSE*|.*) DEST="" ;;
        MISSION-*|*mission*.md) DEST="missions" ;;
        DECISION-*|*decision*.md) DEST="decisions" ;;
        HANDOFF-*|*handoff*.md) DEST="handoffs" ;;
        RULES-*|*rule*.md) DEST="rules" ;;
        PROPOSAL-*|*proposal*.md) DEST="proposals" ;;
        STATE*|DIGEST*|*journal*.md) DEST="state" ;;
        *.md) DEST="knowledge" ;;
      esac
      if [ -n "$DEST" ]; then
        CATALOG "projectBootstrap.adopt.planMove" "$B" "$DEST/$B"
        PLAN_COUNT=$((PLAN_COUNT + 1))
      fi
    done
    [ "$PLAN_COUNT" = "0" ] && CATALOG "projectBootstrap.adopt.planNothing"
    CATALOG "projectBootstrap.adopt.planFooter"
  fi

  # --- Bloc a consommer (Decision 000545, A4) ---
  CATALOG "projectBootstrap.consume.header"
  CATALOG "projectBootstrap.consume.project" "$DISPLAY_NAME"
  CATALOG "projectBootstrap.consume.instructions" "$PILOT_PROMPT_TEMPLATE"
  CATALOG "projectBootstrap.consume.firstMessage" "$TARGET_ABS"
  CATALOG "projectBootstrap.consume.canary" "$CANARY" "$PILOT_PROMPT"
fi

echo "$FICHE"
