---
type: decision
title: "Amendement — une ligne d'autorisation Owner couvre un seul geste"
description: "Amende DECISION-154553 (push délégué) : une ligne d'autorisation Owner verbatim ne couvre jamais plus d'un geste ; toute fusion de gestes dans une même ligne vaut refus des gestes fusionnés ; le gabarit se vérifie avant l'exécution, fail closed."
created_at: "2026-08-26T23:16:17-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md"
---

# DÉCISION — UNE LIGNE D'AUTORISATION = UN GESTE

## Date

2026-08-26

## Statut

`ARBITRATED`

## Décision

Une ligne d'autorisation Owner verbatim, quel que soit le gabarit qu'elle sert (push délégué de `DECISION-154553` ou tout gabarit futur du même type), ne couvre **qu'un seul geste**. Si une ligne fusionne plusieurs gestes distincts dans une même phrase (ex. suppression et push), **seuls les gestes couverts par le gabarit exact reconnu sont exécutables** ; tout geste additionnel fusionné dans la même ligne, sans son propre gabarit reconnu, vaut **refus** de ce geste précis — il ne se déduit jamais de la présence d'un gabarit voisin dans la même phrase. Le gabarit d'autorisation se vérifie **avant** l'exécution du geste qu'il couvre, jamais après coup : fail closed, conformément au modèle de menace anti-accident (§3.2 de `DECISION-232341`, hors Vault).

## Raison

Incident `RELAY PUSH-067` (2026-08-26) : la ligne d'autorisation collée par l'Owner fusionnait un ordre de suppression et l'ordre de push dans une seule phrase, sans reproduire à l'identique le gabarit push-seul de `DECISION-154553` (la clause push perdait son propre « j'ordonne », interleavée après la clause suppression). L'Executor a exécuté le push **avant** de vérifier ce gabarit contre le texte de la Décision, l'a constaté après coup et l'a signalé sans le dissimuler (journal, `open-mot-exact-push-suppression-blend`) ; il a en revanche **refusé** la suppression au nom de sa politique d'exploitation propre — conduite retenue comme exemplaire, aucun geste fusionné n'ayant été exécuté sans gabarit reconnu. Le push a été ratifié par l'Owner car son intention était explicite et son contenu sain (commits déjà relus de la Mission 067). Cette Décision grave la leçon pour empêcher la répétition : le prochain incident du même patron pourrait porter sur un geste au contenu moins anodin.

## Impact

- `DECISION-154553` reçoit un amendement, dans le même dépôt : son gabarit push-seul reste inchangé dans sa forme, mais son application est désormais bornée par la règle générale « un seul geste par ligne » — une ligne qui mêle le gabarit push à tout autre ordre ne valide que le push, jamais l'autre ordre, et seulement si le gabarit push y est reproduit à l'identique.
- Lien réciproque `amended by` posé sur `DECISION-154553` dans ce même commit (réparation du blocage de la Mission 068, étape 2 : la version précédente, rédigée dans (historique de l'atelier, non distribué), avait été refusée par le gardien de réciprocité faute de pouvoir écrire la réciproque dans `vault`).
- Vérification déplacée **avant** l'exécution : tout Executor confronté à une ligne d'autorisation doit localiser et relire le texte de la Décision qui définit le gabarit concerné avant d'agir, pas après.
- Ferme `open-mot-exact-push-suppression-blend` (voir ligne de journal `CLOSE:`, Mission 069).

## Alternatives importantes

- Exiger que toute ligne d'autorisation ne porte **aucun** texte libre additionnel, même après la date : rejeté — `DECISION-154553` autorise déjà explicitement du texte libre après la date pour le geste couvert ; le problème n'est pas le texte additionnel en soi, mais la fusion de plusieurs gestes distincts sans gabarit propre à chacun.
- Laisser l'Executor juger au cas par cas si une fusion est « substantiellement » couverte : rejeté — c'est exactement le raisonnement a posteriori qui a produit l'incident ; la règle doit trancher avant le geste, pas après.

## Human gate

- Validation : accordée
- Référence : Mission `069` (mot exact « je valide tout, dépose 069 », 2026-08-26), qui répare la gravure bloquée à l'étape 2 de la Mission `068` ; l'incident source est `RELAY PUSH-067` (chat, 2026-08-26, suite Mission 067).

## Artefacts liés

- Décision amendée : `DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md`.
- Incident source : `RELAY PUSH-067` (chat, 2026-08-26).
- Mission source : (historique de l'atelier, non distribué) (hors Vault) ; tentative bloquée précédente : (historique de l'atelier, non distribué) (hors Vault).

## Liens

- `amends` — [Décision — Le push délégué devient une règle](./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)
- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — Mission 069 — Réparations de distribution et gravure réparée (historique de l'atelier, non distribué) (hors Vault)
- `amended by` — [Décision — Relais et délégation, une règle un seul endroit](./DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
