#!/usr/bin/env bash
# T6 (Mission 199): tools/check-work-regime.sh refuses the wrong regime, and
# accepts the same gesture once the criterion is gone. Every refusal has its
# twin accepted, so a checker that refuses everything, or accepts everything,
# fails here.
#
#   (a) R1 a push to release / of publish / forced / bare / to another remote
#       / a network tool; twin: git push origin <refspec> -> accepted;
#   (b) R2 deletion, history rewrite, a move out of the repository;
#       twin: a move inside the repository;
#   (c) R3 a Decision, a rule or a template in the Scope; twin: the same path
#       only READ in a measuring rubric -> accepted;
#   (d) R4 a tag, a branch, a remote, a switch -c; twin: their listing forms;
#   (e) R5 the company repository named; twin: not named;
#   (f) R6 a guardian, a hook, the publication tool in the Scope, a hook
#       bypass in the Gesture; twin: an ordinary commit;
#   (g) R7 the Note's form: no regime, a missing rubric, an extra rubric,
#       the wrong order, over the size cap, a journal line that is two lines,
#       has no tag, or is too long; twin: the valid Note;
#   (h) the template itself is a valid Note (template and checker agree);
#   (i) `diff` on a real change: a light change accepted; a deletion, a
#       doctrine file, a guardian or the publication tool refused, named;
#   (j) drift guard: the criterion ids of the tool and of the rule are the
#       same set, and each id is raised somewhere in the tool's code.
# The tool under test is the working-tree one, or WORK_REGIME_TOOL=<file> (how a
# weakened checker is shown to fail this test). The Notes are built in a
# throwaway folder; nothing real is touched, nothing
# is pushed.
#
# usage: bash tests/test-check-work-regime.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="${WORK_REGIME_TOOL:-$REPO_ROOT/tools/check-work-regime.sh}"
FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m199-regime-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
COMPANY="Glint""BloomWorks"

# mknote <file> : a valid Note, each part overridable through the environment.
mknote() {
  local f="$1"
  {
    printf -- '---\ntype: note\ntitle: "T"\ndescription: "d"\ncreated_at: "2026-09-20T00:00:00-04:00"\ntimezone: America/Montreal\n'
    printf 'regime: %s\nscope: t\n---\n\n# NOTE — T\n\n' "${N_REGIME:-light}"
    [ "${N_NO_INTENT:-}" = 1 ] || printf '## Intent\n\nBack up one commit.\n\n'
    [ -z "${N_EXTRA:-}" ] || printf '## Context\n\nlong story\n\n'
    printf '## Scope\n\n%s\n\n' "${N_SCOPE:-- the local repository, remote origin}"
    printf '## Measure before\n\n```\n%s\n```\n\n3 commits.\n\n' "${N_BEFORE:-git rev-list --count HEAD}"
    printf '## Gesture\n\n```\n%s\n```\n\n' "${N_GESTURE:-git push origin main:main}"
    [ "${N_NO_AFTER:-}" = 1 ] || printf '## Measure after\n\n```\ngit ls-remote origin main\n```\n\nEqual.\n\n'
    printf '## Journal line\n\n```\n%s\n```\n' "${N_JOURNAL:-STATE: main pushed to origin, ls-remote equal}"
    [ -z "${N_PAD:-}" ] || { printf '\n<!-- '; head -c "$N_PAD" /dev/zero | tr '\0' 'x'; printf ' -->\n'; }
  } > "$f"
}
run() { OUT="$(bash "$TOOL" "$@" 2>"$TMP/err")"; RC=$?; LAST="$(printf '%s\n' "$OUT" | tail -n 1)"; }
expect_ok() { # expect_ok <label> <file>
  run note "$2"
  if [ "$RC" = 0 ] && [ "$LAST" = "REGIME-LIGHT-OK" ]; then pass "$1 -> accepted"; else fail "$1 -> rc=$RC last='$LAST' $(head -n 3 "$TMP/err" | tr '\n' ' ')"; fi
}
expect_no() { # expect_no <label> <file> <id>
  run note "$2"
  case "$RC:$LAST" in
    1:REFUSED*"$3"*) pass "$1 -> refused $3" ;;
    *) fail "$1 -> wanted REFUSED $3, got rc=$RC last='$LAST'" ;;
  esac
}
case_note() { # case_note <label> <id|OK> VAR=value... : build, run, judge
  local label="$1" id="$2"; shift 2
  local f="$TMP/n-$(printf '%s' "$label" | tr -c 'A-Za-z0-9' '_').md"
  ( for kv in "$@"; do export "${kv%%=*}=${kv#*=}"; done; mknote "$f" )
  if [ "$id" = OK ]; then expect_ok "$label" "$f"; else expect_no "$label" "$f" "$id"; fi
}

echo "=== T6 : le controle de regime de travail ==="

# The valid Note: the baseline every twin comes back to.
case_note "valid Note (push origin main:main)" OK

