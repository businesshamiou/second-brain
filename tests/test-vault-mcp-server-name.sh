#!/usr/bin/env bash
# Mission 205 (Decision 152251 C, Mission 191-C01): the Vault's MCP server announces
# itself under the name derived from its identity, the same name the installer writes
# in the configuration -- `second-brain-vault-<8 characters of vault_id after sb->` --
# and no longer under the fixed name `second-brain-vault` in every Vault. The desktop
# application keeps one server per announced name: two Vaults announcing the same
# name were one server, the second Vault invisible (measured on 2026-09-20).
#
# Oracles (PASS expected):
#   (a) two servers ALIVE at the same time, each with its own identity: two
#       `initialize`, two DISTINCT names, each equal to what
#       `tools/vault-identity.sh get server_name` gives for its Vault;
#   (b) a Vault WITHOUT identity (skeleton, `status: template`, empty values; or no
#       file at all) announces `second-brain-vault`, with a clean standard output
#       (only JSON-RPC lines) and nothing wrong on standard error;
#   (c) an identity file with CRLF line endings (Windows clone with autocrlf) and an
#       unquoted `vault_id` give the same name as the LF, quoted form;
#   (d) with `--vault` absent the identity is read from the script's own root (`..`),
#       never from an `--allow` folder; with `--vault` given, from that one;
#   (e) the protocol is unchanged: `tools/list` is the same as the old script's (same
#       tools, same schemas, same count);
#   (f) the old script (commit f34b405) announces the same fixed name for two
#       different Vaults -- the defect reproduced, when that history is available;
#   (g) Mission 206 (Decision 162812 A): a Vault whose identity carries `workspace_label`
#       announces `second-brain-vault-<label>`, the same name as
#       `tools/vault-identity.sh get server_name`; the label is normalised, CRLF is
#       tolerated, an empty label falls back to the identity, a label without a
#       generated identity keeps the fixed name.
#
# Writes only in a temporary folder (prefix m205).
#
# usage: bash tests/test-vault-mcp-server-name.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- le serveur se lance par uv"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m205-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
NATIVE() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

# make_vault <name> <identity mode> [script]: a Vault-shaped folder holding the server script.
#   ids modes: lf | crlf | unquoted | short | template | empty | none | label | labelcrlf | labelnoid | labelempty
make_vault() {
  local dir="$TMP/$1" mode="$2" script="${3:-$REPO_ROOT/tools/vault-mcp.py}"
  mkdir -p "$dir/tools"
  cp "$script" "$dir/tools/vault-mcp.py"
  local id="${4:-sb-aaaaaaaa11111111}"
  case "$mode" in
    lf)       printf -- '---\ntype: vault-identity\nstatus: generated\nvault_id: "%s"\nvault_origin: "x"\n---\n\n# body\nvault_id: "sb-zzzzzzzz"\n' "$id" > "$dir/VAULT-IDENTITY.md" ;;
    crlf)     printf -- '---\r\ntype: vault-identity\r\nstatus: generated\r\nvault_id: "%s"\r\nvault_origin: "x"\r\n---\r\n' "$id" > "$dir/VAULT-IDENTITY.md" ;;
    unquoted) printf -- '---\ntype: vault-identity\nstatus: generated\nvault_id: %s\n---\n' "$id" > "$dir/VAULT-IDENTITY.md" ;;
    short)    printf -- '---\nstatus: generated\nvault_id: "sb-abc"\n---\n' > "$dir/VAULT-IDENTITY.md" ;;
    template) printf -- '---\ntype: vault-identity\nstatus: template\nvault_id: ""\nvault_origin: ""\n---\n\n# skeleton\n' > "$dir/VAULT-IDENTITY.md" ;;
    empty)    : > "$dir/VAULT-IDENTITY.md" ;;
    none)     : ;;
    label)      printf -- '---
type: vault-identity
status: generated
vault_id: "%s"
vault_origin: "x"
workspace_label: "workspaces"
---
' "$id" > "$dir/VAULT-IDENTITY.md" ;;
    labelcrlf)  printf -- '---
