#!/usr/bin/env bash
# Work-regime check (Mission 199): decides, by command and never by judgement,
# whether a gesture may be carried out under the LIGHT regime (an execution
# Note) or must go through the FULL regime (a Mission). It refuses, it never
# merely warns.
#
# The two regimes: rules/RULES-2026-09-20-*-two-work-regimes-*.md. The Note's
# shape: templates/execution-note-template.md.
#
# The closed list of full-regime criteria lives HERE, and only here in code;
# the rule quotes the same ids (tests/test-check-work-regime.sh fails when the
# two drift apart). It is tightened by a Mission, never loosened, and no
# argument can extend what the light regime accepts (same principle as the
# closed list of tools/publish-from-laboratory.sh, Decision 210904 A2).
#
#   R1-egress       the gesture leaves the workstation other than by
#                   `git push origin <refspec>` / `git fetch origin`: a push
#                   to `release`, of `publish`, forced, of tags, mirrored,
#                   deleting, bare (no named target) or to another remote; a
#                   network tool (curl, wget, ssh, scp, rsync, gh, npm
#                   publish, docker push...)
#   R2-destructive  a file is deleted or moved out of its repository, or
#                   history is rewritten or thrown away (rm, git rm, git
#                   clean, git reset --hard, git rebase, git commit --amend...)
#   R3-doctrine     a Decision, a rule or a template is created or amended
#                   (paths under decisions/, rules/, templates/)
#   R4-refs         a remote, a branch, a tag or a worktree is created,
#                   renamed or removed
#   R5-company      the company repository is named at all (by its folder name)
#   R6-guardians    a guardian, the preflight, a hook, the publication tool or
#                   the hook configuration is touched, or a hook is bypassed
#                   (Mission 199 tightening of the list given by the Owner)
#
# One more refusal is not a criterion but the Note's form:
#   R7-shape        not a valid Note: front matter, the six rubrics in order
#                   and nothing else, size cap, one conforming journal line
# And one more, the form of a mode-2 Note (Mission 218, Decision 012500): a
# Note written by the Executor from a prompt of the Owner, as its first write.
#   R8-origin       front matter `origin: owner-prompt` present but not
#                   `mode: 2a|2b`, not `received_at` (ISO 8601, offset), or
#                   2a: no `prompt_sha256`, not exactly one ```prompt block
#                   in the Intent, or its sha256 differs;
#                   2b: no ```files block in the Intent (lines
#                   `<sha256> <path>`, path relative to the project root, the
#                   parent of the Note's missions/ folder), a file missing or
#                   a fingerprint that differs.
#                   The prompt block is not counted in the size cap:
#                   the Owner's words are not the Note's growth.
#                   A Note without `origin:` is a Pilot's Note: unchanged.
#
# The Owner's go-ahead (Mission 219, Owner arbitration of 2026-09-23 09:08):
# when an Owner's prompt meets a full-regime criterion, the Executor asks, and
# the answer is written in the mode-2 Note's Intent, in exactly one block
#   ```owner_greenlight
#   at: <real time of the answer, ISO 8601 with offset>
#   lifts: <criterion id>[, <criterion id>...]
#   <the Owner's answer, as received, one or more lines>
#   ```
# The criteria named by `lifts:` (R1..R6 only) no longer refuse the Note, and
# the tool prints `OWNER-GREENLIGHT <ids> at <time>` before REGIME-LIGHT-OK.
# The form (R7, R8) is never lifted; a criterion not named stays; a block with
# no time, no answer, no `lifts:`, or in a Note without `origin: owner-prompt`
# is R8-origin. Like the prompt block, it is not counted in the size cap.
#
# Command criteria (R1, R2, R4, bypass part of R6) read every fenced command
# of the three measuring rubrics and of the Gesture; path criteria (R3, path
# part of R6) read the Scope and the Gesture only -- reading a Decision to
# measure something is not amending it. A false positive sends a gesture to
# the full regime, the safe direction.
#
# Modes:
#   check-work-regime.sh note <file>            a Note, before its gesture
#   check-work-regime.sh diff <repo> <range>    the real change, after it
# Last line: REGIME-LIGHT-OK | REFUSED <id>[,<id>...]   (details on stderr)
# Exit: 0 accepted, 1 refused, 2 usage.

set -u
. "$(cd "$(dirname "$0")" && pwd)/lib/tmp.sh"  # declared temporary folder (Mission 234)

NOTE_CAP=4000
JOURNAL_CAP=300

