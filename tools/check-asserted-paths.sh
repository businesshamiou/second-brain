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
# Mission 214: constant launches. Under Git Bash an external command costs
# about 43.5 ms to launch (Mission 210), and this guardian used to launch 316
# of them per pass -- a `grep -o` and a `tr` per perimeter document, a
# `git ls-files | sort | grep` per unresolved bare token, a `dirname` per
# climbing token -- 13.3 s for a block of 23.7 s (Mission 212). It now reads
# the corpus in three `awk` passes and lists the tracked files once: about eight
# launches whatever the size of the corpus, the same verdicts byte for byte
# (tests/test-check-asserted-paths-constant-launches.sh counts them).
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
# Folder of this script, in pure bash (Mission 214): a `$(dirname "$0")` is a
# subshell and a launch, and there were two.
case "$0" in
  */*) TOOLS_DIR="${0%/*}" ;;
  *) TOOLS_DIR="." ;;
esac
[ -n "$TOOLS_DIR" ] || TOOLS_DIR="/"
. "$TOOLS_DIR/resolve-sibling-repo.sh"
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

# Grouped pre-pass (Mission 127, rewritten by Mission 214): ONE awk process
# selects the perimeter for the whole corpus. On this machine (Git
# Bash/Windows) process forking is the dominant cost, not the processing
# itself (same diagnosis and same pattern as tools/build-indexes.sh
# list_fields()). Mission 127 replaced one awk per document by one awk per
# batch of `xargs` (four on this Vault, more as the corpus grew); the list of
# paths now goes to the standard input of a single awk that opens each
# document itself (`getline`): no `xargs`, no batch.
#
# The perimeter is decided IN awk, not in bash: a table of the front matter of
# every tracked document, filled by two `kv_set` each and read back by as
# many `kv_get`, cost 0.8 s of bash function calls. Rules, unchanged: a
# document is in the perimeter when it lives at the repository root, or
# under knowledge/ or templates/, or its front-matter `type` is `rules` or
# `decision`; and it is out when its front-matter `status` is `superseded`.
# The front matter is the block between a first line `---` and the next
# `---`: nothing after it can change either field, so awk stops reading
# there, and at once on a document that does not open with `---` (only the
# perimeter is then read to its end, by the pre-passes below).
#
# awk prints its lines and never uses ENDFILE (a gawk extension which
# Apple's awk reads as a null variable -- no line, empty table, and this
# guardian passed without checking anything: Mission 181). Paths stay
# relative to the root, entered by `cd` in the substitution's subshell, and
# no root is handed to awk as an assignment: an `&` or a backslash in a root
# was mangled by `sed "s#^#$VAULT_ROOT/#"` (Mission 181, resumption of step 6,
# smoke test) and `awk -v` reads a backslash as an escape. A path that git
# prints quoted names no file: `getline` fails, type and status stay empty,
# as the lookup of a document absent from the table returned before.
AWK_PERIMETER='
  function scan(f,    line, n, type, status, v, keep) {
    n = 0; type = ""; status = ""
    while ((getline line < f) > 0) {
      n++
      if (n == 1) {
        if (line == "---") continue
        break
      }
      if (line == "---") break
      if (line ~ /^type:/)   { v = line; sub(/^type:[[:space:]]*/, "", v);   gsub(/^"|"$/, "", v); type = v }
      if (line ~ /^status:/) { v = line; sub(/^status:[[:space:]]*/, "", v); gsub(/^"|"$/, "", v); status = v }
    }
    close(f)
    keep = (index(f, "/") == 0) || (index(f, "knowledge/") == 1) || (index(f, "templates/") == 1) || (type == "rules") || (type == "decision")
    if (keep && status != "superseded") print f
  }
  $0 != "" { scan($0) }
'
PERIMETER_FILES=""
PERIMETER_COUNT=0
if [ -n "$ALL_MD" ]; then
  PERIMETER_LIST="$(cd "$VAULT_ROOT" && printf '%s\n' "$ALL_MD" | LC_ALL=C awk "$AWK_PERIMETER" 2>/dev/null)" || {
    echo "REFUS : lecture du front matter impossible (awk) : gardien non executable." >&2
    exit 1
  }
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    PERIMETER_FILES="$PERIMETER_FILES
$rel"
    PERIMETER_COUNT=$((PERIMETER_COUNT + 1))
  done <<EOF_PERIMETER_LIST
