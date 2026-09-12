---
type: provenance
title: "Provenance — bibliothèque de skills externes skills/external/"
description: "Note de provenance de la bibliothèque de 40 skills externes (DECISION-2026-08-31-231841) construite depuis le paquet du projet skills-warehouse (affiliate-pro-skills-full.zip) : identité du paquet, comptes A/B/C/D/N (Mission 106) puis I/UD/UB/B/O/R (Mission 108, paquet reconstruit), forme standard Agent Skills (six champs, provenance sous metadata), emplacement de l'ancienne bibliothèque V1 en _trash/, et le journal complet des cycles antérieurs."
created_at: "2026-09-01T00:20:00-04:00"
timezone: America/Montreal
status: active
scope: skills-external-provenance
---

# PROVENANCE — `skills/external/`

Ce dossier est une frontière de provenance (`DECISION-2026-08-28-160213` §2) : il ne contient que du matériel d'auteurs tiers, jamais les skills propres du Vault.

**2026-09-01 — remplacement intégral par le paquet du `skills-warehouse` (Mission 106, `DECISION-2026-08-31-231841`).** La bibliothèque V1 (30 skills, enveloppes à clés plates) est remplacée par une bibliothèque en **forme standard Agent Skills** : chaque `SKILL.md` porte au plus les six champs `name`, `description`, `license`, `compatibility`, `allowed-tools`, `metadata` ; toute provenance Vault vit sous `metadata:` en paires chaîne → chaîne. L'ancienne bibliothèque est intégralement conservée, jamais supprimée — voir « Ancienne bibliothèque (V1) » ci-dessous.

**2026-09-01 — mise à jour depuis le paquet reconstruit (Mission 108).** Le warehouse a reconstruit `affiliate-pro-skills-full.zip` (33/33 en forme standard, 0 champ hors des six, 12 descriptions raccourcies) : SHA-256 `8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb`. Cycle update-ou-rejet (`DECISION-2026-08-28-171209` §2) sur les 38 skills de la Mission 106 : deux nouveaux installés (`implement`, `wait-what`), onze descriptions alignées, dix corps remplacés verbatim, les sept skills absents du paquet laissés intacts. La bibliothèque passe de 38 à **40** skills. Détail complet ci-dessous, section « Mise à jour — paquet du 2026-09-01 (Mission 108) ».

## Source — paquet du 2026-09-01

- **Projet** : `skills-warehouse` (« canonical warehouse for Agent Skills », voir `README.md`/`AGENTS.md` du paquet).
- **Paquet** : `affiliate-pro-skills-full.zip`, chemin fourni par l'Owner (hors workspace) : `C:\Users\<utilisateur>\Workspaces\skills-folder\affiliate-pro-skill-pack\dist\affiliate-pro-skills-full.zip`.
- **Taille** : `6 782 829` octets.
- **SHA-256** : `e23edad2c53db59d9e10445c04e8c9b5733e47e69e06c7585505658dbf4fe45f` — recoupé avec `SHA256SUMS.txt` (ligne 1) et `validation-report.md` fournis dans le même dossier (« Résultat : PASS », « Skills actifs : 33 »).
- **Date d'entrée** : 2026-09-01 (Mission 106, reprise après correctif du gardien de réciprocité — Mission 107).
- **Extraction** : `dossier_skills/warehouse-affiliate-pro-20260901/` (hors dépôts, zone de travail).

## Comptes (étape 3 de la Mission 106)

Le paquet contient **33** `SKILL.md` (un par dossier sous `skills/`, aucune sous-arborescence). Comparaison aux 30 skills de l'ancienne bibliothèque, puis filtrage de conformité (six champs de la spécification Agent Skills) :

| Case | Compte | Définition |
|---|---:|---|
| **A** | 11 | dans le paquet **et** conforme **et** dans l'ancienne bibliothèque → installé depuis le paquet |
| **B** | 8 | dans le paquet **et** conforme **et** absent de l'ancienne bibliothèque → nouveau, installé depuis le paquet |
| **C** | 19 | dans l'ancienne bibliothèque, sans remplaçant utilisable dans le paquet (absent, ou présent mais non conforme) → converti depuis la copie V1 |
| **D** | 0 | doublon interne au paquet (deux dossiers pour un même nom canonique) |
| **N** | 14 | dans le paquet mais portant un champ hors des six autorisés → listé, **non installé tel quel** |

