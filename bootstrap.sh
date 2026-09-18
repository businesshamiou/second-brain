#!/usr/bin/env bash
# Second Brain bootstrap for macOS and Linux: installs without Git being
# present first (Mission 183-C01, Decision 142112 point 5 -- mirror of
# bootstrap.ps1).
#
# The published line used to start with `git clone`. This script is what
# the published line now downloads and runs:
#   1. if git is not on PATH:
#      - Linux: downloads the pinned static Git named in
#        tools/prerequisites.sh (read from the same origin as this script,
#        never copied here), checks its SHA-256 and extracts it where
#        install.sh's prerequisites step looks for it
#        ($HOME/.local/share/second-brain/git-linux64, or under
#        --test-root/profile in test mode);
#      - macOS: Git comes with Apple's Command Line Tools; the request is
#        made (Apple's own dialog, no administrator password) and the
#        bootstrap asks to run the line again once they are installed;
#   2. brings <target> to --ref with that git, PATH untouched: a fresh
#      clone when the folder is absent, otherwise fetch + checkout on the
#      clone already there, with HEAD proven equal to --ref (Mission
#      185-C01, gate 1 -- a leftover temp clone used to be installed as is);
#   3. runs the cloned install.sh --source <target>, which adds Git to the
#      user's PATH itself.
# Nothing here uses sudo.
#
# Published line (INSTALL.md):
#   curl -fsSL https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.7/bootstrap.sh | bash
#
# usage: bootstrap.sh [--ref <tag-or-branch>] [--repo-url <url-or-path>]
#                     [--raw-base <url-or-directory>] [--target <dir>]
#                     [--answers-file <path>] [--test-mode --test-root <dir>]
#                     [--stop-after-step <name>]

set -u

REF="v0.1.7"
REPO_URL="https://github.com/businesshamiou/second-brain.git"
RAW_BASE=""
TARGET=""
ANSWERS_FILE=""
TEST_MODE=0
TEST_ROOT=""
STOP_AFTER_STEP=""

stop() {
  echo "Second Brain bootstrap stopped: $1"
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ref) REF="${2:-}"; shift 2 ;;
    --repo-url) REPO_URL="${2:-}"; shift 2 ;;
    --raw-base) RAW_BASE="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --answers-file) ANSWERS_FILE="${2:-}"; shift 2 ;;
    --test-mode) TEST_MODE=1; shift ;;
    --test-root) TEST_ROOT="${2:-}"; shift 2 ;;
    # Test-only, relayed as is to install.sh (same plumbing as
    # --test-mode): tests/test-bootstrap-stale-temp-clone.sh measures the clone
    # step on three systems without paying for a full installation per
    # system.
    --stop-after-step) STOP_AFTER_STEP="${2:-}"; shift 2 ;;
    *) stop "unknown argument: $1" ;;
  esac
done

if [ "$TEST_MODE" = "1" ] && [ -z "$TEST_ROOT" ]; then
  stop "--test-root is required with --test-mode."
fi
[ -n "$RAW_BASE" ] || RAW_BASE="https://raw.githubusercontent.com/businesshamiou/second-brain/$REF"
if [ "$TEST_MODE" = "1" ]; then
  PROFILE_ROOT="$TEST_ROOT/profile"
  [ -n "$TARGET" ] || TARGET="$TEST_ROOT/second-brain-install"
else
  PROFILE_ROOT="$HOME"
  [ -n "$TARGET" ] || TARGET="${TMPDIR:-/tmp}/second-brain-install"
fi

