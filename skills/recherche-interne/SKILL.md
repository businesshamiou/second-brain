---
name: recherche-interne
description: "Search the Vault and the project corpus by discipline: indexes and description fields first, then exact grep or glob, and never assert a path that was not measured. Use when looking for a document, a rule, a decision, a term, or when asked where something lives. Triggers on: « où est », « trouve », « cherche dans le Vault », « quel fichier », « where is »."
license: "MIT"
metadata:
  vault-implements: "(historique de l'atelier, non distribué), decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md, (historique de l'atelier, non distribué)"
  vault-validated: "2026-09-07T20:31:20-04:00"
---

Cherche dans le Vault et le corpus d'un projet **par discipline, pas par moteur** (DECISION-144931 §6a, étude Mnemosyne : câbler l'existant plutôt qu'outiller du neuf). Deux surfaces : Pilot (MCP `read_text_file`, `search_files`, `get_file_info`) et Executor (shell : `cat`, `grep`, `find`, `tools/find-in-vault.sh` du Vault). Ce skill **n'écrit rien** : il rend des chemins mesurés, ou « non trouvé ». Les quatre étapes se jouent dans l'ordre, aucune ne se saute.

**Précédence.** La chaîne d'entrée exigée par la surface (`VAULT-ROOT.md` remonté, puis la charte) se lit **avant** toute recherche et ne compte pas comme lecture de recherche ; elle ne dispense jamais du §1, dont la **première lecture de recherche est un index**, jamais un `grep`. Aucune des deux règles n'annule l'autre (Mission 153, écart mesuré au rapport 152).

## 1. Index d'abord — dévoilement progressif

Ouvre l'`index.md` de la racine concernée, à la racine du Vault (`index.md`, `rules/index.md`, `decisions/index.md`, `skills/index.md`, `knowledge/index.md`, `templates/index.md`, `projects/index.md`, …) ou du projet en cours, et lis le champ `description` de chaque entrée. `skills-warehouse/` suit sa propre convention (un seul `index.md` natif à `skills-warehouse/skill-collections/index.md`, pas un par dossier) : le chercher là, pas ailleurs dans ce sous-arbre. Note les candidats : nom de fichier exact tel que listé, une ligne de raison. Ne descends dans un fichier qu'après l'index : c'est l'index qui dit ce qui existe.

## 2. Puis motif exact

Sur les candidats et sur le corpus : `search_files` (glob sur le nom) ou `grep` (motif exact sur le contenu, `grep -rn -- '<motif>' <racine>`), avec les exclusions `.git`, `node_modules`, et `skills/` sauf si les skills sont la cible (la bibliothèque externe est du matériel adopté, pas du corpus normatif). Un motif est **exact** : ce que tu as tapé, pas une approximation présentée comme telle. Zéro résultat se dit « 0 résultat pour `<motif>` dans `<racine>` », jamais « rien de pertinent ».

## 3. Remonte à la version en vigueur

Pour tout document trouvé, lis sa section `## Liens` : une ligne `amended by` ou `superseded by` désigne un document plus récent — suis-la jusqu'au dernier, et vérifie `superseded-files.txt` de la racine. La version en vigueur est celle que tu rends ; la version remplacée est nommée comme telle (faute « lecture d'un document remplacé », contrat du Pilot point 4 : un document marqué remplacé n'est pas une source).

## 4. Rends des chemins mesurés

La sortie est une liste : un chemin par ligne, relatif au workspace, chacun **mesuré** (`get_file_info` réussi, ou apparu dans un listage réel), une ligne de raison, et la mention « en vigueur » / « remplacé par … » (DECISION-212009 : un chemin est MESURÉ ou n'est pas). Un chemin reconstitué de mémoire ne se rend jamais. Ce qui n'a pas été trouvé se dit tel quel : « non trouvé : `<terme>` — index lus : …, motifs tentés : … ».

## Ce que ce skill ne fait pas

Recherche web (`research`, bibliothèque externe) · recherche d'images (aucun skill, règles en place) · écriture, dépôt, commit · résumé à la place du document (il rend l'adresse, pas le contenu) · affirmation d'un chemin non mesuré.

## Liens

- `applies` — Décision — Fin de passe skills V1 (historique de l'atelier, non distribué) (hors Vault)
- `applies` — [Décision — Statut de preuve et contrôle du STOP](../../decisions/DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `applies` — Note — Mnemosyne : retrieval contre Vault réel (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Standard de liens entre documents](../../rules/RULES-2026-08-21-115658-document-linking-standard.md)
