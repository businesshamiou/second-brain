#!/usr/bin/env bash
# Mission 244 (capture 121525, findings 29-33): the close starts in the Pilot
# and ends in every situation.
#
# Oracle, on a throwaway workspace built from the working tree (a pre-commit
# stand-in: the guardians are not the subject):
#   (1) `close` is « Pilot: yes » in its source and in docs/reference/commands.md;
#       generated files match their source; the how-to carries the seven
#       situations, and no longer contradicts the reference;
#   (2) a project just created: `sb close` measures a light close; `--light`
#       writes one STATE: line, regenerates the sheet and the digest, commits
#       those three files alone (no handoff, no Note), porcelain 0;
#       tools/check-session-close.sh accepts such a commit;
#   (3) a Mission filed since the last STATE: line: a full close, and without a
#       handoff the Owner's gesture in plain words (the project's Pilot);
#       `--light` refuses and writes nothing;
#   (4) a handoff filed: its name, and its closing command to apply;
#   (5) the welcome session: `sb close --accueil` at the workspace root lists
#       the orders waiting and those applied today, and says no handoff;
#   (6) push: the distribution remote of an installed Vault is no hole; the
#       laboratory (a `release` remote) and an Owner's remote ahead keep it;
#   (7) Mission 245 (capture 105405, finding A5): a project with no remote --
#       `sb close` says « no remote, no push to plan » and no push hole; the
#       closing checklist and the Pilot contract (copied into the generated
#       sheet) open a push door only on a pasted « push hole » line, never from
#       a state-sheet snapshot: push doors expected 0.
#
# usage: bash tests/test-sb-close-situations.sh [<source repo>]
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
has() { printf '%s' "$1" | grep -q -- "$2"; }

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m244-close-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"
mkdir -p "$WS" "$TMP/bin"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
printf '#!/usr/bin/env bash\n[ "$1" = install ] || exit 0\nh="$(git rev-parse --git-path hooks)"; mkdir -p "$h"\nprintf "#!/usr/bin/env bash\\nexit 0\\n" > "$h/pre-commit"; chmod +x "$h/pre-commit"\n' > "$TMP/bin/pre-commit"
chmod +x "$TMP/bin/pre-commit"
export PATH="$TMP/bin:$PATH"
export SB_LANG=en
SB="$V/tools/sb/bin/sb"

echo "=== Mission 244 : les situations de cloture ($SRC) ==="

# --- (1) the source, the reference, the how-to ------------------------------------
check "(1) verbs.json : close pilot true" sh -c "uv run --no-project python -c \"import json,sys; v=[x for x in json.load(open(sys.argv[1],encoding='utf-8'))['verbs'] if x['verb']=='close'][0]; sys.exit(0 if v['pilot'] is True else 1)\" '$(sandbox_native_path "$V/tools/sb/verbs.json")'"
check "(1) commands.md : sb close, Pilot: yes" sh -c "awk '/^### sb close\$/{f=1;next} f&&/^### /{exit} f' '$V/docs/reference/commands.md' | grep -q 'Pilot: yes'"
check "(1) fichiers generes conformes a leur source" sh -c "cd '$V' && uv run --no-project python tools/sb/sb.py generate --check"
HOWTO="$V/docs/how-to/close-a-session.md"
check "(1) le how-to porte les sept situations" sh -c "
  for s in 'Welcome session' 'Project just created' 'Pilot session that produced nothing' 'Normal work session' 'distribution repository' 'remote of yours' 'Executor alone'; do
    grep -q \"\$s\" '$HOWTO' || { echo \"absent : \$s\"; exit 1; }
  done"
check "(1) la skill porte la clôture légère et le tableau" sh -c "grep -q 'Light close' '$V/skills/session-close/SKILL.md' && grep -q '| Welcome session' '$V/skills/session-close/SKILL.md'"

