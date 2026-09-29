#!/usr/bin/env bash
# Mission 219, lot E: no baseline carries the fingerprint of a secret file or
# of a virtual environment, and no guardian turns red on a file that Git
# ignores and does not track.
#
#   (a) `project_baseline.py retire` removes, all or nothing, the entries under
#       the given prefixes (`.env`, `a/.venv/`), and writes one header line:
#       who, when, which prefixes, how many; other entries untouched;
#   (b) a prefix that matches no entry -> refused, nothing written (byte for
#       byte);
#   (c) a prefix that covers a file tracked by Git -> refused, nothing written
#       (retire is for what Git does not version);
#   (d) --by and --reason are required;
#   (e) folder mode in a Git work tree: an ignored, untracked `.env` holding a
#       fake secret and `sub/.venv/lib/cert.pem` -> check-secrets.sh rc=0;
#       an ignored `.venv/notes.md` without `## Liens` -> check-links.sh rc=0;
#       witnesses: the same `.env` force-added (tracked) -> refused; a tracked
#       `doc.md` without `## Liens` -> refused;
#   (f) `project_baseline.py write` in a Git work tree records neither `.env`
#       nor anything under `.venv/`;
#   (g) witness: a folder without Git keeps the old listing -- its `.env` is
#       still judged (refused).
#
# usage: bash tests/test-baseline-retire-and-gitignored.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"
PB="$REPO_ROOT/tools/project_baseline.py"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() { local n="$1"; shift; if "$@"; then pass "$n"; else fail "$n"; fi; }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m219-e-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
FAKE="ghp_""ABCDEFGHIJ0123456789ABCDEFGHIJ012345"

# A project with a birth certificate naming its baseline.
mkproject() { # mkproject <dir>
  mkdir -p "$1/a/.venv" "$1/sub/.venv/lib"
  printf '# second-brain-birth-certificate: v1\n# vault_id: sb-0000000000000000\n# baseline: .vault-baseline-t.tsv\nrepos: []\n' > "$1/.pre-commit-config.yaml"
  printf 'x\n' > "$1/a/.venv/x"; printf 'y\n' > "$1/a/.venv/y"
  printf 'token: %s\n' "$FAKE" > "$1/.env"
  printf '# Keep\n\n## Liens\n\n- `see also` — [x](./keep.md)\n' > "$1/keep.md"
}
baseline_lines() { # the baseline of <dir> with the given entries
  local d="$1"; shift
  { printf '# second-brain-baseline: v1\n# created_at: 2026-09-22T22:26:46-0400\n'
    for p in "$@"; do printf '%s\t%s\n' "$(tr -d '\r' < "$d/$p" | sha256sum | awk '{print $1}')" "$p"; done
  } > "$d/.vault-baseline-t.tsv"
}
retire() { uv run --no-project "$PB" retire "$@"; }

# --- (a) retire -------------------------------------------------------------------------------
P="$TMP/pa"; mkdir -p "$P"; git init -q "$P"; mkproject "$P"
printf '.env\n.venv/\n' > "$P/.gitignore"
baseline_lines "$P" .env a/.venv/x a/.venv/y keep.md
OUT="$(retire "$P" --prefix .env --prefix a/.venv/ --by "Executor 219" --reason "secret and venv out of the baseline" 2>&1)"; RC=$?
check "(a) retire rend 0 [$OUT]" [ "$RC" = 0 ]
check "(a) plus aucune entree .env ni a/.venv/" sh -c "! cut -f2 '$P/.vault-baseline-t.tsv' | grep -qE '^(\.env|a/\.venv/)'"
check "(a) keep.md garde son entree" grep -q "	keep.md\$" "$P/.vault-baseline-t.tsv"
check "(a) une ligne d'en-tete : qui, quand, prefixes, combien" \
  grep -qE '^# retired_at: [0-9T:+-]+ by: Executor 219 prefixes: \.env\|a/\.venv/ entries: 3 reason: secret and venv' "$P/.vault-baseline-t.tsv"

# --- (b) all or nothing -----------------------------------------------------------------------
P="$TMP/pb"; mkdir -p "$P"; git init -q "$P"; mkproject "$P"
printf '.env\n.venv/\n' > "$P/.gitignore"
baseline_lines "$P" .env a/.venv/x keep.md
cp "$P/.vault-baseline-t.tsv" "$TMP/pb.before"
retire "$P" --prefix .env --prefix nowhere/ --by x --reason y >"$TMP/pb.out" 2>&1; RC=$?
check "(b) prefixe sans entree : refus (rc=$RC)" sh -c "[ '$RC' != 0 ] && grep -q 'BASELINE-RETIRE-REFUSED' '$TMP/pb.out'"
check "(b) rien ecrit, octet pour octet" cmp -s "$TMP/pb.before" "$P/.vault-baseline-t.tsv"

