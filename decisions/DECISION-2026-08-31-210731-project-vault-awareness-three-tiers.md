---
type: decision
title: "Prise de conscience du Vault par un projet — trois étages (machine, workspace, projet), arrêt sur dossier non adopté, mode adopter du bootstrap, hook et épingle inclus"
description: "Grave l'arbitrage Owner du 2026-08-31 après brainstorm sur un cas réel (dossier déplacé dans le workspace, Codex ouvert dedans, session démarrée sans rien savoir du Vault) : un projet prend conscience du Vault par des fichiers que les agents lisent nativement, sur trois étages — machine (fichiers globaux par outil, posés par first-install), workspace (marqueur VAULT-ROOT.md), projet (fichiers de pointage, hook de démarrage, épingle des gardiens, ligne de registre, posés par project-bootstrap). Un agent qui se découvre dans un dossier non adopté s'arrête et demande ; le mode adopter du bootstrap ajoute ce qui manque sans toucher au contenu ; hook et épingle font partie du bootstrap. Amende 232341 §5.1 pour first-install et project-bootstrap."
created_at: "2026-08-31T21:07:31-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md"
---

# DÉCISION — PRISE DE CONSCIENCE DU VAULT PAR UN PROJET, EN TROIS ÉTAGES

## Date

2026-08-31

## Statut

`ARBITRATED`

## Problème mesuré

Un dossier déplacé dans le workspace, ouvert avec Codex, a démarré sans aucune connaissance du Vault, de ses règles ni de son rôle. Cause mesurée le 2026-08-31 :

- Les agents (Codex, Claude Code) lisent nativement, avant tout travail, un fichier d'instructions global dans leur dossier personnel, puis les fichiers d'instructions du projet depuis la racine Git jusqu'au dossier courant (doc Codex : `AGENTS.md` ; Claude Code : `CLAUDE.md`). Un dossier sans ces fichiers est un dossier aveugle. [MESURÉ : doc officielle Codex ; listage de (historique de l'atelier, non distribué), qui porte `AGENTS.md` et `CLAUDE.md`]
- `tools/project-bootstrap.sh` crée un projet neuf seulement (refus si la cible existe), exige le marqueur `VAULT-ROOT.md` en amont, et pose squelette, README, journal, fiche v2, ligne de registre et index. Il n'a pas de mode pour un dossier existant. [MESURÉ : tête et queue du script lues]
- Le hook `SessionStart` qui injecte le rôle Executor n'existe que dans le dossier `.claude/` du Vault ; (historique de l'atelier, non distribué) n'en a pas. Les sessions ouvrant dans un projet ne le déclenchent jamais. [MESURÉ : listage de (historique de l'atelier, non distribué), aucun `.claude/`]

## Décision

**1. Trois étages, du plus large au plus précis.** Un projet prend conscience du Vault par des fichiers que les agents lisent sans prompt :

- **Étage machine** — un fichier global par outil, hors dépôts (`~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`), au contenu minimal : « il existe un Vault sur cette machine ; si un marqueur `VAULT-ROOT.md` se trouve en remontant depuis le dossier courant, lire la charte à son emplacement, déterminer le rôle selon ses trois barreaux, ne rien faire avant ». Posé par le skill `first-install`. Ce geste n'est pas distribué par le Vault seul : chaque destinataire le fait chez lui, `first-install` l'accompagne.
- **Étage workspace** — le marqueur `VAULT-ROOT.md`, existant, qui borne le territoire du Vault.
- **Étage projet** — à la racine du dossier : fichiers de pointage (`AGENTS.md`, `CLAUDE.md`) vers la charte, hook de démarrage, épingle des gardiens du Vault (`.pre-commit-config.yaml`), ligne au registre des projets. Posé par le skill `project-bootstrap`.

**2. Un agent qui se découvre dans un dossier non adopté s'arrête et demande.** L'étage machine le lui prescrit. Il ne lance pas l'adoption de sa propre initiative : adopter écrit dans le registre du Vault, c'est un geste sur prescription de Mission ou arbitrage Owner.

