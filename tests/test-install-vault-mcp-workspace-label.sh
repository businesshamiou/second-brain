#!/usr/bin/env bash
# Mission 206 (Decision 162812 A-C, amends 152251 C): the MCP server of a Vault carries
# the name of its WORKSPACE, not the first characters of its identity:
# `second-brain-vault-<workspace_label>`, the label being the normalised name of the
# workspace folder, posed in VAULT-IDENTITY.md by the installer.
#
# Two throwaway Vaults on one SIMULATED profile (HOME, APPDATA, LOCALAPPDATA redirected,
# `claude` and `codex` replaced by stand-ins at the head of the PATH):
#   (P2) the label is normalised the same way in shell and in Python, on the same cases;
#   (P1) the installer poses `workspace_label` in VAULT-IDENTITY.md; `vault-identity.sh
#        get server_name` then gives `second-brain-vault-<label>`; the identity is
#        never rewritten (`vault_id` unchanged); without the key the name falls back to
#        the identity's 8 characters;
#   (P4/P5) the three configurations carry the new name; the former key of the SAME Vault
#        (`second-brain-vault-<8 characters of vault_id>`) is migrated; the generic
#        `workshops` server is retired on request, in the three; other servers untouched;
#        a key of a Vault (`second-brain-vault*`) is never retired;
#   (P3) two Vaults with the same label: the second is refused, both identities named,
#        the suffixed name proposed, nothing written (identity, configurations); the
#        proposed label is then accepted (`--label`);
#   (D0/a) `--skip-desktop` leaves the application's configuration byte for byte.
# Never the real profile: everything lives under a temporary folder (m206).
#
# usage: bash tests/test-install-vault-mcp-workspace-label.sh
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
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m206-label-XXXXXX")"
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

echo "=== M206 : le serveur porte le nom de son espace de travail ==="

