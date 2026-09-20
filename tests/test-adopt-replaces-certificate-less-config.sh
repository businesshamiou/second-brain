#!/usr/bin/env bash
# Mission 203, fix 3 (report 202, A4 and A6): `project-bootstrap.sh adopt` on a
# folder whose .pre-commit-config.yaml has NO birth certificate.
#
# Before: the config was left as it was, the certificate was only printed for the
# human to paste, no baseline was written, and -- when the project had no state/ --
# the generated state/PILOT-PROMPT.md carried EMPTY links (rel_path was computed
# before the mkdir of state/).
#
# Oracles (PASS expected):
#   (a) a config holding nothing but Vault guardians (`repo:` + `rev:` +
#       `vault-check-*` ids) is REPLACED by the certificate form: certificate v1,
#       `repo: local`, four local entries, the baseline named by the certificate;
#   (b) the old config is cited in full on the output and kept beside it, dated,
#       byte for byte (`.pre-commit-config.yaml.before-adopt-<date>`);
#   (c) the dated baseline file exists and lists the folder's files;
#   (d) state/PILOT-PROMPT.md has no empty link, in a project that had no state/;
#   (e) a second `adopt` leaves the new config as it is (idempotent, no new copy);
#   (f) a config that carries anything else (a hook of the project) is NEVER
#       replaced: unchanged bytes, no copy, no baseline, the certificate returned;
#   (g) the old tool (commit f34b405): config unchanged, no baseline, empty links --
#       the defects reproduced, when that history is available.
#
# Writes only in a temporary folder (prefix m203-adopt).
#
# usage: bash tests/test-adopt-replaces-certificate-less-config.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable -- tools/project-bootstrap.sh en depend"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m203-adopt-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

mkdir -p "$TMP/bin"
cat > "$TMP/bin/pre-commit" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "install" ]; then
  hooks="$(git rev-parse --git-path hooks)" || exit 1
  mkdir -p "$hooks"
  printf '#!/usr/bin/env bash\n# substitut de test\nexit 0\n' > "$hooks/pre-commit"
  exit 0
fi
exit 0
STUB
chmod +x "$TMP/bin/pre-commit"
PATH="$TMP/bin:$PATH"
export PATH

WS="$TMP/ws"
mkdir -p "$WS"
V="$WS/second-brain"
if ! sandbox_vault "$REPO_ROOT" "$V"; then
  echo "FAIL : Vault jetable non construit"
  exit 1
fi
bash "$V/tools/write-marker.sh" "$WS" >/dev/null

OLD_CONFIG='repos:
  - repo: https://github.com/example/vault
    rev: 628a9dc7bcc3d4f651cad20753d680008b7220da
    hooks:
      - id: vault-check-secrets
      - id: vault-check-indexes-fresh
      - id: vault-check-links
'
FOREIGN_CONFIG="$OLD_CONFIG"'  - repo: https://github.com/example/lint
    rev: v1.0.0
    hooks:
      - id: project-lint
'

# make_old_project <dir> <config text>: an existing folder with Git, a note, and that config.
make_old_project() {
  mkdir -p "$1"
  printf '# notes\n\n## Liens\n\n- `see also` — [notes](notes.md)\n' > "$1/notes.md"
  printf '%s' "$2" > "$1/.pre-commit-config.yaml"
  (cd "$1" && git init -q -b main 2>/dev/null || git init -q; git config user.email t@example.invalid; git config user.name t; git config core.autocrlf false; git add -A; git commit -q -m init)
}

sha() { cksum < "$1"; }

# --- (a)-(e): a config with nothing but Vault guardians ------------------------------
P="$WS/projet-a"
make_old_project "$P" "$OLD_CONFIG"
BEFORE="$(sha "$P/.pre-commit-config.yaml")"
OUT="$(bash "$V/tools/project-bootstrap.sh" adopt "$P" "Projet A" FR --vcs git 2>&1 </dev/null)"; RC=$?
[ "$RC" = "0" ] && pass "adopt rend 0" || fail "adopt rend $RC"
CONF="$P/.pre-commit-config.yaml"
if [ "$(head -n 1 "$CONF" | tr -d '\r')" = "# second-brain-birth-certificate: v1" ] \
   && grep -q '^# vault_id: ' "$CONF" && grep -q '^# vcs: git' "$CONF" \
   && [ "$(grep -c 'repo: local' "$CONF")" = "1" ] \
   && [ "$(grep -c 'entry: .*tools/check-.*\.sh' "$CONF")" = "4" ]; then
  pass "(a) config remplacee : certificat v1, repo: local, quatre entrees locales"
else
  fail "(a) config non remplacee : $(head -n 2 "$CONF" | tr '\n' '|')"
