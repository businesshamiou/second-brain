---
type: decision
title: "Sémantique du champ status — front-matter Mission et registre"
description: "Fige le status du front-matter Mission à l'autorisation de création ; MISSION-INDEX.md devient seule source de l'état d'exécution."
created_at: 2026-08-20T01:57:48-04:00
timezone: America/Montreal
status: ARBITRATED
scope: mission-status-semantics
owner_gate: granted
---

# DECISION — SÉMANTIQUE DU CHAMP STATUS : FRONT-MATTER MISSION ET REGISTRE

## Contexte

La [règle de versionnement des Missions](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) impose qu'une Mission et sa correction déclarent au minimum `mission_id`, `correction`, `supersedes` et `status`, mais ne définit nulle part les valeurs que `status` peut prendre, le moment où il se remplit, ni qui le met à jour. Aucun gabarit Mission n'existe pour fixer cet usage.

Une mesure du 2026-08-20 sur les 18 fichiers Mission actifs du registre (missions/MISSION-INDEX.md (hors Vault) de (historique de l'atelier, non distribué)) a établi que ce vide a produit un usage divergent : `status` porte tantôt une valeur d'autorisation (`AUTHORIZED`), tantôt une valeur d'exécution (`COMPLETED`), selon le fichier.

## Décision

**D1 — Autorisation figée.** Le champ `status` du front-matter d'une Mission exprime l'autorisation accordée au moment de sa création. Il est écrit une fois et n'est jamais retouché ensuite, y compris quand la Mission progresse ou se termine.

**D2 — Le registre fait foi.** missions/MISSION-INDEX.md (hors Vault) est la seule source de l'état d'exécution d'une Mission. Aucun autre emplacement ne fait autorité sur ce point.

**D3 — Vocabulaire du registre.** La colonne « Statut » du registre prend l'une de ces quatre valeurs : `AUTHORIZED`, `IN_PROGRESS`, `COMPLETED`, `ABANDONED`. L'Executor la met à jour à la fin de chaque Mission.

**D4 — Dépréciation en lecture.** Le `status` du front-matter est déprécié en lecture : personne ne s'y fie pour connaître l'état d'exécution d'une Mission. Sa seule fonction restante est de documenter, a posteriori, quelle autorisation a permis l'ouverture du fichier.

**D5 — Aucune reprise du stock.** Les 18 fichiers Mission existants ne sont pas modifiés à la lumière de cette Decision. Aucune Mission de réalignement, aucune correction `Cxx` n'est ouverte pour ce seul motif.

## État existant — sept fichiers COMPLETED

Sept Missions actives portent `COMPLETED` en front-matter : `001-C01`, `002-C01`, `003`, `006`, `007-C01`, `008`, `004-C02`. Leurs `created_at` couvrent une fenêtre continue de trois heures, du 2026-08-17T21:10:23-04:00 au 2026-08-18T00:19:00-04:00.

Cette fenêtre est encadrée des deux côtés par des Missions portant `AUTHORIZED` : avant, `005-C01` à 2026-08-17T21:01:00-04:00, la plus ancienne des 18 ; après, `011` à 2026-08-19T10:19:20-04:00, premier fichier créé après la fenêtre — soit environ 34 heures sans aucune Mission ouverte. Aucun autre fichier du stock actif ne porte `COMPLETED`.

Cette forme — un bloc continu, encadré, sans récidive avant ni après — est celle d'une maintenance interrompue, pas celle d'une convention en vigueur qui aurait ensuite été abandonnée. Ces sept fichiers restent intacts par D5 ; ils n'ont aucune valeur normative pour la présente Decision.

## Human gate

Arbitrage Owner rendu en session de pilotage, sur la mesure du 2026-08-20.

## Liens

- `applies` — missions/MISSION-INDEX.md (historique de l'atelier, non distribué) (hors Vault)
