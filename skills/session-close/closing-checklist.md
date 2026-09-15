---
title: "Liste des trous de clôture, une mesure par ligne"
description: "Source unique de l'inventaire joué par le skill session-close avant toute clôture : chaque famille de trou avec l'outil qui la mesure et la faute datée qui l'a payée. C'est ce fichier qu'on amende quand un trou nouveau apparaît — le corps du skill ne bouge pas. Chaîne amended by suivie par le skill."
created_at: "2026-09-01T19:30:00-04:00"
timezone: America/Montreal
status: active
---

# LISTE DES TROUS DE CLÔTURE

Jouée par le skill `session-close` (§2, étape 1 côté Pilot ; §3 côté Executor pour les lignes marquées E). Une ligne = un trou possible, l'outil qui le mesure, la faute qui l'a payée. Un trou non mesuré est un trou.

| # | Trou | Mesure (Pilot : MCP · Executor : shell) | Faute payée |
|---|---|---|---|
| 1 | Mission de `MISSION-INDEX.md` sans état final (ligne absente, ou statut ni `COMPLETED` ni `STOP`/`PARTIEL` daté) | `read_text_file` de `missions/MISSION-INDEX.md`, comparer aux Missions déposées dans la session · E : `grep` de chaque numéro | Mission 112 : trois fenêtres sans ligne 112, la 113 a STOP dessus (2026-09-01) |
| 2 | Bloc RELAY reçu dans la conversation et non consommé (verdict non repris, « À trancher » sans mot Owner) | relecture de la conversation, un RELAY = une ligne | RELAY 112 (reprise) non tranché avant l'émission du /goal 113 (2026-09-01) |
| 3 | Artefact Pilot déposé (capture, proposal, decision, mission) non suivi par Git | `get_file_info` sur chaque chemin annoncé dans la conversation, puis présence dans le dernier commit du dépôt · E : `git status --porcelain` | résidus non commités traînés trois sessions (28-30 août, rangés Mission 109) |
| 4 | Porte ouverte (`OPEN:` au journal) sans `CLOSE:` postérieure alors que sa condition est remplie | `read_text_file` de `state/STATE.md` (section portes) · E : `build-state.sh` à blanc | porte `open-mission-internal-coherence` fermée seulement par la Mission 111 |
| 5 | Résidu signalé (rapport, RELAY : diff fantôme, sous-produit d'outil, fichier concurrent) sans arbitrage Owner | rubriques « Écarts » / « Consignations » des rapports de la session | `proposals/superseded-files.txt` traîné deux fenêtres avant prescription (Mission 112) |
| 6 | État push : tête locale ≠ `refs/remotes/origin/main` sur un dépôt, sans mot Owner sur le push | `read_text_file` de `.git/refs/heads/main` et `.git/refs/remotes/origin/main` (ou `packed-refs`) · E : `git status -sb` (`ahead`) | push suspendu par l'Owner le 2026-09-01 01:00, à rappeler à chaque clôture |
| 7 | Handoff précédent non consommé (file de reprise dont un point n'a ni été joué ni été arbitré) | lecture du dernier `handoffs/HANDOFF-*.md` | handoff 004859 : points « skills chat » et « override caduc » repris deux sessions plus tard |
| 8 | Épingle en retard : le Vault a reçu un commit dans la session et `<projet>/.pre-commit-config.yaml` pointe encore l'ancien SHA — référence de vérité `origin/main`, `repo:` désignant un dépôt distant (Mission 155) ; ré-épinglage possible **après le push Owner** seulement, sinon trou porté au handoff, avec régénération de `_dist/skills-chat/` | `grep rev:` du fichier comparé à `.git/refs/remotes/origin/main` du Vault · E : `bash tools/check-vault-pin.sh` | ANOMALY des rapports 153 et 154, quatre re-épinglages manuels en un jour |

Règle : la liste est un inventaire ; un trou se ferme par une Mission, un arbitrage Owner ou une instruction ponctuelle — jamais par le skill lui-même.

## Liens

- `see also` — [Skill session-close](./SKILL.md)
- `applies` — [Décision — Tag CLOSE: et portes à clé du journal](../../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
