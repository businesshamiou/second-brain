#!/usr/bin/env bash
# Vue drone des liens ecrits (Mission 042) : mesure deterministe, zero appel
# modele, zero reseau. Lit les deux corpus (vault entier, workshop-build/
# workshop-production), parcourt la section "## Liens" de chaque fichier .md
# suivi par Git, construit le graphe oriente et rend quatre mesures plus
# deux vues Mermaid. Ecrit uniquement sur la sortie standard : aucun fichier
# de sortie persistant (Mission 042, contrainte).
#
# Complement (Session Executor, 2026-08-24) : la mesure 4 ajoute une
# ventilation des couples de remplacement selon la date de creation
# (created_at, front-matter) du document remplacant, frontiere 2026-08-21
# (adoption du standard de liens). Dates absentes ou illisibles comptees a
# part, jamais devinees ni substituees par la date du nom de fichier.
#
# Correction (Mission 043, 2026-08-24) : le pipeline d'extraction FM/SUP/LINK
# (section 2 ci-dessous) utilisait une tabulation comme separateur de champ,
# lue par `read` avec IFS reduit a cette meme tabulation. Or IFS compose
# uniquement d'espace/tabulation/saut de ligne est traite par bash comme de
# l'« IFS whitespace » : les tabulations consecutives sont fusionnees en un
# seul separateur, quel que soit le contenu d'IFS. Un champ vide (`status:`
# present sans valeur, ou `type:` absent/vide) produit deux tabulations
# consecutives dans la ligne imprimee par awk, qui se fusionnent a la lecture
# et decalent tous les champs suivants d'une position. Corrige en remplacant
# le separateur interne par l'octet de controle \001 (jamais IFS whitespace,
# jamais collabore) — uniquement dans ce pipeline interne EXTRACT/read ;
# aucune sortie imprimee par le script n'utilise ce separateur, le format de
# sortie est inchange. Le contournement de la mesure 4 (read_created_at, plus
# bas) reste tel quel : il ne dependait pas de ce pipeline et n'a pas besoin
# d'etre retire pour rester correct.
#
# usage: link-graph-drone-view.sh
#
# Depot frere parametrable (Mission 069, douteux 5) : LINK_GRAPH_WORKSHOP_BUILD_ROOT
# et LINK_GRAPH_WORKSHOP_ROOT en variables d'environnement surchargent le
# nom/emplacement en dur ; non definies, le script recalcule exactement la
# meme valeur qu'avant (defaut inchange, "../workshop-build" puis
# "workshop-production" en sous-dossier).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSHOP_BUILD_ROOT="${LINK_GRAPH_WORKSHOP_BUILD_ROOT:-}"
if [ -z "$WORKSHOP_BUILD_ROOT" ]; then
  WORKSHOP_BUILD_ROOT="$(cd "$VAULT_ROOT/../workshop-build" && pwd)"
fi
WORKSHOP_ROOT="${LINK_GRAPH_WORKSHOP_ROOT:-$WORKSHOP_BUILD_ROOT/workshop-production}"
WORKSHOP_SUBDIR="$(realpath --relative-to="$WORKSHOP_BUILD_ROOT" "$WORKSHOP_ROOT" 2>/dev/null)"
[ -z "$WORKSHOP_SUBDIR" ] && WORKSHOP_SUBDIR="workshop-production"
STATE_FILE="$WORKSHOP_ROOT/state/STATE.md"

resolve_path() {
  # $1 = chemin, potentiellement relatif et contenant . ou ..
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$1" 2>/dev/null
  else
    D="$(cd "$(dirname "$1")" 2>/dev/null && pwd)"
    [ -n "$D" ] && printf '%s/%s\n' "$D" "$(basename "$1")"
  fi
}

