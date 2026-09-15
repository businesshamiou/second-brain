---
type: decision
title: "Arbitrage d — étage 2 (allowlist d'écriture MCP) en statu quo documenté, trois conditions de réveil"
description: "Grave l'arbitrage Owner « d » : l'allowlist d'écriture MCP côté Pilot n'a pas de voie native satisfaisante (Mission 063, confirmé par le rapport du Vault aîné) ; l'étage 3 reste la protection en vigueur ; trois conditions de réveil nommées, aucune portée effective."
created_at: "2026-08-26T16:39:58-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
---

# DÉCISION — ÉTAGE 2 (ALLOWLIST MCP) EN STATU QUO DOCUMENTÉ

## Date

2026-08-26

## Statut

`ARBITRATED`

## Décision

Deux mesures convergent : la Mission `063` a établi que le serveur MCP filesystem installé (`@modelcontextprotocol/server-filesystem@2026.7.10`, lancement natif) ne porte aucun mécanisme de lecture seule par dossier, ni par arguments CLI ni par MCP Roots. Le rapport du Vault aîné (knowledge-note `KNOWLEDGE-NOTE-2026-08-26-163649`) confirme indépendamment que son propre mécanisme de restriction d'écriture repose entièrement sur le hook `PreToolUse` de Claude Code — sans équivalent sous Claude Desktop + MCP, et dont le portage serait une réécriture substantielle, pas une adaptation mineure (knowledge-note §5.3). L'Owner tranche « d » : l'étage 2 de la charte des rôles (allowlist d'écriture du Pilot par configuration du serveur MCP) reste **en statu quo documenté**, non implémenté. L'étage 3 (muraille pre-commit) demeure la protection mécanique effective en vigueur, preuve à l'appui : trois refus réels du garde-fou à la Mission `057` (deux refus de réciprocité de liens, un crash d'outil sur cible cross-dépôt — aucun contournement tenté, tous les trois documentés au rapport 057).

La leçon de la panne de 5 jours du Vault aîné (garde-fou silencieusement inactif du 21 au 26 juillet, détectée seulement a posteriori par lecture du journal — knowledge-note §4.2) justifie, en une phrase, le canari des garde-fous déjà prévu dans le skill `session-start` (Décision `232341` §5.1) : un mécanisme qui peut tomber en panne sans le signaler n'est une protection que tant que quelqu'un vérifie qu'il tourne encore.

## Raison

Le statu quo n'est pas un renoncement silencieux : il est documenté, daté, et borné par des conditions de réveil explicites (ci-dessous), conformément au refus YAGNI du moteur de politique complet (Décision `232341` §5.4) — ne pas construire un mécanisme dont le besoin réel n'est pas encore mesuré.

## Conditions de réveil

Trois, et seulement trois :

1. **Le serveur amont gagne un support natif de lecture seule par dossier** (nouvelle version du paquet, ou changement de méthode de lancement mesuré et validé) — revoir l'allowlist au palier 1.
2. **Un accident réel d'écriture Pilot survient** (pas un risque théorique : un geste effectivement observé hors du périmètre attendu) → voie de réveil : wrapper MCP côté Pilot, sur le modèle du sas par rôle de l'aîné (knowledge-note §5.3, voie 2 — réécriture de l'interception, pas une recopie).
3. **Un accident réel d'écriture Executor survient** → voie de réveil : portage de pre_tool_use.py, sur le même runtime Claude Code que celui déjà en usage ici — la couche « hooks Git + policy » que l'aîné qualifie lui-même de « proche du copier-coller » est déjà couverte, sous une autre forme, par notre étage 3 ; c'est la couche d'interposition Write/Edit qui resterait à porter.

## Impact

- Aucune configuration n'est appliquée à claude_desktop_config.json ; aucun geste d'application n'a eu lieu ni n'est prévu par cette Décision.
- La porte `open-mcp-allowlist-verification` se ferme ; une porte gelée `frozen-mcp-write-allowlist` s'ouvre, portant les trois conditions ci-dessus comme seule condition de réveil.
- Aucun changement de périmètre d'écriture du Pilot ou de l'Executor : la charte des rôles (`RULES-2026-08-23-224706`) s'applique sans modification.

## Alternatives importantes

- Construire immédiatement un wrapper MCP (voie 2 des conditions de réveil) sans accident réel constaté : rejeté, YAGNI (232341 §5.4) — le besoin n'est pas mesuré, seulement anticipé.
- Ne documenter aucun statu quo et laisser la question implicitement close : rejeté — c'est exactement le patron qu'une règle non gravée dérive, déjà nommé aux Missions 062 et 063 pour d'autres sujets.

## Human gate

- Validation : accordée
- Référence : mot exact « je tranche : d, dépose 064 », 2026-08-26, Mission `064`.

## Artefacts liés

- Mesure : (historique de l'atelier, non distribué) (hors Vault).
- Constat brut : (historique de l'atelier, non distribué) (hors Vault).
- Rapport du Vault aîné (enveloppé) : (historique de l'atelier, non distribué) (hors Vault).

## Liens

- `source` — Rapport d'exécution — Mission 063 (historique de l'atelier, non distribué) (hors Vault)
- `source` — Knowledge-note — Mécanisme de restriction d'écriture du Vault aîné (historique de l'atelier, non distribué) (hors Vault)
- `applies` — Décision — Consolidation du 2026-08-25 soir (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
