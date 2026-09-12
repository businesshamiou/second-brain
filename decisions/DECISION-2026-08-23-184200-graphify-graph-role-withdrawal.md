---
type: decision
title: "Retrait de Graphify du rôle « graphe du Vault »"
created_at: "2026-08-23T18:42:00-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: granted
scope: graphify-case-study, verdict
amends:
  - "DECISION-2026-08-18-004740-graphify-v1-architecture.md"
  - "DECISION-2026-08-19-115306-project-registry-v1.md"
  - "DECISION-2026-08-17-003000-vault-central-architecture.md"
  - "DECISION-2026-08-19-233650-graphify-integrations-amendment.md"
---

# DÉCISION — RETRAIT DE GRAPHIFY DU RÔLE « GRAPHE DU VAULT »

## Date

2026-08-23

## Statut

`ARBITRATED`

## Décision

Graphify sort du rôle « graphe du Vault ». Cette Decision applique mécaniquement, sans l'assouplir ni la durcir, la règle de décision du protocole du banc de mesure (historique de l'atelier, non distribué) §2.6 aux chiffres mesurés par les Missions 032 (C2), 033 (C3) et 034 (C1) — trace complète dans l'étude de cas (historique de l'atelier, non distribué) §5.

La règle : « Graphify est conservé si, et seulement si, C3 obtient une justesse strictement supérieure à C2 sur au moins une question, sans dégrader la justesse sur aucune autre. » Mesuré : C3 gagne sur Q5 (2 contre 1) mais dégrade Q1 (1 contre 2). La seconde condition de la règle — aucune dégradation — échoue. Le critère de conservation n'est pas atteint. C'est la clause du dernier essai, acceptée d'avance par la [Decision des sept arbitrages du 2026-08-23, point 6](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md) et par le protocole B1 lui-même : sans nouvelle mesure.

### Ce qui reste en place

Rien de ce qui a remplacé Graphify pour la navigation ne dépend de lui, et rien n'en est retiré par cette Decision : le corpus, la fiche d'état générée (`<projet>/state/journal.md` + `<projet>/state/STATE.md`), les index générés par dossier (`tools/build-indexes.sh`), la recherche par contenu (`tools/find-in-vault.sh`) et les liens écrits (Standard de liens entre documents) restent le système de navigation du Vault. Les trois conditions mesurées le confirment : Q2, Q3 et Q4 obtiennent 2/2 dans les trois conditions, y compris C1 qui n'a aucun de ces outils.

### Gestes de retrait à faire (planifiés, non exécutés par cette Decision)

Hors périmètre de la Mission qui grave cette Decision (035) — à planifier par une Mission distincte :

1. `graphify hook uninstall` : retirer les hooks `post-commit`/`post-checkout` installés dans `vault`, et l'entrée `graphify-out/graph.json merge=graphify` de `.gitattributes`.
2. Désinstaller le paquet hors dépôt : `uv tool uninstall graphifyy`.
3. Archiver ou retirer `graphify-out/` (supprimé, Mission 040) (déjà non versionné) une fois la décision exécutée.
4. Retirer `.env`/`.env.example` (`GEMINI_API_KEY`) si plus aucun usage ne le requiert.
5. Retirer le rappel automatique « MANDATORY: run graphify... » injecté à chaque appel Bash/Read/Grep — observé et explicitement ignoré dans toutes les fenêtres de mesure du lot B (rapports 032 §8, 033 §6, 034 §6).
6. Mettre à jour `knowledge/runbook-vault-setup.md` §4 (retirer ou requalifier la section Graphify, ajouter l'entrée d'historique du retrait en §9 — obligation déjà inscrite dans le runbook lui-même).
7. Revoir la mention de Graphify dans `DECISION-2026-08-19-115306-project-registry-v1.md` (D5 : l'index et les fiches du Registry entraient dans le corpus actif Graphify) — devient sans objet.
8. Vérifier qu'aucun skill de première installation (arbitrage 7 des sept arbitrages) n'installe Graphify comme composant du graphe distribué.

### Porte de retour

Le sujet peut être rouvert si une mesure future — conduite sous ce protocole ou un successeur qui ne l'assouplit pas — produit une condition C3 où le graphe est **effectivement interrogé** (au moins une requête `graphify query`/`path`/`explain` par question, contrairement aux zéro requêtes sur cinq questions de cette mesure, rapport 033 §6 (historique de l'atelier, non distribué)) et où le résultat satisfait alors, sans assouplissement, le critère de la règle B1 §2.6. Tant que cette condition n'est pas remplie, le sujet reste clos.

