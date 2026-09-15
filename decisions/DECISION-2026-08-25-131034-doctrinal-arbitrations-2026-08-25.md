---
type: decision
title: "Arbitrages doctrinaux du 2026-08-25 — révocation du shell Pilot, auto-rangement, références de session, anglicisation du vocabulaire de liens"
created_at: "2026-08-25T13:10:34-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: granted
amends: "./DECISION-2026-08-21-115658-document-linking-standard.md"
related_mission: "053"
---

# DÉCISION — ARBITRAGES DOCTRINAUX DU 2026-08-25

## Date

2026-08-25

## Statut

`ARBITRATED`

Arbitrage : session Pilot du 2026-08-25 (« ok pour la Mission doctrinale, vas-y go », sur les quatre points énoncés par le Pilot dans le même échange) ; point 4 ré-arbitré par l'Owner le 2026-08-25 après explication, l'exception française étant rejetée.

## Décision

1. **Révocation.** L'autorisation orale du 2026-08-24 permettant au Pilot une exécution shell bornée à la mesure en lecture seule est révoquée. Le Barreau 2 de la charte reste le critère : la capacité shell déduit le rôle Executor. Le besoin qui l'avait motivée (horodatage réel) est couvert par le mécanisme MCP : dépôt, `get_file_info`, alignement du nom et de `created_at` avant la fin du tour — prouvé en session du 2026-08-25 (Missions 051 à 053).
2. **Auto-rangement.** Toute Mission commite son propre fichier et régénère les index en dernières étapes de sa fenêtre. Preuve d'efficacité : 041/044/045 ont demandé trois fenêtres pour une clôture ; 050/051/052 une chacune. Gravé dans la règle de versionnement des Missions.
3. **Références de session.** La fiche d'état porte une section catalogue « Références de session » (chemins + une ligne), générée par `tools/build-state.sh` : charte des rôles, règle du relais, Decision des tags de journal, standard de liens, présente Decision. Le contrat du Pilot reste plafonné à sept lignes ; la fiche ne recopie aucun contenu normatif (conforme à l'arbitrage 2 des sept arbitrages du 2026-08-23).
4. **Anglicisation du vocabulaire de liens.** Les mots-clés système sont en anglais, sans exception : le vocabulaire de liens typés y passe. Correspondance arbitrée, alignée sur le front-matter déjà anglais (`supersedes`, `amends`) : `applique` → `applies`, `remplace` → `supersedes`, `amende` → `amends`, `source` → `source` (inchangé), `prescrit par` → `prescribed by`, `voir aussi` → `see also`, `remplacé par` → `superseded by`, `amendé par` → `amended by`. Principe gravé pour l'avenir : le système est destiné au multilingue — la prose, les prompts et les titres se localisent dans la langue de l'utilisateur ; les mots-clés système (tags de journal, types de liens, valeurs de statut, champs de front-matter) restent figés en anglais quelle que soit la langue de travail. La migration du corpus, du standard et de l'outillage est exécutée par la Mission 054, jamais à la volée. Rejeté : l'exception française, un temps envisagée — une exception localisée aujourd'hui devient une exception par langue demain.

## Raison

Trois dettes orales et une contradiction constatée, toutes antérieures au 2026-08-25 ; une exception non écrite à une règle de sécurité érode la règle entière ; une contradiction de langue dans les mots-clés système bloque toute internationalisation propre.

## Impact

- Porte `open-pilot-shell-authorization` fermée : la charte n'est pas modifiée, le mécanisme MCP couvre le besoin d'horodatage.
- Règle de versionnement des Missions et outputs générés amendée d'une règle d'auto-rangement.
- `tools/build-state.sh` porte une nouvelle section catalogue « Références de session ».
- Le standard de liens et son vocabulaire ne sont pas modifiés par la présente Decision : la migration du corpus, de l'outillage et du standard lui-même est exécutée par la Mission 054, jamais à la volée.

## Alternatives importantes

- Maintenir l'autorisation orale du Pilot sans la graver ni la révoquer : écartée, une exception non écrite à une règle de sécurité érode la règle entière.
- Exception française permanente au vocabulaire de liens : écartée par l'Owner après explication — une exception localisée aujourd'hui devient une exception par langue demain, contraire à l'objectif de multilinguisme du système.

## Human gate

- Validation : accordée
- Référence : session Pilot du 2026-08-25 (« ok pour la Mission doctrinale, vas-y go ») ; point 4 ré-arbitré par l'Owner le 2026-08-25 après explication.

## Artefacts liés

- Mission d'exécution : (historique de l'atelier, non distribué)
- Mission de migration (point 4) : (historique de l'atelier, non distribué)

## Liens

- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `applies` — [Decision — taxonomie PIV et langue système anglaise](../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md)
- `amends` — [Décision — Adoption du standard de liens entre documents](./DECISION-2026-08-21-115658-document-linking-standard.md) (point 4, anglicisation du vocabulaire — Mission 065)
- `see also` — Mission 053 — Gravures doctrinales du 2026-08-25 (historique de l'atelier, non distribué) (hors Vault)
- `see also` — Mission 054 — Anglicisation du vocabulaire de liens (historique de l'atelier, non distribué) (hors Vault)
