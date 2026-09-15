---
title: "Liste de lecture d'ouverture de session, par rôle"
description: "Source unique du protocole d'ouverture lu par le skill session-start : les lectures de chaque rôle, dans l'ordre, avec la raison d'une ligne. C'est ce fichier qu'on amende quand le protocole change — le corps du skill ne bouge pas. Chaîne amended by suivie par le skill."
created_at: "2026-09-01T15:30:00-04:00"
timezone: America/Montreal
status: active
amends:
  - "../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
---

# LISTE DE LECTURE D'OUVERTURE — PAR RÔLE

Lue par le skill `session-start` (étape 2). Une lecture par ligne, dans l'ordre. Ce qui a déjà été lu par le prompt d'ouverture de l'Owner n'est pas relu : vérifié, complété seulement.

## Pilot

**La première ligne de prose de la première réponse est le verdict** : `READY` ou `NOT-READY (<motif>)`. Rien avant. Une anomalie trouvée pendant l'ouverture est le **motif** du `NOT-READY`, jamais un paragraphe avant lui (Mission 154, fautes mesurées au rapport 153 : cas 1 et cas 5).

Chaîne de pointeurs, dans cet ordre, chaque maillon nommant le suivant, aucun tenu de mémoire : instructions du Projet (hors dépôt, geste Owner) → charte `rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md` du Vault → ce fichier → digest → handoff → refs.

Lecture d'ouverture réduite au digest plafonné (Mission 121), budget aligné sur la chaîne d'entrée (Mission 136) : **huit appels filesystem** avant le verdict READY/NOT-READY quand le digest est frais, **dix au pire**, comptés un à un — (1) répertoires autorisés du serveur MCP, (2) `VAULT-ROOT.md` à la racine, (3) `CLAUDE.md` du Vault, (4) la charte, (5) ce fichier et le digest en un seul `read_multiple_files`, (6) le canari (un `get_file_info` sur le digest), (7) la mesure de fraîcheur (un `get_file_info` sur `state/journal.md`), (8) le handoff que le digest nomme et les quatre refs Git plus les deux `packed-refs` (six chemins) en un seul `read_multiple_files` — l'ordre digest → handoff → refs de la Décision 140714 point 2 est conservé ; un neuvième appel — le journal en `tail 5` — seulement si le digest est périmé, un dixième — `tail 30` — seulement si les cinq lignes ne suffisent pas (voir le test de fraîcheur) ; rien d'autre. Ce que le prompt d'ouverture a déjà fait lire compte dans les huit et n'est pas relu. Les recherches d'outils se comptent à part (Décision 145256). Le verdict est la **première ligne de prose** de la réponse d'ouverture, mot exact `READY` ou `NOT-READY (<motif mesuré>)` ; l'annonce `[role: …]` suit. Après l'état, la rubrique « Ouverture / budget » (Décision 140714, point 6) : appels d'outil comptés un à un ; octets rapportés — seul `get_file_info` rend une taille, donc le digest (canari) et le journal (mesure de fraîcheur) portent la leur, les autres lectures sont listées par nom avec la mention « taille non rapportée », jamais estimées ; recherches d'outils jouées et schémas chargés. Toute valeur d'état rapportée porte son statut : `VERIFIED` (lue sur disque dans cette session, source nommée), `DECLARED` (recopiée du digest ou du handoff, avec l'horodatage de la source), `ANOMALY` (désaccord entre deux sources, nommé tel quel).

