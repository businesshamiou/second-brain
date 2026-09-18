---
title: "Notes de publication"
description: "Ce que contient chaque version publiée de Second Brain, et ce qu'elle ne promet pas."
status: active
---

# NOTES DE PUBLICATION

## v0.1.5

Version de confort : trois retouches à la manière dont tu délègues un geste à l'agent et dont tu démarres un nouveau Projet — rien qui change ce qui s'exécute.

**Ce que cette version apporte.**

- **Déléguer un push ne demande plus une formule à réciter.** Jusqu'ici, autoriser un push exigeait une phrase précise, recopiée mot pour mot. Une phrase claire de ta part, qui dit quoi pousser, suffit désormais — l'agent la mesure, il n'en juge plus la forme.
- **Les instructions à coller dans un Projet (Claude Desktop ou ChatGPT) sont prêtes à l'emploi.** L'installeur les génère en entier, au moment de créer ou d'adopter un projet, dans le texte même à coller : tu n'as plus besoin d'aller ouvrir un fichier séparé pour les retrouver.
- **La documentation d'installation est retravaillée, avec une FAQ étoffée.** README.md et INSTALL.md suivent désormais le même parcours en quatre étapes (installer, le serveur MCP, ouvrir le Pilot, adopter un dossier existant), et la FAQ répond aux questions les plus fréquentes rencontrées à l'installation.

**Comment c'est prouvé.** Six tests nommés, chacun avec son témoin négatif, enchaînés dans la CI publique. L'inventaire est dans [`tests/index.md`](./tests/index.md).

**Ce que cette version ne promet pas.**

- Rien de neuf côté fonctionnalités d'exécution : cette version clarifie ce qui se lit et se colle, elle ne touche à aucun geste que l'agent exécute pour toi.
- Les limites des versions précédentes restent valables : aucun mécanisme de mise à jour, S7 et S8 en `SKIP` sans clé de fournisseur.

**Ce qui reste à faire de ton côté.**

- Rien d'immédiat : ces changements s'appliquent la prochaine fois que tu délègues un push ou que tu crées ou adoptes un projet. Si tu veux repartir de cette version, relance la ligne publiée ci-dessus.

## v0.1.4

Version corrective : la v0.1.3 rejouée à la main sur un poste Windows déjà utilisé, dans l'application de bureau, a montré onze défauts que la CI ne pouvait pas voir — ses scénarios partent toujours d'une machine vierge. Si tu as déjà lancé la ligne publiée au moins une fois, installe depuis cette version.

**Ce que cette version corrige.**

