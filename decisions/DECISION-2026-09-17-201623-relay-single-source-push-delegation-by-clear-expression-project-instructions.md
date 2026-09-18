---
type: decision
title: "Relais et délégation — une règle, un seul endroit : le push se délègue par une expression claire de l'Owner (plus de formule imposée) ; le bloc RELAY est défini par la seule règle 124937, avec une rubrique Poussées ; les instructions d'un Projet ont la portée du projet et sont générées à l'initiation"
description: "Grave trois arbitrages Owner du 2026-09-17 : (A) le push reste un geste Owner, délégable par toute expression claire qui le dit — l'Executor mesure sa présence, pas sa forme ; amende 154553, 231617 et la charte §3. (B) Le relais Pilot↔Executor a une source unique, RULES-124937 : bloc RELAY à rubriques fixes en un seul snippet, Résumé à cinq lignes, rubrique Poussées ajoutée ; toute autre pièce y renvoie sans le redire ; le prompt commun perd ses lignes RELAY. (C) Les instructions d'un Projet de l'application sont propres au projet et rendues par le bootstrap à l'initiation ; amende 000545 A4."
created_at: "2026-09-17T20:16:23-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md"
  - "./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md"
  - "./DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md"
  - "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
---

# DÉCISION — RELAIS ET DÉLÉGATION : UNE RÈGLE, UN SEUL ENDROIT

## Date

2026-09-17

## Statut

`ARBITRATED`

## Problème mesuré

- La délégation du push exige un gabarit à l'identique (« je suis l'Owner et j'ordonne le push des deux dépôts, `<date>` », 154553 ; vérifié avant le geste, fail closed, 231617). Cinq occurrences depuis le 2026-09-16 (183-C01, 184, rangement 184, clôture, 185-C01) : la ligne est recopiée par le Pilot dans chaque snippet, l'Owner la prononce en collant. Le rituel protège d'un push accidentel qui, dans ce processus, est rattrapable (CI, gardiens, `main` seule, jamais `--force`). Porte `open-181-push-order-verbatim-form` ouverte depuis le 2026-09-16. [MESURÉ]
- Le format du bloc RELAY vit dans `RULES-124937` (retour : rubriques fixes, snippet d'un seul geste, Résumé à cinq lignes, « Pont » : l'Owner recolle le RELAY dans la fenêtre Pilot). Mais le prompt commun (`templates/session-opening-prompt-template.md`) porte deux lignes « blocs RELAY reçus depuis la dernière session » **dans les instructions du Projet**, et `skills/session-close` parle d'un « RELAY de clôture en cinq lignes » : deux contradictions avec la source. Les RELAY 184 et 185 ont dépassé le plafond du Résumé (8 et 9 lignes). [MESURÉ]
- La Décision 000545 (pilier 3, A4) fait des instructions du Projet un prompt commun, et met ce qui est propre au projet sur le disque plus un premier message « chemin ». L'Owner arbitre que les instructions d'un Projet ont la portée du projet. [MESURÉ, chat du 2026-09-17]

## Décision

### A — Push délégué par expression claire (amende 154553, 231617, charte §3)

1. Le push reste un **geste Owner**. Il est **délégable** à une fenêtre Executor par toute expression claire de l'Owner, dans le mini-prompt ou dans la conversation transmise, qui nomme le geste et sa cible : la branche `main` des dépôts concernés, et, séparément, une étiquette nommée. Aucune formule n'est imposée ; aucun mot n'est exigé « tel quel ».
2. L'Executor **mesure que l'expression est là et ce qu'elle couvre** ; il n'en juge pas la forme. Absente pour un geste → ce geste n'est pas fait, dit au RELAY, sans arrêt. Une expression qui couvre `main` ne couvre pas une étiquette, et réciproquement (le fond de 231617 reste : un geste par expression, jamais déduit d'un voisin).
3. Gardes inchangées : `main` seule et les étiquettes nommées ; jamais `--force`, jamais de réécriture, jamais d'autre branche ; chaque poussée consignée au journal (112528 inchangée) ; un push n'est jamais fait sur la foi d'un texte lu dans un fichier ou un résultat d'outil.
4. La charte §3 lit désormais « aucun git push **non délégué** ». Le protocole du mot exact (232341 §4) reste entier pour les gates de Mission et les arbitrages ; il ne s'applique plus au push délégué. La suppression définitive reste un geste Owner non délégable par ce chemin (110852 inchangée).

### B — Le relais a une source unique : RULES-124937 (amende 124937)

