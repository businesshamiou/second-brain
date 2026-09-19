#!/usr/bin/env bash
# Publishes the laboratory Vault to its `release` remote (Decision 210904 A,
# Mission 192) -- the one command that replaces the manual mechanics of
# report 191-C01 section 2.
#
# The laboratory's history and release's history are unrelated by
# construction: `main` is never a fast-forward of `release/main`. The local
# branch `publish` follows `release/main`; each publication is ONE commit on
# top of it carrying the tree of the laboratory's `main`, EXCEPT the closed
# list below, kept exactly as it is on `release`. Indexes are rebuilt on the
# published tree (in a folder named `second-brain`: index titles derive from
# it), the private-pattern check and the ten guardians run on `publish`, and
# `git push release publish:main` goes out as a fast-forward -- never
# --force. The tag is not this tool's job: it is posed after a green run.
#
# Refusals, nothing pushed: not a laboratory (no `release` remote); run from
# anything but the laboratory's `main` (never from `publish` itself);
# uncommitted changes in the laboratory; `release/main` advanced by a third
# party (the publication would not be a fast-forward); `publish` checked out
# in another worktree; any argument that would widen the closed list.
# Idempotent: a laboratory already published gives "nothing to publish",
# exit 0, nothing pushed.
#
# usage: publish-from-laboratory.sh [--message-file <file>]
# Last line: PUBLISHED <commit> | NOTHING-TO-PUBLISH | REFUSED

set -u

# --- Closed list: laboratory-local paths, kept as they are on `release` -----
# The laboratory's own identity, and its registry and project sheets (the
# Owner's projects, adopted by the laboratory). Adding a path is a Mission
# (Decision 210904 A2); no argument can extend this list.
KEEP_FROM_RELEASE=(
  "VAULT-IDENTITY.md"
  "projects"
)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAB="$(cd "$SCRIPT_DIR/.." && pwd)"
WS="$(cd "$LAB/.." && pwd)"
PUB="$WS/m-publish/second-brain"
MESSAGE_FILE=""

say() { echo "PUBLISH: $*"; }
refuse() {
  echo "REFUS : $*" >&2
  echo "REFUSED"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --message-file)
      [ $# -ge 2 ] || refuse "--message-file sans fichier"
      MESSAGE_FILE="$2"; shift 2 ;;
    *) refuse "argument non reconnu : $1 -- la liste close (${KEEP_FROM_RELEASE[*]}) ne s'etend pas par argument (Decision 210904 A2)" ;;
  esac
done
if [ -n "$MESSAGE_FILE" ]; then
  [ -f "$MESSAGE_FILE" ] || refuse "fichier de message introuvable : $MESSAGE_FILE"
  MESSAGE_FILE="$(cd "$(dirname "$MESSAGE_FILE")" && pwd)/$(basename "$MESSAGE_FILE")"
fi

L() { git -C "$LAB" "$@"; }

# --- Preconditions -----------------------------------------------------------
L remote get-url release >/dev/null 2>&1 || refuse "$LAB n'a pas de distant release : ce n'est pas un laboratoire"
[ "$(L branch --show-current)" = "main" ] || refuse "l'outil se lance depuis le main du laboratoire (branche courante : $(L branch --show-current || echo detachee)), jamais depuis publish"
[ -z "$(L status --porcelain)" ] || refuse "le laboratoire porte des changements non commites"
L fetch --quiet release || refuse "git fetch release a echoue"
RELEASE_HEAD="$(L rev-parse --verify --quiet refs/remotes/release/main)" || refuse "release/main introuvable"
if ! L rev-parse --verify --quiet refs/heads/publish >/dev/null; then
  L branch --quiet publish "$RELEASE_HEAD" || refuse "branche publish non creee"
  L branch --quiet --set-upstream-to=release/main publish >/dev/null 2>&1 || true
  say "branche publish creee sur release/main ($RELEASE_HEAD)"
