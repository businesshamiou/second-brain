#!/usr/bin/env bash
# Serveur MCP du Vault, injection et contenance (Mission 184, Decision
# 2026-09-17-000545 A6).
#
#   (g) serveur  : initialize, tools/list, list_allowed_directories (commit du
#                  Vault = git rev-parse HEAD), lecture et ecriture dedans,
#                  refus dehors, refus d'un lien qui s'echappe (jonction sous
#                  Windows, lien symbolique ailleurs). Temoin : le meme
#                  serveur, dehors autorise, lit ce qu'il refusait.
#   (h) injection sur un profil SIMULE (HOME, APPDATA, LOCALAPPDATA rediriges,
#                  `claude` et `codex` remplaces par des substituts en tete du
#                  PATH) : trois configurations au chemin mesure, autres
#                  serveurs conserves, second passage sans aucun changement.
#                  Temoin : une configuration alteree est vue et retablie.
#   (i) contenance : PASS pour un projet de l'espace de travail, FAIL pour un
#                  projet hors de lui et pour une configuration sans serveur.
#
# Jamais le profil reel : tout vit sous un dossier temporaire (prefixe m184).
#
# usage: bash tests/test-vault-mcp.sh
# Code 0 : tous les cas PASS (ou SKIP nomme). Code 1 sinon.

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
has() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- le serveur se lance par uv"
  exit 1
fi

REAL_HOME="$HOME"
REAL_DESKTOP="/nonexistent"
if [ -n "${APPDATA:-}" ]; then
  if command -v cygpath >/dev/null 2>&1; then
    REAL_DESKTOP="$(cygpath -u "$APPDATA")/Claude/claude_desktop_config.json"
  else
    REAL_DESKTOP="$APPDATA/Claude/claude_desktop_config.json"
  fi
fi
# uv garde ses Pythons et son cache hors du profil simule (sinon il en
# telechargerait un neuf dans le dossier redirige).
UV_PYTHON_INSTALL_DIR="$(uv python dir 2>/dev/null | tr -d '\r')"
UV_CACHE_DIR="$(uv cache dir 2>/dev/null | tr -d '\r')"
export UV_PYTHON_INSTALL_DIR UV_CACHE_DIR
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m184-mcp-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
N() { sandbox_native_path "$1"; }

sha_of() {
  if [ ! -f "$1" ]; then echo absent; return 0; fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum < "$1" | awk '{print $1}'
  else
    shasum -a 256 < "$1" | awk '{print $1}'
  fi
}

# =============================================================================
echo "=== (g) serveur MCP ==="
mkdir -p "$TMP/g/ws/proj" "$TMP/g/outside"
printf 'dedans\n' > "$TMP/g/ws/proj/a.txt"
printf 'dehors\n' > "$TMP/g/outside/s.txt"
LINK_KIND=""
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    cmd //c "mklink /J $(cygpath -w "$TMP/g/ws/proj/esc") $(cygpath -w "$TMP/g/outside")" >/dev/null 2>&1 && LINK_KIND="jonction"
    ;;
  *)
    ln -s "$TMP/g/outside" "$TMP/g/ws/proj/esc" 2>/dev/null && LINK_KIND="lien symbolique"
    ;;
