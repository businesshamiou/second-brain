#!/usr/bin/env bash
# T (Mission 214): the asserted-paths guardian launches a constant number of
# external commands, whatever the size of the corpus it reads.
#
# Defect measured in Mission 212: tools/check-asserted-paths.sh made 63 % of
# the ten-guardian block (14.85 s of 23.7 s) because it launched 315 external
# commands per pass -- a `grep -o` and a `tr` per perimeter file (224 of
# them) and a `git ls-files | sort | grep` per unresolved bare token. Under
# Git Bash a launch costs about 43.5 ms (Mission 210): the number of launches
# is the cost, and it grew with the corpus.
#
# The launches are counted, never timed: shims (a folder of tiny scripts put
# first on PATH) note the name of each command and then run the real binary.
# A stopwatch inside the guardian would be a second guardian.
#
# Cases:
#   (1) verdict, on repository B (one perimeter document that exercises every
#       branch, plus a workspace file naming a sibling repository): the
#       `Comptes :` line and the four CHEMIN-AFFIRME-MORT lines are the
#       expected ones, measured on the guardian as it stood before the
#       rewrite (Mission 214, step 1) and written here as literals: the same
#       bytes before and after.
#   (2) launches on B do not exceed 20.
#   (3) launches on C (B plus 50 ordinary perimeter documents) do not exceed
#       those on B: the count does not grow with the corpus.
#   (4) negative control: a stand-in guardian that launches one `grep` per
#       perimeter document (the former pattern) is measured the same way and
#       the growth check catches it.
#
# Writes only in a temporary folder (prefix m214). No model call.
# Portable: bash 3.2 (no mapfile, no associative array, no GNU-only option).
#
# usage: bash tests/test-check-asserted-paths-constant-launches.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUARDIAN="$REPO_ROOT/tools/check-asserted-paths.sh"
LIMIT=20

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m214-launches-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

unset SECOND_BRAIN_SIBLING_REPO

