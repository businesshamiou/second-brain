#!/usr/bin/env bash
# Mission 234, step 10: behaviour tests of the agents, one headless call per
# entry scenario of the matrix at the head of skills/session-start/SKILL.md.
# Each scenario runs `claude -p` (JSON output) in a throwaway workspace built
# under the declared temporary folder from the working tree of this Vault, and
# checks the FIRST LINE of the answer and the NEXT GESTURE (an order printed, a
# refusal, nothing written, a project created).
#
#   Executor side: a shell, the throwaway folder as working directory; the
#   built-in tools limited to Bash, Read, Glob, Grep and Skill, all
#   pre-approved, push and rm denied (anything else that would prompt is
#   denied). A first run pre-approved only some Bash commands: the agents
#   probed with PowerShell, were refused, and fell back to the Pilot role
#   (Mission 234, measured) -- PowerShell is left out, Bash allowed whole.
#   Pilot side: no shell -- `--restricted` and no built-in tool at all; one
#   MCP file server, the Vault's own (tools/vault-mcp.py), bounded to the
#   throwaway workspace; the Project's instructions as appended system prompt.
#
# Mission 236 adds three scenarios of the sb command: S1 an Executor in Claude
# Code with the plugin sb (--plugin-dir) types /sb:status; S2 an Executor
# without the plugin receives "sb status"; S3 a Pilot (no shell) receives
# "sb help" after the project's path.
#
# Mission 242 writes three scenarios for hosts other than Claude, NOT PLAYED:
# played only when named on the command line (`run-agent-evals.sh P4`), never
# by a run without arguments; the first play is the Owner's gesture, one model
# call each (the host's own subscription or key):
#   P4  Pilot in Codex: `codex exec`, --ignore-user-config, the Vault's server
#       only (-c mcp_servers...), sandbox read-only, --disable shell_tool; the
#       common trunk then the project's path as the first message. A pass shows
#       READY on the first line and the project's canary.
#   P5  Pilot in Gemini CLI: `gemini -p`, --approval-mode plan, a project-level
#       .gemini/settings.json with the Vault's server only; the same message
#       and the same expectation as P4.
#   E6  Executor in Codex: `codex exec` in the adopted demo project,
#       workspace-write; "Ouvre la session."; a pass shows READY or NOT-READY
#       on the first line and nothing written by the opening.
# `--list` prints every scenario, its host and whether a run without
# arguments plays it; no call, no workspace built.
#
# Mission 244 writes five scenarios of the client's journey (A1-A3, C1, C2),
# NOT PLAYED either: played only when named, like P4.
#
# MODEL CALLS: one per scenario played (at most 11 here, without naming any). This line of
# tests/suite.tsv is `on-demand`: never played by default, never by CI.
#
# BILLING (Mission 237, measured by reading, no call): the `total_cost_usd`
# each call reports is an ESTIMATE computed by Claude Code. On the laboratory
# workstation (2026-09-26) `claude auth status` says authMethod claude.ai,
# subscriptionType max, and no ANTHROPIC_API_KEY / ANTHROPIC_AUTH_TOKEN is set
# (process, user, machine): the calls count against the subscription's usage
# limits, they are not billed per token. With an API key, the same figures
# would be billed. The first lines of each run print which case applies.
#
# usage: bash tests/agent-evals/run-agent-evals.sh [<scenario id>...]
#   env: SB_EVAL_MODEL (default claude-opus-5-5), SB_EVAL_BUDGET_USD (default
#        1.50 per call), SB_EVAL_MAX_RUN_USD (default 6.00: once the costs
#        reported by the calls of this run reach it, no further scenario is
#        played), SB_EVAL_OUT (default <SB_TMP>/agent-evals/<stamp>)
# Exit 0: every scenario played PASS; 1: a FAIL; 77: SKIP (no claude, or the
# first call failed before the agent ran -- verdict NON MESURÉ, nothing more
# is played).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

