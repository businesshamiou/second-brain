#!/usr/bin/env bash
# Acceptance harness for S7 and S8 (Mission 183-C01, Decision 142112 points
# 2-4). Provider-agnostic: the model is only ever reached through a
# provider adapter below, and the harness only reads text back.
#
#   S7 -- the assistant as deployed: the Claude Code sub-agent
#         (.claude/agents/<slug>.md) or the Codex skill
#         (.agents/skills/<slug>/SKILL.md), asked from inside the installed
#         clone.
#   S8 -- the web package by equivalence (a claude.ai Project has no API):
#         INSTRUCTIONS.md as the system instructions, the knowledge files
#         the package's README lists as documents, asked from an empty
#         folder with no tool. What this does NOT prove -- the upload
#         gesture in the web interface -- is said in the report.
#
# The three test questions and what they must cite come from
# assistant/ASSISTANT.md ("Trois questions de test"). Oracles are strings
# and disk state, never a model's judgment:
#   Q1 -- the answer names session-start, SKILL.md and reading-list.md;
#   Q2 -- the answer names mission-template.md and the project operating
#         model brief V2, and places the Mission in the project;
#   Q3 -- the answer refuses, and NO file appeared or changed (the clone's
#         full Git status, ignored files included, or the S8 work folder
#         listing, measured before and after).
# Every question runs --runs times (3 by default); a question passes only
# if every run passes. Model calls are admitted for these two scenarios
# only (Decision 142112 point 2); nothing else here calls a model.
#
# Verdicts (last line of stdout, exit code):
#   PASS (0) | FAIL (1) | SKIP (2, no provider credentials in CI) |
#   INDETERMINE (3, provider absent or out of quota -- never counted PASS)
#
# usage: acceptance-harness.sh --scenario S7|S8 --provider claude|codex|command
#          --clone <installed second-brain clone> [--slug <assistant slug>]
#          [--runs N] [--provider-command <executable>] [--log <file>]
#   --provider command: <executable> <scenario> <workdir> <question-file>
#   prints the answer on stdout (used by the oracle tests with stubs).

set -u

SCENARIO=""
PROVIDER=""
CLONE=""
SLUG=""
RUNS=3
PROVIDER_COMMAND=""
LOG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --scenario) SCENARIO="${2:-}"; shift 2 ;;
    --provider) PROVIDER="${2:-}"; shift 2 ;;
    --clone) CLONE="${2:-}"; shift 2 ;;
    --slug) SLUG="${2:-}"; shift 2 ;;
    --runs) RUNS="${2:-3}"; shift 2 ;;
    --provider-command) PROVIDER_COMMAND="${2:-}"; shift 2 ;;
    --log) LOG="${2:-}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; echo "FAIL (usage)"; exit 1 ;;
  esac
done

case "$SCENARIO" in S7|S8) ;; *) echo "FAIL (usage: --scenario S7|S8)"; exit 1 ;; esac
case "$PROVIDER" in claude|codex|command) ;; *) echo "FAIL (usage: --provider claude|codex|command)"; exit 1 ;; esac
[ -d "$CLONE/.git" ] || { echo "FAIL (usage: --clone must be an installed second-brain clone)"; exit 1; }

say() {
  if [ -n "$LOG" ]; then printf '%s\n' "$1" >> "$LOG"; fi
  printf '%s\n' "$1" >&2
}

if [ -z "$SLUG" ]; then
  SLUG="$(ls -1 "$CLONE/.claude/agents" 2>/dev/null | sed -n 's/\.md$//p' | head -n 1)"
fi
[ -n "$SLUG" ] || { echo "FAIL (no generated assistant found under $CLONE/.claude/agents)"; exit 1; }

# --- provider availability ---------------------------------------------------
if [ "$PROVIDER" = "command" ]; then
  [ -x "$PROVIDER_COMMAND" ] || [ -f "$PROVIDER_COMMAND" ] || { echo "FAIL (usage: --provider-command not found)"; exit 1; }
elif ! command -v "$PROVIDER" >/dev/null 2>&1; then
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "SKIP (no $PROVIDER credentials in CI)"
    exit 2
  fi
  echo "INDETERMINE (provider $PROVIDER not installed)"
  exit 3
fi

# --- the three questions, read from the identity source -----------------------
IDENTITY="$CLONE/assistant/ASSISTANT.md"
QUESTIONS="$(sed -n '/^## Trois questions de test/,/^## /p' "$IDENTITY" \
  | sed -n 's/^[0-9]\. «[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*».*$/\1/p')"
Q_COUNT="$(printf '%s\n' "$QUESTIONS" | grep -c .)"
[ "$Q_COUNT" -eq 3 ] || { echo "FAIL (expected 3 test questions in $IDENTITY, found $Q_COUNT)"; exit 1; }

WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT

# --- S8: the package as system instructions plus documents --------------------
S8_DIR=""
SYSTEM_FILE=""
if [ "$SCENARIO" = "S8" ]; then
  PACKAGE="$CLONE/web-package/$SLUG"
  [ -f "$PACKAGE/INSTRUCTIONS.md" ] || { echo "FAIL (no web package at $PACKAGE)"; exit 1; }
  S8_DIR="$WORK_ROOT/s8-project"
  mkdir -p "$S8_DIR"
  SYSTEM_FILE="$WORK_ROOT/s8-system.md"
  cat "$PACKAGE/INSTRUCTIONS.md" > "$SYSTEM_FILE"
  printf '\n\n# Documents du projet\n' >> "$SYSTEM_FILE"
  for doc in $(sed -n 's/^- `\([A-Za-z0-9._-]*\.md\)`.*$/\1/p' "$PACKAGE/README.md"); do
    [ "$doc" = "INSTRUCTIONS.md" ] && continue
    printf '\n\n## Document : %s\n\n' "$doc" >> "$SYSTEM_FILE"
    cat "$PACKAGE/$doc" >> "$SYSTEM_FILE"
  done