1. `<projet>/state/DIGEST.md`, entier — digest d'ouverture plafonné, généré par `tools/build-digest.sh` du Vault (8 000 octets, fail-closed). **`<projet>` est nommé par les instructions de Projet** — premier maillon de la chaîne ci-dessus — et ne se cherche jamais : aucun `search_files` d'exploration pour localiser un digest. Si rien ne nomme le projet, le verdict est `NOT-READY (projet non nommé)`, pas une fouille (Mission 156, seul appel hors liste mesuré au tir 155 du cas 1). **Test de fraîcheur** (Mission 119, transposé au digest par la Mission 121, rendu mesurable sans lecture par la Mission 136) : un `get_file_info` sur `state/journal.md` rend son horodatage de dernière modification ; s'il est **postérieur** à la ligne « Dernière entrée journal : \<horodatage\> » du digest, le digest est périmé ; égal ou antérieur, il est frais. Mesure de référence (2026-09-04) : modification 16:16:19 = dernière ligne datée 16:16:19, digest 16:11:47 — périmé d'une ligne, celle du push délégué, qui est le cas ordinaire après toute clôture poussée. Un checkout ou un clone récent peut rendre un « périmé » à tort (horodatage de fichier réinitialisé) ; jamais un « frais » à tort — le sens de l'erreur est sûr. S'il est périmé : le dire tel quel dans l'état en cinq lignes, lire le journal en `tail 5` à sa place (lignes plafonnées à 300 caractères depuis la Mission 123), `tail 30` seulement si la plus ancienne des cinq est encore postérieure à la ligne du digest, et ne pas le régénérer soi-même — la régénération (`tools/build-digest.sh <projet>` du Vault, argument = dossier du projet) est un geste Executor prescrit par Mission. Le verdict READY/NOT-READY ne dépend pas de la fraîcheur.
2. Le dernier handoff de `<projet>/handoffs/`, celui que le digest nomme en « Dernier handoff » (ou que le prompt d'ouverture nomme), entier — la file de reprise.
3. Refs Git des deux dépôts (`.git/refs/heads/main`, `.git/refs/remotes/origin/main`) et `.git/packed-refs` des deux dépôts, six chemins dans le même `read_multiple_files` que le handoff — l'écart entre le disque et l'attendu. Une ref dont le fichier `refs/…` est absent n'est pas une anomalie : Git l'a compactée ; sa valeur est le SHA de la ligne de `packed-refs` dont le nom se termine par cette ref ; si le fichier `refs/…` existe, il prime (plus récent). Une ref introuvable dans les deux sources porte `ANOMALY`. Chaque ref porte `VERIFIED` ; une ref recopiée du digest faute de lecture porte `DECLARED`. Refs et digest en désaccord = `ANOMALY` nommée — un commit de clôture postérieur au digest est le cas ordinaire, à dire tel quel. L'arbre de travail (`git status --porcelain`) n'est jamais mesurable depuis la surface Pilot : toujours `DECLARED`, valeur et horodatage du digest, jamais « propre » déduit de l'égalité des refs.

Un index se lit par `tail` ou par recherche d'une ligne, jamais en entier ; le digest d'ouverture reste la seule lecture entière prescrite (Décision 124647, point 6). Un dossier volumineux porte un `index.md` vivant et des `index-archive-*.md` figés : l'archive ne se lit que sur demande.

Parcimonie (Décision 140714) : l'artefact propre du Pilot — déposé dans la session, présent dans le contexte — n'est jamais relu en entier ; `edit_file` en `dryRun` est une mesure au sens de la Décision 212009 (l'échec sur chaîne absente est la mesure, le diff est la preuve), `head` ou `tail` sinon. Un mini-prompt est émis une fois : toute reprise dit « snippet inchangé » ou réémet la seule rubrique modifiée, nommée. Une recherche d'outils par famille, formulée sur la description de l'outil (verbe et objet : « search memories », « write file ») — l'index de recherche porte les descriptions, pas les noms (mesure 132-A) ; une seconde recherche est permise, et comptée au budget, si la première ne remonte pas l'outil visé.

### Mémoire — la seule source d'état est le journal

Aucune banque mémoire externe n'est câblée dans cet AIOS (Décision 113850, retrait mesuré à la Mission 147). Toute écriture d'état passe par le journal (`append-journal.sh`, Executor) — la mémoire d'un modèle n'est jamais une source d'état.

### Avant tout dépôt

Avant d'écrire une Mission : ouvrir le skill `ecriture-de-mission` et jouer `mission-checklist.md`, ligne par ligne, avant tout dépôt. Déposer par le patron DRAFT (`ecriture-de-mission/SKILL.md` §6) : jamais un fichier `MISSION-…` écrit directement. Aucun mini-prompt n'est émis sans que la liste ait été jouée (Mission 151).

Avant toute recherche de fichier ou de terme dans le Vault : le skill `recherche-interne`. (Mission 152, ANOMALY 1 du rapport 151.)

## Executor

0. Le skill `session-start` couvre aussi cette surface : les trois points suivants sont son protocole d'ouverture Executor (Mission 151). Budget d'appels : **12** ici, contre 8 en session de chat — la sonde de rôle et le shell en coûtent (Mission 154).
1. Conscience de position : répertoire courant, dépôt, chemins relatifs vers la racine du Vault (marqueur `VAULT-ROOT.md`, jamais un dossier nommé `vault` en dur) et vers le dépôt du projet (Décision 213150) — avant toute lecture.
2. La Mission nommée par le mini-prompt reçu, intégralement, section Contexte comprise — c'est la seule source d'instructions.
3. `git status -sb` des deux dépôts — l'écart entre le disque et l'attendu de la Mission.

## Liens

- `see also` — [Charte des rôles et détermination de session](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `amends` — [Charte des rôles et détermination de session](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
