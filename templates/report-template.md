---
type: report
title: "Rapport d'exécution — Mission <NNN>"
created_at: "YYYY-MM-DDTHH:MM:SS±HH:MM"
timezone: America/Montreal
mission_id: "<NNN>"
role: executor
related_mission: "<chemin relatif vers la Mission>"
related_prompt: "<chemin relatif vers le Prompt>"
status: FINAL
---

# RAPPORT D'EXÉCUTION — MISSION <NNN>

## 1. Gates

- Push : <fait | non fait>, dans <quel dépôt>.
- <Autre gate mesuré : version système, appel modèle, garde-fou touché ou non.>

## 2. Fichiers créés et modifiés

**Vault :**
- <Créé | Modifié> : `<chemin relatif>`

**\<projet\> :**
- <Créé | Modifié> : `<chemin relatif>`

## 3. Commits

- Vault : `<SHA>` — "<message>"
- \<projet\> : `<SHA>` — "<message>"

Le SHA du commit Vault et les `git status -sb` finaux sont mesurés **avant** le staging de ce rapport. Le SHA du commit du projet qui contient ce rapport ne peut pas être connu avant ce commit (le rapport s'auto-référencerait) ; il est donné en chat, jamais laissé en emplacement vide ici.

## 4. Impact sur l'installation

<Changement système, environnement, runbook, ou « Aucun changement ».>

## 5. État final mesuré

<Mesure directe, commande à l'appui, distinguée VERIFIED / DECLARED selon les niveaux de preuve.>

## 6. Écarts

- <Écart avec le Prompt, ou « Aucun écart ».>

## 7. Remesure finale, arrêt

```
<commande de remesure et résultat>
```

Cette remesure est faite **avant** le staging de ce rapport, jamais laissée en emplacement du type « rempli après commit ». Aucun emplacement `<…>` ne doit subsister dans un rapport final.

Arrêt de la Mission ici.

## Bloc RELAY

Ce bloc est rempli **en dernier** et affiché **tel quel** en fin de fenêtre Executor, conformément à la [règle du relais entre rôles](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md) :

```text
RELAY <NNN>
Rapport   : <chemin du fichier REPORT déposé>
Verdict   : <FAIT | PARTIEL | BLOQUÉ> + une ligne
Critères  : <n>/<total> PASS
Commits   : <dépôt> <hash> · <dépôt> <hash>
Résumé    : <trois à cinq lignes ; faits et chiffres, pas d'appréciations ; plafond strict>
À trancher: <une ligne, ou « rien »>
```

## Liens

- `prescribed by` — [Canal de rapport d'exécution](../decisions/DECISION-2026-08-21-000236-execution-report-channel.md)
- `prescribed by` — [Relais entre rôles par mini-prompts à rubriques fixes](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Décision — Rubrique « Résumé » dans le bloc RELAY du sens retour](../decisions/DECISION-2026-08-23-180500-relay-summary-rubric.md)
- (à compléter : type — titre — chemin relatif, voir le standard de liens)
