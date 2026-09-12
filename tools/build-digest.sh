#!/usr/bin/env bash
# Regenere <projet>/state/DIGEST.md : lecture d'ouverture plafonnee du Pilot,
# sur le modele de build-state.sh (memes conventions d'appel et de calcul de
# racines). Bash pur, aucun appel reseau, aucun appel modele.
#
# Plafond fail-closed (Mission 121) : DIGEST_CAP_BYTES octets, constante ci-
# dessous. Le digest est ecrit sur un fichier temporaire dans le meme
# dossier, sa taille est mesuree, puis :
#   - taille <= plafond -> le fichier temporaire remplace state/DIGEST.md ;
#   - taille >  plafond -> code de sortie != 0, DIGEST.md n'est ni ecrit ni
#     ecrase, le fichier temporaire est retire.
# Chaque section du digest est elle-meme tronquee a une part fixe du plafond
# avant assemblage (repartition ci-dessous) : la mesure finale reste le seul
# garde-fou qui fait foi, jamais contournee.
#
# Contenu, dans l'ordre (Mission 121, Objectif/Instructions point 2) :
#   1. En-tete       : horodatage de generation, derniere entree du journal.
#   2. Etat des depots : refs vault/projet (8 premiers caracteres), avance
#      ahead/behind calculee, nombre de lignes porcelain (compte, pas liste).
#   3. Journal        : tail 3, chaque ligne tronquee a 300 caracteres avec
#      marqueur "[...]".
#   4. Portes ouvertes : identifiants seuls, un par ligne.
#   5. Derniere Mission : numero et statut court depuis MISSION-INDEX.md.
#   6. Pointeurs      : noms de fichiers seuls (dernier handoff, dernier
#      rapport).
#
# usage: build-digest.sh <chemin-projet>
# override de test (Validation 3, Mission 121) : BUILD_DIGEST_CAP_OVERRIDE=<n>
# reduit le plafond sans editer ce script -- absent en usage normal.

set -u

DIGEST_CAP_BYTES=8000
CAP_BYTES="$DIGEST_CAP_BYTES"
if [ -n "${BUILD_DIGEST_CAP_OVERRIDE:-}" ]; then
  CAP_BYTES="$BUILD_DIGEST_CAP_OVERRIDE"
fi

PROJECT="${1:-}"
if [ -z "$PROJECT" ]; then
  echo "usage: build-digest.sh <chemin-projet>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$PROJECT" && pwd)"
STATE_DIR="$PROJECT_ROOT/state"
JOURNAL="$STATE_DIR/journal.md"
DIGEST_FILE="$STATE_DIR/DIGEST.md"
MISSION_INDEX="$PROJECT_ROOT/missions/MISSION-INDEX.md"
HANDOFFS_DIR="$PROJECT_ROOT/handoffs"
REPORTS_DIR="$PROJECT_ROOT/reports"
READING_LIST="$VAULT_ROOT/skills/session-start/reading-list.md"

mkdir -p "$STATE_DIR"

# --- Repartition du plafond entre les six sections. Une reserve fixe est
# retiree d'abord pour l'enveloppe markdown (front-matter, titres, section
# headers) qui n'est pas elle-meme donnee a tronquer. Parts arbitraires mais
# fixes : a ajuster ici seulement si une section deborde en usage reel --
# jamais en desactivant la mesure finale. ---
CHROME_RESERVE=600
USABLE=$((CAP_BYTES - CHROME_RESERVE))
[ "$USABLE" -lt 60 ] && USABLE=60

PART_HEADER=5
PART_REPOS=15
PART_JOURNAL=40
PART_DOORS=30
PART_MISSION=5
PART_POINTERS=5

BUDGET_HEADER=$((USABLE * PART_HEADER / 100))
BUDGET_REPOS=$((USABLE * PART_REPOS / 100))
BUDGET_JOURNAL=$((USABLE * PART_JOURNAL / 100))
BUDGET_DOORS=$((USABLE * PART_DOORS / 100))
BUDGET_MISSION=$((USABLE * PART_MISSION / 100))
BUDGET_POINTERS=$((USABLE * PART_POINTERS / 100))

truncate_bytes() {
  # $1 = contenu, $2 = budget en octets. Sous le budget : inchange. Au-dessus :
  # coupe a la derniere fin de ligne tenue par le budget, marqueur ajoute.
  local content="$1" budget="$2" size cut
  size="$(printf '%s' "$content" | wc -c)"
  if [ "$size" -le "$budget" ]; then
    printf '%s' "$content"
    return 0
  fi
  cut="$(printf '%s' "$content" | head -c "$budget")"
  case "$cut" in
    *$'\n'*) cut="${cut%$'\n'*}" ;;
  esac
  printf '%s\n[…] (section tronquée à %s octets)' "$cut" "$budget"
}

# --- 1. En-tete ---
GEN_TS="$(date +"%Y-%m-%dT%H:%M:%S%:z")"
LAST_JOURNAL_TS="aucune"
if [ -f "$JOURNAL" ]; then
  T="$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$JOURNAL" | tail -n 1 | awk '{print $1}')"
  [ -n "$T" ] && LAST_JOURNAL_TS="$T"