Cohérence vérifiée par les deux identités prescrites par la Mission : **A + C = 11 + 19 = 30** (les 30 skills de l'ancienne bibliothèque sont tous comptés, soit remplacés par le paquet, soit convertis) ; **A + B + D + N = 11 + 8 + 0 + 14 = 33** (les 33 skills du paquet sont tous comptés). Nouvelle bibliothèque : **A + B + C = 11 + 8 + 19 = 38** dossiers.

### Case N — non conformes, listés, non installés

| Skill | Champ fautif | Disposition |
|---|---|---|
| `ask-matt` | `disable-model-invocation` | copie V1 conservée → case C |
| `grill-me` | `disable-model-invocation` | copie V1 conservée → case C |
| `grill-with-docs` | `disable-model-invocation` | copie V1 conservée → case C |
| `handoff` | `argument-hint`, `disable-model-invocation` | copie V1 conservée → case C |
| `implement` | `disable-model-invocation` | absent de l'ancienne bibliothèque, aucune disposition — simplement non installé |
| `improve-codebase-architecture` | `disable-model-invocation` | copie V1 conservée → case C |
| `setup-matt-pocock-skills` | `disable-model-invocation` | copie V1 conservée → case C |
| `teach` | `argument-hint`, `disable-model-invocation` | copie V1 conservée → case C |
| `to-questionnaire` | `disable-model-invocation` | copie V1 conservée → case C |
| `to-spec` | `disable-model-invocation` | copie V1 conservée → case C |
| `to-tickets` | `disable-model-invocation` | copie V1 conservée → case C |
| `triage` | `disable-model-invocation` | copie V1 conservée → case C |
| `wait-what` | `disable-model-invocation` | absent de l'ancienne bibliothèque, aucune disposition — simplement non installé |
| `wayfinder` | `disable-model-invocation` | copie V1 conservée → case C |

Note : `implement` et `wait-what` figuraient parmi les 8 skills refusés au seuil de score (`DECISION-2026-08-28-151235` §3) ; leur non-conformité ici est une observation indépendante, pas une réouverture de ce refus.

### Case D — doublons internes au paquet

Aucun (0/33). Vérifié par unicité des 33 noms de dossier et concordance `name:` = nom de dossier sur les 33.

### Case C — convertis depuis la copie V1 (corps intact, en-tête réduit à la forme standard)

`ask-matt`, `grill-me`, `grill-with-docs`, `handoff`, `implement-spec`, `improve-codebase-architecture`, `loop-me`, `retro`, `setup-matt-pocock-skills`, `setup-ts-deep-modules`, `teach`, `to-questionnaire`, `to-spec`, `to-tickets`, `triage`, `wayfinder`, `writing-beats`, `writing-fragments`, `writing-shape` — 19 skills. Sept d'entre eux (`implement-spec`, `loop-me`, `retro`, `setup-ts-deep-modules`, `writing-beats`, `writing-fragments`, `writing-shape`) sont absents du paquet par le nom ; les douze autres sont présents dans le paquet mais non conformes (case N ci-dessus), donc sans remplaçant utilisable — leur copie V1 sert de source.

## Mise à jour — paquet du 2026-09-01 (Mission 108)

### Source — paquet reconstruit

- **Paquet** : `affiliate-pro-skills-full.zip`, chemin fourni par l'Owner (hors workspace) : `C:\Users\<utilisateur>\Workspaces\skills-folder\affiliate-pro-skill-pack\dist\2026-09-01-vault-package\affiliate-pro-skills-full.zip`.
- **SHA-256** : `8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb` — recoupé avec `SHA256SUMS.txt` (213 lignes, `sha256sum -c` 213/213) et `validation-report.md` fournis dans le même dossier (33/33 PASS six champs, 0/33 écart de corps avec le paquet précédent `e23edad2…`, 12/33 descriptions changées).
- **Date d'entrée** : 2026-09-01 (Mission 108, après l'instruction ponctuelle qui a reconstruit le paquet — rapport `REPORT-2026-09-01-103638-adhoc-executor-affiliate-pro-skills-header-cleanup.md`).
- **Extraction** : `dossier_skills/warehouse-affiliate-pro-20260901-8d4a5624/` (hors dépôts, zone de travail).

### Cycle update-ou-rejet (`DECISION-2026-08-28-171209` §2)

Comparaison des 33 `SKILL.md` du paquet aux 38 skills de la bibliothèque (Mission 106), par empreinte de corps (`U` = corps du paquet, `V` = `metadata.vault-body-sha256` installé) et par description :

