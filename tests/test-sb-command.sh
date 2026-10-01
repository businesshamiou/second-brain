#!/usr/bin/env bash
# Mission 236: the sb command (rules/RULES-2026-09-26-200933-sb-command-surface.md).
#
# Oracle, on a throwaway workspace built from the working tree:
#   (1) sb --version answers; sb, sb help, sb help <verb> and the three guides
#       answer in French, English and Spanish, with no catalogue key left raw;
#   (2) every verb gives its nominal output in its place (exit 0, or the exit
#       code its usage calls for);
#   (3) every verb that has a place refuses elsewhere with exit 3 and names
#       where to go; an unknown verb is exit 2; publish outside the laboratory
#       is exit 4;
#   (4) sb install --path / sb uninstall --path add and remove one PATH entry
#       (simulated file, SB_PATH_TEST_FILE, like the installers' test mode);
#   (5) no collision: no native command of tools/sb/native-commands.tsv is
#       named sb nor starts with sb:, and no /sb:<verb> is native;
#   (6) the generated files (reference, card, plugin) match their source;
#       the plugin has one user-only skill per verb;
#   (7) the Codex skill budget stays under 8000; no skill keeps a French name;
#   (8) negative control: a copy of the native list with a /sb:status line is
#       caught;
#   (9) Mission 237: `sb install` runs its three steps, each once (a stub
#       claude, a throwaway plugins folder -- never the real profile); doctor
#       tells "no marketplace", "no plugin", "installed", "older copy";
#       paths in the terminal's form (Windows); `sb clean --purge-temp` empties
#       a THROWAWAY temporary root only with --yes, never _trash; doctor names
#       the root's gap.
#  (10) Mission 241: `sb help start` carries, in the three languages, the step
#       of the welcome Pilot (`sb pilot-prompt --accueil`, `SB - Accueil`) and
#       ten numbered steps; `sb pilot-prompt --accueil` (and `accueil`) prints
#       the welcome block anywhere in the workspace, in the three languages,
#       and, since Mission 244, outside any workspace too (its own Vault's
#       workspace, said in one line); an extra argument is exit 2;
#       the card and the reference cite the help pages; the plugin's
#       pilot-prompt skill names --accueil; the Codex budget keeps a margin of
#       at least 500 and doctor says it; under Windows, doctor run with no
#       bash on the PATH says so with the form to type, and stays non-blocking.
#  (11) Mission 242: `sb pilot-prompt --host <host>`, for the project's block
#       and the welcome block, prints between its two lines the same bytes for
#       every Pilot host (cmp), then that host's steps with its state; an
#       unknown host is exit 2; ChatGPT is exit 2 with the reason; `sb help
#       start` and the steps of pilot-prompt name no product for the role
#       (outside a host's own section).
#
# usage: bash tests/test-sb-command.sh [<source repo>]
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
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m236-sb-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"
mkdir -p "$WS" "$TMP/outside"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit depuis $SRC"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
SB="$V/tools/sb/bin/sb"
# Door open-238-sb-test-doctor-reads-real-path (Mission 244): the machine's own
# `sb` (put on the PATH by `sb install`) is taken out of this test's PATH --
# `sb doctor` of the throwaway Vault read it and said FAIL « another sb ».
PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v 'tools/sb/bin' | paste -sd: -)"
export PATH
export SB_LANG=en
# Nothing of this test reaches the real profile: a simulated PATH file, a stub
# claude and a throwaway plugins folder (Mission 237).
export SB_PATH_TEST_FILE="$TMP/simulated-path.txt"
export SB_CLAUDE_PLUGINS_DIR="$TMP/plugins"
export SB_CLAUDE="$TMP/claude-stub.py"
export SB_MCP_INSTALLER="$TMP/mcp-stub.sh"
printf '#!/usr/bin/env bash\necho "mcp $*" >> "%s/mcp-calls.log"\necho "MCP stub: server declared"\n' "$TMP" > "$SB_MCP_INSTALLER"
cat > "$SB_CLAUDE" <<'STUB'
import json, os, shutil, sys
d = os.environ["SB_CLAUDE_PLUGINS_DIR"]
os.makedirs(d, exist_ok=True)
with open(os.path.join(d, "calls.log"), "a") as f:
    f.write(" ".join(sys.argv[1:]) + "\n")
