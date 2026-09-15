---
type: decision
title: "Bornage du standard de liens — la section ## Liens obligatoire s'applique au corpus du Vault, pas au matériel adopté de skills/external/"
description: "Grave l'arbitrage X de l'Owner : l'obligation de section ## Liens du standard de liens est bornée au corpus documentaire du Vault et ne s'applique pas aux fichiers de vault/skills/external/, matériel opérationnel adopté dont les corps restent verbatim ; la vérification de résolution des liens reste globale, y compris dans external/. check-links.sh est ajusté en conséquence, preuves par canaris."
created_at: "2026-08-28T20:36:27-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "../rules/RULES-2026-08-21-115658-document-linking-standard.md"
---

# DÉCISION — LA SECTION ## LIENS EST BORNÉE AU CORPUS, PAS AU MATÉRIEL ADOPTÉ

## Date

2026-08-28

## Statut

`ARBITRATED`

## Décision

**1. Bornage de la règle.** L'obligation de section `## Liens` gravée par le standard de liens (`RULES-2026-08-21-115658`) s'applique au **corpus documentaire du Vault** — règles, décisions, missions, rapports, captures, handoffs, propositions, notes de connaissance, gabarits et skills natifs. Elle ne s'applique **pas** aux fichiers de `vault/skills/external/` : matériel opérationnel adopté, corps verbatim garanti par empreintes (`DECISION-171209`), qui ne participe pas au graphe de citations du corpus.

**2. Ce qui reste global.** La vérification de **résolution** des liens relatifs demeure sur tout le dépôt, `skills/external/` compris : un lien cassé y reste un refus. Seule l'exigence de présence de la section est bornée.

**3. Exécution.** `tools/check-links.sh` est ajusté pour appliquer ce bornage — même patron que son bornage déjà arbitré sur les blocs de code — avec preuve par canaris dans les deux sens : un document du corpus sans `## Liens` reste refusé ; un fichier d'`external/` sans section passe ; un lien cassé dans `external/` reste refusé.

**4. Frontière de la décision.** Le jour où un skill adopté est promu par réécriture complète (corps compris) hors d'`external/`, il rejoint le corpus et l'obligation pleine s'applique à lui.

## Raison

Arbitrage X de l'Owner, 2026-08-28, sur mesure réelle : 54 fichiers amont sans section `## Liens`, zéro cible rompue (rapport 084+083). L'alternative — ajouter des sections dans les corps — aurait détruit la garantie corps-verbatim et ses 28 empreintes gravées le jour même, pour des sections sans objet : ces fichiers ne citent rien du corpus. La règle est légitime, son périmètre ne couvrait simplement pas un type de matériel qui n'existait pas quand elle a été écrite. C'est le cas anticipé et réservé à l'Owner par `DECISION-160213` §6, désormais mesuré.

## Impact

- `RULES-2026-08-21-115658` reçoit le lien réciproque `amended by` (même commit que cette gravure).
- `tools/check-links.sh` modifié, diff limité au bornage, canaris consignés.
- Le commit des 97 fichiers de `skills/external/` (en attente depuis la Mission 082) devient possible sans contournement ni section artificielle.
- La porte `open-guardrail-wiring-arbitration` n'est pas touchée ; le cas « narrowing check-links » déjà en file (exclusion des blocs de code) est distinct et demeure.

## Human gate

- Validation : accordée
- Référence : « je tranche : X », Owner, 2026-08-28, après présentation des deux voies et du conflit mécanique de L avec la garantie corps-verbatim.

## Artefacts liés

- Mesure source : (historique de l'atelier, non distribué) (54 refus de section, 0 cible rompue — hors dépôt).
- Doctrine des corps verbatim : (historique de l'atelier, non distribué) (hors dépôt).
- Mission d'exécution : (historique de l'atelier, non distribué) (hors dépôt).

## Liens

- `amends` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `applies` — Décision — Adoption par réécriture d'enveloppe V1 (historique de l'atelier, non distribué) (hors Vault)
- `see also` — Rapport — correctif du gardien et chaîne 083 (historique de l'atelier, non distribué) (hors Vault)
