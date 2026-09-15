---
type: decision
title: "Principe de placement des amendements — une Décision d'amendement vit dans le dépôt du document qu'elle amende"
description: "Grave l'arbitrage M de l'Owner : toute Décision portant une relation amends ou supersedes vers un document se dépose dans le dépôt de ce document, jamais dans le dépôt frère. Les relations d'amendement restent ainsi internes au graphe de chaque dépôt, calculables par les gardiens, et la chaîne d'amendement du produit distribué ne contient jamais de lien mort. Résout la tension cross-dépôt révélée par la Mission 085 sans toucher ni au standard de liens ni aux gardiens."
created_at: "2026-08-28T20:59:04-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
---

# DÉCISION — L'AMENDEMENT VIT DANS LE DÉPÔT DE L'AMENDÉ

## Date

2026-08-28

## Statut

`ARBITRATED`

## Décision

**1.** Toute Décision portant une relation `amends` ou `supersedes` vers un document se dépose **dans le dépôt où vit ce document**. Une règle du Vault s'amende par une Décision déposée dans `vault/decisions/` ; un document de projet s'amende depuis le dépôt du projet. Aucune relation `amends`/`supersedes` ne traverse la frontière des dépôts.

**2.** Si une Décision devait amender des documents des deux dépôts à la fois, elle se scinde : une Décision par dépôt, reliées entre elles par `see also` (hors graphe, informationnel).

**3.** Ce principe est déjà la pratique de fait du corpus — les amendements du push délégué (`DECISION-112528`) et le protocole de copie (`DECISION-100016`) vivent dans `vault/decisions/` parce qu'ils amendent des textes du Vault. Il devient ici une norme gravée. `DECISION-2026-08-28-203627`, déposée par erreur de placement dans le dépôt de projet, est déménagée dans `vault/decisions/` en application immédiate.

**4.** Motif produit, au-delà de la mécanique : le Vault est distribué seul. Un document du Vault dont la chaîne d'amendement pointe hors du Vault livre un **lien mort** aux participants, dans le produit même. Ce principe garantit que la chaîne d'amendement de tout document distribué est entière dans ce qui est distribué.

## Raison

Arbitrage M de l'Owner, 2026-08-28. La Mission 085 a révélé, à la première relation `amends` cross-dépôt de l'histoire du corpus, une tension structurelle entre `RULES-115658` §5 (réciprocité obligatoire des relations typées) et §6 (un lien hors dépôt n'est pas une arête) : un amendement cross-dépôt est simultanément obligatoire et invisible au calcul. Les trois issues proposées par la mesure — rendre les arêtes cross-dépôt réelles, assouplir le gardien, rétrograder en `see also` — coûtaient respectivement le couplage des dépôts et des liens morts distribués, une exemption de plus sur un gardien tout juste rendu conforme, ou la recréation de l'aveuglement aux amendements. Le placement corrige la cause : la relation n'a plus à traverser.

## Impact

- `RULES-115658` §5 et §6 restent tels quels : la tension disparaît parce que le cas qui l'activait n'a plus le droit d'exister.
- Aucun gardien modifié.
- La ligne réciproque posée sur `RULES-115658` par la Mission 085 (commit `f9887c8`) pointe vers l'ancienne adresse : sa correction vers `../decisions/` est un geste de la Mission 086.
- Ce principe est un candidat naturel à la promotion en règle du Vault lors d'une future consolidation du standard de liens ; en attendant, la présente Décision fait foi.

## Human gate

- Validation : accordée
- Référence : « je tranche : M », Owner, 2026-08-28.

## Artefacts liés

- Tension mesurée : (historique de l'atelier, non distribué) (hors dépôt).
- Application immédiate : `./DECISION-2026-08-28-203627-link-section-requirement-scoped-to-corpus.md` (déménagée).

## Liens

- `applies` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `see also` — [Décision — Bornage du standard de liens au corpus](./DECISION-2026-08-28-203627-link-section-requirement-scoped-to-corpus.md)
