#!/usr/bin/env bash
# Poses the tag of a published version and pushes it to BOTH remotes of the
# laboratory (Mission 230, P2 of report 227) -- the gesture that used to be two
# hand-typed `git tag` / `git push` lines of docs/how-to/publish.md, which named
# `release` only.
#
# Why both. A participant installs from `release` (second-brain.git) and updates
# from it. A Vault installed from `origin` (vault.git) -- the company's, whose
# `company` branch descends from the published line and has no common ancestor
# with the laboratory's `main` -- reads the tags of ITS OWN origin. Tags v0.1.8
# to v0.1.14 reached vault.git only because they were pushed there by hand. A
# version whose tag is on `release` alone is invisible to that Vault, and
# `second-brain update <version>` answers "no such version".
#
# Run it after `tools/publish-from-laboratory.sh --version <vX.Y.Z>` has printed
# PUBLISHED. The commit tagged is the head of the local branch `publish`, and it
# must be exactly what `release/main` reads on the remote: the tag never names a
# commit the publication did not push.
#
# Refused before anything is pushed (exit 1, PUBLISH-TAG-REFUSED on stderr):
#   1. the version is not vX.Y.Z;
#   2. the repository path is not absolute, or is not the root of a Git
#      repository;
#   3. the repository is not a laboratory: it has no `release` remote, or no
#      `origin` remote;
#   4. `origin` does not push to the declared URL: --url <url> when given,
#      otherwise `vault_origin` of VAULT-IDENTITY.md at the repository root;
#   5. there is no local branch `publish`, or its head is not a commit;
#   6. the head of `refs/heads/main` on `release` is not that commit -- the
#      publication did not push it, or someone else advanced release/main;
#   7. the tag already exists on either remote: a published version is never
#      republished;
#   8. the tag exists locally on another commit.
# Otherwise: the annotated tag is created locally if it is not there, then
# pushed to `release` and to `origin`, and `git ls-remote --tags` of each must
# read the tagged commit afterwards.
#
# --dry-run runs every check, creates nothing and pushes nothing; last line
# WOULD-TAG <version> <commit>.
#
# usage: publish-tag.sh <vX.Y.Z> [--repo <absolute repository path>]
#                       [--url <origin url>] [--message <text>] [--dry-run]
# Last line: TAGGED <version> <commit> | WOULD-TAG <version> <commit> | REFUSED
# Exit 0: tagged and pushed (or would). Exit 1: refused, nothing pushed -- or
# PUBLISH-TAG-MISMATCH: the push ran and a remote does not read the tag after.

set -u

refuse() {
  echo "PUBLISH-TAG-REFUSED: $*. Nothing pushed." >&2
  echo "REFUSED"
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION=""; REPO=""; URL=""; MESSAGE=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) [ $# -ge 2 ] || refuse "--repo needs a value"; REPO="$2"; shift 2 ;;
    --url) [ $# -ge 2 ] || refuse "--url needs a value"; URL="$2"; shift 2 ;;
    --message) [ $# -ge 2 ] || refuse "--message needs a value"; MESSAGE="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --force|-f) refuse "--force is never accepted" ;;
    -*) refuse "unknown option: $1" ;;
    *)
      [ -z "$VERSION" ] || refuse "too many arguments: $1"
      VERSION="$1"; shift ;;
  esac
done
[ -n "$VERSION" ] || {
  echo "usage: publish-tag.sh <vX.Y.Z> [--repo <absolute repository path>] [--url <origin url>] [--message <text>] [--dry-run]" >&2
  exit 1
}

# 1. The version.
printf '%s' "$VERSION" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' \
  || refuse "invalid version '$VERSION' (expected vX.Y.Z)"

