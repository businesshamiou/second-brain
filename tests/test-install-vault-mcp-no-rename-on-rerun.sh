#!/usr/bin/env bash
# P4 of report 227 (Mission 230): re-running tools/install-vault-mcp.sh on a
# Vault whose identity carries NO `workspace_label` must not rename its server.
#
# The company's Vault was configured by identity -- `second-brain-vault-<8
# characters of vault_id>` -- because it was installed before Mission 206, and
# its VAULT-IDENTITY.md carries no `workspace_label`. The tool falls back on the
# normalised name of the workspace folder when no label is recorded, so a re-run
# (the very thing `second-brain update` tells the participant to do) renamed the
# server to `second-brain-vault-<folder>` and the PILOT-PROMPT.md of each of its
# projects then named a server that no longer existed.
#
# A re-run never renames: the name already configured for THIS Vault wins. The
# fallback on the folder name stays, for a FIRST configuration and for a Vault
# whose label is already recorded, and `--label` still renames explicitly.
#
# Everything runs on a SIMULATED profile (HOME, APPDATA, LOCALAPPDATA
# redirected, `claude` and `codex` replaced by stand-ins at the head of the
# PATH), as tests/test-install-vault-mcp-workspace-label.sh does. Never the
# real profile.
#
#   (a) RED of the audit: a Vault with no label, its server already configured
#       by identity in the three configurations -> a re-run keeps that name;
#       nothing is renamed, no label is written into VAULT-IDENTITY.md, and the
#       name the projects' PILOT-PROMPT.md would carry is unchanged;
#   (b) first configuration, no label, nothing configured yet -> the fallback on
#       the workspace folder name still applies, and the label is recorded;
#   (c) `--label` still renames explicitly, on that same Vault of case (a), and
#       migrates the former name;
#   (d) a Vault whose label is already recorded is unaffected: its name stays
#       the label's, whatever the folder is called.
#
# usage: bash tests/test-install-vault-mcp-no-rename-on-rerun.sh
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
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m230-rename-XXXXXX")"
trap 'export HOME="$REAL_HOME"; [ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
N() { sandbox_native_path "$1"; }
NW() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi
}

echo "=== P4 : une relance ne renomme jamais le serveur d'un Vault sans libelle ==="

# --- Three throwaway Vaults, each in its own workspace ----------------------------
mkdir -p "$TMP/co/AtelierNordWorks" "$TMP/new/Workspaces" "$TMP/lab/Atelier"
for w in "co/AtelierNordWorks" "new/Workspaces" "lab/Atelier"; do
  if ! sandbox_vault "$REPO_ROOT" "$TMP/$w/second-brain"; then
    echo "FAIL : Vault jetable $w non construit"
    exit 1
  fi
  bash "$TMP/$w/second-brain/tools/write-marker.sh" "$TMP/$w" >/dev/null
