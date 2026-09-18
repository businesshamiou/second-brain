#!/usr/bin/env bash
# Checks distribution-manifest.txt (at the root of this repository) against the real state of the repository.
# Read-only: never fixes a defect it finds, only refuses
# and lists it. Wired into no hook (Mission 073, arbitration C) --
# manual run only, result reported by the caller.
#
# Refuses (exit 1) if any of these conditions holds:
#   1. a file of `git ls-files` is missing from the manifest;
#   2. a path of the manifest no longer exists in `git ls-files`;
#   3. a path appears twice in the manifest;
#   4. a verdict is neither DISTRIBUABLE nor INTERNE;
#   5. a file carries `distributable: false` in front-matter while the
#      manifest classes it DISTRIBUABLE, or the reverse (`distributable: true`
#      while the manifest classes it INTERNE).
#
# usage: check-distribution-manifest.sh

set -u

# Git guard (Mission 125, same reason as in check-secrets.sh): explicit
# refusal outside a repository, rather than an empty $VAULT_ROOT.
VAULT_ROOT="$(git rev-parse --show-toplevel)" || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}
MANIFEST="$VAULT_ROOT/distribution-manifest.txt"

if [ ! -f "$MANIFEST" ]; then
  echo "REFUS : manifeste introuvable : $MANIFEST" >&2
  exit 1
fi

FAIL=0
DISTRIBUABLE_COUNT=0
INTERNE_COUNT=0

# Tab computed only once (Mission 127): "IFS=\"\$(printf '\t')\""
# repeated in the condition of a while relaunches that subprocess at EACH
# iteration (~400 manifest lines) -- measured as the second dominant
# cost once the per-line pipeline of step 4/5 was removed.
TAB="$(printf '\t')"

TRACKED_FILE="$(mktemp)"
MANIFEST_PATHS_FILE="$(mktemp)"
FM_DIST_FILE="$(mktemp)"
trap 'rm -f "$TRACKED_FILE" "$MANIFEST_PATHS_FILE" "$FM_DIST_FILE"' EXIT

# `skills-warehouse/` outside the perimeter (Mission 168, Owner arbitration
# 2026-09-11, option c): subtree adopted as is (T24), never subject to the
# Vault's distribution manifest -- its own provenance standards
# (AGENTS.md, PROVENANCE.md per package) stand in for it.
#
# Project sheets (`projects/PROJECT-<date>-<code>.md`) outside the perimeter
# (Mission 168, ticket 03): written by tools/project-bootstrap.sh after
# installation, one per project created on each user's machine --
# never content of the distributed repository itself. The manifest describes the state
# at the time of distribution (registry v1 D1b); the register and the index of
# `projects/` do remain real lines of the manifest (distributed
# skeletons, ticket 01) -- only the sheets born AFTERWARDS are
# exempted, same principle as the skills-warehouse exemption above.
#
# Assistant forms (Mission 168, ticket 06): tools/generate-assistant.ps1
# writes .claude/agents/<slug>.md, .agents/skills/<slug>/ and
# web-package/<slug>/ at installation, under an identifier derived from the name
# chosen by the participant -- never a fixed path that the manifest
# could list in advance (the name, hence the slug, does not exist before
# someone installs). A rename moves these same forms, under the old
# slug, to _trash/assistant-rename-<old slug>-<timestamp>/ (Move-
# AssistantFormsToTrash, same ticket): same reason, exempted the same way.
# Same principle and same reason as the projects/PROJECT-*.md exemption
# above: content born on the user's machine, never content of the
# distributed repository itself.
git -C "$VAULT_ROOT" ls-files \
  | grep -v '^skills-warehouse/' \
  | grep -vE '^projects/PROJECT-[0-9]{4}-[0-9]{2}-[0-9]{2}-.*\.md$' \
  | grep -vE '^\.claude/agents/.*\.md$' \
  | grep -vE '^\.agents/skills/.*$' \
  | grep -vE '^web-package/.*$' \
  | grep -vE '^_trash/assistant-rename-.*$' \
  | sort > "$TRACKED_FILE"
cut -f1 "$MANIFEST" | sort > "$MANIFEST_PATHS_FILE"

# Grouped pre-pass (Mission 127): a single awk process over all the
# existing files of the manifest, instead of a head|grep|awk|tr pipeline per
# line (up to ~400 x 4 processes) -- process forking dominates the cost
# under Git Bash/Windows, same diagnosis and same pattern as
# tools/build-indexes.sh. Identical behaviour: same first 20 lines
# of each file, same exact pattern `^distributable:[[:space:]]*(true|false)[[:space:]]*$`,
# same first match kept (grep -m1) -- measured by the oracle of Mission 127
# (byte-identical output before/after).
EXISTING_PATHS=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  [ -f "$VAULT_ROOT/$p" ] && EXISTING_PATHS="$EXISTING_PATHS
$p"
done < <(cut -f1 "$MANIFEST")

