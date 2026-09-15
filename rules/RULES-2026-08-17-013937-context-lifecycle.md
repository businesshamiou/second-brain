---
type: rules
title: "Cycle minimal de conservation et de reprise du contexte"
created_at: 2026-08-17T01:39:37-04:00
timezone: America/Montreal
status: superseded
---

# CYCLE MINIMAL DE CONTEXTE

Cette règle définit comment conserver uniquement le contexte qui doit survivre à une session. Elle complète les [règles générales du Vault](./RULES-2026-08-17-005717-vault-operating-rules.md) sans transformer le Vault ou un projet en journal exhaustif.

## 1. Principe sélectif

Conserver une information seulement si elle est durable, utile à une reprise future et absente d’une source canonique déjà suffisante.

Ne pas conserver systématiquement :

- les échanges transitoires et essais sans conséquence ;
- chaque action exécutée ou chaque détail chronologique ;
- les brouillons remplacés sans enseignement durable ;
- une copie de contenu déjà disponible dans une source liée ;
- le contexte métier d’un projet à l’intérieur du Vault central.

## 2. Degrés de certitude

Chaque artefact distingue explicitement la nature de son contenu :

| Nature | Signification |
|---|---|
| Fait | Information observée ou appuyée par une source identifiable. |
| Proposition | Option suggérée, encore ouverte à l’arbitrage. |
| Décision | Choix explicite dont le statut indique s’il est proposé, arbitré ou remplacé. |
| Question ouverte | Point non résolu qui demande une réponse, un test ou un human gate. |

Une proposition ne devient jamais `ARBITRATED` par reformulation implicite. Une décision structurante exige un human gate et une preuve d’arbitrage.

Une capture précise aussi son niveau de certitude : `CONFIRMED` si l’information est vérifiée par une source, `OBSERVED` si elle provient d’une observation directe, `INFERRED` si elle résulte d’un raisonnement, ou `UNCERTAIN` si elle doit encore être vérifiée.

## 3. Capture

Créer une capture lorsqu’une information nouvelle :

- restera utile au-delà de la session courante ;
- éclaire une décision, une méthode, une contrainte ou un incident ;
- mérite une source autonome et des liens vers les artefacts concernés.

Une capture décrit son contexte, l’information conservée, son niveau de certitude, son impact éventuel et ses liens. Elle ne constitue pas une décision.

Utiliser le [modèle de capture](../templates/capture-template.md).

## 4. Décision

Créer ou mettre à jour une décision lorsqu’un choix structurant influence la suite du travail, les règles, l’architecture, la sécurité ou les frontières de contexte.

Le document enregistre la date, le choix, son statut, sa raison, son impact, les alternatives importantes et ses liens. Avant validation, son statut reste `PROPOSED`. Seul un human gate peut le faire passer à `ARBITRATED`.

Utiliser le [modèle de décision](../templates/decision-template.md).

## 5. Current state

Lorsqu’un projet utilise un état de reprise, maintenir un unique fichier `current-state.md`. Il contient seulement l’objectif actuel, l’état opérationnel, la dernière avancée validée, le prochain pas, les blocages, les décisions récentes pertinentes et les sources de référence.

Mettre ce fichier à jour en place. Ne pas empiler des copies datées pour fabriquer un historique ; Git et les artefacts liés portent déjà l’historique utile.

Utiliser le [modèle d’état courant](../templates/current-state-template.md).

## 6. Handoff

Créer un handoff uniquement lorsqu’une reprise fiable est nécessaire : nouvelle session, nouvel agent, interruption significative ou transfert de responsabilité.

Le handoff résume l’objectif, l’état actuel, ce qui est terminé, les décisions actives, les points ouverts, la prochaine action et les contraintes. Il pointe vers les sources prioritaires au lieu de recopier le projet.

Utiliser le [modèle de handoff](../templates/handoff-template.md).

## 7. Cycle de travail

```text
work
  → capture si une connaissance durable apparaît
  → decision si un choix structurant doit être tracé
  → mise à jour de current-state si l’état opérationnel change
  → handoff seulement si une reprise est nécessaire
  → reprise depuis current-state, les décisions et les sources liées
```

Les quatre mécanismes sont disponibles à chaque session, mais aucun n’est obligatoire par simple routine. Le besoin réel commande l’artefact.

## 8. Frontière Vault / projets

Le Vault conserve cette méthode et ses modèles. Chaque projet externe conserve ses captures, décisions, handoffs et son état courant dans son propre espace. Une leçon issue d’un projet ne remonte dans le Vault qu’après validation humaine de son caractère transversal.

## Liens

- `superseded by` — [RULES-2026-08-17-111018-context-lifecycle-v2 — Cycle de contexte V2 — capture → proposal → decision → current state → handoff](RULES-2026-08-17-111018-context-lifecycle-v2.md)
