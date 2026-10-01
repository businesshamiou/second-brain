#!/usr/bin/env bash
# P1 of report 227 (Mission 230): `second-brain update <version>` when the
# version changes the USER.md SKELETON.
#
# USER.md is the participant's own profile: the installer rewrites it whole
# from their answers (sb_installer_helper.py write-user-profile). The
# distributed file, on the version's side, is the empty skeleton. So the
# slightest change of that skeleton -- the `language:` line and the
# "neuf questions" description of v0.1.15 (Missions 218 and 221) -- conflicts
# with every installation on earth, and the update ends REFUSED: measured by
# the audit of Mission 227 on a copy of the company Vault and on a plain
# v0.1.14 participant.
#
# What the tool must do (Mission 230, trap a): keep the participant's side to
# the byte, and lose nothing of the new skeleton the participant has not
# filled in -- front-matter keys and section headings the skeleton adds are
# appended, never merged into a line the participant wrote. No other file of
# the participant is ever resolved silently.
#
# Fixture: a throwaway source with two tags built from this repository's HEAD.
#   v-old : USER.md = the skeleton as it stood up to v0.1.14 (no `language:`,
#           "sept questions");
#   v-new : USER.md = this tree's skeleton, plus a `## Contraintes` section --
#           a heading the participant cannot have, which proves the skeleton's
#           additions survive -- and an empty `## Profil de départ` (Mission
#           240): P carries a filled one (as `sb profile --order` writes it),
#           kept byte for byte and never doubled; E has none and gains it once.
# Two installations at v-old, each with its own filled profile:
#   P : a plain FR participant (accents, `## Liens` last);
#   E : a company-style profile -- a front-matter key of its own
#       (`organisation:`) and a section of its own (`## Notes`).
#
#   (a) P, update to v-new with the version's tool: UPDATED; every line the
#       participant wrote is still there, byte for byte; `language: fr` gained
#       (from the installer's carnet); `## Contraintes` gained; USER.md is
#       inside the merge commit; VAULT-IDENTITY.md and projects/ untouched;
#       porcelain empty.
#   (b) E: UPDATED; its own key and its own section kept; `language: es`
#       (its carnet), never the skeleton's empty value.
#   (c) idempotence: rebuilding the profile resolution changes nothing --
#       a second update says UP-TO-DATE, HEAD unchanged.
#   (d) another file of the participant in conflict (a corpus file they
#       edited) -> REFUSED naming that file, merge aborted, HEAD unchanged,
#       and USER.md NOT resolved behind the participant's back (its worktree
#       file is the one they wrote).
#   (e) RED witness, kept as it is: the tool of the installation itself
#       (v0.1.14, extracted from this repository's history) refuses, naming
#       USER.md -- which is why the update of an installation older than
#       v0.1.15 is run with the new version's tool and `--vault`. Skipped,
#       never failed, when that history is absent.
#
# usage: bash tests/test-update-user-profile-merge.sh
# Exit 0: all cases PASS. Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
SKIPS=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
skip() { echo "  SKIP - $1"; SKIPS=$((SKIPS + 1)); }
check() {
  local name="$1"
  shift
  if "$@"; then pass "$name"; else fail "$name"; fi
}
has() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m230-user-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"

quiet_commit() {
  # quiet_commit <repo> <message>: preflight stamp, then a guarded commit.
  bash "$1/tools/session-preflight.sh" >/dev/null 2>&1 || true
  git -C "$1" commit -q -m "$2" >"$TMP/commit.log" 2>&1 || { sed "s/^/      /" "$TMP/commit.log" | tail -n 15; return 1; }
}
install_commit() {
  # install_commit <repo> <message>: what the installer does -- indexes
  # rebuilt, every change staged path by path, then a guarded commit.
  bash "$1/tools/build-indexes.sh" "$1" >/dev/null 2>&1
  git -C "$1" status --porcelain | cut -c4- | while IFS= read -r p; do git -C "$1" add -- "$p"; done
  quiet_commit "$1" "$2"
}

echo "=== P1 : fusion du profil USER.md quand le gabarit change ==="

