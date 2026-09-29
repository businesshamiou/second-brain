#!/usr/bin/env bash
# Mission 240: the starting interview -- the Owner profile (« ## Profil de
# départ » of USER.md, sb profile) and the project profile (« ## Profil du
# projet » of README.md, the three optional fields of the initiation order and
# --ask). Decision 2026-09-27-213059.
#
# Oracle, on a throwaway workspace built from the working tree:
#   (A) sb profile: shows ABSENT, missing=5; --order writes the section with
#       its five fields and its date, adds lines only (every line of USER.md
#       kept, byte for byte), moves the order to _archive/orders/; a second,
#       partial order changes only the fields it gives, the section stays
#       single; the byte-order mark and CRLF line ends survive; then PRESENT
#       missing=0. Refusals, each with USER.md unchanged and the order where it
#       was: no dated authorization; no profile field; the distributed
#       skeleton (status: template); an archive already holding the name.
#   (B) the order's three fields: create --order carries them into README.md
#       and the state sheet; `-` and placeholders write nothing; create --ask
#       asks them after Git (Enter leaves one empty); sb new --ask the same;
#       adopt of a folder with its own README adds the one section and keeps
#       every line; adopt of a folder without README creates one titled by the
#       display name; a second adoption keeps an existing section.
#   (C) a project without the section stays conforming: identity --check
#       CONCORDANT, conformity CONFORME, state sheet « Aucun » -- and so do
#       the projects with it; a project whose state lives in a sub-folder
#       (state_path) finds the README of its root.
#
# usage: bash tests/test-starting-profile.sh [<source repo>]
# Exit 0: all cases PASS. Exit 1 otherwise. No model call, no network.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$REPO_ROOT}"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m240-profile-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/second-brain"
mkdir -p "$WS"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit depuis $SRC"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
SB="$V/tools/sb/bin/sb"
BOOT="$V/tools/project-bootstrap.sh"
export SB_LANG=en
VID="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"
VREF="$(git -C "$V" rev-parse HEAD)"

echo "=== Mission 240 : l'entretien de depart ($SRC) ==="

# lines_kept <file> <reference>: every line of <reference> is still in <file>,
# in order, byte for byte.
lines_kept() { [ -z "$(diff "$2" "$1" | grep '^<')" ]; }
count_heading() { tr -d '\r' < "$1" | grep -cx "$2"; }

# --- (A) sb profile ------------------------------------------------------------
echo "--- (A) sb profile ---"
# An installed profile, as the installer writes it (PowerShell 5.1: a
# byte-order mark and CRLF line ends).
write_installed_profile() {
  printf '\xef\xbb\xbf'
  printf -- '---\r\ntype: profile\r\ntitle: "Fiche utilisateur — Amélie"\r\ndescription: "Rédigée par le questionnaire."\r\nstatus: active\r\nlanguage: fr\r\n---\r\n\r\n# FICHE UTILISATEUR\r\n\r\n## Qui\r\n\r\n- **Prénom :** Amélie\r\n\r\n## Activité\r\n\r\nÉditrice indépendante.\r\n\r\n## Façon de travailler\r\n\r\n- **Outils IA :** claude-code\r\n- **Ce qui compte :** La simplicité\r\n\r\n## Liens\r\n\r\n- `see also` — [AGENTS.md](./AGENTS.md)\r\n'
}
cp "$V/USER.md" "$TMP/skeleton.md"
write_installed_profile > "$V/USER.md"
cp "$V/USER.md" "$TMP/user.before"
mkdir -p "$WS/_orders"
order() { # order <file> <lines...>
  local f="$1"; shift
  { echo "Session Executor — profil de départ"; echo ""; echo "Ordre de profil"; printf -- '%s\n' "$@"; } > "$f"
}

OUT="$(cd "$WS" && "$SB" profile 2>&1)"; RC=$?
check "(A1) sb profile sans section : exit 0, ABSENT missing=5" sh -c "[ '$RC' = 0 ] && printf '%s' \"\$1\" | grep -q 'OWNER-PROFILE ABSENT missing=5'" _ "$OUT"

