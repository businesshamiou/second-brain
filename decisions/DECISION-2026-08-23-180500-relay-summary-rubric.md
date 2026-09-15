---
type: decision
title: "Rubrique « Résumé » dans le bloc RELAY du sens retour"
created_at: "2026-08-23T18:05:00-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
amends: "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
---

# DÉCISION — Rubrique « Résumé » dans le bloc RELAY du sens retour

## Date

2026-08-23

## Statut

`ARBITRATED`

Arbitrage formalisé par la Mission 036 (historique de l'atelier, non distribué).

## Décision

Le bloc RELAY du sens retour de la [règle du relais entre rôles](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md) compte désormais **six rubriques** au lieu de cinq. La nouvelle, **Résumé**, s'insère **avant** « À trancher » (rang 5 sur 6, entre « Commits » et « À trancher ») :

> **Résumé** : trois à cinq lignes. Les chiffres qui changent une conclusion, tout écart au protocole ou à la Mission, et ce qui a surpris l'Executor.

Trois contraintes s'y attachent :

1. **Des faits, pas des appréciations.** « Q5 en hausse » ne vaut rien ; « Q5 : 12 décisions trouvées contre 7 » vaut la rubrique entière. Un chiffre, une comparaison, un écart nommé.
2. **Plafond de cinq lignes, strict.** Au-delà, la rubrique redevient un second rapport et le coût qu'elle économise est repayé.
3. **Tout écart au protocole ou à la Mission y figure**, même mineur, même sans conséquence apparente — c'est le seul endroit où le Pilot peut le voir sans ouvrir le rapport.

Le sens aller (les cinq rubriques du mini-prompt, livré en snippet) n'est pas touché.

**Principe qui motive la rubrique** : le Pilot ne lit un rapport complet que sur décision explicite ; le résumé du bloc RELAY est le mode de lecture par défaut.

## Raison

Mesure du défaut, faite le 2026-08-23 sur la Mission 033 : le RELAY annonçait « Q5 en hausse ». Le résumé de fin de fenêtre, transmis séparément par l'Owner, disait que la condition C3 avait trouvé douze décisions contre sept — le seul écart concret de toute la mesure, invisible dans le RELAY à cinq rubriques. Deux autres faits décisifs manquaient également : le coût et la durée divisés par deux, et une possible entorse au protocole (« fenêtre persistante ») que le RELAY ne signalait pas.

Conséquence du défaut : le Pilot devait soit ouvrir le rapport complet — coûteux, plusieurs milliers de mots qui restent dans sa fenêtre — soit raisonner sur une information incomplète. Ni l'un ni l'autre n'est un mode par défaut acceptable. Le rapport reste déposé sur disque et lisible ; ce qui manquait était un résumé assez riche pour que la lecture du rapport devienne l'exception, décidée au cas par cas plutôt que subie.

## Impact

- `vault/rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md` porte désormais six rubriques dans le bloc RELAY du sens retour, la nouvelle avant « À trancher », avec ses trois contraintes.
- `vault/templates/report-template.md` porte la même rubrique au même rang, avec sa consigne d'une ligne et son plafond, dans le bloc RELAY du gabarit de rapport.
- Toute Mission future dont le rapport se termine par un bloc RELAY porte la rubrique Résumé, faits et chiffres seulement, cinq lignes au plus.
- La Mission 036, qui grave cette Decision, applique elle-même la rubrique dans son propre bloc RELAY (voir son rapport).

## Alternatives importantes

- Laisser le bloc RELAY à cinq rubriques et compter sur le Pilot pour ouvrir le rapport complet à chaque écart potentiel : rejeté, c'est précisément le mode par défaut coûteux que le défaut constaté sur la Mission 033 a révélé comme insuffisant.
- Rubrique Résumé sans plafond de lignes : rejeté, une rubrique libre en longueur redevient un second rapport et annule le gain de coût qu'elle est censée apporter (§2 de la Mission).
- Rubrique Résumé fondée sur des appréciations qualitatives (« Q5 en hausse ») plutôt que sur des faits chiffrés : rejeté, c'est exactement le défaut mesuré — une appréciation ne permet pas au Pilot de distinguer un écart mineur d'un écart décisif sans ouvrir le rapport.

## Human gate

- Validation : accordée
- Référence : Mission `036`, `AUTHORIZED` par l'Owner (MISSION-2026-08-23-174203-036-relay-summary-rubric.md).

## Artefacts liés

- Mission d'exécution : (historique de l'atelier, non distribué)
- Règle amendée : `../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md`
- Gabarit amendé : `../templates/report-template.md`
- Mesure source du défaut : (historique de l'atelier, non distribué)

## Liens

- `amends` — [Relais entre rôles par mini-prompts à rubriques fixes](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Sens aller du relais en snippet, et liste des remplacés hors graphe mais versionnée](./DECISION-2026-08-23-155831-relay-forward-snippet-and-superseded-list-graph-exclusion.md)
- `see also` — Mission 036 — Rubrique « Résumé » imposée au bloc RELAY (historique de l'atelier, non distribué) (hors Vault)