# (a) R1
case_note "(a) git push release" R1-egress "N_GESTURE=git push release main:main"
case_note "(a) git push of publish" R1-egress "N_GESTURE=git push origin publish:main"
case_note "(a) git push forced" R1-egress "N_GESTURE=git push --force origin main:main"
case_note "(a) bare git push" R1-egress "N_GESTURE=git push"
case_note "(a) git push to another remote" R1-egress "N_GESTURE=git push upstream main:main"
case_note "(a) git push -C form to release" R1-egress "N_GESTURE=git -C x push release main:main"
case_note "(a) curl" R1-egress "N_GESTURE=curl -X POST https://example.invalid/x"
case_note "(a) gh" R1-egress "N_GESTURE=gh pr create"
case_note "(a) command hidden in Measure after" R1-egress "N_BEFORE=ssh host uptime"
case_note "(a) twin: push -u origin branch" OK "N_GESTURE=git push -u origin work:work"
# (b) R2
case_note "(b) rm" R2-destructive "N_GESTURE=rm -f old.txt"
case_note "(b) git rm" R2-destructive "N_GESTURE=git rm old.txt"
case_note "(b) git reset --hard" R2-destructive "N_GESTURE=git reset --hard HEAD~1"
case_note "(b) git rebase" R2-destructive "N_GESTURE=git rebase main"
case_note "(b) git commit --amend" R2-destructive "N_GESTURE=git commit --amend -m x"
case_note "(b) mv out of the repository" R2-destructive "N_GESTURE=mv notes/a.md ../elsewhere/a.md"
case_note "(b) mv to an absolute path" R2-destructive "N_GESTURE=mv notes/a.md /tmp/a.md"
case_note "(b) Remove-Item" R2-destructive "N_GESTURE=Remove-Item old.txt"
case_note "(b) twin: mv inside the repository" OK "N_GESTURE=git mv notes/a.md notes/b.md"
# (c) R3
case_note "(c) a Decision in the Scope" R3-doctrine "N_SCOPE=- decisions/DECISION-2026-09-20-000000-x.md"
case_note "(c) a rule in the Scope" R3-doctrine "N_SCOPE=- rules/RULES-2026-09-20-000000-x.md"
case_note "(c) a template in the Gesture" R3-doctrine "N_GESTURE=git add templates/x.md"
case_note "(c) twin: a Decision only READ in Measure before" OK "N_BEFORE=cat decisions/DECISION-2026-09-20-000000-x.md"
# (d) R4
case_note "(d) git tag" R4-refs "N_GESTURE=git tag v1.0.0"
case_note "(d) git branch <name>" R4-refs "N_GESTURE=git branch feature"
case_note "(d) git remote add" R4-refs "N_GESTURE=git remote add up https://example.invalid/r.git"
case_note "(d) git switch -c" R4-refs "N_GESTURE=git switch -c feature"
case_note "(d) git checkout -b" R4-refs "N_GESTURE=git checkout -b feature"
case_note "(d) git worktree add" R4-refs "N_GESTURE=git worktree add ../w main"
case_note "(d) git push --delete" R4-refs "N_GESTURE=git push origin --delete old"
case_note "(d) twin: listing forms (tag -l, branch --list, remote -v)" OK "N_BEFORE=git tag -l
git branch --list
git remote -v"
# (e) R5
case_note "(e) the company repository named" R5-company "N_SCOPE=- $COMPANY clone"
case_note "(e) twin: not named" OK "N_SCOPE=- the local repository"
# (f) R6
case_note "(f) the publication tool in the Scope" R6-guardians "N_SCOPE=- tools/publish-from-laboratory.sh"
case_note "(f) a hook in the Scope" R6-guardians "N_SCOPE=- .githooks/pre-commit"
case_note "(f) a guardian in the Scope" R6-guardians "N_SCOPE=- tools/check-links.sh"
case_note "(f) --no-verify" R6-guardians "N_GESTURE=git commit --no-verify -m x"
case_note "(f) twin: an ordinary commit" OK "N_GESTURE=git commit -m 'one line'"
# (g) R7
case_note "(g) regime: full" R7-shape "N_REGIME=full"
case_note "(g) a rubric missing" R7-shape "N_NO_AFTER=1"
case_note "(g) an extra rubric" R7-shape "N_EXTRA=1"
case_note "(g) over the size cap" R7-shape "N_PAD=4100"
case_note "(g) journal line without a tag" R7-shape "N_JOURNAL=main pushed"
case_note "(g) journal line too long" R7-shape "N_JOURNAL=STATE: $(head -c 320 /dev/zero | tr '\0' 'y')"
case_note "(g) twin: journal line at the cap edge" OK "N_JOURNAL=STATE: $(head -c 290 /dev/zero | tr '\0' 'y')"
# a rubric out of order
mknote "$TMP/order.md"
{ sed -n '1,/^## Intent$/p' "$TMP/order.md"; echo; echo "Back up one commit."; echo; echo '## Measure before'; echo; echo x; echo; echo '## Scope'; echo; echo "- here"; echo; echo '## Gesture'; echo; echo '```'; echo 'git push origin main:main'; echo '```'; echo; echo '## Measure after'; echo; echo x; echo; echo '## Journal line'; echo; echo '```'; echo 'STATE: x'; echo '```'; } > "$TMP/order2.md"
expect_no "(g) rubrics out of order" "$TMP/order2.md" R7-shape
# CRLF Note
mknote "$TMP/crlf.md"; sed 's/$/\r/' "$TMP/crlf.md" > "$TMP/crlf2.md"
expect_ok "(g) twin: the valid Note saved with CRLF line ends" "$TMP/crlf2.md"
# several criteria at once are all named
case_note "(g) two criteria named together" R2-destructive "N_GESTURE=rm -f a
git tag v1"
grep -q 'R4-refs' <<<"$LAST" && pass "(g) ... and the second one too ($LAST)" || fail "(g) two criteria: last='$LAST'"