# --- (2) a project just created: light close ---------------------------------------
bash "$V/tools/project-bootstrap.sh" create "$WS/demo" "Demo" EN --vcs git >/dev/null 2>&1
P="$WS/demo"
check "(2) projet cree et commite par l'outil" sh -c "git -C '$P' rev-parse --verify -q HEAD && [ \"\$(git -C '$P' status --porcelain | grep -c .)\" = 0 ]"
OUT="$(cd "$P" && "$SB" close 2>&1)"; RC=$?
check "(2) sb close : exit 0, clôture légère mesuree" sh -c "[ '$RC' = 0 ] && printf '%s' \"\$1\" | grep -q 'Situation: light close'" _ "$OUT"
check "(2) sb close : la commande --light nommee, par son lieu" has "$OUT" "In the Executor: « sb close --light »"
BEFORE="$(git -C "$P" rev-list --count HEAD)"
OUT="$(cd "$P" && "$SB" close --light 2>&1)"; RC=$?
check "(2) --light : exit 0, un commit" sh -c "[ '$RC' = 0 ] && [ \"\$(git -C '$P' rev-list --count HEAD)\" = $((BEFORE + 1)) ]"
check "(2) --light : le commit porte les trois fichiers d'etat, seuls" sh -c "[ \"\$(git -C '$P' show --name-only --format= HEAD | sort | tr '\n' ' ')\" = 'state/DIGEST.md state/STATE.md state/journal.md ' ]"
check "(2) --light : une ligne STATE: de cloture legere, porcelain 0" sh -c "tail -n 1 '$P/state/journal.md' | grep -q 'STATE: light close' && [ \"\$(git -C '$P' status --porcelain | grep -c .)\" = 0 ]"
check "(2) --light : aucun handoff, aucune Note d'execution" sh -c "! ls '$P/handoffs' | grep -q HANDOFF && ! ls '$P/missions' | grep -q '^NOTE-'"
# The guardian on the same shape of commit, staged by hand.
bash "$V/tools/append-journal.sh" "$P" "STATE: light close -- guardian check" >/dev/null 2>&1
bash "$V/tools/build-state.sh" "$P" >/dev/null 2>&1
bash "$V/tools/build-digest.sh" "$P" >/dev/null 2>&1
git -C "$P" add state/journal.md state/STATE.md state/DIGEST.md
check "(2) check-session-close.sh accepte une cloture legere" sh -c "cd '$P' && bash '$V/tools/check-session-close.sh'"
git -C "$P" commit -q -m "light close again" >/dev/null 2>&1

# --- (3) a Mission filed since: full close, no handoff -----------------------------------
STAMP="$(date +%Y-%m-%d-%H%M%S)"
sleep 1
M="$P/missions/MISSION-$(date -d '+1 minute' +%Y-%m-%d-%H%M%S 2>/dev/null || date +%Y-%m-%d-%H%M%S)-001-essai.md"
printf -- '---\ntype: mission\nmission_id: "001"\n---\n\n# M\n\n## Liens\n' > "$M"
OUT="$(cd "$P" && "$SB" close 2>&1)"
check "(3) une Mission deposee : clôture complete, la piece nommee" sh -c "printf '%s' \"\$1\" | grep -q 'Situation: full close' && printf '%s' \"\$1\" | grep -q 'missions/MISSION-'" _ "$OUT"
check "(3) sans handoff : le geste de l'Owner en clair, dans le Pilot" has "$OUT" "In the project's Pilot: write « sb close »"
HEAD_BEFORE="$(git -C "$P" rev-parse HEAD)"
OUT="$(cd "$P" && "$SB" close --light 2>&1)"; RC=$?
check "(3) --light refuse : exit 1, rien d'ecrit" sh -c "[ '$RC' = 1 ] && [ \"\$(git -C '$P' rev-parse HEAD)\" = '$HEAD_BEFORE' ] && printf '%s' \"\$1\" | grep -q 'not a light close'" _ "$OUT"

# --- (4) a handoff filed ------------------------------------------------------------
H="HANDOFF-$(date +%Y-%m-%d-%H%M%S)-fin.md"
sleep 1
H="HANDOFF-$(date -d '+2 minutes' +%Y-%m-%d-%H%M%S 2>/dev/null || date +%Y-%m-%d-%H%M%S)-fin.md"
printf -- '---\ntype: handoff\ncreated_at: "2026-09-30T12:00:00-04:00"\n---\n\n# H\n\n## Liens\n' > "$P/handoffs/$H"
OUT="$(cd "$P" && "$SB" close 2>&1)"
check "(4) un handoff depose : nomme, sa commande de cloture a appliquer" sh -c "printf '%s' \"\$1\" | grep -q \"Handoff present: handoffs/$H\" && printf '%s' \"\$1\" | grep -q 'Executor closing command'" _ "$OUT"

