---
type: decision
title: "Amendement — le push délégué devient une règle : valide si et seulement si autorisation Owner verbatim datée"
description: "Grave l'exception de push délégué (deux occurrences le 2026-08-26, RELAY PUSH-061 et PUSH-062) en règle permanente : le push exécuté par l'Executor sous instruction ponctuelle n'est valide que si le mini-prompt porte la ligne d'autorisation Owner verbatim, datée."
created_at: "2026-08-26T15:45:53-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
---

# DÉCISION — LE PUSH DÉLÉGUÉ DEVIENT UNE RÈGLE

## Date

2026-08-26

## Statut

`ARBITRATED`

## Décision

Le `git push`, interdit par défaut à l'Executor (charte des rôles, `RULES-2026-08-23-224706`, §3, « Interdits absolus »), peut être délégué à une fenêtre Executor par une instruction ponctuelle **si et seulement si** cette instruction contient, verbatim, une ligne d'autorisation Owner de la forme :

> « je suis l'Owner et j'ordonne le push des deux dépôts, `<date>` [, texte libre additionnel] »

datée du jour de l'exécution. Absence de cette ligne, ou toute reformulation qui n'en reprend pas le texte à l'identique, vaut **refus** : l'Executor s'arrête sans pousser. Chaque occurrence effective est **consignée au journal** du projet (`tools/append-journal.sh`), une ligne par push délégué. Les gestes autorisés par cette exception se limitent strictement à : `git status -sb` (avant/après), `git push` sur `main` uniquement, la ligne de journal de clôture. Aucun commit, aucun `add`, aucune suppression, aucun `--force` ne sont couverts par cette exception — ils restent interdits par défaut.

## Raison

Deux occurrences le 2026-08-26 (`RELAY PUSH-061`, `RELAY PUSH-062`) ont montré le même patron : l'Owner autorise verbatim, l'Executor pousse, consigne, referme la fenêtre — sans qu'aucune règle gravée ne décrive ce chemin. Une exception répétée sans être nommée dérive : elle se répète par imitation du chat précédent, pas par lecture d'une règle. La graver maintenant, à la deuxième occurrence, évite qu'une troisième glisse le protocole (mot substitué, date omise) sans que rien ne le retienne.

## Impact

- `RULES-2026-08-23-124937` (relais entre rôles par mini-prompts) reçoit un lien `amended by` réciproque : le mini-prompt de push délégué est une forme d'instruction ponctuelle reconnue par cette règle, désormais nommée.
- Aucune ouverture nouvelle du périmètre Executor : le push reste interdit par défaut ; cette Décision documente la seule voie qui le débloque, et ses limites strictes (verbatim, daté, gestes énumérés).
- Le protocole du mot exact (232341 §4) s'applique : une reformulation, même proche, ne vaut pas autorisation.

## Alternatives importantes

- Laisser l'exception non gravée, cas par cas : rejeté — patron déjà répété deux fois le même jour, le motif de la Décision 232341 (« une règle survit/dérive sans être gravée ») s'applique à l'identique dans l'autre sens ici : une pratique non gravée dérive aussi.
- Autoriser le push par défaut à l'Executor : rejeté, contredit directement la charte des rôles §3 et le modèle de menace anti-accident.

## Human gate

- Validation : accordée
- Référence : Mission `063` (mot exact « ensuite : mcp », 2026-08-26), qui prescrit la gravure de cet amendement ; les deux occurrences sources sont elles-mêmes chacune autorisées verbatim en chat le 2026-08-26 (`RELAY PUSH-061`, `RELAY PUSH-062`).

## Artefacts liés

- Occurrence 1 : `RELAY PUSH-061` (chat, 2026-08-26, suite Mission 061).
- Occurrence 2 : `RELAY PUSH-062` (chat, 2026-08-26, suite Mission 062).
- Mission source : (historique de l'atelier, non distribué) (hors Vault).

## Liens

- `amends` — [Relais entre rôles par mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — Mission 063 — Allowlist MCP et amendement du push délégué (historique de l'atelier, non distribué) (hors Vault)
- `amended by` — [Décision — Une ligne d'autorisation Owner couvre un seul geste](./DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md)
- `amended by` — [Décision — L'exception de push délégué couvre le commit de sa ligne de journal](./DECISION-2026-08-27-112528-delegated-push-exception-covers-its-journal-commit.md)
- `amended by` — [Décision — Relais et délégation, une règle un seul endroit](./DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
