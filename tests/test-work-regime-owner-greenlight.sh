#!/usr/bin/env bash
# Mission 219, lot B (Owner arbitration of 2026-09-23 09:08, Decision
# 2026-09-23-105507): when a prompt of the Owner meets a full-regime
# criterion, the Executor asks; the Owner's answer is written word for word in
# the mode-2 Note, in one ```owner_greenlight block (real time, the criteria
# it lifts), and execution goes on under the light regime.
#
#   (a) a 2a Note meeting R3-doctrine, with a greenlight block (at:, lifts:
#       R3-doctrine, the answer as received) -> accepted, and the tool says
#       which criteria the Owner lifted and when;
#   (b) the same Note without the block -> refused, and the refusal names the
#       way out: ask the Owner;
#   (c) a block with no answer line -> R8-origin;
#   (d) a block with no time, or a time without offset -> R8-origin;
#   (e) the block lifts R3-doctrine only, the Note also meets R2-destructive
#       -> refused R2-destructive (only the criteria named are lifted);
#   (f) a greenlight in a Pilot's Note (no origin:) -> R8-origin: the go-ahead
#       answers an Owner's prompt, never a Pilot's choice of regime;
#   (g) a greenlight never lifts the form: a Note without Measure before stays
#       R7-shape;
#   (h) witness: two greenlight blocks -> R8-origin;
#   (i) the greenlight block is not counted in the cap, like the prompt block.
# The checker under test is WORK_REGIME_TOOL=<file> (default: this repository's).
#
# usage: bash tests/test-work-regime-owner-greenlight.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="${WORK_REGIME_TOOL:-$REPO_ROOT/tools/check-work-regime.sh}"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m219-greenlight-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else openssl dgst -sha256 | awk '{print $NF}'; fi
}

PROMPT="Ajoute une ligne a la regle des deux regimes pour citer le feu vert, sans rien pousser."
PROMPT_SHA="$(printf '%s' "$PROMPT" | sha)"
ANSWER="Oui, vas-y pour la regle, en regime leger."
GL_DEFAULT="at: 2026-09-23T09:12:40-04:00
lifts: R3-doctrine
$ANSWER"

# mknote <file> : a mode-2 Note meeting R3-doctrine; parts overridable.
mknote() {
  local f="$1"
  {
    printf -- '---\ntype: note\ntitle: "Feu vert"\ndescription: "d"\ncreated_at: "2026-09-23T09:10:00-04:00"\ntimezone: America/Montreal\nregime: light\nscope: greenlight\n'
    if [ "${G_NO_ORIGIN:-}" != 1 ]; then
      printf 'origin: owner-prompt\nmode: 2a\nreceived_at: "2026-09-23T09:09:30-04:00"\nprompt_sha256: %s\n' "$PROMPT_SHA"
    fi
    printf -- '---\n\n# NOTE — FEU VERT\n\n## Intent\n\nPrompt de l Owner, execute sans Mission.\n\n'
    [ "${G_NO_ORIGIN:-}" = 1 ] || printf '```prompt\n%s\n```\n\n' "$PROMPT"
    if [ "${G_NO_BLOCK:-}" != 1 ]; then
      printf '```owner_greenlight\n%s\n```\n\n' "${G_BLOCK-$GL_DEFAULT}"
      [ "${G_TWO:-}" = 1 ] && printf '```owner_greenlight\n%s\n```\n\n' "$GL_DEFAULT"
    fi
    printf '## Scope\n\n- rules/RULES-2026-09-20-012259-two-work-regimes.md\n\n'
    [ "${G_NO_BEFORE:-}" = 1 ] || printf '## Measure before\n\n```\ngrep -c greenlight rules/RULES-2026-09-20-012259-two-work-regimes.md\n```\n\n0.\n\n'
    printf '## Gesture\n\n```\n%s\n```\n\n' "${G_GESTURE:-printf 'line\\n' >> rules/RULES-2026-09-20-012259-two-work-regimes.md}"
    printf '## Measure after\n\n```\ngrep -c greenlight rules/RULES-2026-09-20-012259-two-work-regimes.md\n```\n\n0 -> 1.\n\n'
    printf '## Journal line\n\n```\nSTATE: regle 012259 -- feu vert cite (Note mode 2a)\n```\n'
  } > "$f"
}

run() { OUT="$(bash "$TOOL" note "$1" 2>"$TMP/err")"; RC=$?; LAST="$(printf '%s\n' "$OUT" | tail -n 1)"; }
expect_no() { run "$2"; case "$LAST" in REFUSED*"$3"*) pass "$1 -> $LAST";; *) fail "$1 : expected $3, read rc=$RC '$LAST'";; esac; }

P="$TMP/proj"
mkdir -p "$P/missions"