O1="$WS/_orders/PROFILE-2026-09-27-100000.md"
order "$O1" "- Ce que je fais : Éditrice indépendante." "- Ce qui compte pour moi : La simplicité" \
  "- Trois casse-têtes du moment : trésorerie · relances · agenda" "- Rythme de revue : chaque lundi matin" \
  "- Outils du quotidien : claude-code, Excel, Gmail" "- Autorisation Owner datée : Oui, c'est mon profil, 2026-09-27"
OUT="$(cd "$WS" && "$SB" profile --order "$O1" 2>&1)"; RC=$?
check "(A2) --order : exit 0, OWNER-PROFILE-WRITTEN" sh -c "[ '$RC' = 0 ] && printf '%s' \"\$1\" | grep -q 'OWNER-PROFILE-WRITTEN'" _ "$OUT"
check "(A2) la section porte les cinq champs et la date" sh -c "
  u='$V/USER.md'
  for f in 'Ce que je fais :\\*\\* Éditrice' 'Ce qui compte pour moi :\\*\\* La simplicité' 'Trois casse-têtes du moment :\\*\\* trésorerie · relances · agenda' \
           'Rythme de revue :\\*\\* chaque lundi matin' 'Outils du quotidien :\\*\\* claude-code, Excel, Gmail' 'Mis à jour le :\\*\\* [0-9]{4}-[0-9]{2}-[0-9]{2}'; do
    tr -d '\\r' < \"\$u\" | grep -Eq \"^- \\*\\*\$f\" || { echo \"      absent : \$f\"; exit 1; }
  done"
