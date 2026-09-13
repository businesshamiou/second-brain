#!/usr/bin/env bash
# Second Brain installer for macOS and Linux (Mission 168, ticket 08 --
# shell parity with install.ps1, tickets 03-07). Same mechanism as the
# Windows installer: one script, a local source, an optional answers file,
# the same three i18n catalogs (i18n/catalog.{en,fr,es}.json) and the same
# install notebook shape (<clone>/.install/state.json).
#
# Intended one-line entry point once this repository is published (T13/T23
# -- not built by this ticket, which only ships this script and its own
# local-source usage; the public one-liner is ticket 09's documentation
# concern):
#   curl -fsSL https://raw.githubusercontent.com/<org>/second-brain/main/install.sh | bash
# Until publication, and for the Owner's own local acceptance (T23), this
# script is always invoked with a local --source, exactly like install.ps1.
#
# Usage:
#   install.sh --source <path-to-local-second-brain-repo> \
#              [--answers-file <path-to-json>] \
#              [--test-mode --test-root <path>] \
#              [--scripted-answers <line>]... [--stop-after-step <name>]
#
# --source          Local filesystem path to a second-brain repository.
#                    Cloned by `git clone`, never fetched over the network
#                    (T23 -- acceptance before push).
# --answers-file     Optional. Path to a JSON file (see
#                    tests/fixtures/install-answers.sample.json for the
#                    shape). When given, no question is ever printed: every
#                    field takes its value from the file, or the same
#                    static default a missing field always took, silently.
# --test-mode        Redirects everything this installer would ever write
#                    outside the workspace itself (profile-rooted defaults,
#                    the per-tool skill folders, prerequisite install
#                    locations, PATH persistence) under --test-root instead
#                    of the real profile. Required by the Mission's
#                    constraint that no test run may touch the Owner's (or
#                    the CI runner's) real $HOME/.claude or $HOME/.codex.
# --test-root        Required with --test-mode. An empty or pre-existing
#                    temporary directory; never the real $HOME.
# --scripted-answers Test-only. Repeatable. One answer per occurrence,
#                    dequeued in the exact order a real person would type
#                    them, in place of a real terminal read.
# --stop-after-step  Test-only. One of: prerequisites, workspace, clone,
#                    guardians, marker, assistant, assistantDeployed,
#                    skillsDeployed, firstProject, profile. Stops right
#                    after that step's own carnet flag is saved (resume
#                    testing).
#
# Outputs: exit code 0 and a one-line verdict on stdout on success; exit
# code 1 and a verdict naming the step, the cause and the remedy
# otherwise. The same verdict is also written to the install notebook.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/tools/sb_installer_helper.py"

PYRUN() {
  uv run --no-project "$HELPER" "$@"
}

# --- Argument parsing --------------------------------------------------

SOURCE=""
ANSWERS_FILE=""
TEST_MODE=0
TEST_ROOT=""
STOP_AFTER_STEP=""
SCRIPTED_ANSWERS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --source) SOURCE="${2:-}"; shift 2 ;;
    --answers-file) ANSWERS_FILE="${2:-}"; shift 2 ;;
    --test-mode) TEST_MODE=1; shift ;;
    --test-root) TEST_ROOT="${2:-}"; shift 2 ;;
    --scripted-answers) SCRIPTED_ANSWERS+=("${2:-}"); shift 2 ;;
    --stop-after-step) STOP_AFTER_STEP="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,45p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

# SCRIPTED_INDEX is tracked in a file, not a plain shell variable
# (pre-existing bug, fixed as part of Mission 171-C01): every caller of
# next_scripted_or_read captures its stdout via command substitution --
# `line="$(next_scripted_or_read ...)"` in read_field/read_required_field
# -- which runs the function in a SUBSHELL. A subshell's own increment of
# a shell variable never reaches the parent shell, so a plain
# `SCRIPTED_INDEX=$((SCRIPTED_INDEX + 1))` was silently discarded after
# every single call: the second and every later --scripted-answers entry
# was unreachable, and every question kept replaying the FIRST scripted
# answer forever -- measured directly while testing this ticket's own
# workspace-path validation loop, which is the first install.sh code path
# to call read_field more than once for a single question and so the
# first to ever expose it. A file survives across subshells the way a
# shell variable cannot.
SCRIPTED_INDEX_FILE=""
if [ "${#SCRIPTED_ANSWERS[@]}" -gt 0 ]; then
  SCRIPTED_INDEX_FILE="$(mktemp)"
  printf '0' > "$SCRIPTED_INDEX_FILE"
  trap 'rm -f "$SCRIPTED_INDEX_FILE"' EXIT
fi

if [ -z "$SOURCE" ]; then
  echo "Usage: install.sh --source <path> [--answers-file <json>] [--test-mode --test-root <path>]" >&2
  exit 2
fi

# shellcheck source=tools/prerequisites.sh
. "$SCRIPT_DIR/tools/prerequisites.sh"

# --- Small helpers -------------------------------------------------------

