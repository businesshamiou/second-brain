---
type: decision
title: "Décision — Plafond de taille des Missions (20 000 octets) et budget de rédaction du Pilot (5 appels avant le cycle d'écriture), fail-closed, non rétroactifs"
created_at: "2026-09-05T14:47:00-04:00"
timezone: America/Montreal
status: active
description: "Chiffre les deux plafonds que la Décision 140714 attendait : une Mission tient sous 20 000 octets ; la rédaction d'un artefact Pilot coûte au plus 5 appels d'outil avant le cycle d'écriture, vérifications d'existence comprises. Mesures : douze artefacts du cycle 128–141 (tailles par get_file_info), sept rédactions comptées. Non rétroactifs ; mécanisation par le validateur mission-lint (prototype d'abord), le RELAY signale jusque-là."
---

# DÉCISION — Plafond de taille des Missions et budget de rédaction du Pilot

## Contexte

La Décision 140714 (2026-09-03) a nommé deux plafonds sans les chiffrer, faute de mesures : la taille d'une Mission et le budget de la phase de rédaction du Pilot. Les mesures existent depuis le cycle 136–141.

**Tailles de Missions, en octets, rapportées par get_file_info au dépôt (MESURÉ)** : sept Missions récentes avant le cycle — 15 175, 15 483, 17 356, 17 745, 18 067, 20 298, 25 000 (Owner, 2026-09-04, distribution des sept dernières) ; puis 137 : 20 385 ; 137-B : 13 139 ; 139 : 13 355 ; 140 : 17 901 ; 141 : 14 192. Douze valeurs ; médiane ≈ 17 000 ; les deux plus grosses (25 000 et 20 385) sont celles dont le Contexte et l'Existant mesuré recopiaient des faits déjà présents dans la conversation — défaut de proportionnalité, pas de contenu.

**Coût de rédaction, en appels d'outil avant le cycle d'écriture (write, info, edit, move), MESURÉ par comptage en session** : 136 : 10 (dont une lecture entière d'un index de 128 Ko pour une ligne utile) ; 137 : 1 ; 137-B : 0 ; Décision 124647 : 3 ; PROPOSAL 140326 : 2 ; 140 : 1 ; 141 : 3 (1 balayage + 2 vérifications d'existence de chemins). Une seule valeur au-dessus de 3, et c'est la faute mesurée du cycle.

**Ce qu'un plafond coûte quand il manque** : la 136 à 25 000 octets a demandé 22 substitutions après son challenge ; les Missions sous 15 000 (137-B, 139) n'en ont demandé qu'une ou deux. Une Mission longue a plus d'endroits pour être fausse (PROPOSAL 140326, point 11).

## Décision (Owner, chat, 2026-09-05)

1. **Taille : une Mission tient sous 20 000 octets**, mesurés par l'outil (get_file_info ou wc -c) sur le fichier déposé. Douze mesures : dix passent, deux — les deux défauts de proportionnalité — sont refusées ; c'est le sens du plafond. Le même plafond s'applique aux Décisions et aux Propositions du Pilot.
2. **Rédaction : au plus 5 appels d'outil avant le cycle d'écriture**, toute lecture, recherche et vérification d'existence comprise ; les recherches d'outils (chargement de schémas) se comptent à part (Décision 145256). Au-delà, le Pilot s'arrête et dit pourquoi au lieu de continuer. Sept mesures : six sous 3, une à 10 par faute ; 5 laisse la marge des vérifications d'existence que le crible manuel impose (2 sur la 141).
3. **Proportionnalité, règle d'écriture** : quand rien n'est créé et que les mesures sont déjà dans la conversation, les rubriques « Existant mesuré » et « Contexte » citent la mesure par son numéro de rapport ou de RELAY en une ligne, sans la recopier. Un index se lit par tail ou par recherche d'une ligne, jamais en entier (Décision 124647, point 6).
4. **Fail-closed, non rétroactif.** Les Missions déjà commitées ne sont ni tronquées ni réécrites. Un artefact Pilot qui dépasse est refusé à sa promotion, pas commité.
5. **Mécanisation.** Le plafond de taille est appliqué par le validateur mission-lint (PROPOSAL 140326 ; prototype d'abord, arbitrage Owner du 2026-09-05, point 7) ; le budget de rédaction est compté par le Pilot dans la rubrique « Ouverture / budget » de chaque dépôt et vérifié par l'Owner. Tant que le validateur n'existe pas, la règle est une consigne d'auteur, et le RELAY ou le Pilot signale tout dépassement — même régime transitoire que la Décision 191407.

## Conséquences

- La Décision 140714 est chiffrée sur ses deux points en attente ; elle n'est pas réécrite (Décision 145256).
- Le gabarit de Mission reçoit une clause d'échelle (règle 3) par une Mission de mise à jour des gabarits, à grouper avec les changements de skills que l'audit 141 a mesurés.
- La liste de lecture du skill de rédaction de Mission reprend les règles 2 et 3.
- Le prototype mission-lint (à venir, hors dépôt) prend la taille comme premier contrôle déterministe ; sa mise au Vault suit l'arbitrage de la Décision Delivery Gate.

## Alternatives écartées

- Plafond à 25 000 (rien refusé) : n'apprend rien, la plus grosse Mission mesurée est aussi la plus fautive.
- Plafond à 15 000 : refuserait sept des douze mesures, dont la 140, jugée proportionnée ; trop serré avant la clause d'échelle du gabarit.
- Budget de rédaction à 3 : refuserait la 141 telle qu'elle a été écrite avec ses vérifications d'existence, que l'on veut encourager.
- Pas de plafond : la Décision 140714 a déjà tranché qu'il en fallait un.

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `see also` — [Décision — Budget de contexte du Pilot](./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md)
- `see also` — [Décision — Un index est un localisateur](./DECISION-2026-09-05-124647-index-as-locator-8000-cap-live-archive.md)
- `see also` — [Décision — Journal et index en pointeurs, ≤ 300 caractères](./DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)
- `source` — PROPOSAL — Delivery Gate, DRAFT → CANONICAL, mission-lint (historique de l'atelier, non distribué) (hors Vault)
- `applies` — [Décision — Statut de preuve et contrôle du STOP](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
