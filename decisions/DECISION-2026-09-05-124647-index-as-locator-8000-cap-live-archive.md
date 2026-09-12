---
type: decision
title: "Décision — Un index est un localisateur : ligne sans description, plafond de 8 000 octets par index, index vivant et index d'archive, registre des Missions allégé"
created_at: "2026-09-05T12:46:47-04:00"
timezone: America/Montreal
status: active
description: "Arbitrage Owner du 2026-09-05 sur la PROPOSAL de l'audit 139 : une ligne d'index générée est un localisateur (identifiant, statut, titre court, nom de fichier), jamais une description ; tout index est plafonné à 8 000 octets, fail-closed et mécanisé ; l'index des Missions se scinde en vivant et archive ; le registre manuel MISSION-INDEX.md est conservé avec un rôle réduit au statut d'exécution. Complète la Décision 191407 (ligne ≤ 300) sans l'amender."
---

# DÉCISION — Un index est un localisateur (≤ 8 000 octets par index, vivant/archive, registre allégé)

## Contexte

L'audit 139 (rapport et PROPOSAL du 2026-09-05, lecture seule) a inventorié 37 index dans les deux dépôts et mesuré : missions/MISSION-INDEX.md 127 892 octets pour 136 entrées, ligne la plus longue 4 534 caractères ; missions/index.md 68 242 octets dont 50 % de descriptions ; reports/index.md 34 773 octets ; cinq index au-dessus des 8 000 octets qui plafonnent le digest d'ouverture (2 209 octets). Lire le registre entier coûte 233 fois un `grep` ciblé et 58 fois le digest. La Mission 080 avait ajouté titre, type, statut et description entière à chaque ligne d'index : c'est l'origine du poids. Le registre manuel et l'index généré des Missions se recouvrent, mais le statut d'exécution n'existe que dans le registre, le `status` du front-matter d'une Mission étant figé à sa création par le gabarit. Le même jour, le gardien de fraîcheur des index a dû être réécrit (Mission 137-B) parce que son coût croissait avec le nombre d'entrées et la longueur des descriptions.

La Décision 191407 (2026-09-02) plafonne la **ligne** du journal et du registre à 300 caractères ; elle n'a pas été mécanisée sur le registre (ligne mesurée à 4 534). La présente Décision ne la réécrit pas : elle fixe le **contenu** d'une ligne d'index générée et le **poids** d'un fichier d'index, et rend les deux mécanisables.

## Décision (Owner, chat, 2026-09-05)