done
CO="$TMP/co/AtelierNordWorks/second-brain"       # no label, already configured
NEW="$TMP/new/Workspaces/second-brain"          # no label, nothing configured
LAB="$TMP/lab/Atelier/second-brain"             # label recorded
ID_CO="$(bash "$CO/tools/vault-identity.sh" get vault_id "$CO")"
SHORT_CO="$(printf '%s' "${ID_CO#sb-}" | cut -c1-8)"
NAME_CO="second-brain-vault-$SHORT_CO"
check "Vault « entreprise » : aucun libelle, nom par identite ($NAME_CO)" sh -c "
  [ -z \"\$(bash '$CO/tools/vault-identity.sh' get workspace_label '$CO')\" ] &&
  [ \"\$(bash '$CO/tools/vault-identity.sh' get server_name '$CO')\" = '$NAME_CO' ]"

# --- Simulated profile and stand-ins ------------------------------------------------
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

HELPER="$CO/tools/sb_installer_helper.py"
UVN="$(NW "$(command -v uv)")"
args_of() {
  uv run --no-project "$HELPER" mcp-server-args "$(N "$1")" "$2" 2>/dev/null | tr -d '\r' | tr '\n' ' '
}
present_in() {
  local name="$1" c
  shift
  for c in "$@"; do [ -n "$(args_of "$c" "$name")" ] || return 1; done
}
absent_from() {
  local name="$1" c
  shift
  for c in "$@"; do [ -z "$(args_of "$c" "$name")" ] || return 1; done
}
ALL3=("$CLAUDE_JSON" "$CODEX_TOML" "$DESKTOP")

printf '{\n  "mcpServers": {\n    "autre": {"command": "autre", "args": ["x"]}\n  }\n}\n' > "$DESKTOP"
printf 'model = "garde"\n\n[mcp_servers.autre]\ncommand = "autre"\nargs = ["x"]\n' > "$CODEX_TOML"
printf '{"mcpServers": {"autre": {"type": "stdio", "command": "autre", "args": ["x"], "env": {}}}}\n' > "$CLAUDE_JSON"

# --- (a) the company's case: configured by identity, no label ----------------------
# First configured under the identity name, the way an installation made before
# Mission 206 left it: --label poses that exact name, then the label is wiped
# from VAULT-IDENTITY.md, which is the state the audit measured.
bash "$CO/tools/install-vault-mcp.sh" --vault "$CO" --label "$SHORT_CO" "$TMP/co/AtelierNordWorks" >/dev/null 2>&1
uv run --no-project - "$CO/VAULT-IDENTITY.md" <<'PY'
import sys
p = sys.argv[1]
lines = [l for l in open(p, encoding="utf-8").read().split("\n") if not l.startswith("workspace_label:")]
open(p, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
PY
check "(a) etat de depart : aucun libelle dans VAULT-IDENTITY.md" sh -c "
  [ -z \"\$(bash '$CO/tools/vault-identity.sh' get workspace_label '$CO')\" ]"
check "(a) etat de depart : serveur $NAME_CO dans les trois configurations" present_in "$NAME_CO" "${ALL3[@]}"

OUT_A="$(bash "$CO/tools/install-vault-mcp.sh" --vault "$CO" "$TMP/co/AtelierNordWorks" 2>&1)"
printf '%s\n' "$OUT_A" | grep -iE 'serveur|server|libell|label' | head -n 4 | sed 's/^/    /'
check "(a) relance : le nom configure est garde ($NAME_CO)" present_in "$NAME_CO" "${ALL3[@]}"
check "(a) relance : aucun serveur second-brain-vault-ateliernordworks cree" absent_from "second-brain-vault-ateliernordworks" "${ALL3[@]}"
check "(a) relance : aucun libelle ecrit dans VAULT-IDENTITY.md" sh -c "
  [ -z \"\$(bash '$CO/tools/vault-identity.sh' get workspace_label '$CO')\" ]"
check "(a) relance : le nom que nommeraient les PILOT-PROMPT est inchange" sh -c "
  [ \"\$(bash '$CO/tools/vault-identity.sh' get server_name '$CO')\" = '$NAME_CO' ]"
check "(a) relance : le serveur pointe bien vers ce Vault" sh -c "
  case \"\$(uv run --no-project '$HELPER' mcp-server-args '$(N "$CLAUDE_JSON")' '$NAME_CO' | tr -d '\r' | tr '\n' ' ')\" in
    *'second-brain'*) exit 0;; *) exit 1;; esac"
check "(a) le serveur « autre » n'est pas touche" present_in "autre" "${ALL3[@]}"

# --- (b) a first configuration still takes the workspace folder name ---------------
OUT_B="$(bash "$NEW/tools/install-vault-mcp.sh" --vault "$NEW" "$TMP/new/Workspaces" 2>&1)"
check "(b) premiere configuration : le repli sur le dossier d'espace s'applique" present_in "second-brain-vault-workspaces" "${ALL3[@]}"
check "(b) premiere configuration : le libelle est enregistre" sh -c "
  [ \"\$(bash '$NEW/tools/vault-identity.sh' get workspace_label '$NEW')\" = 'workspaces' ]"

# --- (c) --label still renames explicitly -------------------------------------------
OUT_C="$(bash "$CO/tools/install-vault-mcp.sh" --vault "$CO" --label "entreprise" "$TMP/co/AtelierNordWorks" 2>&1)"
check "(c) --label : le serveur prend le nouveau nom" present_in "second-brain-vault-entreprise" "${ALL3[@]}"
check "(c) --label : l'ancien nom par identite est migre (retire)" absent_from "$NAME_CO" "${ALL3[@]}"
check "(c) --label : le libelle est enregistre" sh -c "
  [ \"\$(bash '$CO/tools/vault-identity.sh' get workspace_label '$CO')\" = 'entreprise' ]"

# --- (d) a Vault whose label is recorded is unaffected ---------------------------------
bash "$LAB/tools/install-vault-mcp.sh" --vault "$LAB" --label "labo" "$TMP/lab/Atelier" >/dev/null 2>&1
OUT_D="$(bash "$LAB/tools/install-vault-mcp.sh" --vault "$LAB" "$TMP/lab/Atelier" 2>&1)"
check "(d) libelle enregistre : la relance garde ce libelle, pas celui du dossier" sh -c "
  [ \"\$(bash '$LAB/tools/vault-identity.sh' get workspace_label '$LAB')\" = 'labo' ]"
check "(d) ... et le serveur reste second-brain-vault-labo" present_in "second-brain-vault-labo" "${ALL3[@]}"
check "(d) aucun serveur second-brain-vault-atelier cree" absent_from "second-brain-vault-atelier" "${ALL3[@]}"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
