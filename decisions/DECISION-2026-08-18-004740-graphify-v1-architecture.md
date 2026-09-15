---
type: decision
title: "Architecture Graphify V1 — navigation optionnelle et corpus actif borné"
created_at: 2026-08-18T00:47:40-04:00
timezone: America/Montreal
status: active
owner_gate: granted
scope: graphify-v1-architecture
---

# DÉCISION — ARCHITECTURE GRAPHIFY V1

## Date

2026-08-18

## Statut

`ARBITRATED`

## Décision

Graphify `0.9.26` est validé comme couche **optionnelle** de navigation au-dessus des sources canoniques du Vault. Il aide à retrouver des fichiers et leurs liens, mais ne remplace ni leur lecture, ni une règle, ni une décision explicite. Toute exécution conserve un fallback vers les fichiers, les liens Markdown et la recherche locale.

### Machine

- Graphify et son extra Gemini sont installés hors repo via `uv tool`, avec la version épinglée à `0.9.26`;
- `GEMINI_API_KEY` est le nom canonique de la variable du backend Gemini;
- sa valeur reste dans `.env`, fichier local ignoré par Git, et n’est chargée que dans l’environnement du processus;
- `.env.example`, sans valeur secrète, est versionnable;
- aucun hook, MCP ou mécanisme de mise à jour automatique n’est activé par défaut.

### Vault

Le corpus actif V1 est constitué uniquement des sources transverses utiles :

- `README.md` et `AGENTS.md`;
- Decisions actives;
- Knowledge actives : modèle du Vault, modèle projet V2, vérification et preuves;
- Rules actives : conduite du Vault, cycle de contexte V2, versionnement des Missions;
- les cinq Templates documentaires.

Les sources explicitement superseded, secrets, configurations locales, caches, outputs générés et historiques non nécessaires sont exclus par `.graphifyignore` (supprimé, Mission 040). Le corpus pointe directement vers les sources canoniques; aucun dossier miroir ou duplicata dédié n’est créé.

### Projets

Le Vault et chaque projet conservent des graphes séparés. Un graphe projet reste dans le projet et couvre seulement son contexte local actif. Aucun merge global ou import automatique du contexte projet dans le Vault n’est autorisé en V1.

### Outputs générés

`graphify-out/` (supprimé, Mission 040) est dérivé, reconstructible, local et ignoré par Git. Il reste utilisable par Graphify sur la machine, mais ses graphes, manifests, caches et sauvegardes ne sont pas versionnés. Ces fichiers ne sont jamais édités manuellement.

### Actualisation

Le graphe est reconstruit explicitement après une modification canonique significative du corpus. Une actualisation n’est pas déclenchée mécaniquement à chaque session. Toute future automatisation, activation de hook/MCP, fusion globale ou modification de frontière exige une Mission et un human gate distincts.

## Raison

La baseline C01 a établi le fonctionnement de Graphify avec Gemini, mais a révélé un corpus bruité et une récupération A/B/C inégale. C02 a réduit le corpus de 17 à 15 documents, supprimé deux sources superseded du graphe, porté les arêtes de 16 à 28 et obtenu `PASS` sur les trois tests de navigation A/B/C.

La V1 privilégie donc un signal borné, des sources explicites et un coût réduit, tout en acceptant que Graphify reste principalement un index documentaire.

## Impact

- `.graphifyignore` (supprimé, Mission 040) porte les exclusions du corpus actif;
- `.gitignore` exclut `graphify-out/` (supprimé, Mission 040);
- `.env` reste local et `.env.example` peut être suivi;
- les fichiers du Vault restent la source de vérité;
- les graphes Vault et projets restent séparés;
- Graphify demeure facultatif et remplaçable par la navigation locale.

Les limites acceptées en V1 sont la granularité principalement documentaire, les labels parfois normalisés, la relation `references` dominante et une sélectivité limitée sur un petit corpus.

## Alternatives importantes

- **Versionner `graphify-out/`** (supprimé, Mission 040) : rejeté en V1, car l’output est dérivé, contient des caches et peut être reconstruit.
- **Rendre Graphify obligatoire** : rejeté, car les sources doivent rester utilisables sans l’outil ni le backend.
- **Fusionner les graphes Vault et projets** : rejeté en V1 pour préserver les frontières de contexte.
- **Ajouter des copies documentaires dédiées à Graphify** : rejeté pour éviter divergence et duplication.
- **Activer hooks ou MCP** : reporté à une Mission distincte si un besoin réel apparaît.

## Human gate

- Validation : accordée
- Référence : approbation explicite de l’Owner du gate Graphify V1 le 2026-08-18; preuve d’exécution conservée dans (historique de l'atelier, non distribué).

## Artefacts liés

- Architecture Vault/projets : [Vault central et projets frères](./DECISION-2026-08-17-003000-vault-central-architecture.md)
- Architecture d’information : [Architecture d’information V1](./DECISION-2026-08-17-111018-vault-v1-information-architecture.md)
- Modèle projet actif : [Modèle opératoire des projets V2](../knowledge/BRIEF-2026-08-17-211522-project-operating-model-v2.md)
- Cycle actif : [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- Preuves : [Vérification et preuves](../knowledge/verification-and-evidence.md)

## Liens

- `amended by` — [Amendement Graphify V1](./DECISION-2026-08-19-233650-graphify-integrations-amendment.md)
- `amended by` — [Retrait de Graphify du rôle « graphe du Vault »](./DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md)
