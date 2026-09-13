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
| Skills de la méthode, toujours déployés (`skills/` et `skills/external/`) | liens dans ton dossier de skills Claude Code et dans celui de Codex (Codex reçoit `skills/` seul si le budget de description dépasse le plafond mesuré) | ton profil utilisateur |
| L'assistant (par défaut « Brian ») | sous-agent Claude Code, skill Codex, et un paquet web à téléverser toi-même dans un Projet claude.ai ou ChatGPT | ton profil utilisateur, plus un geste manuel pour le paquet web |
| Git, Python et `pre-commit`, si absents de ton poste | ton profil utilisateur uniquement (jamais un emplacement machine, jamais avec élévation) | ton profil utilisateur |
| Ta fiche `USER.md`, ton premier projet éventuel | dans `second-brain` (`USER.md`) et à côté de lui dans l'espace de travail (le projet) | ton espace de travail |
| Le carnet d'installation | `.install/state.json`, à la racine de ton clone, jamais suivi par Git | ton clone local |

Rien n'est installé à un emplacement machine (registre système, dossier partagé), et rien ne demande de droits administrateur.

## Reprise et mise à jour

Si l'installation s'interrompt (fermeture accidentelle, panne réseau pendant la récupération de Git), relance la même ligne d'installation : le carnet (`.install/state.json`, à la racine de ton clone) retient chaque étape déjà faite et chaque réponse déjà donnée, et l'installeur reprend à l'étape manquante sans reposer les questions déjà répondues.

Relancer l'installateur sur un poste déjà installé bascule en **mode mise à jour** : tes réponses actuelles s'affichent, une question te demande si quelque chose a changé, et `USER.md` est réécrit proprement avec sa nouvelle date si tu confirmes un changement.

## Désinstallation

Second Brain n'écrit rien de global : désinstaller consiste à retirer ce que l'installeur a créé dans ton propre profil, puis à supprimer le dépôt lui-même. Aucun script dédié n'existe encore pour cette Mission ; voici les gestes manuels, dans l'ordre :

1. **Retire les liens de skills** : supprime le dossier ou les liens créés sous `~/.claude/skills/` et `~/.agents/skills/` qui pointent vers ton clone de `second-brain` (les skills d'autres sources, s'il y en a, restent intacts).
2. **Retire l'assistant** : supprime le lien (jonction ou lien direct) `~/.claude/agents/<nom-de-ton-assistant>.md` et le dossier du même nom sous `~/.agents/skills/`, tous deux créés par l'installeur au niveau du profil et pointant vers ton clone de `second-brain`.
3. **Retire les outils installés pour toi, si tu ne veux plus les garder** : Git portable et `uv` (avec `pre-commit`) vivent dans le sous-dossier local caché de ton profil (Windows : `%USERPROFILE%\.local\`) ; supprime ce dossier, puis retire les entrées correspondantes de la variable `Path` de ton compte (Windows : Paramètres → Variables d'environnement).
4. **Supprime le dépôt** : le dossier `second-brain` cloné dans ton espace de travail (et le fichier `VAULT-ROOT.md` à la racine de cet espace, si tu abandonnes l'espace de travail entier).

## Questions fréquentes

**Comment je demande quelque chose à mon assistant ?** Nomme-le explicitement dans ta question, par exemple `Demande à Brian : quelles sont les décisions actives sur la structure des projets ?` — Claude Code délègue alors réellement au sous-agent en lecture seule dédié, qui cite ses sources par chemin. Sans le nommer, l'agent principal de Claude Code peut répondre lui-même à ta place ; sa réponse est en général correcte, mais elle n'a pas la garantie de lecture seule que porte ton assistant dédié.

**Pourquoi Claude Code me demande une permission la première fois que je parle à mon assistant depuis un autre projet ?** Ton assistant vit dans le clone de `second-brain`, un dossier voisin de tes projets ; la première fois que Claude Code lit un fichier hors du dossier de travail courant (le sous-agent lui-même, ou une règle qu'il cite), il ouvre une fenêtre de permission — en anglais, texte non figé d'une version à l'autre de Claude Code. Réponds **oui** (`Yes`, ou `Yes, and don't ask again` si tu ne veux plus la revoir pour ce dossier) : ce n'est qu'une autorisation de lecture pour ton assistant, jamais une écriture dans `second-brain` (un projet n'y écrit jamais, voir la [règle de frontière](./rules/RULES-2026-09-11-190000-project-second-brain-boundary.md) ci-dessous). Ce guide ne pose pas de réglage `additionalDirectories` à ta place : ce réglage autoriserait aussi l'écriture depuis ton projet vers `second-brain`, ce que la frontière du produit interdit justement.

**Puis-je installer Second Brain sans abonnement payant à un agent IA ?** Techniquement l'installeur ne le vérifie pas, mais rien n'est conçu ni testé pour un compte gratuit : les résultats ne sont pas garantis.

**Puis-je installer depuis une archive zip téléchargée sur GitHub ?** Non, par construction : voir « Ligne d'installation » ci-dessus. Clone toujours le dépôt avec `git clone`.

**Qu'est-ce que le warehouse, et est-ce que j'en ai besoin ?** `skills-warehouse/` est une bibliothèque de skills tiers déjà vérifiés (licence, portabilité). L'installeur n'en déploie aucune collection : seuls les skills de la méthode (`skills/` et `skills/external/`) sont liés dans ton profil ; ton assistant t'explique comment ajouter une collection du warehouse plus tard.

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