- **Un poste déjà utilisé n'installe plus une version périmée.** C'est le défaut le plus grave. La ligne d'installation télécharge le dépôt dans un dossier temporaire ; ce dossier survit d'une fois sur l'autre, et l'amorçage le réutilisait tel quel. Un dossier oublié de la semaine précédente installait donc son vieux contenu — sans identité, sans acte de naissance, sans prompt Pilot — en annonçant « Installé, tout est en place ». Le dossier est désormais mis à jour et amené à la version demandée, et l'amorçage vérifie qu'il y est arrivé. En cas d'écart (autre dépôt, version inexistante), il refuse en nommant le dossier à écarter : jamais de suppression, jamais de `--force`.
- **Ton Second Brain sait d'où il vient.** `vault_origin` — dans `VAULT-IDENTITY.md`, dans le marqueur `VAULT-ROOT.md` et dans l'acte de naissance de chaque projet — nommait le dossier temporaire au lieu du dépôt d'origine. Il porte maintenant l'origine réelle ; quand la source n'en a pas, le repli sur son chemin t'est dit, jamais posé en silence.
- **Un refus du serveur MCP est lisible.** Dans l'application de bureau, une lecture hors périmètre affichait « Tool execution failed », sans chemin ni raison. Le serveur rend désormais un texte qui nomme le fichier demandé **et** la liste des dossiers autorisés.
- **Le premier commit d'un projet aboutit.** `adopt` créait le dépôt Git sans identité d'auteur : sur un poste sans `user.email` global, le premier commit mourait sur « Author identity unknown ». Tout dépôt créé ou repris reçoit une identité locale — celle de ton Second Brain, sinon une identité neutre.
- **`--git` vaut réponse.** `project-bootstrap.sh adopt <projet> --git` posait quand même la question « Suivre ce projet avec Git ? », ce qui bloquait tout appel sans terminal. L'option tranche la question au lieu de la précéder.
- **Le Pilot sait que le serveur de Second Brain est son seul outil de fichiers.** Le prompt commun le dit désormais en une phrase : tout autre outil de fichiers est hors périmètre, même s'il est disponible.
- **L'installation rend ton Second Brain propre.** Elle se terminait en laissant la fiche du premier projet non suivie et deux index modifiés — l'état que les gardiens refusent. Un dernier passage régénère les index et enregistre ce qui reste.
- **Les chemins affichés sont ceux de ton système.** Sous Windows, le prompt Pilot, la fiche de projet et le bloc à consommer portaient le chemin du projet dans la forme de Git Bash, avec la lettre de lecteur en tête et des barres obliques ; ils portent maintenant la forme native de Windows, celle que l'application et le serveur MCP rendent.
- **La documentation donne une ligne qu'on peut coller.** `INSTALL.md` et `README.md` écrivaient `bash tools/install-vault-mcp.sh` ; `bash` n'est pas sur le `PATH` de PowerShell. L'invocation Windows exacte, par le bash de Git, y figure.
- **Le plan d'adoption ne parle plus que de l'existant.** Il proposait de ranger l'index que le même appel venait d'écrire.

**Comment c'est prouvé.** Douze tests nommés, chacun avec son témoin négatif — la même mesure sur un cas fabriqué pour échouer — enchaînés dans les jobs Windows, Ubuntu et macOS de la CI publique. L'inventaire est dans [`tests/index.md`](./tests/index.md).

**Ce que cette version ne promet pas.**

- Rien de neuf côté fonctionnalités : cette version ferme des portes, elle n'en ouvre pas.
- Le dossier du Projet de l'application de bureau (les outils de fichiers propres à l'application, hors serveur MCP) reste une question ouverte, non tranchée ici.
- Les limites des versions précédentes restent valables : aucun mécanisme de mise à jour, S7 et S8 en `SKIP` sans clé de fournisseur, injection du serveur MCP prouvée sur un profil simulé.

**Ce qui reste à faire de ton côté.**

- Si tu as déjà installé une version précédente : relance simplement la ligne publiée ci-dessus. Si elle refuse en nommant un dossier temporaire, écarte ce dossier comme elle le demande, puis relance.
- Pour le reste, rien ne change : `/first-install` pour le serveur MCP, puis un Projet par projet avec le prompt commun et le chemin en premier message.

## v0.1.3

Version d'initiation : un projet naît ou est adopté en nommant son Second Brain, et le Pilot reçoit un accès disque versionné avec lui.

**Ce que cette version apporte.**

- **Adopter un dossier existant sans le modifier.** `tools/project-bootstrap.sh adopt` n'ajoute que ce qui manque. Il grave une ligne de base datée des fichiers présents :
  - les gardiens ne jugent que le neuf et le touché ;
  - un fichier ancien modifié doit devenir conforme ;
  - la réorganisation en sept fonctions et la réparation des liens cassés sont proposées, jamais appliquées.
- **Un acte de naissance par projet.** En tête de `.pre-commit-config.yaml`, un bloc de commentaires nomme :
  - l'identité du Second Brain (`vault_id`, générée à l'installation dans `VAULT-IDENTITY.md`) ;
  - son origine et son commit ;
  - le suivi Git (`vcs: git` ou `none`).
  `tools/resolve-vault.sh` résout le Second Brain d'un projet par cet acte, puis par le marqueur s'il n'y a qu'un candidat, jamais par voisinage. Deux Second Brain dans un même espace de travail ne se confondent plus, et un projet copié seul garde ses contrôles.
