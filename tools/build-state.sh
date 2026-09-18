#!/usr/bin/env bash
# Regenerates <projet>/state/STATE.md from the journal, the Git state and the
# file listing. Generated sheet: never edit it by hand.
#
# Tag convention recognised in journal lines (text after the timestamp):
#   ETAT:<text>     -> current state (last occurrence kept)
#   PROCHAIN:<text> -> next action (last occurrence kept)
#   REPRISE:<text>  -> resume note; must be the last line of the journal
# Since Mission 038, dual recognition: STATE:/NEXT:/RESUME: (English) in addition to the French tags above.
#
# Doors (since Mission 051): one-door-one-line-one-key.
#   OUVERT:<key> -- <text>   -> opens/reopens a door (French, historical only)
#   OPEN:<key> -- <text>     -> opens/reopens a door (English, new writes)
#   CLOSE:<key> -- <reference> -> closes a door; no French equivalent, single closing tag
#   <key> ~ ^(open|frozen)-[a-z0-9-]+ ; separator " -- " mandatory between the key and the text.
#   Displayed state = for each key, its last occurrence in the journal (order of appending, the journal
#   being append-only and so chronological): if it is an OUVERT:/OPEN:, the door is shown with its text;
#   if it is a later CLOSE: of the same key, the door is removed. A later reopening makes it
#   reappear.
#   OUVERT:/OPEN: lines without a conforming key = legacy (earlier than the baseline arbitrated on 2026-08-25,
#   see DECISION-2026-08-25-110935): excluded from the list of doors, counted in a single line.
# A line with no recognised tag feeds none of the sections above.
#
# usage: build-state.sh <chemin-projet>

set -u

PROJECT="${1:-}"
if [ -z "$PROJECT" ]; then
  echo "usage: build-state.sh <chemin-projet>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/relpath.sh"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$PROJECT" && pwd)"
STATE_DIR="$PROJECT_ROOT/state"
JOURNAL="$STATE_DIR/journal.md"
STATE_FILE="$STATE_DIR/STATE.md"
CONTRACT_TEMPLATE="$VAULT_ROOT/templates/pilot-contract-template.md"
STANDARD_RULE="$VAULT_ROOT/rules/RULES-2026-08-26-142800-project-structure-standard.md"
REL_STANDARD="$(rel_path "$STATE_DIR" "$STANDARD_RULE" 2>/dev/null)"
[ -z "$REL_STANDARD" ] && REL_STANDARD="$STANDARD_RULE"

# --- 0. Pilot contract, copied from the template, never written here ---
# Arbitrated cap: exactly seven lines (Mission 029). Explicit failure,
# sheet not written, if the template departs from this cap.
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

# --- 0bis. Session references (fixed catalogue, since Mission 053) ---
# Relative paths computed from $STATE_DIR (never hard-coded): the
# sheet is a catalogue of pointers, no normative content is copied.
session_ref_line() {
  local target="$1" desc="$2" rel
  rel="$(rel_path "$STATE_DIR" "$target" 2>/dev/null)"
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

# --- 1. Reading the journal tags ---
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

    # Keyed doors: processed in the journal's order of appending (append-only, so
    # chronological) -- the last occurrence per key (OUVERT:/OPEN: or
    # CLOSE:) determines the net state. Output: lines "D<TAB>text" for the
    # displayed doors, one line "L<TAB>n" for the legacy count.
    DOORS_RAW="$(printf '%s\n' "$DATED" | awk '
      {
        line = $0
        # The tag must immediately follow the timestamp (first field): an
        # occurrence of "OPEN:"/"OUVERT:" in prose elsewhere on the line (e.g.
        # a STATE: line that documents the convention) must not be
        # taken for a door.
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

# --- 2. Catalogue of recent documents (mtime desc, limit 15) ---
# `ls -t` rather than `find -printf '%T@ %p'`: `-printf` is a GNU
# extension missing from BSD find (macOS), where the list came out empty silently --
# the sheet lost its « Documents recents » section there without saying so
# (Mission 180). `ls -t` sorts by modification date on both sides.
RECENTS="$(find "$PROJECT_ROOT" -type f -name '*.md' -exec ls -t {} + 2>/dev/null | head -n 15)"

DOC_LIST=""
if [ -n "$RECENTS" ]; then
  while IFS= read -r F; do
    [ -z "$F" ] && continue
    REL="$(rel_path "$PROJECT_ROOT" "$F")"
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

# --- 3. Repository state ---
VAULT_STATUS="$(git -C "$VAULT_ROOT" status -sb 2>/dev/null || echo "non mesurable")"
PROJECT_GIT_ROOT="$(git -C "$PROJECT_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$PROJECT_GIT_ROOT" ]; then
  PROJECT_STATUS="$(git -C "$PROJECT_GIT_ROOT" status -sb 2>/dev/null)"
else
  PROJECT_STATUS="non mesurable (pas un depot Git)"
fi

# --- 4. Write ---
GEN_REL="$(rel_path "$STATE_DIR" "$SCRIPT_DIR/build-state.sh")"
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
  echo "- \`prescribed by\` — [Standard de structure de projet]($REL_STANDARD) (hors Vault)"
} > "$STATE_FILE"