MODEL="${SB_EVAL_MODEL:-claude-opus-5-5}"
BUDGET="${SB_EVAL_BUDGET_USD:-1.50}"
MAX_RUN="${SB_EVAL_MAX_RUN_USD:-6.00}"
RUN_COST="0"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${SB_EVAL_OUT:-$(sb_tmp_dir agent-evals)/$STAMP}"
mkdir -p "$OUT" || exit 1
ONLY="$*"

# --- The scenarios (Mission 242: --list, no call) --------------------------------
SCENARIOS="E2|claude-code|Executor, dossier non adopte, sans ordre|default
E4|claude-code|Executor ouvert a la racine de l'espace|default
E3|claude-code|Executor avec ordre d'initiation|default
E1|claude-code|Executor dans un projet adopte|default
E10|claude-code|Session libre|default
P1|claude-code|Pilot d'un projet (sans shell, MCP borne)|default
P2|claude-code|Pilot sur un projet sans PILOT-PROMPT|default
P3|claude-code|Pilot d'accueil (SB - Accueil)|default
S1|claude-code|Executor Claude Code, plugin sb : /sb:status|default
S2|claude-code|Executor sans plugin : sb status|default
S3|claude-code|Pilot : sb help|default
P4|codex|Pilot dans Codex (sans shell, serveur du Vault seul)|on-request
P5|gemini|Pilot dans Gemini CLI (mode plan, serveur du Vault seul)|on-request
E6|codex|Executor dans Codex, projet adopte|on-request
A1|claude-code|Pilot d'accueil, chemin seul, langue enregistree (M244)|on-request
A2|claude-code|Pilot d'accueil, consignes par lieu (M244)|on-request
A3|claude-code|Pilot d'accueil, relister _orders/ (M244)|on-request
C1|claude-code|Pilot, sb close sans rien produit : cloture legere (M244)|on-request
C2|claude-code|Executor seul, sb close : cloture legere (M244)|on-request"
if [ "$ONLY" = "--list" ]; then
  echo "id	hote	joue sans argument	scenario"
  printf '%s\n' "$SCENARIOS" | awk -F'|' '{ printf "%s\t%s\t%s\t%s\n", $1, $2, ($4 == "default" ? "oui" : "non (a nommer)"), $3 }'
  exit 0
fi

command -v claude >/dev/null 2>&1 || { echo "SKIP : claude introuvable dans PATH"; exit 77; }
sandbox_find_uv || { echo "SKIP : uv introuvable"; exit 77; }

# --- The throwaway workspace ---------------------------------------------------
WS="$OUT/ws"
V="$WS/vault"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
# A real Vault has its origin: without origin/main the Executor's opening
# stops on a missing ref (measured, first run of Mission 234).
git clone -q --bare "$V" "$OUT/vault-origin.git" && git -C "$V" remote add origin "$OUT/vault-origin.git" \
  && git -C "$V" fetch -q origin || { echo "FAIL : origine du Vault jetable"; exit 1; }
# ... and its native hook wired, as AGENTS.md prescribes after every clone:
# without it the Executor's canary (b) stops the opening (measured, second run).
git -C "$V" config core.hooksPath .githooks
git -C "$V" branch -q --set-upstream-to=origin/main main 2>/dev/null || true
# The marker AND the two workspace guides, as at the real root (Mission 235:
# the guides route a session opened at the root to the entry matrix).
bash "$V/tools/write-marker.sh" "$WS" >/dev/null || { echo "FAIL : marqueur"; exit 1; }
BOOT="$V/tools/project-bootstrap.sh"
bash "$BOOT" create "$WS/demo" "Demo" FR --vcs git >"$OUT/setup-demo.log" 2>&1 || { echo "FAIL : projet demo"; exit 1; }
git -C "$WS/demo" add -A >/dev/null 2>&1 && git -C "$WS/demo" commit -q -m "demo: birth" >>"$OUT/setup-demo.log" 2>&1 \
  || { echo "FAIL : premier commit du projet demo (voir setup-demo.log)"; exit 1; }