fi
HEADER_CONTENT="Généré : $GEN_TS
Dernière entrée journal : $LAST_JOURNAL_TS
Photo prise avant le commit de clôture (session-close §3) : tête et porcelain peuvent avoir un commit de retard, les refs Git font foi."

# --- 2. Etat des depots ---
repo_line() {
  local name="$1" root="$2" head_sha origin_sha counts ahead behind dirty
  head_sha="$(git -C "$root" rev-parse --short=8 HEAD 2>/dev/null || echo "????????")"
  origin_sha="$(git -C "$root" rev-parse --short=8 origin/main 2>/dev/null || echo "????????")"
  counts="$(git -C "$root" rev-list --left-right --count HEAD...origin/main 2>/dev/null || echo "? ?")"
  ahead="$(printf '%s' "$counts" | awk '{print $1}')"
  behind="$(printf '%s' "$counts" | awk '{print $2}')"
  dirty="$(git -C "$root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  printf '%s : HEAD %s · origin/main %s · ahead %s / behind %s · %s ligne(s) porcelain\n' \
    "$name" "$head_sha" "$origin_sha" "$ahead" "$behind" "$dirty"
}

PROJECT_GIT_ROOT="$(git -C "$PROJECT_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
REPOS_CONTENT="$(repo_line "$(basename "$VAULT_ROOT")" "$VAULT_ROOT")"
if [ -n "$PROJECT_GIT_ROOT" ]; then
  REPOS_CONTENT="$REPOS_CONTENT
$(repo_line "$(basename "$PROJECT_GIT_ROOT")" "$PROJECT_GIT_ROOT")"
else
  REPOS_CONTENT="$REPOS_CONTENT
$(basename "$PROJECT_ROOT") : non mesurable (pas un depot Git)"
fi

# --- 3. Dernieres lignes du journal (tail 3, 300 caracteres/ligne) ---
JOURNAL_CONTENT="Aucune entrée."
if [ -f "$JOURNAL" ]; then
  DATED="$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$JOURNAL" || true)"
  if [ -n "$DATED" ]; then
    JOURNAL_CONTENT="$(printf '%s\n' "$DATED" | tail -n 3 | while IFS= read -r line; do
      len="$(printf '%s' "$line" | wc -m | tr -d ' ')"
      if [ "$len" -gt 300 ]; then
        printf '%s[…]\n' "$(printf '%s' "$line" | cut -c1-300)"
      else
        printf '%s\n' "$line"
      fi
    done)"
  fi
fi

# --- 4. Portes ouvertes (identifiants seuls) -- meme grammaire de tags que
# build-state.sh (OUVERT:/OPEN:/CLOSE:, cle ^(open|frozen)-[a-z0-9-]+),
# sortie reduite a la cle. ---
DOORS_CONTENT="Aucune."
if [ -f "$JOURNAL" ]; then
  DATED="$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$JOURNAL" || true)"
  if [ -n "$DATED" ]; then
    DOOR_KEYS="$(printf '%s\n' "$DATED" | awk '
      {
        line = $0
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
            status[key] = "open"
          } else if (key in seen) {
            status[key] = "closed"
          }
        }
      }
      END {
        for (i = 1; i <= n; i++) {
          k = order[i]
          if (status[k] == "open") print k
        }
      }
    ')"
    if [ -n "$DOOR_KEYS" ]; then
      DOORS_CONTENT="$(printf '%s\n' "$DOOR_KEYS" | sed 's/^/- /')"
    fi
  fi
fi

# --- 5. Derniere Mission (numero + statut court) ---
# Mission 163 : la colonne Statut est trouvee par son EN-TETE, jamais par sa
# position. Le registre a six colonnes (ID, Objectif, Version active, Statut,
# Mission active, Prompt) la porte en 4e ; le registre a quatre colonnes de la
# DECISION-2026-09-05-124647 point 2 (ID, Statut, Date, Rapport) la porte en 2e.
# Lire par position afficherait un nom de rapport comme statut sur le nouveau
# format. Cette recherche fait fonctionner le digest sur les deux, donc aussi
# sur un projet dont le registre n'est pas encore converti.
MISSION_CONTENT="Aucune."
if [ -f "$MISSION_INDEX" ]; then
  LAST_ROW="$(grep -E '^\| `[0-9]+` \|' "$MISSION_INDEX" | tail -n 1 || true)"
  if [ -n "$LAST_ROW" ]; then
    NNN="$(printf '%s' "$LAST_ROW" | sed -E 's/^\| `([0-9]+)`.*/\1/')"
    HEADER_ROW="$(grep -E '^\| *ID *\|' "$MISSION_INDEX" | head -n 1 || true)"
    STATUS_COL="$(printf '%s' "$HEADER_ROW" | awk -F'|' '{for (i = 2; i <= NF; i++) { h = $i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", h); if (h == "Statut") { print i; exit } } }')"
    if [ -n "$STATUS_COL" ]; then
      STATUS_RAW="$(printf '%s' "$LAST_ROW" | awk -F'|' -v c="$STATUS_COL" '{print $c}' | sed -E 's/^[[:space:]]*`?//; s/`?[[:space:]]*$//')"
      STATUS_SHORT="${STATUS_RAW%% — *}"
      STATUS_SHORT="$(printf '%s' "$STATUS_SHORT" | cut -c1-80)"
      MISSION_CONTENT="Mission $NNN — $STATUS_SHORT"
    else
      MISSION_CONTENT="Mission $NNN — statut illisible (colonne Statut absente)"
    fi
  fi
