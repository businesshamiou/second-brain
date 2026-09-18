#!/usr/bin/env bash
# Project initiation and adoption (Mission 184, Decision 2026-09-17-000545).
#
# Six families of cases, each with its negative control in this file:
#   (a) create        : birth certificate, vcs, Pilot prompt, block to consume;
#                       the historical call stays silent and still creates the certificate;
#                       the certificate's form passes `pre-commit validate-config`
#                       without a warning (control: a top-level key
#                       warns).
#   (b) adopt         : nothing modified, baseline, ratchet, reorganisation
#                       plan proposed and not applied, link repair
#                       proposed and not applied.
#   (c) two Vaults    : the certificate wins; marker alone refused; identity
#                       different or absent refused, naming both.
#   (d) 214607 D4     : project copied alone outside the workspace -- the
#                       per-command checks return a verdict.
#   (e) vcs: none     : no repository, no hook, per-command checks;
#                       `adopt --git` adds repository, hook and active pin.
#   (f) order         : empty folder, existing, existing without Git -> adopted
#                       without a Mission; without an order -> nothing written, order returned.
#
# The guardians are run the way pre-commit runs them (entries of the pin,
# from the project root), so that the verdict does not depend on the
# presence of pre-commit on the runner; `pre-commit install` is a
# recording stand-in placed at the head of the PATH.
#
# Writes only in a temporary folder (prefix m184). No model
# call, no network apart from the form check by pre-commit.
#
# usage: bash tests/test-project-initiation.sh
# Exit 0: all cases PASS (or named SKIP). Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
SKIPS=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
skip() { echo "  SKIP ($1) - $2"; SKIPS=$((SKIPS + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- tools/project-bootstrap.sh en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m184-init-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

# --- pre-commit stand-in: `install` sets a hook, nothing else. ------------
mkdir -p "$TMP/bin"
cat > "$TMP/bin/pre-commit" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "install" ]; then
  hooks="$(git rev-parse --git-path hooks)" || exit 1
  mkdir -p "$hooks"
  printf '#!/usr/bin/env bash\n# substitut de test\nexit 0\n' > "$hooks/pre-commit"
  echo "pre-commit installed at $hooks/pre-commit"
  exit 0
fi
exit 0
STUB
chmod +x "$TMP/bin/pre-commit"
PATH="$TMP/bin:$PATH"
export PATH

WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
echo "=== Vault jetable (arbre de travail) ==="
if ! sandbox_vault "$REPO_ROOT" "$V"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V/tools/write-marker.sh" "$WS" >/dev/null || { echo "FAIL : marqueur non ecrit"; exit 1; }
BOOT="$V/tools/project-bootstrap.sh"
REGISTRY="$V/projects/PROJECT-REGISTRY.md"
VID="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"
VREF="$(git -C "$V" rev-parse HEAD)"
echo "  Vault $VID @ $VREF"

git_quiet() { git -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false "$@"; }

# run_pin <projet>: runs each entry of the pin from the root of the
# project, like pre-commit; 0 if they all pass.
run_pin() {
  local proj="$1" entry rc=0
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    (cd "$proj" && bash "$entry") >"$TMP/pin.out" 2>&1 || { rc=1; sed 's/^/      /' "$TMP/pin.out"; }
  done <<EOF
$(tr -d '\r' < "$proj/.pre-commit-config.yaml" | sed -n 's/^[[:space:]]*entry:[[:space:]]*//p')
EOF
  return "$rc"
}

stage_all() {
  (cd "$1" && git add -A >/dev/null 2>&1)
}

no_modified() {
  ! (cd "$1" && git status --porcelain | grep -qE '^( M|M |MM|R |D | D)')
}

sha_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum < "$1" | awk '{print $1}'
  else
    shasum -a 256 < "$1" | awk '{print $1}'
  fi
}

# =============================================================================
echo ""
echo "=== (a) create ==="
BEFORE_A=0
[ -e "$WS/alpha/.pre-commit-config.yaml" ] && BEFORE_A=1
check "(a) avant : aucun acte a la cible (0)" [ "$BEFORE_A" = "0" ]
OUT_A="$(bash "$BOOT" create "$WS/alpha" "Alpha" --vcs git --lang FR 2>&1)"
RC_A=$?
check "(a) create rend 0" [ "$RC_A" = "0" ]
check "(a) acte de naissance pose (en-tete, vault_id, vault_ref, vcs)" \
  sh -c "grep -qx '# second-brain-birth-certificate: v1' '$WS/alpha/.pre-commit-config.yaml' \
    && grep -qx '# vault_id: $VID' '$WS/alpha/.pre-commit-config.yaml' \
    && grep -qx '# vault_ref: $VREF' '$WS/alpha/.pre-commit-config.yaml' \
    && grep -qx '# vcs: git' '$WS/alpha/.pre-commit-config.yaml'"
CANARY_A="$(sed -n 's/^canary: "\(.*\)"$/\1/p' "$WS/alpha/state/PILOT-PROMPT.md" 2>/dev/null)"
check "(a) state/PILOT-PROMPT.md genere avec un canari" [ -n "$CANARY_A" ]
case "$OUT_A" in *"$CANARY_A"*"$WS"*|*"$CANARY_A"*) r=0 ;; *) r=1 ;; esac
check "(a) bloc a consommer imprime (canari cite)" [ "$r" = "0" ]
case "$OUT_A" in *"Premier message de chaque conversation"*) r=0 ;; *) r=1 ;; esac
check "(a) bloc a consommer imprime par le catalogue FR" [ "$r" = "0" ]
check "(a) registre : ligne avec vcs git et CONFORME" grep -qF "| alpha | git | CONFORME |" "$REGISTRY"
FICHE_A="$(printf '%s\n' "$OUT_A" | tail -n 1)"
check "(a) fiche : vcs, vault_id, vault_ref" sh -c "grep -qx 'vcs: git' '$FICHE_A' && grep -qx 'vault_id: $VID' '$FICHE_A' && grep -qx 'vault_ref: $VREF' '$FICHE_A'"
check "(a) depot Git cree et hook pose (pre-commit install)" [ -f "$WS/alpha/.git/hooks/pre-commit" ]
stage_all "$WS/alpha"
check "(a) les quatre gardiens de l'epingle acceptent le premier commit" run_pin "$WS/alpha"

