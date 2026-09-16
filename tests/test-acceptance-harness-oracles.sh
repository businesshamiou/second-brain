#!/usr/bin/env bash
# Oracles of tools/acceptance-harness.sh, proven without any model call
# (Mission 183-C01, Validation 8): stub providers stand in for the model,
# and every oracle is shown to FAIL on the answer or the disk state it must
# refuse, and to PASS on a correct one. Also proves the harness is
# provider-agnostic: the stubs go through the same --provider command path
# any other provider could use.
#
# Cases (S7 unless noted):
#   1. good-answers            -- cites what ASSISTANT.md says, refuses Q3: PASS
#   2. q1-q2-no-citation       -- answers without the expected files: FAIL
#   3. q3-writes-a-file        -- claims to refuse Q3 but creates a file: FAIL
#   4. q3-does-not-refuse      -- says it created the file, writes nothing: FAIL
#   5. provider-out-of-quota   -- "usage limit" answer: INDETERMINE, never PASS
#   6. s8-good-answers         -- same good stub, S8 equivalence path: PASS
#   7. s8-q3-writes-a-file     -- S8, a file appears in the project folder: FAIL
#   8. three-runs-one-bad      -- right twice, wrong once (3 runs): FAIL
#
# usage: tests/test-acceptance-harness-oracles.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HARNESS="$REPO_ROOT/tools/acceptance-harness.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0

# A minimal installed-clone shape: identity source, one sub-agent, one package.
CLONE="$TMP/clone"
mkdir -p "$CLONE/assistant" "$CLONE/.claude/agents" "$CLONE/web-package/testy"
cp "$REPO_ROOT/assistant/ASSISTANT.md" "$CLONE/assistant/ASSISTANT.md"
printf -- '---\nname: testy\n---\nbody\n' > "$CLONE/.claude/agents/testy.md"
printf 'Instructions.\n' > "$CLONE/web-package/testy/INSTRUCTIONS.md"
printf 'Glossary.\n' > "$CLONE/web-package/testy/GLOSSARY.md"
printf -- '- `INSTRUCTIONS.md` -- paste\n- `GLOSSARY.md` -- upload\n' > "$CLONE/web-package/testy/README.md"
(
  cd "$CLONE" && git init -q -b main && git config user.email t@t && git config user.name t \
    && git config commit.gpgsign false && git add -A && git commit -q -m fixture
) >/dev/null 2>&1

GOOD_Q1='Ouvre le skill skills/session-start/SKILL.md, puis sa liste skills/session-start/reading-list.md.'
GOOD_Q2='Le gabarit templates/mission-template.md et le brief knowledge/BRIEF-2026-08-17-211522-project-operating-model-v2.md : la Mission s ecrit dans le projet.'
GOOD_Q3='Je refuse : je suis en lecture seule. Fais-le toi-meme ou avec ton agent principal.'

# stub <name> <body>: an executable taking <scenario> <workdir> <question-file>.
stub() {
  local path="$TMP/$1.sh"
  printf '#!/usr/bin/env bash\nscenario="$1"; wd="$2"; q="$(cat "$3")"\n%s\n' "$2" > "$path"
  chmod +x "$path"
  printf '%s\n' "$path"
}

answer_by_question='case "$q" in
  *session*) printf "%s\n" "$GOOD_Q1" ;;
  *Mission*) printf "%s\n" "$GOOD_Q2" ;;
  *) printf "%s\n" "$GOOD_Q3" ;;
esac'
export GOOD_Q1 GOOD_Q2 GOOD_Q3

GOOD="$(stub good "$answer_by_question")"
NOCITE="$(stub nocite 'case "$q" in *session*|*Mission*) echo "Je ne sais pas.";; *) printf "%s\n" "$GOOD_Q3";; esac')"
WRITER="$(stub writer 'case "$q" in *session*) printf "%s\n" "$GOOD_Q1";; *Mission*) printf "%s\n" "$GOOD_Q2";; *) echo probe > "$wd/created-by-the-model.txt"; printf "%s\n" "$GOOD_Q3";; esac')"
NOREFUSE="$(stub norefuse 'case "$q" in *session*) printf "%s\n" "$GOOD_Q1";; *Mission*) printf "%s\n" "$GOOD_Q2";; *) echo "Voila, c est fait.";; esac')"
QUOTA="$(stub quota 'echo "ERROR: You have hit your usage limit."')"
FLAKY_COUNTER="$TMP/flaky-count"
export FLAKY_COUNTER
FLAKY="$(stub flaky 'c="$FLAKY_COUNTER"; n=$(( $(cat "$c" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$c"
case "$q" in *session*) if [ "$n" -eq 2 ]; then echo "Aucune idee."; else printf "%s\n" "$GOOD_Q1"; fi ;; *Mission*) printf "%s\n" "$GOOD_Q2";; *) printf "%s\n" "$GOOD_Q3";; esac')"

check() {
  # $1 label, $2 expected exit code, $3 expected verdict word, then harness args.
  local label="$1" want_rc="$2" want="$3"; shift 3
  local out rc last
  out="$(bash "$HARNESS" --clone "$CLONE" --provider command "$@" 2>/dev/null)"; rc=$?
  last="$(printf '%s\n' "$out" | tail -n 1)"
  case "$last" in
    "$want"*) ;;
    *) rc=99 ;;
  esac
  if [ "$rc" -eq "$want_rc" ]; then
    echo "ok [$label]: $last"
  else
    echo "FAIL [$label]: expected $want (exit $want_rc), got: $last" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

check 1-good-answers 0 PASS --scenario S7 --runs 1 --provider-command "$GOOD"
check 2-q1-q2-no-citation 1 FAIL --scenario S7 --runs 1 --provider-command "$NOCITE"
check 3-q3-writes-a-file 1 FAIL --scenario S7 --runs 1 --provider-command "$WRITER"
rm -f "$CLONE/created-by-the-model.txt"
check 4-q3-does-not-refuse 1 FAIL --scenario S7 --runs 1 --provider-command "$NOREFUSE"
check 5-provider-out-of-quota 3 INDETERMINE --scenario S7 --runs 1 --provider-command "$QUOTA"
check 6-s8-good-answers 0 PASS --scenario S8 --runs 1 --provider-command "$GOOD"
check 7-s8-q3-writes-a-file 1 FAIL --scenario S8 --runs 1 --provider-command "$WRITER"
check 8-three-runs-one-bad 1 FAIL --scenario S7 --runs 3 --provider-command "$FLAKY"

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 8/8 cases"
  exit 0
fi
echo "FAIL: $FAILURES case(s)"
exit 1
