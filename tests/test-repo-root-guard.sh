#!/usr/bin/env bash
# Mission 226: the repository-root guard (tools/repo_root_guard.py) replays the
# incident of 2026-09-21 and 2026-09-25 -- a writing tool launched with "."
# from the workspace root, a folder that holds several repositories without
# being one -- against every Vault tool that writes under a root chosen by its
# caller.
#
# Fixture: a throwaway workspace WS carrying VAULT-ROOT.md, a throwaway Vault
# (WS/second-brain, whose tools are the ones played), two repositories
# (WS/repo-a, WS/repo-b) and a folder without Git (WS/plain); a second
# workspace WS2 with two repositories and no marker. The four files of a
# published install line are copied into WS and WS/plain, so a tool without
# the guard would write there.
#
# For each tool, three launches from the fake workspace:
#   (1) "." from WS;  (2) "plain" from WS;  (3) ".." from WS/repo-a;
# plus (4) "." from WS2 (no marker, two repositories). Each must be refused:
# exit code != 0, REPO-ROOT-REFUSED on the output, and 0 file written or
# changed under WS / WS2 (the list of every file outside .git and __pycache__
# before and after, and no file newer than a stamp taken just before).
# project-bootstrap.sh (target: a new project folder, often in no repository)
# is played in its --new-project mode: WS itself, and a folder holding two
# repositories, are refused; its `prompt` subcommand (which rewrites a
# project's Pilot prompt) in the default mode: "." from WS is refused.
# Witnesses: the same tools on WS/repo-a (absolute path) write as before, and
# project-bootstrap.sh creates WS/newproj.
#
# usage: bash tests/test-repo-root-guard.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m226-guard-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/bin/pre-commit"
chmod +x "$TMP/bin/pre-commit"
PATH="$TMP/bin:$PATH"; export PATH

WS="$TMP/ws"; V="$WS/second-brain"; T="$V/tools"
mkdir -p "$WS"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$T/write-marker.sh" --marker-only "$WS" >/dev/null || { echo "FAIL : marqueur"; exit 1; }
for r in repo-a repo-b; do
  mkdir -p "$WS/$r" && git init -q "$WS/$r" && printf -- '---\ntype: note\nstatus: active\n---\n# %s\n' "$r" > "$WS/$r/note.md"
done
mkdir -p "$WS/plain" && printf -- '---\ntype: note\nstatus: active\n---\n# plain\n' > "$WS/plain/note.md"
for f in README.md INSTALL.md bootstrap.sh bootstrap.ps1; do
  cp "$REPO_ROOT/$f" "$WS/$f"; cp "$REPO_ROOT/$f" "$WS/plain/$f"; cp "$REPO_ROOT/$f" "$WS/repo-a/$f"
done
WS2="$TMP/ws2"
for r in one two; do mkdir -p "$WS2/$r" && git init -q "$WS2/$r"; done
printf -- '---\ntype: note\nstatus: active\n---\n# ws2\n' > "$WS2/note.md"
mkdir -p "$WS/multi/x" "$WS/multi/y" && git init -q "$WS/multi/x" && git init -q "$WS/multi/y"
MISSION="$TMP/MISSION-2026-01-01-000000-001-test.md"
printf -- '---\ntype: mission\nmission_id: "001"\n---\n# M\n' > "$MISSION"

# listing <dir>: the list of every file outside .git and __pycache__ (portable:
# no GNU find -printf). A write that keeps the list is caught by `newer`.
listing() {
  (cd "$1" && find . \( -name .git -o -name __pycache__ \) -prune -o -type f -print | LC_ALL=C sort | git hash-object --stdin)
}
newer() {
  find "$WS" "$WS2" \( -name .git -o -name __pycache__ \) -prune -o -type f -newer "$TMP/stamp" -print | head -n 1
}

# play <label> <cwd> <tool and arguments...>: refusal expected.
play() {
  local label="$1" cwd="$2"; shift 2
  local before1 before2 after1 after2 out rc
  local changed
  before1="$(listing "$WS")"; before2="$(listing "$WS2")"
  touch "$TMP/stamp"; sleep 1
  out="$(cd "$cwd" && "$@" 2>&1 </dev/null)"; rc=$?
  changed="$(newer)"
  after1="$(listing "$WS")"; after2="$(listing "$WS2")"
  [ -z "$changed" ] || after1="changed:$changed"
  if [ "$rc" != 0 ] && printf '%s' "$out" | grep -q 'REPO-ROOT-REFUSED' && [ "$before1" = "$after1" ] && [ "$before2" = "$after2" ]; then
    pass "$label : refus (rc=$rc), 0 fichier ecrit"
  else
    fail "$label : rc=$rc, refus nomme=$(printf '%s' "$out" | grep -c 'REPO-ROOT-REFUSED'), arbre WS $( [ "$before1" = "$after1" ] && echo intact || echo MODIFIE ), WS2 $( [ "$before2" = "$after2" ] && echo intact || echo MODIFIE ) -- $(printf '%s' "$out" | tail -n 2 | tr '\n' ' ' | cut -c1-200)"
  fi
}

