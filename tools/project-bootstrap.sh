#!/usr/bin/env bash
# Makes a project aware of the Vault, in two additive modes (DECISION-2026-
# 08-31-210731 point 3, Decision 2026-09-17-000545 A2-A5):
#
#   create : creates a new project that follows the project structure
#            standard (seven functions, RULES-2026-08-26-142800-project-
#            structure-standard.md): skeleton, identity README.md, journal
#            bootstrap, first indexes, PROJECT-v2 sheet and registry
#            line. Refuses if the target already exists: the organisation of the
#            workspace is free (232341 S1.6), this script presumes nothing.
#   adopt  : on an existing folder, writes only what is missing (birth
#            certificate and pin, pointer files, Pilot prompt, registry
#            line, sheet), records the dated baseline, reports what
#            exists, proposes the reorganisation plan and applies nothing.
#            `adopt --git` on a project adopted without Git adds the repository, the
#            hook and the active pin.
#   order  : without an initiation order, writes nothing and returns the order to fill in.
#
# In both modes, the project receives its birth certificate: the comment
# block at the top of .pre-commit-config.yaml (vault_id, vault_origin,
# vault_ref, vcs, and baseline at adoption), a fixed grammar read by
# tools/resolve-vault.sh. Form chosen by measurement: a top-level key
# makes `pre-commit validate-config` warn, a comment block does
# not (Mission 184, prior measurement).
#
# usage:
#   project-bootstrap.sh <target-path> <display_name> [language FR|EN|ES]
#       (historical call: create, answers carried by the arguments)
#   project-bootstrap.sh create <target-path> <display_name> [language] [--vcs none|git] [--ask]
#   project-bootstrap.sh adopt  <target-path> [display_name] [language] [--vcs none|git] [--ask] [--git]
#   (every form also accepts --lang FR|EN|ES)
#   project-bootstrap.sh --order <order-file> [language]
#   project-bootstrap.sh order <folder> [language]
#   project-bootstrap.sh identity <folder> [--check]
#   project-bootstrap.sh accueil-prompt
#   project-bootstrap.sh create <workspace>/<folder> <display_name> --group <group> ...
#
# Mission 234 (rule on workspace hygiene, project names and session types):
#   identity       prints the identity card of a project -- folder, group,
#                  display name, project_id, registry line, canary, expected
#                  Pilot Project name (`SB - <display name>`); --check compares
#                  the certificate, the registry, the Pilot prompt and the
#                  README title and names every mismatch ANOMALY (exit 1).
#   accueil-prompt prints the block that creates the welcome Pilot Project
#                  `SB - Accueil` (templates/accueil-pilot-prompt-template.md).
#   --group        creates <workspace>/<group>/<folder> instead of
#                  <workspace>/<folder> (the order's optional field `Groupe`).
# The Pilot prompt carries `pilot_project_name: "SB - <display name>"`.
#
# --ask: asks name, location and Git before writing (answers read from
# standard input, Enter = keep the proposal). Without --ask, the
# answers are carried by the arguments or by the order (Mode: answered);
# if nothing carries Git, the Git question is asked.
# Mission 240: --ask then asks the three questions of the project interview
# (expected result, current blocker, review rhythm), Enter = left empty; an
# order carries them in its optional fields « Résultat attendu », « Blocage
# actuel », « Rythme de revue ». Answers go under « ## Profil du projet » of
# README.md (tools/starting_profile.py); none, nothing is written.
#
# Language (Mission 177, step 5): optional parameter, default EN --
# backward compatible with any caller that does not supply it yet (existing
# tests included, which then expect the "Note: ..." messages in
# English). install.sh/install.ps1 pass the language chosen in the
# questionnaire; without this parameter, this script's messages intended for the
# participant stayed hard-coded in English, including in the middle of a
# French or Spanish installation (defect measured at the Owner acceptance
# of 2026-09-14).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/relpath.sh"
. "$SCRIPT_DIR/resolve-vault.sh"
. "$SCRIPT_DIR/lib/tmp.sh"  # declared temporary folder (Mission 234)
. "$SCRIPT_DIR/lib/clipboard.sh"  # the Pilot block on the clipboard (Mission 244)
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
  echo "       project-bootstrap.sh prompt <dossier> [--state-path <chemin relatif>]   (regenerates state/PILOT-PROMPT.md of an adopted project)" >&2
  echo "       project-bootstrap.sh identity <dossier> [--check]   (identity card; --check names every mismatch ANOMALY)" >&2
  echo "       project-bootstrap.sh accueil-prompt   (block that creates the welcome Pilot Project \"SB - Accueil\")" >&2
  echo "       project-bootstrap.sh create <espace>/<dossier> <display_name> --group <groupe> ...   (creates <espace>/<groupe>/<dossier>)" >&2
}

# --- Arguments ---------------------------------------------------------------
SUBCOMMAND=""
case "${1:-}" in
  create|adopt|order|prompt|identity|accueil-prompt) SUBCOMMAND="$1"; shift ;;
esac
EXPLICIT=0
[ -n "$SUBCOMMAND" ] && EXPLICIT=1
MODE="${SUBCOMMAND:-create}"
VCS=""
ASK=0
ORDER_FILE=""
ADD_GIT=0
LANG_OPT=""
STATE_PATH_OPT=""
GROUP_OPT=""
CHECK=0
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
    --state-path)
      [ $# -ge 2 ] || { usage; exit 1; }
      STATE_PATH_OPT="$2"; shift 2 ;;
    --group)
      [ $# -ge 2 ] || { usage; exit 1; }
      GROUP_OPT="$2"; shift 2 ;;
    --group=*) GROUP_OPT="${1#--group=}"; shift ;;
    --check) CHECK=1; shift ;;
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

# LANG_EXPLICIT (Mission 218, Decision 012459): 1 when the caller named a
# language -- the EN default below only chooses the catalogue of this script's
# messages, it never records a language for the project.
LANG_EXPLICIT=0
if [ -n "$ORDER_FILE" ]; then
  # --order <file> [language]: the language is the only positional allowed.
  LANGUAGE="${P1:-EN}"
  [ -n "$P1" ] && LANG_EXPLICIT=1
  TARGET=""
  DISPLAY_NAME=""
elif [ "$MODE" = "order" ]; then
  TARGET="$P1"
  DISPLAY_NAME=""
  LANGUAGE="${P2:-EN}"
  [ -n "$P2" ] && LANG_EXPLICIT=1
elif [ "$MODE" = "adopt" ] && [ -z "$P3" ] && printf '%s' "$P2" | grep -qixE 'fr|en|es'; then
  # adopt <target> <language>: the name is optional at adoption.
  TARGET="$P1"
  DISPLAY_NAME=""
  LANGUAGE="$P2"
  LANG_EXPLICIT=1
else
  TARGET="$P1"
  DISPLAY_NAME="$P2"
  LANGUAGE="${P3:-EN}"
  [ -n "$P3" ] && LANG_EXPLICIT=1
fi
if [ -n "$LANG_OPT" ]; then
  LANGUAGE="$LANG_OPT"
  LANG_EXPLICIT=1
fi

CATALOG_FILE="$I18N_DIR/catalog.$(printf '%s' "$LANGUAGE" | tr '[:upper:]' '[:lower:]').json"
if [ ! -e "$CATALOG_FILE" ]; then
  CATALOG_FILE="$I18N_DIR/catalog.en.json"
fi

PYRUN() {
  uv run --no-project "$HELPER" "$@"
}

# native_path <path>: the form the SYSTEM understands (door 9 of
# capture 2026-09-17-144137). Under Git Bash, `pwd` returns `/c/Users/...`;
# the MCP server, the desktop application and the participant read
# `C:\Users\...`. The acceptance Pilot had to guess that one was
# the other. Same mechanism as tools/install-vault-mcp.sh (native()):
# `cygpath -w` where it exists, the path as is everywhere else -- under
# Unix, nothing changes.
native_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

# CATALOG <key> [args...]: message intended for the participant, never
# hard-coded (Mission 177, step 5, constraint "messages through the i18n/ catalogues").
CATALOG() {
  PYRUN format-catalog "$CATALOG_FILE" "$@"
}

# --- Language of the project (Mission 218, Decision 012459) -------------------
# Recorded once by the installer in the front matter of USER.md (`language:`);
# failing it, the language the caller names explicitly (the installer calls this
# script before it writes USER.md); failing both, none -- and then "the language
# of the Owner's messages", never English by default. It is rendered in the Pilot
# prompt and in the project's own files (CLAUDE.md/AGENTS.md, journal birth
# entry) through the catalogue of that language (PCATALOG); this script's
# messages to the participant keep CATALOG.
user_language() {
  local v
  # Mission 219 (Owner arbitration of 2026-09-23 09:08): a local file, never
  # versioned nor distributed, is read first -- USER.local.yaml at the Vault
  # root, one line `language: <fr|en|es>`. It lets a Vault whose USER.md is the
  # distributed skeleton (the laboratory) record its language without writing
  # that skeleton. Ignored by Git (.gitignore); refused by the distribution
  # manifest check. BOM and CRLF tolerated (a file saved by Notepad).
  if [ -f "$VAULT_ROOT/USER.local.yaml" ]; then
    v="$(tr -d '\r' < "$VAULT_ROOT/USER.local.yaml" 2>/dev/null \
      | awk 'NR==1 {sub(/^\357\273\277/, "")} /^language:/ {sub(/^language:[[:space:]]*/, ""); gsub(/"/, ""); print; exit}' \
      | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
    case "$v" in fr|en|es) printf '%s' "$v"; return 0 ;; esac
  fi
  # The UTF-8 byte-order mark that Windows PowerShell 5.1 writes at the head of
  # USER.md (Set-Content -Encoding UTF8, install.ps1) is removed first: without
  # it the first line is not "---" and the language is never read.
  v="$(tr -d '\r' < "$VAULT_ROOT/USER.md" 2>/dev/null \
    | awk 'NR==1 {sub(/^\357\273\277/, "")} NR==1 && $0=="---" {f=1; next} f && $0=="---" {exit} f && /^language:/ {sub(/^language:[[:space:]]*/, ""); gsub(/"/, ""); print; exit}' \
    | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  case "$v" in fr|en|es) printf '%s' "$v" ;; esac
}
PROJECT_LANG="$(user_language)"
if [ -z "$PROJECT_LANG" ] && [ "$LANG_EXPLICIT" = "1" ]; then
  PROJECT_LANG="$(printf '%s' "$LANGUAGE" | tr '[:upper:]' '[:lower:]')"
  case "$PROJECT_LANG" in fr|en|es) ;; *) PROJECT_LANG="" ;; esac