fi
COPY="$(ls "$P"/.pre-commit-config.yaml.before-adopt-* 2>/dev/null | head -n 1)"
if [ -n "$COPY" ] && [ "$(sha "$COPY")" = "$BEFORE" ]; then
  pass "(b) copie datee de l'ancienne config, identique octet pour octet ($(basename "$COPY"))"
else
  fail "(b) copie datee absente ou differente"
fi
if printf '%s\n' "$OUT" | grep -q 'rev: 628a9dc7bcc3d4f651cad20753d680008b7220da' && printf '%s\n' "$OUT" | grep -q 'vault-check-links'; then
  pass "(b) l'ancienne config est citee en entier sur la sortie"
else
  fail "(b) l'ancienne config n'est pas citee sur la sortie"
fi
BL="$(sed -n 's/^# baseline: //p' "$CONF" | head -n 1)"
if [ -n "$BL" ] && [ -f "$P/$BL" ] && grep -q "notes.md" "$P/$BL"; then
  pass "(c) ligne de base ecrite et nommee par l'acte ($BL)"
else
  fail "(c) ligne de base absente ou non nommee (cle : '$BL')"
fi
EMPTY="$(grep -c '\]()' "$P/state/PILOT-PROMPT.md")"
LINKS="$(grep -c '\](\.\./' "$P/state/PILOT-PROMPT.md")"
if [ "$EMPTY" = "0" ] && [ "$LINKS" -ge 2 ]; then
  pass "(d) PILOT-PROMPT.md : aucun lien vide, $LINKS lignes a lien resolu (projet sans state/)"
else
  fail "(d) PILOT-PROMPT.md : $EMPTY lien(s) vide(s), $LINKS ligne(s) a lien"
fi
AFTER1="$(sha "$CONF")"; NCOPY1="$(ls "$P"/.pre-commit-config.yaml.before-adopt-* | wc -l | tr -d ' ')"
bash "$V/tools/project-bootstrap.sh" adopt "$P" "Projet A" FR --vcs git >/dev/null 2>&1 </dev/null
if [ "$(sha "$CONF")" = "$AFTER1" ] && [ "$(ls "$P"/.pre-commit-config.yaml.before-adopt-* | wc -l | tr -d ' ')" = "$NCOPY1" ]; then
  pass "(e) second adopt : config inchangee, aucune nouvelle copie"
else
  fail "(e) second adopt : la config ou les copies ont change"
fi

# --- (f): a config carrying anything else is never replaced ---------------------------
P="$WS/projet-f"
make_old_project "$P" "$FOREIGN_CONFIG"
BEFORE="$(sha "$P/.pre-commit-config.yaml")"
OUT="$(bash "$V/tools/project-bootstrap.sh" adopt "$P" "Projet F" FR --vcs git 2>&1 </dev/null)"
if [ "$(sha "$P/.pre-commit-config.yaml")" = "$BEFORE" ] \
   && [ -z "$(ls "$P"/.pre-commit-config.yaml.before-adopt-* 2>/dev/null)" ] \
   && [ -z "$(ls "$P"/.vault-baseline-*.tsv 2>/dev/null)" ] \
   && printf '%s\n' "$OUT" | grep -q '^# second-brain-birth-certificate: v1'; then
  pass "(f) un crochet du projet dans la config : jamais remplacee, l'acte est rendu a coller"
else
  fail "(f) config a crochet de projet : remplacee, copiee ou baselinee a tort"
fi

# --- (g): the old tool, the defects reproduced ----------------------------------------
if git -C "$REPO_ROOT" cat-file -e 'f34b405^{commit}' 2>/dev/null; then
  git -C "$REPO_ROOT" show f34b405:tools/project-bootstrap.sh > "$V/tools/project-bootstrap-before.sh"
  P="$WS/projet-g"
  make_old_project "$P" "$OLD_CONFIG"
  BEFORE="$(sha "$P/.pre-commit-config.yaml")"
  bash "$V/tools/project-bootstrap-before.sh" adopt "$P" "Projet G" FR --vcs git >/dev/null 2>&1 </dev/null
  if [ "$(sha "$P/.pre-commit-config.yaml")" = "$BEFORE" ] \
     && [ -z "$(ls "$P"/.vault-baseline-*.tsv 2>/dev/null)" ] \
     && [ "$(grep -c '\]()' "$P/state/PILOT-PROMPT.md")" -ge 1 ]; then
    pass "(g) temoin rouge : l'ancien outil laisse la config, n'ecrit aucune base, genere des liens vides"
  else
    fail "(g) temoin rouge : l'ancien outil ne reproduit pas le defaut"
  fi
else
  echo "  SKIP - (g) l'historique f34b405 est absent de ce clone : temoin rouge non joue"
fi

echo ""
echo "RESULT: $PASSES PASS, $FAILURES FAIL"
[ "$FAILURES" = "0" ]
