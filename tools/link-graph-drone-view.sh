#!/usr/bin/env bash
# Drone view of the written links (build history): deterministic measurement, zero model
# call, zero network. Reads this repository, and a second corpus if a sibling repository
# is declared (see below), walks the "## Liens" section of each
# .md file tracked by Git, builds the directed graph and renders four
# measurements plus two Mermaid views. Writes only to standard output:
# no persistent output file (build history, constraint).
#
# Complement (Session Executor, 2026-08-24): measurement 4 adds a
# breakdown of the supersession pairs by the creation date
# (created_at, front-matter) of the superseding document, boundary 2026-08-21
# (adoption of the link standard). Absent or unreadable dates are counted
# separately, never guessed nor replaced by the date in the file name.
#
# Correction (build history, 2026-08-24): the FM/SUP/LINK extraction pipeline
# (section 2 below) used a tab as field separator,
# read by `read` with IFS reduced to that same tab. But an IFS made
# only of space/tab/newline is treated by bash as
# « IFS whitespace »: consecutive tabs are merged into a
# single separator, whatever the content of IFS. An empty field (`status:`
# present without a value, or `type:` absent/empty) produces two consecutive
# tabs in the line printed by awk, which merge on reading
# and shift all following fields by one position. Fixed by replacing
# the internal separator with the control byte \001 (never IFS whitespace,
# never collapsed) — only in this internal EXTRACT/read pipeline;
# no output printed by the script uses this separator, the output
# format is unchanged. The workaround in measurement 4 (read_created_at, further
# down) stays as is: it did not depend on this pipeline and does not need
# to be removed to stay correct.
#
# usage: link-graph-drone-view.sh
#
# Sibling repository (build history; Mission 174 step 3, T21): no name or
# subfolder assumed by default any more. See tools/resolve-sibling-repo.sh --
# LINK_GRAPH_WORKSHOP_SUBDIR still overrides the sub-folder name inside a
# declared sibling (default "workshop-production", unchanged), but the
# sibling itself must be declared (SECOND_BRAIN_SIBLING_REPO or a
# workspace-root SIBLING-REPO.txt) or this tool analyzes the Vault corpus
# alone -- no search, no warning, no crash.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(cd "$VAULT_ROOT/.." && pwd)"
. "$SCRIPT_DIR/resolve-sibling-repo.sh"
. "$SCRIPT_DIR/relpath.sh"
. "$SCRIPT_DIR/kvmap.sh"
resolve_declared_sibling "$WORKSPACE_ROOT"
WORKSHOP_BUILD_ROOT="$SIBLING_ROOT"
WORKSHOP_SUBDIR="${LINK_GRAPH_WORKSHOP_SUBDIR:-workshop-production}"
WORKSHOP_ROOT="${WORKSHOP_BUILD_ROOT:+$WORKSHOP_BUILD_ROOT/$WORKSHOP_SUBDIR}"
STATE_FILE="${WORKSHOP_ROOT:+$WORKSHOP_ROOT/state/STATE.md}"

resolve_path() {
  # $1 = path, possibly relative and containing . or ..
  abs_path "$1"
}

