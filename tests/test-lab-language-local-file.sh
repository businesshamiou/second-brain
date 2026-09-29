#!/usr/bin/env bash
# Mission 219, lot C (Owner arbitration of 2026-09-23 09:08, Decision
# 2026-09-23-105507): the laboratory speaks French through a LOCAL file that
# is never versioned nor published -- `USER.local.yaml` at the Vault root, one
# line `language: <fr|en|es>` -- read before USER.md; the distributed USER.md
# skeleton stays empty. And every reader of USER.md's front matter tolerates
# the UTF-8 byte-order mark Windows PowerShell 5.1 writes (A4, Mission 218).
#
#   (a) skeleton USER.md (no language) + USER.local.yaml `language: fr`
#       -> project-bootstrap.sh renders `language: "fr"` in the Pilot prompt;
#   (b) USER.md `language: es` + USER.local.yaml `language: fr` -> "fr": the
#       local file is read first; the same with a BOM at the head of the local
#       file (a file saved by Notepad);
#   (c) no local file -> the Mission 218 behaviour, unchanged: skeleton gives
#       `language: ""`, USER.md `language: es` gives "es";
#   (d) USER.local.yaml is ignored by Git (.gitignore of the distribution);
#   (e) the distribution manifest check refuses USER.local.yaml, named, even
#       force-added and listed DISTRIBUABLE; witness: the same manifest
#       without that line passes;
#   (f) BOM at the head of USER.md: the index entry keeps its title and
#       status (build_indexes.py) and the freshness guardian agrees with it;
#       find-in-vault.sh --frontmatter-only finds its `language:` line;
#   (g) BOM at the head of a rules/ document: check-asserted-paths.sh still
#       reads its type and examines it (an unresolved path is refused);
#       witness: the same document without BOM is refused the same way;
#   (h) BOM at the head of a document: check-obsolescence-guardrail.py reads
#       its front matter (its `supersedes:` is seen).
#
# usage: bash tests/test-lab-language-local-file.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() { local n="$1"; shift; if "$@"; then pass "$n"; else fail "$n"; fi; }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m219-local-lang-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/bin/pre-commit"
chmod +x "$TMP/bin/pre-commit"
PATH="$TMP/bin:$PATH"; export PATH

BOM="$(printf '\357\273\277')"
WS="$TMP/ws"; V="$WS/second-brain"
mkdir -p "$WS"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" --marker-only "$WS" >/dev/null || { echo "FAIL : marqueur"; exit 1; }
BOOT="$V/tools/project-bootstrap.sh"
SKELETON="$(cat "$V/USER.md")"
pp_lang() { tr -d '\r' < "$1/state/PILOT-PROMPT.md" | sed -n 's/^language: "\(.*\)"$/\1/p' | head -n 1; }
user_es() { printf '%s\n' "$SKELETON" | sed 's/^language:.*$/language: es/' > "$V/USER.md"; }

# --- (c) first, without the local file: Mission 218 unchanged ----------------------------------
rm -f "$V/USER.local.yaml"
bash "$BOOT" create "$WS/c1" "C1" --vcs none >"$TMP/c1.out" 2>&1
check "(c) sans fichier local, squelette : language \"\"" [ "$(pp_lang "$WS/c1")" = "" ]
user_es
bash "$BOOT" create "$WS/c2" "C2" --vcs none >"$TMP/c2.out" 2>&1
check "(c) sans fichier local, USER.md es : language \"es\"" [ "$(pp_lang "$WS/c2")" = "es" ]

# --- (a) skeleton + local fr -------------------------------------------------------------------
printf '%s\n' "$SKELETON" > "$V/USER.md"
printf 'language: fr\n' > "$V/USER.local.yaml"
bash "$BOOT" create "$WS/a1" "A1" --vcs none >"$TMP/a1.out" 2>&1
check "(a) squelette + USER.local.yaml fr : language \"fr\"" [ "$(pp_lang "$WS/a1")" = "fr" ]
check "(a) le squelette USER.md n'a pas ete ecrit" [ "$(cat "$V/USER.md")" = "$SKELETON" ]

# --- (b) local read first, BOM tolerated ---------------------------------------------------------
user_es
bash "$BOOT" create "$WS/b1" "B1" --vcs none >"$TMP/b1.out" 2>&1
check "(b) USER.md es + USER.local.yaml fr : fr (le fichier local d'abord)" [ "$(pp_lang "$WS/b1")" = "fr" ]
printf '%slanguage: fr\r\n' "$BOM" > "$V/USER.local.yaml"
bash "$BOOT" create "$WS/b2" "B2" --vcs none >"$TMP/b2.out" 2>&1
check "(b) USER.local.yaml avec BOM et CRLF : fr" [ "$(pp_lang "$WS/b2")" = "fr" ]
printf '%s\n' "$SKELETON" > "$V/USER.md"

# --- (d) ignored by Git ------------------------------------------------------------------------
check "(d) USER.local.yaml ignore par Git (.gitignore)" git -C "$V" check-ignore -q USER.local.yaml
check "(d) USER.local.yaml absent de git status" sh -c "[ -z \"\$(git -C '$V' status --porcelain -- USER.local.yaml)\" ]"

