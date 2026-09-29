#!/usr/bin/env bash
# Mission 218, lot 1: no index tool overwrites a file it did not generate,
# whatever the case. Replays the incident of 2026-09-21: under NTFS, writing
# `index.md` over a hand-written `INDEX.md` rewrote its content and kept its
# name (532 files of a knowledge base); the freshness guardian then prescribed
# the full mode again.
#
#   (a) a hand-written INDEX.md + full mode -> INDEX.md intact (content and
#       exact name), no index.md beside it, refusal INDEX-CASE-COLLISION, rc!=0;
#   (b) a generated index.md -> regenerated (the new file enters it);
#   (c) the Linux face: index.md (generated) and INDEX.md (hand-written) both
#       in the staged tree -> the guardian says INDEX-CASE-COLLISION and does
#       not prescribe `build-indexes.sh <racine>` for that folder;
#   (c') the NTFS face: INDEX.md alone in the staged tree -> the same state;
#   (d) an exemption declared in the certificate (`# exempt: <prefix>/`) ->
#       the subtree is ignored by the tool (no refusal, INDEX.md untouched)
#       and by the guardian;
#   (e) a root outside any repository and without a certificate -> refused,
#       nothing written (door open-211); twin: the same tree with a
#       certificate -> accepted;
#   (f) negative control, the old behaviour is still detected: a copy of the
#       case (a) folder where the refusal line is removed from the output
#       would pass -- proved by feeding the checker a doctored output.
# The tools under test are those of TOOLS_UNDER_TEST=<folder> (default: this
# repository's tools/), which is how the tool of HEAD is shown to fail.
#
# usage: bash tests/test-build-indexes-case-collision.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="${TOOLS_UNDER_TEST:-$REPO_ROOT/tools}"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- build_indexes.py en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m218-case-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

note() { printf -- '---\ntype: note\ntitle: "%s"\nstatus: active\n---\n# %s\n' "$1" "$1"; }
handwritten() { printf '# Archive — %s\n\nSommaire ecrit a la main, jamais genere.\n' "$1"; }
exact_names() { (cd "$1" && ls -1a | grep -i '^index\.md$' | LC_ALL=C sort | paste -sd' ' -); }
build() { bash "$TOOLS/build-indexes.sh" "$@" >"$TMP/out" 2>"$TMP/err"; echo $?; }
g() { git -C "$REPO" "$@"; }

# Is this file system case-insensitive? (NTFS, APFS by default)
mkdir -p "$TMP/probe"; : > "$TMP/probe/x"
CI_FS=0; [ -e "$TMP/probe/X" ] && CI_FS=1

# --- (a) hand-written INDEX.md, full mode -------------------------------------------
REPO="$TMP/a"
mkdir -p "$REPO/chan"
git init -q "$REPO"
note one > "$REPO/chan/one.md"
handwritten chan > "$REPO/chan/INDEX.md"
BEFORE="$(cksum < "$REPO/chan/INDEX.md")"
RC="$(build "$REPO")"
AFTER="$(cksum < "$REPO/chan/INDEX.md")"
NAMES="$(exact_names "$REPO/chan")"
if [ "$BEFORE" = "$AFTER" ] && [ "$NAMES" = "INDEX.md" ] && [ "$RC" != "0" ] \
   && grep -q "INDEX-CASE-COLLISION : .*chan.*exists and was not generated" "$TMP/err"; then
  pass "(a) INDEX.md manuscrit intact (contenu et nom exact), refus nomme, rc=$RC"
else
  fail "(a) INDEX.md : avant=$BEFORE apres=$AFTER noms=[$NAMES] rc=$RC stderr=[$(head -c 300 "$TMP/err" | tr '\n' ' ')]"
fi

# --- (b) a generated index.md is regenerated -----------------------------------------
REPO="$TMP/b"
mkdir -p "$REPO/docs"
git init -q "$REPO"
note one > "$REPO/docs/one.md"
RC1="$(build "$REPO")"
note two > "$REPO/docs/two.md"
RC2="$(build "$REPO")"
if [ "$RC1" = "0" ] && [ "$RC2" = "0" ] && grep -q '`two.md`' "$REPO/docs/index.md"; then
  pass "(b) index.md genere : regenere, le nouveau fichier y entre"
