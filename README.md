---
title: "Second Brain"
description: "Page d'entrée du dépôt : ce qu'est Second Brain, comment l'installer, ce qui est installé et où, comment le désinstaller."
status: active
---

**Second Brain is a durable memory and a cross-project operating system for working with AI agents — rules, methods, templates, skills and guardrails, versioned in one Git repository you own.** It installs itself from one command line (Windows, macOS or Linux), asks a short questionnaire, and never overwrites what already exists. It requires a paid subscription to at least one AI agent (Claude Pro or higher, or ChatGPT Plus or higher) — nothing here is designed or tested against a free account. Licensed under MIT.

---

# SECOND BRAIN

## Ce que c'est

Second Brain est une mémoire durable et un système opératoire transversal pour travailler avec des agents IA : règles, méthodes, gabarits, skills et gardiens automatiques, versionnés dans un seul dépôt Git dont tu es propriétaire. Les fichiers restent la source de vérité ; les outils gravitent autour d'eux.

Il embarque aussi une bibliothèque de skills tiers déjà vérifiés (licence, portabilité) — voir « ce qui est installé et où » — et un assistant, nommé par toi à l'installation (par défaut « Brian »), qui guide l'installation puis répond en lecture seule une fois celle-ci terminée.

Le glossaire complet des termes du produit vit dans [CONTEXT.md](./CONTEXT.md).

## Prérequis

- **Un abonnement payant à au moins un agent IA** : Claude Pro (ou plus), ou ChatGPT Plus (ou plus). Rien dans Second Brain n'est conçu ni testé pour un compte gratuit — l'installeur ne le vérifie pas lui-même, mais le questionnaire suppose cet accès.
- **Git.** Détecté et réutilisé s'il est déjà sur ton poste ; installé pour toi dans ton propre profil, sans droits administrateur, sinon.
- Python et `pre-commit` : mêmes conditions que Git, installés au besoin par l'installeur (gestionnaire `uv`), jamais de façon globale ni élevée.
- Windows, macOS ou Linux. L'installeur PowerShell (`install.ps1`) et l'installeur shell (`install.sh`) posent les mêmes questions, écrivent le même carnet et produisent le même verdict.

_Remarque honnête (à corriger par une Mission future, hors périmètre de ce ticket) : la toute première étape ci-dessous — récupérer ce dépôt — utilise `git clone`, donc Git doit déjà être présent sur ta machine pour cette étape précise ; l'installation automatique de Git ne prend le relais qu'une fois le dépôt déjà cloné._

## Ligne d'installation

**Windows (PowerShell) :**

```powershell
git clone https://github.com/businesshamiou/second-brain.git $env:TEMP\second-brain-install
& "$env:TEMP\second-brain-install\install.ps1" -Source "$env:TEMP\second-brain-install"
```

**macOS / Linux (Terminal) :**

```bash
git clone https://github.com/businesshamiou/second-brain.git /tmp/second-brain-install && bash /tmp/second-brain-install/install.sh --source /tmp/second-brain-install
```

**Depuis Claude Code ou Codex**, ouvre une session dans un dossier quelconque et lance `/first-install` : l'agent pose les mêmes questions dans son propre chat, écrit le fichier de réponses, puis appelle le même installeur.

Dans les trois cas, l'installeur crée ton espace de travail, y clone `second-brain` à sa place définitive, pose le marqueur `VAULT-ROOT.md`, et te pose sept questions courtes (langue, nom de l'assistant, emplacement de l'espace de travail, prénom, activité, façon de travailler avec l'IA, ce qui compte pour toi) avant de te proposer un premier projet.

**L'installation par archive (zip) reste refusée.** Second Brain se publie par étiquette de version (« tag ») sur un dépôt Git, jamais accompagné d'une archive : les gardiens de ce dépôt (contrôle de secrets, de liens, de fraîcheur des index) exigent un dépôt Git réel (`git rev-parse` doit répondre) pour s'exécuter, et un dossier extrait d'une archive n'en est pas un — ni les gardiens ni `/first-install` n'y fonctionnent correctement. Clone toujours avec `git clone`.

**Remarque Windows :** PowerShell ne sait pas exécuter un script `.sh` directement — c'est le cas, par exemple, de l'assistant d'acceptation `tools/acceptance-wizard.sh`. Lance-le depuis **Git Bash** (installé avec Git, disponible dans le menu Démarrer), ou passe par `acceptance.ps1`, à la racine de ce dépôt, qui retrouve Bash tout seul et lui délègue l'exécution.

