#!/usr/bin/env bash
# Mission 218, lot 4 (Decision 012500): mode 2 -- a prompt of the Owner
# executed without a Mission -- is the light regime, traced by an execution
# Note written first. The Note carries its origin, the real time of reception,
# the prompt verbatim with its sha256 (2a) or each consumed file with its
# sha256 (2b), and its scope; the same guardians judge both modes.
#
#   (i)   a 2a Note (prompt verbatim + sha256 + received_at + scope) -> accepted;
#         the same Note with a prompt edited after the fingerprint -> R8-origin;
#   (ii)  a 2b Note with two files and their fingerprints -> accepted; one
#         fingerprint wrong -> R8-origin;
#   (iii) a mode-2 Note without scope -> refused, named;
#         a mode-2 Note without received_at -> R8-origin;
#   (iv)  the same forbidden content (a fake secret) committed beside a
#         Mission and beside a Note -> refused by the same guardian, same
#         message;
#   (v)   a journal line in each mode reaches the digest in the same form;
#   (vi)  a mode-2 Note in the Vault touching decisions/ or rules/ -> the full
#         regime is required (R3-doctrine), origin notwithstanding;
#   (vii) a long Owner prompt does not push a mode-2 Note over the cap: the
#         verbatim block is not counted; the rest of the Note still is;
#   (viii) the project guide rendered by project-bootstrap.sh names mode 2;
#         the mission-writing skill names mode 2 (door open-199).
# The checker under test is WORK_REGIME_TOOL=<file> (default: this repository's).
#
# usage: bash tests/test-work-regime-mode2.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="${WORK_REGIME_TOOL:-$REPO_ROOT/tools/check-work-regime.sh}"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m218-mode2-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else openssl dgst -sha256 | awk '{print $NF}'; fi
}

PROMPT="Lis ../docs/brief.md et mets a jour le compteur de pages dans docs/stats.md, sans rien pousser."
PROMPT_SHA="$(printf '%s' "$PROMPT" | sha)"

# mknote2 <file> : a mode-2 Note, each part overridable through the environment.
mknote2() {
  local f="$1"
  {
    printf -- '---\ntype: note\ntitle: "Compteur de pages"\ndescription: "d"\ncreated_at: "2026-09-23T01:40:00-04:00"\ntimezone: America/Montreal\nregime: light\nscope: page-counter\n'
    [ "${M_NO_ORIGIN:-}" = 1 ] || printf 'origin: %s\n' "${M_ORIGIN:-owner-prompt}"
    printf 'mode: %s\n' "${M_MODE:-2a}"
    [ "${M_NO_RECEIVED:-}" = 1 ] || printf 'received_at: "%s"\n' "${M_RECEIVED:-2026-09-23T01:39:12-04:00}"
    [ "${M_MODE:-2a}" = 2a ] && printf 'prompt_sha256: %s\n' "${M_SHA:-$PROMPT_SHA}"
    printf -- '---\n\n# NOTE — COMPTEUR DE PAGES\n\n## Intent\n\nPrompt de l Owner, execute sans Mission.\n\n'
    if [ "${M_MODE:-2a}" = 2a ]; then
      printf '```prompt\n%s\n```\n\n' "${M_PROMPT:-$PROMPT}"
    else
      printf '```files\n%s\n```\n\n' "$M_FILES"
    fi
    printf '## Scope\n\n%s\n\n' "${M_SCOPE-- docs/stats.md}"
    printf '## Measure before\n\n```\ngrep -c page docs/stats.md\n```\n\n3.\n\n'
    printf '## Gesture\n\n```\n%s\n```\n\n' "${M_GESTURE:-sed -i s/3/4/ docs/stats.md}"
    printf '## Measure after\n\n```\ngrep -c page docs/stats.md\n```\n\n3 -> 4.\n\n'
    printf '## Journal line\n\n```\nSTATE: compteur de pages 3 -> 4 (Note mode 2a)\n```\n'
  } > "$f"
}

