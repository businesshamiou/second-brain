#!/usr/bin/env bash
# Verified push (Mission 226): the one way a Mission, a report or a block handed
# to the Owner prescribes a push. It pushes exactly the range it is given, to
# the branch the repository is on, and nothing else -- never --force, never a
# `+` refspec, never a tag.
#
# Refused before anything is pushed (exit 1, VERIFIED-PUSH-REFUSED on stderr):
#   1. the repository path is not absolute, or is not the root of a Git
#      repository (a sub-folder, the workspace root, a folder in no repository);
#   2. the range is not <from>..<to>, or either end is not a commit;
#   3. HEAD is not <to>, or HEAD is detached;
#   4. the remote's head of that branch (git ls-remote) is not <from> -- someone
#      else pushed, or the range is stale;
#   5. the remote's push URL is not the declared one: --url <url> when given,
#      otherwise `vault_origin` of a Vault's VAULT-IDENTITY.md at the repository
#      root, otherwise (Mission 231) the `# push_url:` key of the birth
#      certificate that heads the repository's .pre-commit-config.yaml (a
#      project, the workshop); a repository that declares none and gets no
#      --url is refused;
#   6. <to> does not descend from <from>.
# Otherwise: `git push <remote> <to>:refs/heads/<branch>`, then git ls-remote
# must read <to>; last line PUSHED <remote> <branch> <from>..<to>.
# --dry-run runs every check and pushes nothing; last line WOULD-PUSH ...
#
# usage: verified-push.sh <absolute repository path> <from>..<to> [<remote>] [--url <url>] [--dry-run]
# Checks 4 and 5 run in the order 5 then 4: the declared remote is checked
# before the network is read.
# Exit 0: pushed (or would push). Exit 1: refused, nothing pushed -- or
# VERIFIED-PUSH-MISMATCH: the push ran but ls-remote does not read <to>
# afterwards (read the remote before anything else).

set -u

refuse() {
  echo "VERIFIED-PUSH-REFUSED: $*. Nothing pushed." >&2
  exit 1
}

REPO=""; RANGE=""; REMOTE=""; URL=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --url) [ $# -ge 2 ] || refuse "--url needs a value"; URL="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --force|-f|--force-with-lease*) refuse "--force is never accepted" ;;
    -*) refuse "unknown option: $1" ;;
    *)
      if [ -z "$REPO" ]; then REPO="$1"
      elif [ -z "$RANGE" ]; then RANGE="$1"
      elif [ -z "$REMOTE" ]; then REMOTE="$1"
      else refuse "too many arguments: $1"
      fi
      shift ;;
  esac
done
[ -n "$REPO" ] && [ -n "$RANGE" ] || {
  echo "usage: verified-push.sh <absolute repository path> <from>..<to> [<remote>] [--url <url>] [--dry-run]" >&2
  exit 1
}
[ -n "$REMOTE" ] || REMOTE="origin"