usage() {
  echo "usage: check-work-regime.sh note <file> | diff <repo> <range>" >&2
  exit 2
}

REASONS=""
HINT=""
GREENLIGHT_LINE=""
CRITERIA_IDS="R1-egress R2-destructive R3-doctrine R4-refs R5-company R6-guardians"
add() { # add <id> <what>
  REASONS="$REASONS$1	$2
"
}

# A boundary before a command word: start of line, a space, or a shell joiner.
B='(^|[[:space:];&|(])'
GIT='git( +-C +[^ ]+)?'

scan_push() { # scan_push <line> : R1/R4 on a git push
  local line="$1" after tok remote="" refspec="" flags="" n=0
  after="${line#*push}"
  set -f
  # shellcheck disable=SC2086
  set -- $after
  set +f
  for tok in "$@"; do
    case "$tok" in
      -u|--set-upstream|-q|--quiet) ;;
      -*) flags="$flags $tok" ;;
      *) n=$((n + 1))
         if [ "$n" -eq 1 ]; then remote="$tok"; elif [ "$n" -eq 2 ]; then refspec="$tok"; fi ;;
    esac
  done
  [ -z "$flags" ] || add "R1-egress" "git push with$flags : $line"
  [ "$remote" = "origin" ] || add "R1-egress" "git push to '${remote:-<no remote named>}' (only origin, named) : $line"
  [ -n "$refspec" ] || add "R1-egress" "git push with no named refspec : $line"
  case "$refspec" in
    :*|*publish*|*refs/tags*|*release*) add "R1-egress" "git push of '$refspec' : $line" ;;
  esac
  case " $flags " in
    *" --delete "*|*" -d "*|*" --tags "*|*" --follow-tags "*) add "R4-refs" "git push changing refs :$flags" ;;
  esac
}

scan_command() { # scan_command <line> : the command criteria on one line
  local l="$1"
  if printf '%s' "$l" | grep -Eq "${B}git( +-[^ ]+( +[^ -][^ ]*)?)* +push([[:space:]]|\$)"; then
    scan_push "$l"
  fi
  printf '%s' "$l" | grep -Eiq "${B}(curl|wget|scp|rsync|ssh|sftp|ftp|gh|twine)([[:space:]]|\$)|Invoke-(WebRequest|RestMethod)|npm +publish|docker +push" \
    && add "R1-egress" "network tool : $l"
  printf '%s' "$l" | grep -Eiq "${B}(rm|rmdir|del|erase|Remove-Item)([[:space:]]|\$)|${GIT} +(rm|clean|filter-branch|filter-repo)( |\$)|${GIT} +[^|;&]*(reset +--hard|rebase|commit +[^|;&]*--amend|reflog +expire|gc +[^|;&]*--prune|checkout +--( |\$)|restore( |\$)|worktree +remove|branch +[^|;&]*(-d|-D|--delete)( |\$))" \
    && add "R2-destructive" "$l"
  printf '%s' "$l" | grep -Eiq "${B}(mv|move|Move-Item|git +mv)[[:space:]]+[^|;&]*[[:space:]](/|\\.\\./|~|%|[A-Za-z]:[\\\\/])" \
    && add "R2-destructive" "move out of the repository : $l"
  if printf '%s' "$l" | grep -Eiq "${GIT} +remote +(add|set-url|rename|remove|rm|set-head)|${GIT} +tag( |\$)|${GIT} +(switch +(-c|-C|--create)|checkout +(-b|-B))|${GIT} +(update-ref|symbolic-ref)|${GIT} +worktree +add|${GIT} +branch +([^ -]|-m|-M|-c|-C)"; then
    printf '%s' "$l" | grep -Eiq "${GIT} +tag +(-l|--list)|${GIT} +branch +(--list|-a|-r|-v|-vv|--show-current|--contains)" \
      || add "R4-refs" "$l"
  fi
  printf '%s' "$l" | grep -Eiq "core\\.hooksPath|--no-verify|SKIP=" \
    && add "R6-guardians" "hook bypass : $l"
}

scan_path() { # scan_path <line> : the path criteria on one scope/gesture line
  local l="$1"
  printf '%s' "$l" | grep -Eiq "(^|[^A-Za-z0-9_-])(decisions|rules|templates)/" && add "R3-doctrine" "$l"
  printf '%s' "$l" | grep -Eiq "\\.githooks|tools/check-|tools/session-preflight|tools/publish-from-laboratory|\\.pre-commit-config" \
    && add "R6-guardians" "$l"
}

