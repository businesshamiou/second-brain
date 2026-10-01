#!/usr/bin/env bash
# Mission 244 (capture 121525, findings 25, 26, 32, 34): a project born or
# adopted by an explicit call of tools/project-bootstrap.sh is committed by the
# tool itself, never left for an agent to decide.
#
# Oracle, on a throwaway workspace built from the working tree (a pre-commit
# stand-in: the guardians are not the subject; a refusing hook is):
#   (1) `sb new --order` (create, Git): two commits -- the project's scaffold
#       and the Vault's registration --, porcelain 0 in both repositories;
#   (2) the order's « Objet » is the purpose line of CLAUDE.md and AGENTS.md,
#       never « à compléter »;
#   (3) the output proposes no ChatGPT as a Pilot host, and the block reaches
#       the clipboard (SB_CLIPBOARD_FILE) byte for byte as printed;
#   (4) `adopt` of a Git folder carrying its own uncommitted file commits ONLY
#       what the tool added: the project's own file stays untracked;
#   (5) a refusing project hook: exit 1, the refusal said, nothing worked around
#       (the files stay written, uncommitted);
#   (6) the installers' historical call (no subcommand) commits nothing itself.
#
# usage: bash tests/test-project-bootstrap-commits.sh [<source repo>]
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$REPO_ROOT}"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi; }