| Case | Compte | Définition |
|---|---:|---|
| **I** | 10 | même nom, `U = V`, description égale → aucune écriture sur le corps ni la description ; provenance (`vault-source`, `vault-source-sha256`) alignée sur le nouveau paquet |
| **UD** | 11 | même nom, `U = V`, description différente → description remplacée par celle du paquet, corps intact |
| **UB** | 10 | même nom, `U ≠ V` → corps et fichiers compagnons remplacés verbatim depuis le paquet ; `license`/`upstream-repo`/`upstream-version` historiques conservés tels quels |
| **B** | 2 | dans le paquet, absent de la bibliothèque → installé neuf (`implement`, `wait-what`) |
| **O** | 7 | dans la bibliothèque, absent du paquet → intact, aucun octet touché (`implement-spec`, `loop-me`, `retro`, `setup-ts-deep-modules`, `writing-beats`, `writing-fragments`, `writing-shape`) |
| **R** | 0 | skill du paquet rejeté (champ hors des six, ou empreinte `SHA256SUMS.txt` en échec) → aucun |

Identités vérifiées : **I + UD + UB + B + R = 10 + 11 + 10 + 2 + 0 = 33** (paquet) ; **I + UD + UB + O = 10 + 11 + 10 + 7 = 38** (bibliothèque avant mise à jour). Bibliothèque après : **I + UD + UB + B + O = 10 + 11 + 10 + 2 + 7 = 40**.

- **I** : `diagnosing-bugs`, `domain-modeling`, `grilling`, `migrate-to-shoehorn`, `prototype`, `resolving-merge-conflicts`, `tdd`, `teach`, `to-questionnaire`, `writing-for-agents`.
- **UD** : `code-review`, `codebase-design`, `excalidraw-automate`, `git-guardrails-claude-code`, `research`, `scaffold-exercises`, `script-to-whiteboard-storyboard`, `scroll-film-studio`, `scroll-world`, `setup-pre-commit`, `wizard`.
- **UB** : `ask-matt`, `grill-me`, `grill-with-docs`, `handoff`, `improve-codebase-architecture`, `setup-matt-pocock-skills`, `to-spec`, `to-tickets`, `triage`, `wayfinder`.
- **B** : `implement`, `wait-what`.
- **O** (intacts) : `implement-spec`, `loop-me`, `retro`, `setup-ts-deep-modules`, `writing-beats`, `writing-fragments`, `writing-shape`.

**Écart consigné — liste UD vs `validation-report.md` §3 du paquet.** Ce dernier liste 12 descriptions changées par rapport au paquet précédent, dont `to-tickets`. Ici, `to-tickets` tombe en **UB** et non en UD : son corps installé provenait de la copie V1 (`vault-source: "library-v1-converted"`, jamais comparé au warehouse avant ce cycle), donc `U ≠ V` en plus du changement de description — les deux se recouvrent, classé UB par priorité (corps prioritaire sur description dans la règle de classement). Les 11 autres UD concordent exactement avec la liste des 12 du `validation-report.md` moins `to-tickets`. Aucune anomalie : le `validation-report.md` comparait le paquet à son seul prédécesseur direct (`e23edad2…`), pas à l'état mixte de la bibliothèque Vault.

**Écart consigné — `vault-source-sha256` résiduel.** La rubrique Validations de la Mission attendait `e23edad2…` sur 0/40 skills après ce cycle ; les Interdits absolus de la même Mission imposent en parallèle « aucun octet touché sur les 7 skills absents du paquet ». Les deux clauses se contredisent pour les 7 O : ne pas les toucher (retenu, conforme aux Interdits absolus et à la définition même de la case O) laisse mécaniquement `vault-source-sha256 = e23edad2…` sur ces 7 — c'est la seule lecture qui ne fait rien d'irréversible sur du contenu hors périmètre. État final : `vault-source-sha256 = 8d4a5624…` sur 33/40 (I+UD+UB+B), `= e23edad2…` sur 7/40 (les O), `vault-source = "library-v1-converted"` restant sur 7/40 (les mêmes O).

## Forme standard (`DECISION-2026-08-31-231841` §1)

Chaque `SKILL.md` porte au plus `name`, `description`, `license`, `compatibility`, `allowed-tools`, `metadata`. Sous `metadata:`, paires chaîne → chaîne uniquement :

