#!/usr/bin/env bash
# Regenere <projet>/state/STATE.md a partir du journal, de l'etat Git et du
# listing des fichiers. Fiche generee : ne jamais l'editer a la main.
#
# Convention de tags reconnue dans les lignes du journal (texte apres l'horodatage) :
#   ETAT:<texte>     -> etat courant (derniere occurrence retenue)
#   PROCHAIN:<texte> -> prochaine action (derniere occurrence retenue)
#   REPRISE:<texte>  -> note de reprise ; doit etre la derniere ligne du journal
# Depuis Mission 038, double reconnaissance : STATE:/NEXT:/RESUME: (anglais) en plus des tags francais ci-dessus.
#
# Portes (depuis Mission 051) : une-porte-une-ligne-une-clé.
#   OUVERT:<clé> -- <texte>   -> ouvre/reouvre une porte (francais, historique seulement)
#   OPEN:<clé> -- <texte>     -> ouvre/reouvre une porte (anglais, nouvelles ecritures)
#   CLOSE:<clé> -- <reference> -> ferme une porte ; aucun equivalent francais, tag de fermeture unique
#   <clé> ~ ^(open|frozen)-[a-z0-9-]+ ; separateur " -- " obligatoire entre la clé et le texte.
#   Etat affiche = pour chaque clé, la derniere occurrence dans le journal (ordre d'ajout, journal en
#   ajout seul donc chronologique) : si c'est un OUVERT:/OPEN:, la porte est affichee avec son texte ;
#   si c'est un CLOSE: posterieur de la meme clé, la porte est retiree. Une reouverture ulterieure la
#   fait reapparaitre.
#   Lignes OUVERT:/OPEN: sans clé conforme = legacy (anterieures a la baseline arbitree du 2026-08-25,
#   voir DECISION-2026-08-25-110935) : exclues de la liste des portes, comptees en une ligne unique.
# Une ligne sans tag reconnu n'alimente aucune rubrique ci-dessus.
#
# usage: build-state.sh <chemin-projet>

set -u

PROJECT="${1:-}"
if [ -z "$PROJECT" ]; then
  echo "usage: build-state.sh <chemin-projet>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$PROJECT" && pwd)"
STATE_DIR="$PROJECT_ROOT/state"
JOURNAL="$STATE_DIR/journal.md"
STATE_FILE="$STATE_DIR/STATE.md"
CONTRACT_TEMPLATE="$VAULT_ROOT/templates/pilot-contract-template.md"

# --- 0. Contrat du Pilot, recopie depuis le gabarit, jamais redige ici ---
# Plafond arbitre : exactement sept lignes (Mission 029). Echec explicite,
# fiche non ecrite, si le gabarit s'ecarte de ce plafond.
CONTRACT_LINES="$(awk '
  /<!-- CONTRACT:BEGIN -->/ { f=1; next }
  /<!-- CONTRACT:END -->/   { f=0 }
  f && NF { print }
' "$CONTRACT_TEMPLATE" 2>/dev/null)"

CONTRACT_COUNT=0
if [ -n "$CONTRACT_LINES" ]; then
  CONTRACT_COUNT="$(printf '%s\n' "$CONTRACT_LINES" | wc -l)"
fi

if [ ! -f "$CONTRACT_TEMPLATE" ]; then
  echo "ERREUR build-state.sh : gabarit de contrat introuvable ($CONTRACT_TEMPLATE). Fiche d'état non générée." >&2
  exit 1
fi

if [ "$CONTRACT_COUNT" -ne 7 ]; then
  echo "ERREUR build-state.sh : le gabarit de contrat ($CONTRACT_TEMPLATE) porte $CONTRACT_COUNT ligne(s) entre CONTRACT:BEGIN et CONTRACT:END, le plafond arbitré est de sept lignes exactement. Fiche d'état non générée." >&2
  exit 1
fi

mkdir -p "$STATE_DIR"

# --- 0bis. Références de session (catalogue fixe, depuis Mission 053) ---
# Chemins relatifs calcules depuis $STATE_DIR (jamais recopiés en dur) : la
# fiche est un catalogue de pointeurs, aucun contenu normatif n'est recopié.
session_ref_line() {
  local target="$1" desc="$2" rel
  rel="$(realpath --relative-to="$STATE_DIR" "$target" 2>/dev/null)"
  [ -z "$rel" ] && rel="(introuvable : $target)"
  echo "- \`$rel\` — $desc"
}

