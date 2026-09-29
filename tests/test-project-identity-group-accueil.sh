#!/usr/bin/env bash
# Mission 234, steps 5, 6, 7 and 8 (rule on workspace hygiene, project names and
# session types): the tool side of the entry scenarios, on a throwaway Vault
# built from the working tree of <source> (default: this repository).
#
#   (1) create: the block says « Create a Project named "SB - <Name>" »;
#   (2) the Pilot prompt carries pilot_project_name: "SB - <Name>";
#   (3) identity: the card names folder, group, name, project_id, registry
#       line, canary and expected Pilot Project; --check: CONCORDANT, exit 0;
#   (4) the registry renames the project: --check names the Pilot prompt and
#       the README ANOMALY; `prompt` follows the registry and keeps project_id
#       and canary;
#   (5) identity at the workspace root: refused (welcome or free session);
#   (6) identity in a folder that is not adopted: ANOMALY, exit 1;
#   (7) create --group: <ws>/<group>/<folder>, registry path <group>/<folder>,
#       card group named, the root guardian CONFORME (a group of projects);
#   (8) --group refused before any write: a group that is a project, one that
#       carries VAULT-ROOT.md, one that is not a folder name, with adopt;
#   (9) --order with the field Groupe: created in the group;
#  (10) `order` prints "Groupe : -"; a Groupe left as the template's
#       placeholder is ignored (flat);
#  (11) create at the workspace root itself: refused, nothing written;
#  (12) accueil-prompt: the block creates « SB - Accueil », every placeholder
#       rendered.
#
# usage: bash tests/test-project-identity-group-accueil.sh [<source repo>]
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$REPO_ROOT}"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m234-idg-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit depuis $SRC"; exit 1; }
bash "$V/tools/write-marker.sh" --marker-only "$WS" >/dev/null 2>&1 || bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1
BOOT="$V/tools/project-bootstrap.sh"
REG="$V/projects/PROJECT-REGISTRY.md"
VID="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"
DOT="SB - "

echo "=== Mission 234 : carte d'identite, noms SB, groupe, accueil ($SRC) ==="

# --- (1) (2) create, flat ---
OUT="$(bash "$BOOT" create "$WS/proj-one" "Proj One" EN --vcs none 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -qF "Create a Project named \"${DOT}Proj One\""; then
  pass "(1) create : le bloc dit « Create a Project named \"SB - Proj One\" »"
else
  fail "(1) create : rc=$RC, bloc sans le prefixe SB : $(printf '%s' "$OUT" | grep -i 'project named' | head -1)"
fi
if grep -qF "pilot_project_name: \"${DOT}Proj One\"" "$WS/proj-one/state/PILOT-PROMPT.md" 2>/dev/null; then
  pass "(2) le prompt Pilot porte pilot_project_name: \"SB - Proj One\""
else
  fail "(2) pilot_project_name absent du prompt Pilot"
fi

# --- (3) identity card ---
OUT="$(bash "$BOOT" identity "$WS/proj-one" --check 2>&1)"; RC=$?
CANARY="$(sed -n 's/^canary: "\(.*\)"$/\1/p' "$WS/proj-one/state/PILOT-PROMPT.md" | tr -d '\r')"
PID="$(sed -n 's/^project_id: \(.*\)$/\1/p' "$WS/proj-one/state/PILOT-PROMPT.md" | tr -d '\r')"
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q '^IDENTITY: CONCORDANT' \
   && printf '%s' "$OUT" | grep -qF "Project Pilot attendu : ${DOT}Proj One" \
   && printf '%s' "$OUT" | grep -qF "Canari : $CANARY" && printf '%s' "$OUT" | grep -qF "project_id : $PID" \
   && printf '%s' "$OUT" | grep -q '^- Groupe : —' && printf '%s' "$OUT" | grep -q "^- Ligne du registre : | $PID |"; then
  pass "(3) carte d'identite complete ; --check CONCORDANT, code 0"
else
  fail "(3) carte ou --check : rc=$RC : $OUT"
fi