# --- (P2) one normalisation, two implementations ------------------------------------
printf 'Workspaces\tworkspaces\nAcmeCorpWorks\tacmecorpworks\nMon Espace (2)\tmon-espace-2\na--b\ta-b\n\xc3\x89T\xc3\x89\tete\nCaf\xc3\xa9 No\xc3\xabl\tcafe-noel\n  -x- \tx\n***\t\n' > "$TMP/cases.tsv"
cat > "$TMP/norm.py" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("vault_mcp", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
for line in open(sys.argv[2], encoding="utf-8").read().split("\n"):
    if not line:
        continue
    given = line.split("\t")[0]
    sys.stdout.buffer.write((mod.normalize_label(given) + "\n").encode("utf-8"))
PY
PY_OUT="$(uv run --no-project python "$(N "$TMP/norm.py")" "$(N "$REPO_ROOT/tools/vault-mcp.py")" "$(N "$TMP/cases.tsv")" 2>&1 | tr -d '\r')"
i=0
while IFS="$(printf '\t')" read -r given want; do
  i=$((i + 1))
  got_sh="$(bash "$REPO_ROOT/tools/vault-identity.sh" label-normalize "$given" 2>&1 | tr -d '\r')"
  got_py="$(printf '%s\n' "$PY_OUT" | sed -n "${i}p")"
  if [ "$got_sh" = "$want" ] && [ "$got_py" = "$want" ]; then
    pass "(P2) « $given » -> « $want » en shell et en Python"
  else
    fail "(P2) « $given » : shell « $got_sh », Python « $got_py », attendu « $want »"
  fi
done < "$TMP/cases.tsv"

# --- Vaults and profile -----------------------------------------------------------------
mkdir -p "$TMP/a/Workspaces" "$TMP/b/Workspaces" "$TMP/c/Espace C"
for w in a b; do
  if ! sandbox_vault "$REPO_ROOT" "$TMP/$w/Workspaces/second-brain"; then
    echo "FAIL : Vault jetable $w non construit"
    exit 1
  fi
  bash "$TMP/$w/Workspaces/second-brain/tools/write-marker.sh" "$TMP/$w/Workspaces" >/dev/null
done
if ! sandbox_vault "$REPO_ROOT" "$TMP/c/Espace C/second-brain"; then
  echo "FAIL : Vault jetable c non construit"
  exit 1
fi
bash "$TMP/c/Espace C/second-brain/tools/write-marker.sh" "$TMP/c/Espace C" >/dev/null
VA="$TMP/a/Workspaces/second-brain"
VB="$TMP/b/Workspaces/second-brain"
VC="$TMP/c/Espace C/second-brain"
IDA="$(bash "$VA/tools/vault-identity.sh" get vault_id "$VA")"
IDB="$(bash "$VB/tools/vault-identity.sh" get vault_id "$VB")"
SHORTA="$(printf '%s' "${IDA#sb-}" | cut -c1-8)"
SHORTB="$(printf '%s' "${IDB#sb-}" | cut -c1-8)"
check "deux identites distinctes ($IDA, $IDB)" sh -c "[ -n '$IDA' ] && [ '$IDA' != '$IDB' ]"
check "avant l'installateur : pas de libelle, repli par identite (second-brain-vault-$SHORTA)" sh -c "[ -z \"\$(bash '$VA/tools/vault-identity.sh' get workspace_label '$VA')\" ] && [ \"\$(bash '$VA/tools/vault-identity.sh' get server_name '$VA')\" = 'second-brain-vault-$SHORTA' ]"

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

HELPER="$VA/tools/sb_installer_helper.py"
UVN="$(NW "$(command -v uv)")"
args_of() {
  uv run --no-project "$HELPER" mcp-server-args "$(N "$1")" "$2" 2>/dev/null | tr -d '\r' | tr '\n' ' '
}
present_in() {
  # present_in <name> <config>...: 0 if the server is declared in every config given
  local name="$1" c
  shift
  for c in "$@"; do
    [ -n "$(args_of "$c" "$name")" ] || return 1
  done
}
absent_from() {
  local name="$1" c
  shift
  for c in "$@"; do
    [ -z "$(args_of "$c" "$name")" ] || return 1
  done
}
seed() {
  # seed <name> <vault> <workspace>: one server in the three configurations.
  local vn wn
  vn="$(NW "$2")"; wn="$(NW "$3")"
  uv run --no-project "$HELPER" merge-mcp-json "$(N "$DESKTOP")" "$1" "$UVN" run --no-project x --vault "$vn" --allow "$wn" >/dev/null
  claude mcp add -s user "$1" -- "$UVN" run --no-project x --vault "$vn" --allow "$wn"
  codex mcp add "$1" -- "$UVN" run --no-project x --vault "$vn" --allow "$wn"
}
ALL3=("$CLAUDE_JSON" "$CODEX_TOML" "$DESKTOP")

printf '{\n  "mcpServers": {\n    "autre": {"command": "autre", "args": ["x"]}\n  }\n}\n' > "$DESKTOP"
printf 'model = "garde"\n\n[mcp_servers.autre]\ncommand = "autre"\nargs = ["x"]\n' > "$CODEX_TOML"
printf '{"mcpServers": {"autre": {"type": "stdio", "command": "autre", "args": ["x"], "env": {}}}}\n' > "$CLAUDE_JSON"
# The state of the real machine before the Mission: the generic server, and the Vault's
# server under its identity name, in the three configurations.
seed workshops "$TMP" "$TMP"
seed "second-brain-vault-$SHORTA" "$VA" "$TMP/a/Workspaces"

# --- (P1, P4, P5) Vault A: label posed, former key migrated, workshops retired --------------
WSA="$TMP/a/Workspaces"
OUT_A="$(bash "$VA/tools/install-vault-mcp.sh" "$WSA" --retire workshops --lang FR 2>&1)"
RC_A=$?
check "(P1) Vault A : sortie 0" [ "$RC_A" = "0" ]
SA="$(bash "$VA/tools/vault-identity.sh" get server_name "$VA")"
check "(P1) workspace_label = workspaces dans VAULT-IDENTITY.md" [ "$(bash "$VA/tools/vault-identity.sh" get workspace_label "$VA")" = "workspaces" ]
check "(P1) vid_server_name = second-brain-vault-workspaces" [ "$SA" = "second-brain-vault-workspaces" ]
check "(P1) vault_id inchange ($IDA)" [ "$(bash "$VA/tools/vault-identity.sh" get vault_id "$VA")" = "$IDA" ]
check "(P4/P5) $SA dans les trois configurations" present_in "$SA" "${ALL3[@]}"
check "(P4/P5) dossier autorise = l'espace de travail" sh -c "case \"\$1\" in *'--allow $(NW "$WSA")'*) exit 0;; *) exit 1;; esac" _ "$(args_of "$DESKTOP" "$SA")"
check "(P4/P5) l'ancienne cle du meme Vault (second-brain-vault-$SHORTA) migree dans les trois" absent_from "second-brain-vault-$SHORTA" "${ALL3[@]}"
check "(P4/P5) workshops retire des trois" absent_from workshops "${ALL3[@]}"
check "(P4/P5) autres serveurs conserves" sh -c "grep -q '\"autre\"' '$DESKTOP' && grep -q '\"autre\"' '$CLAUDE_JSON' && grep -q 'mcp_servers.autre' '$CODEX_TOML' && grep -q 'model = \"garde\"' '$CODEX_TOML'"
check "(P4/P5) le retrait est dit (retiré), avec l'ancienne entree citee (workshops)" sh -c "case \"\$1\" in *workshops*retiré*) exit 0;; *) exit 1;; esac" _ "$OUT_A"

# idempotent
FP1="$(sha_of "$DESKTOP") $(sha_of "$CLAUDE_JSON") $(sha_of "$CODEX_TOML") $(sha_of "$VA/VAULT-IDENTITY.md")"
bash "$VA/tools/install-vault-mcp.sh" "$WSA" --retire workshops --lang FR >/dev/null 2>&1
FP2="$(sha_of "$DESKTOP") $(sha_of "$CLAUDE_JSON") $(sha_of "$CODEX_TOML") $(sha_of "$VA/VAULT-IDENTITY.md")"
check "(P1) second passage : configurations et identite octet pour octet" [ "$FP1" = "$FP2" ]

# --- (P1) fallbacks ---------------------------------------------------------------------------------
mkdir -p "$TMP/fb"
grep -v '^workspace_label:' "$VA/VAULT-IDENTITY.md" > "$TMP/fb/VAULT-IDENTITY.md"
check "(P1) cle retiree d'une copie : nom par identite" [ "$(bash "$VA/tools/vault-identity.sh" get server_name "$TMP/fb")" = "second-brain-vault-$SHORTA" ]
printf -- '---\r\nstatus: generated\r\nvault_id: "%s"\r\nworkspace_label: "Mon Espace (2)"\r\n---\r\n' "$IDA" > "$TMP/fb/VAULT-IDENTITY.md"
check "(P1) libelle en CRLF et non normalise : lu et normalise" [ "$(bash "$VA/tools/vault-identity.sh" get server_name "$TMP/fb")" = "second-brain-vault-mon-espace-2" ]
rm -f "$TMP/fb/VAULT-IDENTITY.md"
check "(P1) sans VAULT-IDENTITY.md : pas de nom (l'installateur refuse)" [ -z "$(bash "$VA/tools/vault-identity.sh" get server_name "$TMP/fb")" ]

# --- (P3) two Vaults, same label ---------------------------------------------------------------------
WSB="$TMP/b/Workspaces"
FP_CFG="$(sha_of "$DESKTOP") $(sha_of "$CLAUDE_JSON") $(sha_of "$CODEX_TOML")"
FP_IDB="$(sha_of "$VB/VAULT-IDENTITY.md")"
OUT_B="$(bash "$VB/tools/install-vault-mcp.sh" "$WSB" --lang FR 2>&1)"
RC_B=$?
check "(P3) Vault B, meme libelle : refuse (sortie 1)" [ "$RC_B" = "1" ]
check "(P3) le refus nomme les deux identites ($IDA, $IDB)" sh -c "case \"\$1\" in *'$IDA'*) case \"\$1\" in *'$IDB'*) exit 0;; esac;; esac; exit 1" _ "$OUT_B"
check "(P3) le refus propose second-brain-vault-workspaces-$SHORTB" has "$OUT_B" "second-brain-vault-workspaces-$SHORTB"
check "(P3) rien n'est ecrit : trois configurations inchangees" [ "$(sha_of "$DESKTOP") $(sha_of "$CLAUDE_JSON") $(sha_of "$CODEX_TOML")" = "$FP_CFG" ]
check "(P3) rien n'est ecrit : VAULT-IDENTITY.md du Vault B inchange, sans libelle" sh -c "[ '$(sha_of "$VB/VAULT-IDENTITY.md")' = '$FP_IDB' ] && [ -z \"\$(bash '$VB/tools/vault-identity.sh' get workspace_label '$VB')\" ]"
BEFORE_A="$(args_of "$DESKTOP" "$SA")|$(args_of "$CLAUDE_JSON" "$SA")|$(args_of "$CODEX_TOML" "$SA")"
bash "$VB/tools/install-vault-mcp.sh" "$WSB" --label "workspaces-$SHORTB" --lang FR >/dev/null 2>&1
check "(P3) le libelle propose est accepte : sortie 0" [ "$?" = "0" ]
SB="$(bash "$VB/tools/vault-identity.sh" get server_name "$VB")"
check "(P3) Vault B : $SB = second-brain-vault-workspaces-$SHORTB, dans les trois" sh -c "[ '$SB' = 'second-brain-vault-workspaces-$SHORTB' ]"
check "(P3) Vault B present dans les trois configurations" present_in "$SB" "${ALL3[@]}"
AFTER_A="$(args_of "$DESKTOP" "$SA")|$(args_of "$CLAUDE_JSON" "$SA")|$(args_of "$CODEX_TOML" "$SA")"
check "(P3) le serveur du Vault A est intact apres le Vault B" [ "$BEFORE_A" = "$AFTER_A" ]

# --- (P4, witness) a Vault's key is never retired ----------------------------------------------------
FP_W="$(sha_of "$DESKTOP") $(sha_of "$CLAUDE_JSON") $(sha_of "$CODEX_TOML")"
OUT_W="$(bash "$VA/tools/install-vault-mcp.sh" "$WSA" --retire "$SB" --lang FR 2>&1)"
RC_W=$?
check "(P4) temoin : retirer la cle d'un Vault est refuse (sortie 1)" [ "$RC_W" = "1" ]
check "(P4) temoin : le refus est dit (retrait refusé)" has "$OUT_W" "retrait refusé"
check "(P4) temoin : le serveur du Vault B est toujours la, configurations inchangees" sh -c "[ '$(sha_of "$DESKTOP") $(sha_of "$CLAUDE_JSON") $(sha_of "$CODEX_TOML")' = '$FP_W' ]"

# --- (D0 a) --skip-desktop ------------------------------------------------------------------------------
WSC="$TMP/c/Espace C"
FP_D="$(sha_of "$DESKTOP")"
OUT_C="$(bash "$VC/tools/install-vault-mcp.sh" "$WSC" --skip-desktop --lang FR 2>&1)"
check "(D0) --skip-desktop : sortie 0" [ "$?" = "0" ]
SC="$(bash "$VC/tools/vault-identity.sh" get server_name "$VC")"
check "(D0) libelle d'un dossier a espace : $SC = second-brain-vault-espace-c" [ "$SC" = "second-brain-vault-espace-c" ]
check "(D0) --skip-desktop : la configuration de l'application est octet pour octet" [ "$(sha_of "$DESKTOP")" = "$FP_D" ]
check "(D0) --skip-desktop : Claude Code et Codex ont le serveur" present_in "$SC" "$CLAUDE_JSON" "$CODEX_TOML"
check "(D0) --skip-desktop : dit (non modifiée)" has "$OUT_C" "non modifiée"

export HOME="$REAL_HOME"
echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
