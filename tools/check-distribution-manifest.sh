#!/usr/bin/env bash
# Verifie distribution-manifest.txt (a la racine de ce depot) contre l'etat reel du depot.
# Lecture seule : ne corrige jamais un defaut trouve, se contente de refuser
# et de le lister. N'est cable sur aucun hook (Mission 073, arbitrage C) --
# execution manuelle uniquement, resultat rapporte par l'appelant.
#
# Refuse (exit 1) si l'une de ces conditions se verifie :
#   1. un fichier de `git ls-files` est absent du manifeste ;
#   2. un chemin du manifeste n'existe plus dans `git ls-files` ;
#   3. un chemin figure deux fois dans le manifeste ;
#   4. un verdict n'est ni DISTRIBUABLE ni INTERNE ;
#   5. un fichier porte `distributable: false` en front-matter alors que le
#      manifeste le classe DISTRIBUABLE, ou l'inverse (`distributable: true`
#      alors que le manifeste le classe INTERNE).
#
# usage: check-distribution-manifest.sh

set -u

# Garde Git (Mission 125, meme raison qu'a check-secrets.sh) : refus
# explicite hors d'un depot, plutot qu'un $VAULT_ROOT vide.
VAULT_ROOT="$(git rev-parse --show-toplevel)" || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}
MANIFEST="$VAULT_ROOT/distribution-manifest.txt"

if [ ! -f "$MANIFEST" ]; then
  echo "REFUS : manifeste introuvable : $MANIFEST" >&2
  exit 1
fi

FAIL=0
DISTRIBUABLE_COUNT=0
INTERNE_COUNT=0

# Tabulation calculee une seule fois (Mission 127) : "IFS=\"\$(printf '\t')\""
# repete dans la condition d'un while relance ce sous-processus a CHAQUE
# iteration (~400 lignes de manifeste) -- mesure comme le second cout
# dominant une fois le pipeline par ligne de l'etape 4/5 elimine.
TAB="$(printf '\t')"

TRACKED_FILE="$(mktemp)"
MANIFEST_PATHS_FILE="$(mktemp)"
FM_DIST_FILE="$(mktemp)"
trap 'rm -f "$TRACKED_FILE" "$MANIFEST_PATHS_FILE" "$FM_DIST_FILE"' EXIT

# `skills-warehouse/` hors perimetre (Mission 168, arbitrage Owner
# 2026-09-11, option c) : sous-arbre adopte tel quel (T24), jamais soumis au
# manifeste de distribution du Vault -- ses propres standards de provenance
# (AGENTS.md, PROVENANCE.md par paquet) en tiennent lieu.
#
# Fiches de projet (`projects/PROJECT-<date>-<code>.md`) hors perimetre
# (Mission 168, ticket 03) : ecrites par tools/project-bootstrap.sh apres
# l'installation, une par projet cree sur le poste de chaque utilisateur --
# jamais un contenu du depot distribue lui-meme. Le manifeste decrit l'etat
# au moment de la distribution (registry v1 D1b) ; le registre et l'index de
# `projects/` restent, eux, des lignes reelles du manifeste (squelettes
# distribues, ticket 01) -- seules les fiches nees APRES coup en sont
# exemptees, meme principe que l'exemption skills-warehouse ci-dessus.
#
# Formes de l'assistant (Mission 168, ticket 06) : tools/generate-assistant.ps1
# ecrit .claude/agents/<slug>.md, .agents/skills/<slug>/ et
# web-package/<slug>/ a l'installation, sous un identifiant derive du nom
# choisi par le participant -- jamais un chemin fixe que le manifeste
# pourrait lister a l'avance (le nom, donc le slug, n'existe pas avant que
# quelqu'un installe). Un renommage deplace ces memes formes, sous l'ancien
# slug, vers _trash/assistant-rename-<ancien slug>-<horodatage>/ (Move-
# AssistantFormsToTrash, meme ticket) : meme motif, exempte de la meme facon.
# Meme principe et meme motif que l'exemption projects/PROJECT-*.md
# ci-dessus : contenu ne au poste de l'utilisateur, jamais un contenu du
# depot distribue lui-meme.
git -C "$VAULT_ROOT" ls-files \
  | grep -v '^skills-warehouse/' \
  | grep -vE '^projects/PROJECT-[0-9]{4}-[0-9]{2}-[0-9]{2}-.*\.md$' \
  | grep -vE '^\.claude/agents/.*\.md$' \
  | grep -vE '^\.agents/skills/.*$' \
  | grep -vE '^web-package/.*$' \
  | grep -vE '^_trash/assistant-rename-.*$' \
  | sort > "$TRACKED_FILE"
cut -f1 "$MANIFEST" | sort > "$MANIFEST_PATHS_FILE"