# --- Source with two tags -----------------------------------------------------
SRC="$TMP/source"
REF_CLONE="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "FAIL : clone de reference non construit"; exit 1; }
git -c core.longpaths=true clone -q -- "$REF_CLONE" "$SRC" 2>/dev/null || { echo "FAIL : source non construite"; exit 1; }
git -C "$SRC" config core.longpaths true
git -C "$SRC" config user.name fixture
git -C "$SRC" config user.email fixture@example.invalid
git -C "$SRC" tag -l | while IFS= read -r t; do git -C "$SRC" tag -d "$t" >/dev/null; done
# The published repository carries no generated identity: the skeleton.
cat > "$SRC/VAULT-IDENTITY.md" <<'EOF'
---
type: vault-identity
title: "Identity of this Vault — skeleton"
description: "Empty skeleton, replaced at installation by a generated identity (vault_id, vault_origin). No identity before installation."
status: template
vault_id: ""
vault_origin: ""
created_at: ""
---

# IDENTITY OF THIS VAULT

_(This file is generated at installation by `tools/vault-identity.sh ensure`. Before installation, it carries no identity: each installation generates its own.)_

## Liens

- `see also` — [Decision — Project initiation and adoption, birth certificate](./decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
EOF
NEW_SKELETON="$SRC/USER.md"
cp "$NEW_SKELETON" "$TMP/skeleton-new.md"
# v-old: the skeleton as it stood up to v0.1.14 -- no `language:` line, and
# the description that said "sept questions".
awk '
  /^language:$/ { next }
  /^description: "Squelette vide/ { sub(/neuf questions/, "sept questions") }
  { print }
' "$TMP/skeleton-new.md" > "$SRC/USER.md"
(
  cd "$SRC" || exit 1
  bash tools/build-indexes.sh "$PWD" >/dev/null 2>&1
  git add -A && git commit -q -m "fixture v-old" && git tag -a v-old -m v-old
) >/dev/null 2>&1 || { echo "FAIL : etiquette v-old non posee"; exit 1; }
# v-new: this tree's skeleton, plus a section the participant cannot have.
# It also changes one corpus file (RELEASE-NOTES.md), so case (d) has a real
# conflict to refuse on.
# Mission 240: v-new also carries an empty « ## Profil de départ » -- the
# hardest case for the starting profile: a participant who filled theirs with
# `sb profile --order` keeps it byte for byte, never duplicated nor replaced by
# the skeleton's; a participant without one gains the heading once.
awk '
  /^## Liens$/ && !done {
    print "## Profil de départ"
    print ""
    print "_(à remplir)_"
    print ""
    print "## Contraintes"
    print ""
    print "_(à remplir)_"
    print ""
    done = 1
  }
  { print }
' "$TMP/skeleton-new.md" > "$SRC/USER.md"
sed '1s/.*/NEW RELEASE LINE/' "$SRC/RELEASE-NOTES.md" > "$SRC/.rn" && mv "$SRC/.rn" "$SRC/RELEASE-NOTES.md"
(
  cd "$SRC" || exit 1
  bash tools/build-indexes.sh "$PWD" >/dev/null 2>&1
  git add -A && git commit -q -m "fixture v-new" && git tag -a v-new -m v-new
) >/dev/null 2>&1 || { echo "FAIL : etiquette v-new non posee"; exit 1; }
VNEW="$(git -C "$SRC" rev-parse 'v-new^{commit}')"
check "source : v-old sans « language: », v-new avec « language: » et « ## Contraintes »" sh -c "
  git -C '$SRC' show v-old:USER.md | grep -q '^language:' && exit 1
  git -C '$SRC' show v-new:USER.md | grep -q '^language:' || exit 1
  git -C '$SRC' show v-new:USER.md | grep -q '^## Contraintes\$' || exit 1
  exit 0"

