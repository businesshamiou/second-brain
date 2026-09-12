---
type: rules
title: "Règles de conduite du Vault central"
created_at: 2026-08-17T00:57:17-04:00
timezone: America/Montreal
status: active
---

# RÈGLES DE CONDUITE DU VAULT

## 1. Périmètre

Le Vault conserve seulement la connaissance et les mécanismes transversaux nécessaires au travail avec l’IA. Son architecture canonique est définie dans la [décision sur le Vault central](../decisions/DECISION-2026-08-17-003000-vault-central-architecture.md).

Les projets externes conservent leur contexte métier, leurs objectifs, leur état, leurs décisions et leurs artefacts. La production du workshop demeure également à l’extérieur du Vault.

## 2. Source de vérité

- les fichiers versionnés sont la source de vérité ;
- lire les sources et leurs liens avant de modifier ;
- une sortie générée ne devient pas canonique sans validation ;
- un fichier doit porter une idée principale et suffisamment de contexte pour être compris seul.

## 3. Langue et nommage

- prose et explications : français ;
- identifiants machine, slugs, clés et noms de dossiers : anglais idiomatique ;
- artefacts datés : `TYPE-YYYY-MM-DD-HHMMSS-description.ext` ;
- horodatage à la seconde dans le fuseau `America/Montreal` ;
- description en slug anglais, sans accent ni espace.

## 4. Décisions

- enregistrer toute décision structurante avec sa date, son statut, sa raison et son impact ;
- distinguer explicitement les décisions, propositions, hypothèses et éléments non vérifiés ;
- ne jamais transformer silencieusement une proposition en décision ;
- ne pas faire remonter automatiquement une décision propre à un projet dans le Vault.

## 5. Capitalisation depuis les projets

Une leçon découverte dans un projet peut être proposée au Vault uniquement si elle est généralisable. Son intégration exige une validation humaine préalable, conformément au [modèle opératoire](../knowledge/BRIEF-2026-08-17-003000-vault-concept-operating-model.md).

## 6. Git

- inspecter chaque fichier avant staging ;
- stage fichier par fichier ;
- inspecter le diff staged avant commit ;
- produire de petits commits cohérents avec un message explicite ;
- ne jamais push automatiquement ;
- exiger un human gate avant tout push ou commit sensible.

## 7. Sécurité

- aucun secret, token, mot de passe, credential ou clé privée dans les fichiers suivis ;
- ne pas partager de données sensibles sans validation humaine ;
- vérifier les fichiers avant commit.

## 8. Graphify

- Graphify aide à retrouver ce qui est écrit ; il n’invente pas une décision absente ;
- privilégier Markdown et les liens relatifs explicites ;
- utiliser `.graphifyignore` (supprimé, Mission 040) pour exclure le bruit ;
- ne jamais éditer manuellement `graphify-out/` (supprimé, Mission 040) ;
- ne considérer aucune fusion des graphes comme acquise avant test et validation.

## 9. Actions sensibles

Un human gate est requis avant :

- push ou création de remote ;
- suppression importante ;
- renommage structurant ;
- changement de source de vérité ;
- intégration d’une amélioration issue d’un projet ;
- partage de données sensibles.

## 10. Gel du stock

Une nouvelle règle de nommage ne déclenche aucun renommage massif rétroactif. Toute migration doit constituer un chantier explicite, inventorié et vérifié.

## Liens

- `amended by` — [Decision : taxonomie PIV, langue système anglaise, charte des rôles, fin des PROMPT, §3 langue](../decisions/DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md)