fi
PROJECT_CATALOG_FILE="$CATALOG_FILE"
PCATALOG() {
  PYRUN format-catalog "$PROJECT_CATALOG_FILE" "$@"
}
# resolve_language_sentence: PROJECT_CATALOG_FILE and LANG_SENTENCE from PROJECT_LANG.
resolve_language_sentence() {
  local label
  PROJECT_CATALOG_FILE="$CATALOG_FILE"
  if [ -n "$PROJECT_LANG" ] && [ -e "$I18N_DIR/catalog.$PROJECT_LANG.json" ]; then
    PROJECT_CATALOG_FILE="$I18N_DIR/catalog.$PROJECT_LANG.json"
    case "$PROJECT_LANG" in fr) label="français" ;; es) label="español" ;; *) label="English" ;; esac
    LANG_SENTENCE="$(PCATALOG "projectBootstrap.pilotPrompt.languageSet" "$label" "$PROJECT_LANG")"
  else
    PROJECT_LANG=""
    LANG_SENTENCE="$(PCATALOG "projectBootstrap.pilotPrompt.languageUnset")"
  fi
}

# extract_prompt_common_block <template>: returns on stdout the exact text
# between the literal markers <!-- PROMPT:BEGIN --> and <!-- PROMPT:END -->
# (excluded), line breaks preserved -- the common trunk to paste as is
# (Decision 201623 part C, amends 000545 A4). Pure sed, POSIX portable:
# works under bash 3.2 (macOS) as under modern bash (Linux, Git Bash),
# no associative array nor mapfile. Fail-closed failure: if either of the two
# markers is missing, a message naming the faulty template goes to stderr and
# the function returns 1 -- WITHOUT writing partial content. `return`, never
# `exit`: this function is called through a command substitution, which
# runs in a subshell where `exit` would only end that subshell;
# the caller must itself do `|| exit 1` to stop the script.
extract_prompt_common_block() {
  local tpl="$1" body
  body="$(tr -d '\r' < "$tpl")"
  if ! printf '%s\n' "$body" | grep -qF '<!-- PROMPT:BEGIN -->' \
    || ! printf '%s\n' "$body" | grep -qF '<!-- PROMPT:END -->'; then
    echo "REFUS : marqueurs <!-- PROMPT:BEGIN --> / <!-- PROMPT:END --> introuvables dans le gabarit : $tpl" >&2
    return 1
  fi
  printf '%s\n' "$body" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p' | sed '1d;$d'
}

# ask_value <catalogue-key> <default>: question asked on stderr, answer read
# from standard input; Enter or end of input = default.
ask_value() {
  local answer=""
  CATALOG "$1" "$2" >&2
  IFS= read -r answer || answer=""
  answer="$(printf '%s' "$answer" | tr -d '\r')"
  if [ -n "$answer" ]; then printf '%s\n' "$answer"; else printf '%s\n' "$2"; fi
}

# Vault identity: read here without writing anything; generated (vid_ensure)
# only after all validations, just before the first write --
# a refusal must never touch the Vault
# (tests/test-project-bootstrap-path-validation.sh).
VAULT_ID="$(vid_get "$VAULT_ROOT" vault_id)"
VAULT_ORIGIN="$(vid_get "$VAULT_ROOT" vault_origin)"
VAULT_REF="$(vid_ref "$VAULT_ROOT")"

# --- Registry readers (Mission 234): anchored on the columns, never a grep of
# the whole line. Columns: | project_id | display_name | status | relative_path | vcs | conformity |
REGISTRY_FILE="$VAULT_ROOT/projects/PROJECT-REGISTRY.md"
registry_row_of_rel() { # <relative path>: the first row whose path column is it
  [ -f "$REGISTRY_FILE" ] || return 0
  tr -d '\r' < "$REGISTRY_FILE" | awk -F'|' -v p="$1" 'NF >= 6 { c = $5; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == p) { print; exit } }'
}
registry_row_of_id() { # <project_id>
  [ -f "$REGISTRY_FILE" ] || return 0
  tr -d '\r' < "$REGISTRY_FILE" | awk -F'|' -v i="$1" 'NF >= 6 { c = $2; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == i) { print; exit } }'
}
registry_col() { # <row> <column number>
  printf '%s\n' "$1" | awk -F'|' -v n="$2" '{ c = $(n + 1); gsub(/^[ \t]+|[ \t]+$/, "", c); print c }'
}
registry_name_of_id() {
  local row
  row="$(registry_row_of_id "$1")"
  [ -n "$row" ] && registry_col "$row" 2
}

