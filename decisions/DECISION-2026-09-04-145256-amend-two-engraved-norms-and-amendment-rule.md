---
type: decision
title: "Amendement de deux normes gravées sur mesure : recherche d'outils par description, motif de nommage des rapports aligné sur l'usage ; et la règle générale — une Décision gravée n'est jamais réécrite, elle est amendée par une Décision"
description: "Décision arbitrée le 2026-09-04 après le rapport 132 : amende la règle de recherche d'outils de la Décision 140714 (recherche formulée sur la description, seconde recherche permise et comptée) et le motif de nommage des rapports de la Décision 000236 (forme alignée sur l'usage mesuré) ; et grave la règle générale qui manquait — le corps d'une Décision arbitrée ne se réécrit pas, il reçoit une annotation datée pointant vers la Décision qui l'amende, avec réciprocité de liens."
created_at: "2026-09-04T14:52:56-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md"
  - "./DECISION-2026-08-21-000236-execution-report-channel.md"
scope: tool-search-rule, report-naming, decision-amendment-doctrine
---

# DÉCISION — AMENDEMENT DE DEUX NORMES GRAVÉES, ET LA RÈGLE D'AMENDEMENT

## Date

2026-09-04

## Statut

`ARBITRATED`

Arbitrage Owner en clair, session Pilot du 2026-09-04, gate « annote va graver aussi la décision ».

## Fait déclencheur

Le rapport 132 a mesuré deux normes gravées en désaccord avec la pratique. La règle de recherche d'outils de la Décision 140714 (« par le nom exact de l'outil ») avait déjà été remplacée dans `../skills/session-start/reading-list.md` par le texte T7 de la Mission 132-B, sous un gate Owner — **un amendement vivant dans une Mission et absent du corpus des Décisions**. Le motif de nommage des rapports de la Décision 000236 comporte un segment que l'usage n'a jamais respecté, ce qui a produit un rapport hors motif à la Mission 133 sans qu'aucun gardien ne le voie.

Ces deux cas ont la même forme : une norme gravée qu'on n'ose pas réécrire, un usage qui diverge, et rien qui relie les deux.

## Décision

1. **Recherche d'outils.** La règle de la Décision 140714 selon laquelle une recherche d'outils se formule « par le nom exact de l'outil » est amendée. La recherche se formule **sur la description de l'outil** — verbe et objet — parce que l'index de recherche porte les descriptions et non les noms (mesures des Missions 132-A et 132-B). Une seconde recherche est permise, et comptée au budget d'ouverture, si la première ne remonte pas l'outil visé. Le texte appliqué vit dans `../skills/session-start/reading-list.md`.

2. **Nommage des rapports.** Le motif de nommage des rapports d'exécution de la Décision 000236 est aligné sur l'usage mesuré : `REPORT-<AAAA-MM-JJ>-<HHMMSS>-<mission_id>-<slug>.md`. Le segment jamais respecté est retiré de la norme plutôt que d'être imposé rétroactivement à des dizaines de fichiers existants. Faire respecter le motif retenu par un gardien reste ouvert et n'est pas décidé ici.

3. **Règle générale d'amendement.** Le corps d'une Décision au statut `arbitrated` n'est jamais réécrit. Il reçoit, à l'endroit exact de la règle dépassée, une **annotation datée** qui nomme la Décision amendante et l'endroit où vit le texte appliqué. La Décision amendante porte `amends`, la Décision amendée reçoit `amended by` : la réciprocité rend la divergence visible aux gardiens de liens. Un amendement obtenu par gate de Mission, sans Décision, est un état transitoire à régulariser — jamais un état final.

## Raison

- Une norme qui contredit sa propre pratique est pire qu'une norme absente : elle est lue, citée en Mission, et propage l'erreur. Trois textes ont produit des fautes réelles cette semaine par ce seul mécanisme.
- Réécrire le corps d'une Décision effacerait la trace de ce qui a été arbitré et quand. L'annotation conserve l'histoire et signale la dérive au même endroit.
- Le point 3 est le remède structurel : sans lui, le prochain gate de Mission créera un nouvel amendement orphelin.

## Impact

- Les Décisions 140714 et 000236 reçoivent chacune une annotation datée et un lien `amended by` vers celle-ci — geste de la Mission 134-A.
- Le gabarit de Décision et la règle de liens ne changent pas : `amends` et `amended by` existent déjà, ils étaient simplement inemployés dans ce cas.
- Aucun fichier existant n'est renommé. Aucun gardien n'est créé ni modifié.
- Le budget d'ouverture du Pilot compte désormais explicitement une éventuelle seconde recherche d'outils.

## Alternatives importantes

- Réécrire directement le corps des deux Décisions : rejeté, perte de la trace d'arbitrage.
- Laisser l'amendement vivre dans `../skills/session-start/reading-list.md` seul : rejeté, c'est l'état de départ, et il est invisible pour quiconque lit la Décision.
- Imposer le motif de nommage d'origine par un gardien et renommer l'existant : rejeté, coût sans bénéfice, et l'usage mesuré est le meilleur candidat.

## Human gate

- Validation : accordée
- Référence : ordre Owner en clair, session Pilot du 2026-09-04, gate « annote va graver aussi la décision »

## Artefacts liés

- Proposal source : aucune
- Mesure source : (historique de l'atelier, non distribué) (hors Vault)
- Application : Mission 134-A, (historique de l'atelier, non distribué) (hors Vault)

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amends` — [Décision — Budget de contexte du Pilot](./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md)
- `amends` — [Décision — Canal de rapport d'exécution](./DECISION-2026-08-21-000236-execution-report-channel.md)
- `see also` — [Décision — Balayage d'existence, mémoire et hypothèses](./DECISION-2026-09-04-121443-existence-sweep-memory-hypothesis-measured-existing.md)
- `see also` — [Liste de lecture d'ouverture de session, par rôle](../skills/session-start/reading-list.md)
- `see also` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
