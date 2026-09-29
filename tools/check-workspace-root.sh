#!/usr/bin/env bash
# Workspace-root guardian (Mission 234, rule on workspace hygiene, project names
# and session types §3). Compares the root of the workspace with the COMPUTED
# whitelist and names everything else. Read-only: moves, writes and fixes
# nothing.
#
# Allowed at the root, and nothing else:
#   1. VAULT-ROOT.md, and the workspace guides CLAUDE.md and AGENTS.md that
#      tools/write-marker.sh writes next to it (Mission 235);
#   2. the Vault, at the path the marker names (first segment);
#   3. the first segment of every relative_path of the Vault's project registry
#      (projects, and group folders -- a group folder holds only registered
#      projects: anything else inside it is a gap, named <group>/<entry>);
#   4. the organs of the marker line « Organes déclarés à cette racine »;
#   5. _trash, _archive, _orders;
#   6. the declared temporary folder, if an Owner put it there against §2.3
#      (then reported: SIGNALÉ).
# A name on the marker line « Exceptions provisoires à cette racine » is a
# provisional exception (EXCEPTION-PROVISOIRE), not a gap.
#
# usage: check-workspace-root.sh [<workspace root>]
#   default: the folder carrying VAULT-ROOT.md, walking up from this Vault.
# Output: one line per finding (ÉCART, EXCEPTION-PROVISOIRE, SIGNALÉ), then
#   VERDICT: CONFORME (<n> exception(s) provisoire(s))   exit 0
#   VERDICT: <n> ÉCART(S)                                exit 1
# exit 2: no marker, no Vault or no registry (named on stderr).
#
# Called by tools/session-preflight.sh as a WARNING, never a block.
# bash 3.2, POSIX tools only.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/tmp.sh"

ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  ROOT="$(_sb_tmp_marker_dir "$SCRIPT_DIR/.." || true)"
  if [ -z "$ROOT" ]; then
    echo "REFUS : marqueur VAULT-ROOT.md introuvable en remontant depuis $SCRIPT_DIR/.." >&2
    exit 2
  fi
fi
ROOT="$(cd "$ROOT" 2>/dev/null && pwd -P)" || { echo "REFUS : racine introuvable : ${1:-}" >&2; exit 2; }
MARKER="$ROOT/VAULT-ROOT.md"
[ -f "$MARKER" ] || { echo "REFUS : $ROOT ne porte pas VAULT-ROOT.md : ce n'est pas une racine d'espace" >&2; exit 2; }

field() { # <label>: value between backticks after « <label> : »
  tr -d '\r' < "$MARKER" | grep -oE "$1 : \`[^\`]*\`" | head -n 1 | sed -E 's/.*`([^`]*)`.*/\1/'
}
names() { # a marker list: names separated by spaces, `-` for none
  printf '%s\n' "$1" | tr ' \t,' '\n\n\n' | grep -v -e '^$' -e '^-$' || true
}

VAULT_REL="$(field 'Chemin relatif du Vault depuis cette racine de travail')"
[ -n "$VAULT_REL" ] || { echo "REFUS : le marqueur $MARKER ne nomme pas le chemin du Vault" >&2; exit 2; }
VAULT_DIR="$ROOT/$VAULT_REL"
REGISTRY="$VAULT_DIR/projects/PROJECT-REGISTRY.md"
[ -f "$REGISTRY" ] || { echo "REFUS : registre des projets introuvable : $REGISTRY" >&2; exit 2; }
VAULT_SEG="${VAULT_REL%%/*}"

# Registry paths are relative to the parent of the Vault (the root, in the
# standard layout): one path per line.
REG_PATHS="$(tr -d '\r' < "$REGISTRY" | awk -F'|' 'NF >= 6 && $2 !~ /^[ \t]*-+[ \t]*$/ { c = $5; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c != "" && c != "relative_path") print c }')"
REG_FIRST="$(printf '%s\n' "$REG_PATHS" | awk -F'/' 'NF { print $1 }' | LC_ALL=C sort -u)"
GROUP_DIRS="$(printf '%s\n' "$REG_PATHS" | awk -F'/' 'NF >= 2 { print $1 }' | LC_ALL=C sort -u)"
ORGANS="$(names "$(field 'Organes déclarés à cette racine')")"
EXCEPTIONS="$(names "$(field 'Exceptions provisoires à cette racine')")"

TMP_NAME=""
TMP_DECL="$(field "$SB_TMP_MARKER_LABEL")"
if [ -n "$TMP_DECL" ]; then
  TMP_POSIX="$(_sb_tmp_posix "$TMP_DECL")"
  case "$TMP_POSIX/" in
    "$ROOT"/*) TMP_NAME="${TMP_POSIX#"$ROOT"/}"; TMP_NAME="${TMP_NAME%%/*}" ;;
  esac
fi

in_list() { # <name> <list>: 0 if the name is a line of the list
  [ -n "$2" ] || return 1
  printf '%s\n' "$2" | grep -qxF -- "$1"
}

ECARTS=0
EXC=0
ecart() { ECARTS=$((ECARTS + 1)); printf 'ÉCART: %s — %s\n' "$1" "$2"; }

for entry in $(cd "$ROOT" && ls -A | LC_ALL=C sort); do
  case "$entry" in
    VAULT-ROOT.md|CLAUDE.md|AGENTS.md|_trash|_archive|_orders) continue ;;
  esac
  [ "$entry" = "$VAULT_SEG" ] && continue
  if in_list "$entry" "$REG_FIRST"; then
    if in_list "$entry" "$GROUP_DIRS" && ! printf '%s\n' "$REG_PATHS" | grep -qxF -- "$entry"; then
      # A group folder: each entry must be a registered project.
      for inner in $(cd "$ROOT/$entry" 2>/dev/null && ls -A | LC_ALL=C sort); do
        printf '%s\n' "$REG_PATHS" | grep -qxF -- "$entry/$inner" && continue
        ecart "$entry/$inner" "dans un dossier de groupe, hors registre (un groupe ne contient que des projets du registre)"
      done
    fi
    continue
  fi
  if in_list "$entry" "$ORGANS"; then continue; fi
  if [ -n "$TMP_NAME" ] && [ "$entry" = "$TMP_NAME" ]; then
    printf 'SIGNALÉ: %s — dossier temporaire déclaré sous la racine, contraire à la règle 112218 §2.3\n' "$entry"
    continue
  fi
  if in_list "$entry" "$EXCEPTIONS"; then
    EXC=$((EXC + 1))
    printf 'EXCEPTION-PROVISOIRE: %s — nommée par le marqueur, en attente de l'"'"'Owner\n' "$entry"
    continue
  fi
  if [ -d "$ROOT/$entry" ]; then
    ecart "$entry" "dossier hors liste blanche (ni Vault, ni projet ou groupe du registre, ni organe déclaré, ni _trash/_archive/_orders)"
  else
    ecart "$entry" "fichier hors liste blanche (seuls VAULT-ROOT.md et les guides CLAUDE.md, AGENTS.md sont admis à la racine)"
  fi
done

if [ "$ECARTS" -eq 0 ]; then
  echo "VERDICT: CONFORME ($EXC exception(s) provisoire(s)) — $ROOT"
  exit 0
fi
echo "VERDICT: $ECARTS ÉCART(S) — $ROOT"
exit 1
