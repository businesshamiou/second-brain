#!/usr/bin/env bash
# Mission 242: the Vault's MCP server in every host PRESENT, never in an absent
# one; a name too long for the hosts is refused before anything is written; the
# containment check and `sb doctor` read every host present
# (rules/RULES-2026-09-28-*-model-agnostic-pilot-and-executor-hosts.md).
#
# One throwaway Vault on a SIMULATED profile (HOME, USERPROFILE, APPDATA,
# LOCALAPPDATA redirected; `claude` and `codex` replaced by stand-ins at the head
# of the PATH), never the real profile:
#   (H1) the host table (tools/lib/mcp-hosts.sh) says present only what is
#        measured: a host folder makes its host present, none makes it absent;
#   (H2) name length guard: --label acmecorpworkshq (65 > 64) is refused, the
#        shorter label proposed, NOTHING written (identity, host files);
#        --label acmecorp (58) is accepted;
#   (H3) the five JSON hosts present (Gemini CLI, Cursor, Windsurf, Cline,
#        LM Studio) each receive the server under `mcpServers` at their own
#        path; Cursor's entry carries "type": "stdio"; a key already in the
#        file (another server, a setting) is kept;
#   (H4) a second run changes no file (byte for byte);
#   (H5) a profile with none of those folders: 0 file created for them, each
#        said "Not found";
#   (H6) check-mcp-containment.sh --all: one PASS per host present, ABSENT for
#        the others, VERDICT: PASS;
#   (H7) sb doctor: a "declared" line per host present, the absent hosts on one
#        line, still non-blocking; sb install --mcp --label passes the label
#        (the refusal and its proposal relayed) and answers in the reader's
#        language (French last line).
#
# usage: bash tests/test-mcp-hosts-agnostic.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
REAL_HOME="$HOME"
UV_PYTHON_INSTALL_DIR="$(uv python dir 2>/dev/null | tr -d '\r')"
UV_CACHE_DIR="$(uv cache dir 2>/dev/null | tr -d '\r')"
export UV_PYTHON_INSTALL_DIR UV_CACHE_DIR
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m242-hosts-XXXXXX")"
trap 'export HOME="$REAL_HOME"; [ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
N() { sandbox_native_path "$1"; }
sha_of() { if [ -f "$1" ]; then sha256sum < "$1" | awk '{print $1}'; else echo absent; fi; }

WS="$TMP/ws"
V="$WS/vault"
mkdir -p "$WS"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
bash "$V/tools/project-bootstrap.sh" create "$WS/proj" "Proj" EN --vcs none >/dev/null 2>&1 \
  || { echo "FAIL : projet jetable non cree"; exit 1; }

# --- The simulated profile ----------------------------------------------------------
PROFILE="$TMP/profile"
mkdir -p "$PROFILE/.codex" "$TMP/bin" "$PROFILE/AppData/Roaming" "$PROFILE/AppData/Local"
export HOME="$PROFILE"
export USERPROFILE="$(N "$PROFILE")"
export APPDATA="$(N "$PROFILE/AppData/Roaming")"
export LOCALAPPDATA="$(N "$PROFILE/AppData/Local")"
export XDG_CONFIG_HOME="$PROFILE/.config"
unset CODEX_HOME
printf '{}\n' > "$PROFILE/.claude.json"
: > "$PROFILE/.codex/config.toml"
# claude and codex stand-ins (the same as tests/test-install-vault-mcp-workspace-label.sh):
# they log, then write the simulated profile's own files; no real tool is reached.
cat > "$TMP/stub.py" <<'PY'
import json, os, sys
tool = sys.argv[1]
args = sys.argv[2:]
home = os.environ["HOME"]
with open(os.environ["M242_CALLS"], "a", encoding="utf-8") as f:
    f.write(tool + " " + " ".join(args) + "\n")
if args[:1] != ["mcp"]:
    sys.exit(2)
