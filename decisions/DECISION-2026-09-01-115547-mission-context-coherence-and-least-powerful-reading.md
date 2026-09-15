---
type: decision
title: "Cohérence interne des Missions — section Contexte obligatoire, relecture croisée avant dépôt, mini-prompt sans interdit propre, lecture la moins puissante à l'exécution"
description: "Grave quatre règles d'écriture et de consommation des Missions après trois contradictions internes attrapées à l'exécution (Mission 090, Mission 108 deux fois) qu'aucun gardien ne peut voir : une section Contexte obligatoire au contenu fixé, une relecture croisée Validations ↔ Interdits ↔ Étapes tracée avant dépôt, un mini-prompt qui ne porte aucun interdit propre à la Mission, et la règle d'exécution selon laquelle l'Executor retient la lecture la moins puissante d'une contradiction et la remonte. Ferme la porte open-mission-internal-coherence par sa propre condition (« une règle écrite »)."
created_at: "2026-09-01T11:55:47-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-09-01-115547-mission-context-coherence-and-least-powerful-reading.md"
---

# DÉCISION — COHÉRENCE INTERNE DES MISSIONS

## Date

2026-09-01

## Statut

`ARBITRATED` — mot exact « graver », Owner, 2026-09-01, dans la fenêtre Pilot, après recommandation unique.

## Décision

Quatre règles, applicables à toute Mission écrite ou exécutée à partir de ce jour, dans le Vault comme dans tout projet.

**1. La section `## Contexte` est obligatoire dans une Mission**, placée entre le rappel de statut et `## Objectif`. Elle contient, dans cet ordre et sans exception : les faits mesurés qui motivent la Mission, chacun avec sa date et son mode de mesure (`MESURÉ`, `DECLARED`, `HYPOTHÈSE`) ; ce que l'Executor va trouver sur disque et pourquoi c'est là ; les pièges connus (précédents, défauts d'outil, emplacements trompeurs) ; et pourquoi la décision qui autorise la Mission est ce qu'elle est. Une Mission sans contexte oblige l'Executor à reconstituer l'histoire — ou à l'ignorer, ce qui revient à décider l'architecture à sa place.

**2. Avant dépôt, le Pilot fait une relecture croisée** de trois rubriques deux à deux : chaque critère de `## Validations` doit être atteignable sans violer un interdit de `## Gates` ou de `## Contraintes`, et chaque étape de `## Étapes` doit être permise par les mêmes interdits. La relecture est tracée par un commentaire HTML en tête de `## Validations` (« Relecture croisée faite par le Pilot avant dépôt : … »). Un compte de Validations que les Interdits rendent impossible est une faute de rédaction du Pilot, pas un cas à arbitrer par l'Executor.

**3. Le mini-prompt Executor ne porte aucun interdit propre à la Mission.** Sa rubrique 4 (`RULES-2026-08-23-124937`) se limite aux quatre interdits standards — aucun push, aucun appel modèle, aucune suppression, déplacement vers `_trash/` seulement sur prescription de la Mission — plus un renvoi explicite aux rubriques `## Gates` et `## Contraintes` de la Mission comme seule liste d'interdits propres. Une Mission a une seule source de gates ; un interdit ajouté dans le mini-prompt est un second texte normatif, invisible à la relecture du point 2, et c'est ainsi que la Mission 108 s'est contredite.

**4. À l'exécution, une contradiction interne se résout par la lecture la moins puissante.** Quand deux rubriques d'une Mission se contredisent, l'Executor retient l'interprétation qui écrit le moins, ne supprime rien et ne modifie aucun fichier hors du périmètre le plus étroit ; il consigne la contradiction et sa résolution dans la rubrique « Écarts » du rapport et dans le `Résumé` du RELAY. Il ne s'arrête pas pour cela (ce n'est pas un STOP de précondition), sauf si aucune lecture n'est inoffensive. C'est le miroir, pour les Missions, de la règle de la charte pour les rôles : l'erreur doit tomber du côté inoffensif.

## Raison

Trois contradictions internes en trois Missions, toutes du même type — une rubrique demande ce qu'une autre interdit :

- Mission 090 (2026-08-29) : la rubrique Portes prescrivait un verbatim que la rubrique Validations comptait à zéro. Attrapée à l'exécution ; porte `open-mission-internal-coherence` ouverte avec pour condition de fermeture « une règle écrite ou le futur skill d'écriture de Mission ».
- Mission 108 (2026-09-01), première contradiction : Validations exigeait `vault-source-sha256 = e23edad2…(historique de l'atelier, non distribué)superseded-files.txt`, que l'Executor a rangé parmi les résidus. La contradiction n'était pas dans la Mission : elle était entre la Mission et un texte que personne ne relit.

