---
type: knowledge
title: "Vérification et preuves — STATE → CHANGE → VALIDATION → SNAPSHOT → EXTERNAL BOUNDARY"
created_at: 2026-08-17T11:10:18-04:00
timezone: America/Montreal
status: active
---

# VÉRIFICATION ET PREUVES — STATE → CHANGE → VALIDATION → SNAPSHOT → EXTERNAL BOUNDARY

La vérification transforme une affirmation sur le travail en observation reproductible. Elle suit la [décision d'architecture d'information V1](../decisions/DECISION-2026-08-17-111018-vault-v1-information-architecture.md) et complète les [règles de conduite](../rules/RULES-2026-08-17-005717-vault-operating-rules.md).

## Deux principes

### Measure, don't copy

Un état technique qui peut être recalculé doit être mesuré au moment où il sert. Recopier durablement un hash, un compteur ou un ancien `git status` crée une valeur périssable qui peut diverger de la réalité.

Un rapport daté peut enregistrer une mesure comme preuve de son exécution. Il ne doit pas présenter cette mesure historique comme l'état courant permanent.

### Un contrôle existe ≠ le contrôle fonctionne

La présence d'un test, d'une règle, d'un hook ou d'une configuration prouve seulement que le contrôle existe. Pour savoir s'il fonctionne, il faut l'exécuter dans les conditions pertinentes, observer son résultat et, lorsque le risque le justifie, vérifier qu'il détecte bien un cas invalide.

## Modèle de preuve V1

```text
STATE → CHANGE → VALIDATION → SNAPSHOT → EXTERNAL BOUNDARY
```

Ces niveaux répondent à des questions différentes et se complètent. Aucun compteur ni message de succès isolé ne remplace l'ensemble des preuves pertinentes.

## `git status` — STATE

- **Rôle** : montrer l'état réel du working tree et de l'index par rapport à Git.
- **Problème détecté** : fichiers modifiés, ajoutés, supprimés, non suivis ou déjà staged ; branche inattendue.
- **Bénéfice** : établit rapidement le périmètre local avant et après une intervention.
- **Limites** : ne montre pas le contenu des changements, ne valide pas leur comportement et ne prouve pas l'absence d'effets externes antérieurs.
- **Quand l'utiliser** : au début, avant staging, avant commit et à la fin d'une mission.

La forme courte `git status --short --branch` facilite une preuve compacte ; la forme complète fournit davantage d'explications.

## `git diff` et diff staged — CHANGE

- **Rôle** : montrer le contenu exact du changement local.
- **Problème détecté** : modification accidentelle, contenu hors périmètre, suppression involontaire, secret visible, lien ou texte incorrect.
- **Bénéfice** : permet une revue ligne par ligne avant d'enregistrer un snapshot.
- **Limites** : `git diff` ne montre par défaut que les changements non staged ; `git diff --staged` ne montre que l'index. Les fichiers non suivis doivent aussi être repérés par `git status` et inspectés directement avant staging.
- **Quand l'utiliser** : après modification, avant staging pour chaque fichier, puis après staging sur l'ensemble du futur commit.

Pour une mission sûre, consulter les deux vues : `git diff -- <fichier>` pour le working tree et `git diff --staged` pour le contenu qui sera réellement commité.

## Tests et checks — VALIDATION

- **Rôle** : confronter le résultat aux comportements, contraintes ou formats attendus.
- **Problème détecté** : régression fonctionnelle, syntaxe invalide, lien cassé, structure incorrecte ou exigence non satisfaite, selon le contrôle choisi.
- **Bénéfice** : apporte une preuve comportementale ou structurelle que le diff seul ne fournit pas.
- **Limites** : un check ne couvre que ce qu'il teste. Un succès ne démontre pas l'absence de tous les défauts ; un contrôle non exécuté ne fournit aucune validation.
- **Quand l'utiliser** : après les changements et de nouveau sur le contenu staged lorsque le staging ou la génération peut modifier le résultat.

Les checks doivent être proportionnés au risque et explicitement rapportés avec leur commande, leur portée et leur résultat.

