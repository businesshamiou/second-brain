---
type: decision
title: "Décision — Dépendances machine avant cutover : sept arbitrages Owner sur le rapport 148, divergence mesurée du distant Legacy annotée, cible disque de la 143 laissée OPEN"
created_at: "2026-09-07T12:51:56-04:00"
timezone: America/Montreal
status: active
amends:
  - "./DECISION-2026-09-06-114521-legacy-already-prepared-migration-from-acquired-state.md"
description: "Arbitrages Owner du 2026-09-07 sur les sept questions du rapport 148 (inventaire lecture seule des dépendances du poste). Fait d'architecture mesuré et gravé : le Legacy et le NEXT poussent vers deux dépôts distants distincts (businesshamiou/vault.git et businesshamiou/ai-context-vault.git) ; la Décision 114521 est annotée, jamais réécrite. Cible distante finale confirmée : main moderne + branche legacy dans businesshamiou/vault. vault-view en statut LEGACY-2/UNKNOWN, intact et hors 143 ; sauvegarde backup-vault-migration non confirmée comme canonique ; tâches planifiées, profil PowerShell, Workspaces.lnk et safe.directory : aucune action avant v1.0.0-stable. Un point reste OPEN : l'emplacement disque de la 143 (aios-stable\\vault selon la PROPOSAL 165829, <depot-prive>-works\\vault selon l'arbitrage 5). Ordre de travail confirmé : push 4c9cc09, cette Décision, Mission 149 packed-refs, cold start rejoué, puis 143."
---

# DÉCISION — Sept arbitrages sur les dépendances machine avant cutover

## Contexte

