---
type: decision
title: "Contrat du Pilot, marquage des documents remplacés, et ratification de la convention de tags du journal"
created_at: "2026-08-23T14:35:42-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
---

# DÉCISION — Contrat du Pilot, marquage des documents remplacés, et ratification de la convention de tags du journal

## Date

2026-08-23

## Statut

`ARBITRATED`

Arbitrage : session Owner/Pilot du 2026-08-23, formalisé par la Mission 029 (historique de l'atelier, non distribué).

## Décision

Décision cumulative portant quatre points, tous issus de la proposal du 2026-08-23 14:01 (historique de l'atelier, non distribué) et de la Mission 029 qui l'exécute.

1. **Les trois arbitrages du §1 de la Mission 029.**
   - Correctifs exécutés en Mission immédiate, avant le lot B — le prompt d'ouverture cesse d'être une variable avant que l'étude de cas du lot B ne mesure des coûts d'ouverture.
   - La recherche par contenu signale les fichiers remplacés par une marque `[REMPLACÉ]` en fin de ligne ; la ligne reste toujours renvoyée, jamais filtrée.
   - Le contrat du Pilot compte sept lignes — les cinq de la proposal plus deux (ne jamais prétendre avoir lu ; horodatage réel et nom définitif avant fin de tour) — et il est **plafonné à sept lignes**, contrôle logiciel à l'appui dans `tools/build-state.sh`.

2. **Le texte des sept lignes du contrat et son plafond.** Le contrat vit dans `templates/pilot-contract-template.md`, jamais rédigé dans un script, et se lit :
   1. Aucun dépôt de fichier sans accord explicite de l'Owner, demandé juste avant d'écrire.
   2. Aucune lecture ni recherche hors de cette fiche sans l'annoncer (quel document, pourquoi) et attendre l'accord.
   3. La liste des points ouverts est un inventaire, pas une liste de tâches : ne rien traiter sans demande.
   4. Un document marqué remplacé n'est pas une source.
   5. Ne jamais dire qu'un fichier a été lu s'il ne l'a pas été ; distinguer ce qui est vérifié de ce qui est rapporté.
   6. Tout fichier déposé porte son horodatage réel et son nom définitif avant la fin du tour.
   7. Terminer chaque tour par la prochaine action proposée et les portes ouvertes.

   `tools/build-state.sh` échoue avec un message explicite, sans écrire la fiche d'état, si le gabarit porte un nombre de lignes différent de sept entre les repères `CONTRACT:BEGIN` / `CONTRACT:END`.

3. **Limite de fraîcheur de la marque `[REMPLACÉ]`.** La marque posée par `tools/find-in-vault.sh` provient de `superseded-files.txt`, un fichier plat généré par `tools/build-indexes.sh` à chaque régénération des index. Elle n'est donc fraîche qu'à la date de la dernière génération des index : un champ `supersedes` ajouté après coup dans le front-matter d'un document n'apparaît dans la recherche qu'après une régénération des index (`tools/build-indexes.sh <racine>`). Cette limite est structurelle, pas un défaut à corriger — elle est actée ici pour qu'elle ne soit pas découverte par surprise.

4. **Ratification de la convention de tags du journal.** Introduite sans spécification par l'Executor en Mission 027 (`OPEN 2` de son rapport), la convention `ETAT:` / `PROCHAIN:` / `OUVERT:` / `REPRISE:` en préfixe de ligne dans `<projet>/state/journal.md`, lue par `tools/build-state.sh`, est ratifiée telle quelle : dernière occurrence retenue pour `ETAT:` et `PROCHAIN:`, toutes les occurrences listées pour `OUVERT:`, et `REPRISE:` reconnue seulement en dernière ligne du journal. Une ligne de journal sans tag reconnu n'alimente aucune rubrique de la fiche d'état.

## Raison

Une règle de comportement gravée dans un fichier que le Pilot a ordre de ne pas lire à l'ouverture n'a aucune force (proposal du 2026-08-23 14:01 (historique de l'atelier, non distribué), §1) : un incident concret l'a montré (recherche lancée, fichiers lus, capture déposée en nom temporaire, contradiction signalée depuis un document explicitement remplacé — sans accord de l'Owner dans les quatre cas). Le contrat doit vivre là où l'agent regarde effectivement à l'ouverture : la fiche d'état. Le marquage des remplacés rend la quatrième ligne du contrat opérante en pratique plutôt que déclarative. La convention de tags du journal, en usage depuis Mission 027 sans ratification, ne doit pas devenir un usage figé par habitude sans passer par une Decision.

## Impact

- `templates/pilot-contract-template.md` devient la source unique du texte du contrat ; toute modification future du contrat passe par ce gabarit, sous contrôle du plafond de sept lignes.
- `tools/build-indexes.sh` et `tools/find-in-vault.sh` portent désormais le mécanisme de marquage des documents remplacés, sur les deux dépôts (Vault et (historique de l'atelier, non distribué)).
- `templates/session-opening-prompt-template.md` devient le prompt de réouverture de référence, sans règle de comportement dupliquée.
- La convention de tags du journal (`ETAT:`, `PROCHAIN:`, `OUVERT:`, `REPRISE:`) devient normative : toute Mission future qui alimente `<projet>/state/journal.md` s'y conforme, sauf Decision contraire.

## Alternatives importantes

- Rattacher ces correctifs au lot C (mécanique de session) plutôt qu'à une Mission immédiate : écartée, l'étude de cas chiffrée du lot B a besoin d'un prompt d'ouverture stable pour produire des mesures reproductibles.
- Ne pas étendre le marquage des remplacés à la recherche par contenu : écartée, la quatrième ligne du contrat (« un document marqué remplacé n'est pas une source ») resterait sans levier pratique pour un agent qui découvre un document par recherche plutôt que par l'index.
- Filtrer les lignes remplacées au lieu de les marquer : écartée, la Mission 029 exige explicitement que la ligne reste toujours renvoyée.

## Human gate

- Validation : accordée
- Référence : arbitrage de l'Owner en session le 2026-08-23, exécuté par la Mission 029.

## Artefacts liés

- Proposal source : (historique de l'atelier, non distribué)
- Mission d'exécution : (historique de l'atelier, non distribué)
- Rapport source de l'OPEN 2 ratifié : (historique de l'atelier, non distribué)

## Liens

- `source` — Proposal — Contrat de comportement du Pilot et marquage des documents remplacés (historique de l'atelier, non distribué) (hors Vault)
- `applies` — Mission 029 — Contrat du Pilot, marquage des remplacés, prompt d'ouverture minimal (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Sept arbitrages de session du 2026-08-23](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
- `amended by` — [Decision : taxonomie PIV, langue système anglaise, charte des rôles, fin des PROMPT, §4 ratification des tags de journal](./DECISION-2026-08-23-220049-piv-taxonomy-and-english-system-language.md)
- `amended by` — [Decision : extension de la convention de tags du journal — tag CLOSE: et portes à clé](./DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
