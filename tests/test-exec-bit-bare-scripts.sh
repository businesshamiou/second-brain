#!/usr/bin/env bash
# Regression test for tools/check-exec-bit-bare-scripts.sh (Mission 177,
# etape 2, 4e reprise). Written after this exact family of defect struck
# CI twice at two different sizes (3 scripts, then 5) -- both times
# invisible on NTFS (this machine, any Windows machine), only visible on
# the Ubuntu runner that actually enforces the execute bit. This test
# proves the guardian bites on a synthetic sandbox rather than trusting a
# real CI round-trip to prove it, the same way the guardian itself proves
# each real script it checks without needing ext4 on this machine.
#
# `git update-index --chmod` sets the mode directly in the index, the
# same mechanism the real fixes in this Mission used -- avoids depending
# on whether a filesystem `chmod +x` on this machine round-trips through
# Git for Windows' own execute-bit emulation the same way.
#
# Cases:
#   1. bare-invocation-missing-bit -- a script invoked bare (no bash/sh in
#      front) from another tracked .sh, at mode 100644: refused, names it.
#   2. bare-invocation-with-bit -- same script, mode 100755: passes.
#   3. pre-commit-entry-missing-bit -- a script named by `entry:` under
#      `language: script` in .pre-commit-hooks.yaml, at mode 100644:
#      refused, even though nothing else in the tree calls it bare.
#   4. prefixed-invocation-not-flagged -- a script invoked as `bash
#      tools/x.sh` (prefixed), at mode 100644: NOT flagged -- the false-
#      positive guard that justifies scanning by pattern instead of by a
#      blanket "every tracked .sh must be 100755" rule.
#   5. githook-no-extension-missing-bit (Mission 181) -- .githooks/pre-commit
#      at mode 100644, called by nothing but Git: refused, names it.
#   6. githook-any-extension-missing-bit -- a .py and a .sh under
#      .githooks/ at mode 100644: both refused -- the folder's role
#      decides, never the extension.
#   7. githooks-with-bit -- the same hooks at 100755: passes, counted.
#
# usage: tests/test-exec-bit-bare-scripts.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_SCRIPT="$SCRIPT_DIR/../tools/check-exec-bit-bare-scripts.sh"

if [ ! -f "$REAL_SCRIPT" ]; then
  echo "FAIL: script cible introuvable : $REAL_SCRIPT" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILURES=0

make_repo() {
  local ws="$1"
  local repo="$ws/canary"
  mkdir -p "$repo/tools"
  cp "$REAL_SCRIPT" "$repo/tools/check-exec-bit-bare-scripts.sh"
  (
    cd "$repo" && git init -q -b main \
      && git config user.email t@t \
      && git config user.name t \
      && git config commit.gpgsign false
  )
  printf '%s\n' "$repo"
}

# Ajoute et commite tout le contenu courant, puis force le mode Git de
# chaque chemin donne en argument (2e+ arguments), independamment de ce
# que le filesystem hote rapporte -- le mecanisme mesure et deja utilise
# par les correctifs reels de cette Mission (`git update-index --chmod`).
commit_with_modes() {
  local repo="$1"; shift
  local msg="commit"
  local log
  log="$(cd "$repo" && git add -A 2>&1)" || {
    echo "FAIL: git add impossible dans $repo :" >&2
    printf '%s\n' "$log" >&2
    exit 1
  }
  while [ "$#" -ge 2 ]; do
    local path="$1" mode="$2"; shift 2
    (cd "$repo" && git update-index "--chmod=$mode" "$path") >/dev/null 2>&1
  done
  log="$(cd "$repo" && git commit -q -m "$msg" 2>&1)" || {
    echo "FAIL: commit sandbox impossible dans $repo :" >&2
    printf '%s\n' "$log" >&2
    exit 1
  }
}

# --- 1. bare invocation, bit absent : refuse, nomme le chemin ---------------
REPO_1="$(make_repo "$TMP/case-1")"
printf '#!/usr/bin/env bash\n"$REPO_ROOT/tools/nu.sh" "$@"\n' > "$REPO_1/install.sh"
printf '#!/usr/bin/env bash\necho ok\n' > "$REPO_1/tools/nu.sh"
commit_with_modes "$REPO_1" tools/nu.sh -x
OUT_1="$(cd "$REPO_1" && bash tools/check-exec-bit-bare-scripts.sh 2>&1)"; RC_1=$?
if [ "$RC_1" -ne 0 ] && printf '%s' "$OUT_1" | grep -q "tools/nu.sh"; then
  echo "ok [1-bare-invocation-missing-bit]: refuse un script invoque nu sans bit d'execution"
else
  echo "FAIL [1-bare-invocation-missing-bit]: exit=$RC_1, sortie:" >&2
  printf '%s\n' "$OUT_1" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 2. meme script, bit present : passe -------------------------------------
REPO_2="$(make_repo "$TMP/case-2")"
printf '#!/usr/bin/env bash\n"$REPO_ROOT/tools/nu.sh" "$@"\n' > "$REPO_2/install.sh"
printf '#!/usr/bin/env bash\necho ok\n' > "$REPO_2/tools/nu.sh"
commit_with_modes "$REPO_2" tools/nu.sh +x
OUT_2="$(cd "$REPO_2" && bash tools/check-exec-bit-bare-scripts.sh 2>&1)"; RC_2=$?
if [ "$RC_2" -eq 0 ]; then
  echo "ok [2-bare-invocation-with-bit]: passe quand le bit d'execution est present"
else
  echo "FAIL [2-bare-invocation-with-bit]: exit=$RC_2, sortie:" >&2
  printf '%s\n' "$OUT_2" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 3. entry: sous language: script, bit absent : refuse -------------------