# (h) the template is a valid Note
expect_ok "(h) templates/execution-note-template.md" "$REPO_ROOT/templates/execution-note-template.md"

# (i) diff on a real change
G="$TMP/g"
mkdir -p "$G"
(
  cd "$G" || exit 1
  git init -q -b main 2>/dev/null || git init -q
  git config user.email t@example.invalid && git config user.name t
  mkdir -p notes decisions rules templates tools .githooks
  for f in README.md notes/a.md decisions/D.md rules/R.md templates/t.md tools/publish-from-laboratory.sh tools/check-x.sh .githooks/pre-commit; do echo "line $f" > "$f"; done
  git add -A && git commit -q -m base
  echo more >> notes/a.md && git commit -q -am light
  git mv notes/a.md notes/b.md && git commit -q -m rename
  git rm -q notes/b.md && git commit -q -m delete
  echo more >> decisions/D.md && echo n > rules/N.md && git add -A && git commit -q -m doctrine
  echo more >> tools/publish-from-laboratory.sh && git commit -q -am publication
  echo more >> .githooks/pre-commit && git commit -q -am hook
  echo more >> tools/check-x.sh && git commit -q -am guardian
  echo more >> README.md && echo more >> tools/check-x.sh && git commit -q -am mixed
) >/dev/null 2>&1
d() { run diff "$G" "$1"; }
d "HEAD~8..HEAD~7"; [ "$RC" = 0 ] && [ "$LAST" = "REGIME-LIGHT-OK" ] && pass "(i) a plain edit -> accepted" || fail "(i) plain edit: rc=$RC last='$LAST'"
d "HEAD~7..HEAD~6"; [ "$RC" = 0 ] && pass "(i) a rename inside the repository -> accepted" || fail "(i) rename: rc=$RC last='$LAST'"
d "HEAD~6..HEAD~5"; case "$LAST" in REFUSED*R2-destructive*) pass "(i) a deletion -> refused R2";; *) fail "(i) deletion: '$LAST'";; esac
d "HEAD~5..HEAD~4"; case "$LAST" in REFUSED*R3-doctrine*) pass "(i) a Decision amended and a rule created -> refused R3";; *) fail "(i) doctrine: '$LAST'";; esac
d "HEAD~4..HEAD~3"; case "$LAST" in REFUSED*R6-guardians*) pass "(i) the publication tool -> refused R6";; *) fail "(i) publication: '$LAST'";; esac
d "HEAD~3..HEAD~2"; case "$LAST" in REFUSED*R6-guardians*) pass "(i) a hook -> refused R6";; *) fail "(i) hook: '$LAST'";; esac
d "HEAD~2..HEAD~1"; case "$LAST" in REFUSED*R6-guardians*) pass "(i) a guardian -> refused R6";; *) fail "(i) guardian: '$LAST'";; esac
d "HEAD~1..HEAD"; case "$LAST" in REFUSED*R6-guardians*) pass "(i) a plain edit plus a guardian -> refused, the guardian named";; *) fail "(i) mixed: '$LAST'";; esac
d "HEAD..HEAD"; [ "$RC" = 2 ] && pass "(i) an empty range -> usage error, exit 2" || fail "(i) empty range: rc=$RC"

# (j) the ids of the tool and of the rule are the same set; each id is raised in the code
RULE="$(ls "$REPO_ROOT"/rules/RULES-*-two-work-regimes-*.md 2>/dev/null | head -n 1)"
ids() { grep -Eo 'R[1-7]-[a-z]+' "$1" | sort -u; }
if [ -n "$RULE" ]; then
  [ "$(ids "$TOOL")" = "$(ids "$RULE")" ] && pass "(j) tool and rule name the same criterion ids ($(ids "$TOOL" | paste -sd' ' -))" || fail "(j) the ids drifted: tool [$(ids "$TOOL" | paste -sd' ' -)] rule [$(ids "$RULE" | paste -sd' ' -)]"
else
  fail "(j) the rule file is missing"
fi
RAISED="$(grep -Eo 'add "R[1-7]-[a-z]+"' "$TOOL" | grep -Eo 'R[1-7]-[a-z]+' | sort -u)"
[ "$RAISED" = "$(ids "$TOOL")" ] && pass "(j) every id in the tool's header is raised by its code" || fail "(j) header ids [$(ids "$TOOL" | paste -sd' ' -)] vs raised [$(printf '%s' "$RAISED" | paste -sd' ' -)]"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
