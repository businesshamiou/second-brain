---
name: session-start
description: "Open a work session: read the state files in order (Pilot: digest, handoff, Git refs; Executor: also repo and guardian state), and announce role and readiness. Use at the start of any session, or when asked to (re)open, resume, or check readiness. Triggers on: « nouvelle session », « nouvelle session pilote », « ouvre la session », « ouverture », « open the session »."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), (historique de l'atelier, non distribué), rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
  vault-validated: "2026-09-07T21:32:10-04:00"
---

Ouvre une session de travail : mesure l'état du poste, lis les fichiers d'état dans l'ordre, annonce le rôle et le verdict de préparation. Ce skill est **en lecture seule** : il ne dépose rien, ne commite rien, ne déplace rien — jamais, sur aucune surface. Seule exception : un ordre d'initiation reçu, qu'il fait exécuter par `tools/project-bootstrap.sh --order` (§1 bis) ; l'écriture appartient alors au bootstrap, bornée au dossier cible et au registre du Vault. Il complète le prompt d'ouverture de l'Owner, il ne le remplace pas : ce que le prompt a déjà fait lire, ne le relis pas — vérifie que c'est fait et comble les manques seulement.

## 1. Détermine ta surface, mécaniquement

Tente un geste shell inoffensif (`git --version`). Il répond → branche **Executor**. Pas de shell (chat, MCP seul) → branche **Pilot**. La capacité mesurée décide ; ne te déclare jamais un rôle que tu n'as pas mesuré.

## 1 bis. Le dossier est-il adopté ?

**Executor** : remonte depuis le dossier courant jusqu'à un acte de naissance (`.pre-commit-config.yaml` dont la première ligne est `# second-brain-birth-certificate: v1`) ; `bash <Vault>/tools/resolve-vault.sh <dossier>` rend le Vault ou un refus nommé.

- **Acte trouvé** : continue.
- **Pas d'acte, mais un ordre d'initiation reçu** (mini-prompt de type `initiation`) : écris l'ordre dans un fichier temporaire, lance `bash <Vault>/tools/project-bootstrap.sh --order <fichier>`, relaie sa sortie (dont le bloc à consommer), puis continue l'ouverture sur le projet adopté.
- **Ni acte ni ordre** : ne l'adopte pas. Lance `bash <Vault>/tools/project-bootstrap.sh order <dossier>`, rends l'ordre à remplir tel qu'il sort, et arrête-toi : `NOT-READY (dossier non adopté, ordre d'initiation rendu)`.

**Pilot** : le serveur MCP d'abord — `list_allowed_directories` doit contenir le chemin du projet donné au premier message ; puis `<projet>/state/PILOT-PROMPT.md` du projet, dont tu rends le canari. Sans ce fichier, le projet n'est pas adopté : propose l'ordre d'initiation (gabarit `templates/initiation-order-template.md`), n'en présume rien.

## 2. Lis la liste de lecture de ton rôle

Ouvre `reading-list.md` dans le dossier de ce skill et exécute les lectures de ta section, dans son ordre. Si ce fichier porte une ligne `amended by`, lis aussi l'amendement et applique-le : c'est lui la source du protocole d'ouverture, pas ce corps.

## 3. Mesure le canari de ta branche

**Pilot** : la racine MCP répond (un `get_file_info` sur `<projet>/state/DIGEST.md` (forme de référence : depuis la racine du workspace)) ; le digest est lisible, passe le test de fraîcheur de `reading-list.md` et nomme le dernier handoff ; ce handoff existe, est lisible et daté ; les quatre refs Git sont lisibles.

**Executor** : conscience de position d'abord (répertoire courant, dépôt, chemins relatifs vers la racine du Vault — trouvée en remontant jusqu'au marqueur `VAULT-ROOT.md`, jamais un dossier nommé `vault` en dur — et vers le dépôt du projet). Puis les trois mesures : (a) `rev:` du `.pre-commit-config.yaml` du projet comparé à la tête du Vault (`.git/refs/heads/main` à sa racine) — un écart signifie des gardiens épinglés en retard, non applicable à une épingle `repo: local` (T01, projets nés après le ticket 02 de la Mission 168) ; (b) le hook natif présent (`.githooks/pre-commit` à la racine du Vault) et `core.hooksPath` qui pointe dessus ; (c) chaque script gardien nommé par le hook présent dans `tools/` à la racine du Vault. Enfin `git status -sb` des deux dépôts, collé tel quel.

**Budget d'appels** : 8 en session de chat (Décision 140714) ; **12 sur la surface Executor**, où la sonde de rôle et le shell coûtent des appels que le budget chat ne prévoyait pas (Mission 154, mesure du rapport 153 : forme correcte en 13 appels).

## 4. Rends le verdict, puis arrête-toi

**Rien avant le verdict.** Pas de salutation, pas de « voici la synthèse », pas de tableau, pas de récapitulatif des lectures : le premier caractère de la réponse est le `R` de `READY` ou le `N` de `NOT-READY`. Tout ce qui explique vient après (Mission 153, faute mesurée au rapport 152 : verdict juste, rendu après deux mille caractères de préambule). **Une anomalie trouvée pendant l'ouverture est le motif du `NOT-READY`**, jamais un paragraphe avant lui (Mission 154, faute mesurée au rapport 153 : réponse ouvrant sur `**ANOMALY détectée**`).

Format, dans cet ordre : la ligne `READY` ou `NOT-READY (<motif mesuré, verbatim>)`, **première ligne de prose de la réponse** ; l'annonce `[role: <pilot|executor> · <plan|implement|validate> · open]` ; un état en cinq lignes chiffrées maximum (têtes des dépôts, avance sur origin, portes ouvertes, dernier handoff, écarts de `git status`), chaque valeur portant `VERIFIED` (mesurée dans cette session, source nommée), `DECLARED` (recopiée du digest ou du handoff, horodatage de la source) ou `ANOMALY` (désaccord entre deux sources, nommé). Pilot : les écarts de `git status` sont toujours `DECLARED`. Puis une rubrique « Ouverture / budget » : nombre d'appels d'outil avant le verdict, octets rapportés par `get_file_info` seulement — digest et journal —, les autres lectures nommées avec la mention « taille non rapportée », jamais estimées, recherches d'outils jouées (Décision 140714, point 6).

`NOT-READY` a une seule conséquence, non négociable : **Executor — aucun geste** (ni écriture ni commit de toute la fenêtre) ; **Pilot — aucun dépôt** de toute la session. Lire et discuter restent permis. La réparation est une Mission ou un arbitrage Owner, jamais un geste de ce skill.

## Ce que ce skill ne fait pas

La clôture (`session-close`) · l'installation ou la réparation du poste (`first-install`, `project-bootstrap`) · la pose du hook (bootstrap) · la moindre écriture hors d'un ordre d'initiation reçu, y compris une ligne de journal — l'annonce vit dans la conversation · la recherche : tu lis une liste fixée, tu ne fouilles pas.

## Liens

- `see also` — [Liste de lecture d'ouverture de session, par rôle](./reading-list.md)
- `see also` — [Charte des rôles et détermination de session](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Gabarit — ordre d'initiation](../../templates/initiation-order-template.md)
