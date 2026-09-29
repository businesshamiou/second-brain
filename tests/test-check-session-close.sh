#!/usr/bin/env bash
# Mission 217: a session close cannot be skipped. Three locks, one test.
#
#   Lock at the commit: tools/check-session-close.sh refuses a commit that
#   brings in the project's newest handoff without the DIGEST that names it
#   and without a `STATE:` line of the journal later than the handoff's
#   created_at. It reads the Git INDEX (what is committed), and reads nothing
#   when no handoff is staged.
#   Lock at the writing: the handoff template carries the Executor closing
#   command, in a code block.
#   Lock at the next opening: the Pilot's reading list says NOT-READY when
#   the digest's last handoff is older than the newest file of handoffs/.
#
# Cases, in a throwaway repository that imitates a project (state/, handoffs/,
# the DIGEST written by the real tools/build-digest.sh):
#   (1) a handoff alone                                    -> refused
#   (2) a handoff + a DIGEST that names an OLDER handoff   -> refused
#   (3) a handoff + its DIGEST, no later STATE: line       -> refused (also when
#       the STATE: line only LOOKS later: another UTC offset)
#   (4) handoff + DIGEST that names it + a later STATE:    -> accepted
#   (5) a commit without a handoff                         -> accepted, nothing read
#   (6) the tracked handoff corrected, DIGEST and STATE:   -> accepted
#   (7) template: `## Executor closing command`, with a code block
#   (8) reading list: the "session close missing" line is in the Pilot section
#   (9) witness: a stand-in guardian that accepts everything is caught by (1)-(3)
#
# Writes only in a temporary folder (prefix m217). No model call. bash 3.2.
#
# usage: bash tests/test-check-session-close.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$REPO_ROOT/tools/check-session-close.sh"
DIGEST_TOOL="$REPO_ROOT/tools/build-digest.sh"
TEMPLATE="$REPO_ROOT/templates/handoff-template.md"
READING="$REPO_ROOT/skills/session-start/reading-list.md"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m217-close-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
R="$TMP/repo"

G() { git -C "$R" -c user.email=t@example.invalid -c user.name=t -c commit.gpgsign=false -c core.autocrlf=false "$@"; }

# A git shim that notes every `show` (a read of the index), to prove (5).
SHIM="$TMP/shim"; mkdir -p "$SHIM"
REALGIT="$(command -v git)"
printf '#!/usr/bin/env bash\ncase "${1:-}" in show|cat-file) echo "$1" >> "$M217_LOG" ;; esac\nexec "%s" "$@"\n' "$REALGIT" > "$SHIM/git"
chmod +x "$SHIM/git"

# run_guard <guardian> : runs it in the repository, output in $TMP/out, status in $RC.
run_guard() {
  RC=0
  : > "$TMP/reads"
  ( cd "$R" && PATH="$SHIM:$PATH" M217_LOG="$TMP/reads" bash "$1" ) > "$TMP/out" 2>&1 || RC=$?
}
refused_for() { [ "$RC" -ne 0 ] && grep -q "SESSION-CLOSE-MISSING" "$TMP/out" && grep -q -- "$1" "$TMP/out"; }

mk_handoff() { # <path> <created_at>
  printf -- '---\ntype: handoff\ntitle: "probe"\ncreated_at: "%s"\ntimezone: America/Montreal\nstatus: active\n---\n\n# HANDOFF\n\nbody\n\n## Liens\n\n- `see also` — [x](../README.md)\n' "$2" > "$R/$1"
}
digest() { (cd "$R" && bash "$DIGEST_TOOL" proj >/dev/null 2>&1); }
A="proj/handoffs/HANDOFF-2026-09-21-090000-first.md"
B="proj/handoffs/HANDOFF-2026-09-21-112112-second.md"
reset_world() { G reset -q --hard BASE && G clean -qfd; }

echo "=== T (M217) : la cloture ne peut plus etre sautee ==="

if [ ! -f "$DIGEST_TOOL" ]; then echo "FAIL : build-digest.sh introuvable"; exit 1; fi

# --- the throwaway project -----------------------------------------------------
mkdir -p "$R/proj/state" "$R/proj/handoffs" "$R/proj/missions" "$R/proj/reports"
G init -q -b main 2>/dev/null || G init -q
printf '2026-09-21T08:30:00-04:00 STATE: opening\n' > "$R/proj/state/journal.md"
printf '| ID | Statut | Date | Rapport |\n|---|---|---|---|\n' > "$R/proj/missions/MISSION-INDEX.md"
mk_handoff "$A" "2026-09-21T09:00:00-04:00"
printf '2026-09-21T09:05:00-04:00 STATE: close of the first session\n' >> "$R/proj/state/journal.md"
digest
G add -A && G commit -q -m base || { echo "FAIL : throwaway project not built"; exit 1; }
G tag BASE
if ! grep -q "Dernier handoff : HANDOFF-2026-09-21-090000-first.md" "$R/proj/state/DIGEST.md"; then echo "FAIL : the digest does not name the first handoff"; exit 1; fi

# --- (1) a handoff alone --------------------------------------------------------
echo ""
echo "=== (1) a handoff alone ==="
mk_handoff "$B" "2026-09-21T11:21:12-04:00"; G add "$B"
run_guard "$GUARD"
if refused_for "sans DIGEST qui le nomme"; then pass "(1) refused: the handoff comes in without a DIGEST that names it"; else fail "(1) rc=$RC ; $(tr '\n' ' ' < "$TMP/out" | cut -c1-200)"; fi

