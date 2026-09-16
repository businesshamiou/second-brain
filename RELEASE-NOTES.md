---
title: "Notes de publication"
description: "Ce que contient chaque version publiée de Second Brain, et ce qu'elle ne promet pas."
status: active
---

# NOTES DE PUBLICATION

## v0.1.1

Version de preuve : tout ce qui servait à accepter Second Brain devient rejouable, sans geste humain.

**Ce que cette version apporte.**

- **Une ligne d'installation qui n'exige rien d'installé.** Elle télécharge un script d'amorçage (`bootstrap.ps1`, `bootstrap.sh`). Celui-ci pose Git dans ton profil s'il manque, en vérifiant son empreinte, puis récupère le dépôt et lance l'installeur. La ligne de la v0.1.0 commençait par `git clone` : un poste sans Git ne pouvait pas démarrer. Rien ne demande de droits administrateur.
- **Une acceptation entièrement mécanique.** `tests/run-mechanical-acceptance.ps1` rend onze lignes datées (S1 à S10 et T21) :
  - l'assistant (S7) et le paquet web (S8) sont interrogés sur les trois questions de `assistant/ASSISTANT.md`, trois fois chacune, par deux fournisseurs ;
  - S9 installe la ligne publiée sous un compte Windows standard, sans Git, avec un témoin qui prouve qu'aucune élévation n'est possible ;
  - le wizard humain de la v0.1.0 est retiré (conservé dans `_trash/`).
- **Le paquet web contient exactement ce que son README annonce.** Un `index.md` en trop disparaît, et le compte de fichiers du README redevient exact.
- **L'assistant se charge dans Codex.** Sous Windows, les formes générées portaient une marque d'ordre des octets (BOM), qui empêchait Codex de lire le skill.
- **macOS et Linux tels qu'ils sont livrés.** Depuis la v0.1.0 :
  - les gardiens tournent réellement au commit (les hooks n'étaient pas exécutables) ;
  - les outils fonctionnent avec le bash 3.2 et les outils BSD d'Apple, que la CI exerce désormais sur macOS à chaque poussée ;
  - un chemin contenant `&` ou une barre oblique inverse n'échappe plus à deux gardiens ;
  - le mode test de l'installeur Unix n'écrit plus dans ton profil réel.

**Ce que cette version ne promet pas.**

- Toujours aucun mécanisme de mise à jour : une installation v0.1.0 ne devient pas v0.1.1 d'elle-même. Réinstalle depuis la ligne publiée si tu veux cette version.
- S7 et S8 appellent un modèle : dans la CI publique, sans clé de fournisseur, ces deux lignes sont notées `SKIP`, jamais réussies par défaut.
- S8 prouve le contenu du paquet et les réponses obtenues par équivalence ; il ne prouve pas le geste de téléversement dans l'interface web.

**Ce qui reste à faire de ton côté.**

- Coller la ligne d'installation.
- Sous macOS, accepter l'installation des outils en ligne de commande d'Apple si elle est proposée.
- Dans un Projet claude.ai ou ChatGPT, coller le fichier d'instructions du paquet web et téléverser les fichiers que son README liste.

## v0.1.0

Première version publiée : un historique neuf, sans aucun ancêtre de l'historique de développement, et aucun motif privé ni dans l'arbre ni dans l'historique (vérifié par `tools/check-private-patterns.sh` en mode complet).

**Ce que cette version contient.** L'installeur en une ligne (Windows, macOS, Linux) ; le questionnaire de sept questions ; l'assistant généré (sous-agent Claude Code, skill Codex, paquet web) ; les skills de la méthode et le warehouse de skills tiers ; les gardiens automatiques (`.githooks/pre-commit`) ; le registre de Missions et les gabarits de projet.

**Ce que cette version ne promet pas.** Aucun mécanisme de mise à jour : une installation vaut pour la version installée, elle ne peut pas en récupérer une plus récente. Pour une version plus récente, réinstalle depuis le dépôt publié — voir [« Reprise et mise à jour » du README](./README.md#reprise-et-mise-à-jour). Un projet créé pendant le questionnaire ne se renomme pas après coup. macOS n'est pas exercé par la CI automatique : son job ne part que sur déclenchement manuel.

## Liens

- `see also` — [README](./README.md)
- `see also` — [INSTALL](./INSTALL.md)
