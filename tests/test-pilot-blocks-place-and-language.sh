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
#       start` gives each step its place, in three languages;
#   (8) Mission 245 (capture 105405, finding A2) -- one format for the
#       Executor: in every source of a block pasted into an Executor (the two
#       Pilot blocks, the Pilot contract, the order and handoff templates, the
#       session-start and session-close skills and checklist, the close how-to,
#       the cards of verbs.json), 0 plugin form `/sb:` and 0 Codex form `$sb`
#       (10 before); every light closing command handed to the Executor
#       carries its order sentence « You are the Executor. … » (4 without
#       before); both blocks name the order sentence;
#   (9) Mission 245 (capture 105405, finding C4): the welcome block names the
#       Executor instead of a page of the documentation -- the Code tab of the
#       Claude app by default, then Claude Code CLI and Codex with this
#       system's installation lines, rendered in the recorded language (0
#       options before, 3 after); `sb help start` says the same, in three
#       languages.
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
check "(2) accueil : un verbe en clair, sb <verb>" has "$A" 'A verb is given as `sb <verb>`.'
check "(2) accueil : l'Executor annonce et nomme (Mission 245 : ses options, rendues)" sh -c "printf '%s' \"\$1\" | grep -q 'goes to an Executor window' && printf '%s' \"\$1\" | grep -q '{{EXECUTOR_OPTIONS}}'" _ "$A"
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

# --- (8) Mission 245: one format for the Executor -----------------------------------
EXEC_SOURCES="templates/accueil-pilot-prompt-template.md templates/session-opening-prompt-template.md
templates/pilot-contract-template.md templates/initiation-order-template.md templates/handoff-template.md
templates/profile-order-template.md skills/session-start/SKILL.md skills/session-start/reading-list.md
skills/session-close/SKILL.md skills/session-close/closing-checklist.md docs/how-to/close-a-session.md
tools/sb/verbs.json tools/project-bootstrap.sh"
N1=0
for f in $EXEC_SOURCES; do
  n="$(tr -d '\r' < "$SRC/$f" | grep -o '/sb:\|\$sb' | wc -l | tr -d ' ')"
  [ "$n" = 0 ] || echo "    $f : $n forme(s) /sb: ou \$sb"
  N1=$((N1 + n))
done
check "(8) sources de blocs Executor : 0 forme /sb: ou \$sb ($N1)" test "$N1" = 0
N2=0
for f in skills/session-close/SKILL.md tools/sb/verbs.json docs/how-to/close-a-session.md; do
  n="$(tr -d '\r' < "$SRC/$f" | grep -E '(hand|return)s? the light closing' | grep -vc 'You are the Executor. In <project folder>, run: sb close --light. Show the output as it is.')"
  [ "$n" = 0 ] || echo "    $f : $n commande(s) de cloture legere sans phrase d'ordre"
  N2=$((N2 + n))
done
check "(8) commande de cloture legere remise avec sa phrase d'ordre ($N2 sans)" test "$N2" = 0
check "(8) les deux blocs nomment la phrase d'ordre" sh -c "printf '%s' \"\$1\" | grep -q 'You are the Executor. In <folder>, run: sb <verb> <arguments>. Show the output as it is.' && printf '%s' \"\$2\" | grep -q 'You are the Executor. In <folder>, run: sb <verb> <arguments>. Show the output as it is.'" _ "$A" "$B"

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
# Mission 245 (capture 105405, finding C4): the three Executor options named in
# the rendered block -- the Code tab, then each command-line agent by its
# installation line -- in the recorded language (0 before, 3 after).
N_OPT=0
for opt in "l'onglet Code de l'application Claude" "claude.ai/install" "chatgpt.com/codex/install"; do
  has "$OUT" "$opt" && N_OPT=$((N_OPT + 1))
done
check "(9) accueil-prompt : les trois options d'Executor nommees ($N_OPT/3), en francais" test "$N_OPT" = 3
check "(9) accueil-prompt : plus de renvoi a la page d'installation" sh -c "! printf '%s' \"\$1\" | grep -q 'docs/tutorials/install.md'" _ "$OUT"
for lang in fr en es; do
  OUT="$(cd "$WS" && "$V/tools/sb/bin/sb" help start --lang "$lang" 2>&1)"
  N="$(printf '%s\n' "$OUT" | grep -cE '(Dans le terminal|Dans le Pilot|Dans l.Executor|In the terminal|In the Pilot|In the Executor|En la terminal|En el Pilot|En el Executor)')"
  check "(7) sb help start --lang $lang : chaque etape par son lieu ($N lignes)" test "$N" -ge 10
  check "(9) sb help start --lang $lang : l'onglet Code puis les deux options" sh -c "printf '%s' \"\$1\" | grep -qE 'Code tab|onglet Code|pestaña Code' && printf '%s' \"\$1\" | grep -q 'Claude Code CLI' && printf '%s' \"\$1\" | grep -q 'chatgpt.com/codex/install'" _ "$OUT"
done

echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" -eq 0 ]