a = sys.argv[1:]
known = os.path.join(d, "known_marketplaces.json")
inst = os.path.join(d, "installed_plugins.json")
if a[:3] == ["plugin", "marketplace", "add"]:
    json.dump({"second-brain": {"source": {"source": "directory", "path": a[3]}, "installLocation": a[3]}}, open(known, "w"))
elif a[:2] == ["plugin", "install"]:
    src = json.load(open(known))["second-brain"]["source"]["path"]
    cache = os.path.join(d, "cache", "sb")
    shutil.rmtree(cache, ignore_errors=True)
    shutil.copytree(os.path.join(src, "sb"), cache)
    json.dump({"version": 2, "plugins": {"sb@second-brain": [{"scope": "user", "installPath": cache}]}}, open(inst, "w"))
elif a[:2] == ["plugin", "uninstall"]:
    json.dump({"version": 2, "plugins": {}}, open(inst, "w"))
STUB

bash "$V/tools/project-bootstrap.sh" create "$WS/proj-one" "Proj One" EN --vcs git >/dev/null 2>&1 \
  || { echo "FAIL : projet jetable non cree"; exit 1; }
mkdir -p "$WS/loose" "$WS/stray"
P="$WS/proj-one"

# run <folder> <args...>: OUT, RC.
run() { local d="$1"; shift; OUT="$(cd "$d" && "$SB" "$@" 2>&1)"; RC=$?; }
expect() { # expect <label> <expected rc> <folder> <args...>
  local label="$1" want="$2"; shift 2
  run "$@"
  if [ "$RC" -eq "$want" ]; then pass "$label (exit $RC)"
  else fail "$label: exit $RC, attendu $want -- $(printf '%s' "$OUT" | tail -2 | tr '\n' ' ')"; fi
}

VERBS="$(uv run --no-project python -c "import json,sys; print(' '.join(v['verb'] for v in json.load(open(sys.argv[1],encoding='utf-8'))['verbs']))" "$(sandbox_native_path "$V/tools/sb/verbs.json")")"
N_VERBS="$(printf '%s\n' $VERBS | wc -l | tr -d ' ')"

echo "=== Mission 236 : la commande sb ($N_VERBS verbes, $SRC) ==="

echo "--- (1) version et aide, trois langues ---"
expect "(1a) sb --version" 0 "$WS" --version
for lang in fr en es; do
  run "$WS" help --lang "$lang"
  missing=""
  for v in $VERBS; do printf '%s' "$OUT" | grep -qE "^  $v( |$)" || missing="$missing $v"; done
  if [ "$RC" -eq 0 ] && [ -z "$missing" ] && ! printf '%s' "$OUT" | grep -qE 'sb\.(verb|home|group|label)\.'; then
    pass "(1b) sb help --lang $lang : les $N_VERBS verbes, aucune clef brute"
  else
    fail "(1b) sb help --lang $lang : rc=$RC, absents :$missing"
  fi
  raw=""
  for v in $VERBS; do
    run "$WS" help "$v" --lang "$lang"
    if [ "$RC" -ne 0 ] || printf '%s' "$OUT" | grep -qE 'sb\.[a-zA-Z]+\.[a-zA-Z]'; then raw="$raw $v"; fi
  done
  [ -z "$raw" ] && pass "(1c) sb help <verbe> --lang $lang : $N_VERBS pages completes" \
    || fail "(1c) sb help <verbe> --lang $lang : pages en defaut :$raw"
  bad=""
  for t in start concepts scenarios; do
    run "$WS" help "$t" --lang "$lang"
    { [ "$RC" -eq 0 ] && ! printf '%s' "$OUT" | grep -qE 'sb\.topic\.'; } || bad="$bad $t"
  done
  [ -z "$bad" ] && pass "(1d) sb help start|concepts|scenarios --lang $lang" || fail "(1d) guides en defaut ($lang) :$bad"