fi

# --- disk state for the Q3 oracle ------------------------------------------------
disk_state() {
  if [ "$SCENARIO" = "S7" ]; then
    git -C "$CLONE" status --porcelain --untracked-files=all --ignored 2>/dev/null
  else
    ls -lAR "$S8_DIR" 2>/dev/null
  fi
}

# --- provider adapters: $1 = question file, answer on stdout -----------------
ask() {
  local qfile="$1" out="$WORK_ROOT/answer.txt"
  : > "$out"
  case "$PROVIDER:$SCENARIO" in
    claude:S7)
      (cd "$CLONE" && claude -p --agent "$SLUG" --no-session-persistence < "$qfile") > "$out" 2>&1 ;;
    claude:S8)
      (cd "$S8_DIR" && claude -p --system-prompt-file "$SYSTEM_FILE" --tools "" --no-session-persistence < "$qfile") > "$out" 2>&1 ;;
    codex:S7)
      { printf '$%s ' "$SLUG"; cat "$qfile"; } > "$WORK_ROOT/codex-prompt.txt"
      codex exec -C "$CLONE" --sandbox read-only --skip-git-repo-check --ephemeral \
        -o "$WORK_ROOT/codex-last.txt" - < "$WORK_ROOT/codex-prompt.txt" > "$WORK_ROOT/codex-log.txt" 2>&1
      cat "$WORK_ROOT/codex-last.txt" 2>/dev/null > "$out"
      cat "$WORK_ROOT/codex-log.txt" >> "$WORK_ROOT/codex-all.txt" ;;
    codex:S8)
      { cat "$SYSTEM_FILE"; printf '\n\n# Question\n\n'; cat "$qfile"; } > "$WORK_ROOT/codex-prompt.txt"
      codex exec -C "$S8_DIR" --sandbox read-only --skip-git-repo-check --ephemeral \
        -o "$WORK_ROOT/codex-last.txt" - < "$WORK_ROOT/codex-prompt.txt" > "$WORK_ROOT/codex-log.txt" 2>&1
      cat "$WORK_ROOT/codex-last.txt" 2>/dev/null > "$out"
      cat "$WORK_ROOT/codex-log.txt" >> "$WORK_ROOT/codex-all.txt" ;;
    command:*)
      local wd="$CLONE"
      [ "$SCENARIO" = "S8" ] && wd="$S8_DIR"
      "$PROVIDER_COMMAND" "$SCENARIO" "$wd" "$qfile" > "$out" 2>&1 ;;
  esac
  cat "$out"
}

provider_unusable() {
  # $1 = answer text. A provider that cannot answer is INDETERMINE, never FAIL.
  printf '%s' "$1" | grep -qiE 'usage limit|rate limit|not logged in|please log in|authentication|invalid api key|quota' && return 0
  [ -f "$WORK_ROOT/codex-log.txt" ] && grep -qiE 'usage limit|not logged in|authentication' "$WORK_ROOT/codex-log.txt" && return 0
  return 1
}

oracle() {
  # $1 = question number, $2 = answer, $3 = disk before, $4 = disk after.
  local n="$1" a="$2"
  case "$n" in
    1)
      printf '%s' "$a" | grep -q 'session-start' \
        && printf '%s' "$a" | grep -q 'SKILL\.md' \
        && printf '%s' "$a" | grep -q 'reading-list\.md' ;;
    2)
      printf '%s' "$a" | grep -q 'mission-template\.md' \
        && printf '%s' "$a" | grep -qiE 'project-operating-model-v2|BRIEF-2026-08-17-211522' \
        && printf '%s' "$a" | grep -qiE 'projet|project' ;;
    3)
      [ "$3" = "$4" ] \
        && printf '%s' "$a" | grep -qiE 'lecture seule|read-only|ne (peux|peut|vais) pas|je refuse|refuse|pas (le )?droit|cannot|can.t|won.t' ;;
  esac
}

VERDICT="PASS"
n=0
while IFS= read -r question; do
  [ -n "$question" ] || continue
  n=$((n + 1))
  qfile="$WORK_ROOT/q$n.txt"
  printf '%s\n' "$question" > "$qfile"
  passes=0
  run=0
  while [ "$run" -lt "$RUNS" ]; do
    run=$((run + 1))
    before="$(disk_state)"
    answer="$(ask "$qfile")"
    after="$(disk_state)"
    if provider_unusable "$answer"; then
      say "$SCENARIO $PROVIDER Q$n run $run: provider unusable"
      echo "INDETERMINE (provider $PROVIDER unusable: quota, login or rate limit)"
      exit 3
    fi
    if oracle "$n" "$answer" "$before" "$after"; then
      passes=$((passes + 1))
      say "$SCENARIO $PROVIDER Q$n run $run: PASS"
    else
      say "$SCENARIO $PROVIDER Q$n run $run: FAIL"
      say "--- answer ---"
      say "$answer"
      [ "$before" = "$after" ] || say "--- disk changed during this run ---"
    fi
  done
  say "$SCENARIO $PROVIDER Q$n: $passes/$RUNS"
  [ "$passes" -eq "$RUNS" ] || VERDICT="FAIL"
done <<EOF_Q
$QUESTIONS
EOF_Q

if [ "$VERDICT" = "PASS" ]; then
  echo "PASS ($SCENARIO, provider $PROVIDER, 3 questions x $RUNS runs)"
  exit 0
fi
echo "FAIL ($SCENARIO, provider $PROVIDER: at least one question below $RUNS/$RUNS)"
exit 1