OUT_LEGACY="$(bash "$BOOT" "$WS/beta" "Beta" 2>&1)"
RC_LEGACY=$?
check "(a) appel historique (sans sous-commande) rend 0" [ "$RC_LEGACY" = "0" ]
check "(a) appel historique : acte pose, vcs git" grep -qx '# vcs: git' "$WS/beta/.pre-commit-config.yaml"
case "$OUT_LEGACY" in *"First message"*|*"Canary"*) r=1 ;; *) r=0 ;; esac
check "(a) appel historique : aucun bloc a consommer (journal des installeurs inchange)" [ "$r" = "0" ]

bash "$BOOT" create "$WS/alpha" "Alpha" --vcs git >/dev/null 2>&1
check "(a) temoin : create sur une cible existante est refuse" [ "$?" = "1" ]
mkdir -p "$TMP/copies"
(cd "$WS" && tar -cf - --exclude=./alpha/.claude --exclude=./alpha/.agents alpha) | (cd "$TMP/copies" && tar -xf -)
mv "$TMP/copies/alpha" "$WS/alpha-sans-acte"
grep -v '^# ' "$WS/alpha/.pre-commit-config.yaml" > "$WS/alpha-sans-acte/.pre-commit-config.yaml"
CONF_NOCERT="$(bash "$V/tools/check-project-conformity.sh" "$WS/alpha-sans-acte" 2>&1)"
case "$CONF_NOCERT" in *"acte de naissance absent"*) r=0 ;; *) r=1 ;; esac
check "(a) temoin : la conformite dit « acte de naissance absent » sans l'acte" [ "$r" = "0" ]

PC_VERSION="$(sed -n '/"preCommit"/,/}/ s/.*"version": *"\([^"]*\)".*/\1/p' "$REPO_ROOT/tools/prerequisites.lock.json" | head -n 1)"
VALIDATE_OUT="$(cd "$WS/alpha" && uv tool run --from "pre-commit==$PC_VERSION" pre-commit validate-config .pre-commit-config.yaml 2>&1)"
VALIDATE_RC=$?
printf 'vault_birth: {vcs: git}\nrepos: []\n' > "$TMP/key-form.yaml"
KEY_OUT="$(uv tool run --from "pre-commit==$PC_VERSION" pre-commit validate-config "$TMP/key-form.yaml" 2>&1)"
case "$KEY_OUT" in
  *"Unexpected key"*)
    check "(a) forme de l'acte : pre-commit $PC_VERSION validate-config sans erreur ni avertissement" \
      sh -c "[ '$VALIDATE_RC' = '0' ] && [ -z \"\$(printf '%s' \"\$1\" | grep -i 'warn\|error')\" ]" _ "$VALIDATE_OUT"
    pass "(a) temoin : une cle de premier niveau fait avertir le meme validateur"
    ;;
  *)
    skip "pre-commit $PC_VERSION indisponible par uv tool run, $(uname -s)" "(a) forme de l'acte devant validate-config : $(printf '%s' "$KEY_OUT" | head -n 1)"
    ;;