sb_trim() {
  printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

next_scripted_or_read() {
  # $1 = prompt text, printed to stderr (never stdout: this function's
  # return value, printed to stdout, is the answer itself -- same
  # separation as install.ps1's Write-Host/Read-Host split). The dequeue
  # index lives in $SCRIPTED_INDEX_FILE, not a shell variable -- see that
  # variable's own header comment: this function is always called through
  # a command substitution, i.e. a subshell, so a shell-variable increment
  # here would never be visible to the next call.
  echo "$1" >&2
  if [ -n "$SCRIPTED_INDEX_FILE" ]; then
    local idx
    idx="$(cat "$SCRIPTED_INDEX_FILE")"
    if [ "$idx" -lt "${#SCRIPTED_ANSWERS[@]}" ]; then
      printf '%s' "${SCRIPTED_ANSWERS[$idx]}"
      printf '%s' "$((idx + 1))" > "$SCRIPTED_INDEX_FILE"
      return 0
    fi
  fi
  local line
  IFS= read -r line || line=""
  printf '%s' "$line"
}

read_field() {
  # $1 = prompt, $2 = default. Enter (blank line) accepts the default.
  local line trimmed
  line="$(next_scripted_or_read "$1")"
  trimmed="$(sb_trim "$line")"
  if [ -z "$trimmed" ]; then printf '%s' "$2"; else printf '%s' "$trimmed"; fi
}

read_required_field() {
  # $1 = prompt. Loops until a non-blank line comes back.
  local line trimmed
  while true; do
    line="$(next_scripted_or_read "$1")"
    trimmed="$(sb_trim "$line")"
    if [ -n "$trimmed" ]; then printf '%s' "$trimmed"; return 0; fi
  done
}

is_affirmative() {
  case "$(sb_trim "$(sb_lower "$1")")" in
    y|yes|o|oui|s|si) return 0 ;;
    *) return 1 ;;
  esac
}

sb_is_absolute_path() {
  # True for a POSIX absolute path (leading '/') or a Windows drive-letter
  # absolute path (e.g. C:\Users\... or C:/Users\...) -- this installer's
  # own bash entry point can run under Git Bash/MSYS on Windows too
  # (tests/test-install-e2e.sh's own HYPOTHESIS notice), where a
  # participant may naturally type a Windows-spelled path. The Windows form
  # is matched with a regex (`[[ =~ ]]`), never a glob `case` bracket
  # expression: bash's glob engine treats an unquoted backslash inside
  # `[...]` as an escape character, not a literal one, so a bracket meant
  # to match either '/' or '\' silently never matches '\' at all (measured
  # directly while building this check).
  case "$1" in
    /*) return 0 ;;
  esac
  [[ "$1" =~ ^[A-Za-z]:[/\\] ]]
}

sb_normalize_path_for_compare() {
  # String-only normalization for the "is candidate inside the source
  # repository" check below: backslashes become slashes and a trailing
  # slash is stripped, so the same location spelled with '\' or '/'
  # compares equal. Never touches the filesystem -- the candidate
  # workspace usually does not exist yet, so a realpath-style
  # canonicalization is not available (and not needed: the source side of
  # the comparison, $SOURCE_ABS, is already resolved to an absolute path
  # via `cd ... && pwd` before this is ever called).
  local p
  p="$(printf '%s' "$1" | tr '\\' '/')"
  case "$p" in
    ?*/) p="${p%/}" ;;
  esac
  printf '%s' "$p"
}

