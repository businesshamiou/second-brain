#!/usr/bin/env bash
# A-226-21 (Mission 230): the project the installer creates must name, in its
# PILOT-PROMPT.md, the very server tools/install-vault-mcp.sh configures.
#
# The installer generates the Vault's identity and then creates the first
# project. `tools/project-bootstrap.sh` writes into that project's Pilot prompt
# the name `tools/vault-identity.sh get server_name` gives -- and with no
# `workspace_label` recorded, that is the name BY IDENTITY,
# `second-brain-vault-<8 characters of vault_id>`. The participant then runs
# `tools/install-vault-mcp.sh <workspace>`, which falls back on the normalised
# name of the workspace folder: `second-brain-vault-<folder>`. The prompt of
# their very first project names a server that does not exist.
#
# The label is therefore recorded at installation, before the first project is
# created -- one source of truth, VAULT-IDENTITY.md, read by both tools. With
# it recorded, install-vault-mcp.sh uses it (it prefers a recorded label to the
# fallback) and nothing is renamed afterwards (Mission 230, P4).
#
#   (a) a complete installation with a first project, at the default workspace
#       of --test-root;
#   (b) VAULT-IDENTITY.md records the workspace label;
#   (c) the first project's PILOT-PROMPT.md names `second-brain-vault-<label>`,
#       not the identity name;
#   (d) `tools/install-vault-mcp.sh` on a SIMULATED profile configures that
#       same name, in the three configurations: prompt and server agree;
#   (e) `tools/project-bootstrap.sh prompt` regenerates the same name.
#
# Everything lives under --test-root and a simulated profile: the real profile
# is never touched.
#
# usage: bash tests/test-install-first-project-server-name.sh
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

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
REAL_HOME="$HOME"
UV_PYTHON_INSTALL_DIR="$(uv python dir 2>/dev/null | tr -d '\r')"
UV_CACHE_DIR="$(uv cache dir 2>/dev/null | tr -d '\r')"
export UV_PYTHON_INSTALL_DIR UV_CACHE_DIR
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m230-prompt-XXXXXX")"
trap 'export HOME="$REAL_HOME"; [ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
N() { sandbox_native_path "$1"; }
NW() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi
}

echo "=== A-226-21 : le premier projet nomme le serveur reellement configure ==="

TEST_ROOT="$TMP/root"
mkdir -p "$TEST_ROOT"
WS="$TEST_ROOT/workspace"
CLONE="$WS/second-brain"

# --- (a) the installation, with a first project ---------------------------------
ANSWERS="$TMP/answers.json"
uv run --no-project - "$REPO_ROOT/tests/fixtures/install-answers.sample.json" "$ANSWERS" "$WS" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
data["workspacePath"] = sys.argv[3]
data["firstProject"] = {"create": True, "name": "premier-projet", "displayName": "Premier projet"}
json.dump(data, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY
OUT_A="$(bash "$REPO_ROOT/install.sh" --source "$REPO_ROOT" --answers-file "$ANSWERS" \
  --test-mode --test-root "$TEST_ROOT" 2>&1)"
RC_A=$?
[ "$RC_A" = "0" ] || printf '%s\n' "$OUT_A" | tail -n 20 | sed 's/^/    /'
check "(a) installation : sortie 0" [ "$RC_A" = "0" ]
PROJECT="$WS/premier-projet"
PROMPT="$PROJECT/state/PILOT-PROMPT.md"
check "(a) le premier projet et son prompt Pilote sont la" sh -c "[ -f '$PROMPT' ]"
[ -f "$PROMPT" ] || { echo "=== RESULT: FAIL (prompt absent) ==="; exit 1; }

ID="$(bash "$CLONE/tools/vault-identity.sh" get vault_id "$CLONE")"
SHORT="$(printf '%s' "${ID#sb-}" | cut -c1-8)"
IDENTITY_NAME="second-brain-vault-$SHORT"
LABEL_EXPECTED="$(bash "$CLONE/tools/vault-identity.sh" label-normalize "$(basename "$WS")")"
WANTED="second-brain-vault-$LABEL_EXPECTED"

# --- (b) the label is recorded -----------------------------------------------------
check "(b) workspace_label = $LABEL_EXPECTED dans VAULT-IDENTITY.md" sh -c "
  [ \"\$(bash '$CLONE/tools/vault-identity.sh' get workspace_label '$CLONE')\" = '$LABEL_EXPECTED' ]"
check "(b) server_name = $WANTED" sh -c "
  [ \"\$(bash '$CLONE/tools/vault-identity.sh' get server_name '$CLONE')\" = '$WANTED' ]"

# --- (c) the prompt names it ---------------------------------------------------------
NAMED="$(grep -o 'second-brain-vault-[A-Za-z0-9-]*' "$PROMPT" | sort -u | tr '\n' ' ')"
echo "    serveur(s) nomme(s) par le prompt : $NAMED"
check "(c) le prompt Pilote nomme $WANTED" sh -c "grep -q '$WANTED' '$PROMPT'"
check "(c) le prompt Pilote ne nomme pas le nom par identite ($IDENTITY_NAME)" sh -c "
  ! grep -q '$IDENTITY_NAME' '$PROMPT'"

# --- (d) install-vault-mcp.sh configures that same name, on a simulated profile -------
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
printf '{\n  "mcpServers": {}\n}\n' > "$DESKTOP"
printf 'model = "garde"\n' > "$CODEX_TOML"
printf '{"mcpServers": {}}\n' > "$CLAUDE_JSON"

bash "$CLONE/tools/install-vault-mcp.sh" --vault "$CLONE" "$WS" >/dev/null 2>&1
args_of() {
  uv run --no-project "$CLONE/tools/sb_installer_helper.py" mcp-server-args "$(N "$1")" "$2" 2>/dev/null | tr -d '\r' | tr '\n' ' '
}
CONFIGURED=1
for c in "$CLAUDE_JSON" "$CODEX_TOML" "$DESKTOP"; do
  [ -n "$(args_of "$c" "$WANTED")" ] || CONFIGURED=0
done
check "(d) le serveur $WANTED est configure dans les trois configurations" [ "$CONFIGURED" = "1" ]
NO_IDENTITY_NAME=1
for c in "$CLAUDE_JSON" "$CODEX_TOML" "$DESKTOP"; do
  [ -z "$(args_of "$c" "$IDENTITY_NAME")" ] || NO_IDENTITY_NAME=0
done
check "(d) aucun serveur au nom par identite n'est configure" [ "$NO_IDENTITY_NAME" = "1" ]

# --- (e) regenerating the prompt gives the same name -----------------------------------
bash "$CLONE/tools/project-bootstrap.sh" prompt "$PROJECT" >/dev/null 2>&1
check "(e) prompt regenere : il nomme toujours $WANTED" sh -c "
  grep -q '$WANTED' '$PROMPT' && ! grep -q '$IDENTITY_NAME' '$PROMPT'"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
