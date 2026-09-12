---
type: decision
title: "Architecture d'information V1 — primitives, preuves et human gates"
created_at: 2026-08-17T11:10:18-04:00
timezone: America/Montreal
status: active
owner_gate: granted
---

# DÉCISION — ARCHITECTURE D'INFORMATION V1 DU VAULT

## Statut

**ARBITRATED**

Cette décision enregistre dans le Vault les arbitrages V1 validés pour ses primitives documentaires, ses couches d'information et son modèle de preuve.

## Décision

### 1. Primitives documentaires

Les primitives ont des rôles distincts :

- une **capture** conserve une connaissance durable utile sans valeur d'arbitrage implicite ;
- une **proposal** conserve une option importante en attente d'arbitrage ;
- une **decision** enregistre un choix explicitement validé ;
- le **current state** est l'état vivant, court et actualisé d'un projet ;
- un **handoff** est une passation datée, créée seulement lorsqu'une reprise fiable est nécessaire.

Une idée de brainstorming ne produit pas automatiquement une proposal. Une proposal reste `PROPOSED` jusqu'au human gate. Lorsqu'elle est acceptée, elle n'est ni renommée ni transformée silencieusement : un nouvel artefact `DECISION` est créé et pointe vers elle. Les deux historiques restent distincts.

Le current state est mis à jour en place. Le handoff ne devient pas un second état courant : il résume le minimum nécessaire au transfert et pointe vers les sources actives.

### 2. Frontière Vault / projets

Le Vault conserve les règles, les explications et les modèles transversaux. Chaque projet externe conserve son propre current state, ses captures, proposals, décisions et handoffs. Aucun état de projet n'est importé automatiquement dans le Vault.

### 3. Couches documentaires

- `rules/` prescrit les comportements attendus ;
- `knowledge/` explique les mécanismes, leurs raisons et leurs limites ;
- `templates/` matérialise la forme des artefacts ;
- `AGENTS.md` contient les instructions opérationnelles minimales ;
- `README.md` reste la porte d'entrée.

Une même doctrine ne doit pas être recopiée intégralement dans chaque couche.

### 4. Modèle de preuve V1

Le modèle de preuve suit cinq niveaux :

1. **STATE** — `git status` mesure l'état réel du working tree et de l'index ;
2. **CHANGE** — `git diff` et `git diff --staged` montrent le changement réel ;
3. **VALIDATION** — les tests et checks pertinents évaluent le comportement attendu ;
4. **SNAPSHOT** — un commit local et son hash identifient un instantané mesuré ;
5. **EXTERNAL BOUNDARY** — les remotes, pushs, publications et autres effets externes sont traités comme une frontière distincte.

Les hashes, compteurs et états Git sont remesurés lorsqu'ils sont nécessaires plutôt que recopiés comme vérité durable. Un contrôle déclaré ou présent ne prouve pas qu'il fonctionne : son exécution et son résultat doivent être observés.

### 5. Human gates

Une mission locale, bornée et réversible peut autoriser une chaîne complète d'inspection, modification, validation, staging fichier par fichier, inspection du diff staged, commit local et rapport de preuves.

Un human gate explicite reste requis pour une décision structurante non arbitrée, une suppression ou migration importante, un enjeu de sécurité ou de secret, un changement de frontière, un remote, un push, une publication ou tout autre effet externe sensible ou difficilement réversible.

## Raison

Cette architecture évite la confusion entre connaissance et arbitrage, entre état vivant et passation historique, ainsi qu'entre contrôle local et effet externe. Elle permet aussi de vérifier le travail depuis des observations reproductibles plutôt que depuis des déclarations copiées.

## Impact

- le cycle de contexte V2 supplante explicitement la règle précédente ;
- un modèle de proposal rejoint les modèles existants ;
- la connaissance de vérification devient interrogeable de façon autonome ;
- les points d'entrée et modèles utilisent les rôles stabilisés sans dupliquer toute la doctrine.

## Human gate

- Validation : accordée
- Référence d'arbitrage : validation explicitement fournie avant l'enregistrement de cette décision canonique.

## Artefacts liés

- Architecture parente : [Vault central et projets frères](./DECISION-2026-08-17-003000-vault-central-architecture.md)
- Règles générales : [règles de conduite](../rules/RULES-2026-08-17-005717-vault-operating-rules.md)
- Cycle applicable : [cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- Modèle opératoire : [concept et modèle opératoire](../knowledge/BRIEF-2026-08-17-003000-vault-concept-operating-model.md)
- Preuves : [vérification et preuves](../knowledge/verification-and-evidence.md)

## Liens

- `see also` — [Vault central et projets frères](./DECISION-2026-08-17-003000-vault-central-architecture.md)
- `see also` — [Vault — concept pédagogique et modèle opératoire](../knowledge/BRIEF-2026-08-17-003000-vault-concept-operating-model.md)