# --- (7) Mission 245: no remote, no push door ---------------------------------------------
OUT="$(cd "$P" && "$SB" close 2>&1)"
check "(7) projet sans distant : « no remote, no push to plan », aucun trou push" sh -c "printf '%s' \"\$1\" | grep -q 'no remote, no push to plan' && ! printf '%s' \"\$1\" | grep -q 'push hole'" _ "$OUT"
check "(7) liste des trous : porte push seulement sur une ligne « push hole » collee" \
  grep -qF 'the Pilot opens a push door only when the `sb close` output the Owner pasted carries a push-hole line' "$V/skills/session-close/closing-checklist.md"
check "(7) contrat du Pilot (gabarit et fiche generee) : jamais de porte push depuis la fiche" sh -c "
  grep -qF 'a push door only when the \`sb close\` output the Owner pasted names a push hole, never from this sheet' '$V/templates/pilot-contract-template.md' &&
  grep -qF 'a push door only when the \`sb close\` output the Owner pasted names a push hole' '$P/state/STATE.md'"

# --- (5) the welcome session -----------------------------------------------------------
mkdir -p "$WS/_orders" "$WS/_archive/orders"
echo "ordre" > "$WS/_orders/ORDER-2026-09-30-101500-idee.md"
echo "profil" > "$WS/_archive/orders/PROFILE-$(date +%Y-%m-%d)-091500.md"
echo "ancien" > "$WS/_archive/orders/PROFILE-2020-01-01-091500.md"
OUT="$(cd "$WS" && "$SB" close --accueil 2>&1)"; RC=$?
check "(5) sb close --accueil a la racine : exit 0" test "$RC" = 0
check "(5) un ordre en attente, un applique aujourd'hui (l'ancien non compte)" sh -c "printf '%s' \"\$1\" | grep -q 'waiting for an Executor (_orders/): 1' && printf '%s' \"\$1\" | grep -q 'applied today (_archive/orders/): 1'" _ "$OUT"
check "(5) aucun handoff, l'idee orale proposee en ordre" sh -c "printf '%s' \"\$1\" | grep -q 'hence no handoff' && printf '%s' \"\$1\" | grep -q 'initiation order'" _ "$OUT"
OUT="$(cd "$WS" && "$SB" close 2>&1)"; RC=$?
check "(5) sb close sans --accueil a la racine : exit 3" test "$RC" = 3

# --- (6) push: distribution, laboratory, Owner's remote -----------------------------------
ORIGIN="$(bash "$V/tools/vault-identity.sh" get vault_origin "$V")"
git -C "$V" add -A >/dev/null 2>&1; git -C "$V" commit -q -m "sandbox state" >/dev/null 2>&1
git -C "$V" remote add origin "$ORIGIN"
git -C "$V" update-ref refs/remotes/origin/main "$(git -C "$V" rev-parse HEAD~1)"
git -C "$V" config branch.main.remote origin
git -C "$V" config branch.main.merge refs/heads/main
OUT="$(cd "$V" && "$SB" close 2>&1)"
check "(6) Vault installe, origin = vault_origin : distant de distribution, aucun trou" sh -c "printf '%s' \"\$1\" | grep -q 'distribution repository it was installed from' && ! printf '%s' \"\$1\" | grep -q 'ahead of your remote'" _ "$OUT"
git -C "$V" remote add release "https://example.invalid/second-brain.git"
OUT="$(cd "$V" && "$SB" close 2>&1)"
check "(6) laboratoire (distant release) : le trou « push » reste" sh -c "printf '%s' \"\$1\" | grep -q 'ahead of your remote' && printf '%s' \"\$1\" | grep -q 'push hole'" _ "$OUT"
git -C "$V" remote remove release
git -C "$V" remote set-url origin "https://example.invalid/owner/vault.git"
OUT="$(cd "$V" && "$SB" close 2>&1)"
check "(6) un distant de l'Owner en avance : trou « push »" has "$OUT" "push hole"

echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" -eq 0 ]
