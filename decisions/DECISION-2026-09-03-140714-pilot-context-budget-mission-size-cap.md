---
type: decision
title: "Budget de contexte du Pilot : plafond de taille des Missions sur distribution mesurée, ordre d'ouverture digest → handoff → refs, dryRun comme mesure, snippet émis une fois"
description: "Décision arbitrée le 2026-09-03 (gate « plafonne ») : un plafond fail-closed sur la taille des fichiers MISSION dont la valeur ne sera fixée qu'après mesure de la distribution existante ; quatre règles doctrinales de parcimonie côté Pilot ; une HYPOTHÈSE nommée sur le préfixe fixe de conversation et sa seule mesure possible."
created_at: "2026-09-03T14:07:14-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: pilot-context-budget, mission-size-cap, session-opening
---

# DÉCISION — BUDGET DE CONTEXTE DU PILOT

## Date

2026-09-03

## Statut

`ARBITRATED`

## Décision

1. **Plafond de taille des Missions — conditionnel.** Un plafond fail-closed sur la taille en octets de tout fichier de Mission (préfixe MISSION-) sera installé par gardien, sur le modèle du plafond du digest (Mission 121 : constante, fail-closed, non contournable) et avec base non rétroactive (Mission 123). **Sa valeur n'est pas fixée ici.** Précondition, geste Executor prescrit par Mission de mesure : taille de chaque fichier de Mission (préfixe MISSION-) des deux dépôts, médiane, maximum, les cinq plus grosses nommées avec leur taille ; tableau collé au rapport. L'Owner tranche la valeur sur ce tableau. Ce qui réfuterait le point : une distribution où le plafond utile écarterait la majorité des Missions existantes — le gardien serait alors remplacé par un simple avertissement. La taille d'une Mission particulière (dont la Mission 131, 15 509 octets) n'est jamais un argument pour la valeur.
2. **Ordre d'ouverture Pilot : (historique de l'atelier, non distribué) d'abord, puis le handoff qu'il nomme, puis les refs Git.** Le digest porte le test de fraîcheur (Mission 121) ; il nomme le dernier handoff, ce qui supprime le listing du dossier `handoffs/`. Amende l'ordre 1–2 de `vault/skills/session-start/reading-list.md` (Mission 121) sans changer les trois lectures.
3. **`dryRun` est une mesure au sens de la Décision 212009.** L'artefact propre du Pilot — déposé dans la session, présent dans le contexte — n'est jamais relu en entier pour être corrigé. Sa vérification se fait par `edit_file` en `dryRun` (l'échec sur chaîne absente est la mesure ; le diff rendu est la preuve), par `head` ou par `tail`. Relire en entier ce que l'on vient d'écrire est une lecture de confort au sens de la charte §2 « Lecture ».
4. **Le snippet est émis une fois.** Toute reprise d'un mini-prompt déjà émis dit « snippet inchangé » et ne le recopie pas ; s'il change, seule la rubrique modifiée est réémise, nommée. Vaut pour le Pilot ; l'Owner colle les blocs RELAY une fois.
5. **Découverte d'outils et rappel mémoire bornés.** Une seule recherche d'outils par famille, par le nom exact de l'outil ; `recall` Mnemosyne en `limit 3` par défaut.

**Amendé le 2026-09-04** par la [Décision 145256](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md) : la recherche d'outils se formule sur la description de l'outil, l'index portant les descriptions et non les noms ; une seconde recherche est permise et comptée au budget. Texte appliqué : [reading-list](../skills/session-start/reading-list.md).
6. **HYPOTHÈSE nommée — préfixe fixe de conversation.** Le préfixe présent à chaque tour (instructions du Projet, mémoire, schémas d'outils chargés, skills) serait le premier poste de dépense d'une session Pilot, et il grossit à chaque `tool_search` : un schéma chargé est payé à chaque tour suivant, non une fois. Aucun outil du Vault ne le mesure. **Seule mesure possible** : en fin de session, le Pilot compte les `tool_search` joués et les schémas chargés (nombre, familles), et les consigne dans la rubrique « Ouverture / budget » du handoff — rubrique elle-même à créer (tableau des manques de la 128). Trois sessions comptées avant toute conclusion, comme pour l'observation Mnemosyne.

## Raison

Session Pilot du 2026-09-03 : une ouverture et une micro-Mission ont consommé, selon l'interface, ~70 % d'une conversation. Relevé des appels (estimé, tour d'audit) : ~130 Ko d'appels et de prose, dont le cycle de vie d'une seule Mission ≈ 48 Ko — écrite (15,5 Ko), relue entière (15,5 Ko), rééditée (17 Ko d'entrée et de diff) —, ~10 Ko de découverte d'outils en six recherches, un snippet émis deux fois. Le reste du 70 % n'est couvert par aucun relevé : c'est le préfixe fixe, d'où le point 6.

Le précédent tient en deux paires : 120 → 121 (mesurer la boucle d'état — 55 969 octets prescrits à l'ouverture — puis plafonner : digest 2 220 / 8 000 octets, fail-closed) et 118 lot 8 → 127 (chronométrer les gardiens — 110 s, deux gardiens = 99 % — puis optimiser à sortie byte-identique : 3,21 s). Dans les deux cas la première hypothèse de cause était incomplète ou fausse (127 : le fork par fichier pesait 0,42 s), et seule la mesure a tranché. Le point 1 respecte cet ordre ; fixer la valeur du plafond aujourd'hui, sur la taille d'une Mission sous les yeux, serait un raisonnement à l'envers.

Côté chat, la longueur **est** le coût : un octet lu ou écrit est payé jusqu'à la fin de la conversation. Côté scripts, elle ne l'est pas (127). Cette Décision ne touche donc que le poste Pilot ; les scripts hors gardiens restent non mesurés et relèvent d'une Mission de mesure distincte, après la 128, avant la 129.

## Impact

- Une Mission de mesure (lecture seule, rapport seul) précède le gardien du point 1 ; le gardien vient ensuite par Mission, avec le cycle deux pushes.
- `vault/skills/session-start/reading-list.md` (section Pilot) reçoit les points 2, 3, 4 et 5 — par amendement de la Mission 131, déjà ouverte sur ce fichier et non lancée.
- La checklist `écriture-de-mission` reçoit : « artefact propre relu en entier », « snippet réémis », « recherche d'outils par tâtonnement ».
- Le gabarit de handoff reçoit une rubrique « Ouverture / budget » (octets lus, appels, `tool_search` joués, schémas chargés) — au tableau des manques de la 128, vérifiable par gardien de format.

## Alternatives importantes

- Fixer la valeur du plafond maintenant (10 000 ou 16 000 octets) : écartée — valeur sans distribution mesurée, précédent 127 contre.
- Compteur de lectures par document : écarté — non mécanisable côté Pilot (le serveur MCP ne journalise rien), redondant côté Executor (les rapports collent les commandes).
- Tailler dans les gardiens : écartée — chaîne à 3,21 s depuis 127, coût nul mesuré.
- Proposal avant Décision : écarté — rien n'est coupé ici ; le proposal viendra s'il y a quelque chose à couper, après mesure.

## Human gate

- Validation : accordée
- Référence : gate « plafonne », Owner, 2026-09-03, en chat, « sous la condition 1 » (valeur du plafond sur distribution mesurée, précondition de la Décision, non hypothèse).

## Artefacts liés

- Mission ouverte sur `vault/skills/session-start/reading-list.md` : (historique de l'atelier, non distribué)
- Mesures citées : (historique de l'atelier, non distribué), (historique de l'atelier, non distribué), (historique de l'atelier, non distribué), (historique de l'atelier, non distribué)

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `applies` — [Décision — Statut de preuve et contrôle d'arrêt](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Liste de lecture d'ouverture de session, par rôle](../skills/session-start/reading-list.md)
- `see also` — Mission 131 — alignement du protocole d'ouverture Pilot (historique de l'atelier, non distribué) (hors Vault)
- `amended by` — [Décision — Amendement de deux normes gravées](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)
