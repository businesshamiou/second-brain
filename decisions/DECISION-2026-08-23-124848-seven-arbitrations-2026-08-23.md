---
type: decision
title: "Sept arbitrages de session du 2026-08-23"
created_at: "2026-08-23T12:48:48-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
---

# DÉCISION — Sept arbitrages de session du 2026-08-23

## Date

2026-08-23

## Statut

`ARBITRATED`

Arbitrage : session Owner/Pilot du 2026-08-23.

## Décision

Adoption des sept arbitrages rendus par l'Owner en session le 2026-08-23, tels que consignés dans la proposal des sept arbitrages et de l'ordre des lots révisé (historique de l'atelier, non distribué), §2.

1. **Repérage du Vault depuis un dossier de projet.** Retenu : marqueur remonté, un fichier posé à la racine de travail, retrouvé en remontant les dossiers parents jusqu'à le trouver — même principe que la détection d'un dépôt Git par `.git`. La déclaration écrite subsiste en confort de lecture, pas comme mécanisme réel. Écartés : le voisinage (`../vault/`), qui casse dès que l'utilisateur range ses projets autrement ; la déclaration écrite comme mécanisme réel, qui demande une maintenance manuelle par projet.

2. **Contenu de la fiche d'état lue à l'ouverture.** Retenu : niveau moyen — état courant en une phrase, prochaine action, portes ouvertes, catalogue des documents récents (chemin plus une ligne de description), état des dépôts. La fiche est un catalogue, pas un résumé, et ne recopie ni Decisions ni règles. Elle est générée par script, jamais écrite à la main. Écarté : un niveau qui recopierait le contenu des Decisions ou des règles, contraire au principe de catalogue.

3. **Classification de l'activité.** Retenu : l'IA classe et annonce en une ligne courte, corrigeable d'un mot par l'Owner. Classer n'est pas déposer : tout dépôt de fichier reste une porte annoncée avant écriture. Écartés : la classification silencieuse ; la confirmation demandée avant d'enchaîner ; le dépôt automatique pour les types réversibles.

4. **Tenue de l'état et fermeture de session.** Retenu : état tenu en continu et produit par script, patron du journal en ajout seul avec vue dérivée — le Pilot ajoute une ligne au journal à chaque jalon, n'écrit jamais la fiche d'état ; la fiche est la vue régénérée du journal ; une session arrêtée sans note de reprise est signalée sans rien reconstituer. Contrainte technique mesurée en séance : aucun script ne s'exécute sans appel de l'agent dans une fenêtre de chat, et la fermeture d'onglet ne déclenche rien — la délégation totale au script n'est possible que côté Executor. Écarté : la délégation totale au script côté chat, techniquement impossible dans les conditions mesurées.

5. **Identité du Vault.** Retenu : nom (« Brian ») plus contrat de rôle, sans personnalité, gravé dans le fichier marqueur de la racine de travail défini au point 1. Écartée explicitement : la personnalité (voix, ton, manière de répondre) — elle doit être repayée à chaque tour, et pousse l'agent à répondre « comme Brian » de façon fluide et assurée même quand le fichier n'a pas été lu, ce que la doctrine de preuve existe pour empêcher.

6. **Évaluation de Graphify.** Retenu : corriger, tester, puis trancher — Graphify n'est ni gelé ni retiré par anticipation ; il est réparé (les index générés n'entrent pas dans le graphe, défaut principal à corriger) et remesuré dans les conditions corrigées, protocole complet en proposal 122144 §3. Écarté : geler ou retirer Graphify par anticipation, avant mesure dans les conditions corrigées.

7. **Distribution et première installation.** Retenu : un paquet squelette plus un projet modèle démontable, effaçable par une commande — le projet modèle est le cas métier « Une semaine sans écran », reconstruit proprement depuis les gabarits courants. L'histoire réelle du chantier ne s'installe pas chez l'utilisateur : elle devient une étude de cas système (le workshop a construit le workshop), destinée à la présentation et à la fiche produit. Le skill de première installation fait quatre choses et pas davantage : poser ses questions de contexte, écrire le fichier marqueur avec le nom et le contrat, démarrer le journal, générer les premiers index. Écarté : installer l'histoire réelle du chantier chez l'utilisateur. *Note d'amendement (2026-08-26) : le projet modèle ci-dessus n'est plus « Une semaine sans écran » — la Décision `205728` abandonne ce cas d'étude, et la Décision `232341` (point 1.7) désigne `wordpress-workshop` comme premier-né du standard de projet et candidat projet modèle du paquet distribuable.*

## Raison

Ces sept points étaient en attente depuis la proposal du 2026-08-23 01:38 (historique de l'atelier, non distribué), remplacée par la proposal 122144. L'Owner les a tous rendus en session le 2026-08-23 ; cette Decision les grave sans attendre l'exécution des lots qui en découlent.

## Impact

Ouvre l'exécution des lots A à E listés en proposal 122144 §5, à commencer par le lot A (Mission 027). Sert de fondement normatif pour tout script ou gabarit qui implémente le journal, la fiche d'état, la classification, l'identité du Vault, le protocole de mesure Graphify, et le paquet de distribution.

## Alternatives importantes

- Délégation totale au script côté chat : rejetée, impossible techniquement dans une fenêtre de chat (mesuré en séance).
- Personnalité du Vault en plus du contrat de rôle : rejetée, coût de relecture répété et risque de réponse assurée sans lecture.
- Gel ou retrait anticipé de Graphify : rejeté, la mesure doit précéder le verdict.
- Installation de l'historique réel du chantier chez l'utilisateur : rejetée, seule l'étude de cas régénérée est distribuée.

## Human gate

- Validation : accordée
- Référence : arbitrage de l'Owner en session le 2026-08-23, formalisé par la Mission 028.

## Artefacts liés

- Proposal source : (historique de l'atelier, non distribué)
- Proposal remplacée : (historique de l'atelier, non distribué)

## Liens

- `amended by` — [Décision — Pivot du cas d'usage de l'atelier](./DECISION-2026-08-25-205728-workshop-case-study-pivot-wordpress.md)
- `source` — Proposal sept arbitrages et ordre des lots révisé (historique de l'atelier, non distribué) (hors Vault)
- `see also` — Mission 027 — Lot A (historique de l'atelier, non distribué) (hors Vault)
- `see also` — Mission 028 — Gravure du rang 1 (historique de l'atelier, non distribué) (hors Vault)
- `amended by` — [Décision — Initiation et adoption de projet, acte de naissance](./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md) (§1 : résolution par acte de naissance, marqueur porteur d'identité)
