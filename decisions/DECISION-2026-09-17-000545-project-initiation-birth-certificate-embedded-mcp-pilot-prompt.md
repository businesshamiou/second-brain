---
type: decision
title: "Initiation et adoption de projet — acte de naissance, résolution du Vault par identité vérifiée, serveur MCP embarqué, prompt Pilot commun : amendements de 124848 §1, 115306 D2/D4, 210731 point 2, 124937 et de la charte des rôles"
description: "Un projet résout son Vault par un acte de naissance à identité vérifiée, jamais par proximité ; le bootstrap gagne un mode adopter additif et un champ vcs ; un ordre d'initiation permet d'adopter sans Mission ; un serveur MCP embarqué, épinglé au commit du Vault, donne au Pilot un accès borné ; un prompt Pilot commun est personnalisé par projet sur le disque."
created_at: "2026-09-17T00:05:45-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md"
  - "./DECISION-2026-08-19-115306-project-registry-v1.md"
  - "./DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md"
  - "../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md"
  - "../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md"
---

# DÉCISION — INITIATION ET ADOPTION DE PROJET : ACTE DE NAISSANCE, SERVEUR MCP EMBARQUÉ, PROMPT PILOT COMMUN

## Date

2026-09-17 (arbitrage rendu le 2026-09-16).

## Statut

`ARBITRATED`

## Problème mesuré

- `tools/project-bootstrap.sh` ne connaissait qu'un mode : naître ; il refusait toute cible existante. Le mode adopter de la Décision 210731 point 3 n'existait que comme doctrine dans le skill `project-bootstrap`. [MESURÉ]
- Le Vault était résolu par le seul marqueur remonté `VAULT-ROOT.md` (124848 §1), qui porte un nom et un chemin relatif, aucune identité ; deux Vaults dans un même espace de travail ne sont pas distinguables ; un fichier de pointage de l'atelier pointait encore un dossier `vault` voisin en dur, la proximité écartée par 124848 §1 et 214607. [MESURÉ]
- Le Pilot n'avait d'accès disque que par un serveur MCP installé à la main, hors de tout dépôt, sans version ni périmètre prouvés. [MESURÉ]
- Un agent qui se découvre dans un dossier non adopté s'arrête toujours (210731 point 2), même quand l'Owner vient d'ordonner l'adoption : la règle bloque le geste qu'elle voulait protéger. [MESURÉ]
- Le prompt d'ouverture Pilot (gabarit `session-opening-prompt-template.md`) est commun mais rien ne le personnalisait par projet sur le disque ; le Pilot ouvrait de mémoire. [MESURÉ]

## Décision

### Piliers

1. **Agnostique** : tout modèle, tout harnais (Claude Code, Codex, Claude Desktop, ChatGPT), même mécanisme.
2. **Le projet nomme son Vault et sa construction** : rien n'est déduit du voisinage.
3. **Prompt Pilot commun**, source unique dans le Vault, **personnalisé par projet sur le disque**.
4. **Source unique, pointeurs explicites** : aucune copie de doctrine, aucune cascade de fichiers d'instructions, aucune résolution par proximité.

### A1 — Acte de naissance (amende 124848 §1)

Chaque projet porte à sa racine un **acte de naissance** : l'épingle `.pre-commit-config.yaml` étendue de quatre données, dans le même fichier — `vault_id` (identifiant du Vault installé), `vault_origin` (origine du clone : URL ou chemin), `vault_ref` (commit du Vault à l'instanciation, remplace l'empreinte `vault_head` de la fiche), `vcs` (`none` | `git`). La forme exacte est celle qui ne produit ni erreur ni avertissement à `pre-commit validate-config` : mesurée, un bloc de commentaires à grammaire fixe en tête du fichier.

**Résolution du Vault, dans cet ordre.** (a) L'acte, trouvé en remontant depuis le dossier courant comme `.git` ; il nomme le Vault ; le Vault trouvé doit porter la même identité (`vault_id`), sinon **refus nommant les deux identités**. (b) Sans acte : le marqueur remonté `VAULT-ROOT.md`, qui porte désormais une identité, résout **seulement s'il n'y a qu'un candidat** ; deux Vaults candidats dans l'espace de travail → refus, question à l'Owner. La déclaration écrite reste un confort de lecture (124848 §1 inchangé sur ce point) ; la proximité disparaît de tout fichier de pointage : un chemin écrit dans `AGENTS.md`/`CLAUDE.md` d'un projet est copié de l'acte à la génération, jamais supposé, et un contrôle vérifie leur cohérence.

### A2 — Registre : `vcs` et écriture par `adopt` (amende 115306 D2 et D4)

D2 : la fiche projet gagne le champ `vcs` (`none` | `git`) ; l'index gagne la colonne. D4, chemin 1 : `adopt` écrit la ligne de registre, la fiche et l'acte, au même titre que la naissance ; toujours par un Executor, jamais à la main.

### A3 — Arrêt seulement sans ordre (amende 210731 point 2)

Un agent qui se découvre dans un dossier non adopté : **avec un ordre d'initiation** (A5), il adopte et continue ; **sans ordre**, il s'arrête et **propose l'adoption** en rendant l'ordre à remplir. Le point 2 ne prescrit plus un arrêt inconditionnel.

### A4 — Bootstrap en deux modes additifs