sb_path_is_inside_or_equal() {
  # $1 = candidate, $2 = root. Both normalized here before comparing.
  local candidate root
  candidate="$(sb_normalize_path_for_compare "$1")"
  root="$(sb_normalize_path_for_compare "$2")"
  [ "$candidate" = "$root" ] && return 0
  case "$candidate" in
    "$root"/*) return 0 ;;
  esac
  return 1
}

validate_workspace_path_answer() {
  # $1 = candidate typed at the workspace-path question. Prints one cause
  # key and returns 1 when invalid ("blankOrYesNo", "notAbsolute",
  # "insideSource" -- catalog.*.json's own
  # "questionnaire.workspace.error.<cause>" keys); prints nothing and
  # returns 0 when the candidate is acceptable.
  #
  # Defects 1/2 (this ticket, Mission 171-C01): oui/non/y/n and a blank
  # line are not paths -- the literal 'oui' folder found under
  # _trash-oui-20260912 is this exact defect's own physical proof -- a
  # relative path would resolve against whatever directory `git clone`
  # happens to run from rather than the participant's intent (Defect 1),
  # and a path inside $SOURCE_ABS would clone second-brain into its own
  # source (Defect 1 as well).
  local candidate="$1" lower
  lower="$(sb_lower "$(sb_trim "$candidate")")"
  case "$lower" in
    ""|oui|non|y|n) printf '%s' "blankOrYesNo"; return 1 ;;
  esac
  if ! sb_is_absolute_path "$candidate"; then
    printf '%s' "notAbsolute"; return 1
  fi
  if sb_path_is_inside_or_equal "$candidate" "$SOURCE_ABS"; then
    printf '%s' "insideSource"; return 1
  fi
  return 0
}

catalog_get() {
  # $1 = key, remaining args = {0},{1},... substitutions.
  local key="$1"; shift
  PYRUN format-catalog "$CATALOG_FILE" "$key" "$@"
}

prompt_with_default() {
  # $1 = promptKey, $2 = defaultNoteKey, remaining = defaultNoteArgs.
  local prompt_key="$1" note_key="$2"; shift 2
  printf '%s %s' "$(catalog_get "$prompt_key")" "$(catalog_get "$note_key" "$@")"
}

resolve_answer() {
  # $1=NAME (ANSWER_<NAME> is get/set) $2=prompt $3=default $4=interactive(0/1)
  # $5=forceReask(0/1) $6=required(0/1). Prints and records the resolved value.
  local name="$1" prompt="$2" default="$3" interactive="$4" force_reask="$5" required="$6"
  local varname="ANSWER_$name"
  local existing="${!varname:-}"
  local has_existing=0
  [ -n "$existing" ] && has_existing=1

  if [ "$has_existing" = "1" ] && [ "$force_reask" != "1" ]; then
    printf '%s' "$existing"
    return 0
  fi

  if [ "$interactive" != "1" ]; then
    local value
    if [ "$has_existing" = "1" ]; then value="$existing"; else value="$default"; fi
    printf -v "$varname" '%s' "$value"
    printf '%s' "$value"
    return 0
  fi

  local effective_default value
  if [ "$has_existing" = "1" ]; then effective_default="$existing"; else effective_default="$default"; fi
  if [ "$required" = "1" ]; then
    value="$(read_required_field "$prompt")"
  else
    value="$(read_field "$prompt" "$effective_default")"
  fi
  printf -v "$varname" '%s' "$value"
  printf '%s' "$value"
}

resolve_workspace_path() {
  # Same resolution contract as resolve_answer above (an already recorded
  # value is returned untouched, silent mode never prompts) but adds a
  # validation loop for the one field where a bad answer is worst (Defects
  # 1/2, Mission 171-C01): interactive prompting here never accepts
  # oui/non/y/n, a blank line, a relative path, or a path inside the
  # source repository (validate_workspace_path_answer decides) -- it names
  # the cause and asks again instead of falling through to a bad value.
  # $1=prompt $2=default $3=interactive(0/1) $4=forceReask(0/1)
  local prompt="$1" default="$2" interactive="$3" force_reask="$4"
  local existing="$ANSWER_WORKSPACEPATH"
  local has_existing=0
  [ -n "$existing" ] && has_existing=1

  if [ "$has_existing" = "1" ] && [ "$force_reask" != "1" ]; then
    printf '%s' "$existing"
    return 0
  fi

  if [ "$interactive" != "1" ]; then
    local value
    if [ "$has_existing" = "1" ]; then value="$existing"; else value="$default"; fi
    printf -v ANSWER_WORKSPACEPATH '%s' "$value"
    printf '%s' "$value"
    return 0
  fi

  local effective_default candidate cause
  if [ "$has_existing" = "1" ]; then effective_default="$existing"; else effective_default="$default"; fi
  while true; do
    candidate="$(read_field "$prompt" "$effective_default")"
    if cause="$(validate_workspace_path_answer "$candidate")"; then
      break
    fi
    echo "$(catalog_get "questionnaire.workspace.error.$cause" "$candidate" "$default")" >&2
  done
  printf -v ANSWER_WORKSPACEPATH '%s' "$candidate"
  printf '%s' "$candidate"
}

project_slug_from_activity() {
  local activity="$1" slug
  if [ -z "$(sb_trim "$activity")" ]; then printf '%s' "premier-projet"; return 0; fi
  slug="$(printf '%s' "$activity" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g')"
  slug="$(printf '%s' "$slug" | sed -e 's/^-*//' -e 's/-*$//')"
  slug="${slug:0:40}"
  slug="$(printf '%s' "$slug" | sed -e 's/-*$//')"
  if [ -z "$slug" ]; then printf '%s' "premier-projet"; else printf '%s' "$slug"; fi
}

mark_step() {
  case " $STEPS_DONE " in
    *" $1 "*) ;;
    *) STEPS_DONE="$STEPS_DONE $1" ;;
  esac
}

save_carnet() {
  # $1 = verdict text (optional, defaults to whatever was recorded before).
  local steps_csv
  steps_csv="$(printf '%s' "$STEPS_DONE" | sed -e 's/^ *//' -e 's/ *$//' | tr ' ' ',')"
  local test_mode_bool="false"
  [ "$TEST_MODE" = "1" ] && test_mode_bool="true"
  PYRUN save-carnet "$CARNET_PATH" \
    --language "${ANSWER_LANGUAGE:-}" \
    --vault-name "${ANSWER_VAULTNAME:-}" \
    --workspace-path "${ANSWER_WORKSPACEPATH:-}" \
    --first-name "${ANSWER_FIRSTNAME:-}" \
    --activity "${ANSWER_ACTIVITY:-}" \
    --ai-tools "${ANSWER_AITOOLS:-}" \
    --what-matters "${ANSWER_WHATMATTERS:-}" \
    --fp-create "${ANSWER_FP_CREATE:-}" \
    --fp-name "${ANSWER_FP_NAME:-}" \
    --fp-display-name "${ANSWER_FP_DISPLAYNAME:-}" \
    --git-user-name "${ANSWER_GIT_USERNAME:-}" \
    --git-user-email "${ANSWER_GIT_USEREMAIL:-}" \
    --steps "$steps_csv" \
    --verdict "${1:-${CARNET_VERDICT:-}}" \
    --last-run-at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --assistant-name "${ASSISTANT_NAME:-}" \
    --assistant-slug "${ASSISTANT_SLUG:-}" \
    --context-test-mode "$test_mode_bool" \
    --context-profile-root "$CTX_PROFILE_ROOT" >/dev/null
}

stage_and_commit_clone_changes() {
  # $1 = commit message. Shared by save_clone_pending_changes below and the
  # firstProject step: a no-op when nothing changed (the same idempotency
  # rule every step follows), otherwise runs the clone's own
  # session-preflight.sh (stamps the preflight token the guardians
  # require), stages every changed path one at a time (never `git add -A`,
  # AGENTS.md's own staging rule), and commits.
  local commit_message="$1"
  if [ -z "$(git -C "$CLONE_PATH" status --porcelain)" ]; then
    return 0
  fi
  bash "$CLONE_PATH/tools/session-preflight.sh" >/dev/null 2>&1 || true
  git -C "$CLONE_PATH" status --porcelain | while IFS= read -r line; do
    changed_path="$(printf '%s' "$line" | cut -c4-)"
    git -C "$CLONE_PATH" add -- "$changed_path"
  done
  run_or_fail "failed to commit ($commit_message) in $CLONE_PATH (guardians refused)" \
    git -C "$CLONE_PATH" commit -q -m "$commit_message"
}