run() { OUT="$(bash "$TOOL" note "$1" 2>"$TMP/err")"; RC=$?; LAST="$(printf '%s\n' "$OUT" | tail -n 1)"; }
expect_ok() { run "$2"; [ "$RC" = 0 ] && [ "$LAST" = "REGIME-LIGHT-OK" ] && pass "$1" || fail "$1 : rc=$RC last='$LAST' [$(head -c 300 "$TMP/err" | tr '\n' ' ')]"; }
expect_no() { run "$2"; case "$LAST" in REFUSED*"$3"*) pass "$1 -> $LAST";; *) fail "$1 : attendu $3, lu rc=$RC '$LAST'";; esac; }

P="$TMP/proj"
mkdir -p "$P/missions" "$P/docs"
printf 'brief\n' > "$P/docs/brief.md"
printf 'page page page\n' > "$P/docs/stats.md"

# --- (i) 2a -------------------------------------------------------------------------------
mknote2 "$P/missions/NOTE-2026-09-23-014000-a.md"
expect_ok "(i) Note 2a : prompt verbatim, sha256, received_at, perimetre -> acceptee" "$P/missions/NOTE-2026-09-23-014000-a.md"
M_PROMPT="$PROMPT et pousse." mknote2 "$P/missions/NOTE-2026-09-23-014000-b.md"
expect_no "(i) Note 2a, prompt modifie apres l'empreinte" "$P/missions/NOTE-2026-09-23-014000-b.md" R8-origin

# --- (ii) 2b ------------------------------------------------------------------------------
F1="$(sha < "$P/docs/brief.md")"; F2="$(sha < "$P/docs/stats.md")"
M_MODE=2b M_FILES="$F1 docs/brief.md
$F2 docs/stats.md" mknote2 "$P/missions/NOTE-2026-09-23-014000-c.md"
expect_ok "(ii) Note 2b, deux fichiers et leurs empreintes -> acceptee" "$P/missions/NOTE-2026-09-23-014000-c.md"
M_MODE=2b M_FILES="$F1 docs/brief.md
$F1 docs/stats.md" mknote2 "$P/missions/NOTE-2026-09-23-014000-d.md"
expect_no "(ii) Note 2b, une empreinte fausse" "$P/missions/NOTE-2026-09-23-014000-d.md" R8-origin

# --- (iii) no scope, no received_at ------------------------------------------------------------
M_SCOPE="" mknote2 "$P/missions/NOTE-2026-09-23-014000-e.md"
expect_no "(iii) Note mode 2 sans perimetre" "$P/missions/NOTE-2026-09-23-014000-e.md" R7-shape
grep -q "empty Scope" "$TMP/err" && pass "(iii) refus nomme : empty Scope" || fail "(iii) refus sans nom"
M_NO_RECEIVED=1 mknote2 "$P/missions/NOTE-2026-09-23-014000-f.md"
expect_no "(iii) Note mode 2 sans received_at" "$P/missions/NOTE-2026-09-23-014000-f.md" R8-origin
M_ORIGIN="friend" mknote2 "$P/missions/NOTE-2026-09-23-014000-g.md"
expect_no "(iii) Note d'origine inconnue" "$P/missions/NOTE-2026-09-23-014000-g.md" R8-origin

# --- (iv) the same guardian, the same message, under a Mission and under a Note --------------------
FAKE="ghp_""ABCDEFGHIJ0123456789ABCD"
secret_under() { # secret_under <label> <trace-file-name>
  local r="$TMP/iv-$1"
  mkdir -p "$r/missions"; git init -q "$r"
  printf -- '---\ntype: x\n---\n# trace\n' > "$r/missions/$2"
  printf 'token: %s\n' "$FAKE" > "$r/notes.md"
  (cd "$r" && git add -A >/dev/null 2>&1 && bash "$REPO_ROOT/tools/check-secrets.sh" >/dev/null 2>"$TMP/iv-$1.err"); echo $?
}
R1="$(secret_under mission MISSION-2026-09-23-014000-001-x.md)"
R2="$(secret_under note NOTE-2026-09-23-014000-x.md)"
if [ "$R1" != 0 ] && [ "$R2" != 0 ] && cmp -s "$TMP/iv-mission.err" "$TMP/iv-note.err"; then
  pass "(iv) faux secret : refuse sous Mission et sous Note, meme message (rc=$R1/$R2)"