## Ce qui est installé, et où

| Composant | Emplacement | Portée |
|---|---|---|
| Le dépôt `second-brain` lui-même (règles, skills fabriqués, warehouse, outils) | dossier choisi par toi à la question 3, dans ton espace de travail | ce dépôt uniquement |
| Skills de la méthode, toujours déployés (`skills/` et `skills/external/`) | liens dans `.claude/skills/` et `.agents/skills/` de **chaque projet**, posés à sa création (Codex reçoit `skills/` seul si le budget de description dépasse le plafond mesuré) | ce projet uniquement |
| L'assistant (par défaut « Brian ») | sous-agent Claude Code et skill Codex liés dans `.claude/agents/` et `.agents/skills/` de **chaque projet**, plus un paquet web à téléverser toi-même dans un Projet claude.ai ou ChatGPT | ce projet uniquement, plus un geste manuel pour le paquet web |
| Git, Python et `pre-commit`, si absents de ton poste | ton profil utilisateur uniquement (jamais un emplacement machine, jamais avec élévation) | ton profil utilisateur |
| Ta fiche `USER.md`, ton premier projet éventuel | dans `second-brain` (`USER.md`) et à côté de lui dans l'espace de travail (le projet) | ton espace de travail |
| Le carnet d'installation | `.install/state.json`, à la racine de ton clone, jamais suivi par Git | ton clone local |

Rien n'est installé à un emplacement machine (registre système, dossier partagé), rien ne demande de droits administrateur, et rien n'est posé dans ton profil (les dossiers *.claude*, *.agents* ou *.codex* de ton compte) : l'assistant et les skills de la méthode vivent uniquement dans le clone `second-brain` et dans les projets qui les lient — supprimer un projet ou l'espace de travail entier suffit à tout retirer, sans geste de nettoyage séparé. Seul un projet non listé ici perd ces liens ; recrée-le avec le skill `first-install`/`project-bootstrap` pour les obtenir.

## Reprise et mise à jour

Si l'installation s'interrompt (fermeture accidentelle, panne réseau pendant la récupération de Git), relance la même ligne d'installation : le carnet (`.install/state.json`, à la racine de ton clone) retient chaque étape déjà faite et chaque réponse déjà donnée, et l'installeur reprend à l'étape manquante sans reposer les questions déjà répondues.

Relancer l'installateur sur un poste déjà installé bascule en **mode mise à jour** : tes réponses actuelles s'affichent, une question te demande si quelque chose a changé, et `USER.md` est réécrit proprement avec sa nouvelle date si tu confirmes un changement.

## Désinstallation

Depuis la Mission 173 (rien dans le profil), désinstaller Second Brain consiste à **supprimer le dossier de ton espace de travail — rien d'autre**. Le clone `second-brain`, l'assistant, les skills de la méthode : tout vit à l'intérieur de ce dossier ou dans des liens que tes projets y font pointer ; rien n'est écrit ailleurs sur ton poste.

