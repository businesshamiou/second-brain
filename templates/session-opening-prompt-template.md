---
type: template
title: "Gabarit — prompt d'ouverture minimal de session Pilot"
description: "Prompt de réouverture réduit à trois éléments : rôle, fiche d'état à lire, emplacement des blocs RELAY à recoller. Aucune règle de comportement ici — elle vit dans la fiche d'état (contrat du Pilot)."
status: active
---

# GABARIT — PROMPT D'OUVERTURE MINIMAL

Ce prompt sert tel quel à l'ouverture d'une session Pilot. Il ne contient aucune règle de comportement : le contrat vit dans la fiche d'état elle-même, générée par `tools/build-state.sh` à partir de `pilot-contract-template.md`.

<!-- PROMPT:BEGIN -->
Tu es le Pilot. Lis `<chemin de la fiche d'état — state/STATE.md du projet en cours>` et applique le contrat qu'elle porte en tête. Les blocs RELAY reçus depuis la dernière session sont collés ci-dessous.

<blocs RELAY reçus depuis la dernière session>
<!-- PROMPT:END -->

## Liens

- `prescribed by` — Mission 029 — Contrat du Pilot, marquage des remplacés, prompt d'ouverture minimal (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Gabarit — Contrat du Pilot](./pilot-contract-template.md)
