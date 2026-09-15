---
type: mission
mission_id: "NNN"            # identité permanente de la lignée, chaîne entre guillemets (ex. "018")
correction:                  # "Cxx" si correction, alors `supersedes:` (ligne suivante) porte le chemin du fichier remplacé ; sinon omettre les deux clés entièrement (pas de valeur vide)
supersedes:
status: AUTHORIZED           # autorisation à la création — figé, jamais retouché ensuite
title: "<titre de la Mission>"
description: "<une à deux phrases>"  # écrites par l'auteur au moment du dépôt, jamais générées par un modèle tiers (232341 §2.1)
created_at: "YYYY-MM-DDTHH:MM:SS±HH:MM"
timezone: America/Montreal
scope: <slug-kebab-case>
artifact_state: GENERATED_IN_CHAT
---

# MISSION <NNN> — <TITRE>

Rappel : `status` ci-dessus fige l'autorisation à la création de ce fichier ; il n'est jamais retouché. L'état d'exécution de cette Mission vit exclusivement dans `<projet>/missions/MISSION-INDEX.md`, colonne « Statut ». Ce gabarit se remplit avec le skill `ecriture-de-mission`.

## Existant mesuré

<!-- Obligatoire dès que le Périmètre comprend la création d'un fichier (DECISION-2026-09-04-121443 point 3). Table : commande de listage ou de recherche jouée, sortie, conclusion explicite — « aucun fichier ne remplit cette fonction » ou « le fichier X la remplit partiellement, la Mission l'amende au lieu de créer ». Une Mission qui crée sans cette rubrique remplie est refusée. Les paramètres d'un instrument tiers (plafonds, quotas, limites de clé, `max_tokens`) entrent ici au même titre qu'un fichier du corpus (rapport 157, F9). -->

| Commande | Résultat retenu |
|---|---|
| <commande jouée> | <ce qu'elle a montré> |

<Conclusion : ce qui est créé, ce qui est amendé, et pourquoi.>

## Contexte