mkdir -p "$WS/loose" && printf '# Loose\n\nUn dossier jamais adopte.\n' > "$WS/loose/README.md"
mkdir -p "$WS/_orders"
VID="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"
ORDER="$WS/_orders/ORDER-2026-09-26-120000-neo.md"
cat > "$ORDER" <<EOF
Ordre d'initiation
- Type : create
- Mode : answered
- Nom : neo
- Emplacement : $(sandbox_native_path "$WS")
- Groupe : grp
- Vault + construction : vault_id=$VID, vault_origin=x, vault_ref=x
- Git : none
- Objet : projet de test des scenarios d'entree
- Autorisation Owner datée : « évaluation d'agent, Mission 234 » 2026-09-26
EOF
DEMO_CANARY="$(sed -n 's/^canary: "\(.*\)"$/\1/p' "$WS/demo/state/PILOT-PROMPT.md" | tr -d '\r')"
SERVER="$(bash "$V/tools/vault-identity.sh" get server_name "$V" 2>/dev/null || true)"
[ -n "$SERVER" ] || SERVER="second-brain-vault-$(printf '%s' "$VID" | sed 's/^sb-//' | cut -c1-8)"
WS_NATIVE="$(sandbox_native_path "$WS")"
V_NATIVE="$(sandbox_native_path "$V")"
UV_BIN="$(command -v uv)"
cat > "$OUT/mcp.json" <<EOF
{ "mcpServers": { "$SERVER": { "command": "$(sandbox_native_path "$UV_BIN")", "args": ["run", "--no-project", "$V_NATIVE/tools/vault-mcp.py", "--allow", "$WS_NATIVE", "--vault", "$V_NATIVE"] } } }
EOF
# The Project's instructions: the common trunk, rendered as project-bootstrap renders it.
TRUNK="$(sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p' "$V/templates/session-opening-prompt-template.md" | sed '1d;$d' | sed "s/{{VAULT_SHORT_ID}}/${SERVER#second-brain-vault-}/g")"
ACCUEIL="$(bash "$BOOT" accueil-prompt 2>/dev/null | sed -n '/^  ---$/,/^  ---$/p' | sed '1d;$d')"

snapshot() { # a fingerprint of every file of the workspace (Vault excluded)
  (cd "$WS" && find . -path ./vault -prune -o -type f -printf '%P %s\n' 2>/dev/null | LC_ALL=C sort | sha256sum | cut -c1-16)
}

# --- One call ------------------------------------------------------------------
RESULTS="$OUT/results.tsv"
printf 'id\tscenario\tverdict\tfirst_line\tgesture\tcost_usd\tturns\n' > "$RESULTS"
PLAYED=0
FAILS=0
FIRST_CALL=1

run_case() { # <id> <label> <surface exec|pilot> <cwd> <system prompt or -> <message>
  local id="$1" label="$2" surface="$3" cwd="$4" sys="$5" msg="$6" json rc
  if [ -n "$ONLY" ] && ! printf ' %s ' "$ONLY" | grep -q " $id "; then return 0; fi
  if awk -v a="$RUN_COST" -v b="$MAX_RUN" 'BEGIN { exit !(a >= b) }'; then
    echo "  PLAFOND : $RUN_COST USD rapportes >= $MAX_RUN (SB_EVAL_MAX_RUN_USD) : [$id] non joue"
    FIRST_LINE="(non joue : plafond du passage)"; GESTURE_CHANGED=no; ANSWER=""; COST=0; TURNS=0
    return 0
  fi
  json="$OUT/$id.json"
  local before; before="$(snapshot)"
  if [ "$surface" = "plugin" ]; then
    (cd "$cwd" && claude -p "$msg" --output-format json --model "$MODEL" --max-budget-usd "$BUDGET" \
      --no-session-persistence --permission-mode dontAsk --permission-prompts none \
      --plugin-dir "$(sandbox_native_path "$V/skills/claude-plugins/sb")" \
      --tools "Bash,Read,Glob,Grep,Skill" --allowedTools "Bash" "Read" "Glob" "Grep" "Skill" \
      --disallowedTools "Bash(git push *)" "Bash(git * push *)" "Bash(rm *)" \
      < /dev/null > "$json" 2> "$OUT/$id.err")
  elif [ "$surface" = "codex-pilot" ] || [ "$surface" = "codex-exec" ]; then
    # Mission 242 (P4, E6): the user's configuration ignored, the Vault's server
    # alone, given by -c; the last message is the answer.
    local sandbox=read-only extra="--disable shell_tool"
    [ "$surface" = "codex-exec" ] && { sandbox=workspace-write; extra=""; }
    (cd "$cwd" && codex exec --ephemeral --ignore-user-config --skip-git-repo-check -s "$sandbox" $extra \
      -c "mcp_servers.${SERVER}.command=\"$(sandbox_native_path "$UV_BIN")\"" \
      -c "mcp_servers.${SERVER}.args=[\"run\", \"--no-project\", \"$V_NATIVE/tools/vault-mcp.py\", \"--allow\", \"$WS_NATIVE\", \"--vault\", \"$V_NATIVE\"]" \
      -o "$OUT/$id.last.txt" "$(if [ "$sys" != "-" ]; then printf '%s\n\n' "$sys"; fi)$msg" < /dev/null > "$json" 2> "$OUT/$id.err")
  elif [ "$surface" = "gemini-pilot" ]; then
    # Mission 242 (P5): a project-level settings file with the Vault's server
    # alone, Plan Mode (read-only); the answer is standard output.
    mkdir -p "$cwd/.gemini"
    printf '{ "mcpServers": { "%s": { "command": "%s", "args": ["run", "--no-project", "%s/tools/vault-mcp.py", "--allow", "%s", "--vault", "%s"] } } }\n' \
      "$SERVER" "$(sandbox_native_path "$UV_BIN")" "$V_NATIVE" "$WS_NATIVE" "$V_NATIVE" > "$cwd/.gemini/settings.json"
    (cd "$cwd" && gemini --approval-mode plan -p "$(printf '%s\n\n%s' "$sys" "$msg")" < /dev/null > "$OUT/$id.last.txt" 2> "$OUT/$id.err")
  elif [ "$surface" = "pilot" ]; then
    (cd "$cwd" && claude -p "$msg" --output-format json --model "$MODEL" --max-budget-usd "$BUDGET" \
      --no-session-persistence --restricted --tools "" --strict-mcp-config --mcp-config "$OUT/mcp.json" \
      --allowedTools "mcp__${SERVER}__*" --permission-prompts none \
      --append-system-prompt "$sys" < /dev/null > "$json" 2> "$OUT/$id.err")
  else
    (cd "$cwd" && claude -p "$msg" --output-format json --model "$MODEL" --max-budget-usd "$BUDGET" \
      --no-session-persistence --permission-mode dontAsk --permission-prompts none \
      --tools "Bash,Read,Glob,Grep,Skill" --allowedTools "Bash" "Read" "Glob" "Grep" "Skill" \
      --disallowedTools "Bash(git push *)" "Bash(git * push *)" "Bash(rm *)" \
      < /dev/null > "$json" 2> "$OUT/$id.err")
  fi
  rc=$?
  PLAYED=$((PLAYED + 1))
  RESULT="$(PYTHONIOENCODING=utf-8 uv run --no-project python -c 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); print(d.get("result") or "")' "$json" 2>/dev/null)"
  # Codex and Gemini CLI (Mission 242): the answer is a text file, no cost reported.
  [ -f "$OUT/$id.last.txt" ] && RESULT="$(cat "$OUT/$id.last.txt")"
  META="$(PYTHONIOENCODING=utf-8 uv run --no-project python -c 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); print("%s\t%s\t%s" % (d.get("is_error"), d.get("total_cost_usd"), d.get("num_turns")))' "$json" 2>/dev/null)"
  if [ -z "$RESULT" ]; then
    if [ "$FIRST_CALL" = "1" ]; then
      echo "NON MESURE : le premier appel a echoue avant que l'agent ne tourne (rc=$rc) : $(head -c 400 "$OUT/$id.err")"
      printf '%s\t%s\tNON MESURE\t-\t-\t-\t-\n' "$id" "$label" >> "$RESULTS"
      exit 77
    fi
  fi
  FIRST_CALL=0
  FIRST="$(printf '%s\n' "$RESULT" | sed '/^[[:space:]]*$/d' | head -n 1 | tr -d '\r')"
  AFTER="$(snapshot)"
  CHANGED=no; [ "$before" != "$AFTER" ] && CHANGED=yes
  printf '%s\n' "$RESULT" > "$OUT/$id.answer.md"
  FIRST_LINE="$FIRST"; GESTURE_CHANGED="$CHANGED"; ANSWER="$RESULT"
  COST="$(printf '%s' "$META" | cut -f2)"; TURNS="$(printf '%s' "$META" | cut -f3)"
  RUN_COST="$(awk -v a="$RUN_COST" -v b="${COST:-0}" 'BEGIN { printf "%.4f", a + (b == "None" ? 0 : b) }')"
}

record() { # <id> <label> <PASS|FAIL> <gesture text>
  case "$FIRST_LINE" in
    "(non joue"*) printf '%s\t%s\tNON JOUE\t-\tplafond du passage\t0\t0\n' "$1" "$2" >> "$RESULTS"
                  echo "  NON JOUE - [$1] $2 (plafond du passage)"; return 0 ;;
  esac
  [ "$3" = "PASS" ] || FAILS=$((FAILS + 1))
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$(printf '%s' "$FIRST_LINE" | cut -c1-120)" "$4" "${COST:-?}" "${TURNS:-?}" >> "$RESULTS"
  echo "  $3 - [$1] $2 | 1re ligne : $(printf '%s' "$FIRST_LINE" | cut -c1-100) | geste : $4"
}

