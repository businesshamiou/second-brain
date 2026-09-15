---
type: decision
title: "Adoption du standard de liens entre documents"
created_at: "2026-08-21T11:56:58-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
---

# DÉCISION — Adoption du standard de liens entre documents

## Date

2026-08-21

## Statut

`ARBITRATED`

Arbitrage : session Owner/Pilot du 2026-08-21.

## Décision

Adoption de la [règle du standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md), qui grave les douze points de la proposal citée. Cette Decision conserve la proposal comme source au lieu de la renommer ou de la transformer.

Choix retenus pour les points marqués `[choix]` dans la proposal, repris tels qu'écrits :

- Nom de la section récapitulative : « Liens » (point 2).
- Vocabulaire fermé à six types : `applique`, `remplace`, `amende`, `source`, `prescrit par`, `voir aussi` (point 4). **Note (2026-08-26, Mission 065)** : ce vocabulaire français est anglicisé depuis [DECISION-2026-08-25-131034](./DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md), point 4 (`applies`, `supersedes`, `amends`, `source`, `prescribed by`, `see also`), migration exécutée par la Mission 054 ; conservé ici pour lecture historique, non corrigé sur place.
- Suffixe `(hors Vault)` / (historique de l'atelier, non distribué) pour un lien qui sort du dépôt courant, sans production d'arête (point 6).
- Partage bloquant/avertissement du contrôle machine : section `## Liens` absente et lien cassé bloquent ; absence de lien interne avertit seulement (point 9).
- Revue Pilot pour le bon type et le lien en contexte, en complément du contrôle machine (point 10).
- Rétroactivité écartée de cette Mission : les documents existants sans lien sont corrigés par une Mission dédiée (024), pas à la volée (point 11).

## Raison

Le graphe d'un corpus en prose reflète les liens écrits ; le modèle complète, il ne remplace pas. Trois traditions indépendantes (gestion de connaissance personnelle, décisions d'architecture logicielle, OKF) convergent vers la même forme, mesurée par les Missions 021 et 022.

## Impact

Six gabarits existants et un gabarit de rapport portent désormais une section `## Liens` pré-remplie. Un contrôle pre-commit (`tools/check-links.sh`) applique la règle mécaniquement. `AGENTS.md` et le runbook d'installation renvoient à la règle. Les documents existants restent inchangés jusqu'à la Mission 024.

## Alternatives importantes

- Front-matter seul : rejeté, mesuré `PARTIEL` par la Mission 021.
- Section « Liens » seule, sans lien en contexte : rejeté, le lecteur perd la relation là où elle est énoncée.
- Laisser le modèle déduire les liens : rejeté, mesuré par les Missions 020-C01 et 021.

## Human gate

- Validation : accordée
- Référence : accord de principe de l'Owner en session le 2026-08-21, formalisé par la Mission 023.

## Artefacts liés

- Proposal source : (historique de l'atelier, non distribué)
- Règle adoptée : `../rules/RULES-2026-08-21-115658-document-linking-standard.md`

## Liens

- `applies` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `source` — Proposal : standard de liens (historique de l'atelier, non distribué) (hors Vault)
- `see also` — Mission 023 (historique de l'atelier, non distribué) (hors Vault)
- `amended by` — [Arbitrages doctrinaux du 2026-08-25](./DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md) (point 4, anglicisation du vocabulaire)
