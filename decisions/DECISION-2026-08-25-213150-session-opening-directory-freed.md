---
type: decision
title: "Répertoire d'ouverture d'une session — révocation de la contrainte de position, exigence de conscience de position"
created_at: "2026-08-25T21:31:50-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-25-213150-session-opening-directory-freed.md"
---

# DÉCISION — RÉPERTOIRE D'OUVERTURE D'UNE SESSION

## Date

2026-08-25

## Statut

`ARBITRATED`

Arbitré en séance par l'Owner le 2026-08-25, en session Pilot `plan · open`, à la suite de l'arrêt aux préconditions de la Mission 056.

## Décision

1. **Révocation.** La contrainte « toute session Executor s'ouvre toujours dans le Vault, jamais ailleurs » est révoquée. Elle figure aujourd'hui à la charte des rôles, §3, rubrique « Ouverture », et dans plusieurs pièces dérivées ; la présente Décision la prive d'effet à compter de sa date.

2. **Position libre.** Une session peut s'ouvrir n'importe où dans le workspace, et s'ouvre typiquement dans le dossier du projet en cours de développement. Le répertoire de départ n'est plus une précondition, ne peut plus fonder un arrêt, et ne doit plus être vérifié comme tel.

3. **Conscience de position exigée.** Ce qui est exigé n'est plus une position mais une capacité, en quatre points, à établir à l'ouverture :
   - déterminer son répertoire courant ;
   - identifier le dépôt dans lequel ce répertoire se trouve, ou constater qu'il n'est dans aucun ;
   - atteindre les dépôts frères par chemin relatif, et changer de répertoire au besoin ;
   - exécuter toute opération Git dans le dépôt concerné par le geste, jamais par défaut dans celui du répertoire de départ.

4. **Règles métier de projet.** Elles restent dans le dossier de leur projet et sont lues après localisation via le Vault ou le registre, sans changement.

5. **Ce que la charte doit dire.** La charte des rôles doit être amendée pour porter les points 2 à 4 à la place de la formulation révoquée. **Cet amendement n'est pas exécuté par la présente Décision** : la modification d'un fichier de règles existant est un geste Executor, et l'Owner a arbitré que l'audit passe avant toute correction.

## Raison

La contrainte de position répondait à un motif réel — garantir que la session sache atteindre le Vault et ses règles. Ce motif est aujourd'hui satisfait autrement : l'agent sait se localiser et se déplacer, et le travail se déroule majoritairement dans le dossier du projet en développement, ce qui rendait la contrainte à la fois artificielle et coûteuse.

L'arrêt de la Mission 056 a rendu ce coût visible : une session par ailleurs correcte a été bloquée par une précondition dont le motif était abandonné mais dont le texte restait actif.

## Impact

- La précondition « session ouverte dans `vault` » disparaît des Missions à venir et doit être retirée de la correction de la Mission 056.
- La charte des rôles `RULES-2026-08-23-224706` §3 devient **partiellement périmée** tant que l'amendement du point 5 n'est pas exécuté. Toute session lisant cette charte d'ici là doit tenir le §3 « Ouverture » pour révoqué.
- **Perte assumée.** On échange une contrainte vérifiable mécaniquement contre une exigence comportementale. Le contrôle devient plus souple et moins prouvable. L'échange est accepté en connaissance de cause.
- **Point non arbitré, matière à l'audit 057.** Cet épisode est la troisième occurrence en une journée d'un même patron : une règle gravée survit à l'abandon de son motif, faute d'un geste qui amende le texte source au moment de la révocation. L'opportunité de graver une obligation générale — toute Décision qui révoque amende le texte qu'elle révoque — n'est pas tranchée ici et attend les mesures de l'audit.

## Alternatives importantes

- **Maintenir la contrainte.** Rejetée : son motif est éteint et son coût est démontré.
- **Contrainte affaiblie — s'ouvrir dans un dépôt Git, jamais à la racine du workspace.** Écartée à ce stade au profit de la position entièrement libre ; reste réouvrable si une session hors dépôt cause un incident réel.

## Human gate

- Validation : accordée
- Référence : arbitrage en séance de l'Owner, session Pilot du 2026-08-25, à la suite du RELAY 056.

## Artefacts liés

- Arrêt qui a révélé l'écart : `../reports/REPORT-2026-08-25-210526-056-executor-case-study-pivot-engraving-STOP.md`
- Règle à amender : `../../../vault/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md`

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amends` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — Rapport d'arrêt de la Mission 056 (historique de l'atelier, non distribué)
