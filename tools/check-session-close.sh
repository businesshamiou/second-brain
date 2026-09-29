#!/usr/bin/env bash
# Session-close guardian (Mission 217): a handoff cannot come into a project
# without its close.
#
# The Pilot writes the handoff, the Executor closes the session (journal lines,
# STATE.md, DIGEST.md, commit). Nothing tied the two halves: on 2026-09-21 a
# handoff was filed at 11:21 and the close was never prescribed; the next
# window found a stale digest (ANOMALY) and the close was caught up at 13:16.
#
# When a commit brings in (adds or modifies) a project's NEWEST handoff --
# <project>/handoffs/HANDOFF-YYYY-...md -- this guardian requires, in the same
# commit:
#   1. the project's DIGEST (<project>/state/DIGEST.md) names that handoff on
#      its « Dernier handoff : » line;
#   2. the project's journal (<project>/state/journal.md) carries a `STATE:`
#      line whose timestamp is LATER than the handoff's `created_at`
#      (instants compared in UTC: a line that only looks later, in another
#      offset, does not count).
# A handoff corrected after the fact (the case of 112112, edited at 11:41)
# still needs the DIGEST that names it and a STATE: line later than its
# created_at -- not a new complete close.
#
# A handoff that is not the newest of its project (a link added to an old one)
# is a correction of history: nothing is demanded. A commit that brings in no
# handoff passes WITHOUT reading anything.
#
# It reads the Git INDEX (`git diff --cached`, `git show :<path>`), never the
# working tree: what counts is what is committed. Fail-closed: a missing
# DIGEST, journal or created_at refuses.
#
# It is a PROJECT guardian: it lives here, in the Vault, and a project wires it
# in its .pre-commit-config.yaml (entry: ../vault/tools/check-session-close.sh).
# Wiring it into the projects of the audience (project-bootstrap.sh) is a
# separate door.
#
# usage: check-session-close.sh            (current repository, staged files)
# Portable to bash 3.2 and to the awk of Apple: no GNU-only construct.

set -u

VAULT_ROOT="$(git rev-parse --show-toplevel)" || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}

STAGED="$(git -C "$VAULT_ROOT" -c core.quotepath=off diff --cached --name-only --diff-filter=AM 2>/dev/null)" || {
  echo "REFUS : git diff --cached a echoue : gardien non executable." >&2
  exit 1
}

# The handoffs among the staged files; none -> nothing to read.
HANDOFFS="$(printf '%s\n' "$STAGED" | grep -E '(^|/)handoffs/HANDOFF-[0-9]{4}-[^/]*\.md$' || true)"
[ -n "$HANDOFFS" ] || exit 0

# ts_epoch: reads ISO timestamps on the standard input, one per line, prints
# their instant in seconds since 1970 UTC (or -1 when unreadable).
AWK_EPOCH='
  function tsepoch(s,   y, m, d, hh, mi, ss, rest, i, sign, oh, om, off, yy, era, yoe, mm, doy, doe, days) {
    if (length(s) < 19) return -1
    if (substr(s, 5, 1) != "-" || substr(s, 8, 1) != "-" || substr(s, 11, 1) != "T") return -1
    y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
    hh = substr(s, 12, 2) + 0; mi = substr(s, 15, 2) + 0; ss = substr(s, 18, 2) + 0
    rest = substr(s, 20)
    if (substr(rest, 1, 1) == ".") { i = 2; while (substr(rest, i, 1) ~ /[0-9]/) i++; rest = substr(rest, i) }
    off = 0
    if (rest != "" && rest != "Z") {
      sign = substr(rest, 1, 1)
      if (sign != "+" && sign != "-") return -1
      oh = substr(rest, 2, 2) + 0
      if (substr(rest, 4, 1) == ":") om = substr(rest, 5, 2) + 0; else om = substr(rest, 4, 2) + 0
      off = oh * 3600 + om * 60
      if (sign == "-") off = -off
    }
    yy = y - (m <= 2)
    era = int(yy / 400)
    yoe = yy - era * 400
    mm = m + (m > 2 ? -3 : 9)
    doy = int((153 * mm + 2) / 5) + d - 1
    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
    days = era * 146097 + doe - 719468
    return days * 86400 + hh * 3600 + mi * 60 + ss - off
  }