# incident <name> <args-before-root...> -- <args-after-root...>
incident() {
  local name="$1"; shift
  local pre=() post=() seen=0 a
  for a in "$@"; do
    if [ "$a" = "--" ]; then seen=1; continue; fi
    if [ "$seen" = 0 ]; then pre+=("$a"); else post+=("$a"); fi
  done
  play "$name (1) '.' depuis l'espace de travail" "$WS" bash "$T/$name" ${pre[@]+"${pre[@]}"} . ${post[@]+"${post[@]}"}
  play "$name (2) 'plain' (sous-dossier sans Git)" "$WS" bash "$T/$name" ${pre[@]+"${pre[@]}"} plain ${post[@]+"${post[@]}"}
  play "$name (3) '..' depuis un depot" "$WS/repo-a" bash "$T/$name" ${pre[@]+"${pre[@]}"} .. ${post[@]+"${post[@]}"}
  play "$name (4) '.' depuis un espace sans marqueur, deux depots" "$WS2" bash "$T/$name" ${pre[@]+"${pre[@]}"} . ${post[@]+"${post[@]}"}
}

echo "=== Mission 226 : garde-fou de racine, incident rejoue ==="
incident build-indexes.sh --
incident append-journal.sh -- "STATE: incident replay"
incident build-state.sh --
incident build-digest.sh --
incident set-release-version.sh v9.9.9 --
incident vault-identity.sh ensure --
incident propose-link-repairs.sh -- --apply --mission "$MISSION"

play "project-bootstrap.sh create : la racine de l'espace de travail" "$WS" bash "$T/project-bootstrap.sh" create "$WS" "Ws" --vcs none --lang FR
play "project-bootstrap.sh adopt : un dossier qui contient deux depots" "$WS" bash "$T/project-bootstrap.sh" adopt "$WS/multi" "Multi" --vcs none --lang FR
play "project-bootstrap.sh prompt : '.' depuis l'espace de travail" "$WS" bash "$T/project-bootstrap.sh" prompt .

echo "=== Temoins : une racine de depot ecrit comme avant ==="
A="$WS/repo-a"
bash "$T/append-journal.sh" "$A" "STATE: witness" >/dev/null 2>&1 && grep -q 'STATE: witness' "$A/state/journal.md" \
  && pass "append-journal.sh sur un depot : ligne ecrite" || fail "append-journal.sh sur un depot"
bash "$T/build-state.sh" "$A" >/dev/null 2>&1 && [ -f "$A/state/STATE.md" ] \
  && pass "build-state.sh sur un depot : STATE.md ecrit" || fail "build-state.sh sur un depot"
bash "$T/build-digest.sh" "$A" >/dev/null 2>&1 && [ -f "$A/state/DIGEST.md" ] \
  && pass "build-digest.sh sur un depot : DIGEST.md ecrit" || fail "build-digest.sh sur un depot"
bash "$T/build-indexes.sh" "$A" >/dev/null 2>&1 && [ -f "$A/index.md" ] \
  && pass "build-indexes.sh sur un depot : index.md ecrit" || fail "build-indexes.sh sur un depot"
bash "$T/build-indexes.sh" "$A/state" >/dev/null 2>&1 && [ -f "$A/state/index.md" ] \
  && pass "build-indexes.sh sur un sous-dossier d'un depot : admis" || fail "build-indexes.sh sur un sous-dossier d'un depot"
out="$(bash "$T/set-release-version.sh" v9.9.9 "$A" 2>&1)"; case "$out" in *VERSION-SET*) pass "set-release-version.sh sur un depot : VERSION-SET";; *) fail "set-release-version.sh sur un depot -- $out";; esac
bash "$T/vault-identity.sh" ensure "$A" >/dev/null 2>&1 && [ -f "$A/VAULT-IDENTITY.md" ] \
  && pass "vault-identity.sh ensure sur un depot : identite ecrite" || fail "vault-identity.sh ensure sur un depot"
out="$(bash "$T/propose-link-repairs.sh" "$A" 2>&1)"; rc=$?; case "$out" in *REPO-ROOT-REFUSED*) fail "propose-link-repairs.sh sur un depot : refuse a tort";; *) pass "propose-link-repairs.sh sur un depot : admis (rc=$rc)";; esac
bash "$T/project-bootstrap.sh" create "$WS/newproj" "Newproj" --vcs none --lang FR >"$TMP/np.out" 2>&1 && [ -f "$WS/newproj/state/journal.md" ] \
  && pass "project-bootstrap.sh create d'un projet sans Git sous l'espace : cree (acte de naissance, journal)" || fail "project-bootstrap.sh create -- $(tail -n 3 "$TMP/np.out" | tr '\n' ' ')"
bash "$T/append-journal.sh" "$WS/newproj" "STATE: certified project" >/dev/null 2>&1 && grep -q 'certified project' "$WS/newproj/state/journal.md" \
  && pass "append-journal.sh sur un projet a acte de naissance, sans Git : admis" || fail "append-journal.sh sur un projet a acte de naissance"
bash "$T/project-bootstrap.sh" prompt "$WS/newproj" >"$TMP/pr.out" 2>&1 \n  && pass "project-bootstrap.sh prompt sur un projet a acte de naissance : admis" || fail "project-bootstrap.sh prompt sur un projet -- $(tail -n 2 "$TMP/pr.out" | tr '
' ' ')"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
