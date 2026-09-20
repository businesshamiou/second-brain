#!/usr/bin/env bash
# Mission 203, fix 1 (report 202, A8): the birth certificate carries an optional
# `# exempt: <path/> <path/>` key, read by ONE function (bc_exempt in
# tools/resolve-vault.sh, Python twin in tools/project_baseline.py) and applied
# by three guardians and by no other: check-links.sh, check_indexes_fresh.py,
# check_index_weight.py. The secrets check never reads it.
#
# Oracles (PASS expected):
#   (a) with the key, a Markdown file without `## Liens` under an exempt path,
#       and an over-weight index under it, pass the three guardians;
#   (b) the same commit without the key is refused by all three (twin);
#   (c) a file OUTSIDE the exempt paths is still judged (links refuse it);
#   (d) a secret under an exempt path is STILL refused by check-secrets;
#   (e) grammar: an absolute, `..`, backslash, colon or slash-less token exempts
#       nothing and is named on stderr; the shell and Python readers agree;
#   (f) `pre-commit validate-config` does not warn about the key (a comment,
#       not a YAML key: Mission 184 measurement);
#   (g) the old tools (commit f34b405) refuse (a) even with the key present:
#       the defect reproduced, when that history is available.
#
# Writes only in a temporary folder (prefix m203-exempt).
#
# usage: bash tests/test-exempt-paths-key.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- les gardiens Python en dependent"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m203-exempt-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

# A project with a certificate; $2 = the `# exempt:` line (empty: no key).
make_project() {
  local dir="$1" exempt="$2"
  mkdir -p "$dir"
  (
    cd "$dir" || exit 1
    git init -q -b main 2>/dev/null || git init -q
    git config user.email t@example.invalid
    git config user.name t
    git config core.autocrlf false
    {
      echo "# second-brain-birth-certificate: v1"
      echo "# vault_id: sb-test-203"
      echo "# vault_origin: https://example.invalid/vault.git"
      echo "# vcs: git"
      [ -n "$exempt" ] && echo "# exempt: $exempt"
      echo "repos: []"
    } > .pre-commit-config.yaml
    printf '# Projet\n\n## Liens\n\n- `see also` — [Projet](README.md)\n' > README.md
    printf -- '---\ntype: index\nstatus: active\n---\n# Index\n\n## Contenu\n\n- `README` · inconnu · (sans titre) · `README.md`\n\n## Liens\n\n- `see also` — [Projet](README.md)\n' > index.md
    git add -A && git commit -q -m init
  )
}

# Stages, under <prefix>, a third-party skill (no `## Liens`) and an over-weight index.
stage_third_party() {
  local dir="$1" prefix="$2" i
  (
    cd "$dir" || exit 1
    mkdir -p "${prefix}web/skills/tiers"
    printf -- '---\nname: tiers\ndescription: skill de tiers sans Liens\n---\n# tiers\n' > "${prefix}web/skills/tiers/SKILL.md"
    {
      printf -- '---\ntype: index\nstatus: active\n---\n# Index\n\n## Contenu\n\n'
      i=1; while [ "$i" -le 120 ]; do
        printf -- '- `id%d` · x · (sans titre) · `fichier-numero-%d-avec-un-nom-assez-long-pour-peser.md`\n' "$i" "$i"; i=$((i + 1))
      done
      printf '\n## Liens\n\n- `see also` — [Projet](../README.md)\n'
    } > "${prefix}index.md"
    git add -- "$prefix"
  )
}

# run_guardians <tools dir> <project> -> "L I W" exit codes of links, freshness, weight.
run_guardians() {
  local tools="$1" dir="$2" l i w
  (cd "$dir" && bash "$tools/check-links.sh" >/dev/null 2>&1); l=$?
  (cd "$dir" && bash "$tools/check-indexes-fresh.sh" >/dev/null 2>&1); i=$?
  (cd "$dir" && bash "$tools/check-index-weight.sh" >/dev/null 2>&1); w=$?
  echo "$l $i $w"
}

TOOLS="$REPO_ROOT/tools"

# --- (a) with the key --------------------------------------------------------
P="$TMP/with-key"
make_project "$P" "skill-collections/ deliverables/"
stage_third_party "$P" "skill-collections/"
R="$(run_guardians "$TOOLS" "$P")"
[ "$R" = "0 0 0" ] && pass "(a) avec la cle : liens, fraicheur, poids PASS sous skill-collections/ ($R)" \
  || fail "(a) avec la cle : verdicts $R (attendu 0 0 0)"

# --- (b) twin: the same commit without the key ---------------------------------
P="$TMP/no-key"
make_project "$P" ""
stage_third_party "$P" "skill-collections/"
R="$(run_guardians "$TOOLS" "$P")"
[ "$R" = "1 1 1" ] && pass "(b) temoin : sans la cle, les trois gardiens refusent ($R)" \
  || fail "(b) temoin : sans la cle, verdicts $R (attendu 1 1 1)"