# --- Two installations at v-old ------------------------------------------------
# profile_participant <path>: USER.md as the v0.1.14 generator wrote it --
# accents, no `language:` key.
profile_participant() {
  cat > "$1" <<'EOF'
---
type: profile
title: "Fiche utilisateur — Amélie"
description: "Rédigée par le questionnaire d'installation (Mission 168, tickets 05 et 08), à partir des réponses données le 2026-06-01T09:00:00-04:00."
status: active
---

# FICHE UTILISATEUR

## Qui

- **Prénom :** Amélie
- **Langue de travail :** français (FR)

## Activité

Éditrice indépendante, spécialisée en récits brefs.

## Façon de travailler

- **Outils IA :** claude, codex
- **Ce qui compte :** La simplicité

## Environnement

- **Système :** Windows 11
- **Shell :** bash
- **Fuseau horaire :** America/Montreal
- **Git :** 2.47.0
- **Claude Code détecté :** True
- **Codex détecté :** False

## Origine

- **Assistant :** Ibrahim
- **Espace de travail :** C:\Workspaces
- **Installé le :** 2026-06-01T09:00:00-04:00

## Profil de départ

- **Ce que je fais :** Éditrice indépendante, spécialisée en récits brefs.
- **Ce qui compte pour moi :** La simplicité
- **Trois casse-têtes du moment :** trésorerie · relances · agenda
- **Rythme de revue :** chaque lundi matin
- **Outils du quotidien :** claude, codex, Gmail
- **Mis à jour le :** 2026-09-27

## Liens

- `see also` — [AGENTS.md](./AGENTS.md)
EOF
}
# profile_company <path>: a company-style profile -- a front-matter key of
# its own and a section of its own, both of which must survive.
profile_company() {
  cat > "$1" <<'EOF'
---
type: profile
title: "Fiche utilisateur — Équipe"
description: "Rédigée à l'installation, puis complétée à la main par l'équipe."
status: active
organisation: "Atelier Nord"
---

# FICHE UTILISATEUR

## Qui

- **Prénom :** Équipe
- **Langue de travail :** español (ES)

## Activité

Six chantiers, un dossier par chantier.

## Façon de travailler

- **Outils IA :** claude
- **Ce qui compte :** Une trace de chaque geste

## Environnement

- **Système :** Windows 11
- **Shell :** bash
- **Fuseau horaire :** America/Montreal
- **Git :** 2.47.0
- **Claude Code détecté :** True
- **Codex détecté :** True

## Origine

- **Assistant :** Brian
- **Espace de travail :** C:\Atelier
- **Installé le :** 2026-05-02T11:30:00-04:00

## Notes

Écrites par l'équipe, jamais par un outil.

## Liens

- `see also` — [AGENTS.md](./AGENTS.md)
EOF
}

make_installation() {
  # make_installation <dir> <profile-writer> <carnet-language> <assistant>
  local V="$1" writer="$2" lang="$3" name="$4" slug ws
  ws="$(dirname "$V")"
  mkdir -p "$ws"
  git clone -q -- "$SRC" "$V" 2>/dev/null || return 1
  git -C "$V" -c advice.detachedHead=false checkout -q --detach v-old || return 1
  git -C "$V" config user.name "Participant"
  git -C "$V" config user.email participant@example.invalid
  git -C "$V" config core.longpaths true
  git -C "$V" config core.hooksPath .githooks
  bash "$V/tools/vault-identity.sh" ensure "$V" >/dev/null
  install_commit "$V" "Generate vault identity" || return 1
  slug="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
  mkdir -p "$V/.install"
  printf '{"schemaVersion": 1, "answers": {"language": "%s", "vaultName": "%s"}, "steps": {"assistantGenerated": true}, "assistant": {"name": "%s", "slug": "%s"}}\n' \
    "$lang" "$name" "$name" "$slug" > "$V/.install/state.json"
  uv run --no-project "$V/tools/sb_installer_helper.py" render-assistant "$V" "$name" --language "$lang" >/dev/null 2>&1 || return 1
  install_commit "$V" "Generate assistant forms for '$name'" || return 1
  "$writer" "$V/USER.md"
  install_commit "$V" "Write user profile from installer answers" || return 1
  bash "$V/tools/write-marker.sh" "$ws" >/dev/null
  # The installers' historical call (Mission 244: an explicit create commits by
  # itself; the installer's call leaves the registration to the commit below).
  bash "$V/tools/project-bootstrap.sh" "$ws/projet" "Projet" >/dev/null 2>&1 </dev/null
  install_commit "$V" "Register first project: projet" || return 1
  [ -z "$(git -C "$V" status --porcelain)" ]
}

P="$TMP/ws-p/second-brain"
E="$TMP/ws-e/second-brain"
check "installation P (participant FR) : posee a v-old, arbre propre" make_installation "$P" profile_participant FR Ibrahim
check "installation E (profil d'entreprise) : posee a v-old, arbre propre" make_installation "$E" profile_company ES Brian

