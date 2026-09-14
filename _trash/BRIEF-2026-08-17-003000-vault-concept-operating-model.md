---
type: brief
title: "Vault — concept pédagogique et modèle opératoire"
created_at: 2026-08-17T00:30:00-04:00
timezone: America/Montreal
status: active
audience: "conception interne du workshop et future transposition pédagogique"
---

# VAULT — CONCEPT ET MODÈLE OPÉRATOIRE

## 1. Définition simple

Dans ce workshop, un **Vault** est un coffre de mémoire durable pour travailler avec l'IA.

Le mot anglais *vault* évoque un coffre ou un espace protégé où l'on conserve ce qui doit durer.

La métaphore retenue est celle d'un **mini second brain** :

- les conversations passent ;
- les sessions changent ;
- les agents changent ;
- le Vault reste.

## 2. Pourquoi le Vault apparaît après le Context Engineering

Le parcours pédagogique peut progresser ainsi :

1. **Prompt Engineering** — mieux formuler une demande.
2. **Context Engineering** — fournir à l'IA le bon contexte au bon moment.
3. **Harness Engineering** — construire l'environnement, les règles et les mécanismes qui rendent l'agent fiable.
4. **Vault** — donner à cet environnement une mémoire durable, possédée par l'utilisateur et indépendante d'une conversation particulière.

Le Vault matérialise donc une idée simple :

> le contexte important doit survivre à la session qui l'a produit.

## 3. Ce que le Vault conserve

Le Vault conserve ce qui est transversal et réutilisable :

- règles ;
- conventions ;
- méthodes ;
- skills ;
- templates ;
- pratiques Git ;
- règles de sécurité ;
- façons de capturer une décision ;
- façons de faire un handoff ;
- principes Graphify ;
- apprentissages généralisables validés.

## 4. Ce que le Vault ne conserve pas comme contexte central

Le Vault ne doit pas devenir un fourre-tout contenant toutes les informations détaillées de tous les projets.

Les projets gardent localement :

- leurs objectifs ;
- leur état ;
- leurs décisions ;
- leur connaissance métier ;
- leurs documents ;
- leurs sketches ;
- leurs handoffs.

Cette séparation protège la qualité du contexte.

## 5. Le Vault produit à l'extérieur de lui

Le Vault n'est pas le dossier dans lequel tous les projets sont construits.

Il reste stable.

Lorsqu'un nouveau projet démarre, le système crée ou prépare un dossier frère à l'extérieur du Vault.

```text
workshops/
├── vault/
├── product-alpha/
├── campaign-beta/
└── research-gamma/
```

Le Vault fournit la méthode.

Le projet possède son contenu.

## 6. Capitalisation

Le flux d'amélioration est bidirectionnel mais contrôlé :

```text
Vault
  ↓
Projet
  ↓
expérience réelle
  ↓
leçon généralisable
  ↓
human gate
  ↓
Vault amélioré
```

Une leçon ne remonte dans le Vault que lorsqu'elle est réellement transversale et validée.

## 7. Rôle dans le workshop

Le workshop lui-même sert de premier test réel du Vault.

La méthode enseignée est donc utilisée pour construire, documenter et améliorer le système qui permettra ensuite de réaliser d'autres projets avec l'IA.

Le Vault n'est pas présenté comme une technologie magique.

C'est d'abord une discipline :

- écrire ce qui doit durer ;
- séparer le transversal du spécifique ;
- versionner ;
- relier ;
- reprendre ;
- améliorer après validation.

## 8. Principe à retenir

> **Le Vault garde la manière de travailler. Le projet garde ce sur quoi on travaille.**

## Liens

- `see also` — [Architecture centrale — Vault permanent et projets frères](../decisions/DECISION-2026-08-17-003000-vault-central-architecture.md)
- `see also` — [Architecture d'information V1 — primitives, preuves et human gates](../decisions/DECISION-2026-08-17-111018-vault-v1-information-architecture.md)
