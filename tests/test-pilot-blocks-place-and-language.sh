#!/usr/bin/env bash
# Mission 244 (capture 121525, findings 8, 9, 10, 16, 20-24, 26): clear Pilots --
# in the Owner's language and place by place.
#
# Oracle, on the templates of the working tree and a throwaway workspace:
#   (1) the welcome block: a first message with no language gets the recorded
#       language, rendered by `accueil-prompt` (« français (fr) » for a Vault that
#       records fr); the workspace is in the block, any first message opens;
#   (2) every instruction starts with its place (« Dans le terminal »,
#       « Dans le Pilot », « Dans l'Executor »); a verb in the form of its host;
#       the Executor announced before a mini-prompt, with the installation page;
#   (3) the orders: shown first in plain words, technical lines under « Pour
#       l'Executor », the path announced before the write, list_allowed_directories
#       read again (vault_ref), vault_origin read in VAULT-IDENTITY.md, _orders/
#       listed again before saying an order waits;
#   (4) the initiation mini-prompt names `sb new --order`, never
#       `tools/project-bootstrap.sh --order`; the profile one says the command
#       commits USER.md itself;
#   (5) the common trunk carries the same language and place rules, stays within
#       20 non-empty lines, names no product and no relay;
#   (6) no Pilot host that is not supported (ChatGPT) is proposed by the blocks
#       nor by project-bootstrap.sh's catalogue;
#   (7) skills/session-start/SKILL.md carries « Where to type what »; `sb help
#       start` gives each step its place, in three languages.
#
# usage: bash tests/test-pilot-blocks-place-and-language.sh [<source repo>]
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
check() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }
block() { tr -d '\r' < "$1" | awk '/<!-- PROMPT:BEGIN -->/ { f = 1; next } /<!-- PROMPT:END -->/ { f = 0 } f'; }
has() { printf '%s' "$1" | grep -qF -- "$2"; }

ACCUEIL="$SRC/templates/accueil-pilot-prompt-template.md"
TRUNK="$SRC/templates/session-opening-prompt-template.md"
A="$(block "$ACCUEIL")"
B="$(block "$TRUNK")"

echo "=== Mission 244 : des Pilots clairs ==="

check "(1) accueil : un premier message sans langue recoit la langue enregistree" has "$A" "a first message that carries no language (a path, a lone greeting) gets the recorded language, {{LANGUAGE}}"
check "(1) accueil : l'espace est dans le bloc, tout premier message ouvre" has "$A" "any first message opens the session"
check "(2) accueil : chaque consigne commence par son lieu" sh -c "printf '%s' \"\$1\" | grep -q 'Dans le terminal : ' && printf '%s' \"\$1\" | grep -q 'Dans le Pilot : ' && printf '%s' \"\$1\" | grep -q \"Dans l'Executor (<host>) : \"" _ "$A"
check "(2) accueil : un verbe sous la forme de son hote" has "$A" '`$sb <verb>` in Codex'
check "(2) accueil : l'Executor annonce, la page d'installation nommee" sh -c "printf '%s' \"\$1\" | grep -q 'goes to an Executor window' && printf '%s' \"\$1\" | grep -q 'docs/tutorials/install.md'" _ "$A"
check "(3) accueil : l'ordre montre en clair, lignes techniques sous « Pour l'Executor »" has "$A" "the technical lines grouped below under « Pour l'Executor »"
check "(3) accueil : chemin annonce avant l'ecriture, oui de l'Owner" has "$A" "announce the exact path in one line and write only after the Owner's yes"
check "(3) accueil : list_allowed_directories relu pour vault_ref" has "$A" 'call `list_allowed_directories` again and take the Vault commit it returns as `vault_ref`'
check "(3) accueil : vault_origin lu dans VAULT-IDENTITY.md" has "$A" '`vault_origin` in `{{VAULT}}/VAULT-IDENTITY.md`'
check "(3) accueil : _orders/ relu avant d'affirmer un ordre en attente" has "$A" "Never say an order is waiting without listing"
check "(4) mini-prompt d'initiation : sb new --order" has "$A" ": sb new --order <path of the order>"
check "(4) plus de tools/project-bootstrap.sh --order dans le bloc" sh -c "! printf '%s' \"\$1\" | grep -q 'project-bootstrap.sh --order'" _ "$A"
check "(4) mini-prompt de profil : la commande commite USER.md" has "$A" 'The command commits `USER.md` alone itself.'
check "(5) tronc commun : regle de langue d'un premier message sans langue" has "$B" "a first message that carries no language (the project's path alone) gets the language the PILOT-PROMPT records"
check "(5) tronc commun : regle de lieu" sh -c "printf '%s' \"\$1\" | grep -q 'Dans le terminal : ' && printf '%s' \"\$1\" | grep -q 'a mini-prompt goes to an Executor window'" _ "$B"
check "(5) tronc commun : 20 lignes non vides au plus" test "$(printf '%s\n' "$B" | grep -c .)" -le 20
check "(5) blocs : aucun produit nomme, aucun « relay » dans le tronc" sh -c "! printf '%s\n%s' \"\$1\" \"\$2\" | grep -qE 'Claude|desktop application|Project' && ! printf '%s' \"\$2\" | grep -qi relay" _ "$A" "$B"
check "(6) aucun ChatGPT propose comme hote du Pilot (blocs, catalogues de l'amorcage)" sh -c "
  ! printf '%s\n%s' \"\$1\" \"\$2\" | grep -qi chatgpt &&
  ! grep -h '\"projectBootstrap\\.' '$SRC/i18n/catalog.fr.json' '$SRC/i18n/catalog.en.json' '$SRC/i18n/catalog.es.json' | grep -qi chatgpt" _ "$A" "$B"
check "(7) session-start : « Where to type what »" grep -q '^\*\*Where to type what\*\*' "$SRC/skills/session-start/SKILL.md"

# --- The rendering, on a throwaway workspace ------------------------------------------
sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m244-blocks-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"
mkdir -p "$WS"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
printf 'language: fr\n' > "$V/USER.local.yaml"
OUT="$(bash "$V/tools/project-bootstrap.sh" accueil-prompt 2>&1)"
check "(1) accueil-prompt rend la langue enregistree : français (fr)" has "$OUT" "gets the recorded language, français (fr)."
check "(1) accueil-prompt : aucun marqueur {{…}} laisse" sh -c "! printf '%s' \"\$1\" | grep -q '{{'" _ "$OUT"
check "(1) accueil-prompt : 3e geste, ecrire bonjour" has "$OUT" "3. Dans une conversation de ce Project : écris « bonjour »"
for lang in fr en es; do
  OUT="$(cd "$WS" && "$V/tools/sb/bin/sb" help start --lang "$lang" 2>&1)"
  N="$(printf '%s\n' "$OUT" | grep -cE '(Dans le terminal|Dans le Pilot|Dans l.Executor|In the terminal|In the Pilot|In the Executor|En la terminal|En el Pilot|En el Executor)')"
  check "(7) sb help start --lang $lang : chaque etape par son lieu ($N lignes)" test "$N" -ge 10
done

echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" -eq 0 ]