- **Sans Git aussi.** Avec `vcs: none`, aucun hook : `check-links.sh`, `check-secrets.sh`, `check-indexes-fresh.sh`, `check-index-weight.sh` et `check-project-conformity.sh` acceptent un dossier en argument. `adopt --git` ajoute Git plus tard.
- **Un ordre d'initiation.** Un agent qui ouvre un dossier non adopté s'arrête et rend l'ordre à remplir (`project-bootstrap.sh order`). Avec l'ordre daté par l'Owner, il adopte sans Mission (`--order`).
- **Un serveur MCP embarqué.** `tools/vault-mcp.py` (Python, bibliothèque standard, lancé par `uv`) :
  - borne l'accès du Pilot aux dossiers autorisés ;
  - refuse un lien qui s'en échappe ;
  - rend le commit de Second Brain.
  `tools/install-vault-mcp.sh`, appelé par `/first-install`, le déclare dans Claude Code, Codex et l'application de bureau. `tools/check-mcp-containment.sh` vérifie le périmètre.
- **Un prompt Pilot par projet.** `<projet>/state/PILOT-PROMPT.md` porte le chemin du projet, l'identité de Second Brain et un canari que le Pilot rend à l'ouverture ; la création rend le bloc à consommer (Projet à créer, prompt commun à coller, premier message).
- **La conformité mesure l'étage projet** : acte, épingle, hook Git, cohérence des fichiers de pointage avec l'acte. Le registre gagne la colonne `vcs`.

La CI publique exerce chacun de ces comportements sur Windows, macOS et Linux, chacun avec son témoin négatif, en plus des cinq jobs existants.

**Ce que cette version ne promet pas.**

- L'injection du serveur MCP est prouvée sur un profil simulé, avec des substituts de `claude` et `codex` : la CI ne lance pas les vrais outils ni l'application de bureau.
- L'application de bureau lit la configuration au chemin mesuré sur ton poste ; sous Windows, les deux emplacements connus sont renseignés quand ils existent, sans preuve de celui que l'application lit.
- Les limites des versions précédentes restent valables : aucun mécanisme de mise à jour, S7 et S8 en `SKIP` sans clé de fournisseur.

**Ce qui reste à faire de ton côté.**

- Lancer `/first-install` pour poser le serveur MCP, puis redémarrer l'application Claude.
- Pour chaque projet : créer le Projet, coller le prompt commun, donner le chemin du projet comme premier message.

## v0.1.2

Version corrective : la ligne d'installation de la v0.1.1 échoue sous Windows sur un poste qui porte le lanceur WSL (`C:\Windows\System32\bash.exe`). Si c'est ton cas, installe depuis cette version.

**Ce que cette version corrige.**

- **Git Bash est trouvé même quand WSL est présent.** L'installeur prenait le `bash.exe` de WSL pour celui de Git et s'arrêtait. Il part désormais de `git.exe`, remonte jusqu'au `bash.exe` de Git quelle que soit la profondeur du dossier, et refuse un `bash.exe` situé sous le dossier de Windows.
- **pre-commit est trouvé quand uv vient d'ailleurs.** Si uv était déjà installé (winget, scoop), l'installeur cherchait pre-commit à côté de uv au lieu du dossier d'outils de uv, et s'arrêtait. Il demande maintenant ce dossier à uv et l'ajoute à ton `PATH`.
- **Des tests qui mesurent ce qu'ils disent.** Aucun de ces changements ne touche l'installation :
  - le test du paquet web obtient uv comme l'installeur et lance la copie du générateur d'index présente dans le clone ;
  - le test S9 donne au compte standard le droit d'ouvrir une session en tant que tâche, sans lequel la tâche planifiée ne démarrait pas, puis vérifie ce droit.

La CI publique passe sur ce contenu, avec ses cinq jobs, dont S9 sous un compte standard. S7 et S8 y restent notés `SKIP`.

**Ce que cette version ne promet pas.**

- Les limites de la v0.1.1 restent valables (voir ci-dessous) : aucun mécanisme de mise à jour, S7 et S8 en `SKIP` sans clé de fournisseur, téléversement du paquet web non prouvé.

