#!/usr/bin/env bash
# Mission 218, lot 2 (Decision 012458): a project's state sheet has one name,
# is generated, and exists from its birth.
#
#   (a) adopt (vcs: none) on a throwaway folder -> state/journal.md with a
#       birth entry, state/STATE.md and state/DIGEST.md generated, the Pilot
#       prompt carries `state_path` and that file exists;
#   (b) create (vcs: git) -> the same;
#   (c) build-state.sh and build-digest.sh on a project with no Git (a birth
#       certificate, vcs: none -- Mission 226: a folder with neither is refused
#       by the repository-root guard), no missions/, no handoffs/ -> both rc=0,
#       the repository line says "non mesurable";
#   (d) door open-194: a register whose last row is `194-C01` FINAL, after
#       `194` PARTIEL -> the digest's last Mission is 194-C01 FINAL;
#   (e) a Note (NOTE-*.md in missions/, a STATE: journal line) never enters
#       the digest's last Mission line;
#   (f) a STATE.md written by hand is never overwritten: STATE-NOT-GENERATED,
#       content intact; DIGEST.md the same (DIGEST-NOT-GENERATED); twin: a
#       generated sheet is regenerated; `--replace-hand-written` replaces a
#       hand-written sheet only when Git holds its content unchanged;
#   (g) the digest carries the seven-line Pilot contract at its head;
#   (h) `project-bootstrap.sh prompt <dir> --state-path <rel>` writes the
#       field; a path that does not exist is refused, the prompt unchanged.
#
# usage: bash tests/test-state-sheet-at-birth.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() { local n="$1"; shift; if "$@"; then pass "$n"; else fail "$n"; fi; }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- tools/project-bootstrap.sh en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m218-state-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/bin/pre-commit"
chmod +x "$TMP/bin/pre-commit"
PATH="$TMP/bin:$PATH"; export PATH

WS="$TMP/ws"; V="$WS/second-brain"
mkdir -p "$WS"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" --marker-only "$WS" >/dev/null || { echo "FAIL : marqueur"; exit 1; }
BOOT="$V/tools/project-bootstrap.sh"

gen_by() { tr -d '\r' < "$1" | sed -n '2,12p' | grep -q "^generated_by: .*$2\$"; }
field() { tr -d '\r' < "$1" | sed -n "s/^$2: \"\{0,1\}\([^\"]*\)\"\{0,1\}\$/\1/p" | head -n 1; }
contract_in() { tr -d '\r' < "$1" | grep -q '^1\. No file is deposited' && tr -d '\r' < "$1" | grep -q '^7\. End each turn'; }

birth_ok() { # birth_ok <project>
  local p="$1" sp
  [ -f "$p/state/journal.md" ] || return 1
  grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[^ ]+ STATE: ' "$p/state/journal.md" || return 1
  gen_by "$p/state/STATE.md" build-state.sh || return 1
  gen_by "$p/state/DIGEST.md" build-digest.sh || return 1
  sp="$(field "$p/state/PILOT-PROMPT.md" state_path)"
  [ -n "$sp" ] && [ -f "$p/$sp" ]
}

# --- (a) adopt ------------------------------------------------------------------------
P="$WS/adopted"
mkdir -p "$P/docs"; printf '# Notes\n' > "$P/docs/notes.md"
bash "$BOOT" adopt "$P" "Adopted" --vcs none --lang FR >"$TMP/a.out" 2>&1
check "(a) adopt : journal de naissance, STATE et DIGEST generes, state_path du PILOT-PROMPT existant" birth_ok "$P"

# --- (b) create -----------------------------------------------------------------------
P="$WS/created"
bash "$BOOT" create "$P" "Created" --vcs git --lang FR >"$TMP/b.out" 2>&1
check "(b) create : journal de naissance, STATE et DIGEST generes, state_path du PILOT-PROMPT existant" birth_ok "$P"

# --- (c) no Git, no atelier -----------------------------------------------------------
P="$TMP/bare"
mkdir -p "$P/state"
printf '# second-brain-birth-certificate: v1\n# vault_id: sb-test-226\n# vcs: none\nrepos: []\n' > "$P/.pre-commit-config.yaml"
printf '# Journal\n\n## Liens\n\n2026-09-23T01:00:00-04:00 STATE: bare project\n' > "$P/state/journal.md"
bash "$V/tools/build-state.sh" "$P" >"$TMP/c1" 2>&1; R1=$?
bash "$V/tools/build-digest.sh" "$P" >"$TMP/c2" 2>&1; R2=$?
check "(c) sans Git ni atelier : build-state rc=$R1, build-digest rc=$R2, 'non mesurable'" \
  sh -c "[ $R1 = 0 ] && [ $R2 = 0 ] && grep -q 'non mesurable' '$P/state/STATE.md' && grep -q 'non mesurable' '$P/state/DIGEST.md'"

# --- (d) door open-194 ------------------------------------------------------------------
mkdir -p "$P/missions"
cat > "$P/missions/MISSION-INDEX.md" <<'EOF'
# Registre

