---
type: decision
title: "Architecture centrale — Vault permanent et projets frères"
created_at: 2026-08-17T00:30:00-04:00
timezone: America/Montreal
status: active
---

# DÉCISION — VAULT CENTRAL ET PROJETS FRÈRES

## Statut

**ARBITRATED**

## Décision

Le système central du workshop n'est plus conçu comme un projet nommé `ai-context-workshop`.

Il devient un **Vault** permanent.

Dans la prose et les supports pédagogiques, le concept est nommé **Vault**.

Dans les identifiants machine et le système de fichiers, le dossier et futur dépôt utilisent le nom :

`vault`

Le Vault reste à un emplacement fixe et sert de mini second brain / système opératoire de travail avec l'IA.

Il contient uniquement la connaissance et les mécanismes **transversaux et réutilisables** :

- règles de travail ;
- conventions ;
- méthodes ;
- skills ;
- templates utiles ;
- principes de capture ;
- principes de handoff ;
- principes de décision ;
- règles Git ;
- règles de sécurité ;
- principes Graphify ;
- connaissances générales nécessaires au fonctionnement du système.

Le Vault **ne doit pas absorber le contexte métier détaillé de tous les projets**.

Chaque projet réel possède son propre dossier ou dépôt, créé **à l'extérieur du Vault**, comme dossier frère, avec son contexte local :

- objectifs ;
- état courant ;
- décisions propres ;
- connaissance métier ;
- handoffs ;
- sketches ;
- autres artefacts spécifiques.

Le Vault peut aider à créer et guider ces projets sans être recopié dans chacun d'eux.

## Architecture logique

```text
workspace/
└── workshops/
    ├── bootstrap/
    ├── prompt-archive/
    ├── vault/
    ├── project-a/
    ├── project-b/
    └── (historique de l'atelier, non distribué)
```

(historique de l'atelier, non distribué) est un espace séparé, à concevoir ultérieurement, destiné à la fabrication de la formation : prompts Codex, présentation, supports pédagogiques, journaux de construction et outils de production.

## Principe d'héritage

Le Vault porte les règles transversales.

Les projets portent seulement :

- leur contexte propre ;
- leurs décisions propres ;
- leurs exceptions ;
- leurs artefacts de travail.

Une amélioration générale découverte dans un projet peut remonter vers le Vault **uniquement après validation humaine**.

Une décision spécifique à un projet ne remonte pas automatiquement dans le Vault.

## Graphify

Le Vault et chaque projet doivent rester des espaces de contexte séparés.

Le Vault peut avoir son propre graphe Graphify.

Chaque projet peut avoir son propre graphe Graphify.

Aucune fusion globale n'est considérée comme acquise tant qu'elle n'a pas été testée et validée.

**Note (2026-08-26, Mission 065)** : cette section décrit une option d'architecture qui n'a plus cours. Graphify est sorti du rôle « graphe du Vault » puis a été intégralement éradiqué (Mission 040, 2026-08-24) ; conservée pour lecture historique, non corrigée sur place (`amended by` ci-dessous).

## Raison

Cette architecture évite :

- la duplication du cerveau central dans chaque projet ;
- la dérive de règles divergentes entre projets ;
- le mélange de contextes métier sans rapport ;
- la contamination du graphe par des décisions spécifiques à d'autres projets ;
- la confusion entre infrastructure de travail et fabrication du workshop.

Elle permet au système de capitaliser sur l'expérience tout en maintenant des frontières de contexte propres.

## Impact

Les anciennes références à `ai-context-workshop` comme nom du dépôt central sont **supplantées**.

Toute Mission 001 ou tout prompt d'exécution qui crée `ai-context-workshop` est obsolète.

Le prochain bootstrap doit créer `vault`.

Les huit artefacts initiaux restent conservés comme historique et ne sont pas réécrits silencieusement.

## Liens

- `amended by` — [Retrait de Graphify du rôle « graphe du Vault »](./DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md) (section Graphify)