finish() {
  if [ -n "$REASONS" ]; then
    printf '%s' "$REASONS" | awk -F'\t' '{ print "REFUS : " $1 " -- " $2 }' >&2
    [ -z "$HINT" ] || echo "$HINT" >&2
    echo "REFUSED $(printf '%s' "$REASONS" | cut -f1 | sort -u | paste -sd, -)"
    exit 1
  fi
  [ -z "$GREENLIGHT_LINE" ] || echo "$GREENLIGHT_LINE"
  echo "REGIME-LIGHT-OK"
  exit 0
}

# --- Fenced-block aware readers ------------------------------------------------
h2_list() { awk '/^```/{f=!f; next} !f && /^## /{print}' "$1"; }
section() { # section <file> <heading> : the lines of one H2, fences kept
  awk -v h="$2" '/^```/{fence=!fence} !fence && /^## /{f=($0==h); next} f{print}' "$1"
}
fenced() { # fenced <text> : the lines inside the fences only
  printf '%s\n' "$1" | awk '/^```/{f=!f; next} f{print}'
}
blank() { [ -z "$(printf '%s' "$1" | tr -d '[:space:]')" ]; }

sha_stdin() { # sha256 of standard input, portable
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'  # portability: guarded by command -v, shasum and openssl after
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else openssl dgst -sha256 | awk '{print $NF}'; fi
}
fm_value() { # fm_value <front matter> <key> : the value, quotes removed
  printf '%s\n' "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -n 1 | sed 's/^"//; s/"[[:space:]]*$//; s/[[:space:]]*$//'
}
info_block() { # info_block <text> <info> : the lines of the ```<info> block(s)
  printf '%s\n' "$1" | awk -v i="$2" 'f && /^```/{f=0; next} f{print} $0=="```" i{f=1; n++} END{}'
}
info_block_count() { printf '%s\n' "$1" | grep -c "^\`\`\`$2\$"; }