1. **Une ligne d'index générée est un localisateur.** Pour tout index.md produit par `tools/build-indexes.sh`, une entrée porte : identifiant (numéro de Mission, horodatage ou nom), statut du front-matter, titre court, nom de fichier. **Aucune description** : elle vit dans le front-matter du fichier pointé. Le titre court est le `title` du front-matter, tronqué par l'outil à une longueur fixée par la Mission de mise en conformité, jamais à la main.
2. **Registre des Missions conservé, rôle allégé.** MISSION-INDEX.md reste le seul lieu du **statut d'exécution** (le `status` du front-matter reste figé à la création, doctrine du gabarit inchangée). Il devient une table à quatre colonnes — identifiant, statut d'exécution, date, nom du rapport — une ligne par Mission, sans description ni note ; la Décision 191407 (≤ 300 caractères) s'y applique et y est mécanisée. Ce qui n'est pas un statut d'exécution sort du registre.
3. **Plafond : 8 000 octets par fichier d'index**, généré ou registre, aligné sur le plafond du digest. Fail-closed : un index qui dépasse est refusé au commit par un gardien de poids, livré par la Mission de mise en conformité. **Non rétroactif** tant que cette Mission n'est pas livrée : jusque-là, la règle est une consigne d'auteur et le RELAY signale tout index qui la dépasse.

   **Annotation (2026-09-08, Mission 161).** Le gardien de poids du point 3 a été câblé dans le pre-commit de (historique de l'atelier, non distribué) le 2026-09-08 — il ne l'avait jamais été, mesure de l'historique : 0 occurrence de `index-weight` dans le passé de `.pre-commit-config.yaml`. Il a aussitôt refusé MISSION-INDEX.md, mesuré à **134 241 octets** pour 159 lignes de tableau, bloquant tout commit touchant le registre — c'est-à-dire toute Mission. Le plafond de 8 000 octets n'est atteignable par le registre qu'une fois le **point 2** livré, c'est-à-dire la table à quatre colonnes sans description ni note ; `tools/build-indexes.sh` ne produit ni ne scinde le registre, si bien que la consigne du refus (« ligne en localisateur, ou scission vivant/archive ») lui est inapplicable. Sur arbitrage Owner du 2026-09-08, `tools/check_index_weight.py` **exempte le registre du plafond de poids** et ne lui applique plus que la butée de 300 caractères par ligne (Décision 191407). **L'exemption tombe avec la livraison du point 2** : le point 3 reste inchangé dans son intention — « généré ou registre » —, seule son application au registre est suspendue.

   **Annotation (2026-09-08, Mission 163) — point 2 livré, exemption retirée.** Le registre des Missions est passé à quatre colonnes (identifiant, statut d'exécution, date, nom du rapport), ce que le point 2 prescrivait : le lot 3 de la Mission 140, reporté le 2026-09-05 pour fermer la V1, a été repris tel quel. L'exemption de poids posée par la Mission 161 est **retirée** de `tools/check_index_weight.py` : le registre est de nouveau soumis au plafond de 8 000 octets du point 3, comme à la butée de 300 caractères par ligne de la Décision 191407. Le registre vivant est scindé par tranches ; ses archives portent un nom distinct de celui des archives d'index générées, que le gardien de fraîcheur reconnaît par leur préfixe. L'annotation de la Mission 161 ci-dessus décrit un état révolu et n'est pas réécrite : elle date ce qui a été vrai entre le 2026-09-08 et cette livraison.

   **Annotation (2026-09-08, Mission 164) — point 5 livré, porte fermée.** Le banc d'essai des gardiens de fraîcheur et de poids annoncé par ce point — jamais livré, connu depuis la Mission 140 sous le nom de « banc 138 » — est écrit et versionné dans le Vault : un dépôt Git jetable, dix cas prouvés par le rapport 140, un script Python appelant les deux gardiens réels (jamais des copies), rejouable en une commande, tools/bench-guardians.sh. La porte index-conformance de la Mission 140 se ferme sur ce livrable.
4. **Index vivant et index d'archive.** L'index généré des Missions (et tout index qui ne tient pas sous 8 000 octets en localisateur pur — mesure 139 : 136 entrées dépassent) se scinde en un index courant, qui liste les entrées ouvertes et les N dernières closes, et un index d'archive, lu sur demande seulement. N est calculé par la Mission de mise en conformité pour tenir sous le plafond, et recalculé par l'outil, jamais à la main. Le gardien de fraîcheur vérifie les deux.
5. **Ordre de mise en conformité : doctrine d'abord.** Cette Décision, puis une Mission unique qui livre `tools/build-indexes.sh` conforme (points 1 et 4), le registre allégé (point 2), le gardien de poids (point 3) et la butée 300 sur le registre (191407, point 4), avec preuve byte-mesurée avant/après sur les 37 index de l'audit ; puis le banc d'essai des gardiens (138) teste l'ensemble.
6. **Lecture.** Un index se lit par `tail` ou par recherche d'une ligne, jamais en entier ; la liste de lecture d'ouverture reprend cette règle. Le digest d'ouverture reste la seule lecture entière prescrite.

## Conséquences

- Mission à rédiger (140) : build-indexes.sh en localisateur + vivant/archive, registre à quatre colonnes, gardien de poids ≤ 8 000 fail-closed, butée 300 sur le registre ; câblage au pre-commit de (historique de l'atelier, non distribué) par épingle de révision (deux pushes minimum) ; preuve sur les 37 index mesurés par la 139.
- Le gardien `check-indexes-fresh` (Python, 137-B) vérifie « ensemble des noms + statut » ; la disparition des descriptions dans les index réduit ce qu'il compare — sa preuve byte-identique est à rejouer par la Mission 140.
- Les skills `écriture-de-mission` et `session-close` reprennent la règle : la ligne de registre d'une Mission est un statut, pas un récit.
- La liste de lecture d'ouverture (`skills/session-start/reading-list.md`) reprend le point 6.
- Cinq doublons nommés par l'audit 139 : traités par la Mission 140 selon les rôles mesurés, aucune suppression avant elle.

## Alternatives écartées

- Description plafonnée dans la ligne : en localisateur pur, missions/index.md reste au-dessus de 8 000 octets (mesure 139) ; une description, même courte, ne peut pas tenir sous le plafond.
- Fusion du registre dans le front-matter : exigerait de rendre le `status` du front-matter mutable, contre la doctrine du gabarit de Mission ; écartée.
- Index unique avec marquage : ne réduit pas le poids ; écartée au profit de vivant/archive.
- Aucun plafond : le digest a prouvé qu'un plafond fail-closed tient là où une consigne dérive.

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `source` — Rapport 139 — audit des index (historique de l'atelier, non distribué) (hors Vault)
- `source` — PROPOSAL — règles d'index : contenu, coût, doublons (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Décision — Journal et index en pointeurs, ≤ 300 caractères](./DECISION-2026-09-02-191407-journal-and-index-as-pointers-300-chars.md)
- `applies` — [Décision — Statut de preuve et contrôle du STOP](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
