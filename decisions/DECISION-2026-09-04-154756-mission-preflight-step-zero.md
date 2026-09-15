---
type: decision
title: "Étape 0 de pré-vol : tous les gardiens lancés sur le Périmètre avant le premier commit, toutes les violations rapportées en une fois"
description: "Décision arbitrée le 2026-09-04 après cinq fenêtres Executor pour une seule Mission : toute Mission qui commite un artefact déposé par le Pilot commence par une étape 0 qui lance les gardiens sur les fichiers du Périmètre et rapporte l'ensemble des violations avant tout commit ; le Pilot se relit contre les contrats de gardiens mesurés au rapport 132 avant de déposer ; et le gabarit de Mission reçoit les deux rubriques que les Décisions du jour exigent sans qu'il les porte."
created_at: "2026-09-04T15:47:56-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: mission-preflight, pilot-self-check, mission-template
---

# DÉCISION — ÉTAPE 0 DE PRÉ-VOL

## Date

2026-09-04

## Statut

`ARBITRATED`

Arbitrage Owner en clair, session Pilot du 2026-09-04, gate « go pour le step 0 ».

## Fait déclencheur

La Mission 134-A a demandé cinq fenêtres Executor : un STOP de précondition, puis deux refus de gardien portant tous deux sur le même fichier neuf déposé par le Pilot — une réciprocité de front-matter, puis un jeton de chemin nu. Les deux défauts étaient présents dès le dépôt. Les gardiens s'arrêtant au premier refus, ils ont été découverts l'un après l'autre, au prix d'un aller-retour complet chacun : fenêtre Executor, snippet Pilot, geste Owner.

Aucun contournement n'a été employé, et c'est le bon comportement. Le coût, lui, est évitable.

## Décision

1. **Étape 0 de pré-vol.** Toute Mission dont le Périmètre comprend le commit d'un artefact déposé par le Pilot commence par une étape 0 : lancer sur les fichiers du Périmètre tous les contrôles applicables, collecter **l'ensemble** des violations, les rapporter en une seule fois, et s'arrêter avant tout commit si l'une d'elles subsiste. Le pré-vol ne corrige rien : il mesure. Un défaut trouvé se corrige à sa source, par le rôle qui a écrit le fichier.

2. **Relecture du Pilot contre les contrats mesurés.** Avant de déposer un artefact, le Pilot se relit contre les contrats de gardiens établis par le rapport 132 : aucun jeton de chemin nu entre accents graves, accord entre les champs de front-matter et la section `## Liens`, ligne de manifeste prévue pour tout fichier neuf du Vault, nom canonique horodaté. Cette relecture est doctrinale : rien ne la mécanise, puisque rien ne lit le chat.

3. **Deux rubriques manquantes au gabarit de Mission.** Le gabarit reçoit la rubrique « Existant mesuré » qu'exige la Décision 121443 pour toute Mission créant un fichier, et l'étape 0 ci-dessus. Il reçoit également, dans son Périmètre par défaut, le fichier `superseded-files.txt` du dépôt concerné dès qu'une étape régénère un index : c'est une sortie garantie de l'outil d'indexation, jamais une exception (rapport 132, cas C4).

## Raison

- Un gardien qui s'arrête au premier refus est correct pour protéger le dépôt, mais coûteux pour corriger un fichier : il transforme *n* défauts en *n* allers-retours. Le pré-vol les transforme en un seul.
- Les contrats de gardiens n'étaient lisibles nulle part avant le rapport 132 : le Pilot écrivait à l'aveugle. Ils le sont désormais, donc la relecture devient possible — elle ne l'était pas la veille.
- Deux Décisions du 2026-09-04 prescrivent des rubriques que le gabarit ne porte pas. Une norme que son gabarit ignore ne s'applique qu'au souvenir de celui qui rédige.

## Impact

- `../templates/mission-template.md` reçoit trois ajouts — geste d'une Mission distincte, non de cette Décision.
- Les Missions existantes ne sont pas amendées rétroactivement.
- Le pré-vol ajoute une exécution de gardiens par Mission ; le chronométrage du rapport 132 la situe entre une et six secondes, sans effet sur le budget.
- Le point 2 est doctrinal et rejoint la checklist du skill d'écriture de Mission ; il dérivera si rien ne le rappelle, et c'est assumé.

## Alternatives importantes

- Faire rapporter à chaque gardien toutes ses violations au lieu de s'arrêter à la première : rejeté ici, cela modifie six scripts et change leur comportement ; le pré-vol obtient le même effet sans y toucher.
- Laisser le Pilot lancer lui-même les gardiens : impossible, le Pilot n'exécute rien.
- Ne rien changer et accepter les allers-retours : rejeté, cinq fenêtres pour quatre corrections de prose est un coût que la distribution à deux cents participants ne supporterait pas.

## Human gate

- Validation : accordée
- Référence : ordre Owner en clair, session Pilot du 2026-09-04, gate « go pour le step 0 »

## Artefacts liés

- Proposal source : aucune
- Mesure source : (historique de l'atelier, non distribué) (hors Vault)
- Fait déclencheur : (historique de l'atelier, non distribué) (hors Vault)

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `see also` — [Décision — Balayage d'existence, mémoire et hypothèses](./DECISION-2026-09-04-121443-existence-sweep-memory-hypothesis-measured-existing.md)
- `see also` — [Décision — Amendement de deux normes gravées](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)
- `see also` — [Gabarit de Mission](../templates/mission-template.md)
- `see also` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