# pilot_prompt_content: the personalised Pilot prompt of a project, on stdout, from
# the variables of the caller (DISPLAY_NAME, PROJECT_ID, CANARY, VAULT_ID, MCP_SERVER,
# VAULT_REF, TS, TARGET_NATIVE, REL_PROMPT_TEMPLATE, REL_CHARTER_FROM_STATE,
# STATE_PATH). One source for the first write (adopt, create) and for `prompt`
# (Mission 206). STATE_PATH (Mission 218, Decision 012458): the state sheet's path,
# relative to the project path -- a sub-workshop when the project keeps its state
# there; step 3 of the common prompt reads that sheet, so an instruction already
# pasted keeps working.
pilot_prompt_content() {
  cat <<EOF
---
type: pilot-prompt
title: "Prompt Pilot — $DISPLAY_NAME"
description: "Personnalisation, sur le disque, du prompt Pilot commun pour ce projet : chemin, identité du Vault, canari d'ouverture, fiche d'état."
status: generated
project_id: $PROJECT_ID
canary: "$CANARY"
vault_id: "$VAULT_ID"
mcp_server: "$MCP_SERVER"
vault_ref: "$VAULT_REF"
state_path: "$STATE_PATH"
language: "$PROJECT_LANG"
pilot_project_name: "SB - $DISPLAY_NAME"
generated_at: "$TS"
---

# PROMPT PILOT — $DISPLAY_NAME

Généré par \`tools/project-bootstrap.sh\`. Ne pas éditer à la main : le prompt commun vit dans le Vault, ce fichier ne porte que ce qui est propre à ce projet.

- Chemin du projet : \`$TARGET_NATIVE\`
- Vault : \`$VAULT_ID\`, construit au commit \`$VAULT_REF\`
- Serveur MCP de ce Vault : \`$MCP_SERVER\`
- Canari : \`$CANARY\`
- Project Pilot attendu : \`SB - $DISPLAY_NAME\` — le nom du Project de l'application Claude qui porte ce projet (règle 112218 §5) ; à l'ouverture, le Pilot le compare au nom de son Project.
- Fiche d'état : \`$STATE_PATH\` (chemin relatif au projet) — c'est la fiche que l'étape 3 du prompt commun fait lire ; son extrait plafonné \`DIGEST.md\` est dans le même dossier.
- Langue : $LANG_SENTENCE

## Ouverture Pilot

Le rôle Pilot exige l'application de bureau : le serveur MCP du Vault n'existe pas dans le navigateur.

1. Appelle \`list_allowed_directories\` du serveur \`$MCP_SERVER\` : la liste doit contenir le chemin du projet ci-dessus. Compare le commit du Vault qu'il rend à celui ci-dessus ; un écart se dit, il ne bloque pas.
2. Lis ce fichier et rends le canari \`$CANARY\` : c'est la preuve que la lecture a eu lieu.
3. Applique le [prompt commun]($REL_PROMPT_TEMPLATE) et la [charte des rôles]($REL_CHARTER_FROM_STATE).

## Liens

- \`see also\` — [Prompt Pilot commun]($REL_PROMPT_TEMPLATE) (hors Vault)
- \`see also\` — [Charte des rôles et détermination de session]($REL_CHARTER_FROM_STATE) (hors Vault)
EOF
}

# --- order: the initiation order to fill in, nothing written (Decision 000545,
# A3: without an order, the agent stops and proposes adoption) ---------------------
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
  echo "- Groupe : -"
  echo "- Vault + construction : vault_id=$VAULT_ID, vault_origin=$VAULT_ORIGIN, vault_ref=$VAULT_REF"
  echo "- Git : $ORDER_GIT"
  echo "- Objet : <à remplir>"
  echo "- Résultat attendu : -"
  echo "- Blocage actuel : -"
  echo "- Rythme de revue : -"
  echo "- Autorisation Owner datée : <verbatim de l'Owner, avec sa date AAAA-MM-JJ>"
  echo ""
  CATALOG "projectBootstrap.order.footer"
  exit 0
fi

# --- prompt: regenerates state/PILOT-PROMPT.md of an ADOPTED project (Mission 206) --
# The name of the Vault's MCP server changes (Decision 162812: by workspace, no longer
# by identity), and adopt never rewrites a prompt that exists. What belongs to the
# project (project_id, canary, title, path) is read from the prompt and kept; what
# belongs to the Vault (identity, server name, commit, date, links) is regenerated by
# the same function as the first write. Nothing else is touched: no registry, no
# certificate, no Git.
if [ "$MODE" = "prompt" ]; then
  if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
    usage
    echo "REFUS : dossier du projet introuvable : ${TARGET:-(vide)}" >&2
    exit 1
  fi
  # Mission 226: the repository-root guard (default mode) before the Pilot
  # prompt is rewritten -- a project lies in a repository or carries its
  # birth certificate, never at the workspace root.
  uv run --no-project "$SCRIPT_DIR/repo_root_guard.py" "$TARGET" || exit 1
  TARGET_ABS="$(cd "$TARGET" && pwd)"
  PILOT_PROMPT="$TARGET_ABS/state/PILOT-PROMPT.md"
  if [ ! -f "$PILOT_PROMPT" ]; then
    echo "REFUS : pas de state/PILOT-PROMPT.md dans $TARGET_ABS : le projet n'est pas adopte (adopt d'abord)" >&2
    exit 1
  fi
  PP_TEXT="$(tr -d '\r' < "$PILOT_PROMPT")"
  pp_field() {
    printf '%s\n' "$PP_TEXT" | sed -n "s/^$1: \"\{0,1\}\([^\"]*\)\"\{0,1\}\$/\1/p" | head -n 1
  }
  PROJECT_ID="$(pp_field project_id)"
  CANARY="$(pp_field canary)"
  DISPLAY_NAME="$(printf '%s\n' "$PP_TEXT" | sed -n 's/^title: "Prompt Pilot — \(.*\)"$/\1/p' | head -n 1)"
  TARGET_NATIVE="$(printf '%s\n' "$PP_TEXT" | sed -n 's/^- Chemin du projet : `\(.*\)`$/\1/p' | head -n 1)"
  if [ -z "$PROJECT_ID" ] || [ -z "$CANARY" ] || [ -z "$DISPLAY_NAME" ] || [ -z "$TARGET_NATIVE" ]; then
    echo "REFUS : $PILOT_PROMPT ne porte pas project_id, canary, title et « Chemin du projet » : format non reconnu, rien n'est ecrit" >&2
    exit 1
  fi
  # Mission 234 (rule 112218 §5): the registry carries the display name the
  # Owner wants; the prompt follows it (its title, pilot_project_name). The
  # project_id and the canary never change.
  REG_NAME="$(registry_name_of_id "$PROJECT_ID")"
  [ -n "$REG_NAME" ] && DISPLAY_NAME="$REG_NAME"
  MCP_SERVER="$(vid_server_name "$VAULT_ROOT")" || {
    echo "REFUS : ce Vault n'a pas d'identite generee : le nom de son serveur ne peut pas etre derive, prompt inchange" >&2
    exit 1
  }
  # state_path (Mission 218, Decision 012458): --state-path wins, then the value
  # the prompt already carries, then the default. A given path must be relative,
  # stay inside the project and name an existing file: nothing is written otherwise.
  if [ -n "$STATE_PATH_OPT" ]; then
    case "$STATE_PATH_OPT" in
      /*|*..*|*\\*|*:*)
        echo "REFUS : --state-path doit etre un chemin relatif au projet, sans '..' : $STATE_PATH_OPT ; prompt inchange" >&2
        exit 1 ;;
    esac
    if [ ! -f "$TARGET_ABS/$STATE_PATH_OPT" ]; then
      echo "REFUS : --state-path introuvable : $TARGET_ABS/$STATE_PATH_OPT ; prompt inchange" >&2
      exit 1
    fi
    STATE_PATH="$STATE_PATH_OPT"
  else
    STATE_PATH="$(pp_field state_path)"
    [ -n "$STATE_PATH" ] || STATE_PATH="state/STATE.md"
  fi
  # Language (Decision 012459): USER.md, then --lang, then what the prompt carries.
  [ -n "$PROJECT_LANG" ] || PROJECT_LANG="$(pp_field language | tr '[:upper:]' '[:lower:]')"
  resolve_language_sentence
  TS="$(date +"%Y-%m-%dT%H:%M:%S%z")"
  REL_PROMPT_TEMPLATE="$(rel_path "$TARGET_ABS/state" "$PILOT_PROMPT_TEMPLATE")"
  REL_CHARTER_FROM_STATE="$(rel_path "$TARGET_ABS/state" "$CHARTER")"
  PP_NEW="$(mktemp "$(sb_tmp_dir tools)/pb-prompt-XXXXXX")"
  pilot_prompt_content > "$PP_NEW"
  cat "$PP_NEW" > "$PILOT_PROMPT"
  rm -f "$PP_NEW"
  echo "PILOT-PROMPT regenere : $PILOT_PROMPT (serveur $MCP_SERVER, commit $VAULT_REF, fiche $STATE_PATH, langue ${PROJECT_LANG:-non enregistree})"
  exit 0
fi

# --- identity: the identity card of a project (Mission 234, rule 112218 §5) --
# Read-only. The project root is the folder that carries the birth certificate,
# walking up from <folder>; the workspace root is the one of the marker. The
# card names what the Executor and the Pilot must find in agreement; --check
# compares them and names every mismatch ANOMALY (exit 1), never a fix.
if [ "$MODE" = "identity" ]; then
  if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
    usage
    echo "REFUS : dossier introuvable : ${TARGET:-(vide)}" >&2
    exit 1
  fi
  ID_START="$(cd "$TARGET" && pwd -P)"
  ID_WS="$(rv_find_marker "$ID_START" || true)"
  if [ -n "$ID_WS" ] && [ "$ID_START" = "$ID_WS" ]; then
    echo "REFUS : $ID_START est la racine de l'espace, pas un projet : aucune carte d'identite (session d'accueil ou libre)" >&2
    exit 1
  fi
  ID_ROOT="$(bc_find "$ID_START" || true)"
  ID_ANOM=""
  id_anomaly() { ID_ANOM="${ID_ANOM}ANOMALY: $1
"; }
  if [ -z "$ID_ROOT" ]; then
    ID_ROOT="$ID_START"
    id_anomaly "aucun acte de naissance en remontant depuis $ID_START : dossier non adopte (project-bootstrap.sh order)"
  fi
  ID_REL=""
  [ -n "$ID_WS" ] && ID_REL="$(rel_path "$ID_WS" "$ID_ROOT")"
  ID_GROUP="—"
  case "$ID_REL" in */*) ID_GROUP="${ID_REL%%/*}" ;; esac
  ID_ROW="$(registry_row_of_rel "$ID_REL")"
  ID_REG_ID=""; ID_NAME=""
  if [ -n "$ID_ROW" ]; then
    ID_REG_ID="$(registry_col "$ID_ROW" 1)"
    ID_NAME="$(registry_col "$ID_ROW" 2)"
  else
    id_anomaly "aucune ligne du registre pour le chemin ${ID_REL:-(hors espace)}"
  fi
  ID_PP="$ID_ROOT/state/PILOT-PROMPT.md"
  ID_PP_ID=""; ID_CANARY=""; ID_PP_NAME=""; ID_PP_STATE=""
  if [ -f "$ID_PP" ]; then
    ID_PP_TEXT="$(tr -d '\r' < "$ID_PP")"
    ID_PP_ID="$(printf '%s\n' "$ID_PP_TEXT" | sed -n 's/^project_id: "\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' | head -n 1)"
    ID_CANARY="$(printf '%s\n' "$ID_PP_TEXT" | sed -n 's/^canary: "\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' | head -n 1)"
    ID_PP_NAME="$(printf '%s\n' "$ID_PP_TEXT" | sed -n 's/^pilot_project_name: "\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' | head -n 1)"
    ID_PP_STATE="$(printf '%s\n' "$ID_PP_TEXT" | sed -n 's/^state_path: "\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' | head -n 1)"
  else
    id_anomaly "pas de state/PILOT-PROMPT.md : le Pilot n'a pas de prompt pour ce projet (project-bootstrap.sh adopt)"
  fi
  [ -n "$ID_NAME" ] || ID_NAME="$(basename "$ID_ROOT")"
  ID_EXPECTED="SB - $ID_NAME"
  if [ "$CHECK" = "1" ]; then
    if bc_file_has_certificate "$ID_ROOT/.pre-commit-config.yaml"; then
      ID_CERT_VID="$(bc_get "$ID_ROOT/.pre-commit-config.yaml" vault_id)"
      [ "$ID_CERT_VID" = "$VAULT_ID" ] || id_anomaly "l'acte nomme le Vault ${ID_CERT_VID:-(aucun)}, ce Vault est $VAULT_ID"
    fi
    if [ -n "$ID_REG_ID" ] && [ -n "$ID_PP_ID" ] && [ "$ID_REG_ID" != "$ID_PP_ID" ]; then
      id_anomaly "project_id du registre ($ID_REG_ID) different de celui du prompt Pilot ($ID_PP_ID)"
    fi
    if [ -f "$ID_PP" ]; then
      if [ -z "$ID_PP_NAME" ]; then
        id_anomaly "le prompt Pilot ne porte pas pilot_project_name (attendu : $ID_EXPECTED) : project-bootstrap.sh prompt $ID_ROOT"
      elif [ "$ID_PP_NAME" != "$ID_EXPECTED" ]; then
        id_anomaly "pilot_project_name du prompt ($ID_PP_NAME) different du nom attendu ($ID_EXPECTED) : project-bootstrap.sh prompt $ID_ROOT"
      fi
    fi
    if [ -f "$ID_ROOT/README.md" ]; then
      ID_README="$(tr -d '\r' < "$ID_ROOT/README.md" | sed -n 's/^# \(.*\)$/\1/p' | head -n 1)"
      [ "$ID_README" = "$ID_NAME" ] || id_anomaly "titre du README (${ID_README:-(aucun)}) different du nom du registre ($ID_NAME)"
    fi
  fi
  echo "IDENTITE DU PROJET"
  echo "- Dossier : $(native_path "$ID_ROOT")"
  echo "- Chemin dans l'espace : ${ID_REL:-(hors espace)}"
  echo "- Groupe : $ID_GROUP"
  echo "- Nom affiche : $ID_NAME"
  echo "- project_id : ${ID_REG_ID:-${ID_PP_ID:-(aucun)}}"
  echo "- Ligne du registre : ${ID_ROW:-(aucune)}"
  echo "- Canari : ${ID_CANARY:-(aucun)}"
  echo "- Fiche d'etat : ${ID_PP_STATE:-state/STATE.md}"
  echo "- Project Pilot attendu : $ID_EXPECTED"
  if [ "$CHECK" = "1" ]; then
    printf '%s' "$ID_ANOM"
    ID_N="$(printf '%s' "$ID_ANOM" | grep -c '^ANOMALY' || true)"
    if [ "$ID_N" = "0" ]; then
      echo "IDENTITY: CONCORDANT"
      exit 0
    fi
    echo "IDENTITY: $ID_N ANOMALY"
    exit 1
  fi
  exit 0
fi

# --- accueil-prompt: the block that creates the welcome Pilot Project
# (Mission 234, D-B, rule 112218 §7). Nothing written. ------------------------
if [ "$MODE" = "accueil-prompt" ]; then
  ACCUEIL_TEMPLATE="$VAULT_ROOT/templates/accueil-pilot-prompt-template.md"
  [ -f "$ACCUEIL_TEMPLATE" ] || { echo "REFUS : gabarit introuvable : $ACCUEIL_TEMPLATE" >&2; exit 1; }
  ACCUEIL_BLOCK="$(extract_prompt_common_block "$ACCUEIL_TEMPLATE")" || exit 1
  ACCUEIL_WS="$(rv_find_marker "$VAULT_ROOT" || true)"
  [ -n "$ACCUEIL_WS" ] || ACCUEIL_WS="$(dirname "$VAULT_ROOT")"
  ACCUEIL_SERVER="$(vid_server_name "$VAULT_ROOT" 2>/dev/null || true)"
  # Mission 244 (finding 10): the recorded language, said in the block -- a
  # first message that carries none (a path, a greeting) gets it (Decision 012459).
  case "$PROJECT_LANG" in
    fr) ACCUEIL_LANG="français (fr)" ;;
    en) ACCUEIL_LANG="English (en)" ;;
    es) ACCUEIL_LANG="español (es)" ;;
    *) ACCUEIL_LANG="the language of the Owner's first message that carries one (none is recorded)" ;;
  esac
  # Mission 245 (capture 105405, finding C4): the Executor named, not a page
  # of the documentation -- the Code tab by default, the two command-line
  # agents as options with this system's installation lines, in the recorded
  # language (the doctor's own lines). The template names no product: the
  # placeholder carries them (rule on model-agnostic hosts: a product is named
  # where the gesture depends on it).
  resolve_language_sentence
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) ACCUEIL_PLATFORM="windows" ;;
    Darwin) ACCUEIL_PLATFORM="macos" ;;
    *) ACCUEIL_PLATFORM="linux" ;;
  esac
  ACCUEIL_EXECUTOR="$(PCATALOG "projectBootstrap.accueil.executorOptions" "$(PCATALOG "sb.doctor.executorFix.$ACCUEIL_PLATFORM")")"
  # One separator throughout the block: C:/Users/... (cygpath -m), read by the
  # MCP server and the Pilot alike; the template appends /skills/... to it.
  mixed_path() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }
  ACCUEIL_BLOCK="$(printf '%s\n' "$ACCUEIL_BLOCK" \
    | sed -e "s#{{WORKSPACE}}#$(mixed_path "$ACCUEIL_WS" | sed 's/[#&\\]/\\&/g')#g" \
          -e "s#{{VAULT}}#$(mixed_path "$VAULT_ROOT" | sed 's/[#&\\]/\\&/g')#g" \
          -e "s#{{MCP_SERVER}}#${ACCUEIL_SERVER:-second-brain-vault}#g" \
          -e "s#{{VAULT_ID}}#$VAULT_ID#g" \
          -e "s#{{LANGUAGE}}#$ACCUEIL_LANG#g" \
          -e "s#{{EXECUTOR_OPTIONS}}#$(printf '%s' "$ACCUEIL_EXECUTOR" | sed 's/[#&\\]/\\&/g')#g")"
  echo "Pour ouvrir le Pilot d'accueil (application de bureau Claude) :"
  echo "  1. Dans l'application Claude : crée un Project nommé « SB - Accueil »."
  echo "  2. Dans ses instructions : colle ce bloc tel quel :"
  echo "  ---"
  printf '%s\n' "$ACCUEIL_BLOCK"
  echo "  ---"
  echo "  3. Dans une conversation de ce Project : écris « bonjour » (l'espace $(native_path "$ACCUEIL_WS") est dans le bloc)."
  exit 0
fi

# --- --order <file>: the order is the source (Decision 000545, A5) -----------
ORDER_PURPOSE=""
ORDER_AUTH=""
ORDER_DIRTY=""
# The project profile (Mission 240): three optional answers, carried by the
# order's fields « Résultat attendu », « Blocage actuel », « Rythme de revue »
# or asked by --ask; written under « ## Profil du projet » of README.md.
PROFILE_RESULT=""
PROFILE_BLOCKER=""
PROFILE_CADENCE=""
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
  # Optional ninth field (Mission 218, rule 124937): the Owner accepts that the
  # baseline records a Git tree with uncommitted changes.
  ORDER_DIRTY="$(order_field 'Arbre sale')"
  # Optional tenth field (Mission 234, D-D): the group folder the project is
  # created in, <workspace>/<group>/<name>. --group on the command line wins.
  O_GROUP="$(order_field 'Groupe')"
  case "$O_GROUP" in -|—|aucun|none|'<'*) O_GROUP="" ;; esac
  [ -n "$GROUP_OPT" ] || GROUP_OPT="$O_GROUP"
  # Optional fields 11 to 13 (Mission 240): the project profile. Absent, a
  # dash or a placeholder: nothing is written, as before.
  PROFILE_RESULT="$(order_field 'Résultat attendu')"
  PROFILE_BLOCKER="$(order_field 'Blocage actuel')"
  PROFILE_CADENCE="$(order_field 'Rythme de revue')"
  case "$PROFILE_RESULT" in -|—|'<'*) PROFILE_RESULT="" ;; esac
  case "$PROFILE_BLOCKER" in -|—|'<'*) PROFILE_BLOCKER="" ;; esac
  case "$PROFILE_CADENCE" in -|—|'<'*) PROFILE_CADENCE="" ;; esac
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
  if [ -z "$VAULT_ID" ] || [ "$O_VAULT_ID" != "$VAULT_ID" ]; then
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

# --- Question before writing (Decision 000545, A4): name and location
# proposed, the Owner confirms or changes them. ---------------------------------------
if [ "$ASK" = "1" ]; then
  ASK_NAME="$(ask_value "projectBootstrap.question.name" "$(basename "$TARGET")")"
  ASK_PLACE="$(ask_value "projectBootstrap.question.location" "$(dirname "$TARGET")")"
  if [ "$DISPLAY_NAME" = "$(basename "$TARGET")" ]; then
    DISPLAY_NAME="$ASK_NAME"
  fi
  TARGET="${ASK_PLACE%/}/$ASK_NAME"
fi

# --- Optional group (Mission 234, D-D, rule 112218 §6): <workspace>/<folder>
# becomes <workspace>/<group>/<folder>. Refused, before any write: a group for
# anything but create; a group that is not one folder name; a group that is a
# project (registered, or carrying a birth certificate or a .git) or carries
# VAULT-ROOT.md; a target that is not in a workspace. ---
if [ -n "$GROUP_OPT" ]; then
  if [ "$MODE" != "create" ]; then
    echo "REFUS : --group (ou le champ Groupe de l'ordre) ne vaut que pour create ; une adoption garde le dossier ou il est : $TARGET" >&2
    exit 1
  fi
  case "$GROUP_OPT" in
    .*|*/*|*\\*|*:*|*..*)
      echo "REFUS : groupe invalide : '$GROUP_OPT' (un seul nom de dossier, sans / ni \\ ni ..)" >&2
      exit 1 ;;
  esac
  G_PARENT="$(dirname "$TARGET")"
  G_EXISTING="$G_PARENT"
  while [ ! -d "$G_EXISTING" ] && [ "$(dirname "$G_EXISTING")" != "$G_EXISTING" ]; do
    G_EXISTING="$(dirname "$G_EXISTING")"
  done
  G_WS="$(rv_find_marker "$G_EXISTING" || true)"
  if [ -z "$G_WS" ]; then
    echo "REFUS : le groupe '$GROUP_OPT' serait hors d'un espace de travail (aucun VAULT-ROOT.md en remontant depuis $G_PARENT)" >&2
    exit 1
  fi
  G_DIR="$G_PARENT/$GROUP_OPT"
  if [ -f "$G_DIR/VAULT-ROOT.md" ]; then
    echo "REFUS : le groupe $G_DIR porte VAULT-ROOT.md : c'est une racine d'espace, pas un groupe" >&2
    exit 1
  fi
  if [ -e "$G_DIR/.git" ] || bc_file_has_certificate "$G_DIR/.pre-commit-config.yaml"; then
    echo "REFUS : le groupe $G_DIR est un projet (depot Git ou acte de naissance) : un groupe ne contient que des projets" >&2
    exit 1
  fi
  if [ -d "$G_DIR" ]; then
    G_REL="$(rel_path "$G_WS" "$(cd "$G_DIR" && pwd -P)")"
    if [ -n "$(registry_row_of_rel "$G_REL")" ]; then
      echo "REFUS : le groupe $G_DIR est inscrit au registre comme projet ($G_REL)" >&2
      exit 1
    fi
  fi
  TARGET="$G_DIR/$(basename "$TARGET")"
fi

# --- `--git` IS the answer: no question any more (door 5 of capture
# 2026-09-17-144137). `--git` only set ADD_GIT, read much further down at
# the time of the birth certificate; VCS stayed empty here, so `adopt <p>
# --git` still asked « Suivre ce projet avec Git ? » ["Track this project with Git?"] and blocked on
# the standard input of a caller without a terminal. An explicit option
# answers the question it settles. ---
if [ "$ADD_GIT" = "1" ] && [ -z "$VCS" ]; then
  VCS="git"
fi

# --- Git question if nothing carries it (Decision 000545, A4) ------------------
if [ -z "$VCS" ]; then
  if [ "$EXPLICIT" = "0" ]; then
    # Historical call (installers): the Git repository is always created.
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

# --- The three questions of the project interview (Mission 240), after every
# other question: asked one at a time with --ask (or an order in Mode: ask),
# only those the order does not already answer; Enter leaves the answer empty,
# and three empty answers write nothing. ---
if [ "$ASK" = "1" ]; then
  [ -n "$PROFILE_RESULT" ] || PROFILE_RESULT="$(ask_value "projectBootstrap.question.result" "")"
  [ -n "$PROFILE_BLOCKER" ] || PROFILE_BLOCKER="$(ask_value "projectBootstrap.question.blocker" "")"
  [ -n "$PROFILE_CADENCE" ] || PROFILE_CADENCE="$(ask_value "projectBootstrap.question.cadence" "")"
fi

# --- Validation of the target path (Mission 171-C01, step 3: defect of the
# same family as install.sh/install.ps1 -- missing path validation).
# Refuses a target path that is relative or located inside this Vault repository
# itself: a project created in the Vault would break the
# Vault/project boundary that AGENTS.md imposes ("Maintenir la frontiere entre le
# Vault et les projets externes" ["Maintain the boundary between the Vault and external projects"]). ---
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
# Mission 226: the repository-root guard in its --new-project mode -- the
# target is a project folder, never the workspace root nor a folder that
# holds several repositories.
uv run --no-project "$SCRIPT_DIR/repo_root_guard.py" --new-project "$TARGET" || exit 1

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

# --- Baseline due? (adopt) -- computed, with the dirty-tree check below, BEFORE
# the first write (Mission 218): a refusal must never touch the Vault. ---
BASELINE_NAME=""
BASELINE_TMP=""
CONFIG_EXISTED=0
[ -e "$TARGET/.pre-commit-config.yaml" ] && CONFIG_EXISTED=1
# Mission 203 (report 202, A4): a config WITHOUT certificate is replaced by the
# current form when it holds nothing but Vault guardians (an older pin such as
# `repo: <url>` + `rev:` + `vault-check-*` ids); the old one is cited and kept
# next to it, dated, never deleted. A config that carries anything else (a hook
# of the project, another top-level key) is never replaced: the certificate to add is
# returned, as before.
CONFIG_REPLACE=0
if [ "$MODE" = "adopt" ] && [ "$CONFIG_EXISTED" = "1" ] && ! bc_file_has_certificate "$TARGET/.pre-commit-config.yaml"; then
  FOREIGN_LINES="$(tr -d '\r' < "$TARGET/.pre-commit-config.yaml" | grep -v -E '^[[:space:]]*(#.*)?$|^repos:[[:space:]]*(\[\])?[[:space:]]*$|^[[:space:]]*-[[:space:]]*repo:|^[[:space:]]*rev:|^[[:space:]]*hooks:[[:space:]]*$|^[[:space:]]*-[[:space:]]*id:[[:space:]]*"?vault-check-[a-z-]+"?[[:space:]]*$' || true)"
  [ -z "$FOREIGN_LINES" ] && CONFIG_REPLACE=1
fi
BASELINE_DUE=0
if [ "$MODE" = "adopt" ] && { [ "$CONFIG_EXISTED" = "0" ] || [ "$CONFIG_REPLACE" = "1" ]; }; then
  BASELINE_DUE=1
  # --- Mission 218, lot 5: never engrave a dirty tree. On 2026-09-22 a baseline
  # recorded 532 files overwritten in the working tree; once Git restored them,
  # the guardians judged them "touched". A Git working tree with any porcelain
  # line is refused before any write, unless the initiation order carries
  # `Arbre sale : accepté — <raison>`. Without Git the tree cannot be measured:
  # said, not blocking. ---
  if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    DIRTY_N="$(git -C "$TARGET" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$DIRTY_N" != "0" ]; then
      if printf '%s' "$ORDER_DIRTY" | grep -qiE '^(accepté|accepte|accepted|aceptado)'; then
        echo "BASELINE-DIRTY-TREE : $DIRTY_N porcelain line(s), accepted by the order: $ORDER_DIRTY" >&2
      else
        echo "BASELINE-DIRTY-TREE : $DIRTY_N porcelain line(s) in $TARGET: the baseline would engrave uncommitted content. Nothing written. Commit or restore first, or have the order carry 'Arbre sale : accepté — <raison>'." >&2
        exit 1
      fi
    fi
  else
    echo "BASELINE-TREE-UNMEASURED : $TARGET is not a Git working tree: whether it is clean cannot be measured; the baseline records the folder as it is." >&2
  fi