# check_origin <original file> <front matter> : R8-origin, a mode-2 Note only.
check_origin() {
  local orig="$1" fm="$2" origin mode rec intent psha ptext pcount files root line fsha fpath have
  origin="$(fm_value "$fm" origin)"
  [ -n "$origin" ] || return 0
  [ "$origin" = "owner-prompt" ] || { add "R8-origin" "unknown origin '$origin' (only owner-prompt)"; return 0; }
  mode="$(fm_value "$fm" mode)"
  rec="$(fm_value "$fm" received_at)"
  printf '%s' "$rec" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?([+-][0-9]{2}:?[0-9]{2}|Z)$' \
    || add "R8-origin" "received_at missing or not ISO 8601 with an offset (the real time the prompt arrived)"
  intent="$(section "$NOTE_TMP" '## Intent')"
  case "$mode" in
    2a)
      psha="$(fm_value "$fm" prompt_sha256)"
      printf '%s' "$psha" | grep -Eq '^[0-9a-f]{64}$' || add "R8-origin" "mode 2a without prompt_sha256 (64 hexadecimal characters)"
      pcount="$(info_block_count "$intent" prompt)"
      if [ "$pcount" != "1" ]; then
        add "R8-origin" "mode 2a: the Intent must hold exactly one \`\`\`prompt block with the prompt as received ($pcount found)"
      else
        ptext="$(info_block "$intent" prompt)"
        [ "$(printf '%s' "$ptext" | sha_stdin)" = "$psha" ] \
          || add "R8-origin" "mode 2a: the sha256 of the \`\`\`prompt block differs from prompt_sha256 (prompt edited after it was received?)"
      fi
      ;;
    2b)
      files="$(info_block "$intent" files)"
      if blank "$files"; then
        add "R8-origin" "mode 2b: the Intent must hold a \`\`\`files block, one '<sha256> <path>' per consumed file"
      else
        root="$(cd "$(dirname "$orig")/.." 2>/dev/null && pwd)"
        while IFS= read -r line; do
          blank "$line" && continue
          fsha="${line%% *}"; fpath="${line#* }"
          if ! printf '%s' "$fsha" | grep -Eq '^[0-9a-f]{64}$' || [ "$fpath" = "$line" ]; then
            add "R8-origin" "mode 2b: malformed line (expected '<sha256> <path>'): $line"; continue
          fi
          case "$fpath" in /*|[A-Za-z]:[\\/]*) : ;; *) fpath="$root/$fpath" ;; esac
          if [ ! -f "$fpath" ]; then
            add "R8-origin" "mode 2b: consumed file not found: ${line#* }"; continue
          fi
          have="$(sha_stdin < "$fpath")"
          [ "$have" = "$fsha" ] || add "R8-origin" "mode 2b: fingerprint differs for ${line#* }"
        done <<EOF
$files
EOF
      fi
      ;;
    *) add "R8-origin" "origin owner-prompt without mode: 2a or 2b" ;;
  esac
}

# check_greenlight <front matter> : the Owner's go-ahead (Mission 219). Runs
# after every criterion is known; lifts only the criteria the block names.
check_greenlight() {
  local fm="$1" intent n gl at lifts answer id bad="" crit keep
  intent="$(section "$NOTE_TMP" '## Intent')"
  n="$(info_block_count "$intent" owner_greenlight)"
  if [ "$(fm_value "$fm" origin)" != "owner-prompt" ]; then
    [ "$n" = 0 ] || add "R8-origin" "an owner_greenlight block answers an Owner's prompt: only in a mode-2 Note (origin: owner-prompt)"
    return 0
  fi
  crit="$(printf '%s' "$REASONS" | cut -f1 | grep -E '^R[1-6]-' | sort -u | paste -sd' ' -)"
  if [ "$n" = 0 ]; then
    [ -z "$crit" ] || HINT="REFUS : full-regime criterion met by an Owner's prompt ($crit): do not refuse, ask the Owner for the go-ahead, then quote the answer word for word in one \`\`\`owner_greenlight block of the Intent (at: <real time>, lifts: <ids>) -- rule 012259 s3"
    return 0
  fi
  if [ "$n" != 1 ]; then
    add "R8-origin" "exactly one \`\`\`owner_greenlight block ($n found)"; return 0
  fi
  gl="$(info_block "$intent" owner_greenlight)"
  at="$(printf '%s\n' "$gl" | sed -n 's/^at:[[:space:]]*//p' | head -n 1 | sed 's/[[:space:]]*$//')"
  lifts="$(printf '%s\n' "$gl" | sed -n 's/^lifts:[[:space:]]*//p' | head -n 1 | tr ',' ' ' | tr -s ' ' | sed 's/^ //; s/ $//')"
  answer="$(printf '%s\n' "$gl" | grep -Ev '^(at|lifts):')"
  printf '%s' "$at" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?([+-][0-9]{2}:?[0-9]{2}|Z)$' \
    || bad="${bad}owner_greenlight: 'at:' missing or not ISO 8601 with an offset (the real time of the Owner's answer); "
  blank "$answer" && bad="${bad}owner_greenlight: the Owner's answer, as received, is missing; "
  if [ -z "$lifts" ]; then
    bad="${bad}owner_greenlight: 'lifts:' must name the criteria the Owner lifted; "
  else
    for id in $lifts; do
      case " $CRITERIA_IDS " in *" $id "*) ;; *) bad="${bad}owner_greenlight: '$id' cannot be lifted (only $CRITERIA_IDS; the form never); " ;; esac
    done
  fi
  if [ -n "$bad" ]; then
    add "R8-origin" "${bad%; }"; return 0
  fi
  keep="$(printf '%s' "$REASONS" | awk -F'\t' -v l=" $lifts " 'index(l, " " $1 " ") == 0 {print}')"
  REASONS="${keep:+$keep
}"
  GREENLIGHT_LINE="OWNER-GREENLIGHT $(printf '%s' "$lifts" | tr ' ' ',') at $at"
  crit="$(printf '%s' "$REASONS" | cut -f1 | grep -E '^R[1-6]-' | sort -u | paste -sd' ' -)"
  [ -z "$crit" ] || HINT="REFUS : criterion not lifted by the owner_greenlight block ($crit): ask the Owner, or name it in 'lifts:' only if the Owner's answer covers it"
}

