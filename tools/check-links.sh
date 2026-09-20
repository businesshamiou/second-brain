#!/usr/bin/env bash
# Link check on staged .md files.
# Portable shell: no dependency on Python, same structure as check-secrets.sh.
# Refusal is the default position: any abnormal condition blocks.
#
# (build history): the link sweep (rules 2/3 below) recognises the
# layer in which it reads -- a teaching example inside a
# fenced code block (``` or ~~~) or an inline code span (paired
# backticks, even nested like a two-level `` `x` `` span) is no longer
# swept as a real link. Additive only: rule 1 (mandatory
# "## Liens" section, just below) keeps its exact mechanism,
# unchanged, and is not weakened.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/relpath.sh"
. "$SCRIPT_DIR/project-baseline.sh"

# usage: check-links.sh             (current repository, staged files)
#        check-links.sh <projet>    (folder mode, without Git: all .md files of the
#                                    project -- vcs: none, Decision 000545 A4)
if [ -n "${1:-}" ]; then
  if [ ! -d "$1" ]; then
    echo "REFUS : dossier de projet introuvable : $1" >&2
    exit 1
  fi
  VAULT_ROOT="$(cd "$1" && pwd)"
  STAGED="$(pb_list_files "$VAULT_ROOT" | grep -E '\.md$' || true)"
else
  # Git guard (Mission 125, same reason as in check-secrets.sh): explicit
  # refusal outside a repository, rather than an empty $VAULT_ROOT that would give a
  # silent false PASS further on.
  VAULT_ROOT="$(git rev-parse --show-toplevel)" || {
    echo "REFUS : hors d'un depot Git : gardien non executable." >&2
    exit 1
  }
  STAGED="$(git diff --cached --name-only --diff-filter=AM -- '*.md' || true)"
fi
# Workspace root (parent of the current repository): used to identify the target
# repository of an outgoing link (DECISION-2026-09-02-005041) -- ../../<repo>/...
WORKSPACE_ROOT="$(dirname "$VAULT_ROOT")"

# Baseline (Decision 000545, A4): a file engraved at adoption and not
# touched is never judged; once touched, it is judged in full, like a new one.
pb_load "$VAULT_ROOT"
if [ -n "$PB_FILE" ] && [ -n "$STAGED" ]; then
  KEPT=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    pb_untouched "$f" && continue
    KEPT="${KEPT}${KEPT:+
}$f"
  done <<PB_EOF
$STAGED
PB_EOF
  STAGED="$KEPT"
fi

# Exempt paths (Mission 203): the certificate's `# exempt:` prefixes hold files of
# third parties that must stay byte-identical (no `## Liens`). Read by this
# guardian, the index-freshness and the index-weight guardians, and by no other:
# the secrets check never reads the key. No key: nothing changes.
bc_exempt_load "$VAULT_ROOT"
if [ -n "$BC_EXEMPT_LIST" ] && [ -n "$STAGED" ]; then
  KEPT=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    bc_exempt_covers "$f" && continue
    KEPT="${KEPT}${KEPT:+
}$f"
  done <<EX_EOF
$STAGED
EX_EOF
  STAGED="$KEPT"
fi

if [ -z "$STAGED" ]; then
  exit 0
fi

# Removes every inline code span from a line before the link sweep:
# backticks paired by equal delimiter length (CommonMark rule for code
# spans), an unpaired run is left as is (literal text).
strip_inline_code() {
  awk '
    {
      s = $0
      out = ""
      n = length(s)
      i = 1
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == "`") {
          run = 0
          j = i
          while (j <= n && substr(s, j, 1) == "`") { run++; j++ }
          k = j
          found = 0
          while (k <= n) {
            if (substr(s, k, 1) == "`") {
              crun = 0
              m = k
              while (m <= n && substr(s, m, 1) == "`") { crun++; m++ }
              if (crun == run) { found = 1; endk = m; break }
              k = m
            } else {
              k++
            }
          }
          if (found) {
            out = out " "
            i = endk
          } else {
            out = out substr(s, i, run)
            i = j
          }
        } else {
          out = out c
          i++
        }
      }
      print out
    }
  '
}

BLOCK=0