esac
WS_N="$(N "$TMP/g/ws")"
OUT_N="$(N "$TMP/g/outside")"
REQS="$TMP/g/requests.jsonl"
{
  echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"test","version":"0"}}}'
  echo '{"jsonrpc":"2.0","method":"notifications/initialized"}'
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
  echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"list_allowed_directories","arguments":{}}}'
  echo "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"read_text_file\",\"arguments\":{\"path\":\"$(N "$TMP/g/ws/proj/a.txt")\"}}}"
  echo "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"tools/call\",\"params\":{\"name\":\"read_text_file\",\"arguments\":{\"path\":\"$(N "$TMP/g/outside/s.txt")\"}}}"
  echo "{\"jsonrpc\":\"2.0\",\"id\":6,\"method\":\"tools/call\",\"params\":{\"name\":\"read_text_file\",\"arguments\":{\"path\":\"$(N "$TMP/g/ws/proj")/esc/s.txt\"}}}"
  echo "{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"tools/call\",\"params\":{\"name\":\"write_file\",\"arguments\":{\"path\":\"$(N "$TMP/g/ws/proj")/b.txt\",\"content\":\"ecrit\"}}}"
  echo "{\"jsonrpc\":\"2.0\",\"id\":8,\"method\":\"tools/call\",\"params\":{\"name\":\"write_file\",\"arguments\":{\"path\":\"$(N "$TMP/g/outside")/w.txt\",\"content\":\"interdit\"}}}"
  echo "{\"jsonrpc\":\"2.0\",\"id\":9,\"method\":\"tools/call\",\"params\":{\"name\":\"list_directory\",\"arguments\":{\"path\":\"$(N "$TMP/g/ws/proj")\"}}}"
  echo '{"jsonrpc":"2.0","id":10,"method":"no/such"}'
} > "$REQS"
MCP="$REPO_ROOT/tools/vault-mcp.py"
RESP="$(uv run --no-project "$MCP" --vault "$REPO_ROOT" --allow "$TMP/g/ws" < "$REQS" 2>"$TMP/g/stderr.log")"
line_of() { printf '%s\n' "$RESP" | grep "\"id\": $1[,}]" | head -n 1; }
HEAD_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD)"
check "(g) initialize : serverInfo second-brain-vault" has "$(line_of 1)" '"name": "second-brain-vault"'
TOOLS_LINE="$(line_of 2)"
MISSING_TOOLS=""
for t in list_allowed_directories list_directory read_text_file read_multiple_files write_file edit_file create_directory search_files get_file_info move_file; do
  has "$TOOLS_LINE" "\"name\": \"$t\"" || MISSING_TOOLS="$MISSING_TOOLS $t"
done
check "(g) tools/list : dix outils${MISSING_TOOLS:+ (manquants :$MISSING_TOOLS)}" [ -z "$MISSING_TOOLS" ]
check "(g) list_allowed_directories : commit du Vault = git rev-parse HEAD" has "$(line_of 3)" "Vault commit: $HEAD_SHA"
check "(g) lecture dedans : PASS" has "$(line_of 4)" '"text": "dedans'
# Mission 185-C01, porte 3 : un echec d'EXECUTION d'outil n'est plus une
# erreur JSON-RPC (-32001) mais un RESULTAT porteur de isError, dont le
# texte nomme le chemin ET les dossiers autorises -- c'est la seule forme
# que l'application de bureau rend telle quelle. L'oracle se resserre :
# il exige desormais les deux faits, pas seulement un code.
# tests/test-vault-mcp-refusal-message.py mesure la forme en detail.
check "(g) lecture dehors : resultat isError nommant le chemin et le perimetre" sh -c 'case "$1" in *"s.txt"*"Dossiers autorisés"*"\"isError\": true"*) exit 0;; *) exit 1;; esac' _ "$(line_of 5)"
if [ -n "$LINK_KIND" ]; then
  check "(g) $LINK_KIND qui s'echappe : refus" sh -c 'case "$1" in *"\"isError\": true"*) exit 0;; *) exit 1;; esac' _ "$(line_of 6)"
else
  skip "lien non creable sur $(uname -s)" "(g) lien qui s'echappe"
fi
check "(g) ecriture dedans : fichier ecrit" sh -c "has_ok=\$(cat '$TMP/g/ws/proj/b.txt' 2>/dev/null); [ \"\$has_ok\" = 'ecrit' ]"
check "(g) ecriture dehors : refus lisible, rien d'ecrit" sh -c "case \"\$1\" in *'\"isError\": true'*) [ ! -e '$TMP/g/outside/w.txt' ];; *) exit 1;; esac" _ "$(line_of 8)"
check "(g) list_directory dedans" has "$(line_of 9)" '[FILE] a.txt'
check "(g) methode inconnue : erreur, le serveur continue" has "$(line_of 10)" '-32601'
check "(g) sortie standard : seulement du JSON-RPC ($(printf '%s\n' "$RESP" | grep -c .) lignes)" sh -c '! printf "%s\n" "$1" | grep -v "^{\"jsonrpc\"" | grep -q .' _ "$RESP"

