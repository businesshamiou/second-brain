---
type: project-readme
title: "Les Pages Suspendues — projet d'exemple"
description: "Projet fictif, inventé pour ce dépôt, illustrant le squelette de sept fonctions d'un projet Second Brain."
status: active
---

# LES PAGES SUSPENDUES

**Ceci est un projet d'exemple, entièrement inventé pour la documentation de Second Brain.** Rien ici ne vient d'un projet réel : « Les Pages Suspendues » est un club de lecture de quartier imaginaire, choisi comme thème neutre pour illustrer, avec un contenu concret plutôt qu'abstrait, le [squelette de sept fonctions](../../rules/RULES-2026-08-26-142800-project-structure-standard.md) que `tools/project-bootstrap.sh` pose pour chacun de tes propres projets.

Ce dossier n'est **pas** un projet réel : il n'est pas inscrit au [registre des projets](../../projects/PROJECT-REGISTRY.md), qui reste vide tant que tu n'as pas créé le tien. Pour démarrer un vrai projet, utilise le skill `project-bootstrap` — voir la [règle de frontière entre un projet et Second Brain](../../rules/RULES-2026-09-11-190000-project-second-brain-boundary.md).

## Qui

Les Pages Suspendues est un club de lecture fictif d'une dizaine de membres, qui se retrouve une fois par mois pour discuter d'un livre choisi ensemble.

## Les sept fonctions, dans cet exemple

| Fonction | Dossier | Ce qu'il contient ici |
|---|---|---|
| Identité | ce fichier | qui est ce club, en deux phrases |
| Règles métier | [rules/](./rules/) | comment le club choisit son livre du mois |
| Mémoire d'état | `state/` | le journal du club (non suivi comme un document, voir sa propre note) |
| Exécution | [missions/](./missions/) | l'organisation d'une rencontre |
| Arbitrage | [decisions/](./decisions/) | un choix tranché (alterner les genres) |
| Matière | [knowledge/](./knowledge/) | des notes prises après une rencontre |
| Passation | [handoffs/](./handoffs/) | passer l'animation d'un mois à l'autre |

## Écriture

Dans un vrai projet, `CLAUDE.md` et `AGENTS.md` (posés par `tools/project-bootstrap.sh`, absents de cet exemple documentaire) portent la même règle : tout changement part d'une Mission écrite dans `missions/`, l'assistant du projet est en lecture seule, et l'agent qui ouvre le projet n'écrit rien de sa propre initiative en dehors de ce cadre.

## Liens

- `see also` — [Standard de structure de projet](../../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- `see also` — [Règle de frontière entre un projet et Second Brain](../../rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
- `see also` — [Registre des projets](../../projects/PROJECT-REGISTRY.md)