esac

# =============================================================================
echo ""
echo "=== (b) adopt ==="
P="$WS/legacy"
mkdir -p "$P/notes" "$P/archive"
printf '# Ancienne note\n\nVoir [absente](./missing.md).\n' > "$P/notes/old.md"
printf '# Projet existant\n' > "$P/README.md"
printf 'notes\n' > "$P/MISSION-plan.md"
printf '# Cible deplacee\n\n## Liens\n\n- [r](../README.md)\n' > "$P/archive/missing.md"
(cd "$P" && git init -q -b main 2>/dev/null || git init -q)
(cd "$P" && git add -A >/dev/null 2>&1 && git_quiet commit -q -m existant)
OLD_SHA="$(sha_of "$P/notes/old.md")"
OUT_B="$(bash "$BOOT" adopt "$P" --vcs git --lang FR 2>&1)"
check "(b) adopt rend 0" [ "$?" = "0" ]
check "(b) fichiers existants modifies : 0 (porcelain sans M ni D)" no_modified "$P"
ADDED_B="$(cd "$P" && git status --porcelain | grep -c '^??')"
check "(b) fichiers ajoutes listes en ?? ($ADDED_B)" [ "$ADDED_B" -ge 5 ]
case "$OUT_B" in *"Plan de réorganisation proposé"*"déplacer MISSION-plan.md vers missions/MISSION-plan.md"*) r=0 ;; *) r=1 ;; esac
check "(b) plan de reorganisation rendu" [ "$r" = "0" ]
check "(b) plan applique : 0 (MISSION-plan.md toujours a la racine, missions/ absent)" sh -c "[ -f '$P/MISSION-plan.md' ] && [ ! -e '$P/missions' ]"
BASE_B="$(sed -n 's/^# baseline: //p' "$P/.pre-commit-config.yaml")"
check "(b) ligne de base datee nommee par l'acte ($BASE_B)" sh -c "[ -n '$BASE_B' ] && grep -q '	notes/old.md\$' '$P/$BASE_B'"
check "(b) registre et fiche ecrits" grep -qF "| legacy | git |" "$REGISTRY"
stage_all "$P"
check "(b) ligne de base : lien casse d'avant, non touche -> accepte" run_pin "$P"
(cd "$P" && git_quiet commit -q -m adoption >/dev/null 2>&1)

cp "$P/notes/old.md" "$TMP/old.md.orig"
printf '\nAjout.\n' >> "$P/notes/old.md"
stage_all "$P"
if run_pin "$P" >/dev/null; then r=1; else r=0; fi
check "(b) cliquet : fichier de la ligne de base touche, lien casse -> refuse" [ "$r" = "0" ]
cp "$TMP/old.md.orig" "$P/notes/old.md"
(cd "$P" && git reset -q)
printf '# Ancienne note\r\n\r\nVoir [absente](./missing.md).\r\n' > "$TMP/old-crlf.md"
cp "$TMP/old-crlf.md" "$P/notes/old.md"
if bash "$V/tools/check-links.sh" "$P" >/dev/null 2>&1; then r=0; else r=1; fi
check "(b) ligne de base : seules les fins de ligne reecrites (CRLF) -> non touche" [ "$r" = "0" ]
cp "$TMP/old.md.orig" "$P/notes/old.md"

printf '# Neuve\n\n[x](./nope.md)\n\n## Liens\n\n- [r](../README.md)\n' > "$P/notes/new.md"
bash "$V/tools/build-indexes.sh" --only-missing "$P" >/dev/null 2>&1
stage_all "$P"
if (cd "$P" && bash "$V/tools/check-links.sh") >/dev/null 2>&1; then r=1; else r=0; fi
check "(b) nouveau fichier avec lien casse -> refuse" [ "$r" = "0" ]
(cd "$P" && git reset -q && rm -f notes/new.md)

