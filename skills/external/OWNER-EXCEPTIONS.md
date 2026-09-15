---
title: "Exceptions Owner à la politique des licences — bibliothèque externe"
description: "Registre des exceptions explicites à la politique permissive par défaut du skills-warehouse (KNOWLEDGE-NOTE-2026-09-01-230251) : les deux skills conservés sous license: NOASSERTION malgré l'absence de licence prouvée, et le skill conservé sous sa licence copyleft réelle plutôt que réécrit en MIT. Chaque entrée porte le skill, sa licence, la source, le constat, la décision Owner datée."
created_at: "2026-09-01T23:18:06-04:00"
timezone: America/Montreal
status: active
---

# EXCEPTIONS OWNER — BIBLIOTHÈQUE EXTERNE

Une exception est **explicite** : elle apparaît ici, dans `LICENSES.md` de chaque paquet construit, et ne remplace jamais la licence réelle par MIT (politique du warehouse, point 6). NOASSERTION n'est présenté nulle part comme une autorisation de redistribution.

## `excalidraw-automate` — AGPL-3.0-only

- **Licence** : `AGPL-3.0-only`, exception à la politique permissive par défaut.
- **Source figée** : https://github.com/zsviczian/obsidian-excalidraw-plugin/tree/052dfe3c12fbc66c8142368f6393673d7f5aecf6
- **Preuve** : https://github.com/zsviczian/obsidian-excalidraw-plugin/blob/052dfe3c12fbc66c8142368f6393673d7f5aecf6/LICENSE
- **Décision Owner** (« inclure-33 », 2026-09-01) : conserver le skill, ne pas le réécrire en MIT, conserver corps et fichiers compagnons, indiquer exactement `AGPL-3.0-only`, inclure sa licence et sa provenance, le distribuer sous sa licence réelle. Enregistré comme exception explicite à la politique permissive par défaut.

## `script-to-whiteboard-storyboard` — NOASSERTION

- **Licence** : `NOASSERTION`.
- **Source examinée** : https://github.com/Samin12/script-to-whiteboard-storyboard/tree/c4927de34c710771e9bf5bf86d700aa223261d9d
- **Constat** : aucun fichier LICENSE applicable et aucun champ `license` dans le `SKILL.md` amont n'ont été trouvés.
- **Auteur** (constat en fenêtre, 2026-09-01) : chaîne YouTube `@Itssssss_Jack`, communauté Skool https://www.skool.com/ai-automation-vault — l'auteur distribue lui-même ce skill librement, sans licence écrite.
- **Décision Owner** (« inclure-33 », 2026-09-01) : conserver le skill dans cette première passe avec `license: "NOASSERTION"` et consigner clairement l'absence de licence.
- Aucune licence n'est prétendue ; NOASSERTION n'autorise pas la redistribution ; l'inclusion est une décision de l'Owner.

## `scroll-film-studio` — NOASSERTION

- **Licence** : `NOASSERTION`.
- **Source** : archive locale « Super website skill v2.zip », SHA-256 `c818f30350afd90e9bce1b6ef180d4b85d6a4f2e5a3fd599045d65b7a8086ff7`.
- **Constat** : aucun fichier de licence applicable et aucun champ `license` dans le `SKILL.md` source n'ont été trouvés. Les licences présentes dans `package-lock.json` concernent les dépendances et ne prouvent pas la licence du skill lui-même.
- **Auteur** (constat en fenêtre, 2026-09-01) : chaîne YouTube `@Itssssss_Jack`, communauté Skool https://www.skool.com/ai-automation-vault — l'auteur distribue lui-même ce skill librement, sans licence écrite.
- **Décision Owner** (« inclure-33 », 2026-09-01) : conserver le skill dans cette première passe avec `license: "NOASSERTION"` et consigner clairement l'absence de licence.
- Aucune licence n'est prétendue ; NOASSERTION n'autorise pas la redistribution ; l'inclusion est une décision de l'Owner.

## Liens

- `applies` — Politique des licences du warehouse et inventaire prouvé (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Provenance de la bibliothèque externe](./PROVENANCE.md)
