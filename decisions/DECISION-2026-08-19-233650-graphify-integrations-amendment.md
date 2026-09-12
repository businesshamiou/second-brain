---
type: decision
title: "Amendement Graphify V1 — activation des intégrations natives"
description: "Lève l'exclusion des hooks et du MCP, retient le mode par défaut et exclut le mode strict."
created_at: 2026-08-19T23:36:50-04:00
timezone: America/Montreal
status: ARBITRATED
scope: graphify-integrations
amends: "DECISION-2026-08-18-004740-graphify-v1-architecture.md"
owner_gate: granted
---

# DECISION — AMENDEMENT GRAPHIFY V1 : INTÉGRATIONS NATIVES

## Contexte

La Decision Graphify V1 excluait les hooks, le MCP et toute automatisation, et imposait une actualisation explicite du graphe. Elle prévoyait qu'une évolution de cette contrainte exigerait une Mission et un gate distincts.

Deux constats motivent cet amendement.

**Le motif du coût ne tient plus.** La reconnaissance a mesuré que le hook de reconstruction relance une extraction syntaxique locale, sans appel à un modèle, sans transmission de contenu et sans consommation d'interface applicative.

**Le motif de la simplicité s'est retourné.** L'actualisation explicite a été omise à plusieurs reprises. Le graphe s'est périmé en silence, et des mesures ont été conduites sur un état obsolète sans que personne ne s'en aperçoive. Un mécanisme automatique de reconstruction supprime cette classe d'erreur.

## Décision

### D1 — Hooks de reconstruction autorisés

Les hooks de dépôt fournis par l'outil sont autorisés dans le Vault. Ils reconstruisent le graphe après un commit ou un changement de branche, par analyse syntaxique locale uniquement.

L'actualisation cesse d'être exclusivement explicite : elle devient automatique pour la partie qui ne coûte rien, et reste explicite pour l'extraction sémantique complète, qui demeure sous contrôle d'une Mission.

### D2 — Mécanismes toujours-actifs autorisés, dans leur forme native

Les mécanismes qui incitent un assistant à consulter le graphe avant de fouiller les fichiers sont autorisés, tels que l'outil les écrit.

Ces blocs de directives ne sont pas réécrits à la main. Un bloc réécrit ne suit plus les évolutions de l'outil et devient une charge de maintenance permanente. Leur langue et leur formulation relèvent de l'outil, non des conventions du Vault.

Cette exception à la règle de langue est délibérée et bornée : elle ne vaut que pour les blocs maintenus par un outil tiers, jamais pour les artefacts du chantier.

### D3 — Mode strict exclu

Le mode strict, qui bloque la première lecture brute de fichier tant qu'aucune interrogation du graphe n'a eu lieu, est exclu.

Il supprime le fallback vers les fichiers, que la Decision V1 pose comme obligatoire et que cet amendement confirme. Il rendrait par ailleurs inaccessible la lecture directe du [registre des projets](../projects/PROJECT-REGISTRY.md), dont les mesures ont établi qu'il n'est pas restitué par l'interrogation du graphe.

### D4 — Ce qui reste inchangé

- Les fichiers et Git restent la source de vérité ; le graphe demeure une couche dérivée.
- Le fallback vers les fichiers reste obligatoire en toute circonstance.
- Les sorties générées ne sont jamais éditées à la main et ne sont pas versionnées.
- Le graphe du Vault reste séparé des graphes de projet ; aucune fusion globale.
- L'extraction sémantique complète reste sous contrôle d'une Mission.

### D5 — Serveur MCP

L'exclusion du serveur MCP est levée dans son principe. Sa mise en service n'est pas décidée ici : elle relèvera d'une Mission distincte, la reconnaissance ayant établi qu'aucune configuration n'est générée par l'outil et que toute mise en place serait rédigée à la main.

**Note (2026-08-26, Mission 065)** : D1 et D5 autorisent des mécanismes Graphify (hooks de dépôt, principe d'un serveur MCP dédié) devenus sans objet — Graphify est sorti du rôle « graphe du Vault » puis a été intégralement éradiqué (Mission 040, 2026-08-24). Conservé pour lecture historique, non corrigé sur place (`amended by` ci-dessous).

## Conséquences

Aucune réécriture de la Decision V1 : elle reste lisible dans son état d'origine, et cet amendement s'y ajoute.

Les fichiers écrits par l'outil dans le dépôt sont versionnés tels quels. Leur maintenance appartient à l'outil.

## Human gate

Arbitrage Owner rendu en session de pilotage, après lecture du rapport de reconnaissance des intégrations.

## Liens

- `amends` — [Architecture Graphify V1](./DECISION-2026-08-18-004740-graphify-v1-architecture.md)
- `see also` — [Project Registry](../projects/PROJECT-REGISTRY.md)
- `amended by` — [Retrait de Graphify du rôle « graphe du Vault »](./DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md) (D1, D5)
