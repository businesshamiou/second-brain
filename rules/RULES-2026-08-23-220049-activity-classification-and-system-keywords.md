---
type: rules
title: "Classification d'activité PIV et mots-clés système"
description: "Taxonomie des types d'activité (plan / implement / validate), dimension session (open / milestone / close), format d'annonce, périmètre de la règle « mots-clés système en anglais » et langue du journal."
created_at: 2026-08-23T22:00:49-04:00
timezone: America/Montreal
status: active
scope: activity-classification-and-system-keywords
related_mission: "038"
---

# CLASSIFICATION D'ACTIVITÉ PIV ET MOTS-CLÉS SYSTÈME

## 1. Portée

Cette règle s'applique à toute session Pilot et Executor, dans le Vault et dans tout projet. Elle met en œuvre la [Decision : taxonomie PIV et langue système anglaise](../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md), arbitrée par l'Owner.

## 2. Taxonomie des types d'activité

Trois types, tirés de la boucle PIV (Plan–Implement–Validate). [source : Cole Medin, PIV loop, https://github.com/coleam00/skills]

| Type | Activité | Artefacts typiques |
|---|---|---|
| `plan` | explorer, comparer, trancher, cadrer | captures, proposals, decisions, missions, prompts |
| `implement` | produire, intégrer, exécuter | contenu maître, commits, runs Executor |
| `validate` | tester, mesurer, contrôler | audits, reports |

Le brainstorm et la recherche divergente vivent dans `plan`. La lecture pure (retrouver, vérifier un fait) n'est pas un type : elle se classe dans la phase qu'elle prépare.

## 3. Dimension session

Seconde dimension, indépendante du type : `open` / `milestone` / `close`. Elle peut coexister avec n'importe quel type. La commande `wrap` déclenche `close`.

## 4. Annonce

L'IA annonce la classification en une ligne courte, en tête de séquence : `[<type> · <session>]` suivi d'une phrase française. Le marqueur de session est optionnel hors ouverture, jalon ou clôture.

- Exemple : `[plan · milestone] taxonomie arbitrée, on rédige la Mission`.
- L'Owner corrige d'un mot ; la correction fait foi, sans justification demandée.
- Ni classification silencieuse, ni demande de confirmation avant d'enchaîner.
- Une micro-vérification ne déclenche pas d'annonce.

## 5. Classer n'est pas déposer

La classification est informative. Elle n'ouvre aucun droit d'écriture : tout dépôt de fichier reste une porte annoncée, conformément aux [Garde-fous et niveaux de preuve](./RULES-2026-08-19-210803-guardrails-and-evidence-levels.md).

## 6. Mots-clés système : périmètre et langue

Est **mot-clé système** toute chaîne lue ou comparée littéralement par un script, ou servant d'étiquette structurée : commandes (`wrap`), tags de journal, étiquettes de classification (`plan`, `implement`, `validate`, `open`, `milestone`, `close`), statuts, identifiants de champs.

Tout mot-clé système est en **anglais idiomatique, sans accent**. Les annonces, la prose et les documents destinés à l'Owner restent en français.

## 7. Langue du journal

Les lignes de journal s'écrivent désormais **entièrement en anglais** — tags et contenu. Tags : `STATE:`, `NEXT:`, `OPEN:`, `RESUME:`.

**Note (2026-08-26, Mission 066)** : cette énumération s'est étendue depuis — le tag `CLOSE:` a été ajouté par la [DECISION-2026-08-25-110935](../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md) ; la liste des tags s'étend par Decision, jamais par édition silencieuse de ce paragraphe.

- Le journal est en ajout seul : les lignes historiques françaises (`ETAT:`, `PROCHAIN:`, `OUVERT:`, `REPRISE:`) ne sont jamais réécrites.
- Les outils de lecture reconnaissent les deux jeux de tags.
- Les documents destinés à l'Owner (fiche d'état, handoffs, Decisions) restent en français.

## 8. Extensibilité

Si un cas réel ne rentre dans aucun type pendant l'usage, on le note dans le journal (`OPEN:`) et on amende cette règle par le cycle normal — jamais d'extension silencieuse de la taxonomie.

## Liens

- `applies` — [Decision : taxonomie PIV et langue système anglaise](../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md)
- `see also` — [Règles de conduite du Vault](./RULES-2026-08-17-005717-vault-operating-rules.md)
- `see also` — [Relais entre rôles par mini-prompts](./RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amended by` — [Décision — Extension de la convention de tags du journal — tag CLOSE: et portes à clé](../decisions/DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
