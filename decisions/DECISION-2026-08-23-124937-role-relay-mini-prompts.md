---
type: decision
title: "Adoption de la règle du relais entre rôles par mini-prompts"
created_at: "2026-08-23T12:49:37-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
---

# DÉCISION — Adoption de la règle du relais entre rôles par mini-prompts

## Date

2026-08-23

## Statut

`ARBITRATED`

Arbitrage : Owner le 2026-08-23, conception déléguée au Pilot.

## Décision

Adoption de la [règle du relais entre rôles par mini-prompts](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md), qui grave le texte de la proposal du relais par mini-prompts (historique de l'atelier, non distribué), §2, sans le modifier : quatre rubriques — Aller, Retour, Pont, Portée — formalisant la passation entre la fenêtre Pilot et la fenêtre Executor.

Le gabarit de rapport (`vault/templates/report-template.md`) porte désormais la section « Bloc RELAY » en fin de fichier, selon la proposal §3.

## Raison

Les structures fixes de transfert (type SBAR / I-PASS) relevées dans la recherche sur les registres de projets — chronologie, ancrages et objectif — doublent la réussite d'une reprise. Le canal actuel (rapport intégral relu par le Pilot à chaque retour) n'exploite pas ce gain : cette règle borne l'aller à trois rubriques et le retour à un bloc fixe, sans dupliquer le contenu de la Mission ni celui du rapport.

## Impact

Toute Mission ou instruction ponctuelle déléguée à l'Executor applique la règle. Le gabarit de rapport se termine par le bloc RELAY. `AGENTS.md` porte une ligne d'ancrage vers la règle. Cette Mission (028) applique elle-même la règle qu'elle grave : sa fenêtre se termine par le bloc RELAY rempli.

## Alternatives importantes

- Rapport intégral relu par le Pilot à chaque retour, sans bloc de synthèse fixe : c'est l'état antérieur, jugé insuffisant en séance au regard du gain mesuré par les structures fixes de transfert.
- Rubriques du bloc RELAY laissées libres plutôt que fixes : rejeté, la valeur de la structure SBAR / I-PASS tient à la fixité des rubriques.

## Human gate

- Validation : accordée
- Référence : arbitrage de l'Owner en session le 2026-08-23, formalisé par la Mission 028.

## Artefacts liés

- Proposal source : (historique de l'atelier, non distribué)
- Règle adoptée : `../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md`

## Liens

- `applies` — [Relais entre rôles par mini-prompts à rubriques fixes](../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — Proposal — Relais entre rôles par mini-prompts à rubriques fixes (historique de l'atelier, non distribué) (hors Vault)
- `see also` — Mission 028 — Gravure du rang 1 (historique de l'atelier, non distribué) (hors Vault)
