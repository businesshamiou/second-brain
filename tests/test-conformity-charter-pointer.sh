#!/usr/bin/env bash
# Mission 203, fix 5 (report 202, A5): tools/check-project-conformity.sh, section 6
# (pointer files). A link to the Vault's role charter names the Vault as well as a
# link to its CLAUDE.md / AGENTS.md does: it is accepted IN ADDITION to them, never in
# their place, and the folder it names is still checked against the birth certificate.
#
# Oracles (PASS expected):
#   (a) guides that carry only a link to the role charter: no pointer gap in the verdict;
#   (b) guides with no pointer at all: the gap is still named for CLAUDE.md and
#       AGENTS.md (refusal unchanged);
#   (c) a charter link to ANOTHER folder than the certificate's Vault: still refused
#       (`incoherent avec l'acte`);
#   (d) the historical form (`@<vault>/CLAUDE.md`) is still accepted;
#   (e) the old script (commit f34b405) names a pointer gap on (a): the defect
#       reproduced, when that history is available.
#
# Writes only in a temporary folder (prefix m203-pointer).
#
# usage: bash tests/test-conformity-charter-pointer.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- tools/project-bootstrap.sh en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m203-pointer-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
if ! sandbox_vault "$REPO_ROOT" "$V"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V/tools/write-marker.sh" "$WS" >/dev/null
P="$WS/projet"
mkdir -p "$P"
printf '# notes\n' > "$P/notes.md"
bash "$V/tools/project-bootstrap.sh" adopt "$P" "Projet" FR --vcs none >/dev/null 2>&1 </dev/null

CHARTER="rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
verdict() { bash "$V/tools/check-project-conformity.sh" "$P" 2>&1; }
set_guides() { printf '%s\n' "$1" > "$P/CLAUDE.md"; printf '%s\n' "$1" > "$P/AGENTS.md"; }

# --- (a) charter link only ------------------------------------------------------------------
set_guides "Before any action: determine your role. Read [the role charter](../second-brain/$CHARTER) in the Vault."
OUT="$(verdict)"
if printf '%s' "$OUT" | grep -q 'fichier de pointage'; then
  fail "(a) lien vers la charte : un ecart de pointeur est encore nomme : $OUT"
else
  pass "(a) lien vers la charte seul : plus d'ecart de pointeur"
fi

# --- (b) no pointer at all --------------------------------------------------------------------------
set_guides "Un guide sans aucun renvoi vers le Vault."
OUT="$(verdict)"
if printf '%s' "$OUT" | grep -q 'sans chemin vers le Vault (CLAUDE.md)' && printf '%s' "$OUT" | grep -q 'sans chemin vers le Vault (AGENTS.md)'; then
  pass "(b) aucun pointeur : l'ecart est nomme pour CLAUDE.md et AGENTS.md (refus inchange)"
else
  fail "(b) aucun pointeur : ecart non nomme : $OUT"
fi

# --- (c) a charter link to another folder ----------------------------------------------------------
set_guides "Read [the role charter](../autre-vault/$CHARTER) in the Vault."
OUT="$(verdict)"
if printf '%s' "$OUT" | grep -q 'incoh'; then
  pass "(c) lien vers la charte d'un AUTRE dossier : refuse (incoherent avec l'acte)"
else
  fail "(c) lien vers la charte d'un autre dossier accepte a tort : $OUT"
fi

# --- (d) the historical form ------------------------------------------------------------------------
set_guides "@../second-brain/CLAUDE.md"
OUT="$(verdict)"
if printf '%s' "$OUT" | grep -q 'fichier de pointage'; then
  fail "(d) forme historique refusee : $OUT"
else
  pass "(d) la forme historique (@<vault>/CLAUDE.md) reste acceptee"
fi

# --- (e) the old script ------------------------------------------------------------------------------
if git -C "$REPO_ROOT" cat-file -e 'f34b405^{commit}' 2>/dev/null; then
  git -C "$REPO_ROOT" show f34b405:tools/check-project-conformity.sh > "$V/tools/check-project-conformity-before.sh"
  set_guides "Before any action: determine your role. Read [the role charter](../second-brain/$CHARTER) in the Vault."
  OUT="$(bash "$V/tools/check-project-conformity-before.sh" "$P" 2>&1)"
  if printf '%s' "$OUT" | grep -q 'sans chemin vers le Vault'; then
    pass "(e) temoin rouge : l'ancien script nomme un ecart de pointeur sur le lien vers la charte"
  else
    fail "(e) temoin rouge : l'ancien script n'ecarte pas le lien vers la charte : $OUT"
  fi
else
  echo "  SKIP - (e) l'historique f34b405 est absent de ce clone : temoin rouge non joue"
fi

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