## Commit et hash — SNAPSHOT

- **Rôle** : figer un ensemble cohérent de changements dans l'historique local et lui donner un identifiant mesurable.
- **Problème détecté** : le hash, combiné au diff du commit, permet de constater qu'un contenu ou un historique n'est plus celui qui avait été validé.
- **Bénéfice** : fournit un point de reprise et une référence exacte pour la revue.
- **Limites** : un commit ne prouve ni la qualité du changement, ni le succès des tests, ni un push. Le hash dépend de l'objet Git complet et change si le commit est réécrit.
- **Quand l'utiliser** : après inspection du diff staged et réussite des checks pertinents.

Mesurer le snapshot courant avec `git rev-parse HEAD` et inspecter son contenu avec `git show --stat --oneline HEAD` ou `git show HEAD` selon le niveau de détail requis.

## Compteurs — sanity checks

- **Rôle** : fournir un contrôle rapide de plausibilité, par exemple le nombre de fichiers, de liens ou de résultats.
- **Problème détecté** : écart grossier, élément manquant, doublon ou ordre de grandeur inattendu.
- **Bénéfice** : signale rapidement qu'une inspection plus précise est nécessaire.
- **Limites** : un total correct peut masquer un contenu faux, et un total différent peut être légitime. Un compteur n'est jamais une preuve suffisante de conformité.
- **Quand l'utiliser** : comme complément à une inspection de contenu, jamais comme substitut au diff, aux tests ou à la revue.

## `git remote -v` — EXTERNAL BOUNDARY

- **Rôle** : révéler les remotes Git configurés et leurs URL de fetch/push.
- **Problème détecté** : frontière externe inattendue, destination de push erronée ou remote ajouté hors périmètre.
- **Bénéfice** : rend visible une partie de la frontière entre travail local et systèmes externes.
- **Limites** : une sortie vide prouve seulement qu'aucun remote n'est configuré à cet instant. La commande ne prouve pas à elle seule qu'aucune publication ou autre opération réseau n'a eu lieu.
- **Quand l'utiliser** : lors de la vérification initiale, avant toute action distante envisagée et dans les preuves finales d'une mission locale bornée.

Un remote, un push ou une publication constitue un effet externe distinct. Sa présence dans le plan exige le human gate prévu par les règles applicables.

## Checksums et empreintes — frontière read-only

- **Rôle** : comparer ponctuellement les octets d'une source lue avec ceux observés avant ou après une opération.
- **Problème détecté** : modification involontaire d'un fichier ou différence entre deux copies supposées identiques.
- **Bénéfice** : fournit une vérification précise d'intégrité à une frontière en lecture seule.
- **Limites** : une empreinte identique ne prouve ni la qualité ni l'authenticité de la source ; une empreinte copiée sans chaîne de confiance peut elle-même être fausse. Elle devient périssable si le fichier est autorisé à évoluer.
- **Quand l'utiliser** : lorsqu'une mission exige de démontrer qu'une source read-only n'a pas changé ou de comparer deux objets exacts.

Utiliser un algorithme de hash adapté et mesurer les deux côtés de la comparaison. Ne conserver l'empreinte que dans la preuve ponctuelle qui explique ce qu'elle vérifie.

## Séquence de vérification proportionnée

Pour une modification locale bornée :

1. mesurer la racine, la branche, le HEAD, le status et les remotes ;
2. inspecter les sources et les fichiers ciblés ;
3. examiner le status et chaque changement ;
4. exécuter les tests et checks pertinents ;
5. stage fichier par fichier ;
6. inspecter `git diff --staged` et vérifier l'absence de secret ;
7. créer le commit local autorisé ;
8. remesurer le HEAD, le status et la frontière externe.

Cette séquence produit des preuves complémentaires : elle ne transforme pas une mesure isolée en garantie générale.

## Liens

- `see also` — [Garde-fous et niveaux de preuve](../rules/RULES-2026-08-19-210803-guardrails-and-evidence-levels.md)
