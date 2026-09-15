---
type: decision
title: "Décision — Verdicts du benchmark mémoire/retrieval : Vault natif KEEP, Mnemosyne REMOVE, OpenViking DEFER ; FREEZE de la couche après retrait, jusqu'après v1.0.0-stable"
created_at: "2026-09-06T11:38:50-04:00"
timezone: America/Montreal
status: active
description: "Arbitrage Owner du 2026-09-06 sur les mesures de la Mission 146 (rapport 112317) : le Vault natif répond 10/10 en 1,484 s et 6 455 octets ; Mnemosyne, tel que réellement installé et alimenté dans cet AIOS, répond 0/10 en 18,989 s et 10 506 octets, avec un faux positif confiant et un fait présent non remonté — REMOVE, portant sur ce déploiement mesuré, pas sur le produit en général ; OpenViking DEFER pour quatre causes mesurées, retourne au LAB/NEXT hors chemin critique V1. Après le retrait de Mnemosyne (Mission 147) : FREEZE de la couche mémoire/retrieval jusqu'après le tag v1.0.0-stable."
---

# DÉCISION — Verdicts du benchmark mémoire/retrieval et FREEZE

## Contexte

La Décision du 2026-09-05 sur la clôture de la phase mémoire/retrieval (204248) exigeait un benchmark borné et un verdict explicite par outil. La Mission 146 l'a joué le 2026-09-06 : corpus figé (995 fichiers, 16 161 948 octets, vault 0c8ded8 + 3 non suivis, l'atelier (historique, non distribué) bc34443), dix questions écrites avant toute installation, mêmes règles de comptage. Rapport : REPORT-2026-09-06-112317-146-memory-retrieval-benchmark.md (hors Vault, dépôt d'atelier).

**Mesures.** Vault natif : 10/10 correctes, 15 appels, 6 455 octets chargés, 1 484 ms — la question la plus chère a coûté 3 appels et 580 octets, contre jusqu'à 233 grep avant la réforme des index (audit 139 → Décision 124647 → Mission 140). Mnemosyne : 0/10, 10 appels, 10 506 octets, 18 989 ms — 1,6× plus d'octets et 12,8× plus de temps que le natif pour zéro réponse ; deux sondes d'équité aggravantes : un fait présent dans la banque (la ligne de push 2c8acd4..765543e) non remonté par la question naturelle, et un faux positif confiant (Mission 133 rendue pour « mission 135 », score 0,800, entity match) ; cause structurelle : vectors 0, vec_type none, dense_score 0,0 partout — la banque n'a jamais été indexée vectoriellement. OpenViking : non jouable dans les contraintes — pas de CLI dans le paquet pip (binaire Rust absent par conception), la forme « openviking-server init » falsifiée sur place, l'embedder par défaut qui télécharge hors LAB et échoue sur certificat, le serveur Ollama présent sans support des embeddings.

## Décision (Owner, chat, 2026-09-06)

1. **Vault natif : KEEP.** Les mécanismes en place — digest, index localisateurs, grep/tail, gardiens — sont la couche de retrieval de la V1.
2. **Mnemosyne : REMOVE.** Le verdict porte sur **son déploiement réellement installé et mesuré dans cet AIOS** — banque alimentée du seul journal, jamais indexée vectoriellement — pas sur une affirmation générale concernant le produit. Le retrait est propre et vérifiable (Mission 147) : câblage retiré, artefacts déplacés, note « expérimenté / rejeté » avec les mesures.
3. **OpenViking : DEFER**, pour impossibilité mesurable dans les contraintes (quatre causes ci-dessus). Il retourne au LAB/NEXT et ne fait plus partie du chemin critique V1.
4. **FREEZE.** Après le retrait de Mnemosyne, la couche mémoire/retrieval est gelée : aucun outil de mémoire, base vectorielle, mémoire en graphe ou retrieval n'est testé ni intégré **jusqu'après le tag v1.0.0-stable**. La reprise éventuelle est une décision NEXT/LAB, sur mesure.

## Conséquences

- Mission 147 : retrait de Mnemosyne — câblage remember de tools/append-journal.sh (posé par la Mission 122, fail-open), fichiers d'environnement et de données du projet, références opérationnelles dans les règles et skills (mesurées avant retrait), note de connaissance avec les chiffres du benchmark. La configuration MCP du poste (entrée mnemosyne de Claude Desktop) est un geste Owner, hors Mission.
- Le LAB du benchmark est purgé sur autorisation Owner du 2026-09-06, les preuves étant recopiées au rapport commité.
- La présente Décision et la 204248 entrent au Vault avec le commit vault de la Mission 147 (manifeste et index des décisions inclus).

## Alternatives écartées

- Garder Mnemosyne « au cas où » : contraire au point 1 de la 204248 (pas de dépendance sans valeur mesurée) ; les mesures sont sans ambiguïté.
- Réparer l'indexation vectorielle avant de trancher : ce serait un nouveau chantier en phase de stabilisation ; la porte reste ouverte en NEXT/LAB, après le tag.
- Jouer OpenViking en levant les contraintes (clé API, téléchargements hors LAB) : refusé par arbitrages Owner des 2026-09-05/06.

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `applies` — [Décision — Clôture de la phase mémoire/retrieval](./DECISION-2026-09-05-204248-memory-retrieval-closure-benchmark-freeze.md)
- `applies` — [Décision — Statut de preuve et contrôle du STOP](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