sub = args[1]
rest = [a for a in args[2:] if a not in ("-s", "user")]
if tool == "claude":
    path = os.path.join(home, ".claude.json")
    data = json.load(open(path, encoding="utf-8"))
    servers = data.setdefault("mcpServers", {})
    if sub == "remove":
        servers.pop(rest[0], None)
    if sub == "add":
        i = rest.index("--")
        servers[rest[0]] = {"type": "stdio", "command": rest[i + 1], "args": rest[i + 2:], "env": {}}
    json.dump(data, open(path, "w", encoding="utf-8"), indent=2)
    sys.exit(0)
path = os.path.join(home, ".codex", "config.toml")
text = open(path, encoding="utf-8").read()
blocks = text.split("\n[")
name = rest[0]
kept = [b for b in blocks if not b.startswith("mcp_servers." + name + "]")]
text = "\n[".join(kept).rstrip("\n") + "\n"
if sub == "add":
    i = rest.index("--")
    text += "\n[mcp_servers.%s]\ncommand = %s\nargs = [%s]\n" % (
        name, json.dumps(rest[i + 1]), ", ".join(json.dumps(a) for a in rest[i + 2:]))
open(path, "w", encoding="utf-8").write(text)
PY
export M242_CALLS="$(N "$TMP/calls.log")"
for tool in claude codex; do
  printf '#!/usr/bin/env bash\nexec uv run --no-project "%s" %s "$@"\n' "$(N "$TMP/stub.py")" "$tool" > "$TMP/bin/$tool"
  chmod +x "$TMP/bin/$tool"
done
export PATH="$TMP/bin:$PATH"
for cmd in gemini cursor windsurf cline lms; do
  if command -v "$cmd" >/dev/null 2>&1; then echo "FAIL : $cmd est sur le PATH de ce poste ; le test suppose son absence"; exit 1; fi
done

HOSTS() { bash -c ". '$V/tools/lib/mcp-hosts.sh'; mcp_hosts"; }
INSTALL() { bash "$V/tools/install-vault-mcp.sh" "$WS" --skip-desktop "$@" 2>&1; }
GEMINI="$PROFILE/.gemini/settings.json"
CURSOR="$PROFILE/.cursor/mcp.json"
WINDSURF="$PROFILE/.codeium/windsurf/mcp_config.json"
CLINE="$PROFILE/.cline/mcp.json"
LMSTUDIO="$PROFILE/.lmstudio/mcp.json"
ALL_JSON="$GEMINI $CURSOR $WINDSURF $CLINE $LMSTUDIO"

echo "=== Mission 242 : le serveur du Vault dans chaque hote present ==="

echo "--- (H1) table des hotes ---"
OUT="$(HOSTS)"
N_ABSENT="$(printf '%s\n' "$OUT" | awk -F'\t' '$1 ~ /^(gemini|cursor|windsurf|cline|lmstudio)$/ && $5 == "0"' | wc -l | tr -d ' ')"
[ "$N_ABSENT" = 5 ] && pass "(H1) profil vide : les cinq hotes JSON absents" || fail "(H1) profil vide : $N_ABSENT absent(s) sur 5 -- $OUT"
mkdir -p "$PROFILE/.gemini" "$PROFILE/.cursor" "$PROFILE/.codeium/windsurf" "$PROFILE/.cline" "$PROFILE/.lmstudio"
printf '{\n  "theme": "Dracula",\n  "mcpServers": {\n    "other": {"command": "node", "args": ["x.js"]}\n  }\n}\n' > "$GEMINI"
OUT="$(HOSTS)"
N_PRESENT="$(printf '%s\n' "$OUT" | awk -F'\t' '$1 ~ /^(gemini|cursor|windsurf|cline|lmstudio)$/ && $5 == "1"' | wc -l | tr -d ' ')"
[ "$N_PRESENT" = 5 ] && pass "(H1) un dossier par hote : les cinq presents" || fail "(H1) $N_PRESENT present(s) sur 5"
N_HOSTS="$(printf '%s\n' "$OUT" | cut -f1 | sort -u | wc -l | tr -d ' ')"
[ "$N_HOSTS" -ge 8 ] && pass "(H1) $N_HOSTS hotes reconnus (>= 8)" || fail "(H1) $N_HOSTS hotes reconnus"

