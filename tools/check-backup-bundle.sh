#!/usr/bin/env bash
# Backup oracle for a Git bundle (Decision 210904, Mission 192).
#
# `git bundle verify` reads the bundle's header and checks its prerequisites;
# it does NOT check the pack that follows: a bundle truncated in the middle of
# its pack still verifies (measured, Mission 190, P1). A backup is proven
# only by restoring it: this oracle verifies the header, then fetches every
# ref of the bundle into a throwaway repository -- index-pack checks the whole
# pack on the way in -- and runs `git fsck` there. Read-only for the bundle;
# the throwaway repository is removed at the end.
#
# usage: check-backup-bundle.sh <file.bundle>
# Output: the refs restored, then PASS or FAIL with its cause. Exit 0 = PASS.

set -u

BUNDLE="${1:-}"
if [ -z "$BUNDLE" ] || [ ! -f "$BUNDLE" ]; then
  echo "usage: check-backup-bundle.sh <fichier.bundle>" >&2
  echo "FAIL : bundle introuvable : ${BUNDLE:-(vide)}"
  exit 1
fi
BUNDLE="$(cd "$(dirname "$BUNDLE")" && pwd)/$(basename "$BUNDLE")"

T="$(mktemp -d "${TMPDIR:-/tmp}/sb-bundle-check-XXXXXX")" || exit 1
trap 'rm -rf "$T"' EXIT
git init -q "$T/r" || { echo "FAIL : depot jetable non cree"; exit 1; }

if ! git -C "$T/r" bundle verify -q "$BUNDLE" >/dev/null 2>&1; then
  echo "FAIL : en-tete du bundle invalide (git bundle verify)"
  exit 1
fi
if ! git -C "$T/r" fetch -q "$BUNDLE" 'refs/*:refs/restored/*' >/dev/null 2>&1; then
  echo "FAIL : pack illisible ou tronque (la restauration par fetch echoue)"
  exit 1
fi
N="$(git -C "$T/r" for-each-ref refs/restored | wc -l | tr -d ' ')"
if [ "$N" = "0" ]; then
  echo "FAIL : aucune reference restauree"
  exit 1
fi
if ! git -C "$T/r" fsck --no-dangling >/dev/null 2>&1; then
  echo "FAIL : objets incoherents apres restauration (git fsck)"
  exit 1
fi
git -C "$T/r" for-each-ref --format='  %(objectname:short) %(refname)' refs/restored
echo "PASS : $N reference(s) restauree(s), pack et objets verifies"
exit 0