# --- (c) outside the exempt paths, still judged --------------------------------
P="$TMP/outside"
make_project "$P" "skill-collections/"
(cd "$P" && printf -- '---\ntype: note\nstatus: active\n---\n# note sans Liens\n' > NOTE.md && git add NOTE.md)
(cd "$P" && bash "$TOOLS/check-links.sh" >/dev/null 2>&1); rc=$?
[ "$rc" = "1" ] && pass "(c) un .md hors des chemins exemptes reste juge (check-links exit 1)" \
  || fail "(c) un .md hors chemin exempte : check-links exit $rc (attendu 1)"

# --- (d) the secrets check never reads the key -----------------------------------
P="$TMP/secret"
make_project "$P" "skill-collections/"
# Built from two pieces: this file must not match the pattern itself.
FAKE="AKIA""ABCDEFGHIJKLMNOP"
(cd "$P" && mkdir -p skill-collections/web && printf 'valeur factice : %s\n' "$FAKE" > skill-collections/web/example.txt && git add skill-collections)
(cd "$P" && bash "$TOOLS/check-secrets.sh" >/dev/null 2>&1); rc=$?
[ "$rc" = "1" ] && pass "(d) un secret sous un chemin exempte est refuse (check-secrets exit 1)" \
  || fail "(d) secret sous chemin exempte : check-secrets exit $rc (attendu 1)"
if grep -qE 'bc_exempt|parse_exempt|Exempt[(]|# exempt:'"$TOOLS/check-secrets.sh" "$TOOLS/check-private-patterns.sh"; then
  fail "(d) check-secrets.sh ou check-private-patterns.sh mentionne la cle d'exemption"
else
  pass "(d) ni check-secrets.sh ni check-private-patterns.sh ne lisent la cle"
fi

# --- (e) grammar: bad tokens exempt nothing, both readers agree ------------------
BAD="/abs ../up back\\slash c:drive noslash ok/ deeper/ok/"
P="$TMP/grammar"
make_project "$P" "$BAD"
SH="$(cd "$TMP" && . "$TOOLS/resolve-vault.sh" && bc_exempt "$P" 2>"$TMP/sh.err" | tr '\n' ' ')"
PY="$(uv run --no-project python -c "
import sys
sys.path.insert(0, sys.argv[1])
import project_baseline as pb
valid, rejected = pb.parse_exempt(sys.argv[2])
print(' '.join(valid), end='')
" "$TOOLS" "$BAD" 2>/dev/null)"
[ "$SH" = "ok/ deeper/ok/ " ] && pass "(e) lecture shell : seuls 'ok/' et 'deeper/ok/' sont retenus" \
  || fail "(e) lecture shell : '$SH'"
[ "$PY" = "ok/ deeper/ok/" ] && pass "(e) lecture Python : meme liste" \
  || fail "(e) lecture Python : '$PY'"
NBAD="$(grep -c 'entree ignoree' "$TMP/sh.err")"
[ "$NBAD" = "5" ] && pass "(e) les cinq jetons invalides sont nommes sur stderr" \
  || fail "(e) jetons invalides nommes : $NBAD (attendu 5)"
stage_third_party "$P" "noslash/"
(cd "$P" && bash "$TOOLS/check-links.sh" >/dev/null 2>&1); rc=$?
[ "$rc" = "1" ] && pass "(e) un chemin sans '/' final n'exempte rien (check-links exit 1)" \
  || fail "(e) chemin sans '/' final : check-links exit $rc (attendu 1)"

# --- (f) pre-commit validate-config says nothing about the key ------------------
if command -v pre-commit >/dev/null 2>&1; then
  P="$TMP/validate"
  make_project "$P" "skill-collections/ deliverables/"
  OUT="$(cd "$P" && pre-commit validate-config .pre-commit-config.yaml 2>&1)"; rc=$?
  if [ "$rc" = "0" ] && [ -z "$OUT" ]; then
    pass "(f) pre-commit validate-config : rc 0, aucune sortie (la cle est un commentaire)"
  else
    fail "(f) pre-commit validate-config : rc $rc, sortie '$OUT'"
  fi
else
  echo "  SKIP - (f) pre-commit absent"
fi

# --- (g) the old tools: the defect reproduced ---------------------------------------
if sandbox_before_203 "$TMP/before"; then
  P="$TMP/old"
  make_project "$P" "skill-collections/ deliverables/"
  stage_third_party "$P" "skill-collections/"
  R="$(run_guardians "$TMP/before/tools" "$P")"
  [ "$R" = "1 1 1" ] && pass "(g) temoin rouge : les outils d'avant la 203 refusent malgre la cle ($R)" \
    || fail "(g) temoin rouge : outils d'avant la 203 : $R (attendu 1 1 1)"
else
  echo "  SKIP - (g) l'historique f34b405 est absent de ce clone : temoin rouge non joue"
fi

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
