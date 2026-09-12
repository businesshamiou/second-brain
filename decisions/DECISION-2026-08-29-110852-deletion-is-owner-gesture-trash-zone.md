---
type: decision
title: "La suppression définitive est un geste Owner — le déplacement hors dépôts en est le substitut agent"
description: "Grave le fait mesuré trois fois par la Mission 087 : aucun agent, Pilot ou Executor, ne supprime définitivement un fichier, même sous human gate accordé — la politique de l'environnement le refuse, et le refus n'est pas contournable. La suppression rejoint le push parmi les gestes réservés à l'Owner. Substitut agent : déplacer le fichier vers une zone de dépôt hors de tout dépôt (_trash à la racine de l'espace de travail), que l'Owner seul vide. Amende la charte des rôles (§2, §3), la règle du relais (rubrique 4 et sens retour) et le gabarit de Mission (aucune étape de suppression Executor) ; AGENTS.md distingue gestes Owner et human gates."
created_at: "2026-08-29T11:08:52-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  - "../templates/mission-template.md"
  - "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
---

# DÉCISION — LA SUPPRESSION DÉFINITIVE EST UN GESTE OWNER

## Date

2026-08-29

## Statut

`ARBITRATED`

## Décision

**1. Geste réservé.** La suppression définitive d'un fichier — suivi ou non par Git, quel que soit son contenu — est un geste de l'Owner, au même titre que le `push`. Aucun agent ne l'exécute : ni le Pilot (déjà interdit par la charte §2), ni l'Executor, **y compris lorsqu'une Mission lui accorde le human gate**. La charte §3 (« aucune suppression sans human gate ») laissait croire qu'un gate suffisait ; il ne suffit pas. Le refus vient de la politique de l'environnement de l'agent, il est identique par tous les outils, et il n'est pas contournable — ni par reformulation, ni par outil alternatif, ni par autorisation en amont.

**2. Substitut agent : le déplacement hors dépôts.** Quand une Mission exige qu'un fichier cesse d'exister au corpus, l'agent le **déplace** vers la zone de dépôt hors dépôts : `_trash/` à la racine de l'espace de travail, hors de tout dépôt Git. Un déplacement n'est pas une suppression : il est réversible et ne tombe pas sous le refus. Le déplacement est prouvé par empreinte SHA-256 avant et après (le fichier n'est pas altéré) et par l'absence remesurée à l'ancien chemin. Le Pilot peut l'exécuter lui-même via son accès filesystem quand la Mission d'un Executor bloque dessus — c'est le cas de la 087.

**3. `_trash/` — statut.** Zone hors norme documentaire : pas d'index, pas de front-matter, pas de lien ; rien n'y est cité depuis le corpus. Elle est vidée par l'Owner seul, à son rythme ; son vidage n'est jamais une précondition de Mission. Un gardien de liens qui la rencontrerait comme cible signale une erreur du corpus, pas de la zone.

**4. Gabarit de Mission.** Une Mission ne prescrit plus jamais une étape « supprimer » à l'Executor. Deux formes seulement : **(a)** « déplacer vers `_trash/` » comme étape agent, avec empreinte et remesure d'absence en validation ; ou **(b)** « suppression par l'Owner » comme human gate, hors des étapes, avec précondition de reprise « absence mesurée à l'ancien chemin, STOP sinon ». Le snippet de lancement n'affirme jamais qu'une suppression Owner a eu lieu : il demande à l'Executor de la mesurer.

**5. Relais, snippets et réponses d'agent.** Dans le mini-prompt du sens aller (RULES-124937, rubrique 4), l'interdit « aucune suppression » devient « aucune suppression ; déplacement vers `_trash/` seulement sur prescription de la Mission ». Un snippet du Pilot n'affirme jamais qu'un geste Owner — push, suppression, vidage de `_trash/` — a eu lieu : il demande à l'Executor de le mesurer, STOP si absent. Au sens retour, quand un geste réservé bloque une Mission, la rubrique « À trancher » nomme le chemin exact et le substitut disponible (déplacement vers `_trash/`), et l'Executor s'arrête sans tentative de contournement ni deuxième outil : un refus de cette classe est structurel, le répéter est une perte de fenêtre. Le Pilot, à réception, exécute le déplacement lui-même ou le fait prescrire, sans relancer sur un fait non mesuré.

**6. Options écartées.** Contournement par override de gardien ou `--no-verify` — sans objet, le refus n'est pas un gardien du dépôt mais la politique de l'agent ; « l'Owner supprime toujours » (S1) — vrai en principe mais a produit deux reprises bloquées sur un fait annoncé et non fait, d'où la préférence pour le substitut mesurable (S2) ; laisser coexister les deux exemplaires (S3) — contraire à l'objectif de l'enveloppement.

## Raison

Mission 087 : l'Executor a tenté la suppression du fichier source enveloppé par deux outils distincts et reçu deux fois le même refus verbatim, classé « Permanently deleting data » dans une catégorie que la politique système de l'agent n'exécute jamais, quelle que soit l'autorisation reçue. Deux reprises lancées sur un snippet affirmant la suppression Owner ont bloqué à raison (fichier toujours présent, même empreinte). Le déplacement par le Pilot vers `_trash/` a débloqué la Mission en un tour, avec preuve d'identité et d'absence. Arbitrage Owner : « s2 », 2026-08-29.

La leçon est de la même famille que le push délégué (DECISION-154553 et amendements) : un geste que l'agent ne peut pas faire doit être gravé comme geste Owner, avec son substitut mesurable, sinon chaque Mission qui le rencontre redécouvre le mur.

## Impact

- `AGENTS.md` du Vault : la ligne « human gate pour tout push, suppression importante… » distingue désormais les gestes réservés à l'Owner (push, suppression définitive) des gestes sous human gate (renommage structurant, partage sensible).
- Règle du relais §aller rubrique 4 et §retour : formulations du §5 ci-dessus.
- Charte des rôles §2 : « suppression » reste interdite au Pilot ; « déplacement vers `_trash/` » est explicitement permis comme écriture bornée.
- Charte des rôles §3 : « aucune suppression sans human gate » devient « aucune suppression, même sous human gate ; déplacement vers `_trash/` sur prescription de Mission ».
- Gabarit de Mission : commentaire de la section Étapes rappelant le §4 ci-dessus.
- Les réciproques `amended by` sont posées dans les trois documents amendés, dans le même commit que cette Décision (RULES-115658), par l'Executor de la Mission de rangement.
- Le dossier `_trash/` existe depuis le 2026-08-29 à la racine de l'espace de travail, hors des dépôts `vault` et (historique de l'atelier, non distribué).

## Human gate

- Validation : accordée
- Référence : « s2 » puis « on continue » (N1 — graver d'abord), Owner, 2026-08-29.

## Artefacts liés

- Rapports de la Mission 087 (l'atelier (historique, non distribué), hors Vault) : REPORT-2026-08-29-011726-087-second-audit-enveloping-STOP.md (refus verbatim, deux outils), REPORT-2026-08-29-013432-…-resume-STOP.md et REPORT-2026-08-29-103907-…-resume2-STOP.md (reprises bloquées à raison), REPORT-2026-08-29-105604-…-completion.md (déplacement mesuré, achèvement).

## Liens

- `amends` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `amends` — [Gabarit de Mission](../templates/mission-template.md)
- `amends` — [Relais entre rôles par mini-prompts à rubriques fixes](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `applies` — [Instructions pour les agents](../AGENTS.md)
- `see also` — [Décision — L'amendement vit dans le dépôt de l'amendé](./DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md)
