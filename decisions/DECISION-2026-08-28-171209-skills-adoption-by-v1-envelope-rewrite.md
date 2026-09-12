---
type: decision
title: "Doctrine d'adoption des skills externes — adoption par réécriture d'enveloppe V1, cycle update-ou-rejet, fin du statut intouchable"
description: "Grave la doctrine arbitrée par l'Owner : un skill externe s'adopte en étant réécrit en version V1 à nous — enveloppe au format du Vault immédiatement, corps conservé verbatim avec empreinte, puis cycle de vie update ou rejet-et-suppression. Amende DECISION-160213 et lève l'interdit de modification de la Mission 082 pour les enveloppes. L'arbitrage E/P sur le gardien devient sans objet."
created_at: "2026-08-28T17:12:09-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-28-171209-skills-adoption-by-v1-envelope-rewrite.md"
---

# DÉCISION — ADOPTION PAR RÉÉCRITURE D'ENVELOPPE V1

## Date

2026-08-28

## Statut

`ARBITRATED`

## Décision

**1. Adoption = réécriture.** Un skill externe n'entre pas dans le Vault comme matériel intouchable : il s'adopte en devenant une **version V1 à nous**. Le statut « externe, jamais modifié » gravé par les Décisions 151235/160213 et la Mission 082 est levé pour le contenu de `vault/skills/external/`.

**2. La V1 se fait en deux temps, et seul le premier est immédiat.**
- **Enveloppe, maintenant, pour les 28** : le front-matter de chaque `SKILL.md` est réécrit au format du Vault — `type: skill`, `title`, `description` (une ligne), `created_at` réel, `timezone`, `status: ADOPTED-V1` (valeur provisoire, sous réserve de l'arbitrage `open-vocabularies`) — en **conservant les champs fonctionnels** du format Agent Skills sans lesquels le skill cesse d'être découvert et chargé : `name`, la `description` fonctionnelle (fusionnée avec la nôtre : une seule ligne servant les deux lectures), `disable-model-invocation` et `argument-hint` là où ils existent. La provenance vit dans des clés plates `metadata-*` (dépôt amont, version amont, licence, **empreinte SHA-256 du corps d'origine**) — forme plate arbitrée le 2026-08-28 après mesure : le bloc `metadata:` imbriqué, point d'extension conforme du format amont, est illisible pour le parseur restreint du gardien de réciprocité (diagnostic au rapport de la Mission 083, premier lancement).
- **Corps, au fur et à mesure** : le corps reste verbatim à l'entrée, prouvé par l'empreinte. Sa réécriture se fait skill par skill, quand l'usage le justifie, en priorité ceux que les audits demandent de durcir (`wizard`, `scroll-film-studio`). Aucune réécriture de corps en bloc.

**3. Cycle de vie.** Chaque skill adopté vit ensuite : **update** — notre version évolue, l'écart avec l'amont est assumé et la maintenance nous revient ; ou **rejet** — le skill est supprimé du Vault, la suppression restant un human gate de l'Owner, jamais un geste d'Executor seul.

**4. Conséquence sur les gardiens.** Les enveloppes étant au format du Vault, le gardien de réciprocité lit les 28 fichiers sans exemption ni assouplissement : l'arbitrage E/P soulevé par le PARTIEL de la Mission 082 est **sans objet**. Les gardiens gardent pleins pouvoirs sur `skills/external/`, comme partout.

**5. `skills/external/` change de sens** : ce n'est plus une frontière de gouvernance (« matériel qu'on ne touche pas ») mais une frontière de **provenance** (« matériel né ailleurs, adopté chez nous »). Les six skills V1 natifs de `DECISION-232341` §5.1 restent hors de ce dossier.

## Raison

Arbitrage Owner du 2026-08-28 : « il faut à mon avis les adopter en les réécrivant pour être une version V1 et par la suite soit on update soit on rejette et on supprime », rendu après trois tours — définition interne/externe posée, coût du fork exposé, distinction enveloppe/corps proposée par le Pilot et intégrée. La doctrine résout aussi le blocage mesuré de la 082 : 18/28 en-têtes illisibles par le gardien cessent de l'être une fois au format du Vault, sans toucher au gardien lui-même.

## Impact

- `DECISION-160213` reçoit `amended by` (même commit). Le §6 de 160213 (arbitrage de périmètre des hooks) est résolu sans exemption.
- La contrainte « tout durcissement ou modification du contenu des skills » de la Mission 082 est levée **pour les enveloppes seulement** dans la Mission 083 ; les corps restent verbatim jusqu'à leur réécriture individuelle.
- Le catalogue documente par skill : statut ADOPTED-V1, empreinte du corps, écart amont (aucun à l'entrée).
- Les recommandations de durcissement des audits deviennent la file de réécriture des corps.

## Alternatives importantes

- Exemption du gardien sur `external/` (option E) : rendue sans objet — elle traitait le symptôme (en-têtes illisibles) en laissant le matériel intouchable, ce que l'Owner ne veut pas.
- Assouplir le parseur du gardien (option P) : rejetée — toucher un mécanisme prouvé pour tolérer un format qu'on a décidé de faire disparaître.
- Réécrire les 28 corps immédiatement : rejeté — des jours de travail sur du matériel pas encore servi, contraire au « au fur et à mesure » de l'Owner.

## Human gate

- Validation : accordée
- Référence : mots exacts de l'Owner en séance du 2026-08-28 (doctrine), puis « je valide le dépôt de la Décision d'adoption et de la Mission 083 ».

## Artefacts liés

- Décision amendée : `./DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md`.
- Blocage source : `../reports/REPORT-2026-08-28-162300-082-skills-library-into-vault.md` §7 (verbatim du refus du gardien).
- Recherche `metadata` comme point d'extension : knowledge-notes du 2026-08-27.
- Mission d'exécution : `../missions/MISSION-2026-08-28-171305-083-skills-v1-envelope-adoption.md` (déposée dans le même tour).

## Liens

- `amends` — [Décision — La bibliothèque de skills externes entre dans le Vault](./DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md)
- `see also` — Décision — Adoption des skills externes au seuil de score (historique de l'atelier, non distribué)
- `see also` — Rapport d'exécution — Mission 082 (historique de l'atelier, non distribué)
- `amended by` — [Décision — Forme standard de la bibliothèque de skills et remplacement par le paquet du warehouse](./DECISION-2026-08-31-231841-skills-library-standard-form-warehouse.md)