played() { [ -z "$ONLY" ] || printf ' %s ' "$ONLY" | grep -q " $1 "; }

echo "=== Mission 234 : tests de comportement des agents ($MODEL, plafond $BUDGET USD par appel) ==="
echo "    espace jetable : $WS"
if [ -n "${ANTHROPIC_API_KEY:-}${ANTHROPIC_AUTH_TOKEN:-}" ]; then
  echo "    facturation : cle API presente -- les couts rapportes sont factures (plafond du passage : $MAX_RUN USD)"
else
  echo "    facturation : aucune cle API -- les couts rapportes sont des estimations imputees a l'abonnement (plafond du passage : $MAX_RUN USD)"
fi

# E2 -- Executor, folder not adopted, no order
if played E2; then
  run_case E2 "Executor, dossier non adopte, sans ordre" exec "$WS/loose" - "Ouvre la session."
  G="ordre imprime=$(printf '%s' "$ANSWER" | grep -c "Ordre d'initiation") ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -q '^NOT-READY' && printf '%s' "$ANSWER" | grep -q "Ordre d'initiation" && [ "$GESTURE_CHANGED" = no ]; then
    record E2 "Executor, dossier non adopte, sans ordre" PASS "$G"; else record E2 "Executor, dossier non adopte, sans ordre" FAIL "$G"; fi