if bash "$V/tools/check-links.sh" "$P" >/dev/null 2>&1; then r=0; else r=1; fi
check "(b) controle par commande avec ligne de base -> PASS" [ "$r" = "0" ]
(cd "$WS" && tar -cf - --exclude=./legacy/.claude --exclude=./legacy/.agents --exclude=./legacy/.git legacy) | (cd "$TMP/copies" && tar -xf -)
grep -v '^# baseline: ' "$P/.pre-commit-config.yaml" > "$TMP/copies/legacy/.pre-commit-config.yaml"
if bash "$V/tools/check-links.sh" "$TMP/copies/legacy" >/dev/null 2>&1; then r=1; else r=0; fi
check "(b) temoin : la meme copie sans ligne de base -> refusee (le lien casse est bien vu)" [ "$r" = "0" ]

PLAN_OUT="$(bash "$V/tools/propose-link-repairs.sh" "$P" 2>&1)"
case "$PLAN_OUT" in *"PROPOSE notes/old.md:3: ./missing.md -> ../archive/missing.md"*"0 appliquée(s)"*) r=0 ;; *) r=1 ;; esac
check "(b) reparation de liens : plan rendu, 0 appliquee" [ "$r" = "0" ]
check "(b) reparation de liens : fichier inchange" [ "$(sha_of "$P/notes/old.md")" = "$OLD_SHA" ]
bash "$V/tools/propose-link-repairs.sh" "$P" --apply >/dev/null 2>&1
check "(b) temoin : --apply sans Mission est refuse" [ "$?" = "1" ]
check "(b) temoin : fichier toujours inchange apres le refus" [ "$(sha_of "$P/notes/old.md")" = "$OLD_SHA" ]

# =============================================================================
echo ""
echo "=== (c) deux Vaults ==="
WS2="$TMP/ws2"
mkdir -p "$WS2"
A="$WS2/vault-a"
B="$WS2/vault-b"
sandbox_vault "$REPO_ROOT" "$A" >/dev/null 2>&1
sandbox_vault "$REPO_ROOT" "$B" >/dev/null 2>&1
ID_A="$(bash "$A/tools/vault-identity.sh" get vault_id "$A")"
ID_B="$(bash "$B/tools/vault-identity.sh" get vault_id "$B")"
check "(c) deux identites distinctes ($ID_A, $ID_B)" sh -c "[ -n '$ID_A' ] && [ -n '$ID_B' ] && [ '$ID_A' != '$ID_B' ]"
bash "$B/tools/write-marker.sh" "$WS2" >/dev/null
bash "$A/tools/project-bootstrap.sh" create "$WS2/p1" "P1" --vcs none >/dev/null 2>&1
check "(c) projet ne du Vault A, marqueur nommant B" sh -c "grep -qx '# vault_id: $ID_A' '$WS2/p1/.pre-commit-config.yaml' && grep -q '$ID_B' '$WS2/VAULT-ROOT.md'"
RES="$(bash "$B/tools/resolve-vault.sh" "$WS2/p1" 2>&1)"
RES_ABS="$(cd "$A" && pwd -P)"
check "(c) l'acte gagne : resolu vers A ($RES)" [ "$RES" = "$RES_ABS" ]
mkdir -p "$WS2/plain"
RES_PLAIN="$(bash "$B/tools/resolve-vault.sh" "$WS2/plain" 2>&1)"
check "(c) temoin : marqueur seul, deux candidats -> refus" sh -c "case \"\$1\" in *'plusieurs Vaults candidats'*) exit 0;; *) exit 1;; esac" _ "$RES_PLAIN"
cp "$A/VAULT-IDENTITY.md" "$TMP/identity-a.md"
sed "s/^vault_id: .*/vault_id: \"sb-autre\"/" "$TMP/identity-a.md" > "$A/VAULT-IDENTITY.md"
RES_DIFF="$(bash "$B/tools/resolve-vault.sh" "$WS2/p1" 2>&1)"
check "(c) identite differente -> refus nommant les deux" sh -c "case \"\$1\" in *REFUS*'$ID_A'*sb-autre*) exit 0;; *) exit 1;; esac" _ "$RES_DIFF"
sed 's/^vault_id: .*/vault_id: ""/; s/^status: .*/status: template/' "$TMP/identity-a.md" > "$A/VAULT-IDENTITY.md"
RES_NONE="$(bash "$B/tools/resolve-vault.sh" "$WS2/p1" 2>&1)"
check "(c) identite absente -> refus nommant les deux" sh -c "case \"\$1\" in *REFUS*'$ID_A'*'identité absente'*) exit 0;; *) exit 1;; esac" _ "$RES_NONE"
cp "$TMP/identity-a.md" "$A/VAULT-IDENTITY.md"
RES_SINGLE="$(bash "$V/tools/resolve-vault.sh" "$WS/alpha-sans-acte" 2>&1)"
check "(c) sans acte, un seul candidat -> resolu" [ "$RES_SINGLE" = "$(cd "$V" && pwd -P)" ]