<!-- Obligatoire (DECISION-2026-09-01-115547 point 1). Dans cet ordre : les faits mesurés qui motivent la Mission, chacun daté et qualifié MESURÉ / DECLARED / HYPOTHÈSE ; ce que l'Executor va trouver sur disque et pourquoi c'est là ; les pièges connus (précédents, défauts d'outil, emplacements trompeurs) ; pourquoi la décision qui autorise cette Mission est ce qu'elle est. -->

<Faits mesurés, état attendu sur disque, pièges, raison de la décision.>

## Objectif

<Résultat poursuivi et raison de l'ouverture de cette Mission.>

## Périmètre

<Dépôts, dossiers ou systèmes concernés.>

<!-- Dès qu'une étape régénère un index, le `superseded-files.txt` du dépôt concerné entre au Périmètre : c'est une sortie garantie de l'outil d'indexation, jamais une exception (rapport 132, cas C4). -->

Hors périmètre : <ce qui est explicitement exclu.>

## Préconditions

<!-- Ce que l'Executor mesure avant d'écrire quoi que ce soit ; au moindre écart non trivial : STOP et rapport, aucune écriture (232341, Impact). -->
<!-- Une tolérance de git status déjà nommée par la Mission précédente ne se reconduit pas : lot 0 qui la règle, ou arbitrage Owner cité (liste de contrôle, ligne 26). -->

1. <État attendu, mesuré avant toute écriture ; écart non trivial = STOP.>

## Sources

- <Autre source : rapport, Decision, mesure antérieure.>

## Décisions applicables

- <Decision ou contrainte transverse qui s'applique à cette Mission.>

## Contraintes

- <Limite à respecter pendant l'exécution.>

## Mesures préalables

<!-- Obligatoire dès qu'une étape crée, copie, installe, épingle, câble ou configure quoi que ce soit (rapport 157, F6). Une ligne par cible posée : ce qu'on va poser, la commande qui mesure l'état de la cible avant la pose, et ce qu'elle a rendu. Une pose dont la cible n'a pas de ligne ici est une pose à l'aveugle : huit sur vingt-six l'ont été sur les Missions 145-156, et cinq ont fini en arrêt ou en travail nul. -->

| Cible | Commande jouée | Résultat |
|---|---|---|
| <ce que l'étape N va poser> | <commande qui mesure l'état de la cible> | <ce qu'elle a rendu> |

Tout comportement attendu d'un outil, d'un hook ou d'un drapeau qui n'a pas été exercé par une commande est écrit `HYPOTHÈSE` au Contexte.
<!-- Simulation du commit (liste de contrôle, ligne 24) : une section « ## Simulation du commit » suit cette rubrique dès qu'un commit est prescrit — par commit, fichiers stagés, gardiens exécutés, verdict attendu et sa raison, configuration de hooks telle qu'elle sera après la Mission. -->

## Étapes

<!-- Aucune étape « supprimer » : soit « déplacer vers _trash/ » (étape agent, empreinte + absence remesurée en validation), soit « suppression par l'Owner » en human gate hors des étapes, mesurée à la reprise (DECISION-2026-08-29-110852). -->
0. **Pré-vol** (DECISION-2026-09-04-154756, point 1) — obligatoire dès que le Périmètre comprend le commit d'un artefact déposé par le Pilot. Lancer sur les fichiers du Périmètre tous les contrôles applicables, collecter **toutes** les violations, les rapporter en une seule fois, s'arrêter si l'une subsiste. Le pré-vol ne corrige rien : un défaut se corrige par le rôle qui a écrit le fichier.
<!-- Dès qu'un commit du Vault est prescrit : lot explicite « commit Vault → arrêt → push Owner → ré-épinglage de l'atelier (historique, non distribué) → suite » (liste de contrôle, ligne 25). Le Contrat de reprise ne déclare pas « sain » un état où l'atelier (historique, non distribué) ne peut plus commiter. -->
<!-- Dès qu'une étape modifie un gardien d'index (fraîcheur, poids) : rejouer le banc tools/bench-guardians.sh du Vault avant et après, table collée au rapport (Mission 164). -->
1. <Étape ordonnée.>

## Gates

- Autorisation Owner : <accordée pour ... | en attente>
- Human gate non accordé : <ce qui reste hors autorisation>
- Conditions d'arrêt : <signal qui interrompt la Mission>

## Validations

<!-- Relecture croisée faite par le Pilot avant dépôt (DECISION-2026-09-01-115547 point 2) : chaque critère ci-dessous est atteignable sans violer un interdit de Gates ou de Contraintes ; chaque étape est permise par les mêmes interdits. -->
<!-- Chaque critère porte un compte relatif chiffré, avant et après (232341, Impact) : pas "corrigé", mais "3 avant, 0 après". -->

- <Critère vérifiable qui confirme le résultat, avec son compte avant/après chiffré.>

## Contrat de sortie

<Forme du rapport de clôture attendu : distinction VERIFIED/ANOMALY, preuves, SHA des commits, remesure finale, arrêt explicite.>

## Contrat de reprise

<!-- Rempli seulement si la fenêtre s'arrête en PARTIEL : dernier commit sain, ce qui reste à faire, comment la prochaine fenêtre reprend sans rejouer ce qui est fait (232341, Impact). -->

<Dernier commit sain ; étapes restantes ; point de reprise pour la prochaine fenêtre.>

## Portes

<!-- Une ligne par porte que cette Mission ouvre ou ferme, avec sa ligne CLOSE: exacte si elle se ferme ici (Decision 110935, 232341 Impact). -->

- <clé de porte> — <CLOSE: ... | reste ouverte, raison>

## Liens

- `prescribed by` — [Versionnement des Missions et outputs générés](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `amended by` — [Décision — La suppression définitive est un geste Owner](../decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
- `amended by` — Décision — Cohérence interne des Missions (historique de l'atelier, non distribué) (hors Vault)
- (à compléter : type — titre — chemin relatif, voir le standard de liens)
