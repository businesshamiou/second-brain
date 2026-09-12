---
type: decision
title: "Amendement — l'exception de push délégué couvre le commit de sa propre ligne de journal"
description: "Amende DECISION-154553 : l'exception de push délégué autorise désormais l'écriture ET le commit de sa ligne de journal, rien d'autre ; le périmètre des gestes reste inchangé pour tout le reste."
created_at: "2026-08-27T11:25:28-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md"
---

# DÉCISION — L'EXCEPTION DE PUSH DÉLÉGUÉ COUVRE LE COMMIT DE SA LIGNE DE JOURNAL

## Date

2026-08-27

## Statut

`ARBITRATED`

## Décision

L'exception de push délégué (`DECISION-2026-08-26-154553`) couvre désormais, en plus de l'écriture de la ligne de journal de clôture, **le commit de cette seule ligne**. Le geste ajouté est strictement borné : un `git add` portant uniquement `<projet>/state/journal.md`, puis un commit portant uniquement ce fichier. Rien d'autre n'est ajouté au périmètre : `git status -sb` (avant/après), `git push` sur `main` uniquement, aucun `add` d'un autre fichier, aucune suppression, aucun `--force` restent, comme avant, les seuls autres gestes couverts. Le gabarit d'autorisation verbatim et sa portée à un seul geste (`DECISION-2026-08-26-231617`) restent inchangés.

## Raison

Trois occurrences datées du 2026-08-27 (sixième, septième et huitième push délégués du journal, mesurées à l'ouverture de la Mission 072) ont montré le même défaut de conception : l'exception autorisait l'écriture de la ligne mais pas son commit, laissant systématiquement state/journal.md modifié et non commité après chaque push délégué — chacune signalée par l'Executor en rubrique « À trancher » de son bloc RELAY sans qu'aucune règle n'y remédie. Une quatrième occurrence (neuvième push délégué, `2026-08-27T11:18:19-04:00`) est survenue une minute après la rédaction de la Mission 072, pendant l'instruction de push qui a précédé cette fenêtre — elle n'était pas mesurable à l'écriture de la Mission, mais confirme le même patron une fois de plus. Une exception répétée sans être nommée dérive — motif propre de `DECISION-154553`, ici appliqué à son propre défaut de conception plutôt qu'à un patron externe.

## Impact

- `DECISION-154553` reçoit un amendement, dans le même dépôt : son gabarit verbatim et son périmètre de gestes restent inchangés dans leur forme ; l'exception couvre désormais un geste de plus, borné à un seul fichier (`<projet>/state/journal.md`) et un seul commit.
- Lien réciproque `amended by` posé sur `DECISION-154553` dans ce même commit.
- Aucun changement à `DECISION-2026-08-26-231617` (une ligne = un geste) : cette Décision ajoute un geste couvert par le même gabarit d'autorisation, elle ne change pas la règle de non-fusion.
- `open-delegated-push-journal-commit` se ferme par ce lot (Mission 072, étape 6) : les trois (puis quatre) occurrences mesurées cessent de se reproduire pour tout push délégué futur.

## Alternatives importantes

- Étendre l'exception à un commit couvrant `<projet>/state/journal.md` **et** tout autre fichier modifié en même temps : rejeté — élargirait le périmètre bien au-delà du défaut mesuré (une seule ligne de journal orpheline), contredit la doctrine « une ligne d'autorisation, un geste borné » de `DECISION-231617`.
- Laisser une Mission ultérieure absorber la ligne orpheline à chaque fois, sans amender l'exception : rejeté — c'est exactement le patron répété quatre fois qui motive cette gravure ; laisser filer une cinquième occurrence n'apporte rien de plus qu'un cinquième signalement.

## Human gate

- Validation : accordée
- Référence : Mission `072` (mot exact « Rédige la Mission 072 : les deux R1, l'amendement de 154553, la ligne de journal de la porte fantôme », 2026-08-27), qui prescrit cette gravure.

## Artefacts liés

- Décision amendée : `DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md`.
- Occurrences sources : journal (historique de l'atelier, non distribué), lignes du 2026-08-27 (sixième, septième, huitième et neuvième push délégués). (hors Vault)
- Mission source : (historique de l'atelier, non distribué) (hors Vault).

## Liens

- `amends` — [Décision — Le push délégué devient une règle](./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)
- `see also` — [Décision — Une ligne d'autorisation Owner couvre un seul geste](./DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md)
- `see also` — Mission 072 — Lot d'apurement (historique de l'atelier, non distribué) (hors Vault)
