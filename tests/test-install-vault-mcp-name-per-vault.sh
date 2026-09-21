#!/usr/bin/env bash
# T1 (Mission 191-C01, Decision 152251 C): one MCP server per Vault.
#
# Two throwaway Vaults, each with its own generated identity, on one
# SIMULATED profile (HOME, APPDATA, LOCALAPPDATA redirected, `claude` and
# `codex` replaced by stand-ins at the head of the PATH):
#   (a) Vault 1 then Vault 2: two servers in each of the three
#       configurations, each allowed on its own workspace; the first is intact
#       after the second was added. Names: by identity before the installer has
#       posed a workspace label (second-brain-vault-<8 characters of vault_id>),
#       by workspace once it has (second-brain-vault-<label>, Mission 206 --
#       the label-based names are proved in test-install-vault-mcp-workspace-label.sh;
#       here they are only re-read after the run);
#   (b) idempotent: a second run leaves the three files byte for byte;
#   (c) the former fixed name `second-brain-vault`: pointing to Vault 1, it
#       is migrated by Vault 1's run (removed, new name kept); pointing to
#       Vault 2, Vault 1's run leaves it as it is and says so;
#   (d) negative control -- crossed identity: Vault 1's server name pointing
#       to Vault 2 is refused (exit 1), the message names both identities,
#       and that configuration is unchanged.
# Never the real profile: everything lives under a temporary folder (m191).
#
# usage: bash tests/test-install-vault-mcp-name-per-vault.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}
has() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi

REAL_HOME="$HOME"
UV_PYTHON_INSTALL_DIR="$(uv python dir 2>/dev/null | tr -d '\r')"
UV_CACHE_DIR="$(uv cache dir 2>/dev/null | tr -d '\r')"
export UV_PYTHON_INSTALL_DIR UV_CACHE_DIR
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m191-mcpname-XXXXXX")"
trap 'export HOME="$REAL_HOME"; rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
N() { sandbox_native_path "$1"; }
NW() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi
}
sha_of() {
  if [ ! -f "$1" ]; then echo absent; return 0; fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum < "$1" | awk '{print $1}'
  else
    shasum -a 256 < "$1" | awk '{print $1}'
  fi
}

echo "=== T1 : un serveur MCP par Vault ==="
for i in 1 2; do
  mkdir -p "$TMP/ws$i"
  if ! sandbox_vault "$REPO_ROOT" "$TMP/ws$i/second-brain"; then
    echo "FAIL : Vault jetable $i non construit"
    exit 1
  fi
  bash "$TMP/ws$i/second-brain/tools/write-marker.sh" "$TMP/ws$i" >/dev/null
