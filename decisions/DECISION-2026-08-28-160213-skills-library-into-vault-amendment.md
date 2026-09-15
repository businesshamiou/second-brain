---
type: decision
title: "Amendement — les 28 skills externes entrent dans le Vault, bibliothèque vault/skills/external/, la portée personnelle devient des jonctions"
description: "Amende DECISION-151235 §4 sur arbitrage Owner du 2026-08-28 : la bibliothèque canonique des 28 skills externes adoptés vit dans vault/skills/external/ et part avec le produit distribué ; la portée personnelle Claude devient des jonctions vers cette bibliothèque ; licence MIT et provenance embarquées ; le manifeste de distribution doit classer ces fichiers."
created_at: "2026-08-28T16:02:13-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md"
---

# DÉCISION — LA BIBLIOTHÈQUE DE SKILLS EXTERNES ENTRE DANS LE VAULT

## Date

2026-08-28

## Statut

`ARBITRATED`

## Décision

**1.** `DECISION-2026-08-28-151235` §4 (« portée personnelle, hors Vault ») est amendé : **la bibliothèque canonique des 28 skills adoptés vit dans `vault/skills/external/<nom>/`**. Elle fait partie du Vault et donc du produit distribué. Les listes (28 acceptés, 8 refusés), le critère de score et la règle de source unique (§1, §2, §3, §6 de 151235) restent inchangés.

**2.** Le sous-dossier `external/` est une frontière de provenance : il ne contient que du matériel d'auteurs tiers, jamais les skills propres du Vault (les six V1 de `DECISION-232341` §5.1 vivront directement dans `vault/skills/`).

**3.** La bibliothèque embarque la **licence MIT** de la collection source (Matt Pocock, `skills-main` 1.2.3) et une note de provenance ; l'obligation de licence suit les fichiers chez les participants.

**4.** La portée personnelle Claude (`C:\Users\<utilisateur>\.claude\skills\<nom>`) cesse d'être une copie : chaque dossier des 28 devient une **jonction** vers `vault/skills/external/<nom>/`. Une seule source ; Claude y accède par sa porte, tout autre agent par le chemin du Vault. Aucun contenu n'est perdu : le remplacement est copie-puis-jonction, pas suppression sèche.

**5.** Le **manifeste de distribution** du Vault classe les fichiers de `skills/external/` ; si son schéma actuel n'a pas de catégorie adaptée, la classification est remontée à l'Owner, jamais inventée.

**6.** Les hooks du Vault s'appliquent à ce contenu comme au reste. Un refus de hook sur ce matériel externe vaut **arrêt et rapport**, jamais contournement ; l'éventuel besoin d'exclure `skills/external/` du périmètre d'un gardien est un arbitrage d'Owner séparé.

## Raison

Arbitrage Owner du 2026-08-28 : « on garde les skills centralisés dans le vault dans leur bibliothèque c'est plus simple comme ça », rendu après présentation des trois options (bibliothèque hors dépôts ; tout au Vault ; bibliothèque plus sélection durcie) et de leurs coûts — y compris la distribution aux participants de cinq skills bêta et de `wizard` non durci, la licence à honorer, et la maintenance de matériel tiers dans le produit. La simplicité d'une source unique dans le dépôt versionné l'emporte, en connaissance de cause. L'exigence du même jour — skills à portée de n'importe quel agent, pas seulement Claude — est satisfaite : le Vault est un chemin de disque lisible par tout agent, la portée Claude n'est plus qu'un adaptateur.

## Impact

- `DECISION-151235` reçoit le lien réciproque `amended by` dans le même commit.
- Le périmètre d'audit et de packaging du Vault s'élargit de 94 fichiers externes ; le durcissement recommandé par le second audit reste non exécuté et documenté au catalogue.
- Le catalogue (`knowledge-notes`) est mis à jour : chemins canoniques `vault/skills/external/`.
- La distribution du produit inclut désormais ce matériel ; toute mise à jour amont (dépôt GitHub de l'auteur) est une opération de maintenance du produit, à la main de l'Owner.

## Alternatives importantes

- Bibliothèque à la racine du workspace + adaptateurs (proposition B) : rejetée par l'Owner — simplicité d'une source dans le Vault préférée.
- Sélection durcie seule dans le Vault (B+S) : rejetée par l'Owner après explication détaillée.
- Copies par agent sans source canonique : rejetées — divergence garantie, contraire à `DECISION-214607`.

## Human gate

- Validation : accordée
- Référence : arbitrage en séance, Owner, 2026-08-28, après trois tours d'options et l'explication demandée de B+S.

## Artefacts liés

- Décision amendée : DECISION-2026-08-28-151235-external-skills-adoption-score-threshold (historique de l'atelier, non distribué).
- Doctrine source unique / adaptateurs : `../../../vault/decisions/DECISION-2026-08-24-214607-transverse-mechanism-distribution.md`.
- Mission d'exécution : `../missions/MISSION-2026-08-28-160311-082-skills-library-into-vault.md` (déposée dans le même tour).

## Liens

- `amends` — Décision — Adoption des skills externes au seuil de score (historique de l'atelier, non distribué)
- `see also` — [Décision — Distribution des mécanismes transverses](../../../vault/decisions/DECISION-2026-08-24-214607-transverse-mechanism-distribution.md) (hors Vault)
- `amended by` — [Décision — Adoption par réécriture d'enveloppe V1](./DECISION-2026-08-28-171209-skills-adoption-by-v1-envelope-rewrite.md)