fi

# --- First write: the Vault identity, if it is still missing. ---
vid_ensure "$VAULT_ROOT"
VAULT_ID="$(vid_get "$VAULT_ROOT" vault_id)"
VAULT_ORIGIN="$(vid_get "$VAULT_ROOT" vault_origin)"
# Name of THIS Vault's MCP server (Decision 152251 C, Mission 191-C01):
# written in the Pilot prompt and rendered in the Project instructions.
MCP_SERVER="$(vid_server_name "$VAULT_ROOT")"
VAULT_SHORT_ID="${MCP_SERVER#second-brain-vault-}"

# --- Registry missing: created from the template before any line is written
# (Mission 118, batch 5). The template is at the same depth as the registry
# under VAULT_ROOT (templates/ and projects/): its relative links stay
# correct as they are, verbatim copy. ---
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

# --- Dated baseline (adopt): recorded BEFORE any write, so as to list
# only what exists. Put in place afterwards, under the name the certificate carries. ---
if [ "$BASELINE_DUE" = "1" ]; then
  BASELINE_NAME=".vault-baseline-$STAMP.tsv"
  BASELINE_TMP="$(mktemp "$(sb_tmp_dir tools)/pb-baseline-XXXXXX")"
  BASELINE_COUNT="$(uv run --no-project "$BASELINE_TOOL" write "$TARGET" "$BASELINE_TMP")" \
    || { echo "REFUS : ligne de base non ecrite pour $TARGET" >&2; rm -f "$BASELINE_TMP"; exit 1; }
