---
type: decision
title: "Extension de la convention de tags du journal — tag CLOSE: et portes à clé"
created_at: "2026-08-25T11:09:35-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: granted
amends:
  - "DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md"
  - "../rules/RULES-2026-08-23-220049-activity-classification-and-system-keywords.md"
related_mission: "051"
---

# DÉCISION — EXTENSION DE LA CONVENTION DE TAGS DU JOURNAL : TAG `CLOSE:` ET PORTES À CLÉ

## Date

2026-08-25

## Statut

`ARBITRATED`

Arbitrage : session Owner/Pilot du 2026-08-25, ligne à ligne sur les fermetures, les clés et les gels (« je valide go »), exécuté par la Mission 051 (historique de l'atelier, non distribué).

## Décision

1. Le tag `CLOSE: <clé> -- <référence>` est ajouté à la convention de tags du journal ratifiée par la [Decision du 2026-08-23-143542](./DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md).
2. Toute porte s'écrit désormais une-porte-une-ligne-une-clé : clé `open-*` ou `frozen-*`, en kebab-case anglais, suivie de ` -- ` puis le texte.
3. L'état affiché par la fiche est le net : dernière `OPEN:` par clé, moins `CLOSE:` postérieure de la même clé.
4. Les lignes `OPEN:` legacy sans clé, antérieures à la baseline du 2026-08-25, sont exclues de la fiche et comptées en une ligne unique ; le journal n'est jamais réécrit.
5. Fermetures F1–F6 de la baseline du 2026-08-25 :
   - **F1** — check-links actif sur l'atelier (historique, non distribué) (Mission 049).
   - **F2** — défaut skip non-exécutable corrigé (Missions 046/049).
   - **F3** — dépôts poussés et liste périmée (push du 2026-08-24).
   - **F4** — hooks PreToolUse graphify retirés (2026-08-24T11:23).
   - **F5** — formulation « verdict Graphify suspendu jusqu'au lot B » morte : le lot B a été exécuté et Graphify éradiqué (Mission 040) ; le gel survit sous la clé `frozen-graphify-verdict`.
   - **F6** — trou de numérotation 047 assumé.

## Raison

La fiche d'état affichait l'union de toutes les sessions, sans fermeture ni déduplication : besoin démontré le 2026-08-24/25 (11 entrées dont au moins 4 périmées, un item répété quatre fois), pas anticipé lors de la ratification initiale des tags.

## Impact

- `vault/tools/build-state.sh` reconnaît `CLOSE:` en fermeture et calcule l'état net par clé ; `OUVERT:`/`OPEN:` restent reconnus en lecture pour l'historique, les nouvelles écritures utilisent `OPEN:`/`CLOSE:`.
- La baseline arbitrée (13 portes) est gravée au journal de (historique de l'atelier, non distribué) en Mission 051, étape 5.
- Les lignes de journal historiques ne sont ni réécrites ni supprimées.

## Alternatives importantes

- Réécrire ou dédupliquer le journal existant : écartée, le journal est en ajout seul par contrainte structurelle du Vault.
- Fermer les portes legacy par des lignes `CLOSE:` rétroactives une à une : écartée, aucune de ces lignes ne porte de clé conforme ; elles sont comptées comme legacy plutôt que fermées formellement.

## Human gate

- Validation : accordée
- Référence : arbitrage Owner ligne à ligne, session Pilot du 2026-08-25 (« je valide go »), exécuté par la Mission 051.

## Artefacts liés

- Mission d'exécution : (historique de l'atelier, non distribué)

## Liens

- `amends` — [Decision — Contrat du Pilot, marquage des documents remplacés, et ratification de la convention de tags du journal](./DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md)
- `amends` — [Classification d'activité PIV et mots-clés système](../rules/RULES-2026-08-23-220049-activity-classification-and-system-keywords.md) (§7, liste des tags — Mission 066)
- `see also` — Mission 051 — Purge des portes ouvertes, tag CLOSE, index rattrapé (historique de l'atelier, non distribué) (hors Vault)
