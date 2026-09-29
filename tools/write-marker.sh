#!/usr/bin/env bash
# Writes VAULT-ROOT.md at the work root from templates/vault-root-template.md.
# File name: the Pilot's choice, open to revision.
#
# usage: write-marker.sh [--marker-only] [--tmp <path>] [--organs "<name> ..."]
#                        [--exceptions "<name> ..."] <work-root> [vault-name]
#
# Mission 234 (rule on workspace hygiene): three more field lines. The declared
# temporary folder: --tmp, else the value the existing marker carries, else
# SB_TMP, else <system temporary folder>/second-brain -- refused when it lies
# below <work-root> (tools/lib/tmp.sh). The organs declared at this root and
# its provisional exceptions (read by tools/check-workspace-root.sh): the
# option, else the value the existing marker carries, else `-` (none). A
# regeneration therefore keeps what the Owner declared.
#
# --marker-only (Mission 203, report 202 A3): writes VAULT-ROOT.md and nothing
# else. Without it the script also writes the workspace-level CLAUDE.md and
# AGENTS.md at <work-root> -- right for a workspace root, wrong for a project
# root, whose own CLAUDE.md and AGENTS.md it would overwrite. Default unchanged.

set -u

MARKER_ONLY=0
OPT_TMP=""
OPT_ORGANS=""
OPT_EXCEPTIONS=""
HAVE_ORGANS=0
HAVE_EXCEPTIONS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --marker-only) MARKER_ONLY=1; shift ;;
    --tmp) [ $# -ge 2 ] || { echo "REFUS : --tmp sans valeur" >&2; exit 1; }; OPT_TMP="$2"; shift 2 ;;
    --organs) [ $# -ge 2 ] || { echo "REFUS : --organs sans valeur" >&2; exit 1; }; OPT_ORGANS="$2"; HAVE_ORGANS=1; shift 2 ;;
    --exceptions) [ $# -ge 2 ] || { echo "REFUS : --exceptions sans valeur" >&2; exit 1; }; OPT_EXCEPTIONS="$2"; HAVE_EXCEPTIONS=1; shift 2 ;;
    --) shift; break ;;
    -*) echo "REFUS : option inconnue : $1" >&2; exit 1 ;;
    *) break ;;
  esac
done

WORK_ROOT="${1:-}"
VAULT_NAME="${2:-Brian}"

if [ -z "$WORK_ROOT" ]; then
  echo "usage: write-marker.sh [--marker-only] <racine-de-travail> [nom-du-vault]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/relpath.sh"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$VAULT_ROOT/templates/vault-root-template.md"

if [ ! -f "$TEMPLATE" ]; then
  echo "REFUS : gabarit introuvable : $TEMPLATE" >&2
  exit 1
fi

mkdir -p "$WORK_ROOT"
WORK_ROOT_ABS="$(cd "$WORK_ROOT" && pwd)"
REL_PATH="$(rel_path "$WORK_ROOT_ABS" "$VAULT_ROOT")"

MARKER="$WORK_ROOT_ABS/VAULT-ROOT.md"

# Vault identity (Decision 2026-09-17-000545, A7): generated if missing,
# carried by the marker so that two Vaults on the same machine can be told apart.
. "$SCRIPT_DIR/vault-identity.sh"
vid_ensure "$VAULT_ROOT"
sed_escape() {
  printf '%s' "$1" | sed 's/[#&\\]/\\&/g'
}
VAULT_ID_ESC="$(sed_escape "$(vid_get "$VAULT_ROOT" vault_id)")"
VAULT_ORIGIN_ESC="$(sed_escape "$(vid_get "$VAULT_ROOT" vault_origin)")"

