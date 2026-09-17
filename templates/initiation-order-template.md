---
type: template
title: "Gabarit — ordre d'initiation"
description: "Les huit champs de l'ordre qui fait naître ou adopter un projet sans Mission : rempli par le Pilot, daté par l'Owner, consommé par l'Executor."
status: active
---

# GABARIT — ORDRE D'INITIATION

L'ordre d'initiation remplace la Mission pour un seul geste : faire naître (`create`) ou adopter (`adopt`) un projet. Le Pilot le remplit, l'Owner y écrit son autorisation datée, l'Executor le consomme par `tools/project-bootstrap.sh --order <fichier>`. Il voyage dans un mini-prompt de type `initiation`, sans rubrique « Source à appliquer » : l'ordre est la source ([règle du relais](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)).

Un agent qui ouvre un dossier non adopté sans ordre s'arrête et rend cet ordre pré-rempli : `tools/project-bootstrap.sh order <dossier>`.

<!-- ORDER:BEGIN -->
Session Executor — initiation (<nom du projet>)

Position : libre ; établis ta conscience de position.

Ordre d'initiation
- Type : <create | adopt>
- Mode : <answered | ask>
- Nom : <nom du dossier>
- Emplacement : <dossier parent, chemin absolu>
- Vault + construction : vault_id=<…>, vault_origin=<…>, vault_ref=<…>
- Git : <none | git>
- Objet : <une phrase>
- Autorisation Owner datée : <phrase de l'Owner, verbatim, AAAA-MM-JJ>

Interdits absolus : aucun git push, aucun appel modèle, aucune suppression ; écriture bornée au dossier cible et au registre du Vault ; réorganisation proposée, jamais appliquée.

Sortie attendue : la sortie de tools/project-bootstrap.sh --order, dont le bloc à consommer, en snippet copiable.
<!-- ORDER:END -->

## Champs

| Champ | Valeurs | Effet |
|---|---|---|
| `Type` | `create`, `adopt` | naître (cible absente) ou adopter (dossier existant, rien de modifié) |
| `Mode` | `answered`, `ask` | toutes les réponses dans l'ordre, ou questions nom, emplacement et Git |
| `Nom` | texte | nom du dossier et nom affiché |
| `Emplacement` | chemin absolu | dossier parent |
| `Vault + construction` | `vault_id`, `vault_origin`, `vault_ref` | le Vault qui exécute doit porter ce `vault_id`, sinon refus |
| `Git` | `none`, `git` | `none` : contrôles par commande, aucun hook ; absent : question posée |
| `Objet` | une phrase | recopiée dans la fiche du projet |
| `Autorisation Owner datée` | verbatim avec `AAAA-MM-JJ` | sans date, refus |

## Liens

- `see also` — [Relais entre rôles par mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Décision — Initiation et adoption de projet, acte de naissance](../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