REPO_3="$(make_repo "$TMP/case-3")"
printf -- '- id: canary\n  name: canary\n  entry: tools/canary-hook.sh\n  language: script\n  always_run: true\n  pass_filenames: false\n' > "$REPO_3/.pre-commit-hooks.yaml"
printf '#!/usr/bin/env bash\necho ok\n' > "$REPO_3/tools/canary-hook.sh"
commit_with_modes "$REPO_3" tools/canary-hook.sh -x
OUT_3="$(cd "$REPO_3" && bash tools/check-exec-bit-bare-scripts.sh 2>&1)"; RC_3=$?
if [ "$RC_3" -ne 0 ] && printf '%s' "$OUT_3" | grep -q "tools/canary-hook.sh"; then
  echo "ok [3-pre-commit-entry-missing-bit]: refuse un hook 'entry:' sans bit d'execution"
else
  echo "FAIL [3-pre-commit-entry-missing-bit]: exit=$RC_3, sortie:" >&2
  printf '%s\n' "$OUT_3" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 4. invocation prefixee `bash tools/x.sh`, bit absent : jamais signale --
REPO_4="$(make_repo "$TMP/case-4")"
printf '#!/usr/bin/env bash\nbash "$REPO_ROOT/tools/prefixed.sh" "$@"\n' > "$REPO_4/install.sh"
printf '#!/usr/bin/env bash\necho ok\n' > "$REPO_4/tools/prefixed.sh"
commit_with_modes "$REPO_4" tools/prefixed.sh -x
OUT_4="$(cd "$REPO_4" && bash tools/check-exec-bit-bare-scripts.sh 2>&1)"; RC_4=$?
if [ "$RC_4" -eq 0 ] && ! printf '%s' "$OUT_4" | grep -q "tools/prefixed.sh"; then
  echo "ok [4-prefixed-invocation-not-flagged]: une invocation 'bash tools/x.sh' prefixee n'est pas signalee"
else
  echo "FAIL [4-prefixed-invocation-not-flagged]: exit=$RC_4, sortie:" >&2
  printf '%s\n' "$OUT_4" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 5. hook Git sans extension, bit absent : refuse, nomme le hook ---------
# Mission 181 : un hook n'est appele nu par aucun script du depot -- Git
# l'appelle, et l'ignore s'il n'est pas executable. Aucun autre fichier ne
# l'invoque ici : seul son role (dossier .githooks/) le rend candidat.
REPO_5="$(make_repo "$TMP/case-5")"
mkdir -p "$REPO_5/.githooks"
printf '#!/usr/bin/env bash\nexit 0\n' > "$REPO_5/.githooks/pre-commit"
commit_with_modes "$REPO_5" .githooks/pre-commit -x
OUT_5="$(cd "$REPO_5" && bash tools/check-exec-bit-bare-scripts.sh 2>&1)"; RC_5=$?
if [ "$RC_5" -ne 0 ] && printf '%s' "$OUT_5" | grep -q ".githooks/pre-commit"; then
  echo "ok [5-githook-no-extension-missing-bit]: refuse un hook Git sans extension et sans bit d'execution"
else
  echo "FAIL [5-githook-no-extension-missing-bit]: exit=$RC_5, sortie:" >&2
  printf '%s\n' "$OUT_5" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 6. fichier de .githooks/ portant une extension, bit absent : refuse ---
# Le role decide, jamais l'extension : un .py ou un .sh range dans
# .githooks/ est refuse de la meme facon.
REPO_6="$(make_repo "$TMP/case-6")"
mkdir -p "$REPO_6/.githooks"
printf '#!/usr/bin/env python3\n' > "$REPO_6/.githooks/commit-msg.py"
printf '#!/usr/bin/env bash\nexit 0\n' > "$REPO_6/.githooks/pre-push.sh"
commit_with_modes "$REPO_6" .githooks/commit-msg.py -x .githooks/pre-push.sh -x
OUT_6="$(cd "$REPO_6" && bash tools/check-exec-bit-bare-scripts.sh 2>&1)"; RC_6=$?
if [ "$RC_6" -ne 0 ] && printf '%s' "$OUT_6" | grep -q ".githooks/commit-msg.py" \
    && printf '%s' "$OUT_6" | grep -q ".githooks/pre-push.sh"; then
  echo "ok [6-githook-any-extension-missing-bit]: refuse un fichier de .githooks/ non executable, quelle que soit son extension"
else
  echo "FAIL [6-githook-any-extension-missing-bit]: exit=$RC_6, sortie:" >&2
  printf '%s\n' "$OUT_6" >&2
  FAILURES=$((FAILURES + 1))
fi

# --- 7. hooks Git executables dans l'index : passe --------------------------
REPO_7="$(make_repo "$TMP/case-7")"
mkdir -p "$REPO_7/.githooks"
printf '#!/usr/bin/env bash\nexit 0\n' > "$REPO_7/.githooks/pre-commit"
printf '#!/usr/bin/env bash\nexit 0\n' > "$REPO_7/.githooks/commit-msg"
commit_with_modes "$REPO_7" .githooks/pre-commit +x .githooks/commit-msg +x
OUT_7="$(cd "$REPO_7" && bash tools/check-exec-bit-bare-scripts.sh 2>&1)"; RC_7=$?
if [ "$RC_7" -eq 0 ] && printf '%s' "$OUT_7" | grep -q "2 script(s)"; then
  echo "ok [7-githooks-with-bit]: passe quand les hooks sont executables dans l'index, et les compte"
else
  echo "FAIL [7-githooks-with-bit]: exit=$RC_7, sortie:" >&2
  printf '%s\n' "$OUT_7" >&2
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: 7/7 cas conformes"
  exit 0
else
  echo "FAIL: $FAILURES cas non conformes"
  exit 1
fi
