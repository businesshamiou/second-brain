---
type: rules
title: "Versionnement des Missions et outputs générés"
created_at: 2026-08-17T21:15:22-04:00
timezone: America/Montreal
status: active
scope: transverse-project-governance
owner_gate: granted
---

# VERSIONNEMENT DES MISSIONS ET OUTPUTS GÉNÉRÉS

Cette règle transverse s’applique au Vault et aux projets qui en héritent. Elle complète le [cycle de contexte V2](./RULES-2026-08-17-111018-context-lifecycle-v2.md) sans imposer la création de dossiers sans besoin réel.

## 1. Identité permanente d’une Mission

Une Mission reçoit un identifiant projet sur trois positions : `001`, `002`, `003`, etc.

Convention :

`<projet>/missions/MISSION-YYYY-MM-DD-HHMMSS-NNN-description.md`

Le timestamp répond à « quand ce fichier a-t-il été créé ? ». L’ID répond à « quelle Mission représente-t-il ? ».

## 2. Corrections

Une correction conserve l’ID et ajoute `C01` à `C10` :

`<projet>/missions/MISSION-YYYY-MM-DD-HHMMSS-NNN-Cxx-description.md`

L’original n’utilise jamais `C00`. Atteindre `C10` impose de réexaminer si l’objectif doit devenir une nouvelle Mission.

Chaque correction reçoit son timestamp réel. Aucun redatage fictif n’est autorisé.

## 3. Version complète et autonome

Une correction n’est pas un patch isolé. La dernière version active contient l’objectif, le périmètre, les sources, les décisions applicables, les contraintes, les étapes, les gates, les validations et le contrat de sortie actuellement valides.

L’Executor consomme la dernière version active; il ne recompose pas l’état courant en additionnant toutes les versions précédentes.

Les anciennes versions restent conservées comme historique. Chaque correction déclare au minimum `mission_id`, `correction`, `supersedes` et `status`.

## 4. Prompts alignés (note historique — convention close à la Mission `038`)

Convention active jusqu’à la Mission `038` (fin des fichiers PROMPT, Decision `220049`) ; conservée pour lire les Missions antérieures, non appliquée au-delà. Le Prompt canonique d’Executor portait le même identifiant fonctionnel que sa Mission :

- original : PROMPT-YYYY-MM-DD-HHMMSS-NNN-executor-description.md;
- correction : PROMPT-YYYY-MM-DD-HHMMSS-NNN-Cxx-executor-description.md.

Le Prompt possède son propre timestamp réel. Une correction qui modifie le contrat Executor aligne Mission et Prompt sur le même `Cxx`.

## 5. Decisions cumulatives

Les Decisions ne suivent pas la numérotation `NNN-Cxx`. Elles restent cumulatives.

Une Decision plus récente ne remplace une précédente que si elle déclare explicitement `supersedes`, `amends` ou `revokes`. Une proposition arbitrée n’est pas réécrite silencieusement : une nouvelle Decision enregistre l’arbitrage et référence l’historique.

## 6. Registre vivant

Un projet qui utilise des Missions maintient, lorsque le besoin existe :

`<projet>/missions/MISSION-INDEX.md`

Le registre indique au minimum l’ID, l’objectif, la version active, son statut et le chemin de la Mission active. Il ne recopie pas de mesures techniques périssables.

## 7. Zone `generated/`

`generated/` est une landing zone pour un output dont la destination canonique n’est pas encore déterminée.

Règles :

- non canonique par défaut;
- review et validation avant promotion;
- provenance conservée;
- nomenclature datée respectée;
- ne jamais l’utiliser lorsqu’une destination canonique est déjà connue;
- ne jamais y placer un secret ou contourner les règles Git du projet.

La promotion vers un emplacement canonique est explicite. La suppression d’un output suit les human gates applicables.

## 8. Héritage

Ordre de spécialisation :

```text
Vault rules
    ↓
Project rules
    ↓
Mission / task instructions
```

Un projet hérite de cette doctrine et documente uniquement ses spécialisations ou exceptions autorisées. L’héritage porte sur le comportement; il ne force pas la création de `missions/`, `generated/` ou d’autres dossiers sans besoin réel.

## 9. Consommation active

Pour exécuter une Mission :

1. lire les Decisions actives pertinentes;
2. résoudre la dernière version active via `<projet>/missions/MISSION-INDEX.md` lorsqu’il existe;
3. lire la Mission complète;
4. lire le Prompt aligné (uniquement pour les Missions antérieures à la Mission `038` ; convention close au-delà, Decision `220049`);
5. remesurer l’état technique utile;
6. respecter les gates et frontières du projet.

## 10. Auto-rangement

Toute Mission commite son propre fichier et régénère les index générés en dernières étapes de sa fenêtre d'exécution. Une Mission qui laisse ce rangement à une fenêtre ultérieure le déclare explicitement en ANOMALY dans son rapport. [source : [Decision — Arbitrages doctrinaux du 2026-08-25](../decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md), point 2]

## Liens

- `amended by` — [Decision : taxonomie PIV, langue système anglaise, charte des rôles, fin des PROMPT, §4 prompts alignés](../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md)
- `amended by` — [Décision — Un fichier de Mission est gelé dès l'émission de son snippet](../decisions/DECISION-2026-08-30-013217-mission-frozen-at-snippet-emission.md)
- `source` — [Decision — Arbitrages doctrinaux du 2026-08-25](../decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md)