fi

# E4 -- Executor opened at the workspace root
if played E4; then
  run_case E4 "Executor ouvert a la racine de l'espace" exec "$WS" - "Ouvre la session."
  G="ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -qi '^NOT-READY.*racine' && [ "$GESTURE_CHANGED" = no ]; then
    record E4 "Executor ouvert a la racine de l'espace" PASS "$G"; else record E4 "Executor ouvert a la racine de l'espace" FAIL "$G"; fi
fi

# E3 -- Executor with an initiation order
if played E3; then
  run_case E3 "Executor avec ordre d'initiation" exec "$WS" - "Tu es l'Executor. Exécute l'ordre d'initiation $(sandbox_native_path "$ORDER")."
  CREATED=no; [ -f "$WS/grp/neo/state/PILOT-PROMPT.md" ] && CREATED=yes
  G="projet cree dans grp/neo=$CREATED ; bloc SB - neo=$(printf '%s' "$ANSWER" | grep -c 'SB - neo')"
  if [ "$CREATED" = yes ] && printf '%s' "$ANSWER" | grep -q 'SB - neo'; then
    record E3 "Executor avec ordre d'initiation" PASS "$G"; else record E3 "Executor avec ordre d'initiation" FAIL "$G"; fi
fi

# E1 -- Executor in an adopted project
if played E1; then
  run_case E1 "Executor dans un projet adopte" exec "$WS/demo" - "Ouvre la session."
  G="carte d'identite verifiee=$(printf '%s' "$ANSWER" | grep -ci 'CONCORDANT\|identit') ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -q '^READY' && printf '%s' "$ANSWER" | grep -qi 'CONCORDANT\|identit' && [ "$GESTURE_CHANGED" = no ]; then
    record E1 "Executor dans un projet adopte" PASS "$G"; else record E1 "Executor dans un projet adopte" FAIL "$G"; fi