'

FAIL=0
refuse() {
  # $1 handoff, $2 what is missing, $3 how to close
  echo "SESSION-CLOSE-MISSING : $1 entre $2" >&2
  echo "  Remede : $3" >&2
  FAIL=1
}

while IFS= read -r h; do
  [ -z "$h" ] && continue
  case "$h" in
    */handoffs/*) prefix="${h%handoffs/*}" ;;   # ends with "/"
    *) prefix="" ;;
  esac
  name="${h##*/}"

  # Only the newest handoff of the project (as the index holds it) is a close.
  newest="$(git -C "$VAULT_ROOT" ls-files -- "${prefix}handoffs" | grep -E '(^|/)HANDOFF-[0-9]{4}-[^/]*\.md$' | sort | tail -n 1)"
  [ "$h" = "$newest" ] || continue

  digest="${prefix}state/DIGEST.md"
  journal="${prefix}state/journal.md"

  if ! git -C "$VAULT_ROOT" cat-file -e ":$digest" 2>/dev/null; then
    refuse "$h" "sans DIGEST qui le nomme (aucun $digest dans l'index)" "bash tools/build-digest.sh ${prefix:-.} puis stager $digest"
    continue
  fi
  named="$(git -C "$VAULT_ROOT" show ":$digest" 2>/dev/null | tr -d '\r' | sed -n 's/^Dernier handoff : //p' | head -n 1)"
  if [ "$named" != "$name" ]; then
    refuse "$h" "sans DIGEST qui le nomme (le DIGEST de l'index nomme « ${named:-rien} »)" "regenerer le DIGEST apres le depot du handoff (build-digest.sh) et le stager avec lui"
    continue
  fi

  created="$(git -C "$VAULT_ROOT" show ":$h" 2>/dev/null | tr -d '\r' \
    | awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} /^created_at:/{v=$0; sub(/^created_at:[[:space:]]*/,"",v); gsub(/"/,"",v); print v; exit}')"
  cepoch="$(printf '%s\n' "$created" | LC_ALL=C awk "$AWK_EPOCH"'{ print tsepoch($0) }')"
  case "$cepoch" in
    ''|-1) refuse "$h" "sans created_at lisible (front matter : « ${created:-absent} »)" "donner au handoff un created_at ISO, AAAA-MM-JJTHH:MM:SS+HH:MM"; continue ;;
  esac

  if ! git -C "$VAULT_ROOT" cat-file -e ":$journal" 2>/dev/null; then
    refuse "$h" "sans ligne STATE: postérieure (aucun $journal dans l'index)" "ecrire la ligne STATE: de cloture avec vault/tools/append-journal.sh puis stager $journal"
    continue
  fi
  later="$(git -C "$VAULT_ROOT" show ":$journal" 2>/dev/null | tr -d '\r' \
    | LC_ALL=C awk -v c="$cepoch" "$AWK_EPOCH"'
        $2 ~ /^(STATE|ETAT):/ { if (tsepoch($1) > c + 0) { print "yes"; exit } }')"
  if [ "$later" != "yes" ]; then
    refuse "$h" "sans ligne STATE: postérieure à son created_at ($created)" "ecrire la ligne STATE: de cloture avec vault/tools/append-journal.sh (une ligne apres le depot du handoff) puis stager $journal"
    continue
  fi
done <<EOF_HANDOFFS
$HANDOFFS
EOF_HANDOFFS

if [ "$FAIL" -ne 0 ]; then
  echo "REFUS : la cloture de session manque (Mission 217)." >&2
  exit 1
fi
exit 0