# --- (4) renamed in the registry ---
sed -i "s/^| $PID | Proj One |/| $PID | Project One |/" "$REG"
OUT="$(bash "$BOOT" identity "$WS/proj-one" --check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && printf '%s' "$OUT" | grep -q '^ANOMALY: pilot_project_name du prompt' && printf '%s' "$OUT" | grep -q '^ANOMALY: titre du README'; then
  pass "(4a) nom change au registre : --check nomme le prompt Pilot et le README (ANOMALY, code 1)"
else
  fail "(4a) renommage non detecte : rc=$RC : $OUT"
fi
bash "$BOOT" prompt "$WS/proj-one" >/dev/null 2>&1
if grep -qF "pilot_project_name: \"${DOT}Project One\"" "$WS/proj-one/state/PILOT-PROMPT.md" \
   && grep -qF "canary: \"$CANARY\"" "$WS/proj-one/state/PILOT-PROMPT.md" \
   && grep -q "^project_id: $PID" "$WS/proj-one/state/PILOT-PROMPT.md"; then
  pass "(4b) prompt regenere : suit le registre (SB - Project One), garde project_id et canari"
else
  fail "(4b) regeneration : $(grep -E '^(pilot_project_name|canary|project_id)' "$WS/proj-one/state/PILOT-PROMPT.md" | tr '\n' ' ')"
fi

# --- (5) workspace root ---
OUT="$(bash "$BOOT" identity "$WS" 2>&1)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q "racine de l'espace, pas un projet"; then
  pass "(5) identity a la racine de l'espace : refuse (session d'accueil ou libre)"
else
  fail "(5) racine : rc=$RC : $OUT"
fi

# --- (6) not adopted ---
mkdir -p "$TMP/loose"
OUT="$(bash "$BOOT" identity "$TMP/loose" --check 2>&1)"; RC=$?
if [ "$RC" -eq 1 ] && printf '%s' "$OUT" | grep -q '^ANOMALY: aucun acte de naissance'; then
  pass "(6) dossier non adopte : ANOMALY (aucun acte), code 1"
else
  fail "(6) non adopte : rc=$RC : $OUT"
fi

# --- (7) create --group ---
OUT="$(bash "$BOOT" create "$WS/proj-two" "Proj Two" EN --vcs none --group grp 2>&1)"; RC=$?
CARD="$(bash "$BOOT" identity "$WS/grp/proj-two" 2>&1)"
ROOT_OUT="$(bash "$V/tools/check-workspace-root.sh" "$WS" 2>&1)"; ROOT_RC=$?
if [ "$RC" -eq 0 ] && [ -f "$WS/grp/proj-two/state/PILOT-PROMPT.md" ] && [ ! -e "$WS/proj-two" ] \
   && grep -q '| grp/proj-two |' "$REG" && printf '%s' "$CARD" | grep -q '^- Groupe : grp$' \
   && [ "$ROOT_RC" -eq 0 ]; then
  pass "(7) create --group : <ws>/grp/proj-two, registre grp/proj-two, carte « Groupe : grp », racine CONFORME"
else
  fail "(7) --group : rc=$RC, racine rc=$ROOT_RC : $(printf '%s\n%s' "$OUT" "$ROOT_OUT" | grep -E 'REFUS|ÉCART' | head -3)"
fi