fi

if [ "$MODE" = "create" ]; then
  # --- Skeleton of the seven functions (RULES-2026-08-26-142800 S2) ---
  mkdir -p "$TARGET"/rules "$TARGET"/state "$TARGET"/missions "$TARGET"/decisions "$TARGET"/proposals "$TARGET"/knowledge "$TARGET"/handoffs
fi
TARGET_ABS="$(cd "$TARGET" && pwd)"
# Native form of the project path: the only one shown to the
# participant, to the Pilot and to the application (door 9). TARGET_ABS stays the
# shell form, used for every disk access of this script.
TARGET_NATIVE="$(native_path "$TARGET_ABS")"
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

# --- Project identity: reused if already registered (idempotent adopt) ---
# Mission 219 (A3): the lookup is anchored on the path column (the fifth field
# of `| id | name | status | path | ...`), never a `grep -F "| <path> |"` that
# also matched the vcs column: a project whose path is `none` or `git` was
# refused as "already registered" as soon as any row carried that vcs.
registry_row_of_path() { # prints the first row whose path column is $1
  awk -F'|' -v p="$1" 'NF >= 6 { c = $5; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == p) { print; exit } }' "$REGISTRY"
}
REGISTERED=0
PROJECT_ID=""
if [ -n "$(registry_row_of_path "$PROJECT_REL")" ]; then
  REGISTERED=1
  PROJECT_ID="$(registry_row_of_path "$PROJECT_REL" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
fi
if [ "$MODE" = "create" ] && [ "$REGISTERED" = "1" ]; then
  echo "REFUS : chemin deja inscrit au registre : $PROJECT_REL" >&2
  exit 1
fi

if [ -z "$PROJECT_ID" ]; then
  # project_id (registry v1 D1b): real date + mnemonic code derived from display_name
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

# --- Birth certificate and pin of the guardians (Decision 000545, A1); repo:
# local on this Vault (T01, ticket 02 of Mission 168): never a remote
# URL, a measured relative path to this Vault, entry by entry, no
# network nor pre-commit cache involved. vault_ref replaces the vault_head
# fingerprint that the sheet used to carry. ---
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
    # adopt --git: the only gesture that touches again a file already written by this
    # script -- the vcs line of the certificate, the sheet and the registry line.
    VCS="git"
    CONFIG_TMP="$(mktemp "$(sb_tmp_dir tools)/pb-config-XXXXXX")"
    sed 's/^# vcs: none$/# vcs: git/' "$CONFIG" > "$CONFIG_TMP" && cat "$CONFIG_TMP" > "$CONFIG"
    rm -f "$CONFIG_TMP"
    VCS_SWITCHED=1
  elif [ -n "$CURRENT_VCS" ]; then
    VCS="$CURRENT_VCS"
  fi
elif [ "$CONFIG_REPLACE" = "1" ]; then
  # Old config cited in full, copied next to it (dated, never overwritten),
  # then replaced by the certificate form; the baseline recorded above is put in place.
  CONFIG_COPY="$TARGET_ABS/.pre-commit-config.yaml.before-adopt-$TODAY"
  [ -e "$CONFIG_COPY" ] && CONFIG_COPY="$CONFIG_COPY-$(date +"%H%M%S")"
  cp -p "$CONFIG" "$CONFIG_COPY"
  echo "Ancienne .pre-commit-config.yaml (sans acte de naissance) remplacee ; copie datee : $(basename "$CONFIG_COPY")"
  tr -d '\r' < "$CONFIG_COPY" | sed 's/^/  | /'
  write_certificate_config
  note_added ".pre-commit-config.yaml (remplacee : acte de naissance et crochets locaux)"
  note_added "$(basename "$CONFIG_COPY")"
  if [ -n "$BASELINE_NAME" ]; then
    mv "$BASELINE_TMP" "$TARGET_ABS/$BASELINE_NAME"
    note_added "$BASELINE_NAME ($BASELINE_COUNT)"
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
  # --- Mission register of the project (Mission 175, step 2): the skeleton
  # promises "missions/ = Missions AND their reports" (standard S2) but never
  # put the register itself in place -- a created project stayed without
  # MISSION-INDEX.md as long as no Mission was written by hand. Verbatim
  # copy (front matter, headers, ## Liens), never a hard-coded string here,
  # same reason as the Vault registry above. build-indexes.sh (further down)
  # indexes this file as soon as it exists on disk, before any first commit.
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

# --- Project-level CLAUDE.md and AGENTS.md (Mission 173, Q17: three-level
# hierarchy). Under 60 lines; name, purpose, minimal conventions, then
# import of the method (the CLAUDE.md of second-brain itself, which leads up
# to the role charter) -- nothing more, the method is read through the
# import chain, never copied here. Identical content in both
# files. The Vault path is the certificate's (measured above), never
# an assumed proximity (Decision 000545, A1). ## Liens section
# mandatory: these two files are tracked by the repository of THIS project and
# its own check-links.sh guardian refuses them otherwise. At adoption, a file
# already present is left as is. ---
# Mission 218 (Decision 012459): the guide is written in the project's language,
# through the catalogue of that language -- it used to say "Rédiger en français"
# whatever the installation language. Without a recorded language, the
# conventions line says "the language of the Owner's messages".
# Mission 236: one sentence routes a message that starts with `sb ` to the sb
# command (rules/RULES-2026-09-26-200933-sb-command-surface.md) -- Codex does
# not follow the @ import, so the sentence is written here, not only in the
# Vault's CLAUDE.md.
resolve_language_sentence
if [ -n "$PROJECT_LANG" ]; then
  GUIDE_CONVENTIONS="$(PCATALOG "projectBootstrap.guide.conventions")"