La Mission 148 (rapport (historique de l'atelier, non distribué), hors Vault, commit l'atelier (historique, non distribué) `4c9cc09`) a inventorié en lecture seule ce qui, sur le poste, dépend d'un chemin de Vault : 188 tâches planifiées dont 2 retenues, 4 chemins de profil PowerShell dont 1 actif, 3 dépôts mesurés, 0 jonction NTFS, 14 fichiers de configuration, 0 accès refusé. Elle a posé sept questions sans recommandation. L'Owner a arbitré le 2026-09-07.

## Fait mesuré qui contredit une Décision gravée

Le rapport 148 (§5, question 1) mesure que `<depot-prive>-works\vault` a pour `origin` `businesshamiou/vault.git`, et `workshops\vault` (NEXT) `businesshamiou/ai-context-vault.git`. La Décision 114521 énonçait « l'ancien contenu vit comme branche du même dépôt distant que le nouveau Vault ». C'est la divergence nouvelle et mesurée que cette Décision prévoyait. Conformément à la Décision 145256, la 114521 n'est pas réécrite : elle reçoit une annotation datée nommant la présente Décision, avec réciprocité `amends` / `amended by`.

## Décision (Owner, 2026-09-07, verbatim)

1. **Distant Legacy.** OUI, `legacy` est bien conservée sur `businesshamiou/vault.git`. En revanche, `ai-context-vault.git` reste le dépôt actuel/source du NEXT ; il ne devient pas automatiquement le dépôt canonique final. La cible déjà décidée reste : futur `main` moderne + branche `legacy` dans `businesshamiou/vault`. Annoter la divergence mesurée sans réécrire la Décision historique.
2. **`vault-view`.** Statut provisoire LEGACY-2 / UNKNOWN. Le laisser strictement intact, hors cutover et hors scope de la 143. Ne pas le « sécuriser comme le Legacy » ni l'ouvrir davantage tant que son rôle n'est pas établi.
3. **`backup-vault-migration\2026-09-05-200520\`.** NON CONFIRMÉ comme sauvegarde froide canonique. Ne pas l'utiliser comme preuve de satisfaction de la Décision 114521 sans preuve existante qui l'identifie explicitement. Le laisser intact.
4. **`VaultDoctorNightly` et `VaultReflect`.** Ne rien modifier pendant la 143. Après `v1.0.0-stable`, vérifier que leurs commandes existent encore dans le Vault moderne ; si oui, les repointer vers la production stable. Si la fonction correspondante n'existe plus, les désactiver plutôt que recréer artificiellement une dépendance.
5. **Profil PowerShell.** Ne rien modifier avant le cutover/tag. La cible finale étant `<depot-prive>-works\vault`, valider après cutover que le dot-source résout bien vers le nouveau Vault ; ne modifier le profil que si le fichier cible a réellement changé de chemin.
6. **`Workspaces.lnk`.** Hors produit et hors cutover. Ne pas le déplacer en `_trash` maintenant. Le laisser intact et reporter son éventuel nettoyage après stabilisation ; il ne doit ni bloquer ni entrer dans la 143.
7. **`safe.directory` global.** Aucune action maintenant. La 143 mesure le comportement sur le clone STABLE. N'ajouter une exception `safe.directory` que si Git la réclame réellement et dans le cadre du geste Owner correspondant.

Ces arbitrages ne changent pas l'ordre convenu : (1) pousser `4c9cc09` ; (2) enregistrer ces arbitrages ; (3) intervention courte `packed-refs` en Mission 149 ; (4) rejouer le cold start pour vérifier `READY` et le budget d'appels ; (5) seulement après PASS de cette acceptance, reprendre la 143. Ne pas rouvrir Mnemosyne, OpenViking, Legacy ni un chantier d'architecture mémoire.

## Point laissé OPEN — non comblé par le Pilot

**Emplacement disque de la 143.** L'arbitrage 5 nomme `<depot-prive>-works\vault` comme cible finale. La PROPOSAL 165829 (acceptée) prescrit un clone vers `<depot-prive>-works\aios-stable\vault`, `<depot-prive>-works\vault` restant LEGACY intact sur disque. Deux emplacements pour un même geste. Tant que l'Owner n'a pas dit lequel est celui de la 143 — ou si le second est une étape ultérieure —, la 143 ne s'écrit pas. Une annotation datée sur la présente Décision fermera ce point.

   **Annotation datée 2026-09-08 (Owner, chat, consignée par la Mission 165).** L'emplacement disque de la 143 est <depot-prive>-works, sous-dossier aios-stable, sous-dossier vault ; <depot-prive>-works, sous-dossier vault seul, reste LEGACY intact sur disque, inchangé par la 143. Le point est fermé.

## Conséquences

- Précondition de la Mission 143 : la branche `legacy` se vérifie par `git ls-remote` sur `businesshamiou/vault.git` ; le clone STABLE part de la tête poussée de `ai-context-vault.git`. Le dépôt canonique final (`businesshamiou/vault`, `main` moderne + `legacy`) est une cible de promotion distante, postérieure au tag, qui exige son propre human gate (nouvelle frontière externe).
- La Mission 143 ne mentionne ni `vault-view`, ni `backup-vault-migration\`, ni `Workspaces.lnk`, sauf pour constater qu'ils sont intacts.
- Les gestes 4 et 5 sont des gestes Owner post-`v1.0.0-stable`, à mesurer par une Mission de lecture avant tout repointage.
- La Mission 149 commite la présente Décision, l'annotation de la 114521 et l'index des Décisions dans son lot vault.

## Alternatives écartées

- Comprendre l'arbitrage 5 comme un changement de cible de la 143 : c'est une lecture, pas un arbitrage ; le Pilot ne remplit pas un OPEN par proximité (charte §2).
- Réécrire la Décision 114521 : interdit par la Décision 145256.

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amends` — [Décision — Legacy déjà préparé, migration depuis l'acquis](./DECISION-2026-09-06-114521-legacy-already-prepared-migration-from-acquired-state.md)
- `applies` — [Décision — Statut de preuve et contrôle du STOP](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `source` — Rapport 148 — inventaire lecture seule des dépendances machine (historique de l'atelier, non distribué) (hors Vault)
- `see also` — PROPOSAL — Fermeture de la V1 (historique de l'atelier, non distribué) (hors Vault)
