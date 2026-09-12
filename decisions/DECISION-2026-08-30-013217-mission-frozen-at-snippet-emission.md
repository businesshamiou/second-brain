---
type: decision
title: "Amendement — un fichier de Mission est gelé dès l'émission de son snippet"
description: "Une Mission ne se retouche plus en place à partir du moment où son mini-prompt est remis à l'Owner : le Pilot ne peut pas observer quand une fenêtre Executor s'ouvre, donc l'émission du snippet est le seul instant de gel observable ; toute évolution passe par une correction Cxx et un nouveau snippet."
created_at: "2026-08-30T01:32:17-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: mission-lifecycle, pilot-conduct
amends: "../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md"
---

# DÉCISION — GEL D'UNE MISSION À L'ÉMISSION DE SON SNIPPET

## Date

2026-08-30

## Statut

`ARBITRATED`

## Décision

1. **Point de gel.** Un fichier de Mission est gelé à l'instant où son mini-prompt de consommation est remis à l'Owner. À partir de cet instant, son texte ne se retouche plus en place, quelle que soit la nature de la modification et même si elle ne change ni l'objectif, ni le périmètre, ni les critères.
2. **Voie d'évolution unique.** Toute évolution d'une Mission gelée passe par une correction `Cxx`, avec son propre horodatage, son `supersedes`, sa réciproque `superseded by`, et **un nouveau snippet**. Une Mission dont le texte a changé sans nouveau snippet n'a pas été communiquée.
3. **Retouche déjà commise.** Si une retouche en place a déjà eu lieu, elle ne s'annule pas par réflexe. On mesure d'abord quelle version la fenêtre a lue — le rapport d'exécution le dit — puis on consigne l'écart. Annuler le texte pendant qu'une fenêtre l'utilise désynchronise dans l'autre sens.
4. **Fichier non consommé.** Un fichier de Mission déposé mais dont le snippet n'a pas encore été émis reste librement modifiable : il n'est pas gelé, personne ne l'a lu.

## Raison

Le point de gel évident serait le commit, ou le début d'exécution. Aucun des deux n'est observable par le Pilot : il ne commite pas, et il ne voit pas l'Owner ouvrir une fenêtre. Le seul instant qu'il maîtrise est l'émission du snippet. Un gel doit se poser là où celui qui doit le respecter peut le constater.

Deux occurrences le 2026-08-30 l'ont montré. Le fichier de la Mission 096 a été modifié alors que son exécution avait déjà commencé — le rapport porte 01:16:44, la retouche a suivi. Le fichier de la Mission 097 a été modifié pendant que sa fenêtre était ouverte. Dans les deux cas la modification était mineure et sans effet sur le livrable ; dans les deux cas le dossier aurait montré une Mission dont le texte diffère de celui qui a été exécuté, sans qu'aucune trace n'explique la différence.

C'est le même patron que les autres défauts d'écriture de cette nuit : une contrainte que le Pilot croyait tenir par prudence, et qu'aucun instant nommé ne retenait.

## Impact

- `RULES-2026-08-17-211522` reçoit un lien `amended by` réciproque : sa section sur les corrections gagne un instant de bascule nommé.
- Une correction `Cxx` cesse d'être réservée aux changements de fond : elle devient la seule voie pour toute modification postérieure à l'émission du snippet.
- Le coût est assumé : une coquille dans une Mission émise produira désormais une correction `Cxx` complète plutôt qu'une retouche silencieuse.
- La porte `open-mission-internal-coherence` reste ouverte et distincte : elle porte les contrôles de cohérence interne d'une Mission avant émission, là où la présente Décision porte son immuabilité après.

## Alternatives importantes

- Geler au commit : rejeté, la fenêtre Executor lit le fichier sur le disque, pas le commit ; un fichier non suivi est déjà consommable.
- Geler au début d'exécution : rejeté, cet instant n'est observable ni par le Pilot ni par personne d'autre que l'Owner, qui n'a pas à le signaler.
- Autoriser la retouche des seules coquilles : rejeté, la frontière entre coquille et changement de sens se déplace toujours dans le sens de celui qui veut retoucher.

## Human gate

- Validation : accordée
- Référence : « garder », Owner, 2026-08-30, après que le malentendu à l'origine du dépôt a été nommé et les trois options — garder, retirer, geler — posées.
- **Circonstance du dépôt, consignée** : cette Décision a été déposée sur un malentendu. L'Owner demandait un prompt correctif à envoyer dans une fenêtre Executor ouverte ; le Pilot a compris « amendement » au sens d'un amendement du Vault et a gravé le présent texte sans qu'il ait été demandé. La validation ci-dessus est postérieure à ce constat et porte sur le contenu, non sur la circonstance.

## Liens

- `amends` — [Versionnement des Missions et outputs générés](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `see also` — [Relais entre rôles par mini-prompts à rubriques fixes](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — [Décision — Statut de preuve et contrôle d'arrêt](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