save_clone_pending_changes() {
  # $1 = commit message. Mirrors install.ps1's Save-ClonePendingChanges:
  # regenerates the clone's OWN indexes first (its own tools/build-indexes.sh,
  # never this installer's copy -- measured directly while building this
  # ticket: running the wrong copy against a foreign target directory made
  # build_indexes.py compute a wrong cross-repo root and corrupt unrelated
  # index.md files), then stages and commits via stage_and_commit_clone_changes.
  local commit_message="$1"
  run_or_fail "build-indexes.sh failed in $CLONE_PATH" \
    "$CLONE_PATH/tools/build-indexes.sh" "$CLONE_PATH" >/dev/null
  stage_and_commit_clone_changes "$commit_message"
}

fail() {
  local cause="$1" step_label remedy verdict
  if [ -n "${CATALOG_FILE:-}" ]; then
    step_label="$(catalog_get "step.name.$CURRENT_STEP")"
    remedy="$(catalog_get "remedy.generic")"
    verdict="$(catalog_get "verdict.stoppedAtStep" "$step_label" "$cause") $(catalog_get "verdict.remedy" "$remedy")"
  else
    verdict="Stopped at step $CURRENT_STEP: $cause What to do: Review the error above; once it is fixed, run the installer line again to resume."
  fi
  if [ -n "${CARNET_PATH:-}" ]; then
    save_carnet "$verdict" || true
  fi
  echo "$verdict"
  exit 1
}

check_forced_stop() {
  if [ "$STOP_AFTER_STEP" = "$1" ]; then
    fail "Forced stop for testing, after step: $1"
  fi
}

run_or_fail() {
  # $1 = cause on failure, remaining = command to run.
  local cause="$1"; shift
  if ! "$@"; then
    fail "$cause"
  fi
}

# --- Context (Mission constraint: Owner's / CI runner's real environment
# intact) ------------------------------------------------------------------

if [ "$TEST_MODE" = "1" ]; then
  if [ -z "$TEST_ROOT" ]; then
    echo "--test-root is required with --test-mode." >&2
    exit 2
  fi
  CTX_PROFILE_ROOT="$TEST_ROOT/profile"
  mkdir -p "$CTX_PROFILE_ROOT"
  CTX_CLAUDE_SKILLS_DIR="$CTX_PROFILE_ROOT/.claude/skills"
  CTX_CLAUDE_AGENTS_DIR="$CTX_PROFILE_ROOT/.claude/agents"
  CTX_CODEX_SKILLS_DIR="$CTX_PROFILE_ROOT/.codex/skills"
  CTX_CODEX_AGENTS_SKILLS_DIR="$CTX_PROFILE_ROOT/.agents/skills"
  CTX_SIMULATED_PATH_FILE="$TEST_ROOT/simulated-user-path.txt"
  CTX_DEFAULT_WORKSPACE_PATH="$TEST_ROOT/workspace"
else
  CTX_PROFILE_ROOT="$HOME"
  CTX_CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
  CTX_CLAUDE_AGENTS_DIR="$HOME/.claude/agents"
  CTX_CODEX_SKILLS_DIR="$HOME/.codex/skills"
  CTX_CODEX_AGENTS_SKILLS_DIR="$HOME/.agents/skills"
  CTX_SIMULATED_PATH_FILE="$HOME/.profile"
  CTX_DEFAULT_WORKSPACE_PATH="$HOME/second-brain-workspace"
fi

add_installer_path_entry() {
  # $1 = directory to add. Test mode: dedup-appended to a plain text file
  # (environment-fingerprint.sh reads it). Real mode: an idempotent,
  # marked block in ~/.profile -- never sudo, never a system-wide file.
  local entry="$1"
  if [ "$TEST_MODE" = "1" ]; then
    mkdir -p "$(dirname "$CTX_SIMULATED_PATH_FILE")"
    touch "$CTX_SIMULATED_PATH_FILE"
    grep -qxF "$entry" "$CTX_SIMULATED_PATH_FILE" 2>/dev/null || echo "$entry" >> "$CTX_SIMULATED_PATH_FILE"
    return 0
  fi
  touch "$CTX_SIMULATED_PATH_FILE"
  if ! grep -qF "$entry" "$CTX_SIMULATED_PATH_FILE" 2>/dev/null; then
    {
      echo ""
      echo "# Added by the Second Brain installer"
      echo "export PATH=\"$entry:\$PATH\""
    } >> "$CTX_SIMULATED_PATH_FILE"
  fi
}

# --- Load and validate inputs, then run all steps -------------------------

CURRENT_STEP="prerequisites"
CATALOG_FILE=""
CARNET_PATH=""
CARNET_VERDICT=""
STEPS_DONE=""
ANSWER_LANGUAGE=""; ANSWER_VAULTNAME=""; ANSWER_WORKSPACEPATH=""
ANSWER_FIRSTNAME=""; ANSWER_ACTIVITY=""; ANSWER_AITOOLS=""; ANSWER_WHATMATTERS=""
ANSWER_FP_CREATE=""; ANSWER_FP_NAME=""; ANSWER_FP_DISPLAYNAME=""
ANSWER_GIT_USERNAME=""; ANSWER_GIT_USEREMAIL=""
ASSISTANT_NAME=""; ASSISTANT_SLUG=""; PREV_ASSISTANT_SLUG=""

run_or_fail "Failed to ensure prerequisites (Git, uv, pre-commit)" ensure_prerequisites
check_forced_stop "prerequisites"