RESP2="$(uv run --no-project "$MCP" --vault "$REPO_ROOT" --allow "$TMP/g/ws" --allow "$TMP/g/outside" < "$REQS" 2>/dev/null)"
line2_of() { printf '%s\n' "$RESP2" | grep "\"id\": $1[,}]" | head -n 1; }
check "(g) temoin : dehors autorise, la meme lecture passe" has "$(line2_of 5)" '"text": "dehors'
if [ -n "$LINK_KIND" ]; then
  check "(g) temoin : dehors autorise, le meme $LINK_KIND se lit" has "$(line2_of 6)" '"text": "dehors'
fi

# =============================================================================
echo ""
echo "=== (h) injection sur profil simule ==="
REAL_FP_BEFORE="$(sha_of "$REAL_HOME/.codex/config.toml") $(sha_of "$REAL_DESKTOP")"
WS="$TMP/h/ws"
mkdir -p "$WS"
V="$WS/second-brain"
if ! sandbox_vault "$REPO_ROOT" "$V"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V/tools/write-marker.sh" "$WS" >/dev/null
bash "$V/tools/project-bootstrap.sh" create "$WS/projet" "Projet" --vcs none >/dev/null 2>&1

PROFILE="$TMP/h/profile"
mkdir -p "$PROFILE/.codex" "$TMP/h/bin"
export HOME="$PROFILE"
export USERPROFILE="$(N "$PROFILE")"
export APPDATA="$(N "$PROFILE/AppData/Roaming")"
export LOCALAPPDATA="$(N "$PROFILE/AppData/Local")"
export XDG_CONFIG_HOME="$PROFILE/.config"
unset CODEX_HOME
case "$(uname -s)" in
  Darwin) DESKTOP_DIR="$PROFILE/Library/Application Support/Claude" ;;
  MINGW*|MSYS*|CYGWIN*) DESKTOP_DIR="$PROFILE/AppData/Roaming/Claude" ;;
  *) DESKTOP_DIR="$PROFILE/.config/Claude" ;;
esac
mkdir -p "$DESKTOP_DIR"
DESKTOP_CONFIG="$DESKTOP_DIR/claude_desktop_config.json"
printf '{\n  "mcpServers": {\n    "autre": {"command": "autre", "args": ["x"]}\n  },\n  "preferences": {"garder": true}\n}\n' > "$DESKTOP_CONFIG"
printf 'model = "garde"\n\n[mcp_servers.autre]\ncommand = "autre"\nargs = ["x"]\n' > "$PROFILE/.codex/config.toml"
printf '{"mcpServers": {"autre": {"type": "stdio", "command": "autre", "args": ["x"], "env": {}}}, "numStartups": 3}\n' > "$PROFILE/.claude.json"

# Substituts : `claude mcp get|add|remove` et `codex mcp get|add|remove`,
# ecrivant la configuration utilisateur simulee et journalisant chaque appel.
cat > "$TMP/h/stub.py" <<'PY'
import json, os, sys
tool = sys.argv[1]
args = sys.argv[2:]
home = os.environ["HOME"]
with open(os.path.join(os.environ["STUB_LOG"]), "a", encoding="utf-8") as log:
    log.write(tool + " " + " ".join(args[:2]) + "\n")
if args[:1] != ["mcp"]:
    sys.exit(2)
sub = args[1]
rest = [a for a in args[2:] if a not in ("-s", "user")]
if tool == "claude":
    path = os.path.join(home, ".claude.json")
    data = json.load(open(path, encoding="utf-8"))
    servers = data.setdefault("mcpServers", {})
    if sub == "get":
        sys.exit(0 if rest[0] in servers else 1)
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
head = "mcp_servers." + name + "]"
kept = [b for b in blocks if not b.startswith(head)]
present = len(kept) != len(blocks)
if sub == "get":
    sys.exit(0 if present else 1)