# --- 1. Inventory: union of the two corpora, .md files tracked by Git ---
VAULT_FILES="$(cd "$VAULT_ROOT" && git ls-files '*.md' | while IFS= read -r f; do printf '%s/%s\n' "$VAULT_ROOT" "$f"; done)"
WORKSHOP_FILES=""
if [ -n "$WORKSHOP_BUILD_ROOT" ]; then
  WORKSHOP_FILES="$(cd "$WORKSHOP_BUILD_ROOT" && git ls-files -- "$WORKSHOP_SUBDIR/*.md" | while IFS= read -r f; do printf '%s/%s\n' "$WORKSHOP_BUILD_ROOT" "$f"; done)"
else
  echo "No sibling repository declared -- analyzing this repository's own corpus only." >&2
fi
ALL_FILES="$(printf '%s\n%s\n' "$VAULT_FILES" "$WORKSHOP_FILES")"
TOTAL_DOCS="$(printf '%s\n' "$ALL_FILES" | grep -c .)"

# --- 2. Extraction in a single awk pass: front-matter + Liens section ---
# File names passed through `xargs -0`: `xargs -d` is a GNU option that
# the Apple xargs refuses (Mission 181).
# Tagged output, one line per record, separator \001 (see the correction
# note Mission 043 above — never a tab, which merges on
# bash reading as soon as a field is empty):
#   FM<SOH>path<SOH>type<SOH>status<SOH>title
#   SUP<SOH>path<SOH>raw-target-basename
#   LINK<SOH>path<SOH>linktype<SOH>target-raw
EXTRACT="$(printf '%s\n' "$ALL_FILES" | grep . | tr '\n' '\0' | xargs -0 awk '
  FNR == 1 {
    infm = 0; insup = 0; inliens = 0
    ftype = ""; fstatus = ""; ftitle = ""
  }
  FNR == 1 && $0 == "---" { infm = 1; next }
  infm && $0 == "---" {
    infm = 0
    print "FM\001" FILENAME "\001" ftype "\001" fstatus "\001" ftitle
    next
  }
  infm && /^type:/ {
    v = $0; sub(/^type:[[:space:]]*/, "", v); gsub(/^"|"$/, "", v); ftype = v
  }
  infm && /^status:/ {
    v = $0; sub(/^status:[[:space:]]*/, "", v); gsub(/^"|"$/, "", v); fstatus = v
  }
  infm && /^title:/ {
    v = $0; sub(/^title:[[:space:]]*/, "", v); gsub(/^"|"$/, "", v); ftitle = v
  }
  infm && /^supersedes:/ {
    insup = 1
    line = $0
    sub(/^supersedes:[[:space:]]*/, "", line)
    if (line != "") {
      if (match(line, /[A-Za-z0-9._-]+\.md/)) {
        print "SUP\001" FILENAME "\001" substr(line, RSTART, RLENGTH)
      }
    }
    next
  }
  infm && insup {
    if ($0 ~ /^[[:space:]]+-/) {
      line = $0
      sub(/^[[:space:]]+-[[:space:]]*/, "", line)
      if (match(line, /[A-Za-z0-9._-]+\.md/)) {
        print "SUP\001" FILENAME "\001" substr(line, RSTART, RLENGTH)
      }
    } else {
      insup = 0
    }
  }
  !infm && /^## Liens[[:space:]]*$/ { inliens = 1; next }
  !infm && inliens && /^## / { inliens = 0 }
  # Two spellings coexist in the corpus (observation, not fixed by this
  # script): the current form of the standard "- `type` -- [texte](cible)"
  # and an earlier form "- type : [texte](cible)" without quotes or
  # em dash, used by documents written before the adoption of the
  # standard (RULES-2026-08-21-115658). Both are extracted as a
  # link declaration; the form used is reported separately.
  !infm && inliens && /^-[[:space:]]*/ && /\]\(/ {
    line = $0
    linktype = ""
    typeform = ""
    if (match(line, /`[^`]+`/)) {
      linktype = substr(line, RSTART + 1, RLENGTH - 2)
      typeform = "backtick"
    } else if (match(line, /^-[[:space:]]*[^:\[]+:[[:space:]]*\[/)) {
      t = substr(line, RSTART, RLENGTH)
      sub(/^-[[:space:]]*/, "", t)
      sub(/:[[:space:]]*\[$/, "", t)
      gsub(/[[:space:]]+$/, "", t)
      linktype = t
      typeform = "colon"
    }
    target = ""
    if (match(line, /\]\([^)]+\)/)) {
      target = substr(line, RSTART + 2, RLENGTH - 3)
    }
    if (target != "" && linktype != "") {
      print "LINK\001" FILENAME "\001" linktype "\001" target "\001" typeform
    }
  }
' 2>&1)"

# --- 3. Loading into bash memory ---
# Maps DOC_TYPE, DOC_STATUS, DOC_TITLE, INDEGREE, DIST, SEEN_PAIR,
# BASENAME_TO_PATH and ACTIVE_TOUCH carried by tools/kvmap.sh: `declare -A`
# does not exist in the bash 3.2 shipped by Apple (Mission 181).
declare -a EDGE_SRC EDGE_TYPE EDGE_TGT EDGE_RAW
declare -a SUP_SRC SUP_TGT_BASENAME
UNRESOLVED=0
TOTAL_LINKS=0
FORM_BACKTICK=0
FORM_COLON=0

while IFS=$'\001' read -r tag a b c d e; do
  case "$tag" in
    FM)
      kv_set DOC_TYPE "$a" "$b"
      kv_set DOC_STATUS "$a" "$c"
      kv_set DOC_TITLE "$a" "$d"
      ;;
    SUP)
      SUP_SRC+=("$a")
      SUP_TGT_BASENAME+=("$b")
      ;;
    LINK)
      linktype="$b"
      raw="$c"
      typeform="$d"
      case "$raw" in
        *.md) : ;;
        *) continue ;;
      esac
      if [ "$typeform" = "colon" ]; then
        FORM_COLON=$((FORM_COLON + 1))
      else
        FORM_BACKTICK=$((FORM_BACKTICK + 1))
      fi
      dir="$(dirname "$a")"
      resolved="$(resolve_path "$dir/$raw")"
      TOTAL_LINKS=$((TOTAL_LINKS + 1))
      if [ -z "$resolved" ] || [ ! -f "$resolved" ]; then
        UNRESOLVED=$((UNRESOLVED + 1))
        EDGE_SRC+=("$a"); EDGE_TYPE+=("$linktype"); EDGE_TGT+=(""); EDGE_RAW+=("$raw")
      else
        EDGE_SRC+=("$a"); EDGE_TYPE+=("$linktype"); EDGE_TGT+=("$resolved"); EDGE_RAW+=("$raw")
        kv_get INDEGREE "$resolved"
        kv_set INDEGREE "$resolved" $(( ${KV_VALUE:-0} + 1 ))
      fi
      ;;
  esac
done <<EXTRACT_EOF
$EXTRACT
EXTRACT_EOF

# Rate of unresolved links: stop condition Mission 042.
if [ "$TOTAL_LINKS" -gt 0 ]; then
  UNRESOLVED_PCT=$(( UNRESOLVED * 1000 / TOTAL_LINKS ))
else
  UNRESOLVED_PCT=0
fi

echo "=== CONTROLE PREALABLE ==="
echo "documents totaux (union des deux corpus) : $TOTAL_DOCS"
echo "liens declares dans une section ## Liens : $TOTAL_LINKS"
echo "  dont forme actuelle du standard (\`type\` -- [texte](cible)) : $FORM_BACKTICK"
echo "  dont forme anterieure (type : [texte](cible), sans guillemets)  : $FORM_COLON"
echo "liens non resolus (cible introuvable)    : $UNRESOLVED"
printf 'taux de liens non resolus                : %d.%01d%%\n' $((UNRESOLVED_PCT / 10)) $((UNRESOLVED_PCT % 10))
if [ "$UNRESOLVED_PCT" -gt 100 ]; then
  echo "ARRET : plus d'un lien sur dix est non resolu (condition d'arret, build history). Aucune mesure rendue." >&2
  exit 1
fi
if [ "$UNRESOLVED" -gt 0 ]; then
  echo "--- liens non resolus (source -> cible brute) ---"
  for i in "${!EDGE_SRC[@]}"; do
    [ -z "${EDGE_TGT[$i]}" ] || continue
    printf '%s\t%s\n' "${EDGE_SRC[$i]}" "${EDGE_RAW[$i]}"
  done
fi
echo ""

# --- Measurement 1: core, top 15 by incoming links ---
echo "=== MESURE 1 — NOYAU (top 15 par liens entrants) ==="
kv_keys INDEGREE
for p in ${KV_KEYS[@]+"${KV_KEYS[@]}"}; do
  [ -z "$p" ] && continue
  kv_get INDEGREE "$p"; deg="$KV_VALUE"
  kv_get DOC_TYPE "$p"; typ="${KV_VALUE:-(inconnu)}"
  printf '%d\t%s\t%s\n' "$deg" "$p" "$typ"
done | sort -t$'\t' -k1,1nr | head -15 | nl -ba -w2 -s'. '
echo ""

# --- Measurement 2: orphans (no incoming link) ---
echo "=== MESURE 2 — ORPHELINS ==="
ORPHAN_TOTAL=0
ORPHAN_ACTIVE=0
ORPHAN_ACTIVE_LIST=""
ORPHAN_OTHER_LIST=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if ! kv_get INDEGREE "$p" || [ -z "$KV_VALUE" ]; then
    ORPHAN_TOTAL=$((ORPHAN_TOTAL + 1))
    kv_get DOC_STATUS "$p"; st="$KV_VALUE"
    st_lc="$(printf '%s' "$st" | tr '[:upper:]' '[:lower:]')"
    if [ "$st_lc" = "active" ]; then
      ORPHAN_ACTIVE=$((ORPHAN_ACTIVE + 1))
      ORPHAN_ACTIVE_LIST="$ORPHAN_ACTIVE_LIST$p\t$st\n"
    else
      ORPHAN_OTHER_LIST="$ORPHAN_OTHER_LIST$p\t$st\n"
    fi
  fi
done <<DOCS_EOF
$ALL_FILES
DOCS_EOF
echo "orphelins totaux : $ORPHAN_TOTAL"
echo "orphelins actifs (status: active, casse indifferente) : $ORPHAN_ACTIVE"
echo "--- orphelins actifs ---"
printf '%b' "$ORPHAN_ACTIVE_LIST" | grep . | sort
echo "--- orphelins non actifs (autre statut ou aucun) ---"
printf '%b' "$ORPHAN_OTHER_LIST" | grep . | sort
echo ""

# --- Measurement 3: reach, directed BFS from STATE.md ---
echo "=== MESURE 3 — PORTEE depuis ${STATE_FILE:-<aucun depot voisin declare>} ==="
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
  kv_set DIST "$STATE_FILE" 0
  FRONTIER="$STATE_FILE"
  D=0
  while [ -n "$FRONTIER" ]; do
    D=$((D + 1))
    NEXT=""
    while IFS= read -r node; do
      [ -z "$node" ] && continue
      for i in "${!EDGE_SRC[@]}"; do
        if [ "${EDGE_SRC[$i]}" = "$node" ] && [ -n "${EDGE_TGT[$i]}" ]; then
          tgt="${EDGE_TGT[$i]}"
          if ! kv_has DIST "$tgt"; then
            kv_set DIST "$tgt" "$D"
            NEXT="$NEXT$tgt"$'\n'
          fi
        fi
      done
    done <<FRONTIER_EOF
$FRONTIER
FRONTIER_EOF
    FRONTIER="$(printf '%s' "$NEXT" | sort -u | grep .)"
  done
else
  echo "ANOMALY : fiche d'etat introuvable a ${STATE_FILE:-<aucun depot voisin declare>}" >&2
fi

for k in 1 2 3; do
  cnt=0
  kv_keys DIST
  for p in ${KV_KEYS[@]+"${KV_KEYS[@]}"}; do
    kv_get DIST "$p"
    [ "$KV_VALUE" = "$k" ] && cnt=$((cnt + 1))
  done
  echo "documents a $k saut(s) : $cnt"
done

echo "--- documents hors de portee (aucune distance depuis la fiche d'etat) ---"
UNREACHABLE_TOTAL=0
UNREACHABLE_ACTIVE=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if ! kv_has DIST "$p"; then
    UNREACHABLE_TOTAL=$((UNREACHABLE_TOTAL + 1))
    kv_get DOC_STATUS "$p"; st="$KV_VALUE"
    st_lc="$(printf '%s' "$st" | tr '[:upper:]' '[:lower:]')"
    mark=""
    if [ "$st_lc" = "active" ]; then
      UNREACHABLE_ACTIVE=$((UNREACHABLE_ACTIVE + 1))
      mark=" [ACTIF]"
    fi
    printf '%s\t%s%s\n' "$p" "$st" "$mark"
  fi
done <<DOCS_EOF2
$ALL_FILES
DOCS_EOF2
echo "total hors de portee : $UNREACHABLE_TOTAL (dont actifs : $UNREACHABLE_ACTIVE)"
echo ""

# --- Measurement 4: reciprocity of the supersession relations ---
echo "=== MESURE 4 — RECIPROCITE DES REMPLACEMENTS ==="
INCOMPLETE=0
CHECKED=0

# Breakdown by creation date of the superseding document (complement Session Executor,
# 2026-08-24): 2026-08-21 is the adoption date of the link standard
# (RULES-2026-08-21-115658). A superseding document created on that day or after is
# deemed to know the standard; before, it is earlier stock. Only the
# `created_at` date of the front-matter is read; no date is guessed and the
# file name is never substituted for an absent or unreadable date.
# Direct and independent reading of the file (no going through the shared
# tab-based EXTRACT/read pipeline above): that pipeline collapses the
# consecutive tabs of an empty field (`status:` absent), which shifts
# the following columns — observation made while writing this complement,
# not fixed in the existing pipeline (outside the perimeter), worked around here so
# that this measurement alone stays reliable.
DATE_BOUNDARY="2026-08-21"
DATE_BEFORE=0
DATE_ONAFTER=0
DATE_ONAFTER_OK=0
DATE_UNKNOWN=0
DATE_UNKNOWN_LIST=""

read_created_at() {
  # $1 = absolute path of a .md document; prints the raw value of
  # created_at read in its header, or nothing if absent/unreadable.
  awk '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---" { exit }
    infm && /^created_at:/ {
      v = $0
      sub(/^created_at:[[:space:]]*/, "", v)
      gsub(/^"|"$/, "", v)
      print v
      exit
    }
  ' "$1" 2>/dev/null
}

check_pair() {
  # $1 = source (superseding), $2 = target (superseded)
  local src="$1" tgt="$2" key
  key="$src|$tgt"
  kv_has SEEN_PAIR "$key" && return
  kv_set SEEN_PAIR "$key" 1
  CHECKED=$((CHECKED + 1))
  local found=0
  for i in "${!EDGE_SRC[@]}"; do
    if [ "${EDGE_SRC[$i]}" = "$tgt" ] && [ "${EDGE_TGT[$i]}" = "$src" ] && [ "${EDGE_TYPE[$i]}" = "superseded by" ]; then
      found=1
      break
    fi
  done
  if [ "$found" -eq 0 ]; then
    INCOMPLETE=$((INCOMPLETE + 1))
    echo "INCOMPLET : $src (remplace) -> $tgt (remplace) : ligne \`superseded by\` manquante dans $tgt"
  fi
  local st
  kv_get DOC_STATUS "$tgt"; st="$KV_VALUE"
  local st_lc
  st_lc="$(printf '%s' "$st" | tr '[:upper:]' '[:lower:]')"
  if [ "$st_lc" = "active" ]; then
    echo "ANOMALY : cible de remplacement $tgt porte status: $st (actif) alors qu'elle est remplacee par $src"
  fi

  local craw
  craw="$(read_created_at "$src")"
  local cdate=""
  if [[ "$craw" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    cdate="${BASH_REMATCH[1]}"
  fi
  if [ -z "$cdate" ]; then
    DATE_UNKNOWN=$((DATE_UNKNOWN + 1))
    DATE_UNKNOWN_LIST="$DATE_UNKNOWN_LIST$src\t${craw:-(absente)}\n"
  elif [[ "$cdate" < "$DATE_BOUNDARY" ]]; then
    DATE_BEFORE=$((DATE_BEFORE + 1))
  else
    DATE_ONAFTER=$((DATE_ONAFTER + 1))
    [ "$found" -eq 1 ] && DATE_ONAFTER_OK=$((DATE_ONAFTER_OK + 1))
  fi
}

# (a) via front-matter supersedes: basename -> look up the absolute path in the corpus
while IFS= read -r p; do
  [ -z "$p" ] && continue
  kv_set BASENAME_TO_PATH "$(basename "$p")" "$p"
done <<DOCS_EOF3
$ALL_FILES
DOCS_EOF3

for i in "${!SUP_SRC[@]}"; do
  src="${SUP_SRC[$i]}"
  tgt_bn="${SUP_TGT_BASENAME[$i]}"
  kv_get BASENAME_TO_PATH "$tgt_bn"; tgt="$KV_VALUE"
  if [ -z "$tgt" ]; then
    echo "ANOMALY : supersedes de $src pointe vers $tgt_bn, introuvable dans le corpus"
    continue
  fi
  check_pair "$src" "$tgt"
done

# (b) via Liens section, type "supersedes" (Mission 054: English vocabulary
# only since the cutover, step 6)
for i in "${!EDGE_SRC[@]}"; do
  if [ "${EDGE_TYPE[$i]}" = "supersedes" ] && [ -n "${EDGE_TGT[$i]}" ]; then
    check_pair "${EDGE_SRC[$i]}" "${EDGE_TGT[$i]}"
  fi
done

echo "couples de remplacement verifies : $CHECKED"
echo "couples incomplets (lien inverse manquant) : $INCOMPLETE"
echo ""
echo "--- ventilation par date de creation du remplacant (frontiere $DATE_BOUNDARY, adoption du standard de liens) ---"
echo "couples dont le remplacant est cree avant le $DATE_BOUNDARY : $DATE_BEFORE"
echo "couples dont le remplacant est cree le $DATE_BOUNDARY ou apres : $DATE_ONAFTER"
echo "  dont conformes (lien retour \`remplacé par\` present dans la cible) : $DATE_ONAFTER_OK"
echo "couples dont la date de creation du remplacant est absente ou illisible (non devinee, nom de fichier non substitue) : $DATE_UNKNOWN"
if [ "$DATE_UNKNOWN" -gt 0 ]; then
  echo "--- couples a date de creation illisible ou absente (remplacant -> valeur brute created_at lue) ---"
  printf '%b' "$DATE_UNKNOWN_LIST" | grep .
fi
echo ""

# --- 4. Mermaid graph ---
node_id() {
  printf '%s' "$1" | sed -E 's#.*/([^/]+)\.md$#\1#; s/[^A-Za-z0-9_]/_/g'
}
node_label() {
  # No truncation by bytes: titles contain multi-byte
  # characters (arrows, typographic quotes) and `cut -c`/`awk
  # substr` cut here by byte despite the C.UTF-8 locale, producing
  # mojibake. We keep the whole title rather than risk an invalid
  # cut.
  local t
  kv_get DOC_TITLE "$1"; t="$KV_VALUE"
  [ -z "$t" ] && t="$(basename "$1" .md)"
  # Apostrophe written as is: `\x27` in a replacement is a
  # GNU sed extension, which the Apple sed copies as « x27 » (Mission 181).
  printf '%s' "$t" | sed "s/\"/'/g"
}

echo "=== VUE MERMAID — COMPLETE ==="
echo '```mermaid'
echo "flowchart LR"
for i in "${!EDGE_SRC[@]}"; do
  [ -z "${EDGE_TGT[$i]}" ] && continue
  s="$(node_id "${EDGE_SRC[$i]}")"
  t="$(node_id "${EDGE_TGT[$i]}")"
  printf '  %s["%s"] -->|%s| %s["%s"]\n' "$s" "$(node_label "${EDGE_SRC[$i]}")" "${EDGE_TYPE[$i]}" "$t" "$(node_label "${EDGE_TGT[$i]}")"
done | sort -u
echo '```'
echo ""

echo "=== VUE MERMAID — DOCUMENTS ACTIFS + PREMIER CERCLE ==="
kv_keys DOC_STATUS
for p in ${KV_KEYS[@]+"${KV_KEYS[@]}"}; do
  kv_get DOC_STATUS "$p"
  st_lc="$(printf '%s' "$KV_VALUE" | tr '[:upper:]' '[:lower:]')"
  [ "$st_lc" = "active" ] && kv_set ACTIVE_TOUCH "$p" 1
done
echo '```mermaid'
echo "flowchart LR"
for i in "${!EDGE_SRC[@]}"; do
  [ -z "${EDGE_TGT[$i]}" ] && continue
  s="${EDGE_SRC[$i]}"
  t="${EDGE_TGT[$i]}"
  if kv_has ACTIVE_TOUCH "$s" || kv_has ACTIVE_TOUCH "$t"; then
    sid="$(node_id "$s")"
    tid="$(node_id "$t")"
    printf '  %s["%s"] -->|%s| %s["%s"]\n' "$sid" "$(node_label "$s")" "${EDGE_TYPE[$i]}" "$tid" "$(node_label "$t")"
  fi
done | sort -u
echo '```'
