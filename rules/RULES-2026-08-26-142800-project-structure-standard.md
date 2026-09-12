---
type: rules
title: "Standard de structure de projet — sept fonctions, squelette, frontière Vault/projet, YAGNI, clause du grand-père"
description: "Grave le standard de projet arbitré le 2026-08-25 au soir : les sept fonctions minimales d'un projet, le squelette de référence, le test de frontière Vault/projet, le principe YAGNI et la clause du grand-père pour (historique de l'atelier, non distribué)."
created_at: "2026-08-26T14:28:00-04:00"
timezone: America/Montreal
status: active
scope: project-structure-standard
amends: "../decisions/DECISION-2026-08-19-115306-project-registry-v1.md"
---

# STANDARD DE STRUCTURE DE PROJET

Cette règle grave, pour tout projet du workspace, le contrat de structure que le registre v2 mesure (Mission 061). Elle applique les arbitrages de la Décision — Consolidation du 2026-08-25 soir (historique de l'atelier, non distribué) (hors Vault), §1.

## 1. Les sept fonctions

Le minimum vital d'un projet est défini par sept fonctions, pas par des dossiers :

1. **Identité** — « quel est ce projet ? »
2. **Règles métier** — « quelles lois s'appliquent ici et seulement ici ? »
3. **Mémoire d'état** — « où en est-on ? »
4. **Exécution** — « qu'a-t-on fait faire ? »
5. **Arbitrage** — « qu'a-t-on décidé ? »
6. **Matière** — « qu'a-t-on appris ? »
7. **Passation** — « comment on reprend ? »

## 2. Squelette de référence

Les fonctions vivent à la racine du projet — aucun sous-dossier de travail intermédiaire. Les sous-dossiers supplémentaires naissent au fil du besoin réel, jamais par anticipation (§4, YAGNI), selon les normes de nomenclature et les règles de l'art de l'industrie logicielle.

    <projet>/
    ├── README.md      (identité, point d'entrée)
    ├── rules/         (règles métier du projet)
    ├── state/         (journal + fiche générée)
    ├── missions/      (Missions ET leurs rapports — même lignée)
    ├── decisions/     (arbitrages rendus)
    ├── proposals/     (options en attente — séparées : une option n'est pas un arbitrage)
    ├── knowledge/     (matière : captures, études, notes)
    └── handoffs/      (passation)

Exclusions explicites du standard : `prompt-archive/` (aboli, mini-prompts en snippet copiable seulement), `audits/` (un audit est une exécution, son rapport va dans `missions/` avec les autres), `generated/` (naît au besoin, hors minimum).

## 3. Test de frontière Vault/projet

Toute règle candidate se soumet au test suivant :

> « Cette règle aurait-elle du sens dans un autre projet ? »

Oui → elle vit dans le Vault (portable, distribuable). Non → elle vit dans le dossier `rules/` du projet. Le Vault reste distribuable ; les règles métier restent chez elles.

## 4. Principe YAGNI

Aucun sous-dossier, aucun champ, aucun mécanisme n'est créé par anticipation d'un besoin futur. Un projet naît avec le squelette du §2 et rien de plus ; l'extension se fait au moment où le besoin est réel et mesuré, jamais avant.

## 5. Clause du grand-père

(historique de l'atelier, non distribué) reste tel quel : aucune restructuration, aucune migration vers le squelette du §2. Coût connu (liens relatifs, cf. Missions 052–055) pour gain nul. Sa non-conformité au présent standard a valeur pédagogique d'avant/après et sera **constatée, jamais corrigée** par `tools/check-project-conformity.sh` (Mission 061, étape 4). Seule règle qui lui reste applicable : plus aucun dépôt dans ses dossiers morts.

(historique de l'atelier, non distribué) est l'unique bénéficiaire de cette clause. Tout projet créé après l'adoption de ce standard s'y conforme dès sa naissance, sans exception ni délai de grâce.

## Liens

- `amends` — [Decision — Project Registry V1](../decisions/DECISION-2026-08-19-115306-project-registry-v1.md)
- `source` — Décision — Consolidation du 2026-08-25 soir (historique de l'atelier, non distribué) (hors Vault)