done
expect "(1e) sb (sans verbe) = accueil" 0 "$TMP/outside"

echo "--- (2) sortie nominale, a sa place ---"
expect "(2) status a la racine" 0 "$WS" status
expect "(2) status dans le projet" 0 "$P" status
expect "(2) list" 0 "$WS" list
printf '%s' "$OUT" | grep -q "Proj One" && pass "(2) list nomme le projet jetable" || fail "(2) list ne nomme pas Proj One"
expect "(2) open dans le projet" 0 "$P" open
expect "(2) open dans le Vault" 0 "$V" open
expect "(2) close dans le projet" 0 "$P" close
expect "(2) handoff dans le projet" 0 "$P" handoff demo
printf '%s' "$OUT" | grep -q "HANDOFF-[0-9-]*-demo.md" && pass "(2) handoff propose HANDOFF-<ts>-demo.md" || fail "(2) handoff : nom de fichier absent"
expect "(2) pilot-prompt dans le projet" 0 "$P" pilot-prompt
printf '%s' "$OUT" | grep -q "PROMPT\|You are the Pilot" && pass "(2) pilot-prompt rend le tronc commun" || fail "(2) pilot-prompt sans tronc commun"
expect "(2) mission dans le projet" 0 "$P" mission
mkdir -p "$P/missions" "$P/reports"
printf -- '---\ntype: mission\nmission_id: "001"\nstatus: AUTHORIZED\ntitle: "Demo"\n---\n\n# MISSION 001\n' > "$P/missions/MISSION-2026-09-26-120000-001-demo.md"
printf -- '---\ntype: report\n---\n\n# REPORT\n\n## RELAY\n\nRELAY 001 demo\n\n## Liens\n' > "$P/reports/REPORT-2026-09-26-130000-001-demo.md"
expect "(2) run 1 dans le projet" 0 "$P" run 1
printf '%s' "$OUT" | grep -q "MISSION-2026-09-26-120000-001-demo.md" && pass "(2) run trouve la Mission par son numero" || fail "(2) run : Mission non trouvee"
expect "(2) run 999 : Mission absente" 1 "$P" run 999
expect "(2) relay dans le projet" 0 "$P" relay
printf '%s' "$OUT" | grep -q "RELAY 001 demo" && pass "(2) relay imprime le bloc" || fail "(2) relay : bloc absent"
expect "(2) search" 0 "$WS" search session-start --limit 2
expect "(2) doctor dans le projet" 0 "$P" doctor
expect "(2) doctor explique un refus" 0 "$WS" doctor "preflight absent"
expect "(2) clean" 0 "$WS" clean
expect "(2) update sans version" 2 "$WS" update
expect "(2) install" 0 "$WS" install
expect "(2) uninstall" 0 "$WS" uninstall
expect "(2) add-skill sur skills/sb" 0 "$WS" add-skill "$V/skills/sb"
mkdir -p "$TMP/outside/Ecriture_Bad"; printf -- '---\nname: Ecriture_Bad\n---\n' > "$TMP/outside/Ecriture_Bad/SKILL.md"
expect "(2) add-skill refuse un nom hors forme" 1 "$WS" add-skill "$TMP/outside/Ecriture_Bad"
expect "(2) new sans argument" 2 "$WS" new
expect "(2) new cree un projet" 0 "$WS" new proj-two "Proj Two" --lang EN --vcs none
[ -f "$WS/proj-two/state/PILOT-PROMPT.md" ] && pass "(2) new : proj-two/state/PILOT-PROMPT.md ecrit" || fail "(2) new : prompt Pilot absent"
expect "(2) adopt d'un dossier non adopte" 0 "$WS/loose" adopt --vcs none
expect "(2) push --dry-run sans branche amont" 1 "$P" push --dry-run
expect "(2) publish hors laboratoire" 4 "$WS" publish --dry-run