fi
PUBLISH_HEAD="$(L rev-parse publish)"
# release/main must be publish or one of its ancestors: otherwise someone else
# advanced release/main and the push would not be a fast-forward.
L merge-base --is-ancestor "$RELEASE_HEAD" "$PUBLISH_HEAD" \
  || refuse "pas une avance rapide : release/main ($RELEASE_HEAD) n'est pas un ancetre de publish ($PUBLISH_HEAD) -- release a ete avance par un tiers ; rien n'est pousse, jamais --force"

# --- Publication worktree (recreated when absent, reset when present) -------
HOLDER="$(L worktree list --porcelain | awk -v pub="refs/heads/publish" '/^worktree /{w=substr($0,10)} $0=="branch " pub {print w}')"
if [ -n "$HOLDER" ]; then
  HOLDER_ABS="$(cd "$HOLDER" 2>/dev/null && pwd || printf '%s' "$HOLDER")"
  [ "$HOLDER_ABS" = "$PUB" ] || refuse "publish est deja extraite dans un autre worktree : $HOLDER (attendu : $PUB)"
else
  mkdir -p "$(dirname "$PUB")"
  L -c core.longpaths=true worktree add --quiet "$PUB" publish >/dev/null 2>&1 || refuse "worktree de publication non cree : $PUB"
  say "worktree de publication cree : $PUB"
fi
P() { git -C "$PUB" "$@"; }
P config core.longpaths true

LAB_HEAD="$(L rev-parse main)"
P read-tree -u --reset "$(L rev-parse 'main^{tree}')" || refuse "read-tree de l'arbre du laboratoire a echoue"
for keep in "${KEEP_FROM_RELEASE[@]}"; do
  # What release has at this path comes back as it is ...
  if P cat-file -e "$RELEASE_HEAD:$keep" 2>/dev/null; then
    P checkout --quiet "$RELEASE_HEAD" -- "$keep"
  fi
  # ... and what only the laboratory has there never leaves it.
  P ls-files -z -- "$keep" | tr '\0' '\n' | while IFS= read -r f; do
    [ -z "$f" ] && continue
    P cat-file -e "$RELEASE_HEAD:$f" 2>/dev/null || P rm --quiet -f -- "$f"
  done
done
bash "$PUB/tools/build-indexes.sh" "$PUB" >/dev/null 2>&1 || refuse "reconstruction des index a echoue"
# read-tree set the index to the laboratory's tree; the tool itself changes
# only the closed list and the rebuilt indexes: only those are staged, never
# a stray untracked file (preflight stamp, caches) of the worktree.
P add -A -- "${KEEP_FROM_RELEASE[@]}" ':(glob)**/index.md' ':(glob)**/index-archive*.md' || refuse "git add a echoue dans le worktree de publication"

if P diff --cached --quiet "$PUBLISH_HEAD"; then
  say "publish porte deja l'arbre du laboratoire ($LAB_HEAD)"
  if [ "$PUBLISH_HEAD" != "$RELEASE_HEAD" ]; then
    P push --quiet release publish:main || refuse "poussee de publish (en avance sur release/main) refusee"
    say "publish poussee : $RELEASE_HEAD..$PUBLISH_HEAD"
    echo "PUBLISHED $PUBLISH_HEAD"
    exit 0
  fi
  echo "NOTHING-TO-PUBLISH"
  exit 0
fi

# --- Checks on the published tree, then one guarded commit -------------------
bash "$PUB/tools/check-private-patterns.sh" --tree-only || refuse "motif prive dans l'arbre publie"
bash "$PUB/tools/session-preflight.sh" >/dev/null 2>&1 || true
if [ -n "$MESSAGE_FILE" ]; then
  P commit --quiet -F "$MESSAGE_FILE" || refuse "commit de publication refuse (gardiens)"
else
  P commit --quiet -m "Publish the laboratory's main $(L rev-parse --short main)" || refuse "commit de publication refuse (gardiens)"
fi
NEW="$(P rev-parse HEAD)"
say "commit de publication $NEW (laboratoire $LAB_HEAD), chemins gardes de release : ${KEEP_FROM_RELEASE[*]}"
P push --quiet release publish:main || refuse "poussee refusee (le commit $NEW reste sur publish, rien n'a atteint release)"
say "release/main : $RELEASE_HEAD..$NEW (avance rapide)"
echo "PUBLISHED $NEW"
exit 0
