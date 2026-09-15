---
type: brief
title: "Modèle opératoire des projets"
created_at: 2026-08-17T14:01:00-04:00
timezone: America/Montreal
status: superseded
scope: transverse-project-guidance
---

# MODÈLE OPÉRATOIRE DES PROJETS

## But

Expliquer comment un projet externe doit collaborer avec le Vault sans copier l'architecture du Vault.

Ce modèle applique la [séparation entre Vault et projets frères](../decisions/DECISION-2026-08-17-003000-vault-central-architecture.md) ainsi que l'[architecture d'information V1](../decisions/DECISION-2026-08-17-111018-vault-v1-information-architecture.md). Les artefacts optionnels suivent le [cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md) et les [modèles du Vault](../templates/).

## 1. Vault vs projet

Le Vault garde la manière de travailler.

Le projet garde ce sur quoi on travaille.

Le Vault contient les règles, méthodes, connaissances transversales et modèles réutilisables.

Le projet contient son objectif, son contexte, son état, ses règles spécifiques et ses productions métier.

## 2. Noyau minimal recommandé

Un nouveau projet peut commencer par :

```text
project/
├── README.md
├── AGENTS.md
├── .gitignore
└── docs/
    ├── project-overview.md
    └── current-state.md
```

Ne pas créer d'autres dossiers par anticipation.

## 3. Structure à la demande

Ajouter uniquement quand le besoin apparaît :

```text
rules/          # règles propres au projet
proposals/      # options importantes à arbitrer
decisions/      # décisions spécifiques au projet
captures/       # apprentissages durables
handoffs/       # vraies passations
resources/      # inventaire des ressources externes
src/            # code si applicable
tests/          # tests si applicable
assets/         # assets versionnables si applicable
```

La structure métier reste libre et dépend du type de projet.

Les dossiers apparaissent pour porter un besoin réel ; leur simple disponibilité dans le Vault ne justifie pas leur création dans chaque projet.

## 4. Règles du Vault et règles du projet

Ordre de spécialisation :

```text
Vault rules
    ↓
Project rules
    ↓
Mission / task instructions
```

Les règles du Vault portent le transverse.

Les règles projet portent le métier, la stack, le format, les contraintes ou les conventions propres au projet.

Une règle projet peut spécialiser le cadre, mais ne doit pas neutraliser silencieusement les garde-fous structurants du Vault.

## 5. Git : ce qui entre dans le repo

À versionner de préférence :

- code et scripts ;
- fichiers Markdown ;
- configuration ;
- tests ;
- petits assets ;
- schémas ;
- fichiers source raisonnablement petits ;
- tout artefact textuel important et reproductible.

## 6. Ressources hors Git

Certains éléments peuvent rester hors Git :

- vidéos brutes ;
- gros médias ;
- datasets volumineux ;
- fichiers binaires lourds ;
- assets achetés ou soumis à licence ;
- exports temporaires.

Ils restent néanmoins connus du projet via un manifeste, par exemple :

`resources/resources-manifest.md`

Le manifeste peut contenir :

- `name`
- `purpose`
- `location`
- `version`
- `license`
- `git_tracked`
- `checksum` lorsque pertinent

Le manifeste ne doit pas contenir de secret.

## 7. Un repo ou plusieurs ?

Règle par défaut :

> Un projet = un repo principal.

Séparer en plusieurs repos uniquement si un besoin réel le justifie :

- permissions différentes ;
- cycles de déploiement indépendants ;
- produits distincts ;
- contraintes de sécurité ;
- forte autonomie technique.

Ne pas multiplier les repos seulement pour classer des fichiers.

## 8. Principe de conception

> **Besoin réel → structure.**

L'objectif est de rendre les projets suffisamment structurés pour être pilotables par les agents, sans reproduire la complexité du Vault.

## Liens

- `superseded by` — [BRIEF-2026-08-17-211522-project-operating-model-v2 — Modèle opératoire des projets V2 — frontière Vault/projet et hiérarchie Vault rules → Project rules → Mission/task instructions](BRIEF-2026-08-17-211522-project-operating-model-v2.md)