else
  fail "(b) regeneration : rc=$RC1/$RC2, two.md dans l'index=$(grep -c two.md "$REPO/docs/index.md" 2>/dev/null)"
fi

# --- (c) and (c'): the guardian, on the staged tree --------------------------------------
# Entries are put in the Git index by `update-index --cacheinfo`, so both faces
# are reproduced on any file system.
guard_case() { # guard_case <label> <with-lowercase-index 0|1>
  local label="$1" both="$2" blob_hw blob_one blob_gen out rc
  REPO="$TMP/c$both"
  mkdir -p "$REPO"
  git init -q "$REPO"
  g config user.email t@example.invalid; g config user.name t
  blob_one="$(note one | g hash-object -w --stdin)"
  blob_hw="$(handwritten chan | g hash-object -w --stdin)"
  g update-index --add --cacheinfo "100644,$blob_one,chan/one.md"
  g update-index --add --cacheinfo "100644,$blob_hw,chan/INDEX.md"
  if [ "$both" = "1" ]; then
    blob_gen="$(printf -- '---\ntype: index\ntitle: "Index — chan"\nstatus: active\ngenerated_by: tools/build-indexes.sh\n---\n\n## Contenu\n\n- `one` · active · one · `one.md`\n' | g hash-object -w --stdin)"
    g update-index --add --cacheinfo "100644,$blob_gen,chan/index.md"
  fi
  out="$(cd "$REPO" && bash "$TOOLS/check-indexes-fresh.sh" 2>&1)"; rc=$?
  if [ "$rc" != "0" ] && printf '%s' "$out" | grep -q "INDEX-CASE-COLLISION \[chan\]" \
     && ! printf '%s' "$out" | grep -A3 "\[chan\]" | grep -q "build-indexes.sh <racine>"; then
    pass "$label : INDEX-CASE-COLLISION [chan], sans prescrire le mode complet"
  else
    fail "$label : rc=$rc sortie=[$(printf '%s' "$out" | head -c 400 | tr '\n' ' ')]"
  fi
}
guard_case "(c) face Linux, index.md et INDEX.md cote a cote" 1
guard_case "(c') face NTFS, INDEX.md seul suivi" 0

# --- (d) exemption declared ---------------------------------------------------------------
REPO="$TMP/d"
mkdir -p "$REPO/chan" "$REPO/docs"
git init -q "$REPO"
{ echo "# second-brain-birth-certificate: v1"; echo "# vault_id: sb-test-218"; echo "# exempt: chan/"; echo "repos: []"; } > "$REPO/.pre-commit-config.yaml"
note one > "$REPO/chan/one.md"; handwritten chan > "$REPO/chan/INDEX.md"; note d > "$REPO/docs/d.md"
BEFORE="$(cksum < "$REPO/chan/INDEX.md")"
RC="$(build "$REPO")"
AFTER="$(cksum < "$REPO/chan/INDEX.md")"
g config user.email t@example.invalid; g config user.name t
(cd "$REPO" && git add -A >/dev/null 2>&1)
GOUT="$(cd "$REPO" && bash "$TOOLS/check-indexes-fresh.sh" 2>&1)"; GRC=$?
if [ "$RC" = "0" ] && [ "$BEFORE" = "$AFTER" ] && [ "$(exact_names "$REPO/chan")" = "INDEX.md" ] \
   && [ -f "$REPO/docs/index.md" ] && [ "$GRC" = "0" ]; then
  pass "(d) exemption : sous-arbre ignore par l'outil (rc=0, INDEX.md intact) et par le gardien (rc=0)"
else
  fail "(d) exemption : outil rc=$RC intact=$([ "$BEFORE" = "$AFTER" ] && echo oui || echo non) gardien rc=$GRC [$(printf '%s' "$GOUT" | head -c 300 | tr '\n' ' ')]"
fi

