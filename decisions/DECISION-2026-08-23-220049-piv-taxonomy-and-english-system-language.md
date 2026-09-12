---
type: decision
title: "Taxonomie PIV, langue système anglaise, charte des rôles, fin des fichiers PROMPT"
created_at: 2026-08-23T22:00:49-04:00
timezone: America/Montreal
status: ARBITRATED
scope: activity-taxonomy-system-language-and-roles
amends:
  - "../rules/RULES-2026-08-17-005717-vault-operating-rules.md"
  - "../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md"
  - "DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md"
related_mission: "038"
---

# DECISION — TAXONOMIE PIV, LANGUE SYSTÈME, CHARTE DES RÔLES, FIN DES PROMPT

Arbitrée oralement par l'Owner en session Pilot du 2026-08-23 (soirée).

## A1 — Taxonomie des types d'activité : PIV

Les types annoncés en session sont `plan` / `implement` / `validate`, complétés par la dimension session `open` / `milestone` / `close`. [source : Cole Medin, boucle PIV]

Rejetés en chemin : liste plate à six types (mélangeait tâche et gestion de session) ; quatre types ancrés artefacts incluant `mission` (classait par le canal d'exécution, pas par l'intention) ; `read / decide / write` (point de vue du système, pas du modèle mental de l'Owner). Le brainstorm vit dans `plan`.

Le même vocabulaire sert les deux niveaux : les activités du participant sur son projet (niveau produit) et nos activités de fabrication (niveau fabrication).

## A2 — Périmètre de la règle « mots-clés système en anglais »

Est mot-clé système toute chaîne lue ou comparée littéralement par un script, ou servant d'étiquette structurée : commandes, tags, étiquettes de classification, statuts, identifiants de champs. Tout mot-clé système est en anglais. Les valeurs de champs restent en anglais ; leur localisation éventuelle est hors sujet du workshop.

Amende le §3 des [Règles de conduite du Vault](../rules/RULES-2026-08-17-005717-vault-operating-rules.md) : la répartition « prose française / identifiants anglais » demeure, précisée par le périmètre ci-dessus et par A3.

## A3 — Journal entièrement en anglais

Les lignes de journal s'écrivent en anglais, tags et contenu (`STATE:`, `NEXT:`, `OPEN:`, `RESUME:`). Motif Owner : un journal est consulté par des développeurs et des agents ; le système traduit au besoin. Le journal étant en ajout seul, aucune ligne historique n'est réécrite ; les outils lisent les deux jeux. Les documents destinés à l'Owner restent en français.

## A4 — Détermination du rôle par trois barreaux

Une session détermine son rôle par : hook `SessionStart` (contraignant) → sonde de capacité shell (infalsifiable) → déclaration du mini-prompt (confirmation). Contradiction entre barreaux → STOP. Doute → le rôle le moins puissant l'emporte, on présume `pilot`. Le rôle est annoncé au premier message.

Détail opérationnel : [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md).

## A5 — Révocation de la livraison des prompts en fichier téléchargeable

La pratique « prompts Executor longs livrés comme fichiers téléchargeables » était un contournement de l'absence d'accès filesystem du Pilot. Elle est **révoquée** hors du seul cas de fallback (Pilot sans aucun accès filesystem).

Constat de session : cette pratique n'était gravée dans aucune règle du Vault — elle vivait dans une **capture** de contexte, consommée à tort comme une norme. Corollaire durable : *une capture n'est jamais une norme ; seule une règle ou une Decision oblige.*

Le Pilot écrit désormais ses artefacts neufs directement à leur emplacement canonique, après annonce de la porte (périmètre borné, cf. charte §2). Ceci ferme le gate **G5**.

## A6 — Correction du chemin des prompts

Le chemin réel est (historique de l'atelier, non distribué), et non (historique de l'atelier, non distribué) comme l'indiquait la capture maître. Amende le §4 des [Règles de versionnement](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) en précisant l'emplacement, sans toucher au nommage.

## A7 — Fin de la production des fichiers PROMPT

**Arbitré** (levée du OPEN initial) : plus aucun fichier PROMPT n'est produit. Le trio de délégation devient : **Mission** (l'autorité, lue en entier par l'Executor) → **mini-prompt en snippet** (le déclencheur, cinq rubriques, règle du relais) → **bloc RELAY** (le retour).

Motifs, par ordre de force : (1) doublon — depuis la règle du relais, le PROMPT ne fait que répéter la Mission, et deux sources pour une tâche finissent par diverger ; (2) *besoin réel → structure* — plus aucun consommateur ; (3) convergence indépendante : la règle R-CARGAISON d'un vault antérieur de l'Owner (« l'exécutant ne consomme que les pièces `type: mission` ; toute autre pièce ne se suit jamais comme instruction ») aboutit à la même conclusion par un autre chemin ; (4) à titre secondaire, les preuves de dégradation par duplication de contexte (context rot, malédiction des instructions) — valables seulement quand le doublon est effectivement chargé en session.

Amende le §4 des [Règles de versionnement](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) : la convention de nommage `PROMPT-…` reste définie pour lire l'historique ; elle ne produit plus de fichiers neufs. Les fichiers PROMPT existants restent en place, historique gelé (gel du stock) — aucune suppression, aucun déplacement.

## A8 — Emprunts validés du vault antérieur (capitalisation)

Validés en bloc par l'Owner après contre-examen, pour mise en œuvre en Mission 039 (préflight) :

1. **Identité posée avant la CLI** par un lanceur (variable d'environnement — mécanisme universel, pas propre à un assistant).
2. **Verrou d'identité au premier appel d'outil**, fail-closed, là où le harnais le permet (`PreToolUse` Claude Code) — précoce mais propriétaire.
3. **Muraille pre-commit universelle** — tampon de préflight valide exigé pour committer, quelle que soit la marque de l'agent — tardive mais totale. Les deux étages se complètent, aucun ne remplace l'autre.
4. **Le tampon surveille son propre silence** : l'âge du dernier contrôle est vérifié indépendamment de son contenu — un tampon peut mentir par silence.
5. **Défaut `deny`** : tout sujet, action ou ressource non déclaré est refusé.
6. **Modèle de menace assumé** : gardes anti-accident, pas anti-évasion (gravé dans la charte).

Rejetés : politique déclarative sans consommateur (policy.yaml — contre-exemple de *besoin réel → structure*), dépendances Windows-seulement, compilateur de hooks à empreinte (over-engineering à ce stade), dispositifs sans vue les uns sur les autres.

## Liens

- `amends` — [Règles de conduite du Vault](../rules/RULES-2026-08-17-005717-vault-operating-rules.md)
- `amends` — [Versionnement des Missions et outputs générés](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `amends` — [Contrat du Pilot, marquage des documents remplacés, et ratification de la convention de tags du journal](./DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md)
- `see also` — [Classification d'activité PIV et mots-clés système](../rules/RULES-2026-08-23-220049-activity-classification-and-system-keywords.md)
- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
