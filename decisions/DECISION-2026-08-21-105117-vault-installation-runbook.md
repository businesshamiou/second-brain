---
type: decision
title: "Runbook d'installation du Vault — registre vivant, obligation de mise à jour par les Missions"
description: "Institue le runbook d'installation, sa qualification VERIFIED/DECLARED ligne par ligne, et l'obligation pour toute Mission d'installation de le mettre à jour dans le même commit."
created_at: 2026-08-21T10:51:17-04:00
timezone: America/Montreal
status: ARBITRATED
scope: vault-installation-runbook
owner_gate: granted
---

# DECISION — RUNBOOK D'INSTALLATION DU VAULT

## Contexte

Le Vault et son outillage (Git, hooks, Graphify, clé Gemini, serveur MCP « workshops », dépôts frères) ont été installés par gestes successifs depuis le 2026-08-17. Aucun document ne dit comment les remonter. Le `README.md` explique le pourquoi et le quoi, pas le comment. Les faits d'installation sont dispersés dans des audits, rapports et Decisions, et certains gestes n'ont laissé aucune trace (le mode de chargement de la clé Gemini, perdu entre les Missions 018 et 020). Le produit du workshop doit pouvoir être remonté par quelqu'un d'autre que l'Owner, à partir des seuls fichiers.

## Décision

Cette décision reprend, sans ajout de fond, les points de la proposal (historique de l'atelier, non distribué) qu'elle grave :

**D1.** Un fichier [`vault/knowledge/runbook-vault-setup.md`](../knowledge/runbook-vault-setup.md) : mode d'emploi ordonné pour installer et vérifier le Vault et son outillage. Sections fixes : prérequis · dépôts et branches · Git (hooks, `core.hooksPath`, attributs) · Graphify (version, installation, `.env.example`, commandes d'usage, régénération du rapport, sauvegardes) · serveur MCP « workshops » (configuration, sans valeur sensible) · rôles et sessions (Pilot, Executor, où ouvrir la session) · vérification de bon fonctionnement (commandes et résultats attendus) · historique des changements.

**D2.** Chaque ligne est qualifiée `VERIFIED` (mesurée au moment de l'écriture, commande à l'appui) ou `DECLARED` (reprise d'un document). Une ligne `DECLARED` devient `VERIFIED` quand une Mission la mesure.

**D3.** Obligation : toute Mission qui installe, met à jour, configure ou retire un composant met le runbook à jour **dans le même commit**. Le contrat du rapport d'exécution gagne une section « Impact sur l'installation : aucun / lignes du runbook modifiées ».

**D4.** `AGENTS.md` porte une ligne renvoyant au runbook et rappelant l'obligation, ainsi que le canal de rapport (`reports/`, deux lignes en chat).

**D5.** Avant le workshop, une Mission « installation à blanc » remonte le tout dans un dossier vide en ne suivant que le runbook ; ce qui manque est ajouté.

**D6.** Aucun secret dans le runbook : noms de variables, emplacements de fichiers, jamais de valeur.

## Raison

Le runbook est le seul artefact qui rend le produit transportable. Tenu au fil de l'eau, il coûte quelques lignes par Mission ; reconstitué à la fin, il coûte une archéologie et reste incomplet.

## Impact

Premier usage réel dans la présente Mission (022) : le runbook V1 est créé, et sa section Historique + Vérification est mise à jour pour ce que la Mission installe elle-même (environnement Python isolé, temporaire, sous `%TEMP%`). Les Missions suivantes qui touchent à l'installation portent désormais la même obligation.

## Alternatives importantes

- Reconstituer en fin de projet : rejeté (perte avérée d'information, gestes non tracés).
- Mettre l'installation dans le `README.md` : rejeté, le README est un texte d'intention, le runbook un texte de procédure ; deux rythmes de mise à jour.
- Automatiser par script d'installation : prématuré ; le runbook vient d'abord, un script peut le suivre.

## Human gate

- Validation : accordée
- Référence : arbitrage Owner/Pilot en session du 2026-08-21, gravé par la Mission 022 (historique de l'atelier, non distribué).

## Artefacts liés

- Proposal source : (historique de l'atelier, non distribué)
- Mission qui grave cette Decision : (historique de l'atelier, non distribué)
- Runbook institué : `../knowledge/runbook-vault-setup.md`

## Liens

- `see also` — [Runbook d'installation du Vault — V1](../knowledge/runbook-vault-setup.md)
