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
- Git. S'il est déjà sur ton poste, il est réutilisé tel quel. Sinon, l'installeur le récupère lui-même dans ton profil utilisateur, sans droits administrateur — sauf pour l'étape 2 ci-dessous, qui a besoin d'un `git` déjà présent pour récupérer le dépôt en premier lieu.
- Python et `pre-commit` : mêmes conditions que Git, gérés par `uv` si absents.
- Windows (PowerShell 5.1 ou plus), macOS ou Linux (Bash).

## 2. Ligne d'installation

**Windows (PowerShell) :**

```powershell
git clone https://github.com/businesshamiou/second-brain.git $env:TEMP\second-brain-install
& "$env:TEMP\second-brain-install\install.ps1" -Source "$env:TEMP\second-brain-install"
```

**macOS / Linux (Terminal) :**

```bash
git clone https://github.com/businesshamiou/second-brain.git /tmp/second-brain-install && bash /tmp/second-brain-install/install.sh --source /tmp/second-brain-install
```

**Depuis Claude Code ou Codex** (poste déjà équipé, ou clone existant à examiner) : ouvre une session dans n'importe quel dossier et lance `/first-install`. L'agent pose les mêmes questions dans son propre chat, écrit un fichier de réponses, puis appelle le même installeur — comportement identique à un participant qui répond en direct dans le terminal.

**Ne pas extraire une archive.** Second Brain se publie par étiquette de version (« tag ») sur le dépôt Git, jamais par une archive zip qui l'accompagnerait. Les gardiens de ce dépôt (contrôle de secrets, de liens, de fraîcheur des index — `.githooks/pre-commit`) et le script d'installation exigent un dépôt Git réel (`git rev-parse --show-toplevel` doit répondre) : sans `.git`, ils refusent explicitement plutôt que de s'exécuter à moitié. Un dossier extrait d'une archive n'est pas un dépôt Git et ne peut exécuter ni les gardiens ni `/first-install` correctement — clone toujours avec `git clone`.

## 3. Ce que fait l'installeur

Dans l'ordre :

1. Il s'assure que Git, `uv` et `pre-commit` sont utilisables (récupérés dans ton profil au besoin, jamais globalement, jamais avec élévation).
2. Il crée ton espace de travail (dossier qui contiendra `second-brain` et tes projets), y clone `second-brain` à sa place définitive, et y pose le marqueur `VAULT-ROOT.md`.
3. Il pose sept questions courtes, dans la langue que tu choisis à la première (français, anglais ou espagnol) : nom de l'assistant, emplacement de l'espace de travail, prénom, ce que tu fais, comment tu travailles avec l'IA, ce qui compte pour toi — puis confirme un premier projet.
4. Il écrit `USER.md` à partir de tes réponses, génère l'assistant (sous-agent Claude Code, skill Codex, paquet web à téléverser toi-même) et pose un `CLAUDE.md`/`AGENTS.md` de dix lignes au plus à côté de `VAULT-ROOT.md`.
5. Il crée ton premier projet si tu l'as confirmé, avec son propre `CLAUDE.md`/`AGENTS.md`, et y lie l'assistant et les skills de la méthode (`skills/` et `skills/external/`) — jamais dans ton profil.
6. Il rend un verdict d'une ligne, signé par le nom de ton assistant : installation terminée, ou étape d'arrêt et cause.

**Première ouverture d'un projet.** La première fois que tu ouvres un projet dans Claude Code, il détecte que les liens vers l'assistant et les skills sortent du dossier de travail (import externe) et demande une approbation, une fois par projet. Réponds oui : voir la question « Pourquoi Claude Code me demande une approbation » dans les questions fréquentes du [README](./README.md).

Chaque étape est notée dans un carnet (`.install/state.json`, à la racine de ton clone, jamais suivi par Git) : une interruption reprend à l'étape manquante, sans reposer les questions déjà répondues. Relancer l'installeur sur un poste déjà installé bascule en mode mise à jour (réponses actuelles affichées, confirmation de tout changement, `USER.md` réécrit).

## Licence

Second Brain, y compris les skills fabriqués par ce dépôt, est distribué sous licence MIT. Voir [LICENSE](./LICENSE). Les skills tiers adoptés dans le warehouse portent chacun leur propre licence, recensée dans [THIRD-PARTY-LICENSES.md](./THIRD-PARTY-LICENSES.md), généré par script depuis les manifestes du warehouse.

## Liens

- `see also` — [README](./README.md)
- `see also` — [Glossaire du produit](./CONTEXT.md)
- `see also` — [Licence MIT](./LICENSE)
- `see also` — [Licences tierces](./THIRD-PARTY-LICENSES.md)