status: generated
vault_id: "%s"
workspace_label: "Mon Espace (2)"
---
' "$id" > "$dir/VAULT-IDENTITY.md" ;;
    labelnoid)  printf -- '---
type: vault-identity
status: template
vault_id: ""
workspace_label: "workspaces"
---
' > "$dir/VAULT-IDENTITY.md" ;;
    labelempty) printf -- '---
status: generated
vault_id: "%s"
workspace_label: ""
---
' "$id" > "$dir/VAULT-IDENTITY.md" ;;
  esac
}

# The client: starts every server it is given AT THE SAME TIME, sends initialize and
# tools/list to each before reading any answer, then closes them. One line per server:
#   <label> <name> <tools sha> <ntools> <clean 0|1> <rc> <version>
cat > "$TMP/client.py" <<'PY'
import hashlib, json, subprocess, sys
specs = [a.split("=", 1) for a in sys.argv[1:]]          # label=script|allow|vault-or-empty
procs = []
for label, spec in specs:
    script, allow, vault = spec.split("|")
    cmd = ["uv", "run", "--no-project", script, "--allow", allow] + (["--vault", vault] if vault else [])
    procs.append((label, subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)))
msgs = [
    {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "t", "version": "0"}}},
    {"jsonrpc": "2.0", "method": "notifications/initialized"},
    {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
]
payload = ("\n".join(json.dumps(m) for m in msgs) + "\n").encode("utf-8")
for label, p in procs:
    p.stdin.write(payload); p.stdin.flush()            # all servers are alive and hold their request
for label, p in procs:
    out, err = p.communicate(timeout=90)
    clean, init, tools = 1, None, None
    for raw in out.decode("utf-8").splitlines():
        if not raw.strip():
            continue
        try:
            m = json.loads(raw)
        except ValueError:
            clean = 0
            continue
        if m.get("jsonrpc") != "2.0":
            clean = 0
        if m.get("id") == 1: init = m["result"]
        if m.get("id") == 2: tools = m["result"]
    text = err.decode("utf-8", "replace")
    if "Traceback" in text:
        clean = 0
    sha = hashlib.sha256(json.dumps(tools, sort_keys=True).encode()).hexdigest()[:12]
    print("\t".join([label, init["serverInfo"]["name"], sha, str(len(tools["tools"])), str(clean), str(p.returncode), init["serverInfo"]["version"]]))
PY
run_servers() { uv run --no-project python "$(NATIVE "$TMP/client.py")" "$@" 2>&1; }
field() { printf '%s\n' "$1" | awk -F '\t' -v l="$2" -v n="$3" '$1 == l { print $n; exit }'; }

ALLOW="$(NATIVE "$TMP")"

# --- (a) two servers alive side by side, two identities ------------------------------------
make_vault v1 lf "$REPO_ROOT/tools/vault-mcp.py" sb-aaaaaaaa11111111
make_vault v2 lf "$REPO_ROOT/tools/vault-mcp.py" sb-bbbbbbbb22222222
OUT="$(run_servers "one=$(NATIVE "$TMP/v1/tools/vault-mcp.py")|$ALLOW|" "two=$(NATIVE "$TMP/v2/tools/vault-mcp.py")|$ALLOW|")"
N1="$(field "$OUT" one 2)"; N2="$(field "$OUT" two 2)"
S1="$(bash "$REPO_ROOT/tools/vault-identity.sh" get server_name "$TMP/v1")"; S2="$(bash "$REPO_ROOT/tools/vault-identity.sh" get server_name "$TMP/v2")"
if [ "$N1" = "second-brain-vault-aaaaaaaa" ] && [ "$N2" = "second-brain-vault-bbbbbbbb" ] && [ "$N1" != "$N2" ]; then
  pass "(a) deux serveurs vivants, deux noms distincts : $N1 et $N2"
else
  fail "(a) deux serveurs : '$N1' et '$N2' (attendu ...-aaaaaaaa et ...-bbbbbbbb)"
fi
[ "$N1" = "$S1" ] && [ "$N2" = "$S2" ] && pass "(a) chaque nom annonce = vault-identity.sh get server_name ($S1, $S2)" \
  || fail "(a) nom annonce different de celui de l'installateur : '$N1'/'$S1', '$N2'/'$S2'"

