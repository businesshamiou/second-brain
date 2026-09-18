#!/usr/bin/env bash
# T5 (Mission 186, step 4): README.md and INSTALL.md carry, in this
# order, the four steps of the path of a participant discovering the
# product -- install, the MCP server, open the Pilot, adopt an existing
# folder -- and the FAQ names the four lessons drawn from the human
# acceptance capture of Mission 184 (bash outside the PATH on Windows,
# reused temporary folder, two possible locations for
# claude_desktop_config.json, exclusivity of the MCP server
# `second-brain-vault`).
#
# Oracle: for each document, the four section headings are all
# found, at strictly increasing line numbers in the expected order;
# for the FAQ (carried by README.md), one keyword per theme is present,
# case-insensitive.
# Negative control: a throwaway copy of README.md, stripped of a section then
# of a FAQ entry, fails the same check.
#
# usage: bash tests/test-install-doc-participant-path.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FAILURES=0
pass() { echo "  PASS - $1"; }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

echo "=== T5 : parcours participant en quatre etapes, et FAQ des lecons d'acceptation ==="

# --- 1. Relative order of the four sections, per file ----------------------
#
# Entry format: "file|install pattern|MCP pattern|Pilot pattern|adopt pattern"
CHECKS=(
  "README.md|## Installation line|## The MCP server|## Open a project's Pilot|## Adopt an existing folder"
  "INSTALL.md|## 2. Installation line|## 4. The MCP server|## 5. Open the Pilot|## 6. Adopt an existing folder"
)

# section_order_ok <fichier> <motif1> <motif2> <motif3> <motif4>: 0 if the
# four patterns are each found once, at strictly increasing line
# numbers in this order.
section_order_ok() {
  local SOO_DOC="$1"; shift
  local SOO_PREV=0
  local SOO_MOTIF SOO_LINE
  [ -f "$SOO_DOC" ] || return 1
  for SOO_MOTIF in "$@"; do
    SOO_LINE="$(grep -nF -- "$SOO_MOTIF" "$SOO_DOC" | head -n 1 | cut -d: -f1)"
    [ -n "$SOO_LINE" ] || return 1
    [ "$SOO_LINE" -gt "$SOO_PREV" ] || return 1
    SOO_PREV="$SOO_LINE"
  done
  return 0
}

for ENTRY in "${CHECKS[@]}"; do
  IFS='|' read -r DOC M1 M2 M3 M4 <<< "$ENTRY"
  DOC_PATH="$REPO_ROOT/$DOC"
  if section_order_ok "$DOC_PATH" "$M1" "$M2" "$M3" "$M4"; then
    pass "$DOC : installer < serveur MCP < ouvrir le Pilot < adopter, dans cet ordre"
  else
    fail "$DOC : les quatre sections du parcours ne sont pas toutes presentes, dans cet ordre"
  fi
done

# --- 2. The FAQ names the four themes ---------------------------------------
#
# The FAQ lives in README.md, section "## Frequently asked questions" up to the next
# "## ". Entry format: "theme name|pattern1|pattern2"
FAQ_FILE="$REPO_ROOT/README.md"
FAQ_BLOCK="$(awk '/^## Frequently asked questions/{flag=1; next} /^## /{if (flag) exit} flag' "$FAQ_FILE" 2>/dev/null)"

FAQ_THEMES=(
  "bash hors PATH sous Windows|PATH|bash"
  "dossier temporaire reutilise|temporary|second-brain-install"
  "deux emplacements de claude_desktop_config.json|Packages|APPDATA"
  "exclusivite du serveur second-brain-vault|second-brain-vault|exclusiv"
)

faq_has_theme() {
  # $1 = FAQ block (text), $2 = pattern1, $3 = pattern2 -- both must
  # appear (not necessarily on the same line), case-insensitive.
  printf '%s\n' "$1" | grep -qi -- "$2" || return 1
  printf '%s\n' "$1" | grep -qi -- "$3" || return 1
  return 0
}

if [ -z "$FAQ_BLOCK" ]; then
  fail "README.md : section « Frequently asked questions » introuvable"
else
  for ENTRY in "${FAQ_THEMES[@]}"; do
    IFS='|' read -r NOM MOTIF1 MOTIF2 <<< "$ENTRY"
    if faq_has_theme "$FAQ_BLOCK" "$MOTIF1" "$MOTIF2"; then
      pass "FAQ README.md : theme « $NOM » present ($MOTIF1 + $MOTIF2)"
    else
      fail "FAQ README.md : theme « $NOM » absent ($MOTIF1 + $MOTIF2)"
    fi
  done
fi

# --- 3. Negative control: a truncated copy fails the same check ------------
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m186-doc-participant-path-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

# 3a. Copy stripped of the "The MCP server" section (and of everything that follows
# up to the next "## "): the order of the four sections must then fail.
WITNESS_SECTION="$TMP/README-no-mcp-section.md"
awk '
  /^## The MCP server/ { skip = 1; next }
  /^## / { if (skip) skip = 0 }
  !skip { print }
' "$FAQ_FILE" > "$WITNESS_SECTION"

if section_order_ok "$WITNESS_SECTION" "## Installation line" "## The MCP server" "## Open a project's Pilot" "## Adopt an existing folder"; then
  fail "temoin : une copie de README.md privee de « The MCP server » passe quand meme le controle d'ordre"
else
  pass "temoin : une copie de README.md privee de « The MCP server » echoue au controle d'ordre"
fi

# 3b. Copy stripped of the FAQ entry on the exclusivity of the MCP server: the
# matching theme must then fail, the three others must hold.
WITNESS_FAQ="$TMP/README-no-faq-entry.md"
grep -v "second-brain-vault" "$FAQ_FILE" > "$WITNESS_FAQ"
WITNESS_FAQ_BLOCK="$(awk '/^## Frequently asked questions/{flag=1; next} /^## /{if (flag) exit} flag' "$WITNESS_FAQ" 2>/dev/null)"

if faq_has_theme "$WITNESS_FAQ_BLOCK" "second-brain-vault" "exclusiv"; then
  fail "temoin : une copie de README.md privee des mentions « second-brain-vault » passe quand meme le controle FAQ"
else
  pass "temoin : une copie de README.md privee des mentions « second-brain-vault » echoue au controle FAQ"
fi
# The three other themes, for their part, must remain detected in this same
# truncated copy -- proof that the FAQ check indeed targets the removed theme,
# not the whole block.
OTHER_THEMES_OK=1
for ENTRY in "bash hors PATH sous Windows|PATH|bash" "dossier temporaire reutilise|temporary|second-brain-install" "deux emplacements de claude_desktop_config.json|Packages|APPDATA"; do
  IFS='|' read -r NOM MOTIF1 MOTIF2 <<< "$ENTRY"
  faq_has_theme "$WITNESS_FAQ_BLOCK" "$MOTIF1" "$MOTIF2" || OTHER_THEMES_OK=0
done
if [ "$OTHER_THEMES_OK" = "1" ]; then
  pass "temoin : les trois autres themes FAQ restent detectes dans cette meme copie amputee"
else
  fail "temoin : le retrait cible a fait disparaitre plus que le theme vise"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