fi

# E10 -- free session (a question, no path, no Mission, no order)
if played E10; then
  run_case E10 "Session libre" exec "$WS" - "Juste une question, sans projet : en deux phrases, qu'est-ce qu'une session libre ?"
  G="ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -qi '^READY (session libre)' && [ "$GESTURE_CHANGED" = no ]; then
    record E10 "Session libre" PASS "$G"; else record E10 "Session libre" FAIL "$G"; fi
fi

# P1 -- Pilot of a project (no shell, MCP only)
if played P1; then
  run_case P1 "Pilot d'un projet (sans shell, MCP borne)" pilot "$OUT" "$TRUNK" "$(sandbox_native_path "$WS/demo")"
  G="canari rendu=$(printf '%s' "$ANSWER" | grep -c "$DEMO_CANARY") ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -q '^READY' && printf '%s' "$ANSWER" | grep -q "$DEMO_CANARY" && [ "$GESTURE_CHANGED" = no ]; then
    record P1 "Pilot d'un projet (sans shell, MCP borne)" PASS "$G"; else record P1 "Pilot d'un projet (sans shell, MCP borne)" FAIL "$G"; fi
fi

# P2 -- Pilot on a folder without PILOT-PROMPT
if played P2; then
  run_case P2 "Pilot sur un projet sans PILOT-PROMPT" pilot "$OUT" "$TRUNK" "$(sandbox_native_path "$WS/loose")"
  G="ordre propose=$(printf '%s' "$ANSWER" | grep -ci 'ordre') ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -q '^NOT-READY' && printf '%s' "$ANSWER" | grep -qi 'ordre' && [ "$GESTURE_CHANGED" = no ]; then
    record P2 "Pilot sur un projet sans PILOT-PROMPT" PASS "$G"; else record P2 "Pilot sur un projet sans PILOT-PROMPT" FAIL "$G"; fi
fi

# P3 -- welcome Pilot
if played P3; then
  run_case P3 "Pilot d'accueil (SB - Accueil)" pilot "$OUT" "$ACCUEIL" "$WS_NATIVE"
  G="accueil annonce=$(printf '%s' "$ANSWER" | grep -ci 'accueil') ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -q '^READY' && printf '%s' "$ANSWER" | grep -qi 'accueil' && [ "$GESTURE_CHANGED" = no ]; then
    record P3 "Pilot d'accueil (SB - Accueil)" PASS "$G"; else record P3 "Pilot d'accueil (SB - Accueil)" FAIL "$G"; fi
fi

# S1 -- Executor in Claude Code, plugin sb loaded: /sb:status (Mission 236)
if played S1; then
  run_case S1 "Executor Claude Code, plugin sb : /sb:status" plugin "$WS/demo" - "/sb:status"
  G="statut rendu=$(printf '%s' "$ANSWER" | grep -c 'Demo') ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$ANSWER" | grep -q 'Demo' && printf '%s' "$ANSWER" | grep -qi 'vault' && [ "$GESTURE_CHANGED" = no ]; then
    record S1 "Executor Claude Code, plugin sb : /sb:status" PASS "$G"; else record S1 "Executor Claude Code, plugin sb : /sb:status" FAIL "$G"; fi
fi

# S2 -- Executor without the plugin: the message "sb status" (Mission 236)
if played S2; then
  run_case S2 "Executor sans plugin : sb status" exec "$WS/demo" - "sb status"
  G="statut rendu=$(printf '%s' "$ANSWER" | grep -c 'Demo') ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$ANSWER" | grep -q 'Demo' && printf '%s' "$ANSWER" | grep -qi 'vault' && [ "$GESTURE_CHANGED" = no ]; then
    record S2 "Executor sans plugin : sb status" PASS "$G"; else record S2 "Executor sans plugin : sb status" FAIL "$G"; fi
