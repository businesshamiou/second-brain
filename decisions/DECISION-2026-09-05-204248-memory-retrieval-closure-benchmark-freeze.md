---
type: decision
title: "Décision — Clôture de la phase mémoire/retrieval avant V1 STABLE : benchmark borné Vault natif / Mnemosyne / OpenViking, verdict KEEP ou REMOVE par outil, pas de coexistence par défaut, puis FREEZE"
created_at: "2026-09-05T20:42:48-04:00"
timezone: America/Montreal
status: active
description: "Amendement Owner du 2026-09-05 au plan de fermeture de la V1 (PROPOSAL 165829) : Mnemosyne n'est pas acquis ; OpenViking reçoit un dernier test en sandbox, sans intégration ni élargissement ; un benchmark compare Vault natif, Vault + Mnemosyne, Vault + OpenViking sur recall, précision, latence, volume de contexte, coût opérationnel ; chaque outil reçoit KEEP, REMOVE ou DEFER motivé ; coexistence seulement sur bénéfice démontré ; toute technologie sans fruit mesurable est retirée proprement et documentée ; puis FREEZE de la couche mémoire/retrieval pour V1 STABLE. Le benchmark ne démarre qu'après fermeture des blockers d'autonomie."
---

# DÉCISION — Clôture de la phase mémoire/retrieval avant V1 STABLE

## Contexte

La V1 se ferme (PROPOSAL 165829, arbitrages du 2026-09-05) : Vault autonome (Mission 142, objectif atteint, test d'ouverture Owner en attente), puis inventaire Legacy et promotion (Mission 143). Deux outils de mémoire/retrieval sont en jeu : Mnemosyne, installé en recall-only depuis la Mission 126 et jamais mesuré en gain réel (aucune Mission déclenchée par son recall ; recall vide sur « OpenViking » le 2026-09-04, deux faux résultats à score nul) ; OpenViking, évalué sur README et site le 2026-09-04 (base de contexte à trois niveaux L0/L1/L2, serveur local, modèle requis), jamais installé. Quatre autres candidats ont été écartés sur lecture (Rta-Smriti, ModelDeck, Cortex Suite). Le problème mesuré qui motive la question : lire un index entier coûte jusqu'à 58 fois le digest (audit 139) — la réponse structurelle (index localisateurs, Décision 124647) est en cours ; la question de l'outil de recall reste ouverte.

## Décision (Owner, chat, 2026-09-05)

1. **Mnemosyne n'est pas acquis.** Son apport réel est mesuré ; sans gain démontrable, ou si son coût et sa complexité dépassent son utilité, il est retiré proprement. L'absence d'outil est préférée à une dépendance sans valeur mesurée.
2. **OpenViking reçoit un dernier test, en sandbox/LAB seulement** : aucune intégration permanente avant résultat, aucun élargissement d'architecture, aucun impact sur le chemin critique de stabilisation.
3. **Benchmark borné**, trois configurations au minimum — Vault natif ; Vault + Mnemosyne ; Vault + OpenViking — sur les mêmes questions et le même corpus ; mesures : qualité du recall, précision, latence, volume de contexte et de tokens chargés, coût et complexité opérationnelle (installation, dépendances, entretien).
4. **Verdict explicite par outil** à l'issue : KEEP, REMOVE, ou DEFER uniquement si une raison mesurable empêche réellement de conclure — la raison est écrite.
5. **Pas de coexistence par défaut.** Mnemosyne et OpenViking ne coexistent que si le benchmark démontre deux fonctions complémentaires avec un bénéfice réel.
6. **Retrait propre et documenté** de toute technologie sans fruit mesurable : désinstallation, câblage retiré, manifeste et règles à jour, note « expérimentée / rejetée » avec les mesures.
7. **FREEZE** ensuite de la couche mémoire/retrieval pour V1 STABLE : aucun autre outil de mémoire, base vectorielle, mémoire en graphe ou retrieval n'est testé avant la prochaine phase NEXT/LAB. OpenViking est le dernier essai de cette phase, pas l'ouverture d'un chantier.
8. **Ordre** : le benchmark ne démarre qu'après fermeture des blockers d'autonomie (test d'ouverture Pilot de la 142, dépendance machine du dépôt). Il précède l'inventaire Legacy et la Mission 143 dans le plan de clôture.

## Conséquences

- Mission de benchmark à rédiger (LAB, hors dépôts, dans un dossier jetable) : corpus et questions fixés avant toute installation, trois configurations, mesures collées, verdicts KEEP/REMOVE/DEFER proposés à l'arbitrage Owner.
- Mission de retrait, si REMOVE : Mnemosyne (serveur MCP, banque, câblage de store sur le journal, règles et skills qui le nomment) et/ou OpenViking (sandbox détruite) ; note d'expérimentation rejetée dans les connaissances du projet.
- Le plan de clôture (PROPOSAL 165829, section 3) est amendé : étape 2 bis, benchmark et verdicts, entre la 142 et l'inventaire Legacy.
- La capture OpenViking du 2026-08-24, parquée « post-workshop », est la seule trace antérieure : elle est source du benchmark, jamais une norme.

## Alternatives écartées

- Garder Mnemosyne par défaut : dépendance sans mesure, contraire au point 1.
- Intégrer OpenViking sans benchmark : élargissement d'architecture en phase de stabilisation, contraire au principe directeur de la clôture.
- Reporter toute la question après V1 : laisserait un outil non mesuré dans la version stable ; le benchmark est court et borné, il tient avant le tag.

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `source` — PROPOSAL — Fermeture de la V1 (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Décision — Un index est un localisateur](./DECISION-2026-09-05-124647-index-as-locator-8000-cap-live-archive.md)
- `applies` — [Décision — Statut de preuve et contrôle du STOP](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