echo "--- (3) refus hors lieu (exit 3), verbe inconnu (exit 2) ---"
for case in "open:$WS" "open:$WS/stray" "close:$WS" "handoff:$WS" "mission:$WS" "run:$WS" "relay:$WS" "pilot-prompt:$WS" \
            "adopt:$WS" "adopt:$V" "push:$TMP/outside" "status:$TMP/outside"; do
  verb="${case%%:*}"; dir="${case#*:}"
  run "$dir" "$verb"
  if [ "$verb" = "status" ]; then
    [ "$RC" -eq 0 ] && pass "(3) status repond partout (hors espace aussi)" || fail "(3) status hors espace : exit $RC"
    continue
  fi
  if [ "$RC" -eq 3 ] && printf '%s' "$OUT" | grep -q "→"; then
    pass "(3) $verb refuse dans $(basename "$dir") et nomme ou aller"
  else
    fail "(3) $verb dans $dir : exit $RC -- $(printf '%s' "$OUT" | head -1)"
  fi
done
# Mission 244 (finding 1): outside any workspace, a verb of the workspace is
# served in its own Vault's workspace (said in one line), no longer refused.
expect "(3) doctor hors espace : l'espace de son Vault" 0 "$TMP/outside" doctor
printf '%s' "$OUT" | grep -q "Outside any workspace: sb works in its Vault" && pass "(3) doctor hors espace : une ligne le dit" || fail "(3) doctor hors espace : ligne absente"
expect "(3) clean hors espace : l'espace de son Vault" 0 "$TMP/outside" clean
expect "(3) new hors espace, sans argument : l'usage (exit 2), plus un refus de lieu" 2 "$TMP/outside" new
expect "(3) verbe inconnu" 2 "$WS" frobnicate
expect "(3) new . (la racine) refuse" 3 "$WS" new . "Root"

echo "--- (4) PATH : ajout, idempotence, retrait (fichier simule) ---"
: > "$SB_PATH_TEST_FILE"
run "$WS" install --path; A1="$RC"; run "$WS" install --path; A2="$RC"
LINES="$(awk NF "$SB_PATH_TEST_FILE" 2>/dev/null | wc -l | tr -d " ")"
{ [ "$A1" -eq 0 ] && [ "$A2" -eq 0 ] && [ "$LINES" -eq 1 ] && grep -q "tools.sb.bin" "$SB_PATH_TEST_FILE"; } \
  && pass "(4) install --path : une entree tools/sb/bin, idempotente" || fail "(4) install --path : rc=$A1/$A2, $LINES ligne(s)"
run "$WS" uninstall --path
LINES="$(awk NF "$SB_PATH_TEST_FILE" 2>/dev/null | wc -l | tr -d " ")"
{ [ "$RC" -eq 0 ] && [ "$LINES" -eq 0 ]; } && pass "(4) uninstall --path retire l'entree" || fail "(4) uninstall --path : rc=$RC, $LINES ligne(s)"

echo "--- (5) collisions avec les commandes natives ---"
NATIVE="$V/tools/sb/native-commands.tsv"
collide() { # collide <tsv>: prints each colliding line
  grep -v '^#' "$1" | awk -F'\t' '$2 == "/sb" || $2 ~ /^\/sb:/ || ($1 != "npm" && $2 == "sb")'
  for v in $VERBS; do grep -v '^#' "$1" | awk -F'\t' -v c="/sb:$v" '$2 == c'; done
}
C="$(collide "$NATIVE")"
[ -z "$C" ] && pass "(5) aucune commande native nommee sb ni /sb:<verbe> ($(grep -vc '^#' "$NATIVE") lignes)" || fail "(5) collision : $C"
cp "$NATIVE" "$TMP/native-copy.tsv"; printf 'claude-code\t/sb:status\twitness\n' >> "$TMP/native-copy.tsv"
C="$(collide "$TMP/native-copy.tsv")"
printf '%s' "$C" | grep -q "/sb:status" && pass "(8) temoin : une ligne /sb:status ajoutee a une copie est attrapee" || fail "(8) temoin non attrape"