SESSION_REFS="$(
  session_ref_line "$VAULT_ROOT/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md" "Charte des rôles et détermination de session — Pilot/Executor, périmètre d'écriture du Pilot."
  session_ref_line "$VAULT_ROOT/rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md" "Relais entre rôles par mini-prompts — mini-prompt à l'aller, bloc RELAY au retour."
  session_ref_line "$VAULT_ROOT/decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md" "Decision — tag CLOSE: et portes à clé du journal."
  session_ref_line "$VAULT_ROOT/rules/RULES-2026-08-21-115658-document-linking-standard.md" "Standard de liens entre documents."
  session_ref_line "$VAULT_ROOT/decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md" "Decision — arbitrages doctrinaux du 2026-08-25 (shell Pilot révoqué, auto-rangement, références de session, anglicisation du vocabulaire de liens)."
)"

get_field() {
  awk -v f="$2" '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { exit }
    infm && $0 ~ "^"f":" {
      sub("^"f":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$1" 2>/dev/null
}

# --- 1. Lecture des balises du journal ---
LAST_TS=""
LAST_LINE=""
ETAT="Aucune entree ETAT: dans le journal."
PROCHAIN="Aucune entree PROCHAIN: dans le journal."
OUVERTES="Aucune."
REPRISE_STATUS="Le journal ne se termine pas par une note de reprise (REPRISE:) — rien reconstitue."

if [ -f "$JOURNAL" ]; then
  DATED="$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$JOURNAL" || true)"
  if [ -n "$DATED" ]; then
    LAST_LINE="$(printf '%s\n' "$DATED" | tail -n 1)"
    LAST_TS="$(printf '%s' "$LAST_LINE" | awk '{print $1}')"

    E="$(printf '%s\n' "$DATED" | grep -E 'ETAT:|STATE:' | tail -n 1 | sed -E 's/^.*(ETAT|STATE):[[:space:]]*//')"
    [ -n "$E" ] && ETAT="$E"

    P="$(printf '%s\n' "$DATED" | grep -E 'PROCHAIN:|NEXT:' | tail -n 1 | sed -E 's/^.*(PROCHAIN|NEXT):[[:space:]]*//')"
    [ -n "$P" ] && PROCHAIN="$P"

    # Portes a clé : traitement en ordre d'ajout du journal (ajout seul donc
    # chronologique) -- la derniere occurrence par clé (OUVERT:/OPEN: ou
    # CLOSE:) determine l'etat net. Sortie : lignes "D<TAB>texte" pour les
    # portes affichees, une ligne "L<TAB>n" pour le compte legacy.
    DOORS_RAW="$(printf '%s\n' "$DATED" | awk '
      {
        line = $0
        # Le tag doit suivre immediatement lhorodatage (premier champ) : une
        # occurrence de "OPEN:"/"OUVERT:" en prose ailleurs sur la ligne (ex.
        # une ligne STATE: qui documente la convention) ne doit pas etre
        # prise pour une porte.
        tsend = index(line, " ")
        after_ts = substr(line, tsend + 1)
        if (after_ts ~ /^(OUVERT|OPEN):[[:space:]]*/) {
          sub(/^(OUVERT|OPEN):[[:space:]]*/, "", after_ts)
          rest = after_ts
          kind = "open"
        } else if (after_ts ~ /^CLOSE:[[:space:]]*/) {
          sub(/^CLOSE:[[:space:]]*/, "", after_ts)
          rest = after_ts
          kind = "close"
        } else {
          next
        }

        if (rest ~ /^(open|frozen)-[a-z0-9-]+ -- /) {
          keyend = index(rest, " -- ")
          key = substr(rest, 1, keyend - 1)
          if (kind == "open") {
            if (!(key in seen)) { order[++n] = key; seen[key] = 1 }
            text[key] = rest
            status[key] = "open"
          } else if (key in seen) {
            status[key] = "closed"
          }
        } else if (kind == "open") {
          legacy++
        }
      }
      END {
        for (i = 1; i <= n; i++) {
          k = order[i]
          if (status[k] == "open") print "D\t" text[k]
        }
        print "L\t" (legacy + 0)
      }
    ')"

    DOOR_LINES="$(printf '%s\n' "$DOORS_RAW" | awk -F'\t' '$1=="D"{print substr($0, 3)}')"
    LEGACY_N="$(printf '%s\n' "$DOORS_RAW" | awk -F'\t' '$1=="L"{print $2}')"

    OUVERTES=""
    if [ -n "$DOOR_LINES" ]; then
      OUVERTES="$(printf '%s\n' "$DOOR_LINES" | sed 's/^/- /')"
    fi
    [ -z "$OUVERTES" ] && OUVERTES="Aucune."

    LEGACY_HISTORY="Aucune."
    if [ -n "$LEGACY_N" ] && [ "$LEGACY_N" -gt 0 ]; then
      LEGACY_HISTORY="- ${LEGACY_N} lignes OPEN legacy, compte historique figé par la baseline du 2026-08-25 sur des lignes que le journal en ajout seul rend intouchables — voir journal."
    fi

    case "$LAST_LINE" in
      *'REPRISE:'*|*'RESUME:'*) REPRISE_STATUS="Note de reprise en fin de journal : $(printf '%s' "$LAST_LINE" | sed -E 's/^.*(REPRISE|RESUME):[[:space:]]*//')" ;;
    esac
  fi
