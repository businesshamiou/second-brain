#!/usr/bin/env bash
# Mission 203, fix 4 (report 202, A3): `tools/write-marker.sh --marker-only <root>`
# writes VAULT-ROOT.md and nothing else. Without the option the script also
# writes the workspace-level CLAUDE.md and AGENTS.md at <root> -- right for a
# workspace root, wrong for a project root, whose own guides it overwrote.
#
# Oracles (PASS expected):
#   (a) --marker-only on a project root: CLAUDE.md and AGENTS.md keep their bytes,
#       VAULT-ROOT.md is written with the relative path to the Vault;
#   (b) the default call (no option) still writes the marker AND both guides, the two
#       guides identical to each other -- and byte for byte what the old script
#       writes (the folder names of the two Vault-shaped test folders and the
#       generated Vault identity, which differ by construction, are normalised);
#   (c) the marker written with the option equals the marker written without it;
#   (d) usage: the option alone (no root) is refused, exit 1;
#   (e) the old script (commit f34b405) overwrites the guides -- the defect
#       reproduced, when that history is available.
#
# Writes only in a temporary folder (prefix m203-marker).
#
# usage: bash tests/test-write-marker-only.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m203-marker-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

# Two Vault-shaped folders of the same depth and the same name length: the NEW tools
# (working tree) and the OLD ones (commit f34b405). Each carries the one template
# the script reads.
mkdir -p "$TMP/vnew/templates"
cp -r "$REPO_ROOT/tools" "$TMP/vnew/tools"
cp "$REPO_ROOT/templates/vault-root-template.md" "$TMP/vnew/templates/"
HAVE_OLD=0
sandbox_before_203 "$TMP/vold" && HAVE_OLD=1

sum() { cksum < "$1"; }

guides() {
  mkdir -p "$1"
  printf '# Guide propre au projet\n\nNe pas ecraser.\n' > "$1/CLAUDE.md"
  cp "$1/CLAUDE.md" "$1/AGENTS.md"
}

# --- (a) --marker-only on a project root -------------------------------------------------
P="$TMP/ws-a/projet"; guides "$P"
H1="$(sum "$P/CLAUDE.md")"; H2="$(sum "$P/AGENTS.md")"
bash "$TMP/vnew/tools/write-marker.sh" --marker-only "$P" >/dev/null 2>&1; RC=$?
if [ "$RC" = "0" ] && [ "$(sum "$P/CLAUDE.md")" = "$H1" ] && [ "$(sum "$P/AGENTS.md")" = "$H2" ] \
   && grep -q 'Chemin relatif du Vault depuis cette racine de travail : `' "$P/VAULT-ROOT.md"; then
  pass "(a) --marker-only : CLAUDE.md et AGENTS.md intacts (octets), VAULT-ROOT.md ecrit"
else
  fail "(a) --marker-only : rc $RC, guides intacts=$([ "$(sum "$P/CLAUDE.md")" = "$H1" ] && echo oui || echo NON), marqueur=$([ -f "$P/VAULT-ROOT.md" ] && echo oui || echo non)"
fi
MARK_ONLY="$(cat "$P/VAULT-ROOT.md")"

# --- (b), (c) the default call, unchanged ----------------------------------------------------
P="$TMP/ws-b/projet"; guides "$P"
bash "$TMP/vnew/tools/write-marker.sh" "$P" >/dev/null 2>&1; RC=$?
if [ "$RC" = "0" ] && [ -f "$P/VAULT-ROOT.md" ] && [ "$(sum "$P/CLAUDE.md")" = "$(sum "$P/AGENTS.md")" ] \
   && grep -q 'session-start/SKILL.md' "$P/CLAUDE.md"; then
  pass "(b) appel par defaut : marqueur et les deux guides ecrits, guides identiques entre eux"
else
  fail "(b) appel par defaut : rc $RC, guides non ecrits ou differents"
fi
[ "$(cat "$P/VAULT-ROOT.md")" = "$MARK_ONLY" ] && pass "(c) le marqueur avec l'option = le marqueur sans l'option" \
  || fail "(c) le marqueur differe selon l'option"
if [ "$HAVE_OLD" = "1" ]; then
  Q="$TMP/ws-b-old/projet"; guides "$Q"
  bash "$TMP/vold/tools/write-marker.sh" "$Q" >/dev/null 2>&1
  norm() { sed -e 's/vold/vnew/g' -e '/Identit/d' -e '/Origine du Vault/d' "$1"; }
  same=1
  for f in CLAUDE.md AGENTS.md VAULT-ROOT.md; do
    [ "$(norm "$Q/$f" | cksum)" = "$(norm "$P/$f" | cksum)" ] || same=0
  done
  [ "$same" = "1" ] && pass "(b) appel par defaut : sortie identique a celle de l'ancien script (marqueur et guides)" \
    || fail "(b) appel par defaut : la sortie differe de celle de l'ancien script"
fi

# --- (d) usage -----------------------------------------------------------------------------------
bash "$TMP/vnew/tools/write-marker.sh" --marker-only >/dev/null 2>&1; RC=$?
[ "$RC" = "1" ] && pass "(d) l'option sans racine : refus, exit 1" || fail "(d) l'option sans racine : exit $RC (attendu 1)"

# --- (e) the old script, the defect reproduced ------------------------------------------------------
if [ "$HAVE_OLD" = "1" ]; then
  P="$TMP/ws-e/projet"; guides "$P"
  H1="$(sum "$P/CLAUDE.md")"
  bash "$TMP/vold/tools/write-marker.sh" "$P" >/dev/null 2>&1
  if [ "$(sum "$P/CLAUDE.md")" != "$H1" ] && [ "$(sum "$P/AGENTS.md")" != "$H1" ]; then
    pass "(e) temoin rouge : l'ancien script ecrase CLAUDE.md et AGENTS.md du projet"
  else
    fail "(e) temoin rouge : l'ancien script n'ecrase pas les guides"
  fi
else
  echo "  SKIP - (e) l'historique f34b405 est absent de ce clone : temoin rouge non joue"
fi

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
