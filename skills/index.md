---
type: index
title: "Skills du Vault"
description: "Comportements d'agent au format Agent Skills."
created_at: 2026-08-19T11:53:06-04:00
timezone: America/Montreal
status: active
---

# Skills du Vault

Comportements d'agent au format Agent Skills.

## Contenu

- `external/` — bibliothèque de 40 skills externes en forme standard Agent Skills (six champs, provenance sous `metadata:`), construite depuis le paquet du projet `skills-warehouse` — voir [PROVENANCE.md](./external/PROVENANCE.md).
- `ecriture-de-mission/` — rédige un fichier Mission et son mini-prompt Executor depuis le gabarit, liens mesurés, section Contexte obligatoire — voir [SKILL.md](./ecriture-de-mission/SKILL.md).
- `first-install/` — installe le Vault sur un poste pour la première fois, ou complète une installation partielle sans écraser ce qui existe — voir [SKILL.md](./first-install/SKILL.md).
- `project-bootstrap/` — fait prendre conscience du Vault à un projet, à l'un des trois étages (registre, gardiens, hook de préflight) — voir [SKILL.md](./project-bootstrap/SKILL.md).
- `recherche-interne/` — recherche disciplinée dans le Vault et le corpus projet : index et description d'abord, jamais un chemin non mesuré — voir [SKILL.md](./recherche-interne/SKILL.md).
- `session-close/` — clôt une session de travail : inventaire des trous, refus de clore tant qu'il en reste, handoff ou commit de clôture — voir [SKILL.md](./session-close/SKILL.md).
- `session-start/` — ouvre une session de travail : mesure l'état du dépôt et des gardiens, annonce le rôle — voir [SKILL.md](./session-start/SKILL.md).

## Liens

- `prescribed by` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `source` — [Provenance — bibliothèque de skills externes](./external/PROVENANCE.md)
