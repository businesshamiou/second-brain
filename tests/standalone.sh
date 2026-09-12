#!/usr/bin/env bash
# Essai d'autonomie du Vault (Mission 142) : prouve qu'un clone du Vault,
# pose seul a cote d'un projet et SANS depot frere sur disque, sait
# s'installer, commiter en passant ses gardiens, et ranger.
#
# usage: tests/standalone.sh [<dossier de travail>]
#   defaut : dossier temporaire du systeme (mktemp -d), jamais un sibling
#   suppose du Vault (ticket 02, Mission 168 : plus de dependance a la
#   geometrie de l'ancien atelier dans les tests).
#
# N'ecrit QUE dans le dossier de travail. Ne touche ni au Vault courant, ni a
# aucun depot existant. exit 0 seulement si (a) a (d) passent ; (e) est un
# releve, jamais un echec.
set -u

VAULT_SRC="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR="${1:-$(mktemp -d -t standalone-142-XXXXXX)}"
mkdir -p "$WORKDIR" || exit 1
WORKDIR="$(cd "$WORKDIR" && pwd)"
LOG="$WORKDIR/standalone.log"
FAIL=0

say() { printf '%s\n' "$*" | tee -a "$LOG"; }
step() { printf '\n=== %s ===\n' "$*" | tee -a "$LOG"; }

say "Vault source : $VAULT_SRC"
say "Dossier de travail : $WORKDIR"

# --- (a) clone jetable, projet a cote, marqueur de racine -------------------
step "(a) clone et projet"
# Option EPHEMERE, jamais ecrite dans aucune config (arbitrage Owner
# 2026-09-05) : sur cette machine, le .git du Vault appartient a un autre
# compte que l'utilisateur courant, et Git refuse alors de cloner
# (« dubious ownership »). Dependance machine a corriger avant cutover ;
# `-c` ne survit pas a la commande.
git -c safe.directory="$VAULT_SRC/.git" -c safe.directory="$VAULT_SRC" \
    clone -q "$VAULT_SRC" "$WORKDIR/second-brain" 2>&1 | tee -a "$LOG"
[ -d "$WORKDIR/second-brain/.git" ] || { say "ECHEC (a) : clone absent"; exit 1; }

# Marqueur de racine : ecrit par l'outil du Vault depuis son gabarit, jamais
# par substitution improvisee (usage lu : write-marker.sh <racine> [nom]).
if [ -f "$WORKDIR/second-brain/tools/write-marker.sh" ]; then
  ( cd "$WORKDIR/second-brain" && bash tools/write-marker.sh "$WORKDIR" ) 2>&1 | tee -a "$LOG"
else
  say "ECHEC (a) : tools/write-marker.sh absent du clone"
  exit 1
fi
[ -f "$WORKDIR/VAULT-ROOT.md" ] || { say "ECHEC (a) : VAULT-ROOT.md non ecrit"; exit 1; }

# Projet voisin, cree par l'outil du Vault lui-meme (ticket 02, Mission 168) :
# dossier de test temporaire, sans dependance a un projet reel du poste
# (l'ancien nom de dossier prive qu'un projet voisin portait autrefois) ni a
# un nom de dossier de l'ancien atelier -- la racine se trouve par le
# marqueur pose ci-dessus, jamais en dur.
PROJECT_NAME="projet-voisin"
if bash "$WORKDIR/second-brain/tools/project-bootstrap.sh" "$WORKDIR/$PROJECT_NAME" "Projet voisin" >>"$LOG" 2>&1; then
  say "projet voisin cree : $WORKDIR/$PROJECT_NAME"
else
  say "ECHEC (a) : tools/project-bootstrap.sh a echoue sur le projet voisin"
  exit 1
fi

# Epingle des gardiens du projet voisin : repo: local sur ce Vault (T01,
# ticket 02) -- jamais une URL distante, reservee a l'atelier de l'Owner.
if [ -f "$WORKDIR/$PROJECT_NAME/.pre-commit-config.yaml" ] \
   && grep -qE '^[[:space:]]*-?[[:space:]]*repo:[[:space:]]*local[[:space:]]*$' "$WORKDIR/$PROJECT_NAME/.pre-commit-config.yaml"; then
  say "epingle des gardiens du projet voisin : repo: local (T01)"
else
  say "ECHEC (a) : epingle des gardiens du projet voisin absente ou pas repo: local"
  FAIL=1
fi

say "clone : $(git -C "$WORKDIR/second-brain" rev-parse --short HEAD)"
say "depot frere workshop-build present ? $([ -d "$WORKDIR/workshop-build" ] && echo OUI || echo NON) (attendu : NON, essai d'autonomie)"

# --- (b) installation -------------------------------------------------------
step "(b) installation"
git -C "$WORKDIR/second-brain" config core.hooksPath .githooks
git -C "$WORKDIR/second-brain" config user.name "standalone-142"
git -C "$WORKDIR/second-brain" config user.email "standalone@example.invalid"
say "core.hooksPath = $(git -C "$WORKDIR/second-brain" config core.hooksPath)"

