---
type: rules
title: "Garde-fous et niveaux de preuve"
description: "Ce qui protège le dépôt, et comment qualifier un fait selon son niveau de persistance."
created_at: 2026-08-19T21:08:03-04:00
timezone: America/Montreal
status: active
scope: vault-guardrails
---

# GARDE-FOUS ET NIVEAUX DE PREUVE

## 1. Les trois niveaux de la vérité

Le mot « fait » est interdit seul. Toute affirmation qu'un travail est accompli précise son niveau de persistance :

| Niveau | Signification | Vérification |
|---|---|---|
| fait sur disque | le fichier existe et contient ce qu'on dit | lecture du fichier |
| fait committé | le contenu est entré dans l'historique local | `git log`, `git show` |
| fait poussé | le contenu existe hors de cette machine | `git status -sb`, mesure du distant |

Un travail fait sur disque et non committé disparaît avec un incident matériel. Un travail committé et non poussé disparaît avec la machine. Dire « c'est fait » sans qualificatif masque ce risque.

Cette échelle complète la doctrine de preuve sans la remplacer : `VERIFIED` dit **qui** a mesuré, les trois niveaux disent **jusqu'où** le travail est allé.

## 2. Le refus est la position par défaut

Face à une situation ambiguë, un mécanisme de contrôle refuse. Il ne laisse pas passer.

Cela vaut pour toute vérification automatique : un motif inconnu, une dépendance absente, un fichier illisible conduisent au blocage, jamais au passage silencieux. Un contrôle qui ne peut pas vérifier ne conclut pas que tout va bien.

Le même principe s'applique aux rôles : un agent qui ne peut pas trancher ne tranche pas — il mesure, il signale, et il s'arrête.

## 3. Une preuve se montre

Une affirmation sur l'état d'un dépôt s'accompagne de la mesure qui la fonde. Déclarer qu'un contrôle est passé ne vaut pas montrer sa sortie.

Corollaire : ne jamais reformuler un échec ou un refus en sa faveur. Un contrôle qui bloque est une information, pas un obstacle à contourner.

## 4. Un rôle ne modifie pas son propre garde-fou

Un agent ne désactive, ne contourne ni ne modifie un mécanisme qui le contraint, sauf autorisation explicite de l'Owner formulée dans la demande en cours.

Cela couvre les hooks, les fichiers de motifs, la configuration qui les active, et toute option de contournement.

Une autorisation donnée dans une session passée ne vaut pas pour la session courante.

## 5. Ce qui n'est pas déposé est perdu

Une connaissance produite en conversation et non écrite dans un fichier avant la clôture est réputée perdue.

Cela vaut pour un avis, un arbitrage, une observation utile, un principe découvert en chemin. La mémoire d'une session ne se transmet pas ; seul un fichier se transmet.

## 6. Un gate en attente se signale à chaque tour

Un gate humain non arbitré est rappelé à chaque tour, par chaque rôle, jusqu'à ce que l'Owner tranche.

L'Executor le place en tête de rapport, pas dans une liste d'anomalies résiduelles. Le Pilot le rappelle à l'ouverture de session et à chaque clôture de Mission.

Un gate qui dort dans une liste n'est pas un gate, c'est une note. Le silence prolongé sur un gate est lui-même une anomalie.

## 7. Aucun secret dans un fichier versionné

Aucune clé, aucun jeton, aucun mot de passe, aucun identifiant d'accès n'entre dans un fichier suivi par Git.

Les valeurs sensibles vivent dans un fichier d'environnement local, exclu du versionnement, et un modèle sans valeur documente les clés attendues.

Cette règle est vérifiée mécaniquement au commit. Le mécanisme ne dispense pas de la vigilance : il attrape ce qu'il connaît, pas ce qu'il ignore.

## 8. Les motifs de détection sont des données

Les motifs qui définissent ce qu'est un secret ou un contournement vivent dans des fichiers de données versionnés, jamais en dur dans un script.

Ils se lisent, se relisent et s'amendent sans toucher au code qui les applique. Un motif ajouté ne nécessite aucune modification du contrôle.

## 9. Portée des mécanismes

Un garde-fou du Vault s'applique quel que soit le client utilisé — un agent, un autre agent, un humain, un script. Aucun mécanisme de protection n'est câblé à un fournisseur particulier.

Un contrôle qui ne s'active que dans un outil donné n'est pas un garde-fou : c'est une convention locale, et elle doit être documentée comme telle.

## 10. Un garde-fou non éprouvé n'en est pas un

Un mécanisme de contrôle actif mais défaillant est plus dangereux que son absence : il donne une assurance fausse. Tout garde-fou est donc éprouvé par un essai qui doit échouer, avant d'être considéré comme en service.

L'essai fait partie de l'installation, pas de la vérification ultérieure. Un contrôle dont on n'a jamais observé le refus n'est pas installé : il est seulement présent.

## Liens

- `see also` — [Vérification et preuves](../knowledge/verification-and-evidence.md)