# 1. Absolute path, root of a repository.
case "$REPO" in
  /*|[A-Za-z]:/*|[A-Za-z]:\\*) ;;
  *) refuse "repository path is not absolute: '$REPO' (write it in full, e.g. C:/Users/<you>/Workspaces/<repository>)" ;;
esac
[ -d "$REPO" ] || refuse "no such folder: $REPO"
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || refuse "$REPO is in no Git repository (a workspace root holds repositories without being one)"
PREFIX="$(git -C "$REPO" rev-parse --show-prefix 2>/dev/null)"
[ -z "$PREFIX" ] || refuse "$REPO is not the root of its repository ($(git -C "$REPO" rev-parse --show-toplevel)); a sub-folder is never pushed from"
G() { git -C "$REPO" "$@"; }

# 2. The range.
case "$RANGE" in
  *..*) FROM_IN="${RANGE%%..*}"; TO_IN="${RANGE#*..}" ;;
  *) refuse "range is not <from>..<to>: '$RANGE'" ;;
esac
case "$TO_IN" in *..*|"") refuse "range is not <from>..<to>: '$RANGE'" ;; esac
[ -n "$FROM_IN" ] || refuse "range is not <from>..<to>: '$RANGE'"
FROM="$(G rev-parse --verify --quiet "$FROM_IN^{commit}")" || FROM=""
TO="$(G rev-parse --verify --quiet "$TO_IN^{commit}")" || TO=""
[ -n "$FROM" ] || refuse "<from> is not a commit of $REPO: $FROM_IN"
[ -n "$TO" ] || refuse "<to> is not a commit of $REPO: $TO_IN"

# 3. HEAD is <to>, on a branch.
BRANCH="$(G symbolic-ref --quiet --short HEAD 2>/dev/null)" || BRANCH=""
[ -n "$BRANCH" ] || refuse "HEAD is detached in $REPO: a push names a branch"
HEAD_SHA="$(G rev-parse HEAD)"
[ "$HEAD_SHA" = "$TO" ] || refuse "HEAD ($(G rev-parse --short HEAD)) is not <to> ($TO_IN)"

# 5. The declared remote (checked before the network is read).
PUSH_URL="$(G remote get-url --push "$REMOTE" 2>/dev/null)" || refuse "no remote named '$REMOTE' in $REPO"
if [ -z "$URL" ]; then
  if [ -f "$REPO/VAULT-IDENTITY.md" ]; then
    URL="$(tr -d '\r' < "$REPO/VAULT-IDENTITY.md" | sed -n 's/^vault_origin:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' | head -n 1)"
  fi
  # Mission 231: a repository that is not a Vault declares its address in its
  # birth certificate -- the comment block that heads .pre-commit-config.yaml,
  # first line `# second-brain-birth-certificate: v1` -- under `# push_url:`.
  # A push_url line outside such a block declares nothing.
  CERT="$REPO/.pre-commit-config.yaml"
  if [ -z "$URL" ] && [ -f "$CERT" ] \
    && [ "$(tr -d '\r' < "$CERT" | head -n 1)" = "# second-brain-birth-certificate: v1" ]; then
    URL="$(tr -d '\r' < "$CERT" | awk '/^[^#]/ { exit } index($0, "# push_url: ") == 1 { print substr($0, 13); exit }' | sed 's/[[:space:]]*$//')"
  fi
  [ -n "$URL" ] || refuse "$REPO declares no remote (no vault_origin in VAULT-IDENTITY.md, no push_url in the birth certificate of .pre-commit-config.yaml): pass --url <expected url>"
fi
norm_url() {
  # A local path has several spellings (/tmp/x, C:/Users/.../Temp/x): compare
  # its physical form (pwd -W under Git Bash, pwd elsewhere).
  local u="$1"
  if [ -d "$u" ]; then u="$(cd "$u" && { pwd -W 2>/dev/null || pwd; })"; fi
  printf '%s' "$u" | tr '\\' '/' | sed -e 's#/*$##' -e 's#\.git$##'
}
[ "$(norm_url "$PUSH_URL")" = "$(norm_url "$URL")" ] \
  || refuse "remote '$REMOTE' pushes to $PUSH_URL, not to the declared $URL"

# 4. The remote's head is <from>.
REMOTE_SHA="$(G ls-remote "$REMOTE" "refs/heads/$BRANCH" 2>/dev/null | awk 'NR==1{print $1}')"
[ -n "$REMOTE_SHA" ] || refuse "cannot read refs/heads/$BRANCH on '$REMOTE' (network, or no such branch)"
[ "$REMOTE_SHA" = "$FROM" ] || refuse "remote head of $BRANCH is ${REMOTE_SHA%"${REMOTE_SHA#???????}"}, not <from> ($FROM_IN)"

# 6. <to> descends from <from>.
G merge-base --is-ancestor "$FROM" "$TO" || refuse "<to> ($TO_IN) does not descend from <from> ($FROM_IN)"

SHORT="${FROM%"${FROM#???????}"}..${TO%"${TO#???????}"}"
if [ "$DRY" = 1 ]; then
  echo "WOULD-PUSH $REMOTE $BRANCH $SHORT ($PUSH_URL)"
  exit 0
fi

G push "$REMOTE" "$TO:refs/heads/$BRANCH" || refuse "git push failed"
AFTER="$(G ls-remote "$REMOTE" "refs/heads/$BRANCH" 2>/dev/null | awk 'NR==1{print $1}')"
echo "ls-remote $REMOTE refs/heads/$BRANCH: $AFTER"
[ "$AFTER" = "$TO" ] || { echo "VERIFIED-PUSH-MISMATCH: the remote reads $AFTER after the push, not $TO" >&2; exit 1; }
echo "PUSHED $REMOTE $BRANCH $SHORT"
exit 0
