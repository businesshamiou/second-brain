---
type: decision
title: "Protocole de copie — sens retour en snippet, mots exacts groupés et adressés, ligne d'identité étendue aux instructions ponctuelles"
description: "Grave quatre correctifs du protocole de copie Owner/Pilot/Executor : le bloc RELAY du sens retour livré en snippet copiable d'un seul geste, les mots exacts du Pilot livrés en snippets groupés en fin de tour, chaque snippet destiné à l'Owner nommant sa fenêtre de destination, et la ligne d'identité 'Tu es l'Executor — Mission <NNN>' étendue aux instructions ponctuelles sous la forme 'Tu es l'Executor — instruction ponctuelle (<description courte>)'."
created_at: "2026-08-27T10:00:16-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
---

# DÉCISION — PROTOCOLE DE COPIE : SNIPPETS ET DESTINATIONS

## Date

2026-08-27

## Statut

`ARBITRATED`

## Décision

Le canal de copie entre l'Owner, le Pilot et l'Executor reçoit quatre correctifs, gravés ensemble :

1. **Sens retour en snippet.** Le bloc `RELAY` à six rubriques (`RULES-2026-08-23-124937`) est livré par l'Executor **en snippet copiable d'un seul geste** (bloc de code en fin de fenêtre), jamais en prose à recomposer. Symétrie avec le sens aller, déjà gravé sous cette forme par `DECISION-2026-08-23-155831`.
2. **Mots exacts groupés.** Les mots exacts que le Pilot propose à l'Owner (arbitrage, autorisation, formule à coller) sont livrés **en snippets**, un snippet par arbitrage, et **groupés en fin de tour**, jamais dispersés dans la prose qui les justifie.
3. **Destination nommée.** Chaque snippet destiné à l'Owner porte, immédiatement avant lui, une ligne nommant sa fenêtre de destination — pour le Pilot dans la fenêtre de chat, ou pour l'Executor dans une fenêtre Claude Code.
4. **Ligne d'identité étendue.** La ligne d'identité d'une fenêtre Executor, `Tu es l'Executor — Mission <NNN> (<description courte>)`, s'applique **à toute instruction déléguée à l'Executor**, Mission ou instruction ponctuelle. Pour une instruction ponctuelle sans numéro de Mission, la forme est `Tu es l'Executor — instruction ponctuelle (<description courte>)`. Cette ligne reste une confirmation (barreau 3) et ne prouve jamais le rôle à elle seule — le barreau 2 (sonde de capacité) garde la primauté.

## Raison

Défauts mesurés en session du 2026-08-27 : un bloc RELAY rendu en prose libre sans aucune des six rubriques (ni verdict, ni compte de critères, ni rubrique « À trancher »), obligeant le Pilot à reconstruire le verdict lui-même ; des mots exacts dispersés dans la prose du Pilot au fil de plusieurs tours ; un snippet d'autorisation de push livré sans nommer sa fenêtre de destination, l'Owner ayant dû demander explicitement où le porter. Le sens aller du relais est prescrit en snippet copiable depuis `DECISION-2026-08-23-155831` ; rien n'imposait la même forme au sens retour, ni n'encadrait la livraison des mots exacts du Pilot, ni ne nommait la destination d'un snippet, ni n'étendait la ligne d'identité aux instructions ponctuelles.

## Impact

- `RULES-2026-08-23-124937` (relais entre rôles par mini-prompts) reçoit deux ajouts de corps : la rubrique **Retour** prescrit désormais la livraison en snippet copiable du bloc RELAY ; la rubrique **Aller**, rubrique 1 (ligne de titre), étend la forme à `Tu es l'Executor — Mission <NNN>` et mentionne la variante « instruction ponctuelle ». Lien `amended by` réciproque posé dans le même commit.
- `RULES-2026-08-23-224706` (charte des rôles), §2 rôle `pilot`, rubrique **Sortie**, reçoit deux ajouts de corps : snippets groupés en fin de tour, destination nommée avant chaque snippet. Lien `amended by` réciproque posé dans le même commit.
- Aucune ouverture nouvelle de périmètre : ces quatre volets encadrent la forme de livraison d'artefacts déjà prescrits (mini-prompt, bloc RELAY, mots exacts d'autorisation), ils ne créent aucune nouvelle catégorie d'artefact.
- Aucune porte ouverte ni fermée par cette Decision (arbitrage Owner du 2026-08-27 : aucune porte n'est ouverte rétroactivement pour être fermée dans le même lot).

## Alternatives importantes

- Laisser le sens retour en prose libre et compter sur la rubrique Résumé (`DECISION-2026-08-23-180500`) pour porter l'essentiel : rejeté — la mesure du 2026-08-27 montre qu'une prose libre omet verdict et critères, pas seulement le résumé ; seule la forme à rubriques fixes en snippet élimine ce risque, comme elle l'a déjà fait pour le sens aller.
- Laisser les mots exacts dispersés dans le raisonnement du Pilot, au motif que le contexte les justifie mieux ainsi : rejeté — dispersés, ils obligent l'Owner à relire tout le tour pour les retrouver ; le motif qui a fait grader le sens aller en snippet (risque de dérive à la recomposition) s'applique à l'identique ici.
- Ne pas nommer la destination, au motif qu'elle se déduit du contenu du snippet : rejeté — l'incident du 2026-08-27 (push délivré sans destination) montre que la déduction échoue en pratique et coûte un aller-retour à l'Owner.
- Restreindre la ligne d'identité étendue aux seules Missions numérotées, au motif qu'une instruction ponctuelle est par nature plus légère : rejeté — c'est précisément l'absence de ligne d'identité sur une instruction ponctuelle qui prive le barreau 3 de la charte de son objet pour ce cas.

## Human gate

- Validation : accordée
- Référence : arbitrages Owner en chat du 2026-08-27 (« Je valide la gravure : une Decision au vault, amendant RULES-124937 (sens retour en snippet) et RULES-224706 §2 (mots exacts en snippets groupés en fin de tour) », puis « Ajoute le troisième volet : chaque snippet nomme sa destination », puis l'ajout du volet 4 sur la ligne d'identité des mini-prompts) ; Mission `070`.

## Artefacts liés

- Mission source : (historique de l'atelier, non distribué) (hors Vault).
- Précédent direct (sens aller en snippet) : `./DECISION-2026-08-23-155831-relay-forward-snippet-and-superseded-list-graph-exclusion.md`.
- Précédent d'amendement du sens retour (rubrique Résumé) : `./DECISION-2026-08-23-180500-relay-summary-rubric.md`.

## Liens

- `amends` — [Relais entre rôles par mini-prompts à rubriques fixes](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amends` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Sens aller du relais en snippet, et liste des remplacés hors graphe mais versionnée](./DECISION-2026-08-23-155831-relay-forward-snippet-and-superseded-list-graph-exclusion.md)
- `see also` — [Rubrique « Résumé » dans le bloc RELAY du sens retour](./DECISION-2026-08-23-180500-relay-summary-rubric.md)
- `see also` — Mission 070 — Gravure du protocole de copie (historique de l'atelier, non distribué) (hors Vault)