else
  GUIDE_CONVENTIONS="$(PCATALOG "projectBootstrap.guide.conventionsUnset")"
fi
# Mission 244 (finding 34): the order's purpose is the project's purpose -- it
# used to stay « à compléter » although the order carried it.
if [ -n "$ORDER_PURPOSE" ]; then
  GUIDE_PURPOSE="$(PCATALOG "projectBootstrap.guide.purposeGiven" "$ORDER_PURPOSE")"
else
  GUIDE_PURPOSE="$(PCATALOG "projectBootstrap.guide.purpose")"
fi
PROJECT_GUIDE_CONTENT="# $DISPLAY_NAME

$GUIDE_PURPOSE

$(PCATALOG "projectBootstrap.guide.conventionsHeading")

$GUIDE_CONVENTIONS

$(PCATALOG "projectBootstrap.guide.writingHeading")

$(PCATALOG "projectBootstrap.guide.writing")

$(PCATALOG "projectBootstrap.guide.commands")

$(PCATALOG "projectBootstrap.guide.methodHeading")

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

# --- Pilot prompt of the project (Decision 000545, A4/A6): the common prompt lives
# in the Vault (single source); this file personalises it on disk --
# project path, Vault identity, canary to return at opening. ---
PILOT_PROMPT="$TARGET_ABS/state/PILOT-PROMPT.md"
STATE_PATH="state/STATE.md"
# Mission 203 (report 202, A6): the folder exists BEFORE the relative paths are
# computed -- rel_path answers nothing for a folder that is not there yet, which
# left the prompt's links empty when an adopted project had no state/.
mkdir -p "$TARGET_ABS/state"
CANARY="pp-$(od -An -N6 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
REL_PROMPT_TEMPLATE="$(rel_path "$TARGET_ABS/state" "$PILOT_PROMPT_TEMPLATE")"
REL_CHARTER_FROM_STATE="$(rel_path "$TARGET_ABS/state" "$CHARTER")"
if [ -e "$PILOT_PROMPT" ]; then
  note_existing "state/PILOT-PROMPT.md"
  CANARY="$(tr -d '\r' < "$PILOT_PROMPT" | sed -n 's/^canary: "\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' | head -n 1)"
  # Mission 237 (report 236, anomaly 4): an adopted project keeps the state
  # sheet its Pilot prompt names (state_path); the sheet step below writes there,
  # never a second sheet under <project>/state/.
  PP_STATE_PATH="$(tr -d '\r' < "$PILOT_PROMPT" | sed -n 's/^state_path: "\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' | head -n 1)"
  [ -n "$PP_STATE_PATH" ] && STATE_PATH="$PP_STATE_PATH"
else
  mkdir -p "$TARGET_ABS/state"
  pilot_prompt_content > "$PILOT_PROMPT"
  note_added "state/PILOT-PROMPT.md"
fi

# --- .gitignore for the links to the assistant and the skills, PLACED BEFORE
# the links are created: without it, the first `git add -A` of this project (done
# by the installer right after this call) follows every junction/link as
# an ordinary folder and tries to index the whole content of the CLONE as
# files of the project -- measured directly: "Permission denied" while
# writing .git/objects, the Git index of two repositories fighting over the same
# files on disk. Only the THREE paths that link-project creates
# below are excluded (never all of .claude/ or .agents/: a participant
# remains free to track their own .claude/settings.json in this project).
# Mission 231 (step 4b): those three paths are no longer excluded here, by
# folder-wide lines that also hid every skill the project installed there
# itself. Each of the three folders now carries its own .gitignore naming
# the links one by one, written by link-project before any link of its folder
# (tools/sb_installer_helper.py): the links are safe whatever this file says,
# and are always placed. At adoption, an existing .gitignore is never
# modified: a folder-wide line found in it is reported, with why. ---
GITIGNORE="$TARGET_ABS/.gitignore"
LINKS_OK=1
if [ -e "$GITIGNORE" ]; then
  note_existing ".gitignore"
  FOLDER_WIDE=""
  for LINE in "/.claude/skills/" "/.claude/agents/" "/.agents/skills/"; do
    tr -d '\r' < "$GITIGNORE" | grep -qxF -- "$LINE" && FOLDER_WIDE="$FOLDER_WIDE$LINE
"
  done
  if [ -n "$FOLDER_WIDE" ]; then
    CATALOG "projectBootstrap.adopt.gitignoreFolderWide"
    printf '%s' "$FOLDER_WIDE"
  fi
else
  {
    echo "# Second Brain (Mission 173, Q17 ; Mission 231) -- les liens vers l'assistant"
    echo "# et les skills de la methode sont dans .claude/skills, .claude/agents et"
    echo "# .agents/skills ; chacun de ces dossiers porte son propre .gitignore qui les"
    echo "# nomme un par un (tools/sb_installer_helper.py link-project). Un skill"
    echo "# installe pour ce projet dans ces dossiers est suivi."
  } > "$GITIGNORE"
  note_added ".gitignore"
fi

# --- Journal bootstrap, create AND adopt (Mission 218, Decision 012458): the birth
# entry is a STATE: line (it used to be `OPEN:project-bootstrap`, a door key the
# door grammar counts as legacy). At adoption it is written only when the project
# has no journal yet: an existing journal is never touched. A project adopted
# without README.md gets a journal whose Liens points to its Pilot prompt,
# written just above -- append-journal.sh would point to ../README.md. ---
JOURNAL_FILE="$TARGET_ABS/state/journal.md"
if [ ! -e "$JOURNAL_FILE" ]; then
  if [ ! -e "$TARGET_ABS/README.md" ]; then
    printf '# Journal — %s\n\nJournal en ajout seul. Genere/alimente par tools/append-journal.sh, jamais edite a la main.\n\n## Liens\n\n- `see also` — [Prompt Pilot du projet](./PILOT-PROMPT.md)\n\n' "$(basename "$TARGET_ABS")" > "$JOURNAL_FILE"
  fi
  if [ "$MODE" = "create" ]; then
    BIRTH_LINE="$(PCATALOG "projectBootstrap.journal.birthCreate" "$DISPLAY_NAME")"
  else
    BIRTH_LINE="$(PCATALOG "projectBootstrap.journal.birthAdopt" "$DISPLAY_NAME")"
  fi
  bash "$JOURNAL_APPEND" "$TARGET_ABS" "$BIRTH_LINE"
  note_added "state/journal.md"
else
  note_existing "state/journal.md"
fi

# --- Project profile (Mission 240): the three answers, when there is at least
# one, under « ## Profil du projet » of README.md -- a source file, never
# generated, the project's entry point (create writes it above; an adopted
# folder without one gets a README carrying its title and the profile). An
# existing « ## Profil du projet » is kept as it is: adoption only completes.
# No answer: nothing is written, nothing is said. ---
PROFILE_NOTE=""
if [ -n "$PROFILE_RESULT$PROFILE_BLOCKER$PROFILE_CADENCE" ]; then
  README_EXISTED=0
  [ -e "$TARGET_ABS/README.md" ] && README_EXISTED=1
  PROFILE_OUT="$(uv run --no-project "$VAULT_ROOT/tools/starting_profile.py" project-write "$TARGET_ABS/README.md" \
    --result "$PROFILE_RESULT" --blocker "$PROFILE_BLOCKER" --cadence "$PROFILE_CADENCE" --title "$DISPLAY_NAME" 2>&1)"
  PROFILE_NOTE="$(printf '%s\n' "$PROFILE_OUT" | tail -n 1)"
  # Never a half-built project: a profile that could not be written is said,
  # and the birth goes on (the Owner writes the section by hand, or re-adopts).
  case "$PROFILE_NOTE" in
    PROJECT-PROFILE-*) : ;;
    *) printf '%s\n' "$PROFILE_OUT" >&2; PROFILE_NOTE="PROJECT-PROFILE-FAILED" ;;
  esac
  [ "$README_EXISTED" = "0" ] && [ "$MODE" = "adopt" ] && note_added "README.md"
fi

# --- Local Git identity of the project (door 4 of capture
# 2026-09-17-144137). `git init` sets no identity: on a machine without a
# global `user.email` -- the Owner's case -- the very first commit of the
# project failed on « Author identity unknown », whereas the installer
# does set one on the clone. Order: what is already resolved for this
# repository (local or global) wins and is never overwritten; otherwise
# the LOCAL identity of the installed Vault; otherwise a neutral identity, which says
# where it comes from. ---
PB_FALLBACK_NAME="Second Brain Installer"
PB_FALLBACK_EMAIL="installer@example.invalid"
ensure_git_identity() {
  # $1 = project repository.
  GI_NAME="$(git -C "$1" config --get user.name 2>/dev/null || true)"
  GI_EMAIL="$(git -C "$1" config --get user.email 2>/dev/null || true)"
  [ -n "$GI_NAME" ] && [ -n "$GI_EMAIL" ] && return 0
  # --local on the Vault: `--get` alone would go up to the global one, which is
  # precisely the one missing in the measured case.
  GI_VNAME="$(git -C "$VAULT_ROOT" config --local --get user.name 2>/dev/null || true)"
  GI_VEMAIL="$(git -C "$VAULT_ROOT" config --local --get user.email 2>/dev/null || true)"
  [ -n "$GI_NAME" ] || GI_NAME="${GI_VNAME:-$PB_FALLBACK_NAME}"
  [ -n "$GI_EMAIL" ] || GI_EMAIL="${GI_VEMAIL:-$PB_FALLBACK_EMAIL}"
  git -C "$1" config user.name "$GI_NAME" >/dev/null 2>&1 || return 1
  git -C "$1" config user.email "$GI_EMAIL" >/dev/null 2>&1 || return 1
}

