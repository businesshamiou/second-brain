---
type: brief
title: "Modèle opératoire des projets V2 — frontière Vault/projet et hiérarchie Vault rules → Project rules → Mission/task instructions"
created_at: 2026-08-17T21:15:22-04:00
timezone: America/Montreal
status: active
scope: transverse-project-guidance
supersedes: "BRIEF-2026-08-17-140100-project-operating-model.md"
---

# MODÈLE OPÉRATOIRE DES PROJETS V2 — FRONTIÈRE VAULT/PROJET ET HIÉRARCHIE DES INSTRUCTIONS

## But

Expliquer comment un projet collabore avec le Vault, versionne ses Missions et reçoit des outputs générés sans copier toute l’architecture du Vault.

Ce modèle applique l’[architecture Vault/projets](../decisions/DECISION-2026-08-17-003000-vault-central-architecture.md), le [cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md) et la [règle de versionnement des Missions et outputs générés](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md).

## 1. Vault vs projet

Le Vault conserve la manière de travailler : règles, méthodes, connaissance transverse et templates. Le projet conserve ce sur quoi on travaille : objectif, contexte, état, règles spécifiques et productions métier.

Le Vault ne remplace jamais le contexte local et n’importe pas automatiquement les décisions ou artefacts d’un projet.

## 2. Noyau minimal recommandé

Un projet piloté par l’IA peut commencer par :

```text
project/
├── README.md
├── AGENTS.md
├── .gitignore
├── docs/
│   ├── project-overview.md
│   └── current-state.md
└── generated/
```

`generated/` reçoit seulement les outputs sans destination canonique connue. Il est non canonique par défaut et chaque contenu attend une review ou une promotion explicite.

Si aucun tel output n’existe, le dossier n’a pas besoin d’être créé : **besoin réel → structure**.

## 3. Structure à la demande

Ajouter uniquement lorsque le besoin apparaît :

```text
rules/          # règles propres au projet
missions/       # Missions et registre actif
proposals/      # options importantes à arbitrer
decisions/      # décisions spécifiques au projet
captures/       # apprentissages durables
handoffs/       # vraies passations
resources/      # inventaire des ressources externes
src/            # code si applicable
tests/          # tests si applicable
assets/         # assets versionnables si applicable
```

## 4. Missions et versions actives

Lorsqu’un projet utilise des Missions, chaque objectif reçoit un ID `NNN`. Les corrections `Cxx` conservent cet ID, utilisent un nouveau timestamp réel et restent complètes et autonomes.

La Mission et son Prompt Executor portent le même `NNN/Cxx`. Les anciennes versions sont historiques; `<projet>/missions/MISSION-INDEX.md` résout la version active sans recopier d’état Git périssable.

Les Decisions restent cumulatives et ne sont jamais requalifiées silencieusement.

## 5. Héritage des règles

```text
Vault rules
    ↓
Project rules
    ↓
Mission / task instructions
```

Les règles projet spécialisent le métier, la stack et les contraintes locales. Elles ne neutralisent pas silencieusement les garde-fous de sécurité, de preuve ou de frontière externe.

## 6. Git et ressources externes

Versionner de préférence code, Markdown, configuration, tests, schémas, petits assets et sources reproductibles.

Les vidéos, datasets volumineux, gros médias, assets sous licence et autres binaires lourds peuvent rester hors Git, mais le projet conserve leur rôle et leur provenance dans un manifeste sans secret.

Règle par défaut : un projet possède un repo principal. Plusieurs repos ne sont justifiés que par des permissions, cycles de déploiement, produits ou contraintes de sécurité réellement distincts.

## 7. Principe de conception

> **Le Vault définit le cadre commun. Le projet conserve son contexte et spécialise le cadre. Besoin réel → structure.**

## Liens

- `supersedes` — [BRIEF-2026-08-17-140100-project-operating-model — Modèle opératoire des projets](BRIEF-2026-08-17-140100-project-operating-model.md)