**3. Le bootstrap a deux modes.** *Naître* : le comportement actuel du script. *Adopter* : sur un dossier existant, ajouter ce qui manque à l'étage projet — fichiers de pointage, hook, épingle, ligne de registre, fiche v2 — **sans toucher au contenu existant**. La réorganisation en sept fonctions n'est jamais automatique, mais elle est **toujours proposée** à l'adoption, parce qu'elle sert le flux de travail : le bootstrap en mode adopter présente le plan de réorganisation (ce qui bougerait, où) et ne l'applique que sur un **oui catégorique de l'Owner** ; sans ce oui, le dossier reste tel quel, adopté mais non réorganisé, et la fiche v2 le dit.

**4. Hook et épingle font partie du bootstrap**, dans les deux modes. Un projet adopté sans hook ni épingle est non conforme ; `check-project-conformity.sh` doit le dire (extension à prescrire dans la Mission qui applique la présente).

**5. Règle en une phrase.** *Le Vault adopte les projets ; la machine attrape ceux qui ne le sont pas encore ; personne ne travaille dans un dossier qui n'est ni l'un ni l'autre.* La position d'ouverture reste libre (DECISION-213150) : c'est le dossier qui parle, pas l'ordre des fenêtres.

**6. Effet sur 232341 §5.1.** `first-install` porte désormais l'étage machine (point 1) ; `project-bootstrap` porte les deux modes et les points 3 et 4. Les quatre autres skills sont inchangés. Cette Décision ne fabrique rien : elle fixe ce que les deux skills devront faire.

## Raison

Brainstorm Owner–Pilot du 2026-08-31 sur le cas réel, en quatre points soumis avec recommandation unique ; l'Owner a pris les quatre recommandations d'un mot. Le choix « des fichiers, ni un prompt ni un skill seul » tient à un fait : un skill ne s'invoque pas depuis une session qui ne sait pas qu'il existe, et un prompt ne sert qu'à une fenêtre de chat sans dossier. Les fichiers d'instructions sont la seule chose qu'un agent lit sans qu'on le lui dise.

## Impact

- 232341 reçoit `amended by` (réciproque à poser par l'Executor au prochain rangement, même commit que la présente).
- `project-bootstrap.sh` : mode adopter, écriture des fichiers de pointage, du hook, de l'épingle — Mission à venir, avec `check-project-conformity.sh` étendu.
- (historique de l'atelier, non distribué) lui-même est aujourd'hui non conforme au point 4 (pas de hook) : premier candidat au mode adopter.
- Le dossier Codex de l'Owner : second candidat, une fois nommé.
- `first-install` : spécification à écrire avant fabrication (règle « un skill à la fois, entièrement étoffé »).

## Alternatives importantes

- « Toujours ouvrir le Vault d'abord » : écartée, déjà révoquée le 2026-08-25 ; l'ordre des fenêtres ne remplace pas un dossier qui parle.
- Un prompt d'ouverture par outil : écarté, il faut penser à le coller ; l'oubli est exactement le cas mesuré.
- L'agent adopte de lui-même le dossier non adopté : écarté, écriture au registre sans Owner.
- Réorganisation automatique en sept fonctions à l'adoption : écartée, écriture sur le contenu sans Owner. Réorganisation jamais proposée : écartée aussi (Owner, 2026-08-31) — elle aide le flux de travail, donc elle est toujours suggérée, appliquée seulement sur oui catégorique.

## Human gate

- Validation : accordée
- Référence : « Je prends ta recommandation ou bien tes recommandations », Owner, 2026-08-31, sur les quatre points soumis.

## Liens

- `amends` — [Décision — Consolidation du soir, standard de projet et plan](./DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md)
- `see also` — [Charte des rôles et détermination de session](../../../vault/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md) (hors Vault)
- `see also` — [Décision — Répertoire d'ouverture d'une session, position libérée](./DECISION-2026-08-25-213150-session-opening-directory-freed.md)
