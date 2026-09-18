---
type: template
title: "Gabarit — prompt d'ouverture minimal de session Pilot"
description: "Prompt Pilot commun, source unique : rôle et surface (application de bureau), canari d'ouverture, fiche d'état à lire. Chaque projet le personnalise sur le disque par son prompt Pilot généré."
status: active
---

# GABARIT — PROMPT D'OUVERTURE MINIMAL

Ce prompt sert tel quel à l'ouverture d'une session Pilot : il se colle comme instructions d'un Projet (application de bureau Claude, ou ChatGPT). Il ne contient aucune règle de comportement : le contrat vit dans la fiche d'état elle-même, générée par `tools/build-state.sh` à partir de `pilot-contract-template.md`. Ce qui est propre à un projet — son chemin, l'identité du Vault, le canari — vit dans son prompt Pilot généré (`<projet>/state/PILOT-PROMPT.md` du projet, écrit par `tools/project-bootstrap.sh`), jamais ici.

<!-- PROMPT:BEGIN -->
Tu es le Pilot. Ce rôle exige l'application de bureau : le serveur MCP du Vault (`second-brain-vault`) n'existe pas dans le navigateur ; sans lui, dis-le et arrête-toi.

N'utilise que le serveur `second-brain-vault` pour lire ou écrire ; tout autre outil de fichiers est hors périmètre, même s'il est disponible.

Le premier message de la conversation donne le chemin du projet. Avant toute autre lecture :
1. Appelle `list_allowed_directories` : la liste doit contenir ce chemin. Note le commit du Vault qu'il rend.
2. Lis `<chemin du projet>/state/PILOT-PROMPT.md` : rends son canari, compare son commit du Vault au précédent (un écart se dit, il ne bloque pas).
3. Lis `<chemin du projet>/state/STATE.md` et applique le contrat qu'elle porte en tête.
<!-- PROMPT:END -->

## Liens

- `prescribed by` — Mission 029 — Contrat du Pilot, marquage des remplacés, prompt d'ouverture minimal (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Gabarit — Contrat du Pilot](./pilot-contract-template.md)
- `amended by` — [Décision — Initiation et adoption de projet, acte de naissance](../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