`create` et `adopt`, tous deux additifs. `adopt` ne touche aucun fichier existant ; la réorganisation en sept fonctions est **toujours proposée, jamais appliquée** (210731 point 3 inchangé). **Question avant d'écrire** : nom de dossier et emplacement proposés, l'Owner confirme ou change. **Question Git** si l'ordre ne la porte pas : `vcs: none` → contrôles par commande (`tools/check-*.sh <projet>`), aucun hook ; `adopt --git` plus tard ajoute hook et épingle active. **Ligne de base datée et cliquet** : à l'adoption, la liste des fichiers existants est gravée, datée ; les gardiens ne jugent que le nouveau et le touché ; un fichier de la ligne de base touché doit devenir conforme. Les liens cassés d'avant se réparent par un **script qui propose** ; l'application n'a lieu que sous Mission. La cible reçoit un prompt Pilot généré avec un **identifiant canari**, et un **bloc à consommer** est rendu en chat : Projet (claude.ai/ChatGPT) à créer, instructions communes à coller, premier message = chemin du projet.

### A5 — Ordre d'initiation, type de mini-prompt `initiation` (amende 124937 et la charte §3)

Un Pilot **sans Mission** peut émettre un **ordre d'initiation** : `Type` (`create` | `adopt`), `Mode` (`answered` : toutes les réponses portées par l'ordre, aucune question ; `ask` : le bootstrap pose nom, emplacement, Git), `Nom`, `Emplacement`, `Vault + construction` (`vault_id`, `vault_origin`, `vault_ref`), `Git` (`none` | `git`), `Objet`, `Autorisation Owner datée` (verbatim). Il voyage par un mini-prompt de type `initiation`, **seul type sans rubrique « Source à appliquer »** : l'ordre est la source. Charte §3 : un premier prompt Executor peut être une initiation ; l'Executor la consomme comme il consomme une Mission, périmètre borné à la cible et au registre du Vault.

### A6 — Serveur MCP embarqué et poste

`tools/vault-mcp.py` : serveur MCP en Python, transport stdio, dossiers autorisés passés en arguments, refus de tout chemin hors périmètre et de tout lien symbolique qui s'en échappe, **épinglé par le commit** du Vault installé (le serveur rend son commit ; le Pilot le compare). `first-install` détecte les outils présents (`claude`, `codex`, application Claude Desktop) et injecte la configuration (`claude mcp add`, `codex mcp add`, JSON de Claude Desktop **au chemin mesuré**), dossier autorisé = racine de l'espace de travail, vérifie Python, et dit le redémarrage de l'application comme geste restant. Un **contrôle de contenance** vérifie que projet et Vault sont inclus dans les dossiers autorisés. **Canari Pilot à l'ouverture** : `list_allowed_directories` doit contenir le chemin du projet, puis la lecture du prompt Pilot du projet rend l'identifiant canari. Le prompt commun dit que le rôle Pilot exige l'application de bureau (le MCP n'existe pas dans le navigateur).

### A7 — Marqueur

`VAULT-ROOT.md` généré porte l'identité du Vault (`vault_id`, `vault_origin`) en plus du nom et du chemin relatif.

## Raison

Arbitrage Owner du 2026-09-16 sur la spécification proposée par le Pilot : « tout ce que tu dis me va, conforme ». Le fond : la proximité et le marqueur seul cassent dès qu'un espace de travail porte deux Vaults ou qu'un projet est cloné seul (214607 D4) ; une identité vérifiée dans un acte de naissance est la seule chose qu'un projet emporte partout. L'accès disque du Pilot doit venir du Vault, versionné et borné, pas d'une installation manuelle invisible aux Missions.

## Impact

- Livré dans ce dépôt en v0.1.3 : bootstrap `create|adopt|order`, acte de naissance, résolution par identité, ligne de base et cliquet, réparation de liens proposée, prompt Pilot avec canari, serveur MCP, injection et contenance, chacun prouvé en CI avec témoin négatif.
- Amendées : 124848 §1 ; 115306 D2, D4 ; 210731 point 2 ; règle 124937 (type `initiation`) ; charte §3 (première consommation). Les copies de ces pièces dans ce dépôt portent la mention `amended by` (Décision 205904 : l'amendement vit dans le dépôt amendé).
- 214607 D4 devient un test de CI (projet cloné seul, ses règles s'appliquent).

## Alternatives importantes

- **OpenViking** : écarté — base de contexte, AGPL, autre besoin.
- **Copie du registre à la racine du projet** : écartée — copie de doctrine (214607 D1).
- **Sandbox/Vagrant comme base** : écarté — pas une machine neuve, pas un participant.
- **Réorganisation automatique à l'adoption** : écartée (210731 point 3 maintenu).
- **Fichier d'acte séparé de l'épingle** : écarté — deux fichiers à tenir cohérents ; l'épingle est déjà le seul fichier que tout projet porte.

## Human gate

- Validation : accordée
- Référence : Owner, 2026-09-16, « tout ce que tu dis me va, conforme » ; confirmé le 2026-09-17.

## Liens

- `amends` — [Sept arbitrages de session du 2026-08-23](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
- `amends` — [Project Registry V1](./DECISION-2026-08-19-115306-project-registry-v1.md)
- `amends` — [Décision — Prise de conscience du Vault par un projet, trois étages](./DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md)
- `amends` — [Relais entre rôles par mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amends` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `applies` — [Distribution des mécanismes transverses](./DECISION-2026-08-24-214607-transverse-mechanism-distribution.md)
- `applies` — [Décision — L'amendement vit dans le dépôt amendé](./DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md)
- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amended by` — [Décision — Relais et délégation, une règle un seul endroit](./DECISION-2026-09-17-201623-relay-single-source-push-delegation-by-clear-expression-project-instructions.md)
