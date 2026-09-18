#!/usr/bin/env bash
# Asserted-paths guardian: checks against the file system the paths
# cited in prose (between single backticks) by the living normative corpus
# of this repository. Read-only: never fixes a defect it finds, only
# refuses and lists it. Is wired into .githooks/pre-commit
# (measured 2026-09-04, build history) -- the previous header wrongly asserted
# that it was not wired (build history); manual run possible
# too, result reported by the caller in that case.
#
# Perimeter: tracked .md files of this repository whose front-matter `type`
# is `rules` or `decision`, or which live under knowledge/, templates/, or
# at the repository root -- and whose `status` is not `superseded`.
#
# A token is examined only if it names a file (extension present in
# its last segment, including the dot-file form of dotfiles such as
# .graphifyignore): a bare folder (`captures/`, `missions/`, ...) is
# never examined -- this is the rule that leaves untouched the prescriptive
# citations of a template or of a generic standard.
#
# A token immediately followed, in the prose, by the literal mark
# `(supprimé, Mission NNN)` or `(supprimé)` is accepted without resolution.
#
# usage: check-asserted-paths.sh

set -u

# Git guard (Mission 125, same reason as in check-secrets.sh): explicit
# refusal outside a repository, rather than an empty $VAULT_ROOT that made this
# read-only guardian silently harmless (0 files examined, false
# PASS) instead of refusing -- measured in report 124.
VAULT_ROOT="$(git rev-parse --show-toplevel)" || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}
WORKSPACE_ROOT="$(cd "$VAULT_ROOT/.." && pwd)"
# Sibling repository (build history; Mission 174 step 3, T21): no name
# assumed by default. See tools/resolve-sibling-repo.sh -- SIBLING_NAME and
# SIBLING_ROOT stay empty when nothing is declared, which is exactly the
# prior behaviour for a Vault-only checkout (a token that would have
# resolved against the sibling now simply falls through to the other
# candidate roots, same as before this repo ever existed).
. "$(dirname "$0")/resolve-sibling-repo.sh"
# Portable associative arrays (Mission 181): `declare -A` does not exist
# in the bash 3.2 shipped by Apple.
. "$(dirname "$0")/kvmap.sh"
resolve_declared_sibling "$WORKSPACE_ROOT"

FAIL=0
CHECKED=0
IGNORED_DIR=0
ACCEPTED_MARKED=0
OUTSIDE_ROOT=0
GIT_IGNORED=0
EXTERNE_CONNU=0
DEFECT_COUNT=0

# Tab computed only once (Mission 127): avoids relaunching a
# printf process at each iteration of the while below (same cost as
# the one measured and fixed in check-distribution-manifest.sh).
TAB="$(printf '\t')"

# --- 1. Selecting the files of the perimeter ---
ALL_MD="$(git -C "$VAULT_ROOT" ls-files -- '*.md')"

# Grouped pre-pass (Mission 127): a single awk process for the whole corpus
# instead of one awk per file in is_in_perimeter()/is_superseded() -- on
# this machine (Git Bash/Windows) process forking is the dominant cost, not
# the processing itself (same diagnosis and same pattern as
# tools/build-indexes.sh list_fields(): FNR==1 resets the state per
# file within a single awk call, one line emitted per file).
# Emission on change of file and in END rather than via ENDFILE:
# ENDFILE is a gawk extension, which Apple's awk reads as a null
# variable -- no line, empty table, and this guardian passed without checking
# anything (Mission 181). An empty file no longer emits a line: its two
# fields were already the empty string, which the lookup also returns.
# Behaviour unchanged: same two fields (type/status) read in the same
# front-matter block --- ... --- in the same sense, measured by the oracle of
# Mission 127 (byte-identical output before/after).
# Paths prefixed in bash, never via `sed "s#^#$VAULT_ROOT/#"`: sed
# reinterprets the root as a replacement -- an `&` in it becomes the matched
# text, a backslash an escape (GNU sed: `\U` turns everything to
# upper case). Empty table, perimeter 105 -> 42 and false refusal at the
# installer's commit (Mission 181, resumption of step 6, smoke test).
FM_TABLE="$(printf '%s\n' "$ALL_MD" | while IFS= read -r p; do
  [ -n "$p" ] && printf '%s/%s\0' "$VAULT_ROOT" "$p"