# --- (b) no identity -----------------------------------------------------------------------------
make_vault v3 template "$REPO_ROOT/tools/vault-mcp.py"
make_vault v4 none "$REPO_ROOT/tools/vault-mcp.py"
make_vault v5 empty "$REPO_ROOT/tools/vault-mcp.py"
OUT="$(run_servers "tpl=$(NATIVE "$TMP/v3/tools/vault-mcp.py")|$ALLOW|" "none=$(NATIVE "$TMP/v4/tools/vault-mcp.py")|$ALLOW|" "empty=$(NATIVE "$TMP/v5/tools/vault-mcp.py")|$ALLOW|")"
for k in tpl none empty; do
  if [ "$(field "$OUT" $k 2)" = "second-brain-vault" ] && [ "$(field "$OUT" $k 5)" = "1" ] && [ "$(field "$OUT" $k 6)" = "0" ]; then
    pass "(b) Vault sans identite ($k) : second-brain-vault, sortie propre, exit 0"
  else
    fail "(b) Vault sans identite ($k) : nom '$(field "$OUT" $k 2)', propre=$(field "$OUT" $k 5), rc=$(field "$OUT" $k 6)"
  fi
done
[ -z "$(bash "$REPO_ROOT/tools/vault-identity.sh" get server_name "$TMP/v3")" ] && pass "(b) l'installateur refuse ce Vault (nom vide) : le repli du serveur n'est pas celui de l'installateur, dit" \
  || fail "(b) vault-identity.sh donne un nom a un Vault sans identite"

# --- (c) CRLF, unquoted, short ----------------------------------------------------------------------
make_vault v6 crlf "$REPO_ROOT/tools/vault-mcp.py" sb-cccccccc33333333
make_vault v7 unquoted "$REPO_ROOT/tools/vault-mcp.py" sb-dddddddd44444444
make_vault v8 short "$REPO_ROOT/tools/vault-mcp.py"
OUT="$(run_servers "crlf=$(NATIVE "$TMP/v6/tools/vault-mcp.py")|$ALLOW|" "unq=$(NATIVE "$TMP/v7/tools/vault-mcp.py")|$ALLOW|" "short=$(NATIVE "$TMP/v8/tools/vault-mcp.py")|$ALLOW|")"
for pair in "crlf:v6" "unq:v7" "short:v8"; do
  k="${pair%%:*}"; v="${pair#*:}"
  want="$(bash "$REPO_ROOT/tools/vault-identity.sh" get server_name "$TMP/$v")"
  [ -n "$want" ] && [ "$(field "$OUT" $k 2)" = "$want" ] && pass "(c) $k : $(field "$OUT" $k 2) = nom de l'installateur" \
    || fail "(c) $k : annonce '$(field "$OUT" $k 2)', installateur '$want'"
done

# --- (g) workspace label (Mission 206) ------------------------------------------------------------------
make_vault g1 label "$REPO_ROOT/tools/vault-mcp.py" sb-eeeeeeee55555555
make_vault g2 labelcrlf "$REPO_ROOT/tools/vault-mcp.py" sb-ffffffff66666666
make_vault g3 labelnoid "$REPO_ROOT/tools/vault-mcp.py"
make_vault g4 labelempty "$REPO_ROOT/tools/vault-mcp.py" sb-99999999aaaaaaaa
OUT="$(run_servers "lab=$(NATIVE "$TMP/g1/tools/vault-mcp.py")|$ALLOW|" "crlf=$(NATIVE "$TMP/g2/tools/vault-mcp.py")|$ALLOW|" "noid=$(NATIVE "$TMP/g3/tools/vault-mcp.py")|$ALLOW|" "empty=$(NATIVE "$TMP/g4/tools/vault-mcp.py")|$ALLOW|")"
for pair in "lab:g1:second-brain-vault-workspaces" "crlf:g2:second-brain-vault-mon-espace-2" "empty:g4:second-brain-vault-99999999"; do
  k="${pair%%:*}"; rest="${pair#*:}"; v="${rest%%:*}"; want="${rest#*:}"
  inst="$(bash "$REPO_ROOT/tools/vault-identity.sh" get server_name "$TMP/$v")"
  if [ "$(field "$OUT" $k 2)" = "$want" ] && [ "$inst" = "$want" ] && [ "$(field "$OUT" $k 5)" = "1" ]; then
    pass "(g) $k : le serveur annonce $want, comme l'installateur, sortie propre"
  else
    fail "(g) $k : annonce '$(field "$OUT" $k 2)', installateur '$inst', attendu '$want'"
  fi