# The template is written and checked (check-links.sh) from templates/ at the
# Vault root, where its relative links (../decisions/...) are correct. Copied to the work
# root, those same links must point through the relative Vault path
# computed above: they are rewritten at generation time.
# --- Mission 234: declared temporary folder, organs, provisional exceptions ---
. "$SCRIPT_DIR/lib/tmp.sh"
marker_field() { # <label>: value in the existing marker, empty if none
  [ -f "$MARKER" ] || return 0
  tr -d '\r' < "$MARKER" | grep -oE "$1 : \`[^\`]*\`" | head -n 1 | sed -E 's/.*`([^`]*)`.*/\1/'
}
names_value() { # <list>: single folder names separated by spaces; `-` if none
  local n out=""
  for n in $(printf '%s' "$1" | tr ',\t' '  '); do
    [ "$n" = "-" ] && continue
    case "$n" in
      */*|*\\*|.|..|*\`*) echo "REFUS : nom de dossier invalide dans la liste : $n" >&2; return 1 ;;
    esac
    out="$out${out:+ }$n"
  done
  printf '%s' "${out:--}"
}
TMP_DECL="$OPT_TMP"
[ -n "$TMP_DECL" ] || TMP_DECL="$(marker_field "$SB_TMP_MARKER_LABEL")"
[ -n "$TMP_DECL" ] || TMP_DECL="$(sb_tmp_root 2>/dev/null || true)"
if [ -z "$TMP_DECL" ]; then
  echo "REFUS : dossier temporaire declare non determine" >&2
  exit 1
fi
TMP_POSIX="$(_sb_tmp_posix "$TMP_DECL")"
mkdir -p "$TMP_POSIX" 2>/dev/null || { echo "REFUS : dossier temporaire declare non cree : $TMP_DECL" >&2; exit 1; }
TMP_POSIX="$(cd "$TMP_POSIX" && pwd -P)"
case "$TMP_POSIX/" in
  "$(cd "$WORK_ROOT_ABS" && pwd -P)"/*)
    echo "REFUS : dossier temporaire declare sous la racine de travail : $TMP_DECL ; il doit vivre hors de l'espace (regle 112218 §2.3)" >&2
    exit 1 ;;
esac
if command -v cygpath >/dev/null 2>&1; then TMP_NATIVE="$(cygpath -w "$TMP_POSIX")"; else TMP_NATIVE="$TMP_POSIX"; fi
if [ "$HAVE_ORGANS" = "1" ]; then
  ORGANS="$(names_value "$OPT_ORGANS")" || exit 1
else
  ORGANS="$(names_value "$(marker_field 'Organes déclarés à cette racine')")" || exit 1
fi
if [ "$HAVE_EXCEPTIONS" = "1" ]; then
  EXCEPTIONS="$(names_value "$OPT_EXCEPTIONS")" || exit 1
else
  EXCEPTIONS="$(names_value "$(marker_field 'Exceptions provisoires à cette racine')")" || exit 1
fi
TMP_ESC="$(sed_escape "$TMP_NATIVE")"

sed \
  -e "s#{{TMP_DIR}}#$TMP_ESC#g" \
  -e "s#{{ORGANS}}#$ORGANS#g" \
  -e "s#{{EXCEPTIONS}}#$EXCEPTIONS#g" \
  -e "s#{{VAULT_NAME}}#$VAULT_NAME#g" \
  -e "s#{{VAULT_RELATIVE_PATH}}#$REL_PATH#g" \
  -e "s#{{VAULT_ID}}#$VAULT_ID_ESC#g" \
  -e "s#{{VAULT_ORIGIN}}#$VAULT_ORIGIN_ESC#g" \
  -e "s#](\.\./#]($REL_PATH/#g" \
  "$TEMPLATE" > "$MARKER.new.$$" && mv "$MARKER.new.$$" "$MARKER"

# --- Workspace-level CLAUDE.md and AGENTS.md (Mission 173, Q17:
# three-level hierarchy). Placed here, never under 10 lines, next to
# VAULT-ROOT.md -- outside any Git repository (the workspace itself is
# not one), so never tracked, never subject to the guardians or to the link
# standard of second-brain. Identical content in both files (same
# instruction as the second-brain and project levels). Idempotent: rewritten at
# each installation (the assistant's name may change), never appended.
# Mission 235: a routing line sends any session opened at the workspace root
# to the entry matrix of session-start (§0) before its answer, and states the
# free-session form -- the Pilot of Mission 234 measured a free session that
# declared itself in prose. tools/check-workspace-root.sh admits both files.
# Mission 236: one more line routes a message that starts with `sb ` to the sb
# command (rules/RULES-2026-09-26-200933-sb-command-surface.md). ---
if [ "$MARKER_ONLY" = "0" ]; then
WORKSPACE_GUIDE_CONTENT="La méthode de ce workspace vit dans \`$REL_PATH/\` (Second Brain) : règles, skills, assistant.

Ouvrir une session : lire \`$REL_PATH/skills/session-start/SKILL.md\`.

Avant toute réponse, identifie ta ligne dans la matrice de \`$REL_PATH/skills/session-start/SKILL.md\` §0 ; sans projet, sans Mission, sans ordre : première ligne \`READY (session libre)\`, rien écrit.

Un message qui commence par \`sb \` est une commande Second Brain : lance \`sb <verbe>\` (ou \`bash $REL_PATH/tools/sb/bin/sb <verbe>\`), puis applique sa fiche dans \`$REL_PATH/docs/reference/commands.md\` ; sans shell, applique la fiche d'un verbe marqué « Pilot: yes », sinon dis qu'il faut une fenêtre Executor.

Poser une question : « Demande à $VAULT_NAME : ... » — il cite ses sources par chemin. Sans le nommer, l'agent principal peut répondre à sa place, sans garantie de lecture seule."

printf '%s\n' "$WORKSPACE_GUIDE_CONTENT" > "$WORK_ROOT_ABS/CLAUDE.md"
printf '%s\n' "$WORKSPACE_GUIDE_CONTENT" > "$WORK_ROOT_ABS/AGENTS.md"
fi

echo "$MARKER"