fi

# --- 2. Catalogue des documents recents (mtime desc, limite 15) ---
RECENTS="$(find "$PROJECT_ROOT" -type f -name '*.md' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n 15 | cut -d' ' -f2-)"

DOC_LIST=""
if [ -n "$RECENTS" ]; then
  while IFS= read -r F; do
    [ -z "$F" ] && continue
    REL="$(realpath --relative-to="$PROJECT_ROOT" "$F")"
    T="$(get_field "$F" title)"
    [ -z "$T" ] && T="(sans titre)"
    DOC_LIST="$DOC_LIST- \`$REL\` — $T
"
  done <<EOF
$RECENTS
EOF
else
  DOC_LIST="Aucun document .md trouve."
fi

# --- 3. Etat des depots ---
VAULT_STATUS="$(git -C "$VAULT_ROOT" status -sb 2>/dev/null || echo "non mesurable")"
PROJECT_GIT_ROOT="$(git -C "$PROJECT_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$PROJECT_GIT_ROOT" ]; then
  PROJECT_STATUS="$(git -C "$PROJECT_GIT_ROOT" status -sb 2>/dev/null)"
else
  PROJECT_STATUS="non mesurable (pas un depot Git)"
fi

# --- 4. Ecriture ---
GEN_REL="$(realpath --relative-to="$STATE_DIR" "$SCRIPT_DIR/build-state.sh")"
{
  echo "---"
  echo "type: state"
  echo "title: \"Fiche d'état — $(basename "$PROJECT_ROOT")\""
  echo "description: \"Fiche générée automatiquement par $GEN_REL — catalogue, pas un résumé.\""
  echo "status: GENERATED"
  echo "generated_by: $GEN_REL"
  echo "---"
  echo ""
  echo "# FICHE D'ÉTAT — $(basename "$PROJECT_ROOT")"
  echo ""
  echo "> Générée automatiquement par \`$GEN_REL\`. Ne pas éditer à la main."
  echo "> Source : \`state/journal.md\` (dernière entrée : ${LAST_TS:-aucune})."
  echo "> Photo prise avant le commit de clôture (session-close §3) : tête et porcelain peuvent avoir un commit de retard, les refs Git font foi."
  echo ""
  echo "## Contrat du Pilot"
  echo ""
  printf '%s\n' "$CONTRACT_LINES"
  echo ""
  echo "## Références de session"
  echo ""
  printf '%s\n' "$SESSION_REFS"
  echo ""
  echo "## État courant"
  echo ""
  echo "$ETAT"
  echo ""
  echo "## Prochaine action"
  echo ""
  echo "$PROCHAIN"
  echo ""
  echo "## Portes ouvertes"
  echo ""
  echo "$OUVERTES"
  echo ""
  echo "## Historique legacy"
  echo ""
  echo "$LEGACY_HISTORY"
  echo ""
  echo "## Documents récents"
  echo ""
  printf '%s' "$DOC_LIST"
  echo ""
  echo "## État des dépôts"
  echo ""
  echo "**$(basename "$VAULT_ROOT") :**"
  echo '```'
  echo "$VAULT_STATUS"
  echo '```'
  echo ""
  echo "**$(basename "${PROJECT_GIT_ROOT:-$PROJECT_ROOT}") :**"
  echo '```'
  echo "$PROJECT_STATUS"
  echo '```'
  echo ""
  echo "## Reprise"
  echo ""
  echo "$REPRISE_STATUS"
  echo ""
  echo "## Liens"
  echo ""
  echo "- \`prescribed by\` — [Lot A — journal, fiche d'état, index générés, recherche par contenu et fichier marqueur](../missions/MISSION-2026-08-23-122712-027-state-journal-indexes-search-and-marker.md)"
} > "$STATE_FILE"