echo "--- (H2) garde de longueur ---"
ID_SHA="$(sha_of "$V/VAULT-IDENTITY.md")"
G_SHA="$(sha_of "$GEMINI")"
OUT="$(INSTALL --label acmecorpworkshq)"; RC=$?
{ [ "$RC" -eq 1 ] && printf '%s' "$OUT" | grep -q "65" && printf '%s' "$OUT" | grep -q -- "--label acmecorpworksh" \
    && [ "$(sha_of "$V/VAULT-IDENTITY.md")" = "$ID_SHA" ] && [ "$(sha_of "$GEMINI")" = "$G_SHA" ] \
    && [ ! -f "$CURSOR" ] && [ ! -s "$TMP/calls.log" ]; } \
  && pass "(H2) acmecorpworkshq (65 > 64) refuse, forme courte proposee, rien ecrit" \
  || fail "(H2) refus : rc=$RC -- $(printf '%s' "$OUT" | tail -2 | tr '\n' ' ')"
OUT="$(INSTALL --label acmecorp)"; RC=$?
SERVER="second-brain-vault-acmecorp"
[ "$RC" -eq 0 ] && pass "(H2) acmecorp (58) accepte (exit 0)" || fail "(H2) acmecorp : rc=$RC -- $(printf '%s' "$OUT" | tail -3 | tr '\n' ' ')"

echo "--- (H3) chaque hote present recoit le serveur ---"
cat > "$TMP/entry.py" <<'PY'
import json, sys
path, name = sys.argv[1], sys.argv[2]
d = json.load(open(path, encoding="utf-8"))
e = (d.get("mcpServers") or {}).get(name)
if not e:
    print("ABSENT"); sys.exit(1)
a = e.get("args") or []
ok = e.get("command", "").lower().endswith(("uv", "uv.exe")) and "--vault" in a and "--allow" in a
print("type=%s ok=%s keys=%s" % (e.get("type", "-"), ok, ",".join(sorted(k for k in d if k != "mcpServers")) or "-"))
sys.exit(0 if ok else 1)
PY
for f in $ALL_JSON; do
  R="$(uv run --no-project --quiet python "$TMP/entry.py" "$(N "$f")" "$SERVER" 2>&1)"
  if [ $? -eq 0 ]; then pass "(H3) ${f#$PROFILE/} : $SERVER ($R)"; else fail "(H3) ${f#$PROFILE/} : $R"; fi
done
uv run --no-project --quiet python "$TMP/entry.py" "$(N "$CURSOR")" "$SERVER" | grep -q '^type=stdio' \
  && pass "(H3) Cursor : \"type\": \"stdio\"" || fail "(H3) Cursor sans type stdio"
{ uv run --no-project --quiet python "$TMP/entry.py" "$(N "$GEMINI")" other >/dev/null 2>&1 || grep -q '"other"' "$GEMINI"; } \
  && grep -q '"theme": "Dracula"' "$GEMINI" && pass "(H3) Gemini : le serveur 'other' et le reglage 'theme' gardes" \
  || fail "(H3) Gemini : cle existante perdue"
grep -q "^claude mcp add -s user $SERVER " "$TMP/calls.log" && grep -q "^codex mcp add $SERVER " "$TMP/calls.log" \
  && pass "(H3) Claude Code et Codex : ajout demande par leur commande" || fail "(H3) appels : $(cat "$TMP/calls.log" 2>/dev/null | tr '\n' '|')"

echo "--- (H4) deuxieme passage ---"
BEFORE=""; for f in $ALL_JSON; do BEFORE="$BEFORE $(sha_of "$f")"; done
OUT="$(INSTALL)"; RC=$?
AFTER=""; for f in $ALL_JSON; do AFTER="$AFTER $(sha_of "$f")"; done
{ [ "$RC" -eq 0 ] && [ "$BEFORE" = "$AFTER" ]; } && pass "(H4) relance : les cinq fichiers identiques octet pour octet" \
  || fail "(H4) relance : rc=$RC, fichiers changes"

