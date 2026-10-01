#!/usr/bin/env bash
# Mission 231, step 4a: the executor-preflight hook of a project.
#
# Two defects measured on 2026-09-25: the projects kept a COPY of the hook,
# which aged behind the Vault (the warehouse's RELAY 001 was BLOCKED by one),
# and the settings fragment's matcher ignored the PowerShell tool. Now a
# project keeps a launcher (skills/project-bootstrap/preflight-launcher.sh,
# copied as .claude/hooks/preflight-hook.sh) that runs the Vault's own hook,
# and tools/check-project-conformity.sh reports a copy that is not that launcher.
#
# Fixture: a throwaway workspace (marker), a throwaway Vault built from this
# working tree (core.hooksPath set), a project created by project-bootstrap.sh.
#   (1) the fragment's matcher covers PowerShell as well as Bash;
#   (2) the launcher, copied into the project, runs the Vault's CURRENT hook:
#       a line added to the Vault's hook afterwards is printed, exit 0;
#   (3) its refusal is the hook's: core.hooksPath unset -> exit 2, REFUS;
#   (4) conformity: a stale copy of the hook (the checks themselves, as the
#       projects used to keep) is reported; the launcher is not;
#   (5) conformity: a .claude/settings.json whose matcher lacks PowerShell
#       is reported; with it, not.
#
# usage: bash tests/test-preflight-hook-launcher.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m231-hook-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
unset CLAUDE_PROJECT_DIR PREFLIGHT_PROJECT_DIR PREFLIGHT_VAULT_DIR

echo "=== Mission 231 : hook de pre-vol des projets ==="
WS="$TMP/ws"; V="$WS/second-brain"; P="$WS/projet"
mkdir -p "$WS"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null || { echo "FAIL : marqueur"; exit 1; }
bash "$V/tools/project-bootstrap.sh" create "$P" "Projet" --vcs none --lang FR >"$TMP/create.out" 2>&1 </dev/null \
  || { echo "FAIL : projet non cree"; tail -n 5 "$TMP/create.out"; exit 1; }
# Wired after the creation (Mission 244): create now commits the Vault's
# registration, and a copy of the working tree has lost the execute bits the
# bit-execution guardian checks -- the hook, not that commit, is under test.
git -C "$V" config core.hooksPath .githooks

FRAG="$V/skills/project-bootstrap/settings-hook.json"
MATCHER="$(sed -n 's/.*"matcher": *"\([^"]*\)".*/\1/p' "$FRAG")"
case "|$MATCHER|" in
  *"|PowerShell|"*) pass "(1) matcher du fragment : PowerShell couvert ($MATCHER)" ;;
  *) fail "(1) matcher du fragment sans PowerShell ($MATCHER)" ;;
esac
case "|$MATCHER|" in *"|Bash|"*) pass "(1) matcher du fragment : Bash toujours couvert" ;; *) fail "(1) Bash retire du matcher" ;; esac

LAUNCHER="$V/skills/project-bootstrap/preflight-launcher.sh"
if [ ! -f "$LAUNCHER" ]; then
  fail "(2) lanceur absent : skills/project-bootstrap/preflight-launcher.sh"
else
  mkdir -p "$P/.claude/hooks"
  cp "$LAUNCHER" "$P/.claude/hooks/preflight-hook.sh"
  HOOK="$V/skills/project-bootstrap/preflight-hook.sh"
  awk '/^exit 0$/ && !d {print "echo \"VAULT-HOOK-CURRENT\" >&2"; d=1} {print}' "$HOOK" > "$TMP/h" && cat "$TMP/h" > "$HOOK"
  OUT="$(cd "$P" && CLAUDE_PROJECT_DIR="$P" bash .claude/hooks/preflight-hook.sh 2>&1)"; RC=$?
  if [ "$RC" = 0 ] && has "$OUT" "VAULT-HOOK-CURRENT"; then
    pass "(2) le lanceur du projet joue le hook COURANT du Vault (sortie 0)"
  else
    fail "(2) lanceur : rc=$RC -- $(printf '%s' "$OUT" | tail -n 3 | tr '\n' ' ' | cut -c1-240)"
  fi
  git -C "$V" config --unset core.hooksPath
  OUT="$(cd "$P" && CLAUDE_PROJECT_DIR="$P" bash .claude/hooks/preflight-hook.sh 2>&1)"; RC=$?
  if [ "$RC" = 2 ] && has "$OUT" "REFUS executor-preflight" && has "$OUT" "core.hooksPath"; then
    pass "(3) refus du hook du Vault transmis (sortie 2, core.hooksPath nomme)"
  else
    fail "(3) refus attendu : rc=$RC -- $(printf '%s' "$OUT" | tail -n 2 | tr '\n' ' ' | cut -c1-240)"
  fi
  git -C "$V" config core.hooksPath .githooks
fi

conformity() { bash "$V/tools/check-project-conformity.sh" "$P" 2>&1; }
cp "$V/skills/project-bootstrap/preflight-hook.sh" "$P/.claude/hooks/preflight-hook.sh"
OUT="$(conformity)"
has "$OUT" "hook de pré-vol" && pass "(4) conformite : copie perimee du hook signalee" \
  || fail "(4) conformite : copie perimee non signalee -- $OUT"
[ -f "$LAUNCHER" ] && cp "$LAUNCHER" "$P/.claude/hooks/preflight-hook.sh"
OUT="$(conformity)"
has "$OUT" "hook de pré-vol" && fail "(4) conformite : le lanceur est signale a tort -- $OUT" \
  || pass "(4) conformite : le lanceur n'est pas signale"

printf '{"hooks": {"PreToolUse": [{"matcher": "Write|Edit|MultiEdit|NotebookEdit|Bash", "hooks": [{"type": "command", "command": "bash .claude/hooks/preflight-hook.sh"}]}]}}\n' > "$P/.claude/settings.json"
OUT="$(conformity)"
has "$OUT" "PowerShell" && pass "(5) conformite : matcher sans PowerShell signale" \
  || fail "(5) conformite : matcher sans PowerShell non signale -- $OUT"
cp "$FRAG" "$P/.claude/settings.json"
OUT="$(conformity)"
has "$OUT" "PowerShell" && fail "(5) conformite : le fragment du Vault est signale a tort -- $OUT" \
  || pass "(5) conformite : le fragment du Vault n'est pas signale"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