# --- Git repository and hook (vcs: git): the hook is never installed if vcs: none
# (Decision 000545, A4 -- checks by command). ---
HOOK_NOTE=0
if [ "$VCS" = "git" ]; then
  if [ ! -e "$TARGET_ABS/.git" ] && command -v git >/dev/null 2>&1; then
    git -C "$TARGET_ABS" init -q -b main >/dev/null 2>&1 \
      || { git -C "$TARGET_ABS" init -q >/dev/null 2>&1 && git -C "$TARGET_ABS" symbolic-ref HEAD refs/heads/main; }
    [ -e "$TARGET_ABS/.git" ] && note_added ".git"
  fi
  # Also set on a repository this script did not create (adopt --git on a
  # folder already under Git): the measured defect is the absence of identity, not
  # the absence of a repository.
  [ -e "$TARGET_ABS/.git" ] && command -v git >/dev/null 2>&1 && ensure_git_identity "$TARGET_ABS"
  if [ -e "$TARGET_ABS/.git" ] && command -v pre-commit >/dev/null 2>&1; then
    (cd "$TARGET_ABS" && pre-commit install >/dev/null 2>&1) || HOOK_NOTE=1
  else
    HOOK_NOTE=1
  fi
fi

# --- Registry line, before the conformity measurement (registration is
# part of the contract). vcs column (Decision 000545, A2) if the registry
# carries it; an older five-column registry keeps its form. ---
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
  # replaces the line of path PROJECT_REL with $1
  # (anchored on the path column, Mission 219 A3)
  awk -F'|' -v p="$PROJECT_REL" -v new="$1" '{ c = $5; gsub(/^[ \t]+|[ \t]+$/, "", c); if (NF >= 6 && c == p && !done) { print new; done=1 } else print }' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
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

# --- Conformity measured by calling the step-4 script, never guessed ---
CONFORMITY="$(bash "$CONFORMITY_CHECK" "$TARGET_ABS")"
CONFORMITY_STATUS="${CONFORMITY%%:*}"

# Rewrites the registry line with the real measurement.
if [ "$REGISTERED" = "0" ] || [ "$VCS_SWITCHED" = "1" ]; then
  replace_registry_row "$(registry_row "$CONFORMITY_STATUS")"
fi

