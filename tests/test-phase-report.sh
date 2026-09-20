#!/usr/bin/env bash
# Mission 203, fix 6: tools/phase-report.sh reads the `PHASE:<name>:<debut|fin>`
# lines of a project journal and renders `phase | debut | fin | secondes`.
#
# Oracles (PASS expected):
#   (a) six well-formed phases: six rows in journal order, the exact seconds, a total
#       (time zones mixed: -04:00, +02:00, Z);
#   (b) two runs in one journal: only the LAST run is read;
#   (c) refusals, each with its accepted twin (exit 1, nothing rendered):
#       a phase opened before the previous one is closed, a phase opened twice, a closing
#       with no opening, an end before its beginning, a journal with no PHASE line;
#   (d) a last phase still open is shown as `ouverte`, not refused;
#   (e) other journal lines (STATE:, OPEN:) and a `PHASE:` inside a sentence are ignored;
#   (f) end to end: a journal written by tools/append-journal.sh is read back, six
#       rows, exit 0;
#   (g) read-only: the journal's bytes are unchanged after a run.
#
# Writes only in a temporary folder (prefix m203-phase).
#
# usage: bash tests/test-phase-report.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$REPO_ROOT/tools/phase-report.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m203-phase-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

# journal <name> <line>...: a project folder whose journal holds those lines.
journal() {
  local name="$1"; shift
  mkdir -p "$TMP/$name/state"
  printf '# Journal\n\n## Liens\n\n- `see also` — [x](../README.md)\n\n' > "$TMP/$name/state/journal.md"
  local l
  for l in "$@"; do printf '%s\n' "$l" >> "$TMP/$name/state/journal.md"; done
}
run() { bash "$TOOL" "$TMP/$1" 2>"$TMP/err.txt"; }

# --- (a) six phases, mixed time zones -------------------------------------------------------
journal a \
  "2026-09-20T13:00:00-04:00 PHASE:lecture:debut" \
  "2026-09-20T13:01:40-04:00 PHASE:lecture:fin" \
  "2026-09-20T17:01:40Z PHASE:preflight:debut" \
  "2026-09-20T17:02:00Z PHASE:preflight:fin" \
  "2026-09-20T19:02:00+02:00 PHASE:mesures:debut" \
  "2026-09-20T19:05:00+02:00 PHASE:mesures:fin" \
  "2026-09-20T13:05:00-04:00 PHASE:ecritures:debut" \
  "2026-09-20T13:15:00-04:00 PHASE:ecritures:fin" \
  "2026-09-20T13:15:00-04:00 PHASE:preuves:debut" \
  "2026-09-20T13:16:30-04:00 PHASE:preuves:fin" \
  "2026-09-20T13:16:31-04:00 PHASE:rangement:debut" \
  "2026-09-20T13:17:00-04:00 PHASE:rangement:fin"
OUT="$(run a)"; RC=$?
ROWS="$(printf '%s\n' "$OUT" | sed -n '2,7p' | awk -F' [|] ' '{print $1":"$4}' | tr '\n' ' ')"
if [ "$RC" = "0" ] && [ "$ROWS" = "lecture:100 preflight:20 mesures:180 ecritures:600 preuves:90 rangement:29 " ] \
   && printf '%s\n' "$OUT" | tail -n 1 | grep -q '^total | | | 1019$'; then
  pass "(a) six phases, fuseaux -04:00 / Z / +02:00 : secondes exactes ($ROWS), total 1019"
else
  fail "(a) six phases : rc $RC, lignes '$ROWS', sortie : $(printf '%s' "$OUT" | tail -n 2 | tr '\n' '/')"
fi

# --- (b) only the last run --------------------------------------------------------------------
journal b \
  "2026-09-19T10:00:00-04:00 PHASE:lecture:debut" \
  "2026-09-19T10:10:00-04:00 PHASE:lecture:fin" \
  "2026-09-20T09:00:00-04:00 PHASE:lecture:debut" \
  "2026-09-20T09:00:30-04:00 PHASE:lecture:fin" \
  "2026-09-20T09:00:30-04:00 PHASE:preflight:debut" \
  "2026-09-20T09:01:00-04:00 PHASE:preflight:fin"
OUT="$(run b)"; RC=$?
if [ "$RC" = "0" ] && [ "$(printf '%s\n' "$OUT" | grep -c '^lecture')" = "1" ] && printf '%s\n' "$OUT" | grep -q '^lecture .* | 30$'; then
  pass "(b) deux passages dans le journal : seul le dernier est lu (lecture 30 s, non 600)"
else
  fail "(b) deux passages : rc $RC, sortie : $(printf '%s' "$OUT" | tr '\n' '/')"
fi

# --- (c) refusals, each with its accepted twin ----------------------------------------------------
refused() { # <name> <description> <lines...>
  local name="$1" what="$2"; shift 2
  journal "$name" "$@"
  local out rc
  out="$(run "$name")"; rc=$?
  if [ "$rc" = "1" ] && [ -z "$out" ] && grep -q '^REFUS phase-report.sh' "$TMP/err.txt"; then
    pass "(c) refus net : $what"
  else
    fail "(c) $what : rc $rc, sortie '$out', stderr '$(head -n 1 "$TMP/err.txt")'"
  fi
}
refused c1 "une phase s'ouvre avant la fermeture de la precedente" \
  "2026-09-20T10:00:00-04:00 PHASE:lecture:debut" "2026-09-20T10:01:00-04:00 PHASE:preflight:debut"