# --- (c) a tracked file is not retired -----------------------------------------------------------
( cd "$P" && git add -- keep.md >/dev/null 2>&1 )
retire "$P" --prefix keep.md --by x --reason y >"$TMP/pc.out" 2>&1; RC=$?
check "(c) fichier suivi par Git : refus (rc=$RC)" sh -c "[ '$RC' != 0 ] && grep -q 'tracked' '$TMP/pc.out'"
check "(c) rien ecrit" cmp -s "$TMP/pb.before" "$P/.vault-baseline-t.tsv"

# --- (d) who and why ----------------------------------------------------------------------------
retire "$P" --prefix .env >"$TMP/pd.out" 2>&1; RC=$?
check "(d) sans --by ni --reason : refus (rc=$RC)" [ "$RC" != 0 ]
check "(d) rien ecrit" cmp -s "$TMP/pb.before" "$P/.vault-baseline-t.tsv"

# --- (e) folder mode in a Git work tree ------------------------------------------------------------
P="$TMP/pe"; mkdir -p "$P"; git init -q "$P"
printf '.env\n.venv/\n' > "$P/.gitignore"
mkdir -p "$P/sub/.venv/lib" "$P/.venv"
printf 'token: %s\n' "$FAKE" > "$P/.env"
printf 'x\n' > "$P/sub/.venv/lib/cert.pem"
printf '# Notes\n\nno links section\n' > "$P/.venv/notes.md"
printf '# Readme\n\n## Liens\n\n- `see also` — [x](./README.md)\n' > "$P/README.md"
( cd "$P" && git add -- .gitignore README.md >/dev/null 2>&1 )
bash "$REPO_ROOT/tools/check-secrets.sh" "$P" >"$TMP/e1.out" 2>&1; R1=$?
check "(e) check-secrets mode dossier : .env et .venv ignores et non suivis ne rougissent pas (rc=$R1) [$(grep -m2 -v '^progress' "$TMP/e1.out" | tr '\n' ' ')]" [ "$R1" = 0 ]
bash "$REPO_ROOT/tools/check-links.sh" "$P" >"$TMP/e2.out" 2>&1; R2=$?
check "(e) check-links mode dossier : .venv/notes.md ignore ne rougit pas (rc=$R2) [$(grep -m2 -v '^progress' "$TMP/e2.out" | tr '\n' ' ')]" [ "$R2" = 0 ]
( cd "$P" && git add -f -- .env >/dev/null 2>&1 )
bash "$REPO_ROOT/tools/check-secrets.sh" "$P" >"$TMP/e3.out" 2>&1; R3=$?
check "(e) temoin : le meme .env suivi (force) est refuse (rc=$R3)" [ "$R3" != 0 ]
( cd "$P" && git rm -q --cached -- .env >/dev/null 2>&1 )
printf '# Doc\n\nno links section\n' > "$P/doc.md"
( cd "$P" && git add -- doc.md >/dev/null 2>&1 )
bash "$REPO_ROOT/tools/check-links.sh" "$P" >"$TMP/e4.out" 2>&1; R4=$?
check "(e) temoin : doc.md suivi sans ## Liens est refuse (rc=$R4)" [ "$R4" != 0 ]

# --- (f) write ignores what Git ignores -----------------------------------------------------------
uv run --no-project "$PB" write "$P" "$TMP/pf.tsv" >/dev/null 2>&1
check "(f) write : ni .env ni .venv/ dans une ligne de base neuve" sh -c "! cut -f2 '$TMP/pf.tsv' | grep -qE '(^|/)\.env\$|(^|/)\.venv/'"
check "(f) write : README.md et doc.md y sont" sh -c "grep -q '	README.md\$' '$TMP/pf.tsv' && grep -q '	doc.md\$' '$TMP/pf.tsv'"

# --- (g) no Git: unchanged ------------------------------------------------------------------------
P="$TMP/pg"; mkdir -p "$P"
printf '.env\n' > "$P/.gitignore"
printf 'token: %s\n' "$FAKE" > "$P/.env"
bash "$REPO_ROOT/tools/check-secrets.sh" "$P" >"$TMP/g.out" 2>&1; RG=$?
check "(g) temoin sans Git : .env toujours juge, refuse (rc=$RG)" [ "$RG" != 0 ]

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
