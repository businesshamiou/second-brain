---
type: decision
title: "Arbitrage de la baseline Graphify V1 du Vault"
created_at: 2026-08-17T21:14:09-04:00
timezone: America/Montreal
status: ARBITRATED
scope: vault-graphify-baseline
source_audit: "../audits/AUDIT-2026-08-17-165250-graphify-v1-vault-baseline.md"
related_mission: "../missions/MISSION-2026-08-17-211122-004-graphify-v1-vault-baseline.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-17-211409-graphify-v1-baseline-gate-record.md"
---

# DÉCISION — ARBITRAGE DE LA BASELINE GRAPHIFY V1

## Statut

**ARBITRATED — human gate historiquement accordé par l’Owner / Pilot.**

Cette décision enregistre l’arbitrage sans réécrire la proposition `163400`.

## Décision

La baseline Graphify V1 du seul Vault est autorisée dans les limites de Mission 004 : mode standard, frontières du Vault, aucun hook, MCP, watch, deep mode, graphe global, modification de source, staging, commit ou push.

## État d’exécution

La première exécution s’est arrêtée avec `NEEDS_OWNER_INPUT` parce que Graphify était absent. Cette interruption ne termine pas Mission 004.

Mission `007-C01` a ensuite rendu `graphify 0.9.26` disponible selon l’audit `174601`. Mission 004 reste `READY_TO_RESUME` depuis son préflight; la disponibilité de l’outil ne constitue pas une preuve que la baseline a été exécutée.

**Note (2026-08-26, Mission 065)** : cet état `READY_TO_RESUME` est doublement dépassé — `MISSION-INDEX.md` enregistre depuis Mission 004-C02 le statut `COMPLETED` de cette lignée, et Graphify est sorti du rôle « graphe du Vault » puis a été intégralement éradiqué (Mission 040, 2026-08-24). Conservé pour lecture historique, non corrigé sur place.

## Impact

- la proposition `163400` reste historique et inchangée;
- la Mission active est `004`;
- toute exécution doit remesurer l’état réel;
- les résultats de baseline nécessiteront un nouveau human gate.

## Liens

- `amends` — DECISION-2026-08-17-163400-graphify-v1-vault-baseline — Graphify V1 — baseline séparée du Vault (historique de l'atelier, non distribué)
- `amended by` — [Retrait de Graphify du rôle « graphe du Vault »](../../../vault/decisions/DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md) (hors l'atelier (historique, non distribué))