fi

# S3 -- Pilot (no shell) receives "sb help" after the project's path (Mission 236)
if played S3; then
  run_case S3 "Pilot : sb help" pilot "$OUT" "$TRUNK" "$(sandbox_native_path "$WS/demo")

sb help"
  N="$(for v in pilot-prompt add-skill doctor relay handoff; do printf '%s' "$ANSWER" | grep -q -- "$v" && echo "$v"; done | wc -l | tr -d ' ')"
  G="verbes cites=$N/5 ; ecrit=$GESTURE_CHANGED"
  if [ "$N" -ge 4 ] && [ "$GESTURE_CHANGED" = no ]; then
    record S3 "Pilot : sb help" PASS "$G"; else record S3 "Pilot : sb help" FAIL "$G"; fi
fi

# --- Mission 242: hosts other than Claude, played only when named ------------------
named() { [ -n "$ONLY" ] && printf ' %s ' "$ONLY" | grep -q " $1 "; }
host_ready() { # <command> <id>: SKIP line when the host is not installed
  command -v "$1" >/dev/null 2>&1 && return 0
  printf '%s\t%s\tNON MESURE\t-\t%s absent\t-\t-\n' "$2" "$2" "$1" >> "$RESULTS"
  echo "  NON MESURE - [$2] $1 introuvable dans PATH"
  return 1
}
if named P4 && host_ready codex P4; then
  run_case P4 "Pilot dans Codex (sans shell, serveur du Vault seul)" codex-pilot "$OUT" "$TRUNK" "$(sandbox_native_path "$WS/demo")"
  CANARY="$(sed -n 's/^canary: *//p' "$WS/demo/state/PILOT-PROMPT.md" | tr -d '"' | head -1)"
  G="canari=$(printf '%s' "$ANSWER" | grep -c -F "$CANARY") ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -q '^READY' && [ -n "$CANARY" ] && printf '%s' "$ANSWER" | grep -q -F "$CANARY" && [ "$GESTURE_CHANGED" = no ]; then
    record P4 "Pilot dans Codex" PASS "$G"; else record P4 "Pilot dans Codex" FAIL "$G"; fi
fi
if named P5 && host_ready gemini P5; then
  mkdir -p "$OUT/gemini-pilot"
  run_case P5 "Pilot dans Gemini CLI (mode plan, serveur du Vault seul)" gemini-pilot "$OUT/gemini-pilot" "$TRUNK" "$(sandbox_native_path "$WS/demo")"
  CANARY="$(sed -n 's/^canary: *//p' "$WS/demo/state/PILOT-PROMPT.md" | tr -d '"' | head -1)"
  G="canari=$(printf '%s' "$ANSWER" | grep -c -F "$CANARY") ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -q '^READY' && [ -n "$CANARY" ] && printf '%s' "$ANSWER" | grep -q -F "$CANARY" && [ "$GESTURE_CHANGED" = no ]; then
    record P5 "Pilot dans Gemini CLI" PASS "$G"; else record P5 "Pilot dans Gemini CLI" FAIL "$G"; fi
fi
if named E6 && host_ready codex E6; then
  run_case E6 "Executor dans Codex, projet adopte" codex-exec "$WS/demo" - "Ouvre la session."
  G="ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -qE '^(READY|NOT-READY)' && [ "$GESTURE_CHANGED" = no ]; then
    record E6 "Executor dans Codex" PASS "$G"; else record E6 "Executor dans Codex" FAIL "$G"; fi
fi

