---
type: decision
title: "Canal de rapport d'exécution — type report, dossier reports/"
description: "Institue un rapport d'exécution en fichier, type report, dans (historique de l'atelier, non distribué), stagé avec le travail qu'il prouve."
created_at: 2026-08-21T00:02:36-04:00
timezone: America/Montreal
status: ARBITRATED
scope: executor-report-channel
owner_gate: granted
---

# DECISION — CANAL DE RAPPORT D'EXÉCUTION : TYPE REPORT, DOSSIER REPORTS/

## Contexte

L'Executor n'a aucun canal vers le Pilot : son rapport ne vivait que dans sa fenêtre de chat, et l'Owner le recopiait à la main. Depuis le 2026-08-20, le Pilot lit le système de fichiers directement (serveur MCP « workshops »). Un rapport écrit en fichier devient lisible par le Pilot sans intermédiaire, et survit à la fermeture de la fenêtre — ce qui n'est pas déposé est perdu.

Le dossier `audits/` existe mais porte une autre intention : un audit mesure un état à un instant ; un rapport rend compte d'une exécution. Les mélanger brouillerait les deux.

## Décision

Cette décision reprend, sans ajout de fond, les points de la proposal (historique de l'atelier, non distribué) qu'elle grave :

**D1.** Tout Prompt Executor exige un rapport d'exécution **en fichier**, dans (historique de l'atelier, non distribué) (dépôt (historique de l'atelier, non distribué)).

**D2 — Nommage.** `REPORT-YYYY-MM-DD-HHMMSS-NNN-executor-<slug>.md` ; une correction `Cxx` donne `NNN-Cxx`.

**Amendé le 2026-09-04** par la [Décision 145256](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md) : motif aligné sur l'usage mesuré (rapport 132, C6) — forme retenue `REPORT-<AAAA-MM-JJ>-<HHMMSS>-<mission_id>-<slug>.md`.

**D3 — Front-matter.** `type: report`, `role: executor`, `mission_id`, `related_mission`, `related_prompt`, `status: FINAL`, `created_at` au mtime réel, `timezone`.

**D4 — Contenu, dans cet ordre.** Gates en tête · fichiers créés et modifiés · SHA et messages des commits · état final mesuré · écarts avec le prompt · arrêt explicite. Une page cible. Sorties brutes seulement pour les mesures qui prouvent quelque chose.

**D5 — Staging.** Le rapport est stagé **dans le même commit** que le travail qu'il prouve.

**D6 — Canal chat.** En chat, l'Executor ne répète pas le rapport : deux lignes, chemin du fichier et ligne « gates ».

**D7 — Périmètre du graphe.** `reports/` appartient à la couche History / Evidence : exclu du graphe de (historique de l'atelier, non distribué) si un tel graphe voit le jour.

**D8 — Registre.** MISSION-INDEX.md (hors Vault) gagne une colonne « Rapport actif » lors de sa prochaine retouche. Pas de reprise rétroactive des lignées existantes.

## Raison

Le cycle devient lisible en un regard : Mission (ce qu'on veut) → Prompt (ce qu'on ordonne) → Report (ce qui s'est passé) → Audit (ce qu'on remesure après coup, si besoin). Le rapport devient une preuve committée au lieu d'un texte périssable. L'Owner cesse d'être le facteur entre les deux rôles.

## Impact

Un fichier court par Mission, coût négligeable. Premiers Prompts concernés : 020 et 019. Le présent rapport de Mission 020 en est le premier usage réel.

## Alternatives importantes

- Ranger le rapport dans `audits/` : rejeté, deux intentions différentes.
- Ranger le rapport à côté de sa Mission dans `missions/` : rejeté, un type par dossier.
- `LOG` : rejeté, évoque le transcript qu'on veut éviter, et OKF réserve log.md.
- `RUN`, `EVIDENCE`, `RECEIPT` : rejetés, jargon ou sens trop large.

## Human gate

- Validation : accordée
- Référence : arbitrage Owner/Pilot en session du 2026-08-20, gravé par la Mission 020 (MISSION-2026-08-20-234802-020-restore-semantic-graph-and-report-channel.md (historique de l'atelier, non distribué) (hors Vault)).

## Artefacts liés

- Proposal source : PROPOSAL-2026-08-20-234824-execution-report-channel.md (historique de l'atelier, non distribué) (hors Vault)
- Mission qui grave cette Decision : MISSION-2026-08-20-234802-020-restore-semantic-graph-and-report-channel.md (historique de l'atelier, non distribué) (hors Vault)

## Liens

- `source` — PROPOSAL-2026-08-20-234824-execution-report-channel.md (historique de l'atelier, non distribué) (hors Vault)
- `source` — MISSION-2026-08-20-234802-020-restore-semantic-graph-and-report-channel.md (historique de l'atelier, non distribué) (hors Vault)
- `applies` — missions/MISSION-INDEX.md (historique de l'atelier, non distribué) (hors Vault)
- `amended by` — [Décision — Amendement de deux normes gravées](./DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)