else
  fail "(iv) faux secret : rc=$R1/$R2, messages identiques=$(cmp -s "$TMP/iv-mission.err" "$TMP/iv-note.err" && echo oui || echo non)"
fi

# --- (v) journal lines of both modes reach the digest the same way ----------------------------------
J="$TMP/jproj"
mkdir -p "$J/state"
printf '# second-brain-birth-certificate: v1\n# vault_id: sb-test-226\n# vcs: none\nrepos: []\n' > "$J/.pre-commit-config.yaml"  # Mission 226: repository-root guard
printf '# Journal\n\n## Liens\n\n' > "$J/state/journal.md"
bash "$REPO_ROOT/tools/append-journal.sh" "$J" "STATE: Mission 007 FINAL -- 3 fichiers" >/dev/null
bash "$REPO_ROOT/tools/append-journal.sh" "$J" "STATE: compteur de pages 3 -> 4 (Note mode 2a)" >/dev/null
bash "$REPO_ROOT/tools/build-digest.sh" "$J" >/dev/null 2>&1
if grep -Eq '^[0-9T:+-]+ STATE: Mission 007 FINAL' "$J/state/DIGEST.md" && grep -Eq '^[0-9T:+-]+ STATE: compteur de pages' "$J/state/DIGEST.md"; then
  pass "(v) ligne de journal : meme forme dans le digest pour les deux modes"
else
  fail "(v) lignes de journal absentes ou de forme differente dans le digest"
fi

# --- (vi) doctrine in the Vault stays with the full regime ----------------------------------------
M_SCOPE="- decisions/DECISION-2026-09-23-000000-x.md
- rules/RULES-2026-09-23-000000-y.md" mknote2 "$P/missions/NOTE-2026-09-23-014000-h.md"
expect_no "(vi) Note mode 2 touchant decisions/ et rules/" "$P/missions/NOTE-2026-09-23-014000-h.md" R3-doctrine

# --- (vii) a long prompt is not counted in the cap ------------------------------------------------------
LONG="$(head -c 5000 /dev/zero | tr '\0' 'p')"
LONG_SHA="$(printf '%s' "$LONG" | sha)"
M_PROMPT="$LONG" M_SHA="$LONG_SHA" mknote2 "$P/missions/NOTE-2026-09-23-014000-i.md"
expect_ok "(vii) prompt de 5000 caracteres : la Note reste sous le plafond" "$P/missions/NOTE-2026-09-23-014000-i.md"
M_NO_ORIGIN=1 M_MODE=2a mknote2 "$P/missions/NOTE-2026-09-23-014000-j.md"
{ printf '\n<!-- '; head -c 4100 /dev/zero | tr '\0' 'x'; printf ' -->\n'; } >> "$P/missions/NOTE-2026-09-23-014000-j.md"
expect_no "(vii) jumeau : le reste de la Note compte toujours" "$P/missions/NOTE-2026-09-23-014000-j.md" R7-shape

# --- (viii) the project guide and the skill name mode 2 ---------------------------------------------
for l in fr en es; do
  if grep -q '"projectBootstrap.guide.writing": "[^"]*(mode 2)' "$REPO_ROOT/i18n/catalog.$l.json"; then
    pass "(viii) catalog.$l.json : la consigne d'ecriture du projet nomme le mode 2"
  else
    fail "(viii) catalog.$l.json : la consigne d'ecriture ne nomme pas le mode 2"
  fi
done
grep -q "Mode 2" "$REPO_ROOT/skills/mission-writing/SKILL.md" \
  && pass "(viii) skill mission-writing : mode 2 cable (open-199)" \
  || fail "(viii) skill mission-writing : mode 2 absent"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