if [ ! -e "$SOURCE" ]; then
  fail "Source not found: $SOURCE"
fi
if ! git -C "$SOURCE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "Source is not a git repository: $SOURCE"
fi
# Resolved once, here, to an absolute path -- the workspace-path question
# below (validate_workspace_path_answer) compares every typed candidate
# against this, never against the raw (possibly relative) $SOURCE.
SOURCE_ABS="$(cd "$SOURCE" && pwd)"

I18N_DIR="$SCRIPT_DIR/i18n"
INTERACTIVE=1
[ -n "$ANSWERS_FILE" ] && INTERACTIVE=0
IS_UPDATE_RUN=0
HAS_PRIOR_CARNET_AT_DEFAULT=0

if [ "$INTERACTIVE" = "0" ]; then
  # --- Silent mode: never a single prompt. ---
  if [ ! -f "$ANSWERS_FILE" ]; then
    fail "Answers file not found: $ANSWERS_FILE"
  fi
  eval "$(PYRUN load-answers-file "$ANSWERS_FILE")" || fail "Invalid answers file: $ANSWERS_FILE"
  [ -z "$ANSWER_LANGUAGE" ] && ANSWER_LANGUAGE="EN"
  ANSWER_LANGUAGE="$(printf '%s' "$ANSWER_LANGUAGE" | tr '[:lower:]' '[:upper:]')"
else
  # --- Interactive mode: fixed English sentence before any language is
  # chosen (T06 complement 3). ---
  echo "Second Brain installer -- answer each question, or press Enter to accept the default shown in parentheses."
  probed_clone_path="$CTX_DEFAULT_WORKSPACE_PATH/second-brain"
  probed_carnet_path="$probed_clone_path/.install/state.json"
  if [ -f "$probed_carnet_path" ]; then
    eval "$(PYRUN load-carnet "$probed_carnet_path")"
    HAS_PRIOR_CARNET_AT_DEFAULT=1
  fi
  case "${LANG:-}" in
    fr*|fr_*) default_language="FR" ;;
    es*|es_*) default_language="ES" ;;
    *) default_language="EN" ;;
  esac
  ANSWER_LANGUAGE="$(resolve_answer LANGUAGE "Language / Langue / Idioma -- FR, EN or ES [$default_language]:" "$default_language" 1 0 0)"
  ANSWER_LANGUAGE="$(printf '%s' "$ANSWER_LANGUAGE" | tr '[:lower:]' '[:upper:]')"
  case "$ANSWER_LANGUAGE" in FR|EN|ES) ;; *) ANSWER_LANGUAGE="$default_language" ;; esac
fi

CATALOG_FILE="$I18N_DIR/catalog.$(printf '%s' "$ANSWER_LANGUAGE" | tr '[:upper:]' '[:lower:]').json"
[ -f "$CATALOG_FILE" ] || CATALOG_FILE="$I18N_DIR/catalog.en.json"

FORCE_REASK=0
if [ "$INTERACTIVE" = "1" ] && [ "$HAS_PRIOR_CARNET_AT_DEFAULT" = "1" ] && [ "$STEP_WORKSPACECREATED" = "true" ] && \
   [ "$STEP_CLONED" = "true" ] && [ "$STEP_GUARDIANSCONFIGURED" = "true" ] && [ "$STEP_MARKERWRITTEN" = "true" ] && \
   [ "$STEP_ASSISTANTGENERATED" = "true" ] && [ "$STEP_ASSISTANTDEPLOYED" = "true" ] && [ "$STEP_SKILLSDEPLOYED" = "true" ] && [ "$STEP_PROFILEWRITTEN" = "true" ] && \
   { [ "$ANSWER_FP_CREATE" = "false" ] || [ "$STEP_FIRSTPROJECTCREATED" = "true" ]; }; then
  # --- Update mode (T06/T22): install at the default workspace already
  # complete. Show recorded answers, ask if anything changed. ---
  IS_UPDATE_RUN=1
  echo "$(catalog_get "update.header")"
  echo "  language=$ANSWER_LANGUAGE vaultName=$ANSWER_VAULTNAME workspacePath=$ANSWER_WORKSPACEPATH firstName=$ANSWER_FIRSTNAME"
  changed_answer="$(read_field "$(catalog_get "update.anythingChanged")" "n")"
  if ! is_affirmative "$changed_answer"; then
    echo "$(catalog_get "update.noChangeNote")"
    exit 0
  fi
  echo "$(catalog_get "update.rewriting")"
fi
FORCE_REASK=$IS_UPDATE_RUN

if [ "$FORCE_REASK" = "1" ]; then
  language_prompt="Language / Langue / Idioma -- FR, EN or ES [$ANSWER_LANGUAGE]:"
  ANSWER_LANGUAGE="$(resolve_answer LANGUAGE "$language_prompt" "$ANSWER_LANGUAGE" 1 1 0)"
  ANSWER_LANGUAGE="$(printf '%s' "$ANSWER_LANGUAGE" | tr '[:lower:]' '[:upper:]')"
  case "$ANSWER_LANGUAGE" in FR|EN|ES) ;; *) ANSWER_LANGUAGE="EN" ;; esac
  CATALOG_FILE="$I18N_DIR/catalog.$(printf '%s' "$ANSWER_LANGUAGE" | tr '[:upper:]' '[:lower:]').json"
fi

