---
name: ecriture-de-mission
description: "Draft a Vault Mission file and its Executor mini-prompt from the template, with measured links, a mandatory Context section, and a cross-check of Validations against Gates. Use when the Pilot needs to write, review, or fix a Mission. Triggers on: « écris la Mission », « rédige la Mission », « write the Mission »."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md, rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md, decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md"
  vault-validated: "2026-09-08T00:40:13-04:00"
---

Rédige une Mission du Vault et le mini-prompt Executor qui y mène, depuis le gabarit, avec des liens mesurés, une section Contexte obligatoire et une relecture croisée. **Surface Pilot seulement** : déposer un artefact est un geste Pilot ; l'Executor n'invoque pas ce skill. Ce skill n'exécute rien et ne décide pas l'architecture : un choix qui n'est pas une « manière d'implémenter » devient une question à l'Owner, recommandation et gate word inclus.

## 1. Lis le gabarit au moment d'écrire

Ouvre `templates/mission-template.md` du Vault **maintenant**, jamais de mémoire : il a changé le 1er septembre (Mission 111 : section `## Contexte`, commentaire de relecture croisée). La liste des sections est celle du gabarit, dans son ordre.

## 2. Rassemble un contexte mesuré

- Chaque fait porte sa date et son statut : `MESURÉ` / `DECLARED` / `HYPOTHÈSE` (DECISION-212009).
- Chaque nom de fichier lié est obtenu par `search_files` ou par listage, jamais tapé de mémoire (faute du 30 août : lien écrit de tête avec un mauvais nom).
- Chaque existence affirmée passe par `get_file_info` (faute « le hook existe », 30 août).
- Ce que l'Executor va trouver sur disque, et pourquoi c'est là, est écrit ; les pièges connus (défauts d'outil, emplacements trompeurs, précédents) sont nommés.

## 3. Rédige, section par section

`## Contexte` (les quatre contenus de DECISION-115547 point 1, dans l'ordre) · `## Objectif` · `## Périmètre` avec un hors-périmètre explicite · `## Préconditions` avec statut de preuve et STOP au moindre écart non trivial · `## Sources` · `## Décisions applicables` · `## Contraintes` · `## Mesures préalables` (obligatoire dès qu'une étape crée, copie, installe, épingle, câble ou configure : une ligne par cible, avec la commande qui mesure son état avant la pose) · `## Étapes` (jamais « supprimer » : « déplacer vers `_trash/` » avec empreinte, ou human gate) · `## Gates` (mot Owner **verbatim**, daté ; human gate non accordé listé) · `## Validations` chiffrées (avant → après) · `## Contrat de sortie` · `## Contrat de reprise` · `## Portes` · `## Liens` (`prescribed by` le standard de versionnement des Missions + `applies` sur chaque Décision appliquée).

## 4. Relecture croisée avant dépôt

Trois rubriques deux à deux (DECISION-115547 point 2) : chaque compte de `## Validations` est atteignable sans violer un interdit de `## Gates` ou de `## Contraintes` ; chaque étape de `## Étapes` est permise par les mêmes interdits. Trace-la par le commentaire HTML en tête de `## Validations`. Une contradiction trouvée = **réécrire, pas déposer** (fautes 090 et 108 ×2 : contradictions attrapées à l'exécution).

## 5. Contrôle de forme final

Joue `mission-checklist.md` dans le dossier de ce skill, ligne par ligne, avant le dépôt de **tout artefact Pilot** (Mission, Décision, capture, handoff, proposal) — pas seulement d'une Mission : les deux STOP de la Mission 149 sont tombés sur une Décision déposée sans que la liste ait été jouée (rapport 157, F3). Chaque ligne cite la faute ou la Décision qui l'a payée ; une ligne en échec = pas de dépôt.

## 6. Dépose par le patron DRAFT

`DRAFT-<slug>.md` au canonique (`missions/` du projet) → `get_file_info` → horodatage mesuré substitué dans `created_at` et dans le nom → renommage `MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md` → `get_file_info` final. Un seul tour ; `created_at` = horodatage du nom.

## 7. Produis le mini-prompt

Cinq rubriques fixes de RULES-124937, dans l'ordre : titre `Session Executor — Mission <NNN> (<description courte>)` · position libre · source à appliquer (chemin de la Mission) · **les quatre interdits standards seulement** — aucun push non délégué, aucun appel modèle, aucune suppression, déplacement vers `_trash/` seulement sur prescription de la Mission — plus un renvoi explicite aux rubriques `## Gates` et `## Contraintes` de la Mission (DECISION-115547 point 3) · sortie attendue = le bloc RELAY ; le Résumé du bloc RELAY suit le plafond de la règle 124937, jamais redit ici. Jamais un interdit propre ajouté dans le prompt. Livré en snippet copiable d'un seul geste, aucun fichier PROMPT (abolis, Décision A7).

## Ce que ce skill ne fait pas

Exécuter la Mission (Executor) · décider l'architecture à la place de l'Owner (un choix hors « manière d'implémenter » = question à l'Owner) · écrire un fichier PROMPT · clore ou ouvrir une session · modifier une Mission déjà exécutée (gelée, RULES-211522) : une correction passe par une Mission `-C01` ou un arbitrage Owner.

## Liens

- `see also` — [Liste de contrôle de forme d'un artefact Pilot, une faute par ligne](./mission-checklist.md)
- `see also` — [Gabarit de Mission](../../templates/mission-template.md)
- `applies` — Décision — Cohérence interne des Missions (historique de l'atelier, non distribué) (hors Vault)
- `applies` — [Relais entre rôles par mini-prompts à rubriques fixes](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `applies` — [Versionnement des Missions et outputs générés](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `applies` — [Décision — Statut de preuve et contrôle du STOP](../../decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