while IFS= read -r file; do
  [ -z "$file" ] && continue
  case "$file" in
    graphify-out/*) continue ;;
  esac

  FULLPATH="$VAULT_ROOT/$file"
  [ -f "$FULLPATH" ] || continue

  DIR="$(dirname "$FULLPATH")"

  # --- 1. Mandatory "## Liens" section -- limited to the documentary corpus,
  # never to the adopted material of skills/external/ (verbatim body guaranteed
  # by fingerprints, outside the corpus's citation graph). The resolution
  # of links (rules 2/3 below) remains global, external/ included.
  # DECISION-2026-08-28-203627. skills-warehouse/ added (Mission 168,
  # Owner arbitration 2026-09-11, option b -- same principle as
  # DECISION-203627: subtree adopted as is, T24, its own provenance
  # standards stand in for it, never the Vault's linking convention). ---
  case "$file" in
    skills/external/*|skills-warehouse/*) : ;;
    *)
      if ! grep -qE '^## Liens[[:space:]]*$' "$FULLPATH"; then
        echo "LIENS: section manquante: $file" >&2
        BLOCK=1
      fi
      ;;
  esac

  # --- 2/3. Relative links: target resolved, or warning if no internal link ---
  HAS_INTERNAL=0
  LINE_NO=0
  IN_FENCE=0

  while IFS= read -r line || [ -n "$line" ]; do
    LINE_NO=$((LINE_NO + 1))

    # --- layer: fenced code block (Mission 060) -- removes any
    # indentation by pure bash parameter expansion (no subprocess,
    # unlike `sed`: the per-line cost must stay nil for large
    # files) before testing the fence delimiter ---
    LTRIM="${line#"${line%%[![:space:]]*}"}"
    case "$LTRIM" in
      '```'*|'~~~'*)
        if [ "$IN_FENCE" -eq 1 ]; then IN_FENCE=0; else IN_FENCE=1; fi
        continue
        ;;
    esac
    if [ "$IN_FENCE" -eq 1 ]; then
      continue
    fi

    # Quick filter on the raw line, identical to the behaviour before
    # Mission 060: avoids paying the cost of an awk subprocess per
    # line (strip_inline_code) for the vast majority of lines that
    # contain no candidate substring -- performance on
    # large files must not degrade.
    case "$line" in
      *'](./'*|*'](../'*) : ;;
      *) continue ;;
    esac

    # --- layer: inline code (Mission 060) -- the sweep that follows works
    # on SCAN_LINE (code spans removed), never on raw $line. Only
    # the lines that have already passed the quick filter above pay this
    # cost. ---
    SCAN_LINE="$(printf '%s' "$line" | strip_inline_code)"

    case "$SCAN_LINE" in
      *'](./'*|*'](../'*) : ;;
      *) continue ;;
    esac

    # Note (DECISION-2026-09-02-005041): the mention "(hors <depot>)" is
    # for the reader only; the guardian now decides by the resolved
    # path (internal to the current repository, or outgoing to a sibling repository),
    # never by the presence or absence of this mention on the line.

    TARGETS="$(printf '%s' "$SCAN_LINE" | grep -oE '\]\(\.{1,2}/[^)]*\)' | sed -E 's/^\]\((.*)\)$/\1/')"
    [ -z "$TARGETS" ] && continue

    while IFS= read -r TARGET; do
      [ -z "$TARGET" ] && continue
      case "$TARGET" in
        *.md) : ;;
        *) continue ;;
      esac

      TARGET_PATH="$DIR/$TARGET"
      RESOLVED="$(abs_path "$TARGET_PATH")"

      if [ -z "$RESOLVED" ]; then
        echo "LIENS: cible introuvable: $file:$LINE_NO -> $TARGET" >&2
        BLOCK=1
        continue
      fi

      case "$RESOLVED" in
        "$VAULT_ROOT"/*)
          # --- link internal to the current repository: behaviour unchanged,
          # missing = refusal. ---
          if [ -f "$RESOLVED" ]; then
            HAS_INTERNAL=1
          else
            echo "LIENS: cible introuvable: $file:$LINE_NO -> $TARGET" >&2
            BLOCK=1
          fi
          ;;
        *)
          # --- outgoing link (DECISION-2026-09-02-005041): full check
          # only if the target repository (first segment under the workspace
          # root) is present on disk; otherwise a warning, never
          # a refusal -- dead by construction in a standalone package. ---
          REL_TO_WS="${RESOLVED#"$WORKSPACE_ROOT"/}"
          if [ "$REL_TO_WS" = "$RESOLVED" ]; then
            echo "LIENS: avertissement (depot cible non determinable depuis l'espace de travail, lien non verifie) : $file:$LINE_NO -> $TARGET" >&2
          else
            TARGET_REPO_NAME="${REL_TO_WS%%/*}"
            TARGET_REPO_ROOT="$WORKSPACE_ROOT/$TARGET_REPO_NAME"
            if [ -d "$TARGET_REPO_ROOT" ]; then
              if [ -f "$RESOLVED" ]; then
                HAS_INTERNAL=1
              else
                echo "LIENS: cible introuvable: $file:$LINE_NO -> $TARGET" >&2
                BLOCK=1
              fi
            else
              echo "LIENS: avertissement (depot cible absent du disque, lien non verifie) : $file:$LINE_NO -> $TARGET" >&2
            fi
          fi
          ;;
      esac
    done <<TARGETS_EOF
$TARGETS
TARGETS_EOF
  done < "$FULLPATH"

  if [ "$HAS_INTERNAL" -eq 0 ]; then
    echo "LIENS: avertissement, aucun lien interne: $file" >&2
  fi
done <<STAGED_EOF
$STAGED
STAGED_EOF

if [ "$BLOCK" -ne 0 ]; then
  exit 1
fi

exit 0
