---
type: decision
title: "Distribution des mécanismes transverses — doctrine unique, implémentation épinglée, adaptateur local"
created_at: "2026-08-24T21:46:07-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: granted
---

# DÉCISION — DISTRIBUTION DES MÉCANISMES TRANSVERSES

## Date

2026-08-24

## Statut

`ARBITRATED`

Human gate accordé par l'Owner en session du 2026-08-24 à 22:31:52-04:00, sur la mesure de la Mission 048.

## Décision

Trois classes d'objets, trois règles distinctes. La confusion actuelle vient de les traiter comme une seule.

**D1 — La doctrine vit dans le Vault, en exemplaire unique.** Règles, Decisions, gabarits. Jamais dupliquée dans un projet, jamais recopiée « pour commodité ». Deux copies d'une règle sont deux règles qui divergeront, et le jour de la divergence personne ne saura laquelle fait foi.

**D2 — Les mécanismes transverses ont une implémentation unique, consommée par version épinglée.** Contrôle de secrets, contrôle de liens, garde-fou d'obsolescence, générateurs de fiche d'état et d'index. Le code existe une fois. Un projet le consomme en déclarant *quelle version* il applique — jamais en atteignant un dossier frère par chemin relatif.

**D3 — Chaque projet ne porte qu'un adaptateur déclaratif et ses scripts de métier.** L'adaptateur dit quels contrôles s'appliquent et à quelle version. Les scripts propres au métier d'un projet restent dans ce projet et n'ont rien à faire dans le Vault.

**D4 — Critère d'arbitrage, opposable.** Devant tout script nouveau, une seule question : *ce projet, cloné seul sur une machine neuve, applique-t-il encore ses règles ?* Si la réponse est non, le couplage est mauvais et doit être refait.

**D5 — Dupliquer un adaptateur n'est pas dupliquer une règle.** Un hook Git est per-dépôt et per-clone par construction ; l'exiger unique serait exiger l'impossible. La duplication interdite porte sur la doctrine et sur le code du mécanisme, jamais sur les quelques lignes qui les invoquent.

**D6 — Aucune reprise rétroactive automatique.** Conformément aux règles de conduite du Vault §10, cette Decision n'ouvre aucune correction du stock existant. La convergence est un chantier explicite, ouvert par Mission distincte.

**D7 — Le véhicule d'épinglage est V1 : configuration épinglée.** Chaque projet porte un fichier de configuration déclarant les contrôles qu'il applique et la version exacte à laquelle il les applique. Arbitré sur la mesure de la Mission 048, qui a écarté V3 (dernier en gestes après clone nu et en montée de version) et départagé V1 de V2 sur la lisibilité de l'épinglage : un `rev` en configuration se lit et se revoit en diff, un pointeur de sous-module ne se lit pas.

Coût accepté et nommé : V1 est la seule des trois voies exigeant un outil tiers sur la machine (mesuré à 3,70 s + 2,31 s d'installation à froid). Si le dépôt distribuable destiné à des non-développeurs devient prioritaire, cette marche supplémentaire dans le questionnaire d'installation rouvre légitimement l'arbitrage.

## Raison

L'état actuel est un hybride accidentel, jamais décidé, mesuré par lecture directe le 2026-08-24 :

- `tools/check-secrets.sh` existe **en deux copies**, une par dépôt, libres de diverger en silence.
- `tools/check-links.sh` n'existe **que dans le Vault** et n'est jamais appelé depuis (historique de l'atelier, non distribué), dont le hook ne le mentionne pas.
- Le hook de (historique de l'atelier, non distribué) atteint le Vault par **`../vault/` en dur** pour lire le tampon de préflight.

Le troisième point est le plus grave, et pas pour une raison d'esthétique. La feuille de route prévoit un **dépôt distribuable séparé**, empaqueté par une Mission ultérieure avec questionnaire d'installation. Un dépôt qui exige la présence d'un dossier frère nommé `vault` sur la machine de l'utilisateur **n'est pas distribuable**. Le couplage par chemin de système de fichiers est calé exactement sur l'objectif produit qu'il empêchera d'atteindre.

## Impact

**Ce que ça coûte.** Un mécanisme central peut casser N projets d'un seul commit. C'est précisément ce que l'épinglage de version achète : un projet monte de version quand il le choisit, pas quand le Vault commite. **Centraliser sans épingler troquerait la duplication contre une fragilité pire** — c'est le seul mode d'échec sérieux de cette Decision, et D2 existe pour l'interdire.

**Ce que ça change en pratique.** Le garde-fou d'obsolescence livré par la Mission 046 fonctionne aujourd'hui — cinq cas fabriqués prouvés sur le hook réel. Cette Decision ne le remet pas en cause : elle change la manière dont il sera *atteint*. La transition est donc un moment de risque, et doit être prouvée avant d'être déclarée.

**Ce qui reste ouvert.** Deux faits que la Mission 048 n'a pas mesurés et qui doivent l'être avant mise en production :

- **Le mode de panne.** Que fait le contrôle quand la source des outils est inatteignable au moment du commit ? Refuse-t-il, ou laisse-t-il passer en silence ? C'est exactement le défaut corrigé par la Mission 046 dans le hook du Vault ; le réintroduire par le véhicule serait perdre ce qui vient d'être gagné.
- **SSH contre HTTP.** Le critère C4 a été mesuré sur un serveur HTTP Basic local. Un dépôt privé atteint en SSH ne se comporte pas de la même manière. Non mesuré.

Ces deux points sont prouvés dans la Mission de convergence, sur la voie retenue, plutôt que par une Mission de mesure supplémentaire.

## Alternatives importantes

- **Tout dupliquer par projet.** Rejetée : c'est l'état actuel de `tools/check-secrets.sh`, et la divergence silencieuse en est la conséquence mécanique, pas un accident.
- **Tout centraliser par chemin relatif.** Rejetée : fonctionne sur la machine de l'Owner, échoue sur toute autre. Incompatible avec le dépôt distribuable.
- **Copier/`cookiecutter` avec re-synchronisation.** Maintenue ouverte pour le gabarit de projet, où la dérive est admise puis réconciliée. Ne convient pas aux contrôles, qui doivent être identiques et non « proches ».
- **Ne rien décider et corriger au cas par cas.** Rejetée : c'est ce qui a produit l'hybride actuel.

## Human gate

- Validation : accordée
- Date : 2026-08-24T22:31:52-04:00
- Portée : D1 à D7, véhicule V1 inclus
- Référence : arbitrage rendu en session de pilotage sur le tableau 3 voies × 5 critères de la Mission 048

## Artefacts liés

- Mesure de l'état des hooks et des outils : lecture directe du 2026-08-24, session Pilot
- Mission ayant livré le garde-fou concerné : (historique de l'atelier, non distribué) (hors Vault)

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `applies` — [Règles de conduite du Vault](../rules/RULES-2026-08-17-005717-vault-operating-rules.md)
- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `see also` — Mission 046 — garde-fou d'obsolescence (historique de l'atelier, non distribué) (hors Vault)