## v0.1.1

Version de preuve : tout ce qui servait à accepter Second Brain devient rejouable, sans geste humain.

**Ce que cette version apporte.**

- **Une ligne d'installation qui n'exige rien d'installé.** Elle télécharge un script d'amorçage (`bootstrap.ps1`, `bootstrap.sh`). Celui-ci pose Git dans ton profil s'il manque, en vérifiant son empreinte, puis récupère le dépôt et lance l'installeur. La ligne de la v0.1.0 commençait par `git clone` : un poste sans Git ne pouvait pas démarrer. Rien ne demande de droits administrateur.
- **Une acceptation entièrement mécanique.** `tests/run-mechanical-acceptance.ps1` rend onze lignes datées (S1 à S10 et T21) :
  - l'assistant (S7) et le paquet web (S8) sont interrogés sur les trois questions de `assistant/ASSISTANT.md`, trois fois chacune, par deux fournisseurs ;
  - S9 installe la ligne publiée sous un compte Windows standard, sans Git, avec un témoin qui prouve qu'aucune élévation n'est possible ;
  - le wizard humain de la v0.1.0 est retiré (conservé dans `_trash/`).
- **Le paquet web contient exactement ce que son README annonce.** Un `index.md` en trop disparaît, et le compte de fichiers du README redevient exact.
- **L'assistant se charge dans Codex.** Sous Windows, les formes générées portaient une marque d'ordre des octets (BOM), qui empêchait Codex de lire le skill.
- **macOS et Linux tels qu'ils sont livrés.** Depuis la v0.1.0 :
  - les gardiens tournent réellement au commit (les hooks n'étaient pas exécutables) ;
  - les outils fonctionnent avec le bash 3.2 et les outils BSD d'Apple, que la CI exerce désormais sur macOS à chaque poussée ;
  - un chemin contenant `&` ou une barre oblique inverse n'échappe plus à deux gardiens ;
  - le mode test de l'installeur Unix n'écrit plus dans ton profil réel.

**Ce que cette version ne promet pas.**

- Toujours aucun mécanisme de mise à jour : une installation v0.1.0 ne devient pas v0.1.1 d'elle-même. Réinstalle depuis la ligne publiée si tu veux cette version.
- S7 et S8 appellent un modèle : dans la CI publique, sans clé de fournisseur, ces deux lignes sont notées `SKIP`, jamais réussies par défaut.
- S8 prouve le contenu du paquet et les réponses obtenues par équivalence ; il ne prouve pas le geste de téléversement dans l'interface web.

**Ce qui reste à faire de ton côté.**

- Coller la ligne d'installation.
- Sous macOS, accepter l'installation des outils en ligne de commande d'Apple si elle est proposée.
- Dans un Projet claude.ai ou ChatGPT, coller le fichier d'instructions du paquet web et téléverser les fichiers que son README liste.

## v0.1.0

Première version publiée : un historique neuf, sans aucun ancêtre de l'historique de développement, et aucun motif privé ni dans l'arbre ni dans l'historique (vérifié par `tools/check-private-patterns.sh` en mode complet).

**Ce que cette version contient.** L'installeur en une ligne (Windows, macOS, Linux) ; le questionnaire de sept questions ; l'assistant généré (sous-agent Claude Code, skill Codex, paquet web) ; les skills de la méthode et le warehouse de skills tiers ; les gardiens automatiques (`.githooks/pre-commit`) ; le registre de Missions et les gabarits de projet.

**Ce que cette version ne promet pas.** Aucun mécanisme de mise à jour : une installation vaut pour la version installée, elle ne peut pas en récupérer une plus récente. Pour une version plus récente, réinstalle depuis le dépôt publié — voir [« Reprise et mise à jour » du README](./README.md#reprise-et-mise-à-jour). Un projet créé pendant le questionnaire ne se renomme pas après coup. macOS n'est pas exercé par la CI automatique : son job ne part que sur déclenchement manuel.

## Liens

- `see also` — [README](./README.md)
- `see also` — [INSTALL](./INSTALL.md)