DEFAULT_ASSISTANT_NAME="Brian"
if [ "$INTERACTIVE" = "1" ]; then
  assistant_prompt="$(prompt_with_default "questionnaire.assistantName.prompt" "questionnaire.assistantName.defaultNote" "$DEFAULT_ASSISTANT_NAME")"
  resolve_answer VAULTNAME "$assistant_prompt" "$DEFAULT_ASSISTANT_NAME" 1 "$FORCE_REASK" 0 >/dev/null

  workspace_prompt="$(prompt_with_default "questionnaire.workspace.prompt" "questionnaire.workspace.defaultNote" "$CTX_DEFAULT_WORKSPACE_PATH")"
  # Workspace never moves once a real install exists there -- never
  # force-reasked even in update mode. resolve_workspace_path, not
  # resolve_answer: a typed answer is validated in a loop (Defects 1/2,
  # Mission 171-C01) instead of accepted as-is.
  resolve_workspace_path "$workspace_prompt" "$CTX_DEFAULT_WORKSPACE_PATH" 1 0 >/dev/null
else
  resolve_answer VAULTNAME "" "$DEFAULT_ASSISTANT_NAME" 0 0 0 >/dev/null
fi

[ -z "$ANSWER_GIT_USERNAME" ] && ANSWER_GIT_USERNAME="Second Brain Installer"
[ -z "$ANSWER_GIT_USEREMAIL" ] && ANSWER_GIT_USEREMAIL="installer@example.invalid"

WORKSPACE_PATH="$ANSWER_WORKSPACEPATH"
CLONE_PATH="$WORKSPACE_PATH/second-brain"
MARKER_PATH="$WORKSPACE_PATH/VAULT-ROOT.md"
CARNET_PATH="$CLONE_PATH/.install/state.json"

# Only the step flags and the previous assistant slug are read from the
# carnet at its real, resolved path -- never ANSWER_* (`grep -v`): the
# answers for THIS run are already fully resolved above (from
# --answers-file, or interactively -- the only carnet this installer ever
# reloads answers FROM is the one at the *default* workspace path, probed
# earlier, exactly like install.ps1's own $priorCarnetAtDefault). The
# carnet's own `answers` object is about to be replaced wholesale by the
# freshly-resolved ones on the next save_carnet call, same as
# install.ps1's `$carnet.answers = $answers` -- never the reverse. A
# custom (non-default) workspace path interrupted before its own carnet
# existed is a named, accepted residual (ticket 05 report), not fixed here.
eval "$(PYRUN load-carnet "$CARNET_PATH" | grep -v '^ANSWER_')"
PREV_ASSISTANT_SLUG="${PREV_ASSISTANT_SLUG:-}"
STEPS_DONE=""
for step in workspaceCreated cloned guardiansConfigured markerWritten assistantGenerated assistantDeployed skillsDeployed firstProjectCreated profileWritten; do
  upper="$(printf '%s' "$step" | tr '[:lower:]' '[:upper:]')"
  varname="STEP_$upper"
  [ "${!varname:-}" = "true" ] && mark_step "$step"
done

# --- Step: workspace directory -------------------------------------------
mkdir -p "$WORKSPACE_PATH" || fail "Could not create workspace directory: $WORKSPACE_PATH"
mark_step "workspaceCreated"
CURRENT_STEP="workspace"
check_forced_stop "workspace"

# --- Step: clone second-brain from the local source (T23 -- never a URL) --
CURRENT_STEP="clone"
if [ ! -d "$CLONE_PATH/.git" ]; then
  run_or_fail "git clone failed (source: $SOURCE, dest: $CLONE_PATH)" \
    git -c core.longpaths=true clone -- "$SOURCE" "$CLONE_PATH"
  # core.longpaths is a one-off flag on the clone command itself, never
  # carried into the resulting repository's own local config -- every
  # later `git add`/`git status`/`git commit` inside $CLONE_PATH needs it
  # set here too, on Windows only, but harmless elsewhere (measured
  # directly on this Windows machine: the warehouse's own long paths under
  # skills-warehouse/ otherwise fail `git add` right after the clone,
  # same 260-character limit ticket 03's report already named).
  git -C "$CLONE_PATH" config core.longpaths true
  git -C "$CLONE_PATH" config user.name "$ANSWER_GIT_USERNAME"
  git -C "$CLONE_PATH" config user.email "$ANSWER_GIT_USEREMAIL"
fi
mark_step "cloned"
save_carnet
check_forced_stop "clone"

# --- Questions 4-7 (T06 complement 2; eighth question retired, Mission
# 171-C01 step 4 -- skill deployment is unconditional now) ------------------
if [ "$INTERACTIVE" = "1" ]; then
  resolve_answer FIRSTNAME "$(catalog_get "questionnaire.firstName.prompt")" "" 1 "$FORCE_REASK" 1 >/dev/null
  save_carnet

  activity_default="$(catalog_get "questionnaire.activity.default")"
  resolve_answer ACTIVITY "$(catalog_get "questionnaire.activity.prompt")" "$activity_default" 1 "$FORCE_REASK" 0 >/dev/null
  save_carnet

  detected_tools=""
  [ -d "$CTX_CLAUDE_SKILLS_DIR" ] && detected_tools="claude-code"
  if [ -d "$CTX_CODEX_SKILLS_DIR" ]; then
    if [ -n "$detected_tools" ]; then detected_tools="$detected_tools, codex"; else detected_tools="codex"; fi
  fi
  ai_tools_prompt="$(prompt_with_default "questionnaire.aiTools.prompt" "questionnaire.aiTools.detectedNote" "$detected_tools")"
  ai_tools_raw="$(resolve_answer AITOOLSRAW "$ai_tools_prompt" "$detected_tools" 1 "$FORCE_REASK" 0)"
  ANSWER_AITOOLS="$(printf '%s' "$ai_tools_raw" | tr ',' ' ')"
  save_carnet

  what_matters_default="$(catalog_get "questionnaire.whatMatters.default")"
  resolve_answer WHATMATTERS "$(catalog_get "questionnaire.whatMatters.prompt")" "$what_matters_default" 1 "$FORCE_REASK" 0 >/dev/null
  save_carnet
