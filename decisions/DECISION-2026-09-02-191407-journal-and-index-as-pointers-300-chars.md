---
type: decision
title: "Décision — Journal et index en pointeurs : toute ligne ≤ 300 caractères, le récit vit dans le document pointé"
created_at: "2026-09-02T19:14:07-04:00"
timezone: America/Montreal
status: active
description: "Toute ligne future du journal et des index de Missions est un pointeur (date, tag, une phrase, nom du fichier) plafonnée à 300 caractères ; le détail vit dans le rapport, la capture ou le handoff pointé. Applicable par gardien."
---

# DÉCISION — Journal et index en pointeurs (≤ 300 caractères par ligne)

## Contexte

La Mission 120 a mesuré que le coût d'ouverture d'une session Pilot tient d'abord à la taille des lignes, pas au nombre de fichiers : des lignes de journal de 3 à 5 000 caractères, une ligne d'index de Missions à ~2 500 caractères, 55 969 octets prescrits à l'ouverture. La Mission 121 a créé un digest plafonné qui tronque ces lignes à la lecture ; il soulage le Pilot mais ne change pas la source, que l'Executor, les gardiens et la couche mémoire (Mission 122) continuent de lire en entier. Une règle plafonnée existe déjà pour une seule ligne — le `STATE:` de clôture, ≤ 300 caractères — mais elle est vérifiée par l'Executor sur consigne de Mission, pas par un gardien : aucun script ne refuse aujourd'hui une ligne trop longue (mesure : rapports 121 et 122 déclarent la longueur, aucun gardien ne l'impose). Cette Décision l'étend à toutes les lignes et exige sa mécanisation.

## Décision (Owner, chat, 2026-09-02)

1. **La ligne est un pointeur ; le document pointé est le récit.** Toute ligne ajoutée au journal du projet (fichier journal.md du dossier d'état) et toute ligne d'entrée de l'index de Missions du projet (fichier MISSION-INDEX.md du dossier des missions) porte : horodatage, tag, un résumé d'une phrase, et le nom du fichier où vit le détail. Mesures, listes, tableaux, justifications vivent dans le rapport, la capture, le handoff ou la Décision pointés — jamais dans la ligne.
2. **Plafond : 300 caractères par ligne**, journal et index, aligné sur la règle existante de la ligne `STATE:` de clôture.
3. **Non rétroactif.** Le journal est en ajout seul ; les lignes existantes ne sont ni réécrites ni tronquées. La règle s'applique aux lignes ajoutées après la gravure de cette Décision.
4. **Mécanisation obligatoire.** Une règle écrite sans gardien dérive : le plafond est appliqué par une butée fail-closed dans le mécanisme existant (`tools/append-journal.sh` pour le journal, `tools/check-indexes-fresh.sh` pour l'index de Missions), livrée par une Mission distincte. Tant que la butée n'est pas livrée, la règle est une consigne d'auteur, et le RELAY signale toute ligne qui la dépasse.
5. **Portée** : (historique de l'atelier, non distribué) d'abord ; la règle est un mécanisme du Vault (gardien distribuable), pas une convention locale.

## Conséquences

- Mission à rédiger : gardien « ligne ≤ 300 caractères » sur journal et index, fail-closed, câblé au pre-commit de (historique de l'atelier, non distribué) via épingle de révision (deux pushes minimum).
- Le skill `écriture-de-mission` et le skill `session-close` reprennent la règle dans leurs checklists (la ligne d'index d'une Mission se rédige en pointeur).
- Le digest d'ouverture (Mission 121) garde sa troncature à 300 caractères : redondance voulue, il reste correct sur les lignes anciennes.

## Liens

- `source` — Rapport 120 — audit de la boucle d'état (historique de l'atelier, non distribué) (hors Vault)
- `see also` — Mission 121 — digest d'ouverture plafonné (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Décision — tag CLOSE: et portes à clé du journal](./DECISION-2026-08-25-110935-journal-close-tag-and-keyed-doors.md)
- `applies` — [Décision — Statut de preuve et contrôle du STOP](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