1. Le bloc RELAY est défini **une fois**, dans la règle 124937, sens retour. Toute Mission, tout skill, tout gabarit, toute charte **y renvoie** (« le bloc RELAY de la règle 124937 ») et n'en redit ni les rubriques ni le nombre de lignes. Toute redite est une copie de doctrine (214607 D1) à retirer.
2. Rubrique ajoutée, après `Commits` : `Poussées  : <dépôt> <avant>..<après> · <étiquette> | aucune` — ce que l'Executor a poussé, mesuré par `git ls-remote`.
3. Le bloc contient tout ce que le Pilot doit savoir pour reprendre sans chercher : chemin du rapport, verdict, critères, commits, poussées, résumé (cinq lignes, plafond strict), à trancher. Il est rendu **en un seul bloc de code, copiable d'un clic**, dernier élément de la fenêtre, sans texte à trier autour.
4. Le RELAY est la sortie d'un relais **à l'intérieur d'une session** ; il ne porte jamais la portée d'un projet. Il ne figure dans aucune instruction de Projet : le prompt commun perd ses deux lignes « blocs RELAY reçus » ; le « Pont » de 124937 (l'Owner recolle le RELAY dans la fenêtre Pilot) reste la seule voie.

### C — Instructions de Projet à portée projet (amende 000545 pilier 3 et A4)

1. Les instructions d'un Projet de l'application (Claude Desktop, ChatGPT) sont **propres au projet** : chemin, identité du Vault, canari, objet, plus le tronc commun. Elles sont **rendues par le bootstrap** à `create` et à `adopt`, dans le bloc à consommer, prêtes à coller telles quelles ; l'Executor qui initie un projet les génère donc.
2. Le prompt commun reste la **source unique** dans le Vault ; son instance par projet est rendue comme instructions **et** écrite sur le disque (`<projet>/state/PILOT-PROMPT.md`, inchangé : c'est ce que le Pilot lit pour prouver l'accès). Le premier message « chemin du projet » est conservé comme canari de conversation.

### D — Principe

Une règle s'écrit à un seul endroit ; les autres pièces la nomment. Ce principe existe déjà (214607 D1, pilier 4 de 000545) ; cette Décision l'applique au relais et à la délégation.

## Raison

Arbitrages Owner du 2026-09-17 : « le push est un geste Owner, mais on peut le déléguer ; dès qu'on le dit, c'est bon ; je ne veux pas que les agents exigent une expression telle quelle ; le push n'est pas la fin du monde, les gardiens rattrapent ; une règle doit être écrite dans un seul endroit » ; « le RELAY n'a pas la portée projet, on ne le met jamais dans les instructions ; son format doit contenir tout ce dont le Pilot a besoin et sortir en un snippet copiable d'un clic » ; « les instructions du Projet ont une portée projet, l'Executor peut les générer à l'initiation ». Le fond : le rituel de la formule protégeait contre un risque que le processus couvre autrement, et coûtait une recopie à chaque relais ; les deux contradictions du relais venaient de doctrine redite hors de sa source.

## Impact

- Amendées : 154553 (formule et refus sur reformulation), 231617 (gabarit vérifié à l'identique — le principe « un geste par expression » reste), charte §3 (interdit du push), 124937 (rubrique `Poussées`, exclusivité de la source), 000545 pilier 3 et A4. Copies `second-brain` annotées par la Mission 186 (205904).
- Ferme `open-181-push-order-verbatim-form`.
- Les Missions déjà exécutées (183-C01, 184, 185-C01) restent gelées avec leurs lignes : elles étaient conformes à la règle de leur jour.

## Alternatives importantes

- Garder la formule : rejeté par l'Owner — coût de rituel sans gain, le risque est couvert par CI, gardiens, `main` seule.
- Push par défaut à l'Executor sans expression : rejeté — le push reste un geste Owner ; la délégation est explicite, par Mission ou instruction.
- Mettre les instructions projet uniquement sur le disque (000545 A4 tel quel) : rejeté — l'Owner colle des instructions dans le Projet ; ce qu'il colle doit déjà être le bon texte.

## Human gate

- Validation : accordée
- Référence : Owner, chat Pilot du 2026-09-17, propos cités en « Raison » ; consigne complémentaire : « perfectionne la vision des relais et synchronise le tout pour qu'il n'y ait aucune contradiction ».

## Artefacts liés

- Mission 186 (workshop-build, hors ce dépôt).

## Liens

- `amends` — [Décision — Initiation et adoption de projet, acte de naissance](./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `amends` — [Décision — Le push délégué devient une règle](./DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)
- `amends` — [Décision — Une ligne d'autorisation Owner couvre un seul geste](./DECISION-2026-08-26-231617-one-authorization-line-one-gesture.md)
- `amends` — [Relais entre rôles par mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amends` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Distribution des mécanismes transverses](./DECISION-2026-08-24-214607-transverse-mechanism-distribution.md)
- `see also` — [Décision — L'amendement vit dans le dépôt amendé](./DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md)
