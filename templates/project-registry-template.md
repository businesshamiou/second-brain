---
type: template
title: "Gabarit — Project Registry"
description: "Gabarit vide du Project Registry du Vault : en-têtes de colonnes et contrat d'écriture conservés, aucune ligne de données. Destiné à être instancié par le futur skill first-install (non construit par ce lot)."
status: active
write_contract: "executor-only — voir DECISION project-registry-v1"
---

# GABARIT — PROJECT REGISTRY

Gabarit vide du [Project Registry](../projects/PROJECT-REGISTRY.md) : index des projets connus du Vault. Le Vault connaît l'adresse des projets, pas leur contenu — chaque projet reste la source canonique de sa propre mémoire. Le détail de chaque projet vit dans sa fiche `PROJECT-<project_id>.md`.

Les chemins sont relatifs au parent du Vault.

## Active

| project_id | display_name | status | relative_path | conformity |
|---|---|---|---|---|

## Paused

Aucun projet.

## Archived

Aucun projet.

## Liens

- `see also` — [Project Registry — index des projets connus du Vault](../projects/PROJECT-REGISTRY.md)
- `source` — [Decision — Project Registry V1](../decisions/DECISION-2026-08-19-115306-project-registry-v1.md)