sandbox_find_uv || { echo "FAIL : uv introuvable"; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m244-commits-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
WS="$TMP/ws"
V="$WS/vault"
mkdir -p "$WS" "$TMP/bin"
sandbox_vault "$SRC" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" "$WS" >/dev/null 2>&1 || { echo "FAIL : marqueur"; exit 1; }
# pre-commit stand-in: `install` lays a hook that accepts, or refuses when
# $TMP/refuse exists -- never the real guardians, never the network.
cat > "$TMP/bin/pre-commit" <<STUB
#!/usr/bin/env bash
[ "\$1" = install ] || exit 0
h="\$(git rev-parse --git-path hooks)"
mkdir -p "\$h"
printf '#!/usr/bin/env bash\nif [ -e "%s/refuse" ]; then echo "stub guardian: refused"; exit 1; fi\nexit 0\n' "$TMP" > "\$h/pre-commit"
chmod +x "\$h/pre-commit"
STUB
chmod +x "$TMP/bin/pre-commit"
export PATH="$TMP/bin:$PATH"
export SB_LANG=fr
export SB_CLIPBOARD_FILE="$TMP/clipboard.txt"
SB="$V/tools/sb/bin/sb"
BOOT="$V/tools/project-bootstrap.sh"
VID="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"
VREF="$(git -C "$V" rev-parse HEAD)"

write_order() { # write_order <file> <type> <name> <git> [extra line]
  {
    echo "Session Executor — initiation ($3)"
    echo ""
    echo "Ordre d'initiation"
    echo "- Type : $2"
    echo "- Mode : answered"
    echo "- Nom : $3"
    echo "- Emplacement : $WS"
    echo "- Vault + construction : vault_id=$VID, vault_origin=$V, vault_ref=$VREF"
    echo "- Git : $4"
    echo "- Objet : suivre les rapports clients de la semaine"
    [ -n "${5:-}" ] && echo "$5"
    echo "- Autorisation Owner datée : oui, je veux ce projet, 2026-09-30"
  } > "$1"
}
porcelain() { git -C "$1" status --porcelain | grep -c . ; }

echo "=== Mission 244 : commits de l'amorçage ($SRC) ==="

# --- (1)-(3) create by order ---------------------------------------------------
write_order "$TMP/o1.md" create rapports git
V_BEFORE="$(git -C "$V" rev-list --count HEAD)"
OUT="$(cd "$WS" && "$SB" new --order "$TMP/o1.md" 2>&1)"; RC=$?
P="$WS/rapports"
check "(1) sb new --order : exit 0" test "$RC" = 0
check "(1) projet : un commit, porcelain 0" sh -c "[ \"\$(git -C '$P' rev-list --count HEAD)\" = 1 ] && [ \"\$(git -C '$P' status --porcelain | grep -c .)\" = 0 ]"
check "(1) Vault : un commit de plus, porcelain 0" sh -c "[ \"\$(git -C '$V' rev-list --count HEAD)\" = $((V_BEFORE + 1)) ] && [ \"\$(git -C '$V' status --porcelain | grep -c .)\" = 0 ]"
check "(1) le commit du Vault porte le registre et la fiche" sh -c "git -C '$V' show --name-only --format= HEAD | grep -q 'projects/PROJECT-REGISTRY.md' && git -C '$V' show --name-only --format= HEAD | grep -q 'projects/PROJECT-.*RAPPORTS'"
check "(1) la sortie dit les deux commits" sh -c "[ \"\$(printf '%s\n' \"\$1\" | grep -c 'Commit fait par l.outil')\" = 2 ]" _ "$OUT"
check "(2) CLAUDE.md et AGENTS.md portent l'objet de l'ordre" sh -c "grep -qx 'But : suivre les rapports clients de la semaine' '$P/CLAUDE.md' && grep -qx 'But : suivre les rapports clients de la semaine' '$P/AGENTS.md'"
check "(2) plus de « à compléter »" sh -c "! grep -q 'à compléter' '$P/CLAUDE.md'"
check "(3) aucun ChatGPT proposé comme hôte du Pilot" sh -c "! printf '%s' \"\$1\" | grep -qi 'chatgpt'" _ "$OUT"
check "(3) consigne par lieu : « Dans l'application Claude »" sh -c "printf '%s' \"\$1\" | grep -q \"Dans l'application Claude\"" _ "$OUT"
check "(3) le bloc est au presse-papiers, identique au bloc imprime" sh -c "
  printf '%s\n' \"\$1\" | tr -d '\r' | awk 'f && /^  ---\$/ { exit } f { print } /^  ---\$/ { f = 1 }' > '$TMP/printed.txt'
  tr -d '\r' < '$TMP/clipboard.txt' > '$TMP/clip.txt'
  [ -s '$TMP/clip.txt' ] && cmp -s '$TMP/printed.txt' '$TMP/clip.txt'" _ "$OUT"

# --- (4) adopt commits only what it added ----------------------------------------
A="$WS/existant"
mkdir -p "$A"
git -C "$A" init -q -b main
git -C "$A" config user.email t@example.invalid
git -C "$A" config user.name t
echo "# notes" > "$A/notes.md"
git -C "$A" add notes.md && git -C "$A" commit -q -m "notes"
echo "brouillon du projet" > "$A/brouillon.txt"
# A dirty tree is refused by adopt unless the order accepts it (Mission 218):
# accepted here, so that the project's own file is there to be left alone.
write_order "$TMP/o-adopt.md" adopt existant git "- Arbre sale : accepté — un brouillon en cours"
OUT="$(cd "$WS" && "$SB" new --order "$TMP/o-adopt.md" 2>&1)"; RC=$?
check "(4) adopt : exit 0" test "$RC" = 0
check "(4) adopt : un commit de plus dans le projet" sh -c "[ \"\$(git -C '$A' rev-list --count HEAD)\" = 2 ]"
check "(4) le fichier du projet reste non suivi, jamais commite" sh -c "git -C '$A' status --porcelain | grep -qx '?? brouillon.txt' && ! git -C '$A' show --name-only --format= HEAD | grep -q brouillon"
check "(4) le commit d'adoption porte l'acte de naissance" sh -c "git -C '$A' show --name-only --format= HEAD | grep -qx '.pre-commit-config.yaml'"
check "(4) Vault : porcelain 0 apres l'adoption" test "$(porcelain "$V")" = 0

# --- (5) a refusing hook -------------------------------------------------------
write_order "$TMP/o2.md" create refuse git
touch "$TMP/refuse"
OUT="$(cd "$WS" && "$SB" new --order "$TMP/o2.md" 2>&1)"; RC=$?
rm -f "$TMP/refuse"
check "(5) garde refusant : exit non nul" test "$RC" != 0
check "(5) le refus est dit, le texte du gardien montre" sh -c "printf '%s' \"\$1\" | grep -q 'REFUS : les gardiens ont refusé' && printf '%s' \"\$1\" | grep -q 'stub guardian: refused'" _ "$OUT"
check "(5) rien de contourne : le projet reste sans commit" sh -c "! git -C '$WS/refuse' rev-parse --verify -q HEAD"

# --- (6) the historical call commits nothing itself ----------------------------------
V_HEAD="$(git -C "$V" rev-parse HEAD)"
git -C "$V" add -A >/dev/null 2>&1; git -C "$V" commit -q -m "state before historical call" >/dev/null 2>&1
V_HEAD="$(git -C "$V" rev-parse HEAD)"
bash "$BOOT" "$WS/historique" "Historique" FR >/dev/null 2>&1; RC=$?
check "(6) appel historique : exit 0" test "$RC" = 0
check "(6) appel historique : aucun commit dans le Vault" test "$(git -C "$V" rev-parse HEAD)" = "$V_HEAD"
check "(6) appel historique : aucun commit dans le projet" sh -c "! git -C '$WS/historique' rev-parse --verify -q HEAD"

echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" -eq 0 ]