done | xargs -0 awk '
  function flush() { if (cur != "") print cur "\t" type "\t" status }
  FNR==1 { flush(); cur=FILENAME; infm=0; type=""; status="" }
  FNR==1 && $0=="---" { infm=1; next }
  infm && $0=="---" { infm=0 }
  infm && /^type:/   { v=$0; sub(/^type:[[:space:]]*/,"",v);   gsub(/^"|"$/,"",v); type=v }
  infm && /^status:/ { v=$0; sub(/^status:[[:space:]]*/,"",v); gsub(/^"|"$/,"",v); status=v }
  END { flush() }
' 2>/dev/null)"

while IFS="$TAB" read -r fpath ftype fstatus; do
  [ -z "$fpath" ] && continue
  frel="${fpath#"$VAULT_ROOT"/}"
  kv_set FM_TYPE "$frel" "$ftype"
  kv_set FM_STATUS "$frel" "$fstatus"
done <<EOF_FMTABLE
$FM_TABLE
EOF_FMTABLE

is_in_perimeter() {
  local rel="$1"
  case "$rel" in
    */*) : ;;
    *) return 0 ;;  # at the repository root
  esac
  case "$rel" in
    knowledge/*|templates/*) return 0 ;;
  esac
  local ftype
  kv_get FM_TYPE "$rel"; ftype="$KV_VALUE"
  [ "$ftype" = "rules" ] && return 0
  [ "$ftype" = "decision" ] && return 0
  return 1
}

is_superseded() {
  local rel="$1"
  local status
  kv_get FM_STATUS "$rel"; status="$KV_VALUE"
  [ "$status" = "superseded" ]
}

PERIMETER_FILES=""
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  if is_in_perimeter "$rel" && ! is_superseded "$rel"; then
    PERIMETER_FILES="$PERIMETER_FILES
$rel"
  fi
done <<EOF_ALLMD
$ALL_MD
EOF_ALLMD

# --- 2. Extraction and verification, file by file ---
# A token "names a file" if its last segment (after / or \) starts
# with a dot (dotfile, e.g. .graphifyignore -- always examined, whatever
# the allowlist), or if that last segment ends with one of the
# extensions of the allowlist below. The allowlist is measured,
# not invented: distinct extensions carried by the tracked files of
# vault and workshop-build (git ls-files), Mission 092. Replaces the former
# heuristic "a dot followed by at least one character", which counted
# non-paths (version number, Git configuration key) among the
# defects (measured Mission 091).
# Exception, same principle as bare folders (below): a token
# reduced to a dot followed by a single allowlist extension, with no
# other segment nor other dot (e.g. `.md`), names a format and not a
# file -- it is never examined, whatever its content (Mission
# 100). Distinct from a dotfile such as .graphifyignore, which has no
# "name" segment separate from its extension.
names_a_file() {
  local base="$1"
  base="${base%%/}"
  base="${base##*/}"
  base="${base##*\\}"
  case "$base" in
    .md|.yaml|.sh|.txt|.py|.json|.svg|.js|.html|.example|.cjs) return 1 ;;
  esac
  # `.` and `..` are navigation tokens, never a file name --
  # measured Mission 168 (second-brain): an illustrative `..` in prose silently
  # aborted the whole `git check-ignore --stdin` batch ("is
  # outside repository"), losing the ignored status of all the other tokens
  # of the same batch (including `.env`).
  case "$base" in
    .|..) return 1 ;;
  esac
  case "$base" in
    .*) return 0 ;;
  esac
  case "$base" in
    *.md|*.yaml|*.sh|*.txt|*.py|*.json|*.svg|*.js|*.html|*.example|*.cjs) return 0 ;;
  esac
  return 1
}

