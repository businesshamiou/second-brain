#!/usr/bin/env bash
# Reads the PHASE lines of a project journal and renders how long each phase
# lasted (Mission 203, the Owner's request of 2026-09-20 to measure where the minutes of
# a Mission go). Read-only: never writes, never corrects.
#
# Convention (RULES-2026-08-23-220049, section 7, note of Mission 203): a journal line
#   <ISO timestamp> PHASE:<name>:<debut|fin>
# written by tools/append-journal.sh at each boundary. This tool reads the LAST
# run: from the last opening of the first phase seen, while nothing is open.
#
# Output: a table `phase | debut | fin | secondes`, one row per phase in journal
# order, then a `total` row (closed phases only). Exit 0.
# Refusals (exit 1, one line on stderr, nothing rendered):
#   - a phase opened before the previous one is closed;
#   - a phase opened twice in the same run;
#   - a closing with no matching opening;
#   - a phase whose end is before its beginning;
#   - no PHASE line at all, or an unreadable journal.
# An unclosed last phase is shown as `ouverte`, not refused (a run in progress).
#
# usage: phase-report.sh <project-path>     (reads <project-path>/state/journal.md)
#
# POSIX awk only (no gawk extension), bash 3.2.

set -u

PROJECT="${1:-}"
if [ -z "$PROJECT" ]; then
  echo "usage: phase-report.sh <chemin-projet>" >&2
  exit 2
fi
JOURNAL="$PROJECT/state/journal.md"
if [ ! -f "$JOURNAL" ]; then
  echo "REFUS phase-report.sh : journal introuvable : $JOURNAL" >&2
  exit 1
fi

tr -d '\r' < "$JOURNAL" | awk '
# Seconds since the epoch of an ISO 8601 timestamp (civil-days algorithm, no
# dependency on the date command: GNU and BSD date differ).
function epoch(ts,   y, m, d, hh, mi, ss, rest, off, sign, yy, era, yoe, doy, doe, days) {
  y = substr(ts, 1, 4) + 0; m = substr(ts, 6, 2) + 0; d = substr(ts, 9, 2) + 0
  hh = substr(ts, 12, 2) + 0; mi = substr(ts, 15, 2) + 0; ss = substr(ts, 18, 2) + 0
  rest = substr(ts, 20); off = 0
  if (rest ~ /^[+-][0-9][0-9]:[0-9][0-9]$/) {
    sign = (substr(rest, 1, 1) == "-") ? -1 : 1
    off = sign * (substr(rest, 2, 2) * 3600 + substr(rest, 5, 2) * 60)
  }
  yy = y - ((m <= 2) ? 1 : 0)
  era = int(((yy >= 0) ? yy : yy - 399) / 400)
  yoe = yy - era * 400
  doy = int((153 * (m + ((m > 2) ? -3 : 9)) + 2) / 5) + d - 1
  doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
  days = era * 146097 + doe - 719468
  return days * 86400 + hh * 3600 + mi * 60 + ss - off
}
function refuse(msg) {
  print "REFUS phase-report.sh : " msg > "/dev/stderr"
  bad = 1
  exit 1
}
BEGIN { n = 0; open = ""; first = ""; bad = 0 }
$1 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ && $2 ~ /^PHASE:[A-Za-z0-9-]+:(debut|fin)$/ {
  split($2, f, ":")
  name = f[2]; tag = f[3]; ts = $1; e = epoch(ts); found = 1
  if (first == "") first = name
  if (tag == "debut") {
    if (open != "") refuse("la phase " name " s ouvre avant la fermeture de " open " (ligne " NR ")")
    if (name == first && n > 0) { n = 0; split("", seen) }
    if (name in seen) refuse("la phase " name " est ouverte deux fois (ligne " NR ")")
    n++; nm[n] = name; b[n] = e; bts[n] = ts; en[n] = ""; seen[name] = n; open = name; oi = n
  } else {
    if (open == "" || open != name) refuse("fermeture de " name " sans ouverture (ligne " NR ")")
    if (e < b[oi]) refuse("la phase " name " finit avant de commencer (ligne " NR ")")
    en[oi] = e; ets[oi] = ts; open = ""
  }
}
END {
  if (bad) exit 1
  if (!found) { print "REFUS phase-report.sh : aucune ligne PHASE dans le journal" > "/dev/stderr"; exit 1 }
  print "phase | debut | fin | secondes"
  total = 0
  for (i = 1; i <= n; i++) {
    if (en[i] == "") { printf "%s | %s | ouverte | -\n", nm[i], bts[i]; continue }
    printf "%s | %s | %s | %d\n", nm[i], bts[i], ets[i], en[i] - b[i]
    total += en[i] - b[i]
  }
  printf "total | | | %d\n", total
}
'
exit $?
