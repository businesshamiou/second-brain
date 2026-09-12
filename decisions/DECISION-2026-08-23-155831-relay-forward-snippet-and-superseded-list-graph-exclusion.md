---
type: decision
title: "Sens aller du relais en snippet, et liste des remplacés hors graphe mais versionnée"
created_at: "2026-08-23T15:58:31-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
---

# DÉCISION — Sens aller du relais en snippet, et liste des remplacés hors graphe mais versionnée

## Date

2026-08-23

## Statut

`ARBITRATED`

Arbitrage : session Owner/Pilot du 2026-08-23, formalisé par la Mission 030 (historique de l'atelier, non distribué).

## Décision

Deux arbitrages de l'Owner du 2026-08-23.

1. **Sens aller du relais, gravé et livré en snippet.** Le mini-prompt qui ouvre une session Executor suit désormais une structure fixe à cinq rubriques (ligne de titre nommant la session, racine d'ouverture — le Vault en chemin absolu, source à appliquer — le chemin du fichier Mission relatif au Vault, interdits absolus, sortie attendue — le bloc RELAY de la Mission), et il est livré par le Pilot **en snippet copiable d'un seul geste** (bloc de code dans le chat), jamais en fichier à ouvrir ni en prose à recomposer. Le sens retour (bloc RELAY, gravé par la [Decision du 2026-08-23 12:49](./DECISION-2026-08-23-124937-role-relay-mini-prompts.md)) n'est pas modifié : les deux sens vivent désormais dans la même règle, [RULES-2026-08-23-124937](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md). *Note d'amendement (2026-08-26) : la rubrique « racine d'ouverture — le Vault en chemin absolu » ci-dessus est révoquée par la Décision `213150` — la position d'ouverture est libre ; voir `RULES-2026-08-23-124937` rubrique 2, amendée en conséquence.*

2. **Liste des fichiers remplacés (`superseded-files.txt`) exclue du graphe, mais versionnée.** Le fichier plat produit par `tools/build-indexes.sh` (Mission 029) est ajouté au `.graphifyignore` (supprimé, Mission 040) de chaque racine où il est produit — un fichier machine sans prose n'apportant que du bruit à un graphe sémantique — mais reste suivi par Git : sans lui sur une installation fraîche (clone), la marque `[REMPLACÉ]` de `tools/find-in-vault.sh` disparaît silencieusement.

## Raison

1. Un mini-prompt à recomposer de mémoire ou à retrouver dans un fichier introduit un risque de dérive à chaque passation ; un snippet copiable d'un seul geste, à cinq rubriques fixes, élimine ce risque et rend la passation aussi peu coûteuse à l'aller qu'au retour (bloc RELAY).
2. Un nœud de graphe pour un fichier plat sans prose ni relation sémantique ne sert aucune requête `graphify query`/`explain`/`path` ; l'exclure du graphe est un gain de signal sans perte. Mais l'exclure de Git supprimerait la fonctionnalité même que la Mission 029 vient de construire (marquage `[REMPLACÉ]`) sur toute installation qui ne régénère pas les index avant sa première recherche.

## Impact

- `vault/rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md` porte désormais les deux sens du relais (aller à cinq rubriques en snippet, retour en bloc RELAY) dans la même règle.
- `vault/.graphifyignore` (supprimé, Mission 040) et (historique de l'atelier, non distribué) (supprimé, Mission 040) excluent chacun `superseded-files.txt` de leur racine ; le fichier reste suivi par Git dans les deux dépôts (`git ls-files` déjà vérifié avant cette Decision : présent aux deux emplacements).
- Toute Mission future qui livre un mini-prompt d'ouverture de session Executor le fait en snippet à cinq rubriques, jamais autrement.

## Alternatives importantes

- Mini-prompt aller laissé en trois rubriques libres (état antérieur) : rejeté, la structure à cinq rubriques couvre un cas que les trois anciennes ne couvraient pas explicitement (la ligne de titre nommant la session, et la sortie attendue).
- Retirer `superseded-files.txt` de Git plutôt que du seul graphe : rejeté, ferait disparaître la marque `[REMPLACÉ]` sur toute installation fraîche qui n'a pas encore régénéré les index.
- Laisser `superseded-files.txt` entrer au graphe comme n'importe quel autre fichier suivi : rejeté, un fichier plat sans prose n'apporte que du bruit à un graphe sémantique (même motif que l'exclusion de `tools/`, `.githooks/` et `rules/patterns/` dans `.graphifyignore` (supprimé, Mission 040)).

## Human gate

- Validation : accordée
- Référence : arbitrage de l'Owner en session le 2026-08-23, exécuté par la Mission 030.

## Artefacts liés

- Mission d'exécution : (historique de l'atelier, non distribué)
- Règle amendée : `../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md`
- Rapport source du point « à trancher » : (historique de l'atelier, non distribué)

## Liens

- `applies` — [Relais entre rôles par mini-prompts à rubriques fixes](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `amended by` — Décision — Répertoire d'ouverture d'une session, position libérée (historique de l'atelier, non distribué)
- `see also` — [Adoption de la règle du relais entre rôles par mini-prompts](./DECISION-2026-08-23-124937-role-relay-mini-prompts.md)
- `see also` — Mission 030 — Sens aller du relais gravé, liste des remplacés hors graphe (historique de l'atelier, non distribué) (hors Vault)