# --- Rule 1 (Mission 142, batch 6): cross-repository path -------------------
# An asserted path whose resolution leaves VAULT_ROOT targets a sibling repository,
# absent from a Vault installed alone: it cannot be verified here, so it is neither resolved nor
# counted as a defect. Two forms measured in the corpus: the `../` prefix that
# climbs above the root after normalisation, and the path whose
# first segment names the declared sibling repository ($SIBLING_NAME). Every path
# remaining under the root is checked as before.
outside_root() {
  local token="$1" source_dir="$2"

  # SIBLING_NAME can be empty (no sibling declared) -- an empty-prefix case
  # pattern would then match any token starting with "/", which is not what
  # this rule means. Guarded explicitly rather than relying on the pattern.
  if [ -n "$SIBLING_NAME" ]; then
    case "$token" in
      "$SIBLING_NAME"/*) return 0 ;;
    esac
  fi

  case "$token" in
    ../*)
      local probe="$source_dir/$token" norm
      norm="$(cd "$(dirname "$probe")" 2>/dev/null && pwd)" || return 0
      case "$norm/" in
        "$VAULT_ROOT"/*) return 1 ;;
        *) return 0 ;;
      esac
      ;;
  esac
  return 1
}

# --- Rule 2 (Mission 142, batches 6 and 7): path ignored by Git -------------
# A path that `git check-ignore` recognises is unversioned by design
# (.env, caches, build outputs): its absence from a fresh clone is
# expected, never a defect.
#
# Batch 7: a SINGLE `git check-ignore -z --stdin` for the whole corpus, instead
# of one fork per token -- the per-token form cost 18.7 s in a cold
# clone against 1.9 s before the rule (measured Mission 142), same pattern of fork
# per entry that Mission 137-B had removed from the freshness guardian.
# The pre-pass fills the map GIT_IGNORED_SET (tools/kvmap.sh); the
# walk now only does an in-memory lookup.

prime_git_ignored() {
  local tokens
  # A single token outside the repository aborts the whole batch ("is outside
  # repository"): climbing, absolute or sibling-repository paths are
  # set aside here. No loss -- outside_root handles them before git_ignored.
  tokens="$(printf '%s\n' "$PERIMETER_FILES" | while IFS= read -r r; do
    [ -z "$r" ] && continue
    grep -o '`[^`]*`' "$VAULT_ROOT/$r" 2>/dev/null | tr -d '`'
  done | sort -u | grep -v '^$' \
    | grep -v '^\.\./' | grep -v '^/' | grep -v '^[A-Za-z]:' \
    | grep -v "^$SIBLING_NAME/" | grep -vE '^\.\.?$')"
  [ -z "$tokens" ] && return 0
  while IFS= read -r -d '' ign; do
    [ -n "$ign" ] && kv_set GIT_IGNORED_SET "$ign" 1
  done < <(printf '%s\n' "$tokens" | tr '\n' '\0' \
    | git -C "$VAULT_ROOT" check-ignore -z --stdin 2>/dev/null)
}

git_ignored() {
  kv_has GIT_IGNORED_SET "$1"
}

# Known external tokens (ticket 02, brought forward here only -- Mission 168,
# Owner arbitration 2026-09-11): machine-local artefacts or ones proposed by a
# historical Decision without ever having been built under that name, never
# resolvable from a checkout of any repository -- same status as
# the `(hors Vault)` mark already carried by the line. List measured on the 30
# defects remaining after the `vault/` alias and the search by file name,
# never extended for convenience:
#   VAULT-ROOT.md, MISSION-INDEX.md, .pre-commit-config.yaml -- artefacts of the
#     sibling repository workshop-build or generated at installation, absent by
#     design from any checkout of second-brain;
#   ~/.codex/AGENTS.md, ~/.claude/CLAUDE.md -- user-profile files,
#     never versioned;
#   claude_desktop_config.json, %APPDATA%\Claude\claude_desktop_config.json --
#     configuration of the Claude desktop application, same category as the
#     two previous ones (user-profile file, never versioned in this
#     repository); cited by the participant FAQ of README.md (Mission 186, T5);
#   policy.yaml -- named by a Decision as a gesture to make, never
#     built under that name (explicitly rejected, DECISION-2026-08-23-220049);
#   build-package.sh -- INTERNAL build tool (manifest), never
#     distributed;
#   SKILL.md -- file name shared by all skills (167 tracked
#     occurrences): a bare citation can never resolve without ambiguity.
# Residue fixed (ticket 02, report 168 §16.7): check-project-conformity.sh
# and project-bootstrap.sh removed -- both files really exist
# in second-brain (unique names), the search by file name (point 3
# above) already resolves them without ambiguity; the comment that described them
# here as "never built under that name" was inaccurate.
KNOWN_EXTERNAL_TOKENS=" VAULT-ROOT.md MISSION-INDEX.md .pre-commit-config.yaml ~/.codex/AGENTS.md ~/.claude/CLAUDE.md policy.yaml build-package.sh tools/build-package.sh SKILL.md claude_desktop_config.json %APPDATA%\Claude\claude_desktop_config.json "

known_external() {
  case "$KNOWN_EXTERNAL_TOKENS" in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

resolve_token() {
  local token="$1" source_dir="$2"
  for root in "$VAULT_ROOT" "$source_dir" "$SIBLING_ROOT" "$WORKSPACE_ROOT"; do
    if [ -e "$root/$token" ]; then
      return 0
    fi
  done
  # Root by the marker (ticket 02, brought forward here only -- Mission 168,
  # Owner arbitration 2026-09-11): this repository now absorbs at its own
  # root what a `vault/...` token designated from the sibling repository
  # workshop-build. `vault/` is no longer a subfolder nor a sibling: it is
  # this repository itself. A token so prefixed therefore also resolves against
  # VAULT_ROOT once the prefix is removed.
  case "$token" in
    vault/*)
      local aliased="${token#vault/}"
      [ -e "$VAULT_ROOT/$aliased" ] && return 0
      ;;
  esac
  # token already absolute
  case "$token" in
    /*|[A-Za-z]:\\*|[A-Za-z]:/*)
      [ -e "$token" ] && return 0
      ;;
  esac
  # Search by file name (ticket 02, brought forward here only): a
  # bare token (without "/") that names only one tracked file in the whole
  # repository resolves without ambiguity -- the former short citation relied on
  # a co-location that no longer exists once the content was brought home.
  # Never applied if the token matches more than one file (e.g. SKILL.md).
  case "$token" in
    */*) ;;
    *)
      local matches match
      matches="$(git -C "$VAULT_ROOT" ls-files -- "*/$token" "$token" 2>/dev/null | sort -u)"
      if [ "$(printf '%s\n' "$matches" | grep -c .)" -eq 1 ]; then
        match="$matches"
        [ -e "$VAULT_ROOT/$match" ] && return 0
      fi
      ;;
  esac
  return 1
}

