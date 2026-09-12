---
type: rules
title: "Cycle de contexte V2 — capture → proposal → decision → current state → handoff"
created_at: 2026-08-17T11:10:18-04:00
timezone: America/Montreal
status: active
supersedes: "./RULES-2026-08-17-013937-context-lifecycle.md"
---

# CYCLE DE CONTEXTE V2 — CAPTURE → PROPOSAL → DECISION → CURRENT STATE → HANDOFF

Cette règle applique la [décision d'architecture d'information V1](../decisions/DECISION-2026-08-17-111018-vault-v1-information-architecture.md). Elle **supplante** le [cycle minimal de contexte précédent](./RULES-2026-08-17-013937-context-lifecycle.md), qui reste conservé comme historique et ne doit plus être utilisé comme règle courante.

## 1. Principe sélectif

Conserver une information uniquement si elle doit survivre à la session, restera utile et n'est pas déjà portée par une source canonique suffisante. Le besoin réel détermine l'artefact ; aucune session ne doit produire mécaniquement une capture, une proposal, une décision ou un handoff.

Ne pas conserver :

- les échanges transitoires, essais sans conséquence et détails chronologiques ;
- les idées de brainstorming qui ne justifient pas un arbitrage futur ;
- les brouillons remplacés sans enseignement durable ;
- les copies de contenu ou d'état déjà accessibles dans une source canonique ;
- les hashes, compteurs ou états techniques qui peuvent être remesurés ;
- le contexte métier ou l'état courant d'un projet dans le Vault central.

## 2. Capture

Créer une capture lorsqu'un fait, une observation, un apprentissage ou une question durable mérite une source autonome. Préciser son contexte, son niveau de certitude, son impact éventuel et ses liens.

Une capture n'est ni une proposal ni une décision. Utiliser le [modèle de capture](../templates/capture-template.md).

## 3. Proposal

Créer une proposal seulement lorsqu'une option importante doit être conservée jusqu'à un arbitrage. Décrire la proposition, sa raison, son impact attendu et les alternatives réellement utiles.

Son statut reste `PROPOSED`. Une proposal acceptée n'est jamais requalifiée silencieusement : créer un nouvel artefact `DECISION` qui la référence et conserver les deux historiques. Utiliser le [modèle de proposal](../templates/proposal-template.md).

## 4. Decision

Créer une décision pour enregistrer un choix structurant et son arbitrage explicite. Tant que le human gate n'est pas accordé, son statut reste `PROPOSED`; après arbitrage, enregistrer `ARBITRATED` et la référence de validation.

Une décision décrit le choix, sa raison, son impact, les alternatives importantes et ses liens, notamment la proposal source lorsqu'elle existe. Utiliser le [modèle de décision](../templates/decision-template.md).

## 5. Current state

Lorsqu'un projet utilise un état de reprise, maintenir dans ce projet un unique fichier `<projet>/current-state.md`. Il reste court et décrit l'objectif actuel, l'état opérationnel, la dernière avancée validée, le prochain pas, les blocages et les sources actives.

Le current state est un **état vivant** : le mettre à jour en place. Il ne sert ni d'historique daté ni de registre de preuves techniques recopiées. Utiliser le [modèle d'état courant](../templates/current-state-template.md).

## 6. Handoff

Créer un handoff uniquement lorsqu'une reprise fiable est réellement nécessaire : interruption significative, nouvelle session, nouvel agent ou transfert de responsabilité.

Le handoff est une **passation historique datée**, pas un état vivant à maintenir. Il décrit la situation au moment du transfert, le travail terminé, les points ouverts, la prochaine action et les contraintes. Il pointe vers le current state et les sources prioritaires sans les recopier. Utiliser le [modèle de handoff](../templates/handoff-template.md).

## 7. Cycle applicable

```text
work
  → capture si une connaissance durable apparaît
  → proposal si une option importante doit attendre un arbitrage
  → decision lorsqu'un choix est explicitement arbitré
  → mise à jour du current state si l'état opérationnel change
  → handoff seulement si une reprise fiable est nécessaire
  → reprise depuis le current state, les décisions et les sources liées
```

## 8. Frontière Vault / projets

Le Vault conserve cette règle, les explications transversales et les modèles. Les projets externes portent leur propre état courant et leurs propres captures, proposals, décisions et handoffs.

Une amélioration issue d'un projet ne rejoint le Vault qu'après validation humaine de son caractère transversal. Le mécanisme de preuve associé est expliqué dans [Vérification et preuves](../knowledge/verification-and-evidence.md).

## Liens

- `supersedes` — [RULES-2026-08-17-013937-context-lifecycle — Cycle minimal de conservation et de reprise du contexte](RULES-2026-08-17-013937-context-lifecycle.md)