text = "\n[".join(kept).rstrip("\n") + "\n"
if sub == "add":
    i = rest.index("--")
    text += "\n[mcp_servers.%s]\ncommand = %s\nargs = [%s]\n" % (
        name, json.dumps(rest[i + 1]), ", ".join(json.dumps(a) for a in rest[i + 2:]))
open(path, "w", encoding="utf-8").write(text)
PY
for tool in claude codex; do
  cat > "$TMP/h/bin/$tool" <<STUB
#!/usr/bin/env bash
exec uv run --no-project "$TMP/h/stub.py" $tool "\$@"
STUB
  chmod +x "$TMP/h/bin/$tool"
done
export STUB_LOG="$(N "$TMP/h/calls.log")"
: > "$TMP/h/calls.log"
export PATH="$TMP/h/bin:$PATH"
check "(h) substituts en tete du PATH (jamais les vrais outils)" sh -c "[ \"\$(command -v claude)\" = '$TMP/h/bin/claude' ] && [ \"\$(command -v codex)\" = '$TMP/h/bin/codex' ]"

OUT_H1="$(bash "$V/tools/install-vault-mcp.sh" "$WS" --lang FR 2>&1)"
check "(h) premier passage rend 0" [ "$?" = "0" ]
# Forme ecrite par l'injection : chemin natif du systeme (C:\... sous Windows).
if command -v cygpath >/dev/null 2>&1; then
  WS_H_N="$(cygpath -w "$WS")"
else
  WS_H_N="$WS"
fi
CL="$(uv run --no-project "$V/tools/sb_installer_helper.py" mcp-server-args "$(N "$PROFILE/.claude.json")" second-brain-vault 2>/dev/null | tr -d '\r' | tr '\n' ' ')"
CX="$(uv run --no-project "$V/tools/sb_installer_helper.py" mcp-server-args "$(N "$PROFILE/.codex/config.toml")" second-brain-vault 2>/dev/null | tr -d '\r' | tr '\n' ' ')"
DK="$(uv run --no-project "$V/tools/sb_installer_helper.py" mcp-server-args "$(N "$DESKTOP_CONFIG")" second-brain-vault 2>/dev/null | tr -d '\r' | tr '\n' ' ')"
check "(h) Claude Code : serveur declare, dossier autorise = espace de travail" has "$CL" "--allow $WS_H_N"
check "(h) Codex : serveur declare, dossier autorise = espace de travail" has "$CX" "--allow $WS_H_N"
check "(h) application de bureau (chemin mesure) : serveur declare" has "$DK" "--allow $WS_H_N"
check "(h) autres serveurs et cles conserves (trois configurations)" sh -c "grep -q '\"autre\"' '$PROFILE/.claude.json' && grep -q 'mcp_servers.autre' '$PROFILE/.codex/config.toml' && grep -q '^model = \"garde\"' '$PROFILE/.codex/config.toml' && grep -q '\"autre\"' '$DESKTOP_CONFIG' && grep -q '\"garder\"' '$DESKTOP_CONFIG'"
case "$OUT_H1" in *"redémarre l'application Claude"*) r=0 ;; *) r=1 ;; esac
check "(h) geste restant imprime : redemarrer l'application" [ "$r" = "0" ]
check "(h) Python verifie par uv" has "$OUT_H1" "Python par uv"

S1="$(sha_of "$PROFILE/.claude.json") $(sha_of "$PROFILE/.codex/config.toml") $(sha_of "$DESKTOP_CONFIG")"
ADDS1="$(grep -c ' mcp add' "$TMP/h/calls.log" 2>/dev/null || true)"
OUT_H2="$(bash "$V/tools/install-vault-mcp.sh" "$WS" --lang FR 2>&1)"
S2="$(sha_of "$PROFILE/.claude.json") $(sha_of "$PROFILE/.codex/config.toml") $(sha_of "$DESKTOP_CONFIG")"
ADDS2="$(grep -c ' mcp add' "$TMP/h/calls.log" 2>/dev/null || true)"
check "(h) second passage : diff 0 sur les trois configurations" [ "$S1" = "$S2" ]
check "(h) second passage : aucun nouvel ajout ($ADDS1 puis $ADDS2)" [ "$ADDS1" = "$ADDS2" ]
check "(h) second passage : « déjà configuré » dit trois fois" [ "$(printf '%s\n' "$OUT_H2" | grep -c 'déjà configuré')" = "3" ]