check "(A2) toutes les lignes d'avant gardees a l'octet (ajout seul)" lines_kept "$V/USER.md" "$TMP/user.before"
check "(A2) une seule section, avant « ## Liens »" sh -c "
  [ \"\$(tr -d '\\r' < '$V/USER.md' | grep -cx '## Profil de départ')\" = 1 ] &&
  [ \"\$(tr -d '\\r' < '$V/USER.md' | grep -n '^## ' | tail -n 1 | cut -d: -f2-)\" = '## Liens' ]"
check "(A2) BOM et fins de ligne CRLF conserves" sh -c "
  [ \"\$(head -c 3 '$V/USER.md' | od -An -tx1 | tr -d ' ')\" = 'efbbbf' ] &&
  [ \"\$(grep -c \$'\\r\$' '$V/USER.md')\" = \"\$(wc -l < '$V/USER.md' | tr -d ' ')\" ]"
check "(A2) l'ordre est range dans _archive/orders/, _orders/ vide" sh -c "
  [ -f '$WS/_archive/orders/PROFILE-2026-09-27-100000.md' ] && [ ! -e '$O1' ]"

cp "$V/USER.md" "$TMP/user.a2"
O2="$WS/_orders/PROFILE-2026-09-27-110000.md"
order "$O2" "- Rythme de revue : un vendredi sur deux" "- Outils du quotidien : -" "- Ce que je fais : <one sentence>" \
  "- Autorisation Owner datée : Oui pour le rythme, 2026-09-27"
OUT="$(cd "$WS" && "$SB" profile --order "$O2" 2>&1)"; RC=$?
check "(A3) ordre partiel : seul « Rythme de revue » change, le reste garde" sh -c "
  [ '$RC' = 0 ] || exit 1
  d=\"\$(diff '$TMP/user.a2' '$V/USER.md' | grep '^[<>]' | tr -d '\\r')\"
  printf '%s\n' \"\$d\" | grep -q '^> - \\*\\*Rythme de revue :\\*\\* un vendredi sur deux\$' || exit 1
  printf '%s\n' \"\$d\" | grep -v 'Rythme de revue\\|Mis à jour le' | grep -q . && exit 1
  exit 0"
check "(A3) toujours une seule section « ## Profil de départ »" test "$(count_heading "$V/USER.md" '## Profil de départ')" = 1
OUT="$(cd "$WS" && "$SB" profile 2>&1)"; RC=$?
check "(A4) sb profile apres : PRESENT missing=0" sh -c "[ '$RC' = 0 ] && printf '%s' \"\$1\" | grep -q 'OWNER-PROFILE PRESENT missing=0'" _ "$OUT"

refused_unchanged() { # refused_unchanged <label> <order file>
  local label="$1" o="$2"
  cp "$V/USER.md" "$TMP/user.ref"
  OUT="$(cd "$WS" && "$SB" profile --order "$o" 2>&1)"; RC=$?
  check "$label : exit 1, REFUSED, USER.md et ordre inchanges" sh -c "
    [ '$RC' = 1 ] && printf '%s' \"\$1\" | grep -q 'REFUSED' && cmp -s '$V/USER.md' '$TMP/user.ref' && [ -f '$o' ]" _ "$OUT"
}
O3="$WS/_orders/PROFILE-2026-09-27-120000.md"
order "$O3" "- Rythme de revue : jamais" "- Autorisation Owner datée : oui"
refused_unchanged "(A5) ordre sans autorisation datee" "$O3"
O4="$WS/_orders/PROFILE-2026-09-27-130000.md"
order "$O4" "- Objet : autre chose" "- Autorisation Owner datée : oui, 2026-09-27"
refused_unchanged "(A6) ordre sans aucun champ du profil" "$O4"
O5="$WS/_orders/PROFILE-2026-09-27-100000.md"
order "$O5" "- Rythme de revue : jamais" "- Autorisation Owner datée : oui, 2026-09-27"
refused_unchanged "(A7) archive qui porte deja ce nom" "$O5"
cp "$V/USER.md" "$TMP/user.installed"
cp "$TMP/skeleton.md" "$V/USER.md"
O6="$WS/_orders/PROFILE-2026-09-27-140000.md"
order "$O6" "- Rythme de revue : jamais" "- Autorisation Owner datée : oui, 2026-09-27"
refused_unchanged "(A8) squelette distribue (status: template)" "$O6"
cp "$TMP/user.installed" "$V/USER.md"

# --- (B) the three fields of the order and --ask ------------------------------------
echo "--- (B) profil du projet : ordre, --ask, adoption ---"
write_order() { # write_order <file> <type> <name> [extra lines...]
  local f="$1" t="$2" n="$3"; shift 3
  {
    echo "Session Executor — initiation ($n)"
    echo ""
    echo "Ordre d'initiation"
    echo "- Type : $t"
    echo "- Mode : answered"
    echo "- Nom : $n"
    echo "- Emplacement : $WS"
    echo "- Vault + construction : vault_id=$VID, vault_origin=$V, vault_ref=$VREF"
    echo "- Git : none"
    echo "- Objet : essai de la Mission 240"
    [ $# -gt 0 ] && printf -- '%s\n' "$@"
    echo "- Autorisation Owner datée : J'ordonne l'initiation, 2026-09-27"
  } > "$f"
}
section_has() { tr -d '\r' < "$1" | awk -v h="$2" '$0 == h { f = 1; next } f && /^## / { exit } f' | grep -qF -- "$3"; }
identity_ok() { bash "$BOOT" identity "$1" --check >/dev/null 2>&1; }
conform_ok() { [ "$(bash "$V/tools/check-project-conformity.sh" "$1" 2>/dev/null)" = "CONFORME" ]; }

write_order "$TMP/o-avec.md" create avec "- Résultat attendu : un site en ligne" "- Blocage actuel : pas de nom de domaine" "- Rythme de revue : chaque vendredi"
OUT="$(bash "$BOOT" --order "$TMP/o-avec.md" FR 2>&1)"; RC=$?
P="$WS/avec"
check "(B1) create --order avec les trois champs : exit 0" test "$RC" = 0
check "(B1) README : « ## Profil du projet » et ses trois valeurs" sh -c "
  for v in 'Résultat attendu :** un site en ligne' 'Blocage actuel :** pas de nom de domaine' 'Rythme de revue :** chaque vendredi'; do
    tr -d '\\r' < '$P/README.md' | grep -qF \"\$v\" || exit 1
  done"
check "(B1) le rapport le dit" sh -c "printf '%s' \"\$1\" | grep -q 'Profil du projet écrit'" _ "$OUT"
check "(B1) la fiche d'etat reprend la section et sa source" sh -c "
  section_has() { tr -d '\\r' < \"\$1\" | awk -v h=\"\$2\" '\$0 == h { f = 1; next } f && /^## / { exit } f' | grep -qF -- \"\$3\"; }
  section_has '$P/state/STATE.md' '## Profil du projet' 'un site en ligne' && section_has '$P/state/STATE.md' '## Profil du projet' 'README.md'"
check "(B1) identity --check CONCORDANT, conformite CONFORME" sh -c "bash '$BOOT' identity '$P' --check >/dev/null 2>&1 && [ \"\$(bash '$V/tools/check-project-conformity.sh' '$P' 2>/dev/null)\" = CONFORME ]"

write_order "$TMP/o-tirets.md" create tirets "- Résultat attendu : -" "- Blocage actuel : <optional: what blocks it now, or delete this line>" "- Rythme de revue : —"
bash "$BOOT" --order "$TMP/o-tirets.md" FR >/dev/null 2>&1
check "(B2) tirets et gabarits : aucune section ecrite" sh -c "[ -f '$WS/tirets/README.md' ] && ! grep -q 'Profil du projet' '$WS/tirets/README.md'"

# Git is carried by the order: name, location, then the three questions.
printf 'demande\n\nmon resultat\n\nchaque mois\n' > "$TMP/ask.txt"
write_order "$TMP/o-ask.md" create propose
sed -i 's/^- Mode : answered$/- Mode : ask/' "$TMP/o-ask.md"
bash "$BOOT" --order "$TMP/o-ask.md" FR < "$TMP/ask.txt" > "$TMP/ask.out" 2>&1
check "(B3) Mode ask : les trois questions apres Git, Entree laisse vide" sh -c "
  r='$WS/demande/README.md'
  tr -d '\\r' < \"\$r\" | grep -qF 'Résultat attendu :** mon resultat' &&
  tr -d '\\r' < \"\$r\" | grep -qxF -- '- **Blocage actuel :**' &&
  tr -d '\\r' < \"\$r\" | grep -qF 'Rythme de revue :** chaque mois'"
check "(B3) les questions sont posees (sortie d'erreur)" grep -q "Résultat attendu de ce projet" "$TMP/ask.out"

printf '\n\n\n' > "$TMP/ask-empty.txt"
OUT="$(cd "$WS" && "$SB" new vide-ask "Vide Ask" --vcs none --lang FR --ask < "$TMP/ask-empty.txt" 2>&1)"; RC=$?
check "(B4) sb new --ask, trois Entree : exit 0, aucune section" sh -c "[ '$RC' = 0 ] && ! grep -q 'Profil du projet' '$WS/vide-ask/README.md'"
printf '\n\nlivrer v1\nattente client\n\n' > "$TMP/ask-some.txt"
OUT="$(cd "$WS" && "$SB" new plein-ask "Plein Ask" --vcs none --lang FR --ask < "$TMP/ask-some.txt" 2>&1)"; RC=$?
check "(B4) sb new --ask : les reponses donnees ecrites, la vide laissee vide" sh -c "
  r='$WS/plein-ask/README.md'
  [ '$RC' = 0 ] && tr -d '\\r' < \"\$r\" | grep -qF 'Résultat attendu :** livrer v1' &&
  tr -d '\\r' < \"\$r\" | grep -qF 'Blocage actuel :** attente client' &&
  tr -d '\\r' < \"\$r\" | grep -qxF -- '- **Rythme de revue :**'"

mkdir -p "$WS/propre"
printf '# Mon projet a moi\n\nDu texte ecrit par l Owner.\n\n## Liens\n\n- rien\n' > "$WS/propre/README.md"
cp "$WS/propre/README.md" "$TMP/propre.before"
write_order "$TMP/o-propre.md" adopt propre "- Blocage actuel : aucune maquette"
bash "$BOOT" --order "$TMP/o-propre.md" FR > "$TMP/propre.out" 2>&1
check "(B5) adopt avec README : une section ajoutee, chaque ligne gardee" sh -c "
  diff '$TMP/propre.before' '$WS/propre/README.md' | grep -q '^<' && exit 1
  tr -d '\\r' < '$WS/propre/README.md' | grep -qF 'Blocage actuel :** aucune maquette'"
mkdir -p "$WS/nu"
printf 'note\n' > "$WS/nu/notes.txt"
write_order "$TMP/o-nu.md" adopt nu "- Résultat attendu : ranger mes notes"
bash "$BOOT" --order "$TMP/o-nu.md" FR > "$TMP/nu.out" 2>&1
check "(B6) adopt sans README : README cree, titre = nom, section presente" sh -c "
  [ \"\$(head -n 1 '$WS/nu/README.md')\" = '# nu' ] && grep -qF 'ranger mes notes' '$WS/nu/README.md'"
check "(B6) identity --check CONCORDANT sur le README cree" identity_ok "$WS/nu"
cp "$WS/nu/README.md" "$TMP/nu.before"
write_order "$TMP/o-nu2.md" adopt nu "- Résultat attendu : autre chose"
OUT="$(bash "$BOOT" --order "$TMP/o-nu2.md" FR 2>&1)"
check "(B7) seconde adoption : la section existante est gardee" sh -c "
  cmp -s '$TMP/nu.before' '$WS/nu/README.md' && printf '%s' \"\$1\" | grep -q 'déjà présent'" _ "$OUT"

# --- (C) a project without the section stays conforming ---------------------------
echo "--- (C) projet sans profil : toujours conforme ---"
write_order "$TMP/o-sans.md" create sans
bash "$BOOT" --order "$TMP/o-sans.md" FR >/dev/null 2>&1
PS="$WS/sans"
check "(C1) sans profil : README sans section" sh -c "! grep -q 'Profil du projet' '$PS/README.md'"
check "(C1) identity --check CONCORDANT" identity_ok "$PS"
check "(C1) conformite CONFORME" conform_ok "$PS"
check "(C1) fiche d'etat : « Aucun … (facultatif) »" sh -c "tr -d '\\r' < '$PS/state/STATE.md' | grep -q '^Aucun : le README du projet ne porte pas le titre'"
check "(C1) cree avec profil : CONFORME" conform_ok "$P"
# An adopted folder keeps the gaps of its layout (the seven functions are
# proposed, never applied): the profile adds none, and removes the README gap
# when it creates one.
check "(C1) adoptes avec profil : aucun ecart ne tient au README ni au profil" sh -c "
  for p in nu propre; do
    c=\"\$(bash '$V/tools/check-project-conformity.sh' '$WS/'\$p 2>/dev/null)\"
    printf '%s' \"\$c\" | grep -qi 'README\\|profil' && { echo \"      \$p : \$c\"; exit 1; }
  done; exit 0"
# state_path: the state in a sub-folder, the README at the project's root.
mkdir -p "$PS/atelier/state"
printf '# Journal\n\n2026-09-27T10:00:00-04:00 STATE: essai\n' > "$PS/atelier/state/journal.md"
(cd "$PS" && git init -q -b main 2>/dev/null || git init -q) >/dev/null 2>&1
printf '\n## Profil du projet\n\n- **Résultat attendu :** sous-dossier\n' >> "$PS/README.md"
bash "$V/tools/build-state.sh" "$PS/atelier" >/dev/null 2>&1
check "(C2) state_path : la fiche du sous-dossier trouve le README de la racine" sh -c "
  tr -d '\\r' < '$PS/atelier/state/STATE.md' | grep -qF 'sous-dossier' && tr -d '\\r' < '$PS/atelier/state/STATE.md' | grep -qF '../../README.md'"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