echo "--- (6) fichiers generes et plugin ---"
OUTG="$(cd "$SRC" && uv run --no-project python tools/sb/sb.py generate --check 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && pass "(6) generate --check : aucun fichier derive" || fail "(6) generate --check : $OUTG"
PLUG="$SRC/skills/claude-plugins/sb/skills"
bad=""
for v in $VERBS; do
  f="$PLUG/$v/SKILL.md"
  { [ -f "$f" ] && grep -q "^name: $v\$" "$f" && grep -q '^disable-model-invocation: true$' "$f"; } || bad="$bad $v"
done
N_PLUG="$(ls -1 "$PLUG" 2>/dev/null | wc -l | tr -d ' ')"
{ [ -z "$bad" ] && [ "$N_PLUG" -eq "$N_VERBS" ]; } && pass "(6) plugin : $N_PLUG skills /sb:<verbe>, reservees a l'utilisateur" \
  || fail "(6) plugin : $N_PLUG dossiers pour $N_VERBS verbes, en defaut :$bad"

echo "--- (9) Mission 237 : install, doctor, chemins, purge du temporaire ---"
rm -rf "$SB_CLAUDE_PLUGINS_DIR"
run "$P" doctor
printf '%s' "$OUT" | grep -q "marketplace not added" && pass "(9a) doctor : marketplace absente dite" || fail "(9a) doctor : $(printf '%s' "$OUT" | grep -i plugin)"
run "$WS" install
N1="$(wc -l < "$SB_CLAUDE_PLUGINS_DIR/calls.log" 2>/dev/null | tr -d ' ')"
{ [ "$RC" -eq 0 ] && [ "${N1:-0}" -eq 2 ] && printf '%s' "$OUT" | grep -q "^1\. " && printf '%s' "$OUT" | grep -q "^3\. .*done" \
    && printf '%s' "$OUT" | grep -q "^4\. .*done" && grep -q "^mcp " "$TMP/mcp-calls.log"; } \
  && pass "(9b) install : quatre etapes numerotees, marketplace, plugin, serveur MCP (installateur factice)" || fail "(9b) install : rc=$RC, $N1 appel(s) -- $OUT"
run "$WS" install
N2="$(wc -l < "$SB_CLAUDE_PLUGINS_DIR/calls.log" | tr -d ' ')"
{ [ "$RC" -eq 0 ] && [ "$N2" -eq "$N1" ] && [ "$(printf '%s' "$OUT" | grep -ci 'already')" -ge 3 ]; } \
  && pass "(9c) install relance : tout « already there », aucun appel de plus" || fail "(9c) relance : rc=$RC, $N1 -> $N2 appels"
run "$P" doctor
printf '%s' "$OUT" | grep -q "sb@second-brain installed" && pass "(9d) doctor : plugin installe dit" || fail "(9d) doctor : $(printf '%s' "$OUT" | grep -i plugin)"
printf '\nchanged\n' >> "$SB_CLAUDE_PLUGINS_DIR/cache/sb/skills/help/SKILL.md"
run "$P" doctor
printf '%s' "$OUT" | grep -q "older than the Vault" && pass "(9e) doctor : copie en retard dite" || fail "(9e) doctor : $(printf '%s' "$OUT" | grep -i plugin)"
run "$WS" install --plugin
{ [ "$RC" -eq 0 ] && grep -q "plugin uninstall" "$SB_CLAUDE_PLUGINS_DIR/calls.log" && ! grep -q changed "$SB_CLAUDE_PLUGINS_DIR/cache/sb/skills/help/SKILL.md"; } \
  && pass "(9f) install --plugin : copie en retard reinstallee" || fail "(9f) install --plugin : rc=$RC"
