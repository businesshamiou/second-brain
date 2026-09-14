---
type: rules
title: "Standard de liens entre documents"
description: "(historique de l'atelier, non distribué)"
created_at: 2026-08-21T11:56:58-04:00
timezone: America/Montreal
status: active
scope: document-linking-standard
---

# STANDARD DE LIENS ENTRE DOCUMENTS

## 1. Portée

Tout document du Vault et de (historique de l'atelier, non distribué) (règle, decision, capture, proposal, current state, handoff, brief, mission, prompt, rapport, fiche projet) porte au moins un lien vers un autre document. [source : Zettelkasten] [mesure : Mission 021]

## 2. Double emplacement

Le lien apparaît en contexte, dans la phrase qui énonce la relation, **et** dans une section finale `## Liens` qui récapitule avec le type. [source : adr-tools écrit le lien sous le Statut et la relation typée ; MADR « More Information »] [choix : nom « Liens »]

## 3. Forme

Un lien s'écrit `[titre lisible](chemin relatif)` ; le chemin est relatif à l'emplacement du fichier ; jamais de chemin absolu, jamais un nom nu, jamais un identifiant en backticks seul. Une mention par nom sans lien ne compte pas. [mesure : Missions 021-022, c'est ce que l'outil lit]

## 4. Vocabulaire fermé des types

Chaque entrée de la section `## Liens` porte un type parmi les six ci-dessous, en anglais. Aucun autre type sans amendement de cette règle. [source : adr-tools « Supersedes / Amends »] [choix : la liste retenue] [amende : Decision — arbitrages doctrinaux du 2026-08-25, point 4, anglicisation exécutée par la Mission 054]

## 5. Lien inverse

`supersedes` et `amends` imposent la ligne inverse dans la cible (`superseded by`, `amended by`) dans le même commit. [source : adr-tools écrit toujours le lien retour]

## 6. Hors corpus

Un lien vers l'autre dépôt s'écrit quand même, suffixé `(hors Vault)` ou (historique de l'atelier, non distribué) ; il documente la relation sans produire d'arête dans le graphe. [choix]

## 7. Front-matter

Les champs `supersedes`, `amends`, `sources`, `related_mission` restent et doivent être cohérents avec la section `## Liens` ; ils complètent, ne remplacent pas. [source : OKF `sources`] [mesure : Mission 021, front-matter PARTIEL]

## 8. Gabarits

Chaque gabarit porte la section `## Liens` pré-remplie avec au moins la ligne `prescribed by` vers la règle qui le prescrit. [mesure : Mission 021, aucun gabarit relié]

## 9. Vérification machine

Le contrôle pre-commit `tools/check-links.sh` s'applique à tout `.md` nouveau ou modifié hors `graphify-out/` (supprimé, Mission 040) : absence de section `## Liens` → bloquant ; lien relatif cassé → bloquant ; aucun lien relatif interne → avertissement, non bloquant. [choix : le partage blocage/avertissement]

## 10. Vérification humaine

La revue Pilot porte sur le bon type de lien et sur la présence du lien en contexte, au-delà de ce que `tools/check-links.sh` peut mesurer. [choix]

## 11. Rétroactivité

Les documents existants sans lien ne sont pas retouchés à la volée ; ils sont corrigés par une Mission dédiée, à partir de la carte des liens manquants de la Mission 021. [choix]

## 12. Ancrage

Une ligne dans `AGENTS.md` renvoie à cette règle. [pratique établie : rapport d'exécution, runbook]

## Vocabulaire des types

Mots-clés système en anglais sans exception, aligné sur le front-matter déjà anglais (`supersedes`, `amends`) — [Decision — arbitrages doctrinaux du 2026-08-25](../decisions/DECISION-2026-08-25-131034-doctrinal-arbitrations-2026-08-25.md), point 4. Le vocabulaire français ci-avant est **retiré** ; la correspondance historique est conservée en note pour lire le corpus antérieur à la migration (Mission 054).

| Type | Définition | Inverse |
|---|---|---|
| `applies` | le document met en œuvre une règle ou une decision citée | — |
| `supersedes` | le document rend obsolète la cible, qui cesse d'être une source de vérité | `superseded by` (obligatoire dans la cible) |
| `amends` | le document modifie partiellement la cible, qui reste en vigueur pour le reste | `amended by` (obligatoire dans la cible) |
| `source` | le document s'appuie sur la cible comme fondement ou preuve | — |
| `prescribed by` | le document est un gabarit ou un artefact régi par la règle citée | — |
| `see also` | relation informative sans dépendance normative | — |

**Correspondance historique** (retirée, pour lecture du corpus antérieur à la Mission 054 seulement) :

| Français (retiré) | Anglais (canonique) |
|---|---|
| `applique` | `applies` |
| `remplace` | `supersedes` |
| `amende` | `amends` |
| `source` | `source` (inchangé) |
| `prescrit par` | `prescribed by` |
| `voir aussi` | `see also` |
| `remplacé par` | `superseded by` |
| `amendé par` | `amended by` |

## Exemple

Document fictif de cinq lignes, lien en contexte puis section `## Liens` :

```markdown
# NOTE — Exemple

Cette note applique le [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md) à un cas fictif.

## Liens

- `applies` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
```

## Liens

- `applies` — [Règles de conduite du Vault, §8](./RULES-2026-08-17-005717-vault-operating-rules.md)
- `source` — Proposal : standard de liens (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Runbook d'installation du Vault](../_trash/runbook-vault-setup.md) (retiré de la distribution, conservé à titre historique)
- `amended by` — [Décision — Bornage du standard de liens au corpus](../decisions/DECISION-2026-08-28-203627-link-section-requirement-scoped-to-corpus.md)
- `amended by` — Décision — Liens sortants vers un autre dépôt (historique de l'atelier, non distribué) (hors Vault)