done
[ "$(field "$OUT" noid 2)" = "second-brain-vault" ] && [ -z "$(bash "$REPO_ROOT/tools/vault-identity.sh" get server_name "$TMP/g3")" ]   && pass "(g) libelle sans identite generee : nom fixe, l'installateur refuse"   || fail "(g) libelle sans identite : annonce '$(field "$OUT" noid 2)'"

# --- (d) --vault absent: the script's own root; --vault given: that one ---------------------------------
OUT="$(run_servers "own=$(NATIVE "$TMP/v1/tools/vault-mcp.py")|$(NATIVE "$TMP/v2")|" "given=$(NATIVE "$TMP/v1/tools/vault-mcp.py")|$ALLOW|$(NATIVE "$TMP/v2")")"
[ "$(field "$OUT" own 2)" = "second-brain-vault-aaaaaaaa" ] && pass "(d) --vault absent : identite de la racine du script, non du dossier --allow (v2)" \
  || fail "(d) --vault absent : '$(field "$OUT" own 2)' (attendu ...-aaaaaaaa)"
[ "$(field "$OUT" given 2)" = "second-brain-vault-bbbbbbbb" ] && pass "(d) --vault donne : identite de ce Vault" \
  || fail "(d) --vault donne : '$(field "$OUT" given 2)' (attendu ...-bbbbbbbb)"

# --- (e) and (f): the old script ------------------------------------------------------------------------------
if git -C "$REPO_ROOT" cat-file -e 'f34b405^{commit}' 2>/dev/null; then
  git -C "$REPO_ROOT" show f34b405:tools/vault-mcp.py > "$TMP/old-vault-mcp.py"
  make_vault o1 lf "$TMP/old-vault-mcp.py" sb-aaaaaaaa11111111
  make_vault o2 lf "$TMP/old-vault-mcp.py" sb-bbbbbbbb22222222
  OUT_OLD="$(run_servers "o1=$(NATIVE "$TMP/o1/tools/vault-mcp.py")|$ALLOW|" "o2=$(NATIVE "$TMP/o2/tools/vault-mcp.py")|$ALLOW|")"
  if [ "$(field "$OUT_OLD" o1 2)" = "second-brain-vault" ] && [ "$(field "$OUT_OLD" o2 2)" = "second-brain-vault" ]; then
    pass "(f) temoin rouge : l'ancien script annonce 'second-brain-vault' pour deux Vaults distincts"
  else
    fail "(f) temoin rouge : l'ancien script annonce '$(field "$OUT_OLD" o1 2)' et '$(field "$OUT_OLD" o2 2)'"
  fi
  NEW1="$(run_servers "n1=$(NATIVE "$TMP/v1/tools/vault-mcp.py")|$ALLOW|")"
  if [ "$(field "$OUT_OLD" o1 3)" = "$(field "$NEW1" n1 3)" ] && [ "$(field "$OUT_OLD" o1 4)" = "$(field "$NEW1" n1 4)" ]; then
    pass "(e) tools/list identique a celui de l'ancien script ($(field "$NEW1" n1 4) outils, empreinte $(field "$NEW1" n1 3))"
  else
    fail "(e) tools/list different : ancien $(field "$OUT_OLD" o1 3)/$(field "$OUT_OLD" o1 4), nouveau $(field "$NEW1" n1 3)/$(field "$NEW1" n1 4)"
  fi
else
  echo "  SKIP - (e) et (f) : l'historique f34b405 est absent de ce clone : temoin rouge non joue"
fi

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
