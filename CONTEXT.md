---
type: context
title: "Second Brain — glossaire"
description: "Glossaire des termes du produit, validé en T18, au format CONTEXT.md du skill domain-modeling."
status: active
---

# Second Brain — glossaire

Les termes du produit, tels qu'un utilisateur ou un agent les rencontre dans ce dépôt. Validé par l'Owner (DECISION, T18 de la Mission 168), livré ici tel quel.

## Langage

**Second Brain**:
Le système installé — règles, méthodes, gabarits, skills, gardiens — versionné dans le dépôt `second-brain`.
_Éviter_ : OS, framework.

**Vault**:
Nom interne de Second Brain dans les règles et les outils ; même chose.

**Workspace**:
Le dossier qui contient `second-brain` et tes projets, marqué par `VAULT-ROOT.md`.
_Éviter_ : dossier racine.

**Projet**:
Un dossier de travail à côté de `second-brain`, inscrit au registre, qui hérite de la méthode.

**Skill fabriqué**:
Un skill écrit pour Second Brain, dans `skills/`.

**Skill adopté**:
Un skill tiers vérifié, entré par ingestion.
_Éviter_ : plugin, extension.

**Warehouse**:
La bibliothèque des skills adoptés, `skills-warehouse/`.

**Assistant**:
L'agent de Second Brain, nommé par l'utilisateur à l'installation ; nom proposé par défaut : Brian. Il guide l'installation, puis répond en lecture seule.
_Éviter_ : bot.

**Owner**:
Toi, qui décides et qui pousses.
_Éviter_ : admin.

**Pilot**:
Le rôle de session qui réfléchit, arbitre et rédige, sans exécuter.

**Executor**:
Le rôle de session qui exécute, mesure et commite, dans le périmètre d'une Mission.

**Mission**:
Le fichier qui prescrit un travail à l'Executor, gelé à son émission.
_Éviter_ : tâche, prompt.

**Décision**:
Un choix gravé et daté qui fait autorité.
_Éviter_ : ADR.

**Gardien**:
Un contrôle automatique au commit, qui refuse ce qui viole une règle.
_Éviter_ : hook, linter.

**Carnet d'installation**:
La trace qui permet de reprendre une installation interrompue.

## Note

« Atelier » est absent de ce glossaire : ce terme n'existe pas pour l'utilisateur de Second Brain — voir la [règle de frontière entre un projet et Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md).

## Liens

- `see also` — [README](./README.md)
- `see also` — [Règle de frontière entre un projet et Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