refused c2 "une phase ouverte deux fois" \
  "2026-09-20T10:00:00-04:00 PHASE:lecture:debut" "2026-09-20T10:01:00-04:00 PHASE:lecture:fin" \
  "2026-09-20T10:01:00-04:00 PHASE:mesures:debut" "2026-09-20T10:02:00-04:00 PHASE:mesures:fin" \
  "2026-09-20T10:03:00-04:00 PHASE:mesures:debut"
refused c3 "une fermeture sans ouverture" \
  "2026-09-20T10:00:00-04:00 PHASE:lecture:fin"
refused c4 "une fin avant son debut" \
  "2026-09-20T10:00:00-04:00 PHASE:lecture:debut" "2026-09-20T09:59:00-04:00 PHASE:lecture:fin"
journal c5 "2026-09-20T10:00:00-04:00 STATE: rien a mesurer"
OUT="$(run c5)"; RC=$?
[ "$RC" = "1" ] && [ -z "$OUT" ] && pass "(c) refus net : un journal sans ligne PHASE" || fail "(c) journal sans PHASE : rc $RC"
mkdir -p "$TMP/c6"; OUT="$(run c6)"; RC=$?
[ "$RC" = "1" ] && pass "(c) refus net : journal introuvable" || fail "(c) journal introuvable : rc $RC"
# the accepted twin of c1: the same two phases, the first closed before the second opens
journal c1ok "2026-09-20T10:00:00-04:00 PHASE:lecture:debut" "2026-09-20T10:01:00-04:00 PHASE:lecture:fin" \
  "2026-09-20T10:01:00-04:00 PHASE:preflight:debut" "2026-09-20T10:02:00-04:00 PHASE:preflight:fin"
OUT="$(run c1ok)"; RC=$?
[ "$RC" = "0" ] && pass "(c) jumeau accepte : les deux memes phases, fermees dans l'ordre (exit 0)" || fail "(c) jumeau accepte : rc $RC"

# --- (d) last phase open ------------------------------------------------------------------------------
journal d "2026-09-20T10:00:00-04:00 PHASE:lecture:debut" "2026-09-20T10:00:10-04:00 PHASE:lecture:fin" \
  "2026-09-20T10:00:10-04:00 PHASE:preflight:debut"
OUT="$(run d)"; RC=$?
if [ "$RC" = "0" ] && printf '%s\n' "$OUT" | grep -q '^preflight | .* | ouverte | -$'; then
  pass "(d) derniere phase non fermee : montree 'ouverte', exit 0"
else
  fail "(d) phase ouverte : rc $RC, sortie $(printf '%s' "$OUT" | tr '\n' '/')"
fi

# --- (e) other lines ignored ------------------------------------------------------------------------------
journal e "2026-09-20T10:00:00-04:00 STATE: une phrase avec PHASE:lecture:debut au milieu" \
  "2026-09-20T10:00:05-04:00 OPEN:open-x -- PHASE:lecture:fin ne compte pas" \
  "2026-09-20T10:01:00-04:00 PHASE:lecture:debut" "2026-09-20T10:01:20-04:00 PHASE:lecture:fin"
OUT="$(run e)"; RC=$?
if [ "$RC" = "0" ] && printf '%s\n' "$OUT" | grep -q '^lecture .* | 20$' && [ "$(printf '%s\n' "$OUT" | grep -c '^lecture')" = "1" ]; then
  pass "(e) STATE:, OPEN: et un PHASE: au milieu d'une phrase sont ignores"
else
  fail "(e) lignes etrangeres : rc $RC, sortie $(printf '%s' "$OUT" | tr '\n' '/')"
fi

# --- (f) end to end with append-journal.sh ----------------------------------------------------------------
mkdir -p "$TMP/f"; printf '# f\n' > "$TMP/f/README.md"
for step in lecture:debut lecture:fin preflight:debut preflight:fin mesures:debut mesures:fin \
            ecritures:debut ecritures:fin preuves:debut preuves:fin rangement:debut rangement:fin; do
  bash "$REPO_ROOT/tools/append-journal.sh" "$TMP/f" "PHASE:$step" || break
done
OUT="$(run f)"; RC=$?
if [ "$RC" = "0" ] && [ "$(printf '%s\n' "$OUT" | grep -c ' | [0-9]*$')" -ge 6 ] && printf '%s\n' "$OUT" | sed -n '2p' | grep -q '^lecture'; then
  pass "(f) journal ecrit par append-journal.sh relu : six lignes, exit 0"
else
  fail "(f) de bout en bout : rc $RC, sortie $(printf '%s' "$OUT" | tr '\n' '/')"
fi

# --- (g) read-only ------------------------------------------------------------------------------------------
B1="$(cksum < "$TMP/a/state/journal.md")"; run a >/dev/null; B2="$(cksum < "$TMP/a/state/journal.md")"
[ "$B1" = "$B2" ] && pass "(g) le journal est inchange apres une lecture" || fail "(g) le journal a change"

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