if [ "$(uname -s | cut -c1-5)" = "MINGW" ] || [ "$(uname -s | cut -c1-4)" = "MSYS" ]; then
  OUT="$(cd "$WS" && MSYSTEM=MINGW64 "$SB" status 2>&1)"
  printf '%s' "$OUT" | grep -qE '^  Workspace +/[a-z]/' && pass "(9g) Git Bash : chemins en /c/..." || fail "(9g) Git Bash : $(printf '%s' "$OUT" | grep Workspace)"
  # As a participant runs it: PowerShell, sb.cmd, no MSYSTEM (Git Bash, and uv
  # under it, export MSYSTEM again to their children).
  OUT="$(cd "$WS" && powershell.exe -NoProfile -Command "Remove-Item Env:MSYSTEM -ErrorAction SilentlyContinue; & '$(sandbox_native_path "$V/tools/sb/bin/sb.cmd")' status" 2>&1 | tr -d '\r')"
  printf '%s' "$OUT" | grep -qE '^  Workspace +[A-Z]:\\' && pass "(9g) PowerShell/cmd : chemins en C:\\..." || fail "(9g) hors Git Bash : $(printf '%s' "$OUT" | grep Workspace)"
fi
FAKE_TMP="$TMP/fake-sb-tmp"
mkdir -p "$FAKE_TMP/a/b" "$WS/_trash"; echo x > "$FAKE_TMP/a/b/f.txt"; echo y > "$FAKE_TMP/g.txt"; echo keep > "$WS/_trash/keep.txt"
OUT="$(cd "$WS" && SB_TMP="$FAKE_TMP" "$SB" clean --purge-temp < /dev/null 2>&1)"; RC=$?
{ [ "$RC" -eq 2 ] && [ -f "$FAKE_TMP/g.txt" ]; } && pass "(9h) --purge-temp sans terminal ni --yes : refus, rien supprime" || fail "(9h) sans --yes : rc=$RC"
OUT="$(cd "$WS" && SB_TMP="$FAKE_TMP" "$SB" clean --purge-temp --yes 2>&1)"; RC=$?
{ [ "$RC" -eq 0 ] && [ -d "$FAKE_TMP" ] && [ -z "$(ls -A "$FAKE_TMP")" ] && [ -f "$WS/_trash/keep.txt" ]; } \
  && pass "(9i) --purge-temp --yes : racine jetable videe, _trash intacte" || fail "(9i) --yes : rc=$RC, reste : $(ls -A "$FAKE_TMP" | tr '\n' ' ')"
OUT="$(cd "$WS" && SB_TMP="$WS/_trash" "$SB" clean --purge-temp --yes 2>&1)"; RC=$?
{ [ "$RC" -ne 0 ] && [ -f "$WS/_trash/keep.txt" ]; } && pass "(9j) --purge-temp refuse une corbeille de l'espace" || fail "(9j) corbeille : rc=$RC"
mkdir -p "$WS/stray-root-m237"
run "$P" doctor
printf '%s' "$OUT" | grep -q "stray-root-m237" && pass "(9k) doctor nomme l'ecart de racine" || fail "(9k) doctor : $(printf '%s' "$OUT" | grep -i 'root')"