PREFLIGHT_OUT="$(cd "$WORKDIR/second-brain" && bash tools/session-preflight.sh 2>&1)"
PREFLIGHT_RC=$?
say "session-preflight : $PREFLIGHT_OUT (exit $PREFLIGHT_RC)"
[ "$PREFLIGHT_RC" -eq 0 ] || { say "ECHEC (b)"; FAIL=1; }

# --- (c) commit de test, gardien par gardien --------------------------------
step "(c) commit de test"
cat > "$WORKDIR/second-brain/knowledge/standalone-142-probe.md" <<'PROBE'
---
type: knowledge
title: "Sonde d'autonomie (Mission 142)"
description: "Fichier d'essai ecrit par tests/standalone.sh dans un clone jetable. Ne vit jamais dans le Vault reel."
status: active
---

# SONDE D'AUTONOMIE

Ce fichier prouve qu'un commit passe ses gardiens dans un clone pose seul.

## Liens

- `see also` — [Index de knowledge](./index.md)
PROBE

( cd "$WORKDIR/second-brain" && bash tools/build-indexes.sh knowledge ) >/dev/null 2>&1

# Tout fichier suivi du Vault doit porter sa ligne au manifeste : la sonde
# n'y echappe pas, le gardien de distribution la refuserait sinon (mesure
# Mission 142). Insertion a sa place ASCII, comme pour tout fichier neuf.
MANIFEST="$WORKDIR/second-brain/distribution-manifest.txt"
if ! grep -q 'knowledge/standalone-142-probe.md' "$MANIFEST"; then
  printf 'knowledge/standalone-142-probe.md\tDISTRIBUABLE\n' >> "$MANIFEST"
  ( cd "$WORKDIR/second-brain" && LC_ALL=C sort -o "$MANIFEST" "$MANIFEST" )
fi

( cd "$WORKDIR/second-brain" && git add -- knowledge/standalone-142-probe.md knowledge/index.md distribution-manifest.txt ) 2>&1 | tee -a "$LOG"

for g in "bash tools/session-preflight.sh" \
         "uv run tools/check-obsolescence-guardrail.py" \
         "bash tools/check-indexes-fresh.sh" \
         "bash tools/check-index-weight.sh" \
         "bash tools/check-secrets.sh" \
         "bash tools/check-links.sh" \
         "bash tools/check-asserted-paths.sh" \
         "bash tools/check-distribution-manifest.sh"; do
  START=$(date +%s%N)
  OUT="$( cd "$WORKDIR/second-brain" && eval "$g" 2>&1 )"
  RC=$?
  MS=$(( ($(date +%s%N) - START) / 1000000 ))
  say "$(printf '%-46s %5s ms  exit %s' "$g" "$MS" "$RC")"
  [ "$RC" -eq 0 ] || { say "  -> $OUT"; FAIL=1; }
done

COMMIT_START=$(date +%s%N)
COMMIT_OUT="$( cd "$WORKDIR/second-brain" && git commit -m "sonde d'autonomie (Mission 142, clone jetable)" 2>&1 )"
COMMIT_RC=$?
COMMIT_MS=$(( ($(date +%s%N) - COMMIT_START) / 1000000 ))
say "git commit : $COMMIT_MS ms, exit $COMMIT_RC"
[ "$COMMIT_RC" -eq 0 ] || { say "ECHEC (c) : $COMMIT_OUT"; FAIL=1; }

# --- (d) rangement du projet ------------------------------------------------
step "(d) rangement du projet"
( cd "$WORKDIR" && bash second-brain/tools/append-journal.sh "$PROJECT_NAME" \
    "STATE: essai d'autonomie joue par tests/standalone.sh, clone jetable sans depot frere" ) 2>&1 | tee -a "$LOG"
( cd "$WORKDIR" && bash second-brain/tools/build-state.sh "$PROJECT_NAME" ) 2>&1 | tee -a "$LOG"
( cd "$WORKDIR" && bash second-brain/tools/build-digest.sh "$PROJECT_NAME" ) 2>&1 | tee -a "$LOG"

DIGEST="$WORKDIR/$PROJECT_NAME/state/DIGEST.md"
if [ -f "$DIGEST" ]; then
  DSIZE=$(wc -c < "$DIGEST" | tr -d ' ')
  say "digest : $DSIZE octets (plafond 8000)"
  [ "$DSIZE" -le 8000 ] || { say "ECHEC (d) : digest au-dela du plafond"; FAIL=1; }
else
  say "ECHEC (d) : digest absent"
  FAIL=1
fi

# --- (e) releve des references residuelles ---------------------------------
step "(e) references residuelles a l'atelier (releve, jamais un echec)"
( cd "$WORKDIR/second-brain" && grep -rn 'workshop-build' skills rules templates CLAUDE.md AGENTS.md 2>/dev/null \
    | grep -v 'skills/external' | wc -l ) | while read -r n; do
  say "references restantes hors skills/external : $n (attendu : historiques et pedagogiques seulement)"
done

step "verdict"
if [ "$FAIL" -eq 0 ]; then
  say "PASS — le Vault s'installe, commite et range seul."
else
  say "FAIL — voir ci-dessus."
fi
say "log : $LOG"
exit "$FAIL"