# --- 1. Inventaire : union des deux corpus, fichiers .md suivis par Git ---
VAULT_FILES="$(cd "$VAULT_ROOT" && git ls-files '*.md' | while IFS= read -r f; do printf '%s/%s\n' "$VAULT_ROOT" "$f"; done)"
WORKSHOP_FILES="$(cd "$WORKSHOP_BUILD_ROOT" && git ls-files -- "$WORKSHOP_SUBDIR/*.md" | while IFS= read -r f; do printf '%s/%s\n' "$WORKSHOP_BUILD_ROOT" "$f"; done)"
ALL_FILES="$(printf '%s\n%s\n' "$VAULT_FILES" "$WORKSHOP_FILES")"
TOTAL_DOCS="$(printf '%s\n' "$ALL_FILES" | grep -c .)"

# --- 2. Extraction en un seul passage awk : front-matter + section Liens ---
# Sortie taggee, une ligne par enregistrement, separateur \001 (voir note de
# correction Mission 043 ci-dessus — jamais une tabulation, qui se fusionne a
# la lecture bash des qu'un champ est vide) :
#   FM<SOH>path<SOH>type<SOH>status<SOH>title
#   SUP<SOH>path<SOH>raw-basename-cible
#   LINK<SOH>path<SOH>linktype<SOH>target-raw
EXTRACT="$(printf '%s\n' "$ALL_FILES" | grep . | xargs -d '\n' awk '
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
  # Deux graphies coexistent dans le corpus (constat, non corrige par ce
  # script) : la forme actuelle du standard "- `type` -- [texte](cible)"
  # et une forme anterieure "- type : [texte](cible)" sans guillemets ni
  # tiret cadratin, utilisee par des documents ecrits avant adoption du
  # standard (RULES-2026-08-21-115658). Les deux sont extraites comme
  # declaration de lien ; la forme employee est reportee separement.
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

# --- 3. Chargement en memoire bash ---
declare -A DOC_TYPE DOC_STATUS DOC_TITLE
declare -A INDEGREE
declare -a EDGE_SRC EDGE_TYPE EDGE_TGT EDGE_RAW
declare -a SUP_SRC SUP_TGT_BASENAME
UNRESOLVED=0
TOTAL_LINKS=0
FORM_BACKTICK=0
FORM_COLON=0

while IFS=$'\001' read -r tag a b c d e; do
  case "$tag" in
    FM)
      DOC_TYPE["$a"]="$b"
      DOC_STATUS["$a"]="$c"
      DOC_TITLE["$a"]="$d"
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
        INDEGREE["$resolved"]=$(( ${INDEGREE["$resolved"]:-0} + 1 ))
      fi
      ;;
  esac
done <<EXTRACT_EOF
$EXTRACT
EXTRACT_EOF

# Taux de liens non resolus : condition d'arret Mission 042.
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
  echo "ARRET : plus d'un lien sur dix est non resolu (condition d'arret Mission 042). Aucune mesure rendue." >&2
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

# --- Mesure 1 : noyau, top 15 par liens entrants ---
echo "=== MESURE 1 — NOYAU (top 15 par liens entrants) ==="
printf '%s\n' "${!INDEGREE[@]}" | while IFS= read -r p; do
  [ -z "$p" ] && continue
  printf '%d\t%s\t%s\n' "${INDEGREE[$p]}" "$p" "${DOC_TYPE[$p]:-(inconnu)}"
done | sort -t$'\t' -k1,1nr | head -15 | nl -ba -w2 -s'. '
echo ""

# --- Mesure 2 : orphelins (aucun lien entrant) ---
echo "=== MESURE 2 — ORPHELINS ==="
ORPHAN_TOTAL=0
ORPHAN_ACTIVE=0
ORPHAN_ACTIVE_LIST=""
ORPHAN_OTHER_LIST=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if [ -z "${INDEGREE[$p]:-}" ]; then
    ORPHAN_TOTAL=$((ORPHAN_TOTAL + 1))
    st="${DOC_STATUS[$p]:-}"
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

# --- Mesure 3 : portee, BFS oriente depuis STATE.md ---
echo "=== MESURE 3 — PORTEE depuis $STATE_FILE ==="
declare -A DIST
if [ -f "$STATE_FILE" ]; then
  DIST["$STATE_FILE"]=0
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
          if [ -z "${DIST[$tgt]+x}" ]; then
            DIST["$tgt"]=$D
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
  echo "ANOMALY : fiche d'etat introuvable a $STATE_FILE" >&2
fi

for k in 1 2 3; do
  cnt=0
  for p in "${!DIST[@]}"; do
    [ "${DIST[$p]}" = "$k" ] && cnt=$((cnt + 1))
  done
  echo "documents a $k saut(s) : $cnt"
done

echo "--- documents hors de portee (aucune distance depuis la fiche d'etat) ---"
UNREACHABLE_TOTAL=0
UNREACHABLE_ACTIVE=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if [ -z "${DIST[$p]+x}" ]; then
    UNREACHABLE_TOTAL=$((UNREACHABLE_TOTAL + 1))
    st="${DOC_STATUS[$p]:-}"
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

# --- Mesure 4 : reciprocite des relations de remplacement ---
echo "=== MESURE 4 — RECIPROCITE DES REMPLACEMENTS ==="
declare -A SEEN_PAIR
INCOMPLETE=0
CHECKED=0

# Ventilation par date de creation du remplacant (complement Session Executor,
# 2026-08-24) : le 2026-08-21 est la date d'adoption du standard de liens
# (RULES-2026-08-21-115658). Un remplacant cree ce jour-la ou apres est
# repute connaitre le standard ; avant, c'est du stock anterieur. Seule la
# date `created_at` du front-matter est lue ; aucune date n'est devinee et le
# nom de fichier n'est jamais substitue a une date absente ou illisible.
# Lecture directe et independante du fichier (pas de passage par le pipeline
# EXTRACT/read a tabulations partage plus haut) : ce pipeline colle les
# tabulations consecutives d'un champ vide (`status:` absent), ce qui decale
# les colonnes suivantes — constat fait en cours d'ecriture de ce complement,
# non corrige dans le pipeline existant (hors perimetre), contourne ici pour
# que cette mesure seule reste fiable.
DATE_BOUNDARY="2026-08-21"
DATE_BEFORE=0
DATE_ONAFTER=0
DATE_ONAFTER_OK=0
DATE_UNKNOWN=0
DATE_UNKNOWN_LIST=""

read_created_at() {
  # $1 = chemin absolu d'un document .md ; imprime la valeur brute de
  # created_at lue dans son en-tete, ou rien si absente/illisible.
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
  # $1 = source (remplacant), $2 = cible (remplace)
  local src="$1" tgt="$2" key
  key="$src|$tgt"
  [ -n "${SEEN_PAIR[$key]:-}" ] && return
  SEEN_PAIR["$key"]=1
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
  local st="${DOC_STATUS[$tgt]:-}"
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

# (a) via front-matter supersedes : basename -> chercher le chemin absolu dans le corpus
declare -A BASENAME_TO_PATH
while IFS= read -r p; do
  [ -z "$p" ] && continue
  BASENAME_TO_PATH["$(basename "$p")"]="$p"
done <<DOCS_EOF3
$ALL_FILES
DOCS_EOF3

for i in "${!SUP_SRC[@]}"; do
  src="${SUP_SRC[$i]}"
  tgt_bn="${SUP_TGT_BASENAME[$i]}"
  tgt="${BASENAME_TO_PATH[$tgt_bn]:-}"
  if [ -z "$tgt" ]; then
    echo "ANOMALY : supersedes de $src pointe vers $tgt_bn, introuvable dans le corpus"
    continue
  fi
  check_pair "$src" "$tgt"
done

# (b) via section Liens, type "supersedes" (Mission 054 : vocabulaire anglais
# seul depuis la bascule etape 6)
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

# --- 4. Graphe Mermaid ---
node_id() {
  printf '%s' "$1" | sed -E 's#.*/([^/]+)\.md$#\1#; s/[^A-Za-z0-9_]/_/g'
}
node_label() {
  # Pas de troncature par octets : les titres contiennent des caracteres
  # multi-octets (fleches, guillemets typographiques) et `cut -c`/`awk
  # substr` coupent ici par octet malgre la locale C.UTF-8, produisant du
  # mojibake. On garde le titre entier plutot que de risquer une coupure
  # invalide.
  local t="${DOC_TITLE[$1]:-}"
  [ -z "$t" ] && t="$(basename "$1" .md)"
  printf '%s' "$t" | sed 's/"/\x27/g'
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
declare -A ACTIVE_TOUCH
for p in "${!DOC_STATUS[@]}"; do
  st_lc="$(printf '%s' "${DOC_STATUS[$p]}" | tr '[:upper:]' '[:lower:]')"
  [ "$st_lc" = "active" ] && ACTIVE_TOUCH["$p"]=1
done
echo '```mermaid'
echo "flowchart LR"
for i in "${!EDGE_SRC[@]}"; do
  [ -z "${EDGE_TGT[$i]}" ] && continue
  s="${EDGE_SRC[$i]}"
  t="${EDGE_TGT[$i]}"
  if [ -n "${ACTIVE_TOUCH[$s]:-}" ] || [ -n "${ACTIVE_TOUCH[$t]:-}" ]; then
    sid="$(node_id "$s")"
    tid="$(node_id "$t")"
    printf '  %s["%s"] -->|%s| %s["%s"]\n' "$sid" "$(node_label "$s")" "${EDGE_TYPE[$i]}" "$tid" "$(node_label "$t")"
  fi
done | sort -u
echo '```'