check_note() {
  local file="$1" orig="$1" fm expected got chars scope gesture jl line all_cmds tmp pchars
  [ -f "$file" ] || { echo "REFUS : fichier introuvable : $file" >&2; exit 2; }
  chars="$(wc -m < "$file" | tr -d ' ')"
  tmp="$(mktemp "$(sb_tmp_dir tools)/regime-note-XXXXXX")"
  trap 'rm -f "$tmp"' EXIT
  tr -d '\r' < "$file" > "$tmp"
  file="$tmp"
  NOTE_TMP="$tmp"

  # ---- R7: the form -------------------------------------------------------------
  fm="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$file")"
  # Mission 218: in a mode-2 Note, the Owner's prompt block is not counted.
  # Mission 219: nor is the Owner's go-ahead (owner_greenlight block).
  if [ "$(fm_value "$fm" origin)" = "owner-prompt" ]; then
    pchars="$(info_block "$(section "$file" '## Intent')" prompt | wc -m | tr -d ' ')"
    chars=$((chars - pchars))
    pchars="$(info_block "$(section "$file" '## Intent')" owner_greenlight | wc -m | tr -d ' ')"
    chars=$((chars - pchars))
  fi
  printf '%s\n' "$fm" | grep -Eq '^regime:[[:space:]]*light[[:space:]]*$' || add "R7-shape" "front matter lacks 'regime: light'"
  printf '%s\n' "$fm" | grep -Eq '^type:[[:space:]]*note[[:space:]]*$' || add "R7-shape" "front matter lacks 'type: note'"
  [ "$chars" -le "$NOTE_CAP" ] || add "R7-shape" "$chars characters, cap $NOTE_CAP (a Note that grows is a Mission)"
  expected="## Intent
## Scope
## Measure before
## Gesture
## Measure after
## Journal line"
  got="$(h2_list "$file" | grep -v '^## Liens$')"
  [ "$got" = "$expected" ] || add "R7-shape" "the rubrics must be exactly, in order: Intent, Scope, Measure before, Gesture, Measure after, Journal line (then an optional Liens); found: $(printf '%s' "$got" | paste -sd'|' -)"

  scope="$(section "$file" '## Scope')"
  gesture="$(fenced "$(section "$file" '## Gesture')")"
  blank "$scope" && add "R7-shape" "empty Scope"
  blank "$gesture" && add "R7-shape" "empty Gesture (one command per line, in a fenced block)"
  blank "$(section "$file" '## Measure before')" && add "R7-shape" "empty Measure before"
  blank "$(section "$file" '## Measure after')" && add "R7-shape" "empty Measure after"
  jl="$(fenced "$(section "$file" '## Journal line')" | grep -v '^[[:space:]]*$')"
  if [ -z "$jl" ] || [ "$(printf '%s\n' "$jl" | wc -l | tr -d ' ')" -ne 1 ]; then
    add "R7-shape" "Journal line: exactly one line, in a fenced block"
  else
    printf '%s' "$jl" | grep -Eq '^(STATE|OPEN|CLOSE):' || add "R7-shape" "Journal line must start with STATE:, OPEN: or CLOSE:"
    [ "$(printf '%s' "$jl" | wc -m | tr -d ' ')" -le "$JOURNAL_CAP" ] || add "R7-shape" "Journal line over $JOURNAL_CAP characters"
  fi

  # ---- R8: the form of a mode-2 Note (Mission 218) ------------------------------------
  check_origin "$orig" "$fm"

  # ---- the full-regime criteria ---------------------------------------------------
  grep -Eiq 'Glint''BloomWorks' "$file" && add "R5-company" "the company repository is named"
  while IFS= read -r line; do
    blank "$line" || scan_path "$line"
  done <<EOF
$scope
EOF
  while IFS= read -r line; do
    blank "$line" || scan_path "$line"
  done <<EOF
$gesture
EOF
  all_cmds="$(fenced "$(section "$file" '## Measure before')")
$gesture
$(fenced "$(section "$file" '## Measure after')")"
  while IFS= read -r line; do
    blank "$line" || scan_command "$line"
  done <<EOF
$all_cmds
EOF
  # ---- the Owner's go-ahead, last: it lifts only what it names (Mission 219) ----
  check_greenlight "$fm"
  finish
}

check_diff() {
  local repo="$1" range="$2" out st a b line
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "REFUS : pas un depot Git : $repo" >&2; exit 2; }
  out="$(git -C "$repo" diff --name-status -M "$range" 2>/dev/null)" || { echo "REFUS : plage illisible : $range" >&2; exit 2; }
  [ -n "$out" ] || { echo "REFUS : plage vide : $range" >&2; exit 2; }
  while IFS= read -r line; do
    st="$(printf '%s' "$line" | cut -f1)"
    a="$(printf '%s' "$line" | cut -f2)"
    b="$(printf '%s' "$line" | cut -f3)"
    case "$st" in D*) add "R2-destructive" "deleted : $a" ;; esac
    scan_path "$a"
    [ -z "$b" ] || scan_path "$b"
  done <<EOF
$out
EOF
  finish
}

MODE="${1:-}"
case "$MODE" in
  note) [ $# -eq 2 ] || usage; check_note "$2" ;;
  diff) [ $# -eq 3 ] || usage; check_diff "$2" "$3" ;;
  *) usage ;;
esac
