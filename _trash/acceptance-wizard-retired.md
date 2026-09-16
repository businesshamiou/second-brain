---
type: note
title: "Wizard d'acceptation humain — retiré"
description: "Le wizard d'acceptation (tools/acceptance-wizard.sh) et son lanceur Windows (acceptance.ps1) sont retirés par la Décision du 2026-09-16 : l'acceptation de Second Brain est désormais la sortie de tests/run-mechanical-acceptance.ps1. Conservés ici, non supprimés, avec leur empreinte."
status: retired
---

# WIZARD D'ACCEPTATION HUMAIN — RETIRÉ

Depuis la v0.1.1, aucune étape d'acceptation ne demande un humain. Le rapport daté de `tests/run-mechanical-acceptance.ps1` (onze lignes, S1 à S10 et T21) est l'acceptation écrite d'un commit. S7 et S8 passent par `tools/acceptance-harness.sh`, S9 par `tests/test-install-standard-user.ps1`.

Les deux fichiers ci-dessous sont conservés tels qu'ils étaient au moment du retrait, jamais supprimés :

| Fichier conservé | Emplacement d'origine | SHA-256 au retrait |
|---|---|---|
| `acceptance-wizard.sh` | `tools/acceptance-wizard.sh` | `09c735973a1883cbf545aa92b1f0c8eb09267b3458b4866df309c4d87b0b9df4` |
| `acceptance.ps1` | `acceptance.ps1` (racine) | `5c5b78dc29a64656d9953178b94fe6b5cf9edb428ab955c93a5e2926dec6d234` |

Ils ne sont ni distribués ni maintenus : leurs quatre stages (rapport mécanique, S7, S8, S9) sont remplacés par des preuves rejouables.

## Liens

- `see also` — [Guide d'installation](../INSTALL.md)