fi

# --- 6. Pointeurs (noms de fichiers seuls) ---
last_file() {
  local dir="$1" prefix="$2" f
  [ -d "$dir" ] || return 0
  f="$(find "$dir" -maxdepth 1 -type f -name "${prefix}-[0-9][0-9][0-9][0-9]-*.md" 2>/dev/null | sort | tail -n 1)"
  [ -n "$f" ] && basename "$f"
}
LAST_HANDOFF="$(last_file "$HANDOFFS_DIR" "HANDOFF")"
[ -z "$LAST_HANDOFF" ] && LAST_HANDOFF="aucun"
LAST_REPORT="$(last_file "$REPORTS_DIR" "REPORT")"
[ -z "$LAST_REPORT" ] && LAST_REPORT="aucun"
POINTERS_CONTENT="Dernier handoff : $LAST_HANDOFF
Dernier rapport : $LAST_REPORT"

# --- Troncature par section ---
HEADER_TRUNC="$(truncate_bytes "$HEADER_CONTENT" "$BUDGET_HEADER")"
REPOS_TRUNC="$(truncate_bytes "$REPOS_CONTENT" "$BUDGET_REPOS")"
JOURNAL_TRUNC="$(truncate_bytes "$JOURNAL_CONTENT" "$BUDGET_JOURNAL")"
DOORS_TRUNC="$(truncate_bytes "$DOORS_CONTENT" "$BUDGET_DOORS")"
MISSION_TRUNC="$(truncate_bytes "$MISSION_CONTENT" "$BUDGET_MISSION")"
POINTERS_TRUNC="$(truncate_bytes "$POINTERS_CONTENT" "$BUDGET_POINTERS")"

# --- Ecriture fail-closed : fichier temporaire, mesure, puis move ---
GEN_REL="$(realpath --relative-to="$STATE_DIR" "$SCRIPT_DIR/build-digest.sh")"
REL_READING_LIST="$(realpath --relative-to="$STATE_DIR" "$READING_LIST" 2>/dev/null)"
# Repli sur le chemin absolu (jamais un nombre de "../" et un nom de dossier
# devines) si le calcul relatif echoue -- ticket 02, Mission 168.
[ -z "$REL_READING_LIST" ] && REL_READING_LIST="$READING_LIST"

TMP_FILE="$(mktemp "$STATE_DIR/.DIGEST.XXXXXX")"
trap 'rm -f "$TMP_FILE"' EXIT

{
  echo "---"
  echo "type: digest"
  echo "title: \"Digest d'ouverture — $(basename "$PROJECT_ROOT")\""
  echo "description: \"Lecture d'ouverture plafonnée, générée par $GEN_REL. Plafond fail-closed : $CAP_BYTES octets.\""
  echo "status: GENERATED"
  echo "generated_by: $GEN_REL"
  echo "---"
  echo ""
  echo "# DIGEST D'OUVERTURE — $(basename "$PROJECT_ROOT")"
  echo ""
  echo "> Généré automatiquement par \`$GEN_REL\`. Ne pas éditer à la main."
  echo ""
  echo "## En-tête"
  echo ""
  echo "$HEADER_TRUNC"
  echo ""
  echo "## État des dépôts"
  echo ""
  echo "$REPOS_TRUNC"
  echo ""
  echo "## Dernières lignes du journal"
  echo ""
  echo "$JOURNAL_TRUNC"
  echo ""
  echo "## Portes ouvertes"
  echo ""
  echo "$DOORS_TRUNC"
  echo ""
  echo "## Dernière Mission"
  echo ""
  echo "$MISSION_TRUNC"
  echo ""
  echo "## Pointeurs"
  echo ""
  echo "$POINTERS_TRUNC"
  echo ""
  echo "## Liens"
  echo ""
  echo "- \`prescribed by\` — [Liste de lecture d'ouverture de session, par rôle]($REL_READING_LIST)"
} > "$TMP_FILE"

SIZE="$(wc -c < "$TMP_FILE" | tr -d ' ')"

if [ "$SIZE" -gt "$CAP_BYTES" ]; then
  echo "REFUS build-digest.sh : digest généré à $SIZE octets, plafond $CAP_BYTES octets. DIGEST.md non écrit (fail-closed)." >&2
  exit 1
fi

mv "$TMP_FILE" "$DIGEST_FILE"
trap - EXIT
echo "OK build-digest.sh : $DIGEST_FILE écrit, $SIZE octets (plafond $CAP_BYTES)."
exit 0