# make_shims <dir>: one tiny script per external command the guardian may
# use; it notes its own name in $M214_LOG, then runs the real binary.
make_shims() {
  local dir="$1" c p
  mkdir -p "$dir"
  for c in grep tr dirname git sort awk xargs cat head tail sed od wc cut uniq basename expr mktemp; do
    p="$(command -v "$c" 2>/dev/null)"
    case "$p" in
      /*) : ;;
      *) continue ;;
    esac
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s" >> "$M214_LOG"\nexec "%s" "$@"\n' "$c" "$p" > "$dir/$c"
    chmod +x "$dir/$c"
  done
}

# build_repo <dir> <n>: the probe repository. One perimeter document that
# exercises every branch of the guardian, targets that the bare-name search
# meets once, twice or never, and <n> ordinary perimeter documents.
build_repo() {
  local R="$1" NB="$2" n nn
  mkdir -p "$R/rules" "$R/zz" "$R/zz-a" "$R/zz-b"
  (cd "$R" && git init -q -b main && git config core.autocrlf false) >/dev/null 2>&1
  : > "$R/zz/only-a.md"; : > "$R/zz-a/twin.md"; : > "$R/zz-b/twin.md"; : > "$R/rules/RULES-a&b.md"
  printf 'm214-cache.txt\n' > "$R/.gitignore"
  cat > "$R/rules/RULES-a.md" <<'EOF'
---
type: rules
title: "Probe A"
status: active
---

# Probe A

Vivant : `rules/RULES-a.md` ; mort : `rules/absent-a.md` ; alias : `vault/rules/RULES-a.md`.
Accepte : `gone/old.md` (supprimé). Hors racine : `../../outside.md`. Ignore : `m214-cache.txt`.
Externe connu : `~/.claude/CLAUDE.md`. Nu unique : `only-a.md` ; ambigu : `twin.md` ; absent : `nowhere.md`.
Glob : `*.sh` ; esperluette vivante : `rules/RULES-a&b.md` ; frere : `zz-sibling/x.md`.

```text
`fence/dead.md`
```
EOF
  n=1
  while [ "$n" -le "$NB" ]; do
    nn="$(printf '%02d' "$n")"
    printf -- '---\ntype: rules\ntitle: "Banal %s"\nstatus: active\n---\n\nSoi : `rules/RULES-banal-%s.md`, nu : `only-a.md`, mort : `rules/absent-%s.md`.\n' "$nn" "$nn" "$nn" > "$R/rules/RULES-banal-$nn.md"
    n=$((n + 1))
  done
  (cd "$R" && git add -A) >/dev/null 2>&1
}

# launches <script> <repo> <tag>: runs <script> in <repo> with the shims,
# leaves <tag>.out, <tag>.err, <tag>.rc and prints the number of launches.
launches() {
  local script="$1" repo="$2" tag="$3"
  : > "$TMP/$tag.log"
  (cd "$repo" && PATH="$TMP/shims:$PATH" M214_LOG="$TMP/$tag.log" bash "$script" > "$TMP/$tag.out" 2> "$TMP/$tag.err"; echo $? > "$TMP/$tag.rc")
  wc -l < "$TMP/$tag.log" | tr -d ' '
}

echo "=== T (M214) : lancements constants du gardien chemins-affirmes ==="

if [ ! -f "$GUARDIAN" ]; then
  echo "FAIL : gardien introuvable : $GUARDIAN"
  exit 1
fi

make_shims "$TMP/shims"
mkdir -p "$TMP/wsB" "$TMP/wsC"
printf 'zz-sibling\n' > "$TMP/wsB/SIBLING-REPO.txt"
printf 'zz-sibling\n' > "$TMP/wsC/SIBLING-REPO.txt"
build_repo "$TMP/wsB/repo" 0
build_repo "$TMP/wsC/repo" 50

NB="$(launches "$GUARDIAN" "$TMP/wsB/repo" B)"
NC="$(launches "$GUARDIAN" "$TMP/wsC/repo" C)"
echo "  launches : B=$NB  C=$NC  (limit $LIMIT)"

echo ""
echo "=== (1) verdict sur B : Comptes et lignes mortes attendues ==="
EXPECTED_OUT='Comptes : fichiers du périmètre=1 jetons-fichier examinés=13 dossiers nus ignorés=0 marqués acceptés=1 hors racine=2 ignorés=1 externes connus=1 défauts=4'
EXPECTED_ERR='CHEMIN-AFFIRME-MORT : rules/RULES-a.md:9 [Probe A] jeton `rules/absent-a.md` introuvable sous les racines candidates
CHEMIN-AFFIRME-MORT : rules/RULES-a.md:11 [Probe A] jeton `twin.md` introuvable sous les racines candidates
CHEMIN-AFFIRME-MORT : rules/RULES-a.md:11 [Probe A] jeton `nowhere.md` introuvable sous les racines candidates
CHEMIN-AFFIRME-MORT : rules/RULES-a.md:12 [Probe A] jeton `*.sh` introuvable sous les racines candidates
REFUS : 4 chemin(s) affirmé(s) introuvable(s).'
GOT_OUT="$(cat "$TMP/B.out")"
GOT_ERR="$(cat "$TMP/B.err")"
if [ "$(cat "$TMP/B.rc")" = "1" ] && [ "$GOT_OUT" = "$EXPECTED_OUT" ] && [ "$GOT_ERR" = "$EXPECTED_ERR" ]; then
  pass "(1) B : code 1, ligne Comptes et quatre lignes mortes conformes"
else
  fail "(1) B : verdict different de l'attendu (code $(cat "$TMP/B.rc"))"
  printf '%s\n' "$GOT_OUT" "$GOT_ERR" | sed 's/^/      /'
fi

echo ""
echo "=== (2) B : au plus $LIMIT lancements ==="
if [ "$NB" -le "$LIMIT" ]; then
  pass "(2) B : $NB lancements (limite $LIMIT)"
else
  fail "(2) B : $NB lancements (limite $LIMIT)"
fi

echo ""
echo "=== (3) C (B + 50 documents) : pas plus de lancements que B ==="
if [ "$NC" -le "$NB" ] && [ "$NC" -le "$LIMIT" ]; then
  pass "(3) C : $NC lancements, B : $NB -- le compte ne croit pas avec le corpus"
else
  fail "(3) C : $NC lancements contre $NB sur B (limite $LIMIT) -- le compte croit avec le corpus"
fi

echo ""
echo "=== (4) temoin negatif : un gardien qui lance un grep par document ==="
# grows_with_corpus <launches on B> <launches on C>: 0 when the count grows.
grows_with_corpus() { [ "$2" -gt "$1" ]; }
STAND="$TMP/standin.sh"
cat > "$STAND" <<'EOF'
#!/usr/bin/env bash
# Stand-in for the former pattern: one grep per perimeter document.
for f in $(git ls-files -- 'rules/*.md'); do
  grep -o '`[^`]*`' "$f" > /dev/null
done
EOF
SB="$(launches "$STAND" "$TMP/wsB/repo" SB)"
SC="$(launches "$STAND" "$TMP/wsC/repo" SC)"
if grows_with_corpus "$SB" "$SC"; then
  pass "(4) temoin : le pattern ancien passe de $SB a $SC lancements, la croissance est vue"
else
  fail "(4) temoin : le pattern ancien ($SB puis $SC lancements) n'est pas vu croitre"
fi

echo ""
echo "=== RESULT: $PASSES PASS, $FAILURES FAIL ==="
[ "$FAILURES" -eq 0 ] && exit 0
exit 1
