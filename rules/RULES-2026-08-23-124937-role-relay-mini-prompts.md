---
type: rules
title: "Relais entre rôles par mini-prompts à rubriques fixes"
description: "Format symétrique de passation entre la fenêtre Pilot et la fenêtre Executor : mini-prompt à l'aller, bloc RELAY au retour."
created_at: 2026-08-23T12:49:37-04:00
timezone: America/Montreal
status: active
scope: role-relay, mission-workflow
---

# RELAIS ENTRE RÔLES PAR MINI-PROMPTS

> ### Règle — relais entre rôles par mini-prompts
>
> **Aller.** Toute Mission part avec un mini-prompt de consommation, livré par le Pilot **en snippet copiable d'un seul geste** (bloc de code dans le chat), jamais en fichier à ouvrir ni en prose à recomposer. Cinq rubriques fixes, dans cet ordre :
>
> 1. Ligne de titre : `Session Executor — Mission <NNN> (<description courte>)` — elle nomme la session. La forme `Tu es l'Executor — Mission <NNN> (<description courte>)` est équivalente, et s'étend à toute instruction ponctuelle déléguée à l'Executor sans numéro de Mission, sous la forme `Tu es l'Executor — instruction ponctuelle (<description courte>)` (`DECISION-2026-08-27-100016`).
> 2. Position : libre ; la session établit sa conscience de position (Décision `213150`).
> 3. Source à appliquer : le chemin du fichier Mission, relatif au Vault, à lire et appliquer intégralement.
> 4. Interdits absolus : toujours « aucun git push, aucun appel modèle, aucune suppression ; déplacement vers `_trash/` seulement sur prescription de la Mission », plus les interdits propres à la Mission. Le mini-prompt n'affirme jamais qu'un geste Owner (push, suppression, vidage de `_trash/`) a eu lieu : il demande à l'Executor de le mesurer, STOP si absent (`DECISION-2026-08-29-110852`).
> 5. Sortie attendue : terminer la fenêtre par le bloc RELAY défini dans la Mission, rempli.
>
> Le mini-prompt ne duplique pas le contenu de la Mission.
>
> **Type `initiation` (amendement du 2026-09-17, Décision 000545 A5).** Un Pilot sans Mission peut émettre un **ordre d'initiation** pour faire naître ou adopter un projet. Son mini-prompt porte la ligne de titre `Session Executor — initiation (<nom du projet>)`, la position, les interdits absolus et la sortie attendue, mais **aucune rubrique « Source à appliquer »** : l'ordre est la source. Il porte à la place les huit champs de l'ordre, dans cet ordre :
>
> 1. `Type` : `create` ou `adopt`.
> 2. `Mode` : `answered` (toutes les réponses sont dans l'ordre, aucune question) ou `ask` (le bootstrap pose nom, emplacement et Git).
> 3. `Nom` : nom du dossier du projet.
> 4. `Emplacement` : dossier parent, chemin absolu.
> 5. `Vault + construction` : `vault_id=…, vault_origin=…, vault_ref=…`.
> 6. `Git` : `none` ou `git`.
> 7. `Objet` : une phrase.
> 8. `Autorisation Owner datée` : la phrase de l'Owner, verbatim, avec sa date `AAAA-MM-JJ`.
>
> L'Executor la consomme comme une Mission, périmètre borné à la cible et au registre du Vault : `tools/project-bootstrap.sh --order <fichier>`. L'ordre vierge, pré-rempli pour un dossier, se rend par `tools/project-bootstrap.sh order <dossier>` ; le gabarit est [l'ordre d'initiation](../templates/initiation-order-template.md).
>
> **Retour.** Tout rapport d'exécution se termine par un bloc `RELAY` affiché en fin de fenêtre Executor, aux rubriques fixes suivantes, dans cet ordre : ce bloc est livré **en snippet copiable d'un seul geste** (bloc de code en fin de fenêtre), jamais en prose à recomposer — symétrie avec le sens aller (`DECISION-2026-08-27-100016`).
>
> ```text
> RELAY <NNN>
> Rapport   : <chemin du fichier REPORT déposé>
> Verdict   : <FAIT | PARTIEL | BLOQUÉ> + une ligne
> Critères  : <n>/<total> PASS
> Commits   : <dépôt> <hash> · <dépôt> <hash>
> Résumé    : <trois à cinq lignes>
> À trancher: <une ligne, ou « rien »>
> ```
>
> La rubrique **Résumé** tient en trois à cinq lignes, plafond strict — au-delà, elle redevient un second rapport et le coût qu'elle économise est repayé. Trois contraintes :
>
> 1. Des faits, pas des appréciations : un chiffre, une comparaison, un écart nommé. « Q5 en hausse » ne vaut rien ; « Q5 : 12 décisions trouvées contre 7 » vaut la rubrique entière.
> 2. Les chiffres qui changent une conclusion, et ce qui a surpris l'Executor.
> 3. Tout écart au protocole ou à la Mission y figure, même mineur, même sans conséquence apparente — c'est le seul endroit où le Pilot peut le voir sans ouvrir le rapport.
> Quand un geste réservé à l'Owner bloque la Mission, la rubrique « À trancher » nomme le chemin exact et le substitut disponible (déplacement vers `_trash/`) ; l'Executor s'arrête sans second outil ni contournement — le refus est structurel (`DECISION-2026-08-29-110852`).
>
> **Pont.** L'Owner est le seul canal entre les deux fenêtres : il colle le mini-prompt à l'aller, il recolle le bloc `RELAY` au retour. Le Pilot reprend sur la foi du bloc, et ne relit le rapport entier que si le verdict ou la rubrique « À trancher » l'exige.
>
> **Portée.** La règle vaut pour toute action déléguée à l'Executor, Mission ou instruction ponctuelle, dans tous les projets.

## Liens

- `source` — Proposal — Relais entre rôles par mini-prompts à rubriques fixes (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Décision — Adoption de la règle du relais entre rôles](../decisions/DECISION-2026-08-23-124937-role-relay-mini-prompts.md)
- `amended by` — [Décision — Rubrique « Résumé » dans le bloc RELAY du sens retour](../decisions/DECISION-2026-08-23-180500-relay-summary-rubric.md)
- `amended by` — Décision — Répertoire d'ouverture d'une session, position libérée (historique de l'atelier, non distribué)
- `amended by` — [Décision — Le push délégué devient une règle](../decisions/DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)
- `amended by` — [Décision — Protocole de copie : snippets et destinations](../decisions/DECISION-2026-08-27-100016-copy-protocol-snippets-and-destinations.md)
- `amended by` — [Décision — La suppression définitive est un geste Owner](../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
- `amended by` — Décision — Cohérence interne des Missions (historique de l'atelier, non distribué) (hors Vault)
- `amended by` — [Décision — Initiation et adoption de projet, acte de naissance](../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md) (type de mini-prompt `initiation`)