fetch() {
  # $1 = path relative to RAW_BASE, $2 = destination file.
  if [ -d "$RAW_BASE" ]; then
    cp "$RAW_BASE/$1" "$2"
  else
    curl -fsSL -o "$2" "$RAW_BASE/$1"
  fi
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'  # portability: guarded by command -v
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

GIT_BIN=""
if command -v git >/dev/null 2>&1; then
  GIT_BIN="$(command -v git)"
elif [ "$(uname -s)" = "Darwin" ]; then
  xcode-select --install >/dev/null 2>&1 || true
  stop "Git comes with Apple's Command Line Tools: finish the installation Apple just offered, then run the same line again."
else
  TOOLS_ROOT="$PROFILE_ROOT/.local/share/second-brain"
  GIT_ROOT="$TOOLS_ROOT/git-linux64"
  mkdir -p "$TOOLS_ROOT/downloads" || stop "cannot create $TOOLS_ROOT"
  PREREQ_COPY="$TOOLS_ROOT/downloads/prerequisites.sh"
  fetch "tools/prerequisites.sh" "$PREREQ_COPY" || stop "cannot read tools/prerequisites.sh from $RAW_BASE"
  ASSET="$(sed -n 's/^SB_GIT_LINUX64_ASSET="\(.*\)"$/\1/p' "$PREREQ_COPY")"
  URL="$(sed -n 's/^SB_GIT_LINUX64_URL="\(.*\)"$/\1/p' "$PREREQ_COPY")"
  SHA="$(sed -n 's/^SB_GIT_LINUX64_SHA256="\(.*\)"$/\1/p' "$PREREQ_COPY")"
  [ -n "$ASSET" ] && [ -n "$URL" ] && [ -n "$SHA" ] || stop "the pinned Git entry could not be read from tools/prerequisites.sh"
  ARCHIVE="$TOOLS_ROOT/downloads/$ASSET"
  if [ ! -f "$ARCHIVE" ] || [ "$(sha256_of "$ARCHIVE")" != "$SHA" ]; then
    echo "Downloading Git (static build, into your profile)..."
    curl -fsSL -o "$ARCHIVE" "$URL" || stop "Git download failed: $URL"
  fi
  ACTUAL="$(sha256_of "$ARCHIVE")"
  [ "$ACTUAL" = "$SHA" ] || stop "the downloaded Git archive does not match its pinned SHA-256 (expected $SHA, got $ACTUAL)."
  if [ ! -x "$GIT_ROOT/git" ]; then
    mkdir -p "$GIT_ROOT"
    tar -xzf "$ARCHIVE" -C "$GIT_ROOT" || stop "Git could not be extracted into $GIT_ROOT"
    chmod +x "$GIT_ROOT"/* 2>/dev/null || true
  fi
  [ -x "$GIT_ROOT/git" ] || stop "git is missing after extraction: $GIT_ROOT/git"
  GIT_BIN="$GIT_ROOT/git"
fi

# Two spellings of the SAME origin must not read as two
# origins: a test clone is given by a path, a URL carries or not
# its .git suffix and a trailing slash. Under Git Bash (Windows), the
# comparison ignores case, like the file system.
normalize_repo_url() {
  NRU_V="$(printf '%s' "$1" | tr '\\' '/')"
  while [ "${NRU_V%/}" != "$NRU_V" ]; do NRU_V="${NRU_V%/}"; done
  NRU_V="${NRU_V%.git}"
  while [ "${NRU_V%/}" != "$NRU_V" ]; do NRU_V="${NRU_V%/}"; done
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) printf '%s' "$NRU_V" | tr '[:upper:]' '[:lower:]' ;;
    *) printf '%s' "$NRU_V" ;;
  esac
}

# canon_dir <path>: canonical form of a local FOLDER, or nothing if
# the argument is not one. Under Git Bash, `/tmp/x` and
# `C:/Users/.../Temp/x` are the same folder under two names, and
# `git clone` records the origin in the native form while the line
# may have given it in the POSIX form: without this step, the same folder would
# read as two repositories and the line would refuse wrongly (measured by
# tests/test-bootstrap-stale-temp-clone.sh).
canon_dir() {
  [ -d "$1" ] || return 1
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1" 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]'
  else
    (cd "$1" 2>/dev/null && pwd -P)
  fi
}

# same_repo_url <origin read> <origin requested>: 0 if both name the
# same repository. Text comparison first (the ordinary case: a URL),
# then folder comparison when both are local.
same_repo_url() {
  [ "$(normalize_repo_url "$1")" = "$(normalize_repo_url "$2")" ] && return 0
  SRU_A="$(canon_dir "$1")" || return 1
  SRU_B="$(canon_dir "$2")" || return 1
  [ -n "$SRU_A" ] && [ "$SRU_A" = "$SRU_B" ]
}

if [ -d "$TARGET/.git" ]; then
  # A clone ALREADY present is the ordinary case of a machine that has already
  # run the published line: the temporary folder survives from one time to the next.
  # Until Mission 185-C01 this whole block was skipped as soon as .git
  # existed, and the installer ran the commit that this forgotten folder
  # was on -- measured on the Owner's machine (capture
  # 2026-09-17-144137, door 1): a commit older than any tag,
  # installed with a clean verdict. The folder is now brought to
  # --ref: same origin, fetch, checkout, then HEAD proven equal to --ref.
  # Never --force, never a deletion: a mismatch refuses and names the
  # folder to move aside.
  # `config --get` rather than `remote get-url`: silent when the remote
  # is missing (code 1, nothing on standard error).
  EXISTING_ORIGIN="$("$GIT_BIN" -C "$TARGET" config --get remote.origin.url 2>/dev/null | head -n 1)"
  if ! same_repo_url "$EXISTING_ORIGIN" "$REPO_URL"; then
    stop "$TARGET is a clone of '$EXISTING_ORIGIN', not of '$REPO_URL'; move $TARGET aside and run the line again."
  fi
  "$GIT_BIN" -C "$TARGET" fetch --quiet --tags origin \
    || stop "git fetch of $REPO_URL failed in $TARGET; move $TARGET aside and run the line again."
  # A tag first, then the tracking branch, then a commit
  # id: a stale LOCAL branch named `main` must never
  # prevail over what the fetch just brought back.
  WANTED=""
  for CANDIDATE in "refs/tags/$REF^{commit}" "refs/remotes/origin/$REF^{commit}" "$REF^{commit}"; do
    WANTED="$("$GIT_BIN" -C "$TARGET" rev-parse --verify --quiet "$CANDIDATE" | head -n 1)"
    [ -n "$WANTED" ] && break
  done
  [ -n "$WANTED" ] || stop "$REF does not exist in $REPO_URL; nothing was installed."
  "$GIT_BIN" -C "$TARGET" -c advice.detachedHead=false checkout --quiet --detach "$WANTED" \
    || stop "$REF could not be checked out in $TARGET; move $TARGET aside and run the line again."
  HEAD_NOW="$("$GIT_BIN" -C "$TARGET" rev-parse HEAD | head -n 1)"
  [ "$HEAD_NOW" = "$WANTED" ] \
    || stop "$TARGET is at $HEAD_NOW, not at $REF ($WANTED); move $TARGET aside and run the line again."
else
  [ -e "$TARGET" ] && stop "$TARGET exists but is not a Git repository; move it aside and run the line again."
  # --no-checkout, then checkout: --ref may be a branch, a tag or a commit
  # id (CI plays the exact commit under test), which `clone --branch`
  # does not accept.
  "$GIT_BIN" clone --quiet --no-checkout "$REPO_URL" "$TARGET" || stop "git clone of $REPO_URL failed."
  "$GIT_BIN" -C "$TARGET" -c advice.detachedHead=false checkout --quiet "$REF" \
    || stop "$REF could not be checked out from $REPO_URL."
fi

set -- --source "$TARGET"
[ -n "$ANSWERS_FILE" ] && set -- "$@" --answers-file "$ANSWERS_FILE"
[ "$TEST_MODE" = "1" ] && set -- "$@" --test-mode --test-root "$TEST_ROOT"
[ -n "$STOP_AFTER_STEP" ] && set -- "$@" --stop-after-step "$STOP_AFTER_STEP"
bash "$TARGET/install.sh" "$@"
exit $?
