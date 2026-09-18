---
title: "Installer Second Brain"
description: "Guide d'installation : prérequis, ligne d'installation par plateforme, ce que fait le questionnaire, l'installation par archive refusée."
status: active
---

# INSTALLER SECOND BRAIN

**Première condition : un abonnement payant à au moins un agent IA** (Claude Pro ou plus, ou ChatGPT Plus ou plus). Rien dans Second Brain n'est conçu ni testé pour un compte gratuit.

Ce dépôt contient Second Brain : une mémoire durable et un système opératoire transversal pour travailler avec l'IA (voir [README.md](./README.md) pour le pourquoi et le quoi). Une seule ligne suffit pour l'installer.

## 1. Prérequis

- L'abonnement payant ci-dessus.
- Rien d'autre à installer à la main. Git, Python et `pre-commit` sont réutilisés s'ils sont déjà sur ton poste ; sinon, la ligne ci-dessous les pose elle-même dans ton profil utilisateur, sans droits administrateur. Sur macOS, Git vient avec les outils en ligne de commande d'Apple : s'ils manquent, Apple propose de les installer, puis tu relances la même ligne.
- Windows (PowerShell 5.1 ou plus), macOS ou Linux (Bash).

## 2. Ligne d'installation

**Windows (PowerShell, compte standard suffisant) :**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.5/bootstrap.ps1)))"
```

**macOS / Linux (Terminal) :**

```bash
curl -fsSL https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.5/bootstrap.sh | bash
```

La ligne télécharge un script d'amorçage (`bootstrap.ps1` ou `bootstrap.sh`, à la racine de ce dépôt) qui n'exige rien d'installé : il pose Git dans ton profil si besoin, vérifie son empreinte, récupère le dépôt à la version indiquée, puis lance l'installeur (`install.ps1` ou `install.sh`). Aucune invite d'élévation, aucune écriture hors de ton profil.

**Depuis Claude Code ou Codex** (poste déjà équipé, ou clone existant à examiner) : ouvre une session dans n'importe quel dossier et lance `/first-install`. L'agent pose les mêmes questions dans son propre chat, écrit un fichier de réponses, puis appelle le même installeur — comportement identique à un participant qui répond en direct dans le terminal.

**Ne pas extraire une archive.** Second Brain se publie par étiquette de version (« tag ») sur le dépôt Git, jamais par une archive zip qui l'accompagnerait. Les gardiens de ce dépôt (contrôle de secrets, de liens, de fraîcheur des index — `.githooks/pre-commit`) et le script d'installation exigent un dépôt Git réel (`git rev-parse --show-toplevel` doit répondre) : sans `.git`, ils refusent explicitement plutôt que de s'exécuter à moitié. Un dossier extrait d'une archive n'est pas un dépôt Git et ne peut exécuter ni les gardiens ni `/first-install` correctement — la ligne ci-dessus récupère toujours un vrai dépôt.

## 3. Ce que fait l'installeur

Dans l'ordre :

1. Il s'assure que Git, `uv` et `pre-commit` sont utilisables (récupérés dans ton profil au besoin, jamais globalement, jamais avec élévation).
2. Il crée ton espace de travail (dossier qui contiendra `second-brain` et tes projets), y clone `second-brain` à sa place définitive, et y pose le marqueur `VAULT-ROOT.md`.
3. Il pose sept questions courtes, dans la langue que tu choisis à la première (français, anglais ou espagnol) : nom de l'assistant, emplacement de l'espace de travail, prénom, ce que tu fais, comment tu travailles avec l'IA, ce qui compte pour toi — puis confirme un premier projet.
4. Il écrit `USER.md` à partir de tes réponses, génère l'assistant (sous-agent Claude Code, skill Codex, paquet web à téléverser toi-même) et pose un `CLAUDE.md`/`AGENTS.md` de dix lignes au plus à côté de `VAULT-ROOT.md`.
5. Il crée ton premier projet si tu l'as confirmé, avec son propre `CLAUDE.md`/`AGENTS.md`, et y lie l'assistant et les skills de la méthode (`skills/` et `skills/external/`) — jamais dans ton profil.
6. Il rend un verdict d'une ligne, signé par le nom de ton assistant : installation terminée, ou étape d'arrêt et cause.

L'installeur génère aussi l'**identité** de ton Second Brain (`VAULT-IDENTITY.md`, suivie par Git comme `USER.md`) : chaque projet la recopie dans son acte de naissance, et le marqueur `VAULT-ROOT.md` la porte.

Chaque étape est notée dans un carnet (`.install/state.json`, à la racine de ton clone, jamais suivi par Git) : une interruption reprend à l'étape manquante, sans reposer les questions déjà répondues. Relancer l'installeur sur un poste déjà installé bascule en mode mise à jour (réponses actuelles affichées, confirmation de tout changement, `USER.md` réécrit) — ce mode ne touche jamais le code ; voir [« Reprise et mise à jour » du README](./README.md#reprise-et-mise-à-jour) pour ce que cette version promet et ne promet pas.

## 4. Le serveur MCP

L'installeur n'écrit rien dans ton profil. **L'accès disque du Pilot (application de bureau)** se pose ensuite par `/first-install` (ou à la main, ligne ci-dessous) : il détecte Claude Code, Codex et l'application de bureau Claude, y déclare le serveur `second-brain-vault` avec ton espace de travail comme seul dossier autorisé, vérifie Python par `uv`, puis te demande de redémarrer l'application. `check-mcp-containment.sh <configuration> <projet>` vérifie que le projet et Second Brain sont bien dans le périmètre autorisé.

À la main, depuis la racine de ton clone `second-brain` :

```bash
bash tools/install-vault-mcp.sh <espace de travail>
bash tools/check-mcp-containment.sh <configuration> <projet>
```

**Sous Windows, dans PowerShell**, `bash` n'est pas sur le PATH ; appelle celui de Git par son chemin complet (mesuré à l'acceptation du 2026-09-17) :

```powershell
& "C:\Program Files\Git\bin\bash.exe" tools/install-vault-mcp.sh <espace de travail>
& "C:\Program Files\Git\bin\bash.exe" tools/check-mcp-containment.sh <configuration> <projet>
```

**Comment vérifier qu'il tourne.** `check-mcp-containment.sh` valide la configuration écrite sur disque. Que le serveur soit réellement actif dans l'application redémarrée se confirme à l'ouverture du Pilot (section suivante) : sa première réponse porte un **canari**, la preuve qu'il a lu le disque par ce serveur plutôt que sa mémoire.

## 5. Ouvrir le Pilot

La première fois que tu ouvres un projet dans Claude Code, il détecte que les liens vers l'assistant et les skills sortent du dossier de travail (import externe) et demande une approbation, une fois par projet. Réponds oui : voir la question « Pourquoi Claude Code me demande une approbation » dans les questions fréquentes du [README](./README.md).

Le rôle Pilot (penser, arbitrer, écrire les Missions) se joue dans l'application de bureau Claude. Chaque projet porte son prompt Pilot, `<projet>/state/PILOT-PROMPT.md`, généré à sa création : crée un **Projet** portant le nom de ton projet, colle comme instructions le prompt commun (`templates/session-opening-prompt-template.md`), et donne comme premier message le chemin du projet. Détail complet du geste dans [« Ouvrir le Pilot d'un projet » du README](./README.md).

## 6. Adopter un dossier existant

Un dossier qui existe déjà (avec ou sans Git) devient un projet sans que rien de ce qu'il contient ne soit modifié :

```bash
bash second-brain/tools/project-bootstrap.sh adopt /chemin/du/dossier --vcs git
```

Le script ajoute seulement ce qui manque (acte de naissance, fichiers de pointage, prompt Pilot, ligne au registre) et ne réorganise rien sans confirmation. Détail complet (ligne de base, `--vcs none`, ordre d'initiation) dans [« Adopter un dossier existant » du README](./README.md).

## Licence

Second Brain, y compris les skills fabriqués par ce dépôt, est distribué sous licence MIT. Voir [LICENSE](./LICENSE). Les skills tiers adoptés dans le warehouse portent chacun leur propre licence, recensée dans [THIRD-PARTY-LICENSES.md](./THIRD-PARTY-LICENSES.md), généré par script depuis les manifestes du warehouse.

## Liens

- `see also` — [README](./README.md)
- `see also` — [Notes de publication](./RELEASE-NOTES.md)
- `see also` — [Glossaire du produit](./CONTEXT.md)
- `see also` — [Licence MIT](./LICENSE)
- `see also` — [Licences tierces](./THIRD-PARTY-LICENSES.md)
