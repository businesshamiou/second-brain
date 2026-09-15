---
title: "Notes de publication"
description: "Ce que contient chaque version publiée de Second Brain, et ce qu'elle ne promet pas."
status: active
---

# NOTES DE PUBLICATION

## v0.1.0

Première version publiée : un historique neuf, sans aucun ancêtre de l'historique de développement, et aucun motif privé ni dans l'arbre ni dans l'historique (vérifié par `tools/check-private-patterns.sh` en mode complet).

**Ce que cette version contient.** L'installeur en une ligne (Windows, macOS, Linux) ; le questionnaire de sept questions ; l'assistant généré (sous-agent Claude Code, skill Codex, paquet web) ; les skills de la méthode et le warehouse de skills tiers ; les gardiens automatiques (`.githooks/pre-commit`) ; le registre de Missions et les gabarits de projet.

**Ce que cette version ne promet pas.** Aucun mécanisme de mise à jour : une installation vaut pour la version installée, elle ne peut pas en récupérer une plus récente. Pour une version plus récente, réinstalle depuis le dépôt publié — voir [« Reprise et mise à jour » du README](./README.md#reprise-et-mise-à-jour). Un projet créé pendant le questionnaire ne se renomme pas après coup. macOS n'est pas exercé par la CI automatique : son job ne part que sur déclenchement manuel.

## Liens

- `see also` — [README](./README.md)
- `see also` — [INSTALL](./INSTALL.md)