## Raison

La Decision des sept arbitrages du 2026-08-23 (point 6) avait retenu « corriger, tester, puis trancher » plutôt que geler ou retirer Graphify par anticipation. Le défaut identifié (les index générés n'entraient pas dans le graphe) a été corrigé et mesuré comme effectif par la Mission 033 (33 nœuds issus de 9 fichiers `index.md`, sur 434 nœuds au total). La mesure comparative en trois conditions a ensuite été conduite selon le protocole B1, déposé d'avance et non modifié depuis. Le résultat mesuré ne satisfait pas le critère de conservation écrit d'avance : une dégradation sur Q1 accompagne le seul gain observé sur Q5.

## Impact

- Aucune installation ni suppression n'est faite par cette Decision — voir « Gestes de retrait à faire » ci-dessus.
- Aucun composant du système corrigé (fiche d'état, index, recherche par contenu, liens écrits) n'est affecté.
- Le paquet de distribution (arbitrage 7 des sept arbitrages) ne présentera plus Graphify comme composant du graphe du Vault une fois les gestes de retrait exécutés.
- L'épisode ouvert par la Mission 025 (« Graphify retiré du rôle "graphe du Vault", Decision formelle à rédiger ») est clos par cette Decision.

## Alternatives importantes

- **Conserver Graphify malgré la dégradation sur Q1** : rejeté — la règle écrite d'avance (B1 §2.6) exige explicitement l'absence de dégradation sur toute autre question ; l'assouplir après coup pour ne retenir que le gain sur Q5 contredirait la contrainte de la Mission 035 (« sans l'assouplir ni la durcir après coup »).
- **Remesurer C3 en s'assurant que le graphe soit effectivement interrogé** avant de trancher : rejeté par le protocole lui-même — la clause du dernier essai (B1 §2.6) exclut explicitement une nouvelle mesure après ce résultat. Le fait que C3 n'ait jamais interrogé le graphe (§« Ce que l'étude ne dit pas » de l'étude de cas) est documenté comme porte de retour, pas comme motif de remesure immédiate.
- **Retirer aussi le reste du système corrigé** (fiche d'état, index, recherche, liens) : rejeté — ces éléments ne dépendent pas de Graphify et obtiennent la même justesse que les autres conditions sur les questions qu'ils couvrent (Q2, Q3, Q4).

## Human gate

- Validation : accordée.
- Référence : la [Decision des sept arbitrages du 2026-08-23, point 6](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md) a pré-autorisé le mécanisme « corriger, tester, puis trancher » ; le protocole B1 (historique de l'atelier, non distribué), déposé sous une Mission `AUTHORIZED`, fixe la règle de décision d'avance et sans marge d'appréciation. Cette Decision exécute mécaniquement cette règle pré-autorisée sur les chiffres mesurés ; elle ne constitue pas un nouvel arbitrage de fond et ne requiert donc pas de nouveau gate distinct.

## Artefacts liés

- Protocole source de la règle appliquée : (historique de l'atelier, non distribué)
- Étude de cas et trace complète du verdict : (historique de l'atelier, non distribué)
- Mesures : (historique de l'atelier, non distribué), (historique de l'atelier, non distribué), (historique de l'atelier, non distribué)

## Liens

- `amends` — [Architecture Graphify V1 — navigation optionnelle et corpus actif borné](./DECISION-2026-08-18-004740-graphify-v1-architecture.md)
- `amends` — [Project Registry V1 — architecture et contrat d'écriture](./DECISION-2026-08-19-115306-project-registry-v1.md) (D5 devient sans objet)
- `amends` — [Architecture centrale — Vault permanent et projets frères](./DECISION-2026-08-17-003000-vault-central-architecture.md) (section Graphify, Mission 065)
- `amends` — [Amendement Graphify V1 — intégrations natives](./DECISION-2026-08-19-233650-graphify-integrations-amendment.md) (D1, D5 — Mission 065)
- `amends` — Arbitrage de la baseline Graphify V1 du Vault (historique de l'atelier, non distribué) (hors Vault) (statut `READY_TO_RESUME` dépassé — Mission 065)
- `source` — Protocole du banc de mesure — étude de cas Graphify (historique de l'atelier, non distribué) (hors Vault)
- `source` — Étude de cas Graphify — synthèse, verdict et matière à illustration (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Décision — Sept arbitrages de session du 2026-08-23, point 6](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