# --- (8) refusals ---
REG_SUM="$(cksum < "$REG")"
R1="$(bash "$BOOT" create "$WS/x1" "X1" EN --vcs none --group proj-one 2>&1)"; C1=$?
mkdir -p "$WS/grp-marked" && printf 'marker\n' > "$WS/grp-marked/VAULT-ROOT.md"
R2="$(bash "$BOOT" create "$WS/x2" "X2" EN --vcs none --group grp-marked 2>&1)"; C2=$?
R3="$(bash "$BOOT" create "$WS/x3" "X3" EN --vcs none --group a/b 2>&1)"; C3=$?
R4="$(bash "$BOOT" adopt "$WS/proj-one" --vcs none --group grp 2>&1)"; C4=$?
mv "$WS/grp-marked" "$TMP/"
if [ "$C1" -ne 0 ] && printf '%s' "$R1" | grep -q 'est un projet\|inscrit au registre' \
   && [ "$C2" -ne 0 ] && printf '%s' "$R2" | grep -q 'porte VAULT-ROOT.md' \
   && [ "$C3" -ne 0 ] && printf '%s' "$R3" | grep -q 'groupe invalide' \
   && [ "$C4" -ne 0 ] && printf '%s' "$R4" | grep -q 'ne vaut que pour create' \
   && [ ! -e "$WS/proj-one/x1" ] && [ ! -e "$WS/a" ] && [ "$(cksum < "$REG")" = "$REG_SUM" ]; then
  pass "(8) --group refuse avant toute ecriture : groupe-projet, groupe marque, nom invalide, adopt"
else
  fail "(8) refus du groupe : $C1/$C2/$C3/$C4 : $(printf '%s | %s | %s | %s' "$R1" "$R2" "$R3" "$R4" | tr '\n' ' ' | cut -c1-400)"
fi

# --- (9) --order with Groupe ---
ORDER="$TMP/order-three.md"
cat > "$ORDER" <<EOF
Ordre d'initiation
- Type : create
- Mode : answered
- Nom : proj-three
- Emplacement : $WS
- Groupe : grp
- Vault + construction : vault_id=$VID, vault_origin=x, vault_ref=x
- Git : none
- Objet : test du groupe par l'ordre
- Autorisation Owner datée : « test » 2026-09-26
EOF
OUT="$(bash "$BOOT" --order "$ORDER" EN 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && [ -f "$WS/grp/proj-three/state/PILOT-PROMPT.md" ] && grep -q '| grp/proj-three |' "$REG"; then
  pass "(9) --order avec le champ Groupe : cree dans <ws>/grp/proj-three"
else
  fail "(9) ordre avec Groupe : rc=$RC : $(printf '%s' "$OUT" | grep REFUS | head -2)"
fi

# --- (10) order prints Groupe; a placeholder is ignored ---
OUT="$(bash "$BOOT" order "$TMP/newthing" 2>&1)"
sed -e 's/proj-three/proj-four/' -e 's/^- Groupe : grp$/- Groupe : <optional group folder, or delete this line>/' "$ORDER" > "$TMP/order-four.md"
bash "$BOOT" --order "$TMP/order-four.md" EN >/dev/null 2>&1; RC=$?
if printf '%s' "$OUT" | grep -q '^- Groupe : -$' && [ "$RC" -eq 0 ] && [ -d "$WS/proj-four" ]; then
  pass "(10) order imprime « Groupe : - » ; un Groupe laisse en gabarit est ignore (projet a plat)"
else
  fail "(10) order/gabarit : rc=$RC, groupe imprime=$(printf '%s' "$OUT" | grep -c 'Groupe'), a plat=$([ -d "$WS/proj-four" ] && echo oui || echo non)"
fi

# --- (11) the workspace root itself ---
REG_SUM="$(cksum < "$REG")"
OUT="$(bash "$BOOT" create "$WS" "Root Project" EN --vcs none 2>&1)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q 'REPO-ROOT-REFUSED\|REFUS' && [ "$(cksum < "$REG")" = "$REG_SUM" ] && [ ! -e "$WS/README.md" ]; then
  pass "(11) create a la racine de l'espace : refus nomme, rien ecrit"
else
  fail "(11) racine : rc=$RC : $OUT"
fi

# --- (12) accueil-prompt ---
OUT="$(bash "$BOOT" accueil-prompt 2>&1)"; RC=$?
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -qF "${DOT}Accueil" && ! printf '%s' "$OUT" | grep -q '{{' \
   && printf '%s' "$OUT" | grep -q '_orders/ORDER-'; then
  pass "(12) accueil-prompt : bloc « SB - Accueil », gabarits rendus, depot des ordres dans _orders/"
else
  fail "(12) accueil-prompt : rc=$RC : $(printf '%s' "$OUT" | head -3)"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