# --- Mission 244: the client's journey, WRITTEN, NOT PLAYED (played only when
# named; one model call each, the Owner's gesture) ---------------------------------
#   A1  welcome Pilot, first message = the workspace path alone: the answer is in
#       the recorded language (the throwaway Vault records fr), READY first.
#   A2  welcome Pilot asked how to start a project: every instruction for the
#       Owner starts with its place (« Dans le terminal », « Dans le Pilot » or
#       « Dans l'Executor »).
#   A3  welcome Pilot asked whether a profile order still waits, the order
#       being already in _archive/orders/: it lists _orders/ again (never from
#       memory) and says it was applied; nothing written.
#   C1  project Pilot, a session with nothing produced, then « sb close »: a
#       light close (« rien à consigner »), no handoff written.
#   C2  Executor alone in the adopted project, « sb close »: the situation
#       measured, the light close named (sb close --light), no jargon.
if named A1; then
  printf 'language: fr\n' > "$WS/vault/USER.local.yaml"
  run_case A1 "Pilot d'accueil, chemin seul, langue enregistree" pilot "$OUT" "$ACCUEIL" "$WS_NATIVE"
  G="francais=$(printf '%s' "$ANSWER" | grep -ciE ' (le|la|les|tu|ton|ta|est) ') ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$FIRST_LINE" | grep -q '^READY' && printf '%s' "$ANSWER" | grep -qiE ' (le|la|les|tu|ton|ta) ' && [ "$GESTURE_CHANGED" = no ]; then
    record A1 "Pilot d'accueil, langue enregistree" PASS "$G"; else record A1 "Pilot d'accueil, langue enregistree" FAIL "$G"; fi
fi
if named A2; then
  run_case A2 "Pilot d'accueil, consignes par lieu" pilot "$OUT" "$ACCUEIL" "Bonjour. Comment je démarre un nouveau projet ?"
  G="lieux=$(printf '%s' "$ANSWER" | grep -ciE "Dans le terminal|Dans le Pilot|Dans l.Executor") ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$ANSWER" | grep -qiE "Dans le terminal|Dans le Pilot|Dans l.Executor" && [ "$GESTURE_CHANGED" = no ]; then
    record A2 "Pilot d'accueil, consignes par lieu" PASS "$G"; else record A2 "Pilot d'accueil, consignes par lieu" FAIL "$G"; fi
fi
if named A3; then
  mkdir -p "$WS/_archive/orders"
  printf 'Ordre de profil\n- Rythme de revue : lundi\n' > "$WS/_archive/orders/PROFILE-2026-09-30-101500.md"
  run_case A3 "Pilot d'accueil, relister _orders/" pilot "$OUT" "$ACCUEIL" "Bonjour. Mon ordre de profil attend-il encore un Executor ?"
  G="archive=$(printf '%s' "$ANSWER" | grep -ciE 'archiv') ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$ANSWER" | grep -qiE 'archiv|appliqu' && [ "$GESTURE_CHANGED" = no ]; then
    record A3 "Pilot d'accueil, relister _orders/" PASS "$G"; else record A3 "Pilot d'accueil, relister _orders/" FAIL "$G"; fi
fi
if named C1; then
  run_case C1 "Pilot, sb close sans rien produit" pilot "$OUT" "$TRUNK" "$(sandbox_native_path "$WS/demo")

sb close"
  G="legere=$(printf '%s' "$ANSWER" | grep -ciE 'rien à consigner|légère|light') ; ecrit=$GESTURE_CHANGED"
  if printf '%s' "$ANSWER" | grep -qiE 'rien à consigner|légère|light close' && [ "$GESTURE_CHANGED" = no ]; then
    record C1 "Pilot, sb close sans rien produit" PASS "$G"; else record C1 "Pilot, sb close sans rien produit" FAIL "$G"; fi
fi
if named C2; then
  run_case C2 "Executor seul, sb close" exec "$WS/demo" - "sb close"
  G="light=$(printf '%s' "$ANSWER" | grep -ciE -- '--light|légère|light close')"
  if printf '%s' "$ANSWER" | grep -qiE -- '--light|clôture légère|light close'; then
    record C2 "Executor seul, sb close" PASS "$G"; else record C2 "Executor seul, sb close" FAIL "$G"; fi
fi

echo ""
echo "Appels modele : $PLAYED ; couts rapportes : $RUN_COST USD ; resultats : $RESULTS"
if [ "$FAILS" -eq 0 ]; then
  echo "=== RESULT: PASS ($PLAYED scenario(s)) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILS FAIL sur $PLAYED) ==="
exit 1
