---
name: project-bootstrap
description: "Make a project aware of the Vault at one of its three tiers: register it, pin the Vault guardians, install the pre-tool preflight hook, and propose (never impose) the seven-function layout. Use when adopting an existing project or starting a new one under the Vault."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), (historique de l'atelier, non distribué), (historique de l'atelier, non distribué)"
  vault-validated: "2026-09-01T21:02:20-04:00"
---

Rend un projet conscient du Vault à l'un de ses trois étages (DECISION-210731) : l'enregistre, épingle les gardiens, pose le hook `executor-preflight`, et **propose** la mise en sept fonctions sans jamais l'imposer. **Surface Executor seulement** (fichiers, Git local, hook). Ce skill ne se lance que sur prescription d'une Mission, ordre d'initiation daté par l'Owner ou arbitrage Owner : adopter écrit dans le registre du Vault (DECISION-210731 point 2, amendé par la Décision 000545 A3). La source de comportement est la Décision 210731, **à lire intégralement avant le premier geste** ; ce corps ne la paraphrase pas.

## 1. Mesure l'étage actuel et dis-le

Depuis la racine du projet : **machine** — un fichier global par outil existe (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`) et nomme le marqueur ; **workspace** — `VAULT-ROOT.md` trouvé en remontant, sa ligne « Chemin relatif du Vault » lue ; **projet** — présence de `AGENTS.md`/`CLAUDE.md` pointant la charte, de `.pre-commit-config.yaml` épinglé (`repo: local`, sur le Vault voisin — T01), de `.claude/settings.json` avec le hook `PreToolUse`, d'une ligne au registre `projects/PROJECT-REGISTRY.md` du Vault, d'une fiche `projects/PROJECT-<id>.md` du Vault. Rends l'étage mesuré. **Ne dégrade jamais un étage** : rien n'est retiré, rien n'est réécrit.

## 2. Mode adopter — projet existant

`bash <Vault>/tools/project-bootstrap.sh adopt <projet> [nom] --vcs none|git [--lang FR|EN|ES]` (ou `--order <fichier>` pour un ordre d'initiation). Le script n'écrit que ce qui manque, **sans toucher à aucun fichier existant du projet** (un fichier présent, même incomplet, est laissé tel quel et signalé) :
1. **Acte de naissance et épingle** `.pre-commit-config.yaml` : bloc de commentaires en tête (`vault_id`, `vault_origin`, `vault_ref`, `vcs`, `baseline`), puis `repo: local` sur ce Vault par chemin relatif mesuré, quatre hooks (`vault-check-secrets`, `vault-check-indexes-fresh`, `vault-check-index-weight`, `vault-check-links`). Une épingle déjà présente sans acte n'est pas modifiée : le bloc à ajouter est rendu.
2. **Ligne de base datée** (`.vault-baseline-<date>.tsv`, nommée par l'acte) : les fichiers existants et leur empreinte. Les gardiens ne jugent que le nouveau et le touché ; un fichier gravé puis touché doit devenir conforme (cliquet). Les liens cassés d'avant : `tools/propose-link-repairs.sh <projet>` rend un plan ; `--apply` n'existe que sous Mission.
3. **Fichiers de pointage** `AGENTS.md` et `CLAUDE.md`, prompt Pilot `<projet>/state/PILOT-PROMPT.md` (canari), `.gitignore` des liens, index absents : absents seulement.
4. **Ligne au registre** (colonne `vcs`) et **fiche v2** du Vault ; `conformity` mesurée par `tools/check-project-conformity.sh <projet>` (sept fonctions, registre, acte, épingle, hook Git si `vcs: git`, cohérence des fichiers de pointage avec l'acte).
5. **Git** : `vcs: git` → dépôt créé s'il manque, `pre-commit install` ; `vcs: none` → aucun hook, contrôles par commande (`tools/check-links.sh <projet>`, `check-secrets.sh`, `check-indexes-fresh.sh`, `check-index-weight.sh`, `check-project-conformity.sh`). `adopt --git` plus tard fait passer le projet à `vcs: git`.

Le hook `executor-preflight` (compagnon `preflight-hook.sh`, fragment `settings-hook.json`) reste un geste de ce skill : copie le hook dans `.claude/hooks/` s'il manque ; un `.claude/settings.json` existant n'est jamais modifié, le fragment est rendu.

## 3. Mode nouveau — projet à naître

`bash <Vault>/tools/project-bootstrap.sh create <chemin-cible> <display_name> --vcs none|git` (ou l'appel historique sans sous-commande) : squelette des sept fonctions, README, journal, index, acte de naissance et épingle, prompt Pilot, fiche v2, ligne de registre, dépôt et hook si `vcs: git`. `--ask` pose d'abord nom, emplacement et Git. Le script finit par le **bloc à consommer** (Projet à créer, prompt commun à coller, premier message = chemin du projet, canari).

## 4. Propose la réorganisation, n'applique jamais seul

En fin de course, sur un projet adopté : présente le **plan de réorganisation** en sept fonctions (`README.md`, `rules/`, `state/`, `missions/`, `decisions/`, `proposals/`, `knowledge/`, `handoffs/` — RULES-142800 §2) : la liste des déplacements, ce qui bougerait et où, **aucun exécuté**. Elle ne s'applique que sur un « oui » catégorique de l'Owner **écrit dans la Mission** qui lance ce skill — jamais sur un oui de conversation. Sans ce oui : le projet reste tel quel, adopté mais non réorganisé, et la fiche v2 le dit.

## 5. Verdict

Étage avant → étage après ; liste des fichiers ajoutés ; **rien de modifié** — preuve : `git status --porcelain` du projet ne montre que des `??` (ou des `A`), aucun ` M` ; sortie de `check-project-conformity.sh` collée ; le plan de réorganisation proposé ; les gestes humains restants.

## Ce que ce skill ne fait pas

Ouvrir ou clore une session (`session-start`, `session-close`) · pousser · modifier ou déplacer un fichier existant du projet · appliquer les sept fonctions sans le oui écrit dans la Mission · adopter (historique de l'atelier, non distribué), le Vault ou un entrepôt sans Mission dédiée · installer le poste (`first-install`) · dégrader un étage.

## Liens

- `see also` — [Hook executor-preflight, à copier dans le projet](./preflight-hook.sh)
- `see also` — [Fragment PreToolUse à fusionner dans .claude/settings.json](./settings-hook.json)
- `applies` — Décision — Prise de conscience du Vault par un projet, trois étages (historique de l'atelier, non distribué) (hors Vault)
- `applies` — Décision — Fin de passe skills V1 (historique de l'atelier, non distribué) (hors Vault)
- `applies` — Décision — Consolidation du soir, standard de projet et plan (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Standard de structure de projet, sept fonctions](../../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- `see also` — [Gabarit du registre des projets](../../templates/project-registry-template.md)
- `see also` — [Registre des projets](../../projects/PROJECT-REGISTRY.md)
- `applies` — [Décision — Initiation et adoption de projet, acte de naissance](../../decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