else
  resolve_answer FIRSTNAME "" "Second Brain user" 0 0 0 >/dev/null
  activity_default="$(catalog_get "questionnaire.activity.default")"
  resolve_answer ACTIVITY "" "$activity_default" 0 0 0 >/dev/null
  what_matters_default="$(catalog_get "questionnaire.whatMatters.default")"
  resolve_answer WHATMATTERS "" "$what_matters_default" 0 0 0 >/dev/null
fi

# --- Step: wire the clone's own guardians ----------------------------------
CURRENT_STEP="guardians"
run_or_fail "git config core.hooksPath failed in $CLONE_PATH" \
  git -C "$CLONE_PATH" config core.hooksPath .githooks
mark_step "guardiansConfigured"
save_carnet
check_forced_stop "guardians"

# --- Step: workspace marker -------------------------------------------------
CURRENT_STEP="marker"
if [ ! -f "$MARKER_PATH" ]; then
  run_or_fail "write-marker.sh failed" "$CLONE_PATH/tools/write-marker.sh" "$WORKSPACE_PATH" "$ANSWER_VAULTNAME"
fi
mark_step "markerWritten"
save_carnet
check_forced_stop "marker"

# --- Step: assistant identity forms (ticket 06 parity) ---------------------
CURRENT_STEP="assistant"
ASSISTANT_SLUG="$(PYRUN slugify "$ANSWER_VAULTNAME")"
if [ -n "$PREV_ASSISTANT_SLUG" ] && [ "$PREV_ASSISTANT_SLUG" != "$ASSISTANT_SLUG" ]; then
  PYRUN move-assistant-trash "$CLONE_PATH" "$PREV_ASSISTANT_SLUG" >/dev/null
  assistant_commit_message="Rename assistant from '$PREV_ASSISTANT_SLUG' to '$ASSISTANT_SLUG' (old forms moved to _trash)"
else
  assistant_commit_message="Generate assistant forms for '$ANSWER_VAULTNAME'"
fi
run_or_fail "Assistant generation failed for '$ANSWER_VAULTNAME'" \
  bash -c 'uv run --no-project "$1" render-assistant "$2" "$3" >/dev/null' _ "$HELPER" "$CLONE_PATH" "$ANSWER_VAULTNAME"
ASSISTANT_NAME="$ANSWER_VAULTNAME"
mark_step "assistantGenerated"
save_carnet
save_clone_pending_changes "$assistant_commit_message"
check_forced_stop "assistant"

# --- Step: deploy the assistant's own forms by link, at the profile level
# (Mission 171-C01 step 6 parity; audit Defect 3) -- see install.ps1's own
# comment at the same step for the full rationale. Scoped to exactly the
# ONE assistant slug just (re)generated. On a rename, the OLD slug's stale
# profile-level links are removed first (the link only, never the content,
# which move-assistant-trash already preserved under _trash/ above). -----
CURRENT_STEP="assistantDeployed"
if [ -n "$PREV_ASSISTANT_SLUG" ] && [ "$PREV_ASSISTANT_SLUG" != "$ASSISTANT_SLUG" ]; then
  PYRUN remove-assistant-links "$CTX_CLAUDE_AGENTS_DIR" "$CTX_CODEX_AGENTS_SKILLS_DIR" "$PREV_ASSISTANT_SLUG" >/dev/null \
    || fail "Removing stale profile-level assistant links for '$PREV_ASSISTANT_SLUG' failed"
fi
assistant_deploy_output="$(PYRUN deploy-assistant "$CLONE_PATH" "$CTX_CLAUDE_AGENTS_DIR" "$CTX_CODEX_AGENTS_SKILLS_DIR" "$ASSISTANT_SLUG")" \
  || fail "Assistant deployment failed (a link could not be created -- see the error above)"
echo "$assistant_deploy_output" | grep '^CONFLICT ' | sed 's/^CONFLICT /Note: an assistant link path was already occupied by something else, left untouched: /' || true
mark_step "assistantDeployed"
save_carnet
check_forced_stop "assistantDeployed"

# --- Step: deploy skills by link (ticket 07 parity; unconditional external
# and combined Codex budget, Mission 171-C01 step 4) -------------------------
CURRENT_STEP="skillsDeployed"
deploy_output="$(PYRUN deploy-skills "$CLONE_PATH" "$CTX_CLAUDE_SKILLS_DIR" "$CTX_CODEX_AGENTS_SKILLS_DIR")" \
  || fail "Skill deployment failed (a link could not be created -- see the error above)"
echo "$deploy_output" | grep '^DUPLICATE ' | sed 's/^DUPLICATE /Note: duplicate skill name across sources, only the first source was linked: /' || true
echo "$deploy_output" | grep '^FALLBACK 1' >/dev/null && echo "Note: combined skill description budget exceeds the Codex ceiling -- Codex received skills/ only, Claude Code received everything (Doctrine rule 3)."
echo "$deploy_output" | grep '^CONFLICT ' | sed 's/^CONFLICT /Note: a skill link path was already occupied by something else, left untouched: /' || true
mark_step "skillsDeployed"
save_carnet
check_forced_stop "skillsDeployed"

# --- First-project confirmation + step (T06 complement 2's final question) -
NEEDS_FIRST_PROJECT_ASK=0
[ "$INTERACTIVE" = "1" ] && { [ -z "$ANSWER_FP_CREATE" ] || [ "$FORCE_REASK" = "1" ]; } && NEEDS_FIRST_PROJECT_ASK=1