uv run --no-project python -c "import json,sys; p=sys.argv[1]; d=json.load(open(p,encoding='utf-8')); d['mcpServers']['second-brain-vault']['args'][-1]='ailleurs'; json.dump(d,open(p,'w',encoding='utf-8'))" "$(N "$DESKTOP_CONFIG")"
S3="$(sha_of "$DESKTOP_CONFIG")"
bash "$V/tools/install-vault-mcp.sh" "$WS" >/dev/null 2>&1
DK3="$(uv run --no-project "$V/tools/sb_installer_helper.py" mcp-server-args "$(N "$DESKTOP_CONFIG")" second-brain-vault 2>/dev/null | tr -d '\r' | tr '\n' ' ')"
check "(h) temoin : une configuration alteree est vue (empreinte changee) puis retablie" sh -c "[ '$S3' != '$(printf '%s' "$S2" | awk '{print $3}')' ] && case \"\$1\" in *'--allow $WS_H_N'*) exit 0;; *) exit 1;; esac" _ "$DK3"
export HOME="$REAL_HOME"
REAL_FP_AFTER="$(sha_of "$REAL_HOME/.codex/config.toml") $(sha_of "$REAL_DESKTOP")"
check "(h) profil reel : configurations Codex et application inchangees" [ "$REAL_FP_BEFORE" = "$REAL_FP_AFTER" ]

# =============================================================================
echo ""
echo "=== (i) contenance ==="
C_OUT="$(bash "$V/tools/check-mcp-containment.sh" "$(N "$DESKTOP_CONFIG")" "$WS/projet" 2>&1)"
check "(i) projet de l'espace de travail : PASS" sh -c "[ '$?' = '0' ] && case \"\$1\" in *'VERDICT: PASS'*) exit 0;; *) exit 1;; esac" _ "$C_OUT"
C_OUT_CL="$(bash "$V/tools/check-mcp-containment.sh" "$(N "$PROFILE/.claude.json")" "$WS/projet" 2>&1)"
check "(i) configuration Claude Code : PASS" has "$C_OUT_CL" "VERDICT: PASS"
C_OUT_CX="$(bash "$V/tools/check-mcp-containment.sh" "$(N "$PROFILE/.codex/config.toml")" "$WS/projet" 2>&1)"
check "(i) configuration Codex : PASS" has "$C_OUT_CX" "VERDICT: PASS"
mkdir -p "$TMP/i/ailleurs"
(cd "$WS" && tar -cf - --exclude=./projet/.claude --exclude=./projet/.agents projet) | (cd "$TMP/i/ailleurs" && tar -xf -)
C_OUT2="$(bash "$V/tools/check-mcp-containment.sh" "$(N "$DESKTOP_CONFIG")" "$TMP/i/ailleurs/projet" 2>&1)"
RC_I2=$?
check "(i) temoin : projet hors de l'espace de travail -> FAIL" sh -c "[ '$RC_I2' = '1' ] && case \"\$1\" in *'VERDICT: FAIL'*) exit 0;; *) exit 1;; esac" _ "$C_OUT2"
printf '{"mcpServers": {}}\n' > "$TMP/i/vide.json"
bash "$V/tools/check-mcp-containment.sh" "$(N "$TMP/i/vide.json")" "$WS/projet" >/dev/null 2>&1
check "(i) temoin : configuration sans serveur -> FAIL" [ "$?" = "1" ]

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS, $SKIPS SKIP) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS, $SKIPS SKIP) ==="
exit 1
