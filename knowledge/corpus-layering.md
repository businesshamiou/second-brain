---
type: knowledge
title: "Stratification du corpus : où vit un artefact, et s'il entre dans un graphe"
description: "Deux axes — portée et nature — qui déterminent l'emplacement d'un artefact et son entrée dans un graphe de connaissance."
created_at: 2026-08-19T16:14:22-04:00
timezone: America/Montreal
status: active
scope: vault-and-project-corpus
---

# STRATIFICATION DU CORPUS

## Le problème

Deux questions se posent pour chaque artefact produit, et elles sont souvent confondues :

1. **Où vit-il ?** Dans le Vault transverse, ou dans le dossier d'un projet ?
2. **Entre-t-il dans un graphe de connaissance ?** Ou reste-t-il accessible en lecture directe seulement ?

Les traiter comme une seule question conduit à des règles bancales : soit on remonte du métier dans le Vault, soit on noie le graphe sous l'historique. Ce sont deux axes indépendants.

## Axe 1 — la portée

> Ce qui vaut pour n'importe quel projet vit dans le Vault.
> Ce qui n'a de sens que dans un projet vit dans ce projet.

Le Vault porte le **comment universel** : processus, garde-fous, doctrine de preuve, conventions, cycle documentaire, comportements d'agent, [registre des projets](../projects/PROJECT-REGISTRY.md).

Chaque projet porte son **comment métier** : ses règles propres, ses contraintes, son glossaire, ses décisions de fabrication, son contexte. Ces règles ne remontent jamais dans le Vault — un projet client, un produit, une mission de conseil ont chacun un domaine qui n'a rien à faire dans une couche transverse.

Ce point est souvent mal compris : le Vault n'est pas le seul endroit où l'on écrit des règles. Il est l'endroit où l'on écrit les règles **communes**. Chaque projet a besoin de sa propre couche d'instruction, symétrique de celle du Vault.

## Axe 2 — la nature

> Ce qui explique comment ou pourquoi entre dans le graphe.
> Ce qui atteste qu'un travail a eu lieu reste dehors.

Une règle, une décision, une connaissance, un contexte, un registre expliquent. Un audit, un prompt archivé, une mission close, un handoff ancien prouvent.

La preuve garde toute sa valeur : elle reste sur disque, versionnée dans Git, lisible à la demande. Elle n'entre simplement pas dans la couche de navigation sémantique, parce qu'elle en dégrade le signal sans rien ajouter à la compréhension.

Cette distinction est mesurée, pas supposée : réduire le corpus de dix-sept à quinze documents mieux choisis a fait passer un graphe de seize à vingt-huit arêtes, et trois tests de connaissance de partiels à concluants.

## La matrice

```text
                    INSTRUCTION                    PREUVE
                    (comment / pourquoi)           (ça a été fait)
              ┌────────────────────────────┬────────────────────────────┐
 TRANSVERSE   │  rules                     │  handoffs anciens          │
 (Vault)      │  decisions                 │  résultats de test         │
              │  knowledge                 │                            │
              │  skills                    │                            │
              │  registre des projets      │                            │
              │  standards de test         │                            │
              │  → graphe du Vault         │  → hors graphe             │
              ├────────────────────────────┼────────────────────────────┤
 MÉTIER       │  règles métier du projet   │  missions closes           │
 (Projet)     │  décisions de fabrication  │  prompts archivés          │
              │  contexte maître           │  audits                    │
              │  contraintes, glossaire    │  handoffs anciens          │
              │  stratégies de test        │  résultats d'exécution     │
              │  → graphe du projet        │  → hors graphe             │
              └────────────────────────────┴────────────────────────────┘
```

Le principe se lit en deux temps :

- **où ça vit** : la portée décide ;
- **si ça entre dans le graphe** : la nature décide.

## Le modèle de graphes

Chaque périmètre a son propre graphe. Aucun graphe global fusionné : fusionner ferait perdre les frontières, mélangerait des contextes sans rapport et dégraderait la portabilité de chaque projet pris isolément.

```text
                  ┌─────────────────────────────┐
                  │   VAULT — le comment         │
                  │   universel                  │
                  │   ────────────────────       │
                  │   registre des projets ●─────┼──┐
                  └─────────────────────────────┘  │
                             graphe A               │
                                                    │
        ┌───────────────────────┬───────────────────┴──────┐
        ▼                       ▼                          ▼
  ┌───────────┐          ┌───────────┐            ┌───────────┐
  │ projet 1  │          │ projet 2  │            │ projet N  │
  │ comment   │          │ comment   │            │ comment   │
  │ métier    │          │ métier    │            │ métier    │
  │ + quoi    │          │ + quoi    │            │ + quoi    │
  │ graphe B  │          │ graphe C  │            │ graphe D  │
  └───────────┘          └───────────┘            └───────────┘
```

Le registre des projets est le lien : le Vault connaît l'adresse de chaque projet, jamais son contenu. Les graphes restent séparés mais reliés par ce point d'entrée unique.

## Le piège du dossier qui mélange

Un même dossier peut contenir les deux natures. Le cas le plus net est celui des tests :

- une **stratégie de test** dit comment vérifier — c'est une instruction, elle entre dans le graphe ;
- un **résultat de test** atteste qu'une vérification a eu lieu — c'est une preuve, elle reste dehors.

L'axe de portée s'y applique aussi : les standards communs — doctrine de preuve, définition des marques de confiance, exigences avant clôture d'une Mission — vivent dans le Vault ; les stratégies propres à un domaine — comment tester une interface, une page, un flux métier — vivent dans le projet concerné.

Le même piège vaut pour les passations : le handoff courant est une instruction sur l'état du moment, les handoffs anciens sont des preuves.

D'où un principe pratique :

> Quand un dossier mélange instruction et preuve, séparer physiquement plutôt que filtrer finement.

Un filtre qui doit deviner la nature d'un fichier à partir de son nom ou de sa date est fragile et se dégrade à chaque ajout. Deux emplacements distincts rendent le tri mécanique, lisible par un humain comme par un agent, et robuste dans le temps.

## Le cas particulier de l'état courant

La couche d'instruction se subdivise en deux temporalités :

- **stable** : ce qui est vrai durablement — règles, décisions, connaissances ;
- **courant** : ce qui décrit l'état du moment — état courant, index des missions, handoff en cours.

Les deux entrent dans le graphe. Mais le courant, par nature, est remplacé plutôt qu'accumulé : un seul fichier d'état mis à jour en place, plutôt qu'une série datée. Sans cette discipline, la couche courante devient une couche d'historique déguisée, et le graphe se dégrade.

## Ce que ce document ne tranche pas

L'application de ces principes à des cas précis — quels dossiers exactement, par quel mécanisme distinguer un handoff courant d'un handoff ancien, quand créer le graphe d'un projet — relève d'arbitrages distincts, à mener projet par projet.

## Liens

- `see also` — [Project Registry](../projects/PROJECT-REGISTRY.md)