# =============================================================================
echo ""
echo "=== (d) 214607 D4 : projet copie seul ==="
ALONE="$TMP/alone"
mkdir -p "$ALONE"
(cd "$WS" && tar -cf - --exclude=./alpha/.claude --exclude=./alpha/.agents --exclude=./alpha/.git alpha) | (cd "$ALONE" && tar -xf -)
check "(d) aucun marqueur au-dessus de la copie" sh -c "! bash -c '. \"$V/tools/resolve-vault.sh\"; rv_find_marker \"$ALONE/alpha\"' >/dev/null"
CONF_D="$(bash "$V/tools/check-project-conformity.sh" "$ALONE/alpha" 2>&1)"
RC_D=$?
case "$CONF_D" in CONFORME*|ÉCART*) r=0 ;; *) r=1 ;; esac
check "(d) conformite par commande : verdict rendu (rc $RC_D : $(printf '%s' "$CONF_D" | cut -c1-60)...)" sh -c "[ '$RC_D' = '0' ] && [ '$r' = '0' ]"
for g in check-links.sh check-secrets.sh check-indexes-fresh.sh check-index-weight.sh; do
  bash "$V/tools/$g" "$ALONE/alpha" >/dev/null 2>&1
  check "(d) $g <projet> : PASS sur la copie seule" [ "$?" = "0" ]
done
printf '# Casse\n\n[x](./absent.md)\n\n## Liens\n\n- [r](../README.md)\n' > "$ALONE/alpha/knowledge/casse.md"
if bash "$V/tools/check-links.sh" "$ALONE/alpha" >/dev/null 2>&1; then r=1; else r=0; fi
check "(d) temoin : un lien casse ajoute a la copie -> check-links FAIL" [ "$r" = "0" ]
SECRET_KEY_WORD="tok""en"
printf '%s = "%s%s"\n' "$SECRET_KEY_WORD" "abcdefghijklmnop" "qrstuvwxyz123456" > "$ALONE/alpha/knowledge/fuite.txt"
if bash "$V/tools/check-secrets.sh" "$ALONE/alpha" >/dev/null 2>&1; then r=1; else r=0; fi
check "(d) temoin : un secret ajoute a la copie -> check-secrets FAIL" [ "$r" = "0" ]

# =============================================================================
echo ""
echo "=== (e) vcs: none ==="
N="$WS/nogit"
mkdir -p "$N"
printf '# Sans Git\n' > "$N/notes.md"
OUT_E="$(bash "$BOOT" adopt "$N" --vcs none --lang FR 2>&1)"
check "(e) adopt --vcs none rend 0" [ "$?" = "0" ]
check "(e) aucun depot Git, aucun hook" [ ! -e "$N/.git" ]
check "(e) acte : vcs none ; registre : colonne none" sh -c "grep -qx '# vcs: none' '$N/.pre-commit-config.yaml' && grep -qF '| nogit | none |' '$REGISTRY'"
for g in check-links.sh check-secrets.sh check-indexes-fresh.sh check-index-weight.sh check-project-conformity.sh; do
  G_OUT="$(bash "$V/tools/$g" "$N" 2>&1)"
  check "(e) $g <projet> rend un verdict (rc 0)" [ "$?" = "0" ]
done
bash "$BOOT" adopt "$N" --git --lang FR >/dev/null 2>&1
check "(e) adopt --git rend 0" [ "$?" = "0" ]
check "(e) adopt --git : depot, hook, acte vcs git" sh -c "[ -d '$N/.git' ] && [ -f '$N/.git/hooks/pre-commit' ] && grep -qx '# vcs: git' '$N/.pre-commit-config.yaml'"
check "(e) adopt --git : registre et fiche passent a git" sh -c "grep -qF '| nogit | git |' '$REGISTRY' && grep -lx 'vcs: git' '$V'/projects/PROJECT-*NOGIT*.md >/dev/null"
(cd "$WS/alpha" && git config core.hooksPath "$TMP/no-hooks-here")
CONF_E="$(bash "$V/tools/check-project-conformity.sh" "$WS/alpha" 2>&1)"
(cd "$WS/alpha" && git config --unset core.hooksPath)
case "$CONF_E" in *"hook Git absent"*) r=0 ;; *) r=1 ;; esac
check "(e) temoin : vcs git sans hook -> la conformite le dit" [ "$r" = "0" ]