# 2. The repository: the laboratory this tool sits in, unless --repo says
#    otherwise. An explicit --repo is held to the absolute-path rule (100419).
if [ -n "$REPO" ]; then
  case "$REPO" in
    /*|[A-Za-z]:/*|[A-Za-z]:\\*) ;;
    *) refuse "repository path is not absolute: '$REPO' (write it in full, e.g. C:/Users/<you>/Workspaces/vault)" ;;
  esac
  [ -d "$REPO" ] || refuse "no such folder: $REPO"
else
  REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || refuse "$REPO is in no Git repository"
[ -z "$(git -C "$REPO" rev-parse --show-prefix 2>/dev/null)" ] \
  || refuse "$REPO is not the root of its repository ($(git -C "$REPO" rev-parse --show-toplevel))"
G() { git -C "$REPO" "$@"; }

# 3. A laboratory: both remotes.
RELEASE_URL="$(G remote get-url --push release 2>/dev/null)" \
  || refuse "$REPO has no release remote: it is not a laboratory, there is nothing to publish from it"
ORIGIN_URL="$(G remote get-url --push origin 2>/dev/null)" \
  || refuse "$REPO has no origin remote: the tag of a published version goes to both"

# 4. origin pushes to the declared URL (same check as tools/verified-push.sh).
if [ -z "$URL" ]; then
  if [ -f "$REPO/VAULT-IDENTITY.md" ]; then
    URL="$(tr -d '\r' < "$REPO/VAULT-IDENTITY.md" | sed -n 's/^vault_origin:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' | head -n 1)"
  fi
  [ -n "$URL" ] || refuse "$REPO declares no remote (no vault_origin in VAULT-IDENTITY.md): pass --url <expected url>"
fi
norm_url() {
  local u="$1"
  if [ -d "$u" ]; then u="$(cd "$u" && { pwd -W 2>/dev/null || pwd; })"; fi
  printf '%s' "$u" | tr '\\' '/' | sed -e 's#/*$##' -e 's#\.git$##'
}
[ "$(norm_url "$ORIGIN_URL")" = "$(norm_url "$URL")" ] \
  || refuse "remote 'origin' pushes to $ORIGIN_URL, not to the declared $URL"

# 5. The commit to tag: the head of the local branch `publish`.
COMMIT="$(G rev-parse --verify --quiet 'refs/heads/publish^{commit}')" \
  || refuse "no local branch 'publish' in $REPO: run tools/publish-from-laboratory.sh first"

# 6. That commit is what release/main reads on the remote.
RELEASE_MAIN="$(G ls-remote release refs/heads/main 2>/dev/null | awk 'NR==1{print $1}')"
[ -n "$RELEASE_MAIN" ] || refuse "cannot read refs/heads/main on 'release' (network, or no such branch)"
[ "$RELEASE_MAIN" = "$COMMIT" ] \
  || refuse "release/main reads ${RELEASE_MAIN%"${RELEASE_MAIN#???????}"}, not the head of publish (${COMMIT%"${COMMIT#???????}"}): publish it before tagging it"

# 7. The tag is on neither remote.
for remote in release origin; do
  ON="$(G ls-remote --tags "$remote" "refs/tags/$VERSION" 2>/dev/null)" \
    || refuse "git ls-remote --tags $remote failed: $VERSION could not be checked"
  [ -z "$ON" ] || refuse "$VERSION already exists on '$remote': a published version is never republished"
done

# 8. A local tag of that name names that same commit.
LOCAL="$(G rev-parse --verify --quiet "refs/tags/$VERSION^{commit}")" || LOCAL=""
if [ -n "$LOCAL" ] && [ "$LOCAL" != "$COMMIT" ]; then
  refuse "$VERSION already exists locally on ${LOCAL%"${LOCAL#???????}"}, not on the head of publish (${COMMIT%"${COMMIT#???????}"})"
fi

if [ "$DRY" = 1 ]; then
  echo "PUBLISH-TAG: release $RELEASE_URL, origin $ORIGIN_URL"
  echo "WOULD-TAG $VERSION $COMMIT"
  exit 0
fi

if [ -z "$LOCAL" ]; then
  G tag -a "$VERSION" -m "${MESSAGE:-$VERSION}" "$COMMIT" || refuse "git tag failed"
  echo "PUBLISH-TAG: annotated tag $VERSION created on ${COMMIT%"${COMMIT#???????}"}"
fi

for remote in release origin; do
  G push "$remote" "refs/tags/$VERSION" || refuse "git push $remote refs/tags/$VERSION failed"
  AFTER="$(G ls-remote --tags "$remote" "refs/tags/$VERSION^{}" 2>/dev/null | awk 'NR==1{print $1}')"
  [ -n "$AFTER" ] || AFTER="$(G ls-remote --tags "$remote" "refs/tags/$VERSION" 2>/dev/null | awk 'NR==1{print $1}')"
  echo "ls-remote --tags $remote refs/tags/$VERSION: $AFTER"
  [ "$AFTER" = "$COMMIT" ] \
    || { echo "PUBLISH-TAG-MISMATCH: '$remote' reads $AFTER for $VERSION after the push, not $COMMIT" >&2; exit 1; }
done

echo "TAGGED $VERSION $COMMIT"
exit 0
