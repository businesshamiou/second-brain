---
name: first-install
description: "Install Second Brain from Claude Code or Codex: ask the same seven questions the installer's own terminal questionnaire asks, in the agent's own chat, write them to an answers file, then run install.ps1 or install.sh non-interactively. Also handles an already-existing clone: examines the parent folder for a prior or partial installation before deciding whether to start fresh, resume, or update. Use when asked to install, repair, resume, or update Second Brain from an agent chat."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), (historique de l'atelier, non distribué), (historique de l'atelier, non distribué)"
  vault-validated: "2026-09-11T17:00:00-04:00"
---

Installe Second Brain en pilotant **le même mécanisme** que la porte humaine (`install.ps1` sous Windows, `install.sh` sous macOS/Linux) : ce skill ne réimplémente jamais l'installeur, il lui fournit seulement ses deux entrées requises — un **fichier de réponses** et une **source locale** — puis le lance. Tout ce que l'installeur garantit déjà (idempotence, carnet d'installation, mêmes trois catalogues de langue, même verdict) est hérité sans changement.

## 1. Localiser la source et déterminer le scénario

Ce fichier `SKILL.md` vit à `<clone>/skills/first-install/SKILL.md` dans un clone de Second Brain — que ce clone soit celui dans lequel tu travailles directement, ou le clone d'origine depuis lequel ce skill a été lié (jamais copié) lors de son déploiement dans le dossier de skills personnel (`tools/deploy-skills.ps1`/`deploy-skills.sh`, ticket 07). Dans les deux cas, résous `<clone>` comme deux dossiers au-dessus du chemin réel de ce fichier, et utilise-le comme `-Source`/`--source` de l'installeur — toujours un chemin local, jamais une URL.

Examine ensuite le dossier parent de `<clone>` (le workspace) :

- **`<workspace>/.install` ou `<clone>/.install/state.json` est absent** — aucune installation n'a jamais commencé ici. Traite ce cas comme une **installation neuve** : propose le parent de `<clone>` lui-même, ou un nouveau workspace voisin, à la question 3 ci-dessous.
- **`<clone>/.install/state.json` existe mais est incomplet** (une exécution précédente a été interrompue) — **reprends** : lis d'abord toi-même les réponses déjà enregistrées et les étapes déjà faites, et ne pose que ce qui manque réellement, dans l'ordre fixe ci-dessous.
- **`<clone>/.install/state.json` existe et toutes les étapes sont faites** — c'est un workspace **déjà installé**. Montre ce qui a été enregistré, demande « quelque chose a changé ? », et ne réécris une réponse que si la personne répond oui — jamais de relance silencieuse sur une installation terminée.

Ne devine jamais cet état de mémoire : lis le carnet réel. N'y écris jamais toi-même — le script installeur en est le seul propriétaire ; ce skill ne produit que le fichier de réponses que l'installeur lit.

## 2. Poser les sept questions, dans cet ordre exact

Même ordre et mêmes défauts que le questionnaire du terminal (T06 complément 2), car un mélange de questions répondues au terminal et par l'agent, sur la même installation, doit rester indistinguable pour l'installeur :

1. **Langue** — `FR`, `EN` ou `ES`. Défaut : la langue déjà utilisée dans cette conversation, si elle correspond à l'une des trois ; sinon `EN`. C'est aussi la langue à utiliser pour la suite de cette conversation.
2. **Nom de l'assistant** — défaut `Brian`.
3. **Workspace** — où Second Brain (et son premier projet) doivent vivre. Défaut : le dossier parent trouvé à l'étape 1 (installation neuve) ou le dossier existant (reprise/mise à jour — jamais déplacé).
4. **Prénom.**
5. **Ce que la personne fait, en une phrase.**
6. **Comment elle travaille avec l'IA** — jetons séparés par des virgules parmi `claude-code`, `codex`, `claude-ai`, `chatgpt`. Tu sais déjà lesquels des deux premiers sont vrais pour *cette* conversation — propose-le en défaut, ne demande jamais à la personne ce que tu peux déjà constater.
7. **Ce qui compte pour elle** — défaut : « simplicity, no over-engineering ».

Les skills de la méthode (`skills/` et `skills/external/`) sont désormais toujours déployés par lien, pour Claude Code comme pour Codex : plus aucune question ne les concerne (l'ancienne huitième question, retirée). Le warehouse (`skills-warehouse/`) n'est jamais déployé par ce skill.

Confirme ensuite le **premier projet** : défaut oui, nom suggéré dérivé de la réponse à la question 5 (minuscules, suites non alphanumériques réduites à un tiret), modifiable.

Ne jamais poser une question dont la réponse est mesurable par l'environnement (OS, shell, présence de Claude Code ou Codex, fuseau horaire) — c'est exactement ce que T06 interdit, questionnaire par agent compris.

## 3. Écrire le fichier de réponses et appeler l'installeur

Écris un fichier JSON (un chemin temporaire convient — il n'est jamais commité, l'installeur ne fait que le lire) au format suivant, un champ par question ci-dessus, plus les défauts fixes pour tout ce qui n'a pas été posé parce que déjà connu d'un carnet repris :

```json
{
  "language": "EN",
  "vaultName": "Brian",
  "workspacePath": "/chemin/vers/le/workspace",
  "firstName": "...",
  "activity": "...",
  "aiTools": ["claude-code", "codex"],
  "whatMatters": "simplicity, no over-engineering",
  "firstProject": { "create": true, "name": "...", "displayName": "..." },
  "git": { "userName": "Second Brain Installer", "userEmail": "installer@example.invalid" }
}
```

Lance ensuite, selon la plateforme, exactement l'une de ces deux commandes :

- Windows : `powershell -NoProfile -ExecutionPolicy Bypass -File "<clone>\install.ps1" -Source "<clone>" -AnswersFile "<fichier-de-reponses>"`
- macOS/Linux : `bash "<clone>/install.sh" --source "<clone>" --answers-file "<fichier-de-reponses>"`

Ne jamais passer `-TestMode`/`--test-mode` ici — ce skill pilote une installation réelle dans le profil et le workspace de la personne, jamais une installation jetable (`-TestMode`/`--test-mode` n'existent que pour les tests automatisés de ce dépôt, tickets 03 à 08). L'installeur imprime exactement une ligne de verdict, signée du nom d'assistant choisi, en cas de succès — ou une ligne nommant l'étape, la cause et le remède sinon. Relaie cette ligne telle quelle ; ne la paraphrase pas, puisque c'est aussi ce que le carnet d'installation vient d'enregistrer.

## 4. Ce que ce skill ne fait jamais

- Ne réimplémente aucune étape de l'installeur (prérequis, clonage, gardiens, générateur d'assistant, déploiement des skills, profil) — tout cela reste le travail d'`install.ps1`/`install.sh`, inchangé.
- N'écrase jamais une installation existante et complète sans un « oui, quelque chose a changé » explicite de la personne.
- Ne pousse rien, ne supprime rien, ne touche rien hors du workspace qu'il installe.
- N'invente jamais de réponse à une question destinée à un humain — en reprise, il lit les réponses déjà enregistrées, il n'en fabrique jamais de nouvelles.

## Liens

- `see also` — [install.ps1](../../install.ps1)
- `see also` — [install.sh](../../install.sh)
- `see also` — [AGENTS.md](../../AGENTS.md)