# The table goes through a temp file, never a here-document: its size is
# (install path length + file path) x ~500 lines, and Git Bash's bash 5.3
# deadlocks for good on a here-document between 65537 and ~65690 bytes --
# reached by an install path of about 71 characters.
# Paths are prefixed in bash, never by `sed "s#^#$VAULT_ROOT/#"`: sed reads
# the root as a replacement, so an `&` in it becomes the matched text and a
# backslash an escape -- an empty table, and the front-matter check silently
# skipped (Mission 181, step 6 resumed, smoke test).
printf '%s\n' "$EXISTING_PATHS" | while IFS= read -r p; do
  [ -n "$p" ] && printf '%s/%s\0' "$VAULT_ROOT" "$p"
done | xargs -0 awk '
  function flush() { if (cur != "") print cur "\t" distv }
  FNR==1 { flush(); cur=FILENAME; distv="" }
  FNR<=20 && distv=="" && $0 ~ /^distributable:[[:space:]]*(true|false)[[:space:]]*$/ {
    v=$0; sub(/^distributable:[[:space:]]*/,"",v); gsub(/[[:space:]]+$/,"",v); distv=v
  }
  END { flush() }
' > "$FM_DIST_FILE" 2>/dev/null

# One line per file, emitted on change of file and in END: ENDFILE
# is a gawk extension that Apple's awk ignores -- empty table, and the
# front-matter/manifest consistency was no longer checked (Mission 181).
# Portable map (tools/kvmap.sh): `declare -A` does not exist in the
# bash 3.2 shipped by Apple.
. "$(dirname "$0")/kvmap.sh"
while IFS="$TAB" read -r fpath fdist; do
  [ -z "$fpath" ] && continue
  kv_set FM_DIST "${fpath#"$VAULT_ROOT"/}" "$fdist"
done < "$FM_DIST_FILE"

# --- 1. tracked file missing from the manifest ---
MISSING_FROM_MANIFEST="$(comm -23 "$TRACKED_FILE" "$MANIFEST_PATHS_FILE")"
if [ -n "$MISSING_FROM_MANIFEST" ]; then
  FAIL=1
  echo "ABSENT-DU-MANIFESTE : fichier suivi sans ligne au manifeste :" >&2
  printf '%s\n' "$MISSING_FROM_MANIFEST" | while IFS= read -r f; do
    echo "  $f" >&2
  done
fi

# --- 2. manifest path that no longer exists in git ls-files ---
STALE_IN_MANIFEST="$(comm -13 "$TRACKED_FILE" "$MANIFEST_PATHS_FILE")"
if [ -n "$STALE_IN_MANIFEST" ]; then
  FAIL=1
  echo "FANTOME-AU-MANIFESTE : chemin du manifeste non suivi par Git :" >&2
  printf '%s\n' "$STALE_IN_MANIFEST" | while IFS= read -r f; do
    echo "  $f" >&2
  done
fi

# --- 3. duplicate path in the manifest ---
DUPLICATES="$(cut -f1 "$MANIFEST" | sort | uniq -d)"
if [ -n "$DUPLICATES" ]; then
  FAIL=1
  echo "DOUBLON-AU-MANIFESTE : chemin present plus d'une fois :" >&2
  printf '%s\n' "$DUPLICATES" | while IFS= read -r f; do
    echo "  $f" >&2
  done
fi

# --- 4/5. verdict and distributable: consistency ---
LINE_NO=0
while IFS="$TAB" read -r REL_PATH VERDICT || [ -n "$REL_PATH" ]; do
  LINE_NO=$((LINE_NO + 1))
  [ -z "$REL_PATH" ] && continue

  case "$VERDICT" in
    DISTRIBUABLE) DISTRIBUABLE_COUNT=$((DISTRIBUABLE_COUNT + 1)) ;;
    INTERNE) INTERNE_COUNT=$((INTERNE_COUNT + 1)) ;;
    *)
      FAIL=1
      echo "VERDICT-INVALIDE : ligne $LINE_NO, $REL_PATH : verdict '$VERDICT' ni DISTRIBUABLE ni INTERNE" >&2
      continue
      ;;
  esac

  FULL="$VAULT_ROOT/$REL_PATH"
  [ -f "$FULL" ] || continue

  kv_get FM_DIST "$REL_PATH"; FM_DISTRIBUTABLE="$KV_VALUE"

  if [ "$FM_DISTRIBUTABLE" = "false" ] && [ "$VERDICT" = "DISTRIBUABLE" ]; then
    FAIL=1
    echo "INCOHERENCE-DISTRIBUTABLE : $REL_PATH porte 'distributable: false' en front-matter mais le manifeste le classe DISTRIBUABLE" >&2
  fi
  if [ "$FM_DISTRIBUTABLE" = "true" ] && [ "$VERDICT" = "INTERNE" ]; then
    FAIL=1
    echo "INCOHERENCE-DISTRIBUTABLE : $REL_PATH porte 'distributable: true' en front-matter mais le manifeste le classe INTERNE" >&2
  fi
done < "$MANIFEST"

echo "Comptes : DISTRIBUABLE=$DISTRIBUABLE_COUNT INTERNE=$INTERNE_COUNT TOTAL=$((DISTRIBUABLE_COUNT + INTERNE_COUNT))"

if [ "$FAIL" -ne 0 ]; then
  echo "REFUS : le manifeste ne passe pas les controles ci-dessus." >&2
  exit 1
fi

exit 0
