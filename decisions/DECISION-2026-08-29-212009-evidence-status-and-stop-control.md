---
type: decision
title: "Statut de preuve des lignes d'arbitrage et contrôle d'arrêt obligatoire sur toute affirmation non lue"
description: "Toute ligne soumise à l'arbitrage de l'Owner déclare son statut de preuve — mesurée, hypothèse ou jugement — et tout point de Décision affirmant le contenu d'un document non lu dans la session part avec un contrôle d'arrêt nommé dans sa Mission d'exécution."
created_at: "2026-08-29T21:20:09-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: pilot-conduct, arbitration-protocol
---

# DÉCISION — STATUT DE PREUVE DES LIGNES D'ARBITRAGE

## Date

2026-08-29

## Statut

`ARBITRATED`

## Décision

1. **Déclaration du statut de preuve.** Toute ligne d'une table soumise à l'arbitrage de l'Owner porte l'un de ces trois statuts, explicitement :
   - `MESURÉ` — la source a été lue dans la session en cours, et elle est nommée sur la ligne.
   - `HYPOTHÈSE` — l'affirmation repose sur une inférence ; le document qui la trancherait est nommé, et il n'a pas été lu.
   - `JUGEMENT` — la ligne porte une priorité, un ordre ou une préférence, et ne prétend rien sur le contenu d'un document.
2. **Formulation conditionnelle.** Un point de Décision reposant sur une ligne `HYPOTHÈSE` se formule au conditionnel et énonce ce qui le réfuterait.
3. **Contrôle d'arrêt obligatoire.** Toute Mission exécutant un point issu d'une ligne `HYPOTHÈSE` porte, avant l'écriture concernée, une étape de mesure explicite avec un `STOP` nommé, sa source à lire et sa condition de réfutation.
4. **Portée d'une validation globale.** Une validation d'ensemble — « je valide les recos » ou équivalent — ne couvre une ligne `HYPOTHÈSE` que sous la forme conditionnelle du point 2, avec son contrôle d'arrêt du point 3. Sans eux, la ligne n'est pas soumise à l'arbitrage : elle est retirée de la table.

## Raison

Le 2026-08-29, une table de treize questions a été soumise à l'Owner, qui l'a validée d'un mot. Douze lignes reposaient sur des lectures faites dans la session ou sur des jugements de priorité. Une reposait sur une inférence tirée d'un document non ouvert, et rien ne la distinguait des autres. L'inférence était fausse : le compteur qu'elle proposait de retirer est prescrit par `DECISION-2026-08-25-110935` §4.

Le format ne permettait pas à l'Owner de voir la différence : une mesure et une supposition avaient le même poids typographique et se gravaient du même mot. Le défaut n'est pas la supposition — elle est légitime et souvent nécessaire — mais son déguisement en constat.

Ce qui a tenu, c'est le contrôle d'arrêt inscrit dans la Mission d'exécution : la fenêtre Executor a lu la source, mesuré la contradiction et s'est arrêtée avant toute écriture, sans qu'aucun texte ne soit modifié à tort. Cette Décision généralise ce qui a fonctionné.

## Impact

- Toute table d'arbitrage produite par le Pilot porte désormais une colonne ou une marque de statut de preuve.
- Toute Mission exécutant une ligne `HYPOTHÈSE` porte un `STOP` nommé avant l'écriture concernée, et le rapport d'exécution cite la source lue.
- Vaut pour tous les projets, quelle que soit la fenêtre.

## Alternatives importantes

- Interdire les lignes `HYPOTHÈSE` en table d'arbitrage : écartée. Elle imposerait de lire l'ensemble du corpus avant toute proposition, coût prohibitif, et pousserait l'inférence à se cacher au lieu de se déclarer.
- Porter cette règle par amendement de la charte des rôles plutôt qu'en Décision autonome : écartée pour l'instant. Une Décision du Vault est normative par préséance ; l'amendement de la charte coûterait une édition réciproque d'un fichier de règle et un cycle push puis ré-épingle, pour un gain de découvrabilité seul. Le report dans la charte reste ouvert comme geste distinct.

## Limite assumée

Aucun garde-fou ne peut vérifier qu'un fichier a été lu. Le point 1 reste doctrinal et dérivera si rien ne le rappelle. Seul le point 3 est mécanisable, parce qu'il vit dans le texte d'une Mission que la fenêtre Executor applique et dont elle rapporte la mesure. C'est la part mécanisée qui a évité la faute du 2026-08-29 ; la part doctrinale n'y aurait pas suffi.

## Human gate

- Validation : accordée
- Référence : « séparée », Owner, 2026-08-29, en réponse à la question du placement de cette règle.

## Artefacts liés

- Incident fondateur : (historique de l'atelier, non distribué)

## Liens

- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Relais entre rôles par mini-prompts à rubriques fixes](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Décision — Tag CLOSE: et portes à clé du journal](./DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