done
V1="$TMP/ws1/second-brain"
V2="$TMP/ws2/second-brain"
ID1="$(bash "$V1/tools/vault-identity.sh" get vault_id "$V1")"
ID2="$(bash "$V2/tools/vault-identity.sh" get vault_id "$V2")"
S1="$(bash "$V1/tools/vault-identity.sh" get server_name "$V1")"
S2="$(bash "$V2/tools/vault-identity.sh" get server_name "$V2")"
check "deux identites distinctes ($ID1, $ID2)" sh -c "[ -n '$ID1' ] && [ '$ID1' != '$ID2' ]"
check "nom derive de l'identite : $S1 = second-brain-vault-<8 car. de $ID1>" [ "$S1" = "second-brain-vault-$(printf '%s' "${ID1#sb-}" | cut -c1-8)" ]
check "deux noms distincts ($S1, $S2)" [ "$S1" != "$S2" ]

PROFILE="$TMP/profile"
mkdir -p "$PROFILE/.codex" "$TMP/bin"
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
DESKTOP="$DESKTOP_DIR/claude_desktop_config.json"
CLAUDE_JSON="$PROFILE/.claude.json"
CODEX_TOML="$PROFILE/.codex/config.toml"
printf '{\n  "mcpServers": {\n    "autre": {"command": "autre", "args": ["x"]}\n  }\n}\n' > "$DESKTOP"
printf 'model = "garde"\n\n[mcp_servers.autre]\ncommand = "autre"\nargs = ["x"]\n' > "$CODEX_TOML"
printf '{"mcpServers": {"autre": {"type": "stdio", "command": "autre", "args": ["x"], "env": {}}}}\n' > "$CLAUDE_JSON"

# Stand-ins for `claude mcp get|add|remove` and `codex mcp get|add|remove`.
cat > "$TMP/stub.py" <<'PY'
import json, os, sys
tool = sys.argv[1]
args = sys.argv[2:]
home = os.environ["HOME"]
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
if sub == "get":
    sys.exit(0 if len(kept) != len(blocks) else 1)
text = "\n[".join(kept).rstrip("\n") + "\n"
if sub == "add":
    i = rest.index("--")
    text += "\n[mcp_servers.%s]\ncommand = %s\nargs = [%s]\n" % (
        name, json.dumps(rest[i + 1]), ", ".join(json.dumps(a) for a in rest[i + 2:]))
open(path, "w", encoding="utf-8").write(text)
PY
for tool in claude codex; do
  printf '#!/usr/bin/env bash\nexec uv run --no-project "%s" %s "$@"\n' "$TMP/stub.py" "$tool" > "$TMP/bin/$tool"
  chmod +x "$TMP/bin/$tool"
done
export PATH="$TMP/bin:$PATH"

args_of() {
  uv run --no-project "$V1/tools/sb_installer_helper.py" mcp-server-args "$(N "$1")" "$2" 2>/dev/null | tr -d '\r' | tr '\n' ' '
}
all_three_have() {
  local name="$1" ws="$2" c
  for c in "$CLAUDE_JSON" "$CODEX_TOML" "$DESKTOP"; do
    has "$(args_of "$c" "$name")" "--allow $(NW "$ws")" || return 1
  done
}

# --- (a) two Vaults, two servers ---------------------------------------------
OUT1="$(bash "$V1/tools/install-vault-mcp.sh" "$TMP/ws1" --lang FR 2>&1)"
check "(a) Vault 1 : sortie 0" [ "$?" = "0" ]
# Mission 206: the installer poses the workspace label (ws1), the name becomes
# second-brain-vault-ws1. These assertions used to expect the name by identity read
# BEFORE the run -- the naming Decision 162812 replaces; what they prove (two Vaults,
# two servers, each on its own folder) is unchanged.
S1_BY_IDENTITY="$S1"
S1="$(bash "$V1/tools/vault-identity.sh" get server_name "$V1")"
check "(a) Vault 1 : le nom suit l'espace de travail ($S1), plus l'identite ($S1_BY_IDENTITY)" [ "$S1" = "second-brain-vault-ws1" ]
check "(a) Vault 1 : $S1 dans les trois configurations, dossier = ws1" all_three_have "$S1" "$TMP/ws1"
BEFORE_V2="$(args_of "$DESKTOP" "$S1")|$(args_of "$CLAUDE_JSON" "$S1")|$(args_of "$CODEX_TOML" "$S1")"
bash "$V2/tools/install-vault-mcp.sh" "$TMP/ws2" --lang FR >/dev/null 2>&1
check "(a) Vault 2 : sortie 0" [ "$?" = "0" ]
S2="$(bash "$V2/tools/vault-identity.sh" get server_name "$V2")"
check "(a) Vault 2 : le nom suit l'espace de travail ($S2)" [ "$S2" = "second-brain-vault-ws2" ]
check "(a) Vault 2 : $S2 dans les trois configurations, dossier = ws2" all_three_have "$S2" "$TMP/ws2"
AFTER_V2="$(args_of "$DESKTOP" "$S1")|$(args_of "$CLAUDE_JSON" "$S1")|$(args_of "$CODEX_TOML" "$S1")"
check "(a) le serveur du Vault 1 est intact apres le Vault 2" [ "$BEFORE_V2" = "$AFTER_V2" ]
check "(a) autres serveurs conserves" sh -c "grep -q '\"autre\"' '$DESKTOP' && grep -q '\"autre\"' '$CLAUDE_JSON' && grep -q 'mcp_servers.autre' '$CODEX_TOML'"
check "(a) aucun serveur au nom fixe cree" sh -c "! grep -q '\"second-brain-vault\"' '$DESKTOP' && ! grep -q '\"second-brain-vault\"' '$CLAUDE_JSON' && ! grep -q 'mcp_servers.second-brain-vault]' '$CODEX_TOML'"

# --- (b) idempotent -----------------------------------------------------------
FP1="$(sha_of "$DESKTOP") $(sha_of "$CLAUDE_JSON") $(sha_of "$CODEX_TOML")"
OUT_B="$(bash "$V1/tools/install-vault-mcp.sh" "$TMP/ws1" --lang FR 2>&1)"
FP2="$(sha_of "$DESKTOP") $(sha_of "$CLAUDE_JSON") $(sha_of "$CODEX_TOML")"
check "(b) second passage : trois configurations octet pour octet" [ "$FP1" = "$FP2" ]
check "(b) second passage : « déjà configuré » trois fois, nommant $S1" [ "$(printf '%s\n' "$OUT_B" | grep 'déjà configuré' | grep -c "$S1")" = "3" ]

# --- (c) former fixed name ----------------------------------------------------
UVN="$(NW "$(command -v uv)")"
put_legacy() {
  # put_legacy <vault>: the former `second-brain-vault` server in the three
  # configurations, pointing to <vault>.
  local vn wn
  vn="$(NW "$1")"; wn="$(NW "$(dirname "$1")")"
  uv run --no-project "$V1/tools/sb_installer_helper.py" merge-mcp-json "$(N "$DESKTOP")" second-brain-vault "$UVN" run --no-project x --vault "$vn" --allow "$wn" >/dev/null
  claude mcp add -s user second-brain-vault -- "$UVN" run --no-project x --vault "$vn" --allow "$wn"
  codex mcp add second-brain-vault -- "$UVN" run --no-project x --vault "$vn" --allow "$wn"
}
put_legacy "$V1"
OUT_C1="$(bash "$V1/tools/install-vault-mcp.sh" "$TMP/ws1" --lang FR 2>&1)"
check "(c) ancien nom vers ce Vault : migre dans les trois configurations" sh -c "[ -z \"\$1\" ] && [ -z \"\$2\" ] && [ -z \"\$3\" ]" _ "$(args_of "$DESKTOP" second-brain-vault)" "$(args_of "$CLAUDE_JSON" second-brain-vault)" "$(args_of "$CODEX_TOML" second-brain-vault)"
check "(c) migration dite trois fois" [ "$(printf '%s\n' "$OUT_C1" | grep -c 'ancien serveur second-brain-vault pointait ce Vault')" = "3" ]
check "(c) le nouveau nom reste en place" all_three_have "$S1" "$TMP/ws1"
put_legacy "$V2"
LEGACY_BEFORE="$(args_of "$DESKTOP" second-brain-vault)|$(args_of "$CLAUDE_JSON" second-brain-vault)|$(args_of "$CODEX_TOML" second-brain-vault)"
OUT_C2="$(bash "$V1/tools/install-vault-mcp.sh" "$TMP/ws1" --lang FR 2>&1)"
LEGACY_AFTER="$(args_of "$DESKTOP" second-brain-vault)|$(args_of "$CLAUDE_JSON" second-brain-vault)|$(args_of "$CODEX_TOML" second-brain-vault)"
check "(c) ancien nom vers l'autre Vault : laisse intact" sh -c "[ '$LEGACY_BEFORE' = '$LEGACY_AFTER' ] && [ -n '$(args_of "$DESKTOP" second-brain-vault)' ]"
check "(c) ... et dit" has "$OUT_C2" "pointe un autre Vault"

# --- (d) negative control: crossed identity ----------------------------------
uv run --no-project python -c "import json,sys; p=sys.argv[1]; d=json.load(open(p,encoding='utf-8')); a=d['mcpServers'][sys.argv[2]]['args']; a[a.index('--vault')+1]=sys.argv[3]; json.dump(d,open(p,'w',encoding='utf-8'),indent=2)" "$(N "$DESKTOP")" "$S1" "$(NW "$V2")"
FP_D="$(sha_of "$DESKTOP")"
OUT_D="$(bash "$V1/tools/install-vault-mcp.sh" "$TMP/ws1" --lang FR 2>&1)"
RC_D=$?
check "(d) temoin : identite croisee -> sortie 1" [ "$RC_D" = "1" ]
check "(d) temoin : le refus nomme les deux identites ($ID2, $ID1)" sh -c "case \"\$1\" in *'$ID2'*'$ID1'*) exit 0;; *) exit 1;; esac" _ "$OUT_D"
check "(d) temoin : configuration refusee inchangee" [ "$(sha_of "$DESKTOP")" = "$FP_D" ]

export HOME="$REAL_HOME"
echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