$PERIMETER_LIST
EOF_PERIMETER_LIST
fi

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
      # Mission 214: no `dirname` and no subshell. `dirname` drops the
      # trailing slashes, then the last component: the two steps below.
      # `cd` runs in this shell (a builtin, no launch) and comes back.
      local probe="$source_dir/$token" norm here="$PWD"
      while :; do
        case "$probe" in
          */) probe="${probe%/}" ;;
          *) break ;;
        esac
      done
      cd "${probe%/*}" 2>/dev/null || return 0
      norm="$PWD"
      cd "$here" 2>/dev/null
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
# The pre-pass fills the list IGNORED_LIST (a newline-delimited string, see below); the
# walk now only does an in-memory lookup.

# Mission 214: ONE awk pass reads every document of the perimeter, and lists
# the tracked files once, instead of a `grep -o` and a `tr` per document, a
# `sort` and six `grep -v` on the result, and a `git ls-files | sort | grep`
# per unresolved bare token. It writes two blocks, told apart by a sentinel
# line (\001M214\001):
#   before it, one line per bare token: `token<TAB>path` -- a token with no
#   `/`, a dot, no glob character, not `:`-led, and the ONE tracked file it
#   names (empty path when it names none or several);
#   after it, one line per token kept for `git check-ignore`: every distinct
#   backtick span of the perimeter that the former pipeline kept (not empty,
#   not `../*`, not absolute, not `X:*`, not under the sibling repository,
#   not `.` or `..`).
# On the standard input, the same sentinel (\001) separates the list of
# documents from the list of tracked files. The sibling name reaches awk
# through the environment, never through `-v` (a backslash there is read as
# an escape). The backtick is written \140 so that no literal backtick lives
# in the program.
#
# The bare-name rule of resolve_token, reproduced exactly (measured on git
# 2.55 with core.ignorecase=true, matching stays case-sensitive):
# `git ls-files -- "*/$token" "$token"` names a tracked path P when P ends
# with `/token`, or P is `token`, or P lies under a ROOT folder `token/`. So
# each tracked path is entered under its last component and, when it has a
# folder, under its first component; a path is counted once per key.
AWK_PRIME='
  BEGIN { sib = ENVIRON["SIB"]; sec = 0 }
  $0 == "\001" { sec = 1; next }
  sec == 0 {
    f = $0
    if (f == "") next
    while ((getline line < f) > 0) {
      rest = line
      while (match(rest, /\140[^\140]*\140/)) {
        t = substr(rest, RSTART + 1, RLENGTH - 2)
        rest = substr(rest, RSTART + RLENGTH)
        if (!(t in seen)) { seen[t] = 1; order[++n] = t }
      }
    }
    close(f)
    next
  }
  {
    p = $0
    if (p == "" || (p in pseen)) next
    pseen[p] = 1
    b = p
    while ((i = index(b, "/")) > 0) b = substr(b, i + 1)
    cnt[b]++; if (cnt[b] == 1) where[b] = p
    i = index(p, "/")
    if (i > 0) {
      d = substr(p, 1, i - 1)
      if (d != b) { cnt[d]++; if (cnt[d] == 1) where[d] = p }
    }
  }
  END {
    for (k = 1; k <= n; k++) {
      t = order[k]
      if (index(t, "/") == 0 && index(t, ".") > 0 && index(t, "\t") == 0 && t !~ /[*?[\\]/ && substr(t, 1, 1) != ":")
        print t "\t" (cnt[t] == 1 ? where[t] : "")
    }
    print "\001M214\001"
    for (k = 1; k <= n; k++) {
      t = order[k]
      if (t == "") continue
      if (substr(t, 1, 3) == "../") continue
      if (substr(t, 1, 1) == "/") continue
      if (t ~ /^[A-Za-z]:/) continue
      if (sib != "" && t ~ ("^" sib "/")) continue
      if (t == "." || t == "..") continue
      print t
    }
  }
'

# Both tables are plain newline-delimited strings searched with `case`, not
# tools/kvmap.sh maps (Mission 181): a key with a character outside [A-Za-z0-9_./ -] (`~`, `&`, an
# accent...) sent kvmap through `printf | od | tr`, two more launches per such
# key, and the count would have followed the corpus again.
NL="
"
SENT="$(printf '\001M214\001')"
IGNORED_LIST="$NL"
BARE_INDEX="$NL"

prime_git_ignored() {
  local out ipart ign
  [ -n "$PERIMETER_FILES" ] || return 0
  # A single token outside the repository aborts the whole batch ("is outside
  # repository"): climbing, absolute or sibling-repository paths are
  # set aside in the awk program. No loss -- outside_root handles them
  # before git_ignored.
  out="$(cd "$VAULT_ROOT" && { printf '%s\n' "$PERIMETER_FILES"; printf '\001\n'; git ls-files 2>/dev/null; } \
    | SIB="$SIBLING_NAME" LC_ALL=C awk "$AWK_PRIME" 2>/dev/null)" || {
    echo "REFUS : lecture des jetons impossible (awk) : gardien non executable." >&2
    exit 1
  }
  [ -n "$out" ] || return 0
  # The two blocks of the output, split on the sentinel line (a newline is
  # added on both sides so that an empty block still leaves the sentinel
  # framed).
  out="$NL$out$NL"
  BARE_INDEX="${out%%"$NL$SENT$NL"*}$NL"
  ipart="${out#*"$NL$SENT$NL"}"
  ipart="${ipart%"$NL"}"
  [ -n "$ipart" ] || return 0
  while IFS= read -r -d '' ign; do
    [ -n "$ign" ] && IGNORED_LIST="$IGNORED_LIST$ign$NL"
  done < <(printf '%s\n' "$ipart" | tr '\n' '\0' \
    | git -C "$VAULT_ROOT" check-ignore -z --stdin 2>/dev/null)
}

git_ignored() {
  case "$IGNORED_LIST" in
    *"$NL$1$NL"*) return 0 ;;
  esac
  return 1
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
      # Mission 214: the name is looked up in BARE_INDEX, built once by the
      # pre-pass (a `B` line: the token and the ONE tracked file it names, or
      # no file when it names none or several). A token the pre-pass did not
      # cover -- a glob character, a leading `:` (git reads it as a pathspec
      # magic), a token absent from the index -- keeps the former command,
      # which is exact by definition and rare.
      local matches match rest
      case "$token" in
        *'*'*|*'?'*|*'['*|*'\'*|:*) : ;;
        *)
          case "$BARE_INDEX" in
            *"$NL$token$TAB"*)
              rest="${BARE_INDEX#*"$NL$token$TAB"}"
              match="${rest%%"$NL"*}"
              if [ -n "$match" ] && [ -e "$VAULT_ROOT/$match" ]; then
                return 0
              fi
              return 1
              ;;
          esac
          ;;
      esac
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