echo "--- (H6) confinement dans chaque hote present ---"
OUT="$(bash "$V/tools/check-mcp-containment.sh" --all "$WS/proj" 2>&1)"; RC=$?
N_PASS_H="$(printf '%s\n' "$OUT" | grep -E '^(Gemini CLI|Cursor|Windsurf|Cline \(CLI\)|LM Studio): PASS' | cut -d: -f1 | sort -u | wc -l | tr -d ' ')"
{ [ "$RC" -eq 0 ] && [ "$N_PASS_H" = 5 ] && printf '%s' "$OUT" | grep -q '^VERDICT: PASS'; } \
  && pass "(H6) --all : PASS dans les cinq hotes JSON, VERDICT: PASS" || fail "(H6) --all : rc=$RC -- $(printf '%s' "$OUT" | tr '\n' '|')"

echo "--- (H7) sb doctor et sb install --mcp ---"
OUT="$(cd "$WS/proj" && SB_LANG=en "$V/tools/sb/bin/sb" doctor 2>&1)"; RC=$?
N_DECL="$(printf '%s\n' "$OUT" | grep -cE "MCP · (Gemini CLI|Cursor|Windsurf|Cline \(CLI\)|LM Studio) +$SERVER declared")"
{ [ "$N_DECL" = 5 ] && ! printf '%s' "$OUT" | grep -q '^  FAIL  MCP'; } \
  && pass "(H7) doctor : une ligne « declared » par hote JSON present (5)" || fail "(H7) doctor : $N_DECL ligne(s) -- $(printf '%s' "$OUT" | grep MCP | tr '\n' '|')"
OUT="$(cd "$WS" && SB_LANG=en "$V/tools/sb/bin/sb" install --mcp --label acmecorpworkshq 2>&1)"; RC=$?
{ [ "$RC" -eq 1 ] && printf '%s' "$OUT" | grep -q -- "--label acmecorpworksh"; } \
  && pass "(H7) sb install --mcp --label : etiquette transmise, refus et proposition relayes (exit 1)" \
  || fail "(H7) sb install --mcp --label : rc=$RC -- $(printf '%s' "$OUT" | tail -2 | tr '\n' ' ')"
OUT="$(cd "$WS" && "$V/tools/sb/bin/sb" install --mcp --lang fr 2>&1)"; RC=$?
{ [ "$RC" -eq 0 ] && printf '%s' "$OUT" | tail -1 | grep -q "Geste restant"; } \
  && pass "(H7) sb install --mcp --lang fr : derniere ligne en francais" \
  || fail "(H7) langue : rc=$RC -- $(printf '%s' "$OUT" | tail -1)"

echo "--- (H5) profil sans hote JSON ---"
P2="$TMP/profile2"
mkdir -p "$P2/.codex"; printf '{}\n' > "$P2/.claude.json"; : > "$P2/.codex/config.toml"
OUT="$(HOME="$P2" USERPROFILE="$(N "$P2")" bash "$V/tools/install-vault-mcp.sh" "$WS" --skip-desktop 2>&1)"; RC=$?
CREATED="$(find "$P2" -name '*.json' ! -name '.claude.json' | wc -l | tr -d ' ')"
N_NF="$(printf '%s\n' "$OUT" | grep -cE 'Not found: (Gemini CLI|Cursor|Windsurf|Cline \(CLI\)|LM Studio)$')"
{ [ "$RC" -eq 0 ] && [ "$CREATED" = 0 ] && [ "$N_NF" = 5 ] && [ ! -d "$P2/.gemini" ] && [ ! -d "$P2/.cursor" ]; } \
  && pass "(H5) hotes absents : 0 fichier cree, cinq « Not found »" || fail "(H5) rc=$RC, $CREATED fichier(s), $N_NF « Not found »"

echo ""
if [ "$FAILURES" -eq 0 ]; then echo "=== RESULT: PASS ($PASSES) ==="; exit 0; fi
echo "=== RESULT: FAIL ($FAILURES, $PASSES PASS) ==="
exit 1