prime_git_ignored

while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  FULL="$VAULT_ROOT/$rel"
  # Pure-bash dirname (Mission 127): $FULL is always an absolute path
  # with at least one "/", so the substitution is always equivalent;
  # replaces one dirname process per file of the perimeter.
  SOURCE_DIR="${FULL%/*}"

  IN_FENCE=0
  SECTION="(préambule)"
  LINE_NO=0

  while IFS= read -r line || [ -n "$line" ]; do
    LINE_NO=$((LINE_NO + 1))

    LTRIM="${line#"${line%%[![:space:]]*}"}"
    case "$LTRIM" in
      '```'*|'~~~'*)
        if [ "$IN_FENCE" -eq 1 ]; then IN_FENCE=0; else IN_FENCE=1; fi
        continue
        ;;
    esac
    [ "$IN_FENCE" -eq 1 ] && continue

    case "$line" in
      '#'*)
        # Pure-bash heading extraction (Mission 127), same technique already
        # used for LTRIM above: ${var%%pattern} isolates the longest
        # prefix made only of the targeted character (# then space),
        # ${var#"$prefixe"} removes it -- equivalent to sed -E 's/^#+[[:space:]]*//'
        # without launching a process per heading line.
        SECTION="$line"
        HASHRUN="${SECTION%%[!#]*}"
        SECTION="${SECTION#"$HASHRUN"}"
        SECTION="${SECTION#"${SECTION%%[![:space:]]*}"}"
        continue
        ;;
    esac

    # Only processes lines carrying at least one backtick span.
    case "$line" in
      *'`'*'`'*) : ;;
      *) continue ;;
    esac

    REST="$line"
    while :; do
      case "$REST" in
        *'`'*'`'*) : ;;
        *) break ;;
      esac
      BEFORE="${REST%%\`*}"
      AFTER1="${REST#*\`}"
      TOKEN="${AFTER1%%\`*}"
      AFTER2="${AFTER1#*\`}"
      REST="$AFTER2"

      case "$TOKEN" in
        *' '*|*$'\t'*) continue ;;
        *'{{'*|*'}}'*) continue ;;
        *'<'*|*'>'*) continue ;;
        '$'*) continue ;;
        '-'*) continue ;;
      esac

      names_a_file "$TOKEN" || { IGNORED_DIR=$((IGNORED_DIR + 1)); continue; }

      CHECKED=$((CHECKED + 1))

      case "$AFTER2" in
        ' (supprimé)'*|' (supprimé, Mission '*)
          ACCEPTED_MARKED=$((ACCEPTED_MARKED + 1))
          continue
          ;;
      esac

      # `(hors Vault)` mark carried by the LINE (Mission 142, Owner
      # arbitration 2026-09-05): the link targets a sibling repository, absent from a Vault
      # installed alone. The mark is already the linking standard's convention for
      # targets outside the repository; here it counts as a declaration, so neither resolution
      # nor defect. It is read on the whole line and not just after the
      # token, because it follows the complete Markdown link, not the span.
      # Every path NOT marked stays refused: the guardian loses nothing.
      case "$line" in
        *'(hors Vault)'*)
          ACCEPTED_MARKED=$((ACCEPTED_MARKED + 1))
          continue
          ;;
      esac

      if outside_root "$TOKEN" "$SOURCE_DIR"; then
        OUTSIDE_ROOT=$((OUTSIDE_ROOT + 1))
        continue
      fi

      if git_ignored "$TOKEN"; then
        GIT_IGNORED=$((GIT_IGNORED + 1))
        continue
      fi

      if known_external "$TOKEN"; then
        EXTERNE_CONNU=$((EXTERNE_CONNU + 1))
        continue
      fi

      if ! resolve_token "$TOKEN" "$SOURCE_DIR"; then
        FAIL=1
        DEFECT_COUNT=$((DEFECT_COUNT + 1))
        echo "CHEMIN-AFFIRME-MORT : $rel:$LINE_NO [$SECTION] jeton \`$TOKEN\` introuvable sous les racines candidates" >&2
      fi
    done
  done < "$FULL"
done <<EOF_PERIMETER
$PERIMETER_FILES
EOF_PERIMETER

PERIMETER_COUNT="$(printf '%s\n' "$PERIMETER_FILES" | grep -c .)"

echo "Comptes : fichiers du périmètre=$PERIMETER_COUNT jetons-fichier examinés=$CHECKED dossiers nus ignorés=$IGNORED_DIR marqués acceptés=$ACCEPTED_MARKED hors racine=$OUTSIDE_ROOT ignorés=$GIT_IGNORED externes connus=$EXTERNE_CONNU défauts=$DEFECT_COUNT"

if [ "$FAIL" -ne 0 ]; then
  echo "REFUS : $DEFECT_COUNT chemin(s) affirmé(s) introuvable(s)." >&2
  exit 1
fi

exit 0