# =============================================================================
echo ""
echo "=== (f) ordre d'initiation ==="
write_order() {
  # $1 file, $2 type, $3 name, $4 git, $5 vault_id, $6 authorization, $7 mode
  cat > "$1" <<ORDER
Session Executor — initiation ($3)

Ordre d'initiation
- Type : $2
- Mode : ${7:-answered}
- Nom : $3
- Emplacement : $WS
- Vault + construction : vault_id=$5, vault_origin=$V, vault_ref=$VREF
- Git : $4
- Objet : essai d'initiation (Mission 184)
- Autorisation Owner datée : $6
ORDER
}
AUTH="Je suis l'Owner et j'ordonne l'initiation, 2026-09-17"
mkdir -p "$WS/vide" "$WS/existant-git" "$WS/existant-sans-git"
printf '# E\n' > "$WS/existant-git/a.md"
(cd "$WS/existant-git" && (git init -q -b main 2>/dev/null || git init -q) && git add -A >/dev/null 2>&1 && git_quiet commit -q -m e)
printf '# S\n' > "$WS/existant-sans-git/b.md"
for spec in "vide:none" "existant-git:git" "existant-sans-git:none"; do
  name="${spec%%:*}"
  vcs="${spec#*:}"
  write_order "$TMP/order-$name.md" adopt "$name" "$vcs" "$VID" "$AUTH"
  bash "$BOOT" --order "$TMP/order-$name.md" FR >/dev/null 2>&1
  check "(f) ordre sur « $name » rend 0" [ "$?" = "0" ]
  check "(f) « $name » adopte sans Mission : acte et registre ($vcs)" sh -c "grep -qx '# vcs: $vcs' '$WS/$name/.pre-commit-config.yaml' && grep -qF '| $name | $vcs |' '$REGISTRY'"
done
check "(f) « existant-git » : fichiers existants modifies 0" no_modified "$WS/existant-git"

printf 'demande\n\n\n' > "$TMP/answers-ask.txt"
write_order "$TMP/order-ask.md" create "propose" none "$VID" "$AUTH" ask
bash "$BOOT" --order "$TMP/order-ask.md" FR < "$TMP/answers-ask.txt" >/dev/null 2>&1
check "(f) Mode ask : le nom repondu remplace le nom propose" sh -c "[ -d '$WS/demande' ] && [ ! -e '$WS/propose' ]"

mkdir -p "$WS/inconnu"
printf 'x\n' > "$WS/inconnu/f.txt"
REG_BEFORE="$(sha_of "$REGISTRY")"
LIST_BEFORE="$(cd "$WS/inconnu" && ls -A | tr '\n' ' ')"
OUT_F="$(bash "$BOOT" order "$WS/inconnu" FR 2>&1)"
check "(f) sans ordre : rc 0" [ "$?" = "0" ]
case "$OUT_F" in *"Ordre d'initiation"*"- Type : adopt"*"vault_id=$VID"*"Autorisation Owner datée"*) r=0 ;; *) r=1 ;; esac
check "(f) sans ordre : ordre a remplir rendu, pre-rempli" [ "$r" = "0" ]
check "(f) sans ordre : rien d'ecrit (dossier et registre inchanges)" sh -c "[ '$LIST_BEFORE' = \"\$(cd '$WS/inconnu' && ls -A | tr '\n' ' ')\" ] && [ '$REG_BEFORE' = \"\$1\" ]" _ "$(sha_of "$REGISTRY")"

write_order "$TMP/order-bad-vault.md" adopt inconnu none "sb-0000000000000000" "$AUTH"
bash "$BOOT" --order "$TMP/order-bad-vault.md" >/dev/null 2>&1
check "(f) temoin : ordre nommant un autre Vault -> refus" [ "$?" = "1" ]
write_order "$TMP/order-no-date.md" adopt inconnu none "$VID" "Je suis l'Owner, sans date"
bash "$BOOT" --order "$TMP/order-no-date.md" >/dev/null 2>&1
check "(f) temoin : ordre sans autorisation datee -> refus" [ "$?" = "1" ]
check "(f) temoins : registre toujours inchange, dossier non adopte" sh -c "[ '$REG_BEFORE' = \"\$1\" ] && [ ! -e '$WS/inconnu/.pre-commit-config.yaml' ]" _ "$(sha_of "$REGISTRY")"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS, $SKIPS SKIP) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS, $SKIPS SKIP) ==="
exit 1