- `vault-source` : nom du paquet (`affiliate-pro-skills-full.zip`) pour A/B, `"library-v1-converted"` pour C.
- `vault-source-sha256` : `e23edad2c53db59d9e10445c04e8c9b5733e47e69e06c7585505658dbf4fe45f` à l'entrée (Mission 106, sur les 38) ; depuis la mise à jour Mission 108, `8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb` sur 33/40, `e23edad2…` restant sur les 7 O non touchés — voir section « Mise à jour — paquet du 2026-09-01 (Mission 108) ».
- `vault-body-sha256` : empreinte SHA-256 du corps (après le `---` fermant), vérifiée égale avant/après écriture sur les 38.
- `vault-entered` : `2026-09-01`.
- `upstream-repo`, `upstream-version` : transposés depuis `metadata-upstream-*` de l'enveloppe V1, sur les 19 C (tous `github.com/mattpocock/skills` / `1.2.3`). Aucun `upstream-commit` connu (jamais consigné par skill dans l'enveloppe V1).
- `claude-code-disable-model-invocation`, `claude-code-argument-hint` : extensions Claude Code de l'enveloppe V1, transposées avec préfixe, sur les C qui les portaient (19 pour la première, 3 — `handoff`, `loop-me`, `teach` — pour la seconde).
- `license: "MIT"` (champ standard, pas sous `metadata:`) posé sur les 19 C, valeur reprise de `metadata-upstream-license` de l'enveloppe V1.

Vérification de forme : 38/38 `SKILL.md` sans champ hors des six ; 38/38 blocs `metadata:` en paires chaîne → chaîne exclusivement (script de vérification dédié, voir rapport).

## Licence

