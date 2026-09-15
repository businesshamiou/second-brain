---
type: decision
title: "Project Registry V1 — architecture et contrat d'écriture"
created_at: 2026-08-19T11:53:06-04:00
timezone: America/Montreal
status: active
scope: vault-project-discovery
owner_gate: granted
source_proposal: "(historique de l'atelier, non distribué)"
---

# DECISION — PROJECT REGISTRY V1

## Contexte

Le Vault sait comment travailler mais ne connaît pas explicitement les projets existants, leur emplacement et leurs points d'entrée. Un agent qui ouvre le Vault dépend donc d'une indication manuelle de l'Owner pour localiser un projet.

Le Proposal source a été brainstormé puis arbitré avec l'Owner. Son statut `PROPOSED` n'est pas modifié : une Decision référence son Proposal, elle ne le réécrit pas.

## Principe

> Le Vault connaît l'adresse du projet, pas son contenu.

Le projet reste la source canonique de sa propre mémoire.

## Décisions

### D1 — Forme et emplacement

Une fiche par projet, plus un index, dans `vault/projects/` :

    vault/projects/
    ├── PROJECT-REGISTRY.md            (index)
    └── PROJECT-<project_id>.md        (une fiche par projet)

L'index est structuré en sections `Active`, `Paused`, `Archived`, Active en tête. Une entrée archivée reste en place, jamais supprimée.

Noms de champs et identifiants en anglais ; prose en français.

### D1b — Identifiant projet

    project_id : YYYY-MM-DD-CODE

Date complète de première création du projet, puis code mnémonique dérivé du nom : un à trois segments de deux à quatre caractères majuscules alphanumériques séparés par des tirets, par exemple `AI-CTX-WRKS`. Les trois premiers segments d'un `project_id` sont toujours la date ; tout ce qui suit est le code. En cas de collision, ajuster le code, jamais la date.

### D2 — Schéma minimal

Fiche, huit champs : `project_id`, `display_name`, `status`, `relative_path`, `purpose` en une phrase, `canonical_context`, `entry_point`, `last_verified`.

Index, quatre colonnes : `project_id`, `display_name`, `status`, `relative_path`.

Sections de fiche : Identity, Location, Entry Points, Notes.

Exclus explicitement : dernier handoff, dépôt, graphe, tout état Git, tout SHA — périssables ou déductibles.

### D3 — Chemins

`relative_path` est relatif au parent du Vault, le workspace étant implicite. Aucun chemin machine-spécifique n'est versionné, ce qui préserve la portabilité entre machines et fournisseurs.

Le schéma reste extensible par champs optionnels — `workspace_root`, `remote` — le jour où un projet sortira du workspace, sans casser l'existant.

### D4 — Contrat d'écriture

Personne n'édite le Registry à la main. Trois chemins d'écriture, tous passant par un Executor :

1. le Skill `project-bootstrap` écrit automatiquement la fiche et la ligne d'index à la création d'un projet ;
2. une Mission ou instruction Executor, sur arbitrage Owner, applique les changements de cycle de vie : statut, chemin, points d'entrée ;
3. le Skill `session-start` lit seulement : il vérifie le projet ouvert et signale les écarts en ANOMALY, sans corriger.

Statuts fermés : `ACTIVE`, `PAUSED`, `ARCHIVED`.

### D5 — Graphify

L'index et les fiches entrent dans le corpus actif Graphify du Vault. Le graphe du Vault porte ainsi le « quoi et où » des projets ; chaque projet conserve son propre graphe pour son contenu. Aucun graphe global fusionné : la Decision Graphify V1 reste inchangée.

### D6 — Péremption

Chaque fiche porte `last_verified` et `stale_after`, conformément à la Decision d'adoption OKF. `session-start` vérifie l'existence des chemins du projet qu'il ouvre, et non l'ensemble du Registry : le Registry se répare au fil de l'usage réel, sans inventaire périodique.

## Critère de réussite

Un agent qui ne connaît que le Vault peut répondre : quels projets actifs existent, où ils se trouvent, à quoi ils servent, et quel fichier lire pour commencer — sans que le Vault recopie leur mémoire.

## Human gate

Arbitrage Owner rendu en session de pilotage.

## Liens

- `source` — [Project Registry](../projects/PROJECT-REGISTRY.md)
- `source` — Proposal source (historique de l'atelier, non distribué) (hors Vault)
- `amended by` — [Retrait de Graphify du rôle « graphe du Vault »](./DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md) (D5 devient sans objet)
- `amended by` — [Standard de structure de projet](../rules/RULES-2026-08-26-142800-project-structure-standard.md) (D3, extension additive du schéma — registre v2, Mission 061)