# The version's own tool, run from a clone of the version (what the published
# line of a new version prints for an existing installation).
NEWV="$TMP/new-version"
git clone -q -- "$SRC" "$NEWV" 2>/dev/null && git -C "$NEWV" -c advice.detachedHead=false checkout -q --detach v-new
UPDATE="$NEWV/tools/second-brain-update.sh"

# lines_kept <file> <reference>: every line of <reference> is still in <file>,
# in the same order, byte for byte (the participant's side is never rewritten).
lines_kept() {
  local ref="$2" f="$1"
  # `comm` on sorted lines would miss an order change; diff of the reference
  # against the result, keeping only removals, is exact.
  [ -z "$(diff "$ref" "$f" | grep '^<')" ]
}

update_case() {
  # update_case <vault> <label> <expected-language> [extra-grep...]
  local V="$1" label="$2" lang="$3"
  shift 3
  local head0 id0 proj snap0 out rc
  head0="$(git -C "$V" rev-parse HEAD)"
  id0="$(bash "$V/tools/vault-identity.sh" get vault_id "$V")"
  proj="$(cd "$V/.." && pwd)/projet"
  snap0="$(git -C "$proj" rev-parse HEAD 2>/dev/null)"
  cp "$V/USER.md" "$TMP/$label.user.before"
  out="$(bash "$UPDATE" v-new --vault "$V" --lang FR 2>&1)"
  rc=$?
  printf '%s\n' "$out" | tail -n 3 | sed 's/^/    /'
  check "($label) VERDICT: UPDATED, sortie 0" sh -c "[ '$rc' = '0' ] && case \"\$1\" in *'VERDICT: UPDATED'*) exit 0;; *) exit 1;; esac" _ "$out"
  check "($label) HEAD = fusion, second parent = v-new" sh -c "[ \"\$(git -C '$V' rev-parse HEAD^2 2>/dev/null)\" = '$VNEW' ] && [ \"\$(git -C '$V' rev-parse HEAD^1)\" = '$head0' ]"
  check "($label) USER.md : toutes les lignes du participant gardees, a l'octet" lines_kept "$V/USER.md" "$TMP/$label.user.before"
  check "($label) USER.md : « language: $lang » acquise du nouveau gabarit" sh -c "grep -qx 'language: $lang' '$V/USER.md'"
  check "($label) USER.md : « ## Contraintes » acquise du nouveau gabarit" sh -c "grep -qx '## Contraintes' '$V/USER.md'"
  check "($label) USER.md : « ## Profil de départ » present une seule fois" sh -c "[ \"\$(grep -cx '## Profil de départ' '$V/USER.md')\" = 1 ]"
  check "($label) USER.md : « ## Liens » reste la derniere section" sh -c "[ \"\$(grep -n '^## ' '$V/USER.md' | tail -n 1 | cut -d: -f2-)\" = '## Liens' ]"
  check "($label) USER.md : dans le commit de fusion" sh -c "! git -C '$V' diff --quiet HEAD^1 HEAD -- USER.md"
  check "($label) identite inchangee, projet intact, porcelain vide" sh -c "
    [ \"\$(bash '$V/tools/vault-identity.sh' get vault_id '$V')\" = '$id0' ] &&
    [ \"\$(git -C '$proj' rev-parse HEAD 2>/dev/null)\" = '$snap0' ] &&
    [ -z \"\$(git -C '$V' status --porcelain)\" ]"
  check "($label) corpus = v-new (tools, rules, templates, skills)" git -C "$V" diff --quiet v-new HEAD -- tools rules templates skills
}

# --- (a) the plain participant, (b) the company-style profile ------------------
update_case "$P" a fr
# Mission 240: P's filled starting profile, byte for byte and in place (the
# lines_kept check above covers every line; this names the section), never the
# skeleton's placeholder.
check "(a) « ## Profil de départ » du participant garde a l'octet, sans le gabarit vide" sh -c "
  awk '/^## Profil de départ\$/ { f = 1; next } f && /^## / { exit } f' '$P/USER.md' > '$TMP/a.profile.after'
  awk '/^## Profil de départ\$/ { f = 1; next } f && /^## / { exit } f' '$TMP/a.user.before' > '$TMP/a.profile.before'
  cmp -s '$TMP/a.profile.before' '$TMP/a.profile.after' && ! grep -q 'à remplir' '$TMP/a.profile.after' &&
  grep -qF 'trésorerie · relances · agenda' '$TMP/a.profile.after'"
update_case "$E" b es
check "(b) cle propre « organisation: » gardee, section « ## Notes » gardee" sh -c "
  grep -q '^organisation:' '$E/USER.md' && grep -qx '## Notes' '$E/USER.md'"

# --- (c) idempotence -----------------------------------------------------------
P_HEAD="$(git -C "$P" rev-parse HEAD)"
OUT_C="$(bash "$P/tools/second-brain-update.sh" v-new --lang FR 2>&1)"
check "(c) second passage : UP-TO-DATE, HEAD et arbre inchanges" sh -c "
  case \"\$1\" in *'VERDICT: UP-TO-DATE'*) ;; *) exit 1;; esac
  [ \"\$(git -C '$P' rev-parse HEAD)\" = '$P_HEAD' ] && [ -z \"\$(git -C '$P' status --porcelain)\" ]" _ "$OUT_C"

# --- (d) another file of the participant in conflict: never resolved silently --
D="$TMP/ws-d/second-brain"
check "installation D : posee a v-old, arbre propre" make_installation "$D" profile_participant FR Ibrahim
printf 'LOCAL EDIT OF THE FIRST LINE\n' > "$D/.l" && tail -n +2 "$D/RELEASE-NOTES.md" >> "$D/.l" && mv "$D/.l" "$D/RELEASE-NOTES.md"
install_commit "$D" "local edit of a corpus file" || fail "installation D : commit local non fait"
D_HEAD="$(git -C "$D" rev-parse HEAD)"
cp "$D/USER.md" "$TMP/d.user.before"
OUT_D="$(bash "$UPDATE" v-new --vault "$D" --lang FR 2>&1)"
RC_D=$?
check "(d) autre fichier en conflit : REFUSED, sortie 1" sh -c "[ '$RC_D' = '1' ] && case \"\$1\" in *'VERDICT: REFUSED'*) exit 0;; *) exit 1;; esac" _ "$OUT_D"
check "(d) le fichier est nomme (RELEASE-NOTES.md)" has "$OUT_D" "RELEASE-NOTES.md"
check "(d) fusion abandonnee : HEAD et arbre inchanges" sh -c "
  [ \"\$(git -C '$D' rev-parse HEAD)\" = '$D_HEAD' ] && [ -z \"\$(git -C '$D' status --porcelain)\" ]"
check "(d) USER.md non resolu en silence (identique a l'octet)" cmp -s "$D/USER.md" "$TMP/d.user.before"

# --- (e) RED witness: the tool of the installation itself (v0.1.14) ------------
OLD="$TMP/old-tool"
if git -C "$REPO_ROOT" cat-file -e 'v0.1.14^{commit}' 2>/dev/null \
  && mkdir -p "$OLD" && git -C "$REPO_ROOT" archive v0.1.14 tools i18n 2>/dev/null | tar -x -C "$OLD"; then
  W="$TMP/ws-w/second-brain"
  if make_installation "$W" profile_participant FR Ibrahim; then
    W_HEAD="$(git -C "$W" rev-parse HEAD)"
    cp "$W/USER.md" "$TMP/w.user.before"
    OUT_E="$(bash "$OLD/tools/second-brain-update.sh" v-new --vault "$W" --lang FR 2>&1)"
    RC_E=$?
    check "(e) temoin : l'outil de l'installation (v0.1.14) refuse, sortie 1" sh -c "[ '$RC_E' = '1' ] && case \"\$1\" in *'VERDICT: REFUSED'*) exit 0;; *) exit 1;; esac" _ "$OUT_E"
    check "(e) temoin : USER.md est nomme dans le refus" has "$OUT_E" "USER.md"
    check "(e) temoin : HEAD, arbre et profil inchanges" sh -c "
      [ \"\$(git -C '$W' rev-parse HEAD)\" = '$W_HEAD' ] &&
      [ -z \"\$(git -C '$W' status --porcelain)\" ] &&
      cmp -s '$W/USER.md' '$TMP/w.user.before'"
  else
    skip "(e) temoin : installation W non construite"
  fi
else
  skip "(e) temoin : l'etiquette v0.1.14 n'est pas dans cet historique"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS, $SKIPS SKIP) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS, $SKIPS SKIP) ==="
exit 1