- **`LICENSE-mattpocock-skills.txt`** (MIT) : conservée à la racine de `external/`, référencée par les 19 C (skills issus à l'origine de `github.com/mattpocock/skills`, licence portée par leur `license: "MIT"`).
- **Licences par skill du paquet** : `excalidraw-automate/LICENSE` et `scroll-world/LICENSE`, fournies par le paquet lui-même, conservées verbatim comme fichiers compagnons dans leurs dossiers respectifs (aucun top-level de licence unique pour l'ensemble du paquet).
- Les 9 autres A/B (`code-review`, `codebase-design`, `diagnosing-bugs`, `domain-modeling`, `grilling`, `prototype`, `research`, `scroll-film-studio`, `tdd`, `wizard`, `writing-for-agents`, `git-guardrails-claude-code`, `migrate-to-shoehorn`, `resolving-merge-conflicts`, `scaffold-exercises`, `script-to-whiteboard-storyboard`, `setup-pre-commit`) ne portent aucune mention de licence dans le paquet ; aucun champ `license:` posé, statut non déterminé. **Résolu par la Mission 116, voir « Licences (Mission 116) » ci-dessous.**

## Licences (Mission 116)

**2026-09-01 — 21 `SKILL.md` sans champ `license:` (rapport `REPORT-2026-09-01-225118-115-…-STOP2`) reçoivent leur valeur depuis l'inventaire prouvé de l'Owner** (`KNOWLEDGE-NOTE-2026-09-01-230251-skills-warehouse-license-policy-and-inventory`, 33 skills audités par le warehouse, source figée et preuve par skill). Front-matter seul modifié ; corps et fichiers compagnons intacts, empreintes `vault-body-sha256` vérifiées égales avant/après sur les 21.

Répartition finale des 40 skills externes :

| Catégorie | Compte | Détail |
|---|---:|---|
| `MIT` (inventaire warehouse) | 30 | 29 mattpocock (commit `6654f6b6…`) + 1 `scroll-world` (commit `71cc36d3…`) — 12 portaient déjà `license: "MIT"` avant cette Mission, 18 reçus ici |
| `AGPL-3.0-only` | 1 | `excalidraw-automate` (commit `052dfe3c…`), exception Owner explicite à la politique permissive par défaut, texte AGPL conservé dans `excalidraw-automate/LICENSE` |
| `NOASSERTION` + exception Owner | 2 | `script-to-whiteboard-storyboard`, `scroll-film-studio` — aucune licence trouvée, inclusion décidée par l'Owner (« inclure-33 », 2026-09-01), voir `OWNER-EXCEPTIONS.md` |
| `MIT` (V1-only, hors inventaire des 33) | 7 | `implement-spec`, `loop-me`, `retro`, `setup-ts-deep-modules`, `writing-beats`, `writing-fragments`, `writing-shape` — même amont mattpocock, même commit, `license: "MIT"` depuis la Mission 104, non touchés par la 116 |

**Total : 30 + 1 + 2 + 7 = 40.** Chaque skill de l'inventaire des 33 porte désormais `metadata.upstream-repo` (source figée) et `metadata.upstream-license-evidence` (URL de preuve, ou constat en une phrase pour les deux NOASSERTION). Les exceptions (`AGPL-3.0-only`, les deux `NOASSERTION`) sont détaillées dans [`OWNER-EXCEPTIONS.md`](./OWNER-EXCEPTIONS.md) et reprises dans `LICENSES.md` de tout paquet construit (`tools/build-package.sh`, Mission 115-116).

## Ancienne bibliothèque (V1) — conservée, jamais supprimée

Déplacée intégralement (`DECISION-2026-08-29-110852`) vers `_trash/skills-external-v1-20260901-000337/` avant toute écriture dans la nouvelle `external/`. Empreinte d'ensemble (liste triée des 133 fichiers + SHA-256 de chacun, empreinte globale du manifeste) mesurée avant déplacement et remesurée après : **`1208368d8a317177df3ca01d3b977d753e22a33c2762e9f6557d83deba6fd54c`**, égale des deux côtés, 133 fichiers. Absence remesurée à l'ancien emplacement (`vault/skills/external/` ne contenait plus que le dossier lui-même, videmment absent après déplacement).

## Journal des cycles antérieurs (bibliothèque V1, close le 2026-09-01)

- **2026-08-28** — installation en portée personnelle (`C:\Users\<utilisateur>\.claude\skills\`), 28 dossiers, 94 fichiers (Mission 081).
- **2026-08-28** — entrée dans le Vault (`vault/skills/external/`), même contenu, copie vérifiée avant toute jonction (Mission 082, exécution de `DECISION-2026-08-28-160213`).
- **2026-08-30** — cycle update-ou-rejet (Mission 104, exécution de `DECISION-2026-08-28-171209`) : clone amont mesuré au commit `6654f6b60cd9d5be8b54c6fafe44346dabeb3b76` (`package.json` toujours à la version `1.2.3` — commits amont non versionnés depuis le dernier changeset), 24/27 skills de la case A mis à jour (corps + fichiers compagnons remplacés verbatim), 3/27 déjà identiques (`grill-me`, `grill-with-docs`, `handoff`), **0 CONFLIT, 0 ANOMALIE**. `metadata-upstream-version` reste `"1.2.3"` sur les 27 (valeur mesurée inchangée). `scroll-film-studio` non touché (aucun amont). Détail : (historique de l'atelier, non distribué) (hors Vault).
- **2026-08-30** — `implement-spec` et `retro` entrent dans le Vault (Mission 105-C01), depuis le même clone amont, même commit `6654f6b60cd9d5be8b54c6fafe44346dabeb3b76`, `metadata-upstream-version` `"1.2.3"` : adoption par arbitrage Owner nominatif, `DECISION-2026-08-30-210726`, non audités. La liste passe de 28 à 30.
- **2026-09-01** — remplacement intégral par le paquet du `skills-warehouse` (Mission 106, reprise après le correctif du gardien de réciprocité de la Mission 107) : voir sections ci-dessus. La liste passe de 30 à 38 (11 remplacés depuis le paquet, 19 convertis depuis leur copie V1, 8 nouveaux) ; ancienne bibliothèque V1 intégrale dans `_trash/skills-external-v1-20260901-000337/`.
- **2026-09-01** — mise à jour depuis le paquet reconstruit par le warehouse (Mission 108, cycle update-ou-rejet `DECISION-2026-08-28-171209` §2) : SHA-256 `8d4a5624…`, classement I=10/UD=11/UB=10/B=2/O=7/R=0 (détail section ci-dessus), deux nouveaux (`implement`, `wait-what`). La liste passe de 38 à **40**. Copie de sauvegarde de la bibliothèque (v2) dans `_trash/skills-external-v2-20260901-105329/` (bibliothèque restée en place, copie non déplacement).

## Liens

- `applies` — Décision — Forme standard de la bibliothèque de skills et remplacement par le paquet du warehouse (historique de l'atelier, non distribué) (hors Vault)
- `applies` — Décision — La bibliothèque de skills externes entre dans le Vault (historique de l'atelier, non distribué) (hors Vault)
- `see also` — Décision — Adoption par réécriture d'enveloppe V1 (historique de l'atelier, non distribué) (hors Vault)
