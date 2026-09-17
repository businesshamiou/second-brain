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
#   curl -fsSL https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.4/bootstrap.sh | bash
#
# usage: bootstrap.sh [--ref <tag-or-branch>] [--repo-url <url-or-path>]
#                     [--raw-base <url-or-directory>] [--target <dir>]
#                     [--answers-file <path>] [--test-mode --test-root <dir>]
#                     [--stop-after-step <name>]

set -u

REF="v0.1.4"
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
    # Test-only, relaye tel quel a install.sh (meme plomberie que
    # --test-mode) : tests/test-bootstrap-stale-temp-clone.sh mesure l'etape
    # de clone sur trois systemes sans payer une installation complete par
    # systeme.
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

# Deux ecritures de la MEME origine ne doivent pas se lire comme deux
# origines : un clone de test est donne par un chemin, une URL porte ou non
# son suffixe .git et une barre finale. Sous Git Bash (Windows), la
# comparaison ignore la casse, comme le systeme de fichiers.
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

# canon_dir <chemin> : forme canonique d'un DOSSIER local, ou rien si
# l'argument n'en est pas un. Sous Git Bash, `/tmp/x` et
# `C:/Users/.../Temp/x` sont le meme dossier sous deux noms, et
# `git clone` enregistre l'origine dans la forme native alors que la ligne
# a pu la donner dans la forme POSIX : sans ce passage, le meme dossier se
# lirait comme deux depots et la ligne refuserait a tort (mesure par
# tests/test-bootstrap-stale-temp-clone.sh).
canon_dir() {
  [ -d "$1" ] || return 1
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1" 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]'
  else
    (cd "$1" 2>/dev/null && pwd -P)
  fi
}

# same_repo_url <origine lue> <origine demandee> : 0 si les deux nomment le
# meme depot. Comparaison de texte d'abord (le cas ordinaire : une URL),
# puis comparaison de dossiers quand les deux sont locaux.
same_repo_url() {
  [ "$(normalize_repo_url "$1")" = "$(normalize_repo_url "$2")" ] && return 0
  SRU_A="$(canon_dir "$1")" || return 1
  SRU_B="$(canon_dir "$2")" || return 1
  [ -n "$SRU_A" ] && [ "$SRU_A" = "$SRU_B" ]
}

if [ -d "$TARGET/.git" ]; then
  # Un clone DEJA present est le cas ordinaire d'un poste qui a deja joue la
  # ligne publiee : le dossier temporaire survit d'une fois sur l'autre.
  # Jusqu'a la Mission 185-C01 ce bloc entier etait saute des que .git
  # existait, et l'installeur jouait le commit sur lequel ce dossier oublie
  # se trouvait -- mesure sur le poste de l'Owner (capture
  # 2026-09-17-144137, porte 1) : un commit anterieur a toute etiquette,
  # installe avec un verdict propre. Le dossier est desormais amene a
  # --ref : meme origine, fetch, checkout, puis HEAD prouve egal a --ref.
  # Jamais --force, jamais de suppression : un ecart refuse et nomme le
  # dossier a ecarter.
  # `config --get` plutot que `remote get-url` : silencieux quand le remote
  # manque (code 1, rien sur la sortie d'erreur).
  EXISTING_ORIGIN="$("$GIT_BIN" -C "$TARGET" config --get remote.origin.url 2>/dev/null | head -n 1)"
  if ! same_repo_url "$EXISTING_ORIGIN" "$REPO_URL"; then
    stop "$TARGET is a clone of '$EXISTING_ORIGIN', not of '$REPO_URL'; move $TARGET aside and run the line again."
  fi
  "$GIT_BIN" -C "$TARGET" fetch --quiet --tags origin \
    || stop "git fetch of $REPO_URL failed in $TARGET; move $TARGET aside and run the line again."
  # Une etiquette d'abord, puis la branche de suivi, puis un identifiant de
  # commit : une branche LOCALE perimee nommee `main` ne doit jamais
  # l'emporter sur ce que le fetch vient de rapporter.
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