if [ "$NEEDS_FIRST_PROJECT_ASK" = "1" ]; then
  default_create_answer="y"
  [ "$ANSWER_FP_CREATE" = "false" ] && default_create_answer="n"
  fp_prompt="$(prompt_with_default "questionnaire.firstProject.prompt" "questionnaire.firstProject.defaultNote")"
  create_answer="$(read_field "$fp_prompt" "$default_create_answer")"
  if is_affirmative "$create_answer"; then
    ANSWER_FP_CREATE="true"
    suggested_name="$ANSWER_FP_NAME"
    [ -z "$suggested_name" ] && suggested_name="$(project_slug_from_activity "$ANSWER_ACTIVITY")"
    ANSWER_FP_NAME="$(read_field "$(catalog_get "questionnaire.firstProject.namePrompt")" "$suggested_name")"
    ANSWER_FP_DISPLAYNAME="$ANSWER_FP_NAME"
  else
    ANSWER_FP_CREATE="false"
  fi
  save_carnet
elif [ -z "$ANSWER_FP_CREATE" ]; then
  ANSWER_FP_CREATE="true"
fi
if [ "$ANSWER_FP_CREATE" = "true" ] && [ -z "$ANSWER_FP_NAME" ]; then
  ANSWER_FP_NAME="$(project_slug_from_activity "$ANSWER_ACTIVITY")"
fi
[ "$ANSWER_FP_CREATE" = "true" ] && [ -z "$ANSWER_FP_DISPLAYNAME" ] && ANSWER_FP_DISPLAYNAME="$ANSWER_FP_NAME"

FIRST_PROJECT_NAME="${ANSWER_FP_NAME:-premier-projet}"
FIRST_PROJECT_DISPLAY_NAME="${ANSWER_FP_DISPLAYNAME:-$FIRST_PROJECT_NAME}"
FIRST_PROJECT_PATH="$WORKSPACE_PATH/$FIRST_PROJECT_NAME"

CURRENT_STEP="firstProject"
if [ "$ANSWER_FP_CREATE" = "true" ]; then
  if [ ! -e "$FIRST_PROJECT_PATH" ]; then
    run_or_fail "project-bootstrap.sh failed" \
      "$CLONE_PATH/tools/project-bootstrap.sh" "$FIRST_PROJECT_PATH" "$FIRST_PROJECT_DISPLAY_NAME"

    # No build-indexes.sh here, unlike save_clone_pending_changes -- same
    # as install.ps1's own firstProject step, which never regenerates
    # indexes for a project registration either.
    stage_and_commit_clone_changes "Register first project: $FIRST_PROJECT_DISPLAY_NAME"

    (
      cd "$FIRST_PROJECT_PATH" || exit 1
      git init -q -b main
      git config user.name "$ANSWER_GIT_USERNAME"
      git config user.email "$ANSWER_GIT_USEREMAIL"
      git add -A
      pre-commit install >/dev/null 2>&1
      git commit -q -m "Initial scaffold from project-bootstrap"
    ) || fail "First project scaffold/commit failed in $FIRST_PROJECT_PATH (guardians refused)"
  fi
  mark_step "firstProjectCreated"
  save_carnet
fi
check_forced_stop "firstProject"

# --- Step: profile (ticket 05 parity) ---------------------------------------
CURRENT_STEP="profile"
USER_PROFILE_PATH="$CLONE_PATH/USER.md"
if [ "$STEP_PROFILEWRITTEN" != "true" ] || [ "$IS_UPDATE_RUN" = "1" ]; then
  git_version="unknown"
  git --version >/dev/null 2>&1 && git_version="$(git --version)"
  timezone="unknown"
  if command -v date >/dev/null 2>&1; then timezone="$(date +%Z 2>/dev/null || echo unknown)"; fi
  shell_info="${SHELL:-unknown}"
  os_info="$(uname -srm 2>/dev/null || echo unknown)"
  claude_detected="False"
  [ -d "$CTX_CLAUDE_SKILLS_DIR" ] && claude_detected="True"
  codex_detected="False"
  [ -d "$CTX_CODEX_SKILLS_DIR" ] && codex_detected="True"
  installed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  run_or_fail "Writing USER.md failed" \
    bash -c 'uv run --no-project "$0" write-user-profile "$1" --language "$2" --vault-name "$3" --workspace-path "$4" --first-name "$5" --activity "$6" --ai-tools "$7" --what-matters "$8" --installed-at "$9" --os-info "${10}" --shell-info "${11}" --timezone "${12}" --git-version "${13}" --claude-detected "${14}" --codex-detected "${15}"' \
    "$HELPER" "$USER_PROFILE_PATH" "$ANSWER_LANGUAGE" "$ANSWER_VAULTNAME" "$WORKSPACE_PATH" "$ANSWER_FIRSTNAME" \
    "$ANSWER_ACTIVITY" "$ANSWER_AITOOLS" "$ANSWER_WHATMATTERS" "$installed_at" \
    "$os_info" "$shell_info" "$timezone" "$git_version" "$claude_detected" "$codex_detected"

  save_clone_pending_changes "Write user profile from installer answers"
fi
mark_step "profileWritten"
save_carnet
check_forced_stop "profile"

# --- Verdict, signed by the assistant's own chosen name --------------------
VERDICT="$(catalog_get "verdict.success") $(catalog_get "verdict.signature" "$ANSWER_VAULTNAME")"
save_carnet "$VERDICT"
echo "$VERDICT"
exit 0