# Mission 214: the reading of the documents leaves bash. The loop below used
# to read every line of every document of the perimeter (14 800 lines) with
# `read`, keep the fence state, the section and the line number, cut every
# line into its backtick spans and classify each span (2 347 of them) with a
# dozen `case` -- 2.6 s of a 3.7 s pass, about a millisecond a span under Git
# Bash. ONE awk now does all of it, with the same rules in the same order,
# and hands bash only what needs the file system:
#   T<SEP>document<SEP>line number<SEP>section<SEP>token
# the spans that remain to be resolved. It also counts, and closes with
#   C<SEP>checked<SEP>bare-names ignored<SEP>marked accepted
# and, for a document git lists but the disk does not hold,
#   E<SEP>document
# (bash then reports it the way its own redirection did before). SEP is the
# control character \034, which no line of prose carries. Rules, unchanged:
# a line whose first non-blank characters are three backticks or three
# tildes opens or closes a fence, and nothing inside a fence is read; a line
# that starts with `#` names the current section (its `#` and the blanks
# after them removed) and is not read -- the section before the first
# heading is "(préambule)"; only a line with two backticks or more is cut
# into spans, left to right, each span ending at the next backtick; a span
# with a blank, `{{`, `}}`, `<`, `>`, or starting with `$` or `-` is not a
# path; a span that names no file (names_a_file, transcribed below) is
# counted and dropped; a span followed by `(supprimé)` or `(supprimé,
# Mission ` or carried by a line marked `(hors Vault)` is counted as marked
# and accepted. The backtick is written \140 so that no literal backtick
# lives in the program.
AWK_LINES='
  BEGIN { SEP = "\034"; BT = "\140"; nchecked = 0; nignored = 0; naccepted = 0 }
  function ends(b, x) { return length(b) >= length(x) && substr(b, length(b) - length(x) + 1) == x }
  function last(s, c,    i) { for (i = length(s); i > 0; i--) if (substr(s, i, 1) == c) return i; return 0 }
  function names_a_file(t,    b, i) {
    b = t
    if (substr(b, length(b)) == "/") b = substr(b, 1, length(b) - 1)
    i = last(b, "/");  if (i > 0) b = substr(b, i + 1)
    i = last(b, "\\"); if (i > 0) b = substr(b, i + 1)
    if (b == ".md" || b == ".yaml" || b == ".sh" || b == ".txt" || b == ".py" || b == ".json" || b == ".svg" || b == ".js" || b == ".html" || b == ".example" || b == ".cjs") return 0
    if (b == "." || b == "..") return 0
    if (substr(b, 1, 1) == ".") return 1
    if (ends(b, ".md") || ends(b, ".yaml") || ends(b, ".sh") || ends(b, ".txt") || ends(b, ".py") || ends(b, ".json") || ends(b, ".svg") || ends(b, ".js") || ends(b, ".html") || ends(b, ".example") || ends(b, ".cjs")) return 1
    return 0
  }
  function walk(f,    line, r, ok, l2, ins, sec, ln, i, j, rest, after1, after2, t, c1) {
    ins = 0; sec = "(préambule)"; ln = 0; ok = 0
    while ((r = (getline line < f)) > 0) {
      ok = 1; ln++
      l2 = line; sub(/^[[:space:]]+/, "", l2)
      if (substr(l2, 1, 3) == (BT BT BT) || substr(l2, 1, 3) == "~~~") { ins = !ins; continue }
      if (ins) continue
      if (substr(line, 1, 1) == "#") { sec = line; sub(/^#+/, "", sec); sub(/^[[:space:]]+/, "", sec); continue }
      rest = line
      while ((i = index(rest, BT)) > 0) {
        after1 = substr(rest, i + 1)
        j = index(after1, BT)
        if (j == 0) break
        t = substr(after1, 1, j - 1)
        after2 = substr(after1, j + 1)
        rest = after2
        if (index(t, " ") > 0 || index(t, "\t") > 0) continue
        if (index(t, "{{") > 0 || index(t, "}}") > 0) continue
        if (index(t, "<") > 0 || index(t, ">") > 0) continue
        c1 = substr(t, 1, 1)
        if (c1 == "$" || c1 == "-") continue
        if (!names_a_file(t)) { nignored++; continue }
        nchecked++
        if (index(after2, " (supprimé)") == 1 || index(after2, " (supprimé, Mission ") == 1) { naccepted++; continue }
        if (index(line, "(hors Vault)") > 0) { naccepted++; continue }
        print "T" SEP f SEP ln SEP sec SEP t
      }
    }
    close(f)
    if (!ok && r < 0) print "E" SEP f
  }
  $0 != "" { walk($0) }
  END { print "C" SEP nchecked SEP nignored SEP naccepted }
'
SEP="$(printf '\034')"
# The C record is the last thing awk writes: without it, awk failed (its
# errors are silenced) and the reading is incomplete -- refused below, never
# passed as an empty corpus (Mission 125: a guardian that checks nothing).
GOT_END=0

# T records: TAG, document, line number, section, token. C record: TAG, then
# the three counts in the fields that follow (document, line number, section).
while IFS="$SEP" read -r TAG rel LINE_NO SECTION TOKEN; do
  case "$TAG" in
    C)
      CHECKED="$rel"; IGNORED_DIR="$LINE_NO"; ACCEPTED_MARKED="$SECTION"
      GOT_END=1
      continue
      ;;
    E)
      : < "$VAULT_ROOT/$rel"
      continue
      ;;
  esac
  # Pure-bash dirname (Mission 127): the path is always absolute with at
  # least one "/", so the substitution is always equivalent.
  SOURCE_DIR="${VAULT_ROOT}/${rel}"
  SOURCE_DIR="${SOURCE_DIR%/*}"

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
done < <(cd "$VAULT_ROOT" && printf '%s\n' "$PERIMETER_FILES" | LC_ALL=C awk "$AWK_LINES" 2>/dev/null)

if [ "$GOT_END" -ne 1 ]; then
  echo "REFUS : lecture des documents impossible (awk) : gardien non executable." >&2
  exit 1
fi

echo "Comptes : fichiers du périmètre=$PERIMETER_COUNT jetons-fichier examinés=$CHECKED dossiers nus ignorés=$IGNORED_DIR marqués acceptés=$ACCEPTED_MARKED hors racine=$OUTSIDE_ROOT ignorés=$GIT_IGNORED externes connus=$EXTERNE_CONNU défauts=$DEFECT_COUNT"

if [ "$FAIL" -ne 0 ]; then
  echo "REFUS : $DEFECT_COUNT chemin(s) affirmé(s) introuvable(s)." >&2
  exit 1
fi

exit 0