# --- (e) the distribution manifest refuses it --------------------------------------------------
( cd "$V" && bash tools/check-distribution-manifest.sh >"$TMP/e0.out" 2>&1 ); E0=$?
check "(e) temoin : manifeste du Vault jetable accepte sans le fichier local (rc=$E0)" [ "$E0" = 0 ]
git -C "$V" add -f USER.local.yaml >/dev/null 2>&1
printf 'USER.local.yaml\tDISTRIBUABLE\n' >> "$V/distribution-manifest.txt"
( cd "$V" && bash tools/check-distribution-manifest.sh >"$TMP/e1.out" 2>&1 ); E1=$?
check "(e) USER.local.yaml force et liste DISTRIBUABLE : refuse (rc=$E1)" [ "$E1" != 0 ]
check "(e) le refus nomme le fichier local" grep -q "USER.local.yaml" "$TMP/e1.out"
check "(e) le refus dit pourquoi (local, never distributed)" grep -qi "local.*never\|never.*distribut" "$TMP/e1.out"
git -C "$V" rm -q --cached USER.local.yaml >/dev/null 2>&1
git -C "$V" checkout -q -- distribution-manifest.txt 2>/dev/null || sed -i '/^USER.local.yaml\t/d' "$V/distribution-manifest.txt"

# --- (f) BOM at the head of USER.md: indexes and search ------------------------------------------------
{ printf '%s' "$BOM"; printf '%s\n' "$SKELETON" | sed 's/^language:.*$/language: fr/'; } > "$V/USER.md"
( cd "$V" && bash tools/build-indexes.sh . >/dev/null 2>&1 )
ENTRY="$(grep '`USER.md`' "$V/index.md")"
check "(f) index.md : l'entree USER garde type et titre malgre le BOM [$ENTRY]" \
  sh -c "printf '%s' \"\$1\" | grep -qv 'inconnu' && printf '%s' \"\$1\" | grep -qv '(sans titre)'" _ "$ENTRY"
( cd "$V" && git add -- USER.md index.md >/dev/null 2>&1 && bash tools/check-indexes-fresh.sh >"$TMP/f.out" 2>&1 ); F=$?
check "(f) gardien de fraicheur d'accord avec l'index (rc=$F)" [ "$F" = 0 ]
FOUND="$(bash "$V/tools/find-in-vault.sh" --root "$V" --frontmatter-only '^language: fr' 2>/dev/null | grep -c 'USER.md')"
check "(f) find-in-vault.sh --frontmatter-only trouve la langue de USER.md avec BOM ($FOUND)" [ "$FOUND" -ge 1 ]

# --- (g) BOM at the head of a rules/ document: asserted paths ------------------------------------------
mkrule() { # mkrule <file> <bom:0|1>
  { [ "$2" = 1 ] && printf '%s' "$BOM"
    printf -- '---\ntype: rules\ntitle: "x"\ndescription: "x"\nstatus: active\n---\n\n# X\n\nSee `tools/no-such-tool-219.sh`.\n\n## Liens\n\n- `see also` — [AGENTS](../AGENTS.md)\n'; } > "$1"
}
for b in 0 1; do
  G="$V/rules/RULES-2026-09-23-000000-bom$b.md"
  mkrule "$G" "$b"
  ( cd "$V" && git add -- "rules/RULES-2026-09-23-000000-bom$b.md" >/dev/null 2>&1 && bash tools/check-asserted-paths.sh >"$TMP/g$b.out" 2>&1 ); GRC=$?
  ( cd "$V" && git rm -q --cached -- "rules/RULES-2026-09-23-000000-bom$b.md" >/dev/null 2>&1 ); rm -f "$G"
  if [ "$b" = 0 ]; then
    check "(g) temoin sans BOM : chemin affirme inexistant refuse (rc=$GRC)" sh -c "[ '$GRC' != 0 ] && grep -q no-such-tool-219 '$TMP/g0.out'"
  else
    check "(g) avec BOM : le document reste dans le perimetre, chemin refuse (rc=$GRC)" sh -c "[ '$GRC' != 0 ] && grep -q no-such-tool-219 '$TMP/g1.out'"; grep -q no-such-tool-219 "$TMP/g1.out" || sed "s/^/      g1: /" "$TMP/g1.out" | head -5
  fi
done

# --- (h) BOM: the reciprocity guardian reads the front matter ------------------------------------------
HP="$(sandbox_native_path "$V/tools/check-obsolescence-guardrail.py" 2>/dev/null || printf '%s' "$V/tools/check-obsolescence-guardrail.py")"
HOUT="$(uv run --no-project python - "$HP" <<'PY' 2>&1
import importlib.util, sys
spec = importlib.util.spec_from_file_location("guard", sys.argv[1])
m = importlib.util.module_from_spec(spec); sys.modules["guard"] = m; spec.loader.exec_module(m)
fm, _ = m.parse_front_matter("﻿---\ntype: rules\nsupersedes: \"old.md\"\n---\n# X\n")
print("SUPERSEDES=" + str((fm or {}).get("supersedes")))
PY
)"
check "(h) check-obsolescence-guardrail.py lit le front matter malgre le BOM [$HOUT]" sh -c "printf '%s' \"\$1\" | grep -q 'SUPERSEDES=old.md'" _ "$HOUT"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