# Pre-passe groupee (Mission 127) : un seul processus awk sur tous les
# fichiers existants du manifeste, au lieu d'un pipeline head|grep|awk|tr par
# ligne (jusqu'a ~400 x 4 processus) -- le fork de processus domine le cout
# sous Git Bash/Windows, meme diagnostic et meme patron que
# tools/build-indexes.sh. Comportement identique : mêmes 20 premières lignes
# de chaque fichier, même motif exact `^distributable:[[:space:]]*(true|false)[[:space:]]*$`,
# même premier match retenu (grep -m1) -- mesure par l'oracle de la Mission 127
# (sortie byte-identique avant/apres).
EXISTING_PATHS=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  [ -f "$VAULT_ROOT/$p" ] && EXISTING_PATHS="$EXISTING_PATHS
$p"
done < <(cut -f1 "$MANIFEST")

# The table goes through a temp file, never a here-document: its size is
# (install path length + file path) x ~500 lines, and Git Bash's bash 5.3
# deadlocks for good on a here-document between 65537 and ~65690 bytes --
# reached by an install path of about 71 characters.
printf '%s\n' "$EXISTING_PATHS" | sed "s#^#$VAULT_ROOT/#" | tr '\n' '\0' | xargs -0 awk '
  FNR==1 { distv="" }
  FNR<=20 && distv=="" && $0 ~ /^distributable:[[:space:]]*(true|false)[[:space:]]*$/ {
    v=$0; sub(/^distributable:[[:space:]]*/,"",v); gsub(/[[:space:]]+$/,"",v); distv=v
  }
  ENDFILE { print FILENAME "\t" distv }
' > "$FM_DIST_FILE" 2>/dev/null

declare -A FM_DIST=()
while IFS="$TAB" read -r fpath fdist; do
  [ -z "$fpath" ] && continue
  FM_DIST["${fpath#"$VAULT_ROOT"/}"]="$fdist"
done < "$FM_DIST_FILE"

# --- 1. fichier suivi absent du manifeste ---
MISSING_FROM_MANIFEST="$(comm -23 "$TRACKED_FILE" "$MANIFEST_PATHS_FILE")"
if [ -n "$MISSING_FROM_MANIFEST" ]; then
  FAIL=1
  echo "ABSENT-DU-MANIFESTE : fichier suivi sans ligne au manifeste :" >&2
  printf '%s\n' "$MISSING_FROM_MANIFEST" | while IFS= read -r f; do
    echo "  $f" >&2
  done
fi

# --- 2. chemin du manifeste qui n'existe plus dans git ls-files ---
STALE_IN_MANIFEST="$(comm -13 "$TRACKED_FILE" "$MANIFEST_PATHS_FILE")"
if [ -n "$STALE_IN_MANIFEST" ]; then
  FAIL=1
  echo "FANTOME-AU-MANIFESTE : chemin du manifeste non suivi par Git :" >&2
  printf '%s\n' "$STALE_IN_MANIFEST" | while IFS= read -r f; do
    echo "  $f" >&2
  done
fi

# --- 3. chemin en double dans le manifeste ---
DUPLICATES="$(cut -f1 "$MANIFEST" | sort | uniq -d)"
if [ -n "$DUPLICATES" ]; then
  FAIL=1
  echo "DOUBLON-AU-MANIFESTE : chemin present plus d'une fois :" >&2
  printf '%s\n' "$DUPLICATES" | while IFS= read -r f; do
    echo "  $f" >&2
  done
fi

# --- 4/5. verdict et coherence distributable: ---
LINE_NO=0
while IFS="$TAB" read -r REL_PATH VERDICT || [ -n "$REL_PATH" ]; do
  LINE_NO=$((LINE_NO + 1))
  [ -z "$REL_PATH" ] && continue

  case "$VERDICT" in
    DISTRIBUABLE) DISTRIBUABLE_COUNT=$((DISTRIBUABLE_COUNT + 1)) ;;
    INTERNE) INTERNE_COUNT=$((INTERNE_COUNT + 1)) ;;
    *)
      FAIL=1
      echo "VERDICT-INVALIDE : ligne $LINE_NO, $REL_PATH : verdict '$VERDICT' ni DISTRIBUABLE ni INTERNE" >&2
      continue
      ;;
  esac

  FULL="$VAULT_ROOT/$REL_PATH"
  [ -f "$FULL" ] || continue

  FM_DISTRIBUTABLE="${FM_DIST[$REL_PATH]:-}"

  if [ "$FM_DISTRIBUTABLE" = "false" ] && [ "$VERDICT" = "DISTRIBUABLE" ]; then
    FAIL=1
    echo "INCOHERENCE-DISTRIBUTABLE : $REL_PATH porte 'distributable: false' en front-matter mais le manifeste le classe DISTRIBUABLE" >&2
  fi
  if [ "$FM_DISTRIBUTABLE" = "true" ] && [ "$VERDICT" = "INTERNE" ]; then
    FAIL=1
    echo "INCOHERENCE-DISTRIBUTABLE : $REL_PATH porte 'distributable: true' en front-matter mais le manifeste le classe INTERNE" >&2
  fi
done < "$MANIFEST"

echo "Comptes : DISTRIBUABLE=$DISTRIBUABLE_COUNT INTERNE=$INTERNE_COUNT TOTAL=$((DISTRIBUABLE_COUNT + INTERNE_COUNT))"

if [ "$FAIL" -ne 0 ]; then
  echo "REFUS : le manifeste ne passe pas les controles ci-dessus." >&2
  exit 1
fi

exit 0