# --- (a) accepted with the greenlight ------------------------------------------------------
mknote "$P/missions/NOTE-2026-09-23-091000-a.md"
run "$P/missions/NOTE-2026-09-23-091000-a.md"
if [ "$RC" = 0 ] && [ "$LAST" = "REGIME-LIGHT-OK" ]; then
  pass "(a) Note 2a, R3-doctrine lifted by a verbatim, timed greenlight -> accepted"
else
  fail "(a) expected REGIME-LIGHT-OK, read rc=$RC '$LAST' [$(head -c 300 "$TMP/err" | tr '\n' ' ')]"
fi
printf '%s\n' "$OUT" | grep -q '^OWNER-GREENLIGHT R3-doctrine at 2026-09-23T09:12:40-04:00$' \
  && pass "(a) the tool says what the Owner lifted and when" \
  || fail "(a) no 'OWNER-GREENLIGHT R3-doctrine at <time>' line on stdout"

# --- (b) same Note without the block -------------------------------------------------------
G_NO_BLOCK=1 mknote "$P/missions/NOTE-2026-09-23-091000-b.md"
expect_no "(b) same Note without the greenlight" "$P/missions/NOTE-2026-09-23-091000-b.md" R3-doctrine
grep -q "ask the Owner" "$TMP/err" \
  && pass "(b) the refusal names the way out: ask the Owner" \
  || fail "(b) the refusal does not say to ask the Owner [$(head -c 300 "$TMP/err" | tr '\n' ' ')]"

# --- (c) empty answer ----------------------------------------------------------------------
G_BLOCK="at: 2026-09-23T09:12:40-04:00
lifts: R3-doctrine" mknote "$P/missions/NOTE-2026-09-23-091000-c.md"
expect_no "(c) greenlight block without the Owner's answer" "$P/missions/NOTE-2026-09-23-091000-c.md" R8-origin
G_BLOCK="" mknote "$P/missions/NOTE-2026-09-23-091000-c2.md"
expect_no "(c) empty greenlight block" "$P/missions/NOTE-2026-09-23-091000-c2.md" R8-origin

# --- (d) no time, time without offset -------------------------------------------------------
G_BLOCK="lifts: R3-doctrine
$ANSWER" mknote "$P/missions/NOTE-2026-09-23-091000-d.md"
expect_no "(d) greenlight block without at:" "$P/missions/NOTE-2026-09-23-091000-d.md" R8-origin
G_BLOCK="at: 2026-09-23 09:12
lifts: R3-doctrine
$ANSWER" mknote "$P/missions/NOTE-2026-09-23-091000-d2.md"
expect_no "(d) greenlight time without offset" "$P/missions/NOTE-2026-09-23-091000-d2.md" R8-origin

# --- (e) only the named criteria are lifted --------------------------------------------------
G_GESTURE="rm rules/RULES-2026-09-20-012259-two-work-regimes.md" mknote "$P/missions/NOTE-2026-09-23-091000-e.md"
expect_no "(e) R3-doctrine lifted, R2-destructive not" "$P/missions/NOTE-2026-09-23-091000-e.md" R2-destructive
case "$LAST" in *R3-doctrine*) fail "(e) R3-doctrine should have been lifted: '$LAST'";; *) pass "(e) R3-doctrine lifted, R2-destructive kept";; esac

# --- (f) a Pilot's Note -------------------------------------------------------------------------
G_NO_ORIGIN=1 mknote "$P/missions/NOTE-2026-09-23-091000-f.md"
expect_no "(f) greenlight in a Note without origin: owner-prompt" "$P/missions/NOTE-2026-09-23-091000-f.md" R8-origin

# --- (g) the form is never lifted -------------------------------------------------------------
G_NO_BEFORE=1 mknote "$P/missions/NOTE-2026-09-23-091000-g.md"
expect_no "(g) greenlight does not lift the form" "$P/missions/NOTE-2026-09-23-091000-g.md" R7-shape

# --- (h) two blocks -----------------------------------------------------------------------------
G_TWO=1 mknote "$P/missions/NOTE-2026-09-23-091000-h.md"
expect_no "(h) two greenlight blocks" "$P/missions/NOTE-2026-09-23-091000-h.md" R8-origin

# --- (i) the block is not counted in the cap --------------------------------------------------
LONG="$(head -c 4500 /dev/zero | tr '\0' 'o')"
G_BLOCK="at: 2026-09-23T09:12:40-04:00
lifts: R3-doctrine
$LONG" mknote "$P/missions/NOTE-2026-09-23-091000-i.md"
run "$P/missions/NOTE-2026-09-23-091000-i.md"
[ "$RC" = 0 ] && pass "(i) a 4500-character answer does not push the Note over the cap" \
  || fail "(i) long answer: rc=$RC '$LAST' [$(head -c 300 "$TMP/err" | tr '\n' ' ')]"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