Si tu veux aussi retirer les outils installés pour toi (Git portable et `uv`, avec `pre-commit`, si tu ne veux plus les garder) : ils vivent dans le sous-dossier local caché de ton profil (Windows : `%USERPROFILE%\.local\`), en dehors de l'espace de travail — supprime ce dossier, puis retire les entrées correspondantes de la variable `Path` de ton compte (Windows : Paramètres → Variables d'environnement).

**Installation antérieure à la Mission 173 ?** Si tu as installé Second Brain avant cette Mission, une version plus ancienne peut avoir posé des liens dans ton profil (*.claude/agents/*, *.claude/skills/*, *.agents/skills/*, dans ton compte). Le script `tools/remove-profile-links.ps1` (dans ton clone) les liste et les retire sur confirmation, sans jamais toucher au contenu qu'ils pointaient — lance-le, lis ce qu'il propose, puis confirme.

## Relier un second dépôt (avancé)

Par défaut, Second Brain ne suppose l'existence d'aucun autre dépôt à côté du tien : les outils qui pourraient comparer ton clone à un dépôt voisin (`tools/session-preflight.sh`, `tools/check-asserted-paths.sh`, `tools/link-graph-drone-view.sh`) ne cherchent rien et n'avertissent de rien tant que tu n'en déclares pas un explicitement.

Si tu utilises un second dépôt à côté de `second-brain` dans ton espace de travail (par exemple pour y garder tes propres missions et rapports) et que tu veux que ces outils le voient, déclare-le d'une des deux façons suivantes :

- variable d'environnement `SECOND_BRAIN_SIBLING_REPO` (le nom du dossier, pas un chemin) avant de lancer une commande ; ou
- un fichier *SIBLING-REPO.txt* (que tu crées toi-même), une seule ligne avec ce même nom, à la racine de ton espace de travail (à côté de `VAULT-ROOT.md`) — pratique pour une déclaration durable, valable pour toute session ouverte depuis ce dossier.

Sans déclaration : silence, comme si l'outil n'existait pas. Avec une déclaration dont le dossier est introuvable : un seul avertissement clair, jamais un refus.

## Questions fréquentes

**Comment je demande quelque chose à mon assistant ?** Nomme-le explicitement dans ta question, par exemple `Demande à Brian : quelles sont les décisions actives sur la structure des projets ?` — Claude Code délègue alors réellement au sous-agent en lecture seule dédié, qui cite ses sources par chemin. Sans le nommer, l'agent principal de Claude Code peut répondre lui-même à ta place ; sa réponse est en général correcte, mais elle n'a pas la garantie de lecture seule que porte ton assistant dédié.

**Pourquoi Claude Code me demande une approbation la première fois que j'ouvre un projet ?** Ton assistant et tes skills sont liés dans ce projet (`.claude/agents/`, `.claude/skills/`, `.agents/skills/`) par jonction ou lien direct vers ton clone `second-brain`, un dossier voisin. Claude Code traite un lien dont la cible sort du dossier de travail comme un **import externe** et demande une approbation — une fois par projet, jamais à chaque session. Réponds **oui** (le texte exact dépend de ta version de Claude Code) : c'est sûr, parce que ces liens ne donnent accès en lecture qu'à `second-brain` lui-même, jamais en écriture (un projet n'y écrit jamais, voir la [règle de frontière](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md) ci-dessous), et parce que c'est le clone que tu as toi-même installé.

**Puis-je installer Second Brain sans abonnement payant à un agent IA ?** Techniquement l'installeur ne le vérifie pas, mais rien n'est conçu ni testé pour un compte gratuit : les résultats ne sont pas garantis.

**Puis-je installer depuis une archive zip téléchargée sur GitHub ?** Non, par construction : voir « Ligne d'installation » ci-dessus. Clone toujours le dépôt avec `git clone`.

**Qu'est-ce que le warehouse, et est-ce que j'en ai besoin ?** `skills-warehouse/` est une bibliothèque de skills tiers déjà vérifiés (licence, portabilité). L'installeur n'en déploie aucune collection : seuls les skills de la méthode (`skills/` et `skills/external/`) sont liés dans tes projets ; ton assistant t'explique comment ajouter une collection du warehouse plus tard.

**« Vault » et « Second Brain », c'est la même chose ?** Oui : « Vault » est le nom interne, utilisé dans les règles et les outils ; « Second Brain » est le nom que tu vois. Voir [CONTEXT.md](./CONTEXT.md).

**Qui décide ce qui rentre dans `second-brain` par rapport à mes projets ?** Voir la [règle de frontière entre tes projets et Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md).

**Quelle licence pour les skills tiers du warehouse ?** Chacun porte la sienne, recensée dans [THIRD-PARTY-LICENSES.md](./THIRD-PARTY-LICENSES.md), généré depuis les manifestes du warehouse.

## Licence

Second Brain est distribué sous licence MIT — voir [LICENSE](./LICENSE). Les skills tiers adoptés dans le warehouse portent chacun leur propre licence, recensée dans [THIRD-PARTY-LICENSES.md](./THIRD-PARTY-LICENSES.md).

## Liens

- `see also` — [Guide d'installation](./INSTALL.md)
- `see also` — [Glossaire du produit](./CONTEXT.md)
- `see also` — [Règle de frontière entre un projet et Second Brain](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md)
- `see also` — [Licences tierces](./THIRD-PARTY-LICENSES.md)
- `see also` — [Licence MIT](./LICENSE)
- `see also` — [Instructions pour les agents](./AGENTS.md)
- `see also` — [Standard de liens entre documents](./rules/RULES-2026-08-21-115658-document-linking-standard.md)