| ID | Statut | Date | Rapport |
|---|---|---|---|
| `193` | `FINAL` | 2026-09-19 | r193.md |
| `194` | `PARTIEL` | 2026-09-19 | r194.md |
| `194-C01` | `FINAL` | 2026-09-19 | r194c.md |
EOF
bash "$V/tools/build-digest.sh" "$P" >/dev/null 2>&1
check "(d) open-194 : derniere Mission = 194-C01 FINAL" grep -q "^Mission 194-C01 — FINAL" "$P/state/DIGEST.md"

# --- (e) a Note never enters the last Mission line ----------------------------------------
printf -- '---\ntype: note\nregime: light\n---\n# NOTE\n' > "$P/missions/NOTE-2026-09-23-010000-x.md"
bash "$V/tools/append-journal.sh" "$P" "STATE: Note x executee, 3 fichiers" >/dev/null
bash "$V/tools/build-digest.sh" "$P" >/dev/null 2>&1
check "(e) une Note n'entre pas dans la derniere Mission" sh -c "grep -q '^Mission 194-C01 — FINAL' '$P/state/DIGEST.md' && ! grep -q 'NOTE-2026' '$P/state/DIGEST.md'"

# --- (f) never overwrite a sheet that was not generated -------------------------------------
H="$TMP/hand"
mkdir -p "$H/state"
printf '# second-brain-birth-certificate: v1\n# vault_id: sb-test-226\n# vcs: none\nrepos: []\n' > "$H/.pre-commit-config.yaml"
printf '# Journal\n\n2026-09-23T01:00:00-04:00 STATE: hand\n' > "$H/state/journal.md"
printf -- '---\ntype: current-state\n---\n# ecrit a la main\n' > "$H/state/STATE.md"
printf -- '---\ntype: digest\n---\n# ecrit a la main\n' > "$H/state/DIGEST.md"
S0="$(cksum < "$H/state/STATE.md")"; D0="$(cksum < "$H/state/DIGEST.md")"
bash "$V/tools/build-state.sh" "$H" >"$TMP/f1" 2>&1; RS=$?
bash "$V/tools/build-digest.sh" "$H" >"$TMP/f2" 2>&1; RD=$?
check "(f) STATE.md manuscrit : refus STATE-NOT-GENERATED, contenu intact" \
  sh -c "[ $RS != 0 ] && grep -q 'STATE-NOT-GENERATED' '$TMP/f1' && [ \"\$(cksum < '$H/state/STATE.md')\" = '$S0' ]"
check "(f) DIGEST.md manuscrit : refus DIGEST-NOT-GENERATED, contenu intact" \
  sh -c "[ $RD != 0 ] && grep -q 'DIGEST-NOT-GENERATED' '$TMP/f2' && [ \"\$(cksum < '$H/state/DIGEST.md')\" = '$D0' ]"
bash "$V/tools/build-state.sh" --replace-hand-written "$H" >"$TMP/f3" 2>&1; RR=$?
check "(f) --replace-hand-written hors Git : refuse (contenu non garanti), intact" \
  sh -c "[ $RR != 0 ] && [ \"\$(cksum < '$H/state/STATE.md')\" = '$S0' ]"
git -C "$H" init -q; git -C "$H" -c user.name=t -c user.email=t@example.invalid add state/STATE.md
git -C "$H" -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false commit -q -m hand
bash "$V/tools/build-state.sh" --replace-hand-written "$H" >"$TMP/f4" 2>&1; RR=$?
check "(f) --replace-hand-written, contenu tenu par Git : remplace, genere, blob cite" \
  sh -c "[ $RR = 0 ] && grep -q '^generated_by: .*build-state.sh' '$H/state/STATE.md' && grep -q 'HAND-WRITTEN-REPLACED' '$TMP/f4'"
bash "$V/tools/build-state.sh" "$H" >/dev/null 2>&1; RG=$?
check "(f) jumeau : une fiche generee est regeneree (rc=$RG)" [ "$RG" = "0" ]

# --- (g) the digest carries the contract -----------------------------------------------------
check "(g) le digest porte le contrat Pilot de sept lignes" contract_in "$WS/adopted/state/DIGEST.md"

# --- (h) prompt --state-path ---------------------------------------------------------------------
P="$WS/adopted"
mkdir -p "$P/sub/state"; printf 'x\n' > "$P/sub/state/STATE.md"
bash "$BOOT" prompt "$P" --state-path sub/state/STATE.md >"$TMP/h1" 2>&1; RH=$?
check "(h) prompt --state-path : champ ecrit (rc=$RH)" sh -c "[ $RH = 0 ] && [ \"\$(tr -d '\r' < '$P/state/PILOT-PROMPT.md' | sed -n 's/^state_path: \"\\(.*\\)\"\$/\\1/p')\" = 'sub/state/STATE.md' ]"
PP0="$(cksum < "$P/state/PILOT-PROMPT.md")"
bash "$BOOT" prompt "$P" --state-path nowhere/STATE.md >"$TMP/h2" 2>&1; RH=$?
check "(h) chemin absent : refuse, prompt inchange" sh -c "[ $RH != 0 ] && [ \"\$(cksum < '$P/state/PILOT-PROMPT.md')\" = '$PP0' ]"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