# --- PROJECT-<project_id>.md sheet, schema v2 ---
if [ "$REGISTERED" = "1" ]; then
  if [ "$VCS_SWITCHED" = "1" ] && [ -f "$FICHE" ]; then
    FICHE_TMP="$(mktemp "$(sb_tmp_dir tools)/pb-fiche-XXXXXX")"
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
absolute_path: "$TARGET_NATIVE"
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
- \`absolute_path\` : \`$TARGET_NATIVE\`, dans la forme que ce système comprend (porte 9) : c'est ce chemin que le serveur MCP rend et que le premier message d'une session Pilot porte.

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

# --- First indexes (script only, never by hand). VAULT_ROOT, not
# PROJECTS_DIR alone: projects/ is not a sweep root on its own,
# the Vault's superseded-files.txt stays unique, at its root. At adoption,
# only missing indexes are written (--only-missing): an existing index
# is never rewritten, and the files added above pass the freshness
# guardian from their first commit. ---
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

# --- State sheet and digest of the project (Mission 175, step 3): the structure
# standard promises "state/ = journal + generated sheet" but the skeleton
# only put the journal bootstrap in place -- neither STATE.md nor DIGEST.md existed
# before the first Mission, leaving a session opening with nothing to
# read. Both tools already take a generic project folder as argument
# (no hard-coded workshop path): called here as they are, never copied by
# hand. After the regeneration of the indexes above, so that "Documents
# recents" ["Recent documents"] (STATE.md) and the fresh index are consistent from the first
# read. Mission 218 (Decision 012458): at adoption too -- an adopted project was
# left without the sheet its Pilot prompt sends to. Only what is missing: an
# existing sheet is never touched here (and the tools refuse one they did not
# generate). ---
# Mission 237: the folder is the one state_path names (default state/STATE.md);
# the tools take the folder that holds that state/ folder.
STATE_REL_DIR="$(dirname "$STATE_PATH")"
STATE_BASE="$(dirname "$TARGET_ABS/$STATE_PATH")"
STATE_BASE="$(dirname "$STATE_BASE")"
STATE_FRESH=0
for STATE_PIECE in STATE DIGEST; do
  if [ -e "$TARGET_ABS/$STATE_REL_DIR/$STATE_PIECE.md" ]; then
    note_existing "$STATE_REL_DIR/$STATE_PIECE.md"
    continue
  fi
  if [ "$STATE_PIECE" = "STATE" ]; then
    bash "$BUILD_STATE" "$STATE_BASE" >/dev/null
    STATE_FRESH=1
  else
    bash "$BUILD_DIGEST" "$STATE_BASE" >/dev/null
  fi
  [ -e "$TARGET_ABS/$STATE_REL_DIR/$STATE_PIECE.md" ] && note_added "$STATE_REL_DIR/$STATE_PIECE.md"
done

# --- Links to the assistant and to the method skills (Mission 173,
# Q17: "rien dans le profil" ["nothing in the profile"]). Placed here, for EVERY project created by this
# script -- at installation time as well as years later, through the
# first-install/project-bootstrap skill -- never in the user's
# profile. Read-only on the Vault ($VAULT_ROOT); writing
# only under $TARGET_ABS. ---
if [ "$LINKS_OK" = "1" ]; then
  # Mission 237: at adoption, a link to a skill the Vault renamed
  # (tools/skill-renames.tsv), now pointing nowhere, is replaced by the link
  # under the new name -- a rename, traced by one line in the project's
  # journal; a dead link with no known rename is left as it is.
  if [ "$MODE" = "adopt" ]; then
    RELINK_OUTPUT="$(PYRUN relink-renamed "$VAULT_ROOT" "$TARGET_ABS" 2>/dev/null | tr -d '\r')"
    while IFS="$(printf '\t')" read -r _rl_project _rl_sub _rl_old _rl_new; do
      [ -n "$_rl_new" ] && note_added "$_rl_sub/$_rl_new (replaces $_rl_old)"
    done <<RELINK_EOF
$(printf '%s\n' "$RELINK_OUTPUT" | sed -n 's/^RELINKED //p')
RELINK_EOF
    RELINK_BASE="$(printf '%s\n' "$RELINK_OUTPUT" | sed -n 's/^JOURNAL [^	]*	//p' | head -n 1)"
    if [ -n "$RELINK_BASE" ]; then
      bash "$VAULT_ROOT/tools/append-journal.sh" "$RELINK_BASE" \
        "APPLY:adopt -- liens des skills renommees refaits par project-bootstrap.sh adopt (tools/skill-renames.tsv)" >/dev/null 2>&1 || true
    fi
  fi
  LINK_OUTPUT="$(PYRUN link-project "$VAULT_ROOT" "$TARGET_ABS")" \
    || { echo "REFUS : la creation des liens (assistant/skills) dans $TARGET_ABS a echoue" >&2; exit 1; }

  CLAUDE_CONFLICTS="$(printf '%s\n' "$LINK_OUTPUT" | grep '^CONFLICT SKILL ' | sed 's/^CONFLICT SKILL //')"
  ASSISTANT_CONFLICTS="$(printf '%s\n' "$LINK_OUTPUT" | grep '^CONFLICT ASSISTANT ' | sed 's/^CONFLICT ASSISTANT //')"
  CONFLICT_COUNT="$(printf '%s\n' "$LINK_OUTPUT" | grep '^CONFLICT_COUNT ' | sed 's/^CONFLICT_COUNT //')"
  printf '%s\n' "$LINK_OUTPUT" | grep '^FOREIGN_GITIGNORE ' | sed 's/^FOREIGN_GITIGNORE //' | while IFS= read -r p; do
    [ -n "$p" ] && CATALOG "projectBootstrap.linksForeignGitignore" "$p"
  done
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

  # --- Announcement of the external import approval (Mission 173, Q17, step 6).
  # Same announcement as README/INSTALL.md: project creation is the
  # gesture that places the links leaving the working folder, hence the most
  # useful place to warn before Claude Code asks the question.
  # Through the i18n/ catalogue, never hard-coded in English (Mission 177,
  # step 5: this message was shown in English in the middle of a French
  # installation, measured at the Owner acceptance of 2026-09-14). ---
  CATALOG "projectBootstrap.externalImportApproval"
fi

# --- Mechanical commits (Mission 244, findings 25 and 32): a project born or
# adopted by an explicit call is committed by this script, never left for an
# agent to decide. Two commits, each through the repository's own guardians,
# their output shown; a refusal stops here, its text shown, nothing worked
# around. The project: `create` commits the whole new folder (everything in it
# was written here); `adopt` commits ONLY the files this call added, never a
# file of the adopted project. The Vault: its registry, the project's sheet,
# the indexes of projects/ and the identity, if this call wrote them. The
# installers' historical call keeps committing on its own (install.ps1,
# install.sh): nothing is committed here for it. ---
commit_paths() { # commit_paths <repo> <message> <path relative to repo>...
  local repo="$1" msg="$2" out rc
  shift 2
  [ $# -gt 0 ] || return 0
  [ -n "$(git -C "$repo" status --porcelain -- "$@" 2>/dev/null)" ] || return 0
  git -C "$repo" add -- "$@" >/dev/null 2>&1
  # An author identity, never none (door 4 of capture 2026-09-17-144137): the
  # repository's, else the neutral one, for this commit only.
  if [ -z "$(git -C "$repo" config --get user.email 2>/dev/null)" ]; then
    out="$(git -C "$repo" -c "user.name=$PB_FALLBACK_NAME" -c "user.email=$PB_FALLBACK_EMAIL" commit -q -m "$msg" -- "$@" 2>&1)"
  else
    out="$(git -C "$repo" commit -q -m "$msg" -- "$@" 2>&1)"
  fi
  rc=$?
  printf '%s\n' "$out" | grep -v 'CRLF will be replaced\|LF will be replaced' | grep . | sed 's/^/   /'
  if [ "$rc" -ne 0 ]; then
    # Refused: the index is left as it was (the files stay written, unstaged).
    git -C "$repo" reset -q -- "$@" >/dev/null 2>&1 || git -C "$repo" rm -r -q --cached -- "$@" >/dev/null 2>&1
  fi
  return $rc
}
if [ "$EXPLICIT" = "1" ]; then
  if [ "$VCS" = "git" ] && [ -e "$TARGET_ABS/.git" ] && command -v git >/dev/null 2>&1; then
    PROJECT_PATHS=""
    if [ "$MODE" = "create" ]; then
      PROJECT_PATHS="."
      PROJECT_MSG="Initial scaffold from project-bootstrap ($DISPLAY_NAME)"
    else
      PROJECT_MSG="Adoption by project-bootstrap: the files it added ($DISPLAY_NAME)"
      while IFS= read -r p; do
        p="${p%% (*}"
        [ -n "$p" ] && [ "$p" != ".git" ] && [ -e "$TARGET_ABS/$p" ] && PROJECT_PATHS="$PROJECT_PATHS
$p"
      done <<ADDED_EOF
$ADDED
ADDED_EOF
      for p in .claude/skills/.gitignore .claude/agents/.gitignore .agents/skills/.gitignore; do
        [ -f "$TARGET_ABS/$p" ] && [ -n "$(git -C "$TARGET_ABS" status --porcelain -- "$p" 2>/dev/null)" ]           && PROJECT_PATHS="$PROJECT_PATHS
$p"
      done
    fi
    if [ -n "$(printf '%s' "$PROJECT_PATHS" | tr -d '[:space:]')" ]; then
      PP_LIST=()
      while IFS= read -r p; do [ -n "$p" ] && PP_LIST+=("$p"); done <<PP_EOF
$PROJECT_PATHS
PP_EOF
      if commit_paths "$TARGET_ABS" "$PROJECT_MSG" "${PP_LIST[@]}"; then
        CATALOG "projectBootstrap.commit.done" "$TARGET_NATIVE" "$(git -C "$TARGET_ABS" rev-parse --short HEAD 2>/dev/null)"
      else
        CATALOG "projectBootstrap.commit.refused" "$TARGET_NATIVE"
        exit 1
      fi
    fi
  fi
  if git -C "$VAULT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    VAULT_PATHS=()
    for p in "projects/PROJECT-REGISTRY.md" "projects/$(basename "$FICHE")" VAULT-IDENTITY.md index.md; do
      [ -n "$(git -C "$VAULT_ROOT" status --porcelain -- "$p" 2>/dev/null)" ] && VAULT_PATHS+=("$p")
    done
    while IFS= read -r p; do
      [ -n "$p" ] && VAULT_PATHS+=("$p")
    done <<VIDX_EOF
$(git -C "$VAULT_ROOT" status --porcelain -- projects 2>/dev/null | sed 's/^...//' | grep -E '(^|/)index[^/]*\.md$' || true)
VIDX_EOF
    if [ "${#VAULT_PATHS[@]}" -gt 0 ]; then
      # The Vault's guardians want a fresh preflight stamp.
      (cd "$VAULT_ROOT" && bash tools/session-preflight.sh >/dev/null 2>&1) || true
      if commit_paths "$VAULT_ROOT" "Register project: $DISPLAY_NAME ($PROJECT_REL)" "${VAULT_PATHS[@]}"; then
        CATALOG "projectBootstrap.commit.done" "$(native_path "$VAULT_ROOT")" "$(git -C "$VAULT_ROOT" rev-parse --short HEAD 2>/dev/null)"
      else
        CATALOG "projectBootstrap.commit.refused" "$(native_path "$VAULT_ROOT")"
        exit 1
      fi
    fi
  fi
  # Mission 245 (capture 105405, finding A4): the sheet generated above, before
  # the two commits, said « No commits yet » and an uncommitted registry, and
  # the project's Pilot believed it. The sheet this call wrote (never one that
  # was already there) is regenerated once the commits exist, with its digest,
  # and committed alone: it then shows the project's head and a clean registry.
  if [ "$STATE_FRESH" = "1" ] && [ "$VCS" = "git" ] && git -C "$TARGET_ABS" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    bash "$BUILD_STATE" "$STATE_BASE" >/dev/null 2>&1
    bash "$BUILD_DIGEST" "$STATE_BASE" >/dev/null 2>&1
    STATE_PATHS=()
    for p in "$STATE_REL_DIR/STATE.md" "$STATE_REL_DIR/DIGEST.md"; do
      [ -n "$(git -C "$TARGET_ABS" status --porcelain -- "$p" 2>/dev/null)" ] && STATE_PATHS+=("$p")
    done
    if [ "${#STATE_PATHS[@]}" -gt 0 ]; then
      if commit_paths "$TARGET_ABS" "State sheet regenerated after the bootstrap commits ($DISPLAY_NAME)" "${STATE_PATHS[@]}"; then
        CATALOG "projectBootstrap.commit.done" "$TARGET_NATIVE" "$(git -C "$TARGET_ABS" rev-parse --short HEAD 2>/dev/null)"
      else
        CATALOG "projectBootstrap.commit.refused" "$TARGET_NATIVE"
        exit 1
      fi
    fi
  fi
fi

# --- Report of the explicit modes (create/adopt/--order): the installers'
# historical call stays silent here, its log is capped. ---
if [ "$EXPLICIT" = "1" ]; then
  if [ "$HOOK_NOTE" = "1" ]; then
    CATALOG "projectBootstrap.hookMissing" "$TARGET_NATIVE"
  fi
  if [ "$VCS_SWITCHED" = "1" ]; then
    CATALOG "projectBootstrap.adopt.gitSwitched"
  fi
  case "$PROFILE_NOTE" in
    PROJECT-PROFILE-WRITTEN) CATALOG "projectBootstrap.profile.written" "$(native_path "$TARGET_ABS/README.md")" ;;
    PROJECT-PROFILE-KEPT) CATALOG "projectBootstrap.profile.kept" "$(native_path "$TARGET_ABS/README.md")" ;;
    PROJECT-PROFILE-FAILED) CATALOG "projectBootstrap.profile.failed" "$(native_path "$TARGET_ABS/README.md")" ;;
  esac
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

    # --- Reorganisation plan into seven functions: proposed, never applied
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
    # Door 11 of capture 2026-09-17-144137: the plan proposed to
    # move `index.md` to `knowledge/index.md` -- the index that this very
    # call had just written. The plan speaks only of what ALREADY EXISTS: everything
    # this call added (list $ADDED, shown above to the
    # participant) is removed from it.
    for F in "$TARGET_ABS"/*; do
      [ -f "$F" ] || continue
      B="$(basename "$F")"
      case "
$ADDED
" in
        *"
$B
"*) continue ;;
      esac
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

  # --- Block to consume (Decision 000545, A4; Decision 201623 part C,
  # amends 000545 A4: the Project instructions are SHOWN in full,
  # not only pointed to by their path -- a participant must be able to
  # paste as is, without going to open the template themselves). Fail-closed
  # extraction BEFORE any output of this block: a template without its two
  # markers must produce no partial display.
  PROMPT_COMMON_BLOCK="$(extract_prompt_common_block "$PILOT_PROMPT_TEMPLATE")" || exit 1
  # The trunk names the server of THIS Vault (Decision 152251 C): its only
  # placeholder is rendered here, nothing else of the trunk changes.
  PROMPT_COMMON_BLOCK="$(printf '%s\n' "$PROMPT_COMMON_BLOCK" | sed "s/{{VAULT_SHORT_ID}}/$VAULT_SHORT_ID/g")"
  CONSUME_PURPOSE="${ORDER_PURPOSE:-$DISPLAY_NAME}"

  CATALOG "projectBootstrap.consume.header"
  # Mission 234 (D-A): the Pilot Project is named `SB - <display name>`.
  CATALOG "projectBootstrap.consume.project" "SB - $DISPLAY_NAME"
  # --- Project instructions: header, then the canonical common trunk
  # shown as is (single source, never copied nor translated here), framed
  # by "---" lines -- form chosen to stay readable as plain text on
  # the three systems and to mark unambiguously where what must be pasted
  # begins and ends. The four field lines that follow the
  # closing of the frame (path, Vault, canary, purpose) are outside the frame:
  # they inform the participant, they are not part of the text to
  # paste as Project instructions.
  # Mission 245 (capture 105405, finding A3): the copy command sits between
  # « create the Project » and « paste » -- copying the Project's name in
  # gesture 1 would replace a block copied earlier.
  CATALOG "projectBootstrap.consume.instructionsCopy" "$TARGET_NATIVE"
  echo "  ---"
  printf '%s\n' "$PROMPT_COMMON_BLOCK"
  echo "  ---"
  CATALOG "projectBootstrap.consume.instructionsPath" "$TARGET_NATIVE"
  CATALOG "projectBootstrap.consume.instructionsVault" "$VAULT_ID" "$VAULT_REF"
  CATALOG "projectBootstrap.consume.instructionsCanary" "$CANARY"
  CATALOG "projectBootstrap.consume.instructionsPurpose" "$CONSUME_PURPOSE"
  CATALOG "projectBootstrap.consume.firstMessage" "$TARGET_NATIVE"
  CATALOG "projectBootstrap.consume.canary" "$CANARY" "$(native_path "$PILOT_PROMPT")"
  # Mission 244 (findings 27, 28): the block goes to the clipboard by the tool,
  # never by a selection in a terminal (which cuts its long lines) -- when a
  # terminal is there, or a test names SB_CLIPBOARD_FILE; otherwise the command
  # that copies it is named.
  BLOCK_FILE="$(mktemp "$(sb_tmp_dir tools)/pb-block-XXXXXX")"
  printf '%s\n' "$PROMPT_COMMON_BLOCK" > "$BLOCK_FILE"
  if { [ -t 1 ] || [ -n "${SB_CLIPBOARD_FILE:-}" ]; } && sb_clipboard_copy "$BLOCK_FILE"; then
    CATALOG "projectBootstrap.consume.copiedAgain"
  else
    CATALOG "projectBootstrap.consume.copyHint" "$TARGET_NATIVE"
  fi
  rm -f "$BLOCK_FILE"
fi

echo "$FICHE"