# --- (d') exemption declared in the project's versioned file, a folder name with spaces ---------
# The certificate's `# exempt:` key separates its prefixes by spaces: it cannot name
# "Adn Dev/". The project's `.vault-exempt` holds one prefix per line.
REPO="$TMP/d2"
mkdir -p "$REPO/My Chan/sub" "$REPO/docs"
git init -q "$REPO"
{ echo "# second-brain-birth-certificate: v1"; echo "# vault_id: sb-test-218"; echo "repos: []"; } > "$REPO/.pre-commit-config.yaml"
printf '# channel folders keep their own INDEX.md (Mission 218)\nMy Chan/\n' > "$REPO/.vault-exempt"
note one > "$REPO/My Chan/one.md"; handwritten chan > "$REPO/My Chan/INDEX.md"
note two > "$REPO/My Chan/sub/two.md"; handwritten sub > "$REPO/My Chan/sub/INDEX.md"
note d > "$REPO/docs/d.md"
BEFORE="$(cat "$REPO/My Chan/INDEX.md" "$REPO/My Chan/sub/INDEX.md" | cksum)"
RC="$(build "$REPO")"
AFTER="$(cat "$REPO/My Chan/INDEX.md" "$REPO/My Chan/sub/INDEX.md" | cksum)"
g config user.email t@example.invalid; g config user.name t
(cd "$REPO" && git add -A >/dev/null 2>&1)
GOUT="$(cd "$REPO" && bash "$TOOLS/check-indexes-fresh.sh" 2>&1)"; GRC=$?
if [ "$RC" = "0" ] && [ "$BEFORE" = "$AFTER" ] && [ -f "$REPO/docs/index.md" ] && [ "$GRC" = "0" ]; then
  pass "(d') .vault-exempt, dossier a espaces : ignore par l'outil (rc=0, INDEX.md intacts) et par le gardien (rc=0)"
else
  fail "(d') .vault-exempt : outil rc=$RC intact=$([ "$BEFORE" = "$AFTER" ] && echo oui || echo non) gardien rc=$GRC [$(printf '%s' "$GOUT" | head -c 300 | tr '\n' ' ')]"
fi

# --- (e) root outside any repository ------------------------------------------------------
ROOT="$TMP/e/loose"
mkdir -p "$ROOT/sub"
note x > "$ROOT/sub/x.md"
# Mission 234: the repository-root guard admits a throwaway folder below a
# temporary folder (Mission 231) -- and this test runs below one. The case is
# about a root outside ANY repository and outside any temporary folder: the
# guard is shown another temporary folder, never the one that holds $ROOT. It
# used to pass only because the guard's native Python could not resolve the
# /tmp/... path it was given (measured, full suite of Mission 234).
mkdir -p "$TMP/elsewhere-temp"
ELSE_TMP="$TMP/elsewhere-temp"
command -v cygpath >/dev/null 2>&1 && ELSE_TMP="$(cygpath -w "$ELSE_TMP")"
RC="$(env -u SB_TMP -u LOCALAPPDATA TMPDIR="$ELSE_TMP" TEMP="$ELSE_TMP" TMP="$ELSE_TMP" bash "$TOOLS/build-indexes.sh" "$ROOT" >"$TMP/out" 2>"$TMP/err"; echo $?)"
if [ "$RC" != "0" ] && [ -z "$(find "$ROOT" -name index.md)" ] && grep -q "REPO-ROOT-REFUSED" "$TMP/err"; then
  pass "(e) racine hors depot, sans acte : refusee, rien ecrit (open-211)"
else
  fail "(e) racine hors depot : rc=$RC index ecrits=$(find "$ROOT" -name index.md | wc -l | tr -d ' ') stderr=[$(head -c 200 "$TMP/err" | tr '\n' ' ')]"
fi
{ echo "# second-brain-birth-certificate: v1"; echo "# vault_id: sb-test-218"; echo "# vcs: none"; echo "repos: []"; } > "$ROOT/.pre-commit-config.yaml"
RC="$(build "$ROOT")"
if [ "$RC" = "0" ] && [ -f "$ROOT/sub/index.md" ]; then
  pass "(e) jumeau : la meme racine avec un acte de naissance est acceptee"
else
  fail "(e) jumeau : rc=$RC stderr=[$(head -c 200 "$TMP/err" | tr '\n' ' ')]"
fi

# --- (f) negative control of the checker itself -----------------------------------------
if printf 'nothing here\n' | grep -q "INDEX-CASE-COLLISION : .*exists and was not generated"; then
  fail "(f) temoin : le motif de (a) accepte une sortie sans refus"
else
  pass "(f) temoin : une sortie sans ligne de refus ne satisfait pas (a)"
fi

echo ""
echo "(systeme de fichiers insensible a la casse : $CI_FS)"
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