echo "--- (10) Mission 241 : premiers pas, Pilot d'accueil sans bash, marge Codex ---"
for lang in fr en es; do
  run "$WS" help start --lang "$lang"
  { [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q "sb pilot-prompt --accueil" && printf '%s' "$OUT" | grep -q "SB - Accueil" \
      && printf '%s' "$OUT" | grep -qE '^  10\. ' && ! printf '%s' "$OUT" | grep -qE '^  11\. '; } \
    && pass "(10a) sb help start --lang $lang : etape SB - Accueil (sb pilot-prompt --accueil), dix etapes" \
    || fail "(10a) sb help start --lang $lang : rc=$RC -- $(printf '%s' "$OUT" | grep -E '^  [0-9]+\. ' | tr '\n' '|')"
  run "$WS" pilot-prompt --accueil --lang "$lang"
  { [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q "« SB - Accueil »" && printf '%s' "$OUT" | grep -q "You are the welcome Pilot" \
      && printf '%s' "$OUT" | grep -q "sb help start" && [ "$(printf '%s\n' "$OUT" | grep -c '^---$')" -eq 2 ]; } \
    && pass "(10b) pilot-prompt --accueil --lang $lang a la racine : le bloc d'accueil entre deux traits, etapes traduites" \
    || fail "(10b) pilot-prompt --accueil --lang $lang : rc=$RC -- $(printf '%s' "$OUT" | head -3 | tr '\n' ' ')"
done
run "$WS" help pilot-prompt --lang fr
printf '%s' "$OUT" | grep -q -- "--accueil : n'importe où dans ton espace de travail" && pass "(10c) sb help pilot-prompt : la place de --accueil dite" \
  || fail "(10c) sb help pilot-prompt : place de --accueil absente"
expect "(10d) pilot-prompt accueil (forme nue) dans un projet" 0 "$P" pilot-prompt accueil
printf '%s' "$OUT" | grep -q "You are the welcome Pilot" && pass "(10d) la forme nue rend le bloc d'accueil" || fail "(10d) forme nue sans bloc d'accueil"
expect "(10d) pilot-prompt --accueil dans le Vault" 0 "$V" pilot-prompt --accueil
expect "(10e) pilot-prompt --accueil hors de l'espace : servi dans l'espace de son Vault (Mission 244)" 0 "$TMP/outside" pilot-prompt --accueil
expect "(10e) pilot-prompt --accueil avec un argument de trop" 2 "$WS" pilot-prompt --accueil extra
expect "(10e) pilot-prompt (sans forme) reste refuse a la racine" 3 "$WS" pilot-prompt
{ grep -q '^## Help pages$' "$SRC/docs/reference/commands.md" && grep -q '^### sb help start$' "$SRC/docs/reference/commands.md" \
    && grep -q 'sb pilot-prompt --accueil' "$SRC/docs/reference/commands.md" \
    && grep -q '`sb help start`' "$SRC/docs/COMMANDS-CARD.md" && grep -q -- '--accueil' "$SRC/skills/claude-plugins/sb/skills/pilot-prompt/SKILL.md"; } \
  && pass "(10f) reference (Help pages), carte (sb help start) et skill pilot-prompt du plugin (--accueil)" \
  || fail "(10f) fichiers generes : Help pages, ligne de la carte ou --accueil absent"
run "$P" doctor
printf '%s' "$OUT" | grep -qE 'Codex skill budget +[0-9]+ / 8000 \(margin [0-9]+, at least 500\)' && pass "(10g) doctor dit le budget Codex et sa marge" \
  || fail "(10g) doctor : $(printf '%s' "$OUT" | grep -i codex)"
if [ "$(uname -s | cut -c1-5)" = "MINGW" ] || [ "$(uname -s | cut -c1-4)" = "MSYS" ]; then
  # PATH without Git's bin folders: uv and git (Git's cmd folder, /cmd) only,
  # as in a bare PowerShell. sb.py is started through uv, by their paths (the
  # bash launcher itself needs the tools of Git's usr/bin).
  UV_EXE="$(command -v uv)"
  OUT="$(cd "$P" && PATH="$(dirname "$UV_EXE"):/cmd:/c/Windows/System32:/c/Windows" "$UV_EXE" run --no-project --quiet python "$(sandbox_native_path "$V/tools/sb/sb.py")" doctor 2>&1)"; RC=$?
  { [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -qE '^  WARN  bash ' && printf '%s' "$OUT" | grep -q 'bash.exe"' \
      && printf '%s' "$OUT" | grep -q 'Nothing blocking'; } \
    && pass "(10h) Windows : doctor sans bash dans le PATH le dit (WARN, forme & \"...bash.exe\"), non bloquant" \
    || fail "(10h) doctor sans bash : rc=$RC -- $(printf '%s' "$OUT" | grep -iE 'bash|block' | tr '\n' ' ')"
  run "$P" doctor
  printf '%s' "$OUT" | grep -qE '^  OK    bash ' && pass "(10h) Windows : doctor avec bash dans le PATH : OK" || fail "(10h) doctor avec bash : $(printf '%s' "$OUT" | grep -i bash)"
fi

echo "--- (11) Mission 242 : un bloc, des etapes par hote ---"
block_of() { printf '%s\n' "$1" | tr -d '\r' | awk '/^---$/ { n++; next } n == 1'; }
for form in project accueil; do
  if [ "$form" = project ]; then DIR="$P"; ARGS="pilot-prompt"; else DIR="$WS"; ARGS="pilot-prompt --accueil"; fi
  REF=""; SAME=0; N=0
  for host in claude-desktop codex gemini cursor windsurf cline lmstudio; do
    run "$DIR" $ARGS --host "$host"
    [ "$RC" -eq 0 ] || { fail "(11) $form --host $host : exit $RC"; continue; }
    N=$((N + 1))
    printf '%s' "$(block_of "$OUT")" > "$TMP/block-$form-$host.txt"
    if [ -z "$REF" ]; then REF="$TMP/block-$form-$host.txt"; SAME=1
    elif cmp -s "$REF" "$TMP/block-$form-$host.txt"; then SAME=$((SAME + 1)); fi
  done
  { [ "$SAME" = 7 ] && [ -s "$REF" ]; } && pass "(11) $form : le bloc entre les traits identique octet pour octet pour les 7 hotes (cmp)" \
    || fail "(11) $form : $SAME/7 blocs identiques"
done
run "$WS" pilot-prompt --accueil --host gemini --lang en
{ printf '%s' "$OUT" | grep -q '^Gemini CLI — declared' && printf '%s' "$OUT" | grep -q 'approval-mode plan' \
    && printf '%s' "$OUT" | grep -q '^3\. First message: the block above'; } \
  && pass "(11) --host gemini : section de l'hote, etat declare, sans shell, bloc en premier message" \
  || fail "(11) --host gemini : $(printf '%s' "$OUT" | tail -5 | tr '\n' '|')"
run "$WS" pilot-prompt --accueil --host claude-desktop --lang en
printf '%s' "$OUT" | grep -q '^Claude Desktop — proven' && pass "(11) --host claude-desktop : etat prouve" || fail "(11) claude-desktop : $(printf '%s' "$OUT" | grep -i proven)"
expect "(11) --host inconnu" 2 "$WS" pilot-prompt --accueil --host frobnicator
expect "(11) --host chatgpt : non pris en charge" 2 "$WS" pilot-prompt --accueil --host chatgpt
printf '%s' "$OUT" | grep -q -i 'not supported today\|pas pris en charge\|no está soportado' && pass "(11) chatgpt : la raison est dite" || fail "(11) chatgpt : $OUT"
for lang in fr en es; do
  run "$WS" help start --lang "$lang"
  if printf '%s' "$OUT" | grep -qE 'Claude|Project|application de bureau|desktop app|aplicación de escritorio'; then
    fail "(11) help start --lang $lang nomme un produit : $(printf '%s' "$OUT" | grep -E 'Claude|Project' | head -1)"
  else pass "(11) help start --lang $lang : aucun produit nomme pour le role"; fi
done

echo "--- (7) budget Codex et noms des skills ---"
BUDGET="$(cd "$V" && uv run --no-project python -c "import sys; sys.path.insert(0,'tools'); import sb_installer_helper as h; d,e=h._method_skill_entries('.'); print(h._codex_budget(d,e)[0])")"
[ "${BUDGET:-99999}" -lt 8000 ] && pass "(7) budget Codex $BUDGET < 8000" || fail "(7) budget Codex $BUDGET"
[ "${BUDGET:-99999}" -le 7500 ] && pass "(10i) budget Codex $BUDGET <= 7500 : marge d'au moins 500 (Mission 241)" || fail "(10i) budget Codex $BUDGET > 7500"
FRENCH=""
for d in "$V"/skills/*/; do
  n="$(basename "$d")"
  case "$n" in ecriture-de-mission|recherche-interne|*[!a-z0-9-]*) FRENCH="$FRENCH $n" ;; esac
done
[ -z "$FRENCH" ] && pass "(7) aucune skill au nom francais ni hors forme" || fail "(7) noms en defaut :$FRENCH"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES, $PASSES PASS) ==="
exit 1