# --- (2) a DIGEST that names an older handoff -------------------------------------
echo ""
echo "=== (2) a DIGEST that names an older handoff ==="
reset_world; mk_handoff "$B" "2026-09-21T11:21:12-04:00"
printf '\n(touched)\n' >> "$R/proj/state/DIGEST.md"; G add "$B" proj/state/DIGEST.md
run_guard "$GUARD"
if refused_for "sans DIGEST qui le nomme"; then pass "(2) refused: the DIGEST names the older handoff"; else fail "(2) rc=$RC ; $(tr '\n' ' ' < "$TMP/out" | cut -c1-200)"; fi

# --- (3) DIGEST right, no later STATE: --------------------------------------------
echo ""
echo "=== (3) the DIGEST names it, no later STATE: line ==="
reset_world; mk_handoff "$B" "2026-09-21T11:21:12-04:00"; G add "$B"; digest; G add proj/state/DIGEST.md
run_guard "$GUARD"
if refused_for "sans ligne STATE: post"; then pass "(3) refused: no STATE: line later than the handoff"; else fail "(3) rc=$RC ; $(tr '\n' ' ' < "$TMP/out" | cut -c1-200)"; fi
# 15:00+05:00 reads later than 11:21 as text, and is 06:00 in -04:00: earlier.
printf '2026-09-21T15:00:00+05:00 STATE: looks later, is earlier\n' >> "$R/proj/state/journal.md"; G add proj/state/journal.md
run_guard "$GUARD"
if refused_for "sans ligne STATE: post"; then pass "(3) refused: a STATE: line that only looks later (another UTC offset) does not count"; else fail "(3) offset case: rc=$RC ; $(tr '\n' ' ' < "$TMP/out" | cut -c1-200)"; fi

# --- (4) the whole close ----------------------------------------------------------
echo ""
echo "=== (4) handoff + DIGEST + later STATE: ==="
printf '2026-09-21T13:16:43-04:00 STATE: close of the second session\n' >> "$R/proj/state/journal.md"; G add proj/state/journal.md
run_guard "$GUARD"
if [ "$RC" -eq 0 ]; then pass "(4) accepted: the handoff comes with its DIGEST and a later STATE: line"; else fail "(4) rc=$RC ; $(tr '\n' ' ' < "$TMP/out" | cut -c1-200)"; fi
G commit -q -m "close" 2>/dev/null

# --- (6) the tracked handoff corrected ----------------------------------------------
echo ""
echo "=== (6) the tracked handoff corrected ==="
printf '\ncorrection\n' >> "$R/$B"; G add "$B"
run_guard "$GUARD"
if [ "$RC" -eq 0 ]; then pass "(6) accepted: the corrected handoff, its DIGEST and a later STATE: line are in the index"; else fail "(6) rc=$RC ; $(tr '\n' ' ' < "$TMP/out" | cut -c1-200)"; fi
G reset -q --hard HEAD

# --- (5) no handoff, nothing read ------------------------------------------------------
echo ""
echo "=== (5) a commit without a handoff ==="
reset_world
printf 'note\n' > "$R/proj/notes.md"; G add proj/notes.md
run_guard "$GUARD"
if [ "$RC" -eq 0 ] && [ ! -s "$TMP/reads" ]; then pass "(5) accepted, and nothing of the index was read"; else fail "(5) rc=$RC reads=$(wc -l < "$TMP/reads" | tr -d ' ') ; $(tr '\n' ' ' < "$TMP/out" | cut -c1-200)"; fi

# --- (7) the template ---------------------------------------------------------------------
echo ""
echo "=== (7) the handoff template ==="
if [ -f "$TEMPLATE" ] && [ "$(grep -c '^## Executor closing command' "$TEMPLATE")" = "1" ] \
   && awk '/^## Executor closing command/{f=1;next} /^## /{f=0} f && /^```/{c++} END{exit !(c>=2)}' "$TEMPLATE"; then
  pass "(7) the template carries '## Executor closing command' with a code block"
else fail "(7) the section, or its code block, is missing from the template"; fi

# --- (8) the reading list --------------------------------------------------------------------
echo ""
echo "=== (8) the reading list ==="
if [ -f "$READING" ] && awk '/^## Pilot[[:space:]]*$/{f=1;next} /^## /{f=0} f && tolower($0) ~ /session close missing/{c++} END{exit !(c>=1)}' "$READING"; then
  pass "(8) the Pilot section says NOT-READY (session close missing)"
else fail "(8) the 'session close missing' line is not in the Pilot section"; fi

# --- (9) the witness ------------------------------------------------------------------------------
echo ""
echo "=== (9) witness: a stand-in that accepts everything ==="
FAKE="$TMP/fake-guardian.sh"; printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKE"
caught=0
reset_world; mk_handoff "$B" "2026-09-21T11:21:12-04:00"; G add "$B"
run_guard "$FAKE"; refused_for "sans DIGEST" || caught=$((caught + 1))
reset_world; mk_handoff "$B" "2026-09-21T11:21:12-04:00"; printf '\n(touched)\n' >> "$R/proj/state/DIGEST.md"; G add "$B" proj/state/DIGEST.md
run_guard "$FAKE"; refused_for "sans DIGEST" || caught=$((caught + 1))
reset_world; mk_handoff "$B" "2026-09-21T11:21:12-04:00"; G add "$B"; digest; G add proj/state/DIGEST.md
run_guard "$FAKE"; refused_for "sans ligne STATE" || caught=$((caught + 1))
if [ "$caught" -eq 3 ]; then pass "(9) the stand-in fails (1), (2) and (3): the test can fail"; else fail "(9) the stand-in was caught $caught time(s) out of 3"; fi

echo ""
echo "=== RESULT: $PASSES PASS, $FAILURES FAIL ==="
[ "$FAILURES" -eq 0 ] && exit 0
exit 1
