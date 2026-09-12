---
type: decision
title: "Adoption du format OKF comme norme de référence"
created_at: 2026-08-19T11:53:06-04:00
timezone: America/Montreal
status: active
scope: vault-artifact-format
owner_gate: granted
source_proposal: none
---

# DECISION — ADOPTION DU FORMAT OKF

## Contexte

Le Vault a développé ses propres conventions d'artefacts : Markdown, front-matter YAML typé, liens relatifs, versionnement Git. Une comparaison avec l'Open Knowledge Format v0.2, format ouvert et vendor-neutral publié par Google Cloud Platform, a montré une convergence forte et une conformité déjà acquise.

Référence : https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf

## Conformité constatée

Le Vault satisfait les trois critères de conformité OKF v0.2 sans modification : front-matter YAML parsable sur chaque document, champ `type` non vide partout, aucun usage non conforme des noms réservés `index.md` et log.md.

## Décision

Le projet adopte OKF comme norme de référence externe pour le format de ses artefacts de connaissance, et la cite comme telle dans la production pédagogique du workshop.

L'adoption est progressive et sans rupture.

### Adopté immédiatement

- `index.md` par dossier de premier niveau du Vault, pour la progressive disclosure : un agent lit l'index avant de décider quels fichiers ouvrir. Ceci rend également visibles dans Git les dossiers qui seraient autrement vides.
- `stale_after` sur les artefacts sujets à péremption, à commencer par les fiches du [Project Registry](../projects/PROJECT-REGISTRY.md).
- Champ `description` dans le front-matter des artefacts nouvellement créés.

### Conservé en l'état, et documenté comme écart assumé

- Valeurs de `type` en minuscules. OKF ne registre pas centralement ces valeurs et n'impose aucune casse ; la règle de gel du stock interdit par ailleurs tout renommage rétroactif.
- Champ `status` porteur d'un statut métier (`AUTHORIZED`, `ARBITRATED`, `COMPLETED`, `PROPOSED`) là où OKF le réserve au cycle de vie du document. L'écart est assumé et tracé ici.

### Reporté

- `generated` et `verified` structurés avec convention d'acteur. Les trust tiers OKF correspondent exactement à la doctrine VERIFIED / DECLARED du chantier ; l'alignement aura de la valeur lorsque les Skills exploiteront ces champs.
- Champ `sources` structuré.
- log.md par scope.

## Conséquences

Aucune migration, aucun renommage, aucune réécriture d'artefact existant. Les conventions de nommage de fichiers du Vault restent la seule source sur ce point : OKF ne spécifie pas le nommage.

Un futur alignement des points reportés fera l'objet d'une Decision cumulative distincte.

## Human gate

Arbitrage Owner rendu en session de pilotage.

## Liens

- `see also` — [Project Registry](../projects/PROJECT-REGISTRY.md)
