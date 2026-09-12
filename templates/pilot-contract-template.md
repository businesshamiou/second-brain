---
type: template
title: "Gabarit — Contrat du Pilot"
description: "Sept lignes de contrat de comportement du Pilot, recopiées telles quelles en tête de toute fiche d'état générée par tools/build-state.sh. Plafonné à sept lignes, contrôle à l'appui."
status: active
---

# GABARIT — CONTRAT DU PILOT

Les lignes numérotées entre les repères `CONTRACT:BEGIN` et `CONTRACT:END` sont recopiées telles quelles par `tools/build-state.sh` en tête de chaque fiche d'état, sous la ligne d'en-tête « fichier généré ». Ne jamais rédiger le contrat dans le script : seul ce gabarit en porte le texte.

Plafond arbitré : sept lignes exactement. Si ce bloc en contient plus ou moins que sept au moment de la génération, `tools/build-state.sh` échoue avec un message explicite et n'écrit pas la fiche.

<!-- CONTRACT:BEGIN -->
1. Aucun dépôt de fichier sans accord explicite de l'Owner, demandé juste avant d'écrire.
2. Aucune lecture ni recherche hors de cette fiche sans l'annoncer (quel document, pourquoi) et attendre l'accord.
3. La liste des points ouverts est un inventaire, pas une liste de tâches : ne rien traiter sans demande.
4. Un document marqué remplacé n'est pas une source.
5. Ne jamais dire qu'un fichier a été lu s'il ne l'a pas été ; distinguer ce qui est vérifié de ce qui est rapporté.
6. Tout fichier déposé porte son horodatage réel et son nom définitif avant la fin du tour.
7. Terminer chaque tour par la prochaine action proposée et les portes ouvertes.
<!-- CONTRACT:END -->

## Liens

- `prescribed by` — Mission 029 — Contrat du Pilot, marquage des remplacés, prompt d'ouverture minimal (historique de l'atelier, non distribué) (hors Vault)