Aucun gardien ne peut voir ces fautes : elles portent sur le sens, pas sur la forme. Les deux fois où la Mission 108 s'est contredite, l'Executor a pris la lecture la moins puissante, l'a dit au RELAY et n'a rien cassé — un réflexe qui n'était écrit nulle part et qui a tenu à la doctrine seule. Une constante mesurée du Vault (audit 057, DECISION-153503) : ce qui tient à la doctrine seule dérive ; ce qui est écrit puis mécanisé tient. La règle est donc gravée maintenant, et le mécanisme — le skill d'écriture de Mission, désigné par la preuve mesurée comme le plus rentable (handoff 2026-09-01 §3) — en héritera à sa fabrication.

## Impact

- Le gabarit `vault/templates/mission-template.md` est amendé (Mission 111) : section `## Contexte` ajoutée avec son commentaire de consigne ; commentaire de relecture croisée ajouté en tête de `## Validations`.
- `RULES-2026-08-23-124937` rubrique 4 est amendée par cette Décision (réciproque `amended by` posée dans le Vault, Mission 111) : quatre interdits standards plus renvoi aux Gates, rien d'autre.
- La charte (`RULES-2026-08-23-224706` §3, rôle Executor) reçoit une réciproque `amended by` pour le point 4 : l'Executor ne corrige jamais en silence — il ne « corrige » pas non plus une contradiction en choisissant la lecture la plus large.
- Les Missions 109 et 110 (déposées le 2026-09-01 avant cette Décision) appliquent déjà les points 1 à 3 ; elles ne sont pas retouchées (gel, DECISION-013217).
- Porte `open-mission-internal-coherence` : close par cette Décision, condition « une règle écrite » satisfaite. La ligne `CLOSE:` est écrite par la Mission 111.
- Chantier skills V1 (point 3 de la file) : le skill d'écriture de Mission gagne un argument de plus pour l'ordre de fabrication ; cette Décision devient une de ses sources. Rien n'est tranché ici sur cet ordre.
- Coût : une Mission courte (111), aucun cycle push/ré-épingle (gabarit et règle ne sont pas des hooks).

## Alternatives importantes

- **Ne rien graver, laisser le skill d'écriture de Mission porter ces règles.** Rejetée : le skill n'existe pas, son ordre de fabrication n'est pas tranché, et la faute s'est rejouée deux fois en trois jours depuis l'ouverture de la porte. Le skill héritera de la Décision ; l'inverse aurait laissé trois sessions de plus sans règle.
- **Noter en capture à la clôture seulement.** Rejetée : une capture n'est jamais une norme ; la porte resterait ouverte avec sa condition non remplie.
- **Un gardien de cohérence.** Rejetée comme irréalisable : la contradiction est sémantique ; le seul mécanisme possible est le skill qui écrit la Mission, pas un contrôle qui la lit.
- **Autoriser l'Executor à s'arrêter (STOP) sur contradiction.** Maintenue ouverte comme variante du point 4 : le STOP coûte une fenêtre entière pour un cas que la lecture la moins puissante règle sans dommage. Réservé au cas où aucune lecture n'est inoffensive.

## Human gate

- Validation : accordée — « graver », Owner, 2026-09-01.
- Référence : cette fenêtre Pilot (recommandation unique, mot exact embarqué, réponse d'un mot).

## Artefacts liés

- Source : `../reports/REPORT-2026-09-01-111007-108-skills-library-update-from-package.md` (§6, les deux contradictions et leur résolution)
- Source : `../missions/MISSION-2026-09-01-105013-108-skills-library-update-from-package.md` (Mission contradictoire, gelée, non retouchée)
- Exécution : Mission 111 (gabarit, réciproques, ligne `CLOSE:`)

## Liens

- `prescribed by` — [Gabarit de décision](../../../vault/templates/decision-template.md) (hors Vault)
- `amends` — [Relais entre rôles par mini-prompts à rubriques fixes](../../../vault/rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md) (hors Vault)
- `amends` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `amends` — [Gabarit de Mission](../../../vault/templates/mission-template.md) (hors Vault)
- `see also` — Décision — Hygiène des portes, treize arbitrages (historique de l'atelier, non distribué)
- `see also` — Décision — Le code n'est jamais une norme (historique de l'atelier, non distribué)
- `see also` — Rapport 108 — mise à jour de la bibliothèque de skills (historique de l'atelier, non distribué)
